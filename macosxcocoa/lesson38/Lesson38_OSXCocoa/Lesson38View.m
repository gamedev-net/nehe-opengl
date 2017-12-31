/*
 * Original Windows comment:
 * "Jeff Molofee's Lesson 38
 *     nehe.gamedev.net
 *           2002"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson38View.m */

#import "Lesson38View.h"

@interface Lesson38View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) setObject:(int)loop;
@end

// Typedef For Our Compare Function
typedef int ( *compfn )( const void *, const void * );

// Compare function (in C since it's passed to qsort())
int Compare( object *elem1, object *elem2 );

@implementation Lesson38View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   tilt = 45.0f;
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
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glDisable( GL_DEPTH_TEST );               // Disable depth testing
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   glEnable( GL_TEXTURE_2D );                // Enable Texture Mapping
   glEnable( GL_BLEND );                     // Enable Blending

   for( loop = 0; loop < 50; loop++ )        // Loop To Initialize 50 Objects
      [ self setObject:loop ];               // Assign New Random Values

   return TRUE;
}


/*
 * Creates Textures From Bitmaps
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;
   NSBundle *mainBundle;
   int loop;

   mainBundle = [ NSBundle mainBundle ];
   if( [ self loadBitmap:[ mainBundle pathForResource:@"Butterfly1" ofType:@"bmp" ]
              intoIndex:0 ] &&
       [ self loadBitmap:[ mainBundle pathForResource:@"Butterfly2" ofType:@"bmp" ]
              intoIndex:1 ] &&
       [ self loadBitmap:[ mainBundle pathForResource:@"Butterfly3" ofType:@"bmp" ]
              intoIndex:2 ] &&
       [ self loadBitmap:[ mainBundle pathForResource:@"ButterflyMask"
                                      ofType:@"bmp" ] intoIndex:3 ] )
   {
      status = TRUE;

      glGenTextures( 4, &texture[ 0 ] );   // Create the texture

      for( loop = 0; loop < 4; loop++ )
      {
         glBindTexture( GL_TEXTURE_2D, texture[ loop ] );   // Bind our texture
         // Linear Filtering
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
         // Mipmap Linear Filtering
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                          GL_LINEAR_MIPMAP_LINEAR);
         /*
          * Generate Mipmapped Texture (3 Bytes, Width, Height And Data From
          * The BMP)
          */
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
                   1.0f, 1000.0f );
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
   for( loop = 0; loop < 50; loop++ )               // Loop Of 50 (Draw 50 Objects)
   {
      glLoadIdentity();                             // Reset The Modelview Matrix
      // Position The Object
      glTranslatef( obj[ loop ].x, obj[ loop ].y, obj[ loop ].z );
      glRotatef( tilt, 1.0f, 0.0f, 0.0f );                // Rotate On The X-Axis
      glRotatef( obj[ loop ].spinz, 0.0f, 0.0f, 1.0f );   // Spin On The Z-Axis

      // Set Blending Mask Cancels Screen Objects
      glBlendFunc( GL_DST_COLOR, GL_ZERO );
      // Bind Our Texture (Mask Texture)
      glBindTexture( GL_TEXTURE_2D, texture[ 3 ] );

      glBegin( GL_TRIANGLES );                      // Begin Drawing Triangles
         /*
          * First Triangle, vertices as:
          *      (2)|    / (1)
          *         |  /
          *      (3)|/
          */
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f,  1.0f, 0.0f );
         glTexCoord2f( 0.0f, 1.0f );
         glVertex3f( -1.0f,  1.0f, obj[ loop ].flap );
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f, -1.0f, 0.0f );

         /*
          * Second Triangle, vertices as:
          *             /|(1)
          *           /  |
          *      (2)/____|(3)
          */
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f,  1.0f, 0.0f );
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f, -1.0f, 0.0f );
         glTexCoord2f( 1.0f, 0.0f );
         glVertex3f(  1.0f, -1.0f, obj[ loop ].flap );

      glEnd();                                     // Done Drawing Triangles

      glBlendFunc( GL_ONE, GL_ONE );               // Object Only Maps To Mask
      // Bind Our Texture (Random Butterfly)
      glBindTexture( GL_TEXTURE_2D, texture[ obj[ loop ].tex ] );
      glBegin( GL_TRIANGLES );                      // Begin Drawing Triangles
         /*
          * First Triangle, vertices as:
          *      (2)|    / (1)
          *         |  /
          *      (3)|/
          */
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f,  1.0f, 0.0f );
         glTexCoord2f( 0.0f, 1.0f );
         glVertex3f( -1.0f,  1.0f, obj[ loop ].flap );
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f, -1.0f, 0.0f );

         /*
          * Second Triangle, vertices as:
          *             /|(1)
          *           /  |
          *      (2)/____|(3)
          */
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f,  1.0f, 0.0f );
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f, -1.0f, 0.0f );
         glTexCoord2f( 1.0f, 0.0f );
         glVertex3f(  1.0f, -1.0f, obj[ loop ].flap );

      glEnd();                                     // Done Drawing Triangles

      obj[ loop ].y -= obj[ loop ].yi;             // Move Object Down The Screen
      obj[ loop ].spinz += obj[ loop ].spinzi;     // Increase Z Rotation By spinzi
      obj[ loop ].flap += obj[ loop ].fi;          // Increase flap Value By fi
      if( obj[ loop ].y < -18.0f )                 // Is Object Off The Screen?
         [ self setObject:loop ];                  // If So, Reassign New Values

      // Time To Change Flap Direction?
      if( ( obj[ loop ].flap > 1.0f ) || ( obj[ loop ].flap < -1.0f ) )
         obj[ loop ].fi = -obj[ loop ].fi;   // Change Direction By Making fi = -fi
   }

   // Create A Short Delay (15 Milliseconds)
   [ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.015 ] ];

   [ [ self openGLContext ] flushBuffer ];
}


/*
 *Sets The Initial Value Of Each Object (Random)
 */
- (void) setObject:(int)loop
{
   obj[ loop ].tex = rand() % 3;          // Texture Can Be One Of 3 Textures
   obj[ loop ].x = rand() % 34 - 17.0f;   // Random x Value From -17.0f To 17.0f
   obj[ loop ].y = 18.0f;              // Set y Position To 18 (Off Top Of Screen)
   // z Is A Random Value From -10.0f To -40.0f
   obj[ loop ].z = -( ( rand() % 30000 / 1000.0f ) + 10.0f );
   // spinzi Is A Random Value From -1.0f To 1.0f
   obj[ loop ].spinzi = ( rand() % 10000 ) / 5000.0f - 1.0f;
   obj[ loop ].flap = 0.0f;               // flap Starts Off At 0.0f;
   // fi Is A Random Value From 0.05f To 0.15f
   obj[ loop ].fi = 0.05f + ( rand() % 100 ) / 1000.0f;
   // yi Is A Random Value From 0.001f To 0.101f
   obj[ loop ].yi = 0.001f + ( rand() % 1000 ) / 10000.0f;
   // Perform Sort (50 Objects)
   qsort( obj, 50, sizeof( object ), (compfn) Compare );
}


/*
 * Compare Function *** MSDN CODE MODIFIED FOR THIS TUT ***
 */
int Compare( object *elem1, object *elem2 )
{
   if( elem1->z < elem2->z )        // If First distance Is Less Than The Second
      return -1;
   else if( elem1->z > elem2->z )   // If First distance Is Greater Than The Second
      return 1;
   else                             // Otherwise (If The distance Is Equal)
      return 0;
}


- (void) increaseTilt
{
   tilt += 1.0f;                    // Tilt Butterflies
}


- (void) decreaseTilt
{
   tilt -= 1.0f;                    // Tilt Butterflies
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
