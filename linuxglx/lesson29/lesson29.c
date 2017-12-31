/*
 * The OpenGL Basecode Used In This Project Was Created By
 * Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code
 * Useful, Please Let Me Know.
 * 
 * Original Code & Tutorial Text By Andreas Löffler
 * Excellent Job Andreas!
 * 
 * Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )
 * Proper Image Structure, Better Blitter Code, Misc Fixes
 * Thanks Rob!
 * 
 * (ported to Linux/GLX by Rodolphe Suescun using a lot
 * of code from Mihael Vrbanec ports of other lessons)
 * 
 * Visit Me At nehe.gamedev.net
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

Bool		active=True;			/*  Window Active Flag Set To True By Default */
Bool		fullscreen=True;		/*  Fullscreen Flag Set To Fullscreen Mode By Default */

GLfloat		xrot;				/*  X Rotation */
GLfloat		yrot;				/*  Y Rotation */
GLfloat		zrot;				/*  Z Rotation */

GLuint		texture[1];			/*  Storage For 1 Texture */

typedef struct
{
	int width;				/*  Width Of Image In Pixels */
	int height;				/*  Height Of Image In Pixels */
	int format;				/*  Number Of Bytes Per Pixel */
	unsigned char *data;			/*  Texture Data */
} TEXTURE_IMAGE;

typedef TEXTURE_IMAGE *P_TEXTURE_IMAGE;		/*  A Pointer To The Texture Image Data Type */

P_TEXTURE_IMAGE t1;				/*  Pointer To The Texture Image Data Type */
P_TEXTURE_IMAGE t2;				/*  Pointer To The Texture Image Data Type */


/*  Allocate An Image Structure And Inside Allocate Its Memory Requirements */
P_TEXTURE_IMAGE AllocateTextureBuffer( GLint w, GLint h, GLint f)
{
    P_TEXTURE_IMAGE ti=NULL;				/*  Pointer To Image Struct */
    unsigned char *c=NULL;				/*  Pointer To Block Memory For Image */

    ti = (P_TEXTURE_IMAGE)malloc(sizeof(TEXTURE_IMAGE));/*  One Image Struct Please */
    
    if( ti != NULL ) {
        ti->width  = w;					/*  Set Width */
        ti->height = h;					/*  Set Height */
        ti->format = f;					/*  Set Format */
        c = (unsigned char *)malloc( w * h * f);
        if ( c != NULL ) {
            ti->data = c;
        }
        else {
		printf("Could Not Allocate Memory For A Texture Buffer\n");
            return NULL;
        }
    }
    else
	{
		printf("Could Not Allocate An Image Structure\n");
		return NULL;
    }
	return ti;													/*  Return Pointer To Image Struct */
}

/*  Free Up The Image Data */
void DeallocateTexture( P_TEXTURE_IMAGE t )
{
	if(t)
	{
		if(t->data)
		{
			free(t->data);
		}

		free(t);
	}
}

/*  Read A .RAW File In To The Allocated Image Buffer Using Data In The Image Structure Header. */
/*  Flip The Image Top To Bottom.  Returns 0 For Failure Of Read, Or Number Of Bytes Read. */
int ReadTextureData ( char *filename, P_TEXTURE_IMAGE buffer)
{
	FILE *f;
	int i,j,k,done=0;
	int stride = buffer->width * buffer->format;				/*  Size Of A Row (Width * Bytes Per Pixel) */
	unsigned char *p = NULL;

    f = fopen(filename, "rb");									/*  Open "filename" For Reading Bytes */
    if( f != NULL )												/*  If File Exists */
    {
		for( i = buffer->height-1; i >= 0 ; i-- )				/*  Loop Through Height (Bottoms Up - Flip Image) */
		{
			p = buffer->data + (i * stride );					/*   */
			for ( j = 0; j < buffer->width ; j++ )				/*  Loop Through Width */
			{
				for ( k = 0 ; k < buffer->format-1 ; k++, p++, done++ )
				{
					*p = fgetc(f);								/*  Read Value From File And Store In Memory */
				}
				*p = 255; p++;									/*  Store 255 In Alpha Channel And Increase Pointer */
			}
		}
		fclose(f);												/*  Close The File */
	}
	else														/*  Otherwise */
	{
		printf("Unable To Open Image File\n");
    }
	return done;												/*  Returns Number Of Bytes Read In */
}

void BuildTexture (P_TEXTURE_IMAGE tex)
{
	glGenTextures(1, &texture[0]);
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB, tex->width, tex->height, GL_RGBA, GL_UNSIGNED_BYTE, tex->data);
}

void Blit( P_TEXTURE_IMAGE src, P_TEXTURE_IMAGE dst, int src_xstart, int src_ystart, int src_width, int src_height,
           int dst_xstart, int dst_ystart, int blend, int alpha)
{
	int i,j,k;
	unsigned char *s, *d;										/*  Source & Destination */

	/*  Clamp Alpha If Value Is Out Of Range */
    if( alpha > 255 ) alpha = 255;
    if( alpha < 0 ) alpha = 0;

	/*  Check For Incorrect Blend Flag Values */
    if( blend < 0 ) blend = 0;
    if( blend > 1 ) blend = 1;

    d = dst->data + (dst_ystart * dst->width * dst->format);    /*  Start Row - dst (Row * Width In Pixels * Bytes Per Pixel) */
    s = src->data + (src_ystart * src->width * src->format);    /*  Start Row - src (Row * Width In Pixels * Bytes Per Pixel) */

    for (i = 0 ; i < src_height ; i++ )				/*  Height Loop */
    {
        s = s + (src_xstart * src->format);			/*  Move Through Src Data By Bytes Per Pixel */
        d = d + (dst_xstart * dst->format);			/*  Move Through Dst Data By Bytes Per Pixel */
        for (j = 0 ; j < src_width ; j++ )			/*  Width Loop */
        {
            for( k = 0 ; k < src->format ; k++, d++, s++)	/*  "n" Bytes At A Time */
            {
                if (blend)										/*  If Blending Is On */
                    *d = ( (*s * alpha) + (*d * (255-alpha)) ) >> 8; /*  Multiply Src Data*alpha Add Dst Data*(255-alpha) */
                else											/*  Keep in 0-255 Range With >> 8 */
                    *d = *s;									/*  No Blending Just Do A Straight Copy */
            }
        }
        d = d + (dst->width - (src_width + dst_xstart))*dst->format;	/*  Add End Of Row */
        s = s + (src->width - (src_width + src_xstart))*src->format;	/*  Add End Of Row */
    }
}

GLvoid ResizeGLScene(GLsizei width, GLsizei height)/*  Resize And Initialize The GL Window */
{
	if (height==0)				/*  Prevent A Divide By Zero By */
	{
		height=1;			/*  Making Height Equal One */
	}

	glViewport(0,0,width,height);		/*  Reset The Current Viewport */

	glMatrixMode(GL_PROJECTION);		/*  Select The Projection Matrix */
	glLoadIdentity();			/*  Reset The Projection Matrix */

	/*  Calculate The Aspect Ratio Of The Window */
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);		/*  Select The Modelview Matrix */
	glLoadIdentity();			/*  Reset The Modelview Matrix */
}

int InitGL(GLvoid)	/*  This Will Be Called Right After The GL Window Is Created */
{
    t1 = AllocateTextureBuffer( 256, 256, 4 );		/*  Get An Image Structure */
    if (ReadTextureData("Data/Monitor.raw",t1)==0)	/*  Fill The Image Structure With Data */
	{															/*  Nothing Read? */
		printf("Could Not Read 'Monitor.raw' Image Data\n");
        return False;
    }

    t2 = AllocateTextureBuffer( 256, 256, 4 );		/*  Second Image Structure */
	if (ReadTextureData("Data/GL.raw",t2)==0)	/*  Fill The Image Structure With Data */
	{						/*  Nothing Read? */
		printf("Could Not Read 'GL.raw' Image Data\n");
        return False;
    }

	/*  Image To Blend In, Original Image, Src Start X & Y, Src Width & Height, Dst Location X & Y, Blend Flag, Alpha Value */
    Blit(t2,t1,127,127,128,128,64,64,1,127);	/*  Call The Blitter Routine */

    BuildTexture (t1);				/*  Load The Texture Map Into Texture Memory */

    DeallocateTexture( t1 );			/*  Clean Up Image Memory Because Texture Is */
    DeallocateTexture( t2 );			/*  In GL Texture Memory Now */

    glEnable(GL_TEXTURE_2D);			/*  Enable Texture Mapping */

    glShadeModel(GL_SMOOTH);			/*  Enables Smooth Color Shading */
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);	/*  This Will Clear The Background Color To Black */
    glClearDepth(1.0);				/*  Enables Clearing Of The Depth Buffer */
    glEnable(GL_DEPTH_TEST);			/*  Enables Depth Testing */
    glDepthFunc(GL_LESS);			/*  The Type Of Depth Test To Do */
    ResizeGLScene(GLWin.width, GLWin.height);
    glFlush();

    return True;
}

GLvoid DrawGLScene(GLvoid)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		/*  Clear The Screen And The Depth Buffer */
	glLoadIdentity();										/*  Reset The View */
	glTranslatef(0.0f,0.0f,-5.0f);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);
	glRotatef(zrot,0.0f,0.0f,1.0f);

	glBindTexture(GL_TEXTURE_2D, texture[0]);

	glBegin(GL_QUADS);
		/*  Front Face */
		glNormal3f( 0.0f, 0.0f, 1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		/*  Back Face */
		glNormal3f( 0.0f, 0.0f,-1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		/*  Top Face */
		glNormal3f( 0.0f, 1.0f, 0.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		/*  Bottom Face */
		glNormal3f( 0.0f,-1.0f, 0.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		/*  Right Face */
		glNormal3f( 1.0f, 0.0f, 0.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		/*  Left Face */
		glNormal3f(-1.0f, 0.0f, 0.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glEnd();

	xrot+=0.3f;
	yrot+=0.2f;
	zrot+=0.4f;

	glXSwapBuffers(GLWin.dpy, GLWin.win);
}

/* function to release/destroy our resources and restoring the old desktop */
GLvoid KillGLWindow(GLvoid)
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

/* this function creates our window and sets it up properly */
/* FIXME: bits is currently unused */
Bool CreateGLWindow(char* title, int width, int height, int bits,
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
    if (!InitGL())
    {
        printf("Could not initialize OpenGL.\nAborting...\n");
        return False;
    }        
    return True;    
}

void keyPressed(KeySym key)
{
    switch (key)
    {
        case XK_Escape:
            done = True;
            break;
        case XK_F1:
            KillGLWindow();
            GLWin.fs = !GLWin.fs;
            CreateGLWindow("NeHe's Texture Mapping Tutorial",
                640, 480, 24, GLWin.fs);
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
    if (!CreateGLWindow("NeHe's Texture Mapping Tutorial", 640, 480, 24,
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
                    DrawGLScene();
                    break;
                case ConfigureNotify:
                /* call ResizeGLScene only if our window-size changed */
                    if ((event.xconfigure.width != GLWin.width) || 
                        (event.xconfigure.height != GLWin.height))
                    {
                        GLWin.width = event.xconfigure.width;
                        GLWin.height = event.xconfigure.height;
                        printf("Resize event\n");
                        ResizeGLScene(event.xconfigure.width,
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
        DrawGLScene();
    }
    KillGLWindow();
    return 0;
}

