/*
 * This Code Was Created By Jeff Molofee 2000
 * And Modified By Giuseppe D'Agata (waveform@tiscalinet.it)
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net
 *
 * Ported to IRIX/GLUT by Rob Fletcher
 * (email me at R.Fletcher@york.ac.uk)
 */

#include <GL/glut.h>    /*  Header File For The GLUT Library */
#include <GL/gl.h>	/*  Header File For The OpenGL Library */
#include <GL/glu.h>	/*  Header File For The GLu Library */
#include <stdio.h>      /*  Header file for standard file i/o.*/
#include <stdlib.h>     /*  Header file for malloc/free. */

int	masking=1;		/* Masking On/Off */
int	scene;			/* Which Scene To Draw */

GLuint	texture[5];		/* Storage For Our Five Textures */
GLuint	loop;			/* Generic Loop Variable */

GLfloat	roll;			/* Rolling Texture */

/* ascii codes for various special keys */
#define ESCAPE 27
/* The number of our GLUT window */
int window; 
/* Used to toggle full screen/window mode */
int fullscreen=0;	/* toggle fullscreen */
int x_position = 50;	/* position on screen */
int y_position = 50;
int width = 640;	/* Size */
int height = 480;


/* Image type - contains height, width, and data */
struct Image {
    unsigned long sizeX;
    unsigned long sizeY;
    char *data;
};
typedef struct Image Image;

/*
 * getint and getshort arehelp functions to load the bitmap byte by byte on 
 * SPARC platform.
 * I've got them from xv bitmap load routinebecause the original bmp loader didn't work
 * I've tried to change as less code as possible.
 */

static unsigned int getint(fp)
     FILE *fp;
{
  int c, c1, c2, c3;

  /*  get 4 bytes */
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
  
  /* get 2 bytes */
  c = getc(fp);  
  c1 = getc(fp);

  return ((unsigned int) c) + (((unsigned int) c1) << 8);
}

/*  quick and dirty bitmap loader...for 24 bit bitmaps with 1 plane only.  
    See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info. */

int ImageLoad(char *filename, Image *image) {
    FILE *file;
    unsigned long size;                 /*  size of the image in bytes. */
    unsigned long i;                    /*  standard counter. */
    unsigned short int planes;          /*  number of planes in image (must be 1)  */
    unsigned short int bpp;             /*  number of bits per pixel (must be 24) */
    char temp;                          /*  used to convert bgr to rgb color. */

    /*  make sure the file is there. */
    if ((file = fopen(filename, "rb"))==NULL) {
      printf("File Not Found : %s\n",filename);
      return 0;
    }
    
    /*  seek through the bmp header, up to the width/height: */
    fseek(file, 18, SEEK_CUR);

    /*  No 100% errorchecking anymore!!! */

    /*  read the width */
    image->sizeX = getint (file);
/*    printf("Width of %s: %lu\n", filename, image->sizeX); */
    
    /*  read the height  */
    image->sizeY = getint (file);
/*    printf("Height of %s: %lu\n", filename, image->sizeY); */
    
    /*  calculate the size (assuming 24 bits or 3 bytes per pixel). */
    size = image->sizeX * image->sizeY * 3;

    /*  read the planes */
    planes = getshort(file);
    if (planes != 1) {
	printf("Planes from %s is not 1: %u\n", filename, planes);
	return 0;
    }

    /*  read the bpp */
    bpp = getshort(file);
    if (bpp != 24) {
      printf("Bpp from %s is not 24: %u\n", filename, bpp);
      return 0;
    }
	
    /*  seek past the rest of the bitmap header. */
    fseek(file, 24, SEEK_CUR);

    /*  read the data.  */
    image->data = (char *) malloc(size);
    if (image->data == NULL) {
	printf("Error allocating memory for color-corrected image data");
	return 0;	
    }

    if ((i = fread(image->data, size, 1, file)) != 1) {
	printf("Error reading image data from %s.\n", filename);
	return 0;
    }

    for (i=0;i<size;i+=3) { /*  reverse all of the colors. (bgr -> rgb) */
	temp = image->data[i];
	image->data[i] = image->data[i+2];
	image->data[i+2] = temp;
    }

    /*  we're done. */
    return 1;
}

void LoadGLTextures() /* Load Bitmaps And Convert To Textures */
{

    Image *TextureImage[5];
    
    /*  allocate space for texture */
    TextureImage[0] = (Image *) malloc(sizeof(Image));
    TextureImage[1] = (Image *) malloc(sizeof(Image));
    TextureImage[2] = (Image *) malloc(sizeof(Image));
    TextureImage[3] = (Image *) malloc(sizeof(Image));
    TextureImage[4] = (Image *) malloc(sizeof(Image));

	ImageLoad("logo.bmp", TextureImage[0]);
	ImageLoad("mask1.bmp", TextureImage[1]);
	ImageLoad("image1.bmp", TextureImage[2]);
	ImageLoad("mask2.bmp", TextureImage[3]);
	ImageLoad("image2.bmp", TextureImage[4]);

               glGenTextures(5, &texture[0]);          /* Create Five Textures */

			for (loop=0; loop<5; loop++)	/* Loop Through All 5 Textures */
			{
	                glBindTexture(GL_TEXTURE_2D, texture[loop]);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[loop]->sizeX,
                                     TextureImage[loop]->sizeY, 0,
                                     GL_RGB, GL_UNSIGNED_BYTE, TextureImage[loop]->data);
			}

}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height) /* Resize And Initialize The GL Window */
{
	if (height==0)				/* Prevent A Divide By Zero By */
	{
		height=1;			/* Making Height Equal One */
	}

	glViewport(0,0,width,height);		/* Reset The Current Viewport */
	glMatrixMode(GL_PROJECTION);		/* Select The Projection Matrix */
	glLoadIdentity();							/* Reset The Projection Matrix */
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);	/* Calculate Window Aspect Ratio */
	glMatrixMode(GL_MODELVIEW);						/* Select The Modelview Matrix */
	glLoadIdentity();							/* Reset The Modelview Matrix */
}

void InitGL(GLuint width, GLuint height)					/* All Setup For OpenGL Goes Here */
{ 
	LoadGLTextures();				/* Jump To Texture Loading Routine */
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);		/* Clear The Background Color To Black */
	glClearDepth(1.0);				/* Enables Clearing Of The Depth Buffer */
	glEnable(GL_DEPTH_TEST);			/* Enable Depth Testing */
	glShadeModel(GL_SMOOTH);			/* Enables Smooth Color Shading */
	glEnable(GL_TEXTURE_2D);			/* Enable 2D Texture Mapping */
}

void DrawGLScene(GLvoid)	/* Here's Where We Do All The Drawing */
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	/* Clear The Screen And The Depth Buffer */
	glLoadIdentity();					/* Reset The Modelview Matrix */
	glTranslatef(0.0f,0.0f,-2.0f);			/* Move Into The Screen 5 Units */

	glBindTexture(GL_TEXTURE_2D, texture[0]);	/* Select Our Logo Texture */
	glBegin(GL_QUADS);								/* Start Drawing A Textured Quad */
		glTexCoord2f(0.0f, -roll+0.0f); glVertex3f(-1.1f, -1.1f,  0.0f);	/* Bottom Left */
		glTexCoord2f(3.0f, -roll+0.0f); glVertex3f( 1.1f, -1.1f,  0.0f);	/* Bottom Right */
		glTexCoord2f(3.0f, -roll+3.0f); glVertex3f( 1.1f,  1.1f,  0.0f);	/* Top Right */
		glTexCoord2f(0.0f, -roll+3.0f); glVertex3f(-1.1f,  1.1f,  0.0f);	/* Top Left */
	glEnd();									/* Done Drawing The Quad */

	glEnable(GL_BLEND);			/* Enable Blending */
	glDisable(GL_DEPTH_TEST);		/* Disable Depth Testing */

	if (masking)						/* Is Masking Enabled? */
	{
		glBlendFunc(GL_DST_COLOR,GL_ZERO);		/* Blend Screen Color With Zero (Black) */
	}

	if (scene)						/* Are We Drawing The Second Scene? */
	{
		glTranslatef(0.0f,0.0f,-1.0f);			/* Translate Into The Screen One Unit */
		glRotatef(roll*360,0.0f,0.0f,1.0f);		/* Rotate On The Z Axis 360 Degrees. */
		if (masking)					/* Is Masking On? */
		{
			glBindTexture(GL_TEXTURE_2D, texture[3]);	/* Select The Second Mask Texture */
			glBegin(GL_QUADS);							/* Start Drawing A Textured Quad */
				glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f);	/* Bottom Left */
				glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f);	/* Bottom Right */
				glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.1f,  1.1f,  0.0f);	/* Top Right */
				glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.1f,  1.1f,  0.0f);	/* Top Left */
			glEnd();							/* Done Drawing The Quad */
		}

		glBlendFunc(GL_ONE, GL_ONE);				/* Copy Image 2 Color To The Screen */
		glBindTexture(GL_TEXTURE_2D, texture[4]);		/* Select The Second Image Texture */
		glBegin(GL_QUADS);							/* Start Drawing A Textured Quad */
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f);	/* Bottom Left */
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f);	/* Bottom Right */
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.1f,  1.1f,  0.0f);	/* Top Right */
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.1f,  1.1f,  0.0f);	/* Top Left */
		glEnd();							/* Done Drawing The Quad */
	}
	else					/* Otherwise */
	{
		if (masking)			/* Is Masking On? */
		{
			glBindTexture(GL_TEXTURE_2D, texture[1]);	/* Select The First Mask Texture */
			glBegin(GL_QUADS);							/* Start Drawing A Textured Quad */
				glTexCoord2f(roll+0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f);	/* Bottom Left */
				glTexCoord2f(roll+4.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f);	/* Bottom Right */
				glTexCoord2f(roll+4.0f, 4.0f); glVertex3f( 1.1f,  1.1f,  0.0f);	/* Top Right */
				glTexCoord2f(roll+0.0f, 4.0f); glVertex3f(-1.1f,  1.1f,  0.0f);	/* Top Left */
			glEnd();							/* Done Drawing The Quad */
		}

		glBlendFunc(GL_ONE, GL_ONE);				/* Copy Image 1 Color To The Screen */
		glBindTexture(GL_TEXTURE_2D, texture[2]);		/* Select The First Image Texture */
		glBegin(GL_QUADS);					/* Start Drawing A Textured Quad */
			glTexCoord2f(roll+0.0f, 0.0f); glVertex3f(-1.1f, -1.1f,  0.0f);	/* Bottom Left */
			glTexCoord2f(roll+4.0f, 0.0f); glVertex3f( 1.1f, -1.1f,  0.0f);	/* Bottom Right */
			glTexCoord2f(roll+4.0f, 4.0f); glVertex3f( 1.1f,  1.1f,  0.0f);	/* Top Right */
			glTexCoord2f(roll+0.0f, 4.0f); glVertex3f(-1.1f,  1.1f,  0.0f);	/* Top Left */
		glEnd();							/* Done Drawing The Quad */
	}

	glEnable(GL_DEPTH_TEST);		/* Enable Depth Testing */
	glDisable(GL_BLEND);			/* Disable Blending */

	roll+=0.002f;				/* Increase Our Texture Roll Variable */
	if (roll>1.0f)				/* Is Roll Greater Than One */
	{
		roll-=1.0f;			/* Subtract 1 From Roll */
	}

	glutSwapBuffers();
}



/* The function called whenever a normal key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{

    switch (key) {    
    case ESCAPE: /*  kill everything. */
	/* shut down our window */
	glutDestroyWindow(window); 
	
	/* exit the program...normal termination. */
	exit(1);                   	
	break; /*  redundant. */

    case 'o': 
    case 'O': /*  switch the masking textures */
	scene = !scene;
	break;

    case 'm':
    case 'M': 
	masking = !masking;
	break;


    default:
      break;
    }	
}


/* The function called whenever a normal key is pressed. */
void specialKeyPressed(int key, int x, int y) 
{
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
	}
}

/* Routine to save our CPU */
void Icon( int state )
{
	switch (state)
	{
	case GLUT_VISIBLE:
		glutIdleFunc(DrawGLScene); 
		break;
	case GLUT_NOT_VISIBLE:
		glutIdleFunc(NULL); 
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
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);  

    /* get a 640 x 480 window */
    glutInitWindowSize(width,height);  

    /* the window starts at the upper left corner of the screen */
    glutInitWindowPosition(0, 0);  

    /* Open a window */  
    window = glutCreateWindow("Jeff Molofee's GL Code Tutorial ... NeHe '99");  

    /* Register the function to do all our OpenGL drawing. */
    glutDisplayFunc(DrawGLScene);  

    /* Go fullscreen.  This is as soon as possible. */
    /* glutFullScreen(); */

    /* Even if there are no events, redraw our gl scene. */
    glutIdleFunc(DrawGLScene); 

    /* Register the function called when our window is resized. */
    glutReshapeFunc(ReSizeGLScene);

    /* Register the function called when the keyboard is pressed. */
    glutKeyboardFunc(keyPressed);

    /* Register the function called when special keys (arrows, page down, etc) are pressed. */
    glutSpecialFunc(specialKeyPressed);

    /* Use this to save CPU when the scene is obscured/iconised */
    glutVisibilityFunc(Icon);

    /* Initialize our window. */
    InitGL(width,height);
  
    /* Start Event Processing Engine */  
    glutMainLoop();  

    return 1;
}









