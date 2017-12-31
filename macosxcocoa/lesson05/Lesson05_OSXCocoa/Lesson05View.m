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

/* Lesson05View.m */

#import "Lesson05View.h"

@interface Lesson05View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
@end

@implementation Lesson05View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   rtri = rquad = 0;
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
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   
   return TRUE;
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

   glTranslatef( -1.5f, 0.0f, -6.0f );   // Left 1.5 units, into screen 6.0
   // Rotate triangle on Y axis
   glRotatef( rtri, 0.0f, 1.0f, 0.0f );

   glBegin( GL_TRIANGLES );              // Draw a triangle
   glColor3f( 1.0f, 0.0f, 0.0f );        // Set color to red
   glVertex3f(  0.0f,  1.0f, 0.0f );     // Top of front
   glColor3f( 0.0f, 1.0f, 0.0f );        // Set color to green
   glVertex3f( -1.0f, -1.0f, 1.0f );     // Bottom left of front
   glColor3f( 0.0f, 0.0f, 1.0f );        // Set color to blue
   glVertex3f(  1.0f, -1.0f, 1.0f );     // Bottom right of front

   glColor3f( 1.0f, 0.0f, 0.0f );        // Red
   glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of right side
   glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
   glVertex3f( 1.0f, -1.0f, 1.0f );      // Left of right side
   glColor3f( 0.0f, 1.0f, 0.0f );        // Green
   glVertex3f( 1.0f, -1.0f, -1.0f );     // Right of right side

   glColor3f( 1.0f, 0.0f, 0.0f );        // Red
   glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of back side
   glColor3f( 0.0f, 1.0f, 0.0f );        // Green
   glVertex3f( 1.0f, -1.0f, -1.0f );     // Left of back side
   glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
   glVertex3f( -1.0f, -1.0f, -1.0f );    // Right of back side

   glColor3f( 1.0f, 0.0f, 0.0f );        // Red
   glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of left side
   glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
   glVertex3f( -1.0f, -1.0f, -1.0f );    // Left of left side
   glColor3f( 0.0f, 1.0f, 0.0f );        // Green
   glVertex3f( -1.0f, -1.0f, 1.0f );     // Right of left side
   glEnd();                              // Done with triangle

   glLoadIdentity();                       // Reset current modelview matrix
   glTranslatef( 1.5f, 0.0f, -7.0f );      // Move right and into screen
   // Rotate quad on all axes
   glRotatef( rquad, 1.0f, 1.0f, 1.0f );

   glBegin( GL_QUADS );                 // Draw quads
   glColor3f( 0.0f, 1.0f, 0.0f );       // Green
   glVertex3f(  1.0f,  1.0f, -1.0f );   // Top right of top side
   glVertex3f( -1.0f,  1.0f, -1.0f );   // Top left of top side
   glVertex3f( -1.0f,  1.0f,  1.0f );   // Bottom left of top side
   glVertex3f(  1.0f,  1.0f,  1.0f );   // Bottom right of top side
   
   glColor3f( 1.0f, 0.5f, 0.0f );       // Orange
   glVertex3f(  1.0f, -1.0f,  1.0f );   // Top right of bottom side
   glVertex3f( -1.0f, -1.0f,  1.0f );   // Top left of bottom side
   glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom left of bottom side
   glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom right of bottom side
   
   glColor3f( 1.0f, 0.0f, 0.0f );       // Red  
   glVertex3f(  1.0f,  1.0f,  1.0f );   // Top right of front side
   glVertex3f( -1.0f,  1.0f,  1.0f );   // Top left of front side
   glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom left of front side
   glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom right of front side

   glColor3f( 1.0f, 1.0f, 0.0f );       // Yellow
   glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom left of back side
   glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom right of back side
   glVertex3f( -1.0f,  1.0f, -1.0f );   // Top right of back side
   glVertex3f(  1.0f,  1.0f, -1.0f );   // Top left of back side
   
   glColor3f( 0.0f, 0.0f, 1.0f );       // Blue
   glVertex3f( -1.0f,  1.0f,  1.0f );   // Top right of left side
   glVertex3f( -1.0f,  1.0f, -1.0f );   // Top left of left side
   glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom left of left side
   glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom right of left side
   
   glColor3f( 1.0f, 0.0f, 1.0f );       // Violet 
   glVertex3f(  1.0f,  1.0f, -1.0f );   // Top right of right side
   glVertex3f(  1.0f,  1.0f,  1.0f );   // Top left of right side
   glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom left of right side
   glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom right of right side
   glEnd();                             // Quads are complete

   [ [ self openGLContext ] flushBuffer ];

   rtri += 0.2f;     // Increase the rotation variable for the triangle
   rquad -= 0.15f;   // Decrease the rotation variable for the quad
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
