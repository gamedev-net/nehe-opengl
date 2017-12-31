/*
 * This Code Was Created By Jeff Molofee and GB Schmick 2000
 * A HUGE Thanks To Fredric Echols For Cleaning Up
 * And Optimizing The Base Code, Making It More Flexible!
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 *
 * Ported to IRIX/GLUT by Rob Fletcher 2000
 * (email me at R.Fletcher@york.ac.uk)
 *
*/
#include <GL/glut.h>    /*  Header File For The GLUT Library */
#include <GL/gl.h>	/*  Header File For The OpenGL Library */
#include <GL/glu.h>	/*  Header File For The GLu Library */
#include <stdio.h>      /*  Header file for standard file i/o.*/
#include <stdlib.h>     /*  Header file for malloc/free. */

int	light;				/* Lighting ON/OFF */

int		part1;			/* Start Of Disc ( NEW ) */
int		part2;			/* End Of Disc ( NEW ) */
int		p1=0;			/* Increase 1 ( NEW ) */
int		p2=1;			/* Increase 2 ( NEW ) */

GLfloat	xrot;				/* X Rotation */
GLfloat	yrot;				/* Y Rotation */
GLfloat xspeed;				/* X Rotation Speed */
GLfloat yspeed;				/* Y Rotation Speed */
GLfloat	z=-5.0f;			/* Depth Into The Screen */

GLUquadricObj *quadratic;	/* Storage For Our Quadratic Objects ( NEW ) */

GLfloat LightAmbient[]=		{ 0.5f, 0.5f, 0.5f, 1.0f };
GLfloat LightDiffuse[]=		{ 1.0f, 1.0f, 1.0f, 1.0f };
GLfloat LightPosition[]=	{ 0.0f, 0.0f, 2.0f, 1.0f };

GLuint	filter;				/* Which Filter To Use */
GLuint	texture[3];			/* Storage For 3 Textures */
GLuint  object=0;			/* Which Object To Draw (NEW) */

/* ascii codes for various special keys */
#define ESCAPE 27

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
/*    printf("Width of %s: %lu\n", filename, image->sizeX);*/
    
    /*  read the height  */
    image->sizeY = getint (file);
/*    printf("Height of %s: %lu\n", filename, image->sizeY);*/
    
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

/* Load Bitmaps And Convert To Textures */

void LoadGLTextures()
{
    Image *TextureImage;
    /*  allocate space for texture */
    TextureImage = (Image *) malloc(sizeof(Image));
    if (TextureImage == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }

	/* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
        ImageLoad("Wall.bmp", TextureImage);
		glGenTextures(3, &texture[0]);	/* Create Three Textures */

		/* Create Nearest Filtered Texture */
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage->sizeX, TextureImage->sizeY, 
                             0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage->data);

		/* Create Linear Filtered Texture */
		glBindTexture(GL_TEXTURE_2D, texture[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage->sizeX, TextureImage->sizeY,
                             0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage->data);

		/* Create MipMapped Texture */
		glBindTexture(GL_TEXTURE_2D, texture[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, 3, TextureImage->sizeX, TextureImage->sizeY,
                                  GL_RGB, GL_UNSIGNED_BYTE, TextureImage->data);
	

}

/* Resize And Initialize The GL Window */
GLvoid ReSizeGLScene(GLsizei width, GLsizei height)
{
	if (height==0)		/* Prevent A Divide By Zero By */
	{
		height=1;	/* Making Height Equal One */
	}

	glViewport(0,0,width,height);		/* Reset The Current Viewport */

	glMatrixMode(GL_PROJECTION);		/* Select The Projection Matrix */
	glLoadIdentity();			/* Reset The Projection Matrix */

	/* Calculate The Aspect Ratio Of The Window */
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);	/* Select The Modelview Matrix */
	glLoadIdentity();		/* Reset The Modelview Matrix */
}

/* All Setup For OpenGL Goes Here */
void InitGL(GLvoid)/* All Setup For OpenGL Goes Here */
{
	LoadGLTextures();	/* Jump To Texture Loading Routine */

	glEnable(GL_TEXTURE_2D);		/* Enable Texture Mapping */
	glShadeModel(GL_SMOOTH);		/* Enable Smooth Shading */
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);	/* Black Background */
	glClearDepth(1.0f);			/* Depth Buffer Setup */
	glEnable(GL_DEPTH_TEST);		/* Enables Depth Testing */
	glDepthFunc(GL_LEQUAL);			/* The Type Of Depth Testing To Do */
  	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	/* Really Nice Perspective Calculations */

	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);		/* Setup The Ambient Light */
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);		/* Setup The Diffuse Light */
	glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);	/* Position The Light */
	glEnable(GL_LIGHT1);					/* Enable Light One */

	quadratic=gluNewQuadric();				/* Create A Pointer To The Quadric Object */
                                                                /*(Return 0 If No Memory) (NEW) */
	gluQuadricNormals(quadratic, GL_SMOOTH);		/* Create Smooth Normals (NEW) */
	gluQuadricTexture(quadratic, GL_TRUE);			/* Create Texture Coords (NEW) */

}

GLvoid glDrawCube()
{
		glBegin(GL_QUADS);
		/* Front Face */
		glNormal3f( 0.0f, 0.0f, 1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		/* Back Face */
		glNormal3f( 0.0f, 0.0f,-1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		/* Top Face */
		glNormal3f( 0.0f, 1.0f, 0.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		/* Bottom Face */
		glNormal3f( 0.0f,-1.0f, 0.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		/* Right Face */
		glNormal3f( 1.0f, 0.0f, 0.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		/* Left Face */
		glNormal3f(-1.0f, 0.0f, 0.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glEnd();
}

/* Here's Where We Do All The Drawing */
void DrawGLScene(GLvoid)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	/* Clear The Screen And The Depth Buffer */
	glLoadIdentity();					/* Reset The View */
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);

	glBindTexture(GL_TEXTURE_2D, texture[filter]);

	switch(object)
	{
	case 0:
		glDrawCube();
		break;
	case 1:
		glTranslatef(0.0f,0.0f,-1.5f);			/* Center The Cylinder */
		gluCylinder(quadratic,1.0f,1.0f,3.0f,32,32);	/* A Cylinder With A Radius Of 0.5
                                                                   And A Height Of 2 */
		break;
	case 2:
		gluDisk(quadratic,0.5f,1.5f,32,32);		/* Draw A Disc (CD Shape) With An 
								   Inner Radius Of 0.5, And An 
								   Outer Radius Of 2.  Plus A Lot Of Segments  */
		break;
	case 3:
		gluSphere(quadratic,1.3f,32,32);		/* Draw A Sphere With A Radius Of 1
								   And 16 Longitude And 16 Latitude Segments */
		break;
	case 4:
		glTranslatef(0.0f,0.0f,-1.5f);			/* Center The Cone */
		gluCylinder(quadratic,1.0f,0.0f,3.0f,32,32);	/* A Cone With A Bottom Radius Of .5 
								   And A Height Of 2 */
		break;
	case 5:
		part1+=p1;
		part2+=p2;

		if(part1>359)			/* 360 Degrees */
		{
			p1=0;
			part1=0;
			p2=1;
			part2=0;
		}
		if(part2>359)			/* 360 Degrees */
		{
			p1=1;
			p2=0;
		}
		gluPartialDisk(quadratic,0.5f,1.5f,32,32,part1,part2-part1);	/* A Disk Like The One Before */
		break;
#ifdef GLUT_API_VERSION
	case 6:
		glutSolidTeapot(1.0);
		break;
#endif
	}

	xrot+=xspeed;
	yrot+=yspeed;

	glutSwapBuffers();	/* Swap buffers because we are in double buffer mode */
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

    case 'l': 
    case 'L': /*  switch the lighting. */
	light = light ? 0 : 1;              /*  switch the current value of light, between 0 and 1. */
	printf("Light is now: %d\n", light);
	if (!light) {
	    glDisable(GL_LIGHTING);
	} else {
	    glEnable(GL_LIGHTING);
	}
	break;

    case 'f':
    case 'F': /*  switch the filter. */
	filter+=1;
	if (filter>2) {
	    filter=0;	
	}	
	printf("Filter is now: %d\n", filter);
	break;

    case 'o': 
    case 'O': /*  switch the blending. */
	object++;
#ifdef GLUT_API_VERSION
	if(object>6)
#else
	if(object>5)
#endif
	object=0;
	printf("Object is: %d\n", object);
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
     case GLUT_KEY_PAGE_UP: /*  move the cube into the distance. */
	z-=0.02f;
	break;
    
    case GLUT_KEY_PAGE_DOWN: /*  move the cube closer. */
	z+=0.02f;
	break;

    case GLUT_KEY_UP: /*  decrease x rotation speed; */
	xspeed-=0.01f;
	break;

    case GLUT_KEY_DOWN: /*  increase x rotation speed; */
	xspeed+=0.01f;
	break;

    case GLUT_KEY_LEFT: /*  decrease y rotation speed; */
	yspeed-=0.01f;
	break;
    
    case GLUT_KEY_RIGHT: /*  increase y rotation speed; */
	yspeed+=0.01f;
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
     Depth buffer */  
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);  

    /* get a 640 x 480 window */
    glutInitWindowSize(640, 480);  

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
    InitGL();
  
    /* Start Event Processing Engine */  
    glutMainLoop();  

    return 1;
}

