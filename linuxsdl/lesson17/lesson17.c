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
#include <string.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "SDL.h"

/* screen width, height, and bit depth */
#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define SCREEN_BPP     16

/* Setup our booleans */
#define TRUE  1
#define FALSE 0

/* Number of textures to load */
#define NUM_TEXTURES 2

/* This is our SDL surface */
SDL_Surface *surface;

GLuint  base;                  /* Base Display List For The Font           */
GLuint  texture[NUM_TEXTURES]; /* Storage For Our Font Texture             */
GLuint  loop;                  /* Generic Loop Variable                    */

GLfloat cnt1;                  /* Counter Used To Move Text & For Coloring */
GLfloat cnt2;                  /* Counter Used To Move Text & For Coloring */


/* function to recover memory form our list of characters */
GLvoid KillFont( GLvoid )
{
    glDeleteLists( base, 256 ); /* Delete All 256 Display Lists */

    return;
}

/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{

    /* Clean up our font list */
    KillFont( );

    /* Clean up our textures */
    glDeleteTextures( NUM_TEXTURES, &texture[0] );

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
    SDL_Surface *TextureImage[2];

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/font.bmp" ) ) && 
	 ( TextureImage[1] = SDL_LoadBMP( "data/bumps.bmp" ) ) )
        {

	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( NUM_TEXTURES, &texture[0] );

	    /* Load in texture 1 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[0] );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0]->w,
			  TextureImage[0]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[0]->pixels );
	    
	    /* Nearest Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

	    /* Load in texture 2 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[1] );

	    /* Linear Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[1]->w,
			  TextureImage[1]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[1]->pixels );
        }

    /* Free up any memory we may have used */
    if ( TextureImage[0] )
	SDL_FreeSurface( TextureImage[0] );
    if ( TextureImage[1] )
	SDL_FreeSurface( TextureImage[1] );

    return Status;
}

/* function to build our font list */
GLvoid BuildFont( GLvoid )
{
    GLuint loop; /* Loop variable               */
    float cx;    /* Holds Our X Character Coord */
    float cy;    /* Holds Our Y Character Coord */

    /* Creating 256 Display List */
    base  = glGenLists( 256 );
    /* Select Our Font Texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    /* Loop Through All 256 Lists */
    for ( loop = 0; loop < 256; loop++ )
        {
	    /* NOTE:
	     *  BMPs are stored with the top-leftmost pixel being the
	     * last byte and the bottom-rightmost pixel being the first
	     * byte. So an image that is displayed as
	     *    1 0
	     *    0 0
	     * is represented data-wise like
	     *    0 0
	     *    0 1
	     * And because SDL_LoadBMP loads the raw data without
	     * translating to how it is thought of when viewed we need
	     * to start at the bottom-right corner of the data and work
	     * backwards to get everything properly. So the below code has
	     * been modified to reflect this. Examine how this is done and
	     * how the original tutorial is done to grasp the differences.
	     *
	     * As a side note BMPs are also stored as BGR instead of RGB
	     * and that is why we load the texture using GL_BGR. It's
	     * bass-ackwards I know but whattaya gonna do?
	     */

	    /* X Position Of Current Character */
	    cx = 1 - ( float )( loop % 16 ) / 16.0f;
	    /* Y Position Of Current Character */
	    cy = 1 - ( float )( loop / 16 ) / 16.0f;

            /* Start Building A List */
	    glNewList( base + ( 255 - loop ), GL_COMPILE );
	      /* Use A Quad For Each Character */
	      glBegin( GL_QUADS );
	        /* Texture Coord (Bottom Left) */
	        glTexCoord2f( cx - 0.0625, cy );
		/* Vertex Coord (Bottom Left) */
		glVertex2i( 0, 0 );

		/* Texture Coord (Bottom Right) */
		glTexCoord2f( cx, cy );
		/* Vertex Coord (Bottom Right) */
		glVertex2i( 16, 0 );

		/* Texture Coord (Top Right) */
		glTexCoord2f( cx, cy - 0.0625f );
		/* Vertex Coord (Top Right) */
		glVertex2i( 16, 16 );

		/* Texture Coord (Top Left) */
		glTexCoord2f( cx - 0.0625f, cy - 0.0625f);
		/* Vertex Coord (Top Left) */
		glVertex2i( 0, 16 );
	      glEnd( );

	      /* Move To The Left Of The Character */
	      glTranslated( 10, 0, 0 );
	    glEndList( );
        }
}

/* function to reset our viewport after a window resize */
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

    /* Load in the textures */
    if ( !LoadGLTextures( ) )
	return FALSE;

    /* Build our font list */
    BuildFont( );

    /* Enable smooth shading */
    glShadeModel( GL_SMOOTH );

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* The Type Of Depth Test To Do */
    glDepthFunc( GL_LEQUAL );

    /* Select The Type Of Blending */
    glBlendFunc( GL_SRC_ALPHA, GL_ONE );

    /* Enable 2D Texture Mapping */
    glEnable( GL_TEXTURE_2D );
    
    return( TRUE );
}

/* Function to print the string */
GLvoid glPrint( GLint x, GLint y, char *string, int set )
{
    if ( set > 1 )
	set = 1;

    /* Select our texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    /* Disable depth testing */
    glDisable( GL_DEPTH_TEST );

    /* Select The Projection Matrix */
    glMatrixMode( GL_PROJECTION );
    /* Store The Projection Matrix */
    glPushMatrix( );

    /* Reset The Projection Matrix */
    glLoadIdentity( );
    /* Set Up An Ortho Screen */
    glOrtho( 0, 640, 0, 480, -1, 1 );

    /* Select The Modelview Matrix */
    glMatrixMode( GL_MODELVIEW );
    /* Stor the Modelview Matrix */
    glPushMatrix( );
    /* Reset The Modelview Matrix */
    glLoadIdentity( );

    /* Position The Text (0,0 - Bottom Left) */
    glTranslated( x, y, 0 );

    /* Choose The Font Set (0 or 1) */
    glListBase( base - 32 + ( 128 * set ) );

    /* Write The Text To The Screen */
    glCallLists( strlen( string ), GL_BYTE, string );

    /* Select The Projection Matrix */
    glMatrixMode( GL_PROJECTION );
    /* Restore The Old Projection Matrix */
    glPopMatrix( );

    /* Select the Modelview Matrix */
    glMatrixMode( GL_MODELVIEW );
    /* Restore the Old Projection Matrix */
    glPopMatrix( );

    /* Re-enable Depth Testing */
    glEnable( GL_DEPTH_TEST );
}


/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glLoadIdentity( );

    /* Select Our Second Texture */
    glBindTexture( GL_TEXTURE_2D, texture[1] );
    /* Move Into The Screen 5 Units */
    glTranslatef( 0.0f, 0.0f, -5.0f );
    /* Rotate On The Z Axis 45 Degrees (Clockwise) */
    glRotatef( 45.0f, 0.0f, 0.0f, 1.0f );
    /* Rotate On The X & Y Axis By cnt1 (Left To Right) */
    glRotatef( cnt1 * 30.0f, 1.0f, 1.0f, 0.0f );

    /* Disable Blending Before We Draw In 3D */
    glDisable( GL_BLEND );
    glColor3f( 1.0f, 1.0f, 1.0f ); /* Bright White                       */
    glBegin( GL_QUADS );           /* Draw Our First Texture Mapped Quad */
      glTexCoord2d( 0.0f,  0.0f ); /* First Texture Coord                */
      glVertex2f(  -1.0f,  1.0f ); /* First Vertex                       */
      glTexCoord2d( 1.0f,  0.0f ); /* Second Texture Coord               */
      glVertex2f(   1.0f,  1.0f ); /* Second Vertex                      */
      glTexCoord2d( 1.0f,  1.0f ); /* Third Texture Coord                */
      glVertex2f(   1.0f, -1.0f ); /* Third Vertex                       */
      glTexCoord2d( 0.0f,  1.0f ); /* Fourth Texture Coord               */
      glVertex2f(  -1.0f, -1.0f ); /* Fourth Vertex                      */
    glEnd( );

    /* Rotate On The X & Y Axis By 90 Degrees (Left To Right) */
    glRotatef( 90.0f, 1.0f, 1.0f, 0.0f );
    glBegin( GL_QUADS );           /* Draw Our Second Texture Mapped Quad */
      glTexCoord2d( 0.0f,  0.0f ); /* First Texture Coord                 */
      glVertex2f(  -1.0f,  1.0f ); /* First Vertex                        */
      glTexCoord2d( 1.0f,  0.0f ); /* Second Texture Coord                */
      glVertex2f(   1.0f,  1.0f ); /* Second Vertex                       */
      glTexCoord2d( 1.0f,  1.0f ); /* Third Texture Coord                 */
      glVertex2f(   1.0f, -1.0f ); /* Third Vertex                        */
      glTexCoord2d( 0.0f,  1.0f ); /* Fourth Texture Coord                */
      glVertex2f(  -1.0f, -1.0f ); /* Fourth Vertex                       */
    glEnd( );

    /* Re-enable Blending */
    glEnable( GL_BLEND );
    /* Reset the view */
    glLoadIdentity( );


    /* Pulsing Colors Based On Text Position */
    /* Print GL Text To The Screen */
    glColor3f( 1.0f * ( float )cos( cnt1 ),
	       1.0f * ( float )sin( cnt2 ),
	       1.0f - 0.5f * ( float )cos( cnt1 + cnt2 ) );
    glPrint( ( int )( 280 + 250 * cos( cnt1 ) ),
	     ( int )( 235 + 200 * sin( cnt2 ) ),
	     "NeHe", 0 );
    glColor3f( 1.0f * ( float )sin( cnt2 ),
	       1.0f - 0.5f * ( float )cos( cnt1 + cnt2 ),
	       1.0f * ( float )cos( cnt1 ) );
    glPrint( ( int )( 280 + 230 * cos( cnt2 ) ),
	     ( int )( 235 + 200 * sin( cnt1 ) ),
	     "OpenGL", 1 );

    /* Set Color to Red */
    glColor3f( 0.0f, 0.0f, 1.0f );
    /* Draw Text To The Screen */
    glPrint( ( int )( 240 + 200 * cos( ( cnt2 + cnt1 ) / 5 ) ), 2,
	     "Giuseppe D'Agata", 0 );

    /* Set Color To White */
    glColor3f( 1.0f, 1.0f, 1.0f );
    /* Draw Offset Text To The Screen */
    glPrint( ( int )( 242 + 200 * cos( ( cnt2 + cnt1 ) / 5 ) ), 2,
	     "Giuseppe D'Agata", 0 );

    cnt1 += 0.01f;   /* Increase The First Counter  */
    cnt2 += 0.0081f; /* Increase The Second Counter */

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
    videoFlags  = SDL_OPENGL;          /* Enable OpenGL in SDL          */
    videoFlags |= SDL_GL_DOUBLEBUFFER; /* Enable double buffering       */
    videoFlags |= SDL_HWPALETTE;       /* Store the palette in hardware */
    videoFlags |= SDL_RESIZABLE;       /* Enable window resizing        */

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

    /* Enable key repeat */
    if ( ( SDL_EnableKeyRepeat( 100, SDL_DEFAULT_REPEAT_INTERVAL ) ) )
	{
	    fprintf( stderr, "Setting keyboard repeat failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
	}

    /* initialize OpenGL */
    if ( initGL( ) == FALSE )
	{
	    fprintf( stderr, "Could not initialize OpenGL.\n" );
	    Quit( 1 );
	}

    /* Resize the initial window */
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
