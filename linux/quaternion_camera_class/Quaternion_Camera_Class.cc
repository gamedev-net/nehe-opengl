/*
 *		This Code Was Created By Jeff Molofee 2000
 *		A HUGE Thanks To Fredric Echols For Cleaning Up
 *		And Optimizing This Code, Making It More Flexible!
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit My Site At nehe.gamedev.net
 *
 */


#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library
#include <GL/glut.h>			// Header File For The GLu32 Library
#include <stdio.h>
#include <stdlib.h>

#include "glCamera.h"
#include "glHeightMap.h"


#define UINT unsigned int
#define TRUE GL_TRUE

UINT	MouseX, MouseY;		// Coordinates for the mouse
UINT	CenterX, CenterY;      // Coordinates for the center of the screen

glCamera Cam;				// Our Camera for moving around and setting prespective
							// on things.
glHeightMap hMap;			// The height map so we have some point of reference while
							// we fly around.

// Resize And Initialize The GL Window
GLvoid ReSizeGLScene(GLsizei width, GLsizei height)
{
    if (height==0)										// Prevent A Divide By Zero By
    {
	height=1;										// Making Height Equal One
    }
    glViewport(0,0,width,height);						// Reset The Current Viewport
    glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
    glLoadIdentity();									// Reset The Projection Matrix
    // Calculate The Aspect Ratio Of The Window
    gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,20.1f,100000.0f);
    glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
    glLoadIdentity();									// Reset The Modelview Matrix

    CenterX = width/2;
    CenterY = height/2;
}

// All Setup For OpenGL Goes Here
int InitGL(GLvoid)
{
    glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
    glClearColor(0.0f, 0.0f, 0.3f, 0.5f);				// Black Background
    glClearDepth(1.0f);									// Depth Buffer Setup
    glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
    glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
	
    // Try to load our height map
    if(!hMap.LoadRawFile("Art/Terrain1.raw", MAP_SIZE * MAP_SIZE)) 
    {
	printf("Failed to load Terrain1.raw.\n");
	exit(1);
    }
    // Try to load our texture for the height map
    if(!hMap.LoadTexture("Art/Dirt2.bmp"))
    {
	printf("Failed to load terrain texture.\n");
	exit(1);
    }
    // Now set up our max values for the camera
    Cam.m_MaxForwardVelocity = 5.0f;
    Cam.m_MaxPitchRate = 5.0f;
    Cam.m_MaxHeadingRate = 5.0f;
    Cam.m_PitchDegrees = 0.0f;
    Cam.m_HeadingDegrees = 0.0f;
    // Initialization Went OK
    return TRUE;
}

// Here's Where We Do All The Drawing
void DrawGLScene(GLvoid)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
    glLoadIdentity();									// Reset The Current Modelview Matrix
    Cam.SetPrespective();
	
    // Lets make the height map really big since we move so fast.
    glScalef(hMap.m_ScaleValue, hMap.m_ScaleValue * HEIGHT_RATIO, hMap.m_ScaleValue);
    hMap.DrawHeightMap();
	
    glFlush();
    glutSwapBuffers();
}

void CheckMouse(int X,int Y)
{
    GLfloat DeltaMouse;

    MouseX = X;
    MouseY = Y;

    if(MouseX < CenterX)
    {
	DeltaMouse = GLfloat(CenterX - MouseX);
	Cam.ChangeHeading(-0.2f * DeltaMouse);
		
    }
    else if(MouseX > CenterX)
    {
	DeltaMouse = GLfloat(MouseX - CenterX);
	Cam.ChangeHeading(0.2f * DeltaMouse);
    }
    if(MouseY < CenterY)
    {
	DeltaMouse = GLfloat(CenterY - MouseY);
	Cam.ChangePitch(-0.2f * DeltaMouse);
    }
    else if(MouseY > CenterY)
    {
	DeltaMouse = GLfloat(MouseY - CenterY);
	Cam.ChangePitch(0.2f * DeltaMouse);
    }

    glutWarpPointer(CenterX,CenterY);

    glutPostRedisplay();
}

void CheckKeys(int key, int x,int y)
{
    if(key == GLUT_KEY_UP)
    {
	Cam.ChangePitch(5.0f);
    }
    else if(key == GLUT_KEY_DOWN)
    {
	Cam.ChangePitch(-5.0f);
    }
    else if(key == GLUT_KEY_LEFT)
    {
	Cam.ChangeHeading(-5.0f);
    }
    else if(key == GLUT_KEY_RIGHT)
    {
	Cam.ChangeHeading(5.0f);
    }
    glutPostRedisplay();
}

void CheckAlphaKeys(unsigned char key, int x,int y)
{
    if(key == 'w')
    {
	Cam.ChangeVelocity(0.5f);	
    }
    else if(key == 's')
    {
	Cam.ChangeVelocity(-0.5f);
    }
    else if (key == 27) // esc
    {
	exit(0);
    }
    glutPostRedisplay();
}

void GLIdleFunc(void)
{
    glutPostRedisplay();
}

void GLVisibility(int vis)
{
    if (vis == GLUT_VISIBLE)
    {
	// we don't want to do this in main(), because redisplay
	// should only be called when there is a window to display
	glutIdleFunc(GLIdleFunc);
    }
    else
    {
        glutIdleFunc(NULL);
    }
}

int
main( int argc, char *argv[] )
{
    glutInit( &argc, argv );
    glutInitWindowSize( 640, 480 );
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
    glutCreateWindow("NeHe Productions: Quanternion Camera Class");
    InitGL();
   
    glutReshapeFunc(ReSizeGLScene);
    glutKeyboardFunc(CheckAlphaKeys);
    glutSpecialFunc(CheckKeys);

    // To enable moving without holding down the mousebutton,
    // uncomment below.
    //glutPassiveMotionFunc(CheckMouse);

    glutMotionFunc(CheckMouse);
    glutDisplayFunc(DrawGLScene);
    glutVisibilityFunc(GLVisibility);

    glutMainLoop();
    return 0;
}
