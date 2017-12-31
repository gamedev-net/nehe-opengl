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

/* Number of stars */
#define NUM 50

/* This is our SDL surface */
SDL_Surface *surface;

/* Twinkling stars */
int twinkle = FALSE;

/* Define the star structure */
typedef struct
{
    int r, g, b;   /* Stars Color */
    GLfloat dist;  /* Stars Distance From Center */
    GLfloat angle; /* Stars Current Angle */
} star;

star stars[NUM];       /* Make an array of size 'NUM' of stars */

GLfloat zoom = -15.0f; /* Viewing Distance Away From Stars */
GLfloat tilt = 90.0f;  /* Tilt The View */

GLuint loop;           /* General Loop Variable */
GLuint texture[1];     /* Storage For One Texture */


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
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/star.bmp" ) ) )
        {

	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( 1, &texture[0] );

	    /* Load in texture */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[0] );

	    /* Linear Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0]->w,
			  TextureImage[0]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[0]->pixels );

        }

    /* Free up any memory we may have used */
    if ( TextureImage[0] )
	    SDL_FreeSurface( TextureImage[0] );

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
	case SDLK_t:
	    /* 't' key was pressed
	     * this toggles the twinkling of the stars
	     */
	    twinkle = !twinkle;
	    break;
	case SDLK_UP:
	    /* Up arrow key was pressed
	     * this changes the tilt of the stars
	     */
	    tilt -= 0.5f;
	    break;
	case SDLK_DOWN:
	    /* Down arrow key was pressed
	     * this changes the tilt of the stars
	     */
	    tilt += 0.5f;
	    break;
	case SDLK_PAGEUP:
	    /* PageUp key was pressed
	     * zoom into the scene
	     */
	    zoom -= 0.2f;
	    break;
	case SDLK_PAGEDOWN:
	    /* PageDown key was pressed
	     * zoom out of the scene
	     */
	    zoom += 0.2f;
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

    /* Enable Texture Mapping */
    glEnable( GL_TEXTURE_2D );

    /* Enable smooth shading */
    glShadeModel( GL_SMOOTH );

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* Really Nice Perspective Calculations */
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

    /* Set The Blending Function For Translucency */
    glBlendFunc( GL_SRC_ALPHA, GL_ONE );

    /* Enable Blending */
    glEnable( GL_BLEND );

    /* Create A Loop That Goes Through All The Stars */
    for ( loop = 0; loop < NUM; loop++ )
	{
	    /* Start All The Stars At Angle Zero */
	    stars[loop].angle = 0.0f;

	    /* Calculate Distance From The Center */
	    stars[loop].dist = ( ( float )loop / NUM ) * 5.0f;
	    /* Give star[loop] A Random Red Intensity */
	    stars[loop].r = rand( ) % 256;
	    /* Give star[loop] A Random Green Intensity */
	    stars[loop].g = rand( ) % 256;
	    /* Give star[loop] A Random Blue Intensity */
	    stars[loop].b = rand( ) % 256;
        }

    return( TRUE );
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    static int spin = 0;

    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    /* Select Our Texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );
    glLoadIdentity( );

    /* Loop Through All The Stars */
    for ( loop = 0; loop < NUM; loop++ )
        {
	    /* Reset The View Before We Draw Each Star */
	    glLoadIdentity( );
	    /* Zoom Into The Screen (Using The Value In 'zoom') */
	    glTranslatef( 0.0f, 0.0f, zoom );

	    /* Tilt The View (Using The Value In 'tilt') */
	    glRotatef( tilt, 1.0f, 0.0f, 0.0f );
	    /* Rotate To The Current Stars Angle */
	    glRotatef( stars[loop].angle, 0.0f, 1.0f, 0.0f );

	    /* Move Forward On The X Plane */
	    glTranslatef( stars[loop].dist, 0.0f, 0.0f );

	    /* Cancel The Current Stars Angle */
	    glRotatef( -stars[loop].angle, 0.0f, 1.0f, 0.0f );
	    /* Cancel The Screen Tilt */
	    glRotatef( -tilt, 1.0f, 0.0f, 0.0f );

	    /* Twinkling Stars Enabled */
	    if ( twinkle )
                {
		    /* Assign A Color Using Bytes */
		    glColor4ub( stars[( NUM - loop ) - 1].r,
				stars[( NUM - loop ) - 1].g,
				stars[( NUM - loop ) - 1].b, 255 );
		    /* Begin Drawing The Textured Quad */
		    glBegin( GL_QUADS );
		      glTexCoord2f( 0.0f, 0.0f );
		      glVertex3f( -1.0f, -1.0f, 0.0f );
		      glTexCoord2f( 1.0f, 0.0f);
		      glVertex3f( 1.0f, -1.0f, 0.0f );
		      glTexCoord2f( 1.0f, 1.0f );
		      glVertex3f( 1.0f, 1.0f, 0.0f );
		      glTexCoord2f( 0.0f, 1.0f );
		      glVertex3f( -1.0f, 1.0f, 0.0f );
		    glEnd( );
                }

	    /* Rotate The Star On The Z Axis */
	    glRotatef( spin, 0.0f, 0.0f, 1.0f );

	    /* Assign A Color Using Bytes */
	    glColor4ub( stars[loop].r, stars[loop].g, stars[loop].b, 255 );

	    /* Begin Drawing The Textured Quad */
	    glBegin( GL_QUADS );
	      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( -1.0f, -1.0f, 0.0f );
	      glTexCoord2f( 1.0f, 0.0f ); glVertex3f(  1.0f, -1.0f, 0.0f );
	      glTexCoord2f( 1.0f, 1.0f ); glVertex3f(  1.0f,  1.0f, 0.0f );
	      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( -1.0f,  1.0f, 0.0f );
	    glEnd( );

	    /* Used To Spin The Stars */
	    spin += 0.01f;
	    /* Changes The Angle Of A Star */
	    stars[loop].angle += ( float )loop / NUM;
	    /* Changes The Distance Of A Star */
	    stars[loop].dist -= 0.01f;

	    /* Is The Star In The Middle Yet */
	    if ( stars[loop].dist < 0.0f )
                {
		    /* Move The Star 5 Units From The Center */
		    stars[loop].dist += 5.0f;
		    /* Give It A New Red Value */
		    stars[loop].r = rand( ) % 256;
		    /* Give It A New Green Value */
		    stars[loop].g = rand( ) % 256;
		    /* Give It A New Blue Value */
		    stars[loop].b = rand( ) % 256;
                }
        }

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
