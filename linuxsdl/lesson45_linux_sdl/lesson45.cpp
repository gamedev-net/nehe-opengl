/*******************************************
*           Linux / SDL port of            *
*   Paul Frazee's Vertex Array Example     *
*           nehe.gamedev.net               *
*          Ilias Maratos 2004              *
*                                          *
*******************************************/
#ifdef WIN32
#include <windows.h>											// Header File For Windows
#else
#include <stdio.h>												// Header File For Standard Input/Output
#include <string.h>
#endif
#include <GL/gl.h>												// Header File For The OpenGL32 Library
#include <GL/glu.h>												// Header File For The GLu32 Library

#include "main.h"												// Header File For NeHeGL

#pragma comment( lib, "opengl32.lib" )							// Search For OpenGL32.lib While Linking
#pragma comment( lib, "glu32.lib" )								// Search For GLu32.lib While Linking
#pragma comment( lib, "glaux.lib" )								// Search For GLaux.lib While Linking

#ifndef CDS_FULLSCREEN											// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4										// Compilers. By Defining It This Way,
#endif															// We Can Avoid Errors

#ifndef GL_BGR
#define GL_BGR  0x80E0
#endif

// TUTORIAL
// Mesh Generation Paramaters
#define MESH_RESOLUTION 4.0f									// Pixels Per Vertex
#define MESH_HEIGHTSCALE 1.0f									// Mesh Height Scale

// #define NO_VBOS												// If Defined, VBOs Will Be Forced Off

// VBO Extension Definitions, From glext.h
#define GL_ARRAY_BUFFER_ARB 0x8892
#define GL_STATIC_DRAW_ARB 0x88E4

typedef void (APIENTRY * PFNGLBINDBUFFERARBPROC) (GLenum target, GLuint buffer);
typedef void (APIENTRY * PFNGLDELETEBUFFERSARBPROC) (GLsizei n, const GLuint *buffers);
typedef void (APIENTRY * PFNGLGENBUFFERSARBPROC) (GLsizei n, GLuint *buffers);
typedef void (APIENTRY * PFNGLBUFFERDATAARBPROC) (GLenum target, int size, const GLvoid *data, GLenum usage);

// VBO Extension Function Pointers
PFNGLGENBUFFERSARBPROC glGenBuffersARB = NULL;					// VBO Name Generation Procedure
PFNGLBINDBUFFERARBPROC glBindBufferARB = NULL;					// VBO Bind Procedure
PFNGLBUFFERDATAARBPROC glBufferDataARB = NULL;					// VBO Data Loading Procedure
PFNGLDELETEBUFFERSARBPROC glDeleteBuffersARB = NULL;			// VBO Deletion Procedure

extern S_AppStatus AppStatus;	

class CVert														// Vertex Class
{
public:
	GLfloat x;													// X Component
	GLfloat y;													// Y Component
	GLfloat z;													// Z Component
};
typedef CVert CVec;												// The Definitions Are Synonymous

class CTexCoord													// Texture Coordinate Class
{
public:
	GLfloat u;													// U Component
	GLfloat v;													// V Component
};

class CMesh
{
public:
	// Mesh Data
	GLuint				m_nVertexCount;								// Vertex Count
	CVert*			m_pVertices;								// Vertex Data
	CTexCoord*		m_pTexCoords;								// Texture Coordinates
	unsigned int	m_nTextureId;								// Texture ID

	// Vertex Buffer Object Names
	unsigned int	m_nVBOVertices;								// Vertex VBO Name
	unsigned int	m_nVBOTexCoords;							// Texture Coordinate VBO Name

	// Temporary Data
	SDL_Surface* m_pTextureImage;							// Heightmap Data

public:
	CMesh();													// Mesh Constructor
	~CMesh();													// Mesh Deconstructor

	// Heightmap Loader
	bool LoadHeightmap( char* szPath, float flHeightScale, float flResolution );
	// Single Point Height
	float PtHeight( int nX, int nY );
	// VBO Build Function
	void BuildVBOs();
};

bool		g_fVBOSupported = false;							// ARB_vertex_buffer_object supported?
CMesh*		g_pMesh = NULL;										// Mesh Data
float		g_flYRot = 0.0f;									// Rotation
int			g_nFPS = 0, g_nFrames = 0;							// FPS and FPS Counter
int		g_dwLastFPS = 0;									// Last FPS Check Time	
//~TUTORIAL


// TUTORIAL
// Based Off Of Code Supplied At OpenGL.org
bool IsExtensionSupported( char* szTargetExtension )
{
	const unsigned char *pszExtensions = NULL;
	const unsigned char *pszStart;
	unsigned char *pszWhere, *pszTerminator;

	// Extension names should not have spaces
	pszWhere = (unsigned char *) strchr( szTargetExtension, ' ' );
	if( pszWhere || *szTargetExtension == '\0' )
		return false;

	// Get Extensions String
	pszExtensions = glGetString( GL_EXTENSIONS );

	// Search The Extensions String For An Exact Copy
	pszStart = pszExtensions;
	for(;;)
	{
		pszWhere = (unsigned char *) strstr( (const char *) pszStart, szTargetExtension );
		if( !pszWhere )
			break;
		pszTerminator = pszWhere + strlen( szTargetExtension );
		if( pszWhere == pszStart || *( pszWhere - 1 ) == ' ' )
			if( *pszTerminator == ' ' || *pszTerminator == '\0' )
				return true;
		pszStart = pszTerminator;
	}
	return false;
}
//~TUTORIAL

bool Initialize (void)					                     // Any GL Init Code & User Initialiazation Goes Here
{
	AppStatus.Visible	= true;								// At The Beginning, Our App Is Visible
	AppStatus.MouseFocus	= true;								// And Have Both Mouse
	AppStatus.KeyboardFocus = true;								// And Input Focus

	// TUTORIAL
	// Load The Mesh Data
	g_pMesh = new CMesh();										// Instantiate Our Mesh
	if( !g_pMesh->LoadHeightmap( "terrain.bmp",					// Load Our Heightmap
								MESH_HEIGHTSCALE,
								MESH_RESOLUTION ) )
	{
		Log( "Error Loading Heightmap");
		return false;
	}

	// Check For VBOs Supported
	Log("Checking for extensions.....");
#ifndef NO_VBOS
	g_fVBOSupported = IsExtensionSupported( "GL_ARB_vertex_buffer_object" );
	if( g_fVBOSupported )
	{
		Log("VBOs supported, great!\n");
		// Get Pointers To The GL Functions
		glGenBuffersARB = (PFNGLGENBUFFERSARBPROC) SDL_GL_GetProcAddress("glGenBuffersARB");
		glBindBufferARB = (PFNGLBINDBUFFERARBPROC) SDL_GL_GetProcAddress("glBindBufferARB");
		glBufferDataARB = (PFNGLBUFFERDATAARBPROC) SDL_GL_GetProcAddress("glBufferDataARB");
		glDeleteBuffersARB = (PFNGLDELETEBUFFERSARBPROC) SDL_GL_GetProcAddress("glDeleteBuffersARB");
		// Load Vertex Data Into The Graphics Card Memory
		g_pMesh->BuildVBOs();									// Build The VBOs
	}
#else /* NO_VBOS */
	g_fVBOSupported = false;
	Log("VBOs not supported , too bad!\n");
#endif
	//~TUTORIAL
	return true;
	
}


bool InitGL(SDL_Surface *S)										// Any OpenGL Initialization Code Goes Here
{	
	glEnable( GL_TEXTURE_2D );										//Enable Texture Mapping
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);								// Black Background
	glClearDepth (1.0f);												// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);											// The Type Of Depth Testing
	glEnable (GL_DEPTH_TEST);											// Enable Depth Testing
	glShadeModel (GL_SMOOTH);											// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);					// Set Perspective Calculations To Most Accurate
	
    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );			// Enable Double Buffering

	return true;												// Return TRUE (Initialization Successful)
}


void Deinitialize (void)										// Any User DeInitialization Goes Here
{
	if( g_pMesh )												// Deallocate Our Mesh Data
		delete g_pMesh;											// And Delete VBOs
	g_pMesh = NULL;
}

void Update (Uint32 milliseconds, Uint8 *Keys)								// Perform Motion Updates Here
{
	g_flYRot += (float) ( milliseconds ) / 1000.0f * 25.0f;		// Consistantly Rotate The Scenery

	if(Keys)
	{
		if (Keys [SDLK_ESCAPE] == true)					// Is ESC Being Pressed?
		{
			TerminateApplication ();						// Terminate The Program
		}

		if (Keys [SDLK_F1] == true)						// Is F1 Being Pressed?
		{
			ToggleFullscreen ();							// Toggle Fullscreen Mode
		}
    }	

}

void Draw (void)
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glLoadIdentity ();											// Reset The Modelview Matrix

	if( SDL_GetTicks() - g_dwLastFPS >= 1000 )					// When A Second Has Passed...
	{
		g_dwLastFPS = SDL_GetTicks();							// Update Our Time Variable
		g_nFPS = g_nFrames;										// Save The FPS
		g_nFrames = 0;											// Reset The FPS Counter

		char szTitle[256]={0};									// Build The Title String
		sprintf( szTitle, "NeHe & Paul Frazee's VBO Tut - %d Triangles, %d FPS", g_pMesh->m_nVertexCount / 3, g_nFPS );
		if( g_fVBOSupported )									// Include A Notice About VBOs
			strcat( szTitle, ", Using VBOs" );
		else
			strcat( szTitle, ", Not Using VBOs" );
		SDL_WM_SetCaption(szTitle,NULL);				// Set The Title
	}

	g_nFrames++;												// Increment Our FPS Counter
	
	// Move The Camera
	glTranslatef( 0.0f, -220.0f, 0.0f );						// Move Above The Terrain
	glRotatef( 10.0f, 1.0f, 0.0f, 0.0f );						// Look Down Slightly
	glRotatef( g_flYRot, 0.0f, 1.0f, 0.0f );					// Rotate The Camera

	// Enable Pointers
	glEnableClientState( GL_VERTEX_ARRAY );						// Enable Vertex Arrays
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );				// Enable Texture Coord Arrays

	// Set Pointers To Our Data
	if( g_fVBOSupported )
	{
		glBindBufferARB( GL_ARRAY_BUFFER_ARB, g_pMesh->m_nVBOVertices );
		glVertexPointer( 3, GL_FLOAT, 0, (char *) NULL );		// Set The Vertex Pointer To The Vertex Buffer
		glBindBufferARB( GL_ARRAY_BUFFER_ARB, g_pMesh->m_nVBOTexCoords );
		glTexCoordPointer( 2, GL_FLOAT, 0, (char *) NULL );		// Set The TexCoord Pointer To The TexCoord Buffer
	} else
	{
		glVertexPointer( 3, GL_FLOAT, 0, g_pMesh->m_pVertices ); // Set The Vertex Pointer To Our Vertex Data
		glTexCoordPointer( 2, GL_FLOAT, 0, g_pMesh->m_pTexCoords ); // Set The Vertex Pointer To Our TexCoord Data
	}

	// Render
	glDrawArrays( GL_TRIANGLES, 0, g_pMesh->m_nVertexCount );	// Draw All Of The Triangles At Once

	// Disable Pointers
	glDisableClientState( GL_VERTEX_ARRAY );					// Disable Vertex Arrays
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );				// Disable Texture Coord Arrays
}

CMesh :: CMesh()
{
	// Set Pointers To NULL
	m_pTextureImage = NULL;
	m_pVertices = NULL;
	m_pTexCoords = NULL;
	m_nVertexCount = 0;
	m_nVBOVertices = m_nVBOTexCoords = m_nTextureId = 0;
}

CMesh :: ~CMesh()
{
	// Delete VBOs
	if( g_fVBOSupported )
	{
		unsigned int nBuffers[2] = { m_nVBOVertices, m_nVBOTexCoords };
		glDeleteBuffersARB( 2, nBuffers );						// Free The Memory
	}
	// Delete Data
	if( m_pVertices )											// Deallocate Vertex Data
		delete [] m_pVertices;
	m_pVertices = NULL;
	if( m_pTexCoords )											// Deallocate Texture Coord Data
		delete [] m_pTexCoords;
	m_pTexCoords = NULL;
	if(m_nVBOTexCoords)									// Deallocate Vertex Buffer
    	glDeleteBuffersARB( 1, &m_nVBOTexCoords);
   	if(m_nVBOVertices)
   	    glDeleteBuffersARB( 1, &m_nVBOVertices);
}

bool CMesh :: LoadHeightmap( char* szPath, float flHeightScale, float flResolution )
{
   SDL_Surface *surface;				//Surface For image pixelformat conversion
    Uint32 rmask, gmask, bmask, amask;			//Masks for conversion

#if SDL_BYTEORDER == SDL_BIG_ENDIAN		//Check Endianess and set rgba masks accordingly
    rmask = 0xff000000;
    gmask = 0x00ff0000;
    bmask = 0x0000ff00;
    amask = 0x00000000;
#else
    rmask = 0x000000ff;
    gmask = 0x0000ff00;
    bmask = 0x00ff0000;
    amask = 0x00000000;
#endif


	// Load Texture Data
	m_pTextureImage = SDL_LoadBMP( szPath );				// Utilize SDL's Load Routine
    surface = SDL_CreateRGBSurface(SDL_SWSURFACE, m_pTextureImage->w, m_pTextureImage->h, 24,
                                  rmask, gmask, bmask, amask);		// Create a 24bit RGB surface with the same dimensions as the heightmap image
    m_pTextureImage = SDL_ConvertSurface(m_pTextureImage, surface->format , SDL_SWSURFACE ); 	// Convert the heightmap image to 24bit RGB


// Generate Vertex Field
	m_nVertexCount = (int) ( m_pTextureImage->w * m_pTextureImage->h * 6 / ( flResolution * flResolution ) );
	m_pVertices = new CVec[m_nVertexCount];						// Allocate Vertex Data
	m_pTexCoords = new CTexCoord[m_nVertexCount];				// Allocate Tex Coord Data
	int nX, nZ, nTri, nIndex=0;									// Create Variables
	float flX, flZ;
	for( nZ = 0; nZ < m_pTextureImage->h; nZ += (int) flResolution )
	{
		for( nX = 0; nX < m_pTextureImage->w; nX += (int) flResolution )
		{
			for( nTri = 0; nTri < 6; nTri++ )
			{
				// Using This Quick Hack, Figure The X,Z Position Of The Point
				flX = (float) nX + ( ( nTri == 1 || nTri == 2 || nTri == 5 ) ? flResolution : 0.0f );
				flZ = (float) nZ + ( ( nTri == 2 || nTri == 4 || nTri == 5 ) ? flResolution : 0.0f );

				// Set The Data, Using PtHeight To Obtain The Y Value
				m_pVertices[nIndex].x = flX - ( m_pTextureImage->w / 2 );
				m_pVertices[nIndex].y = PtHeight( (int) flX, (int) flZ ) *  flHeightScale;
				m_pVertices[nIndex].z = flZ - ( m_pTextureImage->h / 2 );

				// Stretch The Texture Across The Entire Mesh
				m_pTexCoords[nIndex].u = flX / m_pTextureImage->w;
				m_pTexCoords[nIndex].v = flZ / m_pTextureImage->h;

				// Increment Our Index
				nIndex++;
			}
		}
	}

	// Load The Texture Into OpenGL
	glGenTextures( 1, &m_nTextureId );							// Get An Open ID
	glBindTexture( GL_TEXTURE_2D, m_nTextureId );				// Bind The Texture
	glTexImage2D( GL_TEXTURE_2D, 0, 3, m_pTextureImage->w, m_pTextureImage->h, 0, GL_RGB, GL_UNSIGNED_BYTE, m_pTextureImage->pixels );
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	// Free The Texture Data
	if( m_pTextureImage )
	{
		SDL_FreeSurface( m_pTextureImage );
	}
	
	if( surface )
	{
		SDL_FreeSurface( surface );
	}
	return true;
}

float CMesh :: PtHeight( int nX, int nY )
{
   SDL_Color color;			// Used to store R,G,B components of pixel
   Uint32 col=0;				// Temporary pixel value storage

  char* offset = ( char* ) m_pTextureImage->pixels ;		// Pointer to the first pixel of image

  offset += ( m_pTextureImage->pitch * nY ) ;					// Select Row

  offset += ( m_pTextureImage->format->BytesPerPixel * nX ) ;		// Select column

  memcpy ( &col , offset , m_pTextureImage->format->BytesPerPixel ) ;		// Copy pixel value into col
	
  SDL_GetRGB ( col , m_pTextureImage->format , &color.r , &color.g , &color.b ) ;			// Get R,G,B components of value

  return ( 0.299f * color.r + 0.587f * color.g + 0.114f * color.b );   // Calculate The Height Using The Luminance Algorithm
	
}

void CMesh :: BuildVBOs()
{
	// Generate And Bind The Vertex Buffer
	glGenBuffersARB( 1, &m_nVBOVertices );							// Get A Valid Name
	glBindBufferARB( GL_ARRAY_BUFFER_ARB, m_nVBOVertices );			// Bind The Buffer
	// Load The Data
	glBufferDataARB( GL_ARRAY_BUFFER_ARB, m_nVertexCount*3*sizeof(float), m_pVertices, GL_STATIC_DRAW_ARB );

	// Generate And Bind The Texture Coordinate Buffer
	glGenBuffersARB( 1, &m_nVBOTexCoords );							// Get A Valid Name
	glBindBufferARB( GL_ARRAY_BUFFER_ARB, m_nVBOTexCoords );		// Bind The Buffer
	// Load The Data
	glBufferDataARB( GL_ARRAY_BUFFER_ARB, m_nVertexCount*2*sizeof(float), m_pTexCoords, GL_STATIC_DRAW_ARB );

	// Our Copy Of The Data Is No Longer Necessary, It Is Safe In The Graphics Card
	delete [] m_pVertices; m_pVertices = NULL;
	delete [] m_pTexCoords; m_pTexCoords = NULL;
}
