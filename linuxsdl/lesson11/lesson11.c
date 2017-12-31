/*
 * This code was created by Jeff Molofee '99 
 * (ported to Linux/SDL by Ti Leggett '01)
 *
 * If you've found this code useful, please let me know.
 *
 * Visit Jeff at http://nehe.gamedev.net/
 * 
 * or for port-specific comments, questions, bugreports etc. 
 * email to leggett@eecs.tulane.edu
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "SDL.h"

/* screen width, height, and bit depth */
#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define SCREEN_BPP     16

/* Set up some booleans */
#define TRUE  1
#define FALSE 0

/* This is our SDL surface */
SDL_Surface *surface;

GLfloat xrot;            /* X Rotation */
GLfloat yrot;            /* Y Rotation */
GLfloat zrot;            /* Z Rotation */

float points[45][45][3]; /* The Points On The Grid Of Our "Wave" */
int wiggle_count = 0;    /* Counter Used To Control How Fast Flag Waves */
GLfloat hold;            /* Temporarily Holds A Floating Point Value */

GLuint texture[1];       /* Storage For One Texture */

/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{
    /* clean up the window */
    SDL_Quit( );

    /* and exit appropriately */
    exit( returnCode );
}

/* function to load in bitmap as a GL texture */
int LoadGLTextures( )
{
    /* Status indicator */
    int Status = FALSE;

    /* Create storage space for the texture */
    SDL_Surface *TextureImage[1]; 

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/tim.bmp" ) ) )
        {

	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( 1, &texture[0] );

	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[0] );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0]->w,
			  TextureImage[0]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[0]->pixels );

	    /* Linear Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
        }

    /* Free up any memory we may have used */
    if ( TextureImage[0] )
	    SDL_FreeSurface( TextureImage[0] );

    return Status;
}

/* to resize the window and reset our view */
int resizeWindow( int width, int height )
{
    /* Height / width ration */
    GLfloat ratio;

    /* Protect against a divide by zero */
    if ( height == 0 )
	height = 1;

    ratio = ( GLfloat )width / ( GLfloat )height;

    /* Setup our viewport. */
    glViewport( 0, 0, ( GLint )width, ( GLint )height );

    /* change to the projection matrix and set our viewing volume. */
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity( );

    /* Set our perspective */
    gluPerspective( 45.0f, ratio, 0.1f, 100.0f );

    /* Make sure we're chaning the model view and not the projection */
    glMatrixMode( GL_MODELVIEW );

    /* Reset The View */
    glLoadIdentity( );

    return( TRUE );
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
	default:
	    break;
	}

    return;
}

/* general OpenGL initialization function */
int initGL( GLvoid )
{
    int x, y; /* Loop variables */

    /* Load in the texture */
    if ( !LoadGLTextures( ) )
	return FALSE;

    /* Enable Texture Mapping ( NEW ) */
    glEnable( GL_TEXTURE_2D );

    /* Enable smooth shading */
    glShadeModel( GL_SMOOTH );

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* Enables Depth Testing */
    glEnable( GL_DEPTH_TEST );

    /* The Type Of Depth Test To Do */
    glDepthFunc( GL_LEQUAL );

    /* Really Nice Perspective Calculations */
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

    /* Fill the back with the texture. The front will only be wireline */
    glPolygonMode( GL_BACK, GL_FILL );
    glPolygonMode( GL_FRONT, GL_LINE );

    /* Loop Through The X Plane */
    for ( x = 0; x < 45; x++ )
        {
	    /* Loop Through The Y Plane */
	    for ( y = 0; y < 45; y++ )
                {
		    /* Apply The Wave To Our Mesh */
		    points[x][y][0] = ( float )( ( x / 5.0f ) - 4.5f );
		    points[x][y][1] = ( float )( ( y / 5.0f ) - 4.5f );
		    points[x][y][2] = ( float )( sin( ( ( ( x / 5.0f ) * 40.0f ) / 360.0f ) * 3.141592654 * 2.0f ) );
                }
        }

    return( TRUE );
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    int x, y;                   /* Loop Variables */
    float f_x, f_y, f_xb, f_yb; /* Used To Break The Flag Into Tiny Quads */
 
    /* Clear The Screen And Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    /* Reset The Current Matrix */
    glLoadIdentity( );

    /* Translate 17 Units Into The Screen */
    glTranslatef( 0.0f, 0.0f, -12.0f );

    glRotatef( xrot, 1.0f, 0.0f, 0.0f ); /* Rotate On The X Axis */
    glRotatef( yrot, 0.0f, 1.0f, 0.0f ); /* Rotate On The Y Axis */
    glRotatef( zrot, 0.0f, 0.0f, 1.0f ); /* Rotate On The Z Axis */

    glBindTexture( GL_TEXTURE_2D, texture[0] ); /* Select Our Texture */

    /* Start Drawing Our Quads */
    glBegin( GL_QUADS );
    /* Loop Through The X Plane 0-44 (45 Points) */
    for( x = 0; x < 44; x++ )
	{
	    /* Loop Through The Y Plane 0-44 (45 Points) */
	    for( y = 0; y < 44; y++ )
		{
		    /* Create A Floating Point X Value */
		    f_x = ( float )x / 44.0f;
		    /* Create A Floating Point Y Value */
		    f_y = ( float )y / 44.0f;
		    /* Create A Floating Point Y Value+0.0227f */
		    f_xb = ( float )( x + 1 ) / 44.0f;
		    /* Create A Floating Point Y Value+0.0227f */
		    f_yb = ( float )( y + 1 ) / 44.0f;

		    /* First Texture Coordinate (Bottom Left) */
		    glTexCoord2f( f_x, f_y );
		    glVertex3f( points[x][y][0], points[x][y][1],
				points[x][y][2] );

		    /* Second Texture Coordinate (Top Left) */
		    glTexCoord2f( f_x, f_yb );
		    glVertex3f( points[x][y + 1][0], points[x][y + 1][1],
				points[x][y + 1][2] );

		    /* Third Texture Coordinate (Top Right) */
		    glTexCoord2f( f_xb, f_yb );
		    glVertex3f( points[x + 1][y + 1][0],
				points[x + 1][y + 1][1],
				points[x + 1][y + 1][2] );

		    /* Fourth Texture Coordinate (Bottom Right) */
		    glTexCoord2f( f_xb, f_y );
		    glVertex3f( points[x + 1][y][0], points[x + 1][y][1],
				points[x + 1][y][2] );
                }
        }
    glEnd( );

    /* Used To Slow Down The Wave (Every 2nd Frame Only) */
    if( wiggle_count == 2 )
        {
	    /* Loop Through The Y Plane */
	    for( y = 0; y < 45; y++ )
		{
		    /* Store Current Value One Left Side Of Wave */
		    hold = points[0][y][2];
		    /* Loop Through The X Plane */
		    for( x = 0; x < 44; x++)
			{
                            /* Current Wave Value Equals Value To The Right */
			    points[x][y][2] = points[x + 1][y][2];
                        }
		    /* Last Value Becomes The Far Left Stored Value */
		    points[44][y][2] = hold;
                }
	    wiggle_count = 0; /* Set Counter Back To Zero */
        }
    wiggle_count++; /* Increase The Counter */

    xrot += 0.3f; /* Increase The X Rotation Variable */
    yrot += 0.2f; /* Increase The Y Rotation Variable */
    zrot += 0.4f; /* Increase The Z Rotation Variable */

    /* Draw it to the screen */
    SDL_GL_SwapBuffers( );

    /* Gather our frames per second */
    Frames++;
    {
	GLint t = SDL_GetTicks();
	if (t - T0 >= 5000) {
	    GLfloat seconds = (t - T0) / 1000.0;
	    GLfloat fps = Frames / seconds;
	    printf("%d frames in %g seconds = %g FPS\n", Frames, seconds, fps);
	    T0 = t;
	    Frames = 0;
	}
    }

    xrot += 0.3f; /* X Axis Rotation */
    yrot += 0.2f; /* Y Axis Rotation */
    zrot += 0.4f; /* Z Axis Rotation */

    return( TRUE );
}

int main( int argc, char **argv )
{
    /* Flags to pass to SDL_SetVideoMode */
    int videoFlags;
    /* main loop variable */
    int done = FALSE;
    /* used to collect events */
    SDL_Event event;
    /* this holds some info about our display */
    const SDL_VideoInfo *videoInfo;
    /* whether or not the window is active */
    int isActive = TRUE;

    /* initialize SDL */
    if ( SDL_Init( SDL_INIT_VIDEO ) < 0 )
	{
	    fprintf( stderr, "Video initialization failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
	}

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

    /* initialize OpenGL */
    initGL( );

    /* resize the initial window */
    resizeWindow( SCREEN_WIDTH, SCREEN_HEIGHT );

    /* wait for events */
    while ( !done )
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
							event.resize.h,
							16, videoFlags );
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
			    done = TRUE;
			    break;
			default:
			    break;
			}
		}

	    /* draw the scene */
	    if ( isActive )
		drawGLScene( );
	}

    /* clean ourselves up and exit */
    Quit( 0 );

    /* Should never get here */
    return( 0 );
}
