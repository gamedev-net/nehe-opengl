/*
 *		This Code Was Created By Christopher Aliotta & Jeff Molofee 2000
 *		A HUGE Thanks To Fredric Echols For Cleaning Up And Optimizing
 *		The Base Code, Making It More Flexible!  If You've Found This Code
 *		Useful, Please Let Me Know.  Visit My Site At nehe.gamedev.net
 */

/*
	I took a different ( I think, better ) approach to porting this one.
	Instead of changing the data ( i.e., convert BMP's to RAW pics ) to
	suit my overwhelming laziness, I instead added things to take place of
	the Windows-specific code.  Particulary, I made a sufficient
	AUX_RGBImageRec struct ( I have no idea what the real one is like ),
	and my own LoadBMP function.  This should keep most of the code the
	way it was originally written.

	Have lots of fun.
	-Ken (kjrockot@home.com)
*/

// define this to compile for Windows
#ifdef WIN32
#include <windows.h>
#endif

#include <stdlib.h>
#include <stdio.h>			// Header File For Standard Input/Output
#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library
#include "SDL/SDL.h"

#define BOOL		bool
#define FALSE		0
#define TRUE		1

struct AUX_RGBImageRec {
	int sizeX, sizeY;
	GLubyte *data;
}; 

bool	keys[512];			// Array Used For The Keyboard Routine
bool	active=TRUE;		// Window Active Flag Set To TRUE By Default
bool	fullscreen=TRUE;	// Fullscreen Flag Set To Fullscreen Mode By Default
bool	light;				// Lighting ON/OFF
bool	lp;					// L Pressed?
bool	fp;					// F Pressed?
bool	gp;					// G Pressed? ( NEW )

GLfloat	xrot;				// X Rotation
GLfloat	yrot;				// Y Rotation
GLfloat xspeed;				// X Rotation Speed
GLfloat yspeed;				// Y Rotation Speed
GLfloat	z=-5.0f;			// Depth Into The Screen

GLfloat LightAmbient[]=		{ 0.5f, 0.5f, 0.5f, 1.0f };
GLfloat LightDiffuse[]=		{ 1.0f, 1.0f, 1.0f, 1.0f };
GLfloat LightPosition[]=	{ 0.0f, 0.0f, 2.0f, 1.0f };
GLuint	filter;				// Which Filter To Use
GLuint	texture[3];			// Storage For 3 Textures
GLuint	fogMode[]= { GL_EXP, GL_EXP2, GL_LINEAR };	// Storage For Three Types Of Fog
GLuint	fogfilter = 0;								// Which Fog Mode To Use 
GLfloat	fogColor[4] = {0.5f,0.5f,0.5f,1.0f};		// Fog Color

// Note that this cheaply done BMP loader doesn't care what format the
// BMP file is in.  So if it is anything but 24-bit color, the program
// will most likely crash :>
//
// -Ken
AUX_RGBImageRec *LoadBMP ( char *filename )
{
	FILE *bmp;
	int data_offset;
	AUX_RGBImageRec *image;	
	int size;

	image = ( AUX_RGBImageRec * ) malloc ( sizeof ( AUX_RGBImageRec ) );

	bmp = fopen ( filename, "rb" );
	if ( !bmp ) {
		fprintf ( stderr, "Couldn't open BMP file!\n" );
		exit ( 1 );
	}

	// The location of the bitmap data in the file is stored at offset 0x0A
	fseek ( bmp, 0x0A, SEEK_SET );
	fread ( &data_offset, 4, 1, bmp ); 

	// The width and height are stored at offset 0x12 into the file
	fseek ( bmp, 0x12, SEEK_SET );
	fread ( &image->sizeX, 4, 1, bmp );
	fread ( &image->sizeY, 4, 1, bmp );
	size = image->sizeX * image->sizeY;

	// Head to the data section
	fseek ( bmp, data_offset, SEEK_SET );

	// Allocate some mem for the pixels ( 3 bytes per-pixel )
	image->data = ( GLubyte * ) malloc ( size * 3 );

	// Friggin stupid BMP's use BGR format, AND they are upside-down...
	// how rediculous...
	for ( int i = image->sizeY - 1; i >= 0; i-- )
	{
		int offset = i * image->sizeX;
		for ( int j = 0; j < image->sizeX; j++ ) 
		{
			image->data[ ( offset + j ) * 3 + 2] = fgetc ( bmp );
			image->data[ ( offset + j ) * 3 + 1] = fgetc ( bmp );
			image->data[ ( offset + j ) * 3 + 0] = fgetc ( bmp );
		}
	}

	fclose ( bmp );

	return image; 
}

int LoadGLTextures()									// Load Bitmaps And Convert To Textures
{
	int Status=FALSE;									// Status Indicator

	AUX_RGBImageRec *TextureImage[1];

	// Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
	if (TextureImage[0]=LoadBMP("Data/Crate.bmp"))
	{
		Status=TRUE;									// Set The Status To TRUE

		glGenTextures(3, &texture[0]);					// Create Three Textures

		// Create Nearest Filtered Texture
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);

		// Create Linear Filtered Texture
		glBindTexture(GL_TEXTURE_2D, texture[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);

		// Create MipMapped Texture
		glBindTexture(GL_TEXTURE_2D, texture[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);
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
	if (!LoadGLTextures())								// Jump To Texture Loading Routine
	{
		return FALSE;									// If Texture Didn't Load Return FALSE
	}

	glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.5f,0.5f,0.5f,1.0f);					// We'll Clear To The Color Of The Fog
	glClearDepth(1.0f);									// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations

	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);		// Setup The Ambient Light
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);		// Setup The Diffuse Light
	glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);	// Position The Light
	glEnable(GL_LIGHT1);								// Enable Light One

	glFogi(GL_FOG_MODE, fogMode[fogfilter]);			// Fog Mode
	glFogfv(GL_FOG_COLOR, fogColor);					// Set Fog Color
	glFogf(GL_FOG_DENSITY, 0.35f);						// How Dense Will The Fog Be
	glHint(GL_FOG_HINT, GL_DONT_CARE);					// Fog Hint Value
	glFogf(GL_FOG_START, 1.0f);							// Fog Start Depth
	glFogf(GL_FOG_END, 5.0f);							// Fog End Depth
	glEnable(GL_FOG);									// Enables GL_FOG
	return TRUE;										// Initialization Went OK
}

int DrawGLScene(GLvoid)									// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The View
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);

	glBindTexture(GL_TEXTURE_2D, texture[filter]);

	glBegin(GL_QUADS);
		// Front Face
		glNormal3f( 0.0f, 0.0f, 1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		// Back Face
		glNormal3f( 0.0f, 0.0f,-1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		// Top Face
		glNormal3f( 0.0f, 1.0f, 0.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		// Bottom Face
		glNormal3f( 0.0f,-1.0f, 0.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		// Right face
		glNormal3f( 1.0f, 0.0f, 0.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		// Left Face
		glNormal3f(-1.0f, 0.0f, 0.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glEnd();

	xrot+=xspeed;
	yrot+=yspeed;
	return TRUE;										// Keep Going
}

int main ()
{
	BOOL	done=FALSE;			// Bool Variable To Exit Loop

	if ( SDL_Init ( SDL_INIT_VIDEO ) ) {
		fprintf ( stderr, "SDL_Init error: %s\n", SDL_GetError () );
		exit ( 1 );
	}

	if ( !SDL_SetVideoMode ( 1024, 768, 16, SDL_OPENGL | SDL_FULLSCREEN |
		SDL_DOUBLEBUF ) ) {
		fprintf ( stderr, "SDL_SetVideoMode error: %s\n",
			SDL_GetError () );
		SDL_Quit ();
		exit ( 2 );
	}

	if ( InitGL () == FALSE ) {
		fprintf ( stderr, "Error initializing OpenGL!\n" );
		SDL_Quit ();
		exit ( 3 );
	}

	ReSizeGLScene ( 1024, 768 );

	while(!done)		// Loop That Runs While done=FALSE
	{
		SDL_Event event;

		while ( SDL_PollEvent ( &event ) )
		{
			switch ( event.type ) {
			case SDL_QUIT:
				done = TRUE;
				break;
			case SDL_KEYDOWN:
				keys[event.key.keysym.sym] = TRUE;
				break;
			case SDL_KEYUP:
				keys[event.key.keysym.sym] = FALSE;
				break;
			}
		}

		if ( keys[SDLK_ESCAPE] ) done = TRUE;

		DrawGLScene ();
		SDL_GL_SwapBuffers ();	// Swap Buffers
		if (keys[SDLK_l] && !lp) // Process an 'L' keypress 
		{
			lp=TRUE;
			light=!light;
			if (!light)
			{
				glDisable(GL_LIGHTING);
			}
			else
			{
				glEnable(GL_LIGHTING);
			}
		}
		if (!keys[SDLK_l])
		{
			lp=FALSE;
		}
		if (keys[SDLK_f] && !fp)
		{
			fp=TRUE;
			filter+=1;
			if (filter>2)
			{
				filter=0;
			}
		}
		if (!keys[SDLK_f])
		{
			fp=FALSE;
		}
		if (keys[SDLK_PAGEUP])
		{
			z-=0.02f;
		}
		if (keys[SDLK_PAGEDOWN])
		{
			z+=0.02f;
		}
		if (keys[SDLK_UP])
		{
			xspeed-=0.01f;
		}
		if (keys[SDLK_DOWN])
		{
			xspeed+=0.01f;
		}
		if (keys[SDLK_RIGHT])
		{
			yspeed+=0.01f;
		}
		if (keys[SDLK_LEFT])
		{
			yspeed-=0.01f;
		}
		if (keys[SDLK_g] && !gp)
		{
			gp=TRUE;
			fogfilter+=1;
			if (fogfilter>2)
			{
				fogfilter=0;
			}
			glFogi (GL_FOG_MODE, fogMode[fogfilter]);	// Fog Mode
		}
		if (!keys[SDLK_g])
		{
			gp=FALSE;
		}
	}

	// Shutdown
	SDL_Quit ();

	return 0;
}
