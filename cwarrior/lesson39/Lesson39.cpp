/**************************************************************************

  File: Lesson39.cpp
  
  Based on Jeff Molofee's Basecode Example and Jeff Molofee's Lesson 14

  Modified by Erkin Tunca for http://nehe.gamedev.net

**************************************************************************/

#include <windows.h>											// Header File For Windows
#include <stdio.h>												// Header File For Standard Input/Output
#include <gl\gl.h>												// Header File For The OpenGL32 Library
#include <gl\glu.h>												// Header File For The GLu32 Library
#include "NeHeGL.h"												// Header File For NeHeGL
#include "Physics1.h"											// Header File For Lesson39 (Physics1)

#pragma comment( lib, "opengl32.lib" )							// Search For OpenGL32.lib While Linking
#pragma comment( lib, "glu32.lib" )								// Search For GLu32.lib While Linking

#ifndef CDS_FULLSCREEN											// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4										// Compilers. By Defining It This Way,
#endif															// We Can Avoid Errors

GL_Window*	g_window;
Keys*		g_keys;

/*
ConstantVelocity is an object from Physics1.h. It is a container for simulating masses. 
Specifically, it creates a mass and sets its velocity as (1, 0, 0) so that the mass 
moves with 1.0f meters / second in the x direction.
*/
ConstantVelocity* constantVelocity = new ConstantVelocity();

/*
MotionUnderGravitation is an object from Physics1.h. It is a container for simulating masses. 
This object applies gravitation to all masses it contains. This gravitation is set by the 
constructor which is (0.0f, -9.81f, 0.0f) for now (see below). This means a gravitational acceleration 
of 9.81 meter per (second * second) in the negative y direction. MotionUnderGravitation 
creates one mass by default and sets its position to (-10, 0, 0) and its velocity to
(10, 15, 0)
*/
MotionUnderGravitation* motionUnderGravitation = 
	new MotionUnderGravitation(Vector3D(0.0f, -9.81f, 0.0f));

/*
MassConnectedWithSpring is an object from Physics1.h. It is a container for simulating masses. 
This object has a member called connectionPos, which is the connection position of the spring 
it simulates. All masses in this container are pulled towards the connectionPos by a spring 
with a constant of stiffness. This constant is set by the constructor and for now it is 2.0 
(see below).
*/
MassConnectedWithSpring* massConnectedWithSpring = 
	new MassConnectedWithSpring(2.0f);

float slowMotionRatio = 10.0f;									// slowMotionRatio Is A Value To Slow Down The Simulation, Relative To Real World Time
float timeElapsed = 0;											// Elapsed Time In The Simulation (Not Equal To Real World's Time Unless slowMotionRatio Is 1

GLuint	base;													// Base Display List For The Font Set

GLYPHMETRICSFLOAT gmf[256];										// Storage For Information About Our Outline Font Characters

GLvoid BuildFont(GL_Window* window)								// Build Our Bitmap Font
{
	HFONT	font;												// Windows Font ID

	base = glGenLists(256);										// Storage For 256 Characters

	font = CreateFont(	-12,									// Height Of Font
						0,										// Width Of Font
						0,										// Angle Of Escapement
						0,										// Orientation Angle
						FW_BOLD,								// Font Weight
						FALSE,									// Italic
						FALSE,									// Underline
						FALSE,									// Strikeout
						ANSI_CHARSET,							// Character Set Identifier
						OUT_TT_PRECIS,							// Output Precision
						CLIP_DEFAULT_PRECIS,					// Clipping Precision
						ANTIALIASED_QUALITY,					// Output Quality
						FF_DONTCARE|DEFAULT_PITCH,				// Family And Pitch
						NULL);									// Font Name
	
	HDC hDC = window->hDC;
	SelectObject(hDC, font);									// Selects The Font We Created

	wglUseFontOutlines(	hDC,									// Select The Current DC
						0,										// Starting Character
						255,									// Number Of Display Lists To Build
						base,									// Starting Display Lists
						0.0f,									// Deviation From The True Outlines
						0.0f,									// Font Thickness In The Z Direction
						WGL_FONT_POLYGONS,						// Use Polygons, Not Lines
						gmf);									// Address Of Buffer To Recieve Data
}

GLvoid KillFont(GLvoid)											// Delete The Font
{
	glDeleteLists(base, 256);									// Delete All 256 Characters
}

GLvoid glPrint(float x, float y, float z, const char *fmt, ...)	// Custom GL "Print" Routine
{
	float		length=0;										// Used To Find The Length Of The Text
	char		text[256];										// Holds Our String
	va_list		ap;												// Pointer To List Of Arguments

	if (fmt == NULL)											// If There's No Text
		return;													// Do Nothing

	va_start(ap, fmt);											// Parses The String For Variables
	    vsprintf(text, fmt, ap);								// And Converts Symbols To Actual Numbers
	va_end(ap);													// Results Are Stored In Text

	for (unsigned int loop=0;loop<(strlen(text));loop++)		// Loop To Find Text Length
	{
		length+=gmf[text[loop]].gmfCellIncX;					// Increase Length By Each Characters Width
	}

	glTranslatef(x - length, y, z);								// Position Text On The Screen

	glPushAttrib(GL_LIST_BIT);									// Pushes The Display List Bits
	glListBase(base);											// Sets The Base Character to 0
	glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);			// Draws The Display List Text
	glPopAttrib();												// Pops The Display List Bits

	glTranslatef(-x, -y, -z);									// Position Text On The Screen
}

BOOL Initialize (GL_Window* window, Keys* keys)					// Any GL Init Code & User Initialiazation Goes Here
{
	g_window	= window;
	g_keys		= keys;

	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
	glShadeModel (GL_SMOOTH);									// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Set Perspective Calculations To Most Accurate

	BuildFont(window);											// Build The Font

	return TRUE;												// Return TRUE (Initialization Successful)
}

void Deinitialize (void)										// Any User DeInitialization Goes Here
{
	KillFont();
	
	constantVelocity->release();
	delete(constantVelocity);
	constantVelocity = NULL;

	motionUnderGravitation->release();
	delete(motionUnderGravitation);
	motionUnderGravitation = NULL;

	massConnectedWithSpring->release();
	delete(massConnectedWithSpring);
	massConnectedWithSpring = NULL;
}

void Update (DWORD milliseconds)								// Perform Motion Updates Here
{
	if (g_keys->keyDown [VK_ESCAPE] == TRUE)					// Is ESC Being Pressed?
		TerminateApplication (g_window);						// Terminate The Program

	if (g_keys->keyDown [VK_F1] == TRUE)						// Is F1 Being Pressed?
		ToggleFullscreen (g_window);							// Toggle Fullscreen Mode

	if (g_keys->keyDown [VK_F2] == TRUE)						// Is F2 Being Pressed?
		slowMotionRatio = 1.0f;									// Set slowMotionRatio To 1.0f (Normal Motion)

	if (g_keys->keyDown [VK_F3] == TRUE)						// Is F3 Being Pressed?
		slowMotionRatio = 10.0f;								// Set slowMotionRatio To 10.0f (Very Slow Motion)

	// dt Is The Time Interval (As Seconds) From The Previous Frame To The Current Frame.
	// dt Will Be Used To Iterate Simulation Values Such As Velocity And Position Of Masses.

	float dt = milliseconds / 1000.0f;							// Let's Convert Milliseconds To Seconds

	dt /= slowMotionRatio;										// Divide dt By slowMotionRatio And Obtain The New dt

	timeElapsed += dt;											// Iterate Elapsed Time

	float maxPossible_dt = 0.1f;								// Say That The Maximum Possible dt Is 0.1 Seconds
																// This Is Needed So We Do Not Pass Over A Non Precise dt Value

  	int numOfIterations = (int)(dt / maxPossible_dt) + 1;		// Calculate Number Of Iterations To Be Made At This Update Depending On maxPossible_dt And dt
	if (numOfIterations != 0)									// Avoid Division By Zero
		dt = dt / numOfIterations;								// dt Should Be Updated According To numOfIterations

	for (int a = 0; a < numOfIterations; ++a)					// We Need To Iterate Simulations "numOfIterations" Times
	{
		constantVelocity->operate(dt);							// Iterate constantVelocity Simulation By dt Seconds
		motionUnderGravitation->operate(dt);					// Iterate motionUnderGravitation Simulation By dt Seconds
		massConnectedWithSpring->operate(dt);					// Iterate massConnectedWithSpring Simulation By dt Seconds
	}

}

void Draw (void)
{	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity ();											// Reset The Modelview Matrix
	
	// Position Camera 40 Meters Up In Z-Direction.
	// Set The Up Vector In Y-Direction So That +X Directs To Right And +Y Directs To Up On The Window.
	gluLookAt(0, 0, 40, 0, 0, 0, 0, 1, 0);						

	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer


	// Drawing The Coordinate Plane Starts Here.
	// We Will Draw Horizontal And Vertical Lines With A Space Of 1 Meter Between Them.
	glColor3ub(0, 0, 255);										// Draw In Blue
	glBegin(GL_LINES);
	
	// Draw The Vertical Lines
	for (float x = -20; x <= 20; x += 1.0f)						// x += 1.0f Stands For 1 Meter Of Space In This Example
	{
		glVertex3f(x, 20, 0);
		glVertex3f(x,-20, 0);
	}

	// Draw The Horizontal Lines
	for (float y = -20; y <= 20; y += 1.0f)						// y += 1.0f Stands For 1 Meter Of Space In This Example
	{
		glVertex3f( 20, y, 0);
		glVertex3f(-20, y, 0);
	}

	glEnd();
	// Drawing The Coordinate Plane Ends Here.

	// Draw All Masses In constantVelocity Simulation (Actually There Is Only One Mass In This Example Of Code)
	glColor3ub(255, 0, 0);										// Draw In Red
	int a;
	for (a = 0; a < constantVelocity->numOfMasses; ++a)
	{
		Mass* mass = constantVelocity->getMass(a);
		Vector3D* pos = &mass->pos;

		glPrint(pos->x, pos->y + 1, pos->z, "Mass with constant vel");

		glPointSize(4);
		glBegin(GL_POINTS);
			glVertex3f(pos->x, pos->y, pos->z);
		glEnd();
	}
	// Drawing Masses In constantVelocity Simulation Ends Here.

	// Draw All Masses In motionUnderGravitation Simulation (Actually There Is Only One Mass In This Example Of Code)
	glColor3ub(255, 255, 0);									// Draw In Yellow
	for (a = 0; a < motionUnderGravitation->numOfMasses; ++a)
	{
		Mass* mass = motionUnderGravitation->getMass(a);
		Vector3D* pos = &mass->pos;

		glPrint(pos->x, pos->y + 1, pos->z, "Motion under gravitation");

		glPointSize(4);
		glBegin(GL_POINTS);
			glVertex3f(pos->x, pos->y, pos->z);
		glEnd();
	}
	// Drawing Masses In motionUnderGravitation Simulation Ends Here.

	// Draw All Masses In massConnectedWithSpring Simulation (Actually There Is Only One Mass In This Example Of Code)
	glColor3ub(0, 255, 0);										// Draw In Green
	for (a = 0; a < massConnectedWithSpring->numOfMasses; ++a)
	{
		Mass* mass = massConnectedWithSpring->getMass(a);
		Vector3D* pos = &mass->pos;

		glPrint(pos->x, pos->y + 1, pos->z, "Mass connected with spring");

		glPointSize(8);
		glBegin(GL_POINTS);
			glVertex3f(pos->x, pos->y, pos->z);
		glEnd();

		// Draw A Line From The Mass Position To Connection Position To Represent The Spring
		glBegin(GL_LINES);
			glVertex3f(pos->x, pos->y, pos->z);
			pos = &massConnectedWithSpring->connectionPos;
			glVertex3f(pos->x, pos->y, pos->z);
		glEnd();
	}
	// Drawing Masses In massConnectedWithSpring Simulation Ends Here.


	glColor3ub(255, 255, 255);									// Draw In White
	glPrint(-5.0f, 14, 0, "Time elapsed (seconds): %.2f", timeElapsed);	// Print timeElapsed
	glPrint(-5.0f, 13, 0, "Slow motion ratio: %.2f", slowMotionRatio);	// Print slowMotionRatio
	glPrint(-5.0f, 12, 0, "Press F2 for normal motion");
	glPrint(-5.0f, 11, 0, "Press F3 for slow motion");

	glFlush ();													// Flush The GL Rendering Pipeline
}
