/*
 *		This Code Was Published By Jeff Molofee 2000
 *		(ported to Linux/GLX by Rodolphe Suescun using a lot
 *		 of code from Mihael Vrbanec ports of other lessons)
 *		Code Was Created By David Nikdel For NeHe Productions
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit My Site At nehe.gamedev.net
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>
#include <GL/glx.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>

/* stuff about our window grouped together */
typedef struct {
    Display *dpy;
    int screen;
    Window win;
    GLXContext ctx;
    XSetWindowAttributes attr;
    Bool fs;
    XF86VidModeModeInfo deskMode;
    int x, y;
    unsigned int width, height;
    unsigned int depth;    
} GLWindow;

/* attributes for a single buffered visual in RGBA format with at least
 * 4 bits per color and a 16 bit depth buffer */
static int attrListSgl[] = {GLX_RGBA, GLX_RED_SIZE, 4, 
    GLX_GREEN_SIZE, 4, 
    GLX_BLUE_SIZE, 4, 
    GLX_DEPTH_SIZE, 16,
    None};

/* attributes for a double buffered visual in RGBA format with at least
 * 4 bits per color and a 16 bit depth buffer */
static int attrListDbl[] = { GLX_RGBA, GLX_DOUBLEBUFFER, 
    GLX_RED_SIZE, 4, 
    GLX_GREEN_SIZE, 4, 
    GLX_BLUE_SIZE, 4, 
    GLX_DEPTH_SIZE, 16,
    None };

GLWindow GLWin;
Bool done;

typedef struct point_3d {			/*  Structure for a 3-dimensional point (NEW) */
	double x, y, z;
} POINT_3D;

typedef struct bpatch {				/*  Structure for a 3rd degree bezier patch (NEW) */
	POINT_3D	anchors[4][4];		/*  4x4 grid of anchor points */
	GLuint		dlBPatch;		/*  Display List for Bezier Patch */
	GLuint		texture;		/*  Texture for the patch */
} BEZIER_PATCH;

Bool			keys[256];		/*  Array Used For The Keyboard Routine */
Bool			active=True;		/*  Window Active Flag Set To True By Default */
Bool			fullscreen=True;	/*  Fullscreen Flag Set To Fullscreen Mode By Default */

GLfloat			rotz = 0.0f;		/*  Rotation about the Z axis */
BEZIER_PATCH		mybezier;		/*  The bezier patch we're going to use (NEW) */
Bool			showCPoints=True;	/*  Toggles displaying the control point grid (NEW) */
int			divs = 7;		/*  Number of intrapolations (conrols poly resolution) (NEW) */


/************************************************************************************/

/*  Adds 2 points. Don't just use '+' ;) */
POINT_3D pointAdd(POINT_3D p, POINT_3D q) {
	p.x += q.x;		p.y += q.y;		p.z += q.z;
	return p;
}

/*  Multiplies a point and a constant. Don't just use '*' */
POINT_3D pointTimes(double c, POINT_3D p) {
	p.x *= c;	p.y *= c;	p.z *= c;
	return p;
}

/*  Function for quick point creation */
POINT_3D makePoint(double a, double b, double c) {
	POINT_3D p;
	p.x = a;	p.y = b;	p.z = c;
	return p;
}


/*  Calculates 3rd degree polynomial based on array of 4 points */
/*  and a single variable (u) which is generally between 0 and 1 */
POINT_3D Bernstein(float u, POINT_3D *p) {
	POINT_3D	a, b, c, d, r;

	a = pointTimes(pow(u,3), p[0]);
	b = pointTimes(3*pow(u,2)*(1-u), p[1]);
	c = pointTimes(3*u*pow((1-u),2), p[2]);
	d = pointTimes(pow((1-u),3), p[3]);

	r = pointAdd(pointAdd(a, b), pointAdd(c, d));

	return r;
}

/*  Generates a display list based on the data in the patch */
/*  and the number of divisions */
GLuint genBezier(BEZIER_PATCH patch, int divs) {
	int			u = 0, v;
	float		py, px, pyold; 
	GLuint		drawlist = glGenLists(1);		/*  make the display list */
	POINT_3D	temp[4];
	POINT_3D	*last = (POINT_3D*)malloc(sizeof(POINT_3D)*(divs+1));
												/*  array of points to mark the first line of polys */

	if (patch.dlBPatch != 0)					/*  get rid of any old display lists */
		glDeleteLists(patch.dlBPatch, 1);

	temp[0] = patch.anchors[0][3];				/*  the first derived curve (along x axis) */
	temp[1] = patch.anchors[1][3];
	temp[2] = patch.anchors[2][3];
	temp[3] = patch.anchors[3][3];

	for (v=0;v<=divs;v++) {						/*  create the first line of points */
		px = ((float)v)/((float)divs);			/*  percent along y axis */
	/*  use the 4 points from the derives curve to calculate the points along that curve */
		last[v] = Bernstein(px, temp);
	}

	glNewList(drawlist, GL_COMPILE);				/*  Start a new display list */
	glBindTexture(GL_TEXTURE_2D, patch.texture);	/*  Bind the texture */

	for (u=1;u<=divs;u++) {
		py	  = ((float)u)/((float)divs);			/*  Percent along Y axis */
		pyold = ((float)u-1.0f)/((float)divs);		/*  Percent along old Y axis */

		temp[0] = Bernstein(py, patch.anchors[0]);	/*  Calculate new bezier points */
		temp[1] = Bernstein(py, patch.anchors[1]);
		temp[2] = Bernstein(py, patch.anchors[2]);
		temp[3] = Bernstein(py, patch.anchors[3]);

		glBegin(GL_TRIANGLE_STRIP);					/*  Begin a new triangle strip */

		for (v=0;v<=divs;v++) {
			px = ((float)v)/((float)divs);			/*  Percent along the X axis */

			glTexCoord2f(pyold, px);				/*  Apply the old texture coords */
			glVertex3d(last[v].x, last[v].y, last[v].z);	/*  Old Point */

			last[v] = Bernstein(px, temp);			/*  Generate new point */
			glTexCoord2f(py, px);					/*  Apply the new texture coords */
			glVertex3d(last[v].x, last[v].y, last[v].z);	/*  New Point */
		}

		glEnd();									/*  END the triangle srip */
	}
	
	glEndList();								/*  END the list */

	free(last);									/*  Free the old vertices array */
	return drawlist;							/*  Return the display list */
}

/************************************************************************************/

void initBezier(void) {	
	mybezier.anchors[0][0] = makePoint(-0.75,	-0.75,	-0.5);	/*  set the bezier vertices */
	mybezier.anchors[0][1] = makePoint(-0.25,	-0.75,	0.0);
	mybezier.anchors[0][2] = makePoint(0.25,	-0.75,	0.0);
	mybezier.anchors[0][3] = makePoint(0.75,	-0.75,	-0.5);
	mybezier.anchors[1][0] = makePoint(-0.75,	-0.25,	-0.75);
	mybezier.anchors[1][1] = makePoint(-0.25,	-0.25,	0.5);
	mybezier.anchors[1][2] = makePoint(0.25,	-0.25,	0.5);
	mybezier.anchors[1][3] = makePoint(0.75,	-0.25,	-0.75);
	mybezier.anchors[2][0] = makePoint(-0.75,	0.25,	0.0);
	mybezier.anchors[2][1] = makePoint(-0.25,	0.25,	-0.5);
	mybezier.anchors[2][2] = makePoint(0.25,	0.25,	-0.5);
	mybezier.anchors[2][3] = makePoint(0.75,	0.25,	0.0);
	mybezier.anchors[3][0] = makePoint(-0.75,	0.75,	-0.5);
	mybezier.anchors[3][1] = makePoint(-0.25,	0.75,	-1.0);
	mybezier.anchors[3][2] = makePoint(0.25,	0.75,	-1.0);
	mybezier.anchors[3][3] = makePoint(0.75,	0.75,	-0.5);
	mybezier.dlBPatch = 0;
}

/*****************************************/
/*  Load Bitmaps And Convert To Textures */

typedef struct {
    int width;
    int height;
    unsigned char *data;
} textureImage;

/* simple loader for 24bit bitmaps (data is in rgb-format) */
int loadBMP(char *filename, textureImage *texture)
{
    FILE *file;
    unsigned short int bfType;
    long int bfOffBits;
    short int biPlanes;
    short int biBitCount;
    long int biSizeImage;
    int i;
    unsigned char temp;
    /* make sure the file is there and open it read-only (binary) */
    if ((file = fopen(filename, "rb")) == NULL)
    {
        printf("File not found : %s\n", filename);
        return 0;
    }
    if(!fread(&bfType, sizeof(short int), 1, file))
    {
        printf("Error reading file!\n");
        return 0;
    }
    /* check if file is a bitmap */
    if (bfType != 19778)
    {
        printf("Not a Bitmap-File!\n");
        return 0;
    }        
    /* get the file size */
    /* skip file size and reserved fields of bitmap file header */
    fseek(file, 8, SEEK_CUR);
    /* get the position of the actual bitmap data */
    if (!fread(&bfOffBits, sizeof(long int), 1, file))
    {
        printf("Error reading file!\n");
        return 0;
    }
    printf("Data at Offset: %ld\n", bfOffBits);
    /* skip size of bitmap info header */
    fseek(file, 4, SEEK_CUR);
    /* get the width of the bitmap */
    fread(&texture->width, sizeof(int), 1, file);
    printf("Width of Bitmap: %d\n", texture->width);
    /* get the height of the bitmap */
    fread(&texture->height, sizeof(int), 1, file);
    printf("Height of Bitmap: %d\n", texture->height);
    /* get the number of planes (must be set to 1) */
    fread(&biPlanes, sizeof(short int), 1, file);
    if (biPlanes != 1)
    {
        printf("Error: number of Planes not 1!\n");
        return 0;
    }
    /* get the number of bits per pixel */
    if (!fread(&biBitCount, sizeof(short int), 1, file))
    {
        printf("Error reading file!\n");
        return 0;
    }
    printf("Bits per Pixel: %d\n", biBitCount);
    if (biBitCount != 24)
    {
        printf("Bits per Pixel not 24\n");
        return 0;
    }
    /* calculate the size of the image in bytes */
    biSizeImage = texture->width * texture->height * 3;
    printf("Size of the image data: %ld\n", biSizeImage);
    texture->data = (unsigned char *)malloc(biSizeImage);
    /* seek to the actual data */
    fseek(file, bfOffBits, SEEK_SET);
    if (!fread(texture->data, biSizeImage, 1, file))
    {
        printf("Error loading file!\n");
        return 0;
    }
    /* swap red and blue (bgr -> rgb) */
    for (i = 0; i < biSizeImage; i += 3)
    {
        temp = texture->data[i];
        texture->data[i] = texture->data[i + 2];
        texture->data[i + 2] = temp;
    }
    return 1;
}

Bool LoadGLTexture(GLuint *texPntr, char* name)
{
    Bool status;
    textureImage *texti;
    
    status = False;
    texti = (textureImage *)malloc(sizeof(textureImage));
    if (loadBMP(name, texti))
    {
        status = True;
        glGenTextures(1, &texPntr[0]);   /* create the texture */
        glBindTexture(GL_TEXTURE_2D, texPntr[0]);
        /* actually generate the texture */
        glTexImage2D(GL_TEXTURE_2D, 0, 3, texti->width, texti->height, 0,
            GL_RGB, GL_UNSIGNED_BYTE, texti->data);
        /* enable linear filtering */
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    /* free the ram we used in our texture generation process */
    if (texti)
    {
        if (texti->data)
            free(texti->data);
        free(texti);
    }    
    return status;
}

/************************************************************************************/
/*  (no changes) */

GLvoid resizeGLScene(GLsizei width, GLsizei height)		/*  Resize And Initialize The GL Window */
{
	if (height==0)						/*  Prevent A Divide By Zero By */
	{
		height=1;					/*  Making Height Equal One */
	}

	glViewport(0,0,width,height);				/*  Reset The Current Viewport */

	glMatrixMode(GL_PROJECTION);				/*  Select The Projection Matrix */
	glLoadIdentity();					/*  Reset The Projection Matrix */

	/*  Calculate The Aspect Ratio Of The Window */
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);				/*  Select The Modelview Matrix */
	glLoadIdentity();					/*  Reset The Modelview Matrix */
}

/************************************************************************************/

int initGL(GLvoid)						/*  All Setup For OpenGL Goes Here */
{
	glEnable(GL_TEXTURE_2D);				/*  Enable Texture Mapping */
	glShadeModel(GL_SMOOTH);				/*  Enable Smooth Shading */
	glClearColor(0.05f, 0.05f, 0.05f, 0.5f);		/*  Black Background */
	glClearDepth(1.0f);					/*  Depth Buffer Setup */
	glEnable(GL_DEPTH_TEST);				/*  Enables Depth Testing */
	glDepthFunc(GL_LEQUAL);					/*  The Type Of Depth Testing To Do */
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	/*  Really Nice Perspective Calculations */

	initBezier();						/*  Initialize the Bezier's control grid */
	LoadGLTexture(&(mybezier.texture), "./data/NeHe.bmp");	/*  Load the texture */
	mybezier.dlBPatch = genBezier(mybezier, divs);		/*  Generate the patch */

	resizeGLScene(GLWin.width, GLWin.height);
	glFlush();

	return True;						/*  Initialization Went OK */
}

/************************************************************************************/

int drawGLScene(GLvoid)	{					/*  Here's Where We Do All The Drawing */
	int i, j;
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	/*  Clear Screen And Depth Buffer */
	glLoadIdentity();					/*  Reset The Current Modelview Matrix */
	glTranslatef(0.0f,0.0f,-4.0f);				/*  Move Left 1.5 Units And Into The Screen 6.0 */
	glRotatef(-75.0f,1.0f,0.0f,0.0f);
	glRotatef(rotz,0.0f,0.0f,1.0f);				/*  Rotate The Triangle On The Z axis ( NEW ) */
		
	glCallList(mybezier.dlBPatch);				/*  Call the Bezier's display list */
								/*  this need only be updated when the patch changes */

	if (showCPoints) {					/*  If drawing the grid is toggled on */
		glDisable(GL_TEXTURE_2D);
		glColor3f(1.0f,0.0f,0.0f);
		for(i=0;i<4;i++) {				/*  draw the horizontal lines */
			glBegin(GL_LINE_STRIP);
			for(j=0;j<4;j++)
				glVertex3d(mybezier.anchors[i][j].x, mybezier.anchors[i][j].y, mybezier.anchors[i][j].z);
			glEnd();
		}
		for(i=0;i<4;i++) {				/*  draw the vertical lines */
			glBegin(GL_LINE_STRIP);
			for(j=0;j<4;j++)
				glVertex3d(mybezier.anchors[j][i].x, mybezier.anchors[j][i].y, mybezier.anchors[j][i].z);
			glEnd();
		}
		glColor3f(1.0f,1.0f,1.0f);
		glEnable(GL_TEXTURE_2D);
	}

	glXSwapBuffers(GLWin.dpy, GLWin.win);

	return True;						/*  Keep Going */
}

/************************************************************************************/

/* function to release/destroy our resources and restoring the old desktop */
GLvoid killGLWindow(GLvoid)
{
    if (GLWin.ctx)
    {
        if (!glXMakeCurrent(GLWin.dpy, None, NULL))
        {
            printf("Could not release drawing context.\n");
        }
        glXDestroyContext(GLWin.dpy, GLWin.ctx);
        GLWin.ctx = NULL;
    }
    /* switch back to original desktop resolution if we were in fs */
    if (GLWin.fs)
    {
        XF86VidModeSwitchToMode(GLWin.dpy, GLWin.screen, &GLWin.deskMode);
        XF86VidModeSetViewPort(GLWin.dpy, GLWin.screen, 0, 0);
    }
    XCloseDisplay(GLWin.dpy);
}


/************************************************************************************/

/* this function creates our window and sets it up properly */
/* FIXME: bits is currently unused */
Bool createGLWindow(char* title, int width, int height, int bits,
                    Bool fullscreenflag)
{
    XVisualInfo *vi;
    Colormap cmap;
    int dpyWidth, dpyHeight;
    int i;
    int glxMajorVersion, glxMinorVersion;
    int vidModeMajorVersion, vidModeMinorVersion;
    XF86VidModeModeInfo **modes;
    int modeNum;
    int bestMode;
    Atom wmDelete;
    Window winDummy;
    unsigned int borderDummy;
    
    GLWin.fs = fullscreenflag;
    /* set best mode to current */
    bestMode = 0;
    /* get a connection */
    GLWin.dpy = XOpenDisplay(0);
    GLWin.screen = DefaultScreen(GLWin.dpy);
    XF86VidModeQueryVersion(GLWin.dpy, &vidModeMajorVersion,
        &vidModeMinorVersion);
    printf("XF86VidModeExtension-Version %d.%d\n", vidModeMajorVersion,
        vidModeMinorVersion);
    XF86VidModeGetAllModeLines(GLWin.dpy, GLWin.screen, &modeNum, &modes);
    /* save desktop-resolution before switching modes */
    GLWin.deskMode = *modes[0];
    /* look for mode with requested resolution */
    for (i = 0; i < modeNum; i++)
    {
        if ((modes[i]->hdisplay == width) && (modes[i]->vdisplay == height))
        {
            bestMode = i;
        }
    }
    /* get an appropriate visual */
    vi = glXChooseVisual(GLWin.dpy, GLWin.screen, attrListDbl);
    if (vi == NULL)
    {
        vi = glXChooseVisual(GLWin.dpy, GLWin.screen, attrListSgl);
        printf("Only Singlebuffered Visual!\n");
    }
    else
    {
        printf("Got Doublebuffered Visual!\n");
    }
    glXQueryVersion(GLWin.dpy, &glxMajorVersion, &glxMinorVersion);
    printf("glX-Version %d.%d\n", glxMajorVersion, glxMinorVersion);
    /* create a GLX context */
    GLWin.ctx = glXCreateContext(GLWin.dpy, vi, 0, GL_TRUE);
    /* create a color map */
    cmap = XCreateColormap(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
        vi->visual, AllocNone);
    GLWin.attr.colormap = cmap;
    GLWin.attr.border_pixel = 0;

    if (GLWin.fs)
    {
        XF86VidModeSwitchToMode(GLWin.dpy, GLWin.screen, modes[bestMode]);
        XF86VidModeSetViewPort(GLWin.dpy, GLWin.screen, 0, 0);
        dpyWidth = modes[bestMode]->hdisplay;
        dpyHeight = modes[bestMode]->vdisplay;
        printf("Resolution %dx%d\n", dpyWidth, dpyHeight);
        XFree(modes);
    
        /* create a fullscreen window */
        GLWin.attr.override_redirect = True;
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
            StructureNotifyMask;
        GLWin.win = XCreateWindow(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
            0, 0, dpyWidth, dpyHeight, 0, vi->depth, InputOutput, vi->visual,
            CWBorderPixel | CWColormap | CWEventMask | CWOverrideRedirect,
            &GLWin.attr);
        XWarpPointer(GLWin.dpy, None, GLWin.win, 0, 0, 0, 0, 0, 0);
		XMapRaised(GLWin.dpy, GLWin.win);
        XGrabKeyboard(GLWin.dpy, GLWin.win, True, GrabModeAsync,
            GrabModeAsync, CurrentTime);
        XGrabPointer(GLWin.dpy, GLWin.win, True, ButtonPressMask,
            GrabModeAsync, GrabModeAsync, GLWin.win, None, CurrentTime);
    }
    else
    {
        /* create a window in window mode*/
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
            StructureNotifyMask;
        GLWin.win = XCreateWindow(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
            0, 0, width, height, 0, vi->depth, InputOutput, vi->visual,
            CWBorderPixel | CWColormap | CWEventMask, &GLWin.attr);
        /* only set window title and handle wm_delete_events if in windowed mode */
        wmDelete = XInternAtom(GLWin.dpy, "WM_DELETE_WINDOW", True);
        XSetWMProtocols(GLWin.dpy, GLWin.win, &wmDelete, 1);
        XSetStandardProperties(GLWin.dpy, GLWin.win, title,
            title, None, NULL, 0, NULL);
        XMapRaised(GLWin.dpy, GLWin.win);
    }       
    /* connect the glx-context to the window */
    glXMakeCurrent(GLWin.dpy, GLWin.win, GLWin.ctx);
    XGetGeometry(GLWin.dpy, GLWin.win, &winDummy, &GLWin.x, &GLWin.y,
        &GLWin.width, &GLWin.height, &borderDummy, &GLWin.depth);
    printf("Depth %d\n", GLWin.depth);
    if (glXIsDirect(GLWin.dpy, GLWin.ctx)) 
        printf("Congrats, you have Direct Rendering!\n");
    else
        printf("Sorry, no Direct Rendering possible!\n");
    if (!initGL())
    {
        printf("Could not initialize OpenGL.\nAborting...\n");
        return False;
    }        
    return True;    
}

void keyPressed(KeySym key)
{
    switch (key) {
        case XK_Escape:
            done = True;
            break;
        case XK_F1:
            killGLWindow();
            GLWin.fs = !GLWin.fs;
            createGLWindow("NeHe's Texture Mapping Tutorial",
                640, 480, 24, GLWin.fs);
            break;
        case XK_Left:
	    rotz -= 0.8f;		/*  rotate left */
	    break;
        case XK_Right:
	    rotz += 0.8f;		/*  rotate left */
	    break;
        case XK_Up:
	    divs++;				/*  Update the patch */
	    mybezier.dlBPatch = genBezier(mybezier, divs);
	    keys[XK_Up%256] = False;
	    break;
        case XK_Down:
	    divs--;				/*  Update the patch */
	    mybezier.dlBPatch = genBezier(mybezier, divs);
	    keys[XK_Down%256] = False;
	    break;
        case XK_space:
	    showCPoints = !showCPoints;
	    keys[XK_space%256] = False;
	    break;
    }
}

int main(int argc, char **argv)
{
    XEvent event;
    KeySym key;
        
    done = False;
    /* default to fullscreen */
    GLWin.fs = True;
    if (!createGLWindow("NeHe's Texture Mapping Tutorial", 640, 480, 24,
        GLWin.fs))
    {
        done = True;
    }
    /* wait for events*/ 
    while (!done)
    {
        /* handle the events in the queue */
        while (XPending(GLWin.dpy) > 0)
        {
            XNextEvent(GLWin.dpy, &event);
            switch (event.type)
            {
                case Expose:
	                if (event.xexpose.count != 0)
	                    break;
                    drawGLScene();
                    break;
                case ConfigureNotify:
                /* call resizeGLScene only if our window-size changed */
                    if ((event.xconfigure.width != GLWin.width) || 
                        (event.xconfigure.height != GLWin.height))
                    {
                        GLWin.width = event.xconfigure.width;
                        GLWin.height = event.xconfigure.height;
                        printf("Resize event\n");
                        resizeGLScene(event.xconfigure.width,
                            event.xconfigure.height);
                    }
                    break;
                /* exit in case of a mouse button press */
                case ButtonPress:     
                    done = True;
                    break;
                case KeyPress:
                    key = XLookupKeysym(&event.xkey, 0);
                    keyPressed(key);
                    break;
                case ClientMessage:    
                    if (*XGetAtomName(GLWin.dpy, event.xclient.message_type)
                        == *"WM_PROTOCOLS")
                    {
                        printf("Exiting sanely...\n");
                        done = True;
                    }
                    break;
                default:
                    break;
            }
        }
        drawGLScene();
    }
    killGLWindow();
    return 0;
}
