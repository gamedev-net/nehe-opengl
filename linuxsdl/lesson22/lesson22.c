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
#include <string.h>
#include <math.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glext.h>
#include "SDL.h"

/* screen width, height, and bit depth */
#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define SCREEN_BPP     16

/* Set up some booleans */
#define TRUE  1
#define FALSE 0
typedef unsigned int bool;

/* Maximum Emboss-Translate. Increase To Get Higher Immersion */
#define MAX_EMBOSS ( GLfloat )0.01f

/* This is our SDL surface */
SDL_Surface *surface;

GLfloat xrot;      /* X Rotation                           */
GLfloat yrot;      /* Y Rotation                           */
GLfloat zrot;      /* Z Rotation                           */
GLfloat xspeed;    /* X Rotation Speed                     */
GLfloat yspeed;    /* Y Rotation Speed                     */
GLfloat z = -5.0f; /* Depth into the screen                */

GLuint filter = 1; /* Which Filter To Use                  */
GLuint texture[3]; /* Storage For Textures                 */
GLuint bump[3];    /* Our Bumpmappings                     */
GLuint invbump[3]; /* Inverted Bumpmaps                    */
GLuint glLogo;     /* Handle For OpenGL-Logo               */
GLuint multiLogo;  /* Handle For Multitexture-Enabled-Logo */

bool emboss = FALSE;
bool bumps = TRUE;

/* Our Lights */
/* Ambient Light Is 20% White */
GLfloat LightAmbient[]  = { 0.2f, 0.2f, 0.2f};
/* Diffuse Light Is White */
GLfloat LightDiffuse[]  = { 1.0f, 1.0f, 1.0f};
/* Position Is Somewhat In Front Of Screen */
GLfloat LightPosition[] = { 0.0f, 0.0f, 2.0f};
GLfloat Gray[]          = { 0.5f, 0.5f, 0.5f, 1.0f};

/* Data we'll use to generate our cube */
GLfloat data[]= {
    /* Front Face */
    0.0f, 0.0f,             -1.0f, -1.0f, +1.0f,
    1.0f, 0.0f,             +1.0f, -1.0f, +1.0f,
    1.0f, 1.0f,             +1.0f, +1.0f, +1.0f,
    0.0f, 1.0f,             -1.0f, +1.0f, +1.0f,
    /* Back Face */
    1.0f, 0.0f,             -1.0f, -1.0f, -1.0f,
    1.0f, 1.0f,             -1.0f, +1.0f, -1.0f,
    0.0f, 1.0f,             +1.0f, +1.0f, -1.0f,
    0.0f, 0.0f,             +1.0f, -1.0f, -1.0f,
    /* Top Face */
    0.0f, 1.0f,             -1.0f, +1.0f, -1.0f,
    0.0f, 0.0f,             -1.0f, +1.0f, +1.0f,
    1.0f, 0.0f,             +1.0f, +1.0f, +1.0f,
    1.0f, 1.0f,             +1.0f, +1.0f, -1.0f,
    /* Bottom Face */
    1.0f, 1.0f,             -1.0f, -1.0f, -1.0f,
    0.0f, 1.0f,             +1.0f, -1.0f, -1.0f,
    0.0f, 0.0f,             +1.0f, -1.0f, +1.0f,
    1.0f, 0.0f,             -1.0f, -1.0f, +1.0f,
    /* Right Face */
    1.0f, 0.0f,             +1.0f, -1.0f, -1.0f,
    1.0f, 1.0f,             +1.0f, +1.0f, -1.0f,
    0.0f, 1.0f,             +1.0f, +1.0f, +1.0f,
    0.0f, 0.0f,             +1.0f, -1.0f, +1.0f,
    /* Left Face */
    0.0f, 0.0f,             -1.0f, -1.0f, -1.0f,
    1.0f, 0.0f,             -1.0f, -1.0f, +1.0f,
    1.0f, 1.0f,             -1.0f, +1.0f, +1.0f,
    0.0f, 1.0f,             -1.0f, +1.0f, -1.0f
};

/* Prepare for GL_ARB_multitexture */
/* Used To Disable ARB Extensions Entirely */
#define __ARB_ENABLE TRUE

/* Uncomment To See Your Extensions At Start-Up? */
#define EXT_INFO

/* Characters For Extension-Strings */
#define MAX_EXTENSION_SPACE 10240
/* Maximum Characters In One Extension-String */
#define MAX_EXTENSION_LENGTH 256

/* Flag Indicating Whether Multitexturing Is Supported */
bool multitextureSupported = FALSE;
/* Use It If It Is Supported? */
bool useMultitexture = TRUE;

/* Number Of Texel-Pipelines. This Is At Least 1. */
GLint maxTexelUnits = 1;


/* function to match the sub-string 'string' in 'search' */
bool isInString( char *string, const char *search ) {
    int pos    = 0;
    int maxpos = strlen( search ) - 1;
    int len    = strlen( string );
    char *other;
    int i;

    for ( i = 0; i < len; i++ ) {
	/* New Extension Begins Here! */
	if ( ( i == 0 ) || ( ( i > 1 ) && string[i - 1] == '\n' ) )
	    {
		/* Begin New Search */
		other = &string[i];
		pos   = 0;

		/* Search Whole Extension-String */
		while ( string[i] != '\n' && i < len )
		    {
			if ( string[i] == search[pos] )
			    pos++; /* Next Position */
			if ( ( pos > maxpos ) && string[i + 1] == '\n' )
			    return TRUE; /* We Have A Winner! */
			i++;
		    }
	    }
    }

    return FALSE; /* Sorry, Not Found! */
}

/* function to determine if ARB_multitexture is available */
bool initMultitexture( void ) {
    char *extensions;
    int len;
    int i;

    /* Fetch Extension String */
    extensions = strdup( ( char* )glGetString( GL_EXTENSIONS ) );    
    len = strlen( extensions );

    /* Separate It By Newline Instead Of Blank */
    for ( i = 0; i < len; i++ )
	if ( extensions[i] == ' ' )
	    extensions[i] = '\n';

#ifdef EXT_INFO
    printf( "Supported GL extensions:\n%s\n", extensions );
#endif

    /* Is Multitexturing Supported? */
    if ( isInString( extensions, "GL_ARB_multitexture" ) && __ARB_ENABLE &&
	 isInString( extensions, "GL_EXT_texture_env_combine" ) )
        {
	    glGetIntegerv( GL_MAX_TEXTURE_UNITS_ARB, &maxTexelUnits );
               
#ifdef EXT_INFO
	    printf ( "The GL_ARB_multitexture extension will be used.\n" );
#endif

	    return TRUE;
        }

    /* We Can't Use It If It Isn't Supported! */
    useMultitexture = FALSE;

    return FALSE;
}

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
    SDL_Surface *TextureImage;

    /* Storage space for alpha texture */
    unsigned char *alpha;

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage = SDL_LoadBMP( "data/base.bmp" ) ) )
        {
	    /* Set the status to true */
	    Status = TRUE;

	    /* Create The Texture */
	    glGenTextures( 3, &texture[0] );

	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[0] );

	    /* Nearest Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_NEAREST );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, TextureImage->w,
			  TextureImage->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage->pixels );


	    /* Create Linear Filtered Texture */
	    glBindTexture( GL_TEXTURE_2D, texture[1] );

	    /* Linear Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, TextureImage->w,
			  TextureImage->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage->pixels );

	    /* Create MipMapped Texture */
	    glBindTexture( GL_TEXTURE_2D, texture[2] );

	    /* Mipmap Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR_MIPMAP_NEAREST );

	    /* Generate The Texture */
	    gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB8, TextureImage->w,
			       TextureImage->h, GL_BGR,
			       GL_UNSIGNED_BYTE, TextureImage->pixels );
        }

    /* Free up any memory we may have used */
    if ( TextureImage )
	    SDL_FreeSurface( TextureImage );

    /* Load The Bumpmaps */
    if ( ( TextureImage = SDL_LoadBMP( "data/bump.bmp" ) ) )
	{
	    int i;
	    unsigned char *tempData;

	    /* Scale RGB By 50%, So That We Have Only */
	    glPixelTransferf( GL_RED_SCALE, 0.5f );
	    glPixelTransferf( GL_GREEN_SCALE, 0.5f );
	    glPixelTransferf( GL_BLUE_SCALE, 0.5f );
	    /* Specify not to wrap the texture */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );

	    /* Create Three Textures */
	    glGenTextures( 3, &bump[0] );

	    /* Create Nearest Filtered Texture */
	    glBindTexture( GL_TEXTURE_2D, bump[0] );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_NEAREST );
	    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, TextureImage->w,
			  TextureImage->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage->pixels );

	    /* Create Linear Filtered Texture */
	    glBindTexture( GL_TEXTURE_2D, bump[1] );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR );
	    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, TextureImage->w,
			  TextureImage->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage->pixels );

	    /* Create MipMapped Texture */
	    glBindTexture( GL_TEXTURE_2D, bump[2] );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR_MIPMAP_NEAREST );
	    gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB8, TextureImage->w,
			       TextureImage->h, GL_BGR,
			       GL_UNSIGNED_BYTE, TextureImage->pixels );

	    /* Invert The Bumpmap */
	    tempData = ( unsigned char* )TextureImage->pixels;
	    for ( i = 0; i < 3 * TextureImage->w * TextureImage->h; i++ )
		tempData[i] = 255 - tempData[i];

	    /* Create Three Textures */
	    glGenTextures( 3, invbump );

	    /* Create Nearest Filtered Texture */
	    glBindTexture( GL_TEXTURE_2D, invbump[0] );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_NEAREST );
	    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, TextureImage->w,
			  TextureImage->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, tempData );

	    /* Create Linear Filtered Texture */
	    glBindTexture( GL_TEXTURE_2D, invbump[1] );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_NEAREST );
	    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, TextureImage->w,
			  TextureImage->h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, tempData );

	    /* Create MipMapped Texture */
	    glBindTexture( GL_TEXTURE_2D, invbump[2] );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR_MIPMAP_NEAREST );
	    gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB8, TextureImage->w,
			       TextureImage->h, GL_BGR,
			       GL_UNSIGNED_BYTE, TextureImage->pixels );

	    tempData = NULL;
        }
        else
	    Status = FALSE;

        if ( TextureImage )
	    SDL_FreeSurface( TextureImage );

	/* Load The Logo-Bitmaps */
        if ( ( TextureImage = SDL_LoadBMP( "data/opengl_alpha.bmp" ) ) )
	    {
		int a;
		unsigned char *tempData;

		alpha = ( unsigned char* )malloc( 4 * TextureImage->w *
					 TextureImage->h *
					 sizeof( unsigned char ) );
		tempData = ( unsigned char* )TextureImage->pixels;

                /* Create Memory For RGBA8-Texture */
                for ( a = 0; a < TextureImage->w * TextureImage->h; a++)
		    /* Pick Only Red Value As Alpha! */
		    alpha[4 * a + 3] = tempData[a * 3];

		if ( TextureImage )
		    SDL_FreeSurface( TextureImage );

                if ( !( TextureImage = SDL_LoadBMP( "data/opengl.bmp" ) ) )
		    Status = FALSE;

		tempData = ( unsigned char* )TextureImage->pixels;

                for ( a = 0; a < TextureImage->w * TextureImage->h; a++)
		    {
			/* Red channel */
                        alpha[4 * a] = tempData[a * 3];
			/* Green channel */
                        alpha[4 * a + 1] = tempData[a * 3 + 1];
			/* Blue channel */
                        alpha[4 * a + 2] = tempData[a * 3 + 2];
		    }

		/* Create one texture */
                glGenTextures( 1, &glLogo );

                /* Create Linear Filtered RGBA8-Texture */
                glBindTexture( GL_TEXTURE_2D, glLogo );
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
				 GL_LINEAR );
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
				 GL_LINEAR );
                glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, TextureImage->w,
			      TextureImage->h, 0, GL_RGBA,
			      GL_UNSIGNED_BYTE, alpha );

		tempData = NULL;
                free( alpha );
	    }
        else
	    Status = FALSE;

        if ( TextureImage )
	    SDL_FreeSurface( TextureImage );

        /* Load The "Extension Enabled"-Logo */
        if ( ( TextureImage = SDL_LoadBMP( "data/multi_on_alpha.bmp" ) ) )
	    {
		int a;
		unsigned char *tempData;

		/* Create Memory For RGBA8-Texture */
		alpha = ( char* )malloc( 4 * TextureImage->w *
					 TextureImage->h * sizeof( char ) );
		tempData = ( unsigned char* )TextureImage->pixels;

                /* Create Memory For RGBA8-Texture */
                for ( a = 0; a < TextureImage->w * TextureImage->h; a++)
		    /* Pick Only Red Value As Alpha! */
		    alpha[4 * a + 3] = tempData[a * 3];

		if ( TextureImage )
		    SDL_FreeSurface( TextureImage );

                if ( !( TextureImage = SDL_LoadBMP( "data/multi_on.bmp" ) ) )
		    Status = FALSE;

		tempData = ( unsigned char* )TextureImage->pixels;

                for ( a = 0; a < TextureImage->w * TextureImage->h; a++)
		    {
			/* Red channel */
                        alpha[4 * a] = tempData[a * 3];
			/* Green channel */
                        alpha[4 * a + 1] = tempData[a * 3 + 1];
			/* Blue channel */
                        alpha[4 * a + 2] = tempData[a * 3 + 2];
		    }

		/* Create One Textures */
		glGenTextures( 1, &multiLogo );

                /* Create Linear Filtered RGBA8-Texture */
                glBindTexture( GL_TEXTURE_2D, multiLogo );
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
				 GL_LINEAR );
                glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
				 GL_LINEAR );
                glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, TextureImage->w,
			      TextureImage->h, 0, GL_RGBA,
			      GL_UNSIGNED_BYTE, alpha );

		free( alpha );
		tempData = NULL;
	    }
        else
	    Status = FALSE;

        if ( TextureImage )
	    SDL_FreeSurface( TextureImage );

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

/* function to draw a cube */
void doCube ( void) {
    int i;
    glBegin(GL_QUADS );
      /* Front Face */
      glNormal3f( 0.0f, 0.0f, +1.0f );
      for ( i = 0; i < 4; i++ )
	  {
	      glTexCoord2f( data[5 * i], data[5 * i + 1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Back Face */
      glNormal3f( 0.0f, 0.0f,-1.0f );
      for ( i = 4; i < 8; i++ )
	  {
	      glTexCoord2f( data[5 * i], data[5 * i + 1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Top Face */
      glNormal3f( 0.0f, 1.0f, 0.0f );
      for ( i = 8; i < 12; i++ )
	  {
	      glTexCoord2f( data[5 * i],data[5 * i + 1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Bottom Face */
      glNormal3f( 0.0f, -1.0f, 0.0f );
      for (i = 12; i < 16; i++ )
	  {
	      glTexCoord2f( data[5 * i], data[5 * i + 1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Right Face */
      glNormal3f( 1.0f, 0.0f, 0.0f );
      for ( i = 16; i < 20; i++ )
	  {
	      glTexCoord2f( data[5 * i], data[5 * i + 1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Left Face */
      glNormal3f( -1.0f, 0.0f, 0.0f );
      for ( i = 20; i < 24; i++ )
	  {
	      glTexCoord2f( data[5 * i], data[5 * i + 1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
    glEnd( );
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
	case SDLK_e:
	    /* 'e' key was pressed
	     * this toggles embossing
	     */
	    emboss = !emboss;
	    break;
	case SDLK_m:
	    /* 'm' key was pressed
	     * this toggles multitextured support
	     */
	    useMultitexture = ( ( !useMultitexture ) && multitextureSupported );
	    break;
	case SDLK_b:
	    /* 'b' key was pressed
	     * this toggles bumps
	     */
	    bumps = !bumps;
	    break;
	case SDLK_f:
	    /* 'f' key was pressed
	     * this pages through the different filters
	     */
	    filter = ( ++filter ) % 3;
	    break;
	case SDLK_PAGEUP:
	    /* PageUp key was pressed
	     * this zooms into the screen
	     */
	    z -= 0.02f;
	    break;
	case SDLK_PAGEDOWN:
	    /* PageDown key was pressed
	     * this zooms out of the screen
	     */
	    z += 0.02f;
	    break;
	case SDLK_UP:
	    /* Up arrow key was pressed
	     * this increases the x rotation speed
	     */
	    xspeed -= 0.01f;
	    break;
	case SDLK_DOWN:
	    /* Down arrow key was pressed
	     * this decreases the x rotation speed
	     */
	    xspeed += 0.01f;
	    break;
	case SDLK_RIGHT:
	    /* Right arrow key was pressed
	     * this increases the y rotation speed
	     */
	    yspeed += 0.01f;
	    break;
	case SDLK_LEFT:
	    /* Left arrow key was pressed
	     * this decreases the y rotation speed
	     */
	    yspeed -= 0.01f;
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

/* function to initialize lights */
void initLights( void )
{
    /* Load Light-Parameters into GL_LIGHT1 */
    glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient );
    glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse );
    glLightfv( GL_LIGHT1, GL_POSITION, LightPosition );
    glEnable( GL_LIGHT1 );
}

/* general OpenGL initialization function */
int initGL( GLvoid )
{

    multitextureSupported = initMultitexture( );

    /* Load in the texture */
    if ( !LoadGLTextures( ) )
	return FALSE;

    /* Enable Texture Mapping */
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

    initLights( );

    return( TRUE );
}

/* Calculates v=vM, M Is 4x4 In Column-Major,
 * v Is 4dim. Row (i.e. "Transposed")
 */
void VMatMult( GLfloat *M, GLfloat *v )
{
    GLfloat res[3];

    res[0]=M[0] * v[0] + M[1] * v[1] + M[2] * v[2] + M[3] * v[3];
    res[1]=M[4] * v[0] + M[5] * v[1] + M[6] * v[2] + M[7] * v[3];
    res[2]=M[8] * v[0] + M[9] * v[1] + M[0] * v[2] + M[11] * v[3];

    v[0] = res[0];
    v[1] = res[1];
    v[2] = res[2];
    v[3] = M[15]; /* Homogenous Coordinate */
}

/* Sets Up The Texture-Offsets
 * n : Normal On Surface. Must Be Of Length 1
 * c : Current Vertex On Surface
 * l : Lightposition
 * s : Direction Of s-Texture-Coordinate In Object Space (Must Be Normalized!)
 * t : Direction Of t-Texture-Coordinate In Object Space (Must Be Normalized!)
 */
void SetUpBumps( GLfloat *n, GLfloat *c, GLfloat *l, GLfloat *s, GLfloat *t )
{
    GLfloat v[3]; /* Vertex From Current Position To Light */
    GLfloat lenQ; /* Used To Normalize                     */

    /* Calculate v From Current Vertex c To Lightposition And Normalize v */
    v[0]  = l[0] - c[0];
    v[1]  = l[1] - c[1];
    v[2]  = l[2] - c[2];
    lenQ  = ( GLfloat )sqrt( v[0] * v[0] + v[1] * v[1] + v[2] * v[2] );
    v[0] /= lenQ;
    v[1] /= lenQ;
    v[2] /= lenQ;

    /* Project v Such That We Get Two Values Along Each
     * Texture-Coordinate Axis
     */
    c[0] =( s[0] * v[0] + s[1] * v[1] + s[2] * v[2] ) * MAX_EMBOSS;
    c[1] =( t[0] * v[0] + t[1] * v[1] + t[2] * v[2] ) * MAX_EMBOSS;
}

/* function to billboard two logos */
/* MUST CALL THIS LAST!!!, Billboards The Two Logos */
void doLogo( void )
{

    glDepthFunc( GL_ALWAYS );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glEnable( GL_BLEND );
    glDisable( GL_LIGHTING );
    glLoadIdentity( );
    glBindTexture( GL_TEXTURE_2D, glLogo );
    glBegin( GL_QUADS );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( 0.23f, -0.4f,  -1.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f( 0.53f, -0.4f,  -1.0f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f( 0.53f, -0.25f, -1.0f );
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( 0.23f, -0.25f, -1.0f );
    glEnd( );

    if ( useMultitexture )
	{
	    glBindTexture( GL_TEXTURE_2D, multiLogo );
	    glBegin( GL_QUADS );
	      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( -0.53f, -0.25f, -1.0f );
	      glTexCoord2f( 1.0f, 0.0f ); glVertex3f( -0.33f, -0.25f, -1.0f );
	      glTexCoord2f( 1.0f, 1.0f ); glVertex3f( -0.33f, -0.15f, -1.0f );
	      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( -0.53f, -0.15f, -1.0f );
	glEnd( );
	}
}

/* function to do bump-mapping without multitexturing */
bool doMesh1TexelUnits( void )
{
    /* Holds Current Vertex */
    GLfloat c[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* Normalized Normal Of Current Surface */
    GLfloat n[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* s-Texture Coordinate Direction, Normalized */
    GLfloat s[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* t-Texture Coordinate Direction, Normalized */
    GLfloat t[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* Holds Our Lightposition To Be Transformed Into Object Space */
    GLfloat l[4];
    /* Holds The Inverted Modelview Matrix To Do So */
    GLfloat Minv[16];
    int i;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    /* Build Inverse Modelview Matrix First. 
     * This Substitutes One Push/Pop With One glLoadIdentity();
     * Simply Build It By Doing All Transformations Negated And
     * In Reverse Order
     */
    glLoadIdentity( );
    glRotatef( -yrot, 0.0f, 1.0f, 0.0f );
    glRotatef( -xrot, 1.0f, 0.0f, 0.0f );
    glTranslatef( 0.0f, 0.0f, -z );
    glGetFloatv( GL_MODELVIEW_MATRIX, Minv );
    glLoadIdentity( );
    glTranslatef( 0.0f, 0.0f, z );
    glRotatef( xrot, 1.0f, 0.0f, 0.0f );
    glRotatef( yrot, 0.0f, 1.0f, 0.0f );

    /* Transform The Lightposition Into Object Coordinates: */
    l[0] = LightPosition[0];
    l[1] = LightPosition[1];
    l[2] = LightPosition[2];
    l[3] = 1.0f; /* Homogenous Coordinate */
    VMatMult( Minv, l );

    /* First pass rendering a cube only out of bump map */
    glBindTexture( GL_TEXTURE_2D, bump[filter] );
    glDisable( GL_BLEND );
    glDisable( GL_LIGHTING );
    doCube( );

    /* Second pass redndering a cube with correct emboss bump mapping,
     * but with no colors
     */
    glBindTexture( GL_TEXTURE_2D, invbump[filter] );
    glBlendFunc( GL_ONE, GL_ONE );
    glDepthFunc( GL_LEQUAL );
    glEnable( GL_BLEND );

    glBegin( GL_QUADS );
      /* Front Face */
      n[0] = 0.0f;
      n[1] = 0.0f;
      n[2] = 1.0f;
      s[0] = 1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 0; i < 4; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glTexCoord2f( data[5 * i] + c[0], data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Back Face */
      n[0] = 0.0f;
      n[1] = 0.0f;
      n[2] = -1.0f;
      s[0] = -1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 4; i < 8; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glTexCoord2f( data[5 * i] + c[0], data[5 * i + 1] + c[1] );
	      glVertex3f(data[5 * i + 2], data[5 * i + 3], data[5 * i + 4]);
	  }
      /* Top Face */
      n[0] = 0.0f;
      n[1] = 1.0f;
      n[2] = 0.0f;
      s[0] = 1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 0.0f;
      t[2] = -1.0f;
      for ( i = 8; i < 12; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glTexCoord2f( data[5 * i] + c[0], data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Bottom Face */
      n[0] = 0.0f;
      n[1] = -1.0f;
      n[2] = 0.0f;
      s[0] = -1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 0.0f;
      t[2] = -1.0f;
      for ( i = 12; i < 16; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glTexCoord2f( data[5 * i] + c[0], data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Right Face */
      n[0] = 1.0f;
      n[1] = 0.0f;
      n[2] = 0.0f;
      s[0] = 0.0f;
      s[1] = 0.0f;
      s[2] = -1.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 16; i < 20; i++ )
	  {
	      c[0] = data[5 * i +2];
	      c[1] = data[5 * i +3];
	      c[2] = data[5 * i +4];
	      SetUpBumps( n, c, l, s, t );
	      glTexCoord2f( data[5 * i] + c[0], data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4 ] );
	  }
      /* Left Face */
      n[0] = -1.0f;
      n[1] = 0.0f;
      n[2] = 0.0f;
      s[0] = 0.0f;
      s[1] = 0.0f;
      s[2] = 1.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 20; i < 24; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps(n,c,l,s,t);
	      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
	      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
	  }
    glEnd( );

    /* Third pass finishes rendering cube complete with lighting */
    if ( !emboss )
	{
	    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
	    glBindTexture( GL_TEXTURE_2D, texture[filter] );
	    glBlendFunc( GL_DST_COLOR, GL_SRC_COLOR );
	    glEnable( GL_LIGHTING );
	    doCube( );
	}

    xrot += xspeed;
    yrot += yspeed;
    if ( xrot > 360.0f )
	xrot -= 360.0f;
    if ( xrot < 0.0f )
	xrot += 360.0f;
    if ( yrot > 360.0f )
	yrot -= 360.0f;
    if ( yrot < 0.0f )
	yrot += 360.0f;

    /* LAST PASS: Do The Logos! */
    doLogo( );

    return TRUE;
}

/* same as doMesh1TexelUnits except in 2 passes using 2 texel units */
bool doMesh2TexelUnits( void )
{
    /* Holds Current Vertex */
    GLfloat c[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* Normalized Normal Of Current Surface */
    GLfloat n[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* s-Texture Coordinate Direction, Normalized */
    GLfloat s[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* t-Texture Coordinate Direction, Normalized */
    GLfloat t[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    /* Holds Our Lightposition To Be Transformed Into Object Space */
    GLfloat l[4];
    /* Holds The Inverted Modelview Matrix To Do So */
    GLfloat Minv[16];
    int i;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    /* Build Inverse Modelview Matrix First. This Substitutes
     * One Push/Pop With One glLoadIdentity();
     * Simply Build It By Doing All Transformations Negated And
     * In Reverse Order
     */
    glLoadIdentity( );
    glRotatef( -yrot, 0.0f, 1.0f, 0.0f );
    glRotatef( -xrot, 1.0f, 0.0f, 0.0f );
    glTranslatef( 0.0f, 0.0f, -z );
    glGetFloatv( GL_MODELVIEW_MATRIX, Minv );
    glLoadIdentity( );
    glTranslatef( 0.0f, 0.0f, z );

    glRotatef( xrot, 1.0f, 0.0f, 0.0f );
    glRotatef( yrot, 0.0f, 1.0f, 0.0f );

    /* Transform The Lightposition Into Object Coordinates: */
    l[0] = LightPosition[0];
    l[1] = LightPosition[1];
    l[2] = LightPosition[2];
    l[3] = 1.0f; /* Homogenous Coordinate */
    VMatMult( Minv, l );

    /* First Pass: 
     *
     * No Blending 
     * No Lighting 
     *
     *   Set up the texture-combiner 0 to 
     *
     * Use bump-texture 
     * Use not-offset texture-coordinates 
     * Texture-Operation GL_REPLACE, resulting in texture just being drawn 
     *
     *   Set up the texture-combiner 1 to 
     *
     * Offset texture-coordinates 
     * Texture-Operation GL_ADD, which is the multitexture-equivalent
     * to ONE, ONE- blending. 
     *
     *   This will render a cube consisting out of the grey-scale erode map. 
     */

    /* TEXTURE-UNIT #0 */
    glActiveTextureARB( GL_TEXTURE0_ARB );
    glEnable( GL_TEXTURE_2D );
    glBindTexture( GL_TEXTURE_2D, bump[filter] );
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT );
    glTexEnvf( GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_REPLACE );

    /* TEXTURE-UNIT #1 */
    glActiveTextureARB( GL_TEXTURE1_ARB );
    glEnable( GL_TEXTURE_2D );
    glBindTexture( GL_TEXTURE_2D, invbump[filter] );
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT );
    glTexEnvf( GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_ADD );

    // General Switches
    glDisable( GL_BLEND );
    glDisable( GL_LIGHTING );    

    glBegin( GL_QUADS );
      /* Front Face */
      n[0] = 0.0f;
      n[1] = 0.0f;
      n[2] = 1.0f;
      s[0] = 1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 0; i < 4; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[5 * i],
				    data[5 * i + 1] );
	      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[5 * i] + c[0],
				    data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Back Face */
      n[0] = 0.0f;
      n[1] = 0.0f;
      n[2] = -1.0f;
      s[0] = -1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 4; i < 8; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[5 * i],
				    data[5 * i + 1] );
	      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[5 * i] + c[0],
				    data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Top Face */
      n[0] = 0.0f;
      n[1] = 1.0f;
      n[2] = 0.0f;
      s[0] = 1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 0.0f;
      t[2] = -1.0f;
      for ( i = 8; i < 12; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[5 * i],
				    data[5 * i + 1] );
	      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[5 * i] + c[0],
				    data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i +4] );
	  }
      /* Bottom Face */
      n[0] = 0.0f;
      n[1] = -1.0f;
      n[2] = 0.0f;
      s[0] = -1.0f;
      s[1] = 0.0f;
      s[2] = 0.0f;
      t[0] = 0.0f;
      t[1] = 0.0f;
      t[2] = -1.0f;
      for ( i = 12; i < 16; i++ )
	  {
	      c[0] = data[5 * i +2];
	      c[1] = data[5 * i +3];
	      c[2] = data[5 * i +4];
	      SetUpBumps( n, c, l, s, t );
	      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[5 * i],
				    data[5 * i + 1] );
	      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[5 * i] + c[0],
				    data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Right Face */
      n[0] = 1.0f;
      n[1] = 0.0f;
      n[2] = 0.0f;
      s[0] = 0.0f;
      s[1] = 0.0f;
      s[2] = -1.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for ( i = 16; i < 20; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[5 * i],
				    data[5 * i + 1] );
	      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[5 * i] + c[0],
				    data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
      /* Left Face */
      n[0] = -1.0f;
      n[1] = 0.0f;
      n[2] = 0.0f;
      s[0] = 0.0f;
      s[1] = 0.0f;
      s[2] = 1.0f;
      t[0] = 0.0f;
      t[1] = 1.0f;
      t[2] = 0.0f;
      for (i = 20; i < 24; i++ )
	  {
	      c[0] = data[5 * i + 2];
	      c[1] = data[5 * i + 3];
	      c[2] = data[5 * i + 4];
	      SetUpBumps( n, c, l, s, t );
	      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[5 * i],
				    data[5 * i + 1] );
	      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[5 * i] + c[0],
				    data[5 * i + 1] + c[1] );
	      glVertex3f( data[5 * i + 2], data[5 * i + 3], data[5 * i + 4] );
	  }
    glEnd( );

    /* Second Pass 
     *
     * Use the base-texture 
     * Enable Lighting 
     * No offset texturre-coordinates => reset GL_TEXTURE-matrix 
     * Reset texture environment to GL_MODULATE in order to do
     * OpenGLLighting (doesn?t work otherwise!) 
     *
     *   This will render our complete bump-mapped cube. 
     */ 
    glActiveTextureARB( GL_TEXTURE1_ARB );
    glDisable( GL_TEXTURE_2D );
    glActiveTextureARB( GL_TEXTURE0_ARB );
    if ( !emboss )
	{
	    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
	    glBindTexture( GL_TEXTURE_2D, texture[filter] );
	    glBlendFunc( GL_DST_COLOR, GL_SRC_COLOR );
	    glEnable( GL_BLEND );
	    glEnable( GL_LIGHTING );
	    doCube( );
	}

    /* Last Pass 
     *
     * Update Geometry (esp. rotations) 
     * Do The Logos 
     */
    xrot += xspeed;
    yrot += yspeed;
    if ( xrot > 360.0f )
	xrot -= 360.0f;
    if ( xrot < 0.0f )
	xrot += 360.0f;
    if ( yrot > 360.0f )
	yrot -= 360.0f;
    if ( yrot < 0.0f )
	yrot += 360.0f;

    /* LAST PASS: Do The Logos! */
    doLogo( );

    return TRUE;
}

/* function to draw cube without bump mapping */
bool doMeshNoBumps( void )
{
    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    /* Reset The View */
    glLoadIdentity( );
    glTranslatef( 0.0f, 0.0f, z );

    glRotatef( xrot, 1.0f, 0.0f, 0.0f );
    glRotatef( yrot, 0.0f, 1.0f, 0.0f );

    if ( useMultitexture )
	{
	    glActiveTextureARB( GL_TEXTURE1_ARB );
	    glDisable( GL_TEXTURE_2D );
	    glActiveTextureARB( GL_TEXTURE0_ARB );
        }

    glDisable( GL_BLEND );
    glBindTexture( GL_TEXTURE_2D, texture[filter] );
    glBlendFunc( GL_DST_COLOR, GL_SRC_COLOR );
    glEnable( GL_LIGHTING );
    doCube( );

    xrot += xspeed;
    yrot += yspeed;
    if ( xrot > 360.0f )
	xrot -= 360.0f;
    if ( xrot < 0.0f )
	xrot += 360.0f;
    if ( yrot > 360.0f )
	yrot -= 360.0f;
    if ( yrot < 0.0f )
	yrot += 360.0f;

    /* LAST PASS: Do The Logos! */
    doLogo( );

    return TRUE;
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    if ( bumps )
	{
	    if ( useMultitexture && maxTexelUnits > 1 )
		{
		    if ( !( doMesh2TexelUnits( ) ) )
			return FALSE;
		}
	    else if ( !( doMesh1TexelUnits( ) ) )
		return FALSE;
	}
    else if ( !( doMeshNoBumps( ) ) )
	return FALSE;

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
