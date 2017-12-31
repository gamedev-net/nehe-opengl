//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <math.h>	// Header file for windows math library		( ADD )
#include <stdio.h>	// Header file for standard Input/Output	( ADD )
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

GLuint base;			// Base Display List For The Font
GLuint texture[2];		// Storage For Our Font Texture
GLuint loop;			// Generic Loop Variable

GLfloat	cnt1;			// 1st counter used to move text & for coloring
GLfloat	cnt2;			// 2nd counter used to move text & for coloring

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

AUX_RGBImageRec *LoadBMP(char *Filename)        // Loads a bitmap image
{
	FILE *File = NULL;              // File handle

	if (!Filename)		        // Make sure a filename was given
	{
		return NULL;	        // If not return NULL
	}

	File = fopen(Filename,"r");	// Check to see if the file exists

	if (File)			// Does the file exist?
	{
		fclose(File);		// Close the handle
		return auxDIBImageLoad(Filename);       // Load the bitmap and return a pointer
	}

	return NULL;                    // If load failed return NULL
}

int LoadGLTextures()                                    // Load bitmaps and convert to textures
{
        int Status = false;                             // Status indicator
        AUX_RGBImageRec *TextureImage[2];               // Create storage space for the textures
        memset(TextureImage,0,sizeof(void *)*2);        // Set the pointer to NULL

        if ((TextureImage[0] = LoadBMP("Data/Font.bmp")) &&
			(TextureImage[1] = LoadBMP("Data/Bumps.bmp")))
        {
                Status = true;                          // Set the status to TRUE
                glGenTextures(2, &texture[0]);          // Create two texture

                for (loop = 0; loop < 2; loop++)
                {
	                glBindTexture(GL_TEXTURE_2D, texture[loop]);
                        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
                        glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[loop]->sizeX, TextureImage[loop]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[loop]->data);
                }
        }

	for (loop = 0; loop < 2; loop++)
	{
	        if (TextureImage[loop])					// If texture exists
                {
		        if (TextureImage[loop]->data)			// If texture image exists
                        {
                                free(TextureImage[loop]->data);         // Free the texture image memory
                        }
                        free(TextureImage[loop]);			// Free the image structure
		}
	}
        return Status;          // Return the status
}

GLvoid BuildFont(GLvoid)        // Build our font display list
{
	float	cx;				                	// Holds our X character coord
	float	cy;				                	// Holds our Y character coord

	base = glGenLists(256);                                         // Creating 256 display lists
	glBindTexture(GL_TEXTURE_2D, texture[0]);               	// Select our font texture
	for (loop = 0; loop < 256; loop++)		                // Loop through all 256 lists
	{
		cx = float(loop%16)/16.0f;	                	// X position of current character
		cy = float(loop/16)/16.0f;	                	// Y position of current character

		glNewList(base+loop,GL_COMPILE);	                // Start building a list
			glBegin(GL_QUADS);		                // Use a quad for each character
				glTexCoord2f(cx,1-cy-0.0625f);		// Texture coord (bottom left)
				glVertex2i(0,0);			// Vertex coord (Bottom left)
				glTexCoord2f(cx+0.0625f,1-cy-0.0625f);	// Texture coord (Bottom right)
				glVertex2i(16,0);			// Vertex coord (Bottom right)
				glTexCoord2f(cx+0.0625f,1-cy);		// Texture coord (Top right)
				glVertex2i(16,16);			// Vertex coord (Top right)
				glTexCoord2f(cx,1-cy);			// Texture coord (Top left)
				glVertex2i(0,16);			// Vertex coord (Top left)
			glEnd();					// Done building our quad (Character)
			glTranslated(10,0,0);				// Move to the right of the character
		glEndList();						// Done building the display list
	}								// Loop until all 256 are built
}

GLvoid KillFont(GLvoid)							// Delete the font from memory
{
	glDeleteLists(base,256);					// Delete all 256 display lists
}

GLvoid glPrint(GLint x, GLint y, char *string, int set)	// Where the printing happens
{
	if (set > 1)
	{
		set = 1;
	}
	glBindTexture(GL_TEXTURE_2D, texture[0]);	// Select our font texture
	glDisable(GL_DEPTH_TEST);			// Disables depth testing
	glMatrixMode(GL_PROJECTION);			// Select the projection matrix
	glPushMatrix();					// Store the projection matrix
	glLoadIdentity();				// Reset the projection matrix
	glOrtho(0,640,0,480,-1,1);			// Set up an ortho screen
	glMatrixMode(GL_MODELVIEW);			// Select the modelview matrix
	glPushMatrix();					// Store the modelview matrix
	glLoadIdentity();				// Reset the modelview matrix
	glTranslated(x,y,0);				// Position the text (0,0 - Bottom left)
	glListBase(base-32+(128*set));			// Choose the font set (0 or 1)
	glCallLists(strlen(string),GL_BYTE,string);	// Write the text to the screen
	glMatrixMode(GL_PROJECTION);			// Select the projection matrix
	glPopMatrix();					// Restore the old projection matrix
	glMatrixMode(GL_MODELVIEW);			// Select the modelview matrix
	glPopMatrix();					// Restore the old projection matrix
	glEnable(GL_DEPTH_TEST);			// Enables depth testing
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
        if (!LoadGLTextures())                  // Jump to texture loading routine
	{
		return false;			// If texture didn't load return FALSE
	}

        BuildFont();				// Build the font

	glShadeModel(GL_SMOOTH);                // Enable smooth shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);   // Black background
	glClearDepth(1.0f);                     // Depth buffer setup
	glDepthFunc(GL_LEQUAL);                 // The type of depth testing to do
        glBlendFunc(GL_SRC_ALPHA,GL_ONE);	// Select the type of blending
        glEnable(GL_TEXTURE_2D);		// Enable 2D texture mapping

	return true;                            // Initialization went OK
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// clear screen and depth buffer
	glLoadIdentity();       // Reset the current modelview matrix

        glBindTexture(GL_TEXTURE_2D, texture[1]);		// Select our second texture
	glTranslatef(0.0f,0.0f,-5.0f);				// Move into the screen 5 units
	glRotatef(45.0f,0.0f,0.0f,1.0f);			// Rotate on the Z axis 45 degrees (Clockwise)

        glRotatef(cnt1*30.0f,1.0f,1.0f,0.0f);			// Rotate on the X & Y axis by cnt1 (Left to right)

        glDisable(GL_BLEND);					// Disable blending before ee draw in 3D
	glColor3f(1.0f,1.0f,1.0f);				// Bright white
	glBegin(GL_QUADS);					// Draw our first texture mapped quad
		glTexCoord2d(0.0f,0.0f);			// First texture coord
		glVertex2f(-1.0f, 1.0f);			// First vertex
		glTexCoord2d(1.0f,0.0f);			// Second texture coord
		glVertex2f( 1.0f, 1.0f);			// Second vertex
		glTexCoord2d(1.0f,1.0f);			// Third texture coord
		glVertex2f( 1.0f,-1.0f);			// Third vertex
		glTexCoord2d(0.0f,1.0f);			// Fourth texture coord
		glVertex2f(-1.0f,-1.0f);			// Fourth vertex
	glEnd();

        glRotatef(90.0f,1.0f,1.0f,0.0f);			// Rotate on the X & Y axis by 90 degrees (Left to right)
	glBegin(GL_QUADS);					// Draw our second texture mapped quad
		glTexCoord2d(0.0f,0.0f);			// First texture coord
		glVertex2f(-1.0f, 1.0f);			// First vertex
		glTexCoord2d(1.0f,0.0f);			// Second texture coord
		glVertex2f( 1.0f, 1.0f);			// Second vertex
		glTexCoord2d(1.0f,1.0f);			// Third texture coord
		glVertex2f( 1.0f,-1.0f);			// Third vertex
		glTexCoord2d(0.0f,1.0f);			// Fourth texture coord
		glVertex2f(-1.0f,-1.0f);			// Fourth vertex
	glEnd();

        glEnable(GL_BLEND);					// Enable blending
	glLoadIdentity();					// Reset the view

        // Pulsing colors based on text position
	glColor3f(1.0f*float(cos(cnt1)),1.0f*float(sin(cnt2)),1.0f-0.5f*float(cos(cnt1+cnt2)));

        glPrint(int((280+250*cos(cnt1))),int(235+200*sin(cnt2)),"NeHe",0);	// Print GL text to the screen

	glColor3f(1.0f*float(sin(cnt2)),1.0f-0.5f*float(cos(cnt1+cnt2)),1.0f*float(cos(cnt1)));
	glPrint(int((280+230*cos(cnt2))),int(235+200*sin(cnt1)),"OpenGL",1);	// Print GL text to the screen

        glColor3f(0.0f,0.0f,1.0f);						// Set color to blue
	glPrint(int(240+200*cos((cnt2+cnt1)/5)),2,"Giuseppe D'Agata",0);	// Draw text to the screen

	glColor3f(1.0f,1.0f,1.0f);						// Set color to white
	glPrint(int(242+200*cos((cnt2+cnt1)/5)),2,"Giuseppe D'Agata",0);	// Draw offset text to the screen

        cnt1 += 0.01f;								// Increase the first counter
	cnt2 += 0.0081f;							// Increase the second counter

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

        KillFont();                     // Destroy the font
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
	if (!CreateGLWindow("NeHe & Giuseppe D'Agata's 2D Font Tutorial",640,480,16,fullscreen))
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
			if ((active && !DrawGLScene()) || keys[VK_ESCAPE])	// Active?  Was there a quit received?
			{
				done = true;					// ESC or DrawGLScene signalled a quit
			}
			else							// Not time to quit, update screen
			{
				SwapBuffers(hDC);				// Swap buffers (Double buffering)
			}

			if (keys[VK_F1])                        // Is F1 being pressed?
			{
				keys[VK_F1] = false;            // If so make key FALSE
				KillGLWindow();                 // Kill our current window
				fullscreen =! fullscreen;       // Toggle fullscreen / windowed mode
				// Recreate our OpenGL window
				if (!CreateGLWindow("NeHe & Giuseppe D'Agata's 2D Font Tutorial",640,480,16,fullscreen))
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
