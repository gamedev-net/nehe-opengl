/*
 * Original Windows comment:
 * "This code has been created by Banu Cosmin aka Choko - 20 may 2000
 * and uses NeHe tutorials as a starting point (window initialization,
 * texture loading, GL initialization and code for keypresses) - very good
 * tutorials, Jeff. If anyone is interested about the presented algorithm
 * please e-mail me at boct@romwest.ro
 * Attention!!! This code is not for beginners."
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson27View.mm */

#import "Lesson27View.h"

typedef float GLvector4f[ 4 ];     // Typedef's For VMatMult Procedure
typedef float GLmatrix16f[ 16 ];   // Typedef's For VMatMult Procedure

@interface Lesson27View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) initGLObjects;
- (void) drawGLRoom;
- (void) multiplyMatrix:(GLmatrix16f)M withVector:(GLvector4f)v;
@end

@implementation Lesson27View

// Ambient Light Values
static float lightAmb[] = {  0.2f,  0.2f,  0.2f, 1.0f };
// Diffuse Light Values
static float lightDif[] = {  0.6f,  0.6f,  0.6f, 1.0f };
// Specular Light Values
static float lightSpc[] = { -0.2f, -0.2f, -0.2f, 1.0f };

// Material - Ambient Values
static float matAmb[] = { 0.4f, 0.4f, 0.4f, 1.0f };
// Material - Diffuse Values
static float matDif[] = { 0.2f, 0.6f, 0.9f, 1.0f };
// Material - Specular Values
static float matSpc[] = { 0.0f, 0.0f, 0.0f, 1.0f };
static float matShn = 0.0f;                   // Material - Shininess

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   xrot = xspeed = yrot = yspeed = 0;
   lightPos[ 0 ] = 0.0f;
   lightPos[ 1 ] = 5.0f;
   lightPos[ 2 ] = -4.0f;
   lightPos[ 3 ] = 1.0f;
   objPos[ 0 ] = -2.0f;
   objPos[ 1 ] = -2.0f;
   objPos[ 2 ] = -5.0f;
   spherePos[ 0 ] = -4.0f;
   spherePos[ 1 ] = -5.0f;
   spherePos[ 2 ] = -6.0f;
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
   pixelAttribs[ pixNum++ ] = (NSOpenGLPixelFormatAttribute) colorBits;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
   pixelAttribs[ pixNum++ ] = (NSOpenGLPixelFormatAttribute) depthBits;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAStencilSize;
   pixelAttribs[ pixNum++ ] = (NSOpenGLPixelFormatAttribute) 1;

   if( runningFullScreen )  // Do this before getting the pixel format
   {
      pixelAttribs[ pixNum++ ] = NSOpenGLPFAFullScreen;
      fullScreenMode = (NSDictionary *) CGDisplayBestModeForParameters(
                                           kCGDirectMainDisplay,
                                           colorBits, (size_t) frame.size.width,
                                           (size_t) frame.size.height, NULL );
      CGDisplayCapture( kCGDirectMainDisplay );
      CGDisplayHideCursor( kCGDirectMainDisplay );
      CGDisplaySwitchToMode( kCGDirectMainDisplay,
                             (CFDictionaryRef) fullScreenMode );
   }
   pixelAttribs[ pixNum ] = (NSOpenGLPixelFormatAttribute) 0;
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
   if( ![ self initGLObjects ] )
      return FALSE;

   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearDepth( 1.0f );                     // Depth buffer setup
   glClearStencil( 0 );                      // Stencil Buffer Setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   glLightfv( GL_LIGHT1, GL_POSITION, lightPos );     // Set Light1 Position
   glLightfv( GL_LIGHT1, GL_AMBIENT, lightAmb );      // Set Light1 Ambience
   glLightfv( GL_LIGHT1, GL_DIFFUSE, lightDif );      // Set Light1 Diffuse
   glLightfv( GL_LIGHT1, GL_SPECULAR, lightSpc );     // Set Light1 Specular
   glEnable( GL_LIGHT1 );                             // Enable Light1
   glEnable( GL_LIGHTING );                           // Enable Lighting

   glMaterialfv( GL_FRONT, GL_AMBIENT, matAmb );      // Set Material Ambience
   glMaterialfv( GL_FRONT, GL_DIFFUSE, matDif );      // Set Material Diffuse
   glMaterialfv( GL_FRONT, GL_SPECULAR, matSpc );     // Set Material Specular
   glMaterialfv( GL_FRONT, GL_SHININESS, &matShn );   // Set Material Shininess

   glCullFace( GL_BACK );                    // Set Culling Face To Back Face
   glEnable( GL_CULL_FACE );                 // Enable Culling
   glClearColor( 0.1f, 1.0f, 0.5f, 1.0f );   // Set Clear Color (Greenish Color)

   q = gluNewQuadric();                      // Initialize Quadric
   gluQuadricNormals( q, GL_SMOOTH );        // Enable Smooth Normal Generation
   gluQuadricTexture( q, GL_FALSE );         // Disable Auto Texture Coords
   
   return TRUE;
}


/*
 * Initialize Objects
 */
- (BOOL) initGLObjects
{
   unsigned int i;

   // Read Object2 Into obj
   if( !ReadObject( [ [ [ NSBundle mainBundle ]
                        pathForResource:@"Object2" ofType:@"txt" ] UTF8String ],
                    &obj ) )
      return FALSE;                           // If Failed Return False

   SetConnectivity( &obj );                   // Set Face To Face Connectivity

   for( i = 0; i < obj.nPlanes; i++ )           // Loop Through All Object Planes
   {
      // Compute Plane Equations For All Faces
      CalcPlane( obj, &( obj.planes[ i ] ) );
   }

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
   glViewport( 0, 0, (GLsizei) sceneBounds.size.width,
               (GLsizei) sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   0.099f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   GLmatrix16f Minv;
   GLvector4f wlp, lp;

   // Clear Color Buffer, Depth Buffer, Stencil Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT );

   glLoadIdentity();                                // Reset Modelview Matrix
   glTranslatef( 0.0f, 0.0f, -20.0f );              // Zoom Into Screen 20 Units
   glLightfv( GL_LIGHT1, GL_POSITION, lightPos );   // Position Light1
   // Position The Sphere
   glTranslatef( spherePos[ 0 ], spherePos[ 1 ], spherePos[ 2 ] );
   gluSphere( q, 1.5f, 32, 16 );                    // Draw A Sphere

   // calculate light's position relative to local coordinate system
   // dunno if this is the best way to do it, but it actually works
   // if u find another aproach, let me know ;)

   // we build the inversed matrix by doing all the actions in reverse order
   // and with reverse parameters (notice -xrot, -yrot, -ObjPos[], etc.)
   glLoadIdentity();                                // Reset Matrix
   glRotatef( -yrot, 0.0f, 1.0f, 0.0f );            // Rotate By -yrot On Y Axis
   glRotatef( -xrot, 1.0f, 0.0f, 0.0f );            // Rotate By -xrot On X Axis
   // Retrieve ModelView Matrix (Stores In Minv)
   glGetFloatv( GL_MODELVIEW_MATRIX, Minv );
   lp[ 0 ] = lightPos[ 0 ];                    // Store Light Position X In lp[0]
   lp[ 1 ] = lightPos[ 1 ];                    // Store Light Position Y In lp[1]
   lp[ 2 ] = lightPos[ 2 ];                    // Store Light Position Z In lp[2]
   lp[ 3 ] = lightPos[ 3 ];                    // Store Light Direction In lp[3]
   // We Store Rotated Light Vector In 'lp' Array
   [ self multiplyMatrix:Minv withVector:lp ];
   // Move Negative On All Axis Based On ObjPos[] Values (X, Y, Z)
   glTranslatef( -objPos[ 0 ], -objPos[ 1 ], -objPos[ 2 ] );
   // Retrieve ModelView Matrix From Minv
   glGetFloatv( GL_MODELVIEW_MATRIX, Minv );
   wlp[ 0 ] = 0.0f;                            // World Local Coord X To 0
   wlp[ 1 ] = 0.0f;                            // World Local Coord Y To 0
   wlp[ 2 ] = 0.0f;                            // World Local Coord Z To 0
   wlp[ 3 ] = 1.0f;
   /*
    * We Store The Position Of The World Origin Relative To The
    * Local Coord. System In 'wlp' Array
    */
   [ self multiplyMatrix:Minv withVector:wlp ];

   lp[ 0 ] += wlp[ 0 ];                         // Adding These Two Gives Us The
   lp[ 1 ] += wlp[ 1 ];                         // Position Of The Light Relative
   lp[ 2 ] += wlp[ 2 ];                         // To The Local Coordinate System

   glColor4f( 0.7f, 0.4f, 0.0f, 1.0f );         // Set Color To An Orange
   glLoadIdentity();                            // Reset Modelview Matrix
   glTranslatef( 0.0f, 0.0f, -20.0f );          // Zoom Into The Screen 20 Units
   [ self drawGLRoom ];                         // Draw The Room
   // Position The Object
   glTranslatef( objPos[ 0 ], objPos[ 1 ], objPos[ 2 ] );
   glRotatef( xrot, 1.0f, 0.0f, 0.0f );         // Spin It On The X Axis By xrot
   glRotatef( yrot, 0.0f, 1.0f, 0.0f );         // Spin It On The Y Axis By yrot
   DrawGLObject( obj );               // Procedure For Drawing The Loaded Object
   // Procedure For Casting The Shadow Based On The Silhouette
   CastShadow( &obj, lp );

   glColor4f( 0.7f, 0.4f, 0.0f, 1.0f );         // Set Color To Purplish Blue
   glDisable( GL_LIGHTING );                    // Disable Lighting
   glDepthMask( GL_FALSE );                     // Disable Depth Mask
   glTranslatef( lp[ 0 ], lp[ 1 ], lp[ 2 ] );   // Translate To Light's Position
   // Notice We're Still In Local Coordinate System

   // Draw A Little Yellow Sphere (Represents Light)
   gluSphere( q, 0.2f, 16, 8 );   
   glEnable( GL_LIGHTING );                     // Enable Lighting
   glDepthMask( GL_TRUE );                      // Enable Depth Mask

   xrot += xspeed;                              // Increase xrot By xspeed
   yrot += yspeed;                              // Increase yrot By yspeed

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Draw The Room (Box)
 */
- (void) drawGLRoom
{
   glBegin( GL_QUADS );                       // Begin Drawing Quads
      // Floor
      glNormal3f( 0.0f, 1.0f, 0.0f );         // Normal Pointing Up
      glVertex3f( -10.0f, -10.0f, -20.0f );   // Back Left
      glVertex3f( -10.0f, -10.0f,  20.0f );   // Front Left
      glVertex3f(  10.0f, -10.0f,  20.0f );   // Front Right
      glVertex3f(  10.0f, -10.0f, -20.0f );   // Back Right
      // Ceiling
      glNormal3f( 0.0f, -1.0f, 0.0f );        // Normal Point Down
      glVertex3f( -10.0f, 10.0f,  20.0f );    // Front Left
      glVertex3f( -10.0f, 10.0f, -20.0f );    // Back Left
      glVertex3f(  10.0f, 10.0f, -20.0f );    // Back Right
      glVertex3f(  10.0f, 10.0f,  20.0f );    // Front Right
      // Front Wall
      glNormal3f( 0.0f, 0.0f, 1.0f );         // Normal Pointing Away From Viewer
      glVertex3f( -10.0f,  10.0f, -20.0f );   // Top Left
      glVertex3f( -10.0f, -10.0f, -20.0f );   // Bottom Left
      glVertex3f(  10.0f, -10.0f, -20.0f );   // Bottom Right
      glVertex3f(  10.0f,  10.0f, -20.0f );   // Top Right
      // Back Wall
      glNormal3f( 0.0f, 0.0f, -1.0f );        // Normal Pointing Towards Viewer
      glVertex3f(  10.0f,  10.0f, 20.0f );    // Top Right
      glVertex3f(  10.0f, -10.0f, 20.0f );    // Bottom Right
      glVertex3f( -10.0f, -10.0f, 20.0f );    // Bottom Left
      glVertex3f( -10.0f,  10.0f, 20.0f );    // Top Left
      // Left Wall
      glNormal3f( 1.0f, 0.0f, 0.0f );         // Normal Pointing Right
      glVertex3f( -10.0f,  10.0f,  20.0f );   // Top Front
      glVertex3f( -10.0f, -10.0f,  20.0f );   // Bottom Front
      glVertex3f( -10.0f, -10.0f, -20.0f );   // Bottom Back
      glVertex3f( -10.0f,  10.0f, -20.0f );   // Top Back
      // Right Wall
      glNormal3f( -1.0f, 0.0f, 0.0f );        // Normal Pointing Left
      glVertex3f( 10.0f,  10.0f, -20.0f );    // Top Back
      glVertex3f( 10.0f, -10.0f, -20.0f );    // Bottom Back
      glVertex3f( 10.0f, -10.0f,  20.0f );    // Bottom Front
      glVertex3f( 10.0f,  10.0f,  20.0f );    // Top Front
   glEnd();                                   // Done Drawing Quads
}


/*
 * Multiply the given matrix and vector
 */
- (void) multiplyMatrix:(GLmatrix16f)M withVector:(GLvector4f)v
{
   GLfloat res[ 4 ];                                  // Hold Calculated Results

   res[ 0 ] = M[  0 ] * v[ 0 ] + M[  4 ] * v[ 1 ] +
              M[  8 ] * v[ 2 ] + M[ 12 ] * v[ 3 ];
   res[ 1 ] = M[  1 ] * v[ 0 ] + M[  5 ] * v[ 1 ] +
              M[  9 ] * v[ 2 ] + M[ 13 ] * v[ 3 ];
   res[ 2 ] = M[  2 ] * v[ 0 ] + M[  6 ] * v[ 1 ] +
              M[ 10 ] * v[ 2 ] + M[ 14 ] * v[ 3 ];
   res[ 3 ] = M[  3 ] * v[ 0 ] + M[  7 ] * v[ 1 ] +
              M[ 11 ] * v[ 2 ] + M[ 15 ] * v[ 3 ];
   v[ 0 ] = res[ 0 ];                // Results Are Stored Back In v[]
   v[ 1 ] = res[ 1 ];
   v[ 2 ] = res[ 2 ];
   v[ 3 ] = res[ 3 ];                // Homogenous Coordinate
}


- (void) decreaseYSpeed
{
   yspeed -= 0.1f;
}


- (void) increaseYSpeed
{
   yspeed += 0.1f;
}


- (void) decreaseXSpeed
{
   xspeed -= 0.1f;
}


- (void) increaseXSpeed
{
   xspeed += 0.1f;
}


- (void) moveLightRight
{
   lightPos[ 0 ] += 0.05f;
}


- (void) moveLightLeft
{
   lightPos[ 0 ] -= 0.05f;
}


- (void) moveLightUp
{
   lightPos[ 1 ] += 0.05f;
}


- (void) moveLightDown
{
   lightPos[ 1 ] -= 0.05f;
}


- (void) moveLightToViewer
{
   lightPos[ 2 ] += 0.05f;
}


- (void) moveLightFromViewer
{
   lightPos[ 2 ] -= 0.05f;
}


- (void) moveObjectRight
{
   objPos[ 0 ] += 0.05f;
}


- (void) moveObjectLeft
{
   objPos[ 0 ] -= 0.05f;
}


- (void) moveObjectUp
{
   objPos[ 1 ] += 0.05f;
}


- (void) moveObjectDown
{
   objPos[ 1 ] -= 0.05f;
}


- (void) moveObjectToViewer
{
   objPos[ 2 ] += 0.05f;
}


- (void) moveObjectFromViewer
{
   objPos[ 2 ] -= 0.05f;
}


- (void) moveBallRight
{
   spherePos[ 0 ] += 0.05f;
}


- (void) moveBallLeft
{
   spherePos[ 0 ] -= 0.05f;
}


- (void) moveBallUp
{
   spherePos[ 1 ] += 0.05f;
}


- (void) moveBallDown
{
   spherePos[ 1 ] -= 0.05f;
}


- (void) moveBallToViewer
{
   spherePos[ 2 ] += 0.05f;
}


- (void) moveBallFromViewer
{
   spherePos[ 2 ] -= 0.05f;
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
