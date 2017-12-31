/***********************************************
*             LESSON 22 PORT TO GLUT           *
*                                              *
*         Bruce's GLUT OpenGL Basecode         *
*  Specially made for Nehe's Gamedev Website   *
*            http://nehe.gamedev.net           *
*                April 2003                    *
*                                              *
************************************************
* Project Information:
*
* Author: Bruce "Sinner" Barrera
* E-mail: sinner@opengl.com.br
* Date  : around April 2003 :-)
* Glut Version: 3.7.6
*
* Very special thanks to all people who
* contributed with any online tutors or
* help files. Keep coding!
*
***********************************************/

#include <wchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <GL/glut.h>
#include "glext.h"													// Header File For Multitexturing
#include "frames.h"
#include "tga.h"

#define MAX_EMBOSS (GLfloat)0.008f	// Maximum Emboss-Translate. Increase To Get Higher Immersion
									// At A Cost Of Lower Quality (More Artifacts Will Occur!)

/*	Here Comes The ARB-Multitexture Support.
 *	There Are (Optimally) 6 New Commands To The OpenGL Set:
 *	glMultiTexCoordifARB i=1..4	: Sets Texture-Coordinates For Texel-Pipeline #i
 *	glActiveTextureARB			: Sets Active Texel-Pipeline
 *	glClientActiveTextureARB	: Sets Active Texel-Pipeline For The Pointer-Array-Commands
 *
 *	There Are Even More For The Various Formats Of glMultiTexCoordi{f,fv,d,i}, But We Don't Need Them.
 */

#define __ARB_ENABLE true											// Used To Disable ARB Extensions Entirely

// #define EXT_INFO													// Do You Want To See Your Extensions At Start-Up?
#define MAX_EXTENSION_SPACE 10240									// Characters for Extension-Strings
#define MAX_EXTENSION_LENGTH 256									// Maximum Of Characters In One Extension-String
bool multitextureSupported=false;									// Flag Indicating Whether Multitexturing Is Supported
bool useMultitexture=true;											// Use It If It Is Supported?
GLint maxTexelUnits=1;												// Number Of Texel-Pipelines. This Is At Least 1.

#ifdef _WIN32
	PFNGLMULTITEXCOORD1FARBPROC		glMultiTexCoord1fARB	= NULL;
	PFNGLMULTITEXCOORD2FARBPROC		glMultiTexCoord2fARB	= NULL;
	PFNGLMULTITEXCOORD3FARBPROC		glMultiTexCoord3fARB	= NULL;
	PFNGLMULTITEXCOORD4FARBPROC		glMultiTexCoord4fARB	= NULL;
	PFNGLACTIVETEXTUREARBPROC		glActiveTextureARB		= NULL;
	PFNGLCLIENTACTIVETEXTUREARBPROC	glClientActiveTextureARB= NULL;	
#endif

#define ONE_SECOND 		 1		// one second
#define MAX_TEXTURES 	 10  	// max textures displayed

/* creates a enum type for mouse buttons */
enum {
    BUTTON_LEFT = 0,
    BUTTON_RIGHT,
    BUTTON_LEFT_TRANSLATE,
};

/* set global variables */
int mButton = -1;
int mOldY, mOldX;

/* vectors that makes the rotation and translation of the cube */
float eye[3] = {0.0f, 0.0f, 0.0f};
float rot[3] = {0.0f, 0.0f, 0.0f};

const int ESC = 27;

int wireframe = 0;

/* windows size and position constants */
const int GL_WIN_WIDTH = 640;
const int GL_WIN_HEIGHT = 480;
const int GL_WIN_INITIAL_X = 0;
const int GL_WIN_INITIAL_Y = 0;

/* array to hold texture handles */
GLuint g_TexturesArray[MAX_TEXTURES];

bool	fullscreen=true;											// Fullscreen Flag Set To Fullscreen Mode By Default
bool	emboss=false;												// Emboss Only, No Basetexture?
bool    bumps=true;													// Do Bumpmapping?

GLfloat	xrot;														// X Rotation
GLfloat	yrot;														// Y Rotation
GLfloat xspeed;														// X Rotation Speed
GLfloat yspeed;														// Y Rotation Speed
GLfloat	z=-5.0f;													// Depth Into The Screen

GLuint	filter=1;													// Which Filter To Use
GLuint	texture[3];													// Storage For 3 Textures
GLuint  bump[3];													// Our Bumpmappings
GLuint  invbump[3];													// Inverted Bumpmaps
GLuint	glLogo;														// Handle For OpenGL-Logo
GLuint  multiLogo;													// Handle For Multitexture-Enabled-Logo

GLfloat LightAmbient[]	= { 0.2f, 0.2f, 0.2f};						// Ambient Light is 20% white
GLfloat LightDiffuse[]	= { 1.0f, 1.0f, 1.0f};						// Diffuse Light is white
GLfloat LightPosition[] = { 0.0f, 0.0f, 2.0f};						// Position is somewhat in front of screen

GLfloat Gray[]= {0.5f,0.5f,0.5f,1.0f};

// Data Contains The Faces For The Cube In Format 2xTexCoord, 3xVertex;
// Note That The Tesselation Of The Cube Is Only Absolute Minimum.
GLfloat data[]= {
		// FRONT FACE
		0.0f, 0.0f,		-1.0f, -1.0f, +1.0f,
		1.0f, 0.0f,		+1.0f, -1.0f, +1.0f,
		1.0f, 1.0f,		+1.0f, +1.0f, +1.0f,
		0.0f, 1.0f,		-1.0f, +1.0f, +1.0f,
		// BACK FACE
		1.0f, 0.0f,		-1.0f, -1.0f, -1.0f,
		1.0f, 1.0f,		-1.0f, +1.0f, -1.0f,
		0.0f, 1.0f,		+1.0f, +1.0f, -1.0f,
		0.0f, 0.0f,		+1.0f, -1.0f, -1.0f,
		// Top Face
		0.0f, 1.0f,		-1.0f, +1.0f, -1.0f,
		0.0f, 0.0f,		-1.0f, +1.0f, +1.0f,
		1.0f, 0.0f,		+1.0f, +1.0f, +1.0f,
		1.0f, 1.0f,		+1.0f, +1.0f, -1.0f,
		// Bottom Face
		1.0f, 1.0f,		-1.0f, -1.0f, -1.0f,
		0.0f, 1.0f,		+1.0f, -1.0f, -1.0f,
		0.0f, 0.0f,		+1.0f, -1.0f, +1.0f,
		1.0f, 0.0f,		-1.0f, -1.0f, +1.0f,
		// Right Face
		1.0f, 0.0f,		+1.0f, -1.0f, -1.0f,
		1.0f, 1.0f,		+1.0f, +1.0f, -1.0f,
		0.0f, 1.0f,		+1.0f, +1.0f, +1.0f,
		0.0f, 0.0f,		+1.0f, -1.0f, +1.0f,
		// Left Face
		0.0f, 0.0f,		-1.0f, -1.0f, -1.0f,
		1.0f, 0.0f,		-1.0f, -1.0f,  1.0f,
		1.0f, 1.0f,		-1.0f,  1.0f,  1.0f,
		0.0f, 1.0f,		-1.0f,  1.0f, -1.0f
};


void drawFrameRate(char *str, void *font, GLclampf r, GLclampf g, GLclampf b,
              GLfloat x, GLfloat y);

bool doMesh1TexelUnits(void);
bool doMesh2TexelUnits(void);
bool doMeshNoBumps(void);

///////////////////////////////////////////////////////////////////////////////////////////////////////////

// Always Check For Extension-Availability During Run-Time!
// Here We Go!
bool isInString(char *string, const char *search) {
	int pos=0;
	int maxpos=strlen(search)-1;
	int len=strlen(string);	
	char *other;
	for (int i=0; i<len; i++) {
		if ((i==0) || ((i>1) && string[i-1]=='\n')) {				// New Extension Begins Here!
			other=&string[i];			
			pos=0;													// Begin New Search
			while (string[i]!='\n') {								// Search Whole Extension-String
				if (string[i]==search[pos]) pos++;					// Next Position
				if ((pos>maxpos) && string[i+1]=='\n') return true; // We Have A Winner!
				i++;
			}			
		}
	}	
	return false;													// Sorry, Not Found!
}

// isMultitextureSupported() Checks At Run-Time If Multitexturing Is Supported
bool initMultitexture(void) {
	char *extensions;	
	extensions=strdup((char *) glGetString(GL_EXTENSIONS));			// Fetch Extension String
	int len=strlen(extensions);
	for (int i=0; i<len; i++)										// Separate It By Newline Instead Of Blank
		if (extensions[i]==' ') extensions[i]='\n';

#ifdef EXT_INFO
	printf("%s","\nSupported GL extensions");
#endif

	if (isInString(extensions,"GL_ARB_multitexture")				// Is Multitexturing Supported?
		&& __ARB_ENABLE												// Override-Flag
		&& isInString(extensions,"GL_EXT_texture_env_combine"))		// Is texture_env_combining Supported?
	{	
#ifdef _WIN32
		glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB,&maxTexelUnits);
		glMultiTexCoord1fARB	= (PFNGLMULTITEXCOORD1FARBPROC)		wglGetProcAddress("glMultiTexCoord1fARB");
		glMultiTexCoord2fARB	= (PFNGLMULTITEXCOORD2FARBPROC)		wglGetProcAddress("glMultiTexCoord2fARB");
		glMultiTexCoord3fARB	= (PFNGLMULTITEXCOORD3FARBPROC)		wglGetProcAddress("glMultiTexCoord3fARB");
		glMultiTexCoord4fARB	= (PFNGLMULTITEXCOORD4FARBPROC)		wglGetProcAddress("glMultiTexCoord4fARB");
		glActiveTextureARB		= (PFNGLACTIVETEXTUREARBPROC)		wglGetProcAddress("glActiveTextureARB");
		glClientActiveTextureARB= (PFNGLCLIENTACTIVETEXTUREARBPROC)	wglGetProcAddress("glClientActiveTextureARB");		
#endif
#ifdef EXT_INFO
	printf("%s","\nThe GL_ARB_multitexture extension will be used.");
#endif
		return true;
	}
	useMultitexture=false;											// We Can't Use It If It Isn't Supported!
	return false;
}

void initLights(void) {

	glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient);				// Load Light-Parameters Into GL_LIGHT1
	glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse);	
	glLightfv( GL_LIGHT1, GL_POSITION, LightPosition);

	glEnable(GL_LIGHT1);	
}

// Here I swapped auxDIBImageLoad for LoadTGA
int LoadGLTextures(){												// Load Bitmaps And Convert To Textures
	bool status=true;												// Status Indicator
	tImageTGA *Image=NULL;									// Create Storage Space For The Texture
	char *alpha=NULL;

	// Load The Tile-Bitmap For Base-Texture
	if (Image=LoadTGA("Data/Base.tga")) {											
		glGenTextures(3, texture);									// Create Three Textures

		// Create Nearest Filtered Texture
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		//                             ========
		// Use GL_RGB8 Instead Of "3" In glTexImage2D. Also Defined By GL: GL_RGBA8 Etc.
		// NEW: Now Creating GL_RGBA8 Textures, Alpha Is 1.0f Where Not Specified By Format.

		// Create Linear Filtered Texture
		glBindTexture(GL_TEXTURE_2D, texture[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create MipMapped Texture
		glBindTexture(GL_TEXTURE_2D, texture[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, Image->sizeX, Image->sizeY, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
	}
	else status=false;
	if (Image) {													// If Texture Exists
		if (Image->data) delete Image->data;						// If Texture Image Exists
		delete Image;
		Image=NULL;
	}	
	
	// Load The Bumpmaps
	if (Image=LoadTGA("Data/Bump.tga")) {			
		glPixelTransferf(GL_RED_SCALE,0.5f);						// Scale RGB By 50%, So That We Have Only			
		glPixelTransferf(GL_GREEN_SCALE,0.5f);						// Half Intenstity
		glPixelTransferf(GL_BLUE_SCALE,0.5f);

		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);	// No Wrapping, Please!
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
		glTexParameterfv(GL_TEXTURE_2D,GL_TEXTURE_BORDER_COLOR,Gray);

		glGenTextures(3, bump);										// Create Three Textures

		// Create Nearest Filtered Texture
		glBindTexture(GL_TEXTURE_2D, bump[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		// Create Linear Filtered Texture
		glBindTexture(GL_TEXTURE_2D, bump[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create MipMapped Texture
		glBindTexture(GL_TEXTURE_2D, bump[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, Image->sizeX, Image->sizeY, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		for (int i=0; i<3*Image->sizeX*Image->sizeY; i++)		// Invert The Bumpmap
			Image->data[i]=255-Image->data[i];

		glGenTextures(3, invbump);								// Create Three Textures

		// Create Nearest Filtered Texture
		glBindTexture(GL_TEXTURE_2D, invbump[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		// Create Linear Filtered Texture
		glBindTexture(GL_TEXTURE_2D, invbump[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create MipMapped Texture
		glBindTexture(GL_TEXTURE_2D, invbump[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, Image->sizeX, Image->sizeY, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		glPixelTransferf(GL_RED_SCALE,1.0f);				// Scale RGB Back To 100% Again		
		glPixelTransferf(GL_GREEN_SCALE,1.0f);			
		glPixelTransferf(GL_BLUE_SCALE,1.0f);
	}
	else status=false;
	if (Image) {											// If Texture Exists
		if (Image->data) delete Image->data;				// If Texture Image Exists
		delete Image;
	}

	// Load The Logo-Bitmaps
	if (Image=LoadTGA("Data/OpenGL_ALPHA.tga")) {							
		alpha=new char[4*Image->sizeX*Image->sizeY];		// Create Memory For RGBA8-Texture
		for (int a=0; a<Image->sizeX*Image->sizeY; a++)
			alpha[4*a+3]=Image->data[a*3];					// Pick Only Red Value As Alpha!
		if (!(Image=LoadTGA("Data/OpenGL.tga"))) status=false;
		for (a=0; a<Image->sizeX*Image->sizeY; a++) {		
			alpha[4*a]=Image->data[a*3];					// R
			alpha[4*a+1]=Image->data[a*3+1];				// G
			alpha[4*a+2]=Image->data[a*3+2];				// B
		}
					
		glGenTextures(1, &glLogo);							// Create One Textures

		// Create Linear Filtered RGBA8-Texture
		glBindTexture(GL_TEXTURE_2D, glLogo);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Image->sizeX, Image->sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, alpha);
		delete alpha;
	}
	else status=false;
	if (Image) {											// If Texture Exists
		if (Image->data) delete Image->data;				// If Texture Image Exists
		delete Image;
		Image=NULL;
	}	
	
	// Load The "Extension Enabled"-Logo
	if (Image=LoadTGA("Data/multi_on_alpha.tga")) {							
		alpha=new char[4*Image->sizeX*Image->sizeY];		// Create Memory For RGBA8-Texture
		for (int a=0; a<Image->sizeX*Image->sizeY; a++)
			alpha[4*a+3]=Image->data[a*3];					// Pick Only Red Value As Alpha!
		if (!(Image=LoadTGA("Data/multi_on.tga"))) status=false;
		for (a=0; a<Image->sizeX*Image->sizeY; a++) {		
			alpha[4*a]=Image->data[a*3];					// R
			alpha[4*a+1]=Image->data[a*3+1];				// G
			alpha[4*a+2]=Image->data[a*3+2];				// B
		}
					
		glGenTextures(1, &multiLogo);						// Create One Textures

		// Create Linear Filtered RGBA8-Texture
		glBindTexture(GL_TEXTURE_2D, multiLogo);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Image->sizeX, Image->sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, alpha);
		delete alpha;
	}
	else status=false;
	if (Image) {											// If Texture Exists
		if (Image->data) delete Image->data;				// If Texture Image Exists
		delete Image;
		Image=NULL;
	}		
	
	return status;											// Return The Status
}

void doCube (void) {
	int i;
	glBegin(GL_QUADS);
		// Front Face
		glNormal3f( 0.0f, 0.0f, +1.0f);
		for (i=0; i<4; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Back Face
		glNormal3f( 0.0f, 0.0f,-1.0f);
		for (i=4; i<8; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Top Face
		glNormal3f( 0.0f, 1.0f, 0.0f);
		for (i=8; i<12; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Bottom Face
		glNormal3f( 0.0f,-1.0f, 0.0f);
		for (i=12; i<16; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Right face
		glNormal3f( 1.0f, 0.0f, 0.0f);
		for (i=16; i<20; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Left Face
		glNormal3f(-1.0f, 0.0f, 0.0f);
		for (i=20; i<24; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
	glEnd();	
}

//------------------------------------------------------------------------
// Calculates the current frame rate
//------------------------------------------------------------------------

void CalculateFrameRate()
{


    static float framesPerSecond    = 0.0f;        // This will store our fps
    static long lastTime            = 0;           // This will hold the time from the last frame
    static char strFrameRate[50]    = {0};         // We will store the string here for the window title
    
    // struct for the time value
    struct timeval currentTime;
	currentTime.tv_sec  = 0;
	currentTime.tv_usec = 0; 

    // gets the microseconds passed since app started
    gettimeofday(&currentTime, NULL);	    

    // Increase the frame counter
    ++framesPerSecond;

    if( currentTime.tv_sec - lastTime >= ONE_SECOND )
    {
        lastTime = currentTime.tv_sec;

        // Copy the frames per second into a string to display in the window
        sprintf(strFrameRate, "Current Frames Per Second: %d", int(framesPerSecond));

        // Reset the frames per second
        framesPerSecond = 0;

    }

    // draw frame rate on screen
    drawFrameRate(strFrameRate, GLUT_BITMAP_HELVETICA_10, 1.0f, 1.0f, 1.0f, 0.05, 0.95 );
	printf("\r%s", strFrameRate );
}

//------------------------------------------------------------------------
// Draws the current frame rate on screen
//------------------------------------------------------------------------

void drawFrameRate(char *str, void *font, GLclampf r, GLclampf g, GLclampf b,
              GLfloat x, GLfloat y) {
  /* font: font to use, e.g., GLUT_BITMAP_HELVETICA_10
     r, g, b: text colour
     x, y: text position in window: range [0,0] (bottom left of window)
           to [1,1] (top right of window). */

  char *ch;
  GLint matrixMode;
  GLboolean lightingOn;

 lightingOn= glIsEnabled(GL_LIGHTING);        /* lighting on? */
 if (lightingOn) glDisable(GL_LIGHTING);

 glGetIntegerv(GL_MATRIX_MODE, &matrixMode);  /* matrix mode? */

 glDisable(GL_TEXTURE_2D);
 glDisable(GL_DEPTH_TEST);;

 glMatrixMode(GL_PROJECTION);
 glPushMatrix();
   glLoadIdentity();
   gluOrtho2D(0.0, 1.0, 0.0, 1.0);
   glMatrixMode(GL_MODELVIEW);
   glPushMatrix();
     glLoadIdentity();
     glPushAttrib(GL_COLOR_BUFFER_BIT);       /* save current colour */
       glColor3f(r, g, b);
       glRasterPos3f(x, y, 0.0);
       for(ch= str; *ch; ch++) {
          glutBitmapCharacter(font, (int)*ch);
       }
     glPopAttrib();
   glPopMatrix();
   glMatrixMode(GL_PROJECTION);
 glPopMatrix();
 glMatrixMode(matrixMode);

 if (lightingOn) glEnable(GL_LIGHTING);

 glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
 glEnable(GL_DEPTH_TEST);
}

//------------------------------------------------------------------------
// Window resize function
//------------------------------------------------------------------------
void glutResize(int width, int height)
{
	if (height==0)											// Prevent A Divide By Zero By
		height=1;											// Making Height Equal One
	
	glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
      /* modify this line to change perspective values */
	gluPerspective(45.0, (float)width/(float)height, 1.0f, 100.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

//------------------------------------------------------------------------
// Function that handles keyboard inputs
//------------------------------------------------------------------------
void glutKeyboard(unsigned char key, int x, int y)
{
	switch (key)
	{
		case ESC:
			exit(0);
		case 'W':
		case 'w':			
		    wireframe = !wireframe;
			break;
		case 'E':
		case 'e':
			emboss=!emboss;
			break;
		case 'M':
		case 'm':
			useMultitexture=((!useMultitexture) && multitextureSupported);
			break;
		case 'B':
		case 'b':
			bumps=!bumps;
			break;
		case 'F':
		case 'f':
			filter++;
			filter%=3;
			break;
	}
}

//------------------------------------------------------------------------
// If rotation angle is greater of 360 or lesser than -360,
// resets it back to zero.
//------------------------------------------------------------------------
void clamp(float *v)
{
    int i;

    for (i = 0; i < 3; i ++)
        if (v[i] > 360 || v[i] < -360)
            v[i] = 0;
}

//------------------------------------------------------------------------
// Moves the screen based on mouse pressed button
//------------------------------------------------------------------------
void glutMotion(int x, int y)
{
    if (mButton == BUTTON_LEFT)
    {
        /* rotates screen */
        rot[0] -= (mOldY - y);
        rot[1] -= (mOldX - x);
        clamp (rot);
    }
	else if (mButton == BUTTON_RIGHT)
    {
        /*
           translate the screen, z axis
           gives the idea of zooming in and out 
        */        
        eye[2] -= (mOldY - y) * 0.05f; // here I multiply by a 0.2 factor to 
                                      // slow down the zoom
        clamp (rot);
    } 
    else if (mButton == BUTTON_LEFT_TRANSLATE)
    {
        eye[0] += (mOldX - x) * 0.01f;
        eye[1] -= (mOldY - y) * 0.01f;
        clamp (rot);
    }

    mOldX = x;
    mOldY = y;
}

//------------------------------------------------------------------------
// Function that handles mouse input
//------------------------------------------------------------------------
void glutMouse(int button, int state, int x, int y)
{
    if(state == GLUT_DOWN)
    {
        mOldX = x;
        mOldY = y;
        switch(button)
        {
            case GLUT_LEFT_BUTTON:
                if (glutGetModifiers() == GLUT_ACTIVE_CTRL)
                {
                   mButton = BUTTON_LEFT_TRANSLATE;
                   break;
                } else
                {
                   mButton = BUTTON_LEFT;
                   break;
                }
            case GLUT_RIGHT_BUTTON:
                mButton = BUTTON_RIGHT;
                break;
        }
    } else if (state == GLUT_UP)
      mButton = -1;
}

//------------------------------------------------------------------------
// The glut's menu callback function. Called every time an option is selected
//------------------------------------------------------------------------
void glutMenu(int value)
{
	switch (value)
	{
		case 1:
			glutFullScreen();
			return;

		case 2:
			exit(0);
	}
}

//------------------------------------------------------------------------
// Function that handles special keyboards input (SHIFT, CTRL, ALT)
//------------------------------------------------------------------------
void glutSpecial(int value, int x, int y)
{
    switch (value)
    {
        case GLUT_KEY_F1:
                glutFullScreen();
                return;
		case GLUT_KEY_UP:
				xspeed-=0.01f;
				break;
		case GLUT_KEY_DOWN:
				xspeed+=0.01f;
				break;
		case GLUT_KEY_LEFT:
				yspeed-=0.01f;
				break;
		case GLUT_KEY_RIGHT:
				yspeed+=0.01f;
				break;
		case GLUT_KEY_PAGE_UP:
				z-=0.02f;
				break;
		case GLUT_KEY_PAGE_DOWN:
				z+=0.02f;
				break;
    }
}

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvv ATTENTION HERE!!! vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//************************************************************************
// The draw function. Replaces code listed here for your own drawing code.
// For demo of the framework i drawed i simple cube that can be freely
// rotated with mouse buttons.
//************************************************************************
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
void glutDisplay(void)
{    

    if (wireframe)
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    else
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);    

	// Here is the lesson stuff
	if (bumps) {
		if (useMultitexture && maxTexelUnits>1)
			doMesh2TexelUnits();	
		else doMesh1TexelUnits();	
	}
	else doMeshNoBumps();
	// lesson stuff ends here

    CalculateFrameRate();

    glFlush();
    glutSwapBuffers();

}

///vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
/// The code here can be freely altered too. It's mainly designed to set
/// OpenGl's initial value and configuration.
///vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
bool InitializeOGL()
{
    multitextureSupported=initMultitexture();
	if (!LoadGLTextures()) return false;				// Jump To Texture Loading Routine
	
	glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations

	initLights();										// Initialize OpenGL Light	
	return true;	
}

// Calculates v=vM, M Is 4x4 In Column-Major, v Is 4dim. Row (i.e. "Transposed")
void VMatMult(GLfloat *M, GLfloat *v) {
	GLfloat res[3];
	res[0]=M[ 0]*v[0]+M[ 1]*v[1]+M[ 2]*v[2]+M[ 3]*v[3];
	res[1]=M[ 4]*v[0]+M[ 5]*v[1]+M[ 6]*v[2]+M[ 7]*v[3];
	res[2]=M[ 8]*v[0]+M[ 9]*v[1]+M[10]*v[2]+M[11]*v[3];;	
	v[0]=res[0];
	v[1]=res[1];
	v[2]=res[2];
	v[3]=M[15];											// Homogenous Coordinate
}

/*	Okay, Here Comes The Important Stuff:
	
	On http://www.nvidia.com/marketing/Developer/DevRel.nsf/TechnicalDemosFrame?OpenPage
	You Can Find A Demo Called GL_BUMP That Is A Little Bit More Complicated.
	GL_BUMP:   Copyright Diego Tártara, 1999.			
		     -  diego_tartara@ciudad.com.ar  -

	The Idea Behind GL_BUMP Is, That You Compute The Texture-Coordinate Offset As Follows:
		0) All Coordinates Either In Object Or In World Space.
		1) Calculate Vertex v From Actual Position (The Vertex You're At) To The Lightposition
		2) Normalize v
		3) Project This v Into Tangent Space.
			Tangent Space Is The Plane "Touching" The Object In Our Current Position On It.
			Typically, If You're Working With Flat Surfaces, This Is The Surface Itself.
		4) Offset s,t-Texture-Coordinates By The Projected v's x And y-Component.

	* This Would Be Called Once Per Vertex In Our Geometry, If Done Correctly.
	* This Might Lead To Incoherencies In Our Texture Coordinates, But Is Ok As Long As You Did Not
	* Wrap The Bumpmap.
		
	Basically, We Do It The Same Way With Some Exceptions:
		ad 0) We'll Work In Object Space All Time. This Has The Advantage That We'll Only
		      Have To Transform The Lightposition From Frame To Frame. This Position Obviously
			  Has To Be Transformed Using The Inversion Of The Modelview Matrix. This Is, However,
			  A Considerable Drawback, If You Don't Know How Your Modelview Matrix Was Built, Since
			  Inverting A Matrix Is Costly And Complicated.
		ad 1) Do It Exactly That Way.
		ad 2) Do It Exactly That Way.
		ad 3) To Project The Lightvector Into Tangent Space, We'll Support The Setup-Routine
			  With Two Directions: One Of Increasing s-Texture-Coordinate Axis, The Other In
			  Increasing t-Texture-Coordinate Axis. The Projection Simply Is (Assumed Both
			  texCoord Vectors And The Lightvector Are Normalized) The Dotproduct Between The
			  Respective texCoord Vector And The Lightvector. 
		ad 4) The Offset Is Computed By Taking The Result Of Step 3 And Multiplying The Two
			  Numbers With MAX_EMBOSS, A Constant That Specifies How Much Quality We're Willing To
			  Trade For Stronger Bump-Effects. Just Temper A Little Bit With MAX_EMBOSS!

	WHY THIS IS COOL:
		* Have A Look!
		* Very Cheap To Implement (About One Squareroot And A Couple Of MULs)!
		* Can Even Be Further Optimized!
		* SetUpBump Doesn't Disturb glBegin()/glEnd()
		* THIS DOES ALWAYS WORK - Not Only With XY-Tangent Spaces!!

	DRAWBACKS:
		* Must Know "Structure" Of Modelview-Matrix Or Invert It. Possible To Do The Whole Thing
		* In World Space, But This Involves One Transformation For Each Vertex!
*/	
	
void SetUpBumps(GLfloat *n, GLfloat *c, GLfloat *l, GLfloat *s, GLfloat *t) {
	GLfloat v[3];							// Vertex From Current Position To Light	
	GLfloat lenQ;							// Used To Normalize		
		
	// Calculate v From Current Vector c To Lightposition And Normalize v	
	v[0]=l[0]-c[0];		
	v[1]=l[1]-c[1];		
	v[2]=l[2]-c[2];		
	lenQ=(GLfloat) sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
	v[0]/=lenQ;		v[1]/=lenQ;		v[2]/=lenQ;
	// Project v Such That We Get Two Values Along Each Texture-Coordinat Axis.
	c[0]=(s[0]*v[0]+s[1]*v[1]+s[2]*v[2])*MAX_EMBOSS;
	c[1]=(t[0]*v[0]+t[1]*v[1]+t[2]*v[2])*MAX_EMBOSS;	
}

void doLogo(void) {			// MUST CALL THIS LAST!!!, Billboards The Two Logos.
	glDepthFunc(GL_ALWAYS);		
	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glDisable(GL_LIGHTING);
	glLoadIdentity();	
	glBindTexture(GL_TEXTURE_2D,glLogo);
	glBegin(GL_QUADS);
		glTexCoord2f(0.0f,0.0f);	glVertex3f(0.23f, -0.4f,-1.0f);
		glTexCoord2f(1.0f,0.0f);	glVertex3f(0.53f, -0.4f,-1.0f);
		glTexCoord2f(1.0f,1.0f);	glVertex3f(0.53f, -0.25f,-1.0f);
		glTexCoord2f(0.0f,1.0f);	glVertex3f(0.23f, -0.25f,-1.0f);
	glEnd();		
	if (useMultitexture) {
		glBindTexture(GL_TEXTURE_2D,multiLogo);
		glBegin(GL_QUADS);
			glTexCoord2f(0.0f,0.0f);	glVertex3f(-0.53f, -0.4f,-1.0f);
			glTexCoord2f(1.0f,0.0f);	glVertex3f(-0.33f, -0.4f,-1.0f);
			glTexCoord2f(1.0f,1.0f);	glVertex3f(-0.33f, -0.3f,-1.0f);
			glTexCoord2f(0.0f,1.0f);	glVertex3f(-0.53f, -0.3f,-1.0f);
		glEnd();		
	}
	glDepthFunc(GL_LEQUAL);
}

bool doMesh1TexelUnits(void) {

	GLfloat c[4]={0.0f,0.0f,0.0f,1.0f};					// Holds Current Vertex
	GLfloat n[4]={0.0f,0.0f,0.0f,1.0f};					// Normalized Normal Of Current Surface		
	GLfloat s[4]={0.0f,0.0f,0.0f,1.0f};					// s-Texture Coordinate Direction, Normalized
	GLfloat t[4]={0.0f,0.0f,0.0f,1.0f};					// t-Texture Coordinate Direction, Normalized
	GLfloat l[4];										// Holds Our Lightposition To Be Transformed Into Object Space
	GLfloat Minv[16];									// Holds The Inverted Modelview Matrix To Do So.
	int i;								

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
		
	// Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With One glLoadIdentity();
	// Simply Build It By Doing All Transformations Negated And In Reverse Order.
	glLoadIdentity();								
	glRotatef(-yrot,0.0f,1.0f,0.0f);
	glRotatef(-xrot,1.0f,0.0f,0.0f);
	glTranslatef(0.0f,0.0f,-z);
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);
	glLoadIdentity();
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);	
	
	// Transform The Lightposition Into Object Coordinates:
	l[0]=LightPosition[0];
	l[1]=LightPosition[1];
	l[2]=LightPosition[2];
	l[3]=1.0f;											// Homogenous Coordinate
	VMatMult(Minv,l);
	
/*	PASS#1: Use Texture "Bump"
			No Blend
			No Lighting
			No Offset Texture-Coordinates */
	glBindTexture(GL_TEXTURE_2D, bump[filter]);
	glDisable(GL_BLEND);
	glDisable(GL_LIGHTING);
	doCube();

/* PASS#2:	Use Texture "Invbump"
			Blend GL_ONE To GL_ONE
			No Lighting
			Offset Texture Coordinates 
			*/
	glBindTexture(GL_TEXTURE_2D,invbump[filter]);
	glBlendFunc(GL_ONE,GL_ONE);
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_BLEND);	

	glBegin(GL_QUADS);	
		// Front Face	
		n[0]=0.0f;		n[1]=0.0f;		n[2]=1.0f;			
		s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=0; i<4; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Back Face	
		n[0]=0.0f;		n[1]=0.0f;		n[2]=-1.0f;	
		s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=4; i<8; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Top Face	
		n[0]=0.0f;		n[1]=1.0f;		n[2]=0.0f;		
		s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
		for (i=8; i<12; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Bottom Face
		n[0]=0.0f;		n[1]=-1.0f;		n[2]=0.0f;		
		s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
		for (i=12; i<16; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Right Face	
		n[0]=1.0f;		n[1]=0.0f;		n[2]=0.0f;		
		s[0]=0.0f;		s[1]=0.0f;		s[2]=-1.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=16; i<20; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Left Face
		n[0]=-1.0f;		n[1]=0.0f;		n[2]=0.0f;		
		s[0]=0.0f;		s[1]=0.0f;		s[2]=1.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=20; i<24; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}		
	glEnd();
	
/* PASS#3:	Use Texture "Base"
			Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
			Lighting Enabled
			No Offset Texture-Coordinates
			*/
	if (!emboss) {
		glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glBindTexture(GL_TEXTURE_2D,texture[filter]);
		glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);	
		glEnable(GL_LIGHTING);
		doCube();
	}

	xrot+=xspeed;
	yrot+=yspeed;
	if (xrot>360.0f) xrot-=360.0f;
	if (xrot<0.0f) xrot+=360.0f;
	if (yrot>360.0f) yrot-=360.0f;
	if (yrot<0.0f) yrot+=360.0f;

/*	LAST PASS:	Do The Logos! */
	doLogo();
	
	return true;										// Keep Going
}

bool doMesh2TexelUnits(void) {
	
	GLfloat c[4]={0.0f,0.0f,0.0f,1.0f};					// holds current vertex
	GLfloat n[4]={0.0f,0.0f,0.0f,1.0f};					// normalized normal of current surface		
	GLfloat s[4]={0.0f,0.0f,0.0f,1.0f};					// s-texture coordinate direction, normalized
	GLfloat t[4]={0.0f,0.0f,0.0f,1.0f};					// t-texture coordinate direction, normalized
	GLfloat l[4];										// holds our lightposition to be transformed into object space
	GLfloat Minv[16];									// holds the inverted modelview matrix to do so.
	int i;								

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
		
	// Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With One glLoadIdentity();
	// Simply Build It By Doing All Transformations Negated And In Reverse Order.
	glLoadIdentity();								
	glRotatef(-yrot,0.0f,1.0f,0.0f);
	glRotatef(-xrot,1.0f,0.0f,0.0f);
	glTranslatef(0.0f,0.0f,-z);
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);
	glLoadIdentity();
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);	

	// Transform The Lightposition Into Object Coordinates:
	l[0]=LightPosition[0];
	l[1]=LightPosition[1];
	l[2]=LightPosition[2];
	l[3]=1.0f;											// Homogenous Coordinate
	VMatMult(Minv,l);
		
/*	PASS#1: Texel-Unit 0:	Use Texture "Bump"
							No Blend
							No Lighting
							No Offset Texture-Coordinates 
							Texture-Operation "Replace"
			Texel-Unit 1:	Use Texture "Invbump"
							No Lighting
							Offset Texture Coordinates 
							Texture-Operation "Replace"
*/
	// TEXTURE-UNIT #0		
	glActiveTextureARB(GL_TEXTURE0_ARB);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, bump[filter]);
	glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT);
	glTexEnvf (GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_REPLACE);	
	// TEXTURE-UNIT #1:
	glActiveTextureARB(GL_TEXTURE1_ARB);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, invbump[filter]);
	glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT);
	glTexEnvf (GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_ADD);
	// General Switches:
	glDisable(GL_BLEND);
	glDisable(GL_LIGHTING);	
	glBegin(GL_QUADS);	
		// Front Face	
		n[0]=0.0f;		n[1]=0.0f;		n[2]=1.0f;			
		s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=0; i<4; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]); 
			glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Back Face	
		n[0]=0.0f;		n[1]=0.0f;		n[2]=-1.0f;	
		s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=4; i<8; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]); 
			glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Top Face	
		n[0]=0.0f;		n[1]=1.0f;		n[2]=0.0f;		
		s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
		for (i=8; i<12; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
			glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Bottom Face
		n[0]=0.0f;		n[1]=-1.0f;		n[2]=0.0f;		
		s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
		t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
		for (i=12; i<16; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
			glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Right Face	
		n[0]=1.0f;		n[1]=0.0f;		n[2]=0.0f;		
		s[0]=0.0f;		s[1]=0.0f;		s[2]=-1.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=16; i<20; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
			glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}
		// Left Face
		n[0]=-1.0f;		n[1]=0.0f;		n[2]=0.0f;		
		s[0]=0.0f;		s[1]=0.0f;		s[2]=1.0f;
		t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
		for (i=20; i<24; i++) {	
			c[0]=data[5*i+2];		
			c[1]=data[5*i+3];
			c[2]=data[5*i+4];
			SetUpBumps(n,c,l,s,t);
			glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
			glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
			glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
		}		
	glEnd();
	
/* PASS#2	Use Texture "Base"
			Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
			Lighting Enabled
			No Offset Texture-Coordinates
			*/	
	glActiveTextureARB(GL_TEXTURE1_ARB);		
	glDisable(GL_TEXTURE_2D);
	glActiveTextureARB(GL_TEXTURE0_ARB);			
	if (!emboss) {						
		glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glBindTexture(GL_TEXTURE_2D,texture[filter]);
		glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
		glEnable(GL_BLEND);
		glEnable(GL_LIGHTING);
		doCube();
	}

	xrot+=xspeed;
	yrot+=yspeed;
	if (xrot>360.0f) xrot-=360.0f;
	if (xrot<0.0f) xrot+=360.0f;
	if (yrot>360.0f) yrot-=360.0f;
	if (yrot<0.0f) yrot+=360.0f;

/* LAST PASS:	Do The Logos! */	
	doLogo();

	return true;										// Keep Going
}
bool doMeshNoBumps(void) {

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The View
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);	
	if (useMultitexture) {
		glActiveTextureARB(GL_TEXTURE1_ARB);		
		glDisable(GL_TEXTURE_2D);
		glActiveTextureARB(GL_TEXTURE0_ARB);
	}
	glDisable(GL_BLEND);
	glBindTexture(GL_TEXTURE_2D,texture[filter]);	
	glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
	glEnable(GL_LIGHTING);
	doCube();
	
	xrot+=xspeed;
	yrot+=yspeed;
	if (xrot>360.0f) xrot-=360.0f;
	if (xrot<0.0f) xrot+=360.0f;
	if (yrot>360.0f) yrot-=360.0f;
	if (yrot<0.0f) yrot+=360.0f;

/* LAST PASS:	Do The Logos! */	
	doLogo();

	return true;										// Keep Going
}

//------------------------------------------------------------------------
//   It's the main application function. Note the clean code you can
//   obtain using he GLUT library. No calls to dark windows API
//   functions with many obscure parameters list. =)
//------------------------------------------------------------------------
int main(int argc, char** argv)
{
    /*
        Glut's initialization code. Set window's size and type of display.
        Window size is put half the 800x600 resolution as defined by above
	constants. The windows is positioned at the top leftmost area of
	the screen.
    */
    glutInitDisplayMode( GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGBA | GLUT_MULTISAMPLE );
    glutInitWindowPosition( GL_WIN_INITIAL_X, GL_WIN_INITIAL_Y );
    glutInitWindowSize( GL_WIN_WIDTH, GL_WIN_HEIGHT );
    glutInit( &argc, argv );

    glutCreateWindow("NeHe's GL_ARB_multitexture & Bump Mapping Tutorial");

    /*
       The function below are called when the respective event
       is triggered. Very simple, isn't it?
    */
    glutReshapeFunc(glutResize);       // called every time  the screen is resized
    glutDisplayFunc(glutDisplay);      // called when window needs to be redisplayed
    glutIdleFunc(glutDisplay);         // called whenever the application is idle
    glutKeyboardFunc(glutKeyboard);    // called when the application receives a input from the keyboard
    glutMouseFunc(glutMouse);          // called when the application receives a input from the mouse
    glutMotionFunc(glutMotion);        // called when the mouse moves over the screen with one of this button pressed
    glutSpecialFunc(glutSpecial);      // called when a special key is pressed like SHIFT

    /*
        Do any lighting, material, alpha, etc initialization or
        configuration here.
    */
    if (!InitializeOGL())
	{
		printf("%s", "\nCould not initialize OpenGL.\n");
		return 1;
	}

    /*
        Creates a menu attached to the mouses middle button
        the menu here consists in two options, one to toggle
        fullscreen mode and another for exiting the application.
    */
	glutCreateMenu(glutMenu);
	glutAddMenuEntry("Full Screen", 1);
	glutAddMenuEntry("Exit", 2);
	glutAttachMenu(GLUT_MIDDLE_BUTTON);

    /*
       Application's main loop. All the above functions
	 are called whe the respective events are triggered
    */
	glutMainLoop();

	return 0;
}

//---------------------------------------------------------------------------
//    Special Notes: Look the above program and realize how simple it was
//    to write a full working OpenGL application! Most of the
//    ready-to-work codes in internet are big ones with many Windows API
//    calls and so on. Another advantage of this code is that with the right
//    implementation it can be REALLY ported to others OS with ease.
//    Should compile and work with Mesa implementation without problems!
//    I tested it a lot in SuSE Linux 8.2 and of course Windows XP.
//---------------------------------------------------------------------------

