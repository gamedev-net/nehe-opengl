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
#define SCREEN_HEIGHT 400
#define SCREEN_BPP     16

/* Set up some booleans */
#define TRUE  1
#define FALSE 0

/* This is our SDL surface */
SDL_Surface *surface;

/* Build Our Vertex Structure */
typedef struct
{
    float x, y, z; /* 3D Coordinates */
    float u, v;    /* Texture Coordinates */
} vertex;

/* Build Our Triangle Structure */
typedef struct
{
    vertex vertex[3]; /* Array Of Three Vertices */
} triangle;

/* Build Our Sector Structure */
typedef struct
{
    int numTriangles;   /* Number Of Triangles In Sector */
    triangle *triangle; /* Pointer To Array Of Triangles */
} sector;

sector sector1;     /* Our sector */

GLfloat yrot;       /* Camera rotation variable */
GLfloat xpos, zpos; /* Camera pos variable */

GLfloat walkbias, walkbiasangle; /* Head-bobbing variables */
GLfloat lookupdown;

/* Ambient Light Values */
GLfloat LightAmbient[]  = { 0.5f, 0.5f, 0.5f, 1.0f };
/* Diffuse Light Values */
GLfloat LightDiffuse[]  = { 1.0f, 1.0f, 1.0f, 1.0f };
/* Light Position */
GLfloat LightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };

/* constant used for converting to radians */
const float piover180 = 0.0174532925f;

GLuint filter;     /* Which Filter To Use */
GLuint texture[3]; /* Storage for 3 textures */

/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{
    /* clean up the window */
    SDL_Quit( );

    /* Deallocate things we allocated */
    if ( sector1.triangle )
	free( sector1.triangle );

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
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/mud.bmp" ) ) )
        {

	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( 3, &texture[0] );

	    /* Load in texture 1 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[0] );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0]->w,
			  TextureImage[0]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[0]->pixels );
	    
	    /* Nearest Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_NEAREST );

	    /* Load in texture 2 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[1] );

	    /* Linear Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0]->w,
			  TextureImage[0]->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage[0]->pixels );

	    /* Load in texture 3 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[2] );

	    /* Mipmapped Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR_MIPMAP_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );

	    /* Generate The MipMapped Texture ( NEW ) */
	    gluBuild2DMipmaps( GL_TEXTURE_2D, 3, TextureImage[0]->w,
			       TextureImage[0]->h, GL_BGR,
			       GL_UNSIGNED_BYTE, TextureImage[0]->pixels );
        }

    /* Free up any memory we may have used */
    if ( TextureImage[0] )
	    SDL_FreeSurface( TextureImage[0] );

    return Status;
}


/* Read In A String */
void readstr( FILE *f, char *string )
{
    /* Start A Loop */
    do
        {
	    /* Read One Line */
	    fgets( string, 255, f );
        } while ( ( string[0] == '/' ) || ( string[0] == '\n' ) );

    return;
}

/* Setup Our World */
void SetupWorld( char* worldFile )
{
    FILE *filein;        /* File To Work With */

    int numTriangles;    /* Number of Triangles */
    char oneLine[255];   /* One line from conf file */

    float x, y, z, u, v; /* 3d and texture coordinates */

    int triLoop;         /* Triangle loop variable */
    int verLoop;         /* Vertex loop variable */

    /* Open Our File */
    filein = fopen( worldFile, "rt" );

    /* Grab a line from 'filein' */
    readstr( filein, oneLine );

    /* Read in number of triangle */
    sscanf( oneLine, "NUMPOLLIES %d\n", &numTriangles );

    /* allocate space for our triangles */
    sector1.triangle     = malloc( numTriangles * sizeof( triangle ) );
    if ( sector1.triangle == NULL )
	{
	    fprintf( stderr, "Could not allocate memory for triangles.\n" );
	    Quit( 1 );
	}
    sector1.numTriangles = numTriangles;

    /* Get coords for each triangle */
    for ( triLoop = 0; triLoop < numTriangles; triLoop++ )
	{
	    for ( verLoop = 0; verLoop < 3; verLoop++ )
		{
		    readstr( filein, oneLine );
		    sscanf( oneLine, "%f %f %f %f %f\n", &x, &y, &z, &u, &v );
		    sector1.triangle[triLoop].vertex[verLoop].x = x;
		    sector1.triangle[triLoop].vertex[verLoop].y = y;
		    sector1.triangle[triLoop].vertex[verLoop].z = z;
		    sector1.triangle[triLoop].vertex[verLoop].u = u;
		    sector1.triangle[triLoop].vertex[verLoop].v = v;
		}
	}

    /* Close Our File */
    fclose( filein );

    return;
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
	case SDLK_RIGHT:
	    /* Right arrow key was pressed
	     * this effectively turns the camera right, but does it by
	     * rotating the scene left
	     */
	    yrot -= 1.5f;
	    break;
	case SDLK_LEFT:
	    /* Left arrow key was pressed
	     * this effectively turns the camera left, but does it by
	     * rotating the scene right
	     */
	    yrot += 1.5f;
	    break;
	case SDLK_UP:
	    /* Up arrow key was pressed
	     * this moves the player forward
	     */
	    /* Move On The X-Plane Based On Player Direction */
	    xpos -= ( float )sin( yrot * piover180 ) * 0.05f;
	    /* Move On The Z-Plane Based On Player Direction */
	    zpos -= ( float )cos( yrot * piover180 ) * 0.05f;
	    if ( walkbiasangle >= 359.0f )
		walkbiasangle = 0.0f;
	    else
		walkbiasangle+= 10;

	    /* Causes the player to bounce */
	    walkbias = ( float )sin( walkbiasangle * piover180 ) / 20.0f;
	    break;
	case SDLK_DOWN:
	    /* Down arrow key was pressed
	     * this causes the player to move backwards
	     */
	    /* Move On The X-Plane Based On Player Direction */
	    xpos += ( float )sin( yrot * piover180 ) * 0.05f;
	    /* Move On The Z-Plane Based On Player Direction */
	    zpos += ( float )cos( yrot * piover180 ) * 0.05f;
	    if ( walkbiasangle <= 1.0f )
                walkbiasangle = 359.0f;
	    else
                walkbiasangle -= 10;

	    walkbias = ( float )sin( walkbiasangle * piover180 ) / 20.0f;
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

    /* Enables Depth Testing */
    glEnable( GL_DEPTH_TEST );

    /* The Type Of Depth Test To Do */
    glDepthFunc( GL_LEQUAL );

    /* Really Nice Perspective Calculations */
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

    /* Setup The Ambient Light */
    glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient );

    /* Setup The Diffuse Light */
    glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse );

    /* Position The Light */
    glLightfv( GL_LIGHT1, GL_POSITION, LightPosition );

    /* Enable Light One */
    glEnable( GL_LIGHT1 );

    lookupdown    = 0.0f;
    walkbias      = 0.0f;
    walkbiasangle = 0.0f;
    
    /* Full Brightness, 50% Alpha */
    glColor4f( 1.0f, 1.0f, 1.0f, 0.5f);

    /* Blending Function For Translucency Based On Source Alpha Value */
    glBlendFunc( GL_SRC_ALPHA, GL_ONE );

    return( TRUE );
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    /* Floating Point For Temp X, Y, Z, U And V Vertices */
    GLfloat x_m, y_m, z_m, u_m, v_m;
    /* Used For Player Translation On The X Axis */
    GLfloat xtrans = -xpos;
    /* Used For Player Translation On The Z Axis */
    GLfloat ztrans = -zpos;
    /* Used For Bouncing Motion Up And Down */
    GLfloat ytrans = -walkbias - 0.25f;
    /* 360 Degree Angle For Player Direction */
    GLfloat sceneroty = 360.0f - yrot;

    /* Loop variable */
    int loop_m;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glLoadIdentity( );

    /* Rotate Up And Down To Look Up And Down */
    glRotatef( lookupdown, 1.0f, 0.0f , 0.0f );
    /* Rotate Depending On Direction Player Is Facing */
    glRotatef( sceneroty, 0.0f, 1.0f , 0.0f );

    /* Translate The Scene Based On Player Position */
    glTranslatef( xtrans, ytrans, ztrans );
    /* Select A Texture Based On filter */
    glBindTexture( GL_TEXTURE_2D, texture[filter] );
        
    /* Process Each Triangle */
    for ( loop_m = 0; loop_m < sector1.numTriangles; loop_m++ )
        {
	    /* Start Drawing Triangles */
	    glBegin(GL_TRIANGLES);
	      /* Normal Pointing Forward */
	      glNormal3f( 0.0f, 0.0f, 1.0f);
	      /* X Vertex Of 1st Point */
	      x_m = sector1.triangle[loop_m].vertex[0].x;
	      /* Y Vertex Of 1st Point */
	      y_m = sector1.triangle[loop_m].vertex[0].y;
	      /* Z Vertex Of 1st Point */
	      z_m = sector1.triangle[loop_m].vertex[0].z;
	      /* U Texture Coord Of 1st Point */
	      u_m = sector1.triangle[loop_m].vertex[0].u;
	      /* V Texture Coord Of 1st Point */
	      v_m = sector1.triangle[loop_m].vertex[0].v;

	      /* Set The TexCoord And Vertice */
	      glTexCoord2f( u_m, v_m );
	      glVertex3f( x_m, y_m, z_m );

	      /* X Vertex Of 2nd Point */
	      x_m = sector1.triangle[loop_m].vertex[1].x;
	      /* Y Vertex Of 2nd Point */
	      y_m = sector1.triangle[loop_m].vertex[1].y;
	      /* Z Vertex Of 2nd Point */
	      z_m = sector1.triangle[loop_m].vertex[1].z;
	      /* U Texture Coord Of 2nd Point */
	      u_m = sector1.triangle[loop_m].vertex[1].u;
	      /* V Texture Coord Of 2nd Point */
	      v_m = sector1.triangle[loop_m].vertex[1].v;

	      /* Set The TexCoord And Vertice */
	      glTexCoord2f( u_m, v_m );
	      glVertex3f( x_m, y_m, z_m );

	      /* X Vertex Of 3rd Point */
	      x_m = sector1.triangle[loop_m].vertex[2].x;
	      /* Y Vertex Of 3rd Point */
	      y_m = sector1.triangle[loop_m].vertex[2].y;
	      /* Z Vertex Of 3rd Point */
	      z_m = sector1.triangle[loop_m].vertex[2].z;
	      /*  Texture Coord Of 3rd Point */
	      u_m = sector1.triangle[loop_m].vertex[2].u;
	      /* V Texture Coord Of 3rd Point */
	      v_m = sector1.triangle[loop_m].vertex[2].v;

	      /* Set The TexCoord And Vertice */
	      glTexCoord2f( u_m, v_m );
	      glVertex3f( x_m, y_m, z_m );
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

    /* Read in the data */
    SetupWorld( "data/world.txt" );

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
