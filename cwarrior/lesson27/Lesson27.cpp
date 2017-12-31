/*		This code has been created by Banu Octavian aka Choko - 20 may 2000
 *		and uses NeHe tutorials as a starting point (window initialization,
 *		texture loading, GL initialization and code for keypresses) - very good
 *		tutorials, Jeff. If anyone is interested about the presented algorithm
 *		please e-mail me at boct@romwest.ro
 *		Attention!!! This code is not for beginners.
 */

#include <windows.h>									// Header File For Windows
#include <gl\gl.h>										// Header File For The OpenGL32 Library
#include <gl\glu.h>										// Header File For The GLu32 Library
#include <gl\glaux.h>									// Header File For The Glaux Library
#include "3dobject.h"									// Header File For 3D Object Handling

typedef float GLvector4f[4];							// Typedef's For VMatMult Procedure
typedef float GLmatrix16f[16];							// Typedef's For VMatMult Procedure

HDC			hDC=NULL;									// Private GDI Device Context
HGLRC		hRC=NULL;									// Permanent Rendering Context
HWND		hWnd=NULL;									// Holds Our Window Handle
HINSTANCE	hInstance=NULL;								// Holds The Instance Of The Application

bool keys[256], keypressed[256];						// Array Used For The Keyboard Routine
bool active=TRUE;										// Window Active Flag Set To TRUE By Default
bool fullscreen=TRUE;									// Fullscreen Flag Set To Fullscreen Mode By Default

glObject	obj;										// Object
GLfloat		xrot=0, xspeed=0;							// X Rotation & X Speed
GLfloat		yrot=0, yspeed=0;							// Y Rotation & Y Speed

float LightPos[] = { 0.0f, 5.0f,-4.0f, 1.0f};			// Light Position
float LightAmb[] = { 0.2f, 0.2f, 0.2f, 1.0f};			// Ambient Light Values
float LightDif[] = { 0.6f, 0.6f, 0.6f, 1.0f};			// Diffuse Light Values
float LightSpc[] = {-0.2f, -0.2f, -0.2f, 1.0f};			// Specular Light Values

float MatAmb[] = {0.4f, 0.4f, 0.4f, 1.0f};				// Material - Ambient Values
float MatDif[] = {0.2f, 0.6f, 0.9f, 1.0f};				// Material - Diffuse Values
float MatSpc[] = {0.0f, 0.0f, 0.0f, 1.0f};				// Material - Specular Values
float MatShn[] = {0.0f};								// Material - Shininess

float ObjPos[] = {-2.0f,-2.0f,-5.0f};					// Object Position

GLUquadricObj	*q;										// Quadratic For Drawing A Sphere
float SpherePos[] = {-4.0f,-5.0f,-6.0f};

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);	// Declaration For WndProc

void VMatMult(GLmatrix16f M, GLvector4f v)
{
	GLfloat res[4];										// Hold Calculated Results
	res[0]=M[ 0]*v[0]+M[ 4]*v[1]+M[ 8]*v[2]+M[12]*v[3];
	res[1]=M[ 1]*v[0]+M[ 5]*v[1]+M[ 9]*v[2]+M[13]*v[3];
	res[2]=M[ 2]*v[0]+M[ 6]*v[1]+M[10]*v[2]+M[14]*v[3];
	res[3]=M[ 3]*v[0]+M[ 7]*v[1]+M[11]*v[2]+M[15]*v[3];
	v[0]=res[0];										// Results Are Stored Back In v[]
	v[1]=res[1];
	v[2]=res[2];
	v[3]=res[3];										// Homogenous Coordinate
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)		// Resize And Initialize The GL Window
{
	if (height==0)										// Prevent A Divide By Zero By
	{
		height=1;										// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.001f,100.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

int InitGLObjects()										// Initialize Objects
{
	if (!ReadObject("Data/Object2.txt", &obj))			// Read Object2 Into obj
	{
		return FALSE;									// If Failed Return False
	}

	SetConnectivity(&obj);								// Set Face To Face Connectivity

	for (unsigned int i=0;i<obj.nPlanes;i++)			// Loop Through All Object Planes
		CalcPlane(obj, &(obj.planes[i]));				// Compute Plane Equations For All Faces

	return TRUE;										// Return True
}

int InitGL(GLvoid)										// All Setup For OpenGL Goes Here
{
	if (!InitGLObjects()) return FALSE;					// Function For Initializing Our Object(s)
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glClearStencil(0);									// Stencil Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations

	glLightfv(GL_LIGHT1, GL_POSITION, LightPos);		// Set Light1 Position
	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmb);			// Set Light1 Ambience
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDif);			// Set Light1 Diffuse
	glLightfv(GL_LIGHT1, GL_SPECULAR, LightSpc);		// Set Light1 Specular
	glEnable(GL_LIGHT1);								// Enable Light1
	glEnable(GL_LIGHTING);								// Enable Lighting

	glMaterialfv(GL_FRONT, GL_AMBIENT, MatAmb);			// Set Material Ambience
	glMaterialfv(GL_FRONT, GL_DIFFUSE, MatDif);			// Set Material Diffuse
	glMaterialfv(GL_FRONT, GL_SPECULAR, MatSpc);		// Set Material Specular
	glMaterialfv(GL_FRONT, GL_SHININESS, MatShn);		// Set Material Shininess

	glCullFace(GL_BACK);								// Set Culling Face To Back Face
	glEnable(GL_CULL_FACE);								// Enable Culling
	glClearColor(0.1f, 1.0f, 0.5f, 1.0f);				// Set Clear Color (Greenish Color)

	q = gluNewQuadric();								// Initialize Quadratic
	gluQuadricNormals(q, GL_SMOOTH);					// Enable Smooth Normal Generation
	gluQuadricTexture(q, GL_FALSE);						// Disable Auto Texture Coords

	return TRUE;										// Initialization Went OK
}

void DrawGLRoom()										// Draw The Room (Box)
{
	glBegin(GL_QUADS);									// Begin Drawing Quads
		// Floor
		glNormal3f(0.0f, 1.0f, 0.0f);					// Normal Pointing Up
		glVertex3f(-10.0f,-10.0f,-20.0f);				// Back Left
		glVertex3f(-10.0f,-10.0f, 20.0f);				// Front Left
		glVertex3f( 10.0f,-10.0f, 20.0f);				// Front Right
		glVertex3f( 10.0f,-10.0f,-20.0f);				// Back Right
		// Ceiling
		glNormal3f(0.0f,-1.0f, 0.0f);					// Normal Point Down
		glVertex3f(-10.0f, 10.0f, 20.0f);				// Front Left
		glVertex3f(-10.0f, 10.0f,-20.0f);				// Back Left
		glVertex3f( 10.0f, 10.0f,-20.0f);				// Back Right
		glVertex3f( 10.0f, 10.0f, 20.0f);				// Front Right
		// Front Wall
		glNormal3f(0.0f, 0.0f, 1.0f);					// Normal Pointing Away From Viewer
		glVertex3f(-10.0f, 10.0f,-20.0f);				// Top Left
		glVertex3f(-10.0f,-10.0f,-20.0f);				// Bottom Left
		glVertex3f( 10.0f,-10.0f,-20.0f);				// Bottom Right
		glVertex3f( 10.0f, 10.0f,-20.0f);				// Top Right
		// Back Wall
		glNormal3f(0.0f, 0.0f,-1.0f);					// Normal Pointing Towards Viewer
		glVertex3f( 10.0f, 10.0f, 20.0f);				// Top Right
		glVertex3f( 10.0f,-10.0f, 20.0f);				// Bottom Right
		glVertex3f(-10.0f,-10.0f, 20.0f);				// Bottom Left
		glVertex3f(-10.0f, 10.0f, 20.0f);				// Top Left
		// Left Wall
		glNormal3f(1.0f, 0.0f, 0.0f);					// Normal Pointing Right
		glVertex3f(-10.0f, 10.0f, 20.0f);				// Top Front
		glVertex3f(-10.0f,-10.0f, 20.0f);				// Bottom Front
		glVertex3f(-10.0f,-10.0f,-20.0f);				// Bottom Back
		glVertex3f(-10.0f, 10.0f,-20.0f);				// Top Back
		// Right Wall
		glNormal3f(-1.0f, 0.0f, 0.0f);					// Normal Pointing Left
		glVertex3f( 10.0f, 10.0f,-20.0f);				// Top Back
		glVertex3f( 10.0f,-10.0f,-20.0f);				// Bottom Back
		glVertex3f( 10.0f,-10.0f, 20.0f);				// Bottom Front
		glVertex3f( 10.0f, 10.0f, 20.0f);				// Top Front
	glEnd();											// Done Drawing Quads
}

int DrawGLScene(GLvoid)									// Main Drawing Routine
{
	GLmatrix16f Minv;
	GLvector4f wlp, lp;

	// Clear Color Buffer, Depth Buffer, Stencil Buffer
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	
	glLoadIdentity();									// Reset Modelview Matrix
	glTranslatef(0.0f, 0.0f, -20.0f);					// Zoom Into Screen 20 Units
	glLightfv(GL_LIGHT1, GL_POSITION, LightPos);		// Position Light1
	glTranslatef(SpherePos[0], SpherePos[1], SpherePos[2]);	// Position The Sphere
	gluSphere(q, 1.5f, 32, 16);							// Draw A Sphere

	// calculate light's position relative to local coordinate system
	// dunno if this is the best way to do it, but it actually works
	// if u find another aproach, let me know ;)

	// we build the inversed matrix by doing all the actions in reverse order
	// and with reverse parameters (notice -xrot, -yrot, -ObjPos[], etc.)
	glLoadIdentity();									// Reset Matrix
	glRotatef(-yrot, 0.0f, 1.0f, 0.0f);					// Rotate By -yrot On Y Axis
	glRotatef(-xrot, 1.0f, 0.0f, 0.0f);					// Rotate By -xrot On X Axis
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);				// Retrieve ModelView Matrix (Stores In Minv)
	lp[0] = LightPos[0];								// Store Light Position X In lp[0]
	lp[1] = LightPos[1];								// Store Light Position Y In lp[1]
	lp[2] = LightPos[2];								// Store Light Position Z In lp[2]
	lp[3] = LightPos[3];								// Store Light Direction In lp[3]
	VMatMult(Minv, lp);									// We Store Rotated Light Vector In 'lp' Array
	glTranslatef(-ObjPos[0], -ObjPos[1], -ObjPos[2]);	// Move Negative On All Axis Based On ObjPos[] Values (X, Y, Z)
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);				// Retrieve ModelView Matrix From Minv
	wlp[0] = 0.0f;										// World Local Coord X To 0
	wlp[1] = 0.0f;										// World Local Coord Y To 0
	wlp[2] = 0.0f;										// World Local Coord Z To 0
	wlp[3] = 1.0f;
	VMatMult(Minv, wlp);								// We Store The Position Of The World Origin Relative To The
														// Local Coord. System In 'wlp' Array
	lp[0] += wlp[0];									// Adding These Two Gives Us The
	lp[1] += wlp[1];									// Position Of The Light Relative To
	lp[2] += wlp[2];									// The Local Coordinate System

	glColor4f(0.7f, 0.4f, 0.0f, 1.0f);					// Set Color To An Orange
	glLoadIdentity();									// Reset Modelview Matrix
	glTranslatef(0.0f, 0.0f, -20.0f);					// Zoom Into The Screen 20 Units
	DrawGLRoom();										// Draw The Room
	glTranslatef(ObjPos[0], ObjPos[1], ObjPos[2]);		// Position The Object
	glRotatef(xrot, 1.0f, 0.0f, 0.0f);					// Spin It On The X Axis By xrot
	glRotatef(yrot, 0.0f, 1.0f, 0.0f);					// Spin It On The Y Axis By yrot
	DrawGLObject(obj);									// Procedure For Drawing The Loaded Object
	CastShadow(&obj, lp);								// Procedure For Casting The Shadow Based On The Silhouette

	glColor4f(0.7f, 0.4f, 0.0f, 1.0f);					// Set Color To Purplish Blue
	glDisable(GL_LIGHTING);								// Disable Lighting
	glDepthMask(GL_FALSE);								// Disable Depth Mask
	glTranslatef(lp[0], lp[1], lp[2]);					// Translate To Light's Position
														// Notice We're Still In Local Coordinate System
	gluSphere(q, 0.2f, 16, 8);							// Draw A Little Yellow Sphere (Represents Light)
	glEnable(GL_LIGHTING);								// Enable Lighting
	glDepthMask(GL_TRUE);								// Enable Depth Mask

	xrot += xspeed;										// Increase xrot By xspeed
	yrot += yspeed;										// Increase yrot By yspeed

	glFlush();											// Flush The OpenGL Pipeline
	return TRUE;										// Everything Went OK
}

void ProcessKeyboard()									// Process Key Presses
{
	// Spin Object
	if (keys[VK_LEFT])	yspeed -= 0.1f;					// 'Arrow Left' Decrease yspeed
	if (keys[VK_RIGHT])	yspeed += 0.1f;					// 'Arrow Right' Increase yspeed
	if (keys[VK_UP])	xspeed -= 0.1f;					// 'Arrow Up' Decrease xspeed
	if (keys[VK_DOWN])	xspeed += 0.1f;					// 'Arrow Down' Increase xspeed

	// Adjust Light's Position
	if (keys['L']) LightPos[0] += 0.05f;				// 'L' Moves Light Right
	if (keys['J']) LightPos[0] -= 0.05f;				// 'J' Moves Light Left

	if (keys['I']) LightPos[1] += 0.05f;				// 'I' Moves Light Up
	if (keys['K']) LightPos[1] -= 0.05f;				// 'K' Moves Light Down

	if (keys['O']) LightPos[2] += 0.05f;				// 'O' Moves Light Toward Viewer
	if (keys['U']) LightPos[2] -= 0.05f;				// 'U' Moves Light Away From Viewer

	// Adjust Object's Position
	if (keys[VK_NUMPAD6]) ObjPos[0] += 0.05f;			// 'Numpad6' Move Object Right
	if (keys[VK_NUMPAD4]) ObjPos[0] -= 0.05f;			// 'Numpad4' Move Object Left

	if (keys[VK_NUMPAD8]) ObjPos[1] += 0.05f;			// 'Numpad8' Move Object Up
	if (keys[VK_NUMPAD5]) ObjPos[1] -= 0.05f;			// 'Numpad5' Move Object Down

	if (keys[VK_NUMPAD9]) ObjPos[2] += 0.05f;			// 'Numpad9' Move Object Toward Viewer
	if (keys[VK_NUMPAD7]) ObjPos[2] -= 0.05f;			// 'Numpad7' Move Object Away From Viewer

	// Adjust Ball's Position
	if (keys['D']) SpherePos[0] += 0.05f;				// 'D' Move Ball Right
	if (keys['A']) SpherePos[0] -= 0.05f;				// 'A' Move Ball Left

	if (keys['W']) SpherePos[1] += 0.05f;				// 'W' Move Ball Up
	if (keys['S']) SpherePos[1] -= 0.05f;				// 'S' Move Ball Down

	if (keys['E']) SpherePos[2] += 0.05f;				// 'E' Move Ball Toward Viewer
	if (keys['Q']) SpherePos[2] -= 0.05f;				// 'Q' Move Ball Away From Viewer
}


GLvoid KillGLWindow(GLvoid)								// Properly Kill The Window
{
	if (hRC)											// Do We Have A Rendering Context?
	{
		if (!wglMakeCurrent(NULL,NULL))					// Are We Able To Release The DC And RC Contexts?
		{
			MessageBox(NULL,"Release Of DC And RC Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))						// Are We Able To Delete The RC?
		{
			MessageBox(NULL,"Release Rendering Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC=NULL;										// Set RC To NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))					// Are We Able To Release The DC
	{
		MessageBox(NULL,"Release Device Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC=NULL;										// Set DC To NULL
	}

	if (hWnd && !DestroyWindow(hWnd))					// Are We Able To Destroy The Window?
	{
		MessageBox(NULL,"Could Not Release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd=NULL;										// Set hWnd To NULL
	}

	if (fullscreen)										// Are We In Fullscreen Mode?
	{
		ChangeDisplaySettings(NULL,0);					// If So Switch Back To The Desktop
		ShowCursor(TRUE);								// Show Mouse Pointer
	}

	if (!UnregisterClass("OpenGL",hInstance))			// Are We Able To Unregister Class
	{
		MessageBox(NULL,"Could Not Unregister Class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance=NULL;									// Set hInstance To NULL
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
	GLuint		PixelFormat;							// Holds The Results After Searching For A Match
	WNDCLASS	wc;										// Windows Class Structure
	DWORD		dwExStyle;								// Window Extended Style
	DWORD		dwStyle;								// Window Style

	fullscreen=fullscreenflag;							// Set The Global Fullscreen Flag

	hInstance			= GetModuleHandle(NULL);		// Grab An Instance For Our Window
	wc.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraw On Size, And Own DC For Window.
	wc.lpfnWndProc		= (WNDPROC) WndProc;			// WndProc Handles Messages
	wc.cbClsExtra		= 0;							// No Extra Window Data
	wc.cbWndExtra		= 0;							// No Extra Window Data
	wc.hInstance		= hInstance;					// Set The Instance
	wc.hIcon			= LoadIcon(NULL, IDI_WINLOGO);	// Load The Default Icon
	wc.hCursor			= LoadCursor(NULL, IDC_ARROW);	// Load The Arrow Pointer
	wc.hbrBackground	= NULL;							// No Background Required For GL
	wc.lpszMenuName		= NULL;							// We Don't Want A Menu
	wc.lpszClassName	= "OpenGL";						// Set The Class Name

	if (!RegisterClass(&wc))							// Attempt To Register The Window Class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}
	
	if (fullscreen)										// Attempt Fullscreen Mode?
	{
		DEVMODE dmScreenSettings;						// Device Mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	// Makes Sure Memory's Cleared
		dmScreenSettings.dmSize=sizeof(dmScreenSettings);	// Size Of The Devmode Structure
		dmScreenSettings.dmPelsWidth	= width;		// Selected Screen Width
		dmScreenSettings.dmPelsHeight	= height;		// Selected Screen Height
		dmScreenSettings.dmBitsPerPel	= bits;			// Selected Bits Per Pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
			if (MessageBox(NULL,"The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen=FALSE;						// Windowed Mode Selected.  Fullscreen = FALSE
			}
			else										// Otherwise
			{
				// Pop Up A Message Box Letting User Know The Program Is Closing.
				MessageBox(NULL,"Program Will Now Close.","ERROR",MB_OK|MB_ICONSTOP);
				return FALSE;							// Return FALSE
			}
		}
	}

	if (fullscreen)										// Are We Still In Fullscreen Mode?
	{
		dwExStyle=WS_EX_APPWINDOW;						// Window Extended Style
		dwStyle=WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;	// Windows Style
		ShowCursor(FALSE);								// Hide Mouse Pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;	// Window Extended Style
		dwStyle=WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;	// Windows Style
	}

	// Create The Window
	if (!(hWnd=CreateWindowEx(	dwExStyle,				// Extended Style For The Window
								"OpenGL",				// Class Name
								title,					// Window Title
								dwStyle,				// Window Style
								0, 0,					// Window Position
								width, height,			// Selected Width And Height
								NULL,					// No Parent Window
								NULL,					// No Menu
								hInstance,				// Instance
								NULL)))					// Dont Pass Anything To WM_CREATE
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd=					// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),					// Size Of This Pixel Format Descriptor
		1,												// Version Number
		PFD_DRAW_TO_WINDOW |							// Format Must Support Window
		PFD_SUPPORT_OPENGL |							// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,								// Must Support Double Buffering
		PFD_TYPE_RGBA,									// Request An RGBA Format
		bits,											// Select Our Color Depth
		0, 0, 0, 0, 0, 0,								// Color Bits Ignored
		0,												// No Alpha Buffer
		0,												// Shift Bit Ignored
		0,												// No Accumulation Buffer
		0, 0, 0, 0,										// Accumulation Bits Ignored
		16,												// 16Bit Z-Buffer (Depth Buffer)  
		1,												// Use Stencil Buffer ( * Important * )
		0,												// No Auxiliary Buffer
		PFD_MAIN_PLANE,									// Main Drawing Layer
		0,												// Reserved
		0, 0, 0											// Layer Masks Ignored
	};
	
	if (!(hDC=GetDC(hWnd)))								// Did We Get A Device Context?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Create A GL Device Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))		// Did Windows Find A Matching Pixel Format?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Find A Suitable PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))			// Are We Able To Set The Pixel Format?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Set The PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))					// Are We Able To Get A Rendering Context?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Create A GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))						// Try To Activate The Rendering Context
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Activate The GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);							// Show The Window
	SetForegroundWindow(hWnd);							// Slightly Higher Priority
	SetFocus(hWnd);										// Sets Keyboard Focus To The Window
	ReSizeGLScene(width, height);						// Set Up Our Perspective GL Screen

	if (!InitGL())										// Initialize Our Newly Created GL Window
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	return TRUE;										// Success
}


LRESULT CALLBACK WndProc(	HWND	hWnd,				// Handle For This Window
							UINT	uMsg,				// Message For This Window
							WPARAM	wParam,				// Additional Message Information
							LPARAM	lParam)				// Additional Message Information
{
	switch (uMsg)										// Check For Windows Messages
	{
		case WM_ACTIVATE:								// Watch For Window Activate Message
		{
			if (!HIWORD(wParam))						// Check Minimization State
			{
				active=TRUE;							// Program Is Active
			}
			else										// Otherwise
			{
				active=FALSE;							// Program Is No Longer Active
			}

			return 0;									// Return To The Message Loop
		}

		case WM_SYSCOMMAND:								// Intercept System Commands
		{
			switch (wParam)								// Check System Calls
			{
				case SC_SCREENSAVE:						// Screensaver Trying To Start?
				case SC_MONITORPOWER:					// Monitor Trying To Enter Powersave?
				return 0;								// Prevent From Happening
			}
			break;										// Exit
		}

		case WM_CLOSE:									// Did We Receive A Close Message?
		{
			PostQuitMessage(0);							// Send A Quit Message
			return 0;									// Jump Back
		}

		case WM_KEYDOWN:								// Is A Key Being Held Down?
		{
			keys[wParam] = TRUE;						// If So, Mark It As TRUE
			return 0;									// Jump Back
		}

		case WM_KEYUP:									// Has A Key Been Released?
		{
			keys[wParam] = FALSE;						// If So, Mark It As FALSE
			return 0;									// Jump Back
		}

		case WM_SIZE:									// Resize The OpenGL Window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord=Width, HiWord=Height
			return 0;									// Jump Back
		}
	}

	// Pass All Unhandled Messages To DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

int WINAPI WinMain(	HINSTANCE	hInstance,				// Instance
					HINSTANCE	hPrevInstance,			// Previous Instance
					LPSTR		lpCmdLine,				// Command Line Parameters
					int			nCmdShow)				// Window Show State
{
	MSG		msg;										// Windows Message Structure
	BOOL	done=FALSE;									// Bool Variable To Exit Loop

	// Ask The User Which Screen Mode They Prefer
	if (MessageBox(NULL,"Would You Like To Run In Fullscreen Mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen=FALSE;								// Windowed Mode
	}

	// Create Our OpenGL Window
	if (!CreateGLWindow("Banu Octavian & NeHe's Shadow Casting Tutorial",800,600,32,fullscreen))
	{
		return 0;										// Quit If Window Was Not Created
	}

	while(!done)										// Loop That Runs While done=FALSE
	{
		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))		// Is There A Message Waiting?
		{
			if (msg.message==WM_QUIT)					// Have We Received A Quit Message?
			{
				done=TRUE;								// If So done=TRUE
			}
			else										// If Not, Deal With Window Messages
			{
				TranslateMessage(&msg);					// Translate The Message
				DispatchMessage(&msg);					// Dispatch The Message
			}
		}
		else											// If There Are No Messages
		{
			// Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
			if (active && keys[VK_ESCAPE])				// Active?  Was There A Quit Received?
			{
				done=TRUE;								// ESC or DrawGLScene Signalled A Quit
			}
			else										// Not Time To Quit, Update Screen
			{
				DrawGLScene();							// Draw GL Scene
				SwapBuffers(hDC);						// Swap Buffers (Double Buffering)
				ProcessKeyboard();						// Process Key Presses
			}
		}
	}

	// Shutdown
	KillGLWindow();										// Kill The Window
	return (msg.wParam);								// Exit The Program
}
