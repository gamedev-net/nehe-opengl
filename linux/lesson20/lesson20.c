//
// This code was created by Jeff Molofee '99 (ported to Linux/GLUT by Richard Campbell '99)
//
// If you've found this code useful, please let me know.
//
// Visit me at www.demonews.com/hosted/nehe
// (email Richard Campbell at ulmont@bellsouth.net)
//
// It was modified heavily by Daniel Davis to get rid of Glut (Blah!) and the Tab characters (double Blah!)
// Daniel (planetes@mediaone.net)
// I should note that this was completed on a custom Linux (see www.linuxfromscratch.org)
// using XFree86 4.0.1 with DRI cvs code and a 3dfx Voodoo3 card.

#include <X11/Xlib.h>   // Standard X header for X libraries
#include <X11/Xatom.h>  // Header to provide X's Atom functionality
#include <X11/keysym.h> // Header to provide keyboard functionality under X
#include <GL/gl.h>	// Header File For The OpenGL32 Library
#include <GL/glx.h>     // Header File For The X library for OpenGL
#include <GL/glu.h>	// Header File For The GLu32 Library
#include <stdio.h>      // Standard I/O routines
#include <stdlib.h>     // Standard Library routines
#include <unistd.h>     // Header file for sleeping.

/* Buffer parameters for Double Buffering */
static int dblBuf[] = {GLX_RGBA,
                       GLX_RED_SIZE, 1,
                       GLX_GREEN_SIZE, 1,
                       GLX_BLUE_SIZE, 1,
                       GLX_DEPTH_SIZE, 12,
                       GLX_DOUBLEBUFFER,
                       None};

/* Global variables */
Atom    wmDeleteWindow; // Custom message to Delete Window
Display *dpDisplay;     // Display variable
Window  win;            // Current Window variable
Bool    masking;        // Masking On/Off
Bool    scene;          // Which Scene To Draw

GLuint  iTexture[5];    // Storage For Our Five Textures
GLuint  loop;           // Generic Loop Variable

GLfloat roll;           // Rolling Texture

/* Image type - contains height, width, and data */
struct Texture {
    unsigned long ulDimensionX;
    unsigned long ulDimensionY;
    char *pcData;
};
typedef struct Texture Texture;

// quick and dirty bitmap loader...for 24 bit bitmaps with 1 plane only.
// See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info.
int LoadBMP(char *szFilename, Texture *pTexture)
{
//  Texture *pTexture;
  FILE *filePointer;
  unsigned long ulSize;               // size of the image in bytes.
  unsigned long iCount;               // standard counter.
  unsigned short int usiPlanes;       // number of planes in image (must be 1)
  unsigned short int usiBpp;          // number of bits per pixel (must be 24)
  char cTempColor;                    // temporary color storage for bgr-rgb conversion.

    // make sure the file is there.
  if ((filePointer = fopen(szFilename, "rb"))==NULL)
  {
    printf("File Not Found : %s\n",szFilename);
    exit(0);
  }

  // seek through the bmp header, up to the width/height:
  fseek(filePointer, 18, SEEK_CUR);

  // read the width
  if ((iCount = fread(&pTexture->ulDimensionX, 4, 1, filePointer)) != 1)
  {
    printf("Error reading width from %s.\n", szFilename);
    exit(0);
  }
  printf("Width of %s: %lu\n", szFilename, pTexture->ulDimensionX);

    // read the height
  if ((iCount = fread(&pTexture->ulDimensionY, 4, 1, filePointer)) != 1)
  {
    printf("Error reading height from %s.\n", szFilename);
    exit(0);
  }
  printf("Height of %s: %lu\n", szFilename, pTexture->ulDimensionY);

  // calculate the size (assuming 24 bits or 3 bytes per pixel).
  ulSize = pTexture->ulDimensionX * pTexture->ulDimensionY * 3;

//  printf("zz%dyy%dxx%d\n\r", ulSize, pTexture->ulDimensionX, pTexture->ulDimensionY);
    // read the planes
  if ((fread(&usiPlanes, 2, 1, filePointer)) != 1)
  {
    printf("Error reading planes from %s.\n", szFilename);
    exit(0);
  }

  if (usiPlanes != 1)
  {
    printf("Planes from %s is not 1: %u\n", szFilename, usiPlanes);
    exit(0);
  }

  // read the bpp
  if ((iCount = fread(&usiBpp, 2, 1, filePointer)) != 1)
  {
    printf("Error reading bpp from %s.\n", szFilename);
    exit(0);
  }
  if (usiBpp != 24)
  {
    printf("Bpp from %s is not 24: %u\n", szFilename, usiBpp);
    exit(0);
  }

  // seek past the rest of the bitmap header.
  fseek(filePointer, 24, SEEK_CUR);

  // read the data.
  pTexture->pcData = (char *) malloc(ulSize);
  if (pTexture->pcData == NULL)
  {
    printf("Error allocating memory for color-corrected image data");
    exit(0);
  }

  if ((iCount = fread(pTexture->pcData, ulSize, 1, filePointer)) != 1)
  {
    printf("Error reading image data from %s.\n", szFilename);
    exit(0);
  }

  for (iCount=0;iCount<ulSize;iCount+=3) // reverse all of the colors. (bgr -> rgb)
  {
    cTempColor = pTexture->pcData[iCount];
    pTexture->pcData[iCount] = pTexture->pcData[iCount+2];
    pTexture->pcData[iCount+2] = cTempColor;
  }
  // we're done.
//  return pTexture;
  return 1;
}

// Load Bitmaps And Convert To Textures
int LoadGLTextures()
{
  // Load Texture
  Texture *TextureImage;
  // allocate space for texture
  TextureImage = (Texture *) malloc(sizeof(Texture));

  glGenTextures(5, &iTexture[0]);                // Create Five Textures

  for(loop=0;loop<5;loop++)
  {
    switch(loop)
    {
      case 0:
        LoadBMP("Data/lesson20/logo.bmp", TextureImage);
        break;

      case 1:
        LoadBMP("Data/lesson20/image1.bmp", TextureImage);
        break;

      case 2:
        LoadBMP("Data/lesson20/mask1.bmp", TextureImage);
        break;

      case 3:
        LoadBMP("Data/lesson20/image2.bmp", TextureImage);
        break;

      case 4:
        LoadBMP("Data/lesson20/mask2.bmp", TextureImage);
        break;
    }
    glBindTexture(GL_TEXTURE_2D, iTexture[loop]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage->ulDimensionX, TextureImage->ulDimensionY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage->pcData);
  }

  if (TextureImage)                      // If Texture Exists
  {
    if (TextureImage->pcData)            // If Texture Image Exists
    {
      free(TextureImage->pcData);        // Free The Texture Image Memory
    }
    free(TextureImage);                  // Free The Image Structure
  }

  return True;                                   // Return The Status
}

/* Function to construct and initialize X-windows Window */
void xInitWindow(int *argv, char **argc)
{
  XVisualInfo *xvVisualInfo;
  Colormap    cmColorMap;
  XSetWindowAttributes winAttributes;
  GLXContext  glXContext;

  /* Open the Display */
  dpDisplay = XOpenDisplay(NULL);
  if(dpDisplay == NULL)
  {
    printf("Could not open display!\n\r");
    exit(0);
  }

  /* Check for GLX extension to X-Windows */
  if(!glXQueryExtension(dpDisplay, NULL, NULL))
  {
    printf("X server has no GLX extension.\n\r");
    exit(0);
  }

  /* Grab a doublebuffering RGBA visual as defined in dblBuf */
  xvVisualInfo = glXChooseVisual(dpDisplay, DefaultScreen(dpDisplay), dblBuf);
  if(xvVisualInfo == NULL)
  {
    printf("No double buffering RGB visual with depth buffer available.\n\r");
    exit(0);
  }

  /* Create a window context */
  glXContext = glXCreateContext(dpDisplay, xvVisualInfo, None, True);
  if(glXContext == NULL)
  {
    printf("Could not create rendering context.\n\r");
    exit(0);
  }

  /* Create the color map for the new window */
  cmColorMap = XCreateColormap(dpDisplay, RootWindow(dpDisplay, xvVisualInfo->screen), xvVisualInfo->visual, AllocNone);
  winAttributes.colormap = cmColorMap;
  winAttributes.border_pixel = 0;
  winAttributes.event_mask = ExposureMask | ButtonPressMask | StructureNotifyMask |
                             KeyPressMask;

  /* Create the actual window object */
  win = XCreateWindow(dpDisplay,
                      RootWindow(dpDisplay, xvVisualInfo->screen),
                      0,
                      0,
                      640,                      // Horizontal Size
                      480,                      // Veritical Size
                      0,
                      xvVisualInfo->depth,
                      InputOutput,
                      xvVisualInfo->visual,
                      CWBorderPixel | CWColormap | CWEventMask,
                      &winAttributes);

  /* Set the standard properties for the window. */
  XSetStandardProperties(dpDisplay,
                         win,
                         "Daniel Davis's Fog Tutorial ... NeHe '99",
                         "lesson20",
                         None,
                         (char **) argv,
                         (int) argc,
                         NULL);

  /* Establish new event */
  wmDeleteWindow = XInternAtom(dpDisplay, "WM_DELETE_WINDOW", False);
  XSetWMProtocols(dpDisplay, win, &wmDeleteWindow, 1);

  /* Bind the OpenGL context to the newly created window. */
  glXMakeCurrent(dpDisplay, win, glXContext);

  /* Make the new window the active window. */
  XMapWindow(dpDisplay, win);
}

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
int InitGL(int Width, int Height)                // We call this right after our OpenGL window is created.
{
  if (!LoadGLTextures())                         // Jump To Texture Loading Routine
  {
    return False;                                // If Texture Didn't Load Return FALSE
  }

  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);          // Clear The Background Color To Black
  glClearDepth(1.0);                             // Enables Clearing Of The Depth Buffer
  glEnable(GL_DEPTH_TEST);                       // Enable Depth Testing
  glShadeModel(GL_SMOOTH);                       // Enables Smooth Color Shading
  glEnable(GL_TEXTURE_2D);                       // Enable 2D Texture Mapping
  return True;
}


/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
void ReSizeGLScene(int Width, int Height)
{
  if (Height==0)                                // Prevent A Divide By Zero If The Window Is Too Small
    Height=1;

  glViewport(0, 0, Width, Height);              // Reset The Current Viewport And Perspective Transformation

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);
  glMatrixMode(GL_MODELVIEW);
}

/* The function to draw the screendrawing function. */
void DrawGLScene()
{
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
  glLoadIdentity();                              // Reset The Modelview Matrix
  glTranslatef(0.0f,0.0f,-2.0f);                 // Move Into The Screen 5 Units

  glBindTexture(GL_TEXTURE_2D, iTexture[0]);     // Select Our Logo Texture
  glBegin(GL_QUADS);                             // Start Drawing A Textured Quad
    glTexCoord2f(0.0f, -roll+0.0f); glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
    glTexCoord2f(3.0f, -roll+0.0f); glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
    glTexCoord2f(3.0f, -roll+3.0f); glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
    glTexCoord2f(0.0f, -roll+3.0f); glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
  glEnd();                                       // Done Drawing The Quad

  glEnable(GL_BLEND);                            // Enable Blending
  glDisable(GL_DEPTH_TEST);                      // Disable Depth Testing

  if (masking)                                   // Is Masking Enabled?
  {
    glBlendFunc(GL_DST_COLOR,GL_ZERO);           // Blend Screen Color With Zero (Black)
  }

  if (scene)                                     // Are We Drawing The Second Scene?
  {
    glTranslatef(0.0f,0.0f,-1.0f);               // Translate Into The Screen One Unit
    glRotatef(roll*360,0.0f,0.0f,1.0f);          // Rotate On The Z Axis 360 Degrees.
    if (masking)                                 // Is Masking On?
    {
      glBindTexture(GL_TEXTURE_2D, iTexture[3]); // Select The Second Mask Texture
      glBegin(GL_QUADS);                         // Start Drawing A Textured Quad
        glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
        glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
        glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
        glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
      glEnd();                                   // Done Drawing The Quad
    }

    glBlendFunc(GL_ONE, GL_ONE);                 // Copy Image 2 Color To The Screen
    glBindTexture(GL_TEXTURE_2D, iTexture[4]);   // Select The Second Image Texture
    glBegin(GL_QUADS);                           // Start Drawing A Textured Quad
      glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
      glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
      glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
      glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
      glEnd();                                   // Done Drawing The Quad
  }
  else                                           // Otherwise
  {
    if (masking)                                 // Is Masking On?
    {
      glBindTexture(GL_TEXTURE_2D, iTexture[1]); // Select The First Mask Texture
      glBegin(GL_QUADS);                         // Start Drawing A Textured Quad
        glTexCoord2f(roll+0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
        glTexCoord2f(roll+4.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
        glTexCoord2f(roll+4.0f, 4.0f); glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
        glTexCoord2f(roll+0.0f, 4.0f); glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
      glEnd();                                   // Done Drawing The Quad
    }

    glBlendFunc(GL_ONE, GL_ONE);                 // Copy Image 1 Color To The Screen
    glBindTexture(GL_TEXTURE_2D, iTexture[2]);   // Select The First Image Texture
    glBegin(GL_QUADS);                           // Start Drawing A Textured Quad
      glTexCoord2f(roll+0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
      glTexCoord2f(roll+4.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
      glTexCoord2f(roll+4.0f, 4.0f); glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
      glTexCoord2f(roll+0.0f, 4.0f); glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
    glEnd();                                     // Done Drawing The Quad
  }

  glEnable(GL_DEPTH_TEST);                       // Enable Depth Testing
  glDisable(GL_BLEND);                           // Disable Blending

  roll+=0.002f;                                  // Increase Our Texture Roll Variable
  if (roll>1.0f)                                 // Is Roll Greater Than One
  {
    roll-=1.0f;                                  // Subtract 1 From Roll
  }

   // since this is double buffered, swap the buffers to display what just got drawn.
  glXSwapBuffers(dpDisplay, win);
}


/* The function called whenever a key is pressed. */
void keyPressed(KeySym key)
{
  /* avoid thrashing this procedure */
//  usleep(100);

  /* If escape is pressed, kill everything. */
  switch(key)
  {
    case XK_Escape:
      XCloseDisplay(dpDisplay);

      /* exit the program...normal termination. */
      exit(0);
      break;

    case XK_space:
      scene=!scene;
      break;

    case XK_M:
    case XK_m:
      masking=!masking;
      break;
  }
}


void xMainLoop()
{
  XEvent event;
  KeySym ks;
  Bool needRedraw = False;

  while(1)
  {
    if(XPending(dpDisplay))  // While more events are pending, continue processing.
    {
      /* Get the current event from the system queue. */
      XNextEvent(dpDisplay, &event);

      /* Process the incoming event. */
      switch(event.type)
      {
        case Expose:
          needRedraw = True;
          break;

        /* If window moves, redraw it. */
        case MotionNotify:
          needRedraw = True;
          break;

        /* If a key was pressed, get keystroke and called the processing function. */
        case KeyPress:
          ks = XLookupKeysym((XKeyEvent *) &event, 0);
          keyPressed(ks);
          break;

        /* If the screen was resized, call the appropriate function. */
        case ConfigureNotify:
          ReSizeGLScene(event.xconfigure.width, event.xconfigure.height);
          break;

        case ButtonPress:
          break;

        /* Process any custom messages. */
        case ClientMessage:
          if(event.xclient.data.l[0] == wmDeleteWindow)
          {
 XCloseDisplay(dpDisplay);
            exit(0);
          }
          break;
      }
    }

    /* If redraw flag is set, redraw the window. */
//    if(needRedraw)
    {
      DrawGLScene();
    }
  }
}


int main(int argc, char **argv)
{
  /* Initialize our window. */
  xInitWindow(&argc, argv);

  /* Initialize OpenGL routines */
  if(!InitGL(640, 480))
  {
    printf("Error initializing OpenGL. \n\r");
    exit(0);
  }

  /* Start Event Processing Engine */
  xMainLoop();

  return(1);
}

