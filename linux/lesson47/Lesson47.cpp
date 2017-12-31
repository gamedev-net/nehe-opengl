/****************************************************************************
*                                     *                                     *
*  Jeff Molofee's IPicture Basecode   *    Huge Thanks To: Dave Richards    *
*       http://nehe.gamedev.net       *                    Bobby Ward &     *
*                2002                 *                    The MSDN         *
*                                     *                                     *
*****************************************************************************
*                                                                           *
*   Loads  : BMP, EMF, GIF, ICO, JPG, WMF                                   *
*   Source : Reads From Disk Or The Internet                                *
*   Extras : Images Can Be Any Width Or Height                              *
*                                                                           *
*****************************************************************************
*                                                                           *
*   ReshapeGL  : Set Your Aspect Ratio, How You Want                        *
*   WindowProc : Add Custom WM_ Events (Mouse, Etc)                         *
*   WinMain    : Set The Window Title                                       *
*                Set Resolution & Color Depth                               *
*                Remove 4 Lines Of Code To Force Fullscreen (Commented)     *
*                                                                           *
*****************************************************************************
*                                                                           *
*   Free To Use In Projects Of Your Own.  All I Ask For Is A Simple Greet   *
*   Or Mention Of The Site In Your Readme Or The Project Itself :)          *
*                                                                           *
****************************************************************************/

#include <GL/gl.h>														// Header File For The OpenGL32 Library
#include <GL/glu.h>														// Header File For The GLu32 Library

#include <Cg/cg.h>														// NEW: Cg Header
#include <Cg/cgGL.h>													// NEW: Cg OpenGL Specific Header

#include <stdlib.h>
#include <stdio.h>
#include <GL/glut.h>

// User Defined Variables
#define		SIZE	64													// Defines The Size Of The X/Z Axis Of The Mesh
bool		cg_enable = true, sp;										// Toggle Cg Program On / Off, Space Pressed?
GLfloat		mesh[SIZE][SIZE][3];										// Our Static Mesh
GLfloat		wave_movement = 0.0f;										// Our Variable To Move The Waves Across The Mesh

CGcontext	cgContext;													// A Context To Hold Our Cg Program(s)
CGprogram	cgProgram;													// Our Cg Vertex Program
CGprofile	cgVertexProfile;											// The Profile To Use For Our Vertex Shader
CGparameter	position, color, modelViewMatrix, wave;						// The Parameters Needed For Our Shader

bool Initialize ()					// Any GL Init Code & User Initialiazation Goes Here
{

	// Start Of User Initialization
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);								// Black Background
	glClearDepth (1.0f);												// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);											// The Type Of Depth Testing
	glEnable (GL_DEPTH_TEST);											// Enable Depth Testing
	glShadeModel (GL_SMOOTH);											// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);					// Set Perspective Calculations To Most Accurate
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);							// Draw Our Mesh In Wireframe Mode

	// Create Our Mesh
	for (int x = 0; x < SIZE; x++)
	{
		for (int z = 0; z < SIZE; z++)
		{
			mesh[x][z][0] = (float) (SIZE / 2) - x;						// We Want To Center Our Mesh Around The Origin
			mesh[x][z][1] = 0.0f;										// Set The Y Values For All Points To 0
			mesh[x][z][2] = (float) (SIZE / 2) - z;						// We Want To Center Our Mesh Around The Origin
		}
	}

	// Setup Cg
	cgContext = cgCreateContext();										// Create A New Context For Our Cg Program(s)

	// Validate Our Context Generation Was Successful
	if (cgContext == 0)
	{
		fprintf(stderr, "Failed To Create Cg Context\n");
		exit(-1);													// We Cannot Continue
	}

	cgVertexProfile = cgGLGetLatestProfile(CG_GL_VERTEX);				// Get The Latest GL Vertex Profile

	// Validate Our Profile Determination Was Successful
	if (cgVertexProfile == CG_PROFILE_UNKNOWN)
	{
		fprintf(stderr, "Invalid profile type\n");
		exit(-1);													// We Cannot Continue
	}

	cgGLSetOptimalOptions(cgVertexProfile);								// Set The Current Profile

	// Load And Compile The Vertex Shader From File
	cgProgram = cgCreateProgramFromFile(cgContext, CG_SOURCE, "./Cg/Wave.cg", cgVertexProfile, "main", 0);

	// Validate Success
	if (cgProgram == 0)
	{
		// We Need To Determine What Went Wrong
		CGerror Error = cgGetError();

		// Show A Message Box Explaining What Went Wrong
		fprintf(stderr,"%s \n",cgGetErrorString(Error));
		exit(-1);													// We Cannot Continue
	}

	// Load The Program
	cgGLLoadProgram(cgProgram);

	// Get Handles To Each Of Our Parameters So That
	// We Can Change Them At Will Within Our Code
	position		= cgGetNamedParameter(cgProgram, "IN.position");
	color			= cgGetNamedParameter(cgProgram, "IN.color");
	wave			= cgGetNamedParameter(cgProgram, "IN.wave");
	modelViewMatrix	= cgGetNamedParameter(cgProgram, "ModelViewProj");

	return true;														// Return true (Initialization Successful)
}

void Deinitialize (void)												// Any User DeInitialization Goes Here
{
	// Destroy Our Cg Context And All Programs Contained Within It
	cgDestroyContext(cgContext);
}

void Update (int key,int x,int y)										// Perform Motion Updates Here
{
	if ( key==27 )									// Is ESC Being Pressed?
	{
		Deinitialize();
		exit(0);							// Terminate The Program
	};
	
//	if (g_keys->keyDown [VK_F1])										// Is F1 Being Pressed?
//		ToggleFullscreen (g_window);									// Toggle Fullscreen Mode


	if ( key==' ' )
	{
		sp=!sp;
		cg_enable=!cg_enable;
	};


	glutPostRedisplay();
}


void Draw (void)
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);				// Clear Screen And Depth Buffer
	glLoadIdentity ();													// Reset The Modelview Matrix

	// Position The Camera To Look At Our Mesh From A Distance
	gluLookAt(0.0f, 25.0f, -45.0f, 0.0f, 0.0f, 0.0f, 0, 1, 0);

	// Set The Modelview Matrix Of Our Shader To Our OpenGL Modelview Matrix
	cgGLSetStateMatrixParameter(modelViewMatrix, CG_GL_MODELVIEW_PROJECTION_MATRIX, CG_GL_MATRIX_IDENTITY);

	if (cg_enable)
	{
		cgGLEnableProfile(cgVertexProfile);								// Enable Our Vertex Shader Profile

		// Bind Our Vertex Program To The Current State
		cgGLBindProgram(cgProgram);

		// Set The Drawing Color To Light Green (Can Be Changed By Shader, Etc...)
		cgGLSetParameter4f(color, 0.5f, 1.0f, 0.5f, 1.0f);
	}

	// Start Drawing Our Mesh
	for (int x = 0; x < SIZE - 1; x++)
	{
		// Draw A Triangle Strip For Each Column Of Our Mesh
		glBegin(GL_TRIANGLE_STRIP);
		for (int z = 0; z < SIZE - 1; z++)
		{
			// Set The Wave Parameter Of Our Shader To The Incremented Wave Value From Our Main Program
			cgGLSetParameter3f(wave, wave_movement, 1.0f, 1.0f);
			glVertex3f(mesh[x][z][0], mesh[x][z][1], mesh[x][z][2]);		// Draw Vertex
			glVertex3f(mesh[x+1][z][0], mesh[x+1][z][1], mesh[x+1][z][2]);	// Draw Vertex
			wave_movement += 0.00001f;									// Increment Our Wave Movement
		}
		glEnd();
	}

	if (cg_enable)
		cgGLDisableProfile(cgVertexProfile);							// Disable Our Vertex Profile

	glFlush ();															// Flush The GL Rendering Pipeline
	glutSwapBuffers();
}

void ReshapeGL (int width, int height)									// Reshape The Window When It's Moved Or Resized
{
	glViewport (0, 0, (GLsizei)(width), (GLsizei)(height));				// Reset The Current Viewport
	glMatrixMode (GL_PROJECTION);										// Select The Projection Matrix
	glLoadIdentity ();													// Reset The Projection Matrix
	gluPerspective (45.0f, (GLfloat)(width)/(GLfloat)(height),			// Calculate The Aspect Ratio Of The Window
					0.1f, 100.0f);		
	glMatrixMode (GL_MODELVIEW);										// Select The Modelview Matrix
	glLoadIdentity ();													// Reset The Modelview Matrix

	glutPostRedisplay();
}


// GLUT 

void Key(unsigned char key,int x,int y)
{
	Update(key,x,y);
	return ;
};

void OnIdle()
{
	glutPostRedisplay();
};

int main( int argc, char *argv[] )
{
   glutInit( &argc, argv );
   glutInitWindowPosition( 0, 0 );
   glutInitWindowSize( 640, 480 );
   glutInitDisplayMode( GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH );
   glutCreateWindow(argv[0]);
   glutReshapeFunc( ReshapeGL );
   glutKeyboardFunc( Key );
   glutSpecialFunc( Update );
   glutDisplayFunc( Draw );
   glutIdleFunc( OnIdle );
   Initialize();
   glutMainLoop();
   return 0;
}
