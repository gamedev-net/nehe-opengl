/*                                                           */
/* This code was created by Jeff Molofee '99                 */
/* (Ported to Irix/GLUT by Rob Fletcher 2000)                */
/*                                                           */
/* If you've found this code useful, please let me know.     */
/* Visit Jeff at www.demonews.com/hosted/nehe                */
/* (email Rob Fletcher at R.Fletcher@york.ac.uk)             */
/*                                                           */
#include <GL/glut.h>    /* Header File For The GLUT Library  */
#include <GL/gl.h>	/* Header File For The OpenGL Library */
#include <GL/glu.h>	/* Header File For The GLu Library */
#include <stdio.h>      /* Header file for standard file i/o. */
#include <stdlib.h>     /* Header file for malloc/free. */
#include <unistd.h>     /* needed to sleep. */

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

/* storage for one texture  */
GLuint texture[1];

GLuint cube;             /* storage for the display list  */
GLuint top;              /* storage for the 2nd display list */
GLuint xloop;            /* loop for x axis. */
GLuint yloop;            /* loop for y axis. */

GLfloat xrot;            /* rotates cube on the x axis. */
GLfloat yrot;            /* rotates cube on the y axis. */

/* colors for boxes. */
static GLfloat boxcol[5][3]=
{
    {1.0f,0.0f,0.0f},{1.0f,0.5f,0.0f},{1.0f,1.0f,0.0f},{0.0f,1.0f,0.0f},{0.0f,1.0f,1.0f}
};

/* colors for tops of boxes. */
static GLfloat topcol[5][3]=
{
    {.5f,0.0f,0.0f},{0.5f,0.25f,0.0f},{0.5f,0.5f,0.0f},{0.0f,0.5f,0.0f},{0.0f,0.5f,0.5f}
};
 
/* Image type - contains height, width, and data */
struct Image {
    unsigned long sizeX;
    unsigned long sizeY;
    char *data;
};
typedef struct Image Image;

/* build the display list. */
GLvoid BuildList() 
{
    cube = glGenLists(2);              /* generate storage for 2 lists, and return a pointer to the first. */
    glNewList(cube, GL_COMPILE);       /* store this list at location cube, and compile it once. */

    /* cube without the top; */
    glBegin(GL_QUADS);			/* Bottom Face */

    glTexCoord2f(1.0f, 1.0f); 
    glVertex3f(-1.0f, -1.0f, -1.0f);	/* Top Right Of The Texture and Quad */
    glTexCoord2f(0.0f, 1.0f); 
    glVertex3f( 1.0f, -1.0f, -1.0f);	/* Top Left Of The Texture and Quad */
    glTexCoord2f(0.0f, 0.0f); 
    glVertex3f( 1.0f, -1.0f,  1.0f);	/* Bottom Left Of The Texture and Quad */
    glTexCoord2f(1.0f, 0.0f); 
    glVertex3f(-1.0f, -1.0f,  1.0f);	/* Bottom Right Of The Texture and Quad */
    
    /* Front Face */
    glTexCoord2f(0.0f, 0.0f); 
    glVertex3f(-1.0f, -1.0f,  1.0f);	/* Bottom Left Of The Texture and Quad */
    glTexCoord2f(1.0f, 0.0f); 
    glVertex3f( 1.0f, -1.0f,  1.0f);	/* Bottom Right Of The Texture and Quad */
    glTexCoord2f(1.0f, 1.0f); 
    glVertex3f( 1.0f,  1.0f,  1.0f);	/* Top Right Of The Texture and Quad */
    glTexCoord2f(0.0f, 1.0f); 
    glVertex3f(-1.0f,  1.0f,  1.0f);	/* Top Left Of The Texture and Quad */
    
    /* Back Face */
    glTexCoord2f(1.0f, 0.0f); 
    glVertex3f(-1.0f, -1.0f, -1.0f);	/* Bottom Right Of The Texture and Quad */
    glTexCoord2f(1.0f, 1.0f); 
    glVertex3f(-1.0f,  1.0f, -1.0f);	/* Top Right Of The Texture and Quad */
    glTexCoord2f(0.0f, 1.0f); 
    glVertex3f( 1.0f,  1.0f, -1.0f);	/* Top Left Of The Texture and Quad */
    glTexCoord2f(0.0f, 0.0f); 
    glVertex3f( 1.0f, -1.0f, -1.0f);	/* Bottom Left Of The Texture and Quad */
    
    /* Right face */
    glTexCoord2f(1.0f, 0.0f); 
    glVertex3f( 1.0f, -1.0f, -1.0f);	/* Bottom Right Of The Texture and Quad */
    glTexCoord2f(1.0f, 1.0f); 
    glVertex3f( 1.0f,  1.0f, -1.0f);	/* Top Right Of The Texture and Quad */
    glTexCoord2f(0.0f, 1.0f); 
    glVertex3f( 1.0f,  1.0f,  1.0f);	/* Top Left Of The Texture and Quad */
    glTexCoord2f(0.0f, 0.0f); 
    glVertex3f( 1.0f, -1.0f,  1.0f);	/* Bottom Left Of The Texture and Quad */
    
    /* Left Face */
    glTexCoord2f(0.0f, 0.0f); 
    glVertex3f(-1.0f, -1.0f, -1.0f);	/* Bottom Left Of The Texture and Quad */
    glTexCoord2f(1.0f, 0.0f); 
    glVertex3f(-1.0f, -1.0f,  1.0f);	/* Bottom Right Of The Texture and Quad */
    glTexCoord2f(1.0f, 1.0f); 
    glVertex3f(-1.0f,  1.0f,  1.0f);	/* Top Right Of The Texture and Quad */
    glTexCoord2f(0.0f, 1.0f); 
    glVertex3f(-1.0f,  1.0f, -1.0f);	/* Top Left Of The Texture and Quad */
    
    glEnd();
    glEndList();

    top = cube + 1;                    /* since we generated 2 lists, this is where the second
                                          is...1 GLuint up from cube. */
    glNewList(top, GL_COMPILE);        /* generate 2nd list (top of box). */

    glBegin(GL_QUADS);
    /* Top Face */
    glTexCoord2f(0.0f, 1.0f); 
    glVertex3f(-1.0f,  1.0f, -1.0f);	/* Top Left Of The Texture and Quad */
    glTexCoord2f(0.0f, 0.0f); 
    glVertex3f(-1.0f,  1.0f,  1.0f);	/* Bottom Left Of The Texture and Quad */
    glTexCoord2f(1.0f, 0.0f); 
    glVertex3f( 1.0f,  1.0f,  1.0f);	/* Bottom Right Of The Texture and Quad */
    glTexCoord2f(1.0f, 1.0f); 
    glVertex3f( 1.0f,  1.0f, -1.0f);	/* Top Right Of The Texture and Quad */
    glEnd();

    glEndList();
}

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

    for (i=0;i<size;i+=3) { /* reverse all of the colors. (bgr -> rgb) */
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

    if (!ImageLoad("cube.bmp", TextureImage)) {
	exit(1);
    }        

    /* Create Texture	 */
    glGenTextures(1, &texture[0]);
    glBindTexture(GL_TEXTURE_2D, texture[0]);   /* 2d texture (x and y size) */

 /* scale linearly when image bigger than texture */
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
 /* scale linearly (use mipmaps) when image smaller than texture */    
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    /* 2d texture, 3 components (red, green, blue), x size from image, y size from image,  */
    /* rgb color data, unsigned byte data, and finally the data itself. */
    gluBuild2DMipmaps(GL_TEXTURE_2D, 3, TextureImage->sizeX, TextureImage->sizeY, GL_RGB, GL_UNSIGNED_BYTE, TextureImage->data);
};

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
void InitGL(int Width, int Height)	        /* We call this right after our OpenGL window is created. */
{
    LoadGLTextures();				/* Load The Texture(s)  */
    BuildList();                                /* set up our display lists. */
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

    glEnable(GL_LIGHT0);
    glEnable(GL_LIGHTING);
    glEnable(GL_COLOR_MATERIAL);
}

/* The function called when our window is resized
 (which shouldn't happen, because we're fullscreen) */
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
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		/* Clear The Screen And The Depth Buffer */

    glBindTexture(GL_TEXTURE_2D, texture[0]);

    for (yloop=1; yloop<6; yloop++) { /* 5 rows of cubes. */
	for (xloop=0; xloop<yloop; xloop++) {
	    glLoadIdentity();

	    glTranslatef(1.4f+(((float)xloop)*2.8f)-(((float)yloop)*1.4f),((6.0f-((float)yloop))*2.4f)-7.0f,-20.0f);

	    glRotatef(45.0f - (2.0f*yloop)+xrot, 1.0f, 0.0f, 0.0f);
	    glRotatef(45.0f + yrot, 0.0f, 1.0f, 0.0f);

	    glColor3fv(boxcol[yloop-1]);	    
	    glCallList(cube);
	    
	    glColor3fv(topcol[yloop-1]);
	    glCallList(top);
	}
    }

    /* since this is double buffered, swap the buffers to display what just got drawn. */
    glutSwapBuffers();
}

/* The function called whenever a key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
    /* avoid thrashing this procedure */
    switch (key) {    
    case ESCAPE: /* kill everything.  */
	/* exit the program...normal termination. */
		exit(1);                   	
		break; /* redundant.  */
	default:
		break;
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
    case GLUT_KEY_UP: 
	xrot -= 0.2f;
	break;

    case GLUT_KEY_DOWN:
	xrot += 0.2f;
	break;

    case GLUT_KEY_LEFT: 
	yrot += 0.2f;
	break;
    
    case GLUT_KEY_RIGHT:
	yrot -= 0.2f;
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

