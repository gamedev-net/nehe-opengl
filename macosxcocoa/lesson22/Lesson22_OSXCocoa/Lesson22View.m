/*
 * Original Windows comment:
 * "This code was created by Jens Schneider (WizardSoft) 2000
 * Lesson22 to the series of OpenGL tutorials by NeHe-Production
 *
 * This code is loosely based upon Lesson06 by Jeff Molofee.
 *
 * contact me at: schneide@pool.informatik.rwth-aachen.de
 *
 * Basecode was created by Jeff Molofee 2000 
 * If you've found this code useful, please let me know. 
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson22View.m */

#import "Lesson22View.h"

@interface Lesson22View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (BOOL) initMultitexture;
- (void) initLights;
- (void) doCube;
- (void) doLogo;
- (BOOL) doMesh1TexelUnits;
- (BOOL) doMesh2TexelUnits;
- (BOOL) doMeshNoBumps;
- (void) setUpBumpsNormal:(GLfloat *)n currentVertex:(GLfloat *)c
         lightPos:(GLfloat *)l sTexCoord:(GLfloat *)s tTexCoord:(GLfloat *)t;
- (void) multMatrix:(GLfloat *)M withVector:(GLfloat *)v;
- (void) showInfoSheetTitle:(NSString *)title msgText:(NSString *)text;
@end

@implementation Lesson22View

// Ambient light, 20% white
static GLfloat LightAmbient[] = { 0.2f, 0.2f, 0.2f };
// Diffuse light, full white
static GLfloat LightDiffuse[] = { 1.0f, 1.0f, 1.0f };
// Position of diffuse light, somewhat in front of screen
static GLfloat LightPosition[] = { 0.0f, 0.0f, 2.0f };
static GLfloat Gray[] = { 0.5f, 0.5f, 0.5f, 1.0f };

// Data Contains The Faces For The Cube In Format 2xTexCoord, 3xVertex;
// Note That The Tesselation Of The Cube Is Only Absolute Minimum.
static GLfloat data[] =
   {
      // FRONT FACE
      0.0f, 0.0f,      -1.0f, -1.0f, +1.0f,
      1.0f, 0.0f,      +1.0f, -1.0f, +1.0f,
      1.0f, 1.0f,      +1.0f, +1.0f, +1.0f,
      0.0f, 1.0f,      -1.0f, +1.0f, +1.0f,
      // BACK FACE
      1.0f, 0.0f,      -1.0f, -1.0f, -1.0f,
      1.0f, 1.0f,      -1.0f, +1.0f, -1.0f,
      0.0f, 1.0f,      +1.0f, +1.0f, -1.0f,
      0.0f, 0.0f,      +1.0f, -1.0f, -1.0f,
      // Top Face
      0.0f, 1.0f,      -1.0f, +1.0f, -1.0f,
      0.0f, 0.0f,      -1.0f, +1.0f, +1.0f,
      1.0f, 0.0f,      +1.0f, +1.0f, +1.0f,
      1.0f, 1.0f,      +1.0f, +1.0f, -1.0f,
      // Bottom Face
      1.0f, 1.0f,      -1.0f, -1.0f, -1.0f,
      0.0f, 1.0f,      +1.0f, -1.0f, -1.0f,
      0.0f, 0.0f,      +1.0f, -1.0f, +1.0f,
      1.0f, 0.0f,      -1.0f, -1.0f, +1.0f,
      // Right Face
      1.0f, 0.0f,      +1.0f, -1.0f, -1.0f,
      1.0f, 1.0f,      +1.0f, +1.0f, -1.0f,
      0.0f, 1.0f,      +1.0f, +1.0f, +1.0f,
      0.0f, 0.0f,      +1.0f, -1.0f, +1.0f,
      // Left Face
      0.0f, 0.0f,      -1.0f, -1.0f, -1.0f,
      1.0f, 0.0f,      -1.0f, -1.0f,  1.0f,
      1.0f, 1.0f,      -1.0f,  1.0f,  1.0f,
      0.0f, 1.0f,      -1.0f,  1.0f, -1.0f
};

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   xrot = yrot = 0;
   z = -5.0f;
   emboss = FALSE;
   bumps = TRUE;
   multitextureSupported = FALSE;
   useMultitexture = TRUE;
   maxTexelUnits = 1;
   filter = 1;
   pixelFormat = [ self createPixelFormat:frame ];
   if( pixelFormat != nil )
   {
      self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
      [ pixelFormat release ];
      if( self )
      {
         [ [ self openGLContext ] makeCurrentContext ];
         if( runningFullScreen )
            [ [ self openGLContext ] setFullScreen ];
         [ self reshape ];
         if( ![ self initGL ] )
         {
            [ self clearGLContext ];
            self = nil;
         }
      }
   }
   else
      self = nil;

   return self;
}


/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
   NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
   int pixNum = 0;
   NSDictionary *fullScreenMode;
   NSOpenGLPixelFormat *pixelFormat;

   pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
   pixelAttribs[ pixNum++ ] = colorBits;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
   pixelAttribs[ pixNum++ ] = depthBits;

   if( runningFullScreen )  // Do this before getting the pixel format
   {
      pixelAttribs[ pixNum++ ] = NSOpenGLPFAFullScreen;
      fullScreenMode = (NSDictionary *) CGDisplayBestModeForParameters(
                                           kCGDirectMainDisplay,
                                           colorBits, frame.size.width,
                                           frame.size.height, NULL );
      CGDisplayCapture( kCGDirectMainDisplay );
      CGDisplayHideCursor( kCGDirectMainDisplay );
      CGDisplaySwitchToMode( kCGDirectMainDisplay,
                             (CFDictionaryRef) fullScreenMode );
   }
   pixelAttribs[ pixNum ] = 0;
   pixelFormat = [ [ NSOpenGLPixelFormat alloc ]
                   initWithAttributes:pixelAttribs ];

   return pixelFormat;
}


/*
 * Enable/disable full screen mode
 */
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame
{
   BOOL success = FALSE;
   NSOpenGLPixelFormat *pixelFormat;
   NSOpenGLContext *newContext;

   [ [ self openGLContext ] clearDrawable ];
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   runningFullScreen = enableFS;
   pixelFormat = [ self createPixelFormat:frame ];
   if( pixelFormat != nil )
   {
      newContext = [ [ NSOpenGLContext alloc ] initWithFormat:pixelFormat
                     shareContext:nil ];
      if( newContext != nil )
      {
         [ super setFrame:frame ];
         [ super setOpenGLContext:newContext ];
         [ newContext makeCurrentContext ];
         if( runningFullScreen )
            [ newContext setFullScreen ];
         [ self reshape ];
         if( [ self initGL ] )
            success = TRUE;
      }
      [ pixelFormat release ];
   }
   if( !success && runningFullScreen )
      [ self switchToOriginalDisplayMode ];

   return success;
}


/*
 * Switch to the display mode in which we originally began
 */
- (void) switchToOriginalDisplayMode
{
   CGDisplaySwitchToMode( kCGDirectMainDisplay,
                          (CFDictionaryRef) originalDisplayMode );
   CGDisplayShowCursor( kCGDirectMainDisplay );
   CGDisplayRelease( kCGDirectMainDisplay );
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{
   multitextureSupported = [ self initMultitexture ];
   if( ![ self loadGLTextures ] )
      return FALSE;

   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   [ self initLights ];   // Initialize OpenGL light
   
   return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;
   NSString *resourcePath = [ [ NSBundle mainBundle ] resourcePath ];
   int i, a;
   char *alpha;

   if( [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "Base.bmp" ] intoIndex:0 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "Bump.bmp" ] intoIndex:1 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "OpenGL_Alpha.bmp" ] intoIndex:2 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "OpenGL.bmp" ] intoIndex:3 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                      "Multi_On_Alpha.bmp" ] intoIndex:4 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "Multi_On.bmp" ] intoIndex:5 ] )
   {
      status = TRUE;

      glGenTextures( 3, texture );   // Create the textures

      // Create nearest filtered texture
      glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );
      // Create linear filtered texture
      glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );
      // Create mipmapped texture
      glBindTexture( GL_TEXTURE_2D, texture[ 2 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                       GL_LINEAR_MIPMAP_NEAREST );
      gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB8, texSize[ 0 ].width,
                         texSize[ 0 ].height, texFormat[ 0 ],
                         GL_UNSIGNED_BYTE, texBytes[ 0 ] );

      free( texBytes[ 0 ] );

      // Load the bumpmaps
      glPixelTransferf( GL_RED_SCALE, 0.5f );     // Scale RGB by 50%, so
      glPixelTransferf( GL_GREEN_SCALE, 0.5f );   // that we only have
      glPixelTransferf( GL_BLUE_SCALE, 0.5f );    // half intensity
      // No wrapping, please
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );
      glTexParameterfv( GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, Gray );
      glGenTextures( 3, bump );
      // Create nearest filtered texture
      glBindTexture( GL_TEXTURE_2D, bump[ 0 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, texSize[ 1 ].width,
                    texSize[ 1 ].height, 0, texFormat[ 1 ],
                    GL_UNSIGNED_BYTE, texBytes[ 1 ] );
      // Create linear filtered texture
      glBindTexture( GL_TEXTURE_2D, bump[ 1 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, texSize[ 1 ].width,
                    texSize[ 1 ].height, 0, texFormat[ 1 ],
                    GL_UNSIGNED_BYTE, texBytes[ 1 ] );
      // Create mipmapped texture
      glBindTexture( GL_TEXTURE_2D, bump[ 2 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                       GL_LINEAR_MIPMAP_NEAREST );
      gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB8, texSize[ 1 ].width,
                         texSize[ 1 ].height, texFormat[ 1 ],
                         GL_UNSIGNED_BYTE, texBytes[ 1 ] );

      // Invert the bumpmap
      for( i = 0; i < 3 * texSize[ 1 ].width * texSize[ 1 ].height; i++ )
         texBytes[ 1 ][ i ] = 255 - texBytes[ 1 ][ i ];
      glGenTextures( 3, invbump );
      // Create nearest filtered texture
      glBindTexture( GL_TEXTURE_2D, invbump[ 0 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, texSize[ 1 ].width,
                    texSize[ 1 ].height, 0, texFormat[ 1 ],
                    GL_UNSIGNED_BYTE, texBytes[ 1 ] );
      // Create linear filtered texture
      glBindTexture( GL_TEXTURE_2D, invbump[ 1 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB8, texSize[ 1 ].width,
                    texSize[ 1 ].height, 0, texFormat[ 1 ],
                    GL_UNSIGNED_BYTE, texBytes[ 1 ] );
      // Create mipmapped texture
      glBindTexture( GL_TEXTURE_2D, invbump[ 2 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                       GL_LINEAR_MIPMAP_NEAREST );
      gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB8, texSize[ 1 ].width,
                         texSize[ 1 ].height, texFormat[ 1 ],
                         GL_UNSIGNED_BYTE, texBytes[ 1 ] );
      glPixelTransferf( GL_RED_SCALE, 1.0f );     // Scale RGB Back To 100% Again
      glPixelTransferf( GL_GREEN_SCALE, 1.0f );
      glPixelTransferf( GL_BLUE_SCALE, 1.0f );

      free( texBytes[ 1 ] );

      // Setup the logo bitmaps
      alpha = calloc( 4 * texSize[ 2 ].width * texSize[ 2 ].height, 1 );
      for( a = 0; a < texSize[ 2 ].width * texSize[ 2 ].height; a++ )
      {
         // Pick only red value as alpha
         alpha[ 4 * a + 3 ] = texBytes[ 2 ][ a * 3 ];
      }
      free( texBytes[ 2 ] );

      for( a = 0; a < texSize[ 3 ].width * texSize[ 3 ].height; a++ )
      {
         alpha[ 4 * a ] = texBytes[ 3 ][ a * 3 ];           // R
         alpha[ 4 * a + 1 ] = texBytes[ 3 ][ a * 3 + 1 ];   // G
         alpha[ 4 * a + 2 ] = texBytes[ 3 ][ a * 3 + 2 ];   // B
      }
      free( texBytes[ 3 ] );

      glGenTextures( 1, &glLogo );
      // Create linear filtered RGBA8 texture
      glBindTexture( GL_TEXTURE_2D, glLogo );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, texSize[ 3 ].width,
                    texSize[ 3 ].height, 0, GL_RGBA,
                    GL_UNSIGNED_BYTE, alpha );
      free( alpha );

      // Setup the "extension-enabled" logo
      alpha = calloc( 4 * texSize[ 4 ].width * texSize[ 4 ].height, 1 );
      for( a = 0; a < texSize[ 4 ].width * texSize[ 4 ].height; a++ )
      {
         // Pick only red value as alpha
         alpha[ 4 * a + 3 ] = texBytes[ 4 ][ a * 3 ];
      }
      free( texBytes[ 4 ] );

      for( a = 0; a < texSize[ 4 ].width * texSize[ 4 ].height; a++ )
      {
         alpha[ 4 * a ] = texBytes[ 4 ][ a * 3 ];           // R
         alpha[ 4 * a + 1 ] = texBytes[ 4 ][ a * 3 + 1 ];   // G
         alpha[ 4 * a + 2 ] = texBytes[ 4 ][ a * 3 + 2 ];   // B
      }
      free( texBytes[ 5 ] );

      glGenTextures( 1, &multiLogo );
      // Create linear filtered RGBA8 texture
      glBindTexture( GL_TEXTURE_2D, multiLogo );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, texSize[ 5 ].width,
                    texSize[ 5 ].height, 0, GL_RGBA,
                    GL_UNSIGNED_BYTE, alpha );
      free( alpha );
   }

   return status;
}


/*
 * The NSBitmapImageRep is going to load the bitmap, but it will be
 * setup for the opposite coordinate system than what OpenGL uses, so
 * we copy things around.
 */
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex
{
   BOOL success = FALSE;
   NSBitmapImageRep *theImage;
   int bitsPPixel, bytesPRow;
   unsigned char *theImageData;
   int rowNum, destRowNum;

   theImage = [ NSBitmapImageRep imageRepWithContentsOfFile:filename ];
   if( theImage != nil )
   {
      bitsPPixel = [ theImage bitsPerPixel ];
      bytesPRow = [ theImage bytesPerRow ];
      if( bitsPPixel == 24 )        // No alpha channel
         texFormat[ texIndex ] = GL_RGB;
      else if( bitsPPixel == 32 )   // There is an alpha channel
         texFormat[ texIndex ] = GL_RGBA;
      texSize[ texIndex ].width = [ theImage pixelsWide ];
      texSize[ texIndex ].height = [ theImage pixelsHigh ];
      texBytes[ texIndex ] = calloc( bytesPRow * texSize[ texIndex ].height,
                                     1 );
      if( texBytes[ texIndex ] != NULL )
      {
         success = TRUE;
         theImageData = [ theImage bitmapData ];
         destRowNum = 0;
         for( rowNum = texSize[ texIndex ].height - 1; rowNum >= 0;
              rowNum--, destRowNum++ )
         {
            // Copy the entire row in one shot
            memcpy( texBytes[ texIndex ] + ( destRowNum * bytesPRow ),
                    theImageData + ( rowNum * bytesPRow ),
                    bytesPRow );
         }
      }
   }

   return success;
}


/*
 * Checks at run-rime if multitexturing is supported (use gluCheckExtension()
 * as OS X supports GLU 1.3).
 */
- (BOOL) initMultitexture
{
   const char *extensions;

   // Fetch Extension String
   extensions = glGetString( GL_EXTENSIONS );

#ifdef EXT_INFO
   [ self showInfoSheetTitle:@"Supported GL extensions"
          msgText:[ NSString stringWithCString:extensions ] ];
#endif

   /*
    * Check for multitexturing, ARB_texture_env_combine (not the EXT version,
    * as the ARB is more standard; switch to EXT version if needed), and
    * see if ARB is enabled
    */
   if( gluCheckExtension( "GL_ARB_multitexture", extensions ) &&
       __ARB_ENABLE && gluCheckExtension( "GL_ARB_texture_env_combine",
                                          extensions ) )
   {
      glGetIntegerv( GL_MAX_TEXTURE_UNITS_ARB, &maxTexelUnits );
#ifdef EXT_INFO
      [ self showInfoSheetTitle:@"Feature supported"
             msgText:@"The GL_ARB_multitexture extension will be used." ];
#endif
      return TRUE;
   }
   useMultitexture = FALSE;   // We Can't Use It If It Isn't Supported!

   return FALSE;
}


- (void) initLights
{
   // Load light parameters into GL_LIGHT1 and enable it
   glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient );
   glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse );
   glLightfv( GL_LIGHT1, GL_POSITION, LightPosition );
   glEnable( GL_LIGHT1 );
}


/*
 * Resize ourself
 */
- (void) reshape
{ 
   NSRect sceneBounds;
   
   [ [ self openGLContext ] update ];
   sceneBounds = [ self bounds ];
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   if( bumps )
   {
      if( useMultitexture && maxTexelUnits > 1 )
         [ self doMesh2TexelUnits ];
      else
         [ self doMesh1TexelUnits ];
   }
   else
      [ self doMeshNoBumps ];

   [ [ self openGLContext ] flushBuffer ];
}


- (void) doCube
{
   int i;

   glBegin( GL_QUADS );
   // Front face
   glNormal3f( 0.0f, 0.0f, +1.0f );
   for( i = 0; i < 4; i++ )
   {
      glTexCoord2f( data[ 5 * i ], data[ 5 * i + 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Back Face
   glNormal3f( 0.0f, 0.0f, -1.0f );
   for( i = 4; i < 8; i++ )
   {
      glTexCoord2f( data[ 5 * i ], data[ 5 * i + 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Top Face
   glNormal3f( 0.0f, 1.0f, 0.0f );
   for( i = 8; i < 12; i++ )
   {
      glTexCoord2f( data[ 5 * i ], data[ 5 * i + 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Bottom Face
   glNormal3f( 0.0f, -1.0f, 0.0f );
   for( i = 12; i < 16; i++ )
   {
      glTexCoord2f( data[ 5 * i ], data[ 5 * i + 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Right face
   glNormal3f( 1.0f, 0.0f, 0.0f );
   for( i = 16; i < 20; i++ )
   {
      glTexCoord2f( data[ 5 * i ], data[ 5 * i + 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Left Face
   glNormal3f( -1.0f, 0.0f, 0.0f );
   for( i = 20; i < 24; i++ )
   {
      glTexCoord2f( data[ 5 * i ], data[ 5 * i + 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   glEnd();
}


/*
 * Must call this last; billboards the two logos.
 */
- (void) doLogo
{
   glDepthFunc( GL_ALWAYS );
   glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
   glEnable( GL_BLEND );
   glDisable( GL_LIGHTING );
   glLoadIdentity();
   glBindTexture( GL_TEXTURE_2D, glLogo );
   glBegin( GL_QUADS );
   glTexCoord2f( 0.0f, 0.0f );   glVertex3f( 0.23f, -0.4f, -1.0f );
   glTexCoord2f( 1.0f, 0.0f );   glVertex3f( 0.53f, -0.4f, -1.0f );
   glTexCoord2f( 1.0f, 1.0f );   glVertex3f( 0.53f, -0.25f, -1.0f );
   glTexCoord2f( 0.0f, 1.0f );   glVertex3f( 0.23f, -0.25f, -1.0f );
   glEnd();
   if( useMultitexture )
   {
      glBindTexture( GL_TEXTURE_2D, multiLogo );
      glBegin( GL_QUADS );
      glTexCoord2f( 0.0f, 0.0f );   glVertex3f( -0.53f, -0.4f, -1.0f );
      glTexCoord2f( 1.0f, 0.0f );   glVertex3f( -0.33f, -0.4f, -1.0f );
      glTexCoord2f( 1.0f, 1.0f );   glVertex3f( -0.33f, -0.3f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f );   glVertex3f( -0.53f, -0.3f, -1.0f );
      glEnd();
   }
   glDepthFunc( GL_LEQUAL );
}


/*
 * Okay, Here Comes The Important Stuff:
 *
 * On http://www.nvidia.com/marketing/Developer/DevRel.nsf/TechnicalDemosFrame?OpenPage
 * You Can Find A Demo Called GL_BUMP That Is A Little Bit More Complicated.
 * GL_BUMP:   Copyright Diego T?ara, 1999.
 *            -  diego_tartara@ciudad.com.ar  -
 *
 * The Idea Behind GL_BUMP Is, That You Compute The Texture-Coordinate Offset
 * As Follows:
 *   0) All Coordinates Either In Object Or In World Space.
 *   1) Calculate Vertex v From Actual Position (The Vertex You're At) To
 *      The Lightposition
 *   2) Normalize v
 *   3) Project This v Into Tangent Space.
 *      Tangent Space Is The Plane "Touching" The Object In Our Current
 *      Position On It.  Typically, If You're Working With Flat Surfaces,
 *      This Is The Surface Itself.
 *   4) Offset s,t-Texture-Coordinates By The Projected v's x And
 *      y-Component.
 *
 *   * This Would Be Called Once Per Vertex In Our Geometry, If Done
 *     Correctly.  This Might Lead To Incoherencies In Our Texture
 *     Coordinates, But Is Ok As Long As You Did Not Wrap The Bumpmap.
 *
 * Basically, We Do It The Same Way With Some Exceptions:
 *   ad 0) We'll Work In Object Space All Time. This Has The Advantage That
 *         We'll Only Have To Transform The Lightposition From Frame To
 *         Frame. This Position Obviously Has To Be Transformed Using The
 *         Inversion Of The Modelview Matrix. This Is, However, A
 *         Considerable Drawback, If You Don't Know How Your Modelview
 *         Matrix Was Built, Since Inverting A Matrix Is Costly And
 *         Complicated.
 *   ad 1) Do It Exactly That Way.
 *   ad 2) Do It Exactly That Way.
 *   ad 3) To Project The Lightvector Into Tangent Space, We'll Support The
 *         Setup-Routine With Two Directions: One Of Increasing
 *         s-Texture-Coordinate Axis, The Other In Increasing
 *         t-Texture-Coordinate Axis. The Projection Simply Is (Assumed Both
 *         texCoord Vectors And The Lightvector Are Normalized) The
 *         Dotproduct Between The Respective texCoord Vector And The
 *         Lightvector.
 *   ad 4) The Offset Is Computed By Taking The Result Of Step 3 And
 *         Multiplying The Two Numbers With MAX_EMBOSS, A Constant That
 *         Specifies How Much Quality We're Willing To Trade For Stronger
 *         Bump-Effects. Just Temper A Little Bit With MAX_EMBOSS!
 *
 * WHY THIS IS COOL:
 *   * Have A Look!
 *   * Very Cheap To Implement (About One Squareroot And A Couple Of MULs)!
 *   * Can Even Be Further Optimized!
 *   * SetUpBump Doesn't Disturb glBegin()/glEnd()
 *   * THIS DOES ALWAYS WORK - Not Only With XY-Tangent Spaces!!
 *
 * DRAWBACKS:
 *   * Must Know "Structure" Of Modelview-Matrix Or Invert It. Possible To
 *     Do The Whole Thing In World Space, But This Involves One
 *     Transformation For Each Vertex!
*/


- (BOOL) doMesh1TexelUnits
{
   // Holds Current Vertex
   GLfloat c[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // Normal Of Current Surface
   GLfloat n[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // s-Texture Coordinate Direction, Normalized
   GLfloat s[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // t-Texture Coordinate Direction, Normalized
   GLfloat t[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // Holds Our Lightposition To Be Transformed Into Object Space
   GLfloat l[ 4 ];
   GLfloat Minv[ 16 ];   // Holds The Inverted Modelview Matrix To Do So.
   int i;

   // Clear The Screen And The Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

   /*
    * Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With
    * One glLoadIdentity(); Simply Build It By Doing All Transformations
    * Negated And In Reverse Order.
    */
   glLoadIdentity();                                                        
   glRotatef( -yrot, 0.0f, 1.0f, 0.0f );
   glRotatef( -xrot, 1.0f, 0.0f, 0.0f );
   glTranslatef( 0.0f, 0.0f, -z );
   glGetFloatv( GL_MODELVIEW_MATRIX, Minv );
   glLoadIdentity();
   glTranslatef( 0.0f, 0.0f, z );
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );

   // Transform The Lightposition Into Object Coordinates:
   l[ 0 ] = LightPosition[ 0 ];
   l[ 1 ] = LightPosition[ 1 ];
   l[ 2 ] = LightPosition[ 2 ];
   l[ 3 ] = 1.0f;   // Homogenous Coordinate
   [ self multMatrix:Minv withVector:l ];

   /*
    * PASS#1: Use Texture "Bump"
    *             No Blend
    *             No Lighting
    *             No Offset Texture-Coordinates
    */
   glBindTexture( GL_TEXTURE_2D, bump[ filter ] );
   glDisable( GL_BLEND );
   glDisable( GL_LIGHTING );
   [ self doCube ];

   /*
    * PASS#2:      Use Texture "Invbump"
    *                  Blend GL_ONE To GL_ONE
    *                  No Lighting
    *                  Offset Texture Coordinates
    */
   glBindTexture( GL_TEXTURE_2D, invbump[ filter ] );
   glBlendFunc( GL_ONE, GL_ONE );
   glDepthFunc( GL_LEQUAL );
   glEnable( GL_BLEND );

   glBegin( GL_QUADS );
   // Front Face
   n[ 0 ] = 0.0f;   n[ 1 ] = 0.0f;   n[ 2 ] = 1.0f;
   s[ 0 ] = 1.0f;   s[ 1 ] = 0.0f;   s[ 2 ] = 0.0f;
   t[ 0 ] = 0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] = 0.0f;
   for( i = 0; i < 4; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glTexCoord2f( data[ 5 * i ] + c[ 0 ], data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Back Face
   n[ 0 ] =  0.0f;   n[ 1 ] = 0.0f;   n[ 2 ] = -1.0f;
   s[ 0 ] = -1.0f;   s[ 1 ] = 0.0f;   s[ 2 ] =  0.0f;
   t[ 0 ] =  0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] =  0.0f;
   for( i = 4; i < 8; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glTexCoord2f( data[ 5 * i ] + c[ 0 ], data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Top Face
   n[ 0 ] = 0.0f;   n[ 1 ] = 1.0f;   n[ 2 ] =  0.0f;
   s[ 0 ] = 1.0f;   s[ 1 ] = 0.0f;   s[ 2 ] =  0.0f;
   t[ 0 ] = 0.0f;   t[ 1 ] = 0.0f;   t[ 2 ] = -1.0f;
   for( i = 8; i < 12; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glTexCoord2f( data[ 5 * i ] + c[ 0 ], data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Bottom Face
   n[ 0 ] =  0.0f;   n[ 1 ] = -1.0f;   n[ 2 ] =  0.0f;
   s[ 0 ] = -1.0f;   s[ 1 ] =  0.0f;   s[ 2 ] =  0.0f;
   t[ 0 ] =  0.0f;   t[ 1 ] =  0.0f;   t[ 2 ] = -1.0f;
   for( i = 12; i < 16; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glTexCoord2f( data[ 5 * i ] + c[ 0 ], data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Right Face
   n[ 0 ] = 1.0f;   n[ 1 ] = 0.0f;   n[ 2 ] =  0.0f;
   s[ 0 ] = 0.0f;   s[ 1 ] = 0.0f;   s[ 2 ] = -1.0f;
   t[ 0 ] = 0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] =  0.0f;
   for( i = 16; i < 20; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glTexCoord2f( data[ 5 * i ] + c[ 0 ], data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Left Face
   n[ 0 ] = -1.0f;   n[ 1 ] = 0.0f;   n[ 2 ] = 0.0f;
   s[ 0 ] =  0.0f;   s[ 1 ] = 0.0f;   s[ 2 ] = 1.0f;
   t[ 0 ] =  0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] = 0.0f;
   for( i = 20; i < 24; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glTexCoord2f( data[ 5 * i ] + c[ 0 ], data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   glEnd();

   /*
    * PASS#3:      Use Texture "Base"
    *                  Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
    *                  Lighting Enabled
    *                  No Offset Texture-Coordinates
    */
   if( !emboss )
   {
      glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
      glBindTexture( GL_TEXTURE_2D, texture[ filter ] );
      glBlendFunc( GL_DST_COLOR, GL_SRC_COLOR );
      glEnable( GL_LIGHTING );
      [ self doCube ];
   }

   xrot += xspeed;
   yrot += yspeed;
   if( xrot > 360.0f )
      xrot -= 360.0f;
   if( xrot < 0.0f )
      xrot += 360.0f;
   if( yrot > 360.0f )
      yrot -= 360.0f;
   if( yrot < 0.0f )
      yrot += 360.0f;

   // LAST PASS:      Do The Logos!
   [ self doLogo ];

   return TRUE;   // Keep Going
}


- (BOOL) doMesh2TexelUnits
{
   // holds current vertex
   GLfloat c[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // normalized normal of current surface
   GLfloat n[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // s-texture coordinate direction, normalized
   GLfloat s[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // t-texture coordinate direction, normalized
   GLfloat t[ 4 ] = { 0.0f, 0.0f, 0.0f, 1.0f };
   // holds our lightposition to be transformed into object space
   GLfloat l[ 4 ];
   GLfloat Minv[ 16 ];   // holds the inverted modelview matrix to do so.
   int i;

   // Clear The Screen And The Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

   /*
    * Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With
    * One glLoadIdentity(); Simply Build It By Doing All Transformations
    * Negated And In Reverse Order.
    */
   glLoadIdentity();
   glRotatef( -yrot, 0.0f, 1.0f, 0.0f );
   glRotatef( -xrot, 1.0f, 0.0f, 0.0f );
   glTranslatef( 0.0f, 0.0f, -z );
   glGetFloatv( GL_MODELVIEW_MATRIX, Minv );
   glLoadIdentity();
   glTranslatef( 0.0f, 0.0f, z );
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );

   // Transform The Lightposition Into Object Coordinates:
   l[ 0 ] = LightPosition[ 0 ];
   l[ 1 ] = LightPosition[ 1 ];
   l[ 2 ] = LightPosition[ 2 ];
   l[ 3 ] = 1.0f;   // Homogenous Coordinate
   [ self multMatrix:Minv withVector:l ];

   /*
    * PASS#1: Texel-Unit 0:   Use Texture "Bump"
    *                             No Blend
    *                             No Lighting
    *                             No Offset Texture-Coordinates
    *                             Texture-Operation "Replace"
    *         Texel-Unit 1:   Use Texture "Invbump"
    *                             No Lighting
    *                             Offset Texture Coordinates
    *                             Texture-Operation "Replace"
    */
   // TEXTURE-UNIT #0
   glActiveTextureARB( GL_TEXTURE0_ARB );
   glEnable( GL_TEXTURE_2D );
   glBindTexture( GL_TEXTURE_2D, bump[ filter ] );
   glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_ARB );
   glTexEnvf( GL_TEXTURE_ENV, GL_COMBINE_RGB_ARB, GL_REPLACE );
   // TEXTURE-UNIT #1:
   glActiveTextureARB( GL_TEXTURE1_ARB );
   glEnable( GL_TEXTURE_2D );
   glBindTexture( GL_TEXTURE_2D, invbump[ filter ] );
   glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_ARB );
   glTexEnvf( GL_TEXTURE_ENV, GL_COMBINE_RGB_ARB, GL_ADD );
   // General Switches:
   glDisable( GL_BLEND );
   glDisable( GL_LIGHTING );
   glBegin( GL_QUADS );
   // Front Face
   n[ 0 ] = 0.0f;   n[ 1 ] = 0.0f;   n[ 2 ] = 1.0f;
   s[ 0 ] = 1.0f;   s[ 1 ] = 0.0f;   s[ 2 ] = 0.0f;
   t[ 0 ] = 0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] = 0.0f;
   for( i = 0; i < 4; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[ 5 * i ], data[ 5 * i + 1 ] );
      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[ 5 * i ] + c[ 0 ],
                            data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Back Face
   n[ 0 ] =  0.0f;   n[ 1 ] = 0.0f;   n[ 2 ] = -1.0f;
   s[ 0 ] = -1.0f;   s[ 1 ] = 0.0f;   s[ 2 ] =  0.0f;
   t[ 0 ] =  0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] =  0.0f;
   for( i = 4; i < 8; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[ 5 * i ], data[ 5 * i + 1 ] );
      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[ 5 * i ] + c[ 0 ],
                            data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Top Face
   n[ 0 ] = 0.0f;   n[ 1 ] = 1.0f;   n[ 2 ] =  0.0f;
   s[ 0 ] = 1.0f;   s[ 1 ] = 0.0f;   s[ 2 ] =  0.0f;
   t[ 0 ] = 0.0f;   t[ 1 ] = 0.0f;   t[ 2 ] = -1.0f;
   for( i = 8; i < 12; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[ 5 * i ], data[ 5 * i + 1 ] );
      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[ 5 * i ] + c[ 0 ],
                            data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Bottom Face
   n[ 0 ] =  0.0f;   n[ 1 ] = -1.0f;   n[ 2 ] =  0.0f;
   s[ 0 ] = -1.0f;   s[ 1 ] =  0.0f;   s[ 2 ] =  0.0f;
   t[ 0 ] =  0.0f;   t[ 1 ] =  0.0f;   t[ 2 ] = -1.0f;
   for( i = 12; i < 16; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[ 5 * i ], data[ 5 * i + 1 ] );
      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[ 5 * i ] + c[ 0 ],
                            data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Right Face
   n[ 0 ] = 1.0f;   n[ 1 ] = 0.0f;   n[ 2 ] =  0.0f;
   s[ 0 ] = 0.0f;   s[ 1 ] = 0.0f;   s[ 2 ] = -1.0f;
   t[ 0 ] = 0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] =  0.0f;
   for( i = 16; i < 20; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[ 5 * i ], data[ 5 * i + 1 ] );
      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[ 5 * i ] + c[ 0 ],
                            data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   // Left Face
   n[ 0 ] = -1.0f;   n[ 1 ] = 0.0f;   n[ 2 ] = 0.0f;
   s[ 0 ] =  0.0f;   s[ 1 ] = 0.0f;   s[ 2 ] = 1.0f;
   t[ 0 ] =  0.0f;   t[ 1 ] = 1.0f;   t[ 2 ] = 0.0f;
   for( i = 20; i < 24; i++ )
   {
      c[ 0 ] = data[ 5 * i + 2 ];
      c[ 1 ] = data[ 5 * i + 3 ];
      c[ 2 ] = data[ 5 * i + 4 ];
      [ self setUpBumpsNormal:n currentVertex:c lightPos:l sTexCoord:s
             tTexCoord:t ];
      glMultiTexCoord2fARB( GL_TEXTURE0_ARB, data[ 5 * i ], data[ 5 * i + 1 ] );
      glMultiTexCoord2fARB( GL_TEXTURE1_ARB, data[ 5 * i ] + c[ 0 ],
                            data[ 5 * i + 1 ] + c[ 1 ] );
      glVertex3f( data[ 5 * i + 2 ], data[ 5 * i + 3 ], data[ 5 * i + 4 ] );
   }
   glEnd();

   /*
    * PASS#2       Use Texture "Base"
    *                  Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
    *                  Lighting Enabled
    *                  No Offset Texture-Coordinates
    */
   glActiveTextureARB( GL_TEXTURE1_ARB );
   glDisable( GL_TEXTURE_2D );
   glActiveTextureARB( GL_TEXTURE0_ARB );
   if( !emboss )
   {
      glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
      glBindTexture( GL_TEXTURE_2D, texture[ filter ] );
      glBlendFunc( GL_DST_COLOR, GL_SRC_COLOR );
      glEnable( GL_BLEND );
      glEnable( GL_LIGHTING );
      [ self doCube ];
   }

   xrot += xspeed;
   yrot += yspeed;
   if( xrot > 360.0f )
      xrot -= 360.0f;
   if( xrot < 0.0f )
      xrot += 360.0f;
   if( yrot > 360.0f )
      yrot -= 360.0f;
   if( yrot < 0.0f )
      yrot += 360.0f;

   // LAST PASS:   Do The Logos!
   [ self doLogo ];

   return TRUE;    // Keep Going
}


- (BOOL) doMeshNoBumps
{
   // Clear The Screen And The Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset The View
   glTranslatef( 0.0f, 0.0f, z );
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );
   if( useMultitexture )
   {
      glActiveTextureARB( GL_TEXTURE1_ARB );
      glDisable( GL_TEXTURE_2D );
      glActiveTextureARB( GL_TEXTURE0_ARB );
   }
   glDisable( GL_BLEND );
   glBindTexture( GL_TEXTURE_2D, texture[ filter ] );
   glBlendFunc( GL_DST_COLOR, GL_SRC_COLOR );
   glEnable( GL_LIGHTING );
   [ self doCube ];

   xrot += xspeed;
   yrot += yspeed;
   if( xrot > 360.0f )
      xrot -= 360.0f;
   if( xrot < 0.0f )
      xrot += 360.0f;
   if( yrot > 360.0f )
      yrot -= 360.0f;
   if( yrot < 0.0f )
      yrot += 360.0f;

   // LAST PASS:   Do The Logos!
   [ self doLogo ];

   return true;   // Keep Going
}


/*
 * Sets up the texture offsets.
 * n - normal on surface; must be length 1
 * c - current vertex on surface
 * l - light position
 * s - direction of s texture coordinate in object space (normalized)
 * t - direction of t texture coordinate in object space (normalized)
 */
- (void) setUpBumpsNormal:(GLfloat *)n currentVertex:(GLfloat *)c
         lightPos:(GLfloat *)l sTexCoord:(GLfloat *)s tTexCoord:(GLfloat *)t
{
   GLfloat v[ 3 ];   // Vertex From Current Position To Light
   GLfloat lenQ;     // Used To Normalize
        
   // Calculate v From Current Vector c To Lightposition And Normalize v
   v[ 0 ] = l[ 0 ] - c[ 0 ];         
   v[ 1 ] = l[ 1 ] - c[ 1 ];
   v[ 2 ] = l[ 2 ] - c[ 2 ];
   lenQ = (GLfloat) sqrt( v[ 0 ] * v[ 0 ] + v[ 1 ] * v[ 1 ] + v[ 2 ] * v[ 2 ] );
   v[ 0 ] /= lenQ;
   v[ 1 ] /= lenQ;
   v[ 2 ] /= lenQ;
   // Project v Such That We Get Two Values Along Each Texture-Coordinate
   // Axis.
   c[ 0 ] = ( s[ 0 ] * v[ 0 ] + s[ 1 ] * v[ 1 ] + s[ 2 ] * v[ 2 ] ) * MAX_EMBOSS;
   c[ 1 ] = ( t[ 0 ] * v[ 0 ] + t[ 1 ] * v[ 1 ] + t[ 2 ] * v[ 2 ] ) * MAX_EMBOSS;
}


/*
 * Calculates v = Mv; M is 4x4 column-major, v is 4 dim. row
 */
- (void) multMatrix:(GLfloat *)M withVector:(GLfloat *)v
{
   GLfloat res[ 3 ];

   res[ 0 ] = M[  0 ] * v[ 0 ] + M[  1 ] * v[ 1 ] +
              M[  2 ] * v[ 2 ] + M[  3 ] * v[ 3 ];
   res[ 1 ] = M[  4 ] * v[ 0 ] + M[  5 ] * v[ 1 ] +
              M[  6 ] * v[ 2 ] + M[  7 ] * v[ 3 ];
   res[ 2 ] = M[  8 ] * v[ 0 ] + M[  9 ] * v[ 1 ] +
              M[ 10 ] * v[ 2 ] + M[ 11 ] * v[ 3 ];
   v[ 0 ] = res[ 0 ];
   v[ 1 ] = res[ 1 ];
   v[ 2 ] = res[ 2 ];
   v[ 3 ] = M[ 15 ];   // Homogenous Coordinate
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) toggleEmboss
{
   emboss = !emboss;
}


- (void) toggleMultitexture
{
   useMultitexture = ( ( !useMultitexture ) && multitextureSupported );
}


- (void) toggleBumps
{
   bumps = !bumps;
}


- (void) selectNextFilter
{
   filter = ( filter + 1 ) % 3;
}


- (void) decreaseZ
{
   z -= 0.02f;
}


- (void) increaseZ
{
   z += 0.02f;
}


- (void) decreaseXSpeed
{
   xspeed -= 0.01f;
}


- (void) increaseXSpeed
{
   xspeed += 0.01f;
}


- (void) decreaseYSpeed
{
   yspeed -= 0.01f;
}


- (void) increaseYSpeed
{
   yspeed += 0.01f;
}


- (void) showInfoSheetTitle:(NSString *)title msgText:(NSString *)text
{
   NSWindow *infoWindow;

   infoWindow = NSGetInformationalAlertPanel( title, text, @"OK", nil, nil );
   [ NSApp runModalForWindow:infoWindow ];
   [ infoWindow close ];
}


/*
 * Cleanup
 */
- (void) dealloc
{
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
