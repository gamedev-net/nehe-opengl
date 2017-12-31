/*
 * This Code Was Created By Jeff Molofee 2000
 * And Modified By Giuseppe D'Agata (waveform@tiscalinet.it)
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net
 *
 * Ported to IRIX/GLUT by Rob Fletcher 2000
 * (email me at R.Fletcher@york.ac.uk)
 */

#include <math.h>			/* Header File For Windows Math Library */
#include <stdio.h>			/* Header File For Standard Input/Output */
#include <GL/glut.h>    		/* Header File For The GLUT Library  */
#include <GL/gl.h>			/* Header File For The OpenGL Library */
#include <GL/glu.h>			/* Header File For The GLu Library */


GLuint	base;				/* Base Display List For The Font */
GLuint	texture[2];			/* Storage For Our Font Texture */
GLuint	loop;				/* Generic Loop Variable */

GLfloat	cnt1;				/* 1st Counter Used To Move Text & For Coloring */
GLfloat	cnt2;				/* 2nd Counter Used To Move Text & For Coloring */

/* Image type - contains height, width, and data */
typedef struct {
    unsigned long sizeX;
    unsigned long sizeY;
    char *data;
} Image;

int window;		/* Out GLUT window ID */
/* Used to toggle full screen/window mode */
int fullscreen=0;	/* toggle fullscreen */
int x_position = 50;	/* position on screen */
int y_position = 50;
int width = 640;	/* Size */
int height = 480;

/* ascii codes for various special keys */
#define ESCAPE 27

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
  
  /*get 2 bytes  */
  c = getc(fp);  
  c1 = getc(fp);

  return ((unsigned int) c) + (((unsigned int) c1) << 8);
}

/* quick and dirty bitmap loader...for 24 bit bitmaps with 1 plane only.   */ 
/* See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info.  */
int ImageLoad(char *filename, Image *image) 
{
    FILE *file;
    unsigned long size;                 /* size of the image in bytes.  */
    unsigned long i;                    /* standard counter.  */
    unsigned short int planes;          /* number of planes in image (must be 1)   */
    unsigned short int bpp;             /* number of bits per pixel (must be 24)  */
    char temp;                          /* used to convert bgr to rgb color.  */

    /* make sure the file is there.  */
    if ((file = fopen(filename, "rb"))==NULL) {
      printf("File Not Found : %s\n",filename);
      return 0;
    }
    
    /* seek through the bmp header, up to the width/height:  */
    fseek(file, 18, SEEK_CUR);

    /* No 100% errorchecking anymore!!!  */

    /* read the width  */
    image->sizeX = getint (file);
/*    printf("Width of %s: %lu\n", filename, image->sizeX);*/
    
    /* read the height   */
    image->sizeY = getint (file);
/*    printf("Height of %s: %lu\n", filename, image->sizeY);*/
    
    /* calculate the size (assuming 24 bits or 3 bytes per pixel).  */
    size = image->sizeX * image->sizeY * 3;

    /* read the planes  */
    planes = getshort(file);
    if (planes != 1) {
	printf("Planes from %s is not 1: %u\n", filename, planes);
	return 0;
    }

    /* read the bpp  */
    bpp = getshort(file);
    if (bpp != 24) {
      printf("Bpp from %s is not 24: %u\n", filename, bpp);
      return 0;
    }
	
    /* seek past the rest of the bitmap header.  */
    fseek(file, 24, SEEK_CUR);

    /* read the data.   */
    image->data = (char *) malloc(size);
    if (image->data == NULL) {
	printf("Error allocating memory for color-corrected image data");
	return 0;	
    }

    if ((i = fread(image->data, size, 1, file)) != 1) {
	printf("Error reading image data from %s.\n", filename);
	return 0;
    }

    for (i=0;i<size;i+=3) { /* reverse all of the colors. (bgr -> rgb)  */
	temp = image->data[i];
	image->data[i] = image->data[i+2];
	image->data[i+2] = temp;
    }

    /* we're done.  */
    return 1;
}


/* Load Bitmaps And Convert To Textures  */
void LoadGLTextures()      
{
    Image *TextureImage[2];
    TextureImage[0] = (Image *) malloc(sizeof(Image));
    TextureImage[1] = (Image *) malloc(sizeof(Image));

    if (!ImageLoad("Font.bmp", TextureImage[0])) {
	exit(1);
    }        
    if (!ImageLoad("Bumps.bmp", TextureImage[1])) {
	exit(1);
    }        
              glGenTextures(2, &texture[0]);          /* Create Two Textures  */

			for (loop=0; loop<2; loop++)
			{
	                glBindTexture(GL_TEXTURE_2D, texture[loop]);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[loop]->sizeX, 
                                     TextureImage[loop]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE,
                                     TextureImage[loop]->data);
				}
}

/* Build Our Font Display List  */
GLvoid BuildFont(GLvoid) 
{
	float	cx;				/* Holds Our X Character Coord  */
	float	cy;				/* Holds Our Y Character Coord  */

	base=glGenLists(256);				/* Creating 256 Display Lists  */
	glBindTexture(GL_TEXTURE_2D, texture[0]);	/* Select Our Font Texture  */
	for (loop=0; loop<256; loop++)			/* Loop Through All 256 Lists  */
	{
		cx=(float)(loop%16)/16.0f;		/* X Position Of Current Character  */
		cy=(float)(loop/16)/16.0f;		/* Y Position Of Current Character  */

		glNewList(base+loop,GL_COMPILE);	/* Start Building A List  */
			glBegin(GL_QUADS);		/* Use A Quad For Each Character  */
				glTexCoord2f(cx,1-cy-0.0625f);		/* Texture Coord (Bottom Left)  */
				glVertex2i(0,0);			/* Vertex Coord (Bottom Left)  */
				glTexCoord2f(cx+0.0625f,1-cy-0.0625f);	/* Texture Coord (Bottom Right)  */
				glVertex2i(16,0);			/* Vertex Coord (Bottom Right)  */
				glTexCoord2f(cx+0.0625f,1-cy);		/* Texture Coord (Top Right)  */
				glVertex2i(16,16);			/* Vertex Coord (Top Right)  */
				glTexCoord2f(cx,1-cy);			/* Texture Coord (Top Left)  */
				glVertex2i(0,16);			/* Vertex Coord (Top Left)  */
			glEnd();					/* Done Building Our Quad (Character)  */
			glTranslated(10,0,0);				/* Move To The Right Of The Character  */
		glEndList();						/* Done Building The Display List  */
	}								/* Loop Until All 256 Are Built  */
}

/* Delete The Font From Memory  */
GLvoid KillFont(GLvoid)	
{
	glDeleteLists(base,256);	/* Delete All 256 Display Lists  */
}

/* Where The Printing Happens  */
GLvoid glPrint(GLint x, GLint y, char *string, int set)	
{
	if (set>1)
	{
		set=1;
	}
	glBindTexture(GL_TEXTURE_2D, texture[0]);	/* Select Our Font Texture  */
	glDisable(GL_DEPTH_TEST);			/* Disables Depth Testing  */
	glMatrixMode(GL_PROJECTION);			/* Select The Projection Matrix  */
	glPushMatrix();					/* Store The Projection Matrix  */
	glLoadIdentity();				/* Reset The Projection Matrix  */
	glOrtho(0,640,0,480,-100,100);			/* Set Up An Ortho Screen  */
	glMatrixMode(GL_MODELVIEW);			/* Select The Modelview Matrix  */
	glPushMatrix();					/* Store The Modelview Matrix  */
	glLoadIdentity();				/* Reset The Modelview Matrix  */
	glTranslated(x,y,0);				/* Position The Text (0,0 - Bottom Left)  */
	glListBase(base-32+(128*set));			/* Choose The Font Set (0 or 1)  */
	glCallLists(strlen(string),GL_BYTE,string);	/* Write The Text To The Screen  */
	glMatrixMode(GL_PROJECTION);			/* Select The Projection Matrix  */
	glPopMatrix();					/* Restore The Old Projection Matrix  */
	glMatrixMode(GL_MODELVIEW);			/* Select The Modelview Matrix  */
	glPopMatrix();					/* Restore The Old Projection Matrix  */
	glEnable(GL_DEPTH_TEST);			/* Enables Depth Testing  */
}

/* Resize And Initialize The GL Window  */
GLvoid ReSizeGLScene(GLsizei width, GLsizei height)
{
	if (height==0)			/* Prevent A Divide By Zero By  */
	{
		height=1;		/* Making Height Equal One  */
	}
	glViewport(0,0,width,height);			/* Reset The Current Viewport  */
	glMatrixMode(GL_PROJECTION);			/* Select The Projection Matrix  */
	glLoadIdentity();				/* Reset The Projection Matrix  */
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);	/* Calculate Window Aspect Ratio  */
	glMatrixMode(GL_MODELVIEW);						/* Select The Modelview Matrix  */
	glLoadIdentity();							/* Reset The Modelview Matrix  */
}

/* All Setup For OpenGL Goes Here  */
void InitGL(GLsizei Width, GLsizei Height)
{
LoadGLTextures();
	BuildFont();				/* Build The Font  */
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);	/* Clear The Background Color To Black  */
	glClearDepth(1.0);			/* Enables Clearing Of The Depth Buffer  */
	glDepthFunc(GL_LEQUAL);			/* The Type Of Depth Test To Do  */
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);	/* Select The Type Of Blending  */
	glShadeModel(GL_SMOOTH);		/* Enables Smooth Color Shading  */
	glEnable(GL_TEXTURE_2D);		/* Enable 2D Texture Mapping  */
}

/* Here's Where We Do All The Drawing  */
void DrawGLScene(GLvoid)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	/* Clear The Screen And The Depth Buffer  */
	glLoadIdentity();					/* Reset The Modelview Matrix  */
	glBindTexture(GL_TEXTURE_2D, texture[1]);		/* Select Our Second Texture  */
	glTranslatef(0.0f,0.0f,-5.0f);				/* Move Into The Screen 5 Units  */
	glRotatef(45.0f,0.0f,0.0f,1.0f);			/* Rotate On The Z Axis 45 Degrees (Clockwise)  */
	glRotatef(cnt1*30.0f,1.0f,1.0f,0.0f);			/* Rotate On The X & Y Axis By cnt1 (Left To Right)  */
	glDisable(GL_BLEND);					/* Disable Blending Before We Draw In 3D  */
	glColor3f(1.0f,1.0f,1.0f);				/* Bright White  */
	glBegin(GL_QUADS);					/* Draw Our First Texture Mapped Quad  */
		glTexCoord2d(0.0f,0.0f);			/* First Texture Coord  */
		glVertex2f(-1.0f, 1.0f);			/* First Vertex  */
		glTexCoord2d(1.0f,0.0f);			/* Second Texture Coord  */
		glVertex2f( 1.0f, 1.0f);			/* Second Vertex  */
		glTexCoord2d(1.0f,1.0f);			/* Third Texture Coord  */
		glVertex2f( 1.0f,-1.0f);			/* Third Vertex  */
		glTexCoord2d(0.0f,1.0f);			/* Fourth Texture Coord  */
		glVertex2f(-1.0f,-1.0f);			/* Fourth Vertex  */
	glEnd();					/* Done Drawing The First Quad  */
	glRotatef(90.0f,1.0f,1.0f,0.0f);			/* Rotate On The X & Y Axis By 90 Degrees (Left To Right)  */
	glBegin(GL_QUADS);					/* Draw Our Second Texture Mapped Quad  */
		glTexCoord2d(0.0f,0.0f);			/* First Texture Coord  */
		glVertex2f(-1.0f, 1.0f);			/* First Vertex  */
		glTexCoord2d(1.0f,0.0f);			/* Second Texture Coord  */
		glVertex2f( 1.0f, 1.0f);			/* Second Vertex  */
		glTexCoord2d(1.0f,1.0f);			/* Third Texture Coord  */
		glVertex2f( 1.0f,-1.0f);			/* Third Vertex  */
		glTexCoord2d(0.0f,1.0f);			/* Fourth Texture Coord  */
		glVertex2f(-1.0f,-1.0f);			/* Fourth Vertex  */
	glEnd();					/* Done Drawing Our Second Quad  */
	glEnable(GL_BLEND);				/* Enable Blending  */

	glLoadIdentity();				/* Reset The View  */
	/* Pulsing Colors Based On Text Position  */
	glColor3f(1.0f*(float)(cos(cnt1)),1.0f*(float)(sin(cnt2)),1.0f-0.5f*(float)(cos(cnt1+cnt2)));
	glPrint((int)((280+250*cos(cnt1))),(int)(235+200*sin(cnt2)),"NeHe",0);		/* Print GL Text To The Screen  */

	glColor3f(1.0f*(float)(sin(cnt2)),1.0f-0.5f*(float)(cos(cnt1+cnt2)),1.0f*(float)(cos(cnt1)));
	glPrint((int)((280+230*cos(cnt2))),(int)(235+200*sin(cnt1)),"OpenGL",1);	/* Print GL Text To The Screen  */

	glColor3f(0.0f,0.0f,1.0f);
	glPrint((int)(240+200*cos((cnt2+cnt1)/5)),2,"Giuseppe D'Agata",0);

	glColor3f(1.0f,1.0f,1.0f);
	glPrint((int)(242+200*cos((cnt2+cnt1)/5)),2,"Giuseppe D'Agata",0);

	cnt1+=0.01f;			/* Increase The First Counter  */
	cnt2+=0.0081f;			/* Increase The Second Counter  */

	glutSwapBuffers();		/* Swap, using GLUT routine */
}





/* The function called whenever a normal key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
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
     Depth buffer  */  
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);  

    /* get a 640 x 480 window */
    glutInitWindowSize(width,height);  

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

    /* Use this to save CPU when the scene is obscured/iconised */
    glutVisibilityFunc(Icon);

    /* Initialize our window. */
    InitGL(width,height);
  
    /* Start Event Processing Engine */  
    glutMainLoop();  

    return 1;
}
