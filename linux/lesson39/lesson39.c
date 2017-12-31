/**************************************************************************

  File: lesson39.cpp
  
  Based on Jeff Molofee's Basecode Example and Jeff Molofee's Lesson 14

  Modified by Erkin Tunca for http://nehe.gamedev.net
	
	Ported to Linux/GLUT by laks raghupathi (laks@imag.fr)

**************************************************************************/

#include <GL/glut.h>    									// Header File For The GLUT Library 
#include <GL/gl.h>												// Header File For The OpenGL32 Library
#include <GL/glu.h>												// Header File For The GLu32 Library
#include <unistd.h>     									// Header File For sleeping.
#include <stdio.h>
#include <stdlib.h>
#include "Physics1.h"											// Header File For Lesson39 (Physics1)

/* ASCII code for the escape key. */
#define ESCAPE 27

#ifndef CDS_FULLSCREEN											// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4										// Compilers. By Defining It This Way,
#endif																			// We Can Avoid Errors

/* The number of our GLUT window */
int window; 

int font=(int)GLUT_BITMAP_HELVETICA_10;    // For printing bitmap fonts
char s[30];                                // Tmp variable for storing the display strings  
int time,timeprev=0;											 // For calculating elapsed time
bool fullScreen=false;										 // toggle for fullscreen mode

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
float timeElapsed = 0;													// Elapsed Time In The Simulation (Not Equal To Real World's Time Unless slowMotionRatio Is 1
GLuint	base;																		// Base Display List For The Font Set


/* A general OpenGL initialization function.  Sets all of the initial parameters. */
void InitGL(int Width, int Height)	        // We call this right after our OpenGL window is created.
{
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);			// This Will Clear The Background Color To Black
  glClearDepth(1.0);												// Enables Clearing Of The Depth Buffer
  glDepthFunc(GL_LESS);											// The Type Of Depth Test To Do
  glEnable(GL_DEPTH_TEST);									// Enables Depth Testing
  glShadeModel(GL_SMOOTH);									// Enables Smooth Color Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, 
					GL_NICEST);												// Set Perspective Calculations To Most Accurate

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();													// Reset The Projection Matrix
  gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);	// Calculate The Aspect Ratio Of The Window

  glMatrixMode(GL_MODELVIEW);
}

/* Function for displaying bitmap fonts on the screen */
void glPrint(float x, float y, void *font,char *string) {

	char *c;
	glRasterPos2f(x, y);
	for (c=string; *c != '\0'; c++) {
		glutBitmapCharacter(font, *c);
	}
}

void Deinitialize (void)										// Any User DeInitialization Goes Here
{
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

/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
void ReSizeGLScene(int Width, int Height)
{
  if (Height==0)											// Prevent A Divide By Zero If The Window Is Too Small
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
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear The Screen And The Depth Buffer
  glLoadIdentity();				// Reset The View
	
	if (fullScreen)
		glutFullScreen();
	else
		glutReshapeWindow(640, 480);

	time=glutGet(GLUT_ELAPSED_TIME);
	int milliseconds = time - timeprev;
	timeprev = time;

	// dt Is The Time Interval (As Seconds) From The Previous Frame To The Current Frame.
	// dt Will Be Used To Iterate Simulation Values Such As Velocity And Position Of Masses.

	float dt = milliseconds / 1000.0f;							// Let's Convert Milliseconds To Seconds

	dt /= slowMotionRatio;													// Divide dt By slowMotionRatio And Obtain The New dt

	timeElapsed += dt;															// Iterate Elapsed Time

	float maxPossible_dt = 0.1f;										// Say That The Maximum Possible dt Is 0.1 Seconds
																									// This Is Needed So We Do Not Pass Over A Non Precise dt Value

 	int numOfIterations = (int)(dt / maxPossible_dt) + 1;		// Calculate Number Of Iterations To Be Made At This Update Depending On maxPossible_dt And dt
	if (numOfIterations != 0)													// Avoid Division By Zero
		dt = dt / numOfIterations;											// dt Should Be Updated According To numOfIterations

	for (int a = 0; a < numOfIterations; ++a)					// We Need To Iterate Simulations "numOfIterations" Times
	{
		constantVelocity->operate(dt);									// Iterate constantVelocity Simulation By dt Seconds
		motionUnderGravitation->operate(dt);						// Iterate motionUnderGravitation Simulation By dt Seconds
		massConnectedWithSpring->operate(dt);						// Iterate massConnectedWithSpring Simulation By dt Seconds
	}

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

		glPrint(pos->x, pos->y + 1, (void *)font, "Mass with constant vel");

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

		glPrint(pos->x, pos->y + 1, (void *)font, "Motion under gravitation");

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

		glPrint(pos->x, pos->y + 1, (void *)font, "Mass connected with spring");

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
	
	sprintf(s,"Time elapsed (seconds): %.2f",timeElapsed);
	glPrint(-5.0f, 14, (void *)font, s);	// Print timeElapsed

	sprintf(s,"Slow motion ratio: %.2f", slowMotionRatio);
	glPrint(-5.0f, 13, (void *)font, s);	// Print slowMotionRatio
	
	glPrint(-5.0f, 12, (void *)font, "Press F2 for normal motion");
	glPrint(-5.0f, 11, (void *)font, "Press F3 for slow motion");

	glFlush ();													// Flush The GL Rendering Pipeline

  // swap buffers to display, since we're double buffered.
  glutSwapBuffers();
}

void processNormalKeys(unsigned char keys, int x, int y)
{
  if (keys == 27) {
		exit(0);
	}
}

/* The function called whenever a key is pressed. */
void keyPressed(int key, int x, int y) 
{
	switch (key) {
		case GLUT_KEY_F1:
			fullScreen = !fullScreen;								// Toggle Fullscreen Mode
			break;
		
		case GLUT_KEY_F2:
			slowMotionRatio = 1.0f;									// Set slowMotionRatio To 1.0f (Normal Motion)
			break;

		case GLUT_KEY_F3:
			slowMotionRatio = 10.0f;								// Set slowMotionRatio To 10.0f (Very Slow Motion)
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
  window = glutCreateWindow("Jeff Molofee's GL Code Tutorial ...");  

  /* Register the function to do all our OpenGL drawing. */
  glutDisplayFunc(&DrawGLScene);  

  /* Even if there are no events, redraw our gl scene. */
  glutIdleFunc(&DrawGLScene);

  /* Register the function called when our window is resized. */
  glutReshapeFunc(&ReSizeGLScene);

  /* Function to handle the escape key */
   glutKeyboardFunc(&processNormalKeys);
	
  /* Register the function called when the keyboard is pressed. */
  glutSpecialFunc(&keyPressed);

  /* Initialize our window. */
  InitGL(640, 480);
  
  /* Start Event Processing Engine */  
  glutMainLoop();  

  return 1;
}
