//
// This code was created by Jeff Molofee '99 (ported to Linux/GLUT by Kah-Wah Tang 2002 with help from the lesson 1 basecode for Linux by Richard Campbell)
//
// If you've found this code useful, please let me know.
//
// Visit me at www.xs4all.nl/~chtang 
// (email Kah-Wah Tang at tombraider28@hotmail.com)
//
#include <GL/glut.h>    // Header File For The GLUT Library 
#include <GL/gl.h>	// Header File For The OpenGL32 Library
#include <GL/glu.h>	// Header File For The GLu32 Library
#include <unistd.h>     // Header file for sleeping.
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
/* ascii code for the escape key */
#define ESCAPE 27

#define FALSE 0
#define TRUE 1

/* The number of our GLUT window */
int window; 

#ifndef CDS_FULLSCREEN											// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4										// Compilers. By Defining It This Way,
#endif															// We Can Avoid Errors

// User Defined Structures
typedef struct tagMATRIX										// A Structure To Hold An OpenGL Matrix ( NEW )
{
	float Data[16];												// We Use [16] Due To OpenGL's Matrix Format ( NEW )
}
MATRIX;

typedef struct tagVECTOR										// A Structure To Hold A Single Vector ( NEW )
{
	float X, Y, Z;												// The Components Of The Vector ( NEW )
}
VECTOR;

typedef struct tagVERTEX										// A Structure To Hold A Single Vertex ( NEW )
{
	VECTOR Nor;													// Vertex Normal ( NEW )
	VECTOR Pos;													// Vertex Position ( NEW )
}
VERTEX;

typedef struct tagPOLYGON										// A Structure To Hold A Single Polygon ( NEW )
{
	VERTEX Verts[3];											// Array Of 3 VERTEX Structures ( NEW )
}
POLYGON;

// User Defined Variables
bool	outlineDraw	= true;								// Flag To Draw The Outline ( NEW )
bool	outlineSmooth	= false;							// Flag To Anti-Alias The Lines ( NEW )
float	outlineColor[3]	= { 0.0f, 0.0f, 0.0f };				// Color Of The Lines ( NEW )
float	outlineWidth	= 3.0f;								// Width Of The Lines ( NEW )



VECTOR	lightAngle;											// The Direction Of The Light ( NEW )
bool	lightRotate	= false;							// Flag To See If We Rotate The Light ( NEW )

float	modelAngle	= 0.0f;								// Y-Axis Angle Of The Model ( NEW )
bool    modelRotate	= true;							// Flag To Rotate The Model ( NEW )

POLYGON	*polyData	= NULL;								// Polygon Data ( NEW )
int	polyNum		= 0;								// Number Of Polygons ( NEW )

GLuint	shaderTexture[1];									// Storage For One Texture ( NEW )

// File Functions
bool ReadMesh(void)	// Reads The Contents Of The "model.txt" File ( NEW )
{
	FILE *In = fopen ("Data/Model.txt", "rb");					// Open The File ( NEW )

	if (!In)
		return FALSE;											// Return FALSE If File Not Opened ( NEW )

	fread (&polyNum, sizeof (int), 1, In);						// Read The Header (i.e. Number Of Polygons) ( NEW )

	polyData = new POLYGON [polyNum];							// Allocate The Memory ( NEW )

	fread (&polyData[0], sizeof (POLYGON) * polyNum, 1, In);	// Read In All Polygon Data ( NEW )

	fclose (In);												// Close The File ( NEW )

	return TRUE;												// It Worked ( NEW )
}

// Math Functions
inline float DotProduct (VECTOR &V1, VECTOR &V2)				// Calculate The Angle Between The 2 Vectors ( NEW )
{
	return V1.X * V2.X + V1.Y * V2.Y + V1.Z * V2.Z;				// Return The Angle ( NEW )
}

inline float Magnitude (VECTOR &V)								// Calculate The Length Of The Vector ( NEW )
{
	return sqrtf (V.X * V.X + V.Y * V.Y + V.Z * V.Z);			// Return The Length Of The Vector ( NEW )
}

void Normalize (VECTOR &V)										// Creates A Vector With A Unit Length Of 1 ( NEW )
{
	float M = Magnitude (V);									// Calculate The Length Of The Vector  ( NEW )

	if (M != 0.0f)												// Make Sure We Don't Divide By 0  ( NEW )
	{
		V.X /= M;												// Normalize The 3 Components  ( NEW )
		V.Y /= M;
		V.Z /= M;
	}
}

void RotateVector (MATRIX &M, VECTOR &V, VECTOR &D)				// Rotate A Vector Using The Supplied Matrix ( NEW )
{
	D.X = (M.Data[0] * V.X) + (M.Data[4] * V.Y) + (M.Data[8]  * V.Z);	// Rotate Around The X Axis ( NEW )
	D.Y = (M.Data[1] * V.X) + (M.Data[5] * V.Y) + (M.Data[9]  * V.Z);	// Rotate Around The Y Axis ( NEW )
	D.Z = (M.Data[2] * V.X) + (M.Data[6] * V.Y) + (M.Data[10] * V.Z);	// Rotate Around The Z Axis ( NEW )
}


/* A general OpenGL initialization function.  Sets all of the initial parameters. */
bool InitGL(int Width, int Height)	        // We call this right after our OpenGL window is created.
{

  int i;														// Looping Variable ( NEW )
  char Line[255];												// Storage For 255 Characters ( NEW )
  float shaderData[32][3];									// Storate For The 96 Shader Values ( NEW )
  
  FILE *In	= NULL;											// File Pointer ( NEW )

  //g_window	= window;
  //g_keys	= keys;

  // Start Of User Initialization
  glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Realy Nice perspective calculations
	
  glClearColor (0.7f, 0.7f, 0.7f, 0.0f);						// Light Grey Background
  glClearDepth (1.0f);										// Depth Buffer Setup

  glEnable (GL_DEPTH_TEST);									// Enable Depth Testing
  glDepthFunc (GL_LESS);										// The Type Of Depth Test To Do

  glShadeModel (GL_SMOOTH);									// Enables Smooth Color Shading ( NEW )
  glDisable (GL_LINE_SMOOTH);									// Initially Disable Line Smoothing ( NEW )

  glEnable (GL_CULL_FACE);									// Enable OpenGL Face Culling ( NEW )

  glDisable (GL_LIGHTING);									// Disable OpenGL Lighting ( NEW )

  In = fopen ("Data/Shader.txt", "r");						// Open The Shader File ( NEW )

  if (In)														// Check To See If The File Opened ( NEW )
  {
    for (i = 0; i < 32; i++)								// Loop Though The 32 Greyscale Values ( NEW )
    {
      if (feof (In))										// Check For The End Of The File ( NEW )
        break;

      fgets (Line, 255, In);								// Get The Current Line ( NEW )

      shaderData[i][0] = shaderData[i][1] = shaderData[i][2] = float(atof(Line)); // Copy Over The Value ( NEW )
    }

    fclose (In);											// Close The File ( NEW )
  }

  else
    return FALSE;											// It Went Horribly Horribly Wrong ( NEW )

  glGenTextures (1, &shaderTexture[0]);						// Get A Free Texture ID ( NEW )

  glBindTexture (GL_TEXTURE_1D, shaderTexture[0]);			// Bind This Texture. From Now On It Will Be 1D ( NEW )

  // For Crying Out Loud Don't Let OpenGL Use Bi/Trilinear Filtering! ( NEW )
  glTexParameteri (GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);	
  glTexParameteri (GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  glTexImage1D (GL_TEXTURE_1D, 0, GL_RGB, 32, 0, GL_RGB , GL_FLOAT, shaderData);	// Upload ( NEW )

  lightAngle.X = 0.0f;										// Set The X Direction ( NEW )
  lightAngle.Y = 0.0f;										// Set The Y Direction ( NEW )
  lightAngle.Z = 1.0f;										// Set The Z Direction ( NEW )

  Normalize (lightAngle);
										// Normalize The Light Direction ( NEW )
  return ReadMesh ();
}

/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
void ReSizeGLScene(int Width, int Height)
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
void DrawGLScene()
{
	int i, j;													// Looping Variables ( NEW )

	float TmpShade;												// Temporary Shader Value ( NEW )

	MATRIX TmpMatrix;											// Temporary MATRIX Structure ( NEW )
	VECTOR TmpVector, TmpNormal;								// Temporary VECTOR Structures ( NEW )
	
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear The Buffers
	glLoadIdentity ();											// Reset The Matrix

	if (outlineSmooth)											// Check To See If We Want Anti-Aliased Lines ( NEW )
	{
		glHint (GL_LINE_SMOOTH_HINT, GL_NICEST);				// Use The Good Calculations ( NEW )
		glEnable (GL_LINE_SMOOTH);								// Enable Anti-Aliasing ( NEW )
	}

	else														// We Don't Want Smooth Lines ( NEW )
		glDisable (GL_LINE_SMOOTH);								// Disable Anti-Aliasing ( NEW )

	glTranslatef (0.0f, 0.0f, -2.0f);							// Move 2 Units Away From The Screen ( NEW )
	glRotatef (modelAngle, 0.0f, 1.0f, 0.0f);					// Rotate The Model On It's Y-Axis ( NEW )

	glGetFloatv (GL_MODELVIEW_MATRIX, TmpMatrix.Data);			// Get The Generated Matrix ( NEW )

	// Cel-Shading Code //
	glEnable (GL_TEXTURE_1D);									// Enable 1D Texturing ( NEW )
	glBindTexture (GL_TEXTURE_1D, shaderTexture[0]);			// Bind Our Texture ( NEW )

	glColor3f (1.0f, 1.0f, 1.0f);								// Set The Color Of The Model ( NEW )

	glBegin (GL_TRIANGLES);										// Tell OpenGL That We're Drawing Triangles

		for (i = 0; i < polyNum; i++)							// Loop Through Each Polygon ( NEW )
		{
			for (j = 0; j < 3; j++)								// Loop Through Each Vertex ( NEW )
			{
				TmpNormal.X = polyData[i].Verts[j].Nor.X;		// Fill Up The TmpNormal Structure With
				TmpNormal.Y = polyData[i].Verts[j].Nor.Y;		// The Current Vertices' Normal Values ( NEW )
				TmpNormal.Z = polyData[i].Verts[j].Nor.Z;

				RotateVector (TmpMatrix, TmpNormal, TmpVector);	// Rotate This By The Matrix ( NEW )

				Normalize (TmpVector);							// Normalize The New Normal ( NEW )

				TmpShade = DotProduct (TmpVector, lightAngle);	// Calculate The Shade Value ( NEW )

				if (TmpShade < 0.0f)
					TmpShade = 0.0f;							// Clamp The Value to 0 If Negative ( NEW )

				glTexCoord1f (TmpShade);						// Set The Texture Co-ordinate As The Shade Value ( NEW )
				glVertex3fv (&polyData[i].Verts[j].Pos.X);		// Send The Vertex Position ( NEW )
		    }
		}

	glEnd ();													// Tell OpenGL To Finish Drawing

	glDisable (GL_TEXTURE_1D);									// Disable 1D Textures ( NEW )

	// Outline Code //
	if (outlineDraw)											// Check To See If We Want To Draw The Outline ( NEW )
	{
		glEnable (GL_BLEND);									// Enable Blending ( NEW )
		glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);		// Set The Blend Mode ( NEW )

		glPolygonMode (GL_BACK, GL_LINE);						// Draw Backfacing Polygons As Wireframes ( NEW )
		glLineWidth (outlineWidth);								// Set The Line Width ( NEW )

		glCullFace (GL_FRONT);									// Don't Draw Any Front-Facing Polygons ( NEW )

		glDepthFunc (GL_LEQUAL);								// Change The Depth Mode ( NEW )

		glColor3fv (&outlineColor[0]);							// Set The Outline Color ( NEW )

		glBegin (GL_TRIANGLES);									// Tell OpenGL What We Want To Draw

			for (i = 0; i < polyNum; i++)						// Loop Through Each Polygon ( NEW )
			{
				for (j = 0; j < 3; j++)							// Loop Through Each Vertex ( NEW )
				{
					glVertex3fv (&polyData[i].Verts[j].Pos.X);	// Send The Vertex Position ( NEW )
				}
			}

		glEnd ();												// Tell OpenGL We've Finished

		glDepthFunc (GL_LESS);									// Reset The Depth-Testing Mode ( NEW )

		glCullFace (GL_BACK);									// Reset The Face To Be Culled ( NEW )

		glPolygonMode (GL_BACK, GL_FILL);						// Reset Back-Facing Polygon Drawing Mode ( NEW )

		glDisable (GL_BLEND);									// Disable Blending ( NEW )
	}
  // since this is double buffered, swap the buffers to display what just got drawn.
	glutSwapBuffers();
	if (modelRotate)											// Check To See If Rotation Is Enabled ( NEW )
		modelAngle += 2.0f;
}

void Deinitialize (void)										// Any User DeInitialization Goes Here
{
	glDeleteTextures (1, &shaderTexture[0]);					// Delete The Shader Texture ( NEW )

	delete [] polyData;											// Delete The Polygon Data ( NEW )
}

/* The function called whenever a key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
    /* avoid thrashing this procedure */
  usleep(100);

    /* If escape is pressed, kill everything. */

  switch (key) {    
    
    case ESCAPE: // kill everything.
	/* shut down our window */
	Deinitialize();
	glutDestroyWindow(window); 
	
	/* exit the program...normal termination. */
	exit(1);                   	
	break; // redundant.
    case 32:
    	modelRotate = !modelRotate;
    	break;
    case 49:
        outlineDraw = !outlineDraw;
	break;
    case 50:
	outlineSmooth = !outlineSmooth;	
	break;

    default:
      printf ("Key %d pressed. No action there yet.\n", key);
      break;
    }

			// Update Angle Based On The Clock
}

void specialKeyPressed(int key, int x, int y) 
{
    /* avoid thrashing this procedure */
    usleep(100);

    switch (key) {    

    case GLUT_KEY_UP: // decrease x rotation speed;
	outlineWidth++;	
	break;

    case GLUT_KEY_DOWN: // increase x rotation speed;
	outlineWidth--;	
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
     Alpha components supported 
     Depth buffer */  
  glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH);  

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
  
  glutSpecialFunc(&specialKeyPressed);
  
/* Initialize our window. */
  InitGL(640, 480);
  
  /* Start Event Processing Engine */  
  glutMainLoop();  

  return 1;
}











