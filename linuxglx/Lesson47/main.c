/* This code was created by Jeff Molofee '99 (Ported to Linux/GLX by
 * Patrick Schubert 2000 with the help from lesson 1 basecode for Linux/GLX
 * by Mihael Vrbanec).
 *
 * Cleaned up and Hopefully easier to read version by Jason Schultz (2004)
 *
 * @File:			main.c
 *
 * @Description: 	Main file for the OpenGL/GLX Base Code
 *
 * @Lesson 47 Converted to GLX by Jason Schultz (2004). Based on Grey Fox's GLUT
 *  conversion.
 */
 
#include "glx_base.h"

/* User Defined Variables */
#define			SIZE 64
BOOL			cg_enable = True, sp;
GLfloat			mesh[SIZE][SIZE][3];
GLfloat			wave_movement = 0.0f;

CGcontext		cgContext;
CGprogram		cgProgram;
CGprofile		cgVertexProfile;
CGparameter		position, color, modelViewMatrix, wave;
CGerror			cgError;

/* initGLScene(void)
 * 
 * Here is where we initialize everything that will be needed in the
 * OpenGL GLX program. Things like glHint, glEnable, any textures, models
 * that will be used with in the program. Etc.
 * Anything that is Initialized here, should be cleaned up in the 
 * cleanGLScene() function
 */
BOOL initGLScene(void)
{
	int x, z;	/* Used for our for loops, creating mesh */
	
	glShadeModel(GL_SMOOTH);
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0f);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	
	/* Create our mesh */
	for(x = 0; x < SIZE; x++)
	{
		for(z = 0; z < SIZE; z++)
		{
			mesh[x][z][0] = (float)(SIZE/2) - x;
			mesh[x][z][1] = 0.0f;
			mesh[x][z][2] = (float)(SIZE/2) - z;
		}
	}
	
	/* Set up Cg */
	cgContext = cgCreateContext();
	
	/* Validate our context generation was successful */
	if(cgContext == 0)
	{
		fprintf(stderr, "Failed to create Cg Context\n");
		exit(EXIT_FAILURE);
	}
	
	cgVertexProfile = cgGLGetLatestProfile(CG_GL_VERTEX);
	
	/* Validate our Profile Determination was Successful */
	if(cgVertexProfile == CG_PROFILE_UNKNOWN)
	{
		fprintf(stderr, "Invalid profile type\n");
		exit(EXIT_FAILURE);
	}
	
	cgGLSetOptimalOptions(cgVertexProfile);
	
	/* Load and Compile the Vertex Shader From File */
	cgProgram = cgCreateProgramFromFile(cgContext, CG_SOURCE, "./Cg/Wave.cg", cgVertexProfile, "main", 0);
	
	/* Validate Success */
	if(cgProgram == 0)
	{
		cgError = cgGetError();
		
		/* Show a message box explaining what went wrong */
		fprintf(stderr, "%s\n", cgGetErrorString(cgError));
		exit(EXIT_FAILURE);
	}		
	
	/* Load the program */
	cgGLLoadProgram(cgProgram);
	
	/* Get handles to each of our parameters so that 
	 * we can change them at will within our code
	 */
	position		= cgGetNamedParameter(cgProgram, "IN.position");
	color			= cgGetNamedParameter(cgProgram, "IN.color");
	wave			= cgGetNamedParameter(cgProgram, "IN.wave");
	modelViewMatrix	= cgGetNamedParameter(cgProgram, "ModelViewProj");
	
	return True;
}

/* drawGLScene(void)
 *
 * This is our drawing function. What ever we want to/need to draw, will go
 * in this function. 
 */
void drawGLScene(void)
{
	int x, z;
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	gluLookAt(0.0f, 25.0f, -45.0f, 0.0f, 0.0f, 0.0f, 0, 1, 0);
	
	/* set the modelview matrix of our shader to our opengl modelview matrix */
	cgGLSetStateMatrixParameter(modelViewMatrix, CG_GL_MODELVIEW_PROJECTION_MATRIX, CG_GL_MATRIX_IDENTITY);
	
	if(cg_enable)
	{
		cgGLEnableProfile(cgVertexProfile);
		
		/* Bind our Vertex Program to the Current State */
		cgGLBindProgram(cgProgram);
		
		/* Set the Drawing Color to light green (can be changed by shader, etc..) */
		cgGLSetParameter4f(color, 0.5f, 1.0f, 0.5f, 1.0f);
	}
	
	/* Start drawing our mesh */
	for(x = 0; x < SIZE - 1; x++)
	{
		/* Draw a triangle strip for each column of our mesh */
		glBegin(GL_TRIANGLE_STRIP);
		for(z = 0; z < SIZE - 1; z++)
		{
			/* Set the wave parameter of our shader to the incremented wave value from our main program */
			cgGLSetParameter3f(wave, wave_movement, 1.0f, 1.0f);
			glVertex3f(mesh[x][z][0], mesh[x][z][1], mesh[x][z][2]);
			glVertex3f(mesh[x+1][z][0], mesh[x+1][z][1], mesh[x+1][z][2]);
			wave_movement += 0.00001f;
		}
		glEnd();
	}
	
	if(cg_enable)
		cgGLDisableProfile(cgVertexProfile);
	glFlush();
	swapBuffers();
}


/* updateGLScene(void)
 *
 * Function that will be used in updating the scene. What ever you you need
 * to do to progress the scene (key presses, timing, rotations, etc), should
 * be put into this function
 */
void updateGLScene(void)
{
}

/* cleanGLScene(void)
 *
 * Here is where we clean up anything we have initialized in the scene.
 * Things like system resources (keymaps, etc), models, textures, etc.
 *
 * Because this is a base code, we don't do anthing with this function
 */
void cleanGLScene(void)
{
	/* Destroy our Cg Context and all programs contained within it */
	cgDestroyContext(cgContext);
}

/* main(void)
 *
 * This is the main function that calls all other functions to make 
 * things run.
 */
int main(void)
{
	/* Create our OpenGL GLX Window 
     * 640x480 24bpp, no fullscreen
	 */
	createGLWindow("Lesson 47 GLX", 640, 480, 24, False);
	
	/* Initialize the OpenGL GLX Scene */
	initGLScene();
	
	/* Run the OpenGL GLX Scene */
	runGLScene();
	
	/* Deinitialize OpenGL GLX Scene and clean up anything we have
	 * initialized
	 */
	cleanGLScene();
	
	/* Kill the OpenGL GLX Scene */
	killGLWindow();
	
	return 0;
}
