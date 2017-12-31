
/**************************************
*                                     *
*   Jeff Molofee's Lesson41           *
*   SDL porting by Anthony Whitehead  *
*          nehe.gamedev.net           *
*                2003                 *
*                                     *
**************************************/

// Includes
#ifdef WIN32													// If We're Under MSVC
#include <windows.h>											// Include The Windows Header
#else															// Otherwise
#include <stdio.h>												// Include The Standar IO Header
#include <stdlib.h>												// And The Standard Lib (for exit())
#include <string.h>												// And The Standard Lib (for exit())
#endif															// Then...

#include <math.h>												// We Require The Math Lib For Sin and Cos
#include <GL/gl.h>												// And Obviously The OpenGL Header
#include <GL/glu.h>												// And The GLu Heander

#include <SDL.h>												// Finally: The SDL Header!

#include "main.h"												// We're Including theHeader Where Defs And Prototypes Are

#ifdef WIN32													// If We're Under MSVC
#pragma comment( lib, "OpenGL32.lib" )							// We Can Tell The Linker To Look For OpenGl32.lib ...
#pragma comment( lib, "GLu32.lib" )								// ...GLu32.lib ...
#pragma comment( lib, "SDLmain.lib" )							// ...SDLmain.lib ...
#pragma comment( lib, "SDL.lib" )								// And SDL.lib At Link Time
#endif															// For Other Platforms, Such As LINUX, The Link Flags Are Defined in The Makefile


extern S_AppStatus AppStatus;									// We're Using This Struct As A Repository For The Application State (Visible, Focus, ecc)

/* User Defined Variables */
GLfloat	fogColor[4] = {0.6f, 0.3f, 0.0f, 1.0f};							// Fog Colour 
GLfloat camz;															// Camera Z Depth
GLfloat camx;															// Camera Z Depth

/* Variables Necessary For FogCoordfEXT */
#define GL_FOG_COORDINATE_SOURCE_EXT		0x8450
#define GL_FOG_COORDINATE_EXT			0x8451

GLuint	texture[1];														// One Texture (For The Walls)

/*
 * Bitmap loading code from lesson06 - Ti Leggett
 */
int BuildTexture( char *filename, int texid )
{
    /* Status indicator */
    int Status = false;

    /* Create storage space for the texture */
    SDL_Surface *TextureImage[1]; 

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage[0] = SDL_LoadBMP( filename ) ) )
    {
	/* Set the status to true */
	Status = true;

	/* Create The Texture */
	glGenTextures( 1, &texture[texid] );

	/* Typical Texture Generation Using Data From The Bitmap */
	glBindTexture( GL_TEXTURE_2D, texture[texid] );

	/* Generate The Texture */
	glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0]->w,
			  TextureImage[0]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[0]->pixels );

	/* Linear Filtering */
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    }

    /* Free up any memory we may have used */
    if ( TextureImage[0] )
	    SDL_FreeSurface( TextureImage[0] );

    return Status;
}

// Code
bool InitGL(SDL_Surface *S)										// Any OpenGL Initialization Code Goes Here
{
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);								// Black Background
	glClearDepth (1.0f);												// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);											// The Type Of Depth Testing
	glEnable (GL_DEPTH_TEST);											// Enable Depth Testing
	glShadeModel (GL_SMOOTH);											// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);					// Set Perspective Calculations To Most Accurate

	return true;												// Return TRUE (Initialization Successful)
}


int Extension_Init()
{
    char extensions[ 16384 ];
    char Extension_Name[] = "GL_EXT_fog_coord";
    char *buf;

    sprintf( extensions, "%s", (char *)glGetString( GL_EXTENSIONS ) );
    buf = strtok( extensions, " " );
    while( buf != NULL )
    {
	if( !strcmp( Extension_Name, buf ) )
	{
	    Log( "%s found, great.\n", Extension_Name );
	    return true;
	}
	buf = strtok( NULL, " " );
    }

    Log( "%s\n", (char *)glGetString( GL_EXTENSIONS ) );
    Log( "%s not found, dammit.\n", Extension_Name );
    return false;
}

bool Initialize(void)											// Any Application & User Initialization Code Goes Here
{
	AppStatus.Visible	= true;								// At The Beginning, Our App Is Visible
	AppStatus.MouseFocus	= true;								// And Have Both Mouse
	AppStatus.KeyboardFocus = true;								// And Input Focus

	// Start Of User Initialization
	if (!Extension_Init())												// Check And Enable Fog Extension If Available
		return false;													// Return False If Extension Not Supported

	if (!BuildTexture("data/wall.bmp", 0 ))						// Load The Wall Texture
		return false;													// Return False If Loading Failed

	glEnable(GL_TEXTURE_2D);											// Enable Texture Mapping

	// Set Up Fog 
	glEnable(GL_FOG);													// Enable Fog
	glFogi(GL_FOG_MODE, GL_LINEAR);										// Fog Fade Is Linear
	glFogfv(GL_FOG_COLOR, fogColor);									// Set The Fog Color
	glFogf(GL_FOG_START,  1.0f);										// Set The Fog Start
	glFogf(GL_FOG_END,    0.0f);										// Set The Fog End
	glHint(GL_FOG_HINT, GL_NICEST);										// Per-Pixel Fog Calculation
	glFogi(GL_FOG_COORDINATE_SOURCE_EXT, GL_FOG_COORDINATE_EXT);		// Set Fog Based On Vertice Coordinates

	camz =	-19.0f;														// Set Camera Z Position To -19.0f
	camx =	0.0f;														// Set Camera X Position To 0.0f

	return true;												// Return TRUE (Initialization Successful)
}


void Deinitialize(void)											// Any User Deinitialization Goes Here
{
	return;														// We Have Nothing To Deinit Now
}

void Update(Uint32 Milliseconds, Uint8 *Keys)					// Perform Motion Updates Here
{
	if(Keys)													// If We're Sent A Key Event With The Update
	{
		if(Keys[SDLK_ESCAPE])									// And If The Key Pressed Was ESC
		{
			TerminateApplication();								// Terminate The Application
		}

		if(Keys[SDLK_F1])										// If The Key Pressed Was F1
		{
			ToggleFullscreen();									// Use SDL Function To Toggle Fullscreen Mode (But Not In Windows :) )
		}

		if(Keys[SDLK_UP])										// If The Key Pressed Was Up Arrow
		{
			camz+=(float)(Milliseconds)/100.0f;							// Move camera in
		}

		if(Keys[SDLK_DOWN])										// If The Key Pressed Was Down Arrow
		{
			camz-=(float)(Milliseconds)/100.0f;							// Move camera out
		}

		if(Keys[SDLK_LEFT])										// If The Key Pressed Was Left Arrow
		{
			camx+=(float)(Milliseconds)/100.0f;							// Move camera left
		}

		if(Keys[SDLK_RIGHT])										// If The Key Pressed Was Right Arrow
		{
			camx-=(float)(Milliseconds)/100.0f;							// Move camera right
		}
	}

	return;														// We Always Make Functions Return
}

void Draw(void)													// Our Drawing Code
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);				// Clear Screen And Depth Buffer
	glLoadIdentity ();													// Reset The Modelview Matrix

	glTranslatef(camx, 0.0f, camz);							// Move To Our Camera Z/X Position

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

	return;														// We're Always Making Functions Return
}
