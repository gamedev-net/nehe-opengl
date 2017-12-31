/*
 *		This Code Was Created By Jeff Molofee 2000
 *		A HUGE Thanks To Fredric Echols For Cleaning Up
 *		And Optimizing This Code, Making It More Flexible!
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit My Site At nehe.gamedev.net
 */

#include <windows.h>												// Header File For Windows
#include <gl\gl.h>													// Header File For The OpenGL32 Library
#include <gl\glu.h>													// Header File For The GLu32 Library
#include <stdio.h>													// Header for c standard library
#include <mmsystem.h>												// Header for window multi media lib 
#include "glFont.h"													// Header for fonts
#include "glCamera.h"												// Header for the camera class

HDC			hDC=NULL;												// Private GDI Device Context
HGLRC		hRC=NULL;												// Permanent Rendering Context
HWND		hWnd=NULL;												// Holds Our Window Handle
HINSTANCE	hInstance;												// Holds The Instance Of The Application

/////////////// GLOBALS //////////////////////////////////
bool		keys[256];												// Array Used For The Keyboard Routine
bool		active=TRUE;											// Window Active Flag Set To TRUE By Default
bool		fullscreen=TRUE;										// Fullscreen Flag Set To Fullscreen Mode By Default
bool		infoOn=FALSE;
int			gFrames=0;
DWORD		gStartTime;
DWORD		gCurrentTime;
GLfloat		gFPS;
glFont		gFont;
glCamera	gCamera;



//##################  NEW STUFF  ##################################

GLUquadricObj *qobj;			//the quadric for our cylinder
GLint						cylList;

/////////////// PROTOTYPES ///////////////////////////////
LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);				// Declaration For WndProc
void DrawGLInfo(void);
void CheckKeys(void);

bool LoadTexture(LPTSTR szFileName, GLuint &texid)					// Creates Texture From A Bitmap File
{
	HBITMAP hBMP;													// Handle Of The Bitmap
	BITMAP	BMP;													// Bitmap Structure

	glGenTextures(1, &texid);										// Create The Texture
	hBMP=(HBITMAP)LoadImage(GetModuleHandle(NULL), szFileName, IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION | LR_LOADFROMFILE );

	if (!hBMP)														// Does The Bitmap Exist?
		return FALSE;												// If Not Return False

	GetObject(hBMP, sizeof(BMP), &BMP);								// Get The Object
																	// hBMP:        Handle To Graphics Object
																	// sizeof(BMP): Size Of Buffer For Object Information
																	// &BMP:        Buffer For Object Information

	glPixelStorei(GL_UNPACK_ALIGNMENT, 4);							// Pixel Storage Mode (Word Alignment / 4 Bytes)

	// Typical Texture Generation Using Data From The Bitmap
	glBindTexture(GL_TEXTURE_2D, texid);								// Bind To The Texture ID
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// Linear Min Filter
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// Linear Mag Filter
	glTexImage2D(GL_TEXTURE_2D, 0, 3, BMP.bmWidth, BMP.bmHeight, 0, GL_BGR_EXT, GL_UNSIGNED_BYTE, BMP.bmBits);

	DeleteObject(hBMP);												// Delete The Object

	return TRUE;													// Loading Was Successful
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)					// Resize And Initialize The GL Window
{
	gCamera.m_WindowHeight = height;								// The camera needs to know the window height
	gCamera.m_WindowWidth = width;									// The camera needs to know the window width

	if (height==0)													// Prevent A Divide By Zero By
	{
		height=1;													// Making Height Equal One
	}

	glViewport(0,0,width,height);									// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);									// Select The Projection Matrix
	glLoadIdentity();												// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,1.0f,1000.0f);

	glMatrixMode(GL_MODELVIEW);										// Select The Modelview Matrix
	glLoadIdentity();												// Reset The Modelview Matrix
}

int InitGL(GLvoid)													// All Setup For OpenGL Goes Here
{
	GLuint tex=0;

	glShadeModel(GL_SMOOTH);										// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);							// Black Background
	glClearDepth(1.0f);												// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);										// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);											// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);				// Really Nice Perspective Calculations

	LoadTexture("Art/Font.bmp", tex);								// Load the font texture
	if(tex != 0)													// Make sure it was loaded
	{
		gFont.SetFontTexture(tex);									// Set the font texture
		gFont.SetWindowSize(1024, 768);								// The font class needs to know the window size
		gFont.BuildFont(1.0f);					                    // Build the font
	}
	else
	{
		MessageBox(NULL,											// We didn't load the font texture
					"Failed to load font texture.",					// so tell the user about it.
					"Error", 
					MB_OK);
	}

	gCamera.m_MaxHeadingRate = 1.0f;								// Set our Maximum rates for the camera
	gCamera.m_MaxPitchRate = 1.0f;									// Set our Maximum rates for the camera
	gCamera.m_HeadingDegrees = 0.0f;								// Set our Maximum rates for the camera

	// Try and load the HardGlow texture tell the user if we can't find it then quit
	LoadTexture("Art/HardGlow2.bmp", gCamera.m_GlowTexture);
	if(gCamera.m_GlowTexture == 0) {
		MessageBox(NULL, "Failed to load Hard Glow texture.", "Error", MB_OK);
		return(FALSE);
	}
	
	// Try and load the BigGlow texture tell the user if we can't find it then quit
	LoadTexture("Art/BigGlow3.bmp", gCamera.m_BigGlowTexture);
	if(gCamera.m_BigGlowTexture == 0) {
		MessageBox(NULL, "Failed to load Big Glow texture.", "Error", MB_OK);
		return(FALSE);
	}
	
	// Try and load the Halo texture tell the user if we can't find it then quit
	LoadTexture("Art/Halo3.bmp", gCamera.m_HaloTexture);
	if(gCamera.m_HaloTexture == 0) {
		MessageBox(NULL, "Failed to load Halo texture.", "Error", MB_OK);
		return(FALSE);
	}
	
	// Try and load the Streaks texture tell the user if we can't find it then quit
	LoadTexture("Art/Streaks4.bmp", gCamera.m_StreakTexture);
	if(gCamera.m_StreakTexture == 0) {
		MessageBox(NULL, "Failed to load Streaks texture.", "Error", MB_OK);
		return(FALSE);
	}

//##################  NEW STUFF  ##################################

	// Just create a cylinder that will be used as occluder object
	cylList = glGenLists(1);
	qobj = gluNewQuadric();
	gluQuadricDrawStyle(qobj, GLU_FILL); 
	gluQuadricNormals(qobj, GLU_SMOOTH);
	glNewList(cylList, GL_COMPILE);
		glEnable(GL_COLOR_MATERIAL);
		glColor3f(0.0f, 0.0f, 1.0f);
		glEnable(GL_LIGHT0);
		glEnable(GL_LIGHTING);
		glTranslatef(0.0f,0.0f,-2.0f);
		gluCylinder(qobj, 0.5, 0.5, 4.0, 15, 5);
		glDisable(GL_LIGHTING);
		glDisable(GL_LIGHT0);
		glDisable(GL_COLOR_MATERIAL);
	glEndList();

	gStartTime = timeGetTime();										// Get the time the app started

	return TRUE;													// Initialization Went OK
}

int DrawGLScene(GLvoid)												// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);				// Clear Screen And Depth Buffer
	glLoadIdentity();												// Reset The Current Modelview Matrix

	// We want our light source to be 50 units if front 
	// of the camera all the time to make it look like 
	// it is infinately far away from the camera. We only
	// do this to the z coordinate because we want to see
	// the flares adjust if we fly in a straight line.
	gCamera.m_LightSourcePos.z = gCamera.m_Position.z - 50.0f;

	//##################### NEW STUFF ##########################
	// Draw our cylinder and make it "do something"
	// Of course we do that BEFORE testing for occlusion
	// We need our depth buffer to be filled to check against occluder objects
	glPushMatrix();
		glLoadIdentity();
		glTranslatef(0.0f, 0.0f, -20.0f);
		glRotatef(timeGetTime() / 50.0f, 0.3f, 0.0f, 0.0f);
		glRotatef(timeGetTime() / 50.0f, 0.0f, 0.5f, 0.0f);
		glCallList(cylList);
	glPopMatrix();

	gCamera.SetPrespective();										// Set our perspective/oriention on the world
	gCamera.RenderLensFlare();										// Render the lens flare
	gCamera.UpdateFrustumFaster();									// Update the frustum as fast as possible.
	
	if(infoOn == TRUE) {											// Check to see if info has been toggled by 1,2
		DrawGLInfo();												// Info is on so draw the GL information.								
	}

	CheckKeys();													// Check to see if the user pressed any keys.

	return TRUE;
}

GLvoid KillGLWindow(GLvoid)											// Properly Kill The Window
{
	if (fullscreen)													// Are We In Fullscreen Mode?
	{
		ChangeDisplaySettings(NULL,0);								// If So Switch Back To The Desktop
		ShowCursor(TRUE);											// Show Mouse Pointer
	}

	if (hRC)														// Do We Have A Rendering Context?
	{
		if (!wglMakeCurrent(NULL,NULL))								// Are We Able To Release The DC And RC Contexts?
		{
			MessageBox(NULL,"Release Of DC And RC Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))									// Are We Able To Delete The RC?
		{
			MessageBox(NULL,"Release Rendering Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC=NULL;													// Set RC To NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))								// Are We Able To Release The DC
	{
		MessageBox(NULL,"Release Device Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC=NULL;													// Set DC To NULL
	}

	if (hWnd && !DestroyWindow(hWnd))								// Are We Able To Destroy The Window?
	{
		MessageBox(NULL,"Could Not Release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd=NULL;													// Set hWnd To NULL
	}

	if (!UnregisterClass("OpenGL",hInstance))						// Are We Able To Unregister Class
	{
		MessageBox(NULL,"Could Not Unregister Class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance=NULL;												// Set hInstance To NULL
	}
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:					*
 *	title			- Title To Appear At The Top Of The Window				*
 *	width			- Width Of The GL Window Or Fullscreen Mode				*
 *	height			- Height Of The GL Window Or Fullscreen Mode			*
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)			*
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)	*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	GLuint		PixelFormat;									// Holds The Results After Searching For A Match
	WNDCLASS	wc;												// Windows Class Structure
	DWORD		dwExStyle;										// Window Extended Style
	DWORD		dwStyle;										// Window Style
	RECT		WindowRect;										// Grabs Rectangle Upper Left / Lower Right Values
	WindowRect.left=(long)0;									// Set Left Value To 0
	WindowRect.right=(long)width;								// Set Right Value To Requested Width
	WindowRect.top=(long)0;										// Set Top Value To 0
	WindowRect.bottom=(long)height;								// Set Bottom Value To Requested Height

	fullscreen=fullscreenflag;									// Set The Global Fullscreen Flag

	hInstance			= GetModuleHandle(NULL);				// Grab An Instance For Our Window
	wc.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraw On Size, And Own DC For Window.
	wc.lpfnWndProc		= (WNDPROC) WndProc;					// WndProc Handles Messages
	wc.cbClsExtra		= 0;									// No Extra Window Data
	wc.cbWndExtra		= 0;									// No Extra Window Data
	wc.hInstance		= hInstance;							// Set The Instance
	wc.hIcon			= LoadIcon(NULL, IDI_WINLOGO);			// Load The Default Icon
	wc.hCursor			= LoadCursor(NULL, IDC_ARROW);			// Load The Arrow Pointer
	wc.hbrBackground	= NULL;									// No Background Required For GL
	wc.lpszMenuName		= NULL;									// We Don't Want A Menu
	wc.lpszClassName	= "OpenGL";								// Set The Class Name

	if (!RegisterClass(&wc))									// Attempt To Register The Window Class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}
	
	if (fullscreen)												// Attempt Fullscreen Mode?
	{
		DEVMODE dmScreenSettings;								// Device Mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	// Makes Sure Memory's Cleared
		dmScreenSettings.dmSize=sizeof(dmScreenSettings);		// Size Of The Devmode Structure
		dmScreenSettings.dmPelsWidth	= width;				// Selected Screen Width
		dmScreenSettings.dmPelsHeight	= height;				// Selected Screen Height
		dmScreenSettings.dmBitsPerPel	= bits;					// Selected Bits Per Pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
			if (MessageBox(NULL,"The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen=FALSE;								// Windowed Mode Selected.  Fullscreen = FALSE
			}
			else
			{
				// Pop Up A Message Box Letting User Know The Program Is Closing.
				MessageBox(NULL,"Program Will Now Close.","ERROR",MB_OK|MB_ICONSTOP);
				return FALSE;									// Return FALSE
			}
		}
	}

	if (fullscreen)												// Are We Still In Fullscreen Mode?
	{
		dwExStyle=WS_EX_APPWINDOW;								// Window Extended Style
		dwStyle=WS_POPUP;										// Windows Style
		ShowCursor(FALSE);										// Hide Mouse Pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;			// Window Extended Style
		dwStyle=WS_OVERLAPPEDWINDOW;							// Windows Style
	}

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);	// Adjust Window To True Requested Size

	// Create The Window
	if (!(hWnd=CreateWindowEx(	dwExStyle,							// Extended Style For The Window
								"OpenGL",							// Class Name
								title,								// Window Title
								dwStyle |							// Defined Window Style
								WS_CLIPSIBLINGS |					// Required Window Style
								WS_CLIPCHILDREN,					// Required Window Style
								0, 0,								// Window Position
								WindowRect.right-WindowRect.left,	// Calculate Window Width
								WindowRect.bottom-WindowRect.top,	// Calculate Window Height
								NULL,								// No Parent Window
								NULL,								// No Menu
								hInstance,							// Instance
								NULL)))								// Dont Pass Anything To WM_CREATE
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd=							// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),							// Size Of This Pixel Format Descriptor
		1,														// Version Number
		PFD_DRAW_TO_WINDOW |									// Format Must Support Window
		PFD_SUPPORT_OPENGL |									// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,										// Must Support Double Buffering
		PFD_TYPE_RGBA,											// Request An RGBA Format
		bits,													// Select Our Color Depth
		0, 0, 0, 0, 0, 0,										// Color Bits Ignored
		0,														// No Alpha Buffer
		0,														// Shift Bit Ignored
		0,														// No Accumulation Buffer
		0, 0, 0, 0,												// Accumulation Bits Ignored
		16,														// 16Bit Z-Buffer (Depth Buffer)  
		0,														// No Stencil Buffer
		0,														// No Auxiliary Buffer
		PFD_MAIN_PLANE,											// Main Drawing Layer
		0,														// Reserved
		0, 0, 0													// Layer Masks Ignored
	};
	
	if (!(hDC=GetDC(hWnd)))										// Did We Get A Device Context?
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Can't Create A GL Device Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))				// Did Windows Find A Matching Pixel Format?
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Can't Find A Suitable PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))					// Are We Able To Set The Pixel Format?
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Can't Set The PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))							// Are We Able To Get A Rendering Context?
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Can't Create A GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))								// Try To Activate The Rendering Context
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Can't Activate The GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);									// Show The Window
	SetForegroundWindow(hWnd);									// Slightly Higher Priority
	SetFocus(hWnd);												// Sets Keyboard Focus To The Window
	ReSizeGLScene(width, height);								// Set Up Our Perspective GL Screen

	if (!InitGL())												// Initialize Our Newly Created GL Window
	{
		KillGLWindow();											// Reset The Display
		MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}

	return TRUE;												// Success
}

LRESULT CALLBACK WndProc(	HWND	hWnd,						// Handle For This Window
							UINT	uMsg,						// Message For This Window
							WPARAM	wParam,						// Additional Message Information
							LPARAM	lParam)						// Additional Message Information
{
	switch (uMsg)												// Check For Windows Messages
	{
		case WM_ACTIVATE:										// Watch For Window Activate Message
		{
			if (!HIWORD(wParam))								// Check Minimization State
			{
				active=TRUE;									// Program Is Active
			}
			else
			{
				active=FALSE;									// Program Is No Longer Active
			}

			return 0;											// Return To The Message Loop
		}

		case WM_SYSCOMMAND:										// Intercept System Commands
		{
			switch (wParam)										// Check System Calls
			{
				case SC_SCREENSAVE:								// Screensaver Trying To Start?
				case SC_MONITORPOWER:							// Monitor Trying To Enter Powersave?
				return 0;										// Prevent From Happening
			}
			break;												// Exit
		}

		case WM_CLOSE:											// Did We Receive A Close Message?
		{
			PostQuitMessage(0);									// Send A Quit Message
			return 0;											// Jump Back
		}

		case WM_KEYDOWN:										// Is A Key Being Held Down?
		{
			keys[wParam] = TRUE;								// If So, Mark It As TRUE
			return 0;											// Jump Back
		}

		case WM_KEYUP:											// Has A Key Been Released?
		{
			keys[wParam] = FALSE;								// If So, Mark It As FALSE
			return 0;											// Jump Back
		}

		case WM_SIZE:											// Resize The OpenGL Window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));		// LoWord=Width, HiWord=Height
			return 0;											// Jump Back
		}
	}

	// Pass All Unhandled Messages To DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

int WINAPI WinMain(	HINSTANCE	hInstance,						// Instance
					HINSTANCE	hPrevInstance,					// Previous Instance
					LPSTR		lpCmdLine,						// Command Line Parameters
					int			nCmdShow)						// Window Show State
{
	MSG		msg;												// Windows Message Structure
	BOOL	done=FALSE;											// Bool Variable To Exit Loop

	// Ask The User Which Screen Mode They Prefer
	if (MessageBox(NULL,"Would You Like To Run In Fullscreen Mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen=FALSE;										// Windowed Mode
	}

	// Create Our OpenGL Window
	if (!CreateGLWindow("Lens Flare Tutorial",640,480,32,fullscreen))
	{
		return 0;												// Quit If Window Was Not Created
	}

	while(!done)												// Loop That Runs While done=FALSE
	{
		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))				// Is There A Message Waiting?
		{
			if (msg.message==WM_QUIT)							// Have We Received A Quit Message?
			{
				done=TRUE;										// If So done=TRUE
			}
			else												// If Not, Deal With Window Messages
			{
				TranslateMessage(&msg);							// Translate The Message
				DispatchMessage(&msg);							// Dispatch The Message
			}
		}
		else													// If There Are No Messages
		{
			// Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
			if (active)											// Program Active?
			{
				if (keys[VK_ESCAPE])							// Was ESC Pressed?
				{
					done=TRUE;									// ESC Signalled A Quit
				}
				else											// Not Time To Quit, Update Screen
				{
					DrawGLScene();								// Draw The Scene
					SwapBuffers(hDC);							// Swap Buffers (Double Buffering)
				}
			}

			if (keys[VK_F1])									// Is F1 Being Pressed?
			{
				keys[VK_F1]=FALSE;								// If So Make Key FALSE
				KillGLWindow();									// Kill Our Current Window
				fullscreen=!fullscreen;							// Toggle Fullscreen / Windowed Mode
				// Recreate Our OpenGL Window
				if (!CreateGLWindow("NeHe's OpenGL Framework",640,480,16,fullscreen))
				{
					return 0;									// Quit If Window Was Not Created
				}
			}
		}
	}


	//########################### NEW STUFF ##############################à
	// This code is missing a proper unload function  ;D

	gluDeleteQuadric(qobj);							// Delete our quadric object
	glDeleteLists(cylList,1);						// Delete the cylinder list


	// Shutdown
	KillGLWindow();												// Kill The Window
	return (msg.wParam);										// Exit The Program
}

void DrawGLInfo(void)
{
	GLfloat modelMatrix[16];									// This will hold the model view matrix
	GLfloat projMatrix[16];										// This will hold the projection matrix
	GLfloat DiffTime;											// This is will contain the difference in time
	char String[64];											// A temporary string to use to format information
																// that will be printed to the screen.

	glGetFloatv(GL_PROJECTION_MATRIX, projMatrix);				// Grab the projection matrix
	glGetFloatv(GL_MODELVIEW_MATRIX, modelMatrix);				// Grab the modelview matrix

	// Print out the cameras position
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	sprintf(String, "m_Position............. = %.02f, %.02f, %.02f", gCamera.m_Position.x, gCamera.m_Position.y, gCamera.m_Position.z);
	gFont.glPrintf(10, 720, 1, String);
	
	// Print out the cameras direction
	sprintf(String, "m_DirectionVector...... = %.02f, %.02f, %.02f", gCamera.m_DirectionVector.i, gCamera.m_DirectionVector.j, gCamera.m_DirectionVector.k);
	gFont.glPrintf(10, 700, 1, String);
	
	// Print out the light sources position
	sprintf(String, "m_LightSourcePos....... = %.02f, %.02f, %.02f", gCamera.m_LightSourcePos.x, gCamera.m_LightSourcePos.y, gCamera.m_LightSourcePos.z);
	gFont.glPrintf(10, 680, 1, String);

	// Print out the intersection point
	sprintf(String, "ptIntersect............ = %.02f, %.02f, %.02f", gCamera.ptIntersect.x, gCamera.ptIntersect.y, gCamera.ptIntersect.x);
	gFont.glPrintf(10, 660, 1, String);

	// Print out the vector that points from the light source to the camera
	sprintf(String, "vLightSourceToCamera... = %.02f, %.02f, %.02f", gCamera.vLightSourceToCamera.i, gCamera.vLightSourceToCamera.j, gCamera.vLightSourceToCamera.k);
	gFont.glPrintf(10, 640, 1, String);

	// Print out the vector that points from the light source to the intersection point.
	sprintf(String, "vLightSourceToIntersect = %.02f, %.02f, %.02f", gCamera.vLightSourceToIntersect.i, gCamera.vLightSourceToIntersect.j, gCamera.vLightSourceToIntersect.k);
	gFont.glPrintf(10, 620, 1, String);

	// Let everyone know the below matrix is the model view matrix
	sprintf(String, "GL_MODELVIEW_MATRIX");
	gFont.glPrintf(10, 580, 1, String);
	
	// Print out row 1 of the model view matrix
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", modelMatrix[0], modelMatrix[1], modelMatrix[2], modelMatrix[3]);
	gFont.glPrintf(10, 560, 1, String);

	// Print out row 2 of the model view matrix
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", modelMatrix[4], modelMatrix[5], modelMatrix[6], modelMatrix[7]);
	gFont.glPrintf(10, 540, 1, String);

	// Print out row 3 of the model view matrix
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", modelMatrix[8], modelMatrix[9], modelMatrix[10], modelMatrix[11]);
	gFont.glPrintf(10, 520, 1, String);

	// Print out row 4 of the model view matrix
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", modelMatrix[12], modelMatrix[13], modelMatrix[14], modelMatrix[15]);
	gFont.glPrintf(10, 500, 1, String);

	// Let everyone know the below matrix is the projection matrix
	sprintf(String, "GL_PROJECTION_MATRIX");
	gFont.glPrintf(10, 460, 1, String);
	
	// Print out row 1 of the projection view matrix
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", projMatrix[0], projMatrix[1], projMatrix[2], projMatrix[3]);
	gFont.glPrintf(10, 440, 1, String);

	// Print out row 2 of the projection view matrix
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", projMatrix[4], projMatrix[5], projMatrix[6], projMatrix[7]);
	gFont.glPrintf(10, 420, 1, String);

	// Print out row 3 of the projection view matrix
	sprintf(String, "%.02f, %.02f, %.03f, %.03f", projMatrix[8], projMatrix[9], projMatrix[10], projMatrix[11]);
	gFont.glPrintf(10, 400, 1, String);

	// Print out row 4 of the projection view matrix
	sprintf(String, "%.02f, %.02f, %.03f, %.03f", projMatrix[12], projMatrix[13], projMatrix[14], projMatrix[15]);
	gFont.glPrintf(10, 380, 1, String);

	// Let everyone know the below values are the Frustum clipping planes
	gFont.glPrintf(10, 320, 1, "FRUSTUM CLIPPING PLANES");

	// Print out the right clipping plane
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", gCamera.m_Frustum[0][0], gCamera.m_Frustum[0][1], gCamera.m_Frustum[0][2], gCamera.m_Frustum[0][3]);
	gFont.glPrintf(10, 300, 1, String);

	// Print out the left clipping plane
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", gCamera.m_Frustum[1][0], gCamera.m_Frustum[1][1], gCamera.m_Frustum[1][2], gCamera.m_Frustum[1][3]);
	gFont.glPrintf(10, 280, 1, String);

	// Print out the bottom clipping plane
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", gCamera.m_Frustum[2][0], gCamera.m_Frustum[2][1], gCamera.m_Frustum[2][2], gCamera.m_Frustum[2][3]);
	gFont.glPrintf(10, 260, 1, String);

	// Print out the top clipping plane
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", gCamera.m_Frustum[3][0], gCamera.m_Frustum[3][1], gCamera.m_Frustum[3][2], gCamera.m_Frustum[3][3]);
	gFont.glPrintf(10, 240, 1, String);

	// Print out the far clipping plane
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", gCamera.m_Frustum[4][0], gCamera.m_Frustum[4][1], gCamera.m_Frustum[4][2], gCamera.m_Frustum[4][3]);
	gFont.glPrintf(10, 220, 1, String);

	// Print out the near clipping plane
	sprintf(String, "%.02f, %.02f, %.02f, %.02f", gCamera.m_Frustum[5][0], gCamera.m_Frustum[5][1], gCamera.m_Frustum[5][2], gCamera.m_Frustum[5][3]);
	gFont.glPrintf(10, 200, 1, String);

	if(gFrames >= 100)											// if we are due for another FPS update
	{
		gCurrentTime = timeGetTime();							// Get the current time
		DiffTime = GLfloat(gCurrentTime - gStartTime);			// Find the difference between the start and end times
		gFPS = (gFrames / DiffTime) * 1000.0f;					// Compute the FPS
		gStartTime = gCurrentTime;								// Set the current start time to the current time
		gFrames = 1;											// Set the number of frames to 1
	}
	else
	{
		gFrames++;												// We are not due to for another update so add one to the frame count
	}
	
	// Print out the FPS
	sprintf(String, "FPS %.02f", gFPS);
	gFont.glPrintf(10, 160, 1, String);
}

void CheckKeys(void)
{
	if(keys['W'] == TRUE)										// Is the W key down?
	{
		gCamera.ChangePitch(-0.2f);								// Pitch the camera up 0.2 degrees
	}

	if(keys['S'] == TRUE)										// Is the S key down?
	{
		gCamera.ChangePitch(0.2f);								// Pitch the camera down 0.2 degrees
	}
	
	if(keys['D'] == TRUE)										// Is the D key down?
	{
		gCamera.ChangeHeading(0.2f);							// Yaw the camera to the left
	}
	
	if(keys['A'] == TRUE)										// Is the A key down?
	{
		gCamera.ChangeHeading(-0.2f);							// Yaw the camera to the right
	}
	
	if(keys['Z'] == TRUE)										// Is the Z key down?
	{
		gCamera.m_ForwardVelocity = 0.01f;						// Start moving the camera forward 0.01 units every frame
	}
	
	if(keys['C'] == TRUE)										// Is the C key down?
	{
		gCamera.m_ForwardVelocity = -0.01f;						// Start moving the camera backwards 0.01 units every frame
	}
	
	if(keys['X'] == TRUE)										// Is the X key down?
	{
		gCamera.m_ForwardVelocity = 0.0f;						// Stop the camera from moving.
	}

	if(keys['1'] == TRUE)										// Is the 1 key down?
	{
		infoOn = TRUE;											// Toggle info on
	}
	
	if(keys['2'] == TRUE)										// Is the 2 key down?
	{
		infoOn = FALSE;											// Toggle info off
	}
}
