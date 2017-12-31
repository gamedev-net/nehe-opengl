/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * and modified by Giuseppe D'Agata (waveform@tiscalinet.it)
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson20View.m */

#import "Lesson20View.h"

@interface Lesson20View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
@end

@implementation Lesson20View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   masking = TRUE;
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
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
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
                                    "Logo.bmp" ] intoIndex:0 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Mask1.bmp" ] intoIndex:1 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Image1.bmp" ] intoIndex:2 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Mask2.bmp" ] intoIndex:3 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Image2.bmp" ] intoIndex:4 ] )
   {
      status = TRUE;

      glGenTextures( 5, &texture[ 0 ] );   // Create the textures

      for( loop = 0; loop < 5; loop++ )
      {
         glBindTexture( GL_TEXTURE_2D, texture[ loop ] );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ loop ].width,
                       texSize[ loop ].height, 0, texFormat[ loop ],
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

   glTranslatef( 0.0f, 0.0f, -2.0f );   // Move into screen 2 units

   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select Our Logo Texture
   glBegin( GL_QUADS );                      // Start Drawing A Textured Quad
   glTexCoord2f( 0.0f, -roll + 0.0f );
   glVertex3f( -1.1f, -1.1f,  0.0f );        // Bottom Left
   glTexCoord2f( 3.0f, -roll + 0.0f );
   glVertex3f(  1.1f, -1.1f,  0.0f );        // Bottom Right
   glTexCoord2f( 3.0f, -roll + 3.0f );
   glVertex3f(  1.1f,  1.1f,  0.0f );        // Top Right
   glTexCoord2f( 0.0f, -roll + 3.0f );
   glVertex3f( -1.1f,  1.1f,  0.0f );        // Top Left
   glEnd();                                  // Done Drawing The Quad

   glEnable( GL_BLEND );         // Enable blending
   glDisable( GL_DEPTH_TEST );   // Disable depth testing
   if( masking )
   {
      // Blend screen color with 0 (black)
      glBlendFunc( GL_DST_COLOR, GL_ZERO );
   }
   if( scene )   // Are we drawing the second scene?
   {
      glTranslatef( 0.0f, 0.0f, -1.0f );   // Into screen 1 unit
      glRotatef( roll * 360.0f, 0.0f, 0.0f, 1.0f );   // Rotate on the Z axis
      if( masking )
      {
         // Select The Second Mask Texture
         glBindTexture( GL_TEXTURE_2D, texture[ 3 ] );
         glBegin( GL_QUADS );   // Start Drawing A Textured Quad
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.1f, -1.1f,  0.0f );      // Bottom Left
         glTexCoord2f( 1.0f, 0.0f );
         glVertex3f(  1.1f, -1.1f,  0.0f );      // Bottom Right
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.1f,  1.1f,  0.0f );      // Top Right
         glTexCoord2f( 0.0f, 1.0f );
         glVertex3f( -1.1f,  1.1f,  0.0f );      // Top Left
         glEnd();               // Done Drawing The Quad
      }
      glBlendFunc( GL_ONE, GL_ONE );   // Copy Image 2 Color To The Screen
      // Select The Second Image Texture
      glBindTexture( GL_TEXTURE_2D, texture[ 4 ] );
      glBegin( GL_QUADS );   // Start Drawing A Textured Quad
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -1.1f, -1.1f,  0.0f );      // Bottom Left
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  1.1f, -1.1f,  0.0f );      // Bottom Right
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  1.1f,  1.1f,  0.0f );      // Top Right
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -1.1f,  1.1f,  0.0f );      // Top Left
      glEnd();               // Done Drawing The Quad
   }
   else   // First scene
   {
      if( masking )
      {
         // Select The First Mask Texture
         glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );
         glBegin( GL_QUADS );   // Start Drawing A Textured Quad
         glTexCoord2f( roll + 0.0f, 0.0f );
         glVertex3f( -1.1f, -1.1f,  0.0f );   // Bottom Left
         glTexCoord2f( roll + 4.0f, 0.0f );
         glVertex3f(  1.1f, -1.1f,  0.0f );   // Bottom Right
         glTexCoord2f( roll + 4.0f, 4.0f );
         glVertex3f(  1.1f,  1.1f,  0.0f );   // Top Right
         glTexCoord2f( roll + 0.0f, 4.0f );
         glVertex3f( -1.1f,  1.1f,  0.0f );   // Top Left
         glEnd();               // Done Drawing The Quad
      }
      glBlendFunc( GL_ONE, GL_ONE );   // Copy Image 1 Color To The Screen
      // Select The First Image Texture
      glBindTexture( GL_TEXTURE_2D, texture[ 2 ] );
      glBegin( GL_QUADS );   // Start Drawing A Textured Quad
      glTexCoord2f( roll + 0.0f, 0.0f );
      glVertex3f( -1.1f, -1.1f,  0.0f );   // Bottom Left
      glTexCoord2f( roll + 4.0f, 0.0f );
      glVertex3f(  1.1f, -1.1f,  0.0f );   // Bottom Right
      glTexCoord2f( roll + 4.0f, 4.0f );
      glVertex3f(  1.1f,  1.1f,  0.0f );   // Top Right
      glTexCoord2f( roll + 0.0f, 4.0f );
      glVertex3f( -1.1f,  1.1f,  0.0f );   // Top Left
      glEnd();               // Done Drawing The Quad
   }

   glEnable( GL_DEPTH_TEST );   // Enable depth testing
   glDisable( GL_BLEND );       // Disable blending

   [ [ self openGLContext ] flushBuffer ];

   roll += 0.002f;   // Increase our texture roll
   if( roll > 1.0f )
      roll -= 1.0f;
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) toggleScene
{
   scene = !scene;
}


- (void) toggleMasking
{
   masking = !masking;
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
