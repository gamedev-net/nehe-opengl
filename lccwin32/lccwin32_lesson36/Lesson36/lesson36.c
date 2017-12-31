/**************************************
*                                     *
*   Jeff Molofee's Basecode Example   *
*          nehe.gamedev.net           *
*                2001                 *
*                                     *
*    All Code / Tutorial Commenting   *
*       by Jeff Molofee ( NeHe )      *
*                                     *
***************************************


==========================================================================
          OpenGL Lesson 36:  Radial Blur & Rendering To A Texture
==========================================================================

	 Authors Name: Dario Corno ( rIo )

	 Modified for LCCWin32 compiler by Yann [ kohai/synrj ] Parmentier 2004/01/31

	 Notes from kohai : I striped down the new NeHe framework and its C++ syntax,
	 					as it wasn't compatible with LCC pure C syntax.
						I used good old NeHe initialization code instead,
						for maximum simplicity and reliability.

***************************************/


#include <windows.h>		// Header File For Windows
#include <gl\gl.h>			// Header File For The OpenGL32 Library
#include <gl\glu.h>			// Header File For The GLu32 Library
//#include <gl\glut.h>		// Header File For The GLut32 Library
//#include <gl\glaux.h>		// Header File For The Glaux Library
#include <math.h>

HDC			hDC=NULL;		// Private GDI Device Context
HGLRC		hRC=NULL;		// Permanent Rendering Context
HWND		hWnd=NULL;		// Holds Our Window Handle
HINSTANCE	hInstance;		// Holds The Instance Of The Application

BOOL	keys[256];			// Array Used For The Keyboard Routine
BOOL	active=TRUE;		// Window Active Flag Set To TRUE By Default
BOOL	fullscreen=TRUE;	// Fullscreen Flag Set To Fullscreen Mode By Default
int 	width = 640, height = 480;


// User Defined Variables
float		angle;												// Used To Rotate The Helix
float		vertexes[4][3];										// Holds Float Info For 4 Sets Of Vertices
float		normal[3];											// An Array To Store The Normal Data
GLuint		BlurTexture;										// An Unsigned Int To Store The Texture Number
int 		TextureSize = 8 ;									// Size of our RenderToTexture target



LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);	// Declaration For WndProc




GLuint EmptyTexture()											// Create An Empty Texture
{
	GLuint txtnumber;											// Texture ID
	unsigned int* data;											// Stored Data

	// Create Storage Space For Texture Data (128x128x4)
	data = (unsigned int*) malloc((TextureSize * TextureSize)* 4 * sizeof(unsigned int));
	ZeroMemory(data,((TextureSize * TextureSize)* 4 * sizeof(unsigned int)));	// Clear Storage Memory

	glGenTextures(1, &txtnumber);								// Create 1 Texture
	glBindTexture(GL_TEXTURE_2D, txtnumber);					// Bind The Texture
	glTexImage2D(GL_TEXTURE_2D, 0, 4, TextureSize, TextureSize, 0,
		GL_RGBA, GL_UNSIGNED_BYTE, data);						// Build Texture Using Information In data
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

	free ( data );												// Release data

	return txtnumber;											// Return The Texture ID
}



void ReduceToUnit(float vector[3])								// Reduces A Normal Vector (3 Coordinates)
{																// To A Unit Normal Vector With A Length Of One.
	float length;												// Holds Unit Length
	// Calculates The Length Of The Vector
	length = (float)sqrt((vector[0]*vector[0]) + (vector[1]*vector[1]) + (vector[2]*vector[2]));

	if(length == 0.0f)											// Prevents Divide By 0 Error By Providing
		length = 1.0f;											// An Acceptable Value For Vectors To Close To 0.

	vector[0] /= length;										// Dividing Each Element By
	vector[1] /= length;										// The Length Results In A
	vector[2] /= length;										// Unit Normal Vector.
}

void calcNormal(float v[3][3], float out[3])					// Calculates Normal For A Quad Using 3 Points
{
	float v1[3],v2[3];											// Vector 1 (x,y,z) & Vector 2 (x,y,z)
	static const int x = 0;										// Define X Coord
	static const int y = 1;										// Define Y Coord
	static const int z = 2;										// Define Z Coord

	// Finds The Vector Between 2 Points By Subtracting
	// The x,y,z Coordinates From One Point To Another.

	// Calculate The Vector From Point 1 To Point 0
	v1[x] = v[0][x] - v[1][x];									// Vector 1.x=Vertex[0].x-Vertex[1].x
	v1[y] = v[0][y] - v[1][y];									// Vector 1.y=Vertex[0].y-Vertex[1].y
	v1[z] = v[0][z] - v[1][z];									// Vector 1.z=Vertex[0].y-Vertex[1].z
	// Calculate The Vector From Point 2 To Point 1
	v2[x] = v[1][x] - v[2][x];									// Vector 2.x=Vertex[0].x-Vertex[1].x
	v2[y] = v[1][y] - v[2][y];									// Vector 2.y=Vertex[0].y-Vertex[1].y
	v2[z] = v[1][z] - v[2][z];									// Vector 2.z=Vertex[0].z-Vertex[1].z
	// Compute The Cross Product To Give Us A Surface Normal
	out[x] = v1[y]*v2[z] - v1[z]*v2[y];							// Cross Product For Y - Z
	out[y] = v1[z]*v2[x] - v1[x]*v2[z];							// Cross Product For X - Z
	out[z] = v1[x]*v2[y] - v1[y]*v2[x];							// Cross Product For X - Y

	ReduceToUnit(out);											// Normalize The Vectors
}

void ProcessHelix()												// Draws A Helix
{
	GLfloat x;													// Helix x Coordinate
	GLfloat y;													// Helix y Coordinate
	GLfloat z;													// Helix z Coordinate
	GLfloat phi;												// Angle
	GLfloat theta;												// Angle
	GLfloat v,u;												// Angles
	GLfloat r;													// Radius Of Twist
	int twists = 5;												// 5 Twists

	GLfloat glfMaterialColor[]={0.4f,0.2f,0.8f,1.0f};			// Set The Material Color
	GLfloat specular[]={1.0f,1.0f,1.0f,1.0f};					// Sets Up Specular Lighting

	glLoadIdentity();											// Reset The Modelview Matrix
	gluLookAt(0, 5, 50, 0, 0, 0, 0, 1, 0);						// Eye Position (0,5,50) Center Of Scene (0,0,0), Up On Y Axis

	glPushMatrix();												// Push The Modelview Matrix

	glTranslatef(0,0,-50);										// Translate 50 Units Into The Screen
	glRotatef(angle/2.0f,1,0,0);								// Rotate By angle/2 On The X-Axis
	glRotatef(angle/3.0f,0,1,0);								// Rotate By angle/3 On The Y-Axis

    glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE,glfMaterialColor);
	glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,specular);

	r=1.5f;														// Radius

	glBegin(GL_QUADS);											// Begin Drawing Quads
	for(phi=0; phi <= 360; phi+=20.0)							// 360 Degrees In Steps Of 20
	{
		for(theta=0; theta<=360*twists; theta+=20.0)			// 360 Degrees * Number Of Twists In Steps Of 20
		{
			v=(phi/180.0f*3.142f);								// Calculate Angle Of First Point	(  0 )
			u=(theta/180.0f*3.142f);							// Calculate Angle Of First Point	(  0 )

			x=(float)(cos(u)*(2.0f+cos(v) ))*r;					// Calculate x Position (1st Point)
			y=(float)(sin(u)*(2.0f+cos(v) ))*r;					// Calculate y Position (1st Point)
			z=(float)((( u-(2.0f*3.142f)) + sin(v) ) * r);		// Calculate z Position (1st Point)

			vertexes[0][0]=x;									// Set x Value Of First Vertex
			vertexes[0][1]=y;									// Set y Value Of First Vertex
			vertexes[0][2]=z;									// Set z Value Of First Vertex

			v=(phi/180.0f*3.142f);								// Calculate Angle Of Second Point	(  0 )
			u=((theta+20)/180.0f*3.142f);						// Calculate Angle Of Second Point	( 20 )

			x=(float)(cos(u)*(2.0f+cos(v) ))*r;					// Calculate x Position (2nd Point)
			y=(float)(sin(u)*(2.0f+cos(v) ))*r;					// Calculate y Position (2nd Point)
			z=(float)((( u-(2.0f*3.142f)) + sin(v) ) * r);		// Calculate z Position (2nd Point)

			vertexes[1][0]=x;									// Set x Value Of Second Vertex
			vertexes[1][1]=y;									// Set y Value Of Second Vertex
			vertexes[1][2]=z;									// Set z Value Of Second Vertex

			v=((phi+20)/180.0f*3.142f);							// Calculate Angle Of Third Point	( 20 )
			u=((theta+20)/180.0f*3.142f);						// Calculate Angle Of Third Point	( 20 )

			x=(float)(cos(u)*(2.0f+cos(v) ))*r;					// Calculate x Position (3rd Point)
			y=(float)(sin(u)*(2.0f+cos(v) ))*r;					// Calculate y Position (3rd Point)
			z=(float)((( u-(2.0f*3.142f)) + sin(v) ) * r);		// Calculate z Position (3rd Point)

			vertexes[2][0]=x;									// Set x Value Of Third Vertex
			vertexes[2][1]=y;									// Set y Value Of Third Vertex
			vertexes[2][2]=z;									// Set z Value Of Third Vertex

			v=((phi+20)/180.0f*3.142f);							// Calculate Angle Of Fourth Point	( 20 )
			u=((theta)/180.0f*3.142f);							// Calculate Angle Of Fourth Point	(  0 )

			x=(float)(cos(u)*(2.0f+cos(v) ))*r;					// Calculate x Position (4th Point)
			y=(float)(sin(u)*(2.0f+cos(v) ))*r;					// Calculate y Position (4th Point)
			z=(float)((( u-(2.0f*3.142f)) + sin(v) ) * r);		// Calculate z Position (4th Point)

			vertexes[3][0]=x;									// Set x Value Of Fourth Vertex
			vertexes[3][1]=y;									// Set y Value Of Fourth Vertex
			vertexes[3][2]=z;									// Set z Value Of Fourth Vertex

			calcNormal(vertexes,normal);						// Calculate The Quad Normal

			glNormal3f(normal[0],normal[1],normal[2]);			// Set The Normal

			// Render The Quad
			glVertex3f(vertexes[0][0],vertexes[0][1],vertexes[0][2]);
			glVertex3f(vertexes[1][0],vertexes[1][1],vertexes[1][2]);
			glVertex3f(vertexes[2][0],vertexes[2][1],vertexes[2][2]);
			glVertex3f(vertexes[3][0],vertexes[3][1],vertexes[3][2]);
		}
	}
	glEnd();													// Done Rendering Quads

	glPopMatrix();												// Pop The Matrix
}


void ViewOrtho()												// Set Up An Ortho View
{
	glMatrixMode(GL_PROJECTION);								// Select Projection
	glPushMatrix();												// Push The Matrix
	glLoadIdentity();											// Reset The Matrix
	glOrtho( 0, 640 , 480 , 0, -1, 1 );							// Select Ortho Mode (640x480)
	glMatrixMode(GL_MODELVIEW);									// Select Modelview Matrix
	glPushMatrix();												// Push The Matrix
	glLoadIdentity();											// Reset The Matrix
}

void ViewPerspective()											// Set Up A Perspective View
{
	glMatrixMode( GL_PROJECTION );								// Select Projection
	glPopMatrix();												// Pop The Matrix
	glMatrixMode( GL_MODELVIEW );								// Select Modelview
	glPopMatrix();												// Pop The Matrix
}

void RenderToTexture()											// Renders To A Texture
{
	glViewport(0,0,TextureSize,TextureSize);									// Set Our Viewport (Match Texture Size)

	ProcessHelix();												// Render The Helix

	glBindTexture(GL_TEXTURE_2D,BlurTexture);					// Bind To The Blur Texture

	// Copy Our ViewPort To The Blur Texture (From 0,0 To 128,128... No Border)
	glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 0, 0, TextureSize, TextureSize, 0);

	glClearColor(0.0f, 0.0f, 0.5f, 0.5);						// Set The Clear Color To Medium Blue
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);			// Clear The Screen And Depth Buffer

	glViewport(0 , 0,640 ,480);									// Set Viewport (0,0 to 640x480)
}



void DrawBlur(int times, float inc)								// Draw The Blurred Image
{
	float spost = 0.0f;											// Starting Texture Coordinate Offset
	float alphainc = 0.3f / times;								// Fade Speed For Alpha Blending
	float alpha = 0.1f;											// Starting Alpha Value

	// Disable AutoTexture Coordinates
	glDisable(GL_TEXTURE_GEN_S);
	glDisable(GL_TEXTURE_GEN_T);

	glEnable(GL_TEXTURE_2D);									// Enable 2D Texture Mapping
	glDisable(GL_DEPTH_TEST);									// Disable Depth Testing
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);							// Set Blending Mode
	//glBlendFunc(GL_ONE,GL_ONE);							// Set Blending Mode
	glEnable(GL_BLEND);											// Enable Blending
	glBindTexture(GL_TEXTURE_2D,BlurTexture);					// Bind To The Blur Texture
	ViewOrtho();												// Switch To An Ortho View

	alphainc = alpha / times;									// alphainc=0.2f / Times To Render Blur

	glBegin(GL_QUADS);											// Begin Drawing Quads
		for (int num = 0;num < times;num++)						// Number Of Times To Render Blur
		{
			glColor4f(1.0f, 1.0f, 1.0f, alpha);					// Set The Alpha Value (Starts At 0.2)
			glTexCoord2f(0+spost,1-spost);						// Texture Coordinate	( 0, 1 )
			glVertex2f(0,0);									// First Vertex		(   0,   0 )

			glTexCoord2f(0+spost,0+spost);						// Texture Coordinate	( 0, 0 )
			glVertex2f(0,480);									// Second Vertex	(   0, 480 )

			glTexCoord2f(1-spost,0+spost);						// Texture Coordinate	( 1, 0 )
			glVertex2f(640,480);								// Third Vertex		( 640, 480 )

			glTexCoord2f(1-spost,1-spost);						// Texture Coordinate	( 1, 1 )
			glVertex2f(640,0);									// Fourth Vertex	( 640,   0 )

			spost += inc;										// Gradually Increase spost (Zooming Closer To Texture Center)
			alpha = alpha - alphainc;							// Gradually Decrease alpha (Gradually Fading Image Out)
		}
	glEnd();													// Done Drawing Quads

	ViewPerspective();											// Switch To A Perspective View

	glEnable(GL_DEPTH_TEST);									// Enable Depth Testing
	glDisable(GL_TEXTURE_2D);									// Disable 2D Texture Mapping
	glDisable(GL_BLEND);										// Disable Blending
	glBindTexture(GL_TEXTURE_2D,0);								// Unbind The Blur Texture
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
	gluPerspective(50, (float)width/(float)height, 5,  2000); // Set Our Perspective

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}



BOOL Initialize ()					// Any GL Init Code & User Initialiazation Goes Here
{

	// Start Of User Initialization
	angle		= 0.0f;											// Set Starting Angle To Zero

	BlurTexture = EmptyTexture();								// Create Our Empty Texture

	glViewport(0 , 0,width ,height);	// Set Up A Viewport
	glMatrixMode(GL_PROJECTION);								// Select The Projection Matrix
	glLoadIdentity();											// Reset The Projection Matrix
	gluPerspective(50, (float)width/(float)height, 5,  2000); // Set Our Perspective
	glMatrixMode(GL_MODELVIEW);									// Select The Modelview Matrix
	glLoadIdentity();											// Reset The Modelview Matrix

	glEnable(GL_DEPTH_TEST);									// Enable Depth Testing

	GLfloat global_ambient[4]={0.2f, 0.2f,  0.2f, 1.0f};		// Set Ambient Lighting To Fairly Dark Light (No Color)
	GLfloat light0pos[4]=     {0.0f, 5.0f, 10.0f, 1.0f};		// Set The Light Position
	GLfloat light0ambient[4]= {0.2f, 0.2f,  0.2f, 1.0f};		// More Ambient Light
	GLfloat light0diffuse[4]= {0.3f, 0.3f,  0.3f, 1.0f};		// Set The Diffuse Light A Bit Brighter
	GLfloat light0specular[4]={0.8f, 0.8f,  0.8f, 1.0f};		// Fairly Bright Specular Lighting

	GLfloat lmodel_ambient[]= {0.2f,0.2f,0.2f,1.0f};			// And More Ambient Light
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,lmodel_ambient);		// Set The Ambient Light Model

	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, global_ambient);		// Set The Global Ambient Light Model
	glLightfv(GL_LIGHT0, GL_POSITION, light0pos);				// Set The Lights Position
	glLightfv(GL_LIGHT0, GL_AMBIENT, light0ambient);			// Set The Ambient Light
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light0diffuse);			// Set The Diffuse Light
	glLightfv(GL_LIGHT0, GL_SPECULAR, light0specular);			// Set Up Specular Lighting
	glEnable(GL_LIGHTING);										// Enable Lighting
	glEnable(GL_LIGHT0);										// Enable Light0

	glShadeModel(GL_SMOOTH);									// Select Smooth Shading

	glMateriali(GL_FRONT, GL_SHININESS, 128);
	glClearColor(0.0f, 0.0f, 0.0f, 0.5);						// Set The Clear Color To Black

	return TRUE;												// Return TRUE (Initialization Successful)
}




void Deinitialize (void)										// Any User DeInitialization Goes Here
{
	glDeleteTextures(1,&BlurTexture);							// Delete The Blur Texture
}





void DrawGLScene(GLvoid)									// Here's Where We Do All The Drawing
{


	glClearColor(0.0f, 0.0f, 0.0f, 0.5);						// Set The Clear Color To Black
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glLoadIdentity();											// Reset The View
	RenderToTexture();											// Render To A Texture
	ProcessHelix();												// Draw Our Helix
	DrawBlur(20,0.055f);											// Draw The Blur Effect
	glFlush ();													// Flush The GL Rendering Pipeline

}








GLvoid KillGLWindow(GLvoid)								// Properly Kill The Window
{


	Deinitialize();										// Get rid of allocated texture

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

BOOL CreateGLWindow(char* title, int width, int height, int bits, BOOL fullscreenflag)
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
				fullscreen=FALSE;		// Windowed Mode Selected.  Fullscreen = FALSE
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

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);		// Adjust Window To True Requested Size

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
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd=				// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),				// Size Of This Pixel Format Descriptor
		1,											// Version Number
		PFD_DRAW_TO_WINDOW |						// Format Must Support Window
		PFD_SUPPORT_OPENGL |						// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,							// Must Support Double Buffering
		PFD_TYPE_RGBA,								// Request An RGBA Format
		0,						    				// Select Our Color Depth
		0, 0, 0, 0, 0, 0,							// Color Bits Ignored
		0,											// No Alpha Buffer
		0,											// Shift Bit Ignored
		0,											// No Accumulation Buffer
		0, 0, 0, 0,									// Accumulation Bits Ignored
		16,											// 16Bit Z-Buffer (Depth Buffer)
		0,											// No Stencil Buffer
		0,											// No Auxiliary Buffer
		PFD_MAIN_PLANE,								// Main Drawing Layer
		0,											// Reserved
		0, 0, 0										// Layer Masks Ignored
    };
    pfd.cColorBits = bits;

    if (!(hDC=GetDC(hWnd)))                         // Did We Get A Device Context?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Create A GL Device Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))	// Did Windows Find A Matching Pixel Format?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Find A Suitable PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))		// Are We Able To Set The Pixel Format?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Set The PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))				// Are We Able To Get A Rendering Context?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Create A GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))					// Try To Activate The Rendering Context
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Activate The GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);						// Show The Window
	SetForegroundWindow(hWnd);						// Slightly Higher Priority
	SetFocus(hWnd);									// Sets Keyboard Focus To The Window
	ReSizeGLScene(width, height);					// Set Up Our Perspective GL Screen

	if (!Initialize())									// Initialize Our Newly Created GL Window
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	return TRUE;									// Success
}




LRESULT CALLBACK WndProc(	HWND	hWnd,			// Handle For This Window
							UINT	uMsg,			// Message For This Window
							WPARAM	wParam,			// Additional Message Information
							LPARAM	lParam)			// Additional Message Information
{
	switch (uMsg)									// Check For Windows Messages
	{
		case WM_ACTIVATE:							// Watch For Window Activate Message
		{
			if (!HIWORD(wParam))					// Check Minimization State
			{
				active=TRUE;						// Program Is Active
			}
			else
			{
				active=FALSE;						// Program Is No Longer Active
			}

			return 0;								// Return To The Message Loop
		}

		case WM_SYSCOMMAND:							// Intercept System Commands
		{
			switch (wParam)							// Check System Calls
			{
				case SC_SCREENSAVE:					// Screensaver Trying To Start?
				case SC_MONITORPOWER:				// Monitor Trying To Enter Powersave?
				return 0;							// Prevent From Happening
			}
			break;									// Exit
		}

		case WM_CLOSE:								// Did We Receive A Close Message?
		{
			PostQuitMessage(0);						// Send A Quit Message
			return 0;								// Jump Back
		}

		case WM_KEYDOWN:							// Is A Key Being Held Down?
		{
			keys[wParam] = TRUE;					// If So, Mark It As TRUE
			return 0;								// Jump Back
		}

		case WM_KEYUP:								// Has A Key Been Released?
		{
			keys[wParam] = FALSE;					// If So, Mark It As FALSE
			return 0;								// Jump Back
		}

		case WM_SIZE:								// Resize The OpenGL Window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord=Width, HiWord=Height
			return 0;								// Jump Back
		}
	}

	// Pass All Unhandled Messages To DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

int WINAPI WinMain(	HINSTANCE	hInstance,			// Instance
					HINSTANCE	hPrevInstance,		// Previous Instance
					LPSTR		lpCmdLine,			// Command Line Parameters
					int			nCmdShow)			// Window Show State
{
	MSG		msg;									// Windows Message Structure
	BOOL	done=FALSE;								// BOOL Variable To Exit Loop
	float	t,t0;

	// Ask The User Which Screen Mode They Prefer
	if (MessageBox(NULL,"Would You Like To Run In Fullscreen Mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen=FALSE;							// Windowed Mode
	}

	// Create Our OpenGL Window
	if (!CreateGLWindow("[NeHe Radial] _ by rIO / Spinning Kids",width,height,32,fullscreen))
	{
		return 0;									// Quit If Window Was Not Created
	}


	t0 = GetTickCount();

	while(!done)									// Loop That Runs While done=FALSE

		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))	// Is There A Message Waiting?
		{
			if (msg.message==WM_QUIT)				// Have We Received A Quit Message?
			{
				done=TRUE;							// If So done=TRUE
			}
			else									// If Not, Deal With Window Messages
			{
				TranslateMessage(&msg);				// Translate The Message
				DispatchMessage(&msg);				// Dispatch The Message
			}
		}
		else										// If There Are No Messages
		{
			// Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
			if (active)								// Program Active?
			{
				if (keys[VK_ESCAPE])				// Was ESC Pressed?
				{
					done=TRUE;						// ESC Signalled A Quit
				}
				else								// Not Time To Quit, Update Screen
				{

					t = GetTickCount();

					angle += (float)(t-t0) * 0.5f;			// Update angle Based On The Clock
					DrawGLScene();					// Draw The Scene
					SwapBuffers(hDC);				// Swap Buffers (Double Buffering)

					t0 = t;
				}
			}

			if (keys[VK_F1])						// Is F1 Being Pressed?
			{
				keys[VK_F1]=FALSE;					// If So Make Key FALSE
				KillGLWindow();						// Kill Our Current Window
				fullscreen=!fullscreen;				// Toggle Fullscreen / Windowed Mode
				// Recreate Our OpenGL Window
				if (!CreateGLWindow("NeHe's OpenGL Framework",width,height,32,fullscreen))
				{
					return 0;						// Quit If Window Was Not Created
				}
			}
		}


	// Shutdown
	KillGLWindow();									// Kill The Window
	return (msg.wParam);							// Exit The Program
}
