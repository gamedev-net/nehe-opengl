//---------------------------------------------------------------------------

#include <windows.h>	// Header file for windows
#include <gl\gl.h>	// Header file for the OpenGL32 library
#include <gl\glu.h>	// Header file for the GLu32 library
#include <gl\glaux.h>	// Header file for the GLaux library
#include "NeHeGL.h"	// Header file for NeHeGL
#include "resource.h"	// Header file for resource

#ifndef CDS_FULLSCREEN          // CDS_FULLSCREEN is not defined by some
#define CDS_FULLSCREEN 4	// compilers. By defining it this way,
#endif				// we can avoid errors

#pragma hdrstop

//---------------------------------------------------------------------------

GL_Window *g_window;
Keys *g_keys;

// User defined variables
GLuint texture[3];		// Storage for 3 textures

struct object		        // Create a structure called object
{
	int tex;		// Integer used to select our texture
	float x;		// X position
	float y;		// Y position
	float z;		// Z position
	float yi;		// Y increase speed (Fall speed)
	float spinz;		// Z axis spin
	float spinzi;		// Z axis spin speed
	float flap;		// Flapping triangles :)
	float fi;		// Flap direction (Increase value)
};

object obj[50];			// Create 50 objects using the object structure

void SetObject(int loop)				// Sets the initial value of each object (Random)
{
	obj[loop].tex=rand()%3;				// Texture can be one of 3 textures
	obj[loop].x=rand()%34-17.0f;			// Random x value from -17.0f to 17.0f
	obj[loop].y=18.0f;				// Set y position to 18 (Off top of screen)
	obj[loop].z=-((rand()%30000/1000.0f)+10.0f);	// z is a random value from -10.0f to -40.0f
	obj[loop].spinzi=(rand()%10000)/5000.0f-1.0f;	// spinzi is a random value from -1.0f to 1.0f
	obj[loop].flap=0.0f;				// flap starts off at 0.0f;
	obj[loop].fi=0.05f+(rand()%100)/1000.0f;	// fi is a random value from 0.05f to 0.15f
	obj[loop].yi=0.001f+(rand()%1000)/10000.0f;	// yi is a random value from 0.001f to 0.101f
}

void LoadGLTextures()		// Creates textures from bitmaps in the resource file
{
	HBITMAP hBMP;		// Handle of the bitmap
	BITMAP	BMP;		// Bitmap structure

	// The ID of the 3 bitmap images we want to load from the resource file
	byte Texture[] = {IDB_BUTTERFLY1,IDB_BUTTERFLY2,IDB_BUTTERFLY3};

	glGenTextures(sizeof(Texture), &texture[0]);		// Generate 3 textures (sizeof(Texture) = 3 ID's)
	for (int loop=0; loop<sizeof(Texture); loop++)		// Loop through all the ID's (Bitmap images)
	{
		hBMP=(HBITMAP)LoadImage(GetModuleHandle(NULL),MAKEINTRESOURCE(Texture[loop]), IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
		if (hBMP)					// Does the bitmap exist?
		{						// If so...
			GetObject(hBMP,sizeof(BMP), &BMP);	// Get the object
								// hBMP: Handle to graphics object
								// sizeof(BMP): Size of buffer for object information
								// Buffer for object information
			glPixelStorei(GL_UNPACK_ALIGNMENT,4);			                        // Pixel storage mode (Word alignment / 4 bytes)
			glBindTexture(GL_TEXTURE_2D, texture[loop]);		                        // Bind our texture
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);                 // Linear filtering
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);   // Mipmap linear filtering

			// Generate mipmapped texture (3 bytes, width, height and data from the BMP)
			gluBuild2DMipmaps(GL_TEXTURE_2D, 3, BMP.bmWidth, BMP.bmHeight, GL_BGR_EXT, GL_UNSIGNED_BYTE, BMP.bmBits);
			DeleteObject(hBMP);		        // Delete the bitmap object
		}
	}
}

BOOL Initialize (GL_Window* window, Keys* keys)         // Any GL init code & user initialiazation goes here
{
	g_window = window;
	g_keys = keys;

	// Start of user initialization
	LoadGLTextures();			        	// Load the textures from our resource file
	
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);	        	// Black background
	glClearDepth (1.0f);			        	// Depth buffer setup
	glDepthFunc (GL_LEQUAL);		        	// The type of depth testing (Less or equal)
	glDisable(GL_DEPTH_TEST);			        // Disable depth testing
	glShadeModel (GL_SMOOTH);			        // Select smooth shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Set perspective calculations to most accurate
	glEnable(GL_TEXTURE_2D);				// Enable texture mapping
	glBlendFunc(GL_ONE,GL_SRC_ALPHA);			// Set blending mode (Cheap / quick)
	glEnable(GL_BLEND);					// Enable blending

	for (int loop=0; loop<50; loop++)	// Loop to initialize 50 objects
	{
		SetObject(loop);		// Call SetObject to assign new random values
	}

	return TRUE;				// Return TRUE (Initialization successful)
}

void Deinitialize (void)        // Any user deinitialization goes here
{
}

void Update (DWORD milliseconds)                        // Perform motion updates here
{
	if (g_keys->keyDown [VK_ESCAPE] == true)	// Is ESC being pressed?
	{
		TerminateApplication (g_window);	// Terminate the program
	}

	if (g_keys->keyDown [VK_F1] == true)		// Is F1 being pressed?
	{
		ToggleFullscreen (g_window);		// Toggle fullscreen mode
	}
}

void Draw (void)                // Draw the scene
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear screen and depth buffer

	for (int loop=0; loop<50; loop++)				// Loop of 50 (Draw 50 objects)
	{
		glLoadIdentity ();					// Reset the modelview matrix
		glBindTexture(GL_TEXTURE_2D, texture[obj[loop].tex]);	// Bind our texture
		glTranslatef(obj[loop].x,obj[loop].y,obj[loop].z);	// Position the object
		glRotatef(45.0f,1.0f,0.0f,0.0f);			// Rotate on the X-axis
		glRotatef((obj[loop].spinz),0.0f,0.0f,1.0f);		// Spin on the Z-axis

		glBegin(GL_TRIANGLES);		// Begin drawing triangles
			// First triangle
			glTexCoord2f(1.0f,1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);
			glTexCoord2f(0.0f,1.0f); glVertex3f(-1.0f, 1.0f, obj[loop].flap);
			glTexCoord2f(0.0f,0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);

			// Second triangle
			glTexCoord2f(1.0f,1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);
			glTexCoord2f(0.0f,0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);
			glTexCoord2f(1.0f,0.0f); glVertex3f( 1.0f,-1.0f, obj[loop].flap);

		glEnd();				// Done drawing triangles

		obj[loop].y-=obj[loop].yi;		// Move object down the screen
		obj[loop].spinz+=obj[loop].spinzi;	// Increase Z rotation by spinzi
		obj[loop].flap+=obj[loop].fi;		// Increase flap value by fi

		if (obj[loop].y<-18.0f)			// Is object off the screen?
		{
			SetObject(loop);		// If so, reassign new values
		}

		if ((obj[loop].flap>1.0f) || (obj[loop].flap<-1.0f))	// Time to change flap direction?
		{
			obj[loop].fi=-obj[loop].fi;	// Change direction by making fi = -fi
		}
	}

	Sleep(15);		// Create a short delay (15 milliseconds)

	glFlush ();		// Flush the GL rendering pipeline
}
