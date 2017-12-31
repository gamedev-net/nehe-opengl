//---------------------------------------------------------------------------

#include <windows.h>    // Header file for windows
#include <math.h>	// Header file for math library routines
#include <stdio.h>	// Header file for standard I/O routines
#include <stdlib.h>	// Header file for standard library
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#include <gl\glaux.h>   // Header file for the GLaux library
#include "tvector.h"
#include "tmatrix.h"
#include "tray.h"
#include "image.h"
#pragma hdrstop

//---------------------------------------------------------------------------
#pragma argsused

GLfloat spec[] = {1.0, 1.0 ,1.0 ,1.0};          // Sets specular highlight of balls
GLfloat posl[] = {0,400,0,1};                   // Position of ligth source
GLfloat amb[]={0.2f, 0.2f, 0.2f ,1.0f};         // Global ambient
GLfloat amb2[]={0.3f, 0.3f, 0.3f ,1.0f};        // Ambient of lightsource

TVector dir(0,0,-10);           // Initial direction of camera
TVector pos(0,-50,1000);        // Initial position of camera
float camera_rotation = 0;      // Holds rotation around the Y axis

TVector veloc(0.5,-0.1,0.5);    // Initial velocity of balls
TVector accel(0,-0.05,0);       // Acceleration ie. gravity of balls

TVector ArrayVel[10];           // Holds velocity of balls
TVector ArrayPos[10];           // Position of balls
TVector OldPos[10];             // Old position of balls
int NrOfBalls;                  // Sets the number of balls
double Time = 0.6;              // Timestep of simulation
int hook_toball1 = 0,sounds = 1;// Hook camera on ball, and sound on/off

// Plane structure
struct Plane
{
	        TVector _Position;
			TVector _Normal;
};
//Cylinder structure
struct Cylinder
{
	   TVector _Position;
       TVector _Axis;
       double _Radius;
};
// Explosion structure
struct Explosion
{
	   TVector _Position;
	   float   _Alpha;
	   float   _Scale;
};

Plane pl1,pl2,pl3,pl4,pl5;                // The 5 planes of the room
Cylinder cyl1,cyl2,cyl3;                  // The 2 cylinders of the room
GLUquadricObj *cylinder_obj;              // Quadratic object to render the cylinders
GLuint texture[4], dlist;                 // Stores texture objects and display list
Explosion ExplosionArray[20];             // Holds max 20 explosions at once
//Perform intersection tests with primitives
int TestIntersionPlane(const Plane& plane,const TVector& position,const TVector& direction, double& lamda, TVector& pNormal);
int TestIntersionCylinder(const Cylinder& cylinder,const TVector& position,const TVector& direction, double& lamda, TVector& pNormal,TVector& newposition);
void LoadGLTextures();                    //Loads texture objects
void InitVars();
void idle();

HGLRC hRC = NULL;               // Permanent rendering context
HDC hDC = NULL;                 // Private GDI device context
HWND hWnd = NULL;               // Holds our window handle
HINSTANCE hInstance = NULL;     // Holds the instance of the application

DEVMODE DMsaved;                // Saves the previous screen settings (NEW)

bool keys[256];                 // Array used for the keyboard routine
bool active = true;             // Window active flag set to TRUE by default
bool fullscreen = true;         // Fullscreen flag set to fullscreen mode by default

int ProcessKeys();
LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)     // Resize and initialize the GL window
{
        if (height == 0)                        // Prevent A Divide By Zero By
        {
                height = 1;                     // Making height equal One
        }

        glViewport(0, 0, width, height);        // Reset the current viewport

        glMatrixMode(GL_PROJECTION);            // Select the projection matrix
	glLoadIdentity();                       // Reset the projection matrix

	// Calculate the aspect ratio of the window
	gluPerspective(50.0f,(GLfloat)width/(GLfloat)height,10.0f,1700.0f);

	glMatrixMode(GL_MODELVIEW);             // Select the modelview matrix
	glLoadIdentity();                       // Reset the modelview matrix
}

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
	float df = 100.0;

	glClearDepth(1.0f);					// Depth buffer setup
	glEnable(GL_DEPTH_TEST);				// Enables depth testing
	glDepthFunc(GL_LEQUAL);					// The type of depth testing to do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really nice perspective calculations

	glClearColor(0,0,0,0);
  	glMatrixMode(GL_MODELVIEW);

        glLoadIdentity();

	glShadeModel(GL_SMOOTH);
	glEnable(GL_CULL_FACE);
	glEnable(GL_DEPTH_TEST);

	glMaterialfv(GL_FRONT,GL_SPECULAR,spec);
	glMaterialfv(GL_FRONT,GL_SHININESS,&df);

	glEnable(GL_LIGHTING);
	glLightfv(GL_LIGHT0,GL_POSITION,posl);
	glLightfv(GL_LIGHT0,GL_AMBIENT,amb2);
	glEnable(GL_LIGHT0);

	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,amb);
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
   
	glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	glEnable(GL_TEXTURE_2D);
        LoadGLTextures();

	//Construct billboarded explosion primitive as display list
	//4 quads at right angles to each other
        glNewList(dlist=glGenLists(1), GL_COMPILE);
                glBegin(GL_QUADS);
	                glRotatef(-45,0,1,0);
	                glNormal3f(0,0,1);
	                glTexCoord2f(0.0f, 0.0f); glVertex3f(-50,-40,0);
	                glTexCoord2f(0.0f, 1.0f); glVertex3f(50,-40,0);
	                glTexCoord2f(1.0f, 1.0f); glVertex3f(50,40,0);
	                glTexCoord2f(1.0f, 0.0f); glVertex3f(-50,40,0);
                        glNormal3f(0,0,-1);
	                glTexCoord2f(0.0f, 0.0f); glVertex3f(-50,40,0);
	                glTexCoord2f(0.0f, 1.0f); glVertex3f(50,40,0);
	                glTexCoord2f(1.0f, 1.0f); glVertex3f(50,-40,0);
	                glTexCoord2f(1.0f, 0.0f); glVertex3f(-50,-40,0);

	                glNormal3f(1,0,0);
	                glTexCoord2f(0.0f, 0.0f); glVertex3f(0,-40,50);
	                glTexCoord2f(0.0f, 1.0f); glVertex3f(0,-40,-50);
	                glTexCoord2f(1.0f, 1.0f); glVertex3f(0,40,-50);
	                glTexCoord2f(1.0f, 0.0f); glVertex3f(0,40,50);
                        glNormal3f(-1,0,0);
	                glTexCoord2f(0.0f, 0.0f); glVertex3f(0,40,50);
	                glTexCoord2f(0.0f, 1.0f); glVertex3f(0,40,-50);
	                glTexCoord2f(1.0f, 1.0f); glVertex3f(0,-40,-50);
	                glTexCoord2f(1.0f, 0.0f); glVertex3f(0,-40,50);
	        glEnd();
        glEndList();

        return true;            // Initialization went OK
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	int i;
	
	glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        // Set camera in hookmode
	if (hook_toball1)
	{
		TVector unit_followvector=ArrayVel[0];
		unit_followvector.unit();
 		gluLookAt(ArrayPos[0].X()+250,ArrayPos[0].Y()+250 ,ArrayPos[0].Z(), ArrayPos[0].X()+ArrayVel[0].X() ,ArrayPos[0].Y()+ArrayVel[0].Y() ,ArrayPos[0].Z()+ArrayVel[0].Z() ,0,1,0);

        }
	else
	        gluLookAt(pos.X(),pos.Y(),pos.Z(), pos.X()+dir.X(),pos.Y()+dir.Y(),pos.Z()+dir.Z(), 0,1.0,0.0);
	

	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

        glRotatef(camera_rotation,0,1,0);

	// Render balls
	for (i=0;i<NrOfBalls;i++)
	{
		switch(i)
                {
                        case 1: glColor3f(1.0f,1.0f,1.0f);
			       break;
                        case 2: glColor3f(1.0f,1.0f,0.0f);
			       break;
		        case 3: glColor3f(0.0f,1.0f,1.0f);
			       break;
		        case 4: glColor3f(0.0f,1.0f,0.0f);
			       break;
		        case 5: glColor3f(0.0f,0.0f,1.0f);
			       break;
		        case 6: glColor3f(0.65f,0.2f,0.3f);
			       break;
		        case 7: glColor3f(1.0f,0.0f,1.0f);
			       break;
		        case 8: glColor3f(0.0f,0.7f,0.4f);
			       break;
		        default: glColor3f(1.0f,0,0);
		}

		glPushMatrix();
		glTranslated(ArrayPos[i].X(),ArrayPos[i].Y(),ArrayPos[i].Z());
		gluSphere(cylinder_obj,20,20,20);
		glPopMatrix();
	}

	glEnable(GL_TEXTURE_2D);
	
	// Render walls(planes) with texture
	glBindTexture(GL_TEXTURE_2D, texture[3]);
	glColor3f(1, 1, 1);
	glBegin(GL_QUADS);
	        glTexCoord2f(1.0f, 0.0f); glVertex3f(320,320,320);
	        glTexCoord2f(1.0f, 1.0f); glVertex3f(320,-320,320);
                glTexCoord2f(0.0f, 1.0f); glVertex3f(-320,-320,320);
	        glTexCoord2f(0.0f, 0.0f); glVertex3f(-320,320,320);
        
	        glTexCoord2f(1.0f, 0.0f); glVertex3f(-320,320,-320);
	        glTexCoord2f(1.0f, 1.0f); glVertex3f(-320,-320,-320);
                glTexCoord2f(0.0f, 1.0f); glVertex3f(320,-320,-320);
	        glTexCoord2f(0.0f, 0.0f); glVertex3f(320,320,-320);
    
	        glTexCoord2f(1.0f, 0.0f); glVertex3f(320,320,-320);
	        glTexCoord2f(1.0f, 1.0f); glVertex3f(320,-320,-320);
                glTexCoord2f(0.0f, 1.0f); glVertex3f(320,-320,320);
	        glTexCoord2f(0.0f, 0.0f); glVertex3f(320,320,320);
	
	        glTexCoord2f(1.0f, 0.0f); glVertex3f(-320,320,320);
	        glTexCoord2f(1.0f, 1.0f); glVertex3f(-320,-320,320);
                glTexCoord2f(0.0f, 1.0f); glVertex3f(-320,-320,-320);
	        glTexCoord2f(0.0f, 0.0f); glVertex3f(-320,320,-320);
	glEnd();

	// Render floor (plane) with colours
	glBindTexture(GL_TEXTURE_2D, texture[2]); 
        glBegin(GL_QUADS);
	        glTexCoord2f(1.0f, 0.0f); glVertex3f(-320,-320,320);
	        glTexCoord2f(1.0f, 1.0f); glVertex3f(320,-320,320);
                glTexCoord2f(0.0f, 1.0f); glVertex3f(320,-320,-320);
	        glTexCoord2f(0.0f, 0.0f); glVertex3f(-320,-320,-320);
	glEnd();

        // Render columns(cylinders)
	glBindTexture(GL_TEXTURE_2D, texture[0]);   // Choose the texture to use.
	glColor3f(0.5,0.5,0.5);
        glPushMatrix();
	glRotatef(90, 1,0,0);
	glTranslatef(0,0,-500);
	gluCylinder(cylinder_obj, 60, 60, 1000, 20, 2);
	glPopMatrix();

  	glPushMatrix();
  	glTranslatef(200,-300,-500);
	gluCylinder(cylinder_obj, 60, 60, 1000, 20, 2);
	glPopMatrix();

	glPushMatrix();
        glTranslatef(-200,0,0);
	glRotatef(135, 1,0,0);
	glTranslatef(0,0,-500);
	gluCylinder(cylinder_obj, 30, 30, 1000, 20, 2);
	glPopMatrix();
	
	// Render/blend explosions
	glEnable(GL_BLEND);
	glDepthMask(GL_FALSE);
        glBindTexture(GL_TEXTURE_2D, texture[1]);
	for(i=0; i<20; i++)
	{
		if(ExplosionArray[i]._Alpha>=0)
		{
		        glPushMatrix();
                        ExplosionArray[i]._Alpha-=0.01f;
		        ExplosionArray[i]._Scale+=0.03f;
		        glColor4f(1,1,0,ExplosionArray[i]._Alpha);
		        glScalef(ExplosionArray[i]._Scale,ExplosionArray[i]._Scale,ExplosionArray[i]._Scale);
                        glTranslatef((float)ExplosionArray[i]._Position.X()/ExplosionArray[i]._Scale, (float)ExplosionArray[i]._Position.Y()/ExplosionArray[i]._Scale, (float)ExplosionArray[i]._Position.Z()/ExplosionArray[i]._Scale);
                        glCallList(dlist);
	                glPopMatrix();
		}
	}
	glDepthMask(GL_TRUE);
	glDisable(GL_BLEND);
        glDisable(GL_TEXTURE_2D);
        
	return true;            // Everything went OK
}

GLvoid KillGLWindow(GLvoid)     // Properly kill the window
{
	if (fullscreen)         // Are we in fullscreen mode?
	{
		ChangeDisplaySettings(NULL,0);  // If so switch back to the desktop
		ShowCursor(true);               // Show mouse pointer
	}

	if (hRC)        // Do we have a rendering context?
	{
		if (!wglMakeCurrent(NULL,NULL))         // Are we able to release the DC and RC contexts?
		{
			MessageBox(NULL,"Release of DC and RC failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))             // Are we able to delete the RC?
		{
			MessageBox(NULL,"Release rendering context failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC = NULL;             // Set RC to NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))        // Are we able to release the DC
	{
		MessageBox(NULL,"Release device context failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC = NULL;             // Set DC to NULL
	}

	if (hWnd && !DestroyWindow(hWnd))       // Are we able to destroy the window?
	{
		MessageBox(NULL,"Could not release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd = NULL;            // Set hWnd to NULL
	}

	if (!UnregisterClass("OpenGL",hInstance))       // Are we able to unregister class
	{
		MessageBox(NULL,"Could not unregister class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance = NULL;       // Set hInstance to NULL
	}
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:
 *	title			- Title To Appear At The Top Of The Window
 *	width			- Width Of The GL Window Or Fullscreen Mode
 *	height			- Height Of The GL Window Or Fullscreen Mode
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	GLuint		PixelFormat;		// Holds the results after searching for a match
	WNDCLASS	wc;		        // Windows class structure
	DWORD		dwExStyle;              // Window extended style
	DWORD		dwStyle;                // Window style
	RECT		WindowRect;             // Grabs rctangle upper left / lower right values
	WindowRect.left = (long)0;              // Set left value to 0
	WindowRect.right = (long)width;		// Set right value to requested width
	WindowRect.top = (long)0;               // Set top value to 0
	WindowRect.bottom = (long)height;       // Set bottom value to requested height

	fullscreen = fullscreenflag;              // Set the global fullscreen flag

	hInstance               = GetModuleHandle(NULL);		// Grab an instance for our window
	wc.style                = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;   // Redraw on size, and own DC for window
	wc.lpfnWndProc          = (WNDPROC) WndProc;			// WndProc handles messages
	wc.cbClsExtra           = 0;					// No extra window data
	wc.cbWndExtra           = 0;					// No extra window data
	wc.hInstance            = hInstance;				// Set the Instance
	wc.hIcon                = LoadIcon(NULL, IDI_WINLOGO);		// Load the default icon
	wc.hCursor              = LoadCursor(NULL, IDC_ARROW);		// Load the arrow pointer
	wc.hbrBackground        = NULL;					// No background required for GL
	wc.lpszMenuName		= NULL;					// We don't want a menu
	wc.lpszClassName	= "OpenGL";				// Set the class name

	if (!RegisterClass(&wc))					// Attempt to register the window class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);

		return false;   // Return FALSE
	}
	
	if (fullscreen)         // Attempt fullscreen mode?
	{
		DEVMODE dmScreenSettings;                                       // Device mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	        // Makes sure memory's cleared
		dmScreenSettings.dmSize         = sizeof(dmScreenSettings);     // Size of the devmode structure
		dmScreenSettings.dmPelsWidth	= width;                        // Selected screen width
		dmScreenSettings.dmPelsHeight	= height;                       // Selected screen height
		dmScreenSettings.dmBitsPerPel	= bits;	                        // Selected bits per pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try to set selected mode and get results. NOTE: CDS_FULLSCREEN gets rid of start bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If the mode fails, offer two options. Quit or use windowed mode.
			if (MessageBox(NULL,"The requested fullscreen mode is not supported by\nyour video card. Use windowed mode instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen = false;       // Windowed mode selected. Fullscreen = FALSE
			}
			else
			{
				// Pop up a message box letting user know the program is closing.
				MessageBox(NULL,"Program will now close.","ERROR",MB_OK|MB_ICONSTOP);
				return false;           // Return FALSE
			}
		}
	}

	if (fullscreen)                         // Are We Still In Fullscreen Mode?
	{
		dwExStyle = WS_EX_APPWINDOW;    // Window extended style
		dwStyle = WS_POPUP;		// Windows style
		ShowCursor(false);		// Hide mouse pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;           // Window extended style
		dwStyle=WS_OVERLAPPEDWINDOW;                            // Windows style
	}

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);     // Adjust window to true requested size

	// Create the window
	if (!(hWnd = CreateWindowEx(dwExStyle,          // Extended Style For The Window
                "OpenGL",				// Class name
		title,					// Window title
		dwStyle |				// Defined window style
		WS_CLIPSIBLINGS |			// Required window style
		WS_CLIPCHILDREN,			// Required window style
		0, 0,					// Window position
		WindowRect.right-WindowRect.left,	// Calculate window width
		WindowRect.bottom-WindowRect.top,	// Calculate window height
		NULL,					// No parent window
		NULL,					// No menu
		hInstance,				// Instance
		NULL)))					// Dont pass anything to WM_CREATE
	{
		KillGLWindow();                         // Reset the display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;                           // Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd =             // pfd tells windows how we want things to be
	{
		sizeof(PIXELFORMATDESCRIPTOR),          // Size of this pixel format descriptor
		1,					// Version number
		PFD_DRAW_TO_WINDOW |			// Format must support window
		PFD_SUPPORT_OPENGL |			// Format must support OpenGL
		PFD_DOUBLEBUFFER,			// Must support double buffering
		PFD_TYPE_RGBA,				// Request an RGBA format
		bits,					// Select our color depth
		0, 0, 0, 0, 0, 0,			// Color bits ignored
		0,					// No alpha buffer
		0,					// Shift bit ignored
		0,					// No accumulation buffer
		0, 0, 0, 0,				// Accumulation bits ignored
		16,					// 16Bit Z-Buffer (Depth buffer)
		0,					// No stencil buffer
		0,					// No auxiliary buffer
		PFD_MAIN_PLANE,				// Main drawing layer
		0,					// Reserved
		0, 0, 0					// Layer masks ignored
	};
	
	if (!(hDC=GetDC(hWnd)))         // Did we get a device context?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't create a GL device context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))	// Did windows find a matching pixel format?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't find a suitable pixelformat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))       // Are we able to set the pixel format?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't set the pixelformat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))               // Are we able to get a rendering context?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't create a GL rendering context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))    // Try to activate the rendering context
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't activate the GL rendering context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);       // Show the window
	SetForegroundWindow(hWnd);      // Slightly higher priority
	SetFocus(hWnd);                 // Sets keyboard focus to the window
	ReSizeGLScene(width, height);   // Set up our perspective GL screen

	if (!InitGL())                  // Initialize our newly created GL window
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Initialization failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	return true;                    // Success
}

LRESULT CALLBACK WndProc(HWND hWnd,     // Handle for this window
                        UINT uMsg,      // Message for this window
			WPARAM wParam,  // Additional message information
			LPARAM lParam)  // Additional message information
{
	switch (uMsg)                           // Check for windows messages
	{
		case WM_ACTIVATE:               // Watch for window activate message
		{
			if (!HIWORD(wParam))    // Check minimization state
			{
				active = true;  // Program is active
			}
			else
			{
				active = false; // Program is no longer active
			}

			return 0;               // Return to the message loop
		}

		case WM_SYSCOMMAND:             // Intercept system commands
		{
			switch (wParam)         // Check system calls
			{
				case SC_SCREENSAVE:     // Screensaver trying to start?
				case SC_MONITORPOWER:	// Monitor trying to enter powersave?
				return 0;       // Prevent from happening
			}
			break;                  // Exit
		}

		case WM_CLOSE:                  // Did we receive a close message?
		{
			PostQuitMessage(0);     // Send a quit message
			return 0;               // Jump back
		}

		case WM_KEYDOWN:                // Is a key being held down?
		{
			keys[wParam] = true;    // If so, mark it as TRUE
			return 0;               // Jump back
		}

		case WM_KEYUP:                  // Has a key been released?
		{
			keys[wParam] = false;   // If so, mark it as FALSE
			return 0;               // Jump back
		}

		case WM_SIZE:                   // Resize the OpenGL window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord = Width, HiWord = Height
			return 0;               // Jump back
		}
	}

	// Pass all unhandled messages to DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
        MSG msg;                // Windows message structure
	bool done = false;      // Bool variable to exit loop

	// Ask the user which screen mode they prefer
	if (MessageBox(NULL,"Would you like to run in fullscreen mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen = false;       // Windowed mode
	}

        InitVars();                       // Initialize variables

	// Create our OpenGL window
	if (!CreateGLWindow("Magic Room",640,480,16,fullscreen))
	{
		return 0;               // Quit if window was not created
	}

	while(!done)            // Loop that runs while done = FALSE
	{
		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))	// Is there a message waiting?
		{
			if (msg.message == WM_QUIT)             // Have we received a quit message?
			{
				done = true;                    // If so done = TRUE
			}
			else                                    // If not, deal with window messages
			{
				TranslateMessage(&msg);         // Translate the message
				DispatchMessage(&msg);          // Dispatch the message
			}
		}
		else            // If there are no messages
		{
			// Draw the scene.  Watch for ESC key and quit messages from DrawGLScene()
			if (active)                             // Program active?
			{
				if (keys[VK_ESCAPE])            // Was ESC pressed?
				{
					done = true;            // ESC signalled a quit
				}
				else                            // Not time to quit, Update screen
				{
                                        idle();                 // Advancesimulation
					DrawGLScene();          // Draw the scene
					SwapBuffers(hDC);       // Swap buffers (Double buffering)
				}

                                if (!ProcessKeys()) return 0;
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
        glDeleteTextures(4,texture);
	return (msg.wParam);    // Exit the program
}
//---------------------------------------------------------------------------
/*************************************************************************************/
/*************************************************************************************/
/***                  Find if any of the current balls                            ****/
/***             intersect with each other in the current timestep                ****/
/***Returns the index of the 2 itersecting balls, the point and time of intersection */
/*************************************************************************************/
/*************************************************************************************/
int FindBallCol(TVector& point, double& TimePoint, double Time2, int& BallNr1, int& BallNr2)
{
	TVector RelativeV;
	TRay rays;
	double MyTime = 0.0, Add=Time2/150.0, Timedummy = 10000, Timedummy2 = -1;
	TVector posi;

	// Test all balls against eachother in 150 small steps
	for (int i=0;i<NrOfBalls-1;i++)
	{
	 for (int j=i+1;j<NrOfBalls;j++)
	 {	
		    RelativeV=ArrayVel[i]-ArrayVel[j];
			rays=TRay(OldPos[i],TVector::unit(RelativeV));
			MyTime=0.0;

			if ( (rays.dist(OldPos[j])) > 40) continue; 

			while (MyTime<Time2)
			{
			   MyTime+=Add;
			   posi=OldPos[i]+RelativeV*MyTime;
			   if (posi.dist(OldPos[j])<=40) {
										   point=posi;
										   if (Timedummy>(MyTime-Add)) Timedummy=MyTime-Add;
										   BallNr1=i;
										   BallNr2=j;
										   break;
										}
			
			}
	 }

	}

	if (Timedummy!=10000) { TimePoint=Timedummy;
	                        return 1;
	}

	return 0;
}

/*************************************************************************************/
/*************************************************************************************/
/***             Main loop of the simulation                                      ****/
/***      Moves, finds the collisions and responses of the objects in the         ****/
/***      current time step.                                                      ****/
/*************************************************************************************/
/*************************************************************************************/
void idle()
{
  double rt,rt2,rt4,lamda=10000;
  TVector norm,uveloc;
  TVector normal,point,time;
  double RestTime,BallTime;
  TVector Pos2;
  int BallNr=0,dummy=0,BallColNr1,BallColNr2;
  TVector Nc;

  if (!hook_toball1)
  {
	  camera_rotation+=0.1f;
	  if (camera_rotation>360)
		  camera_rotation=0;
  }
 
	  RestTime = Time;
	  lamda=1000;

	// Compute velocity for next timestep using Euler equations
	for (int j=0;j<NrOfBalls;j++)
	  ArrayVel[j]+=accel*RestTime;

	// While timestep not over
	while (RestTime>ZERO)
	{
	   lamda=10000;   // Initialize to very large value
	
	   // For all the balls find closest intersection between balls and planes/cylinders
   	   for (int i=0;i<NrOfBalls;i++)
	   {
		      // Compute new position and distance
			  OldPos[i]=ArrayPos[i];
			  TVector::unit(ArrayVel[i],uveloc);
			  ArrayPos[i]=ArrayPos[i]+ArrayVel[i]*RestTime;
			  rt2=OldPos[i].dist(ArrayPos[i]);

			  // Test if collision occured between ball and all 5 planes
			  if (TestIntersionPlane(pl1,OldPos[i],uveloc,rt,norm))
			  {  
				  // Find intersection time
				  rt4=rt*RestTime/rt2;

				  // If smaller than the one already stored replace and in timestep
				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						 if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						  {
							normal=norm;
							point=OldPos[i]+uveloc*rt;
							lamda=rt4;
							BallNr=i;
						  }
				  }
			  }
			  
			  if (TestIntersionPlane(pl2,OldPos[i],uveloc,rt,norm))
			  {
				   rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=OldPos[i]+uveloc*rt;
							lamda=rt4;
							BallNr=i;
							dummy=1;
						 }
				  }
				 
			  }

			  if (TestIntersionPlane(pl3,OldPos[i],uveloc,rt,norm))
			  {
			      rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=OldPos[i]+uveloc*rt;
							lamda=rt4;
							BallNr=i;
						 }
				  }
			  }

			  if (TestIntersionPlane(pl4,OldPos[i],uveloc,rt,norm))
			  {
				  rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=OldPos[i]+uveloc*rt;
							lamda=rt4;
							BallNr=i;
						 }
				  }
			  }

			  if (TestIntersionPlane(pl5,OldPos[i],uveloc,rt,norm))
			  {
				  rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=OldPos[i]+uveloc*rt;
							lamda=rt4;
							BallNr=i;
						 }
				  }
			  }

              // Now test intersection with the 3 cylinders
			  if (TestIntersionCylinder(cyl1,OldPos[i],uveloc,rt,norm,Nc))
			  {
				  rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=Nc;
							lamda=rt4;
							BallNr=i;
						 }
				  }
				 
			  }
			  if (TestIntersionCylinder(cyl2,OldPos[i],uveloc,rt,norm,Nc))
			  {
				  rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=Nc;
							lamda=rt4;
							BallNr=i;
						 }
				  }
				 
			  }
			  if (TestIntersionCylinder(cyl3,OldPos[i],uveloc,rt,norm,Nc))
			  {
				  rt4=rt*RestTime/rt2;

				  if (rt4<=lamda)
				  { 
				    if (rt4<=RestTime+ZERO)
						if (! ((rt<=ZERO)&&(uveloc.dot(norm)>ZERO)) )
						 {
							normal=norm;
							point=Nc;
							lamda=rt4;
							BallNr=i;
						 }
				  }
				 
			  }
	   }

	   // After all balls were teste with planes/cylinders test for collision
	   // Between them and replace if collision time smaller
	   if (FindBallCol(Pos2,BallTime,RestTime,BallColNr1,BallColNr2))
			  {
				  if (sounds)
					  PlaySound("Data/Explode.wav",NULL,SND_FILENAME|SND_ASYNC);
			      
				  if ( (lamda==10000) || (lamda>BallTime) )
				  {
					  RestTime=RestTime-BallTime;

					  TVector pb1,pb2,xaxis,U1x,U1y,U2x,U2y,V1x,V1y,V2x,V2y;
					  double a,b;

					  pb1=OldPos[BallColNr1]+ArrayVel[BallColNr1]*BallTime;
					  pb2=OldPos[BallColNr2]+ArrayVel[BallColNr2]*BallTime;
					  xaxis=(pb2-pb1).unit();

					  a=xaxis.dot(ArrayVel[BallColNr1]);
					  U1x=xaxis*a;
					  U1y=ArrayVel[BallColNr1]-U1x;

					  xaxis=(pb1-pb2).unit();
					  b=xaxis.dot(ArrayVel[BallColNr2]);
      				  U2x=xaxis*b;
					  U2y=ArrayVel[BallColNr2]-U2x;

					  V1x=(U1x+U2x-(U1x-U2x))*0.5;
					  V2x=(U1x+U2x-(U2x-U1x))*0.5;
					  V1y=U1y;
					  V2y=U2y;

					  for (int j=0;j<NrOfBalls;j++)
					  ArrayPos[j]=OldPos[j]+ArrayVel[j]*BallTime;

					  ArrayVel[BallColNr1]=V1x+V1y;
					  ArrayVel[BallColNr2]=V2x+V2y;

					  // Update explosion array
                      for(int j=0;j<20;j++)
					  {
						  if (ExplosionArray[j]._Alpha<=0)
						  {
							  ExplosionArray[j]._Alpha=1;
                              ExplosionArray[j]._Position=ArrayPos[BallColNr1];
							  ExplosionArray[j]._Scale=1;
							  break;
						  }
					  }

					  continue;
				  }
			  }
			  

			   
  
		// End of tests
	        // If test occured move simulation for the correct timestep
	        // and compute response for the colliding ball
			if (lamda!=10000)
			{		 
				      RestTime-=lamda;

					  for (int j=0;j<NrOfBalls;j++)
					  ArrayPos[j]=OldPos[j]+ArrayVel[j]*lamda;

					  rt2=ArrayVel[BallNr].mag();
					  ArrayVel[BallNr].unit();
					  ArrayVel[BallNr]=TVector::unit( (normal*(2*normal.dot(-ArrayVel[BallNr]))) + ArrayVel[BallNr] );
					  ArrayVel[BallNr]=ArrayVel[BallNr]*rt2;
							
					  // Update explosion array
					  for(int j=0;j<20;j++)
					  {
						  if (ExplosionArray[j]._Alpha<=0)
						  {
							  ExplosionArray[j]._Alpha=1;
                              ExplosionArray[j]._Position=point;
							  ExplosionArray[j]._Scale=1;
							  break;
						  }
					  }
			}
			else RestTime=0;

	}

}

/*************************************************************************************/
/*************************************************************************************/
/***        Init Variables                                                        ****/
/*************************************************************************************/
/*************************************************************************************/
void InitVars()
{
	 // Create palnes
	pl1._Position=TVector(0,-300,0);
	pl1._Normal=TVector(0,1,0);
	pl2._Position=TVector(300,0,0);
	pl2._Normal=TVector(-1,0,0);
	pl3._Position=TVector(-300,0,0);
	pl3._Normal=TVector(1,0,0);
	pl4._Position=TVector(0,0,300);
	pl4._Normal=TVector(0,0,-1);
	pl5._Position=TVector(0,0,-300);
	pl5._Normal=TVector(0,0,1);


	// Create cylinders
	cyl1._Position=TVector(0,0,0);
	cyl1._Axis=TVector(0,1,0);
	cyl1._Radius=60+20;
	cyl2._Position=TVector(200,-300,0);
	cyl2._Axis=TVector(0,0,1);
	cyl2._Radius=60+20;
	cyl3._Position=TVector(-200,0,0);
	cyl3._Axis=TVector(0,1,1);
    cyl3._Axis.unit();
	cyl3._Radius=30+20;
	// Create quadratic object to render cylinders
	cylinder_obj= gluNewQuadric();
	gluQuadricTexture(cylinder_obj, GL_TRUE);

        // Set initial positions and velocities of balls
	// also initialize array which holds explosions
	NrOfBalls=10;
	ArrayVel[0]=veloc;
	ArrayPos[0]=TVector(199,180,10);
	ExplosionArray[0]._Alpha=0;
	ExplosionArray[0]._Scale=1;
	ArrayVel[1]=veloc;
	ArrayPos[1]=TVector(0,150,100);
	ExplosionArray[1]._Alpha=0;
	ExplosionArray[1]._Scale=1;
	ArrayVel[2]=veloc;
	ArrayPos[2]=TVector(-100,180,-100);
	ExplosionArray[2]._Alpha=0;
	ExplosionArray[2]._Scale=1;
	for (int i=3; i<10; i++)
	{
         ArrayVel[i]=veloc;
	     ArrayPos[i]=TVector(-500+i*75, 300, -500+i*50);
		 ExplosionArray[i]._Alpha=0;
	     ExplosionArray[i]._Scale=1;
	}
	for (int i=10; i<20; i++)
	{
         ExplosionArray[i]._Alpha=0;
	     ExplosionArray[i]._Scale=1;
	}
}

/*************************************************************************************/
/*************************************************************************************/
/***        Fast Intersection Function between ray/plane                          ****/
/*************************************************************************************/
/*************************************************************************************/
int TestIntersionPlane(const Plane& plane,const TVector& position,const TVector& direction, double& lamda, TVector& pNormal)
{

    double DotProduct=direction.dot(plane._Normal);
	double l2;

    // Determine if ray paralle to plane
    if ((DotProduct<ZERO)&&(DotProduct>-ZERO)) 
		return 0;

    l2=(plane._Normal.dot(plane._Position-position))/DotProduct;

    if (l2<-ZERO) 
		return 0;

    pNormal=plane._Normal;
	lamda=l2;
    return 1;

}

/*************************************************************************************/
/*************************************************************************************/
/***        Fast Intersection Function between ray/cylinder                       ****/
/*************************************************************************************/
int TestIntersionCylinder(const Cylinder& cylinder,const TVector& position,const TVector& direction, double& lamda, TVector& pNormal,TVector& newposition)
{
	TVector RC;
	double d;
	double t,s;
	TVector n,D,O;
	double ln;
	double in,out;
	

	TVector::subtract(position,cylinder._Position,RC);
	TVector::cross(direction,cylinder._Axis,n);

    ln=n.mag();

	if ( (ln<ZERO)&&(ln>-ZERO) ) return 0;

	n.unit();

	d= fabs( RC.dot(n) );

    if (d<=cylinder._Radius)
	{
		TVector::cross(RC,cylinder._Axis,O);
		t= - O.dot(n)/ln;
		TVector::cross(n,cylinder._Axis,O);
		O.unit();
		s= fabs( sqrt(cylinder._Radius*cylinder._Radius - d*d) / direction.dot(O) );

		in=t-s;
		out=t+s;

		if (in<-ZERO){
			if (out<-ZERO) return 0;
			else lamda=out;
		}
		else
        if (out<-ZERO) {
			      lamda=in;
		}
		else
		if (in<out) lamda=in;
		else lamda=out;

    	newposition=position+direction*lamda;
		TVector HB=newposition-cylinder._Position;
		pNormal=HB - cylinder._Axis*(HB.dot(cylinder._Axis));
		pNormal.unit();

		return 1;
	}
    
	return 0;
}

/*************************************************************************************/
/*************************************************************************************/
/***        Load Bitmaps And Convert To Textures                                  ****/
/*************************************************************************************/
void LoadGLTextures() {	
    /* Load texture*/
    Image *image1, *image2, *image3, *image4;
    
    /* Allocate space for texture*/
    image1 = (Image *) malloc(sizeof(Image));
    if (image1 == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }
	image2 = (Image *) malloc(sizeof(Image));
    if (image2 == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }
	image3 = (Image *) malloc(sizeof(Image));
    if (image3 == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }
	image4 = (Image *) malloc(sizeof(Image));
    if (image4 == NULL) {
	printf("Error allocating space for image");
	exit(0);
    }

    if (!ImageLoad("data/marble.bmp", image1)) {
	exit(1);
    } 
	if (!ImageLoad("data/spark.bmp", image2)) {
	exit(1);
    }
	if (!ImageLoad("data/boden.bmp", image3)) {
	exit(1);
    } 
	if (!ImageLoad("data/wand.bmp", image4)) {
	exit(1);
    }

    /* Create texture	*****************************************/
    glGenTextures(2, &texture[0]);
    glBindTexture(GL_TEXTURE_2D, texture[0]);   /* 2d texture (x and y size)*/

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); /* scale linearly when image bigger than texture*/
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); /* scale linearly when image smalled than texture*/
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_REPEAT);

    /* 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image, */
    /* border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.*/
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->sizeX, image1->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->data);

	/* Create Texture	******************************************/
    glBindTexture(GL_TEXTURE_2D, texture[1]);   /* 2d texture (x and y size)*/

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); /* scale linearly when image bigger than texture*/
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); /* scale linearly when image smalled than texture*/
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_REPEAT);

    /* 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image, */
    /* border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.*/
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image2->sizeX, image2->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image2->data);


	/* Create Texture	********************************************/
    glGenTextures(2, &texture[2]);
    glBindTexture(GL_TEXTURE_2D, texture[2]);   /* 2d texture (x and y size)*/

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); /* scale linearly when image bigger than texture*/
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); /* scale linearly when image smalled than texture*/
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_REPEAT);

    /* 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image, */
    /* border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.*/
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image3->sizeX, image3->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image3->data);

	/* Create Texture	*********************************************/
    glBindTexture(GL_TEXTURE_2D, texture[3]);   /* 2d texture (x and y size)*/

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); /* scale linearly when image bigger than texture*/
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); /* scale linearly when image smalled than texture*/
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_REPEAT);

    /* 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image, */
    /* border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.*/
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image4->sizeX, image4->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, image4->data);

	free(image1->data);
	free(image1);
	free(image2->data);
	free(image2);
	free(image3->data);
	free(image3);
	free(image4->data);
	free(image4);

};

int ProcessKeys()
{
	if (keys[VK_UP])    pos+=TVector(0,0,-10);
	if (keys[VK_UP])    pos+=TVector(0,0,10);
	if (keys[VK_LEFT])  camera_rotation+=10;
	if (keys[VK_RIGHT]) camera_rotation-=10;
	if (keys[VK_ADD])
	{
		Time+=0.1;
        keys[VK_ADD]=FALSE;
	}
	if (keys[VK_SUBTRACT])
	{
		Time-=0.1;
        keys[VK_SUBTRACT]=FALSE;
	}
	if (keys[VK_F3]) 
	{   
		sounds^=1;
        keys[VK_F3]=FALSE;
	}
	if (keys[VK_F2])
	{
	    hook_toball1^=1;
	    camera_rotation=0;
		keys[VK_F2]=FALSE;
	}
	if (keys[VK_F1])						// Is F1 Being Pressed?
	{
		keys[VK_F1]=FALSE;					// If So Make Key FALSE
		KillGLWindow();						// Kill Our Current Window
		fullscreen=!fullscreen;				// Toggle Fullscreen / Windowed Mode
		// Recreate our OpenGL window
		if (!CreateGLWindow("Magic Room",640,480,16,fullscreen))
		{
			return 0;						// Quit If Window Was Not Created
		}
	}

	return 1;
}
