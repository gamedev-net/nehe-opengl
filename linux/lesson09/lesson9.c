//
// This code was created by Jeff Molofee '99 (ported to Linux/GLUT by 
// Richard Campbell '99)
//
// If you've found this code useful, please let me know.
//
// Visit me at www.demonews.com/hosted/nehe 
// (email Richard Campbell at ulmont@bellsouth.net)
//
#include <GL/glut.h>    // Header File For The GLUT Library 
#include <GL/gl.h>	// Header File For The OpenGL32 Library
#include <GL/glu.h>	// Header File For The GLu32 Library
#include <unistd.h>     // Header file for sleeping.
#include <stdio.h>      // Header file for standard file i/o.
#include <stdlib.h>     // Header file for malloc/free.

/* number of stars to have */
#define STAR_NUM 50

/* ascii codes for various special keys */
#define ESCAPE 27
#define PAGE_UP 73
#define PAGE_DOWN 81
#define UP_ARROW 72
#define DOWN_ARROW 80
#define LEFT_ARROW 75
#define RIGHT_ARROW 77

/* The number of our GLUT window */
int window; 

/* twinkle on/off (1 = on, 0 = off) */
int twinkle = 0;

typedef struct {         // Star structure
    int r, g, b;         // stars' color
    GLfloat dist;        // stars' distance from center
    GLfloat angle;       // stars' current angle
} stars;                 // name is stars

stars star[STAR_NUM];    // make 'star' array of STAR_NUM size using info from the structure 'stars'

GLfloat zoom = -15.0f;   // viewing distance from stars.
GLfloat tilt = 90.0f;    // tilt the view
GLfloat spin;            // spin twinkling stars

GLuint loop;             // general loop variable
GLuint texture[1];       // storage for one texture;

/* Image type - contains height, width, and data */
struct Image {
    unsigned long sizeX;
    unsigned long sizeY;
    char *data;
};
typedef struct Image Image;

/*
 * getint and getshort are help functions to load the bitmap byte by byte on 
 * SPARC platform (actually, just makes the thing work on platforms of either
 * endianness, not just Intel's little endian)
 */

static unsigned int getint(fp)
     FILE *fp;
{
  int c, c1, c2, c3;

  // get 4 bytes
  c = getc(fp);  
  c1 = getc(fp);  
  c2 = getc(fp);  
  c3 = getc(fp);
  
  return ((unsigned int) c) +   
    (((unsigned int) c1) << 8) + 
    (((unsigned int) c2) << 16) +
    (((unsigned int) c3) << 24);
}

static unsigned int getshort(fp)
     FILE *fp;
{
  int c, c1;
  
  //get 2 bytes
  c = getc(fp);  
  c1 = getc(fp);

  return ((unsigned int) c) + (((unsigned int) c1) << 8);
}

// quick and dirty bitmap loader...for 24 bit bitmaps with 1 plane only.  
// See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info.

int ImageLoad(char *filename, Image *image) 
{
    FILE *file;
    unsigned long size;                 // size of the image in bytes.
    unsigned long i;                    // standard counter.
    unsigned short int planes;          // number of planes in image (must be 1) 
    unsigned short int bpp;             // number of bits per pixel (must be 24)
    char temp;                          // used to convert bgr to rgb color.

    // make sure the file is there.
    if ((file = fopen(filename, "rb"))==NULL) {
      printf("File Not Found : %s\n",filename);
      return 0;
    }
    
    // seek through the bmp header, up to the width/height:
    fseek(file, 18, SEEK_CUR);

    // No 100% errorchecking anymore!!!

    // read the width
    image->sizeX = getint (file);
    printf("Width of %s: %lu\n", filename, image->sizeX);
    
    // read the height 
    image->sizeY = getint (file);
    printf("Height of %s: %lu\n", filename, image->sizeY);
    
    // calculate the size (assuming 24 bits or 3 bytes per pixel).
    size = image->sizeX * image->sizeY * 3;

    // read the planes
    planes = getshort(file);
    if (planes != 1) {
	printf("Planes from %s is not 1: %u\n", filename, planes);
	return 0;
    }

    // read the bpp
    bpp = getshort(file);
    if (bpp != 24) {
      printf("Bpp from %s is not 24: %u\n", filename, bpp);
      return 0;
    }
	
    // seek past the rest of the bitmap header.
    fseek(file, 24, SEEK_CUR);

    // read the data. 
    image->data = (char *) malloc(size);
    if (image->data == NULL) {
	printf("Error allocating memory for color-corrected image data");
	return 0;	
    }

    if ((i = fread(image->data, size, 1, file)) != 1) {
	printf("Error reading image data from %s.\n", filename);
	return 0;
    }

    for (i=0;i<size;i+=3) { // reverse all of the colors. (bgr -> rgb)
	temp = image->data[i];
	image->data[i] = image->data[i+2];
	image->data[i+2] = temp;
    }

    // we're done.
    return 1;
}

// Load Bitmaps And Convert To Textures
GLvoid LoadGLTextures(GLvoid) 
{	
    // Load Texture
    Image *image1;
    
    // allocate space for texture
    image1 = (Image *) malloc(sizeof(Image));
    if (image1 == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }

    if (!ImageLoad("Data/lesson9/Star.bmp", image1)) {
	exit(1);
    }        

    // Create Textures	
    glGenTextures(3, &texture[0]);

    // linear filtered texture
    glBindTexture(GL_TEXTURE_2D, texture[0]);   // 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); // scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); // scale linearly when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->sizeX, image1->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->data);
};

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
GLvoid InitGL(GLsizei Width, GLsizei Height)	// We call this right after our OpenGL window is created.
{
    LoadGLTextures();                           // load the textures.
    glEnable(GL_TEXTURE_2D);                    // Enable texture mapping.

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);	// This Will Clear The Background Color To Black
    glClearDepth(1.0);				// Enables Clearing Of The Depth Buffer

    glShadeModel(GL_SMOOTH);			// Enables Smooth Color Shading
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();				// Reset The Projection Matrix
    
    gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);	// Calculate The Aspect Ratio Of The Window
    
    glMatrixMode(GL_MODELVIEW);

    /* setup blending */
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);	        // Set The Blending Function For Translucency
    glEnable(GL_BLEND);                         // Enable Blending

    /* set up the stars */
    for (loop=0; loop<STAR_NUM; loop++) {
	star[loop].angle = 0.0f;                // initially no rotation.
	
	star[loop].dist = loop * 1.0f / STAR_NUM * 5.0f; // calculate distance form the center
	star[loop].r = rand() % 256;            // random red intensity;
	star[loop].g = rand() % 256;            // random green intensity;
	star[loop].b = rand() % 256;            // random blue intensity;
    }    
}

/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
GLvoid ReSizeGLScene(GLsizei Width, GLsizei Height)
{
    if (Height==0)				// Prevent A Divide By Zero If The Window Is Too Small
	Height=1;

    glViewport(0, 0, Width, Height);		// Reset The Current Viewport And Perspective Transformation

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);
    glMatrixMode(GL_MODELVIEW);
}

/* The main drawing function. */
GLvoid DrawGLScene(GLvoid)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear The Screen And The Depth Buffer
    
    glBindTexture(GL_TEXTURE_2D, texture[0]);    // pick the texture.

    for (loop=0; loop<STAR_NUM; loop++) {        // loop through all the stars.
	glLoadIdentity();                        // reset the view before we draw each star.
	glTranslatef(0.0f, 0.0f, zoom);          // zoom into the screen.
	glRotatef(tilt, 1.0f, 0.0f, 0.0f);       // tilt the view.
	
	glRotatef(star[loop].angle, 0.0f, 1.0f, 0.0f); // rotate to the current star's angle.
	glTranslatef(star[loop].dist, 0.0f, 0.0f); // move forward on the X plane (the star's x plane).

	glRotatef(-star[loop].angle, 0.0f, 1.0f, 0.0f); // cancel the current star's angle.
	glRotatef(-tilt, 1.0f, 0.0f, 0.0f);      // cancel the screen tilt.

	if (twinkle) {                           // twinkling stars enabled ... draw an additional star.
	    // assign a color using bytes
	    glColor4ub(star[STAR_NUM - loop].r, star[STAR_NUM - loop].g, star[STAR_NUM - loop].b, 255);

	    glBegin(GL_QUADS);                   // begin drawing the textured quad.
	    glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, 0.0f);
	    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, 0.0f);
	    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, 0.0f);
	    glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f, 1.0f, 0.0f);
	    glEnd();                             // done drawing the textured quad.
	}

	// main star
	glRotatef(spin, 0.0f, 0.0f, 1.0f);       // rotate the star on the z axis.

        // Assign A Color Using Bytes
	glColor4ub(star[loop].r,star[loop].g,star[loop].b,255);
	glBegin(GL_QUADS);			// Begin Drawing The Textured Quad
	glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,-1.0f, 0.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f, 1.0f, 0.0f);
	glEnd();				// Done Drawing The Textured Quad
	
	spin +=0.01f;                           // used to spin the stars.
	star[loop].angle += loop * 1.0f / STAR_NUM * 1.0f;    // change star angle.
	star[loop].dist  -= 0.01f;              // bring back to center.

	if (star[loop].dist<0.0f) {             // star hit the center
	    star[loop].dist += 5.0f;            // move 5 units from the center.
	    star[loop].r = rand() % 256;        // new red color.
	    star[loop].g = rand() % 256;        // new green color.
	    star[loop].b = rand() % 256;        // new blue color.
	}
    }
   
    // since this is double buffered, swap the buffers to display what just got drawn.
    glutSwapBuffers();
}


/* The function called whenever a normal key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
    /* avoid thrashing this procedure */
    usleep(100);

    switch (key) {    
    case ESCAPE: // kill everything.
	/* exit the program...normal termination. */
	exit(1);                   	
	break; // redundant.

    case 84: 
    case 116: // switch the twinkling.
	printf("T/t pressed; twinkle is: %d\n", twinkle);
	twinkle = twinkle ? 0 : 1;              // switch the current value of twinkle, between 0 and 1.
	printf("Twinkle is now: %d\n", twinkle);
	break;

    default:
      printf ("Key %d pressed. No action there yet.\n", key);
      break;
    }	
}

/* The function called whenever a normal key is pressed. */
void specialKeyPressed(int key, int x, int y) 
{
    /* avoid thrashing this procedure */
    usleep(100);

    switch (key) {    
    case GLUT_KEY_PAGE_UP: // zoom out
	zoom -= 0.2f;
	break;
    
    case GLUT_KEY_PAGE_DOWN: // zoom in
	zoom += 0.2f;
	break;

    case GLUT_KEY_UP: // tilt up
	tilt -= 0.5f;
	break;

    case GLUT_KEY_DOWN: // tilt down
	tilt += 0.5f;
	break;

    default:
	printf ("Special key %d pressed. No action there yet.\n", key);
	break;
    }	
}

int main(int argc, char **argv) 
{  
    /* Initialize GLUT state - glut will take any command line arguments that pertain to it or 
       X Windows - look at its documentation at http://reality.sgi.com/mjk/spec3/spec3.html */  
    glutInit(&argc, argv);  

    /* Select type of Display mode:   
     Double buffer 
     RGBA color
     Depth buffer */
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);  

    /* get a 640 x 480 window */
    glutInitWindowSize(640, 480);  

    /* the window starts at the upper left corner of the screen */
    glutInitWindowPosition(0, 0);  

    /* Open a window */  
    window = glutCreateWindow("Jeff Molofee's GL Code Tutorial ... NeHe '99");  

    /* Register the function to do all our OpenGL drawing. */
    glutDisplayFunc(&DrawGLScene);  

    /* Go fullscreen.  This is as soon as possible. */
    glutFullScreen();

    /* Even if there are no events, redraw our gl scene. */
    glutIdleFunc(&DrawGLScene); 

    /* Register the function called when our window is resized. */
    glutReshapeFunc(&ReSizeGLScene);

    /* Register the function called when the keyboard is pressed. */
    glutKeyboardFunc(&keyPressed);

    /* Register the function called when special keys (arrows, page down, etc) are pressed. */
    glutSpecialFunc(&specialKeyPressed);

    /* Initialize our window. */
    InitGL(640, 480);
  
    /* Start Event Processing Engine */  
    glutMainLoop();  

    return 1;
}

