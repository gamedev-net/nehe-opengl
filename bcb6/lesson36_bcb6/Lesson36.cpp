//---------------------------------------------------------------------------

#include <windows.h>
#include <gl\gl.h>	// Header file for the OpenGL32 library
#include <gl\glu.h>	// Header file for the GLu32 library
#include <gl\glaux.h>	// Header file for the GLaux library
#include <math.h>	// We'll need some math
#include "NeHeGL.h"	// Header file for NeHeGL
#pragma hdrstop

#ifndef CDS_FULLSCREEN	        // CDS_FULLSCREEN is not defined by some
#define CDS_FULLSCREEN 4	// compilers. By defining it this way,
#endif				// we can avoid errors

//---------------------------------------------------------------------------

GL_Window* g_window;
Keys* g_keys;

// User defined variables
float angle;		// Used to rotate the helix
float vertexes[3][3];	// An array of 3 floats to ttore the vertex data
float normal[3];	// An array to store the normal data
GLuint BlurTexture;	// An unsigned int to store the texture number

GLuint EmptyTexture()   // Create an empty texture
{
	GLuint txtnumber;	// Texture ID
	unsigned int* data;	// Stored data

	// Create storage space for texture data (128x128x4)
	data = (unsigned int*)new GLuint[((128 * 128)* 4 * sizeof(unsigned int))];
	ZeroMemory(data,((128 * 128)* 4 * sizeof(unsigned int)));	// Clear storage memory

	glGenTextures(1, &txtnumber);					// Create 1 texture
	glBindTexture(GL_TEXTURE_2D, txtnumber);			// Bind the texture
	glTexImage2D(GL_TEXTURE_2D, 0, 4, 128, 128, 0,
		GL_RGBA, GL_UNSIGNED_BYTE, data);			// Build texture using information in data
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

	delete [] data;		// Release data

	return txtnumber;	// Return the texture ID
}

void ReduceToUnit(float vector[3])      // Reduces a normal vector (3 coordinates)
{					// To a unit normal vector with a length of one.
	float length;			// Holds unit length
	// Calculates the length of the vector
	length = (float)sqrt((vector[0]*vector[0]) + (vector[1]*vector[1]) + (vector[2]*vector[2]));

	if(length == 0.0f)		// Prevents divide by 0 error by providing
		length = 1.0f;		// An acceptable value for vectors to close to 0.

	vector[0] /= length;		// Dividing each element by
	vector[1] /= length;		// the length results in a
	vector[2] /= length;		// unit normal vector.
}

void calcNormal(float v[3][3], float out[3])    // Calculates normal for a quad using 3 points
{
	float v1[3],v2[3];		// Vector 1 (x,y,z) & vector 2 (x,y,z)
	static const int x = 0;		// Define X coord
	static const int y = 1;		// Define Y coord
	static const int z = 2;		// Define Z coord

	// Finds the vector between 2 points by subtracting
	// the x,y,z coordinates from one point to another.

	// Calculate the vector from point 1 to point 0
	v1[x] = v[0][x] - v[1][x];	// Vector 1.x = Vertex[0].x - Vertex[1].x
	v1[y] = v[0][y] - v[1][y];	// Vector 1.y = Vertex[0].y - Vertex[1].y
	v1[z] = v[0][z] - v[1][z];	// Vector 1.z = Vertex[0].y - Vertex[1].z
	// Calculate the vector from point 2 to point 1
	v2[x] = v[1][x] - v[2][x];	// Vector 2.x = Vertex[0].x - Vertex[1].x
	v2[y] = v[1][y] - v[2][y];	// Vector 2.y = Vertex[0].y - Vertex[1].y
	v2[z] = v[1][z] - v[2][z];	// Vector 2.z = Vertex[0].z - Vertex[1].z
	// Compute the cross product to give us a surface normal
	out[x] = v1[y]*v2[z] - v1[z]*v2[y];     // Cross product for Y - Z
	out[y] = v1[z]*v2[x] - v1[x]*v2[z];	// Cross product for X - Z
	out[z] = v1[x]*v2[y] - v1[y]*v2[x];	// Cross product for X - Y

	ReduceToUnit(out);		// Normalize the vectors
}

void ProcessHelix()             // Draws a helix
{
	GLfloat x;		// Helix x coordinate
	GLfloat y;		// Helix y coordinate
	GLfloat z;		// Helix z coordinate
	GLfloat phi;		// Angle
	GLfloat theta;		// Angle
	GLfloat v,u;		// Angles
	GLfloat r;		// Radius of twist
	int twists = 5;		// 5 twists

	GLfloat glfMaterialColor[]={0.4f,0.2f,0.8f,1.0f};	// Set the material color
	GLfloat specular[]={1.0f,1.0f,1.0f,1.0f};		// Sets up specular lighting

	glLoadIdentity();			// Reset the modelview matrix
	gluLookAt(0, 5, 50, 0, 0, 0, 0, 1, 0);	// Eye position (0,5,50) center of scene (0,0,0), up on Y axis

	glPushMatrix();				// Push the modelview matrix

	glTranslatef(0,0,-50);			// Translate 50 units into the screen
	glRotatef(angle/2.0f,1,0,0);		// Rotate by angle/2 on the X-axis
	glRotatef(angle/3.0f,0,1,0);		// Rotate by angle/3 on the Y-axis

    glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE,glfMaterialColor);
	glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,specular);

	r=1.5f;					// Radius

	glBegin(GL_QUADS);			// Begin drawing quads
	for(phi=0; phi <= 360; phi+=20.0)	// 360 degrees in steps of 20
	{
		for(theta=0; theta<=360*twists; theta+=20.0)		// 360 degrees * number of twists in steps of 20
		{
			v=(phi/180.0f*3.142f);				// Calculate angle of first point	(  0 )
			u=(theta/180.0f*3.142f);			// Calculate angle of first point	(  0 )

			x=float(cos(u)*(2.0f+cos(v) ))*r;		// Calculate x position (1st point)
			y=float(sin(u)*(2.0f+cos(v) ))*r;		// Calculate y position (1st point)
			z=float((( u-(2.0f*3.142f)) + sin(v) ) * r);	// Calculate z position (1st point)

			vertexes[0][0]=x;				// Set x value of first vertex
			vertexes[0][1]=y;				// Set y value of first vertex
			vertexes[0][2]=z;				// Set z value of first vertex

			v=(phi/180.0f*3.142f);				// Calculate angle of second point	(  0 )
			u=((theta+20)/180.0f*3.142f);			// Calculate angle of second point	( 20 )

			x=float(cos(u)*(2.0f+cos(v) ))*r;		// Calculate x position (2nd point)
			y=float(sin(u)*(2.0f+cos(v) ))*r;		// Calculate y position (2nd point)
			z=float((( u-(2.0f*3.142f)) + sin(v) ) * r);	// Calculate z position (2nd point)

			vertexes[1][0]=x;			// Set x value of second vertex
			vertexes[1][1]=y;			// Set y value of second vertex
			vertexes[1][2]=z;			// Set z value of second vertex

			v=((phi+20)/180.0f*3.142f);		// Calculate angle of third point	( 20 )
			u=((theta+20)/180.0f*3.142f);		// Calculate angle of third point	( 20 )

			x=float(cos(u)*(2.0f+cos(v) ))*r;	// Calculate x position (3rd point)
			y=float(sin(u)*(2.0f+cos(v) ))*r;	// Calculate y position (3rd point)
			z=float((( u-(2.0f*3.142f)) + sin(v) ) * r);	// Calculate z Position (3rd Point)

			vertexes[2][0]=x;			// Set x value of third vertex
			vertexes[2][1]=y;			// Set y value of third vertex
			vertexes[2][2]=z;			// Set z value of third vertex

			v=((phi+20)/180.0f*3.142f);		// Calculate angle of fourth point	( 20 )
			u=((theta)/180.0f*3.142f);		// Calculate angle of fourth point	(  0 )

			x=float(cos(u)*(2.0f+cos(v) ))*r;		// Calculate x position (4th point)
			y=float(sin(u)*(2.0f+cos(v) ))*r;		// Calculate y position (4th point)
			z=float((( u-(2.0f*3.142f)) + sin(v) ) * r);	// Calculate z position (4th point)

			vertexes[3][0]=x;			// Set x value of fourth vertex
			vertexes[3][1]=y;			// Set y value of fourth vertex
			vertexes[3][2]=z;			// Set z value of fourth vertex

			calcNormal(vertexes,normal);		// Calculate the quad normal

			glNormal3f(normal[0],normal[1],normal[2]);	// Set the normal

			// Render The Quad
			glVertex3f(vertexes[0][0],vertexes[0][1],vertexes[0][2]);
			glVertex3f(vertexes[1][0],vertexes[1][1],vertexes[1][2]);
			glVertex3f(vertexes[2][0],vertexes[2][1],vertexes[2][2]);
			glVertex3f(vertexes[3][0],vertexes[3][1],vertexes[3][2]);
		}
	}
	glEnd();	// Done rendering quads

	glPopMatrix();	// Pop the matrix
}

void ViewOrtho()        // Set up an ortho view
{
	glMatrixMode(GL_PROJECTION);		// Select projection
	glPushMatrix();				// Push the matrix
	glLoadIdentity();			// Reset the matrix
	glOrtho( 0, 640 , 480 , 0, -1, 1 );	// Select ortho mode (640x480)
	glMatrixMode(GL_MODELVIEW);		// Select modelview matrix
	glPushMatrix();				// Push the matrix
	glLoadIdentity();			// Reset the matrix
}

void ViewPerspective()	// Set up a perspective view
{
	glMatrixMode( GL_PROJECTION );		// Select projection
	glPopMatrix();				// Pop the matrix
	glMatrixMode( GL_MODELVIEW );		// Select modelview
	glPopMatrix();				// Pop the matrix
}

void RenderToTexture()	// Renders to a texture
{
	glViewport(0,0,128,128);	// Set our viewport (Match texture size)

	ProcessHelix();			// Render the helix

	glBindTexture(GL_TEXTURE_2D,BlurTexture);	        // Bind to the blur texture

	// Copy our viewPort to the blur texture (From 0,0 to 128,128... no border)
	glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 0, 0, 128, 128, 0);

	glClearColor(0.0f, 0.0f, 0.5f, 0.5);			// Set the clear color to medium blue
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear the screen and depth buffer

	glViewport(0 , 0,640 ,480);	// Set viewport (0,0 to 640x480)
}

void DrawBlur(int times, float inc)	// Draw the blurred image
{
	float spost = 0.0f;			// Starting texture coordinate offset
	float alphainc = 0.9f / times;		// Fade speed for alpha blending
	float alpha = 0.2f;			// Starting alpha value

	// Disable AutoTexture Coordinates
	glDisable(GL_TEXTURE_GEN_S);
	glDisable(GL_TEXTURE_GEN_T);

	glEnable(GL_TEXTURE_2D);		// Enable 2D texture mapping
	glDisable(GL_DEPTH_TEST);		// Disable depth testing
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);	// Set blending mode
	glEnable(GL_BLEND);			// Enable blending
	glBindTexture(GL_TEXTURE_2D,BlurTexture);	// Bind to the blur texture
	ViewOrtho();				// Switch to an ortho view

	alphainc = alpha / times;		// alphainc = 0.2f / times to render blur

	glBegin(GL_QUADS);			// Begin drawing quads
		for (int num = 0;num < times;num++)		// Number Of Times To Render Blur
		{
			glColor4f(1.0f, 1.0f, 1.0f, alpha);	// Set the alpha value (Starts at 0.2)
			glTexCoord2f(0+spost,1-spost);		// Texture coordinate	( 0, 1 )
			glVertex2f(0,0);			// First vertex		(   0,   0 )

			glTexCoord2f(0+spost,0+spost);		// Texture coordinate	( 0, 0 )
			glVertex2f(0,480);			// Second vertex	(   0, 480 )

			glTexCoord2f(1-spost,0+spost);		// Texture coordinate	( 1, 0 )
			glVertex2f(640,480);			// Third vertex		( 640, 480 )

			glTexCoord2f(1-spost,1-spost);		// Texture coordinate	( 1, 1 )
			glVertex2f(640,0);			// Fourth vertex	( 640,   0 )

			spost += inc;				// Gradually increase spost (Zooming closer to texture center)
			alpha = alpha - alphainc;		// Gradually decrease alpha (Gradually fading image out)
		}
	glEnd();			        // Done drawing quads

	ViewPerspective();			// Switch to a perspective view

	glEnable(GL_DEPTH_TEST);		// Enable depth testing
	glDisable(GL_TEXTURE_2D);		// Disable 2D texture mapping
	glDisable(GL_BLEND);			// Disable blending
	glBindTexture(GL_TEXTURE_2D,0);		// Unbind the blur texture
}

BOOL Initialize (GL_Window* window, Keys* keys)		// Any GL init code & user initialiazation goes here
{
	g_window = window;
	g_keys = keys;

	// Start of user initialization
	angle = 0.0f;                           // Set Starting Angle To Zero

	BlurTexture = EmptyTexture();					// Create our empty texture

	glViewport(0 , 0,window->init.width ,window->init.height);	// Set up a viewport
	glMatrixMode(GL_PROJECTION);					// Select the projection matrix
	glLoadIdentity();						// Reset the projection matrix
	gluPerspective(50, (float)window->init.width/(float)window->init.height, 5,  2000); // Set our perspective
	glMatrixMode(GL_MODELVIEW);					// Select the modelview matrix
	glLoadIdentity();						// Reset the modelview matrix

	glEnable(GL_DEPTH_TEST);					// Enable depth testing

	GLfloat global_ambient[4]={0.2f, 0.2f,  0.2f, 1.0f};		// Set ambient lighting to fairly dark light (No color)
	GLfloat light0pos[4]=     {0.0f, 5.0f, 10.0f, 1.0f};		// Set the light position
	GLfloat light0ambient[4]= {0.2f, 0.2f,  0.2f, 1.0f};		// More ambient light
	GLfloat light0diffuse[4]= {0.3f, 0.3f,  0.3f, 1.0f};		// Set the diffuse light a bit brighter
	GLfloat light0specular[4]={0.8f, 0.8f,  0.8f, 1.0f};		// Fairly bright specular lighting

	GLfloat lmodel_ambient[]= {0.2f,0.2f,0.2f,1.0f};		// And more ambient light
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,lmodel_ambient);		// Set the ambient light model

	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, global_ambient);		// Set the global ambient light model
	glLightfv(GL_LIGHT0, GL_POSITION, light0pos);			// Set the lights position
	glLightfv(GL_LIGHT0, GL_AMBIENT, light0ambient);		// Set the ambient light
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light0diffuse);		// Set the diffuse light
	glLightfv(GL_LIGHT0, GL_SPECULAR, light0specular);		// Set up specular lighting
	glEnable(GL_LIGHTING);			// Enable lighting
	glEnable(GL_LIGHT0);			// Enable light0

	glShadeModel(GL_SMOOTH);		// Select smooth shading

	glMateriali(GL_FRONT, GL_SHININESS, 128);
	glClearColor(0.0f, 0.0f, 0.0f, 0.5);	// Set the clear color to black

	return TRUE;				// Return TRUE (Initialization successful)
}

void Deinitialize (void)                // Any user deinitialization goes here
{
	glDeleteTextures(1,&BlurTexture);	// Delete the blur texture
}

void Update (DWORD milliseconds)	// Perform motion updates here
{
	if (g_keys->keyDown [VK_ESCAPE] == TRUE)	// Is ESC being pressed?
	{
		TerminateApplication (g_window);	// Terminate the program
	}

	if (g_keys->keyDown [VK_F1] == TRUE)		// Is F1 being pressed?
	{
		ToggleFullscreen (g_window);		// Toggle fullscreen mode
	}

	angle += (float)(milliseconds) / 5.0f;		// Update angle based on the clock
}

void Draw (void)	// Draw the scene
{
	glClearColor(0.0f, 0.0f, 0.0f, 0.5);			// Set the clear color to black
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear screen and depth buffer
	glLoadIdentity();	// Reset the view
	RenderToTexture();	// Render to a texture
	ProcessHelix();		// Draw our helix
	DrawBlur(25,0.02f);	// Draw the blur effect
	glFlush ();		// Flush the GL rendering pipeline
}
