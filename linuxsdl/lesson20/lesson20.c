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

/* Number of textures to load */
#define NUM_TEXTURES 5

/* This is our SDL surface */
SDL_Surface *surface;

GLfloat xrot;                   /* X Rotation           */
GLfloat yrot;                   /* Y Rotation           */
GLfloat zrot;                   /* Z Rotation           */
GLfloat roll;                   /* Rolling texture      */

GLuint texture[NUM_TEXTURES];   /* Storage For Textures */

int masking = TRUE;  /* Masking toggle          */
int scene   = FALSE; /* Scene toggle            */

int loop;            /* Generic loop variable   */

/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{
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
    SDL_Surface *TextureImage[5]; 

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/logo.bmp" ) ) &&
	 ( TextureImage[1] = SDL_LoadBMP( "data/mask1.bmp" ) ) &&
	 ( TextureImage[2] = SDL_LoadBMP( "data/image1.bmp" ) ) &&
	 ( TextureImage[3] = SDL_LoadBMP( "data/mask2.bmp" ) ) &&
	 ( TextureImage[4] = SDL_LoadBMP( "data/image2.bmp" ) ) )
        {

	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( NUM_TEXTURES, &texture[0] );

	    for ( loop = 0; loop < 5; loop++ )
		{
		    /* Typical Texture Generation Using Data From The Bitmap */
		    glBindTexture( GL_TEXTURE_2D, texture[loop] );

		    /* Generate The Texture */
		    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[loop]->w,
				  TextureImage[loop]->h, 0, GL_BGR,
				  GL_UNSIGNED_BYTE,
				  TextureImage[loop]->pixels );

		    /* Linear Filtering */
		    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
				     GL_LINEAR );
		    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
				     GL_LINEAR );
		}
        }

    /* Free up any memory we may have used */
    for ( loop = 0; loop < 5; loop++ )
	if ( TextureImage[loop] )
	    SDL_FreeSurface( TextureImage[loop] );

    return Status;
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

    /*
     * change to the projection matrix and set
     * our viewing volume.
     */
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
	case SDLK_m:
	    /* 'm' key was pressed
	     * toggles masking
	     */
	    masking = !masking;
	    break;
	case SDLK_SPACE:
	    /* Spacebar key was pressed
	     * toggles the scene to display
	     */
	    scene = !scene;
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

    /* Load in the texture */
    if ( !LoadGLTextures( ) )
	return FALSE;

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* Enables Depth Testing */
    glEnable( GL_DEPTH_TEST );

    /* Enables Smooth Color Shading */
    glShadeModel( GL_SMOOTH );

    /* Enable 2D Texture Mapping */
    glEnable( GL_TEXTURE_2D );

    return( TRUE );
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    /* Move Into The Screen 5 Units */
    glLoadIdentity( );
    glTranslatef( 0.0f, 0.0f, -2.0f );

    /* Select Our Logo Texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );
    glBegin( GL_QUADS ); /* Start Drawing A Textured Quad */
      glTexCoord2f( 0.0f, -roll + 3.0f ); glVertex3f( -1.1f, -1.1f,  0.0f );
      glTexCoord2f( 3.0f, -roll + 3.0f ); glVertex3f(  1.1f, -1.1f,  0.0f );
      glTexCoord2f( 3.0f, -roll + 0.0f ); glVertex3f(  1.1f,  1.1f,  0.0f );
      glTexCoord2f( 0.0f, -roll + 0.0f ); glVertex3f( -1.1f,  1.1f,  0.0f );
    glEnd( );

    /* Enable Blending */
    glEnable( GL_BLEND );
    /* Disable Depth Testing */
    glDisable( GL_DEPTH_TEST );

    /* Is masking enables */
    if ( masking )
	glBlendFunc( GL_DST_COLOR, GL_ZERO );

    /* Draw the second scene? */
    if ( scene )
	{
	    /* Translate Into The Screen One Unit */
	    glTranslatef( 0.0f, 0.0f, -1.0f );
	    /* Rotate On The Z Axis 360 Degrees */
	    glRotatef( roll * 360, 0.0f, 0.0f, 1.0f );

	    if ( masking )
		{
		    /* Select The Second Mask Texture */
		    glBindTexture( GL_TEXTURE_2D, texture[3] );
		    /* Start Drawing A Textured Quad */
		    glBegin( GL_QUADS );
		      glTexCoord2f( 0.0f, 1.0f );
		      glVertex3f( -1.1f, -1.1f,  0.0f);
		      glTexCoord2f( 1.0f, 1.0f );
		      glVertex3f( 1.1f, -1.1f,  0.0f );
		      glTexCoord2f( 1.0f, 0.0f );
		      glVertex3f( 1.1f,  1.1f,  0.0f );
		      glTexCoord2f( 0.0f, 0.0f );
		      glVertex3f( -1.1f,  1.1f,  0.0f );
		    glEnd( );

		}

	    /* Copy Image 2 Color To The Screen */
	    glBlendFunc( GL_ONE, GL_ONE );
	    /* Select The Second Image Texture */
	    glBindTexture( GL_TEXTURE_2D, texture[4] );
	    /* Start Drawing A Textured Quad */
	    glBegin( GL_QUADS );
	      glTexCoord2f( 0.0f, 1.0f );
	      glVertex3f( -1.1f, -1.1f, 0.0f );
	      glTexCoord2f( 1.0f, 1.0f );
	      glVertex3f( 1.1f, -1.1f, 0.0f );
	      glTexCoord2f( 1.0f, 0.0f );
	      glVertex3f( 1.1f, 1.1f, 0.0f );
	      glTexCoord2f( 0.0f, 0.0f );
	      glVertex3f( -1.1f, 1.1f, 0.0f );
	    glEnd( );
        }
    else
	{
	    if ( masking )
		{
		    /* Select The First Mask Texture */
		    glBindTexture( GL_TEXTURE_2D, texture[1] );
		    /* Start Drawing A Textured Quad */
		    glBegin( GL_QUADS );
		      glTexCoord2f( roll + 0.0f, 4.0f );
		      glVertex3f( -1.1f, -1.1f, 0.0f );
		      glTexCoord2f( roll + 4.0f, 4.0f );
		      glVertex3f( 1.1f, -1.1f, 0.0f );
		      glTexCoord2f( roll + 4.0f, 0.0f );
		      glVertex3f( 1.1f, 1.1f, 0.0f);
		      glTexCoord2f( roll + 0.0f, 0.0f );
		      glVertex3f( -1.1f, 1.1f, 0.0f );
		    glEnd( );
                }

	    /* Copy Image 1 Color To The Screen */
	    glBlendFunc( GL_ONE, GL_ONE );
	    /* Select The First Image Texture */
	    glBindTexture( GL_TEXTURE_2D, texture[2] );
	    /* Start Drawing A Textured Quad */
	    glBegin( GL_QUADS );
	      glTexCoord2f( roll + 0.0f, 4.0f );
	      glVertex3f( -1.1f, -1.1f, 0.0f);
	      glTexCoord2f( roll + 4.0f, 4.0f );
	      glVertex3f( 1.1f, -1.1f, 0.0f );
	      glTexCoord2f( roll + 4.0f, 0.0f );
	      glVertex3f( 1.1f, 1.1f, 0.0f);
	      glTexCoord2f( roll + 0.0f, 0.0f );
	      glVertex3f( -1.1f, 1.1f, 0.0f );
	    glEnd( );
        }

    glEnable( GL_DEPTH_TEST ); /* Enable Depth Testing */
    glDisable( GL_BLEND );     /* Disable Blending     */

    roll += 0.002f; /* Increase Our Texture Roll Variable */
    if ( roll > 1.0f )
	roll -= 1.0f;

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

    /* the flags to pass to SDL_SetVideoMode                            */
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
