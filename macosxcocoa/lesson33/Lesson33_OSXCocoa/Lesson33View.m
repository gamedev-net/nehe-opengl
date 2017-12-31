/*
 * Original Windows comment:
 * "Based On Lesson 6"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson33View.m */

#import "Lesson33View.h"

@interface Lesson33View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
@end

@implementation Lesson33View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
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

   glEnable( GL_TEXTURE_2D );                       // Enable Texture Mapping
   glShadeModel( GL_SMOOTH );                       // Enable Smooth Shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );          // Black Background
   glClearDepth( 1.0f );                            // Depth Buffer Setup
   glEnable( GL_DEPTH_TEST );                       // Enables Depth Testing
   glDepthFunc( GL_LEQUAL );                        // The Type Of Depth Testing To Do
   // Really Nice Perspective Calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   
   return TRUE;
}


/*
 * Load Bitmaps And Convert To Textures
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;
   NSString *resourcePath = [ [ NSBundle mainBundle ] resourcePath ];
   int loop;

   // Load The Bitmap, Check For Errors.
   if( LoadTGA( &texture[ 0 ], [ [ resourcePath stringByAppendingFormat:@"/%s",
                                                   "Uncompressed.tga" ] cString ] ) &&
       LoadTGA( &texture[ 1 ], [ [ resourcePath stringByAppendingFormat:@"/%s",
                                                   "Compressed.tga" ] cString ] ) )
   {
      status = TRUE;

      for( loop = 0; loop < 2; loop++ )            // Loop Through Both Textures
      {
         // Typical Texture Generation Using Data From The TGA
         glGenTextures( 1, &texture[ loop ].texID );   // Create The Texture
         glBindTexture( GL_TEXTURE_2D, texture[ loop ].texID );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texture[ loop ].width,
                       texture[ loop ].height, 0, GL_RGB, GL_UNSIGNED_BYTE,
                       texture[ loop ].imageData );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

         if( texture[ loop ].imageData )   // If Texture Image Exists
            free( texture[ loop ].imageData );     // Free The Texture Image Memory
      }
   }

   return status;
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

   // Clear The Screen And The Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();                          // Reset The Modelview Matrix
   glTranslatef( 0.0f, 0.0f, -10.0f );        // Translate 10 Units Into The Screen

   spin += 0.05f;                             // Increase Spin

   for( loop = 0; loop < 20; loop++ )
   {
      glPushMatrix();                              // Push The Matrix
      // Rotate On The X-Axis (Up - Down)
      glRotatef( spin + loop * 18.0f, 1.0f, 0.0f, 0.0f );
      glTranslatef( -2.0f, 2.0f, 0.0f );           // Translate 2 Units Left And 2 Up

      glBindTexture( GL_TEXTURE_2D, texture[ 0 ].texID );
      glBegin( GL_QUADS );                         // Draw Our Quad
         glTexCoord2f( 0.0f, 1.0f );
         glVertex3f( -1.0f,  1.0f, 0.0f );
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f,  1.0f, 0.0f );
         glTexCoord2f( 1.0f, 0.0f );
         glVertex3f(  1.0f, -1.0f, 0.0f );
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f, -1.0f, 0.0f );
      glEnd();                                     // Done Drawing The Quad
      glPopMatrix();                               // Pop The Matrix

      glPushMatrix();                              // Push The Matrix
      glTranslatef( 2.0f, 0.0f, 0.0f );            // Translate 2 Units To The Right
      // Rotate On The Y-Axis (Left - Right)
      glRotatef( spin + loop * 36.0f, 0.0f, 1.0f, 0.0f );
      glTranslatef( 1.0f, 0.0f, 0.0f );            // Move One Unit Right

      glBindTexture( GL_TEXTURE_2D, texture[ 1 ].texID );
      glBegin( GL_QUADS );                         // Draw Our Quad
         glTexCoord2f( 0.0f, 0.0f );
         glVertex3f( -1.0f,  1.0f, 0.0f );
         glTexCoord2f( 1.0f, 0.0f );
         glVertex3f(  1.0f,  1.0f, 0.0f );
         glTexCoord2f( 1.0f, 1.0f );
         glVertex3f(  1.0f, -1.0f, 0.0f );
         glTexCoord2f( 0.0f, 1.0f );
         glVertex3f( -1.0f, -1.0f, 0.0f );
      glEnd();                                     // Done Drawing The Quad
      glPopMatrix();                               // Pop The Matrix
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
