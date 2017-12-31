//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <stdio.h>      // Header file for standard Input/Output ( NEW )
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#include <gl\glaux.h>   // Header file for the GLaux library
#include "glext.h"	// Header File For Multitexturing
#include <string.h>	// Header file for the string library
#include <math.h>	// Header file for the math library

#define MAX_EMBOSS (GLfloat)0.01f       // Maximum emboss-translate. Increase to get higher immersion

/*	Here comes the ARB-Multitexture support.
 *	There are (Optimally) 6 new commands to the OpenGL set:
 *	glMultiTexCoordifARB i = 1..4	: Sets texture-coordinates for texel-pipeline #i
 *	glActiveTextureARB		: Sets active texel-pipeline
 *	glClientActiveTextureARB	: Sets active texel-pipeline for the pointer-array-commands
 *
 *	There are even more for the various formats of glMultiTexCoordi{f,fv,d,i}, but we don't need them.
 */

#define __ARB_ENABLE true               // Used to disable ARB xtensions entirely
//#define EXT_INFO                      // Do you want to see your extensions at start-up?
#define MAX_EXTENSION_SPACE 10240	// Characters for extension-strings
#define MAX_EXTENSION_LENGTH 256	// Maximum of characters in one extension-string
bool multitextureSupported = false;	// Flag indicating whether multitexturing is supported
bool useMultitexture = true;		// Use it if it is supported?
GLint maxTexelUnits = 1;		// Number of texel-pipelines. This is st least 1.

PFNGLMULTITEXCOORD1FARBPROC glMultiTexCoord1fARB = NULL;
PFNGLMULTITEXCOORD2FARBPROC glMultiTexCoord2fARB = NULL;
PFNGLMULTITEXCOORD3FARBPROC glMultiTexCoord3fARB = NULL;
PFNGLMULTITEXCOORD4FARBPROC glMultiTexCoord4fARB = NULL;
PFNGLACTIVETEXTUREARBPROC glActiveTextureARB = NULL;
PFNGLCLIENTACTIVETEXTUREARBPROC	glClientActiveTextureARB = NULL;

#pragma hdrstop

//---------------------------------------------------------------------------
#pragma argsused

HGLRC hRC = NULL;               // Permanent rendering context
HDC hDC = NULL;                 // Private GDI device context
HWND hWnd = NULL;               // Holds our window handle
HINSTANCE hInstance = NULL;     // Holds the instance of the application

bool keys[256];                 // Array used for the keyboard routine
bool active = true;             // Window active flag set to TRUE by default
bool fullscreen = true;         // Fullscreen flag set to fullscreen mode by default

bool emboss = false;		// Emboss only, no basetexture?
bool bumps = true;              // Do bumpmapping?

GLfloat xrot;	                // X rotation
GLfloat yrot;		        // Y rotation
GLfloat xspeed;			// X rotation speed
GLfloat yspeed;			// Y rotation speed
GLfloat	z=-5.0f;                // Depth into the screen

GLuint filter = 1;		// Which filter to use
GLuint texture[3];		// Storage for 3 textures
GLuint bump[3];		        // Our bumpmappings
GLuint invbump[3];		// Inverted bumpmaps
GLuint glLogo;			// Handle for OpenGL-logo
GLuint multiLogo;		// Handle for multitexture-enabled-logo
GLfloat LightAmbient[] = { 0.2f, 0.2f, 0.2f};           // Ambient light is 20% white
GLfloat LightDiffuse[] = { 1.0f, 1.0f, 1.0f};		// Diffuse light is white
GLfloat LightPosition[]	= { 0.0f, 0.0f, 2.0f};	    	// Position is somewhat in front of screen
GLfloat Gray[] = { 0.5f, 0.5f, 0.5f, 1.0f};

// Data contains the faces for the cube in format 2xTexCoord, 3xVertex;
// Note that the tesselation of the cube is only absolute minimum.
GLfloat data[] = {
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

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

// Always check for extension-availability during run-time!
// Here we go!
bool isInString(char *string, const char *search)
{
	int pos=0;
	int maxpos=strlen(search)-1;
	int len=strlen(string);
	char *other;
	for (int i=0; i<len; i++) {
		if ((i==0) || ((i>1) && string[i-1]=='\n'))                             // New extension begins here!
                {
			other=&string[i];
			pos=0;				        			// Begin new search
			while (string[i]!='\n')                                         // Search whole extension-string
                        {
				if (string[i]==search[pos]) pos++;      		// Next position
				if ((pos>maxpos) && string[i+1]=='\n') return true;	// We have a winner!
				i++;
			}
		}
	}
	return false;								        // Sorry, not found!
}
// isMultitextureSupported() Checks at run-time if multitexturing is supported
bool initMultitexture(void)
{
	char *extensions;	
	extensions=strdup((char *) glGetString(GL_EXTENSIONS));		// Fetch extension string
	int len=strlen(extensions);
	for (int i=0; i<len; i++)					// Separate it by newline instead of blank
		if (extensions[i]==' ') extensions[i]='\n';

#ifdef EXT_INFO
	MessageBox(hWnd,extensions,"supported GL extensions",MB_OK | MB_ICONINFORMATION);
#endif

	if (isInString(extensions,"GL_ARB_multitexture")		// Is multitexturing supported?
		&& __ARB_ENABLE						// Override-flag
		&& isInString(extensions,"GL_EXT_texture_env_combine"))	// Is texture_env_combining Supported?
	{	
		glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB,&maxTexelUnits);
		glMultiTexCoord1fARB	= (PFNGLMULTITEXCOORD1FARBPROC)		wglGetProcAddress("glMultiTexCoord1fARB");
		glMultiTexCoord2fARB	= (PFNGLMULTITEXCOORD2FARBPROC)		wglGetProcAddress("glMultiTexCoord2fARB");
		glMultiTexCoord3fARB	= (PFNGLMULTITEXCOORD3FARBPROC)		wglGetProcAddress("glMultiTexCoord3fARB");
		glMultiTexCoord4fARB	= (PFNGLMULTITEXCOORD4FARBPROC)		wglGetProcAddress("glMultiTexCoord4fARB");
		glActiveTextureARB		= (PFNGLACTIVETEXTUREARBPROC)		wglGetProcAddress("glActiveTextureARB");
		glClientActiveTextureARB= (PFNGLCLIENTACTIVETEXTUREARBPROC)	wglGetProcAddress("glClientActiveTextureARB");		
#ifdef EXT_INFO
	MessageBox(hWnd,"The GL_ARB_multitexture extension will be used.","feature supported!",MB_OK | MB_ICONINFORMATION);
#endif
		return true;
	}
	useMultitexture = false;					// We can't use it if it isn't supported!
	return false;
}

void initLights(void)
{
	glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient);		// Load light-parameters into GL_LIGHT1
	glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse);	
	glLightfv( GL_LIGHT1, GL_POSITION, LightPosition);

	glEnable(GL_LIGHT1);	
}

// Using auxDIBImageLoad's own error-handler!
int LoadGLTextures()
{								// Load bitmaps and convert to textures
	bool status=true;					// Status indicator
	AUX_RGBImageRec *Image=NULL;				// Create storage space for the texture
	char *alpha=NULL;

	// Load the tile-bitmap for base-texture
	if (Image=auxDIBImageLoad("Data/Base.bmp"))
        {
		glGenTextures(3, texture);			// Create three textures

		// Create nearest filtered texture
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		//                             ========
		// Use GL_RGB8 Instead of "3" in glTexImage2D. Also defined by GL: GL_RGBA8 etc.
		// NEW: Now creating GL_RGBA8 textures, Alpha is 1.0f Where not specified by format.

		// Create linear filtered texture
		glBindTexture(GL_TEXTURE_2D, texture[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create mipmapped texture
		glBindTexture(GL_TEXTURE_2D, texture[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, Image->sizeX, Image->sizeY, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
	}
	else status=false;
	if (Image) {					// If texture exists
		if (Image->data) delete Image->data;	// If texture image exists
		delete Image;
		Image=NULL;
	}	
	
	// Load The bumpmaps
	if (Image=auxDIBImageLoad("Data/Bump.bmp")) {			
		glPixelTransferf(GL_RED_SCALE,0.5f);	// Scale RGB By 50%, So that we have only
		glPixelTransferf(GL_GREEN_SCALE,0.5f);	// Half intenstity
		glPixelTransferf(GL_BLUE_SCALE,0.5f);

		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);	// No wrapping, please!
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
		glTexParameterfv(GL_TEXTURE_2D,GL_TEXTURE_BORDER_COLOR,Gray);

		glGenTextures(3, bump);			// Create three textures

		// Create nearest filtered texture
		glBindTexture(GL_TEXTURE_2D, bump[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		// Create linear filtered texture
		glBindTexture(GL_TEXTURE_2D, bump[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create mipMapped texture
		glBindTexture(GL_TEXTURE_2D, bump[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, Image->sizeX, Image->sizeY, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		for (int i=0; i<3*Image->sizeX*Image->sizeY; i++)	// Invert the bumpmap
			Image->data[i]=255-Image->data[i];

		glGenTextures(3, invbump);		// Create three textures

		// Create nearest filtered texture
		glBindTexture(GL_TEXTURE_2D, invbump[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create linear filtered texture
		glBindTexture(GL_TEXTURE_2D, invbump[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, Image->sizeX, Image->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, Image->data);

		// Create mipmapped texture
		glBindTexture(GL_TEXTURE_2D, invbump[2]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
		gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, Image->sizeX, Image->sizeY, GL_RGB, GL_UNSIGNED_BYTE, Image->data);
		
		glPixelTransferf(GL_RED_SCALE,1.0f);	// Scale RGB back to 100% again
		glPixelTransferf(GL_GREEN_SCALE,1.0f);			
		glPixelTransferf(GL_BLUE_SCALE,1.0f);
	}
	else status=false;
	if (Image) {					// If texture exists
		if (Image->data) delete Image->data;	// If texture image exists
		delete Image;
	}

	// Load The Logo-bitmaps
	if (Image=auxDIBImageLoad("Data/OpenGL_ALPHA.bmp")) {							
		alpha=new char[4*Image->sizeX*Image->sizeY];		// Create memory for RGBA8-texture
		for (int a=0; a<Image->sizeX*Image->sizeY; a++)
			alpha[4*a+3]=Image->data[a*3];			// Pick only red value as alpha!
		if (!(Image=auxDIBImageLoad("Data/OpenGL.bmp"))) status=false;
		for (int a=0; a<Image->sizeX*Image->sizeY; a++)
                {
			alpha[4*a]=Image->data[a*3];			// R
			alpha[4*a+1]=Image->data[a*3+1];		// G
			alpha[4*a+2]=Image->data[a*3+2];		// B
		}

		glGenTextures(1, &glLogo);				// Create one textures

		// Create Linear Filtered RGBA8-Texture
		glBindTexture(GL_TEXTURE_2D, glLogo);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Image->sizeX, Image->sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, alpha);
		delete alpha;
	}
	else status=false;
	if (Image) {							// If texture exists
		if (Image->data) delete Image->data;			// If texture image exists
		delete Image;
		Image=NULL;
	}	
	
	// Load The "Extension Enabled"-Logo
	if (Image=auxDIBImageLoad("Data/multi_on_alpha.bmp")) {							
		alpha=new char[4*Image->sizeX*Image->sizeY];		// Create memory for RGBA8-texture
		for (int a=0; a<Image->sizeX*Image->sizeY; a++)
			alpha[4*a+3]=Image->data[a*3];			// Pick only red value as alpha!
		if (!(Image=auxDIBImageLoad("Data/multi_on.bmp"))) status=false;
		for (int a=0; a<Image->sizeX*Image->sizeY; a++) {
			alpha[4*a]=Image->data[a*3];			// R
			alpha[4*a+1]=Image->data[a*3+1];		// G
			alpha[4*a+2]=Image->data[a*3+2];		// B
		}
					
		glGenTextures(1, &multiLogo);				// Create one textures

		// Create Linear Filtered RGBA8-Texture
		glBindTexture(GL_TEXTURE_2D, multiLogo);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Image->sizeX, Image->sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, alpha);
		delete alpha;
	}
	else status=false;
	if (Image) {					// If texture exists
		if (Image->data) delete Image->data;	// If texture image exists
		delete Image;
		Image=NULL;
	}

	return status;					// Return the status
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)     // Resize and initialize the GL window
{
        if (height == 0)                        // Prevent a divide by zero by
        {
                height = 1;                     // Making height equal One
        }

        glViewport(0, 0, width, height);        // Reset the current viewport

        glMatrixMode(GL_PROJECTION);            // Select the projection matrix
	glLoadIdentity();                       // Reset the projection matrix

	// Calculate the aspect ratio of the window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);             // Select the modelview matrix
	glLoadIdentity();                       // Reset the modelview matrix
}

void doCube (void)
{
	int i;
	glBegin(GL_QUADS);
		// Front face
		glNormal3f( 0.0f, 0.0f, +1.0f);
		for (i=0; i<4; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Back face
		glNormal3f( 0.0f, 0.0f,-1.0f);
		for (i=4; i<8; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Top face
		glNormal3f( 0.0f, 1.0f, 0.0f);
		for (i=8; i<12; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
		// Bottom face
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
		// Left face
		glNormal3f(-1.0f, 0.0f, 0.0f);
		for (i=20; i<24; i++) {
			glTexCoord2f(data[5*i],data[5*i+1]);
			glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
		}
	glEnd();
}

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
        multitextureSupported=initMultitexture();
	if (!LoadGLTextures()) return false;		// Jump to texture loadig routine
	glEnable(GL_TEXTURE_2D);			// Enable texture mapping
	glShadeModel(GL_SMOOTH);			// Enable smooth shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);		// Black background
	glClearDepth(1.0f);				// Depth buffer setup
	glEnable(GL_DEPTH_TEST);		        // Enables depth testing
	glDepthFunc(GL_LEQUAL);			        // The type of depth testing to do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);// Really nice perspective calculations

	initLights();			        	// Initialize OpenGL light
	return true;                                    // Initialization went OK
}

// Calculates v=vM, M Is 4x4 in column-major, v Is 4dim. Row (i.e. "Transposed")
void VMatMult(GLfloat *M, GLfloat *v)
{
	GLfloat res[3];
	res[0] = M[ 0]*v[0]+M[ 1]*v[1]+M[ 2]*v[2]+M[ 3]*v[3];
	res[1] = M[ 4]*v[0]+M[ 5]*v[1]+M[ 6]*v[2]+M[ 7]*v[3];
	res[2] = M[ 8]*v[0]+M[ 9]*v[1]+M[10]*v[2]+M[11]*v[3];
	v[0] = res[0];
	v[1] = res[1];
	v[2] = res[2];
	v[3] = M[15];           // Homogenous coordinate
}

/*	Okay, Here comes the important stuff:
	
	On http://www.nvidia.com/marketing/Developer/DevRel.nsf/TechnicalDemosFrame?OpenPage
	You can find a demo called GL_BUMP that is a little bit more complicated.
	GL_BUMP:   Copyright Diego Tártara, 1999.
		     -  diego_tartara@ciudad.com.ar  -

	The idea behind GL_BUMP is, that you compute the texture-coordinate offset as follows:
		0) All coordinates either in object or in world space.
		1) Calculate vertex v from actual position (The vertex you're at) to the lightposition
		2) Normalize v
		3) Project this v into tangent space.
			Tangent space is the plane "Touching" the object in our current position on it.
			typically, if you're working with flat surfaces, this is the surface itself.
		4) Offset s,t-texture-coordinates by the projected v's x and y-component.

	* This would be called once per vertex in our geometry, if done correctly.
	* This might lead to incoherencies in our texture coordinates, but is ok as long as you did not
	* wrap the bumpmap.
		
	Basically, we do it the same way with some exceptions:
		ad 0) We'll work in object space all time. This has the advantage that we'll only
		      have to transform the lightposition from frame to frame. This position obviously
			  has to be transformed using the inversion of the modelview matrix. This is, however,
			  a considerable drawback, if you don't know how your modelview matrix was built, since
			  inverting a matrix is costly and complicated.
		ad 1) Do it exactly that way.
		ad 2) Do it exactly That way.
		ad 3) To project the lightvector into tangent space, we'll support the setup-routine
			  with two directions: One of increasing s-texture-coordinate axis, the other in
			  increasing t-texture-coordinate axis. The projection simply is (Assumed both
			  texcoord vectors and the lightvector are normalized) the dotproduct between the
			  respective texcoord vector and the lightvector. 
		ad 4) The offset is computed by taking the result of step 3 and multiplying the two
			  numbers with MAX_EMBOSS, a constant that specifies how much quality we're willing to
			  trade for stronger bump-effects. Just temper a little bit with MAX_EMBOSS!

	WHY THIS IS COOL:
		* Have a look!
		* Very cheap to implement (About one squareroot and a couple of MULs)!
		* Can even be further optimized!
		* SetUpBump doesn't disturb glBegin()/glEnd()
		* THIS DOES ALWAYS WORK - Not only with XY-tangent spaces!!

	DRAWBACKS:
		* Must mnow "Structure" of modelview-matrix or invert it. Possible to do the whole thing
		* in world space, but this involves one transformation for each vertex!
*/	
	
void SetUpBumps(GLfloat *n, GLfloat *c, GLfloat *l, GLfloat *s, GLfloat *t)
{
	GLfloat v[3];   // Vertex from current position to light
	GLfloat lenQ;	// Used to normalize

	// Calculate v from current vector c to lightposition and normalize v
	v[0]=l[0]-c[0];		
	v[1]=l[1]-c[1];		
	v[2]=l[2]-c[2];		
	lenQ=(GLfloat) sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
	v[0]/=lenQ;		v[1]/=lenQ;		v[2]/=lenQ;
	// Project v such that we get two values along each texture-coordinat axis.
	c[0]=(s[0]*v[0]+s[1]*v[1]+s[2]*v[2])*MAX_EMBOSS;
	c[1]=(t[0]*v[0]+t[1]*v[1]+t[2]*v[2])*MAX_EMBOSS;	
}

void doLogo(void)       // MUST CALL THIS LAST!!!, Billboards the two logos.
{
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
	if (useMultitexture)
        {
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

	GLfloat c[4]={0.0f,0.0f,0.0f,1.0f};                     // Holds current vertex
	GLfloat n[4]={0.0f,0.0f,0.0f,1.0f};	        	// Normalized normal of current surface
	GLfloat s[4]={0.0f,0.0f,0.0f,1.0f};     		// s-Texture coordinate direction, normalized
	GLfloat t[4]={0.0f,0.0f,0.0f,1.0f};	        	// t-Texture coordinate direction, normalized
	GLfloat l[4];				        	// Holds our lightposition to be transformed into object space
	GLfloat Minv[16];		        		// Holds the inverted modelview matrix to do so.
	int i;

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear the screen and the depth buffer
		
	// Build inverse modelview matrix first. This substitutes one Push/Pop with one glLoadIdentity();
	// Simply build it by doing all transformations negated and in reverse order.
	glLoadIdentity();								
	glRotatef(-yrot,0.0f,1.0f,0.0f);
	glRotatef(-xrot,1.0f,0.0f,0.0f);
	glTranslatef(0.0f,0.0f,-z);
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);
	glLoadIdentity();
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);	
	
	// Transform the lightposition into object coordinates:
	l[0]=LightPosition[0];
	l[1]=LightPosition[1];
	l[2]=LightPosition[2];
	l[3]=1.0f;                      // Homogenous coordinate
	VMatMult(Minv,l);
	
/*	PASS#1: Use texture "Bump"
			No blend
			No lighting
			No offset texturecoordinates */
	glBindTexture(GL_TEXTURE_2D, bump[filter]);
	glDisable(GL_BLEND);
	glDisable(GL_LIGHTING);
	doCube();

/* PASS#2:	Use texture "Invbump"
			Blend GL_ONE To GL_ONE
			No lighting
			Offset texture coordinates
			*/
	glBindTexture(GL_TEXTURE_2D,invbump[filter]);
	glBlendFunc(GL_ONE,GL_ONE);
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_BLEND);	

	glBegin(GL_QUADS);	
		// Front face
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
		// Back face
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
		// Top face
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
		// Bottom face
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
		// Right face
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
		// Left face
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
	
/* PASS#3:	Use texture "Base"
			Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
			Lighting enabled
			No offset texture-coordinates
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

/*	LAST PASS:	Do the logos! */
	doLogo();

	return true;            // Keep going
}

bool doMesh2TexelUnits(void) {
	
	GLfloat c[4]={0.0f,0.0f,0.0f,1.0f};			// Holds current vertex
	GLfloat n[4]={0.0f,0.0f,0.0f,1.0f};			// Normalized normal of current surface
	GLfloat s[4]={0.0f,0.0f,0.0f,1.0f};			// S-texture coordinate direction, normalized
	GLfloat t[4]={0.0f,0.0f,0.0f,1.0f};			// T-texture coordinate direction, normalized
	GLfloat l[4];						// Holds our lightposition to be transformed into object space
	GLfloat Minv[16];					// Holds the inverted modelview matrix to do so.
	int i;

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
		
	// Build inverse modelview matrix first. This substitutes one push/pop with one glLoadIdentity();
	// Simply build it by doing all transformations negated and in reverse order.
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
		
/*	PASS#1: Texel-unit 0:	Use texture "Bump"
							No blend
							No lighting
							No offset texture-coordinates
							Texture-operation "Replace"
			Texel-unit 1:	Use texture "Invbump"
							No lighting
							Offset texture coordinates
							Texture-operation "Replace"
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
	// General switches:
	glDisable(GL_BLEND);
	glDisable(GL_LIGHTING);	
	glBegin(GL_QUADS);	
		// Frontface
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
		// Back face
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
		// Top face
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
		// Bottom face
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
		// Right face
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
		// Left face
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
	
/* PASS#2	Use texture "Base"
			Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies by 2)
			Lighting enabled
			No offset texture-coordinates
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

/* LAST PASS:	Do the logos! */
	doLogo();

	return true;            // Keep going
}

bool doMeshNoBumps(void) {

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear the screen and the depth buffer
	glLoadIdentity();					// Reset the view
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

/* LAST PASS:	Do the logos! */
	doLogo();

	return true;            // Keep going
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	if (bumps)
        {
		if (useMultitexture && maxTexelUnits>1)
			return doMesh2TexelUnits();
		else return doMesh1TexelUnits();

	}
	else return doMeshNoBumps();


	return true;            // Keep going
}

GLvoid KillGLWindow(GLvoid)     // Properly kill the window
{
	if (fullscreen)         // Are we in fullscreen mode?
	{
		ChangeDisplaySettings(NULL,0);  // If so switch back to the desktop
		ShowCursor(true);               // Show mouse pointer
	}

	if (hRC)        // Do we have a rendering context?
	{
		if (!wglMakeCurrent(NULL,NULL))         // Are we able to release the DC and RC contexts?
		{
			MessageBox(NULL,"Release of DC and RC failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))             // Are we able to delete the RC?
		{
			MessageBox(NULL,"Release rendering context failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC = NULL;             // Set RC to NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))        // Are we able to release the DC
	{
		MessageBox(NULL,"Release device context failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC = NULL;             // Set DC to NULL
	}

	if (hWnd && !DestroyWindow(hWnd))       // Are we able to destroy the window?
	{
		MessageBox(NULL,"Could not release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd = NULL;            // Set hWnd to NULL
	}

	if (!UnregisterClass("OpenGL",hInstance))       // Are we able to unregister class
	{
		MessageBox(NULL,"Could not unregister class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance = NULL;       // Set hInstance to NULL
	}
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:
 *	title			- Title To Appear At The Top Of The Window
 *	width			- Width Of The GL Window Or Fullscreen Mode
 *	height			- Height Of The GL Window Or Fullscreen Mode
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	GLuint		PixelFormat;		// Holds the results after searching for a match
	WNDCLASS	wc;		        // Windows class structure
	DWORD		dwExStyle;              // Window extended style
	DWORD		dwStyle;                // Window style
	RECT		WindowRect;             // Grabs rctangle upper left / lower right values
	WindowRect.left = (long)0;              // Set left value to 0
	WindowRect.right = (long)width;		// Set right value to requested width
	WindowRect.top = (long)0;               // Set top value to 0
	WindowRect.bottom = (long)height;       // Set bottom value to requested height

	fullscreen = fullscreenflag;              // Set the global fullscreen flag

	hInstance               = GetModuleHandle(NULL);		// Grab an instance for our window
	wc.style                = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;   // Redraw on size, and own DC for window
	wc.lpfnWndProc          = (WNDPROC) WndProc;			// WndProc handles messages
	wc.cbClsExtra           = 0;					// No extra window data
	wc.cbWndExtra           = 0;					// No extra window data
	wc.hInstance            = hInstance;				// Set the Instance
	wc.hIcon                = LoadIcon(NULL, IDI_WINLOGO);		// Load the default icon
	wc.hCursor              = LoadCursor(NULL, IDC_ARROW);		// Load the arrow pointer
	wc.hbrBackground        = NULL;					// No background required for GL
	wc.lpszMenuName		= NULL;					// We don't want a menu
	wc.lpszClassName	= "OpenGL";				// Set the class name

	if (!RegisterClass(&wc))					// Attempt to register the window class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);

		return false;   // Return FALSE
	}
	
	if (fullscreen)         // Attempt fullscreen mode?
	{
		DEVMODE dmScreenSettings;                                       // Device mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	        // Makes sure memory's cleared
		dmScreenSettings.dmSize         = sizeof(dmScreenSettings);     // Size of the devmode structure
		dmScreenSettings.dmPelsWidth	= width;                        // Selected screen width
		dmScreenSettings.dmPelsHeight	= height;                       // Selected screen height
		dmScreenSettings.dmBitsPerPel	= bits;	                        // Selected bits per pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try to set selected mode and get results. NOTE: CDS_FULLSCREEN gets rid of start bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If the mode fails, offer two options. Quit or use windowed mode.
			if (MessageBox(NULL,"The requested fullscreen mode is not supported by\nyour video card. Use windowed mode instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen = false;       // Windowed mode selected. Fullscreen = FALSE
			}
			else
			{
				// Pop up a message box letting user know the program is closing.
				MessageBox(NULL,"Program will now close.","ERROR",MB_OK|MB_ICONSTOP);
				return false;           // Return FALSE
			}
		}
	}

	if (fullscreen)                         // Are We Still In Fullscreen Mode?
	{
		dwExStyle = WS_EX_APPWINDOW;    // Window extended style
		dwStyle = WS_POPUP;		// Windows style
		ShowCursor(false);		// Hide mouse pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;           // Window extended style
		dwStyle=WS_OVERLAPPEDWINDOW;                            // Windows style
	}

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);     // Adjust window to true requested size

	// Create the window
	if (!(hWnd = CreateWindowEx(dwExStyle,          // Extended Style For The Window
                "OpenGL",				// Class name
		title,					// Window title
		dwStyle |				// Defined window style
		WS_CLIPSIBLINGS |			// Required window style
		WS_CLIPCHILDREN,			// Required window style
		0, 0,					// Window position
		WindowRect.right-WindowRect.left,	// Calculate window width
		WindowRect.bottom-WindowRect.top,	// Calculate window height
		NULL,					// No parent window
		NULL,					// No menu
		hInstance,				// Instance
		NULL)))					// Dont pass anything to WM_CREATE
	{
		KillGLWindow();                         // Reset the display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;                           // Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd =             // pfd tells windows how we want things to be
	{
		sizeof(PIXELFORMATDESCRIPTOR),          // Size of this pixel format descriptor
		1,					// Version number
		PFD_DRAW_TO_WINDOW |			// Format must support window
		PFD_SUPPORT_OPENGL |			// Format must support OpenGL
		PFD_DOUBLEBUFFER,			// Must support double buffering
		PFD_TYPE_RGBA,				// Request an RGBA format
		bits,					// Select our color depth
		0, 0, 0, 0, 0, 0,			// Color bits ignored
		0,					// No alpha buffer
		0,					// Shift bit ignored
		0,					// No accumulation buffer
		0, 0, 0, 0,				// Accumulation bits ignored
		16,					// 16Bit Z-Buffer (Depth buffer)
		0,					// No stencil buffer
		0,					// No auxiliary buffer
		PFD_MAIN_PLANE,				// Main drawing layer
		0,					// Reserved
		0, 0, 0					// Layer masks ignored
	};
	
	if (!(hDC=GetDC(hWnd)))         // Did we get a device context?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't create a GL device context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))	// Did windows find a matching pixel format?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't find a suitable pixelformat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))       // Are we able to set the pixel format?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't set the pixelformat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))               // Are we able to get a rendering context?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't create a GL rendering context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))    // Try to activate the rendering context
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't activate the GL rendering context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);       // Show the window
	SetForegroundWindow(hWnd);      // Slightly higher priority
	SetFocus(hWnd);                 // Sets keyboard focus to the window
	ReSizeGLScene(width, height);   // Set up our perspective GL screen

	if (!InitGL())                  // Initialize our newly created GL window
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Initialization failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	return true;                    // Success
}

LRESULT CALLBACK WndProc(HWND hWnd,     // Handle for this window
                        UINT uMsg,      // Message for this window
			WPARAM wParam,  // Additional message information
			LPARAM lParam)  // Additional message information
{
	switch (uMsg)                           // Check for windows messages
	{
		case WM_ACTIVATE:               // Watch for window activate message
		{
			if (!HIWORD(wParam))    // Check minimization state
			{
				active = true;  // Program is active
			}
			else
			{
				active = false; // Program is no longer active
			}

			return 0;               // Return to the message loop
		}

		case WM_SYSCOMMAND:             // Intercept system commands
		{
			switch (wParam)         // Check system calls
			{
				case SC_SCREENSAVE:     // Screensaver trying to start?
				case SC_MONITORPOWER:	// Monitor trying to enter powersave?
				return 0;       // Prevent from happening
			}
			break;                  // Exit
		}

		case WM_CLOSE:                  // Did we receive a close message?
		{
			PostQuitMessage(0);     // Send a quit message
			return 0;               // Jump back
		}

		case WM_KEYDOWN:                // Is a key being held down?
		{
			keys[wParam] = true;    // If so, mark it as TRUE
			return 0;               // Jump back
		}

		case WM_KEYUP:                  // Has a key been released?
		{
			keys[wParam] = false;   // If so, mark it as FALSE
			return 0;               // Jump back
		}

		case WM_SIZE:                   // Resize the OpenGL window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord = Width, HiWord = Height
			return 0;               // Jump back
		}
	}

	// Pass all unhandled messages to DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
        MSG msg;                // Windows message structure
	bool done = false;      // Bool variable to exit loop

	// Ask the user which screen mode they prefer
	if (MessageBox(NULL,"Would you like to run in fullscreen mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen = false;       // Windowed mode
	}

	// Create our OpenGL window
	if (!CreateGLWindow("NeHe's GL_ARB_multitexture & Bump Mapping Tutorial",640,480,16,fullscreen))
	{
		return 0;               // Quit if window was not created
	}

	while(!done)            // Loop that runs while done = FALSE
	{
		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))	// Is there a message waiting?
		{
			if (msg.message == WM_QUIT)             // Have we received a quit message?
			{
				done = true;                    // If so done = TRUE
			}
			else                                    // If not, deal with window messages
			{
				TranslateMessage(&msg);         // Translate the message
				DispatchMessage(&msg);          // Dispatch the message
			}
		}
		else            // If there are no messages
		{
			// Draw the scene.  Watch for ESC key and quit messages from DrawGLScene()
			if (active)                             // Program active?
			{
				if (keys[VK_ESCAPE])            // Was ESC pressed?
				{
					done = true;            // ESC signalled a quit
				}
				else                            // Not time to quit, Update screen
				{
					DrawGLScene();          // Draw the scene
					SwapBuffers(hDC);       // Swap buffers (Double buffering)
				}
			}

                        if (keys['E'])
			{
				keys['E']=false;
				emboss=!emboss;
			}

			if (keys['M'])
			{
				keys['M']=false;
				useMultitexture=((!useMultitexture) && multitextureSupported);
			}

			if (keys['B'])
			{
				keys['B']=false;
				bumps=!bumps;
			}

			if (keys['F'])
			{
				keys['F']=false;
				filter++;
				filter%=3;
			}

			if (keys[VK_PRIOR])
			{
				z-=0.02f;
			}

			if (keys[VK_NEXT])
			{
				z+=0.02f;
			}

			if (keys[VK_UP])
			{
				xspeed-=0.01f;
			}

			if (keys[VK_DOWN])
			{
				xspeed+=0.01f;
			}

			if (keys[VK_RIGHT])
			{
				yspeed+=0.01f;
			}

			if (keys[VK_LEFT])
			{
				yspeed-=0.01f;
                        }

			if (keys[VK_F1])                        // Is F1 being pressed?
			{
				keys[VK_F1] = false;            // If so make key FALSE
				KillGLWindow();                 // Kill our current window
				fullscreen =! fullscreen;       // Toggle fullscreen / windowed mode
				// Recreate our OpenGL window
				if (!CreateGLWindow("NeHe's GL_ARB_multitexture & Bump Mapping Tutorial",640,480,16,fullscreen))
				{
					return 0;               // Quit if window was not created
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//---------------------------------------------------------------------------
