/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee and GB Schmick 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit our sites at www.tiptup.com and nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson23View.m */

#import "Lesson23View.h"

@interface Lesson23View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) glDrawCube;
- (void) checkLighting;
@end

@implementation Lesson23View

// Ambient light values
static GLfloat lightAmbient[] = { 0.5f, 0.5f, 0.5f, 1.0f };
// Diffuse light values
static GLfloat lightDiffuse[] = { 1.0f, 1.0f, 1.0f, 1.0f };
// Light position
static GLfloat lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   p1 = 0;
   p2 = 1;
   object = 1;
   z = -10.0f;
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

   // Setup ambient light
   glLightfv( GL_LIGHT1, GL_AMBIENT, lightAmbient );
   // Setup diffuse light
   glLightfv( GL_LIGHT1, GL_DIFFUSE, lightDiffuse );
   // Position the light
   glLightfv( GL_LIGHT1, GL_POSITION, lightPosition );
   glEnable( GL_LIGHT1 );   // Enable light 1

   quadric = gluNewQuadric();   // Create a pointer to the quadric object
   gluQuadricNormals( quadric, GLU_SMOOTH );   // Create smooth normals
   gluQuadricTexture( quadric, GL_TRUE );      // Create texture coords

   // Set the texture generation mode for S to sphere mapping
   glTexGeni( GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
   // Set the texture generation mode for T to sphere mapping
   glTexGeni( GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );

   [ self checkLighting ];

   return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;
   int loop;

   if( [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "BG.bmp" ] intoIndex:0 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Reflect.bmp" ] intoIndex:1 ] )
   {
      status = TRUE;

      glGenTextures( 6, &texture[ 0 ] );   // Create the textures

      for( loop = 0; loop < 2; loop++ )
      {
         // Create nearest filtered texture (as textures 0 and 1)
         glBindTexture( GL_TEXTURE_2D, texture[ loop ] );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ loop ].width,
                       texSize[ loop ].height, 0, texFormat[ loop ],
                       GL_UNSIGNED_BYTE, texBytes[ loop ] );
         // Create linear filtered texture (as textures 2 and 3)
         glBindTexture( GL_TEXTURE_2D, texture[ loop + 2 ] );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ loop ].width,
                       texSize[ loop ].height, 0, texFormat[ loop ],
                       GL_UNSIGNED_BYTE, texBytes[ loop ] );
         // Create mipmapped texture (as textures 4 and 5)
         glBindTexture( GL_TEXTURE_2D, texture[ loop + 4 ] );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                          GL_LINEAR_MIPMAP_NEAREST );
         gluBuild2DMipmaps( GL_TEXTURE_2D, 3, texSize[ loop ].width,
                            texSize[ loop ].height, texFormat[ loop ],
                            GL_UNSIGNED_BYTE, texBytes[ loop ] );

         free( texBytes[ loop ] );
      }
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
   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix

   glTranslatef( 0.0f, 0.0f, z );

   glEnable( GL_TEXTURE_GEN_S );   // Enable texture coord generation for S
   glEnable( GL_TEXTURE_GEN_T );   // Enable texture coord generation for T

   // This Will Select The Sphere Map
   glBindTexture( GL_TEXTURE_2D, texture[ filter + ( filter + 1 ) ] );

   glPushMatrix();
   // Rotate on X axis
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );
   // Rotate on Y axis
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );

   switch( object )
   {
      case 0:   // Drawing object 1
         [ self glDrawCube ];
         break;

      case 1:   // Drawing object 2
         glTranslatef( 0.0f, 0.0f, -1.5f );   // Center the cylinder
         gluCylinder( quadric, 1.0f, 1.0f, 3.0f, 32, 32 );   // Draw cylinder
         break;

      case 2:   // Drawing object 3
         // Draw a sphere with a radius of 1.3 and 32 longitude and 32
         // latitude segments
         gluSphere( quadric, 1.3f, 32, 32 );
         break;

      case 3:   // Drawing object 4
         glTranslatef( 0.0f, 0.0f, -1.5f );   // Center The Cone
         // A cone with a bottom radius of 1 and a height of 3
         gluCylinder( quadric, 1.0f, 0.0f, 3.0f, 32, 32 );
         break;
   }

   glPopMatrix();
   glDisable( GL_TEXTURE_GEN_S );   // Disable texture coord generation
   glDisable( GL_TEXTURE_GEN_T );   // Disable texture coord generation

   // This will select the BG texture
   glBindTexture( GL_TEXTURE_2D, texture[ filter * 2 ] );

   glPushMatrix();
   glTranslatef( 0.0f, 0.0f, -24.0f );
   glBegin( GL_QUADS );
   glNormal3f( 0.0f, 0.0f, 1.0f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -13.3f, -10.0f,  10.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  13.3f, -10.0f,  10.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  13.3f,  10.0f,  10.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -13.3f,  10.0f,  10.0f );
   glEnd();

   glPopMatrix();

   [ [ self openGLContext ] flushBuffer ];

   xrot += xspeed;
   yrot += yspeed;
}


- (void) glDrawCube
{
   glBegin( GL_QUADS ); 
   // Front Face
   glNormal3f( 0.0f, 0.0f, 0.5f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f,  1.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f,  1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f,  1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f,  1.0f );
   // Back Face
   glNormal3f( 0.0f, 0.0f, -0.5f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f, -1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f, -1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f, -1.0f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f, -1.0f );
   // Top Face
   glNormal3f( 0.0f, 0.5f, 0.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f, -1.0f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -1.0f,  1.0f,  1.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  1.0f,  1.0f,  1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f, -1.0f );
   // Bottom Face
   glNormal3f( 0.0f,-0.5f, 0.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f( -1.0f, -1.0f, -1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f(  1.0f, -1.0f, -1.0f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f,  1.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f,  1.0f );
   // Right Face
   glNormal3f( 0.5f, 0.0f, 0.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f, -1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f, -1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f,  1.0f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f,  1.0f );
   // Left Face
   glNormal3f( -0.5f, 0.0f, 0.0f );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f, -1.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f,  1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f,  1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f, -1.0f );
   glEnd();                             // Done Drawing Quads
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) toggleLight
{
   light = !light;
   [ self checkLighting ];
}


- (void) selectNextFilter
{
   filter = ( filter + 1 ) % 3;
}


- (void) selectNextObject
{
   object = ( object + 1 ) % 4;
}


- (void) decreaseZPos
{
   z -= 0.02f;
}


- (void) increaseZPos
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


- (void) checkLighting
{
   if( !light )
      glDisable( GL_LIGHTING );
   else
      glEnable( GL_LIGHTING );
}


/*
 * Cleanup
 */
- (void) dealloc
{
   gluDeleteQuadric( quadric );
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
