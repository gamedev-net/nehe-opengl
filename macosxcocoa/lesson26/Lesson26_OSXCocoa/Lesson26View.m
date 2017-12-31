/*
 * Original Windows comment:
 * "This code has been created by Banu Cosmin aka Choko - 20 may 2000
 * and uses NeHe tutorials as a starting point (window initialization,
 * texture loading, GL initialization and code for keypresses) - very good
 * tutorials, Jeff. If anyone is interested about the presented algorithm
 * please e-mail me at boct@romwest.ro
 *
 * Code commmenting and clean up by Jeff Molofee ( NeHe )
 * NeHe Productions        ...             http://nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson26View.m */

#import "Lesson26View.h"

@interface Lesson26View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) drawObject;
- (void) drawFloor;
@end

@implementation Lesson26View

static GLfloat lightAmb[] = { 0.7f, 0.7f, 0.7f, 1.0f };   // Ambient light
static GLfloat lightDif[] = { 1.0f, 1.0f, 1.0f, 1.0f };   // Diffuse light
static GLfloat lightPos[] = { 4.0f, 4.0f, 6.0f, 1.0f };   // Light position

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   zoom = -7.0f;
   height = 2.0f;
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
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAStencilSize;   // Use stencil buffer
   pixelAttribs[ pixNum++ ] = 1;

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

   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.2f, 0.5f, 1.0f, 1.0f );   // Clear background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glClearStencil( 0 );                      // Clear stencil buffer to 0
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   glEnable( GL_TEXTURE_2D );                // Enable texture mapping

   // Set ambient, diffuse, and position settings for light 0
   glLightfv( GL_LIGHT0, GL_AMBIENT, lightAmb );
   glLightfv( GL_LIGHT0, GL_DIFFUSE, lightDif );
   glLightfv( GL_LIGHT0, GL_POSITION, lightPos );
   glEnable( GL_LIGHT0 );     // Enable light 0
   glEnable( GL_LIGHTING );   // And lighting

   q = gluNewQuadric();   // Create a new quadric
   gluQuadricNormals( q, GL_SMOOTH );   // Generate smooth normals
   gluQuadricTexture( q, GL_TRUE );     // Enable texture coords

   // Setup sphere mapping for S & T
   glTexGeni( GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
   glTexGeni( GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
   
   return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;
   NSString *resourcePath = [ [ NSBundle mainBundle ] resourcePath ];
   int loop;

   if( [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "Envwall.bmp" ] intoIndex:0 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "Ball.bmp" ] intoIndex:1 ] &&
       [ self loadBitmap:[ resourcePath stringByAppendingFormat:@"/%s",
                                        "Envroll.bmp" ] intoIndex:2 ] )
   {
      status = TRUE;

      glGenTextures( 3, &texture[ 0 ] );   // Create the textures

      for( loop = 0; loop < 3; loop++ )
      {
         glBindTexture( GL_TEXTURE_2D, texture[ loop ] );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ loop ].width,
                       texSize[ loop ].height, 0, texFormat[ loop ],
                       GL_UNSIGNED_BYTE, texBytes[ loop ] );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

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
   // Plane equation to use for the reflected objects
   double eqr[] = { 0.0f, -1.0f, 0.0f, 0.0f };

   // Clear the screen, depth, and stencil buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT |
            GL_STENCIL_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix
   glTranslatef( 0.0f, -0.6f, zoom );   // Zoom and raise camera above floor

   glColorMask( GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE );   // Set color mask

   // Enable stencil buffer for "marking" the floor
   glEnable( GL_STENCIL_TEST );
   // Always passes, 1 bit plane, 1 as mask
   glStencilFunc( GL_ALWAYS, 1, 1 );
   // Set the stencil buffer to one where we draw any polygon, keep if
   // test failes, keep if test passes but buffer test fails, and replace
   // if test passes
   glStencilOp( GL_KEEP, GL_KEEP, GL_REPLACE );
   glDisable( GL_DEPTH_TEST );   // Disable depth testing
   [ self drawFloor ];           // Draw the floor to the stencil buffer

   glEnable( GL_DEPTH_TEST );    // Enable depth testing
   glColorMask( GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE );   // Set color mask
   glStencilFunc( GL_EQUAL, 1, 1 );   // Draw only where the stencil is 1
   glStencilOp( GL_KEEP, GL_KEEP, GL_KEEP );   // Don't change stencil buffer

   // Enable clip plane for removing artifacts (when the object crosses
   // the floor)
   glEnable( GL_CLIP_PLANE0 );
   glClipPlane( GL_CLIP_PLANE0, eqr );   // Equation for reflected objects
   glPushMatrix();                       // Push matrix onto the stack
   glScalef( 1.0f, -1.0f, 1.0f );        // Mirror on Y axis

   glLightfv( GL_LIGHT0, GL_POSITION, lightPos );   // Setup light 0
   glTranslatef( 0.0f, height, 0.0f );              // Position the object
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );             // Rotate on X axis
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );             // Rotate on Y axis
   [ self drawObject ];   // Draw the sphere (reflected)
   glPopMatrix();         // Restore previously-saved matrix
   glDisable( GL_CLIP_PLANE0 );   // Disable clip plane for drawing the floor
   glDisable( GL_STENCIL_TEST );   // No longer need the stencil buffer

   glLightfv( GL_LIGHT0, GL_POSITION, lightPos );   // Setup light 0
   glEnable( GL_BLEND );   // Enable blending
   glDisable( GL_LIGHTING );   // Since we use blending, turn off lighting
   glColor4f( 1.0f, 1.0f, 1.0f, 0.8f );   // White, 80% alpha
   // Blending based on source alpha and 1 minus dest alpha
   glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
   [ self drawFloor ];   // Draw the floor to the screen

   glEnable( GL_LIGHTING );   // Lighting back on
   glDisable( GL_BLEND );     // and blending off
   glTranslatef( 0.0f, height, 0.0f );   // Position ball at proper height
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );   // Rotate on X axis
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );   // Rotate on Y axis
   [ self drawObject ];                   // Draw the ball

   glFlush();   // Flush the GL pipeline

   [ [ self openGLContext ] flushBuffer ];

   xrot += xrotspeed;
   yrot += yrotspeed;
}


/*
 * Draw our ball
 */
- (void) drawObject
{
   glColor3f( 1.0f, 1.0f, 1.0f );   // Set color to white
   glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );   // Select ball texture
   gluSphere( q, 0.35f, 32, 16 );   // Draw first sphere

   glBindTexture( GL_TEXTURE_2D, texture[ 2 ] );   // Select Envroll texture
   glColor4f( 1.0f, 1.0f, 1.0f, 0.4f );   // White with 40% alpha
   glEnable( GL_BLEND );                  // Enable blending
   // Blending mode set to mix based on source alpha
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );
   glEnable( GL_TEXTURE_GEN_S );          // Enable texture coord generation
   glEnable( GL_TEXTURE_GEN_T );          // for S & T
   gluSphere( q, 0.35f, 32, 16 );   // Another sphere, same size as last

   glDisable( GL_TEXTURE_GEN_S );   // Disable texture coord generation
   glDisable( GL_TEXTURE_GEN_T );   // for S & T
   glDisable( GL_BLEND );           // Disable blending
}


/*
 * Draw the floor
 */
- (void) drawFloor
{
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select floor texture
   glBegin( GL_QUADS );
   glNormal3f( 0.0f, 1.0f, 0.0f );     // Normal pointing up
   glTexCoord2f( 0.0f, 1.0f );         // Bottom left of texture
   glVertex3f( -2.0f, 0.0f,  2.0f );   // Bottom left corner of floor

   glTexCoord2f( 0.0f, 0.0f );         // Top left of texture
   glVertex3f( -2.0f, 0.0f, -2.0f );   // Top left corner of floor

   glTexCoord2f( 1.0f, 0.0f );         // Top right of texture
   glVertex3f(  2.0f, 0.0f, -2.0f );   // Top right corner of floor

   glTexCoord2f( 1.0f, 1.0f );         // Bottom right of texture
   glVertex3f(  2.0f, 0.0f,  2.0f );   // Bottom right corner of floor
   glEnd();
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) decreaseYRotSpeed
{
   yrotspeed -= 0.08f;
}


- (void) increaseYRotSpeed
{
   yrotspeed += 0.08f;
}


- (void) decreaseXRotSpeed
{
   xrotspeed -= 0.08f;
}


- (void) increaseXRotSpeed
{
   xrotspeed += 0.08f;
}


- (void) decreaseZoom
{
   zoom -= 0.05f;
}


- (void) increaseZoom
{
   zoom += 0.05f;
}


- (void) decreaseHeight
{
   height -= 0.03f;
}


- (void) increaseHeight
{
   height += 0.03f;
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
