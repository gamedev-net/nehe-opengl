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

/* Lesson12View.m */

#import "Lesson12View.h"

@interface Lesson12View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) buildLists;
@end

@implementation Lesson12View

static GLfloat boxcol[ 5 ][ 3 ] =
   {
      { 1.0f, 0.0f, 0.0f },   // Bright red
      { 1.0f, 0.5f, 0.0f },   //        orange
      { 1.0f, 1.0f, 0.0f },   //        yellow
      { 0.0f, 1.0f, 0.0f },   //        green
      { 0.0f, 1.0f, 1.0f }    //        blue
   };
static GLfloat topcol[ 5 ][ 3 ] =
   {
      { 0.5f,  0.0f, 0.0f },   // Dark red
      { 0.5f, 0.25f, 0.0f },   //      orange
      { 0.5f,  0.5f, 0.0f },   //      yellow
      { 0.0f,  0.5f, 0.0f },   //      green
      { 0.0f,  0.5f, 0.5f }    //      blue
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

   [ self buildLists ];
   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   glEnable( GL_LIGHT0 );                    // Quick and dirty lighting
   glEnable( GL_LIGHTING );                  // Enable lighting
   glEnable( GL_COLOR_MATERIAL );            // Enable material coloring
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   
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
                                    "Cube.bmp" ] intoIndex:0 ] )
   {
      status = TRUE;

      glGenTextures( 1, &texture[ 0 ] );   // Create the texture

      // Typical texture generation using data from the bitmap
      glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );

      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );
      // Linear filtering
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

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
 * Build box and top display lists
 */
- (void) buildLists
{
   box = glGenLists( 2 );          // Building two lists
   glNewList( box, GL_COMPILE );   // New compiled box display list
   glBegin( GL_QUADS );
   // Bottom face
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f( -1.0f, -1.0f, -1.0f );   // Top right
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f(  1.0f, -1.0f, -1.0f );   // Top left
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom left
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom right 
   // Front face       
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom left
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom right
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f,  1.0f );   // Top right
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f,  1.0f );   // Top left
   // Back face
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom right
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f, -1.0f );   // Top right
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f, -1.0f );   // Top left
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom left
   // Right face
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom right
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f, -1.0f );   // Top right
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f,  1.0f );   // Top left
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom left
   // Left face
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom left
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom right
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f,  1.0f );   // Top right
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f, -1.0f );   // Top left
   glEnd();
   glEndList();   // Done with box list

   top = box + 1;                  // top is the second display list
   glNewList( top, GL_COMPILE );   // Compile top display list
   glBegin( GL_QUADS );
   // Top face
   glTexCoord2f( 0.0f, 1.0f );
   glVertex3f( -1.0f,  1.0f, -1.0f );   // Top left
   glTexCoord2f( 0.0f, 0.0f );
   glVertex3f( -1.0f,  1.0f,  1.0f );   // Bottom left
   glTexCoord2f( 1.0f, 0.0f );
   glVertex3f(  1.0f,  1.0f,  1.0f );   // Bottom right
   glTexCoord2f( 1.0f, 1.0f );
   glVertex3f(  1.0f,  1.0f, -1.0f );   // Top right
   glEnd();
   glEndList();   // Done with top list
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
   int xloop, yloop;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
   for( yloop = 1; yloop < 6; yloop++ )
   {
      for( xloop = 0; xloop < yloop; xloop++ )
      {
         glLoadIdentity();      // Reset the view
         // Position the cubes on the screen
         glTranslatef( 1.4f + xloop * 2.8f - yloop * 1.4f,
                       ( 6.0f - yloop ) * 2.4f - 7.0f, -20.0f );
         // Tilt cubes up and down
         glRotatef( 45.0f - 2.0f * yloop + xrot,
                   1.0f, 0.0f, 0.0f );
         // Spin cubes left and right
         glRotatef( 45.0f + yrot, 0.0f, 1.0f, 0.0f );
         glColor3fv( boxcol[ yloop - 1 ] );   // Select a box color
         glCallList( box );                   // Draw the box
         glColor3fv( topcol[ yloop - 1 ] );   // Select a top color
         glCallList( top );                   // Draw the top
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


- (void) rotateLeft
{
   yrot -= 0.2f;
}


- (void) rotateRight
{
   yrot += 0.2f;
}


- (void) rotateUp
{
   xrot -= 0.2f;
}


- (void) rotateDown
{
   xrot += 0.2f;
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
