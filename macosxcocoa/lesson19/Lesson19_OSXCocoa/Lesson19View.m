/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson19View.m */

#import "Lesson19View.h"

@interface Lesson19View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
@end

@implementation Lesson19View

static GLfloat colors[ 12 ][ 3 ] =   // Rainbow of colors
   {
      {  1.0f, 0.5f, 0.5f }, { 1.0f, 0.75f, 0.5f }, { 1.0f, 1.0f,  0.5f },
      { 0.75f, 1.0f, 0.5f }, { 0.5f,  1.0f, 0.5f }, { 0.5f, 1.0f, 0.75f },
      {  0.5f, 1.0f, 1.0f }, { 0.5f, 0.75f, 1.0f }, { 0.5f, 0.5f,  1.0f },
      { 0.75f, 0.5f, 1.0f }, { 1.0f,  0.5f, 1.0f }, { 1.0f, 0.5f, 0.75f }
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
   rainbow = TRUE;
   slowdown = 2.0f;
   zoom = -40.0f;
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
   int loop;

   if( ![ self loadGLTextures ] )
      return FALSE;

   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glDisable( GL_DEPTH_TEST );               // Disable depth testing
   glEnable( GL_BLEND );                     // Enable blending
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );      // Type of blending to perform
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   // Really nice point smoothing
   glHint( GL_POINT_SMOOTH_HINT, GL_NICEST );
   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select our texture

   for( loop = 0; loop < MAX_PARTICLES; loop++ )
   {
      particle[ loop ].active = TRUE;   // Make all particles active
      particle[ loop ].life = 1.0f;     // Give all particles full life
      // Random fade speed
      particle[ loop ].fade = (float) ( rand() % 100 ) / 1000.0f + 0.003;
      particle[ loop ].r = colors[ loop * ( 12 / MAX_PARTICLES ) ][ 0 ];
      particle[ loop ].g = colors[ loop * ( 12 / MAX_PARTICLES ) ][ 1 ];
      particle[ loop ].b = colors[ loop * ( 12 / MAX_PARTICLES ) ][ 2 ];
      particle[ loop ].xi = ( (float) ( rand() % 50 ) - 26.0f ) * 10.0f;
      particle[ loop ].yi = ( (float) ( rand() % 50 ) - 25.0f ) * 10.0f;
      particle[ loop ].zi = ( (float) ( rand() % 50 ) - 25.0f ) * 10.0f;
      particle[ loop ].xg = 0.0f;    // Set horizontal pull to zero
      particle[ loop ].yg = -0.8f;   // Set vertical pull downward
      particle[ loop ].zg = 0.0f;    // Set pull on Z axis to zero
   }

   return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;

   if( [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Particle.bmp" ] intoIndex:0 ] )
   {
      status = TRUE;

      glGenTextures( 1, &texture[ 0 ] );   // Create the texture

      glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );

      free( texBytes[ 0 ] );
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
                   0.1f, 200.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   int loop;
   float x, y, z;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix

   for( loop = 0; loop < MAX_PARTICLES; loop++ )
   {
      if( particle[ loop ].active )
      {
         x = particle[ loop ].x;          // Grab our particle X position
         y = particle[ loop ].y;          // Grab our particle Y position
         z = particle[ loop ].z + zoom;   // Particle Z pos + zoom
         // Draw the particle using its RGB values, fade the particle based
         // on its life
         glColor4f( particle[ loop ].r, particle[ loop ].g,
                    particle[ loop ].b, particle[ loop ].life );
         glBegin( GL_TRIANGLE_STRIP );   // Build quad from triangle strip
         glTexCoord2d( 1, 1 );
         glVertex3f( x + 0.5f, y + 0.5f, z );   // Top right
         glTexCoord2d( 0, 1 );
         glVertex3f( x - 0.5f, y + 0.5f, z );   // Top left
         glTexCoord2d( 1, 0 );
         glVertex3f( x + 0.5f, y - 0.5f, z );   // Bottom right
         glTexCoord2d( 0, 0 );
         glVertex3f( x - 0.5f, y - 0.5f, z );   // Bottom left
         glEnd();

         // Move on the axes by appropriate amount
         particle[ loop ].x += particle[ loop ].xi / ( slowdown * 1000 );
         particle[ loop ].y += particle[ loop ].yi / ( slowdown * 1000 );
         particle[ loop ].z += particle[ loop ].zi / ( slowdown * 1000 );
         // Take gravity into account
         particle[ loop ].xi += particle[ loop ].xg;
         particle[ loop ].yi += particle[ loop ].yg;
         particle[ loop ].zi += particle[ loop ].zg;
         // Reduce particle's life by 'fade'
         particle[ loop ].life -= particle[ loop ].fade;
         if( particle[ loop ].life < 0.0f )
         {
            particle[ loop ].life = 1.0f;   // Give it new life
            // Random fade value
            particle[ loop ].fade = (float) ( rand() % 100 ) / 1000.0f +
                                    0.003f;
            particle[ loop ].x = 0.0f;   // Center on X axis
            particle[ loop ].y = 0.0f;   // Center on Y axis
            particle[ loop ].z = 0.0f;   // Center on Z axis
            // X axis speed and direction
            particle[ loop ].xi = xspeed + (float) ( rand() % 60 ) - 32.0f;
            particle[ loop ].yi = yspeed + (float) ( rand() % 60 ) - 30.0f;
            particle[ loop ].zi = (float) ( rand() % 60 ) - 30.0f;
            // Select red from color table
            particle[ loop ].r = colors[ col ][ 0 ];
            // Select green from color table
            particle[ loop ].g = colors[ col ][ 1 ];
            // Select blue from color table
            particle[ loop ].b = colors[ col ][ 2 ];
         }
         if( doIncreaseYGravity && ( particle[ loop ].yg < 1.5f ) )
            particle[ loop ].yg += 0.01f;
         if( doDecreaseYGravity && ( particle[ loop ].yg > -1.5f ) )
            particle[ loop ].yg -= 0.01f;
         if( doIncreaseXGravity && ( particle[ loop ].xg < 1.5f ) )
            particle[ loop ].xg += 0.01f;
         if( doDecreaseXGravity && ( particle[ loop ].xg > -1.5f ) )
            particle[ loop ].xg -= 0.01f;
         if( doBurst )
         {
            particle[ loop ].x = 0.0f;   // Center on X axis
            particle[ loop ].y = 0.0f;   // Center on Y axis
            particle[ loop ].z = 0.0f;   // Center on Z axis
            particle[ loop ].xi = ( (float) ( rand() % 50 ) - 26.0f ) *
                                  10.0f;
            particle[ loop ].yi = ( (float) ( rand() % 50 ) - 25.0f ) *
                                  10.0f;
            particle[ loop ].zi = ( (float) ( rand() % 50 ) - 25.0f ) *
                                  10.0f;
         }
      }
   }

   doIncreaseYGravity = doDecreaseYGravity = FALSE;
   doIncreaseXGravity = doDecreaseXGravity = doBurst = FALSE;
   if( rainbow && ( delay > 25 ) )
      [ self nextColor ];
   delay++;   // Increase rainbow mode color cycling delay counter

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) speedParticles
{
   if( slowdown > 1.0f )
      slowdown -= 0.01f;
}

- (void) slowParticles
{
   if( slowdown < 4.0f )
      slowdown += 0.01f;
}


- (void) increaseZoom
{
   zoom += 0.1f;
}


- (void) decreaseZoom
{
   zoom -= 0.1f;
}


- (void) toggleRainbow
{
   rainbow = !rainbow;
}


- (void) disableRainbow
{
   rainbow = FALSE;
}


- (void) nextColor
{
   delay = 0;                // Reset the rainbow color cycling delay
   col = ( col + 1 ) % 12;   // Change the particle color
}


- (void) increaseYSpeed
{
   if( yspeed < 200.0f )
      yspeed += 1.0f;
}


- (void) decreaseYSpeed
{
   if( yspeed > -200.0f )
      yspeed -= 1.0f;
}


- (void) increaseXSpeed
{
   if( xspeed < 200.0f )
      xspeed += 1.0f;
}


- (void) decreaseXSpeed
{
   if( xspeed > -200.0f )
      xspeed -= 1.0f;
}


- (void) increaseYGravity
{
   doIncreaseYGravity = TRUE;
}


- (void) decreaseYGravity
{
   doDecreaseYGravity = TRUE;
}


- (void) increaseXGravity
{
   doIncreaseXGravity = TRUE;
}


- (void) decreaseXGravity
{
   doDecreaseXGravity = TRUE;
}


- (void) burst
{
   doBurst = TRUE;
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
