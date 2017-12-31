/*
 * This code was created by Lionel Brits & Jeff Molofee 2000
 * (ported to Linux/GLX by Mihael Vrbanec '00)
 *
 * If you've found this code useful, please let me know.
 *
 * Visit Jeff at http://nehe.gamedev.net/
 * 
 * or for port-specific comments, questions, bugreports etc. 
 * email to Mihael.Vrbanec@stud.uni-karlsruhe.de
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <GL/glx.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>
#include <math.h>           /* include for trigonometric functions */


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

/* a texture struct */
typedef struct {
    int width;
    int height;
    unsigned char *data;
} textureImage;

typedef struct {
    float x, y, z;
    float u, v;
} vertex;

typedef struct {
    vertex vertex[3];
} triangle;

typedef struct {
    int numTris;
    triangle* triangle;
} sector;


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
Bool keys[256];
int keyCodes[20];     /* array to hold our fetched keycodes */
Bool done;
Bool light;
Bool blend;    /* Blending on/off */
GLfloat rotY;  /* Y Rotation */
GLfloat xpos;  /* X position */
GLfloat zpos;  /* Y position */
GLfloat walkbias, walkbiasangle;    /* variables for head-bobbing */
GLfloat lookupdown;
GLfloat lightAmbient[] = { 0.5f, 0.5f, 0.5f, 1.0f };
GLfloat lightDiffuse[] = { 1.0f, 1.0f, 1.0f, 1.0f };
GLfloat lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };
const char *worldfile = "Data/world.txt";   /* datafile for our 3D world */
const float piover180 = 0.0174532925f;
sector sector1;
GLuint filter;      /* which filter to use */
GLuint texture[3];  /* storage for three textures */

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
    texture->data = malloc(biSizeImage);
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

Bool loadGLTextures()   /* Load Bitmaps And Convert To Textures */
{
    Bool status;
    textureImage *texti;
    
    status = False;
    texti = malloc(sizeof(textureImage));
    if (loadBMP("Data/mud.bmp", texti))
    {
        status = True;
        glGenTextures(3, &texture[0]);   /* create three textures */
        glBindTexture(GL_TEXTURE_2D, texture[0]);
        /* actually generate the texture */
        glTexImage2D(GL_TEXTURE_2D, 0, 3, texti->width, texti->height, 0,
            GL_RGB, GL_UNSIGNED_BYTE, texti->data);
        /* use no filtering */
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        /* the second texture */
        glBindTexture(GL_TEXTURE_2D, texture[1]);
        glTexImage2D(GL_TEXTURE_2D, 0, 3, texti->width, texti->height, 0,
            GL_RGB, GL_UNSIGNED_BYTE, texti->data);
        /* use linear filtering */
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        /* the third texture */
        glBindTexture(GL_TEXTURE_2D, texture[2]);
        gluBuild2DMipmaps(GL_TEXTURE_2D, 3, texti->width,
            texti->height, GL_RGB, GL_UNSIGNED_BYTE, texti->data);
        /* use mipmapping */
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
            GL_LINEAR_MIPMAP_NEAREST);
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

GLvoid readStr(FILE *file, char *string)
{
    do
    {
        fgets(string, 255, file);
    }
    while ((string[0] == '/') || (string[0] == '\n'));
    return;
}

GLvoid setupWorld()
{
    FILE *filein;
    int numTris;
    char oneline[255];
    float x, y, z, u, v;
    int triLoop, vertLoop;
    
    filein = fopen(worldfile, "r");
    readStr(filein, oneline);
    sscanf(oneline, "NUMPOLLIES %d\n", &numTris);
    sector1.triangle = malloc (numTris * sizeof(triangle));
    sector1.numTris = numTris;
    for (triLoop = 0; triLoop < sector1.numTris; triLoop++)
    {
        for (vertLoop = 0; vertLoop < 3; vertLoop++)
        {
            readStr(filein, oneline);
            sscanf(oneline, "%f %f %f %f %f", &x, &y, &z, &u, &v);
            sector1.triangle[triLoop].vertex[vertLoop].x = x;
            sector1.triangle[triLoop].vertex[vertLoop].y = y;
            sector1.triangle[triLoop].vertex[vertLoop].z = z;
            sector1.triangle[triLoop].vertex[vertLoop].u = u;
            sector1.triangle[triLoop].vertex[vertLoop].v = v;
        }
    }
    fclose(filein);
    return;
}

/* function called when our window is resized (should only happen in window mode) */
void resizeGLScene(unsigned int width, unsigned int height)
{
    if (height == 0)    /* Prevent A Divide By Zero If The Window Is Too Small */
        height = 1;
    glViewport(0, 0, width, height);    /* Reset The Current Viewport And Perspective Transformation */
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0f, (GLfloat)width / (GLfloat)height, 0.1f, 100.0f);
    glMatrixMode(GL_MODELVIEW);
}

/* general OpenGL initialization function */
int initGL(GLvoid)
{
    if (!loadGLTextures())
    {
        return False;
    }
    glEnable(GL_TEXTURE_2D);       /* enable texture mapping */
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);  /* blending function */
    glShadeModel(GL_SMOOTH);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    /* set up our lighting */
    glLightfv(GL_LIGHT1, GL_AMBIENT, lightAmbient);
    glLightfv(GL_LIGHT1, GL_DIFFUSE, lightDiffuse);
    glLightfv(GL_LIGHT1, GL_POSITION, lightPosition);
    glEnable(GL_LIGHT1);
    lookupdown = 0.0f;
    walkbias = 0.0f;
    walkbiasangle = 0.0f;
    if (blend)
    {
        glEnable(GL_BLEND);
        glDisable(GL_DEPTH_TEST);
    }
    if (light)
        glEnable(GL_LIGHTING);
    setupWorld();
    /* we use resizeGLScene once to set up our initial perspective */
    resizeGLScene(GLWin.width, GLWin.height);
    glFlush();
    return True;
}

/* Here goes our drawing code */
int drawGLScene(GLvoid)
{
    GLfloat x, y, z, u, v;      /* temporary floating variables */
    GLfloat xtrans, ytrans, ztrans;
    GLfloat sceneroty;
    int i;
    int numTri;
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    xtrans = -xpos;
    ztrans = -zpos;
    ytrans = -walkbias - 0.25f;
    sceneroty = 360.0f - rotY;
    glRotatef(lookupdown, 1.0f, 0.0f, 0.0f);
    glRotatef(sceneroty, 0.0f, 1.0f, 0.0f);
    glTranslatef(xtrans, ytrans, ztrans);
    glBindTexture(GL_TEXTURE_2D, texture[filter]);
    numTri = sector1.numTris;
    for (i = 0; i < numTri; i++)
    {
        glBegin(GL_TRIANGLES);
            glNormal3f(0.0f, 0.0f, 1.0f);
            /* first vertex of triangle */
            x = sector1.triangle[i].vertex[0].x;
            y = sector1.triangle[i].vertex[0].y;
            z = sector1.triangle[i].vertex[0].z;
            u = sector1.triangle[i].vertex[0].u;
            v = sector1.triangle[i].vertex[0].v;
            glTexCoord2f(u, v);
            glVertex3f(x, y, z);
            /* second vertex of triangle */
            x = sector1.triangle[i].vertex[1].x;
            y = sector1.triangle[i].vertex[1].y;
            z = sector1.triangle[i].vertex[1].z;
            u = sector1.triangle[i].vertex[1].u;
            v = sector1.triangle[i].vertex[1].v;
            glTexCoord2f(u, v);
            glVertex3f(x, y, z);
            /* third vertex of triangle */
            x = sector1.triangle[i].vertex[2].x;
            y = sector1.triangle[i].vertex[2].y;
            z = sector1.triangle[i].vertex[2].z;
            u = sector1.triangle[i].vertex[2].u;
            v = sector1.triangle[i].vertex[2].v;
            glTexCoord2f(u, v);
            glVertex3f(x, y, z);
        glEnd();
    }  
    glXSwapBuffers(GLWin.dpy, GLWin.win);
    return True;    
}

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
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask |
            ButtonPressMask | StructureNotifyMask;
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
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask |
            ButtonPressMask | StructureNotifyMask;
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
    initGL();
    return True;    
}
/* get the keycodes of the keys we want to react on and store them in an array.
 * This way we do not need to get them everytime we check for pressed keys.
 */
void initKeys()
{
    printf("Initializing keys...\n");
    /* get keycode for escape-key */
    keyCodes[0] = XKeysymToKeycode(GLWin.dpy, XK_Escape);
    /* get keycode for F1 */
    keyCodes[1] = XKeysymToKeycode(GLWin.dpy, XK_F1);
    /* get keycode for l */
    keyCodes[2] = XKeysymToKeycode(GLWin.dpy, XK_l);
    /* get keycode for f */
    keyCodes[3] = XKeysymToKeycode(GLWin.dpy, XK_f);
    /* get keycode for b */
    keyCodes[4] = XKeysymToKeycode(GLWin.dpy, XK_b);
    /* get keycode for Page_Up */
    keyCodes[5] = XKeysymToKeycode(GLWin.dpy, XK_Page_Up);
    /* get keycode for Page_Down */
    keyCodes[6] = XKeysymToKeycode(GLWin.dpy, XK_Page_Down);
    /* get keycode for Up-Arrow */
    keyCodes[7] = XKeysymToKeycode(GLWin.dpy, XK_Up);
    /* get keycode for Down-Arrow */
    keyCodes[8] = XKeysymToKeycode(GLWin.dpy, XK_Down);
    /* get keycode for Left-Arrow */
    keyCodes[9] = XKeysymToKeycode(GLWin.dpy, XK_Left);
    /* get keycode for Right-Arrow */
    keyCodes[10] = XKeysymToKeycode(GLWin.dpy, XK_Right);
}

/* this function uses the keycode to determine if an action should be performed.
 * It replaces the keyPressed-function of former lessons to provide smooth 
 * (more quake-like *grin*) moving in our 3D-world
 */
void keyAction(void)
{
    if (keys[keyCodes[0]])
    {
        done = True;
    }
    if (keys[keyCodes[1]])
    {
        killGLWindow();
        GLWin.fs = !GLWin.fs;
        createGLWindow("NeHe's 3D-World Tutorial",
            640, 480, 24, GLWin.fs);
        /* avoid multiple switches and therefore set the keypress back  */
        keys[keyCodes[1]] = False;
    }
    if (keys[keyCodes[2]])
    {
        light = !light;
        if (!light)
            glDisable(GL_LIGHTING);
        else
            glEnable(GL_LIGHTING);
        /* avoid multiple switches and therefore set the keypress back  */
        keys[keyCodes[2]] = False;
    }
    if (keys[keyCodes[3]])
    {
        filter += 1;
        if (filter > 2)
            filter = 0;
        /* avoid multiple switches and therefore set the keypress back  */
        keys[keyCodes[3]] = False;
    }
    if (keys[keyCodes[4]])
    {
        blend = !blend;
        if (blend)
        {
            glEnable(GL_BLEND);         /* turn blending on */
            glDisable(GL_DEPTH_TEST);   /* turn depth testing off */
        }
        else
        {
            glDisable(GL_BLEND);        /* turn blending off */
            glEnable(GL_DEPTH_TEST);    /* turn depth testing on */
        }
        /* avoid multiple switches and therefore set the keypress back  */
        keys[keyCodes[4]] = False;
    }
    if (keys[keyCodes[5]])
    {
            lookupdown -= 1.0f;
    }
    if (keys[keyCodes[6]])
    {
            lookupdown += 1.0f;
    }
    if (keys[keyCodes[7]])
    {
        xpos -= (float) sin(rotY * piover180) * 0.02f;  /* move on X-Plane */
        zpos -= (float) cos(rotY * piover180) * 0.02f;  /* move on Z-Plane */
        if (walkbiasangle >= 359.0f)
        {
            walkbiasangle = 0.0f;
        }
        else
        {
            walkbiasangle += 5;
        }
        walkbias = (float) sin(walkbiasangle * piover180) / 20.0f;
    }
    if (keys[keyCodes[8]])
    {
        xpos += (float) sin(rotY * piover180) * 0.02f;  /* move on X-Plane */
        zpos += (float) cos(rotY * piover180) * 0.02f;  /* move on Z-Plane */
        if (walkbiasangle <= 1.0f)
        {
            walkbiasangle = 359.0f;
        }
        else
        {
            walkbiasangle -= 10;
        }
        walkbias = (float) sin(walkbiasangle * piover180) / 20.0f;
    }
    if (keys[keyCodes[9]])
    {
        rotY += 0.6f;
    }
    if (keys[keyCodes[10]])
    {
        rotY -= 0.6f;
    }
}

int main(int argc, char **argv)
{
    XEvent event;
        
    done = False;
    light = False;
    blend = False;
    /* default to fullscreen */
    GLWin.fs = True;
    if (!createGLWindow("NeHe's 3D-World Tutorial",
        640, 480, 24, GLWin.fs))
    {
        done = True;
    }
    initKeys();
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
                    keys[event.xkey.keycode] = True;
                    break;
                case KeyRelease:
                    keys[event.xkey.keycode] = False;
                    break;
                case ClientMessage:    
                    if (*XGetAtomName(GLWin.dpy, event.xclient.message_type) == 
                        *"WM_PROTOCOLS")
                    {
                        printf("Exiting sanely...\n");
                        done = True;
                    }
                    break;
                default:
                    break;
            }
        }
        /* look if we should perfom actions due to keypresses */
        keyAction();
        drawGLScene();
    }
    killGLWindow();
    return 0;
}
