



/**************************************************************************

  File: Lesson40.cpp

  Based on Jeff Molofee's Basecode Example

  Modified by Erkin Tunca for nehe.gamedev.net

  Ported to SDL under Linux by Gianni Cestari

**************************************************************************/

// Includes
#include "main.h"												// We're Including theHeader Where Defs And Prototypes

extern S_AppStatus AppStatus;									// We're Using This Struct As A Repository For The Application State (Visible, Focus, ecc)


/*
  class RopeSimulation is derived from class Simulation (see Physics1.h). It simulates a rope with
  point-like particles binded with springs. The springs have inner friction and normal length. One tip of
  the rope is stabilized at a point in space called "Vector3D ropeConnectionPos". This point can be
  moved externally by a method "void setRopeConnectionVel(Vector3D ropeConnectionVel)". RopeSimulation
  creates air friction and a planer surface (or ground) with a normal in +y direction. RopeSimulation
  implements the force applied by this surface. In the code, the surface is refered as "ground".
*/
RopeSimulation* ropeSimulation = new RopeSimulation(
													80,						// 80 Particles (Masses)
													0.05f,					// Each Particle Has A Weight Of 50 Grams
													10000.0f,				// springConstant In The Rope
													0.05f,					// Normal Length Of Springs In The Rope
													0.2f,					// Spring Inner Friction Constant
													Vector3D(0, -9.81f, 0), // Gravitational Acceleration
													0.02f,					// Air Friction Constant
													100.0f,					// Ground Repel Constant
													0.2f,					// Ground Slide Friction Constant
													2.0f,					// Ground Absoption Constant
													-1.5f);					// Height Of Ground


// Code
bool InitGL(SDL_Surface *S)										// Any OpenGL Initialization Code Goes Here
{
	ropeSimulation->getMass(ropeSimulation->numOfMasses - 1)->vel.z = 10.0f;

	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);								// Black Background
	glClearDepth (1.0f);													// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);											// The Type Of Depth Testing
	glEnable (GL_DEPTH_TEST);											// Enable Depth Testing
	glShadeModel (GL_SMOOTH);											// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);					// Set Perspective Calculations To Most Accurate

	return true;												// Return TRUE (Initialization Successful)
}

bool Initialize(void)											// Any Application & User Initialization Code Goes Here
{
	AppStatus.Visible	= true;								// At The Beginning, Our App Is Visible
	AppStatus.MouseFocus	= true;								// And Have Both Mouse
	AppStatus.KeyboardFocus = true;								// And Input Focus

	return true;												// Return TRUE (Initialization Successful)
}


void Deinitialize(void)											// Any User Deinitialization Goes Here
{
	ropeSimulation->release();												// Release The ropeSimulation
	delete(ropeSimulation);													// Delete The ropeSimulation
	ropeSimulation = NULL;

	return;														// We Have Nothing To Deinit Now
}

void Update(Uint32 milliseconds, Uint8 *Keys)					// Perform Motion Updates Here
{
	if(Keys)													// If We're Sent A Key Event With The Update
	{
		if(Keys[SDLK_ESCAPE])									// And If The Key Pressed Was ESC
		{
			TerminateApplication();								// Terminate The Application
		}

		if(Keys[SDLK_F1])										// If The Key Pressed Was F1
		{
			ToggleFullscreen();									// Use SDL Function To Toggle Fullscreen Mode (But Not In Windows :) )
		}

		Vector3D ropeConnectionVel;						// Create A Temporary Vector3D

		if(Keys[SDLK_UP])										// If The Key Pressed Was Up Arrow
		{
			ropeConnectionVel.z -= 3.0f;					// Add Velocity In +Z Direction
		}

		if(Keys[SDLK_DOWN])										// If The Key Pressed Was Down Arrow
		{
			ropeConnectionVel.z += 3.0f;					// Add Velocity In -Z Direction
		}

		if(Keys[SDLK_LEFT])										// If The Key Pressed Was Left Arrow
		{
			ropeConnectionVel.x -= 3.0f;						// Add Velocity In -X Direction
		}

		if(Keys[SDLK_RIGHT])										// If The Key Pressed Was Right Arrow
		{
			ropeConnectionVel.x += 3.0f;						// Add Velocity In +X Direction
		}

		if(Keys[SDLK_HOME])										// If The Key Pressed Was Right Arrow
		{
			ropeConnectionVel.y += 3.0f;						// Add Velocity In +Y Direction
		}

		if(Keys[SDLK_END])										// If The Key Pressed Was Right Arrow
		{
			ropeConnectionVel.y -= 3.0f;						// Add Velocity In -Y Direction
		}
		ropeSimulation->setRopeConnectionVel(ropeConnectionVel);		// Set The Obtained ropeConnectionVel In The Simulation

		float dt = milliseconds / 1000.0f;										// Let's Convert Milliseconds To Seconds

	float maxPossible_dt = 0.002f;											// Maximum Possible dt Is 0.002 Seconds
																			// This Is Needed To Prevent Pass Over Of A Non-Precise dt Value

  	int numOfIterations = (int)(dt / maxPossible_dt) + 1;					// Calculate Number Of Iterations To Be Made At This Update Depending On maxPossible_dt And dt
	if (numOfIterations != 0)												// Avoid Division By Zero
		dt = dt / numOfIterations;											// dt Should Be Updated According To numOfIterations

	for (int a = 0; a < numOfIterations; ++a)								// We Need To Iterate Simulations "numOfIterations" Times
		ropeSimulation->operate(dt);
	}

	return;														// We Always Make Functions Return
}

void Draw(void)													// Our Drawing Code
{
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity ();														// Reset The Modelview Matrix

	// Position Camera 40 Meters Up In Z-Direction.
	// Set The Up Vector In Y-Direction So That +X Directs To Right And +Y Directs To Up On The Window.
	gluLookAt(0, 0, 4, 0, 0, 0, 0, 1, 0);

	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);					// Clear Screen And Depth Buffer

	// Draw A Plane To Represent The Ground (Different Colors To Create A Fade)
	glBegin(GL_QUADS);
		glColor3ub(0, 0, 255);												// Set Color To Light Blue
		glVertex3f(20, ropeSimulation->groundHeight, 20);
		glVertex3f(-20, ropeSimulation->groundHeight, 20);
		glColor3ub(0, 0, 0);												// Set Color To Black
		glVertex3f(-20, ropeSimulation->groundHeight, -20);
		glVertex3f(20, ropeSimulation->groundHeight, -20);
	glEnd();

	// Start Drawing Shadow Of The Rope
	glColor3ub(0, 0, 0);													// Set Color To Black
	for (int index = 0; index < ropeSimulation->numOfMasses - 1; ++index)
	{
		Mass* mass1 = ropeSimulation->getMass(index);
		Vector3D* pos1 = &mass1->pos;

		Mass* mass2 = ropeSimulation->getMass(index + 1);
		Vector3D* pos2 = &mass2->pos;

		glLineWidth(2);
		glBegin(GL_LINES);
			glVertex3f(pos1->x, ropeSimulation->groundHeight, pos1->z);		// Draw Shadow At groundHeight
			glVertex3f(pos2->x, ropeSimulation->groundHeight, pos2->z);		// Draw Shadow At groundHeight
		glEnd();
	}
	// Drawing Shadow Ends Here.

	// Start Drawing The Rope.
	glColor3ub(255, 255, 0);												// Set Color To Yellow
	for (int index = 0; index < ropeSimulation->numOfMasses - 1; ++index)
	{
		Mass* mass1 = ropeSimulation->getMass(index);
		Vector3D* pos1 = &mass1->pos;

		Mass* mass2 = ropeSimulation->getMass(index + 1);
		Vector3D* pos2 = &mass2->pos;

		glLineWidth(4);
		glBegin(GL_LINES);
			glVertex3f(pos1->x, pos1->y, pos1->z);
			glVertex3f(pos2->x, pos2->y, pos2->z);
		glEnd();
	}
	// Drawing The Rope Ends Here.

	glFlush ();													// Flush The GL Rendering Pipeline

	return;														// We're Always Making Functions Return
}
