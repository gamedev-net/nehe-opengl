//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <stdio.h>	// Header file for standard Input / Output
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

// Light Parameters
static GLfloat LightAmb[] = {0.7f, 0.7f, 0.7f, 1.0f};           // Ambient light
static GLfloat LightDif[] = {1.0f, 1.0f, 1.0f, 1.0f};		// Diffuse light
static GLfloat LightPos[] = {4.0f, 4.0f, 6.0f, 1.0f};		// Light position

GLUquadricObj *q;		// Quadratic for drawing a sphere

GLfloat xrot = 0.0f;            // X rotation
GLfloat yrot = 0.0f;            // Y rotation
GLfloat xrotspeed = 0.0f;	// X rotation Speed
GLfloat yrotspeed = 0.0f;	// Y rotation Speed
GLfloat zoom = -7.0f;           // Depth into the screen
GLfloat height = 2.0f;          // Height of ball from floor

GLuint texture[3];		// 3 textures

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

AUX_RGBImageRec *LoadBMP(char *Filename)        // Loads a bitmap image
{
	FILE *File = NULL;                      // File handle

	if (!Filename)		                // Make sure a filename was given
	{
		return NULL;	                // If not return NULL
	}

	File = fopen(Filename,"r");	        // Check to see if the file exists

	if (File)			        // Does the file exist?
	{
		fclose(File);		        // Close the handle
		return auxDIBImageLoad(Filename);       // Load the bitmap and return a pointer
	}

	return NULL;                            // If load failed return NULL
}

int LoadGLTextures()    // Load bitmaps and convert to textures
{
	int Status = false;					// Status indicator
        AUX_RGBImageRec *TextureImage[3];			// Create storage space for the textures
        memset(TextureImage,0,sizeof(void *)*3);		// Set the pointer to NULL
        if ((TextureImage[0]=LoadBMP("Data/EnvWall.bmp")) &&	// Load the floor texture
        (TextureImage[1]=LoadBMP("Data/Ball.bmp")) &&		// Load the light texture
        (TextureImage[2]=LoadBMP("Data/EnvRoll.bmp")))		// Load the wall texture
	{
		Status=TRUE;					// Set the status to TRUE
		glGenTextures(3, &texture[0]);			// Create the texture
		for (int loop=0; loop<3; loop++)		// Loop through 5 textures
		{
			glBindTexture(GL_TEXTURE_2D, texture[loop]);
			glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[loop]->sizeX, TextureImage[loop]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[loop]->data);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		}
		for (int loop=0; loop<3; loop++)				// Loop through 5 textures
		{
			if (TextureImage[loop])				// If texture exists
			{
				if (TextureImage[loop]->data)		// If texture image exists
				{
					free(TextureImage[loop]->data);	// Free the texture image memory
				}
				free(TextureImage[loop]);		// Free the image structure
			}
		}
	}
	return Status;							// Return the status
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
        if (!LoadGLTextures())							// If Loading The Textures Failed
	{
		return false;			// Return false
	}

	glShadeModel(GL_SMOOTH);                // Enable smooth shading
	glClearColor(0.2f, 0.5f, 1.0f, 1.0f);	// Background
	glClearDepth(1.0f);                     // Depth buffer setup
        glClearStencil(0);			// Clear the stencil buffer to 0
	glEnable(GL_DEPTH_TEST);                // Enables depth testing
	glDepthFunc(GL_LEQUAL);                 // The type of depth testing to do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);      // Really nice perspective calculations
        glEnable(GL_TEXTURE_2D);		// Enable 2D texture mapping

        glLightfv(GL_LIGHT0, GL_AMBIENT, LightAmb);	// Set the ambient lighting for light0
	glLightfv(GL_LIGHT0, GL_DIFFUSE, LightDif);	// Set the diffuse lighting for light0
	glLightfv(GL_LIGHT0, GL_POSITION, LightPos);	// Set the position for light0

	glEnable(GL_LIGHT0);			// Enable light 0
	glEnable(GL_LIGHTING);			// Enable lighting

        q = gluNewQuadric();			// Create a new quadratic
	gluQuadricNormals(q, GL_SMOOTH);	// Generate smooth normals for the quad
	gluQuadricTexture(q, GL_TRUE);		// Enable texture coords for the quad

	glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);	// Set up sphere mapping
	glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);	// Set up sphere mapping

	return true;                            // Initialization went OK
}

void DrawObject()		// Draw our ball
{
	glColor3f(1.0f, 1.0f, 1.0f);			// Set color to white
	glBindTexture(GL_TEXTURE_2D, texture[1]);	// Select texture 2 (1)
	gluSphere(q, 0.35f, 32, 16);			// Draw first sphere

        glBindTexture(GL_TEXTURE_2D, texture[2]);	// Select texture 3 (2)
	glColor4f(1.0f, 1.0f, 1.0f, 0.4f);		// Set color to white with 40% alpha
	glEnable(GL_BLEND);				// Enable blending
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);		// Set blending mode to mix based on SRC alpha
	glEnable(GL_TEXTURE_GEN_S);			// Enable sphere mapping
	glEnable(GL_TEXTURE_GEN_T);			// Enable sphere mapping

	gluSphere(q, 0.35f, 32, 16);			// Draw another sphere using new texture
							// Textures will mix creating a multiTexture effect (Reflection)
	glDisable(GL_TEXTURE_GEN_S);			// Disable sphere mapping
	glDisable(GL_TEXTURE_GEN_T);			// Disable sphere mapping
	glDisable(GL_BLEND);				// Disable blending
}

void DrawFloor()		// Draws the floor
{
	glBindTexture(GL_TEXTURE_2D, texture[0]);	// Select texture 1 (0)
	glBegin(GL_QUADS);				// Begin drawing a quad
		glNormal3f(0.0, 1.0, 0.0);		// Normal pointing up
		glTexCoord2f(0.0f, 1.0f);		// Bottom left of texture
		glVertex3f(-2.0, 0.0, 2.0);		// Bottom left corner of floor

		glTexCoord2f(0.0f, 0.0f);		// Top left of texture
		glVertex3f(-2.0, 0.0,-2.0);		// Top left corner of floor

		glTexCoord2f(1.0f, 0.0f);		// Top right of texture
		glVertex3f( 2.0, 0.0,-2.0);		// Top right corner of floor

		glTexCoord2f(1.0f, 1.0f);		// Bottom right of texture
		glVertex3f( 2.0, 0.0, 2.0);		// Bottom right corner of floor
	glEnd();					// Done drawing the quad
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// clear screen and depth buffer

        // Clip plane equations
	double eqr[] = {0.0f,-1.0f, 0.0f, 0.0f};	// Plane equation to use for the reflected objects

	glLoadIdentity();                               // Reset the current modelview matrix
        glTranslatef(0.0f, -0.6f, zoom);		// Zoom and raise camera above the floor (Up 0.6 units)
        glColorMask(0,0,0,0);				// Set color mask
        glEnable(GL_STENCIL_TEST);			// Enable stencil buffer for "marking" the floor
	glStencilFunc(GL_ALWAYS, 1, 1);			// Always passes, 1 bit plane, 1 as mask
	glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);	// We set the stencil buffer to 1 where we draw any polygon
							// Keep if test fails, keep if test passes but buffer test fails
							// Replace if test passes
	glDisable(GL_DEPTH_TEST);			// Disable depth testing
	DrawFloor();					// Draw the floor (Draws to the stencil buffer)
							// We only want to mark it in the stencil buffer
	glEnable(GL_DEPTH_TEST);			// Enable depth testing
	glColorMask(1,1,1,1);				// Set color mask to TRUE, TRUE, TRUE, TRUE
	glStencilFunc(GL_EQUAL, 1, 1);			// We draw only where the stencil is 1
							// (I.E. where the floor was drawn)
	glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);		// Don't change the stencil buffer
	glEnable(GL_CLIP_PLANE0);			// Enable clip plane for removing artifacts
							// (When the object crosses the floor)
	glClipPlane(GL_CLIP_PLANE0, eqr);		// Equation for reflected objects
	glPushMatrix();					// Push the matrix onto the stack
		glScalef(1.0f, -1.0f, 1.0f);		// Mirror Y axis
		glLightfv(GL_LIGHT0, GL_POSITION, LightPos);	// Set Up Light0
		glTranslatef(0.0f, height, 0.0f);	// Position the object
		glRotatef(xrot, 1.0f, 0.0f, 0.0f);	// Rotate local coordinate system on X axis
		glRotatef(yrot, 0.0f, 1.0f, 0.0f);	// Rotate local coordinate system on Y axis
		DrawObject();				// Draw the sphere (Reflection)
	glPopMatrix();					// Pop the matrix off the stack
	glDisable(GL_CLIP_PLANE0);			// Disable clip plane for drawing the floor
	glDisable(GL_STENCIL_TEST);			// We don't need the stencil buffer any more (Disable)
	glLightfv(GL_LIGHT0, GL_POSITION, LightPos);	// Set up Light0 position
	glEnable(GL_BLEND);				// Enable blending (Otherwise the reflected object wont show)
	glDisable(GL_LIGHTING);				// Since we use blending, we disable lighting
	glColor4f(1.0f, 1.0f, 1.0f, 0.8f);		// Set color to white with 80% alpha
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);	// Blending based on source alpha and 1 minus dest alpha
	DrawFloor();					// Draw the floor to the screen
	glEnable(GL_LIGHTING);				// Enable lighting
	glDisable(GL_BLEND);				// Disable blending
	glTranslatef(0.0f, height, 0.0f);		// Position the ball at proper height
	glRotatef(xrot, 1.0f, 0.0f, 0.0f);		// Rotate on the X axis
	glRotatef(yrot, 0.0f, 1.0f, 0.0f);		// Rotate on the Y axis
	DrawObject();					// Draw the ball
	xrot += xrotspeed;				// Update X rotation angle by xrotspeed
	yrot += yrotspeed;				// Update Y rotation angle by yrotspeed
	glFlush();					// Flush the GL pipeline

	return true;            // Everything went OK
}

void ProcessKeyboard()		// Process keyboard results
{
	if (keys[VK_RIGHT])	yrotspeed += 0.08f;	// Right arrow pressed (Increase yrotspeed)
	if (keys[VK_LEFT])	yrotspeed -= 0.08f;	// Left arrow pressed (Decrease yrotspeed)
	if (keys[VK_DOWN])	xrotspeed += 0.08f;	// Down arrow pressed (Increase xrotspeed)
	if (keys[VK_UP])	xrotspeed -= 0.08f;	// Up arrow pressed (Decrease xrotspeed)

	if (keys['A'])		zoom +=0.05f;		// 'A' Key pressed ... zoom in
	if (keys['Z'])		zoom -=0.05f;		// 'Z' Key pressed ... zoom out

	if (keys[VK_PRIOR])	height +=0.03f;		// Page up key pressed move ball up
	if (keys[VK_NEXT])	height -=0.03f;		// Page down key pressed move ball down
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
	if (!CreateGLWindow("Banu Octavian & NeHe's Stencil & Reflection Tutorial",640,480,32,fullscreen))
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

                                        ProcessKeyboard();	// Processed keyboard presses
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//--------------------------------------------------------------------------- 
