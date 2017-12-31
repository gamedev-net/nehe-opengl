/*
 *		This Code Was Created By Jeff Molofee and GB Schmick 2000
 *		A HUGE Thanks To Fredric Echols For Cleaning Up
 *		And Optimizing The Base Code, Making It More Flexible!
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

// SDL port by Ken Rockot ( kjrockot@home.com )
#ifdef WIN32
#include <windows.h>
#endif

#include <stdio.h>			// Header File For Standard Input/Output
#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library
#include "SDL.h"

bool	keys[512];			// Array Used For The Keyboard Routine
bool	active=true;			// Window active flag set to true by default
bool	fullscreen=true;		// Fullscreen Flag Set To Fullscreen Mode By Default
bool	light;				// Lighting ON/OFF
bool	lp;				// L Pressed? 
bool	fp;				// F Pressed? 
bool    sp;    		             	// Spacebar Pressed? ( NEW )

int		part1;			// Start Of Disc ( NEW )
int		part2;			// End Of Disc ( NEW )
int		p1=0;			// Increase 1 ( NEW )
int		p2=1;			// Increase 2 ( NEW )

GLfloat	xrot;				// X Rotation
GLfloat	yrot;				// Y Rotation
GLfloat xspeed;				// X Rotation Speed
GLfloat yspeed;				// Y Rotation Speed
GLfloat	z=-5.0f;			// Depth Into The Screen

GLUquadricObj *quadratic;		// Storage For Our Quadratic Objects ( NEW )

GLfloat LightAmbient[]=		{ 0.5f, 0.5f, 0.5f, 1.0f };
GLfloat LightDiffuse[]=		{ 1.0f, 1.0f, 1.0f, 1.0f };
GLfloat LightPosition[]=	{ 0.0f, 0.0f, 2.0f, 1.0f };

GLuint	filter;				// Which Filter To Use
GLuint	texture[3];			// Storage For 3 Textures
GLuint  object=0;			// Which Object To Draw (NEW)

int LoadGLTextures()							// Load Bitmaps And Convert To Textures
{
	int Status=true;						// Status Indicator

	FILE *tex_file;
	GLubyte *tex_data = new GLubyte[64*64*3];

	tex_file = fopen ( "Data/Wall.raw", "rb" );
	fread ( tex_data, 1, 64*64*3, tex_file );
	fclose ( tex_file );

	glGenTextures(3, &texture[0]);					// Create Three Textures

	// Create Nearest Filtered Texture
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, 64, 64, 0, GL_RGB, GL_UNSIGNED_BYTE, tex_data ); 

	// Create Linear Filtered Texture
	glBindTexture(GL_TEXTURE_2D, texture[1]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, 64, 64, 0, GL_RGB, GL_UNSIGNED_BYTE, tex_data );

	// Create MipMapped Texture
	glBindTexture(GL_TEXTURE_2D, texture[2]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
	gluBuild2DMipmaps(GL_TEXTURE_2D, 3, 64, 64, GL_RGB, GL_UNSIGNED_BYTE, tex_data );

	return Status;								// Return The Status
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)				// Resize And Initialize The GL Window
{
	if (height==0)								// Prevent A Divide By Zero By
	{
		height=1;							// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();							// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);						// Select The Modelview Matrix
	glLoadIdentity();							// Reset The Modelview Matrix
}

int InitGL(GLvoid)								// All Setup For OpenGL Goes Here
{
	if (!LoadGLTextures())							// Jump To Texture Loading Routine
	{
		return false;							// If Texture Didn't Load Return FALSE
	}

	glEnable(GL_TEXTURE_2D);						// Enable Texture Mapping
	glShadeModel(GL_SMOOTH);						// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);					// Black Background
	glClearDepth(1.0f);							// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);						// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);							// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Really Nice Perspective Calculations

	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);				// Setup The Ambient Light
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);				// Setup The Diffuse Light
	glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);			// Position The Light
	glEnable(GL_LIGHT1);							// Enable Light One

	quadratic=gluNewQuadric();		// Create A Pointer To The Quadric Object (Return 0 If No Memory) (NEW)
	gluQuadricNormals(quadratic, GLU_SMOOTH);				// Create Smooth Normals (NEW)
	gluQuadricTexture(quadratic, GL_TRUE);					// Create Texture Coords (NEW)

	return true;								// Initialization Went OK
}

GLvoid glDrawCube()
{
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
		// Right Face
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
}

int DrawGLScene(GLvoid)						// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();					// Reset The View
	glTranslatef(0.0f,0.0f,z);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);

	glBindTexture(GL_TEXTURE_2D, texture[filter]);

	switch(object)
	{
	case 0:
		glDrawCube();
		break;
	case 1:
		glTranslatef(0.0f,0.0f,-1.5f);			// Center The Cylinder
		gluCylinder(quadratic,1.0f,1.0f,3.0f,32,32);	// A Cylinder With A Radius Of 0.5 And A Height Of 2
		break;
	case 2:
		gluDisk(quadratic,0.5f,1.5f,32,32);		// Draw A Disc (CD Shape) With An Inner Radius Of 0.5, And An Outer Radius Of 2.  Plus A Lot Of Segments ;)
		break;
	case 3:
		gluSphere(quadratic,1.3f,32,32);		// Draw A Sphere With A Radius Of 1 And 16 Longitude And 16 Latitude Segments
		break;
	case 4:
		glTranslatef(0.0f,0.0f,-1.5f);			// Center The Cone
		gluCylinder(quadratic,1.0f,0.0f,3.0f,32,32);	// A Cone With A Bottom Radius Of .5 And A Height Of 2
		break;
	case 5:
		part1+=p1;
		part2+=p2;

		if(part1>359)									// 360 Degrees
		{
			p1=0;
			part1=0;
			p2=1;
			part2=0;
		}
		if(part2>359)									// 360 Degrees
		{
			p1=1;
			p2=0;
		}
		gluPartialDisk(quadratic,0.5f,1.5f,32,32,part1,part2-part1);	// A Disk Like The One Before
		break;
	};

	xrot+=xspeed;
	yrot+=yspeed;
	return true;									// Keep Going
}

bool handle_event ( SDL_Event *event )
{
	switch (event->type)
	{
	case SDL_KEYDOWN:
		keys[event->key.keysym.sym] = true;
		break;
	case SDL_KEYUP:
		keys[event->key.keysym.sym] = false;
		break;
	case SDL_QUIT:
		return true;
	}

	return false;
}

int main ( int argc, char **argv )
{
	bool	done=false;								// Bool Variable To Exit Loop

	SDL_Init ( SDL_INIT_VIDEO );

	SDL_GL_SetAttribute ( SDL_GL_RED_SIZE, 5 );
	SDL_GL_SetAttribute ( SDL_GL_GREEN_SIZE, 5 );
	SDL_GL_SetAttribute ( SDL_GL_BLUE_SIZE, 5 );
	SDL_SetVideoMode ( 1024, 768, 16, SDL_OPENGL | SDL_DOUBLEBUF | SDL_FULLSCREEN );

	ReSizeGLScene ( 1024, 768 );
	InitGL ();

	while(!done)							// Loop That Runs While done=FALSE
	{
		SDL_Event event;
		while ( SDL_PollEvent (&event) ) 
			done |= handle_event ( &event ); 		// Handle any current SDL events

		if ((active && !DrawGLScene()) || keys[SDLK_ESCAPE])	// Active?  Was There A Quit Received?
		{
			done=true;					// ESC or DrawGLScene Signalled A Quit
		}
		
		SDL_GL_SwapBuffers();					// Swap Buffers (Double Buffering)
		
		if (keys[SDLK_l] && !lp)
		{
			lp=true;
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
			lp=false;
		}
		if (keys[SDLK_f] && !fp)
		{
			fp=true;
			filter+=1;
			if (filter>2)
			{
				filter=0;
			}
		}
		if (!keys[SDLK_f])
		{
			fp=false;
		}
		if (keys[SDLK_SPACE] && !sp)
		{
			sp=true;
			object++;
			if(object>5)
				object=0;
		}
		if (!keys[SDLK_SPACE])
		{
			sp=false;
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
	}

	SDL_Quit ();
}
