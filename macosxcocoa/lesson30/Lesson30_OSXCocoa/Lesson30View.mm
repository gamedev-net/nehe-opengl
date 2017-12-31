/*
 * Original Windows comment:
 * "Programmer: Dimitrios Christopoulos
 *
 * Windows Frame Code Was Published By Jeff Molofee 2000
 * Code Was Created By David Nikdel For NeHe Productions
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson30View.mm */

#import "Lesson30View.h"

@interface Lesson30View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (void) initVars;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) testIntersionPlane:(const Plane&)plane
         position:(const TVector&)position
         direction:(const TVector&)direction lambda:(double&)lambda
         normal:(TVector&)pNormal;
- (BOOL) testIntersionCylinder:(const Cylinder&)cylinder
         position:(const TVector&)position
         direction:(const TVector&)direction lambda:(double&)lambda
         normal:(TVector&)pNormal newPosition:(TVector&)newposition;
- (BOOL) findBallCol:(TVector&)point timePoint:(double&)TimePoint
         time2:(double)Time2 ball1:(int&)BallNr1 ball2:(int&)BallNr2;
@end

@implementation Lesson30View

// sets specular highlight of balls
GLfloat spec[] = { 1.0, 1.0, 1.0, 1.0 };
GLfloat posl[] = { 0, 400, 0, 1 };             // position of ligth source
GLfloat amb[] = { 0.2f, 0.2f, 0.2f ,1.0f };    // global ambient
GLfloat amb2[] = { 0.3f, 0.3f, 0.3f ,1.0f };   // ambient of lightsource

TVector dir( 0, 0, -10 );          // initial direction of camera
TVector pos( 0, -50, 1000 );       // initial position of camera
TVector veloc( 0.5, -0.1, 0.5 );   // initial velocity of balls
TVector accel( 0, -0.05, 0 );      // acceleration ie. gravity of balls

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   explodeSound = [ [ NSSound alloc ] initWithContentsOfFile:[ NSString
                                    stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Explode.wav" ]
                                      byReference:YES ];
   sounds = TRUE;
   Time = 0.6;
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
         else
            [ self initVars ];
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

   if( runningFullScreen )  // Do this before getting the pixel format
   {
      pixelAttribs[ pixNum++ ] = NSOpenGLPFAFullScreen;
      fullScreenMode = (NSDictionary *) CGDisplayBestModeForParameters(
                                           kCGDirectMainDisplay,
                                           colorBits,
                                           (size_t) frame.size.width,
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
         {
            [ self initVars ];
            success = TRUE;
         }
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
 * Init variables
 */
- (void) initVars
{
   // create planes
   pl1._Position = TVector( 0, -300, 0 );
   pl1._Normal = TVector( 0, 1, 0 );
   pl2._Position = TVector( 300, 0, 0 );
   pl2._Normal = TVector( -1, 0, 0 );
   pl3._Position = TVector( -300, 0, 0 );
   pl3._Normal = TVector( 1, 0, 0 );
   pl4._Position = TVector( 0, 0, 300 );
   pl4._Normal = TVector( 0, 0, -1 );
   pl5._Position = TVector( 0, 0, -300 );
   pl5._Normal = TVector( 0, 0, 1 );

   // create cylinders
   cyl1._Position = TVector( 0, 0, 0 );
   cyl1._Axis = TVector( 0, 1, 0 );
   cyl1._Radius = 60 + 20;
   cyl2._Position = TVector( 200, -300, 0 );
   cyl2._Axis = TVector( 0, 0, 1 );
   cyl2._Radius = 60 + 20;
   cyl3._Position = TVector( -200, 0, 0 );
   cyl3._Axis = TVector( 0, 1, 1 );
   cyl3._Axis.unit();
   cyl3._Radius = 30 + 20;

   // create quadratic object to render cylinders
   cylinder_obj = gluNewQuadric();
   gluQuadricTexture( cylinder_obj, GL_TRUE );

   // Set initial positions and velocities of balls
   // also initialize array which holds explosions
   NrOfBalls = 10;
   ArrayVel[ 0 ] = veloc;
   ArrayPos[ 0 ] = TVector( 199, 180, 10 );
   ExplosionArray[ 0 ]._Alpha = 0;
   ExplosionArray[ 0 ]._Scale = 1;
   ArrayVel[ 1 ] = veloc;
   ArrayPos[ 1 ] = TVector( 0, 150, 100 );
   ExplosionArray[ 1 ]._Alpha = 0;
   ExplosionArray[ 1 ]._Scale = 1;
   ArrayVel[ 2 ] = veloc;
   ArrayPos[ 2 ] = TVector( -100, 180, -100 );
   ExplosionArray[ 2 ]._Alpha = 0;
   ExplosionArray[ 2 ]._Scale = 1;
   for( int i = 3; i < 10; i++ )
   {
      ArrayVel[ i ] = veloc;
      ArrayPos[ i ] = TVector( -500 + i * 75, 300, -500 + i * 50 );
      ExplosionArray[ i ]._Alpha = 0;
      ExplosionArray[ i ]._Scale = 1;
   }
   for( int i = 10; i < 20; i++ )
   {
      ExplosionArray[ i ]._Alpha = 0;
      ExplosionArray[ i ]._Scale = 1;
   }
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 
   float df = 100.0;

   glClearDepth( 1.0f );        // Depth Buffer Setup
   glEnable( GL_DEPTH_TEST );   // Enables Depth Testing
   glDepthFunc( GL_LEQUAL );    // The Type Of Depth Testing To Do
   // Really Nice Perspective Calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   glClearColor( 0, 0, 0, 0 );
   glMatrixMode( GL_MODELVIEW );
   glLoadIdentity();

   glShadeModel( GL_SMOOTH );
   glEnable( GL_CULL_FACE );
   glEnable( GL_DEPTH_TEST );

   glMaterialfv( GL_FRONT, GL_SPECULAR, spec );
   glMaterialfv( GL_FRONT, GL_SHININESS, &df );

   glEnable( GL_LIGHTING );
   glLightfv( GL_LIGHT0, GL_POSITION, posl );
   glLightfv( GL_LIGHT0, GL_AMBIENT, amb2 );
   glEnable( GL_LIGHT0 );

   glLightModelfv( GL_LIGHT_MODEL_AMBIENT, amb );
   glEnable( GL_COLOR_MATERIAL );
   glColorMaterial( GL_FRONT, GL_AMBIENT_AND_DIFFUSE );

   glEnable( GL_BLEND );
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );

   glEnable( GL_TEXTURE_2D );
   if( ![ self loadGLTextures ] )
      return FALSE;

   // Construct billboarded explosion primitive as display list
   // 4 quads at right angles to each other
   glNewList( dlist = glGenLists( 1 ), GL_COMPILE );
   glBegin( GL_QUADS );
      glRotatef( -45, 0, 1, 0 );
      glNormal3f( 0, 0, 1 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -50, -40, 0 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  50, -40, 0 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  50,  40, 0 );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -50,  40, 0 );

      glNormal3f( 0, 0, -1 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -50,  40, 0 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  50,  40, 0 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  50, -40, 0 );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -50, -40, 0 );

      glNormal3f( 1, 0, 0 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( 0, -40,  50 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( 0, -40, -50 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( 0,  40, -50 );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( 0,  40,  50 );

      glNormal3f( -1, 0, 0 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( 0,  40,  50 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( 0,  40, -50 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( 0, -40, -50 );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( 0, -40,  50 );
   glEnd();
   glEndList();
   
   return TRUE;
}


/*
 * Load Bitmaps And Convert To Textures
 */
- (BOOL) loadGLTextures
{
   Image *images[ 4 ];
   NSString *resourcePath = [ [ NSBundle mainBundle ] resourcePath ];
   int index;

   for( index = 0; index < 4; index++ )
   {
      images[ index ] = (Image *) malloc( sizeof( Image ) );
      if( images[ index ] == NULL )
      {
         printf( "Error allocating space for image %d\n", index );
         return FALSE;
      }
   }

   if( !ImageLoad( [ [ NSString stringWithFormat:@"%@/%s", resourcePath,
                              "Marble.bmp" ] cString ], images[ 0 ] ) )
      return FALSE;
   if( !ImageLoad( [ [ NSString stringWithFormat:@"%@/%s", resourcePath,
                              "Spark.bmp" ] cString ], images[ 1 ] ) )
      return FALSE;
   if( !ImageLoad( [ [ NSString stringWithFormat:@"%@/%s", resourcePath,
                              "Boden.bmp" ] cString ], images[ 2 ] ) )
      return FALSE;
   if( !ImageLoad( [ [ NSString stringWithFormat:@"%@/%s", resourcePath,
                              "Wand.bmp" ] cString ], images[ 3 ] ) )
      return FALSE;

   glGenTextures( 4, &texture[ 0 ] );
   for( index = 0; index < 4; index++ )
   {
      glBindTexture( GL_TEXTURE_2D, texture[ index ] );
      // 2d texture, level of detail 0 (normal), 3 components (red, green,
      //  blue), x size from image, y size from image, border 0 (normal), rgb
      // color data, unsigned byte data, and finally the data itself.
      glTexImage2D( GL_TEXTURE_2D, 0, 3, images[ index ]->sizeX,
                    images[ index ]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE,
                    images[ index ]->data );

      // scale linearly when image bigger than texture
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      // scale linearly when image smaller than texture
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );

      free( images[ index ]->data );
      free( images[ index ] );
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
   glViewport( 0, 0, (long int) sceneBounds.size.width,
               (long int) sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 50.0f, sceneBounds.size.width / sceneBounds.size.height,
                   10.0f, 1700.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Main loop of the simulation
 * Moves, finds the collisions and responses of the objects in the
 * current time step.
 * (called idle() in original Windows code)
 */
- (void) advanceSimulation
{
   double rt, rt2, rt4, lambda = 10000;
   TVector norm, uveloc;
   TVector normal, point;
   double RestTime, BallTime;
   TVector Pos2;
   int BallNr = 0, dummy = 0, BallColNr1, BallColNr2;
   TVector Nc;

   if( !hook_toball1 )
   {
      camera_rotation += 0.1f;
      if( camera_rotation > 360 )
         camera_rotation = 0;
   }             
 
   RestTime = Time;
   lambda = 1000;

   // Compute velocity for next timestep using Euler equations
   for( int j = 0; j < NrOfBalls; j++ )
      ArrayVel[ j ] += accel * RestTime;

   // While timestep not over
   while( RestTime > ZERO )
   {
      lambda = 10000;   // initialize to very large value

      // For all the balls find closest intersection between balls and
      // planes/cylinders
      for( int i = 0;i < NrOfBalls; i++ )
      {
         // compute new position and distance
         OldPos[ i ] = ArrayPos[ i ];
         TVector::unit( ArrayVel[ i ], uveloc );
         ArrayPos[ i ] = ArrayPos[ i ] + ArrayVel[ i ] * RestTime;
         rt2 = OldPos[ i ].dist( ArrayPos[ i ] );

         // Test if collision occured between ball and all 5 planes
         if( [ self testIntersionPlane:pl1 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm ] )
         {
            // Find intersection time
            rt4 = rt * RestTime / rt2;

            // if smaller than the one already stored replace and in
            // timestep
            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = OldPos[ i ] + uveloc * rt;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }

         if( [ self testIntersionPlane:pl2 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = OldPos[ i ] + uveloc * rt;
                     lambda = rt4;
                     BallNr = i;
                     dummy = 1;
                  }
            }
         }

         if( [ self testIntersionPlane:pl3 position:OldPos[ i ]
                    direction:uveloc  lambda:rt normal:norm ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = OldPos[ i ] + uveloc * rt;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }

         if( [ self testIntersionPlane:pl4 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = OldPos[ i ] + uveloc * rt;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }

         if( [ self testIntersionPlane:pl5 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = OldPos[ i ] + uveloc * rt;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }

         // Now test intersection with the 3 cylinders
         if( [ self testIntersionCylinder:cyl1 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm newPosition:Nc ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = Nc;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }
         if( [ self testIntersionCylinder:cyl2 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm newPosition:Nc ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = Nc;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }
         if( [ self testIntersionCylinder:cyl3 position:OldPos[ i ]
                    direction:uveloc lambda:rt normal:norm newPosition:Nc ] )
         {
            rt4 = rt * RestTime / rt2;

            if( rt4 <= lambda )
            {
               if( rt4 <= RestTime + ZERO )
                  if( !( ( rt <= ZERO ) && ( uveloc.dot( norm ) > ZERO ) ) )
                  {
                     normal = norm;
                     point = Nc;
                     lambda = rt4;
                     BallNr = i;
                  }
            }
         }
      }

      // After all balls were teste with planes/cylinders test for
      // collision between them and replace if collision time smaller
      if( [ self findBallCol:Pos2 timePoint:BallTime time2:RestTime
                 ball1:BallColNr1 ball2:BallColNr2 ] )
      {
         if( sounds )
            [ explodeSound play ];

         if( ( lambda == 10000 ) || ( lambda > BallTime ) )
         {
            RestTime = RestTime - BallTime;

            TVector pb1,pb2,xaxis,U1x,U1y,U2x,U2y,V1x,V1y,V2x,V2y;
            double a,b;

            pb1 = OldPos[ BallColNr1 ] + ArrayVel[ BallColNr1 ] * BallTime;
            pb2 = OldPos[ BallColNr2 ] + ArrayVel[ BallColNr2 ] * BallTime;
            xaxis = ( pb2 - pb1 ).unit();

            a = xaxis.dot( ArrayVel[ BallColNr1 ] );
            U1x = xaxis * a;
            U1y = ArrayVel[ BallColNr1 ] - U1x;

            xaxis = ( pb1 - pb2 ).unit();
            b = xaxis.dot( ArrayVel[ BallColNr2 ] );
            U2x = xaxis * b;
            U2y = ArrayVel[ BallColNr2 ] - U2x;

            V1x = ( U1x + U2x - ( U1x - U2x ) ) * 0.5;
            V2x = ( U1x + U2x - ( U2x - U1x ) ) * 0.5;
            V1y = U1y;
            V2y = U2y;

            for( int j = 0; j < NrOfBalls; j++ )
               ArrayPos[ j ] = OldPos[ j ] + ArrayVel[ j ] * BallTime;

            ArrayVel[ BallColNr1 ] = V1x + V1y;
            ArrayVel[ BallColNr2 ] = V2x + V2y;

            // Update explosion array
            for( int j = 0; j < 20; j++ )
            {
               if( ExplosionArray[ j ]._Alpha <= 0 )
               {
                  ExplosionArray[ j ]._Alpha = 1;
                  ExplosionArray[ j ]._Position = ArrayPos[ BallColNr1 ];
                  ExplosionArray[ j ]._Scale = 1;
                  break;
               }
            }

            continue;
         }
      }

      // End of tests
      // If test occured move simulation for the correct timestep
      // and compute response for the colliding ball
      if( lambda != 10000 )
      {
         RestTime -= lambda;

         for( int j = 0; j < NrOfBalls; j++ )
            ArrayPos[ j ] = OldPos[ j ] + ArrayVel[ j ] * lambda;

         rt2 = ArrayVel[ BallNr ].mag();
         ArrayVel[ BallNr ].unit();
         ArrayVel[ BallNr ] = TVector::unit( ( normal * ( 2 *
                    normal.dot( -ArrayVel[ BallNr ] ) ) ) +
                    ArrayVel[ BallNr ] );
         ArrayVel[ BallNr ] = ArrayVel[ BallNr ] * rt2;

         // Update explosion array
         for( int j = 0; j < 20; j++ )
         {
            if( ExplosionArray[ j ]._Alpha <= 0 )
            {
               ExplosionArray[ j ]._Alpha = 1;
               ExplosionArray[ j ]._Position = point;
               ExplosionArray[ j ]._Scale = 1;
               break;
            }
         }
      }
      else
         RestTime = 0;
   }
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   int i;

   glMatrixMode( GL_MODELVIEW );
   glLoadIdentity();

   // set camera in hookmode
   if( hook_toball1 )
   {
      TVector unit_followvector = ArrayVel[ 0 ];
      unit_followvector.unit();
      gluLookAt( ArrayPos[ 0 ].X() + 250,
                 ArrayPos[ 0 ].Y() + 250,
                 ArrayPos[ 0 ].Z(),
                 ArrayPos[ 0 ].X() + ArrayVel[ 0 ].X(),
                 ArrayPos[ 0 ].Y() + ArrayVel[ 0 ].Y(),
                 ArrayPos[ 0 ].Z() + ArrayVel[ 0 ].Z(),
                 0, 1, 0 );
   }
   else
      gluLookAt( pos.X(), pos.Y(), pos.Z(),
                 pos.X() + dir.X(), pos.Y() + dir.Y(), pos.Z() + dir.Z(),
                 0, 1, 0 );

   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

   glRotatef( camera_rotation, 0, 1, 0 );

   // render balls
   for( i = 0; i < NrOfBalls; i++ )
   {
      switch( i )
      {
         case 1:
            glColor3f( 1.0f, 1.0f, 1.0f );
            break;
         case 2:
            glColor3f( 1.0f, 1.0f, 0.0f );
            break;
         case 3:
            glColor3f( 0.0f, 1.0f, 1.0f );
            break;
         case 4:
            glColor3f( 0.0f, 1.0f, 0.0f );
            break;
         case 5:
            glColor3f( 0.0f, 0.0f, 1.0f );
            break;
         case 6:
            glColor3f( 0.65f, 0.2f, 0.3f );
            break;
         case 7:
            glColor3f( 1.0f, 0.0f, 1.0f );
            break;
         case 8:
            glColor3f( 0.0f, 0.7f, 0.4f );
            break;
         default:
            glColor3f( 1.0f, 0, 0 );
      }
      glPushMatrix();
      glTranslated( ArrayPos[ i ].X(), ArrayPos[ i ].Y(),
                    ArrayPos[ i ].Z() );
      gluSphere( cylinder_obj, 20, 20, 20 );
      glPopMatrix();
   }

   glEnable( GL_TEXTURE_2D );

   // render walls(planes) with texture
   glBindTexture( GL_TEXTURE_2D, texture[ 3 ] );
   glColor3f( 1, 1, 1 );
   glBegin( GL_QUADS );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  320,  320, 320 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  320, -320, 320 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -320, -320, 320 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -320,  320, 320 );

      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -320,  320, -320 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( -320, -320, -320 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  320, -320, -320 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f(  320,  320, -320 );

      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( 320,  320, -320 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( 320, -320, -320 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( 320, -320,  320 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( 320,  320,  320 );

      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -320,  320,  320 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f( -320, -320,  320 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -320, -320, -320 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -320,  320, -320 );
   glEnd();

   // render floor (plane) with colours
   glBindTexture( GL_TEXTURE_2D, texture[ 2 ] );
   glBegin( GL_QUADS );
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f( -320, -320,  320 );
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  320, -320,  320 );
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f(  320, -320, -320 );
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -320, -320, -320 );
   glEnd();

   // render columns(cylinders)
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
   glColor3f( 0.5, 0.5, 0.5 );
   glPushMatrix();
   glRotatef( 90, 1, 0, 0 );
   glTranslatef( 0, 0, -500 );
   gluCylinder( cylinder_obj, 60, 60, 1000, 20, 2 );
   glPopMatrix();

   glPushMatrix();
   glTranslatef( 200, -300, -500 );
   gluCylinder( cylinder_obj, 60, 60, 1000, 20, 2 );
   glPopMatrix();

   glPushMatrix();
   glTranslatef( -200, 0, 0 );
   glRotatef( 135, 1, 0, 0 );
   glTranslatef( 0, 0, -500 );
   gluCylinder( cylinder_obj, 30, 30, 1000, 20, 2 );
   glPopMatrix();

   // render/blend explosions
   glEnable( GL_BLEND );
   glDepthMask( GL_FALSE );
   glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );
   for( i = 0; i < 20; i++ )
   {
      if( ExplosionArray[ i ]._Alpha >= 0 )
      {
         glPushMatrix();
         ExplosionArray[ i ]._Alpha -= 0.01f;
         ExplosionArray[ i ]._Scale += 0.03f;
         glColor4f( 1, 1, 0, ExplosionArray[ i ]._Alpha );
         glScalef( ExplosionArray[ i ]._Scale, ExplosionArray[ i ]._Scale,
                   ExplosionArray[ i ]._Scale );
         glTranslatef( (float) ExplosionArray[ i ]._Position.X() /
                       ExplosionArray[ i ]._Scale,
                       (float) ExplosionArray[ i ]._Position.Y() /
                       ExplosionArray[ i ]._Scale,
                       (float) ExplosionArray[ i ]._Position.Z() /
                       ExplosionArray[ i ]._Scale );
         glCallList( dlist );
         glPopMatrix();
      }
   }
   glDepthMask( GL_TRUE );
   glDisable( GL_BLEND );
   glDisable( GL_TEXTURE_2D );

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Fast Intersection Function between ray/plane
 */
- (BOOL) testIntersionPlane:(const Plane&)plane
        position:(const TVector&)position
        direction:(const TVector&)direction lambda:(double&)lambda
        normal:(TVector&)pNormal
{
   double DotProduct = direction.dot( plane._Normal );
   double l2;

   // determine if ray paralle to plane
   if( ( DotProduct < ZERO ) && ( DotProduct > -ZERO ) )
      return FALSE;

   l2 = ( plane._Normal.dot( plane._Position - position ) ) / DotProduct;

   if( l2 < -ZERO )
      return FALSE;

   pNormal = plane._Normal;
   lambda = l2;

   return TRUE;
}


/*
 * Fast Intersection Function between ray/cylinder
 */
- (BOOL) testIntersionCylinder:(const Cylinder&)cylinder
         position:(const TVector&)position
         direction:(const TVector&)direction lambda:(double&)lambda
         normal:(TVector&)pNormal newPosition:(TVector&)newposition
{
   TVector RC;
   double d;
   double t, s;
   TVector n, O;
   double ln;
   double in, out;


   TVector::subtract( position, cylinder._Position, RC );
   TVector::cross( direction, cylinder._Axis, n );

   ln = n.mag();

   if( ( ln < ZERO ) && ( ln > -ZERO ) )
      return FALSE;

   n.unit();

   d = fabs( RC.dot( n ) );

   if( d <= cylinder._Radius )
   {
      TVector::cross( RC, cylinder._Axis, O );
      t = -O.dot( n ) / ln;
      TVector::cross( n, cylinder._Axis, O );
      O.unit();
      s = fabs( sqrt( cylinder._Radius * cylinder._Radius - d * d ) /
                direction.dot( O ) );

      in = t - s;
      out = t + s;

      if( in < -ZERO )
      {
         if( out < -ZERO )
            return FALSE;
         else
            lambda = out;
      }
      else if( out < -ZERO )
      {
         lambda = in;
      }
      else if( in < out )
         lambda = in;
      else
         lambda = out;

      newposition = position + direction * lambda;
      TVector HB = newposition - cylinder._Position;
      pNormal = HB - cylinder._Axis * ( HB.dot( cylinder._Axis ) );
      pNormal.unit();

      return TRUE;
   }

   return FALSE;
}


/*
 * Find if any of the current balls
 * intersect with each other in the current timestep
 * Returns the index of the 2 itersecting balls, the point and time of
 * intersection
 */
- (BOOL) findBallCol:(TVector&)point timePoint:(double&)TimePoint
         time2:(double)Time2 ball1:(int&)BallNr1 ball2:(int&)BallNr2
{
   TVector RelativeV;
   TRay rays;
   double MyTime = 0.0, Add = Time2 / 150.0, Timedummy = 10000;
   TVector posi;

   // Test all balls against eachother in 150 small steps
   for( int i = 0; i < NrOfBalls - 1; i++ )
   {
      for( int j = i + 1; j < NrOfBalls; j++ )
      {
         RelativeV = ArrayVel[ i ] - ArrayVel[ j ];
         rays = TRay( OldPos[ i ], TVector::unit( RelativeV ) );
         MyTime = 0.0;

         if( ( rays.dist( OldPos[ j ] ) ) > 40 )
            continue;

         while( MyTime < Time2 )
         {
            MyTime += Add;
            posi = OldPos[ i ] + RelativeV * MyTime;
            if( posi.dist( OldPos[ j ] ) <= 40 )
            {
               point=posi;
               if( Timedummy > ( MyTime - Add ) )
                  Timedummy = MyTime - Add;
               BallNr1 = i;
               BallNr2 = j;
               break;
            }
         }
      }
   }

   if( Timedummy != 10000 )
   {
      TimePoint = Timedummy;
      return TRUE;
   }

   return FALSE;
}


- (void) decreaseCameraPos
{
   pos += TVector( 0, 0, -10 );
}


- (void) increaseCameraPos
{
   pos += TVector( 0, 0, 10 );
}


- (void) decreaseCameraRot
{
   camera_rotation -= 10;
}


- (void) increaseCameraRot
{
   camera_rotation += 10;
}


- (void) decreaseTime
{
   Time -= 0.1;
}


- (void) increaseTime
{
   Time += 0.1;
}


- (void) toggleSounds
{
   sounds = !sounds;
}


- (void) toggleHook
{
   hook_toball1 = !hook_toball1;
   camera_rotation = 0;
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
   glDeleteTextures( 4, texture );
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
