//---------------------------------------------------------------------------

#include <windows.h>
#include <gl\gl.h>	// Header file for the OpenGL32 library
#include <gl\glu.h>	// Header file for the GLu32 library
#include <vfw.h>	// Header file for video for windows
#include "NeHeGL.h"	// Header file for NeHeGL
#pragma hdrstop

#ifndef CDS_FULLSCREEN		// CDS_FULLSCREEN is not defined by some
#define CDS_FULLSCREEN 4	// compilers. By defining it this way,
#endif				// we can avoid errors

//---------------------------------------------------------------------------

GL_Window* g_window;
Keys* g_keys;

// User Defined Variables
float angle;			// Used for rotation
int next;			// Used for animation
int frame = 0;			// Frame counter
int effect;			// Current effect
bool sp;			// Space bar pressed?
bool env = true;		// Environment mapping (Default on)
bool ep;			// 'E' pressed?
bool bg = true;			// Background (Default on)
bool bp;			// 'B' pressed?

AVISTREAMINFO psi;		// Pointer to a structure containing stream info
PAVISTREAM pavi;		// Handle to an open stream
PGETFRAME pgf;			// Pointer to a getframe object
BITMAPINFOHEADER bmih;		// Header information for drawdibdraw decoding
long lastframe;			// Last frame of the stream
int width;			// Video width
int height;			// Video height
char *pdata;			// Pointer to texture data
int mpf;			// Will hold rough milliseconds per frame

GLUquadricObj *quadratic;	// Storage for our quadratic objects

HDRAWDIB hdd;			// Handle for our dib
HBITMAP hBitmap;		// Handle to a device dependant bitmap
HDC hdc = CreateCompatibleDC(0);// Creates a compatible device context
unsigned char* data = 0;	// Pointer to our resized image

void flipIt(void* buffer)	// Flips the red and blue bytes (256x256)
{
	void* b = buffer;	// Pointer to the buffer
	__asm			// Assembler code to follow
	{
		mov ecx, 256*256        	// Counter set to dimensions of our memory block
		mov ebx, b	        	// Points ebx to our data (b)
		label:		        	// Label used for looping
			mov al,[ebx+0]  	// Loads value at ebx into al
			mov ah,[ebx+2]  	// Loads value at ebx+2 into ah
			mov [ebx+2],al	        // Stores value in al at ebx+2
			mov [ebx+0],ah		// Stores value in ah at ebx

			add ebx,3		// Moves through the data by 3 bytes
			dec ecx			// Decreases our loop counter
			jnz label		// If not zero jump back to label
	}
}

void OpenAVI(LPCSTR szFile)	// Opens an AVI file (szFile)
{
	TCHAR title[100];	// Will hold the modified window title

	AVIFileInit();		// Opens the AVIFile library

	// Opens the AVI stream
	if (AVIStreamOpenFromFile(&pavi, szFile, streamtypeVIDEO, 0, OF_READ, NULL) !=0)
	{
		// An error occurred opening the stream
		MessageBox (HWND_DESKTOP, "Failed To Open The AVI Stream", "Error", MB_OK | MB_ICONEXCLAMATION);
	}

	AVIStreamInfo(pavi, &psi, sizeof(psi));			// Reads information about the stream into psi
	width=psi.rcFrame.right-psi.rcFrame.left;		// Width is right side of frame minus left
	height=psi.rcFrame.bottom-psi.rcFrame.top;		// Height is bottom of frame minus top

	lastframe=AVIStreamLength(pavi);			// The last frame of the stream

	mpf=AVIStreamSampleToTime(pavi,lastframe)/lastframe;	// Calculate rough milliseconds per frame

	bmih.biSize = sizeof (BITMAPINFOHEADER);		// Size of the bitmapinfoheader
	bmih.biPlanes = 1;					// Bitplanes
	bmih.biBitCount = 24;					// Bits format we want (24 bit, 3 bytes)
	bmih.biWidth = 256;					// Width we want (256 Pixels)
	bmih.biHeight = 256;					// Height we want (256 Pixels)
	bmih.biCompression = BI_RGB;				// Requested mode = RGB

	hBitmap = CreateDIBSection (hdc, (BITMAPINFO*)(&bmih), DIB_RGB_COLORS, (void**)(&data), NULL, NULL);
	SelectObject (hdc, hBitmap);				// Select hBitmap into our device context (hdc)

	pgf=AVIStreamGetFrameOpen(pavi, NULL);			// Create the PGETFRAME	using our request mode
	if (pgf==NULL)
	{
		// An error occurred opening the frame
		MessageBox (HWND_DESKTOP, "Failed To Open The AVI Frame", "Error", MB_OK | MB_ICONEXCLAMATION);
	}

	// Information for the title bar (Width / height / last frame)
	wsprintf (title, "NeHe's AVI Player: Width: %d, Height: %d, Frames: %d", width, height, lastframe);
	SetWindowText(g_window->hWnd, title);			// Modify the title bar
}

void GrabAVIFrame(int frame)            // Grabs a frame from the stream
{
	LPBITMAPINFOHEADER lpbi;	// Holds the bitmap header information
	lpbi = (LPBITMAPINFOHEADER)AVIStreamGetFrame(pgf, frame);	        // Grab data from the AVI stream
	pdata=(char *)lpbi+lpbi->biSize+lpbi->biClrUsed * sizeof(RGBQUAD);	// Pointer to data returned by AVIStreamGetFrame

	// Convert data to requested bitmap format
	DrawDibDraw (hdd, hdc, 0, 0, 256, 256, lpbi, pdata, 0, 0, width, height, 0);

	flipIt(data);								// Swap the red and blue bytes (GL compatability)

	// Update the texture
	glTexSubImage2D (GL_TEXTURE_2D, 0, 0, 0, 256, 256, GL_RGB, GL_UNSIGNED_BYTE, data);
}

void CloseAVI(void)             // Properly closes the AVIfile
{
	DeleteObject(hBitmap);		// Delete the device dependant bitmap object
	DrawDibClose(hdd);		// Closes the drawDib device context
	AVIStreamGetFrameClose(pgf);	// Deallocates the GetFrame resources
	AVIStreamRelease(pavi);		// Release the stream
	AVIFileExit();			// Release the file
}

BOOL Initialize (GL_Window* window, Keys* keys)         // Any GL init code & user initialiazation goes here
{
	g_window = window;
	g_keys = keys;

	// Start Of User Initialization
	angle		= 0.0f;					// Set starting angle to zero
	hdd = DrawDibOpen();					// Grab a device context for our dib
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);			// Black background
	glClearDepth (1.0f);					// Depth buffer setup
	glDepthFunc (GL_LEQUAL);				// The type of depth testing (Less or equal)
	glEnable(GL_DEPTH_TEST);				// Enable depth testing
	glShadeModel (GL_SMOOTH);				// Select smooth shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Set perspective calculations to most accurate

	quadratic=gluNewQuadric();				// Create a pointer to the quadric object
	gluQuadricNormals(quadratic, GLU_SMOOTH);		// Create smooth normals
	gluQuadricTexture(quadratic, GL_TRUE);			// Create texture coords

	glEnable(GL_TEXTURE_2D);				// Enable texture mapping
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);	// Set texture max filter
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);	// Set texture min filter

	glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);	// Set the texture generation mode for S to sphere mapping
	glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);	// Set the texture generation mode for T to sphere mapping

	OpenAVI("data/face2.avi");				// Open the AVI file

	// Create the texture
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 256, 256, 0, GL_RGB, GL_UNSIGNED_BYTE, data);

	return true;		// Return TRUE (Initialization successful)
}

void Deinitialize (void)	// Any user deinitialization goes here
{
	CloseAVI();		// Close the AVI file
}

void Update (DWORD milliseconds)        // Perform motion updates here
{
	if (g_keys->keyDown [VK_ESCAPE] == TRUE)	// Is ESC being pressed?
	{
		TerminateApplication (g_window);	// Terminate the program
	}

	if (g_keys->keyDown [VK_F1] == TRUE)		// Is F1 being pressed?
	{
		ToggleFullscreen (g_window);		// Toggle fullscreen mode
	}

	if ((g_keys->keyDown [' ']) && !sp)		// Is space being pressed and not held?
	{
		sp=TRUE;				// Set sp to true
		effect++;				// Change effects (Increase effect)
		if (effect>3)				// Over our limit?
			effect=0;			// Reset back to 0
	}

	if (!g_keys->keyDown[' '])			// Is space released?
		sp=FALSE;				// Set sp to false

	if ((g_keys->keyDown ['B']) && !bp)		// Is 'B' being pressed and not held?
	{
		bp=TRUE;				// Set bp to true
		bg=!bg;					// Toggle background off/on
	}

	if (!g_keys->keyDown['B'])			// Is 'B' released?
		bp=FALSE;				// Set bp to false

	if ((g_keys->keyDown ['E']) && !ep)		// Is 'E' Being Pressed And Not Held?
	{
		ep=TRUE;				// Set ep to true
		env=!env;				// Toggle environment mapping off/on
	}

	if (!g_keys->keyDown['E'])			// Is 'E' released?
		ep=FALSE;				// Set ep to false

	angle += (float)(milliseconds) / 60.0f;		// Update angle based on the timer

	next+=milliseconds;				// Increase next based on the timer
	frame=next/mpf;					// Calculate the current frame

	if (frame>=lastframe)				// Are we at or past the last frame?
	{
		frame=0;				// Reset the frame back to zero (Start of video)
		next=0;					// Reset the animation timer (next)
	}
}

void Draw (void)        // Draw our scene
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear screen and depth buffer

	GrabAVIFrame(frame);		// Grab a frame from the AVI

	if (bg)				// Is background visible?
	{
		glLoadIdentity();	// Reset the modelview matrix
		glBegin(GL_QUADS);	// Begin drawing the background (One quad)
			// Front face
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 11.0f,  8.3f, -20.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-11.0f,  8.3f, -20.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-11.0f, -8.3f, -20.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 11.0f, -8.3f, -20.0f);
		glEnd();		// Done drawing the background
	}

	glLoadIdentity ();		// Reset the modelview matrix
	glTranslatef (0.0f, 0.0f, -10.0f);	// Translate 10 units into the screen

	if (env)			// Is environment mapping on?
	{
		glEnable(GL_TEXTURE_GEN_S);	// Enable texture coord generation for S
		glEnable(GL_TEXTURE_GEN_T);	// Enable texture coord generation for T
	}

	glRotatef(angle*2.3f,1.0f,0.0f,0.0f);	// Throw in some rotations to move things around a bit
	glRotatef(angle*1.8f,0.0f,1.0f,0.0f);	// Throw in some rotations to move things around a bit
	glTranslatef(0.0f,0.0f,2.0f);		// After Rotating Translate To New Position

	switch (effect)			// Which effect?
	{
	case 0:							// Effect 0 - cube
		glRotatef (angle*1.3f, 1.0f, 0.0f, 0.0f);	// Rotate on the X-axis by angle
		glRotatef (angle*1.1f, 0.0f, 1.0f, 0.0f);	// Rotate on the Y-axis by angle
		glRotatef (angle*1.2f, 0.0f, 0.0f, 1.0f);	// Rotate on the Z-axis by angle
		glBegin(GL_QUADS);				// Begin drawing a cube
			// Front face
			glNormal3f( 0.0f, 0.0f, 0.5f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
			// Back face
			glNormal3f( 0.0f, 0.0f,-0.5f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
			// Top face
			glNormal3f( 0.0f, 0.5f, 0.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
			// Bottom face
			glNormal3f( 0.0f,-0.5f, 0.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
			// Right face
			glNormal3f( 0.5f, 0.0f, 0.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
			// Left face
			glNormal3f(-0.5f, 0.0f, 0.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glEnd();	// Done drawing our cube
		break;		// Done effect 0

	case 1:			// Effect 1 - sphere
		glRotatef (angle*1.3f, 1.0f, 0.0f, 0.0f);	// Rotate on the X-axis by angle
		glRotatef (angle*1.1f, 0.0f, 1.0f, 0.0f);	// Rotate on the Y-axis by angle
		glRotatef (angle*1.2f, 0.0f, 0.0f, 1.0f);	// Rotate on the Z-axis by angle
		gluSphere(quadratic,1.3f,20,20);		// Draw a sphere
		break;		// Done drawing sphere

	case 2:			// Effect 2 - cylinder
		glRotatef (angle*1.3f, 1.0f, 0.0f, 0.0f);	// Rotate on the X-axis by angle
		glRotatef (angle*1.1f, 0.0f, 1.0f, 0.0f);	// Rotate on the Y-axis by angle
		glRotatef (angle*1.2f, 0.0f, 0.0f, 1.0f);	// Rotate on the Z-axis by angle
		glTranslatef(0.0f,0.0f,-1.5f);			// Center the cylinder
		gluCylinder(quadratic,1.0f,1.0f,3.0f,32,32);	// Draw a cylinder
		break;		// Done drawing cylinder
	}
	
	if (env)		// Environment mapping enabled?
	{
		glDisable(GL_TEXTURE_GEN_S);	// Disable texture coord generation for S
		glDisable(GL_TEXTURE_GEN_T);	// Disable texture coord generation for T
	}
	
	glFlush ();	// Flush the GL rendering pipeline
}

