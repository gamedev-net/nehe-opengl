//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <stdio.h>	// Header file for standard Input/Output ( ADD )
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#include <gl\glaux.h>   // Header file for the GLaux library

#define	MAX_PARTICLES	1000    // Number of particles to create ( NEW )

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

bool rainbow = true;		// Rainbow mode?	( ADD )
bool sp;			// Spacebar pressed?	( ADD )
bool rp;			// Return key pressed?	( ADD )

float slowdown = 2.0f;		// Slow down particles
float xspeed;			// Base X speed (To allow keyboard direction of tail)
float yspeed;			// Base Y speed (To allow keyboard direction of tail)
float zoom = -40.0f;		// Used to zoom out

GLuint loop;			// Misc loop variable
GLuint col;			// Current color selection
GLuint delay;			// Rainbow effect delay
GLuint texture[1];		// Storage for our particle texture

typedef struct			// Create a structure for particle
{
	bool	active;		// Active (Yes/No)
	float	life;		// Particle life
	float	fade;		// Fade speed
	float	r;		// Red value
	float	g;		// Green value
	float	b;		// Blue value
	float	x;		// X position
	float	y;		// Y position
	float	z;		// Z position
	float	xi;		// X direction
	float	yi;		// Y direction
	float	zi;		// Z direction
	float	xg;		// X gravity
	float	yg;		// Y gravity
	float	zg;		// Z gravity
}
particles;			// Particles structure

particles particle[MAX_PARTICLES];	// Particle array (Room for particle info)

static GLfloat colors[12][3]=		// Rainbow of colors
{
	{1.0f,0.5f,0.5f},{1.0f,0.75f,0.5f},{1.0f,1.0f,0.5f},{0.75f,1.0f,0.5f},
	{0.5f,1.0f,0.5f},{0.5f,1.0f,0.75f},{0.5f,1.0f,1.0f},{0.5f,0.75f,1.0f},
	{0.5f,0.5f,1.0f},{0.75f,0.5f,1.0f},{1.0f,0.5f,1.0f},{1.0f,0.5f,0.75f}
};

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

AUX_RGBImageRec *LoadBMP(char *Filename)		// Loads a bitmap image
{
        FILE *File=NULL;				// File handle
        if (!Filename)					// Make sure a filename was given
        {
                return NULL;				// If not return NULL
        }
        File=fopen(Filename,"r");			// Check to see if the file exists
        if (File)					// Does the file exist?
        {
			fclose(File);			// Close the handle
			return auxDIBImageLoad(Filename);	// Load the bitmap and return a pointer
        }
        return NULL;					// If load failed return NULL
}

int LoadGLTextures()					// Load bitmap and convert to a texture
{
        int Status = false;				// Status indicator
        AUX_RGBImageRec *TextureImage[1];		// Create storage space for the textures
        memset(TextureImage,0,sizeof(void *)*1);	// Set the pointer to NULL

        if (TextureImage[0] = LoadBMP("Data/Particle.bmp"))	// Load particle texture
        {
			Status = true;			// Set the status to TRUE
			glGenTextures(1, &texture[0]);	// Create one texture

			glBindTexture(GL_TEXTURE_2D, texture[0]);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);
        }

        if (TextureImage[0])				// If texture exists
		{
			if (TextureImage[0]->data)	// If texture image exists
			{
				free(TextureImage[0]->data);	// Free the texture image memory
			}
			free(TextureImage[0]);		// Free the image structure
		}
        return Status;					// Return the status
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

	// Calculate the aspect ratio of the window     ( MODIFIED )
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,200.0f);

	glMatrixMode(GL_MODELVIEW);             // Select the modelview matrix
	glLoadIdentity();                       // Reset the modelview matrix
}

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
        if (!LoadGLTextures())			// Jump to texture loading routine
	{
		return false;			// If texture didn't load return FALSE
	}

	glShadeModel(GL_SMOOTH);		        // Enables smooth shading
	glClearColor(0.0f,0.0f,0.0f,0.0f);      	// Black background
	glClearDepth(1.0f);			        // Depth buffer setup
	glDisable(GL_DEPTH_TEST);	        	// Disables depth testing
	glEnable(GL_BLEND);	        		// Enable blending
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);	        // Type of blending to perform
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);	// Really nice perspective calculations
	glHint(GL_POINT_SMOOTH_HINT,GL_NICEST);	        // Really nice point smoothing
	glEnable(GL_TEXTURE_2D);	        	// Enable texture mapping
	glBindTexture(GL_TEXTURE_2D,texture[0]);        // Select our texture

        for (loop = 0;loop < MAX_PARTICLES;loop++)	// Initials all the textures
	{
		particle[loop].active = true;	                	// Make all the particles active
		particle[loop].life = 1.0f;		                // Give all the particles full life
		particle[loop].fade = float(rand()%100)/1000.0f+0.003f;	// Random fade speed
		particle[loop].r = colors[loop*(12/MAX_PARTICLES)][0];	// Select red rainbow color
		particle[loop].g = colors[loop*(12/MAX_PARTICLES)][1];	// Select red rainbow color
		particle[loop].b = colors[loop*(12/MAX_PARTICLES)][2];	// Select red rainbow color
		particle[loop].xi = float((rand()%50)-26.0f)*10.0f;	// Random speed on X axis
		particle[loop].yi = float((rand()%50)-25.0f)*10.0f;	// Random speed on Y axis
		particle[loop].zi = float((rand()%50)-25.0f)*10.0f;	// Random speed on Z axis
		particle[loop].xg = 0.0f;				// Set horizontal pull to zero
		particle[loop].yg = -0.8f;				// Set vertical pull downward
		particle[loop].zg = 0.0f;				// Set pull on Z axis to zero
	}

	return true;                                    // Initialization went OK
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// clear screen and depth buffer
	glLoadIdentity();       // Reset the current modelview matrix

        for (loop = 0;loop < MAX_PARTICLES;loop++)		// Loop through all the particles
	{
		if (particle[loop].active)			// If the particle is active
		{
			float x = particle[loop].x;		// Grab our particle X position
			float y = particle[loop].y;		// Grab our particle Y position
			float z = particle[loop].z+zoom;	// Particle Z pos + zoom

			// Draw the particle using our RGB values, fade the particle based on it's life
			glColor4f(particle[loop].r,particle[loop].g,particle[loop].b,particle[loop].life);

			glBegin(GL_TRIANGLE_STRIP);				        // Build quad from a triangle strip
			    glTexCoord2d(1,1); glVertex3f(x+0.5f,y+0.5f,z);             // Top right
				glTexCoord2d(0,1); glVertex3f(x-0.5f,y+0.5f,z);         // Top left
				glTexCoord2d(1,0); glVertex3f(x+0.5f,y-0.5f,z);         // Bottom right
				glTexCoord2d(0,0); glVertex3f(x-0.5f,y-0.5f,z);         // Bottom left
			glEnd();							// Done building triangle strip

			particle[loop].x += particle[loop].xi/(slowdown*1000);          // Move on the X axis by X speed
			particle[loop].y += particle[loop].yi/(slowdown*1000);          // Move on the Y axis by Y speed
			particle[loop].z += particle[loop].zi/(slowdown*1000);          // Move on the Z axis by Z speed

			particle[loop].xi += particle[loop].xg;	        		// Take pull on X axis into account
			particle[loop].yi += particle[loop].yg;		        	// Take pull on Y axis into account
			particle[loop].zi += particle[loop].zg;	        		// Take pull on Z axis into account
			particle[loop].life -= particle[loop].fade;	        	// Reduce particles life by 'Fade'

			if (particle[loop].life < 0.0f)					// If particle is burned out
			{
				particle[loop].life = 1.0f;				// Give it bew life
				particle[loop].fade = float(rand()%100)/1000.0f+0.003f;	// Random fade value
				particle[loop].x = 0.0f;				// Center on X axis
				particle[loop].y = 0.0f;				// Center on Y axis
				particle[loop].z = 0.0f;				// Center on Z axis
				particle[loop].xi = xspeed+float((rand()%60)-32.0f);	// X axis speed and direction
				particle[loop].yi = yspeed+float((rand()%60)-30.0f);	// Y axis speed and direction
				particle[loop].zi = float((rand()%60)-30.0f);     	// Z axis speed and direction
				particle[loop].r = colors[col][0];			// Select red from color table
				particle[loop].g = colors[col][1];			// Select green from color table
				particle[loop].b = colors[col][2];			// Select blue from color table
			}

			// If number pad 8 and Y gravity is less than 1.5 increase pull upwards
			if (keys[VK_NUMPAD8] && (particle[loop].yg<1.5f)) particle[loop].yg+=0.01f;

			// If number pad 2 and Y gravity is greater than -1.5 increase pull downwards
			if (keys[VK_NUMPAD2] && (particle[loop].yg>-1.5f)) particle[loop].yg-=0.01f;

			// If number pad 6 and X gravity is less than 1.5 increase pull right
			if (keys[VK_NUMPAD6] && (particle[loop].xg<1.5f)) particle[loop].xg+=0.01f;

			// If number pad 4 and X gravity is greater than -1.5 increase pull left
			if (keys[VK_NUMPAD4] && (particle[loop].xg>-1.5f)) particle[loop].xg-=0.01f;

			if (keys[VK_TAB])						// Tab key causes a burst
			{
				particle[loop].x = 0.0f;				// Center on X axis
				particle[loop].y = 0.0f;				// Center on Y axis
				particle[loop].z = 0.0f;				// Center on Z axis
				particle[loop].xi = float((rand()%50)-26.0f)*10.0f;	// Random speed on X axis
				particle[loop].yi = float((rand()%50)-25.0f)*10.0f;	// Random speed on Y axis
				particle[loop].zi = float((rand()%50)-25.0f)*10.0f;	// Random speed on Z axis
			}
		}
        }

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

	// Create our OpenGL window
	if (!CreateGLWindow("NeHe's Particle Tutorial",640,480,16,fullscreen))
	{
		return 0;               // Quit if window was not created
	}

        if (fullscreen)			// Are we in fullscreen mode ( ADD )
	{
		slowdown = 1.0f;	// Speed up the particles (3dfx Issue) ( ADD )
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
			if ((active && !DrawGLScene()) || keys[VK_ESCAPE])	// Active?  Was there a quit received?
			{
				done = true;					// ESC or DrawGLScene signalled a quit
			}
			else							// Not time to quit, update screen
			{
				SwapBuffers(hDC);				// Swap buffers (Double buffering)

				if (keys[VK_ADD] && (slowdown>1.0f)) slowdown-=0.01f;		// Speed up particles
				if (keys[VK_SUBTRACT] && (slowdown<4.0f)) slowdown+=0.01f;	// Slow down particles

				if (keys[VK_PRIOR])	zoom+=0.1f;		// Zoom in
				if (keys[VK_NEXT])	zoom-=0.1f;		// Zoom out

				if (keys[VK_RETURN] && !rp)			// Return key pressed
				{
					rp = true;				// Set flag telling us it's pressed
					rainbow = !rainbow;			// Toggle rainbow mode On / Off
				}
				if (!keys[VK_RETURN]) rp = false;		// If return is released clear flag

				if ((keys[' '] && !sp) || (rainbow && (delay>25)))      // Space or rainbow mode
				{
					if (keys[' '])	rainbow = false;	// If spacebar is pressed disable rainbow mode
					sp = true;				// Set flag telling us space is pressed
					delay = 0;				// Reset the rainbow color cycling delay
					col++;					// Change the particle color
					if (col>11)	col = 0;		// If color is to high reset it
				}
				if (!keys[' '])	sp=false;			// If spacebar is released clear flag

				// If up arrow and Y speed is less than 200 increase upward speed
				if (keys[VK_UP] && (yspeed<200)) yspeed += 1.0f;

				// If down arrow and Y speed is greater than -200 increase downward speed
				if (keys[VK_DOWN] && (yspeed>-200)) yspeed-=1.0f;

				// If right arrow and X speed is less than 200 increase speed to the right
				if (keys[VK_RIGHT] && (xspeed<200)) xspeed+=1.0f;

				// If left arrow and X speed is greater than -200 increase speed to the left
				if (keys[VK_LEFT] && (xspeed>-200)) xspeed-=1.0f;

				delay++;						// Increase rainbow mode color cycling delay counter

				if (keys[VK_F1])					// Is F1 being pressed?
				{
					keys[VK_F1]=FALSE;				// If so make key FALSE
					KillGLWindow();					// Kill our current window
					fullscreen=!fullscreen;				// Toggle fullscreen / windowed mode
					// Recreate Our OpenGL Window
					if (!CreateGLWindow("NeHe's Particle Tutorial",640,480,16,fullscreen))
					{
						return 0;				// Quit if window was not created
					}
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//---------------------------------------------------------------------------
