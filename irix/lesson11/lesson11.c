/*                                                            */
/* This code was created by Jeff Molofee '99                  */
/* (ported to Irix/GLUT by Rob Fletcher 2000)                 */
/*  */
/* If you've found this code useful, please let me know. */
/* */
/* Visit Jeff Molofee at www.demonews.com/hosted/nehe  */
/* (email Rob Fletcher at R.Fletcher@york.ac.uk) */
/* */
#include <GL/glut.h>    /* Header File For The GLUT Library  */
#include <GL/gl.h>	/* Header File For The OpenGL Library */
#include <GL/glu.h>	/* Header File For The GLu Library */
#include <stdio.h>      /* Header file for standard file i/o. */
#include <stdlib.h>     /* Header file for malloc/free. */
#include <unistd.h>     /* needed to sleep. */
#include <math.h>       /* sin function. */

/* ascii code for the escape key */
#define ESCAPE 27

/* The number of our GLUT window */
int window; 
int fullscreen=0;	/* toggle fullscreen */
int x_position = 50;	/* position on screen */
int y_position = 50;
int width = 640;	/* Size */
int height = 480;

/* floats for x rotation, y rotation, z rotation */
float xrot, yrot, zrot;

float points[45][45][3];   /* the array for the points on the grid of our "wave" */

int wiggle_count = 0;

/* storage for one texture  */
GLuint texture[1];

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

  /* get 4 bytes */
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
  
  /*get 2 bytes */
  c = getc(fp);  
  c1 = getc(fp);

  return ((unsigned int) c) + (((unsigned int) c1) << 8);
}

/* quick and dirty bitmap loader...for 24 bit bitmaps with 1 plane only.   */
/* See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info. */
int ImageLoad(char *filename, Image *image) 
{
    FILE *file;
    unsigned long size;                 /* size of the image in bytes. */
    unsigned long i;                    /* standard counter. */
    unsigned short int planes;          /* number of planes in image (must be 1)  */
    unsigned short int bpp;             /* number of bits per pixel (must be 24) */
    char temp;                          /* used to convert bgr to rgb color. */

    /* make sure the file is there. */
    if ((file = fopen(filename, "rb"))==NULL) {
      printf("File Not Found : %s\n",filename);
      return 0;
    }
    
    /* seek through the bmp header, up to the width/height: */
    fseek(file, 18, SEEK_CUR);

    /* No 100% errorchecking anymore!!! */

    /* read the width */
    image->sizeX = getint (file);
    printf("Width of %s: %lu\n", filename, image->sizeX);
    
    /* read the height  */
    image->sizeY = getint (file);
    printf("Height of %s: %lu\n", filename, image->sizeY);
    
    /* calculate the size (assuming 24 bits or 3 bytes per pixel). */
    size = image->sizeX * image->sizeY * 3;

    /* read the planes */
    planes = getshort(file);
    if (planes != 1) {
	printf("Planes from %s is not 1: %u\n", filename, planes);
	return 0;
    }

    /* read the bpp */
    bpp = getshort(file);
    if (bpp != 24) {
      printf("Bpp from %s is not 24: %u\n", filename, bpp);
      return 0;
    }
	
    /* seek past the rest of the bitmap header. */
    fseek(file, 24, SEEK_CUR);

    /* read the data.  */
    image->data = (char *) malloc(size);
    if (image->data == NULL) {
	printf("Error allocating memory for color-corrected image data");
	return 0;	
    }

    if ((i = fread(image->data, size, 1, file)) != 1) {
	printf("Error reading image data from %s.\n", filename);
	return 0;
    }

    for (i=0;i<size;i+=3) { /* reverse all of the colors.  (bgr -> rgb) */
	temp = image->data[i];
	image->data[i] = image->data[i+2];
	image->data[i+2] = temp;
    }

    /* we're done. */
    return 1;
}
    
/* Load Bitmaps And Convert To Textures */
void LoadGLTextures() {	
    /* Load Texture */
    Image *TextureImage;
    
    /* allocate space for texture */
    TextureImage = (Image *) malloc(sizeof(Image));
    if (TextureImage == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }

    if (!ImageLoad("tim.bmp", TextureImage)) {
	exit(1);
    }        

    /* Create Texture	 */
    glGenTextures(1, &texture[0]);
    glBindTexture(GL_TEXTURE_2D, texture[0]);   /* 2d texture (x and y size) */

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); /* scale linearly when image bigger than texture */
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); /* scale linearly when image smalled than texture */

    /* 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image,  */
    /* border 0 (normal), rgb color data, unsigned byte data, and finally the data itself. */
    glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage->sizeX, TextureImage->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage->data);
};

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
void InitGL(int Width, int Height)	        /* We call this right after our OpenGL window is created. */
{
    float float_x, float_y;                     /* loop counters. */
    LoadGLTextures();				/* Load The Texture(s)  */
    glEnable(GL_TEXTURE_2D);			/* Enable Texture Mapping */
    glClearColor(0.0f, 0.0f, 1.0f, 0.0f);	/* Clear The Background Color To Blue  */
    glClearDepth(1.0);				/* Enables Clearing Of The Depth Buffer */
    glDepthFunc(GL_LESS);			/* The Type Of Depth Test To Do */
    glEnable(GL_DEPTH_TEST);			/* Enables Depth Testing */
    glShadeModel(GL_SMOOTH);			/* Enables Smooth Color Shading */
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();				/* Reset The Projection Matrix */
    
    gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);	/* Calculate The Aspect Ratio Of The Window */
    
    glMatrixMode(GL_MODELVIEW);

    for(float_x = 0.0f; float_x < 9.0f; float_x +=  0.2f )	{
	for(float_y = 0.0f; float_y < 9.0f; float_y += 0.2f)		{
	    points[ (int) (float_x*5) ][ (int) (float_y*5) ][0] = float_x - 4.4f;
	    points[ (int) (float_x*5) ][ (int) (float_y*5) ][1] = float_y - 4.4f;
	    points[ (int) (float_x*5) ][ (int) (float_y*5) ][2] = (float) (sin( ( (float_x*5*8)/360 ) * 3.14159 * 2 ));
	}
    }
}

/* The function called when our window is resized  */
void ReSizeGLScene(int Width, int Height)
{
    if (Height==0)				/* Prevent A Divide By Zero If The Window Is Too Small */
	Height=1;

    glViewport(0, 0, Width, Height);		/* Reset The Current Viewport And Perspective Transformation */

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);
    glMatrixMode(GL_MODELVIEW);
}

/* The main drawing function. */
void DrawGLScene()
{
    int x, y;
    float float_x, float_y, float_xb, float_yb;

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		/* Clear The Screen And The Depth Buffer */
    glLoadIdentity();				/* Reset The View */
    glTranslatef(0.0f,0.0f,-12.0f);              /* move 12 units into the screen. */
    
    glBindTexture(GL_TEXTURE_2D, texture[0]);   /* choose the texture to use. */

    glPolygonMode(GL_BACK, GL_FILL);
    glPolygonMode(GL_FRONT, GL_LINE);

    glBegin(GL_QUADS);
    for (x=0; x<44; x++) {
	for (y=0; y<44; y++) {
	    float_x  = (float) (x)/44;
	    float_y  = (float) (y)/44;
	    float_xb = (float) (x+1)/44;
	    float_yb = (float) (y+1)/44;

	    glTexCoord2f( float_x, float_y);
	    glVertex3f( points[x][y][0], points[x][y][1], points[x][y][2] );
			
	    glTexCoord2f( float_x, float_yb );
	    glVertex3f( points[x][y+1][0], points[x][y+1][1], points[x][y+1][2] );
			
	    glTexCoord2f( float_xb, float_yb );
	    glVertex3f( points[x+1][y+1][0], points[x+1][y+1][1], points[x+1][y+1][2] );
			
	    glTexCoord2f( float_xb, float_y );
	    glVertex3f( points[x+1][y][0], points[x+1][y][1], points[x+1][y][2] );
	}
    }
    glEnd();

    if (wiggle_count == 2) { /* cycle the sine values */
	for (y = 0; y <45; y++) {
	    points[44][y][2] = points[0][y][2];
	}

	for( x = 0; x < 44; x++ ) {
	    for( y = 0; y < 45; y++) {
		points[x][y][2] = points[x+1][y][2];
	    }		
	}		
	wiggle_count = 0;
    }    
    wiggle_count++;

    xrot +=0.3f;
    yrot +=0.2f;
    zrot +=0.4f;

    /* since this is double buffered, swap the buffers to display what just got drawn. */
    glutSwapBuffers();
}

/* The function called whenever a key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
    switch (key) {    
    case ESCAPE: /* kill everything.  */
	/* exit the program...normal termination. */
	exit(1);                   	
	break; /* redundant.  */
   }
}
/* The function called whenever a normal key is pressed. */
void specialKeyPressed(int key, int x, int y) 
{
    /* avoid thrashing this procedure */
    usleep(100);

    switch (key) {    
	case GLUT_KEY_F1:
	fullscreen = !fullscreen;
	if (fullscreen) {
	    x_position = glutGet((GLenum)GLUT_WINDOW_X);	/* Save parameters */
	    y_position = glutGet((GLenum)GLUT_WINDOW_Y);
	    width = glutGet((GLenum)GLUT_WINDOW_WIDTH);
	    height = glutGet((GLenum)GLUT_WINDOW_HEIGHT);
	    glutFullScreen();				/* Go to full screen */
	} else {
	    glutReshapeWindow(width, height);		/* Restore us */
	    glutPositionWindow(x_position, y_position);
	}
		break;
	default:
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
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE  | GLUT_DEPTH);  

    /* get a 640 x 480 window */
    glutInitWindowSize(width, height);  

    /* the window starts at the upper left corner of the screen */
    glutInitWindowPosition(0, 0);  

    /* Open a window */  
    window = glutCreateWindow("Jeff Molofee's GL Code Tutorial ... NeHe '99");  

    /* Register the function to do all our OpenGL drawing. */
    glutDisplayFunc(DrawGLScene);  

    /* Even if there are no events, redraw our gl scene. */
    glutIdleFunc(DrawGLScene);

    /* Register the function called when our window is resized. */
    glutReshapeFunc(ReSizeGLScene);

    /* Register the function called when the keyboard is pressed. */
    glutKeyboardFunc(keyPressed);

    /* Register the function called when special keys (arrows, page down, etc) are pressed. */
    glutSpecialFunc(specialKeyPressed);

    /* Initialize our window. */
    InitGL(width, height);
  
    /* Start Event Processing Engine */  
    glutMainLoop();  

    return 1;
}

