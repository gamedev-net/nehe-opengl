//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#include <gl\glaux.h>   // Header file for the GLaux library
#include "3dobject.h"	// Header file for 3D object handling
#pragma hdrstop

//---------------------------------------------------------------------------
#pragma argsused

typedef float GLvector4f[4];	// Typedef's for VMatMult procedure
typedef float GLmatrix16f[16];	// Typedef's for VMatMult procedure

HGLRC hRC = NULL;               // Permanent rendering context
HDC hDC = NULL;                 // Private GDI device context
HWND hWnd = NULL;               // Holds our window handle
HINSTANCE hInstance = NULL;     // Holds the instance of the application

bool keys[256];                 // Array used for the keyboard routine
bool active = true;             // Window active flag set to TRUE by default
bool fullscreen = true;         // Fullscreen flag set to fullscreen mode by default

glObject obj;			// Object
GLfloat xrot = 0,xspeed = 0;	// X rotation & X speed
GLfloat yrot = 0,yspeed = 0;	// Y rotation & Y speed

float LightPos[] = { 0.0f, 5.0f,-4.0f, 1.0f};	// Light position
float LightAmb[] = { 0.2f, 0.2f, 0.2f, 1.0f};	// Ambient light values
float LightDif[] = { 0.6f, 0.6f, 0.6f, 1.0f};	// Diffuse light values
float LightSpc[] = {-0.2f, -0.2f, -0.2f, 1.0f};	// Specular light values

float MatAmb[] = {0.4f, 0.4f, 0.4f, 1.0f};	// Material - ambient values
float MatDif[] = {0.2f, 0.6f, 0.9f, 1.0f};	// Material - diffuse values
float MatSpc[] = {0.0f, 0.0f, 0.0f, 1.0f};	// Material - specular values
float MatShn[] = {0.0f};			// Material - shininess

float ObjPos[] = {-2.0f,-2.0f,-5.0f};		// Object position

GLUquadricObj *q;				// Quadratic for drawing a sphere
float SpherePos[] = {-4.0f,-5.0f,-6.0f};

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

void VMatMult(GLmatrix16f M, GLvector4f v)
{
	GLfloat res[4];					        // Hold calculated results
	res[0]=M[ 0]*v[0]+M[ 4]*v[1]+M[ 8]*v[2]+M[12]*v[3];
	res[1]=M[ 1]*v[0]+M[ 5]*v[1]+M[ 9]*v[2]+M[13]*v[3];
	res[2]=M[ 2]*v[0]+M[ 6]*v[1]+M[10]*v[2]+M[14]*v[3];
	res[3]=M[ 3]*v[0]+M[ 7]*v[1]+M[11]*v[2]+M[15]*v[3];
	v[0]=res[0];						// Results are stored back in v[]
	v[1]=res[1];
	v[2]=res[2];
	v[3]=res[3];		// Homogenous coordinate
}

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
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);             // Select the modelview matrix
	glLoadIdentity();                       // Reset the modelview matrix
}

int InitGLObjects()		// Initialize objects
{
	if (!ReadObject("Data/Object2.txt", &obj))	// Read object2 into obj
	{
		return FALSE;				// If failed return false
	}

	SetConnectivity(&obj);				// Set face to face connectivity

	for (unsigned int i=0;i<obj.nPlanes;i++)	// Loop through all object planes
		CalcPlane(obj, &(obj.planes[i]));	// Compute plane equations for all faces

	return true;		// Return true
}

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
	if (!InitGLObjects()) return FALSE;			// Function for initializing our object(s)
	glShadeModel(GL_SMOOTH);				// Enable smooth shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);			// Black background
	glClearDepth(1.0f);					// Depth buffer setup
	glClearStencil(0);					// Stencil buffer setup
	glEnable(GL_DEPTH_TEST);				// Enables depth testing
	glDepthFunc(GL_LEQUAL);					// The type of depth testing to do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really nice perspective calculations

	glLightfv(GL_LIGHT1, GL_POSITION, LightPos);		// Set light1 position
	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmb);		// Set light1 ambience
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDif);		// Set light1 diffuse
	glLightfv(GL_LIGHT1, GL_SPECULAR, LightSpc);		// Set light1 specular
	glEnable(GL_LIGHT1);					// Enable light1
	glEnable(GL_LIGHTING);					// Enable lighting

	glMaterialfv(GL_FRONT, GL_AMBIENT, MatAmb);		// Set material ambience
	glMaterialfv(GL_FRONT, GL_DIFFUSE, MatDif);		// Set material diffuse
	glMaterialfv(GL_FRONT, GL_SPECULAR, MatSpc);		// Set material specular
	glMaterialfv(GL_FRONT, GL_SHININESS, MatShn);		// Set material shininess

	glCullFace(GL_BACK);					// Set culling face to back face
	glEnable(GL_CULL_FACE);					// Enable culling
	glClearColor(0.1f, 1.0f, 0.5f, 1.0f);			// Set clear color (Greenish color)

	q = gluNewQuadric();					// Initialize quadratic
	gluQuadricNormals(q, GL_SMOOTH);			// Enable smooth normal generation
	gluQuadricTexture(q, GL_FALSE);				// Disable auto texture coords

	return true;                            // Initialization went OK
}

void DrawGLRoom()		// Draw the room (Box)
{
	glBegin(GL_QUADS);	// Begin drawing quads
		// Floor
		glNormal3f(0.0f, 1.0f, 0.0f);		// Normal pointing up
		glVertex3f(-10.0f,-10.0f,-20.0f);	// Back left
		glVertex3f(-10.0f,-10.0f, 20.0f);	// Front left
		glVertex3f( 10.0f,-10.0f, 20.0f);	// Front right
		glVertex3f( 10.0f,-10.0f,-20.0f);	// Back right
		// Ceiling
		glNormal3f(0.0f,-1.0f, 0.0f);		// Normal point down
		glVertex3f(-10.0f, 10.0f, 20.0f);	// Front left
		glVertex3f(-10.0f, 10.0f,-20.0f);	// Back left
		glVertex3f( 10.0f, 10.0f,-20.0f);	// Back right
		glVertex3f( 10.0f, 10.0f, 20.0f);	// Front right
		// Front wall
		glNormal3f(0.0f, 0.0f, 1.0f);		// Normal pointing away from viewer
		glVertex3f(-10.0f, 10.0f,-20.0f);	// Top left
		glVertex3f(-10.0f,-10.0f,-20.0f);	// Bottom left
		glVertex3f( 10.0f,-10.0f,-20.0f);	// Bottom right
		glVertex3f( 10.0f, 10.0f,-20.0f);	// Top right
		// Back wall
		glNormal3f(0.0f, 0.0f,-1.0f);		// Normal pointing towards viewer
		glVertex3f( 10.0f, 10.0f, 20.0f);	// Top right
		glVertex3f( 10.0f,-10.0f, 20.0f);	// Bottom right
		glVertex3f(-10.0f,-10.0f, 20.0f);	// Bottom left
		glVertex3f(-10.0f, 10.0f, 20.0f);	// Top left
		// Left wall
		glNormal3f(1.0f, 0.0f, 0.0f);		// Normal pointing right
		glVertex3f(-10.0f, 10.0f, 20.0f);	// Top front
		glVertex3f(-10.0f,-10.0f, 20.0f);	// Bottom front
		glVertex3f(-10.0f,-10.0f,-20.0f);	// Bottom back
		glVertex3f(-10.0f, 10.0f,-20.0f);	// Top back
		// Right wall
		glNormal3f(-1.0f, 0.0f, 0.0f);		// Normal pointing left
		glVertex3f( 10.0f, 10.0f,-20.0f);	// Top back
		glVertex3f( 10.0f,-10.0f,-20.0f);	// Bottom back
		glVertex3f( 10.0f,-10.0f, 20.0f);	// Bottom front
		glVertex3f( 10.0f, 10.0f, 20.0f);	// Top front
	glEnd();        	// Done drawing quads
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	GLmatrix16f Minv;
	GLvector4f wlp, lp;

	// Clear color buffer, depth buffer, stencil buffer
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

	glLoadIdentity();					// Reset modelview matrix
	glTranslatef(0.0f, 0.0f, -20.0f);			// Zoom into screen 20 units
	glLightfv(GL_LIGHT1, GL_POSITION, LightPos);		// Position light1
	glTranslatef(SpherePos[0], SpherePos[1], SpherePos[2]);	// Position the sphere
	gluSphere(q, 1.5f, 32, 16);				// Draw a sphere

	// Calculate light's position relative to local coordinate system
	// dunno if this is the best way to do it, but it actually works
	// if u find another aproach, let me know ;)

	// we build the inversed matrix by doing all the actions in reverse order
	// and with reverse parameters (notice -xrot, -yrot, -ObjPos[], etc.)
	glLoadIdentity();					// Reset matrix
	glRotatef(-yrot, 0.0f, 1.0f, 0.0f);			// Rotate by -yrot on Y axis
	glRotatef(-xrot, 1.0f, 0.0f, 0.0f);			// Rotate by -xrot on X axis
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);			// Retrieve modelview matrix (Stores in Minv)
	lp[0] = LightPos[0];					// Store light position X in lp[0]
	lp[1] = LightPos[1];					// Store light position Y in lp[1]
	lp[2] = LightPos[2];					// Store light position Z in lp[2]
	lp[3] = LightPos[3];					// Store light direction in lp[3]
	VMatMult(Minv, lp);					// We store rotated light vector in 'lp' array
	glTranslatef(-ObjPos[0], -ObjPos[1], -ObjPos[2]);	// Move negative on all axis based on ObjPos[] values (X, Y, Z)
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);			// Retrieve modelview matrix from Minv
	wlp[0] = 0.0f;						// World local coord X to 0
	wlp[1] = 0.0f;						// World local coord Y to 0
	wlp[2] = 0.0f;						// World local coord Z to 0
	wlp[3] = 1.0f;
	VMatMult(Minv, wlp);					// We store the position of the world origin relative to the
								// local coord. System in 'wlp' array
	lp[0] += wlp[0];					// Adding these two gives us the
	lp[1] += wlp[1];					// position of the light relative to
	lp[2] += wlp[2];					// the local coordinate system

	glColor4f(0.7f, 0.4f, 0.0f, 1.0f);			// Set color to an orange
	glLoadIdentity();					// Reset modelview matrix
	glTranslatef(0.0f, 0.0f, -20.0f);			// Zoom into the screen 20 units
	DrawGLRoom();						// Draw the room
	glTranslatef(ObjPos[0], ObjPos[1], ObjPos[2]);		// Position the object
	glRotatef(xrot, 1.0f, 0.0f, 0.0f);			// Spin it on the X axis by xrot
	glRotatef(yrot, 0.0f, 1.0f, 0.0f);			// Spin it on the Y axis by yrot
	DrawGLObject(obj);					// Procedure for drawing the loaded object
	CastShadow(&obj, lp);					// Procedure for casting the shadow based on the silhouette

	glColor4f(0.7f, 0.4f, 0.0f, 1.0f);			// Set color to purplish blue
	glDisable(GL_LIGHTING);					// Disable lighting
	glDepthMask(GL_FALSE);					// Disable depth mask
	glTranslatef(lp[0], lp[1], lp[2]);			// Translate to light's position
								// Notice we're still in local coordinate system
	gluSphere(q, 0.2f, 16, 8);				// Draw a little yellow sphere (Represents light)
	glEnable(GL_LIGHTING);					// Enable lighting
	glDepthMask(GL_TRUE);					// Enable depth mask

	xrot += xspeed;						// Increase xrot by xspeed
	yrot += yspeed;						// Increase yrot by yspeed

	glFlush();						// Flush the OpenGL pipeline
        
	return true;            // Everything went OK
}

void ProcessKeyboard()          // Process key presses
{
	// Spin object
	if (keys[VK_LEFT])	yspeed -= 0.1f;	        // 'Arrow Left' decrease yspeed
	if (keys[VK_RIGHT])	yspeed += 0.1f;		// 'Arrow Right' increase yspeed
	if (keys[VK_UP])	xspeed -= 0.1f;		// 'Arrow Up' decrease xspeed
	if (keys[VK_DOWN])	xspeed += 0.1f;		// 'Arrow Down' increase xspeed

	// Adjust light's position
	if (keys['L']) LightPos[0] += 0.05f;		// 'L' Moves light right
	if (keys['J']) LightPos[0] -= 0.05f;		// 'J' Moves light left

	if (keys['I']) LightPos[1] += 0.05f;		// 'I' Moves light up
	if (keys['K']) LightPos[1] -= 0.05f;		// 'K' Moves light down

	if (keys['O']) LightPos[2] += 0.05f;		// 'O' Moves light toward viewer
	if (keys['U']) LightPos[2] -= 0.05f;		// 'U' Moves light away from viewer

	// Adjust object's position
	if (keys[VK_NUMPAD6]) ObjPos[0] += 0.05f;	// 'Numpad6' move object right
	if (keys[VK_NUMPAD4]) ObjPos[0] -= 0.05f;	// 'Numpad4' move object left

	if (keys[VK_NUMPAD8]) ObjPos[1] += 0.05f;	// 'Numpad8' move object up
	if (keys[VK_NUMPAD5]) ObjPos[1] -= 0.05f;	// 'Numpad5' move object down

	if (keys[VK_NUMPAD9]) ObjPos[2] += 0.05f;	// 'Numpad9' move object toward viewer
	if (keys[VK_NUMPAD7]) ObjPos[2] -= 0.05f;	// 'Numpad7' move object away from viewer

	// Adjust ball's position
	if (keys['D']) SpherePos[0] += 0.05f;		// 'D' Move ball right
	if (keys['A']) SpherePos[0] -= 0.05f;		// 'A' Move ball left

	if (keys['W']) SpherePos[1] += 0.05f;		// 'W' Move ball up
	if (keys['S']) SpherePos[1] -= 0.05f;		// 'S' Move ball down

	if (keys['E']) SpherePos[2] += 0.05f;		// 'E' Move ball toward viewer
	if (keys['Q']) SpherePos[2] -= 0.05f;		// 'Q' Move ball away from viewer
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
		1,					// Use stencil buffer ( * Important * )
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

	// Create our OpenGL window
	if (!CreateGLWindow("Banu Octavian & NeHe's Shadow Casting Tutorial",800,600,32,fullscreen))
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
					DrawGLScene();          // Draw the scene
					SwapBuffers(hDC);       // Swap buffers (Double buffering)
                                        ProcessKeyboard();	// Process key presses
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//--------------------------------------------------------------------------- 
