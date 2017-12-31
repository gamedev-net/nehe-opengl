/*
 * Original Windows comment:
 * "This Code Was Created By Ben Humphrey 2001
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit NeHe Productions At http://nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson34View.m */

#import "Lesson34View.h"

@interface Lesson34View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (void) loadRawFile:(NSString *)filename size:(int)mapSize
         map:(GLubyte *)heightMapDest;
- (void) renderHeightMap:(GLubyte *)theHeightMap;
- (void) setVertexColorFrom:(GLubyte *)theHeightMap x:(int)x y:(int)y;
- (int) heightFrom:(GLubyte *)theHeightMap x:(int)xval y:(int)yval;
@end

@implementation Lesson34View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   solidPolys = TRUE;
   scaleValue = 0.15f;
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
   [ self loadRawFile:[ NSString stringWithFormat:@"%@/%s",
                                 [ [ NSBundle mainBundle ] resourcePath ],
                                 "Terrain.raw" ]
          size:MAP_SIZE * MAP_SIZE map:heightMap ];
   
   return TRUE;
}

/*
 * Loads The .RAW File And Stores It In pHeightMap
 */
- (void) loadRawFile:(NSString *)filename size:(int)mapSize
         map:(GLubyte *)heightMapDest
{
   FILE *pFile = NULL;

        // Open The File In Read / Binary Mode.
   pFile = fopen( [ filename cString ], "rb" );

   // Check To See If We Found The File And Could Open It
   if( pFile == NULL )
   {
      // Display Error Message And Stop The Function
      NSRunCriticalAlertPanel( @"Error", @"Can't find the height map!", nil, nil,
                               nil );
      return;
   }

   fread( heightMapDest, 1, mapSize, pFile );

   // After We Read The Data, It's A Good Idea To Check If Everything Read Fine
   if( ferror( pFile ) )
      NSRunCriticalAlertPanel( @"Error", @"Failed to get data!", nil, nil, nil );

   // Close The File.
   fclose( pFile );
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
                   0.1f, 500.0f );
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

   // This Determines Where The Camera's Position And View Is
   //           Position         View      Up Vector
   gluLookAt( 212, 60, 194,  186, 55, 171,  0, 1, 0 );

   glScalef( scaleValue, scaleValue * HEIGHT_RATIO, scaleValue );

   [ self renderHeightMap:heightMap ];   // Render The Height Map

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * This Renders The Height Map As Quads
 */
- (void) renderHeightMap:(GLubyte *)theHeightMap
{
   int X = 0, Y = 0;   // Create Some Variables To Walk The Array With.
   int x, y, z;        // Create Some Variables For Readability

   if( !theHeightMap )
      return;          // Make Sure Our Height Data Is Valid

   if( solidPolys )          // What We Want To Render
      glBegin( GL_QUADS );   // Render Polygons
   else
      glBegin( GL_LINES );   // Render Lines Instead

   for( X = 0; X < MAP_SIZE; X += STEP_SIZE )
      for( Y = 0; Y < MAP_SIZE; Y += STEP_SIZE )
      {
         // Get The (X, Y, Z) Value For The Bottom Left Vertex
         x = X;
         y = [ self heightFrom:theHeightMap x:X y:Y ];
         z = Y;

         // Set The Color Value Of The Current Vertex
         [ self setVertexColorFrom:theHeightMap x:x y:z ];

         // Send This Vertex To OpenGL To Be Rendered (Integer Points Are Faster)
         glVertex3i( x, y, z );

         // Get The (X, Y, Z) Value For The Top Left Vertex
         x = X;                                                   
         y = [ self heightFrom:theHeightMap x:X y:Y + STEP_SIZE ];
         z = Y + STEP_SIZE;

         // Set The Color Value Of The Current Vertex
         [ self setVertexColorFrom:theHeightMap x:x y:z ];

         glVertex3i( x, y, z );   // Send This Vertex To OpenGL To Be Rendered

         // Get The (X, Y, Z) Value For The Top Right Vertex
         x = X + STEP_SIZE;
         y = [ self heightFrom:theHeightMap x:X + STEP_SIZE y:Y + STEP_SIZE ];
         z = Y + STEP_SIZE;

         // Set The Color Value Of The Current Vertex
         [ self setVertexColorFrom:theHeightMap x:x y:z ];

         glVertex3i( x, y, z );   // Send This Vertex To OpenGL To Be Rendered

         // Get The (X, Y, Z) Value For The Bottom Right Vertex
         x = X + STEP_SIZE;
         y = [ self heightFrom:theHeightMap x:X + STEP_SIZE y:Y ];
         z = Y;

         // Set The Color Value Of The Current Vertex
         [ self setVertexColorFrom:theHeightMap x:x y:z ];

         glVertex3i( x, y, z );   // Send This Vertex To OpenGL To Be Rendered
      }

   glEnd();

   glColor4f( 1.0f, 1.0f, 1.0f, 1.0f );   // Reset The Color
}


/*
 * Sets The Color Value For A Particular Index, Depending On The Height Index
 */
- (void) setVertexColorFrom:(GLubyte *)theHeightMap x:(int)x y:(int)y
{
   float color;

   if( !theHeightMap )
      return;                     // Make Sure Our Height Data Is Valid

   color = -0.15f + ( [ self heightFrom:theHeightMap x:x y:y ] / 256.0f );

   // Assign This Blue Shade To The Current Vertex
   glColor3f( 0, 0, color );
}

/*
 * This Returns The Height From A Height Map Index
 */
- (int) heightFrom:(GLubyte *)theHeightMap x:(int)xval y:(int)yval
{
   int x = xval % MAP_SIZE;   // Error Check Our x Value
   int y = yval % MAP_SIZE;   // Error Check Our y Value

   if( !theHeightMap )
      return 0;            // Make Sure Our Data Is Valid

   return theHeightMap[ x + ( y * MAP_SIZE ) ];   // Return the desired height
}


- (void) toggleSolidPolys
{
   solidPolys = !solidPolys;
}


- (void) increaseScaleValue
{
   scaleValue += 0.001f;   // Increase the scale value to zoom in
}


- (void) decreaseScaleValue
{
   scaleValue -= 0.001f;   // Decrease the scale value to zoom out
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
