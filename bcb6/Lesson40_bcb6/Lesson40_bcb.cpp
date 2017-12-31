//------------------------------------------------------------------------
//
//  This Code Was Created By Erkin Tunca
//	OpenGL Tutorial #39
//  If You've Found This Code Useful, Please Let Me Know.
//  Visit NeHe Productions At http://nehe.gamedev.net
//
//  Translation to CBuilder by Le Thanh Cong (conglth@hotmail.com)
//
//------------------------------------------------------------------------

#include <windows.h>														// Header File For Windows
#include <gl\gl.h>															// Header File For The OpenGL32 Library
#include <gl\glu.h>															// Header File For The GLu32 Library
#include "NeHeGL.h"															// Header File For NeHeGL

#include "Physics2.h"														// Header File For Physics2.h

#pragma hdrstop
#include <condefs.h>


//---------------------------------------------------------------------------
USEUNIT("NeHeGL.cpp");
//---------------------------------------------------------------------------
#pragma argsused

#ifndef CDS_FULLSCREEN														// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4													// Compilers. By Defining It This Way,
#endif																		// We Can Avoid Errors

GL_Window*	g_window;
Keys*		g_keys;
static BOOL g_isProgramLooping;											// Window Creation Loop, For FullScreen/Windowed Toggle																		// Between Fullscreen / Windowed Mode

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

BOOL Initialize (GL_Window* window, Keys* keys)								// Any GL Init Code & User Initialiazation Goes Here
{
	g_window	= window;
	g_keys		= keys;

	ropeSimulation->getMass(ropeSimulation->numOfMasses - 1)->vel.z = 10.0f;

	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);									// Black Background
	glClearDepth (1.0f);													// Depth Buffer Setup
	glShadeModel (GL_SMOOTH);												// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);						// Set Perspective Calculations To Most Accurate

	return TRUE;															// Return TRUE (Initialization Successful)
}

void Deinitialize (void)													// Any User DeInitialization Goes Here
{
	ropeSimulation->release();												// Release The ropeSimulation
	delete(ropeSimulation);													// Delete The ropeSimulation
	ropeSimulation = NULL;
}

void Update (DWORD milliseconds)											// Perform Motion Updates Here
{
	if (g_keys->keyDown [VK_ESCAPE] == TRUE)								// Is ESC Being Pressed?
		TerminateApplication (g_window);									// Terminate The Program

	if (g_keys->keyDown [VK_F1] == TRUE)									// Is F1 Being Pressed?
		ToggleFullscreen (g_window);										// Toggle Fullscreen Mode

	Vector3D ropeConnectionVel;												// Create A Temporary Vector3D

	// Keys Are Used To Move The Rope
	if (g_keys->keyDown [VK_RIGHT] == TRUE)									// Is The Right Arrow Being Pressed?
		ropeConnectionVel.x += 3.0f;										// Add Velocity In +X Direction

	if (g_keys->keyDown [VK_LEFT] == TRUE)									// Is The Left Arrow Being Pressed?
		ropeConnectionVel.x -= 3.0f;										// Add Velocity In -X Direction

	if (g_keys->keyDown [VK_UP] == TRUE)									// Is The Up Arrow Being Pressed?
		ropeConnectionVel.z -= 3.0f;										// Add Velocity In +Z Direction

	if (g_keys->keyDown [VK_DOWN] == TRUE)									// Is The Down Arrow Being Pressed?
		ropeConnectionVel.z += 3.0f;										// Add Velocity In -Z Direction

	if (g_keys->keyDown [VK_HOME] == TRUE)									// Is The Home Key Pressed?
		ropeConnectionVel.y += 3.0f;										// Add Velocity In +Y Direction

	if (g_keys->keyDown [VK_END] == TRUE)									// Is The End Key Pressed?
		ropeConnectionVel.y -= 3.0f;										// Add Velocity In -Y Direction

	ropeSimulation->setRopeConnectionVel(ropeConnectionVel);				// Set The Obtained ropeConnectionVel In The Simulation

	float dt = milliseconds / 1000.0f;										// Let's Convert Milliseconds To Seconds

	float maxPossible_dt = 0.002f;											// Maximum Possible dt Is 0.002 Seconds
																			// This Is Needed To Prevent Pass Over Of A Non-Precise dt Value

  	int numOfIterations = (int)(dt / maxPossible_dt) + 1;					// Calculate Number Of Iterations To Be Made At This Update Depending On maxPossible_dt And dt
	if (numOfIterations != 0)												// Avoid Division By Zero
		dt = dt / numOfIterations;											// dt Should Be Updated According To numOfIterations

	for (int a = 0; a < numOfIterations; ++a)								// We Need To Iterate Simulations "numOfIterations" Times
		ropeSimulation->operate(dt);
}

void Draw (void)
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
	for (int a = 0; a < ropeSimulation->numOfMasses - 1; ++a)
	{
		Mass* mass1 = ropeSimulation->getMass(a);
		Vector3D* pos1 = &mass1->pos;

		Mass* mass2 = ropeSimulation->getMass(a + 1);
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
	for (int a = 0; a < ropeSimulation->numOfMasses - 1; ++a)
	{
		Mass* mass1 = ropeSimulation->getMass(a);
		Vector3D* pos1 = &mass1->pos;

		Mass* mass2 = ropeSimulation->getMass(a + 1);
		Vector3D* pos2 = &mass2->pos;

		glLineWidth(4);
		glBegin(GL_LINES);
			glVertex3f(pos1->x, pos1->y, pos1->z);
			glVertex3f(pos2->x, pos2->y, pos2->z);
		glEnd();
	}
	// Drawing The Rope Ends Here.
	
	glFlush ();																// Flush The GL Rendering Pipeline
}
LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// Get The Window Context
	GL_Window* window = (GL_Window*)(GetWindowLong (hWnd, GWL_USERDATA));

	switch (uMsg)														// Evaluate Window Message
	{
		case WM_SYSCOMMAND:												// Intercept System Commands
		{
			switch (wParam)												// Check System Calls
			{
				case SC_SCREENSAVE:										// Screensaver Trying To Start?
				case SC_MONITORPOWER:									// Monitor Trying To Enter Powersave?
				return 0;												// Prevent From Happening
			}
			break;														// Exit
		}
		return 0;														// Return

		case WM_CREATE:													// Window Creation
		{
			CREATESTRUCT* creation = (CREATESTRUCT*)(lParam);			// Store Window Structure Pointer
			window = (GL_Window*)(creation->lpCreateParams);
			SetWindowLong (hWnd, GWL_USERDATA, (LONG)(window));
		}
		return 0;														// Return

		case WM_CLOSE:													// Closing The Window
			TerminateApplication(window);								// Terminate The Application
		return 0;														// Return

		case WM_SIZE:													// Size Action Has Taken Place
			switch (wParam)												// Evaluate Size Action
			{
				case SIZE_MINIMIZED:									// Was Window Minimized?
					window->isVisible = FALSE;							// Set isVisible To False
				return 0;												// Return

				case SIZE_MAXIMIZED:									// Was Window Maximized?
					window->isVisible = TRUE;							// Set isVisible To True
					ReshapeGL (LOWORD (lParam), HIWORD (lParam));		// Reshape Window - LoWord=Width, HiWord=Height
				return 0;												// Return

				case SIZE_RESTORED:										// Was Window Restored?
					window->isVisible = TRUE;							// Set isVisible To True
					ReshapeGL (LOWORD (lParam), HIWORD (lParam));		// Reshape Window - LoWord=Width, HiWord=Height
				return 0;												// Return
			}
		break;															// Break

		case WM_KEYDOWN:												// Update Keyboard Buffers For Keys Pressed
			if ((wParam >= 0) && (wParam <= 255))						// Is Key (wParam) In A Valid Range?
			{
				window->keys->keyDown [wParam] = TRUE;					// Set The Selected Key (wParam) To True
				return 0;												// Return
			}
		break;															// Break

		case WM_KEYUP:													// Update Keyboard Buffers For Keys Released
			if ((wParam >= 0) && (wParam <= 255))						// Is Key (wParam) In A Valid Range?
			{
				window->keys->keyDown [wParam] = FALSE;					// Set The Selected Key (wParam) To False
				return 0;												// Return
			}
		break;															// Break

		case WM_TOGGLEFULLSCREEN:										// Toggle FullScreen Mode On/Off
			g_createFullScreen = (g_createFullScreen == TRUE) ? FALSE : TRUE;
			PostMessage (hWnd, WM_QUIT, 0, 0);
		break;															// Break
	}

	return DefWindowProc (hWnd, uMsg, wParam, lParam);					// Pass Unhandled Messages To DefWindowProc
}

BOOL RegisterWindowClass (Application* application)						// Register A Window Class For This Application.
{																		// TRUE If Successful
	// Register A Window Class
	WNDCLASSEX windowClass;												// Window Class
	ZeroMemory (&windowClass, sizeof (WNDCLASSEX));						// Make Sure Memory Is Cleared
	windowClass.cbSize			= sizeof (WNDCLASSEX);					// Size Of The windowClass Structure
	windowClass.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraws The Window For Any Movement / Resizing
	windowClass.lpfnWndProc		= (WNDPROC)(WindowProc);				// WindowProc Handles Messages
	windowClass.hInstance		= application->hInstance;				// Set The Instance
	windowClass.hbrBackground	= (HBRUSH)(COLOR_APPWORKSPACE);			// Class Background Brush Color
	windowClass.hCursor			= LoadCursor(NULL, IDC_ARROW);			// Load The Arrow Pointer
	windowClass.lpszClassName	= application->className;				// Sets The Applications Classname
	if (RegisterClassEx (&windowClass) == 0)							// Did Registering The Class Fail?
	{
		// NOTE: Failure, Should Never Happen
		MessageBox (HWND_DESKTOP, "RegisterClassEx Failed!", "Error", MB_OK | MB_ICONEXCLAMATION);
		return FALSE;													// Return False (Failure)
	}
	return TRUE;														// Return True (Success)
}

// Program Entry (WinMain)
int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	Application			application;									// Application Structure
	GL_Window			window;											// Window Structure
	Keys				keys;											// Key Structure
	BOOL				isMessagePumpActive;							// Message Pump Active?
	MSG					msg;											// Window Message Structure
	DWORD				tickCount;										// Used For The Tick Counter

	// Fill Out Application Data
	application.className = "OpenGL";									// Application Class Name
	application.hInstance = hInstance;									// Application Instance

	// Fill Out Window
	ZeroMemory (&window, sizeof (GL_Window));							// Make Sure Memory Is Zeroed
	window.keys					= &keys;								// Window Key Structure
	window.init.application		= &application;							// Window Application
	window.init.title			= "NeHe & Erkin Tunca's Physics Tutorial";	// Window Title
	window.init.width			= 640;									// Window Width
	window.init.height			= 480;									// Window Height
	window.init.bitsPerPixel	= 16;									// Bits Per Pixel
	window.init.isFullScreen	= TRUE;									// Fullscreen? (Set To TRUE)

	ZeroMemory (&keys, sizeof (Keys));									// Zero keys Structure

	// Ask The User If They Want To Start In FullScreen Mode?
	if (MessageBox (HWND_DESKTOP, "Would You Like To Run In Fullscreen Mode?", "Start FullScreen?", MB_YESNO | MB_ICONQUESTION) == IDNO)
	{
		window.init.isFullScreen = FALSE;								// If Not, Run In Windowed Mode
	}

	// Register A Class For Our Window To Use
	if (RegisterWindowClass (&application) == FALSE)					// Did Registering A Class Fail?
	{
		// Failure
		MessageBox (HWND_DESKTOP, "Error Registering Window Class!", "Error", MB_OK | MB_ICONEXCLAMATION);
		return -1;														// Terminate Application
	}

	g_isProgramLooping = TRUE;											// Program Looping Is Set To TRUE
	g_createFullScreen = window.init.isFullScreen;						// g_createFullScreen Is Set To User Default
	while (g_isProgramLooping)											// Loop Until WM_QUIT Is Received
	{
		// Create A Window
		window.init.isFullScreen = g_createFullScreen;					// Set Init Param Of Window Creation To Fullscreen?
		if (CreateWindowGL (&window) == TRUE)							// Was Window Creation Successful?
		{
			// At This Point We Should Have A Window That Is Setup To Render OpenGL
			if (Initialize (&window, &keys) == FALSE)					// Call User Intialization
			{
				// Failure
				TerminateApplication (&window);							// Close Window, This Will Handle The Shutdown
			}
			else														// Otherwise (Start The Message Pump)
			{	// Initialize was a success
				isMessagePumpActive = TRUE;								// Set isMessagePumpActive To TRUE
				while (isMessagePumpActive == TRUE)						// While The Message Pump Is Active
				{
					// Success Creating Window.  Check For Window Messages
					if (PeekMessage (&msg, window.hWnd, 0, 0, PM_REMOVE) != 0)
					{
						// Check For WM_QUIT Message
						if (msg.message != WM_QUIT)						// Is The Message A WM_QUIT Message?
						{
							DispatchMessage (&msg);						// If Not, Dispatch The Message
						}
						else											// Otherwise (If Message Is WM_QUIT)
						{
							isMessagePumpActive = FALSE;				// Terminate The Message Pump
						}
					}
					else												// If There Are No Messages
					{
						if (window.isVisible == FALSE)					// If Window Is Not Visible
						{
							WaitMessage ();								// Application Is Minimized Wait For A Message
						}
						else											// If Window Is Visible
						{
							// Process Application Loop
							tickCount = GetTickCount ();				// Get The Tick Count
							Update (tickCount - window.lastTickCount);	// Update The Counter
							window.lastTickCount = tickCount;			// Set Last Count To Current Count
							Draw ();									// Draw Our Scene

							SwapBuffers (window.hDC);					// Swap Buffers (Double Buffering)
						}
					}
				}														// Loop While isMessagePumpActive == TRUE
			}															// If (Initialize (...

			// Application Is Finished
			Deinitialize ();											// User Defined DeInitialization

			DestroyWindowGL (&window);									// Destroy The Active Window
		}
		else															// If Window Creation Failed
		{
			// Error Creating Window
			MessageBox (HWND_DESKTOP, "Error Creating OpenGL Window", "Error", MB_OK | MB_ICONEXCLAMATION);
			g_isProgramLooping = FALSE;									// Terminate The Loop
		}
	}																	// While (isProgramLooping)

	UnregisterClass (application.className, application.hInstance);		// UnRegister Window Class
	return 0;
}																		// End Of WinMain()

void TerminateApplication (GL_Window* window)							// Terminate The Application
{
	PostMessage (window->hWnd, WM_QUIT, 0, 0);							// Send A WM_QUIT Message
	g_isProgramLooping = FALSE;											// Stop Looping Of The Program
}


