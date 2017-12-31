/*
 *		This Code Was Created By Jeff Molofee 2003
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit My Site At nehe.gamedev.net
 */

#include <windows.h>													// Header File For Windows
#include <stdio.h>			// Header File For Standard Input/Output
#include <gl\gl.h>														// Header File For The OpenGL32 Library
#include <gl\glu.h>
#include <gl\glaux.h>														// Header File For The GLu32 Library
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

AUX_RGBImageRec *LoadBMP(char *Filename)				// Loads A Bitmap Image
{
	FILE *File=NULL;									// File Handle

	if (!Filename)										// Make Sure A Filename Was Given
	{
		return NULL;									// If Not Return NULL
	}

	File=fopen(Filename,"r");							// Check To See If The File Exists

	if (File)											// Does The File Exist?
	{
		fclose(File);									// Close The Handle
		return auxDIBImageLoad(Filename);				// Load The Bitmap And Return A Pointer
	}

	return NULL;										// If Load Failed Return NULL
}

int LoadGLTextures()									// Load Bitmaps And Convert To Textures
{
	int Status=FALSE;									// Status Indicator

	AUX_RGBImageRec *TextureImage[1];					// Create Storage Space For The Texture

	memset(TextureImage,0,sizeof(void *)*1);           	// Set The Pointer To NULL

	// Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
	if (TextureImage[0]=LoadBMP("Data/Wall.bmp"))
	{
		Status=TRUE;									// Set The Status To TRUE

		glGenTextures(1, &texture[0]);					// Create Three Textures

		// Create Nearest Filtered Texture
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);
	}

	if (TextureImage[0])								// If Texture Exists
	{
		if (TextureImage[0]->data)						// If Texture Image Exists
		{
			free(TextureImage[0]->data);				// Free The Texture Image Memory
		}

		free(TextureImage[0]);							// Free The Image Structure
	}

	return Status;										// Return The Status
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

	if (!LoadGLTextures())								// Jump To Texture Loading Routine
		return FALSE;									// If Texture Didn't Load Return FALSE

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
