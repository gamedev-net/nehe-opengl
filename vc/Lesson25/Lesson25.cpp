/*
 *		This Code Was Created By Pet & Commented/Cleaned Up By Jeff Molofee
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit NeHe Productions At http://nehe.gamedev.net
 */

#include <windows.h>									// Header File For Windows
#include <math.h>										// Math Library Header File
#include <stdio.h>										// Header File For Standard Input/Output
#include <gl\gl.h>										// Header File For The OpenGL32 Library
#include <gl\glu.h>										// Header File For The GLu32 Library

HDC			hDC=NULL;									// Device Context Handle
HGLRC		hRC=NULL;									// Rendering Context Handle
HWND		hWnd=NULL;									// Window Handle
HINSTANCE	hInstance;									// Instance Handle

bool		keys[256];									// Key Array
bool		active=TRUE;								// Program's Active
bool		fullscreen=TRUE;							// Default Fullscreen To True

GLfloat		xrot,yrot,zrot,								// X, Y & Z Rotation
			xspeed,yspeed,zspeed,						// X, Y & Z Spin Speed
			cx,cy,cz=-15;								// X, Y & Z Position

int			key=1;										// Used To Make Sure Same Morph Key Is Not Pressed
int			step=0,steps=200;							// Step Counter And Maximum Number Of Steps
bool		morph=FALSE;								// Default morph To False (Not Morphing)

typedef struct											// Structure For 3D Points
{
	float	x, y, z;									// X, Y & Z Points
} VERTEX;												// Called VERTEX

typedef struct											// Structure For An Object
{
 int		verts;										// Number Of Vertices For The Object
 VERTEX		*points;									// One Vertice (Vertex x,y & z)
} OBJECT;												// Called OBJECT

int			maxver;										// Will Eventually Hold The Maximum Number Of Vertices
OBJECT		morph1,morph2,morph3,morph4,				// Our 4 Morphable Objects (morph1,2,3 & 4)
			helper,*sour,*dest;							// Helper Object, Source Object, Destination Object

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);	// Declaration

void objallocate(OBJECT *k,int n)						// Allocate Memory For Each Object
{														// And Defines points
	k->points=(VERTEX*)malloc(sizeof(VERTEX)*n);		// Sets points Equal To VERTEX * Number Of Vertices
}														// (3 Points For Each Vertice)

void objfree(OBJECT *k)									// Frees The Object (Releasing The Memory)
{
	free(k->points);									// Frees Points
}

void readstr(FILE *f,char *string)						// Reads A String From File (f)
{
	do													// Do This
	{
		fgets(string, 255, f);							// Gets A String Of 255 Chars Max From f (File)
	} while ((string[0] == '/') || (string[0] == '\n'));// Until End Of Line Is Reached
	return;												// Return
}

void objload(char *name,OBJECT *k)						// Loads Object From File (name)
{
	int		ver;										// Will Hold Vertice Count
	float	rx,ry,rz;									// Hold Vertex X, Y & Z Position
	FILE	*filein;									// Filename To Open
	char	oneline[255];								// Holds One Line Of Text (255 Chars Max)

	filein = fopen(name, "rt");							// Opens The File For Reading Text In Translated Mode
														// CTRL Z Symbolizes End Of File In Translated Mode
	readstr(filein,oneline);							// Jumps To Code That Reads One Line Of Text From The File
	sscanf(oneline, "Vertices: %d\n", &ver);			// Scans Text For "Vertices: ".  Number After Is Stored In ver
	k->verts=ver;										// Sets Objects verts Variable To Equal The Value Of ver
	objallocate(k,ver);									// Jumps To Code That Allocates Ram To Hold The Object

	for (int i=0;i<ver;i++)								// Loops Through The Vertices
	{
		readstr(filein,oneline);						// Reads In The Next Line Of Text
		sscanf(oneline, "%f %f %f", &rx, &ry, &rz);		// Searches For 3 Floating Point Numbers, Store In rx,ry & rz
		k->points[i].x = rx;							// Sets Objects (k) points.x Value To rx
		k->points[i].y = ry;							// Sets Objects (k) points.y Value To ry
		k->points[i].z = rz;							// Sets Objects (k) points.z Value To rz
	}
	fclose(filein);										// Close The File

	if(ver>maxver) maxver=ver;							// If ver Is Greater Than maxver Set maxver Equal To ver
}														// Keeps Track Of Highest Number Of Vertices Used In Any Of The
														// Objects
VERTEX calculate(int i)									// Calculates Movement Of Points During Morphing
{
	VERTEX a;											// Temporary Vertex Called a
	a.x=(sour->points[i].x-dest->points[i].x)/steps;	// a.x Value Equals Source x - Destination x Divided By Steps
	a.y=(sour->points[i].y-dest->points[i].y)/steps;	// a.y Value Equals Source y - Destination y Divided By Steps
	a.z=(sour->points[i].z-dest->points[i].z)/steps;	// a.z Value Equals Source z - Destination z Divided By Steps
	return a;											// Return The Results
}														// This Makes Points Move At A Speed So They All Get To Their
														// Destination At The Same Time
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
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

int InitGL(GLvoid)										// All Setup For OpenGL Goes Here
{
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Set The Blending Function For Translucency
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);				// This Will Clear The Background Color To Black
	glClearDepth(1.0);									// Enables Clearing Of The Depth Buffer
	glDepthFunc(GL_LESS);								// The Type Of Depth Test To Do
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glShadeModel(GL_SMOOTH);							// Enables Smooth Color Shading
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations

	maxver=0;											// Sets Max Vertices To 0 By Default
	objload("data/sphere.txt",&morph1);					// Load The First Object Into morph1 From File sphere.txt
	objload("data/torus.txt",&morph2);					// Load The Second Object Into morph2 From File torus.txt
	objload("data/tube.txt",&morph3);					// Load The Third Object Into morph3 From File tube.txt

	objallocate(&morph4,486);							// Manually Reserver Ram For A 4th 468 Vertice Object (morph4)
	for(int i=0;i<486;i++)								// Loop Through All 468 Vertices
	{
		morph4.points[i].x=((float)(rand()%14000)/1000)-7;	// morph4 x Point Becomes A Random Float Value From -7 to 7
		morph4.points[i].y=((float)(rand()%14000)/1000)-7;	// morph4 y Point Becomes A Random Float Value From -7 to 7
		morph4.points[i].z=((float)(rand()%14000)/1000)-7;	// morph4 z Point Becomes A Random Float Value From -7 to 7
	}

	objload("data/sphere.txt",&helper);					// Load sphere.txt Object Into Helper (Used As Starting Point)
	sour=dest=&morph1;									// Source & Destination Are Set To Equal First Object (morph1)

	return TRUE;										// Initialization Went OK
}

void DrawGLScene(GLvoid)								// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The View
	glTranslatef(cx,cy,cz);								// Translate The The Current Position To Start Drawing
	glRotatef(xrot,1,0,0);								// Rotate On The X Axis By xrot
	glRotatef(yrot,0,1,0);								// Rotate On The Y Axis By yrot
	glRotatef(zrot,0,0,1);								// Rotate On The Z Axis By zrot

	xrot+=xspeed; yrot+=yspeed; zrot+=zspeed;			// Increase xrot,yrot & zrot by xspeed, yspeed & zspeed

	GLfloat tx,ty,tz;									// Temp X, Y & Z Variables
	VERTEX q;											// Holds Returned Calculated Values For One Vertex

	glBegin(GL_POINTS);									// Begin Drawing Points
		for(int i=0;i<morph1.verts;i++)					// Loop Through All The Verts Of morph1 (All Objects Have
		{												// The Same Amount Of Verts For Simplicity, Could Use maxver Also)
			if(morph) q=calculate(i); else q.x=q.y=q.z=0;	// If morph Is True Calculate Movement Otherwise Movement=0
			helper.points[i].x-=q.x;					// Subtract q.x Units From helper.points[i].x (Move On X Axis)
			helper.points[i].y-=q.y;					// Subtract q.y Units From helper.points[i].y (Move On Y Axis)
			helper.points[i].z-=q.z;					// Subtract q.z Units From helper.points[i].z (Move On Z Axis)
			tx=helper.points[i].x;						// Make Temp X Variable Equal To Helper's X Variable
			ty=helper.points[i].y;						// Make Temp Y Variable Equal To Helper's Y Variable
			tz=helper.points[i].z;						// Make Temp Z Variable Equal To Helper's Z Variable

			glColor3f(0,1,1);							// Set Color To A Bright Shade Of Off Blue
			glVertex3f(tx,ty,tz);						// Draw A Point At The Current Temp Values (Vertex)
			glColor3f(0,0.5f,1);						// Darken Color A Bit
			tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;			// Calculate Two Positions Ahead
			glVertex3f(tx,ty,tz);						// Draw A Second Point At The Newly Calculate Position
			glColor3f(0,0,1);							// Set Color To A Very Dark Blue
			tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;			// Calculate Two More Positions Ahead
			glVertex3f(tx,ty,tz);						// Draw A Third Point At The Second New Position
		}												// This Creates A Ghostly Tail As Points Move
	glEnd();											// Done Drawing Points

	// If We're Morphing And We Haven't Gone Through All 200 Steps Increase Our Step Counter
	// Otherwise Set Morphing To False, Make Source=Destination And Set The Step Counter Back To Zero.
	if(morph && step<=steps)step++; else { morph=FALSE; sour=dest; step=0;}
}

GLvoid KillGLWindow(GLvoid)								// Properly Kill The Window
{
	objfree(&morph1);									// Jump To Code To Release morph1 Allocated Ram
	objfree(&morph2);									// Jump To Code To Release morph2 Allocated Ram
	objfree(&morph3);									// Jump To Code To Release morph3 Allocated Ram
	objfree(&morph4);									// Jump To Code To Release morph4 Allocated Ram
	objfree(&helper);									// Jump To Code To Release helper Allocated Ram

	if (fullscreen)										// Are We In Fullscreen Mode?
	{
		ChangeDisplaySettings(NULL,0);					// If So Switch Back To The Desktop
		ShowCursor(TRUE);								// Show Mouse Pointer
	}

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
	GLuint		PixelFormat;			// Holds The Results After Searching For A Match
	WNDCLASS	wc;						// Windows Class Structure
	DWORD		dwExStyle;				// Window Extended Style
	DWORD		dwStyle;				// Window Style
	RECT		WindowRect;				// Grabs Rectangle Upper Left / Lower Right Values
	WindowRect.left=(long)0;			// Set Left Value To 0
	WindowRect.right=(long)width;		// Set Right Value To Requested Width
	WindowRect.top=(long)0;				// Set Top Value To 0
	WindowRect.bottom=(long)height;		// Set Bottom Value To Requested Height

	fullscreen=fullscreenflag;			// Set The Global Fullscreen Flag

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
	if (!(hWnd=CreateWindowEx(	dwExStyle,						// Extended Style For The Window
								"OpenGL",						// Class Name
								title,							// Window Title
								dwStyle |						// Defined Window Style
								WS_CLIPSIBLINGS |				// Required Window Style
								WS_CLIPCHILDREN,				// Required Window Style
								0, 0,							// Window Position
								WindowRect.right-WindowRect.left,	// Calculate Window Width
								WindowRect.bottom-WindowRect.top,	// Calculate Window Height
								NULL,							// No Parent Window
								NULL,							// No Menu
								hInstance,						// Instance
								NULL)))							// Dont Pass Anything To WM_CREATE
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
			else												// Otherwise
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
	if (!CreateGLWindow("Piotr Cieslak & NeHe's Morphing Points Tutorial",640,480,16,fullscreen))
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
			if (active && keys[VK_ESCAPE])						// Active?  Was There A Quit Received?
			{
				done=TRUE;										// ESC or DrawGLScene Signalled A Quit
			}
			else												// Not Time To Quit, Update Screen
			{
				DrawGLScene();									// Draw The Scene (Don't Draw When Inactive 1% CPU Use)
				SwapBuffers(hDC);								// Swap Buffers (Double Buffering)

				if(keys[VK_PRIOR])								// Is Page Up Being Pressed?
					zspeed+=0.01f;								// Increase zspeed

				if(keys[VK_NEXT])								// Is Page Down Being Pressed?
					zspeed-=0.01f;								// Decrease zspeed

				if(keys[VK_DOWN])								// Is Down Arrow Being Pressed?
					xspeed+=0.01f;								// Increase xspeed

				if(keys[VK_UP])									// Is Up Arrow Being Pressed?
					xspeed-=0.01f;								// Decrease xspeed

				if(keys[VK_RIGHT])								// Is Right Arrow Being Pressed?
					yspeed+=0.01f;								// Increase yspeed

				if(keys[VK_LEFT])								// Is Left Arrow Being Pressed?
					yspeed-=0.01f;								// Decrease yspeed

				if (keys['Q'])									// Is Q Key Being Pressed?
				 cz-=0.01f;										// Move Object Away From Viewer

				if (keys['Z'])									// Is Z Key Being Pressed?
				 cz+=0.01f;										// Move Object Towards Viewer

				if (keys['W'])									// Is W Key Being Pressed?
				 cy+=0.01f;										// Move Object Up

				if (keys['S'])									// Is S Key Being Pressed?
				 cy-=0.01f;										// Move Object Down

				if (keys['D'])									// Is D Key Being Pressed?
				 cx+=0.01f;										// Move Object Right

				if (keys['A'])									// Is A Key Being Pressed?
				 cx-=0.01f;										// Move Object Left

				if (keys['1'] && (key!=1) && !morph)			// Is 1 Pressed, key Not Equal To 1 And Morph False?
				{
					key=1;										// Sets key To 1 (To Prevent Pressing 1 2x In A Row)
					morph=TRUE;									// Set morph To True (Starts Morphing Process)
					dest=&morph1;								// Destination Object To Morph To Becomes morph1
				}
				if (keys['2'] && (key!=2) && !morph)			// Is 2 Pressed, key Not Equal To 2 And Morph False?
				{
					key=2;										// Sets key To 2 (To Prevent Pressing 2 2x In A Row)
					morph=TRUE;									// Set morph To True (Starts Morphing Process)
					dest=&morph2;								// Destination Object To Morph To Becomes morph2
				}
				if (keys['3'] && (key!=3) && !morph)			// Is 3 Pressed, key Not Equal To 3 And Morph False?
				{
					key=3;										// Sets key To 3 (To Prevent Pressing 3 2x In A Row)
					morph=TRUE;									// Set morph To True (Starts Morphing Process)
					dest=&morph3;								// Destination Object To Morph To Becomes morph3
				}
				if (keys['4'] && (key!=4) && !morph)			// Is 4 Pressed, key Not Equal To 4 And Morph False?
				{
					key=4;										// Sets key To 4 (To Prevent Pressing 4 2x In A Row)
					morph=TRUE;									// Set morph To True (Starts Morphing Process)
					dest=&morph4;								// Destination Object To Morph To Becomes morph4
				}

				if (keys[VK_F1])								// Is F1 Being Pressed?
				{
					keys[VK_F1]=FALSE;							// If So Make Key FALSE
					KillGLWindow();								// Kill Our Current Window
					fullscreen=!fullscreen;						// Toggle Fullscreen / Windowed Mode
					// Recreate Our OpenGL Window
					if (!CreateGLWindow("Piotr Cieslak & NeHe's Morphing Points Tutorial",640,480,16,fullscreen))
					{
						return 0;								// Quit If Window Was Not Created
					}
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();												// Kill The Window
	return (msg.wParam);										// Exit The Program
}
