/*
 * Original Windows comment:
 * "This code was created by Pet & Commented/Cleaned Up By Jeff Molofee
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson25View.m */

#import "Lesson25View.h"

@interface Lesson25View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (void) objLoad:(const char *)name into:(OBJECT *)k;
- (void) objAllocate:(OBJECT *)k number:(int)n;
- (void) objFree:(OBJECT *)k;
- (void) readFrom:(FILE *)f intoString:(char *)string;
- (VERTEX) calculate:(int)i;
@end

@implementation Lesson25View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   cz = -15.0f;
   key = 1;
   step = 0;
   steps = 200;
   morph = FALSE;
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
   NSString *resourcePath = [ [ NSBundle mainBundle ] resourcePath ];
   int i;

   // Select the blending function for translucency
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glDepthFunc( GL_LESS )  ;                 // Type of depth test to do
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glShadeModel( GL_SMOOTH );                // Enables smooth color shading
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   maxver = 0;
   // Load the object; data from Sphere.txt into morph1, Torus.txt into
   // morph2, and Tube.txt into morph3
   [ self objLoad:[ [ resourcePath stringByAppendingFormat:@"/%s",
                                    "Sphere.txt" ] cString ] into:&morph1 ];
   [ self objLoad:[ [ resourcePath stringByAppendingFormat:@"/%s",
                                    "Torus.txt" ] cString ] into:&morph2 ];
   [ self objLoad:[ [ resourcePath stringByAppendingFormat:@"/%s",
                                    "Tube.txt" ] cString ] into:&morph3 ];
   // Create space for 486 vertices
   [ self objAllocate:&morph4 number:486 ];
   for( i = 0; i < 486; i++ )
   {
      // Random vertex, with each value being from -7 to 7
      morph4.points[ i ].x = (float) ( rand() % 14000 ) / 1000 - 7;
      morph4.points[ i ].y = (float) ( rand() % 14000 ) / 1000 - 7;
      morph4.points[ i ].z = (float) ( rand() % 14000 ) / 1000 - 7;
   }
   // Load Sphere.txt into helper (used as starting point)
   [ self objLoad:[ [ resourcePath stringByAppendingFormat:@"/%s",
                                 "Sphere.txt" ] cString ] into:&helper ];
   sour = dest = &morph1;   // Source and destination are set to morph1

   return TRUE;
}


/*
 * Loads object into k from the given file name
 */
- (void) objLoad:(const char *)name into:(OBJECT *)k
{
   int ver;   // Hold the vertex count
   float rx, ry, rz;   // Hold vertex x,y,z position
   FILE *filein;
   char oneline[ 255 ];   // Holds a line of text
   int i;

   filein = fopen( name, "rt" );  // Open the file, readonly, text mode
   // Read first interesting line
   [ self readFrom:filein intoString:oneline ];
   // Load the number of vertices into ver
   sscanf( oneline, "Vertices: %d\n", &ver );
   k->verts = ver;
   [ self objAllocate:k number:ver ];   // Create the object's memory
   for( i = 0; i < ver; i++ )
   {
      [ self readFrom:filein intoString:oneline ];
      // Read in the X,Y,Z values
      sscanf( oneline, "%f %f %f", &rx, &ry, &rz );
      k->points[ i ].x = rx;
      k->points[ i ].y = ry;
      k->points[ i ].z = rz;
   }
   fclose( filein );

   if( ver > maxver )
      maxver = ver;   // Keep track of highest number of vertices used
}


- (void) objAllocate:(OBJECT *)k number:(int)n
{
   // Allocate memory for n VERTEX's, storing into k's points
   k->points = (VERTEX *) malloc( sizeof( VERTEX ) * n );
}


- (void) objFree:(OBJECT *)k
{
   free( k->points );
}


- (void) readFrom:(FILE *)f intoString:(char *)string
{
   do
   {
      fgets( string, 255, f );
   } while( ( string[ 0 ] == '/' ) || ( string[ 0 ] == '\n' ) );

   return;
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
   GLfloat tx, ty, tz;
   VERTEX q;   // Calculated values for a vertex
   int i;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix

   glTranslatef( cx, cy, cz );   // Translate to start drawing
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );   // Rotate X axis by xrot
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );   // Rotate Y axis by yrot
   glRotatef( zrot, 0.0f, 0.0f, 1.0f );   // Rotate Z axis by zrot

   xrot += xspeed;   // Increase rotations
   yrot += yspeed;   //    by their
   zrot += zspeed;   //    respective speeds

   glBegin( GL_POINTS );
   // Loop over all vertices of morph1 (all objects have same number of
   // vertices for simplicity, could use maxver as well)
   for( i = 0; i < morph1.verts; i++ )
   {
      if( morph )
         q = [ self calculate:i ];   // Calculate movement
      else
         q.x = q.y = q.z = 0;        // No movement
      helper.points[ i ].x -= q.x;
      helper.points[ i ].y -= q.y;
      helper.points[ i ].z -= q.z;
      tx = helper.points[ i ].x;
      ty = helper.points[ i ].y;
      tz = helper.points[ i ].z;
      glColor3f( 0.0f, 1.0f, 1.0f );   // Set color to cyan
      glVertex3f( tx, ty, tz );        // Draw a point
      glColor3f( 0.0f, 0.5f, 1.0f );   // Darken color a bit
      tx -= 2 * q.x;
      ty -= 2 * q.y;
      tz -= 2 * q.z;
      glVertex3f( tx, ty, tz );
      glColor3f( 0.0f, 0.0f, 1.0f );   // Set color to bright blue
      tx -= 2 * q.x;
      ty -= 2 * q.y;
      tz -= 2 * q.z;
      glVertex3f( tx, ty, tz );
   }   // This creates a ghostly tail as points move
   glEnd();

   // If we're morphing and we haven't gone through all 'steps' steps,
   // increase our step counter; otherwise, set morphing to false,
   // make source=destination, and reset the step counter
   if( morph && step <= steps )
      step++;
   else
   {
      morph = FALSE;
      sour = dest;
      step = 0;
   }

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Calculate movement of points during morphing
 */
- (VERTEX) calculate:(int)i
{
   VERTEX a;

   a.x = ( sour->points[ i ].x - dest->points[ i ].x ) / steps;
   a.y = ( sour->points[ i ].y - dest->points[ i ].y ) / steps;
   a.z = ( sour->points[ i ].z - dest->points[ i ].z ) / steps;

   return a;
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) decreaseZSpeed
{
   zspeed -= 0.01f;
}


- (void) increaseZSpeed
{
   zspeed += 0.01f;
}


- (void) decreaseXSpeed
{
   xspeed -= 0.01f;
}


- (void) increaseXSpeed
{
   xspeed += 0.01f;
}


- (void) decreaseYSpeed
{
   yspeed -= 0.01f;
}


- (void) increaseYSpeed
{
   yspeed += 0.01f;
}


- (void) decreaseZPos
{
   cz -= 0.01f;
}


- (void) increaseZPos
{
   cz += 0.01f;
}


- (void) decreaseYPos
{
   cy -= 0.01f;
}


- (void) increaseYPos
{
   cy += 0.01f;
}


- (void) decreaseXPos
{
   cx -= 0.01f;
}


- (void) increaseXPos
{
   cx += 0.01f;
}


- (void) setMorphTo1
{
   if( ( key != 1 ) && !morph )
   {
      key = 1;
      morph = TRUE;
      dest = &morph1;
   }
}


- (void) setMorphTo2
{
   if( ( key != 2 ) && !morph )
   {
      key = 2;
      morph = TRUE;
      dest = &morph2;
   }
}


- (void) setMorphTo3
{
   if( ( key != 3 ) && !morph )
   {
      key = 3;
      morph = TRUE;
      dest = &morph3;
   }
}


- (void) setMorphTo4
{
   if( ( key != 4 ) && !morph )
   {
      key = 4;
      morph = TRUE;
      dest = &morph4;
   }
}


/*
 * Cleanup
 */
- (void) dealloc
{
   [ self objFree:&morph1 ];
   [ self objFree:&morph2 ];
   [ self objFree:&morph3 ];
   [ self objFree:&morph4 ];
   [ self objFree:&helper ];

   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
