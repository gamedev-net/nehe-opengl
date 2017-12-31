/*************************************
*                                    *
*      Jeff Molofee's Lesson 38      *
*          nehe.gamedev.net          *
*                2002                *
*                                    *
*************************************/

#include <windows.h>											// Header File For Windows
#include <gl\gl.h>												// Header File For The OpenGL32 Library
#include <gl\glu.h>												// Header File For The GLu32 Library
#include <gl\glaux.h>											// Header File For The GLaux Library
#include "NeHeGL.h"												// Header File For NeHeGL
#include "resource.h"											// Header File For Resource (*IMPORTANT*)

#pragma comment( lib, "opengl32.lib" )							// Search For OpenGL32.lib While Linking
#pragma comment( lib, "glu32.lib" )								// Search For GLu32.lib While Linking
#pragma comment( lib, "glaux.lib" )								// Search For GLaux.lib While Linking

#ifndef CDS_FULLSCREEN											// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4										// Compilers. By Defining It This Way,
#endif															// We Can Avoid Errors

GL_Window*	g_window;
Keys*		g_keys;

// User Defined Variables
GLuint texture[3];												// Storage For 3 Textures

struct object													// Create A Structure Called Object
{
	int   tex;													// Integer Used To Select Our Texture
	float x;													// X Position
	float y;													// Y Position
	float z;													// Z Position
	float yi;													// Y Increase Speed (Fall Speed)
	float spinz;												// Z Axis Spin
	float spinzi;												// Z Axis Spin Speed
	float flap;													// Flapping Triangles :)
	float fi;													// Flap Direction (Increase Value)
};

object obj[50];													// Create 50 Objects Using The Object Structure

void SetObject(int loop)										// Sets The Initial Value Of Each Object (Random)
{
	obj[loop].tex=rand()%3;										// Texture Can Be One Of 3 Textures
	obj[loop].x=rand()%34-17.0f;								// Random x Value From -17.0f To 17.0f
	obj[loop].y=18.0f;											// Set y Position To 18 (Off Top Of Screen)
	obj[loop].z=-((rand()%30000/1000.0f)+10.0f);				// z Is A Random Value From -10.0f To -40.0f
	obj[loop].spinzi=(rand()%10000)/5000.0f-1.0f;				// spinzi Is A Random Value From -1.0f To 1.0f
	obj[loop].flap=0.0f;										// flap Starts Off At 0.0f;
	obj[loop].fi=0.05f+(rand()%100)/1000.0f;					// fi Is A Random Value From 0.05f To 0.15f
	obj[loop].yi=0.001f+(rand()%1000)/10000.0f;					// yi Is A Random Value From 0.001f To 0.101f
}

void LoadGLTextures()											// Creates Textures From Bitmaps In The Resource File
{
	HBITMAP hBMP;												// Handle Of The Bitmap
	BITMAP	BMP;												// Bitmap Structure

	// The ID Of The 3 Bitmap Images We Want To Load From The Resource File
	byte	Texture[]={	IDB_BUTTERFLY1,	IDB_BUTTERFLY2,	IDB_BUTTERFLY3 };

	glGenTextures(sizeof(Texture), &texture[0]);				// Generate 3 Textures (sizeof(Texture)=3 ID's)
	for (int loop=0; loop<sizeof(Texture); loop++)				// Loop Through All The ID's (Bitmap Images)
	{
		hBMP=(HBITMAP)LoadImage(GetModuleHandle(NULL),MAKEINTRESOURCE(Texture[loop]), IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
		if (hBMP)												// Does The Bitmap Exist?
		{														// If So...
			GetObject(hBMP,sizeof(BMP), &BMP);					// Get The Object
																// hBMP: Handle To Graphics Object
																// sizeof(BMP): Size Of Buffer For Object Information
																// Buffer For Object Information
			glPixelStorei(GL_UNPACK_ALIGNMENT,4);				// Pixel Storage Mode (Word Alignment / 4 Bytes)
			glBindTexture(GL_TEXTURE_2D, texture[loop]);		// Bind Our Texture
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);	// Linear Filtering
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR); // Mipmap Linear Filtering

			// Generate Mipmapped Texture (3 Bytes, Width, Height And Data From The BMP)
			gluBuild2DMipmaps(GL_TEXTURE_2D, 3, BMP.bmWidth, BMP.bmHeight, GL_BGR_EXT, GL_UNSIGNED_BYTE, BMP.bmBits);
			DeleteObject(hBMP);									// Delete The Bitmap Object
		}
	}
}

BOOL Initialize (GL_Window* window, Keys* keys)					// Any GL Init Code & User Initialiazation Goes Here
{
	g_window	= window;
	g_keys		= keys;

	// Start Of User Initialization
	LoadGLTextures();											// Load The Textures From Our Resource File
	
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
	glClearDepth (1.0f);										// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);									// The Type Of Depth Testing (Less Or Equal)
	glDisable(GL_DEPTH_TEST);									// Disable Depth Testing
	glShadeModel (GL_SMOOTH);									// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Set Perspective Calculations To Most Accurate
	glEnable(GL_TEXTURE_2D);									// Enable Texture Mapping
	glBlendFunc(GL_ONE,GL_SRC_ALPHA);							// Set Blending Mode (Cheap / Quick)
	glEnable(GL_BLEND);											// Enable Blending

	for (int loop=0; loop<50; loop++)							// Loop To Initialize 50 Objects
	{
		SetObject(loop);										// Call SetObject To Assign New Random Values
	}

	return TRUE;												// Return TRUE (Initialization Successful)
}

void Deinitialize (void)										// Any User DeInitialization Goes Here
{
}

void Update (DWORD milliseconds)								// Perform Motion Updates Here
{
	if (g_keys->keyDown [VK_ESCAPE] == TRUE)					// Is ESC Being Pressed?
	{
		TerminateApplication (g_window);						// Terminate The Program
	}

	if (g_keys->keyDown [VK_F1] == TRUE)						// Is F1 Being Pressed?
	{
		ToggleFullscreen (g_window);							// Toggle Fullscreen Mode
	}
}

void Draw (void)												// Draw The Scene
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer

	for (int loop=0; loop<50; loop++)							// Loop Of 50 (Draw 50 Objects)
	{
		glLoadIdentity ();										// Reset The Modelview Matrix
		glBindTexture(GL_TEXTURE_2D, texture[obj[loop].tex]);	// Bind Our Texture
		glTranslatef(obj[loop].x,obj[loop].y,obj[loop].z);		// Position The Object
		glRotatef(45.0f,1.0f,0.0f,0.0f);						// Rotate On The X-Axis
		glRotatef((obj[loop].spinz),0.0f,0.0f,1.0f);			// Spin On The Z-Axis

		glBegin(GL_TRIANGLES);									// Begin Drawing Triangles
			// First Triangle														    _____
			glTexCoord2f(1.0f,1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);				//	(2)|    / (1)
			glTexCoord2f(0.0f,1.0f); glVertex3f(-1.0f, 1.0f, obj[loop].flap);	//	   |  /
			glTexCoord2f(0.0f,0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);				//	(3)|/

			// Second Triangle
			glTexCoord2f(1.0f,1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);				//	       /|(1)
			glTexCoord2f(0.0f,0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);				//	     /  |
			glTexCoord2f(1.0f,0.0f); glVertex3f( 1.0f,-1.0f, obj[loop].flap);	//	(2)/____|(3)

		glEnd();												// Done Drawing Triangles

		obj[loop].y-=obj[loop].yi;								// Move Object Down The Screen
		obj[loop].spinz+=obj[loop].spinzi;						// Increase Z Rotation By spinzi
		obj[loop].flap+=obj[loop].fi;							// Increase flap Value By fi

		if (obj[loop].y<-18.0f)									// Is Object Off The Screen?
		{
			SetObject(loop);									// If So, Reassign New Values
		}

		if ((obj[loop].flap>1.0f) || (obj[loop].flap<-1.0f))	// Time To Change Flap Direction?
		{
			obj[loop].fi=-obj[loop].fi;							// Change Direction By Making fi = -fi
		}
	}

	Sleep(15);													// Create A Short Delay (15 Milliseconds)

	glFlush ();													// Flush The GL Rendering Pipeline
}
