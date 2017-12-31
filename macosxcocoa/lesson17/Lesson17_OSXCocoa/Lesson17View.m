/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * and modified by Giuseppe D'Agata (waveform@tiscalinet.it)
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson17View.m */

#import "Lesson17View.h"

@interface Lesson17View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) buildFont;
- (void) glPrintAtX:(GLint)x Y:(GLint)y string:(char *)string
         set:(int)set;
@end

@implementation Lesson17View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   cnt1 = cnt2 = 0.0f;
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
   [ self buildFont ];

   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );      // Type of blending
   glShadeModel( GL_SMOOTH );                // Enable smooth color shading
   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   
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
                                    "Font.bmp" ] intoIndex:0 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Bumps.bmp" ] intoIndex:1 ] )
   {
      status = TRUE;

      glGenTextures( 2, &texture[ 0 ] );   // Create the textures
      for( loop = 0; loop < 2; loop++ )
      {
         glBindTexture( GL_TEXTURE_2D, texture[ loop ] );

         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ loop ].width,
                       texSize[ loop ].height, 0,
                       texFormat[ loop ], GL_UNSIGNED_BYTE,
                       texBytes[ loop ] );
      }

      for( loop = 0; loop < 2; loop++ )
         free( texBytes[ loop ] );
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


- (void) buildFont
{
   float cx;
   float cy;
   int loop;

   base = glGenLists( 256 );   // Create 256 display lists
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select font texture
   for( loop = 0; loop < 256; loop++ )
   {
      // X position of current character
      cx = ( (float) ( loop % 16 ) ) / 16.0f;
      // Y position of current character
      cy = ( (float) ( loop / 16 ) ) / 16.0f;
      glNewList( base + loop, GL_COMPILE );   // Start building a list
      glBegin( GL_QUADS );
      glTexCoord2f( cx, 1 - cy - 0.0625f );   // Texture coord, bottom left
      glVertex2i( 0, 0 );                     // Vertex coord, bottom left

      // Texture coord, bottom right
      glTexCoord2f( cx + 0.0625f, 1 - cy - 0.0625f );
      glVertex2i( 16, 0 );                    // Vertex coord, bottom right

      glTexCoord2f( cx + 0.0625f, 1 - cy );   // Texture coord, top right
      glVertex2i( 16, 16 );                   // Vertex coord, top right

      glTexCoord2f( cx, 1 - cy );             // Texture coord, top left
      glVertex2i( 0, 16 );                    // Vertex coord, top left
      glEnd();
      glTranslated( 10, 0, 0 );   // Move to the right of the character
      glEndList();
   }
}


- (void) killFont
{
   glDeleteLists( base, 256 );   // Delete all 256 display lists
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

   glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );   // Select second texture
   glTranslatef( 0.0f, 0.0f, -5.0f );   // Move into screen 5 units
   glRotatef( 45.0f, 0.0f, 0.0f, 1.0f );   // Rotate around Z axis (clockwise)
   // Rotate on X and Y axis by cnt1 (left and right )
   glRotatef( cnt1 * 30.0f, 1.0f, 1.0f, 0.0f );
   glDisable( GL_BLEND );   // Disable blending before drawing in 3D
   glColor3f( 1.0f, 1.0f, 1.0f );   // Bright white
   glBegin( GL_QUADS );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex2f( -1.0f,  1.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex2f(  1.0f,  1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex2f(  1.0f, -1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex2f( -1.0f, -1.0f );
   glEnd();

   // Rotate on the X and Y axis by 90 degrees (left to right )
   glRotatef( 90.0f, 1.0f, 1.0f, 0.0f );
   glBegin( GL_QUADS );
   glTexCoord2f( 0.0f, 0.0f );
   glVertex2f( -1.0f,  1.0f );
   glTexCoord2f( 1.0f, 0.0f );
   glVertex2f(  1.0f,  1.0f );
   glTexCoord2f( 1.0f, 1.0f );
   glVertex2f(  1.0f, -1.0f );
   glTexCoord2f( 0.0f, 1.0f );
   glVertex2f( -1.0f, -1.0f );
   glEnd();

   glEnable( GL_BLEND );
   glLoadIdentity();   // Reset the view
   // Pulsing colors based on text position
   glColor3f( cos( cnt1 ), sin( cnt2 ), 1.0f - 0.5f * cos( cnt1 + cnt2 ) );
   // Print GL text to the screen
   [ self glPrintAtX:280 + (int) ( 250 * cos( cnt1 ) )
          Y:235 + (int) ( 200 * sin( cnt2 ) ) string:"NeHe" set:0 ];
   glColor3f( sin( cnt2 ), 1.0f - 0.5f * cos( cnt1 + cnt2 ), cos( cnt1 ) );
   [ self glPrintAtX:280 + (int) ( 230 * cos( cnt2 ) )
          Y:235 + (int) ( 200 * sin( cnt1 ) ) string:"OpenGL" set:1 ];
   glColor3f( 0.0f, 0.0f, 1.0f );   // Blue
   [ self glPrintAtX:240 + (int) ( 200 * cos( cnt2 + cnt1 ) ) Y:2
          string:"Giuseppe D'Agata" set:0 ];
   glColor3f( 1.0f, 1.0f, 1.0f );   // White
   [ self glPrintAtX:242 + (int) ( 200 * cos( cnt2 + cnt1 ) ) Y:2
          string:"Giuseppe D'Agata" set:0 ];

   cnt1 += 0.01f;     // Increase first counter
   cnt2 += 0.0081f;   // Increase second counter

   [ [ self openGLContext ] flushBuffer ];
}


- (void) glPrintAtX:(GLint)x Y:(GLint)y string:(char *)string
         set:(int)set
{
   if( set > 1 )
      set = 1;

   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select font texture
   glDisable( GL_DEPTH_TEST );
   glMatrixMode( GL_PROJECTION );
   glPushMatrix();     // Save the projection matrix
   glLoadIdentity();   // Reset the projection matrix
   // Set up an ortho screen
   glOrtho( 0, [ self bounds ].size.width, 0, [ self bounds ].size.height,
            -1, 1 );
   glMatrixMode( GL_MODELVIEW );
   glPushMatrix();     // Save the modelview matrix
   glLoadIdentity();   // Reset the modelview matrix
   glTranslated( x, y, 0 );   // Position the text
   glListBase( base - 32 + ( 128 * set ) );   // Choose the font set
   // Write the text to the screen
   glCallLists( strlen( string ), GL_BYTE, string );
   glMatrixMode( GL_PROJECTION );
   glPopMatrix();   // Restore the previous projection matrix
   glMatrixMode( GL_MODELVIEW );
   glPopMatrix();   // Restore the previous modelview matrix
   glEnable( GL_DEPTH_TEST );
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


/*
 * Cleanup
 */
- (void) dealloc
{
   [ self killFont ];
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
