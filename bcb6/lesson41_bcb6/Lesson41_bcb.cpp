//------------------------------------------------------------------------
//
//  This Code Was Created By Jeff Molofee 2003
//	OpenGL Tutorial #41
//  If You've Found This Code Useful, Please Let Me Know.
//  Visit NeHe Productions At http://nehe.gamedev.net
//
//  Translation to CBuilder by Le Thanh Cong (conglt@cardvn.net)
//
//------------------------------------------------------------------------

#include <windows.h> 													// Header File For Windows
#include <gl\gl.h>	 													// Header File For The OpenGL32 Library
#include <gl\glu.h>	 													// Header File For The GLu32 Library
#include <olectl.h>														// Header File For The OLE Controls Library	(Used In BuildTexture)
#include <math.h>														// Header File For The Math Library			(Used In BuildTexture)

#include "NeHeGL.h"	 													// Header File For NeHeGL

#pragma hdrstop
#include <condefs.h>


//---------------------------------------------------------------------------
USEUNIT("NeHeGL.cpp");
//---------------------------------------------------------------------------
#pragma argsused

#ifndef CDS_FULLSCREEN													// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4												// Compilers. By Defining It This Way,
#endif																	// We Can Avoid Errors

GL_Window*	g_window;													// Window Structure
Keys*		g_keys;														// Keyboard
static BOOL g_isProgramLooping;											// Window Creation Loop, For FullScreen/Windowed Toggle																		// Between Fullscreen / Windowed Mode

// User Defined Variables
GLfloat	fogColor[4] = {0.6f, 0.3f, 0.0f, 1.0f};							// Fog Colour 
GLfloat camz;															// Camera Z Depth

// Variables Necessary For FogCoordfEXT
#define GL_FOG_COORDINATE_SOURCE_EXT			0x8450					// Value Taken From GLEXT.H
#define GL_FOG_COORDINATE_EXT					0x8451					// Value Taken From GLEXT.H

typedef void (APIENTRY * PFNGLFOGCOORDFEXTPROC) (GLfloat coord);		// Declare Function Prototype

PFNGLFOGCOORDFEXTPROC glFogCoordfEXT = NULL;							// Our glFogCoordfEXT Function

GLuint	texture[1];														// One Texture (For The Walls)

int BuildTexture(char *szPathName, GLuint &texid)						// Load Image And Convert To A Texture
{
	HDC			hdcTemp;												// The DC To Hold Our Bitmap
	HBITMAP		hbmpTemp;												// Holds The Bitmap Temporarily
	IPicture	*pPicture;												// IPicture Interface
	OLECHAR		wszPath[MAX_PATH+1];									// Full Path To Picture (WCHAR)
	char		szPath[MAX_PATH+1];										// Full Path To Picture
	long		lWidth;													// Width In Logical Units
	long		lHeight;												// Height In Logical Units
	long		lWidthPixels;											// Width In Pixels
	long		lHeightPixels;											// Height In Pixels
	GLint		glMaxTexDim ;											// Holds Maximum Texture Size

	if (strstr(szPathName, "http://"))									// If PathName Contains http:// Then...
	{
		strcpy(szPath, szPathName);										// Append The PathName To szPath
	}
	else																// Otherwise... We Are Loading From A File
	{
		GetCurrentDirectory(MAX_PATH, szPath);							// Get Our Working Directory
		strcat(szPath, "\\");											// Append "\" After The Working Directory
		strcat(szPath, szPathName);										// Append The PathName
	}

	MultiByteToWideChar(CP_ACP, 0, szPath, -1, wszPath, MAX_PATH);		// Convert From ASCII To Unicode
	HRESULT hr = OleLoadPicturePath(wszPath, 0, 0, 0, IID_IPicture, (void**)&pPicture);

	if(FAILED(hr))														// If Loading Failed
		return FALSE;													// Return False

	hdcTemp = CreateCompatibleDC(GetDC(0));								// Create The Windows Compatible Device Context
	if(!hdcTemp)														// Did Creation Fail?
	{
		pPicture->Release();											// Decrements IPicture Reference Count
		return FALSE;													// Return False (Failure)
	}

	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &glMaxTexDim);					// Get Maximum Texture Size Supported
	
	pPicture->get_Width(&lWidth);										// Get IPicture Width (Convert To Pixels)
	lWidthPixels	= MulDiv(lWidth, GetDeviceCaps(hdcTemp, LOGPIXELSX), 2540);
	pPicture->get_Height(&lHeight);										// Get IPicture Height (Convert To Pixels)
	lHeightPixels	= MulDiv(lHeight, GetDeviceCaps(hdcTemp, LOGPIXELSY), 2540);

	// Resize Image To Closest Power Of Two
	if (lWidthPixels <= glMaxTexDim) // Is Image Width Less Than Or Equal To Cards Limit
		lWidthPixels = 1 << (int)floor((log((double)lWidthPixels)/log(2.0f)) + 0.5f); 
	else  // Otherwise  Set Width To "Max Power Of Two" That The Card Can Handle
		lWidthPixels = glMaxTexDim;
 
	if (lHeightPixels <= glMaxTexDim) // Is Image Height Greater Than Cards Limit
		lHeightPixels = 1 << (int)floor((log((double)lHeightPixels)/log(2.0f)) + 0.5f);
	else  // Otherwise  Set Height To "Max Power Of Two" That The Card Can Handle
		lHeightPixels = glMaxTexDim;
	
	//	Create A Temporary Bitmap
	BITMAPINFO	bi = {0};												// The Type Of Bitmap We Request
	DWORD		*pBits = 0;												// Pointer To The Bitmap Bits

	bi.bmiHeader.biSize			= sizeof(BITMAPINFOHEADER);				// Set Structure Size
	bi.bmiHeader.biBitCount		= 32;									// 32 Bit
	bi.bmiHeader.biWidth		= lWidthPixels;							// Power Of Two Width
	bi.bmiHeader.biHeight		= lHeightPixels;						// Make Image Top Up (Positive Y-Axis)
	bi.bmiHeader.biCompression	= BI_RGB;								// RGB Encoding
	bi.bmiHeader.biPlanes		= 1;									// 1 Bitplane

	//	Creating A Bitmap This Way Allows Us To Specify Color Depth And Gives Us Imediate Access To The Bits
	hbmpTemp = CreateDIBSection(hdcTemp, &bi, DIB_RGB_COLORS, (void**)&pBits, 0, 0);
	
	if(!hbmpTemp)														// Did Creation Fail?
	{
		DeleteDC(hdcTemp);												// Delete The Device Context
		pPicture->Release();											// Decrements IPicture Reference Count
		return FALSE;													// Return False (Failure)
	}

	SelectObject(hdcTemp, hbmpTemp);									// Select Handle To Our Temp DC And Our Temp Bitmap Object

	// Render The IPicture On To The Bitmap
	pPicture->Render(hdcTemp, 0, 0, lWidthPixels, lHeightPixels, 0, lHeight, lWidth, -lHeight, 0);

	// Convert From BGR To RGB Format And Add An Alpha Value Of 255
	for(long i = 0; i < lWidthPixels * lHeightPixels; i++)				// Loop Through All Of The Pixels
	{
		BYTE* pPixel	= (BYTE*)(&pBits[i]);							// Grab The Current Pixel
		BYTE  temp		= pPixel[0];									// Store 1st Color In Temp Variable (Blue)
		pPixel[0]		= pPixel[2];									// Move Red Value To Correct Position (1st)
		pPixel[2]		= temp;											// Move Temp Value To Correct Blue Position (3rd)
		pPixel[3]		= 255;											// Set The Alpha Value To 255
	}

	glGenTextures(1, &texid);											// Create The Texture

	// Typical Texture Generation Using Data From The Bitmap
	glBindTexture(GL_TEXTURE_2D, texid);								// Bind To The Texture ID
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);		// (Modify This For The Type Of Filtering You Want)
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);     // (Modify This For The Type Of Filtering You Want)

	// (Modify This If You Want Mipmaps)
	glTexImage2D(GL_TEXTURE_2D, 0, 3, lWidthPixels, lHeightPixels, 0, GL_RGBA, GL_UNSIGNED_BYTE, pBits);

	DeleteObject(hbmpTemp);												// Delete The Object
	DeleteDC(hdcTemp);													// Delete The Device Context

	pPicture->Release();												// Decrements IPicture Reference Count

	return TRUE;														// Return True (All Good)
}

int Extension_Init()
{
	char Extension_Name[] = "EXT_fog_coord";

	// Allocate Memory For Our Extension String
	char* glextstring=(char *)malloc(strlen((char *)glGetString(GL_EXTENSIONS))+1);
	strcpy (glextstring,(char *)glGetString(GL_EXTENSIONS));			// Grab The Extension List, Store In glextstring

	if (!strstr(glextstring,Extension_Name))							// Check To See If The Extension Is Supported
		return FALSE;													// If Not, Return FALSE

	free(glextstring);													// Free Allocated Memory

	// Setup And Enable glFogCoordEXT
	glFogCoordfEXT = (PFNGLFOGCOORDFEXTPROC) wglGetProcAddress("glFogCoordfEXT");

	return TRUE;
}

BOOL Initialize (GL_Window* window, Keys* keys)							// Any GL Init Code & User Initialiazation Goes Here
{
	g_window	= window;												// Window Values
	g_keys		= keys;													// Key Values

	// Start Of User Initialization
	if (!Extension_Init())												// Check And Enable Fog Extension If Available
		return FALSE;													// Return False If Extension Not Supported

	if (!BuildTexture("data/wall.bmp", texture[0]))						// Load The Wall Texture
		return FALSE;													// Return False If Loading Failed

	glEnable(GL_TEXTURE_2D);											// Enable Texture Mapping
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);								// Black Background
	glClearDepth (1.0f);												// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);											// The Type Of Depth Testing
	glEnable (GL_DEPTH_TEST);											// Enable Depth Testing
	glShadeModel (GL_SMOOTH);											// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);					// Set Perspective Calculations To Most Accurate

	// Set Up Fog 
	glEnable(GL_FOG);													// Enable Fog
	glFogi(GL_FOG_MODE, GL_LINEAR);										// Fog Fade Is Linear
	glFogfv(GL_FOG_COLOR, fogColor);									// Set The Fog Color
	glFogf(GL_FOG_START,  1.0f);										// Set The Fog Start
	glFogf(GL_FOG_END,    0.0f);										// Set The Fog End
	glHint(GL_FOG_HINT, GL_NICEST);										// Per-Pixel Fog Calculation
	glFogi(GL_FOG_COORDINATE_SOURCE_EXT, GL_FOG_COORDINATE_EXT);		// Set Fog Based On Vertice Coordinates

	camz =	-19.0f;														// Set Camera Z Position To -19.0f

	return TRUE;														// Return TRUE (Initialization Successful)
}

void Deinitialize (void)												// Any User DeInitialization Goes Here
{
}

void Update (DWORD milliseconds)										// Perform Motion Updates Here
{
	if (g_keys->keyDown [VK_ESCAPE])									// Is ESC Being Pressed?
		TerminateApplication (g_window);								// Terminate The Program

	if (g_keys->keyDown [VK_F1])										// Is F1 Being Pressed?
		ToggleFullscreen (g_window);									// Toggle Fullscreen Mode

	if (g_keys->keyDown [VK_UP] && camz<14.0f)							// Is UP Arrow Being Pressed?
		camz+=(float)(milliseconds)/100.0f;								// Move Object Closer (Move Forwards Through Hallway)

	if (g_keys->keyDown [VK_DOWN] && camz>-19.0f)						// Is DOWN Arrow Being Pressed?
		camz-=(float)(milliseconds)/100.0f;								// Move Object Further (Move Backwards Through Hallway)
}

void Draw (void)
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);				// Clear Screen And Depth Buffer
	glLoadIdentity ();													// Reset The Modelview Matrix

	glTranslatef(0.0f, 0.0f, camz);										// Move To Our Camera Z Position

	// glFogCoordEXT is very similar to glVertex3f. If you understand
	// the way vertexs are applied in OpenGL, you will not have any dificulty
	// understanding glFogCoordEXT.

	// In this tutorial we are applyng the fog in a corridor, so the fog
	// goes from the less density (the minor z) to a bigger density (the biggest z).
	// If you check the fog_start and fog_eng, it's 0 and 1.

	// So, we will pass to the function glFogCoordEXT, the fog value corresponding
	// with the glVertex3f value.If we are drawing a quad from z minus to z major, 
	// we do exactly the same with glFogCoord.

	// For example, in the first quad, is vertex coordinates in the Z field are all 
	// -15.0f. So we want the fog to completely fill this quad, so we assign 0 to all
	// the glFogCoordExt.
	
	glBegin(GL_QUADS);													// Back Wall
	 	glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f, 2.5f,-15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Floor
	 	glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f,-2.5f, 15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f,-2.5f, 15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Roof
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f, 2.5f, 15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f, 2.5f, 15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Right Wall
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f( 2.5f,-2.5f, 15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f( 2.5f, 2.5f, 15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f,-2.5f,-15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Left Wall
	 	glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f,-2.5f, 15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f, 2.5f, 15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f(-2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f(-2.5f,-2.5f,-15.0f);
	glEnd();
 
	glFlush ();															// Flush The GL Rendering Pipeline
}

// Process Window Message Callbacks
LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	DWORD				tickCount;										// Used For The Tick Counter

	// Get The Window Context
	GL_Window* window = (GL_Window*)(GetWindowLong (hWnd, GWL_USERDATA));

	switch (uMsg)														// Evaluate Window Message
	{
		case WM_PAINT:													// Window Needs Updating
		{
			tickCount = GetTickCount ();								// Get The Tick Count
			Update (tickCount - window->lastTickCount);					// Update The Counter
			window->lastTickCount = tickCount;							// Set Last Count To Current Count
			Draw ();													// Draw Our Scene
			SwapBuffers (window->hDC);									// Swap Buffers (Double Buffering)
		}
		return 0;														// Return

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
	windowClass.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);				// Class Background Brush Color
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

	// Fill Out Application Data
	application.className = "OpenGL";									// Application Class Name
	application.hInstance = hInstance;									// Application Instance

	// Fill Out Window
	ZeroMemory (&window, sizeof (GL_Window));							// Make Sure Memory Is Zeroed
	window.keys					= &keys;								// Window Key Structure
	window.init.application		= &application;							// Window Application

	// Window Title
	window.init.title			= "NeHe's Volumetric Fog Tutorial";		// Tutorial Title

	window.init.width			= 640;									// Window Width
	window.init.height			= 480;									// Window Height
	window.init.bitsPerPixel	= 32;									// Bits Per Pixel
	window.init.isFullScreen	= TRUE;									// Fullscreen? (Set To TRUE)

	ZeroMemory (&keys, sizeof (Keys));									// Zero keys Structure

	// Ask The User If They Want To Start In FullScreen Mode? (Remove These 4 Lines If You Want To Force Fullscreen)
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
			if (Initialize (&window, &keys) == FALSE)					// Call User Initialization
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
