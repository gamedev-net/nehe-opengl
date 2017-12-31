/*
 * Original Windows comment:
 * "The OpenGL Basecode Used In This Project Was Created By
 * Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code
 * Useful, Please Let Me Know.
 *
 * Original Code & Tutorial Text By Andreas Lšffler
 * Excellent Job Andreas!
 *
 * Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )
 * Proper Image Structure, Better Blitter Code, Misc Fixes
 * Thanks Rob!
 *
 * 0% CPU Usage While Minimized Thanks To Jim Strong
 * ( jim@scn.net ).  Thanks Jim!
 *
 * This Code Also Has The ATI Fullscreen Fix!
 *
 * Visit Me At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson29View.m */

#import "Lesson29View.h"

@interface Lesson29View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) allocateTextureWidth:(GLint)newWidth height:(GLint)newHeight
         format:(GLenum)newFormat index:(int)newIndex;
- (void) deallocateTexture:(int)texIndex;
- (int) readTextureData:(const char *)filename intoIndex:(int)texIndex;
- (void) buildTexture:(int)texIndex;
- (void) blitSrc:(int)src dest:(int)dst srcXStart:(int)src_xstart
         srcYStart:(int)src_ystart srcWidth:(int)src_width
         srcHeight:(int)src_height destXStart:(int)dst_xstart
         destYStart:(int)dst_ystart blend:(BOOL)doBlend alpha:(int)alphaVal;
@end

@implementation Lesson29View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   xrot = yrot = zrot = 0;
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
   [ self allocateTextureWidth:256 height:256 format:4 index:0 ];
   if( [ self readTextureData:[ [ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Monitor.raw" ] cString ]
              intoIndex:0 ] == 0 )
      return FALSE;
   [ self allocateTextureWidth:256 height:256 format:4 index:1 ];
   if( [ self readTextureData:[ [ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "GL.raw" ] cString ]
              intoIndex:1 ] == 0 )
      return FALSE;

   // Image To Blend In, Original Image, Src Start X & Y, Src Width & Height,
   // Dst Location X & Y, Blend Flag, Alpha Value
   [ self blitSrc:1 dest:0 srcXStart:127 srcYStart:127 srcWidth:128
          srcHeight:128 destXStart:64 destYStart:64 blend:TRUE alpha:127 ];

   [ self buildTexture:0 ];   // Load the now-blit'd texture
   [ self deallocateTexture:0 ];
   [ self deallocateTexture:1 ];

   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LESS );                   // Type of depth test to do
   
   return TRUE;
}


/*
 * Allocate space for a texture image
 */
- (BOOL) allocateTextureWidth:(GLint)newWidth height:(GLint)newHeight
         format:(GLenum)newFormat index:(int)newIndex
{
   texSize[ newIndex ].width = newWidth;
   texSize[ newIndex ].height = newHeight;
   texFormat[ newIndex ] = newFormat;
   texBytes[ newIndex ] = malloc( newWidth * newHeight * newFormat );
   if( texBytes[ newIndex ] == NULL )
      return FALSE;
   else
      return TRUE;
}


/*
 * Free up texture image data
 */
- (void) deallocateTexture:(int)texIndex
{
   free( texBytes[ texIndex ] );
}


/*
 * Read a .RAW file in to the given texture index using data found in
 * the image structure header.  Flip the image top to bottom.  Returns
 * number of bytes read, so 0 on failure.
 */
- (int) readTextureData:(const char *)filename intoIndex:(int)texIndex
{
   FILE *f;
   int i, j, k, done = 0;
   // stride is size of a row (width * bytes per pixel)
   int stride = texSize[ texIndex ].width * texFormat[ texIndex ];
   unsigned char *p = NULL;
   NSWindow *infoWindow;

   f = fopen( filename, "rb" );   // Open "filename" For Reading Bytes
   if( f != NULL )                // If File Exists
   {
      // Loop Through Height (Bottoms Up - Flip Image)
      for( i = texSize[ texIndex ].height - 1; i >= 0 ; i-- )
      {
         p = texBytes[ texIndex ] + ( i * stride );
         // Loop Through Width
         for ( j = 0; j < texSize[ texIndex ].width; j++ )
         {
            for ( k = 0 ; k < texFormat[ texIndex ] - 1; k++, p++, done++ )
            {
               *p = fgetc( f );   // Read Value From File And Store In Memory
            }
            *p = 255;
            p++;   // Store 255 In Alpha Channel And Increase Pointer
         }
      }
      fclose( f );   // Close The File
   }
   else
   {
      infoWindow = NSGetCriticalAlertPanel( @"Image Error",
                                            @"Unable To Open Image File",
                                            @"OK", nil, nil );
      [ NSApp runModalForWindow:infoWindow ];
      [ infoWindow close ];
   }

   return done;   // Returns Number Of Bytes Read In
}


- (void) buildTexture:(int)texIndex
{
   glGenTextures( 1, &texture[ 0 ] );
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
   glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
   glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
   gluBuild2DMipmaps( GL_TEXTURE_2D, GL_RGB, texSize[ texIndex ].width,
                      texSize[ texIndex ].height, GL_RGBA, GL_UNSIGNED_BYTE,
                      texBytes[ texIndex ] );
}


- (void) blitSrc:(int)src dest:(int)dst srcXStart:(int)src_xstart
         srcYStart:(int)src_ystart srcWidth:(int)src_width
         srcHeight:(int)src_height destXStart:(int)dst_xstart
         destYStart:(int)dst_ystart blend:(BOOL)doBlend alpha:(int)alphaVal
{
   int i, j, k;
   unsigned char *s, *d;   // Source & Destination

   // Clamp Alpha If Value Is Out Of Range
   if( alphaVal > 255 )
      alphaVal = 255;
   if( alphaVal < 0 )
      alphaVal = 0;

   // Start Row - dst (Row * Width In Pixels * Bytes Per Pixel)
   d = texBytes[ dst ] + ( dst_ystart * (int) texSize[ dst ].width *
                           texFormat[ dst ] );
   // Start Row - src (Row * Width In Pixels * Bytes Per Pixel)
   s = texBytes[ src ] + ( src_ystart * (int) texSize[ src ].width *
                           texFormat[ src ] );

   for( i = 0 ; i < src_height; i++ )     // Height Loop
   {
      // Move Through Src Data By Bytes Per Pixel
      s = s + ( src_xstart * texFormat[ src ] );
      // Move Through Dst Data By Bytes Per Pixel
      d = d + ( dst_xstart * texFormat[ dst ] );
      for( j = 0 ; j < src_width; j++ )   // Width Loop
      {
         // "n" Bytes At A Time
         for( k = 0 ; k < texFormat[ src ]; k++, d++, s++ )
         {
            if( blend )    // If Blending Is On
            {
               // Multiply Src Data*alpha Add Dst Data*(255-alpha)
               *d = ( ( *s * alphaVal ) + ( *d * ( 255 - alphaVal ) ) ) >> 8;
            }
            else           // Keep in 0-255 Range With >> 8
            {
               // No Blending Just Do A Straight Copy
               *d = *s;
            }
         }
      }
      d = d + ( (int) texSize[ dst ].width - ( src_width + dst_xstart ) ) *
          texFormat[ dst ];    // Add End Of Row
      s = s + ( (int) texSize[ src ].width - ( src_width + src_xstart ) ) *
          texFormat[ src ];    // Add End Of Row
   }
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

   glTranslatef( 0.0f, 0.0f, -5.0f );

   glRotatef( xrot, 1.0f, 0.0f, 0.0f );
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );
   glRotatef( zrot, 0.0f, 0.0f, 1.0f );

   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );

   glBegin( GL_QUADS );
      // Front Face
      glNormal3f( 0.0f, 0.0f, 1.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  1.0f,  1.0f,  1.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -1.0f,  1.0f,  1.0f );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -1.0f, -1.0f,  1.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  1.0f, -1.0f,  1.0f );
      // Back Face
      glNormal3f( 0.0f, 0.0f, -1.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( -1.0f,  1.0f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  1.0f,  1.0f, -1.0f );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f(  1.0f, -1.0f, -1.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -1.0f, -1.0f, -1.0f );
      // Top Face
      glNormal3f( 0.0f, 1.0f, 0.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  1.0f,  1.0f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -1.0f,  1.0f, -1.0f );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -1.0f,  1.0f,  1.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  1.0f,  1.0f,  1.0f );
      // Bottom Face
      glNormal3f( 0.0f,-1.0f, 0.0f );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f(  1.0f, -1.0f,  1.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -1.0f, -1.0f,  1.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( -1.0f, -1.0f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  1.0f, -1.0f, -1.0f );
      // Right Face
      glNormal3f( 1.0f, 0.0f, 0.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  1.0f, -1.0f, -1.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  1.0f,  1.0f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  1.0f,  1.0f,  1.0f );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f(  1.0f, -1.0f,  1.0f );
      // Left Face
      glNormal3f( -1.0f, 0.0f, 0.0f );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -1.0f, -1.0f, -1.0f );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -1.0f, -1.0f,  1.0f );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( -1.0f,  1.0f,  1.0f );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -1.0f,  1.0f, -1.0f );
   glEnd();

   [ [ self openGLContext ] flushBuffer ];

   xrot += 0.3f;
   yrot += 0.2f;
   zrot += 0.4f;
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
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
