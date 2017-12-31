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

/* Comment this out if you don't want sound. */
#define SOUND
 
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "SDL.h"

#ifdef SOUND
#include "SDL_mixer.h"
#endif

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

#ifdef SOUND
/* Our audio chunk */
Mix_Chunk *chunk;
Mix_Music *music;
#endif

int vline[11][10];   /* Keeps Track Of Verticle Lines                */
int hline[10][11];   /* Keeps Track Of Horizontal Lines              */
int filled;          /* Done Filling In The Grid?                    */
int gameover = TRUE; /* Is The Game Over?                            */
int anti     = TRUE; /* Antialiasing?                                */

int loop1;           /* Generic Loop1                                */
int loop2;           /* Generic Loop2                                */
int delay  = 0;      /* Enemy Delay                                  */
int adjust = 3;      /* Speed Adjustment For Really Slow Video Cards */
int lives  = 5;      /* Player Lives                                 */
int level  = 1;      /* Internal Game Level                          */
int level2 = 1;      /* Displayed Game Level                         */
int stage  = 1;      /* Game Stage                                   */

/* Create a structure for our player */
typedef struct
{
    int fx, fy; /* Fine Movement Position  */
    int x, y;   /* Current Player Position */
    float spin; /* Spin Direction          */
} object;

object player;     /* Player Information    */
object enemies[9]; /* Enemy Information     */
object hourglass;  /* Hourglass Information */

/* Stepping Values For Slow Video Adjustment */
int steps[6] = { 1, 2, 4, 5, 10, 20 };

GLuint texture[NUM_TEXTURES]; /* Storage for textures           */
GLuint base;                  /* Base Display List For The Font */

/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{
    /* Clean up our font list */
    glDeleteLists( base, 256 );

    /* Clean up our textures */
    glDeleteTextures( NUM_TEXTURES, &texture[0] );

#ifdef SOUND
    /* Stop playing the music */
    Mix_HaltMusic( );

    /* Free up the memory for the music */
    Mix_FreeMusic( music );

    /* Free up any memory for the sfx */
    Mix_FreeChunk( chunk );

    /* Close our audio device */
    Mix_CloseAudio( );

    /* Close up the sound sub system */
    SDL_QuitSubSystem( SDL_INIT_AUDIO );
#endif

    /* clean up the window */
    SDL_Quit( );

    /* and exit appropriately */
    exit( returnCode );
}

void ResetObjects( void )
{

    player.x  = 0; /* Reset Player X Position To Far Left Of The Screen */
    player.y  = 0; /* Reset Player Y Position To The Top Of The Screen  */
    player.fx = 0; /* Set Fine X Position To Match                      */
    player.fy = 0; /* Set Fine Y Position To Match                      */

    /* Loop Through All The Enemies */
    for ( loop1 = 0; loop1 < ( stage * level ); loop1++ )
        {
	    /* A Random X Position */
	    enemies[loop1].x  = 5 + rand( ) % 6;
	    /* A Random Y Position */
	    enemies[loop1].y  = rand( ) % 11;
	    /* Set Fine X To Match */
	    enemies[loop1].fx = enemies[loop1].x * 60;
	    /* Set Fine Y To Match */
	    enemies[loop1].fy = enemies[loop1].y * 40;
        }
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
	 ( TextureImage[1] = SDL_LoadBMP( "data/image.bmp" ) ) )
        {

	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( NUM_TEXTURES, &texture[0] );

	    /* Loop Through 2 Textures */
	    for ( loop1 = 0; loop1 < NUM_TEXTURES; loop1++ )
		{
		    glBindTexture( GL_TEXTURE_2D, texture[loop1] );
		    glTexImage2D( GL_TEXTURE_2D, 0, 3,
				  TextureImage[loop1]->w,
				  TextureImage[loop1]->h, 0, GL_RGB,
				  GL_UNSIGNED_BYTE,
				  TextureImage[loop1]->pixels );
		    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
				     GL_LINEAR);
		    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
				     GL_LINEAR);
                }

	    /* Loop through 2 local Textures */
	    for ( loop1 = 0; loop1 < 2; loop1++ )
		if ( TextureImage[loop1] )
		    SDL_FreeSurface( TextureImage[loop1] );
	}

    return Status;
}

/* function to build our font list */
GLvoid BuildFont( GLvoid )
{
    float cx;    /* Holds Our X Character Coord */
    float cy;    /* Holds Our Y Character Coord */

    /* Creating 256 Display List */
    base = glGenLists( 256 );
    /* Select Our Font Texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    /* Loop Through All 256 Lists */
    for ( loop1 = 0; loop1 < 256; loop1++ )
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
	    cx = 1 - ( float )( loop1 % 16 ) / 16.0f;
	    /* Y Position Of Current Character */
	    cy = 1 - ( float )( loop1 / 16 ) / 16.0f;

            /* Start Building A List */
	    glNewList( base + ( 255 - loop1 ), GL_COMPILE );
	      /* Use A Quad For Each Character */
	      glBegin( GL_QUADS );
	        /* Texture Coord (Bottom Left) */
	        glTexCoord2f( cx - 0.0625, cy );
		/* Vertex Coord (Bottom Left) */
		glVertex2i( 0, 16 );

		/* Texture Coord (Bottom Right) */
		glTexCoord2f( cx, cy );
		/* Vertex Coord (Bottom Right) */
		glVertex2i( 16, 16 );

		/* Texture Coord (Top Right) */
		glTexCoord2f( cx, cy - 0.0625f );
		/* Vertex Coord (Top Right) */
		glVertex2i( 16, 0 );

		/* Texture Coord (Top Left) */
		glTexCoord2f( cx - 0.0625f, cy - 0.0625f);
		/* Vertex Coord (Top Left) */
		glVertex2i( 0, 0 );
	      glEnd( );

	      /* Move To The Left Of The Character */
	      glTranslated( 15, 0, 0 );
	    glEndList( );
        }
}

/* function to reset our viewport after a window resize */
int resizeWindow( int width, int height )
{

    /* Protect against a divide by zero */
    if ( height == 0 )
	height = 1;

    /* Setup our viewport. */
    glViewport( 0, 0, ( GLint )width, ( GLint )height );

    /* change to the projection matrix and set our viewing volume. */
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity( );

    /* Set our ortho view */
    glOrtho( 0.0f, width, height, 0.0f, -1.0f, 1.0f );

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
	case SDLK_a:
	    anti = !anti;
	    break;
	case SDLK_RIGHT:
	    if ( ( player.x < 10 ) && ( player.fx == player.x * 60 ) &&
		 ( player.fy == player.y * 40 ) )
		{
		    /* Mark The Current Horizontal Border As Filled */
		    hline[player.x][player.y] = TRUE;
		    /* Move The Player Right */
		    player.x++;
		}
	    break;
	case SDLK_LEFT:
	    if ( ( player.x > 0 ) && ( player.fx == player.x * 60 ) &&
		 ( player.fy == player.y * 40 ) )
		{
		    /* Move The Player Left */
		    player.x--;
		    /* Mark The Current Horizontal Border As Filled */
		    hline[player.x][player.y] = TRUE;
		}
	    break;
	case SDLK_UP:
	    if ( ( player.y > 0 ) && ( player.fx == player.x * 60 ) &&
		 ( player.fy == player.y * 40 ) )
		{
		    /* Move The Player Up */
		    player.y--;
		    /* Mark The Current Verticle Border As Filled */
		    vline[player.x][player.y] = TRUE;
		}
	    break;
	case SDLK_DOWN:
	    if ( ( player.y < 10 ) && ( player.fx == player.x * 60 ) &&
		 ( player.fy == player.y * 40 ) )
		{
		    /* Mark The Current Verticle Border As Filled */
		    vline[player.x][player.y] = TRUE;
		    /* Move The Player Down */
		    player.y++;
		}
	    break;
	case SDLK_SPACE:
	    if ( gameover )
		{
		    gameover = FALSE; /* gameover Becomes FALSE             */
		    filled   = TRUE;  /* filled Becomes TRUE                */
		    level    = 1;     /* Starting Level Is Set Back To One  */
		    level2   = 1;     /* Displayed Level Is Also Set To One */
		    stage    = 1;     /* Game Stage Is Set To Zero          */
		    lives    = 5;     /* Lives Is Set To Five               */
		}
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

    /* Jump To Texture Loading Routine */
    if ( !LoadGLTextures( ) )
	return FALSE;

    /* Build The Font */
    BuildFont( );

    /* Enable smooth shading */
    glShadeModel( GL_SMOOTH );

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* Set Line Antialiasing */
    glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );
    /* Enable Blending */
    glEnable( GL_BLEND );
    /* Type Of Blending To Use */
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );

    return( TRUE );
}

/* function to print a string */
GLvoid glPrint( GLint x, GLint y, int set, const char *fmt, ... )
{
    char text[256]; /* Holds Our String */
    va_list ap;     /* Pointer To List Of Arguments */

    /* If There's No Text */
    if ( fmt == NULL )
	return;

    /* Parses The String For Variables */
    va_start( ap, fmt );
      /* Converts Symbols To Actual Numbers */
      vsprintf( text, fmt, ap );
    va_end( ap );

    /* Did User Choose An Invalid Character Set? */
    if ( set > 1 )
	set = 1;

    /* Enable Texture Mapping */
    glEnable( GL_TEXTURE_2D );

    /* Select our texture */
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    /* Disable depth testing */
    glDisable( GL_DEPTH_TEST );

    /* Reset The Modelview Matrix */
    glLoadIdentity( );
    /* Position The Text (0,0 - Bottom Left) */
    glTranslated( x, y, 0 );
    /* Choose The Font Set (0 or 1) */
    glListBase( base - 32 + ( 128 * set ) );

    /* If Set 0 Is Being Used Enlarge Font */
    if ( set == 0 )
	/* Enlarge Font Width And Height */
	glScalef( 1.5f, 2.0f, 1.0f );

    /* Write The Text To The Screen */
    glCallLists( strlen( text ), GL_BYTE, text );
    /* Disable Texture Mapping */
    glDisable( GL_TEXTURE_2D );

    /* Re-enable Depth Testing */
    glEnable( GL_DEPTH_TEST );

    return;
}

/* Here goes our drawing code */
void drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glLoadIdentity( );

    /* Set Color To Purple */
    glColor3f( 1.0f, 0.5f, 1.0f );
    /* Write GRID CRAZY On The Screen */
    glPrint( 207, 24, 0, "GRID CRAZY" );
    /* Set Color To Yellow */
    glColor3f( 1.0f, 1.0f, 0.0f );
    /* Write Actual Level Stats */
    glPrint( 20, 20, 1, "Level:%2i", level2 );
    /* Write Stage Stats */
    glPrint( 20, 40, 1, "Stage:%2i", stage );

    /* Is The Game Over? */
    if ( gameover )
        {
	    /* Pick A Random Color */
	    glColor3ub( rand( ) % 255, rand( ) % 255, rand( ) % 255 );
	    /* Write GAME OVER To The Screen */
	    glPrint( 472, 20, 1, "GAME OVER" );
	    /* Write PRESS SPACE To The Screen */
	    glPrint( 456, 40, 1, "PRESS SPACE" );
        }

    /* Loop Through Lives Minus Current Life */
    for ( loop1 = 0; loop1 < lives - 1; loop1++ )
        {
	    /* Reset The View */
	    glLoadIdentity( );
	    /* Move To The Right Of Our Title Text */
	    glTranslatef( 490 + ( loop1 * 40.0f ), 40.0f, 0.0f );
	    /* Rotate Counter Clockwise */
	    glRotatef( -player.spin, 0.0f, 0.0f, 1.0f );
	    /* Set Player Color To Light Green */
	    glColor3f( 0.0f, 1.0f, 0.0f );

	    /* Start Drawing Our Player Using Lines */
	    glBegin( GL_LINES );
	      glVertex2d( -5, -5 ); /* Top Left Of Player     */
	      glVertex2d(  5,  5 ); /* Bottom Right Of Player */
	      glVertex2d(  5, -5 ); /* Top Right Of Player    */
	      glVertex2d( -5,  5 ); /* Bottom Left Of Player  */
	    glEnd( );

	    /* Rotate Counter Clockwise */
	    glRotatef( -player.spin * 0.5f, 0.0f, 0.0f, 1.0f );
	    /* Set Player Color To Dark Green */
	    glColor3f( 0.0f, 0.75f, 0.0f );

	    /* Start Drawing Our Player Using Lines */
	    glBegin( GL_LINES );
	      glVertex2d( -7,  0 ); /* Left Center Of Player   */
	      glVertex2d(  7,  0 ); /* Right Center Of Player  */
	      glVertex2d(  0, -7 ); /* Top Center Of Player    */
	      glVertex2d(  0,  7 ); /* Bottom Center Of Player */
	    glEnd( );
        }

    /* Set Filled To True Before Testing */
    filled = TRUE;
    /* Set Line Width For Cells To 2.0f */
    glLineWidth( 2.0f );
    /* Disable Antialiasing */
    glDisable( GL_LINE_SMOOTH );
    /* Reset The Current Modelview Matrix */
    glLoadIdentity( );

    /* Loop From Left To Right */
    for ( loop1 = 0; loop1 < 11; loop1++ )
        {
	    /* Loop From Top To Bottom */
	    for ( loop2 = 0; loop2 < 11; loop2++ )
                {
		    /* Set Line Color To Blue */
		    glColor3f( 0.0f, 0.5f, 1.0f );

		    /* Has The Horizontal Line Been Traced */
		    if ( hline[loop1][loop2] )
			glColor3f( 1.0f, 1.0f, 1.0f );

		    /* Dont Draw To Far Right */
		    if ( loop1 < 10 )
                        {
			    /* If A Horizontal Line Isn't Filled */
			    if ( !hline[loop1][loop2] )
				filled = FALSE;

			    /* Start Drawing Horizontal Cell Borders */
			    glBegin( GL_LINES );
			      /* Left Side Of Horizontal Line */
			      glVertex2d( 20 + ( loop1 * 60 ),
					  70 + ( loop2 * 40 ) );
			      /* Right Side Of Horizontal Line */
			      glVertex2d( 80 + ( loop1 * 60 ),
					  70 + ( loop2 * 40 ) );
			    glEnd( );
                        }

		    /* Set Line Color To Blue */
		    glColor3f( 0.0f, 0.5f, 1.0f );

		    /* Has The Horizontal Line Been Traced */
		    if ( vline[loop1][loop2] )
			/* If So, Set Line Color To White */
			glColor3f( 1.0f, 1.0f, 1.0f );

		    /* Dont Draw To Far Down */
		    if ( loop2 < 10 )
                        {
			    /* If A Verticle Line Isn't Filled */
			    if ( !vline[loop1][loop2] )
				filled = FALSE;

			    /* Start Drawing Verticle Cell Borders */
			    glBegin( GL_LINES );
			      /* Left Side Of Horizontal Line */
			      glVertex2d( 20 + ( loop1 * 60 ),
					  70 + ( loop2 * 40 ) );
			      /* Right Side Of Horizontal Line */
			      glVertex2d( 20 + ( loop1 * 60 ),
					  110 + ( loop2 * 40 ) );
			    glEnd( );
                        }

		    /* Enable Texture Mapping */
		    glEnable( GL_TEXTURE_2D );
		    /* Bright White Color */
		    glColor3f( 1.0f, 1.0f, 1.0f );
		    /* Select The Tile Image */
		    glBindTexture( GL_TEXTURE_2D, texture[1] );

		    /* If In Bounds, Fill In Traced Boxes */
		    if ( ( loop1 < 10 ) && ( loop2 < 10 ) )
                        {
                            /* Are All Sides Of The Box Traced? */
			    if ( hline[loop1][loop2] &&
				 hline[loop1][loop2 + 1] &&
				 vline[loop1][loop2] &&
				 vline[loop1+1][loop2] )
                                {
				    /* Draw A Textured Quad */
				    glBegin( GL_QUADS );
				    /* Top Right */
				    glTexCoord2f( ( float )( loop1 / 10.0f ) + 0.1f, 1.0f - ( ( float )( loop2 / 10.0f ) ) );
				    glVertex2d( 20 + ( loop1 * 60 ) + 59,
						70 + loop2 * 40 + 1 );
				    /* Top Left */
				    glTexCoord2f( ( float )( loop1 / 10.0f ), 1.0f - ( ( float )( loop2 / 10.0f ) ) );
				    glVertex2d( 20 + ( loop1 * 60 ) + 1,
						70 + loop2 * 40 + 1 );
				    /* Bottom Left */
				    glTexCoord2f( ( float )( loop1 / 10.0f ), 1.0f - ( ( float )( loop2 / 10.0f ) + 0.1f ) );
				    glVertex2d( 20 + ( loop1 * 60 ) + 1,
						( 70 + loop2 * 40 ) + 39 );
				    /* Bottom Right */
				    glTexCoord2f( ( float )( loop1 / 10.0f ) + 0.1f, 1.0f - ( ( float )( loop2 / 10.0f ) + 0.1f ) );
				    glVertex2d( 20 + ( loop1 * 60 ) + 59,
						( 70 + loop2 * 40 ) + 39 );
				    glEnd( );
                                }
                        }

		    /* Disable Texture Mapping */
		    glDisable( GL_TEXTURE_2D );
                }
        }

    /* Set The Line Width To 1.0f */
    glLineWidth( 1.0f );

    /* Is Anti TRUE? */
    if ( anti )
	glEnable( GL_LINE_SMOOTH );

    /* If fx=1 Draw The Hourglass */
    if ( hourglass.fx == 1 )
        {
	    /* Reset The Modelview Matrix */
	    glLoadIdentity( );
	    /* Move To The Fine Hourglass Position */
	    glTranslatef( 20.0f + ( hourglass.x * 60 ),
			  70.0f + ( hourglass.y * 40 ), 0.0f );
	    /* Rotate Clockwise */
	    glRotatef( hourglass.spin, 0.0f, 0.0f, 1.0f );
	    /* Set Hourglass Color To Random Color */
	    glColor3ub( rand( ) % 255, rand( ) % 255, rand( ) % 255 );

	    /* Start Drawing Our Hourglass Using Lines */
	    glBegin( GL_LINES );
	      /* Top Left Of Hourglass */
	      glVertex2d( -5, -5 );
	      /* Bottom Right Of Hourglass */
	      glVertex2d(  5,  5 );
	      /* Top Right Of Hourglass */
	      glVertex2d(  5, -5 );
	      /* Bottom Left Of Hourglass */
	      glVertex2d( -5,  5 );
	      /* Bottom Left Of Hourglass */
	      glVertex2d( -5,  5 );
	      /* Bottom Right Of Hourglass */
	      glVertex2d(  5,  5 );
	      /* Top Left Of Hourglass */
	      glVertex2d( -5, -5 );
	      /* Top Right Of Hourglass */
	      glVertex2d(  5, -5 );
	    glEnd( );
	}

    /* Reset The Modelview Matrix */
    glLoadIdentity( );
    /* Move To The Fine Player Position */
    glTranslatef( player.fx + 20.0f, player.fy + 70.0f, 0.0f );
    /* Rotate Clockwise */
    glRotatef( player.spin, 0.0f, 0.0f, 1.0f );
    /* Set Player Color To Light Green */
    glColor3f( 0.0f, 1.0f, 0.0f );

    /* Start Drawing Our Player Using Lines */
    glBegin( GL_LINES );
      /* Top Left Of Player */
      glVertex2d( -5, -5 );
      /* Bottom Right Of Player */
      glVertex2d(  5,  5 );
      /* Top Right Of Player */
      glVertex2d(  5, -5 );
      /* Bottom Left Of Player */
      glVertex2d( -5,  5 );
    glEnd( );

    /* Rotate Clockwise */
    glRotatef( player.spin * 0.5f, 0.0f, 0.0f, 1.0f );
    /* Set Player Color To Dark Green */
    glColor3f( 0.0f, 0.75f, 0.0f );
    /* Start Drawing Our Player Using Lines */
    glBegin( GL_LINES );
      /* Left Center Of Player */
      glVertex2d( -7,  0 );
      /* Right Center Of Player */
      glVertex2d(  7,  0 );
      /* Top Center Of Player */
      glVertex2d(  0, -7 );
      /* Bottom Center Of Player */
      glVertex2d(  0,  7 );
    glEnd( );

    /* Loop To Draw Enemies */
    for ( loop1 = 0; loop1 < ( stage * level ); loop1++ )
	{
	    /* Reset The Modelview Matrix */
	    glLoadIdentity( );
	    glTranslatef( enemies[loop1].fx + 20.0f,
			  enemies[loop1].fy + 70.0f, 0.0f );
	    /* Make Enemy Body Pink */
	    glColor3f( 1.0f, 0.5f, 0.5f );

	    /* Start Drawing Enemy */
	    glBegin( GL_LINES );
	      /* Top Point Of Body */
	      glVertex2d(  0, -7 );
	      /* Left Point Of Body */
	      glVertex2d( -7,  0 );
	      /* Left Point Of Body */
	      glVertex2d( -7,  0 );
	      /* Bottom Point Of Body */
	      glVertex2d(  0,  7 );
	      /* Bottom Point Of Body */
	      glVertex2d(  0,  7 );
	      /* Right Point Of Body */
	      glVertex2d(  7,  0 );
	      /* Right Point Of Body */
	      glVertex2d(  7,  0 );
	      /* Top Point Of Body */
	      glVertex2d(  0, -7 );
	    glEnd( );

	    /* Rotate The Enemy Blade */
	    glRotatef( enemies[loop1].spin, 0.0f, 0.0f, 1.0f );
	    /* Make Enemy Blade Red */
	    glColor3f( 1.0f, 0.0f, 0.0f );

	    /* Start Drawing Enemy Blade */
	    glBegin( GL_LINES );
	      /* Top Left Of Enemy */
	      glVertex2d( -7, -7 );
	      /* Bottom Right Of Enemy */
	      glVertex2d(  7,  7 );
	      /* Bottom Left Of Enemy */
	      glVertex2d( -7,  7 );
	      /* Top Right Of Enemy */
	      glVertex2d(  7, -7 );
	    glEnd( );
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

    return;
}

#ifdef SOUND
void PlaySound( char *sound, int repeat )
{

    if ( sound == NULL )
	{
	    Mix_HaltChannel( 1 );
	    Mix_FreeChunk( chunk );
	    chunk = NULL;

	    return;
	}

    if ( chunk )
	{
	    Mix_HaltChannel( 1 );
	    Mix_FreeChunk( chunk );

	    chunk = NULL;
	}

    chunk = Mix_LoadWAV( sound );

    if ( chunk == NULL )
	fprintf( stderr, "Failed to load sound: %s\n", sound );

    Mix_PlayChannel( -1, chunk, repeat );

    return;
}
#endif

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
    /* Our timer */
    Uint32 time;

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

    /* initialize OpenGL */
    if ( initGL( ) == FALSE )
	{
	    fprintf( stderr, "Could not initialize OpenGL.\n" );
	    Quit( 1 );
	}

#ifdef SOUND
    /* Initialize Audio sub system */
    if ( SDL_InitSubSystem( SDL_INIT_AUDIO ) == -1 )
	{
	    fprintf( stderr, "Could not initialize audio subsystem: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
	}

    /* Open the sound device */
    if ( Mix_OpenAudio( 22060, AUDIO_S16SYS, 2, 512 ) < 0 )
	{
	    fprintf( stderr, "Unable to open audio: %s\n", SDL_GetError( ) );
	    Quit( 1 );
	}
    /* Load in the music */
    music = Mix_LoadMUS( "data/lktheme.mod" );
#endif

    /* Resize the initial window */
    resizeWindow( SCREEN_WIDTH, SCREEN_HEIGHT );

    /* reset our objects */
    ResetObjects( );

#ifdef SOUND
    /* Start playing the music */
    Mix_PlayMusic( music, -1 );
#endif

    /* wait for events */
    while ( !done )
	{

	    /* Get our time */
	    time = SDL_GetTicks( );

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

	    /* Waste some cycles */
	    while( SDL_GetTicks( ) < time + ( Uint32 )steps[adjust] * 2 ) ;

	    /* draw the scene */
	    if ( isActive )
		drawGLScene( );

	    if ( !gameover && isActive )
		{
		    /* Move the enemies */
		    for ( loop1 = 0; loop1 < ( stage * level ); loop1++ )
			{
			    /* Move The Enemy Right */
			    if ( ( enemies[loop1].x < player.x ) &&
				 ( enemies[loop1].fy == enemies[loop1].y * 40 ) )
				enemies[loop1].x++;

			    /* Move The Enemy Left */
			    if ( ( enemies[loop1].x > player.x ) &&
				 ( enemies[loop1].fy == enemies[loop1].y * 40 ) )
				enemies[loop1].x--;
		    
			    /* Move The Enemy Down */
			    if ( ( enemies[loop1].y < player.y ) &&
				 ( enemies[loop1].fx == enemies[loop1].x * 60 ) )
				enemies[loop1].y++;
			    
			    /* Move The Enemy Up */
			    if ( ( enemies[loop1].y > player.y ) &&
				 ( enemies[loop1].fx == enemies[loop1].x * 60 ) )
				enemies[loop1].y--;
			
			    /* Should the enemies move? */
			    if ( delay > ( 3 - level ) && ( hourglass.fx != 2 ) )
				{
				    /* Reset The Delay Counter Back To Zero */
				    delay = 0;

				    /* Loop Through All The Enemies */
				    for ( loop2 = 0; loop2 < ( stage * level );
					  loop2++ )
					{
					    /* Is Fine Position On X Axis Lower
					     * Than Intended Position?
					     */
					    if ( enemies[loop2].fx <
						 enemies[loop2].x * 60 )
						{
						    /* Increase Fine Position
						     * On X Axis
						     */
						    enemies[loop2].fx +=
							steps[adjust];
						    /* Spin Enemy Clockwise */
						    enemies[loop2].spin +=
							steps[adjust];
						}

					    /* Is Fine Position On X Axis
					     * Higher Than Intended Position?
					     */
					    if ( enemies[loop2].fx >
						 enemies[loop2].x * 60 )
						{
						    /* Decrease Fine Position
						     * On X Axis
						     */
						    enemies[loop2].fx -=
							steps[adjust];
						    /* Spin Enemy Counter
						     * Clockwise 
						     */
						    enemies[loop2].spin -=
							steps[adjust];
						}

					    /* Is Fine Position On Y Axis Lower
					     * Than Intended Position?
					     */
					    if ( enemies[loop2].fy <
						 enemies[loop2].y * 40 )
						{
						    /* Increase Fine Position
						     * On Y Axis
						     */
						    enemies[loop2].fy +=
							steps[adjust];
						    /* Spin Enemy Clockwise */
						    enemies[loop2].spin +=
							steps[adjust];
						}

					    /* Is Fine Position On Y Axis
					     * Higher Than Intended Position?
					     */
					    if (enemies[loop2].fy >
						enemies[loop2].y * 40 )
						{
						    /* Decrease Fine Position
						     * On Y Axis
						     */
						    enemies[loop2].fy -=
							steps[adjust];
						    /* Spin Enemy Counter
						     * Clockwise
						     */
						    enemies[loop2].spin -=
							steps[adjust];
						}
					}
				}

			    /* Are Any Of The Enemies On Top Of The Player? */
			    if ( ( enemies[loop1].fx == player.fx ) &&
				 ( enemies[loop1].fy == player.fy ) )
				{
				    /* Player Loses A Life */
				    lives--;

				    /* Are We Out Of Lives? */
				    if ( lives == 0 )
					gameover = TRUE;

#ifdef SOUND
				    /* Play The Death Sound */
				    PlaySound( "data/die.wav", 0 );
#endif

				    ResetObjects( );
				}
			}

		    /* Move the player */
		    /* Is Fine Position On X Axis Lower Than
		     * Intended Position?
		     */
		    if ( player.fx < player.x * 60 )
			/* Increase The Fine X Position */
			player.fx += steps[adjust];

		    /* Is Fine Position On X Axis Greater Than
		     * Intended Position?
		     */
		    if ( player.fx > player.x * 60 )
			/* Decrease The Fine X Position */
			player.fx -= steps[adjust];

		    /* Is Fine Position On Y Axis Lower Than
		     * Intended Position?
		     */
		    if ( player.fy < player.y * 40 )
			/* Increase The Fine Y Position */
			player.fy += steps[adjust];

		    /* Is Fine Position On Y Axis Lower Than
		     * Intended Position?
		     */
		    if  (player.fy > player.y * 40 )
			/* Decrease The Fine Y Position */
			player.fy -= steps[adjust];
		}

	    /* Is The Grid Filled In? */
	    if ( filled )
		{
#ifdef SOUND
		    /* Play The Level Complete Sound */
		    PlaySound( "data/complete.wav", 0 );
#endif

		    /* Increase The Stage */
		    stage++;

		    /* Is The Stage Higher Than 3? */
		    if ( stage > 3 )
			{
			    stage = 1; /* If So, Set The Stage To One  */
			    level++;   /* Increase The Level           */
			    level2++;  /* Increase The Displayed Level */

			    /* Is The Level Greater Than 3? */
			    if ( level > 3 )
				{
				    /* Set The Level To 3 */
				    level = 3;
				    /* Give The Player A Free Life */
				    lives++;

				    /* Player Have More Than 5 Lives? */
				    if ( lives > 5 )
					lives = 5; /* Set Lives To Five */
				} 
			}

		    /* Reset Player / Enemy Positions */
		    ResetObjects( );

		    /* Loop Through The Grid X Coordinates */
		    for ( loop1 = 0; loop1 < 11; loop1++ )
			{
			    /* Loop Through The Grid Y Coordinates */
			    for ( loop2 = 0; loop2 < 11; loop2++ )
				{
				    /* If X Coordinate Is Less Than 10 */
				    if ( loop1 < 10 )
					/* Set Horizontal Value To FALSE */
					hline[loop1][loop2] = FALSE;

				    /* If Y Coordinate Is Less Than 10 */
				    if ( loop2 < 10 )
					/* Set Vertical Value To FALSE */
					vline[loop1][loop2] = FALSE;
				}
			}
		}

	    /* If The Player Hits The Hourglass While
	     * It's Being Displayed On The Screen
	     */
	    if ( ( player.fx == hourglass.x * 60 ) &&
		 ( player.fy == hourglass.y * 40 ) &&
		 ( hourglass.fx ==1 ) )
		{
#ifdef SOUND
		    /* Play Freeze Enemy Sound */
		    PlaySound( "data/freeze.wav", -1 );
#endif

		    /* Set The hourglass fx Variable To Two */
		    hourglass.fx = 2;
		    /* Set The hourglass fy Variable To Zero */
		    hourglass.fy = 0;
		}

	    /* Spin The Player Clockwise */
	    player.spin += 0.5f * steps[adjust];

	    /* Is The spin Value Greater Than 360? */
	    if ( player.spin > 360.0f )
		player.spin -= 360;

	    /* Spin The Hourglass Counter Clockwise */
	    hourglass.spin -= 0.25f * steps[adjust];

	    /* Is The spin Value Less Than 0? */
	    if ( hourglass.spin < 0.0f )
		hourglass.spin += 360.0f;

	    /* Increase The hourglass fy Variable */
	    hourglass.fy +=steps[adjust];

	    /* Is The hourglass fx Variable Equal To 0 And
	     * The fy Variable Greater Than 6000 Divided By The Current Level?
	     */
	    if ( ( hourglass.fx == 0 ) && ( hourglass.fy > 6000 / level ) )
		{
#ifdef SOUND
		    /* Play The Hourglass Appears Sound */
		    PlaySound( "data/hourglass.wav", 0 );
#endif

		    /* Give The Hourglass A Random X Value */
		    hourglass.x = rand( ) % 10 + 1;
		    /* Give The Hourglass A Random Y Value */
		    hourglass.y = rand( ) % 11;
		    /* Set hourglass fx Variable To One (Hourglass Stage) */
		    hourglass.fx = 1;
		    /* Set hourglass fy Variable To Zero (Counter) */
		    hourglass.fy = 0;
		}

	    /* Is The hourglass fx Variable Equal To 1 And
	     * The fy Variable Greater Than 6000 Divided By The Current Level?
	     */
	    if ( ( hourglass.fx == 1 ) && ( hourglass.fy > 6000 / level ) )
		{
		    /* Set fx To Zero (Hourglass Will Vanish) */
		    hourglass.fx = 0;
		    /* Set fy to Zero (Counter Is Reset) */
		    hourglass.fy = 0;
		}

	    /* Is The hourglass fx Variable Equal To 2 And The fy Variable
	     * Greater Than 500 Plus 500 Times The Current Level?
	     */
	    if ( ( hourglass.fx == 2 ) &&
		 ( hourglass.fy > 500 + ( 500 * level ) ) )
		{
#ifdef SOUND
		    /* Kill The Freeze Sound */
		    PlaySound( NULL, 0 );
#endif

		    /* Set hourglass fx Variable To Zero */
		    hourglass.fx = 0;
		    /* Set hourglass fy Variable To Zero */
		    hourglass.fy = 0;
		}
	    
	    delay++;
	}


    /* clean ourselves up and exit */
    Quit( 0 );

    /* Should never get here */
    return( 0 );
}
