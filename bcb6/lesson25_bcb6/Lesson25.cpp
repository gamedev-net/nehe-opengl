//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <stdio.h>	// Header file for standard Input/Output
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#include <gl\glaux.h>   // Header file for the GLaux library
#pragma hdrstop

//---------------------------------------------------------------------------
#pragma argsused

HGLRC hRC = NULL;               // Permanent rendering context
HDC hDC = NULL;                 // Private GDI device context
HWND hWnd = NULL;               // Holds our window handle
HINSTANCE hInstance = NULL;     // Holds the instance of the application

bool keys[256];                 // Array used for the keyboard routine
bool active = true;             // Window active flag set to TRUE by default
bool fullscreen = true;         // Fullscreen flag set to fullscreen mode by default

GLfloat	xrot,yrot,zrot,		// X, Y & Z rotation
	xspeed,yspeed,zspeed,	// X, Y & Z spin speed
	cx,cy,cz=-15;	     	// X, Y & Z position

int key = 1;			// Used to make sure same morph key is not pressed
int step = 0,steps = 200;	// Step counter and maximum number of steps
bool morph = false;		// Default morph to false (Not morphing)

typedef struct			// Structure for 3D points
{
	float x, y, z;          // X, Y & Z points
} VERTEX;			// Called VERTEX

typedef	struct			// Structure for an object
{
        int verts;		// Number of vertices for the object
        VERTEX *points;         // One vertice (Vertex x,y & z)
} OBJECT;			// Called OBJECT

int maxver;                             // Will eventually hold the maximum number of vertices
OBJECT	morph1,morph2,morph3,morph4,    // Our 4 morphable objects (morph1,2,3 & 4)
	helper,*sour,*dest;             // Helper object, source object, destination object

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

void objallocate(OBJECT *k,int n)                       // Allocate memory for each object
{							// And defines points
	k->points=(VERTEX*)malloc(sizeof(VERTEX)*n);	// Sets points equal to VERTEX * number of vertices
}							// (3 Points for each vertice)

void objfree(OBJECT *k)		// Frees the object (Releasing the memory)
{
	free(k->points);	// Frees points
}

void readstr(FILE *f,char *string)	// Reads a string from file (f)
{
	do				// Do this
	{
		fgets(string, 255, f);	                        // Gets a string of 255 chars max from f (File)
	} while ((string[0] == '/') || (string[0] == '\n'));    // Until end of line is reached
	return;				// Return
}

void objload(char *name,OBJECT *k)	// Loads object from file (name)
{
	int		ver;		// Will hold vertice count
	float	rx,ry,rz;		// Hold vertex X, Y & Z position
	FILE	*filein;		// Filename to open
	char	oneline[255];		// Holds one line of text (255 chars max)

	filein = fopen(name, "rt");	// Opens the file for reading text in translated mode
					// CTRL Z symbolizes end of file in translated mode
	readstr(filein,oneline);			// Jumps to code that reads one line of text from the file
	sscanf(oneline, "Vertices: %d\n", &ver);	// Scans text for "Vertices: ". Number after is stored in ver
	k->verts=ver;			       		// Sets objects verts variable to equal the value of ver
	objallocate(k,ver);		       		// Jumps to code that allocates ram to hold the object

	for (int i=0;i<ver;i++)      	// Loops through the vertices
	{
		readstr(filein,oneline);                // Reads in the next line of text
		sscanf(oneline, "%f %f %f", &rx, &ry, &rz);	// Searches for 3 floating point numbers, store in rx,ry & rz
		k->points[i].x = rx;	// Sets objects (k) points.x value to rx
		k->points[i].y = ry;	// Sets objects (k) points.y value to ry
		k->points[i].z = rz;	// Sets objects (k) points.z value to rz
	}
	fclose(filein);			// Close the file

	if(ver>maxver) maxver=ver;	// If ver is greater than maxver set maxver equal to ver
}					// Keeps track of highest number of vertices used in any of the
					// objects
VERTEX calculate(int i)	// Calculates movement of points during morphing
{
	VERTEX a;	// Temporary vertex called a
	a.x=(sour->points[i].x-dest->points[i].x)/steps;	// a.x value equals source x - destination x divided by steps
	a.y=(sour->points[i].y-dest->points[i].y)/steps;	// a.y value equals source y - destination y divided by steps
	a.z=(sour->points[i].z-dest->points[i].z)/steps;	// a.z value equals source z - destination z divided by steps
	return a;       // Return the results
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

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
	glShadeModel(GL_SMOOTH);                // Enable smooth shading
        glBlendFunc(GL_SRC_ALPHA,GL_ONE);	// Set the blending function for translucency
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);   // Black background
	glClearDepth(1.0f);                     // Depth buffer setup
	glEnable(GL_DEPTH_TEST);                // Enables depth testing
	glDepthFunc(GL_LEQUAL);                 // The type of depth testing to do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);      // Really nice perspective calculations

        maxver = 0;				// Sets max vertices to 0 by default
	objload("data/sphere.txt",&morph1);	// Load the first object into morph1 from file sphere.txt
	objload("data/torus.txt",&morph2);	// Load the second object into morph2 from file torus.txt
	objload("data/tube.txt",&morph3);	// Load the third object into morph3 from file tube.txt

        objallocate(&morph4,486);		// Manually reserver ram for a 4th 468 vertice object (morph4)
	for(int i=0;i<486;i++)			// Loop through all 468 vertices
	{
		morph4.points[i].x=((float)(rand()%14000)/1000)-7;	// morph4 x point becomes a random float value from -7 to 7
		morph4.points[i].y=((float)(rand()%14000)/1000)-7;	// morph4 y point becomes a random float value from -7 to 7
		morph4.points[i].z=((float)(rand()%14000)/1000)-7;	// morph4 z point becomes a random float value from -7 to 7
	}

	objload("data/sphere.txt",&helper);	// Load sphere.txt object into helper (Used as starting point)
	sour = dest = &morph1;			// Source & destination are set to equal first object (morph1)

	return true;                            // Initialization went OK
}

void DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// clear screen and depth buffer
	glLoadIdentity();                                       // Reset view

        glTranslatef(cx,cy,cz);		// Translate the current position to start drawing
	glRotatef(xrot,1,0,0);		// Rotate on the X axis by xrot
	glRotatef(yrot,0,1,0);		// Rotate on the Y axis by yrot
	glRotatef(zrot,0,0,1);		// Rotate on the Z axis by zrot

	xrot+=xspeed; yrot+=yspeed; zrot+=zspeed;		// Increase xrot,yrot & zrot by xspeed, yspeed & zspeed

	GLfloat tx,ty,tz;		// Temp X, Y & Z variables
	VERTEX q;			// Holds returned calculated values for one vertex

	glBegin(GL_POINTS);		// Begin drawing points
		for(int i=0;i<morph1.verts;i++)		// Loop through all the verts of morph1 (All objects have the same amount of verts for simplicity, could use maxcer also)
		{
			if(morph) q=calculate(i); else q.x=q.y=q.z=0;	// If morph is true calculate movement otherwise movement = 0
			helper.points[i].x-=q.x;			// Subtract q.x units from helper.points[i].x (Move on X axis)
			helper.points[i].y-=q.y;			// Subtract q.y units from helper.points[i].y (Move on Y axis)
			helper.points[i].z-=q.z;			// Subtract q.z units from helper.points[i].z (Move on Z axis)
			tx=helper.points[i].x;				// Make Temp X variable equal to helper's X variable
			ty=helper.points[i].y;				// Make Temp Y variable equal to helper's Y variable
			tz=helper.points[i].z;				// Make Temp Z variable equal to helper's Z variable

			glColor3f(0,1,1);			// Set color to a bright shade of blue
			glVertex3f(tx,ty,tz);			// Draw a point at the current temp values (Vertex)
			glColor3f(0,0.5f,1);			// Darken color a bit
			tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;	// Calculate two positions ahead
			glVertex3f(tx,ty,tz);			// Draw a second point at the newly calculate position
			glColor3f(0,0,1);			// Set color to a very dark blue
			tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;	// Calculate two more positions ahead
			glVertex3f(tx,ty,tz);			// Draw a third point at the second new position
		}			                        // This creates a ghostly tail as points move
	glEnd();	                // Done drawing points

	// If we're morphing and we haven't gone through all 200 steps increase our step counter
	// Otherwise set morphing to false, make source = destination and set the step counter back to zero.
	if(morph && step <= steps)step++; else { morph = false; sour = dest; step = 0;}
}

GLvoid KillGLWindow(GLvoid)     // Properly kill the window
{
        objfree(&morph1);	// Jump to code to release morph1 allocated ram
	objfree(&morph2);	// Jump to code to release morph2 allocated ram
	objfree(&morph3);	// Jump to code to release morph3 allocated ram
	objfree(&morph4);	// Jump to code to release morph4 allocated ram
	objfree(&helper);	// Jump to code to release helper allocated ram

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

	// Create our OpenGL window
	if (!CreateGLWindow("Piotr Cieslak & NeHe's Morphing Points Tutorial",640,480,16,fullscreen))
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

                                        if(keys[VK_PRIOR])		// Is page up being pressed?
					        zspeed+=0.01f;		// Increase zspeed

				        if(keys[VK_NEXT])		// Is page down being ressed?
					        zspeed-=0.01f;		// Decrease zspeed

                                        if(keys[VK_DOWN])		// Is page up being pressed?
					        xspeed+=0.01f;		// Increase xspeed

				        if(keys[VK_UP])			// Is page up being pressed?
					        xspeed-=0.01f;		// Decrease xspeed

				        if(keys[VK_RIGHT])		// Is page up being pressed?
					        yspeed+=0.01f;		// Increase yspeed

				        if(keys[VK_LEFT])		// Is page up being pressed?
					        yspeed-=0.01f;		// Decrease yspeed

				        if (keys['Q'])			// Is Q key being pressed?
				                cz-=0.01f;		// Move object away from viewer

                                        if (keys['Z'])			// Is Z key being pressed?
				                cz+=0.01f;		// Move object towards viewer

				        if (keys['W'])			// Is W key being pressed?
				                cy+=0.01f;		// Move object up

				        if (keys['S'])			// Is S key being pressed?
				                cy-=0.01f;		// Move object down

				        if (keys['D'])			// Is D key being pressed?
				                cx+=0.01f;		// Move object right

				        if (keys['A'])			// Is A kyey being pressed?
				                cx-=0.01f;		// Move object left

				        if (keys['1'] && (key!=1) && !morph)	// Is 1 pressed, key not equal to 1 and morph false?
				        {
					        key = 1;			// Sets key to 1 (To prevent pressing 1 2x in a row)
					        morph = true;			// Set morph to true (Starts morphing process)
					        dest = &morph1;			// Destination object to morph To becomes morph1
				        }
				        if (keys['2'] && (key!=2) && !morph)	// Is 2 pressed, key not equal to 2 and morph false?
				        {
					        key=2;				// Sets key to 2 (To prevent pressing 2 2x in a row)
					        morph=TRUE;			// Set morph to true (Starts morphing process)
					        dest=&morph2;			// Destination object to morph to becomes morph2
				        }
				        if (keys['3'] && (key!=3) && !morph)	// Is 3 pressed, key not equal to 3 and morph false?
				        {
					        key=3;				// Sets key to 3 (To prevent pressing 3 2x in a row)
					        morph=TRUE;			// Set morph to true (Starts morphing process)
					        dest=&morph3;			// Destination object to morph to becomes morph3
				        }
				        if (keys['4'] && (key!=4) && !morph)	// Is 4 pressed, key not equal to 4 and morph false?
				        {
					        key=4;				// Sets key to 4 (To prevent pressing 4 2x in a row)
					        morph=TRUE;			// Set morph to true (Starts morphing process)
					        dest=&morph4;		       	// Destination object to morph to becomes morph4
				        }
				}
			}

			if (keys[VK_F1])                        // Is F1 being pressed?
			{
				keys[VK_F1] = false;            // If so make key FALSE
				KillGLWindow();                 // Kill our current window
				fullscreen =! fullscreen;       // Toggle fullscreen / windowed mode
				// Recreate our OpenGL window
				if (!CreateGLWindow("Piotr Cieslak & NeHe's Morphing Points Tutorial",640,480,16,fullscreen))
				{
					return 0;               // Quit if window was not created
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//--------------------------------------------------------------------------- 
