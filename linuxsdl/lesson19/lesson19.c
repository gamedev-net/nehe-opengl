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

/* Setup our booleans */
#define TRUE  1
#define FALSE 0

/* Max number of particles */
#define MAX_PARTICLES 1000

/* This is our SDL surface */
SDL_Surface *surface;

int rainbow = TRUE;    /* Toggle rainbow effect                              */

float slowdown = 2.0f; /* Slow Down Particles                                */
float xspeed;          /* Base X Speed (To Allow Keyboard Direction Of Tail) */
float yspeed;          /* Base Y Speed (To Allow Keyboard Direction Of Tail) */
float zoom = -40.0f;   /* Used To Zoom Out                                   */

GLuint loop;           /* Misc Loop Variable                                 */
GLuint col = 0;        /* Current Color Selection                            */
GLuint delay;          /* Rainbow Effect Delay                               */
GLuint texture[1];     /* Storage For Our Particle Texture                   */

/* Create our particle structure */
typedef struct
{
    int   active; /* Active (Yes/No) */
    float life;   /* Particle Life   */
    float fade;   /* Fade Speed      */

    float r;      /* Red Value       */
    float g;      /* Green Value     */
    float b;      /* Blue Value      */

    float x;      /* X Position      */
    float y;      /* Y Position      */
    float z;      /* Z Position      */

    float xi;     /* X Direction     */
    float yi;     /* Y Direction     */
    float zi;     /* Z Direction     */

    float xg;     /* X Gravity       */
    float yg;     /* Y Gravity       */
    float zg;     /* Z Gravity       */
} particle;

/* Rainbow of colors */
static GLfloat colors[12][3] =
{
        { 1.0f,  0.5f,  0.5f},
	{ 1.0f,  0.75f, 0.5f},
	{ 1.0f,  1.0f,  0.5f},
	{ 0.75f, 1.0f,  0.5f},
        { 0.5f,  1.0f,  0.5f},
	{ 0.5f,  1.0f,  0.75f},
	{ 0.5f,  1.0f,  1.0f},
	{ 0.5f,  0.75f, 1.0f},
        { 0.5f,  0.5f,  1.0f},
	{ 0.75f, 0.5f,  1.0f},
	{ 1.0f,  0.5f,  1.0f},
	{ 1.0f,  0.5f,  0.75f}
};

/* Our beloved array of particles */
particle particles[MAX_PARTICLES];


/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{
    /* Clean up our textures */
    glDeleteTextures( 1, &texture[0] );

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
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/particle.bmp" ) ) )
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
    gluPerspective( 45.0f, ratio, 0.1f, 200.0f );

    /* Make sure we're chaning the model view and not the projection */
    glMatrixMode( GL_MODELVIEW );

    /* Reset The View */
    glLoadIdentity( );

    return( TRUE );
}

/* function to reset one particle to initial state */
/* NOTE: I added this function to replace doing the same thing in several
 * places and to also make it easy to move the pressing of numpad keys
 * 2, 4, 6, and 8 into handleKeyPress function.
 */
void ResetParticle( int num, int color, float xDir, float yDir, float zDir )
{
    /* Make the particels active */
    particles[num].active = TRUE;
    /* Give the particles life */
    particles[num].life = 1.0f;
    /* Random Fade Speed */
    particles[num].fade = ( float )( rand( ) %100 ) / 1000.0f + 0.003f;
    /* Select Red Rainbow Color */
    particles[num].r = colors[color][0];
    /* Select Green Rainbow Color */
    particles[num].g = colors[color][1];
    /* Select Blue Rainbow Color */
    particles[num].b = colors[color][2];
    /* Set the position on the X axis */
    particles[num].x = 0.0f;
    /* Set the position on the Y axis */
    particles[num].y = 0.0f;
    /* Set the position on the Z axis */
    particles[num].z = 0.0f;
    /* Random Speed On X Axis */
    particles[num].xi = xDir;
    /* Random Speed On Y Axi */
    particles[num].yi = yDir;
    /* Random Speed On Z Axis */
    particles[num].zi = zDir;
    /* Set Horizontal Pull To Zero */
    particles[num].xg = 0.0f;
    /* Set Vertical Pull Downward */
    particles[num].yg = -0.8f;
    /* Set Pull On Z Axis To Zero */
    particles[num].zg = 0.0f;

    return;
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
	case SDLK_KP_PLUS:
	    /* '+' key was pressed
	     * this speeds up the particles
	     */
	    if ( slowdown > 1.0f )
		slowdown -= 0.01f;
	    break;
	case SDLK_KP_MINUS:
	    /* '-' key was pressed
	     * this slows down the particles
	     */
	    if ( slowdown < 4.0f )
		slowdown += 0.01f;
	case SDLK_PAGEUP:
	    /* PageUp key was pressed
	     * this zooms into the scene
	     */
	    zoom += 0.01f;
	    break;
	case SDLK_PAGEDOWN:
	    /* PageDown key was pressed
	     * this zooms out of the scene
	     */
	    zoom -= 0.01f;
	    break;
	case SDLK_UP:
	    /* Up arrow key was pressed
	     * this increases the particles' y movement
	     */
	    if ( yspeed < 200.0f )
		yspeed++;
	    break;
	case SDLK_DOWN:
	    /* Down arrow key was pressed
	     * this decreases the particles' y movement
	     */
	    if ( yspeed > -200.0f )
		yspeed--;
	    break;
	case SDLK_RIGHT:
	    /* Right arrow key was pressed
	     * this increases the particles' x movement
	     */
	    if ( xspeed < 200.0f )
		xspeed++;
	    break;
	case SDLK_LEFT:
	    /* Left arrow key was pressed
	     * this decreases the particles' x movement
	     */
	    if ( xspeed > -200.0f )
		xspeed--;
	    break;
	case SDLK_KP8:
	    /* NumPad 8 key was pressed
	     * increase particles' y gravity
	     */
	    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
		if ( particles[loop].yg < 1.5f )
		    particles[loop].yg += 0.01f;
	    break;
	case SDLK_KP2:
	    /* NumPad 2 key was pressed
	     * decrease particles' y gravity
	     */
	    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
		if ( particles[loop].yg > -1.5f )
		    particles[loop].yg -= 0.01f;
	    break;
	case SDLK_KP6:
	    /* NumPad 6 key was pressed
	     * this increases the particles' x gravity
	     */
	    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
		if ( particles[loop].xg < 1.5f )
		    particles[loop].xg += 0.01f;
	    break;
	case SDLK_KP4:
	    /* NumPad 4 key was pressed
	     * this decreases the particles' y gravity
	     */
	    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
		if ( particles[loop].xg > -1.5f )
		    particles[loop].xg -= 0.01f;
	    break;
	case SDLK_TAB:
	    /* Tab key was pressed
	     * this resets the particles and makes them re-explode
	     */
	    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
		{
		   int color = ( loop + 1 ) / ( MAX_PARTICLES / 12 );
		   float xi, yi, zi;
		   xi = ( float )( ( rand( ) % 50 ) - 26.0f ) * 10.0f;
		   yi = zi = ( float )( ( rand( ) % 50 ) - 25.0f ) * 10.0f;

		   ResetParticle( loop, color, xi, yi, zi );
		}
	    break;
	case SDLK_RETURN:
	    /* Return key was pressed
	     * this toggles the rainbow color effect
	     */
	    rainbow = !rainbow;
	    delay = 25;
	    break;
	case SDLK_SPACE:
	    /* Spacebar was pressed
	     * this turns off rainbow-ing and manually cycles through colors
	     */
	    rainbow = FALSE;
	    delay = 0;
	    col = ( ++col ) % 12;
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

    /* Enable smooth shading */
    glShadeModel( GL_SMOOTH );

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* Enables Depth Testing */
    glDisable( GL_DEPTH_TEST );

    /* Enable Blending */
    glEnable( GL_BLEND );
    /* Type Of Blending To Perform */
    glBlendFunc( GL_SRC_ALPHA, GL_ONE );

    /* Really Nice Perspective Calculations */
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
    /* Really Nice Point Smoothing */
    glHint( GL_POINT_SMOOTH_HINT, GL_NICEST );

    /* Enable Texture Mapping */
    glEnable( GL_TEXTURE_2D );
    /* Select Our Texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    /* Reset all the particles */
    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
	{
	    int color = ( loop + 1 ) / ( MAX_PARTICLES / 12 );
	    float xi, yi, zi;
	    xi =  ( float )( ( rand( ) % 50 ) - 26.0f ) * 10.0f;
	    yi = zi = ( float )( ( rand( ) % 50 ) - 25.0f ) * 10.0f;

	    ResetParticle( loop, color, xi, yi, zi );
        }

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

    glLoadIdentity( );

    /* Modify each of the particles */
    for ( loop = 0; loop < MAX_PARTICLES; loop++ )
	{
	    if ( particles[loop].active )
		{
		    /* Grab Our Particle X Position */
		    float x = particles[loop].x;
		    /* Grab Our Particle Y Position */
		    float y = particles[loop].y;
		    /* Particle Z Position + Zoom */
		    float z = particles[loop].z + zoom;

		    /* Draw The Particle Using Our RGB Values,
		     * Fade The Particle Based On It's Life
		     */
		    glColor4f( particles[loop].r,
			       particles[loop].g,
			       particles[loop].b,
			       particles[loop].life );

		    /* Build Quad From A Triangle Strip */
		    glBegin( GL_TRIANGLE_STRIP );
		      /* Top Right */
		      glTexCoord2d( 1, 1 );
		      glVertex3f( x + 0.5f, y + 0.5f, z );
		      /* Top Left */
		      glTexCoord2d( 0, 1 );
		      glVertex3f( x - 0.5f, y + 0.5f, z );
		      /* Bottom Right */
		      glTexCoord2d( 1, 0 );
		      glVertex3f( x + 0.5f, y - 0.5f, z );
		      /* Bottom Left */
		      glTexCoord2d( 0, 0 );
		      glVertex3f( x - 0.5f, y - 0.5f, z );
		    glEnd( );

		    /* Move On The X Axis By X Speed */
		    particles[loop].x += particles[loop].xi /
			( slowdown * 1000 );
		    /* Move On The Y Axis By Y Speed */
		    particles[loop].y += particles[loop].yi /
			( slowdown * 1000 );
		    /* Move On The Z Axis By Z Speed */
		    particles[loop].z += particles[loop].zi /
			( slowdown * 1000 );

		    /* Take Pull On X Axis Into Account */
		    particles[loop].xi += particles[loop].xg;
		    /* Take Pull On Y Axis Into Account */
		    particles[loop].yi += particles[loop].yg;
		    /* Take Pull On Z Axis Into Account */
		    particles[loop].zi += particles[loop].zg;

		    /* Reduce Particles Life By 'Fade' */
		    particles[loop].life -= particles[loop].fade;

		    /* If the particle dies, revive it */
		    if ( particles[loop].life < 0.0f )
			{
			    float xi, yi, zi;
			    xi = xspeed +
				( float )( ( rand( ) % 60 ) - 32.0f );
			    yi = yspeed +
				( float)( ( rand( ) % 60 ) - 30.0f );
			    zi = ( float )( ( rand( ) % 60 ) - 30.0f );
			    ResetParticle( loop, col, xi, yi, zi );
                        }
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

	    /* If rainbow coloring is turned on, cycle the colors */
	    if ( rainbow && ( delay > 25 ) )
		col = ( ++col ) % 12;

	    /* draw the scene */
	    if ( isActive )
		drawGLScene( );

	    delay++;
	}

    /* clean ourselves up and exit */
    Quit( 0 );

    /* Should never get here */
    return( 0 );
}
