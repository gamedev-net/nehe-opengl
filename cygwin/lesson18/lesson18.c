/* 
 * Simon Werner, 23.07.2000
 * 
 * OpenGL lesson 18. This lesson is the Linux version based on lesson 18 
 * written by NeHe (Jeff Molofee), http://nehe.gamedev.net/ . It is also 
 * based on other ports done by Richard Campbell. This code includes snippets 
 * from lessons 5, 6, 7 and 8. 
 * 
 * Usage:
 * 		make lessonX
 * 		
 * 	where X = lesson number
 * 
 */

#include <GL/glut.h>				// Header for the GLUT library
#include <GL/gl.h>                  // Header File For The OpenGL32 Library
#include <GL/glu.h>                 // Header File For The GLu32 Library
#include <unistd.h>					// Header for sleeping
#include <stdio.h>					// Standard IO header
#include <stdlib.h>					// Header file for malloc/free

/* ascii code for various keys */
#define ESCAPE 27
#define PAGE_UP 73
#define PAGE_DOWN 81
#define UP_ARROW 72
#define DOWN_ARROW 80
#define LEFT_ARROW 75
#define RIGHT_ARROW 77

int 	window; 		// The number of our GLUT window

int     light;			// Lighting ON/OFF
int	blend;			// Toggle blending

int     part1;			// Start Of Disc 
int     part2;			// End Of Disc     
int     p1=0;			// Increase 1
int     p2=1;			// Increase 2

GLuint	filter;			// Which Filter To Use (nearest/linear/mipmapped)
GLuint	texture[3];		// Storage for 3 textures.
GLuint  object=0;		// Which object to draw

GLfloat xrot;			// X Rotation
GLfloat yrot;			// Y Rotation
GLfloat xspeed;			// x rotation speed
GLfloat yspeed;			// y rotation speed
GLfloat z=-5.0f;		// depth into the screen.


GLUquadricObj *quadratic;	// Storage For Our Quadratic Objects

/* white ambient light at half intensity (rgba) */
GLfloat LightAmbient[] = { 0.5f, 0.5f, 0.5f, 1.0f };

/* super bright, full intensity diffuse light. */
GLfloat LightDiffuse[] = { 1.0f, 1.0f, 1.0f, 1.0f };

/* position of light (x, y, z, (position of light)) */
GLfloat LightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };


/* Image type - contains height, width and data */
struct Image {
	unsigned long sizeX;
	unsigned long sizeY;
	char *data;
};
typedef struct Image Image;


// Draws the cube
GLvoid DrawCube() {

    glBegin(GL_QUADS);		                // begin drawing a cube
    
	    // Front Face (note that the texture's corners have to match the quad's corners)
	    glNormal3f( 0.0f, 0.0f, 1.0f);                              // front face points out of the screen on z.
	    glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);	// Bottom Left Of The Texture and Quad
	    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);	// Bottom Right Of The Texture and Quad
	    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);	// Top Right Of The Texture and Quad
	    glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);	// Top Left Of The Texture and Quad
	    
	    // Back Face
	    glNormal3f( 0.0f, 0.0f,-1.0f);                              // back face points into the screen on z.
	    glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);	// Bottom Right Of The Texture and Quad
	    glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);	// Top Right Of The Texture and Quad
	    glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);	// Top Left Of The Texture and Quad
	    glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);	// Bottom Left Of The Texture and Quad
		
	    // Top Face
	    glNormal3f( 0.0f, 1.0f, 0.0f);                              // top face points up on y.
	    glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);	// Top Left Of The Texture and Quad
	    glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);	// Bottom Left Of The Texture and Quad
	    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);	// Bottom Right Of The Texture and Quad
	    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);	// Top Right Of The Texture and Quad
	    
	    // Bottom Face       
	    glNormal3f( 0.0f, -1.0f, 0.0f);                             // bottom face points down on y. 
	    glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);	// Top Right Of The Texture and Quad
	    glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);	// Top Left Of The Texture and Quad
	    glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);	// Bottom Left Of The Texture and Quad
	    glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);	// Bottom Right Of The Texture and Quad
	    
	    // Right face
	    glNormal3f( 1.0f, 0.0f, 0.0f);                              // right face points right on x.
	    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);	// Bottom Right Of The Texture and Quad
	    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);	// Top Right Of The Texture and Quad
	    glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);	// Top Left Of The Texture and Quad
	    glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);	// Bottom Left Of The Texture and Quad
	    
	    // Left Face
	    glNormal3f(-1.0f, 0.0f, 0.0f);                              // left face points left on x.
	    glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);	// Bottom Left Of The Texture and Quad
	    glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);	// Bottom Right Of The Texture and Quad
	    glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);	// Top Right Of The Texture and Quad
	    glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);	// Top Left Of The Texture and Quad
	  
    glEnd();                            // done with the polygon.

}

/* The main drawing function. */
GLvoid DrawGLScene(GLvoid)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear The Screen And The Depth Buffer
    glLoadIdentity();					// Reset The View

    glTranslatef(0.0f,0.0f,z);          // move 5 units into the screen.
    
    glRotatef(xrot,1.0f,0.0f,0.0f);		// Rotate On The X Axis
    glRotatef(yrot,0.0f,1.0f,0.0f);		// Rotate On The Y Axis

    glBindTexture(GL_TEXTURE_2D, texture[filter]);   // choose the texture to use.

	switch( object )					// Check object To Find Out What To Draw
	{
	case 0:								// Drawing object
		DrawCube();						// Draw the cube
		break;							// Done
		
	case 1:								// Drawing object 2
		glTranslatef(0.0f,0.0f,-1.5f);	// Center the cylinder
        gluCylinder(quadratic,1.0f,1.0f,3.0f,32,32);    // Draw Our Cylinder
        break;                                          // Done

    case 2:                                             // Drawing Object 3
        gluDisk(quadratic,0.5f,1.5f,32,32);             // Draw A Disc (CD Shape)
        break;                                          // Done

    case 3:                                             // Drawing Object 4
        gluSphere(quadratic,1.3f,32,32);                // Draw A Sphere
        break;                                          // Done

    case 4:                                             // Drawing Object 5
        glTranslatef(0.0f,0.0f,-1.5f);                  // Center The Cone
        gluCylinder(quadratic,1.0f,0.2f,3.0f,32,32);    // A Cone With A Bottom Radius Of .5 And A Height Of 2
        break;                                          // Done

    case 5:                                             // Drawing Object 6
        part1+=p1;                                      // Increase Start Angle
        part2+=p2;                                      // Increase Sweep Angle

        if(part1>359) {                                 // 360 Degrees
             p1=0;                                      // Stop Increasing Start Angle
             part1=0;                                   // Set Start Angle To Zero
             p2=1;                                      // Start Increasing Sweep Angle
             part2=0;                                   // Start Sweep Angle At Zero
        }

        if(part2>359) {                                 // 360 Degrees
             p1=1;                                      // Start Increasing Start Angle
             p2=0;                                      // Stop Increasing Sweep Angle
        }

        gluPartialDisk(quadratic,0.5f,1.5f,32,32,part1,part2-part1);    // A Disk Like The One Before
        break;                                          // Done
        };

    xrot+=xspeed;		                // X Axis Rotation	
    yrot+=yspeed;		                // Y Axis Rotation

    // since this is double buffered, swap the buffers to display what just got drawn.
    glutSwapBuffers();

}

// Load an image from .BMP file
int ImageLoad(char *filename, Image *image) {
    FILE *file;
    unsigned long size;                 // size of the image in bytes.
    unsigned long i;                    // standard counter.
    unsigned short int planes;          // number of planes in image (must be 1) 
    unsigned short int bpp;             // number of bits per pixel (must be 24)
    char temp;                          // used to convert bgr to rgb color.

	// Make sure the file exists
	if ((file = fopen(filename, "rb"))==NULL)
	{
		printf("File Not Found : %s\n",filename);
		return 0;
	}

	// Skip to bmp header
	fseek(file,18, SEEK_CUR);

	// read width
	if ((i = fread(&image->sizeX, 4, 1, file)) != 1) {
		printf("Error reading width from %s.\n", filename);
		return 0;
	}
	printf("Width of %s: %lu\n",filename, image->sizeX);

	//read the height
	if ((i = fread(&image->sizeY,4,1,file)) != 1) {
		printf("Error reading height from %s.\n", filename);
		return 0;
	}
	printf("Height of %s: %lu\n", filename, image->sizeY);

	// calculate the size (assuming 24 bpp)
	size = image->sizeX * image->sizeY * 3;

	// read the planes
	if ((fread(&planes, 2, 1, file)) != 1) {
		printf("Error reading planes from %s. \n", filename);
		return 0;
	}

	if (planes != 1) {
		printf("Planes from %s is not 1: %u\n", filename, planes);
		return 0;
	}

	// read the bpp
	if ((i = fread(&bpp, 2, 1, file)) != 1) {
		printf("Error reading bpp from %s. \n", filename);
		return 0;
	}

	if (bpp != 24) {
		printf("Bpp from %s is not 24: %u\n", filename, bpp);
		return 0;
	}

	// seek past the rest of the bitmap header
	fseek(file, 24, SEEK_CUR);

	// Read the data
	image->data = (char *) malloc(size);
	if (image->data == NULL) {
		printf("Error allocating memory for colour-corrected image data");
		return 0;
	}

	if ((i = fread(image->data,size,1,file)) != 1) {
		printf("Error reading image data from %s.\n", filename);
		return 0;
	}

	// reverse all of the colours bgr => rgb)
	for (i=0;i<size;i+=3) {
		temp = image->data[i];
		image->data[i] = image->data[i+2];
		image->data[i+2] = temp;
	}

	// Thats all folks
	return 1;

}


// Load texture into memory
GLvoid LoadGLTextures(GLvoid) {

	// Stores the texture
	Image *image1;

	// Allocate space for texture
	image1 = (Image *) malloc(sizeof(Image));
	if (image1 == NULL) {
		printf("Error allocating space for image");
		exit(0);
	}

	if (!ImageLoad("./Data/lesson18/crate.bmp", image1)) {
		exit(1);
	}

	// create Texture
    glGenTextures(3, &texture[0]);

    // texture 1 (poor quality scaling)
    glBindTexture(GL_TEXTURE_2D, texture[0]);   // 2d texture (x and y size)

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); // cheap scaling when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST); // cheap scaling when image smalled than texture

    // 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image, 
    // border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->sizeX, image1->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->data);

    // texture 2 (linear scaling)
    glBindTexture(GL_TEXTURE_2D, texture[1]);   // 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); // scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); // scale linearly when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->sizeX, image1->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->data);

    // texture 3 (mipmapped scaling)
    glBindTexture(GL_TEXTURE_2D, texture[2]);   // 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); // scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST); // scale linearly + mipmap when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->sizeX, image1->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->data);

    // 2d texture, 3 colors, width, height, RGB in that order, byte data, and the data.
    gluBuild2DMipmaps(GL_TEXTURE_2D, 3, image1->sizeX, image1->sizeY, GL_RGB, GL_UNSIGNED_BYTE, image1->data); 

}

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
GLvoid InitGL(GLsizei Width, GLsizei Height)	// We call this right after our OpenGL window is created.
{
	LoadGLTextures();					// Load the textures
	glEnable(GL_TEXTURE_2D);			// Enable texture mapping

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);	// This Will Clear The Background Color To Black
  	glClearDepth(1.0);					// Enables Clearing Of The Depth Buffer
  	glDepthFunc(GL_LESS);				// The Type Of Depth Test To Do
  	glEnable(GL_DEPTH_TEST);			// Enables Depth Testing
  	glShadeModel(GL_SMOOTH);			// Enables Smooth Color Shading

  	glMatrixMode(GL_PROJECTION);
  	glLoadIdentity();					// Reset The Projection Matrix

  	gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);	// Calculate The Aspect Ratio Of The Window

  	glMatrixMode(GL_MODELVIEW);
  
    // set up light number 1.
    glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);  	// add lighting. (ambient)
    glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);  	// add lighting. (diffuse).
    glLightfv(GL_LIGHT1, GL_POSITION,LightPosition); 	// set light position.
    glEnable(GL_LIGHT1);                             	// turn light 1 on.

    /* setup blending */
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);			// Set The Blending Function For Translucency
    glColor4f(1.0f, 1.0f, 1.0f, 0.5);

    quadratic=gluNewQuadric();                  // Create A Pointer To The Quadric Object ( NEW )

    // Can also use GLU_NONE, GLU_FLAT
    gluQuadricNormals(quadratic, GLU_SMOOTH);   // Create Smooth Normals
    gluQuadricTexture(quadratic, GL_TRUE);      // Create Texture Coords ( NEW )
   
}


/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
GLvoid ReSizeGLScene(GLsizei Width, GLsizei Height)
{
    if (Height==0)						// Prevent A Divide By Zero If The Window Is Too Small
	Height=1;

    glViewport(0, 0, Width, Height);	// Reset The Current Viewport And Perspective Transformation

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    gluPerspective(45.0f, (GLfloat)Width / (GLfloat)Height, 0.1f, 100.0f);
    glMatrixMode(GL_MODELVIEW);
}


/* The function called whenever a key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
    /* avoid thrashing this procedure */
    usleep(100);

    switch (key) { 
    case 'Q':
    case 'q':  
    case ESCAPE: // kill everything.
		/* shut down our window */
		glutDestroyWindow(window); 
	
		/* exit the program...normal termination. */
		exit(1);                   	
	break; // redundant.

    case 'l': 
    case 'L': // switch the lighting.
		printf("L/l pressed; light is: %d\n", light);
		light = light ? 0 : 1;              // switch the current value of light, between 0 and 1.
		printf("Light is now: %d\n", light);
		if (!light) {
	    	glDisable(GL_LIGHTING);
		} else {
	    	glEnable(GL_LIGHTING);
		}
	break;

    case 'F':
    case 'f': // switch the filter.
		printf("F/f pressed; filter is: %d\n", filter);
		filter+=1;
		if (filter>2) 
			filter=0;		
		printf("Filter is now: %d\n", filter);
	break;
	
    case 'b': 
    case 'B':							// switch the blending.
		printf("B/b pressed; blending is: %d\n", blend);
		blend = blend ? 0 : 1;			// switch the current value of blend, between 0 and 1.
		printf("Blend is now: %d\n", blend);
		if (!blend) {
			glDisable(GL_BLEND);		// Turn Blending Off
			glEnable(GL_DEPTH_TEST);	// Turn Depth Testing On
		} else {
			glEnable(GL_BLEND);			// Turn Blending On
			glDisable(GL_DEPTH_TEST);	// Turn Depth Testing Off
		}
	break;

	case ' ':						// Is Spacebar Being Pressed?
    	object++;					// Cycle Through The Objects
    	if(object>5)				// Is object Greater Than 5?
        	object=0;				// If So, Set To Zero
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
    case GLUT_KEY_PAGE_UP: // move the cube into the distance.
		z-=0.02f;
	break;
    
    case GLUT_KEY_PAGE_DOWN: // move the cube closer.
		z+=0.02f;
	break;

    case GLUT_KEY_UP: // decrease x rotation speed;
		xspeed-=0.01f;
	break;

    case GLUT_KEY_DOWN: // increase x rotation speed;
		xspeed+=0.01f;
	break;

    case GLUT_KEY_LEFT: // decrease y rotation speed;
		yspeed-=0.01f;
	break;
    
    case GLUT_KEY_RIGHT: // increase y rotation speed;
		yspeed+=0.01f;
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
     Alpha components supported (use GLUT_ALPHA)
     Depth buffer */  
  glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE |  GLUT_DEPTH );  

  /* get a 640 x 480 window */
  glutInitWindowSize(640, 480);  

  /* the window starts at the upper left corner of the screen */
  glutInitWindowPosition(0, 0);  

  /* Open a window */  
  window = glutCreateWindow("My GL Tutorial");  

  /* Register the function to do all our OpenGL drawing. */
  glutDisplayFunc(&DrawGLScene);  

  /* Go fullscreen.  This is as soon as possible. */
//  glutFullScreen();

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
