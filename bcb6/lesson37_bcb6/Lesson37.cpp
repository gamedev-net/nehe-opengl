//---------------------------------------------------------------------------

// Note: The original article for this code can be found at:
// http://www.gamedev.net/reference/programming/features/celshading

#include <windows.h>	// Header file for Windows
#include <math.h>	// Header file for the math library
#include <stdio.h>	// Header file for the standard I/O library
#include <gl\gl.h>	// Header file for the OpenGL32 library
#include <gl\glu.h>	// Header file for the GLu32 library
#include <gl\glaux.h>	// Header file for the GLaux library
#include "NeHeGL.h"	// Header file for NeHeGL

#ifndef CDS_FULLSCREEN		// CDS_FULLSCREEN is not defined by some
#define CDS_FULLSCREEN 4	// compilers. By defining it this way,
#endif				// we can avoid errors

#pragma hdrstop

//---------------------------------------------------------------------------

GL_Window* g_window;
Keys* g_keys;

// User defined structures
typedef struct tagMATRIX	// A structure to hold an OpenGL matrix
{
	float Data[16];		// We use [16] due to OpenGL's matrix format
}
MATRIX;

typedef struct tagVECTOR	// A structure to hold a single vector
{
	float X, Y, Z;		// The components of the vector
}
VECTOR;

typedef struct tagVERTEX	// A structure to hold a single vertex
{
	VECTOR Nor;		// Vertex normal
	VECTOR Pos;	        // Vertex position
}
VERTEX;

typedef struct tagPOLYGON	// A structure to hold a single polygon
{
	VERTEX Verts[3];	// Array of 3 VERTEX structures
}
POLYGON;

// User defined variables
bool outlineDraw  = true;	// Flag to draw the outline
bool outlineSmooth = false;	// Flag to anti-alias the lines
float outlineColor[3] = { 0.0f, 0.0f, 0.0f };	// Color of the lines
float outlineWidth = 3.0f;	// Width of the lines

VECTOR lightAngle;		// The direction of the light
bool lightRotate = false;	// Flag to see if we rotate the light

float modelAngle = 0.0f;	// Y-axis angle of the model
bool modelRotate = false;	// Flag to rotate the model

POLYGON *polyData = NULL;	// Polygon data
int polyNum = 0;		// Number of polygons

GLuint shaderTexture[1];        // Storage for one texture

// File functions
BOOL ReadMesh ()		// Reads the contents of the "model.txt" file
{
	FILE *In = fopen ("Data\\model.txt", "rb");	// Open the file

	if (!In)
		return FALSE;				// Return FALSE if file not opened

	fread (&polyNum, sizeof (int), 1, In);		// Read the header (i.e. number of polygons)

	polyData = new POLYGON [polyNum];		// Allocate the memory

	fread (&polyData[0], sizeof (POLYGON) * polyNum, 1, In);	// Read in all polygon data

	fclose (In);	        // Close the file

	return true;		// It worked
}

// Math Functions
inline float DotProduct (VECTOR &V1, VECTOR &V2)	// Calculate the angle between the 2 vectors
{
	return V1.X * V2.X + V1.Y * V2.Y + V1.Z * V2.Z;	// Return the angle
}

inline float Magnitude (VECTOR &V)	// Calculate the length of the vector
{
	return sqrt (V.X * V.X + V.Y * V.Y + V.Z * V.Z);	// Return the length of the vector
}

void Normalize (VECTOR &V)		// Creates a vector with a unit length of 1
{
	float M = Magnitude (V);	// Calculate the length of the vector

	if (M != 0.0f)			// Make sure we don't divide by 0
	{
		V.X /= M;		// Normalize the 3 components
		V.Y /= M;
		V.Z /= M;
	}
}

void RotateVector (MATRIX &M, VECTOR &V, VECTOR &D)	        // Rotate a vector using the supplied matrix
{
	D.X = (M.Data[0] * V.X) + (M.Data[4] * V.Y) + (M.Data[8]  * V.Z);	// Rotate around the X axis
	D.Y = (M.Data[1] * V.X) + (M.Data[5] * V.Y) + (M.Data[9]  * V.Z);	// Rotate around the Y axis
	D.Z = (M.Data[2] * V.X) + (M.Data[6] * V.Y) + (M.Data[10] * V.Z);	// Rotate around the Z axis
}

// Engine Functions
BOOL Initialize (GL_Window* window, Keys* keys)	// Any GL init code & user initialiazation goes here
{
	int i;				// Looping variable
	char Line[255];			// Storage for 255 characters
	float shaderData[32][3];	// Storate for the 96 shader values

	FILE *In = NULL;		// File pointer

	g_window = window;
	g_keys = keys;

	// Start Of User Initialization
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Realy nice perspective calculations

	glClearColor (0.7f, 0.7f, 0.7f, 0.0f);			// Light grey background
	glClearDepth (1.0f);			// Depth buffer setup

	glEnable (GL_DEPTH_TEST);		// Enable depth testing
	glDepthFunc (GL_LESS);			// The type of depth test to do

	glShadeModel (GL_SMOOTH);		// Enables smooth color shading
	glDisable (GL_LINE_SMOOTH);		// Initially disable line smoothing

	glEnable (GL_CULL_FACE);		// Enable OpenGL face culling

	glDisable (GL_LIGHTING);		// Disable OpenGL lighting

	In = fopen ("Data\\shader.txt", "r");	// Open the shader file

	if (In)					// Check to see if the file opened
	{
		for (i = 0; i < 32; i++)	// Loop though the 32 greyscale values
		{
			if (feof (In))		// Check for the end of the file
				break;

			fgets (Line, 255, In);	// Get the current line

			shaderData[i][0] = shaderData[i][1] = shaderData[i][2] = float(atof (Line)); // Copy over the value
		}

		fclose (In);		        // Close the file
	}

	else
		return false;		        // It went horribly horribly wrong

	glGenTextures (1, &shaderTexture[0]);	// Get a free texture ID

	glBindTexture (GL_TEXTURE_1D, shaderTexture[0]);	// Bind this texture. From now on it will be 1D

	// For crying out loud don't let OpenGL use bi/trilinear filtering!
	glTexParameteri (GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri (GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

	glTexImage1D (GL_TEXTURE_1D, 0, GL_RGB, 32, 0, GL_RGB , GL_FLOAT, shaderData);	// Upload

	lightAngle.X = 0.0f;		// Set the X direction
	lightAngle.Y = 0.0f;		// Set the Y direction
	lightAngle.Z = 1.0f;		// Set the Z direction

	Normalize (lightAngle);		// Normalize the light direction

	return ReadMesh ();		// Return the value of readmesh
}

void Deinitialize (void)		// Any user deinitialization goes here
{
	glDeleteTextures (1, &shaderTexture[0]);	// Delete the shader texture

	delete [] polyData;				// Delete the polygon data
}

void Update (DWORD milliseconds)			// Perform motion updates here
{
	if (g_keys->keyDown [VK_ESCAPE] == TRUE)	// Is ESC being pressed?
	{
		TerminateApplication (g_window);	// Terminate the program
	}

	if (g_keys->keyDown [VK_F1] == TRUE)		// Is F1 being pressed?
	{
		ToggleFullscreen (g_window);		// Toggle fullscreen mode
	}

	if (g_keys->keyDown [' '] == TRUE)		// Is the space bar being pressed?
	{
		modelRotate = !modelRotate;		// Toggle model rotation on/off

		g_keys->keyDown [' '] = FALSE;
	}

	if (g_keys->keyDown ['1'] == TRUE)		// Is the number 1 being pressed?
	{
		outlineDraw = !outlineDraw;		// Toggle outline drawing on/off

		g_keys->keyDown ['1'] = FALSE;
	}

	if (g_keys->keyDown ['2'] == TRUE)		// Is the number 2 being pressed?
	{
		outlineSmooth = !outlineSmooth;		// Toggle anti-aliasing on/off

		g_keys->keyDown ['2'] = FALSE;
	}

	if (g_keys->keyDown [VK_UP] == TRUE)		// Is the up arrow being pressed?
	{
		outlineWidth++;				// Increase line width

		g_keys->keyDown [VK_UP] = FALSE;
	}

	if (g_keys->keyDown [VK_DOWN] == TRUE)		// Is the down arrow being pressed?
	{
		outlineWidth--;				// Decrease line width

		g_keys->keyDown [VK_DOWN] = FALSE;
	}

	if (modelRotate)				// Check to see if rotation is enabled
		modelAngle += (float) (milliseconds) / 10.0f;	// Update angle based on the clock
}

void Draw (void)
{
	int i, j;			// Looping variables

	float TmpShade;			// Temporary shader value

	MATRIX TmpMatrix;		// Temporary MATRIX structure
	VECTOR TmpVector, TmpNormal;	// Temporary VECTOR structures
	
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear the buffers
	glLoadIdentity ();					// Reset the matrix

	if (outlineSmooth)					// Check to see if we want anti-aliased lines
	{
		glHint (GL_LINE_SMOOTH_HINT, GL_NICEST);	// Use the good calculations
		glEnable (GL_LINE_SMOOTH);			// Enable anti-aliasing
	}

	else							// We don't want smooth lines
		glDisable (GL_LINE_SMOOTH);			// Disable anti-aliasing

	glTranslatef (0.0f, 0.0f, -2.0f);			// Move 2 units away from the screen
	glRotatef (modelAngle, 0.0f, 1.0f, 0.0f);		// Rotate the model on it's Y-axis

	glGetFloatv (GL_MODELVIEW_MATRIX, TmpMatrix.Data);	// Get the generated matrix

	// Cel-Shading Code //
	glEnable (GL_TEXTURE_1D);				// Enable 1D texturing
	glBindTexture (GL_TEXTURE_1D, shaderTexture[0]);	// Bind our texture

	glColor3f (1.0f, 1.0f, 1.0f);			// Set the color of the model

	glBegin (GL_TRIANGLES);				// Tell OpenGL that we're drawing triangles

		for (i = 0; i < polyNum; i++)		// Loop through each polygon
		{
			for (j = 0; j < 3; j++)		// Loop through each vertex
			{
				TmpNormal.X = polyData[i].Verts[j].Nor.X;	// Fill up the TmpNormal structure with
				TmpNormal.Y = polyData[i].Verts[j].Nor.Y;	// the current vertices' normal values
				TmpNormal.Z = polyData[i].Verts[j].Nor.Z;

				RotateVector (TmpMatrix, TmpNormal, TmpVector);	// Rotate this by the matrix

				Normalize (TmpVector);				// Normalize the new normal

				TmpShade = DotProduct (TmpVector, lightAngle);	// Calculate the shade value

				if (TmpShade < 0.0f)
					TmpShade = 0.0f;			// Clamp the value to 0 if negative

				glTexCoord1f (TmpShade);			// Set the texture co-ordinate as the shade value
				glVertex3fv (&polyData[i].Verts[j].Pos.X);	// Send the vertex position
		    }
		}

    glEnd ();							// Tell OpenGL to finish drawing

	glDisable (GL_TEXTURE_1D);				// Disable 1D textures

	// Outline Code //
	if (outlineDraw)					// Check to see if we want to draw the outline
	{
		glEnable (GL_BLEND);					// Enable blending
		glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);	// Set the blend mode

		glPolygonMode (GL_BACK, GL_LINE);	        // Draw backfacing polygons as wireframes
		glLineWidth (outlineWidth);			// Set the line width

		glCullFace (GL_FRONT);				// Don't draw any front-facing polygons

		glDepthFunc (GL_LEQUAL);			// Change the depth mode

		glColor3fv (&outlineColor[0]);			// Set the outline color

		glBegin (GL_TRIANGLES);				// Tell OpenGL what we want to draw

			for (i = 0; i < polyNum; i++)		// Loop through each polygon
			{
				for (j = 0; j < 3; j++)		// Loop through each vertex
				{
					glVertex3fv (&polyData[i].Verts[j].Pos.X);	// Send the vertex position
				}
			}

		glEnd ();				// Tell OpenGL we've finished

		glDepthFunc (GL_LESS);			// Reset the depth-testing mode

		glCullFace (GL_BACK);			// Reset the face to be culled

		glPolygonMode (GL_BACK, GL_FILL);	// Reset back-facing polygon drawing mode

		glDisable (GL_BLEND);			// Disable blending
	}
}
