/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson09View.m */

#import "Lesson09View.h"

@interface Lesson09View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
@end

@implementation Lesson09View

const int num = 50;

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   zoom = -15.0f;
   tilt = 90.0f;
   starInfo = calloc( num, sizeof( stars ) );
   if( starInfo == NULL )
      return nil;
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

   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   // Set the blending function for translucency
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );
   glEnable( GL_BLEND );   // Enable blending

   for( loop = 0; loop < num; loop++ )
   {
      starInfo[ loop ].angle = 0.0f;   // Start all stars at angle zero
      starInfo[ loop ].dist = ( (float) loop ) / num * 5.0f;
      starInfo[ loop ].r = rand() % 256;
      starInfo[ loop ].g = rand() % 256;
      starInfo[ loop ].b = rand() % 256;
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
                                    "Star.bmp" ] intoIndex:0 ] )
   {
      status = TRUE;

      glGenTextures( 1, &texture[ 0 ] );   // Create the texture

      // Create linear filtered texture
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
                   0.1f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   int loop;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );

   for( loop = 0; loop < num; loop++ )
   {
      glLoadIdentity();                      // Reset view for each star
      glTranslatef( 0.0f, 0.0f, zoom );      // Zoom into screen
      glRotatef( tilt, 1.0f, 0.0f, 0.0f );   // Tilt the view
      // Rotate for this star
      glRotatef( starInfo[ loop ].angle, 0.0f, 1.0f, 0.0f );
      // Move forward on X axis
      glTranslatef( starInfo[ loop ].dist, 0.0f, 0.0f );
      // Cancel star's angle 
      glRotatef( -starInfo[ loop ].angle, 0.0f, 1.0f, 0.0f );
      glRotatef( -tilt, 1.0f, 0.0f, 0.0f );   // Cancel tilt
      if( twinkle )
      {
         glColor4ub( starInfo[ num - loop - 1 ].r,
                     starInfo[ num - loop - 1 ].g,
                     starInfo[ num - loop - 1 ].b, 255 );
         glBegin( GL_QUADS );
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f, -1.0f,  0.0f );
         glTexCoord2f( 1.0f, 0.0f );
         glVertex3f(  1.0f, -1.0f,  0.0f );
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f,  1.0f,  0.0f );
         glTexCoord2f( 0.0f, 1.0f );
         glVertex3f( -1.0f,  1.0f,  0.0f );
         glEnd();
      }
      glRotatef( spin, 0.0f, 0.0f, 1.0f );   // Rotate on Z axis
      glColor4ub( starInfo[ loop ].r, starInfo[ loop ].g,
                  starInfo[ loop ].b, 255 );
      glBegin( GL_QUADS );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -1.0f, -1.0f,  0.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  1.0f, -1.0f,  0.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  1.0f,  1.0f,  0.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -1.0f,  1.0f,  0.0f );
      glEnd();
      spin += 0.01f;   // Spin the stars
      starInfo[ loop ].angle += (float) loop / num;
      starInfo[ loop ].dist -= 0.01f;
      if( starInfo[ loop ].dist < 0.0f )
      {
         starInfo[ loop ].dist += 5.0f;       // Move star out
         starInfo[ loop ].r = rand() % 256;   // New red,
         starInfo[ loop ].g = rand() % 256;   // green,
         starInfo[ loop ].b = rand() % 256;   // and blue values
      }
   }

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) toggleTwinkle
{
   twinkle = !twinkle;
}


- (void) decreaseTilt
{
   tilt -= 0.5f;
}

- (void) increaseTilt
{
   tilt += 0.5f;
}


- (void) decreaseZoom
{
   zoom -= 0.2f;
}

- (void) increaseZoom
{
   zoom += 0.2f;
}


/*
 * Cleanup
 */
- (void) dealloc
{
   free( starInfo );
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
