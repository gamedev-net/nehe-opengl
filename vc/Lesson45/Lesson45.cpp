/*******************************************
*                                          *
*   Paul Frazee's Vertex Array Example     *
*           nehe.gamedev.net               *
*                2003                      *
*                                          *
*******************************************/

#include <windows.h>											// Header File For Windows
#include <gl\gl.h>												// Header File For The OpenGL32 Library
#include <gl\glu.h>												// Header File For The GLu32 Library
#include <gl\glaux.h>											// Header File For The GLaux Library
#include <stdio.h>												// Header File For Standard Input/Output
#include "NeHeGL.h"												// Header File For NeHeGL

#pragma comment( lib, "opengl32.lib" )							// Search For OpenGL32.lib While Linking
#pragma comment( lib, "glu32.lib" )								// Search For GLu32.lib While Linking
#pragma comment( lib, "glaux.lib" )								// Search For GLaux.lib While Linking

#ifndef CDS_FULLSCREEN											// CDS_FULLSCREEN Is Not Defined By Some
#define CDS_FULLSCREEN 4										// Compilers. By Defining It This Way,
#endif															// We Can Avoid Errors

// TUTORIAL
// Mesh Generation Paramaters
#define MESH_RESOLUTION 4.0f									// Pixels Per Vertex
#define MESH_HEIGHTSCALE 1.0f									// Mesh Height Scale
//#define NO_VBOS												// If Defined, VBOs Will Be Forced Off

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

class CVert														// Vertex Class
{
public:
	float x;													// X Component
	float y;													// Y Component
	float z;													// Z Component
};
typedef CVert CVec;												// The Definitions Are Synonymous

class CTexCoord													// Texture Coordinate Class
{
public:
	float u;													// U Component
	float v;													// V Component
};

class CMesh
{
public:
	// Mesh Data
	int				m_nVertexCount;								// Vertex Count
	CVert*			m_pVertices;								// Vertex Data
	CTexCoord*		m_pTexCoords;								// Texture Coordinates
	unsigned int	m_nTextureId;								// Texture ID

	// Vertex Buffer Object Names
	unsigned int	m_nVBOVertices;								// Vertex VBO Name
	unsigned int	m_nVBOTexCoords;							// Texture Coordinate VBO Name

	// Temporary Data
	AUX_RGBImageRec* m_pTextureImage;							// Heightmap Data

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
DWORD		g_dwLastFPS = 0;									// Last FPS Check Time	
//~TUTORIAL

GL_Window*	g_window;
Keys*		g_keys;

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

BOOL Initialize (GL_Window* window, Keys* keys)					// Any GL Init Code & User Initialiazation Goes Here
{
	g_window	= window;
	g_keys		= keys;

	// TUTORIAL
	// Load The Mesh Data
	g_pMesh = new CMesh();										// Instantiate Our Mesh
	if( !g_pMesh->LoadHeightmap( "terrain.bmp",					// Load Our Heightmap
								MESH_HEIGHTSCALE,
								MESH_RESOLUTION ) )
	{
		MessageBox( NULL, "Error Loading Heightmap", "Error", MB_OK );
		return false;
	}

	// Check For VBOs Supported
#ifndef NO_VBOS
	g_fVBOSupported = IsExtensionSupported( "GL_ARB_vertex_buffer_object" );
	if( g_fVBOSupported )
	{
		// Get Pointers To The GL Functions
		glGenBuffersARB = (PFNGLGENBUFFERSARBPROC) wglGetProcAddress("glGenBuffersARB");
		glBindBufferARB = (PFNGLBINDBUFFERARBPROC) wglGetProcAddress("glBindBufferARB");
		glBufferDataARB = (PFNGLBUFFERDATAARBPROC) wglGetProcAddress("glBufferDataARB");
		glDeleteBuffersARB = (PFNGLDELETEBUFFERSARBPROC) wglGetProcAddress("glDeleteBuffersARB");
		// Load Vertex Data Into The Graphics Card Memory
		g_pMesh->BuildVBOs();									// Build The VBOs
	}
#else /* NO_VBOS */
	g_fVBOSupported = false;
#endif
	//~TUTORIAL
	
	// Setup GL States
	glClearColor (0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
	glClearDepth (1.0f);										// Depth Buffer Setup
	glDepthFunc (GL_LEQUAL);									// The Type Of Depth Testing (Less Or Equal)
	glEnable (GL_DEPTH_TEST);									// Enable Depth Testing
	glShadeModel (GL_SMOOTH);									// Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Set Perspective Calculations To Most Accurate
	glEnable( GL_TEXTURE_2D );									// Enable Textures
	glColor4f( 1.0f, 1.0f, 1.0f, 1.0f );						// Set The Color To White

	return TRUE;												// Return TRUE (Initialization Successful)
}

void Deinitialize (void)										// Any User DeInitialization Goes Here
{
	if( g_pMesh )												// Deallocate Our Mesh Data
		delete g_pMesh;											// And Delete VBOs
	g_pMesh = NULL;
}

void Update (DWORD milliseconds)								// Perform Motion Updates Here
{
	g_flYRot += (float) ( milliseconds ) / 1000.0f * 25.0f;		// Consistantly Rotate The Scenery

	if (g_keys->keyDown [VK_ESCAPE] == TRUE)					// Is ESC Being Pressed?
	{
		TerminateApplication (g_window);						// Terminate The Program
	}

	if (g_keys->keyDown [VK_F1] == TRUE)						// Is F1 Being Pressed?
	{
		ToggleFullscreen (g_window);							// Toggle Fullscreen Mode
	}
}

void Draw (void)
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glLoadIdentity ();											// Reset The Modelview Matrix

	// Get FPS
	if( GetTickCount() - g_dwLastFPS >= 1000 )					// When A Second Has Passed...
	{
		g_dwLastFPS = GetTickCount();							// Update Our Time Variable
		g_nFPS = g_nFrames;										// Save The FPS
		g_nFrames = 0;											// Reset The FPS Counter

		char szTitle[256]={0};									// Build The Title String
		sprintf( szTitle, "Lesson 45: NeHe & Paul Frazee's VBO Tut - %d Triangles, %d FPS", g_pMesh->m_nVertexCount / 3, g_nFPS );
		if( g_fVBOSupported )									// Include A Notice About VBOs
			strcat( szTitle, ", Using VBOs" );
		else
			strcat( szTitle, ", Not Using VBOs" );
		SetWindowText( g_window->hWnd, szTitle );				// Set The Title
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
}

bool CMesh :: LoadHeightmap( char* szPath, float flHeightScale, float flResolution )
{
	// Error-Checking
	FILE* fTest = fopen( szPath, "r" );							// Open The Image
	if( !fTest )												// Make Sure It Was Found
		return false;											// If Not, The File Is Missing
	fclose( fTest );											// Done With The Handle

	// Load Texture Data
	m_pTextureImage = auxDIBImageLoad( szPath );				// Utilize GLaux's Bitmap Load Routine

	// Generate Vertex Field
	m_nVertexCount = (int) ( m_pTextureImage->sizeX * m_pTextureImage->sizeY * 6 / ( flResolution * flResolution ) );
	m_pVertices = new CVec[m_nVertexCount];						// Allocate Vertex Data
	m_pTexCoords = new CTexCoord[m_nVertexCount];				// Allocate Tex Coord Data
	int nX, nZ, nTri, nIndex=0;									// Create Variables
	float flX, flZ;
	for( nZ = 0; nZ < m_pTextureImage->sizeY; nZ += (int) flResolution )
	{
		for( nX = 0; nX < m_pTextureImage->sizeX; nX += (int) flResolution )
		{
			for( nTri = 0; nTri < 6; nTri++ )
			{
				// Using This Quick Hack, Figure The X,Z Position Of The Point
				flX = (float) nX + ( ( nTri == 1 || nTri == 2 || nTri == 5 ) ? flResolution : 0.0f );
				flZ = (float) nZ + ( ( nTri == 2 || nTri == 4 || nTri == 5 ) ? flResolution : 0.0f );

				// Set The Data, Using PtHeight To Obtain The Y Value
				m_pVertices[nIndex].x = flX - ( m_pTextureImage->sizeX / 2 );
				m_pVertices[nIndex].y = PtHeight( (int) flX, (int) flZ ) *  flHeightScale;
				m_pVertices[nIndex].z = flZ - ( m_pTextureImage->sizeY / 2 );

				// Stretch The Texture Across The Entire Mesh
				m_pTexCoords[nIndex].u = flX / m_pTextureImage->sizeX;
				m_pTexCoords[nIndex].v = flZ / m_pTextureImage->sizeY;

				// Increment Our Index
				nIndex++;
			}
		}
	}

	// Load The Texture Into OpenGL
	glGenTextures( 1, &m_nTextureId );							// Get An Open ID
	glBindTexture( GL_TEXTURE_2D, m_nTextureId );				// Bind The Texture
	glTexImage2D( GL_TEXTURE_2D, 0, 3, m_pTextureImage->sizeX, m_pTextureImage->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, m_pTextureImage->data );
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

	// Free The Texture Data
	if( m_pTextureImage )
	{
		if( m_pTextureImage->data )
			free( m_pTextureImage->data );
		free( m_pTextureImage );
	}
	return true;
}

float CMesh :: PtHeight( int nX, int nY )
{
	// Calculate The Position In The Texture, Careful Not To Overflow
	int nPos = ( ( nX % m_pTextureImage->sizeX )  + ( ( nY % m_pTextureImage->sizeY ) * m_pTextureImage->sizeX ) ) * 3;
	float flR = (float) m_pTextureImage->data[ nPos ];			// Get The Red Component
	float flG = (float) m_pTextureImage->data[ nPos + 1 ];		// Get The Green Component
	float flB = (float) m_pTextureImage->data[ nPos + 2 ];		// Get The Blue Component
	return ( 0.299f * flR + 0.587f * flG + 0.114f * flB );		// Calculate The Height Using The Luminance Algorithm
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
