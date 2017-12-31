/*
 * This code was created by Jeff Molofee '99 
 * (ported to Linux/GLX by Mihael Vrbanec '01)
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

typedef struct {
    int width;
    int height;
    unsigned char *data;
} textureImage;

/* attributes for a single buffered visual in RGBA format with at least
 * 4 bits per color and a 16 bit depth buffer */
static int attrListSgl[] = {GLX_RGBA, GLX_RED_SIZE, 4, 
    GLX_GREEN_SIZE, 4, 
    GLX_BLUE_SIZE, 4, 
    GLX_DEPTH_SIZE, 16,
    None
};

/* attributes for a double buffered visual in RGBA format with at least
 * 4 bits per color and a 16 bit depth buffer */
static int attrListDbl[] = { GLX_RGBA, GLX_DOUBLEBUFFER, 
    GLX_RED_SIZE, 4, 
    GLX_GREEN_SIZE, 4, 
    GLX_BLUE_SIZE, 4, 
    GLX_DEPTH_SIZE, 16,
    None
};


GLWindow GLWin;
Bool done;
Bool keys[256];
int keyCodes[4];       /* array to hold our fetched keycodes */
Bool masking = True;
Bool scene = True;
GLuint loop;
GLfloat roll;
GLuint texture[5];

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
    texti = malloc(sizeof(textureImage) * 5);
    if (loadBMP("Data/logo.bmp", &texti[0]) &&
        loadBMP("Data/mask1.bmp", &texti[1]) &&
        loadBMP("Data/image1.bmp", &texti[2]) &&
        loadBMP("Data/mask2.bmp", &texti[3]) &&
        loadBMP("Data/image2.bmp", &texti[4]))
    {
        status = True;
        glGenTextures(5, &texture[0]);   /* create five textures */
        for (loop = 0; loop < 5; loop++)
        {
            glBindTexture(GL_TEXTURE_2D, texture[loop]);
            /* use linear filtering */
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            /* actually generate the texture */
            glTexImage2D(GL_TEXTURE_2D, 0, 3, texti[loop].width,
                texti[loop].height, 0, GL_RGB, GL_UNSIGNED_BYTE,
                texti[loop].data);
        }
    }
    /* free the ram we used in our texture generation process */
    for (loop = 0; loop < 5; loop++)
    {    
        if (&texti[loop])
        {
            if (texti[loop].data)
                free(texti[loop].data);
        }
    }
    free(texti);
    return status;
}


/* function called when our window is resized (should only happen in window mode) */
void resizeGLScene(unsigned int width, unsigned int height)
{
    if (height == 0)    /* Prevent A Divide By Zero If The Window Is Too Small */
        height = 1;
    glViewport(0, 0, width, height);    /* Reset The Current Viewport And Perspective Transformation */
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0f, (GLfloat)width / (GLfloat)height, 0.1f, 200.0f);
    glMatrixMode(GL_MODELVIEW);
}

/* general OpenGL initialization function */
int initGL(GLvoid)
{
    if (!loadGLTextures())
    {
        return False;
    }
    glShadeModel(GL_SMOOTH);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    /* we use resizeGLScene once to set up our initial perspective */
    resizeGLScene(GLWin.width, GLWin.height);
    glFlush();
    return True;
}

/* Here goes our drawing code */
int drawGLScene(GLvoid)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glTranslatef(0.0f, 0.0f, -2.0f);
    glBindTexture(GL_TEXTURE_2D, texture[0]);
    glBegin(GL_QUADS);
        glTexCoord2f(0.0f, -roll + 0.0f);
        glVertex3f(-1.1f, -1.1f, 0.0f);
        glTexCoord2f(3.0f, -roll + 0.0f);
        glVertex3f(1.1f, -1.1f, 0.0f);
        glTexCoord2f(3.0f, -roll + 3.0f);
        glVertex3f(1.1f, 1.1f, 0.0f);
        glTexCoord2f(0.0f, -roll + 3.0f);
        glVertex3f(-1.1f, 1.1f, 0.0f);
    glEnd();
    glEnable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
    if (masking)
    {
        glBlendFunc(GL_DST_COLOR, GL_ZERO);
    }
    if (scene)
    {
        glTranslatef(0.0f, 0.0f, -1.0f);
        glRotatef(roll * 360, 0.0f, 0.0f, 1.0f);
        if (masking)
        {
            glBindTexture(GL_TEXTURE_2D, texture[3]);
            glBegin(GL_QUADS);
                glTexCoord2f(0.0f, 0.0f);
                glVertex3f(-1.1f, -1.1f, 0.0f);
                glTexCoord2f(1.0f, 0.0f);
                glVertex3f(1.1f, -1.1f, 0.0f);
                glTexCoord2f(1.0f, 1.0f);
                glVertex3f(1.1f, 1.1f, 0.0f);
                glTexCoord2f(0.0f, 1.0f);
                glVertex3f(-1.1f, 1.1f, 0.0f);
            glEnd();
        }
        glBlendFunc(GL_ONE, GL_ONE);
        glBindTexture(GL_TEXTURE_2D, texture[4]);
        glBegin(GL_QUADS);
            glTexCoord2f(0.0f, 0.0f);
            glVertex3f(-1.1f, -1.1f, 0.0f);
            glTexCoord2f(1.0f, 0.0f);
            glVertex3f(1.1f, -1.1f, 0.0f);
            glTexCoord2f(1.0f, 1.0f);
            glVertex3f(1.1f, 1.1f, 0.0f);
            glTexCoord2f(0.0f, 1.0f);
            glVertex3f(-1.1f, 1.1f, 0.0f);
        glEnd();
    }
    else
    {
        if (masking)
        {
            glBindTexture(GL_TEXTURE_2D, texture[1]);
            glBegin(GL_QUADS);
                glTexCoord2f(roll + 0.0f, 0.0f);
                glVertex3f(-1.1f, -1.1f, 0.0f);
                glTexCoord2f(roll + 4.0f, 0.0f);
                glVertex3f(1.1f, -1.1f, 0.0f);
                glTexCoord2f(roll + 4.0f, 4.0f);
                glVertex3f(1.1f, 1.1f, 0.0f);
                glTexCoord2f(roll + 0.0f, 4.0f);
                glVertex3f(-1.1f, 1.1f, 0.0f);
            glEnd();
        }
        glBlendFunc(GL_ONE, GL_ONE);
        glBindTexture(GL_TEXTURE_2D, texture[2]);
        glBegin(GL_QUADS);
            glTexCoord2f(roll + 0.0f, 0.0f);
            glVertex3f(-1.1f, -1.1f, 0.0f);
            glTexCoord2f(roll + 4.0f, 0.0f);
            glVertex3f(1.1f, -1.1f, 0.0f);
            glTexCoord2f(roll + 4.0f, 4.0f);
            glVertex3f(1.1f, 1.1f, 0.0f);
            glTexCoord2f(roll + 0.0f, 4.0f);
            glVertex3f(-1.1f, 1.1f, 0.0f);
        glEnd();
    }
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    roll += 0.002f;
    if (roll > 1.0f)
        roll -= 1.0f;
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
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
            KeyReleaseMask | StructureNotifyMask;
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
            KeyReleaseMask | StructureNotifyMask;
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

void initKeys()
{
    printf("Initializing keys...\n");
    /* get keycode for escape-key */
    keyCodes[0] = XKeysymToKeycode(GLWin.dpy, XK_Escape);
    /* get keycode for F1 */
    keyCodes[1] = XKeysymToKeycode(GLWin.dpy, XK_F1);
    /* get keycode for "space" */
    keyCodes[2] = XKeysymToKeycode(GLWin.dpy, XK_space);
    /* get keycode for 'm' */
    keyCodes[3] = XKeysymToKeycode(GLWin.dpy, XK_m);
}

void keyAction()
{
    if (keys[keyCodes[0]])
        done = True;
    if (keys[keyCodes[1]])
    {
        killGLWindow();
        GLWin.fs = !GLWin.fs;
        createGLWindow("NeHe's Masking Tutorial", 640, 480, 24, GLWin.fs);
        keys[keyCodes[1]] = False;
    }
    if (keys[keyCodes[2]])
    {
        scene = !scene;
        keys[keyCodes[2]] = False;
    }    
    if (keys[keyCodes[3]])
    {
        masking = !masking;
        keys[keyCodes[3]] = False;
    }    
}

int main(int argc, char **argv)
{
    XEvent event;
    
    done = False;
    /* default to fullscreen */
    GLWin.fs = True;
    createGLWindow("NeHe's Masking Tutorial", 640, 480, 24, GLWin.fs);
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
        keyAction();
        drawGLScene();
    }
    killGLWindow();
    return 0;
}
