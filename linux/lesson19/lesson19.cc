/*
 *		This Code Was Created By Jeff Molofee 2000
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit My Site At nehe.gamedev.net
 *
 *		this linux port by Ken Rockot ( read README )
 */

#include <stdlib.h>
#include <stdio.h>					// Header File For Standard Input/Output
#include <GL/gl.h>					// Header File For The OpenGL 
#include <GL/glu.h>					// Header File For The GLu

#include "SDL.h"					// SDL include

#define	MAX_PARTICLES	1000				// Number Of Particles To Create

bool	keys[512];

bool	active=true;					// Window Active Flag Set To TRUE By Default
bool	fullscreen=true;				// Fullscreen Flag Set To Fullscreen Mode By Default
bool	rainbow=true;					// Rainbow Mode?
bool	sp;						// Spacebar Pressed?
bool	rp;						// Enter Key Pressed?

float	slowdown=2.0f;					// Slow Down Particles
float	xspeed;						// Base X Speed (To Allow Keyboard Direction Of Tail)
float	yspeed;						// Base Y Speed (To Allow Keyboard Direction Of Tail)
float	zoom=-40.0f;					// Used To Zoom Out

GLuint	loop;						// Misc Loop Variable
GLuint	col;						// Current Color Selection
GLuint	delay;						// Rainbow Effect Delay
GLuint	texture[1];					// Storage For Our Particle Texture

typedef struct						// Create A Structure For Particle
{
	bool	active;					// Active (Yes/No)
	float	life;					// Particle Life
	float	fade;					// Fade Speed
	float	r;					// Red Value
	float	g;					// Green Value
	float	b;					// Blue Value
	float	x;					// X Position
	float	y;					// Y Position
	float	z;					// Z Position
	float	xi;					// X Direction
	float	yi;					// Y Direction
	float	zi;					// Z Direction
	float	xg;					// X Gravity
	float	yg;					// Y Gravity
	float	zg;					// Z Gravity
}
particles;						// Particles Structure

particles particle[MAX_PARTICLES];			// Particle Array (Room For Particle Info)

static GLfloat colors[12][3]=				// Rainbow Of Colors
{
	{1.0f,0.5f,0.5f},{1.0f,0.75f,0.5f},{1.0f,1.0f,0.5f},{0.75f,1.0f,0.5f},
	{0.5f,1.0f,0.5f},{0.5f,1.0f,0.75f},{0.5f,1.0f,1.0f},{0.5f,0.75f,1.0f},
	{0.5f,0.5f,1.0f},{0.75f,0.5f,1.0f},{1.0f,0.5f,1.0f},{1.0f,0.5f,0.75f}
};

int HandleSDL ( SDL_Event *event );					// SDL event handler

int LoadGLTextures()							// Load Bitmap And Convert To A Texture
{
	int Status;
	GLubyte *tex = new GLubyte[32 * 32 * 3];
	FILE *tf;

	tf = fopen ( "Data/Particle.raw", "rb" );
	fread ( tex, 1, 32 * 32 * 3, tf );
	fclose ( tf );

	// do stuff
	Status=1;						// Set The Status To TRUE
	glGenTextures(1, &texture[0]);				// Create One Texture

	glBindTexture(GL_TEXTURE_2D, texture[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, 32, 32,
		0, GL_RGB, GL_UNSIGNED_BYTE, tex);

	delete [] tex;

        return Status;							// Return The Status
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)			// Resize And Initialize The GL Window
{
	if (height==0)							// Prevent A Divide By Zero By
	{
		height=1;						// Making Height Equal One
	}

	glViewport(0,0,width,height);					// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);					// Select The Projection Matrix
	glLoadIdentity();						// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,200.0f);

	glMatrixMode(GL_MODELVIEW);					// Select The Modelview Matrix
	glLoadIdentity();						// Reset The Modelview Matrix
}

int InitGL(GLvoid)							// All Setup For OpenGL Goes Here
{
	if (!LoadGLTextures())						// Jump To Texture Loading Routine
	{
		return 0;						// If Texture Didn't Load Return FALSE
	}

	glShadeModel(GL_SMOOTH);					// Enable Smooth Shading
	glClearColor(0.0f,0.0f,0.0f,0.0f);				// Black Background
	glClearDepth(1.0f);						// Depth Buffer Setup
	glDisable(GL_DEPTH_TEST);					// Disable Depth Testing
	glEnable(GL_BLEND);						// Enable Blending
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);				// Type Of Blending To Perform
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);		// Really Nice Perspective Calculations
	glHint(GL_POINT_SMOOTH_HINT,GL_NICEST);				// Really Nice Point Smoothing
	glEnable(GL_TEXTURE_2D);					// Enable Texture Mapping
	glBindTexture(GL_TEXTURE_2D,texture[0]);			// Select Our Texture

	for (loop=0;loop<MAX_PARTICLES;loop++)				// Initials All The Textures
	{
		particle[loop].active=true;				// Make All The Particles Active
		particle[loop].life=1.0f;				// Give All The Particles Full Life
		particle[loop].fade=float(rand()%100)/1000.0f+0.003f;	// Random Fade Speed
		particle[loop].r=colors[(loop+1)/(MAX_PARTICLES/12)][0];	// Select Red Rainbow Color
		particle[loop].g=colors[(loop+1)/(MAX_PARTICLES/12)][1];	// Select Green Rainbow Color
		particle[loop].b=colors[(loop+1)/(MAX_PARTICLES/12)][2];	// Select Blue Rainbow Color
		particle[loop].xi=float((rand()%50)-26.0f)*10.0f;	// Random Speed On X Axis
		particle[loop].yi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Y Axis
		particle[loop].zi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Z Axis
		particle[loop].xg=0.0f;					// Set Horizontal Pull To Zero
		particle[loop].yg=-0.8f;				// Set Vertical Pull Downward
		particle[loop].zg=0.0f;					// Set Pull On Z Axis To Zero
	}

	return 1;							// Initialization Went OK
}

int DrawGLScene(GLvoid)							// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glLoadIdentity();						// Reset The ModelView Matrix

	for (loop=0;loop<MAX_PARTICLES;loop++)				// Loop Through All The Particles
	{
		if (particle[loop].active)				// If The Particle Is Active
		{
			float x=particle[loop].x;			// Grab Our Particle X Position
			float y=particle[loop].y;			// Grab Our Particle Y Position
			float z=particle[loop].z+zoom;			// Particle Z Pos + Zoom

			// Draw The Particle Using Our RGB Values, Fade The Particle Based On It's Life
			glColor4f(particle[loop].r,particle[loop].g,particle[loop].b,particle[loop].life);

			glBegin(GL_TRIANGLE_STRIP);				// Build Quad From A Triangle Strip
			    glTexCoord2d(1,1); glVertex3f(x+0.5f,y+0.5f,z);	// Top Right
				glTexCoord2d(0,1); glVertex3f(x-0.5f,y+0.5f,z); // Top Left
				glTexCoord2d(1,0); glVertex3f(x+0.5f,y-0.5f,z); // Bottom Right
				glTexCoord2d(0,0); glVertex3f(x-0.5f,y-0.5f,z); // Bottom Left
			glEnd();						// Done Building Triangle Strip

			particle[loop].x+=particle[loop].xi/(slowdown*1000);// Move On The X Axis By X Speed
			particle[loop].y+=particle[loop].yi/(slowdown*1000);// Move On The Y Axis By Y Speed
			particle[loop].z+=particle[loop].zi/(slowdown*1000);// Move On The Z Axis By Z Speed

			particle[loop].xi+=particle[loop].xg;			// Take Pull On X Axis Into Account
			particle[loop].yi+=particle[loop].yg;			// Take Pull On Y Axis Into Account
			particle[loop].zi+=particle[loop].zg;			// Take Pull On Z Axis Into Account
			particle[loop].life-=particle[loop].fade;		// Reduce Particles Life By 'Fade'

			if (particle[loop].life<0.0f)					// If Particle Is Burned Out
			{
				particle[loop].life=1.0f;				// Give It New Life
				particle[loop].fade=float(rand()%100)/1000.0f+0.003f;	// Random Fade Value
				particle[loop].x=0.0f;					// Center On X Axis
				particle[loop].y=0.0f;					// Center On Y Axis
				particle[loop].z=0.0f;					// Center On Z Axis
				particle[loop].xi=xspeed+float((rand()%60)-32.0f);	// X Axis Speed And Direction
				particle[loop].yi=yspeed+float((rand()%60)-30.0f);	// Y Axis Speed And Direction
				particle[loop].zi=float((rand()%60)-30.0f);		// Z Axis Speed And Direction
				particle[loop].r=colors[col][0];			// Select Red From Color Table
				particle[loop].g=colors[col][1];			// Select Green From Color Table
				particle[loop].b=colors[col][2];			// Select Blue From Color Table
			}

			// If Number Pad 8 And Y Gravity Is Less Than 1.5 Increase Pull Upwards
			if (keys[SDLK_KP8] && (particle[loop].yg<1.5f)) particle[loop].yg+=0.01f;

			// If Number Pad 2 And Y Gravity Is Greater Than -1.5 Increase Pull Downwards
			if (keys[SDLK_KP2] && (particle[loop].yg>-1.5f)) particle[loop].yg-=0.01f;

			// If Number Pad 6 And X Gravity Is Less Than 1.5 Increase Pull Right
			if (keys[SDLK_KP6] && (particle[loop].xg<1.5f)) particle[loop].xg+=0.01f;

			// If Number Pad 4 And X Gravity Is Greater Than -1.5 Increase Pull Left
			if (keys[SDLK_KP4] && (particle[loop].xg>-1.5f)) particle[loop].xg-=0.01f;

			if (keys[SDLK_TAB])						// Tab Key Causes A Burst
			{
				particle[loop].x=0.0f;					// Center On X Axis
				particle[loop].y=0.0f;					// Center On Y Axis
				particle[loop].z=0.0f;					// Center On Z Axis
				particle[loop].xi=float((rand()%50)-26.0f)*10.0f;	// Random Speed On X Axis
				particle[loop].yi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Y Axis
				particle[loop].zi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Z Axis
			}
		}
    	}

	SDL_GL_SwapBuffers ();

	return 1;									// Everything Went OK
}

void check_keys ()
{
	if (keys[SDLK_KP_PLUS] && (slowdown>0.0f)) slowdown-=0.01f;
	if (keys[SDLK_KP_MINUS] && (slowdown<4.0f)) slowdown+=0.01f;	// Slow Down Particles

	if (keys[SDLK_PAGEUP])	zoom+=0.1f;				// Zoom In
	if (keys[SDLK_PAGEDOWN])	zoom-=0.1f;			// Zoom Out

	if (keys[SDLK_RETURN] && !rp)					// Return Key Pressed
	{
		rp=true;						// Set Flag Telling Us It's Pressed
		rainbow=!rainbow;					// Toggle Rainbow Mode On / Off
	}
	if (!keys[SDLK_RETURN]) rp=false;				// If Return Is Released Clear Flag
				
	if ((keys[SDLK_SPACE] && !sp) || (rainbow && (delay>25)))	// Space Or Rainbow Mode
	{
		if (keys[SDLK_SPACE])	rainbow=false;			// If Spacebar Is Pressed Disable Rainbow Mode
		sp=true;						// Set Flag Telling Us Space Is Pressed
		delay=0;						// Reset The Rainbow Color Cycling Delay
		col++;							// Change The Particle Color
		if (col>11)	col=0;					// If Color Is To High Reset It
	}
	if (!keys[SDLK_SPACE])	sp=false;				// If Spacebar Is Released Clear Flag

	// If Up Arrow And Y Speed Is Less Than 200 Increase Upward Speed
	if (keys[SDLK_UP] && (yspeed<200)) yspeed+=1.0f;

	// If Down Arrow And Y Speed Is Greater Than -200 Increase Downward Speed
	if (keys[SDLK_DOWN] && (yspeed>-200)) yspeed-=1.0f;

	// If Right Arrow And X Speed Is Less Than 200 Increase Speed To The Right
	if (keys[SDLK_RIGHT] && (xspeed<200)) xspeed+=1.0f;

	// If Left Arrow And X Speed Is Greater Than -200 Increase Speed To The Left
	if (keys[SDLK_LEFT] && (xspeed>-200)) xspeed-=1.0f;

	delay++;			// Increase Rainbow Mode Color Cycling Delay Counter
}

int HandleSDL ( SDL_Event *event )
{
	int done = 0;

	switch ( event->type )
	{
		case SDL_QUIT:
			done = 1;
			break;

		case SDL_KEYDOWN:
			if ( event->key.keysym.sym == SDLK_ESCAPE ) done = 1;
			keys[event->key.keysym.sym] = true;
			break;

		case SDL_KEYUP:
			keys[event->key.keysym.sym] = false;
			break;
	}

	return done;
}

int main ( int argc, char **argv )
{
	SDL_Init ( SDL_INIT_VIDEO );

	int flags = SDL_DOUBLEBUF | SDL_FULLSCREEN | SDL_OPENGL;
	SDL_GL_SetAttribute ( SDL_GL_RED_SIZE, 5 );
	SDL_GL_SetAttribute ( SDL_GL_GREEN_SIZE, 5 );
	SDL_GL_SetAttribute ( SDL_GL_BLUE_SIZE, 5 );
	SDL_SetVideoMode ( 1024, 768, 16, flags );

	InitGL ();
	ReSizeGLScene ( 1024, 768 );

	int done = 0;
	while ( !done )
	{
		DrawGLScene ();
		check_keys ();
		
		SDL_Event event;
		while ( SDL_PollEvent ( &event ) )
		{
			done = HandleSDL ( &event );
		}
	}

	SDL_Quit ();
}
