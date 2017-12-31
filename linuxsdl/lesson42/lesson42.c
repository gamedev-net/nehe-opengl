/*
 * This code was created by Jeff Molofee '99 
 * (merged to Linux/SDL by evik form Sean Farrel's 
 * Linux/SDL code.
 * 
 *
 * If you've found this code useful, please let me know.
 *
 * Visit Jeff at http://nehe.gamedev.net/
 * 
 * or for port-specific comments, questions, bugreports etc. 
 * email to evik@chaos.hu
 */

#include <stdio.h>
#include <stdlib.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "SDL.h"

/* screen width, height, and bit depth */
#define SCREEN_WIDTH  1024
#define SCREEN_HEIGHT  768
#define SCREEN_BPP      32

/* Set up some booleans */
#define TRUE  1
#define FALSE 0

/* This is our SDL surface */
SDL_Surface *surface;

/* User Defined Variables */
int	mx,my;						/* General Loops (Used For Seeking) */

const	GLint width	= 128;		/* Maze Width  (Must Be A Power Of 2) */
const	GLint height	= 128;	/* Maze Height (Must Be A Power Of 2) */

GLboolean	done;							/* Flag To Let Us Know When It's Done */
GLboolean	sp;								/* Spacebar Pressed? */

GLbyte	r[4], g[4], b[4];		/* Random Colors (4 Red, 4 Green, 4 Blue) */
GLubyte	*tex_data;					/* Holds Our Texture Data */

GLfloat	xrot = 0;		/* Use For Rotation Of Objects */
GLfloat yrot = 0;
GLfloat zrot = 0;

GLUquadricObj *quadric;			/* The Quadric Object */

void Quit( int returnCode )
{
	  /* freeing up texture data memory */
    free(tex_data);
	
		/* clean up the window */
    SDL_Quit( );

    /* and exit appropriately */
    exit( returnCode );
}

/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
void resizeWindow(int Width, int Height)
{
  if (Height==0)				/* Prevent A Divide By Zero If The Window Is Too Small */
    Height=1;

  glViewport(0, 0, Width, Height);		/* Reset The Current Viewport And Perspective Transformation */
}

void UpdateTex(int dmx, int dmy)					/* Update Pixel dmx, dmy On The Texture */
{
	tex_data[0+((dmx+(width*dmy))*3)]=255;	/* Set Red Pixel To Full Bright */
	tex_data[1+((dmx+(width*dmy))*3)]=255;	/* Set Green Pixel To Full Bright */
	tex_data[2+((dmx+(width*dmy))*3)]=255;	/* Set Blue Pixel To Full Bright */
}

void Reset (void)														/* Reset The Maze, Colors, Start Point, Etc */
{
	int loop;
	
	memset(tex_data, 0, width * height *3);	/* Clear Out The Texture Memory With 0's */

	srand(SDL_GetTicks());										/* Try To Get More Randomness */

	for (loop=0; loop<4; loop++)					/* Loop So We Can Assign 4 Random Colors */
	{
		r[loop]=rand()%128+128;									/* Pick A Random Red Color (Bright) */
		g[loop]=rand()%128+128;									/* Pick A Random Green Color (Bright) */
		b[loop]=rand()%128+128;									/* Pick A Random Blue Color (Bright) */
	}

	mx=(int)(rand()%(width/2))*2;								/* Pick A New Random X Position */
	my=(int)(rand()%(height/2))*2;							/* Pick A New Random Y Position */
}

/* Perform Motion Updates Here */
void Update (float milliseconds)
{
	int		dir;													/* Will Hold Current Direction */
	int x, y;
	
	xrot+=(float)(milliseconds)*0.02f;	/* Increase Rotation On The X-Axis */
	yrot+=(float)(milliseconds)*0.03f;	/* Increase Rotation On The Y-Axis */
	zrot+=(float)(milliseconds)*0.015f;	/* Increase Rotation On The Z-Axis */

	done=TRUE;													/* Set done To True */
	for (x=0; x<width; x+=2)			  /* Loop Through All The Rooms */
	{
		for (y=0; y<height; y+=2)			/* On X And Y Axis */
		{
			if (tex_data[((x+(width*y))*3)]==0)	/* If Current Texture Pixel (Room) Is Blank */
				done=FALSE;										/* We Have To Set done To False (Not Finished Yet) */
		}
	}

	if (done)														/* If done Is True Then There Were No Unvisited Rooms */
	{
		/* Display A Message At The Top Of The Window, Pause For A Bit And Then Start Building A New Maze! */
		SDL_WM_SetCaption("Lesson 42: Multiple Viewports... 2003 NeHe Productions... Maze Complete!", NULL);
		SDL_Delay(5000);
		SDL_WM_SetCaption("Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!", NULL);
		Reset();
	}

	/* Check To Make Sure We Are Not Trapped (Nowhere Else To Move) */
	if (((tex_data[(((mx+2)+(width*my))*3)]==255) || mx>(width-4)) && ((tex_data[(((mx-2)+(width*my))*3)]==255) || mx<2) &&
		((tex_data[((mx+(width*(my+2)))*3)]==255) || my>(height-4)) && ((tex_data[((mx+(width*(my-2)))*3)]==255) || my<2))
	{
		do																/* If We Are Trapped */
		{
			mx=(int)(rand()%(width/2))*2;			/* Pick A New Random X Position */
			my=(int)(rand()%(height/2))*2;		/* Pick A New Random Y Position */
		}
		while (tex_data[((mx+(width*my))*3)]==0);	/* Keep Picking A Random Position Until We Find */
	}																		/* One That Has Already Been Tagged (Safe Starting Point) */

	dir=(int)(rand()%4);									/* Pick A Random Direction */

	if ((dir==0) && (mx<=(width-4)))		/* If The Direction Is 0 (Right) And We Are Not At The Far Right */
	{
		if (tex_data[(((mx+2)+(width*my))*3)]==0)	/* And If The Room To The Right Has Not Already Been Visited */
		{
			UpdateTex(mx+1,my);							/* Update The Texture To Show Path Cut Out Between Rooms */
			mx+=2;													/* Move To The Right (Room To The Right) */
		}
	}

	if ((dir==1) && (my<=(height-4)))		/* If The Direction Is 1 (Down) And We Are Not At The Bottom */
	{
		if (tex_data[((mx+(width*(my+2)))*3)]==0)	/* And If The Room Below Has Not Already Been Visited */
		{
			UpdateTex(mx,my+1);							/* Update The Texture To Show Path Cut Out Between Rooms */
			my+=2;													/* Move Down (Room Below) */
		}
	}

	if ((dir==2) && (mx>=2))						/* If The Direction Is 2 (Left) And We Are Not At The Far Left */
	{
		if (tex_data[(((mx-2)+(width*my))*3)]==0)	/* And If The Room To The Left Has Not Already Been Visited */
		{
			UpdateTex(mx-1,my);							/* Update The Texture To Show Path Cut Out Between Rooms */
			mx-=2;													/* Move To The Left (Room To The Left) */
		}
	}

	if ((dir==3) && (my>=2))						/* If The Direction Is 3 (Up) And We Are Not At The Top */
	{
		if (tex_data[((mx+(width*(my-2)))*3)]==0)	/* And If The Room Above Has Not Already Been Visited */
		{
			UpdateTex(mx,my-1);							/* Update The Texture To Show Path Cut Out Between Rooms */
			my-=2;													/* Move Up (Room Above) */
		}
	}

	UpdateTex(mx,my);										/* Update Current Room */
}


/* The main drawing function. */
void drawGLScene()
{
	int loop;
	
	int window_width =surface->w;	/* Calculate The Width (Right Side-Left Side) */
	int window_height=surface->h;	/* Calculate The Height (Bottom-Top) */

	/* Update Our Texture... This Is The Key To The Programs Speed... Much Faster Than Rebuilding The Texture Each Time */
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, tex_data);

	glClear (GL_COLOR_BUFFER_BIT);					/* Clear Screen */

	for (loop=0; loop<4; loop++)				/* Loop To Draw Our 4 Views */
	{
		glColor3ub(r[loop],g[loop],b[loop]);	/* Assign Color To Current View */

		if (loop==0)	/* If We Are Drawing The First Scene */
		{
			/* Set The Viewport To The Top Left.  It Will Take Up Half The Screen Width And Height */
			glViewport (0, window_height/2, window_width/2, window_height/2);
			glMatrixMode (GL_PROJECTION);		/* Select The Projection Matrix */
			glLoadIdentity ();							/* Reset The Projection Matrix */
			/* Set Up Ortho Mode To Fit 1/4 The Screen (Size Of A Viewport) */
			gluOrtho2D(0, window_width/2, window_height/2, 0);
		}

		if (loop==1)	/* If We Are Drawing The Second Scene */
		{
			/* Set The Viewport To The Top Right.  It Will Take Up Half The Screen Width And Height */
			glViewport (window_width/2, window_height/2, window_width/2, window_height/2);
			glMatrixMode (GL_PROJECTION);		/* Select The Projection Matrix */
			glLoadIdentity ();							/* Reset The Projection Matrix */
			/* Set Up Perspective Mode To Fit 1/4 The Screen (Size Of A Viewport) */
			gluPerspective( 45.0, (GLfloat)(width)/(GLfloat)(height), 0.1f, 500.0 ); 
		}

		if (loop==2)	/* If We Are Drawing The Third Scene */
		{
			/* Set The Viewport To The Bottom Right.  It Will Take Up Half The Screen Width And Height */
			glViewport (window_width/2, 0, window_width/2, window_height/2);
			glMatrixMode (GL_PROJECTION);		/* Select The Projection Matrix */
			glLoadIdentity ();							/* Reset The Projection Matrix */
			/* Set Up Perspective Mode To Fit 1/4 The Screen (Size Of A Viewport) */
			gluPerspective( 45.0, (GLfloat)(width)/(GLfloat)(height), 0.1f, 500.0 ); 
		}

		if (loop==3)	/* If We Are Drawing The Fourth Scene */
		{
			/* Set The Viewport To The Bottom Left.  It Will Take Up Half The Screen Width And Height */
			glViewport (0, 0, window_width/2, window_height/2);
			glMatrixMode (GL_PROJECTION);		/* Select The Projection Matrix */
			glLoadIdentity ();							/* Reset The Projection Matrix */
			/* Set Up Perspective Mode To Fit 1/4 The Screen (Size Of A Viewport) */
			gluPerspective( 45.0, (GLfloat)(width)/(GLfloat)(height), 0.1f, 500.0 ); 
		}

		glMatrixMode (GL_MODELVIEW);			/* Select The Modelview Matrix */
		glLoadIdentity ();								/* Reset The Modelview Matrix */

		glClear (GL_DEPTH_BUFFER_BIT);		/* Clear Depth Buffer */

		if (loop==0)	/* Are We Drawing The First Image?  (Original Texture... Ortho) */
		{
			glBegin(GL_QUADS);	/* Begin Drawing A Single Quad */
				/* We Fill The Entire 1/4 Section With A Single Textured Quad. */
				glTexCoord2f(1.0f, 0.0f); glVertex2i(window_width/2, 0              );
				glTexCoord2f(0.0f, 0.0f); glVertex2i(0,              0              );
				glTexCoord2f(0.0f, 1.0f); glVertex2i(0,              window_height/2);
				glTexCoord2f(1.0f, 1.0f); glVertex2i(window_width/2, window_height/2);
			glEnd();						/* Done Drawing The Textured Quad */
		}

		if (loop==1)	/* Are We Drawing The Second Image?  (3D Texture Mapped Sphere... Perspective) */
		{
			glTranslatef(0.0f,0.0f,-14.0f);	/* Move 14 Units Into The Screen */

			glRotatef(xrot,1.0f,0.0f,0.0f);	/* Rotate By xrot On The X-Axis */
			glRotatef(yrot,0.0f,1.0f,0.0f);	/* Rotate By yrot On The Y-Axis */
			glRotatef(zrot,0.0f,0.0f,1.0f);	/* Rotate By zrot On The Z-Axis */

			glEnable(GL_LIGHTING);					/* Enable Lighting */
			gluSphere(quadric,4.0f,32,32);	/* Draw A Sphere */
			glDisable(GL_LIGHTING);					/* Disable Lighting */
		}
		
		if (loop==2)	/* Are We Drawing The Third Image?  (Texture At An Angle... Perspective) */
		{
			glTranslatef(0.0f,0.0f,-2.0f);				/* Move 2 Units Into The Screen */
			glRotatef(-45.0f,1.0f,0.0f,0.0f);			/* Tilt The Quad Below Back 45 Degrees. */
			glRotatef(zrot/1.5f,0.0f,0.0f,1.0f);	/* Rotate By zrot/1.5 On The Z-Axis */

			glBegin(GL_QUADS);	/* Begin Drawing A Single Quad */
				glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, 0.0f);
				glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, 0.0f);
				glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, 0.0f);
				glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, 0.0f);
			glEnd();						/* Done Drawing The Textured Quad */
		}

		if (loop==3) /* Are We Drawing The Fourth Image?  (3D Texture Mapped Cylinder... Perspective) */
		{
			glTranslatef(0.0f,0.0f,-7.0f);			/* Move 7 Units Into The Screen */
			glRotatef(-xrot/2,1.0f,0.0f,0.0f);	/* Rotate By -xrot/2 On The X-Axis */
			glRotatef(-yrot/2,0.0f,1.0f,0.0f);	/* Rotate By -yrot/2 On The Y-Axis */
			glRotatef(-zrot/2,0.0f,0.0f,1.0f);	/* Rotate By -zrot/2 On The Z-Axis */

			glEnable(GL_LIGHTING);							/* Enable Lighting */
			glTranslatef(0.0f,0.0f,-2.0f);			/* Translate -2 On The Z-Axis (To Rotate Cylinder Around The Center, Not An End) */
			gluCylinder(quadric,1.5f,1.5f,4.0f,32,16);	/* Draw A Cylinder */
			glDisable(GL_LIGHTING);							/* Disable Lighting */
		}
	}

	glFlush ();															/* Flush The GL Rendering Pipeline */

	SDL_GL_SwapBuffers();
}

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
void initGL()	        /* We call this right after our OpenGL window is created. */
{
	tex_data=malloc(width*height*3);		/* Allocate Space For Our Texture */

	Reset();															/* Call Reset To Build Our Initial Texture, Etc. */

	/* Start Of User Initialization */
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, tex_data);

  glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			/* Realy Nice perspective calculations */
	
  glClearColor (0.0f, 0.0f, 0.0f, 0.0f);		/* Light Grey Background */
  glClearDepth (1.0f);										  /* Depth Buffer Setup */

	glDepthFunc (GL_LEQUAL);									/* The Type Of Depth Test To Do */
  glEnable (GL_DEPTH_TEST);									/* Enable Depth Testing */

  glShadeModel (GL_SMOOTH);									/* Enables Smooth Color Shading */
  glDisable (GL_LINE_SMOOTH);								/* Initially Disable Line Smoothing */

	glEnable(GL_COLOR_MATERIAL);							/* Enable Color Material (Allows Us To Tint Textures) */
	
	glEnable(GL_TEXTURE_2D);									/* Enable Texture Mapping */
	
	glEnable(GL_LIGHT0);											/* Enable Light0 (Default GL Light) */

	quadric=gluNewQuadric();									/* Create A Pointer To The Quadric Object */
	gluQuadricNormals(quadric, GLU_SMOOTH);		/* Create Smooth Normals */
	gluQuadricTexture(quadric, GL_TRUE);			/* Create Texture Coords */
}

/* function to handle key press events */
void handleKeyPress( SDL_keysym *keysym )
{
    switch ( keysym->sym )
	{
	case SDLK_ESCAPE:
	    /* ESC key was pressed */
	    Quit( 0 );
	    break;
	case SDLK_F1:
	    /* F1 key was pressed
	     * this toggles fullscreen mode
	     */
	    SDL_WM_ToggleFullScreen( surface );
	    break;
	case SDLK_SPACE:
			/* Spacebar pressed */
			Reset();
			break;
	default:
	    break;
	}

    return;
}


int main(int argc, char **argv) 
{
 /* Flags to pass to SDL_SetVideoMode */
    int videoFlags;
    /* main loop variable */
    int running = TRUE;
    /* used to collect events */
    SDL_Event event;
    /* this holds some info about our display */
    const SDL_VideoInfo *videoInfo;
    /* whether or not the window is active */
    int isActive = TRUE;
		/* TickCount */
		GLuint lastTickCount;
		GLuint tickCount;

    /* initialize SDL */
    if ( SDL_Init( SDL_INIT_VIDEO ) < 0 )
		{
	    fprintf( stderr, "Video initialization failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
		}

		lastTickCount = SDL_GetTicks();
		
    /* Fetch the video info */
    videoInfo = SDL_GetVideoInfo( );

    if ( !videoInfo )
		{
	    fprintf( stderr, "Video query failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
		}

    /* the flags to pass to SDL_SetVideoMode */
    videoFlags  = SDL_OPENGL;          /* Enable OpenGL in SDL */
    videoFlags |= SDL_GL_DOUBLEBUFFER; /* Enable double buffering */
    videoFlags |= SDL_HWPALETTE;       /* Store the palette in hardware */
    videoFlags |= SDL_RESIZABLE;       /* Enable window resizing */

    /* This checks to see if surfaces can be stored in memory */
    if ( videoInfo->hw_available )
			videoFlags |= SDL_HWSURFACE;
    else
			videoFlags |= SDL_SWSURFACE;

    /* This checks if hardware blits can be done */
    if ( videoInfo->blit_hw )
			videoFlags |= SDL_HWACCEL;

    /* Sets up OpenGL double buffering */
    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

    /* get a SDL surface */
    surface = SDL_SetVideoMode( SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP,
				videoFlags );

    /* Verify there is a surface */
    if ( !surface )
		{
	    fprintf( stderr,  "Video mode set failed: %s\n", SDL_GetError( ) );
	    Quit( 1 );
		}

		SDL_WM_ToggleFullScreen( surface );

		SDL_WM_SetCaption("Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!", NULL);

    /* initialize OpenGL */
    initGL( );

    /* resize the initial window */
    resizeWindow( SCREEN_WIDTH, SCREEN_HEIGHT );
  
    /* wait for events */
    while ( running )
	  {
	    /* handle the events in the queue */

	    while ( SDL_PollEvent( &event ) )
			{
		    switch( event.type )
				{
					case SDL_ACTIVEEVENT:
						/* Something's happend with our focus
						 * If we lost focus or we are iconified, we
						 * shouldn't draw the screen
						 */
						if ( event.active.gain == 0 )
							isActive = FALSE;
						else
							isActive = TRUE;
			    break;			    
					case SDL_VIDEORESIZE:
					  /* handle resize event */
					  surface = SDL_SetVideoMode( event.resize.w,
								event.resize.h,	SCREEN_BPP, videoFlags );
			    if ( !surface )
					{
				    fprintf( stderr, "Could not get a surface after resize: %s\n", SDL_GetError( ) );
				    Quit( 1 );
					}
			    resizeWindow( event.resize.w, event.resize.h );
			    break;
				case SDL_KEYDOWN:
			    /* handle key presses */
			    handleKeyPress( &event.key.keysym );
			    break;
				case SDL_QUIT:
			    /* handle quit requests */
			    running = FALSE;
			    break;
				default:
			    break;
				}
			}
    
			tickCount = SDL_GetTicks();
			Update(tickCount - lastTickCount);
			lastTickCount = tickCount; 
    	/* draw the scene */
	    if ( isActive )
				drawGLScene( );
			
		}
  
    /* clean ourselves up and exit */
    Quit( 0 );

    /* Should never get here */
    return( 0 );
}

