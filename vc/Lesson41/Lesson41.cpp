/*
 *		This Code Was Created By Jeff Molofee 2003
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit My Site At nehe.gamedev.net
 */

#include <windows.h>													// Header File For Windows
#include <gl\gl.h>														// Header File For The OpenGL32 Library
#include <gl\glu.h>														// Header File For The GLu32 Library
#include <olectl.h>														// Header File For The OLE Controls Library	(Used In BuildTexture)
#include <math.h>														// Header File For The Math Library			(Used In BuildTexture)

#include "NeHeGL.h"														// Header File For NeHeGL

#pragma comment( lib, "opengl32.lib" )									// Search For OpenGL32.lib While Linking
#pragma comment( lib, "glu32.lib" )										// Search For GLu32.lib While Linking

#ifndef CDS_FULLSCREEN													// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4												// Compilers. By Defining It This Way,
#endif																	// We Can Avoid Errors

GL_Window*	g_window;													// Window Structure
Keys*		g_keys;														// Keyboard

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
	glFogf(GL_FOG_START,  0.0f);										// Set The Fog Start
	glFogf(GL_FOG_END,    1.0f);										// Set The Fog End
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
	
	glBegin(GL_QUADS);													// Back Wall
	 	glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f, 2.5f,-15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Floor
	 	glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f,-2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f,-2.5f, 15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f,-2.5f, 15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Roof
		glFogCoordfEXT( 1.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f, 2.5f, 15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f, 2.5f, 15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Right Wall
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f( 2.5f,-2.5f, 15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f( 2.5f, 2.5f, 15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f( 2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f( 2.5f,-2.5f,-15.0f);
	glEnd();

	glBegin(GL_QUADS);													// Left Wall
	 	glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 0.0f);	glVertex3f(-2.5f,-2.5f, 15.0f);
		glFogCoordfEXT( 0.0f);	glTexCoord2f(0.0f, 1.0f);	glVertex3f(-2.5f, 2.5f, 15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 1.0f);	glVertex3f(-2.5f, 2.5f,-15.0f);
		glFogCoordfEXT( 1.0f);	glTexCoord2f(1.0f, 0.0f);	glVertex3f(-2.5f,-2.5f,-15.0f);
	glEnd();
 
	glFlush ();															// Flush The GL Rendering Pipeline
}
