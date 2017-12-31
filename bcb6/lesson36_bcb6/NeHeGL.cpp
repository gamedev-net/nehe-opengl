/***********************************************
*                                              *
*    Jeff Molofee's Revised OpenGL Basecode    *
*  Huge Thanks To Maxwell Sayles & Peter Puck  *
*            http://nehe.gamedev.net           *
*                     2001                     *
*                                              *
***********************************************/

#include <windows.h>	// Header file for the windows library
#include <gl/gl.h>	// Header file for the OpenGL32 library
#include <gl/glu.h>	// Header file for the GLu32 library
#include "NeHeGL.h"	// Header file for the NeHeGL basecode

#define WM_TOGGLEFULLSCREEN (WM_USER+1)		// Application define message for toggling
						// Between fullscreen / windowed mode
static BOOL g_isProgramLooping;			// Window creation loop, for fullScreen / windowed toggle																		// Between Fullscreen / Windowed Mode
static BOOL g_createFullScreen;			// If true, then create fullscreen

void TerminateApplication (GL_Window* window)		// Terminate the application
{
	PostMessage (window->hWnd, WM_QUIT, 0, 0);	// Send a WM_QUIT message
	g_isProgramLooping = FALSE;			// Stop looping of the program
}

void ToggleFullscreen (GL_Window* window)	// Toggle fullscreen / windowed
{
	PostMessage (window->hWnd, WM_TOGGLEFULLSCREEN, 0, 0);		// Send a WM_TOGGLEFULLSCREEN message
}

void ReshapeGL (int width, int height)					// Reshape the window when it's moved or resized
{
	glViewport (0, 0, (GLsizei)(width), (GLsizei)(height));		// Reset the current viewport
	glMatrixMode (GL_PROJECTION);					// Select the projection matrix
	glLoadIdentity ();													// Reset The Projection Matrix
	gluPerspective (45.0f, (GLfloat)(width)/(GLfloat)(height),	// Calculate the aspect ratio of the window
					1.0f, 100.0f);
	glMatrixMode (GL_MODELVIEW);					// Select the modelview matrix
	glLoadIdentity ();													// Reset The Modelview Matrix
}

BOOL ChangeScreenResolution (int width, int height, int bitsPerPixel)	// Change the screen resolution
{
	DEVMODE dmScreenSettings;					        // Device mode
	ZeroMemory (&dmScreenSettings, sizeof (DEVMODE));			// Make sure memory is cleared
	dmScreenSettings.dmSize				= sizeof (DEVMODE);	// Size of the devmode structure
	dmScreenSettings.dmPelsWidth		= width;			// Select screen width
	dmScreenSettings.dmPelsHeight		= height;			// Select screen height
	dmScreenSettings.dmBitsPerPel		= bitsPerPixel;			// Select bits per pixel
	dmScreenSettings.dmFields			= DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT;
	if (ChangeDisplaySettings (&dmScreenSettings, CDS_FULLSCREEN) != DISP_CHANGE_SUCCESSFUL)
	{
		return FALSE;				// Display change failed, return false
	}
	return TRUE;					// Display change was successful, return true
}

BOOL CreateWindowGL (GL_Window* window)			// This code creates our OpenGL window
{
	DWORD windowStyle = WS_OVERLAPPEDWINDOW;	// Define our window style
	DWORD windowExtendedStyle = WS_EX_APPWINDOW;	// Define the window's extended style

	ShowCursor(FALSE);
	PIXELFORMATDESCRIPTOR pfd =			// pfd tells windows how we want things to be
	{
		sizeof (PIXELFORMATDESCRIPTOR),		// Size of this pixel format descriptor
		1,					// Version number
		PFD_DRAW_TO_WINDOW |			// Format must support window
		PFD_SUPPORT_OPENGL |			// Format must support OpenGL
		PFD_DOUBLEBUFFER,			// Must support double buffering
		PFD_TYPE_RGBA,				// Request an RGBA format
		window->init.bitsPerPixel,		// Select our color depth
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

	RECT windowRect = {0, 0, window->init.width, window->init.height};	// Define our window coordinates

	GLuint PixelFormat;				// Will hold the selected pixel format

	if (window->init.isFullScreen == TRUE)		// Fullscreen requested, try changing video modes
	{
		if (ChangeScreenResolution (window->init.width, window->init.height, window->init.bitsPerPixel) == FALSE)
		{
			// Fullscreen Mode Failed.  Run In Windowed Mode Instead
			MessageBox (HWND_DESKTOP, "Mode Switch Failed.\nRunning In Windowed Mode.", "Error", MB_OK | MB_ICONEXCLAMATION);
			window->init.isFullScreen = FALSE;	// Set isFullscreen to false (Windowed mode)
		}
		else						// Otherwise (If fullscreen mode was successful)
		{
			windowStyle = WS_POPUP;			// Set the windowStyle to WS_POPUP (Popup window)
			windowExtendedStyle |= WS_EX_TOPMOST;	// Set the extended window style to WS_EX_TOPMOST
		}						// (Top window covering everything else)
	}
	else							// If fullscreen was not selected
	{
		// Adjust window, account for window borders
		AdjustWindowRectEx (&windowRect, windowStyle, 0, windowExtendedStyle);
	}

	// Create The OpenGL Window
	window->hWnd = CreateWindowEx (windowExtendedStyle,	// Extended style
								   window->init.application->className,	// Class name
								   window->init.title,			// Window title
								   windowStyle,				// Window style
								   0, 0,				// Window X,Y position
								   windowRect.right - windowRect.left,	// Window width
								   windowRect.bottom - windowRect.top,	// Window height
								   HWND_DESKTOP,			// Desktop is window's parent
								   0,					// No menu
								   window->init.application->hInstance, // Pass the window instance
								   window);

	if (window->hWnd == 0)			// Was window creation a success?
	{
		return FALSE;			// If not return false
	}

	window->hDC = GetDC (window->hWnd);	// Grab a device context for this window
	if (window->hDC == 0)			// Did we get a device context?
	{
		// Failed
		DestroyWindow (window->hWnd);	// Destroy the window
		window->hWnd = 0;		// Zero the window handle
		return FALSE;			// Return false
	}

	PixelFormat = ChoosePixelFormat (window->hDC, &pfd);	// Find a compatible pixel format
	if (PixelFormat == 0)					// Did we find a compatible format?
	{
		// Failed
		ReleaseDC (window->hWnd, window->hDC);		// Release our device context
		window->hDC = 0;				// Zero the device context
		DestroyWindow (window->hWnd);			// Destroy the window
		window->hWnd = 0;				// Zero the window handle
		return FALSE;					// Return false
	}

	if (SetPixelFormat (window->hDC, PixelFormat, &pfd) == FALSE)	// Try to set the pixel format
	{
		// Failed
		ReleaseDC (window->hWnd, window->hDC);		// Release our device context
		window->hDC = 0;				// Zero the device context
		DestroyWindow (window->hWnd);			// Destroy the window
		window->hWnd = 0;				// Zero the window handle
		return FALSE;					// Return false
	}

	window->hRC = wglCreateContext (window->hDC);		// Try to get a rendering context
	if (window->hRC == 0)					// Did we get a rendering context?
	{
		// Failed
		ReleaseDC (window->hWnd, window->hDC);		// Release our device context
		window->hDC = 0;				// Zero the device context
		DestroyWindow (window->hWnd);			// Destroy the window
		window->hWnd = 0;				// Zero the window handle
		return FALSE;					// Return false
	}

	// Make The Rendering Context Our Current Rendering Context
	if (wglMakeCurrent (window->hDC, window->hRC) == FALSE)
	{
		// Failed
		wglDeleteContext (window->hRC);			// Delete the rendering context
		window->hRC = 0;				// Zero the rendering context
		ReleaseDC (window->hWnd, window->hDC);		// Release our device context
		window->hDC = 0;				// Zero the device context
		DestroyWindow (window->hWnd);			// Destroy the window
		window->hWnd = 0;				// Zero the window handle
		return FALSE;					// Return false
	}

	ShowWindow (window->hWnd, SW_NORMAL);			// Make the window visible
	window->isVisible = TRUE;				// Set isVisible to true

	ReshapeGL (window->init.width, window->init.height);	// Reshape our GL window

	ZeroMemory (window->keys, sizeof (Keys));		// Clear all keys

	window->lastTickCount = GetTickCount ();		// Get tick count

	return TRUE;						// Window creating was a success
								// Initialization will be done in WM_CREATE
}

BOOL DestroyWindowGL (GL_Window* window)			// Destroy the OpenGL window & release resources
{
	if (window->hWnd != 0)					// Does the window have a handle?
	{
		if (window->hDC != 0)				// Does the window have a device context?
		{
			wglMakeCurrent (window->hDC, 0);	// Set the current active rendering context to zero
			if (window->hRC != 0)			// Does the window have a rendering context?
			{
				wglDeleteContext (window->hRC);	// Release the rendering context
				window->hRC = 0;		// Zero the rendering context

			}
			ReleaseDC (window->hWnd, window->hDC);	// Release the device context
			window->hDC = 0;			// Zero the device context
		}
		DestroyWindow (window->hWnd);			// Destroy the window
		window->hWnd = 0;				// Zero the window handle
	}

	if (window->init.isFullScreen)				// Is window in fullscreen mode
	{
		ChangeDisplaySettings (NULL,0);			// Switch back to desktop resolution
	}
	ShowCursor(TRUE);
	return TRUE;						// Return true
}

// Process window message callbacks
LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// Get the window context
	GL_Window* window = (GL_Window*)(GetWindowLong (hWnd, GWL_USERDATA));

	switch (uMsg)					// Evaluate window message
	{
		case WM_SYSCOMMAND:			// Intercept system commands
		{
			switch (wParam)			// Check system calls
			{
				case SC_SCREENSAVE:	// Screensaver trying to start?
				case SC_MONITORPOWER:	// Monitor trying to enter powersave?
				return 0;		// Prevent from happening
			}
			break;				// Exit
		}
		return 0;				// Return

		case WM_CREATE:				// Window creation
		{
			CREATESTRUCT* creation = (CREATESTRUCT*)(lParam);	// Store Window Structure Pointer
			window = (GL_Window*)(creation->lpCreateParams);
			SetWindowLong (hWnd, GWL_USERDATA, (LONG)(window));
		}
		return 0;						// Return

		case WM_CLOSE:						// Closing the window
			TerminateApplication(window);			// Terminate the application
		return 0;						// Return

		case WM_SIZE:						// Size action has taken place
			switch (wParam)					// Evaluate size action
			{
				case SIZE_MINIMIZED:			// Was window minimized?
					window->isVisible = FALSE;	// Set isVisible to false
				return 0;				// Return

				case SIZE_MAXIMIZED:			// Was window maximized?
					window->isVisible = TRUE;	// Set isVisible to true
					ReshapeGL (LOWORD (lParam), HIWORD (lParam));	// Reshape window - LoWord = Width, HiWord = Height
				return 0;						// Return

				case SIZE_RESTORED:					// Was window restored?
					window->isVisible = TRUE;			// Set isVisible to true
					ReshapeGL (LOWORD (lParam), HIWORD (lParam));	// Reshape window - LoWord = Width, HiWord = Height
				return 0;				// Return
			}
		break;							// Break

		case WM_KEYDOWN:					// Update keyboard buffers for keys pressed
			if ((wParam >= 0) && (wParam <= 255))		// Is key (wParam) in a valid range?
			{
				window->keys->keyDown [wParam] = TRUE;	// Set the selected key (wParam) to true
				return 0;				// Return
			}
		break;							// Break

		case WM_KEYUP:						// Update keyboard buffers for keys released
			if ((wParam >= 0) && (wParam <= 255))		// Is key (wParam) in a valid range?
			{
				window->keys->keyDown [wParam] = FALSE;	// Set the selected key (wParam) to false
				return 0;				// Return
			}
		break;							// Break

		case WM_TOGGLEFULLSCREEN:				// Toggle fullScreen mode on/off
			g_createFullScreen = (g_createFullScreen == TRUE) ? FALSE : TRUE;
			PostMessage (hWnd, WM_QUIT, 0, 0);
		break;							// Break
	}

	return DefWindowProc (hWnd, uMsg, wParam, lParam);		// Pass unhandled messages to DefWindowProc
}

BOOL RegisterWindowClass (Application* application)             // Register a window class for this application.
{								// TRUE if successful
	// Register A Window Class
	WNDCLASSEX windowClass;						                // Window class
	ZeroMemory (&windowClass, sizeof (WNDCLASSEX));					// Make sure memory is cleared
	windowClass.cbSize			= sizeof (WNDCLASSEX);			// Size of the windowClass structure
	windowClass.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraws the window for any movement / resizing
	windowClass.lpfnWndProc		= (WNDPROC)(WindowProc);			// WindowProc handles messages
	windowClass.hInstance		= application->hInstance;			// Set the instance
	windowClass.hbrBackground	= (HBRUSH)(COLOR_APPWORKSPACE);			// Class background brush color
	windowClass.hCursor			= LoadCursor(NULL, IDC_ARROW);		// Load the arrow pointer
	windowClass.lpszClassName	= application->className;			// Sets the applications classname
	if (RegisterClassEx (&windowClass) == 0)					// Did registering the class fail?
	{
		// NOTE: Failure, Should Never Happen
		MessageBox (HWND_DESKTOP, "RegisterClassEx Failed!", "Error", MB_OK | MB_ICONEXCLAMATION);
		return FALSE;		// Return false (Failure)
	}
	return TRUE;			// Return true (Success)
}

// Program Entry (WinMain)
int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	Application			application;		// Application structure
	GL_Window			window;			// Window structure
	Keys				keys;			// Key structure
	BOOL				isMessagePumpActive;	// Message pump active?
	MSG					msg;		// Window message structure
	DWORD				tickCount;		// Used for the tick counter

	// Fill Out Application Data
	application.className = "OpenGL";			// Application class name
	application.hInstance = hInstance;			// Application instance

	// Fill Out Window
	ZeroMemory (&window, sizeof (GL_Window));				// Make sure memory is zeroed
	window.keys					= &keys;		// Window key structure
	window.init.application		= &application;				// Window application
	window.init.title			= "rIO And NeHe's RadialBlur Tutorial.";        // Window title
	window.init.width			= 640;				// Window width
	window.init.height			= 480;				// Window height
	window.init.bitsPerPixel	= 16;					// Bits per pixel
	window.init.isFullScreen	= TRUE;					// Fullscreen? (Set to TRUE)

	ZeroMemory (&keys, sizeof (Keys));					// Zero keys structure

	// Ask the user if they want to start in fullscreen mode?
	if (MessageBox (HWND_DESKTOP, "Would you like to run in fullscreen mode?", "Start FullScreen?", MB_YESNO | MB_ICONQUESTION) == IDNO)
	{
		window.init.isFullScreen = FALSE;				// If not, run in windowed mode
	}

	// Register a class for our window to use
	if (RegisterWindowClass (&application) == FALSE)			// Did registering a class fail?
	{
		// Failure
		MessageBox (HWND_DESKTOP, "Error Registering Window Class!", "Error", MB_OK | MB_ICONEXCLAMATION);
		return -1;							// Terminate application
	}

	g_isProgramLooping = TRUE;						// Program looping is set to TRUE
	g_createFullScreen = window.init.isFullScreen;				// g_createFullScreen is set to user default
	while (g_isProgramLooping)						// Loop until WM_QUIT is received
	{
		// Create a window
		window.init.isFullScreen = g_createFullScreen;			// Set init param of window creation to fullscreen?
		if (CreateWindowGL (&window) == TRUE)				// Was window creation successful?
		{
			// At this point we should have a window that is setup to render OpenGL
			if (Initialize (&window, &keys) == FALSE)		// Call user intialization
			{
				// Failure
				TerminateApplication(&window);			// Close window, this will handle the shutdown
			}
			else							// Otherwise (Start the message pump)
			{	// Initialize was a success
				isMessagePumpActive = TRUE;			// Set isMessagePumpActive yo TRUE
				while (isMessagePumpActive == TRUE)		// While the message pump is sctive
				{
					// Success creating window. Check for window messages
					if (PeekMessage (&msg, window.hWnd, 0, 0, PM_REMOVE) != 0)
					{
						// Check For WM_QUIT Message
						if (msg.message != WM_QUIT)		// Is the message a WM_QUIT message?
						{
							DispatchMessage (&msg);		// If not, dispatch the message
						}
						else					// Otherwise (If message is WM_QUIT)
						{
							isMessagePumpActive = FALSE;	// Terminate the message pump
						}
					}
					else						// If there are no messages
					{
						if (window.isVisible == FALSE)		// If window is not visible
						{
							WaitMessage ();			// Application is minimized wait for a message
						}
						else					// If window is visible
						{
							// Process Application Loop
							tickCount = GetTickCount ();			// Get the tick count
							Update (tickCount - window.lastTickCount);	// Update the counter
							window.lastTickCount = tickCount;		// Set last count to current count
							Draw ();					// Draw our scene

							SwapBuffers (window.hDC);	// Swap buffers (Double buffering)
						}
					}
				}			// Loop While isMessagePumpActive == TRUE
			}				// If (Initialize (...

			// Application is finished
			Deinitialize ();		// User defined deinitialization

			DestroyWindowGL (&window);	// Destroy the active window
		}
		else					// If window creation failed
		{
			// Error creating window
			MessageBox (HWND_DESKTOP, "Error Creating OpenGL Window", "Error", MB_OK | MB_ICONEXCLAMATION);
			g_isProgramLooping = FALSE;	// Terminate the loop
		}
	}						// While (isProgramLooping)

	UnregisterClass (application.className, application.hInstance);		// Unregister window class
	return 0;
}               // End of WinMain()
