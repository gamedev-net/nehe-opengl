/*
 * Original Windows comment:
 * "Radial Blur & Rendering To A Texture
 * How To Create A Radial Blur Effect
 * Dario Corno (rIo) / Jeff Molofee (NeHe)
 * http://www.spinningkids.org/rio
 * http://nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson36View.m */

#import "Lesson36View.h"

@interface Lesson36View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (GLuint) emptyTexture;
- (void) renderToTexture;
- (void) processHelix;
- (void) drawBlur:(int)times increment:(float)inc;
- (void) calcNormalFor:(float [][ 3 ])v into:(float *)outvec;
- (void) reduceToUnit:(float *)vector;
- (void) viewOrtho;
- (void) viewPerspective;
@end

@implementation Lesson36View

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
   // Set Ambient Lighting To Fairly Dark Light (No Color)
   GLfloat global_ambient[ 4 ] = { 0.2f, 0.2f,  0.2f, 1.0f };
   // Set The Light Position
   GLfloat light0pos[ 4 ] =      { 0.0f, 5.0f, 10.0f, 1.0f };
   // More Ambient Light
   GLfloat light0ambient[ 4 ] =  { 0.2f, 0.2f,  0.2f, 1.0f };
   // Set The Diffuse Light A Bit Brighter
   GLfloat light0diffuse[ 4 ] =  { 0.3f, 0.3f,  0.3f, 1.0f };
   // Fairly Bright Specular Lighting
   GLfloat light0specular[ 4 ] = { 0.8f, 0.8f,  0.8f, 1.0f };

   angle = 0.0f;                             // Set Starting Angle To Zero
   blurTexture = [ self emptyTexture ];      // Create Our Empty Texture
   glEnable( GL_DEPTH_TEST );                // Enable depth testing

   // Set The Global Ambient Light Model
   glLightModelfv( GL_LIGHT_MODEL_AMBIENT, global_ambient );
   glLightfv( GL_LIGHT0, GL_POSITION, light0pos );   // Set The Lights Position
   glLightfv( GL_LIGHT0, GL_AMBIENT, light0ambient );   // Set The Ambient Light
   glLightfv( GL_LIGHT0, GL_DIFFUSE, light0diffuse );   // Set The Diffuse Light
   // Set Up Specular Lighting
   glLightfv( GL_LIGHT0, GL_SPECULAR, light0specular );
   glEnable( GL_LIGHTING );                             // Enable Lighting
   glEnable( GL_LIGHT0 );                               // Enable Light0

   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glMateriali( GL_FRONT, GL_SHININESS, 128 );

   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   
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

   /*
    * Since bounds is a private ivar in NSView, we have to either call
    * [ self bounds ] for the size (needed in several places), or just note
    * it once and store it when it changes.
    */
   viewSize = sceneBounds.size;

   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 50.0f, sceneBounds.size.width / sceneBounds.size.height,
                   5.0f, 2000.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Create an empty texture
 */
- (GLuint) emptyTexture
{
   GLuint txtnumber;     // Texture ID
   unsigned int *data;   // Stored data

   // calloc() will zero out the memory for us
   data = calloc( 128 * 128 * 4, sizeof( GLuint ) );

   glGenTextures( 1, &txtnumber );   // Create one texture
   glBindTexture( GL_TEXTURE_2D, txtnumber );
   glTexImage2D( GL_TEXTURE_2D, 0, 4, 128, 128, 0, GL_RGBA, GL_UNSIGNED_BYTE,
                 data );   // Build texture using empty buffer
   glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
   glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

   free( data );

   return txtnumber;
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Set The Clear Color To Black
   // Clear Screen And Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();                         // Reset The View
   [ self renderToTexture ];                 // Render To A Texture
   [ self processHelix ];                    // Draw Our Helix
   [ self drawBlur:25 increment:0.02f ];     // Draw The Blur Effect

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Renders To A Texture
 */
- (void) renderToTexture
{
   glViewport( 0, 0, 128, 128 );   // Set Our Viewport (Match Texture Size)

   [ self processHelix ];          // Render The Helix

   glBindTexture( GL_TEXTURE_2D, blurTexture );   // Bind To The Blur Texture

   // Copy Our ViewPort To The Blur Texture (From 0,0 To 128,128... No Border)
   glCopyTexImage2D( GL_TEXTURE_2D, 0, GL_LUMINANCE, 0, 0, 128, 128, 0 );

   // Set The Clear Color To Medium Blue
   glClearColor( 0.0f, 0.0f, 0.5f, 0.5f );
   // Clear The Screen And Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

   // Set viewport to the entire view's size
   glViewport( 0, 0, viewSize.width, viewSize.height );
}


/*
 * Draws A Helix
 */
- (void) processHelix
{
   GLfloat x;        // Helix x Coordinate
   GLfloat y;        // Helix y Coordinate
   GLfloat z;        // Helix z Coordinate
   GLfloat phi;      // Angle
   GLfloat theta;    // Angle
   GLfloat v,u;      // Angles
   GLfloat r;        // Radius Of Twist
   int twists = 5;   // 5 Twists
   // Set The Material Color
   GLfloat glfMaterialColor[] = { 0.4f, 0.2f, 0.8f, 1.0f };
   // Sets Up Specular Lighting
   GLfloat specular[] = { 1.0f, 1.0f, 1.0f, 1.0f };
   float vertexes[ 4 ][ 3 ];   // Store for the vertex data
   float normal[ 3 ];          // Normals

   glLoadIdentity();                             // Reset The Modelview Matrix
   // Eye Position (0,5,50) Center Of Scene (0,0,0), Up On Y Axis
   gluLookAt( 0, 5, 50, 0, 0, 0, 0, 1, 0 );

   glPushMatrix();                               // Push The Modelview Matrix

   glTranslatef( 0, 0, -50 );            // Translate 50 Units Into The Screen
   glRotatef( angle / 2.0f, 1, 0, 0 );   // Rotate By angle/2 On The X-Axis
   glRotatef( angle / 3.0f, 0, 1, 0 );   // Rotate By angle/3 On The Y-Axis

   glMaterialfv( GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, glfMaterialColor );
   glMaterialfv( GL_FRONT_AND_BACK, GL_SPECULAR, specular );

   r = 1.5f;                                       // Radius
   glBegin( GL_QUADS );                            // Begin Drawing Quads
   for( phi = 0; phi <= 360; phi += 20.0 )         // 360 Degrees In Steps Of 20
   {
      // 360 Degrees * Number Of Twists In Steps Of 20
      for( theta = 0; theta <= 360 * twists; theta += 20.0 )
      {
         // Calculate Angle Of First Point (  0 )
         v = ( phi / 180.0f * 3.142f );
         // Calculate Angle Of First Point (  0 )
         u = ( theta / 180.0f * 3.142f );

         // Calculate x Position (1st Point)
         x = cos( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate y Position (1st Point)
         y = sin( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate z Position (1st Point)
         z = ( ( u - ( 2.0f * 3.142f ) ) + sin( v ) ) * r;

         vertexes[ 0 ][ 0 ] = x;            // Set x Value Of First Vertex
         vertexes[ 0 ][ 1 ] = y;            // Set y Value Of First Vertex
         vertexes[ 0 ][ 2 ] = z;            // Set z Value Of First Vertex

         // Calculate Angle Of Second Point (  0 )
         v = ( phi / 180.0f * 3.142f );
         // Calculate Angle Of Second Point      ( 20 )
         u = ( ( theta + 20 ) / 180.0f * 3.142f );

         // Calculate x Position (2nd Point)
         x = cos( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate y Position (2nd Point)
         y = sin( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate z Position (2nd Point)
         z = ( ( u - ( 2.0f * 3.142f ) ) + sin( v ) ) * r;

         vertexes[ 1 ][ 0 ] = x;   // Set x Value Of Second Vertex
         vertexes[ 1 ][ 1 ] = y;   // Set y Value Of Second Vertex
         vertexes[ 1 ][ 2 ] = z;   // Set z Value Of Second Vertex

         // Calculate Angle Of Third Point       ( 20 )
         v = ( ( phi + 20 ) / 180.0f * 3.142f );
         // Calculate Angle Of Third Point       ( 20 )
         u = ( ( theta + 20 ) / 180.0f * 3.142f );

         // Calculate x Position (3rd Point)
         x = cos( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate y Position (3rd Point)
         y = sin( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate z Position (3rd Point)
         z = ( ( u - ( 2.0f * 3.142f ) ) + sin( v ) ) * r;

         vertexes[ 2 ][ 0 ] = x;   // Set x Value Of Third Vertex
         vertexes[ 2 ][ 1 ] = y;   // Set y Value Of Third Vertex
         vertexes[ 2 ][ 2 ] = z;   // Set z Value Of Third Vertex

         // Calculate Angle Of Fourth Point      ( 20 )
         v = ( ( phi + 20 ) / 180.0f * 3.142f );
         // Calculate Angle Of Fourth Point      (  0 )
         u = ( ( theta ) / 180.0f * 3.142f );

         // Calculate x Position (4th Point)
         x = cos( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate y Position (4th Point)
         y = sin( u ) * ( 2.0f + cos( v ) ) * r;
         // Calculate z Position (4th Point)
         z = ( ( u - ( 2.0f * 3.142f ) ) + sin( v ) ) * r;

         vertexes[ 3 ][ 0 ] = x;   // Set x Value Of Fourth Vertex
         vertexes[ 3 ][ 1 ] = y;   // Set y Value Of Fourth Vertex
         vertexes[ 3 ][ 2 ] = z;   // Set z Value Of Fourth Vertex

         // Calculate The Quad Normal
         [ self calcNormalFor:vertexes into:normal ];

         glNormal3f( normal[ 0 ], normal[ 1 ], normal[ 2 ] );   // Set The Normal

         // Render The Quad
         glVertex3f( vertexes[ 0 ][ 0 ], vertexes[ 0 ][ 1 ],
                     vertexes[ 0 ][ 2 ] );
         glVertex3f( vertexes[ 1 ][ 0 ], vertexes[ 1 ][ 1 ],
                     vertexes[ 1 ][ 2 ] );
         glVertex3f( vertexes[ 2 ][ 0 ], vertexes[ 2 ][ 1 ],
                     vertexes[ 2 ][ 2 ] );
         glVertex3f( vertexes[ 3 ][ 0 ], vertexes[ 3 ][ 1 ],
                     vertexes[ 3 ][ 2 ] );
      }
   }
   glEnd();         // Done Rendering Quads

   glPopMatrix();   // Pop The Matrix
}


/*
 * Draw The Blurred Image
 */
- (void) drawBlur:(int)times increment:(float)inc
{
   float spost = 0.0f;              // Starting Texture Coordinate Offset
   float alphainc = 0.9f / times;   // Fade Speed For Alpha Blending
   float alpha = 0.2f;              // Starting Alpha Value
   int num;

   // Disable AutoTexture Coordinates
   glDisable( GL_TEXTURE_GEN_S );
   glDisable( GL_TEXTURE_GEN_T );

   glEnable( GL_TEXTURE_2D );                     // Enable 2D Texture Mapping
   glDisable( GL_DEPTH_TEST );                    // Disable Depth Testing
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );           // Set Blending Mode
   glEnable( GL_BLEND );                          // Enable Blending
   glBindTexture( GL_TEXTURE_2D, blurTexture );   // Bind To The Blur Texture
   [ self viewOrtho ];                            // Switch To An Ortho View

   alphainc = alpha / times;   // alphainc=0.2f / Times To Render Blur

   glBegin( GL_QUADS );        // Begin Drawing Quads
   for( num = 0; num < times; num++ )   // Number Of Times To Render Blur
   {
      // Set The Alpha Value (Starts At 0.2)
      glColor4f( 1.0f, 1.0f, 1.0f, alpha );
      glTexCoord2f( 0 + spost, 1 - spost );   // Texture Coordinate   ( 0, 1 )
      glVertex2f( 0, 0 );                     // First Vertex         ( 0, 0 )

      glTexCoord2f( 0 + spost, 0 + spost );   // Texture Coordinate   ( 0, 0 )
      glVertex2f( 0, viewSize.height );       // Second Vertex        ( 0, h )

      glTexCoord2f( 1 - spost, 0 + spost );   // Texture Coordinate   ( 1, 0 )
      // Third Vertex                                                 ( w, h )
      glVertex2f( viewSize.width, viewSize.height );

      glTexCoord2f( 1 - spost, 1 - spost );   // Texture Coordinate   ( 1, 1 )
      glVertex2f( viewSize.width, 0 );        // Fourth Vertex        ( w, 0 )

      // Gradually Increase spost (Zooming Closer To Texture Center)
      spost += inc;
      // Gradually Decrease alpha (Gradually Fading Image Out)
      alpha = alpha - alphainc;
   }
   glEnd();                    // Done Drawing Quads

   [ self viewPerspective ];   // Switch To A Perspective View

   glEnable( GL_DEPTH_TEST );           // Enable Depth Testing
   glDisable( GL_TEXTURE_2D );          // Disable 2D Texture Mapping
   glDisable( GL_BLEND );               // Disable Blending
   glBindTexture( GL_TEXTURE_2D, 0 );   // Unbind The Blur Texture
}


/*
 * Calculates Normal For A Quad Using 3 Points
 */
- (void) calcNormalFor:(float [][ 3 ])v into:(float *)outvec
{
   float v1[ 3 ], v2[ 3 ];   // Vector 1 (x,y,z) & Vector 2 (x,y,z)
   static const int x = 0;   // Define X Coord
   static const int y = 1;   // Define Y Coord
   static const int z = 2;   // Define Z Coord

   /*
    * Finds The Vector Between 2 Points By Subtracting
    * The x,y,z Coordinates From One Point To Another.
    */

   // Calculate The Vector From Point 1 To Point 0
   v1[ x ] = v[ 0 ][ x ] - v[ 1 ][ x ];   // Vector 1.x=Vertex[0].x-Vertex[1].x
   v1[ y ] = v[ 0 ][ y ] - v[ 1 ][ y ];   // Vector 1.y=Vertex[0].y-Vertex[1].y
   v1[ z ] = v[ 0 ][ z ] - v[ 1 ][ z ];   // Vector 1.z=Vertex[0].y-Vertex[1].z
   // Calculate The Vector From Point 2 To Point 1
   v2[ x ] = v[ 1 ][ x ] - v[ 2 ][ x ];   // Vector 2.x=Vertex[0].x-Vertex[1].x
   v2[ y ] = v[ 1 ][ y ] - v[ 2 ][ y ];   // Vector 2.y=Vertex[0].y-Vertex[1].y
   v2[ z ] = v[ 1 ][ z ] - v[ 2 ][ z ];   // Vector 2.z=Vertex[0].z-Vertex[1].z
   // Compute The Cross Product To Give Us A Surface Normal
   // Cross Product For Y - Z
   outvec[ x ] = v1[ y ] * v2[ z ] - v1[ z ] * v2[ y ];
   // Cross Product For X - Z
   outvec[ y ] = v1[ z ] * v2[ x ] - v1[ x ] * v2[ z ];
   // Cross Product For X - Y
   outvec[ z ] = v1[ x ] * v2[ y ] - v1[ y ] * v2[ x ];

   [ self reduceToUnit:outvec ];   // Normalize The Vectors
}


/*
 * Reduces A Normal Vector (3 Coordinates) To A Unit Normal Vector With A
 * Length Of One.
 */
- (void) reduceToUnit:(float *)vector
{
   float length;   // Holds Unit Length

   // Calculates The Length Of The Vector
   length = (float) sqrt( ( vector[ 0 ] * vector[ 0 ] ) +
                          ( vector[ 1 ] * vector[ 1 ] ) +
                          ( vector[ 2 ] * vector[ 2 ] ) );

   if( length == 0.0f )     // Prevents Divide By 0 Error By Providing
      length = 1.0f;        // An Acceptable Value For Vectors To Close To 0.

   vector[ 0 ] /= length;   // Dividing Each Element By
   vector[ 1 ] /= length;   // The Length Results In A
   vector[ 2 ] /= length;   // Unit Normal Vector.
}


/*
 * Set Up An Ortho View
 */
- (void) viewOrtho
{
   glMatrixMode( GL_PROJECTION );        // Select Projection
   glPushMatrix();                       // Push The Matrix
   glLoadIdentity();                     // Reset The Matrix
   // Select ortho mode for the entire view
   glOrtho( 0, viewSize.width, viewSize.height, 0, -1, 1 );
   glMatrixMode( GL_MODELVIEW );         // Select Modelview Matrix
   glPushMatrix();                       // Push The Matrix
   glLoadIdentity();                     // Reset The Matrix
}


/*
 * Set Up A Perspective View
 */
- (void) viewPerspective
{
   glMatrixMode( GL_PROJECTION );   // Select Projection
   glPopMatrix();                   // Pop The Matrix
   glMatrixMode( GL_MODELVIEW );    // Select Modelview
   glPopMatrix();                   // Pop The Matrix
}


/*
 * Perform Motion Updates Here
 */
- (void) update:(long)milliseconds
{
   angle += (float) milliseconds / 5.0f;   // Update angle Based On The Clock
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
   glDeleteTextures( 1, &blurTexture );   // Delete the blur texture
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
