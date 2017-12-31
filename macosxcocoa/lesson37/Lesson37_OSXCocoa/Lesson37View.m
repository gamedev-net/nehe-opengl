/*
 * Original Windows comment:
 * "Sami Hamlaoui's Cel-Shading Code
 *     http://nehe.gamedev.net
 *               2001"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson37View.m */

#import "Lesson37View.h"

@interface Lesson37View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) readMesh;
- (float) dotProductOf:(VECTOR *)V1 with:(VECTOR *)V2;
- (float) magnitudeOf:(VECTOR *)V;
- (void) normalize:(VECTOR *)V;
- (void) rotateVector:(VECTOR *)V with:(MATRIX *)M into:(VECTOR *)D;
@end

#define SWAPLITTLETOHOST(x) ( (x).val = NSSwapLittleFloatToHost( (x).swap ) )

@implementation Lesson37View

static float outlineColor[ 3 ] = { 0.0f, 0.0f, 0.0f };   // Color Of The Lines

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   outlineDraw = TRUE;
   outlineSmooth = FALSE;
   outlineWidth = 3.0f;
   modelAngle = 0.0f;
   modelRotate = FALSE;
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
   int i;                         // Looping Variable
   char Line[ 255 ];              // Storage For 255 Characters
   float shaderData[ 32 ][ 3 ];   // Storate For The 96 Shader Values
   FILE *In;                      // File Pointer

   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   glClearColor( 0.7f, 0.7f, 0.7f, 0.0f );   // Light grey background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LESS )  ;                 // Type of depth test to do
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glDisable( GL_LINE_SMOOTH );              // Initially Disable Line Smoothing
   glEnable( GL_CULL_FACE );                 // Enable OpenGL Face Culling
   glDisable( GL_LIGHTING );                 // Disable OpenGL Lighting

   // Open The Shader File
   In = fopen( [ [ [ NSBundle mainBundle ] pathForResource:@"Shader"
                                           ofType:@"txt" ] UTF8String ], "r" );
   if( In )                                 // Check To See If The File Opened
   {
      for( i = 0; i < 32; i++ )             // Loop Though The 32 Greyscale Values
      {
         if( feof( In ) )                   // Check For The End Of The File
            break;
         fgets( Line, 255, In );            // Get The Current Line

         shaderData[ i ][ 0 ] = shaderData[ i ][ 1 ] = shaderData[ i ][ 2 ] =
            atof( Line );                   // Copy Over The Value
      }

      fclose( In );                         // Close The File
   }
   else
      return FALSE;                         // It Went Horribly Horribly Wrong

   glGenTextures( 1, &shaderTexture[ 0 ] );           // Get A Free Texture ID

   // Bind This Texture. From Now On It Will Be 1D
   glBindTexture( GL_TEXTURE_1D, shaderTexture[ 0 ] );

   // For Crying Out Loud Don't Let OpenGL Use Bi/Trilinear Filtering!
   glTexParameteri( GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
   glTexParameteri( GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );

   // Upload
   glTexImage1D( GL_TEXTURE_1D, 0, GL_RGB, 32, 0, GL_RGB , GL_FLOAT, shaderData );

   lightAngle.X.val = 0.0f;                     // Set The X Direction
   lightAngle.Y.val = 0.0f;                     // Set The Y Direction
   lightAngle.Z.val = 1.0f;                     // Set The Z Direction

   [ self normalize:&lightAngle ];          // Normalize The Light Direction

   return [ self readMesh ];                // Return The Value Of ReadMesh
}


/*
 * Reads The Contents Of The "model.txt" File
 */
- (BOOL) readMesh
{
   int polys, verts;
   // Open the file
   FILE *In = fopen( [ [ [ NSBundle mainBundle ] pathForResource:@"Model"
                                                 ofType:@"txt" ]
                       UTF8String ], "rb" );

   if( !In )
      return FALSE;         // Return FALSE If File Not Opened

   // Read The Header (i.e. Number Of Polygons)
   fread( &polyNum, sizeof( int ), 1, In );
   polyNum = NSSwapLittleIntToHost( polyNum );         // Swap it around for us
   polyData = calloc( polyNum, sizeof( POLYGON ) );   // Allocate the memory
   // Read In All Polygon Data
   fread( polyData, sizeof( POLYGON ) * polyNum, 1, In );
   /*
    * Since all float data was saved little endian, we need to make sure we
    * can handle it
    */
   for( polys = 0; polys < polyNum; polys++ )
   {
      for( verts = 0; verts < 3; verts++ )
      {
         SWAPLITTLETOHOST( polyData[ polys ].Verts[ verts ].Pos.X );
         SWAPLITTLETOHOST( polyData[ polys ].Verts[ verts ].Pos.Y );
         SWAPLITTLETOHOST( polyData[ polys ].Verts[ verts ].Pos.Z );
         SWAPLITTLETOHOST( polyData[ polys ].Verts[ verts ].Nor.X );
         SWAPLITTLETOHOST( polyData[ polys ].Verts[ verts ].Nor.Y );
         SWAPLITTLETOHOST( polyData[ polys ].Verts[ verts ].Nor.Z );
      }
   }
   fclose( In );                         // Close The File

   return TRUE;                          // It Worked
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
   int i, j;                                        // Looping Variables
   float TmpShade;                                  // Temporary Shader Value
   MATRIX TmpMatrix;                                // Temporary MATRIX Structure
   VECTOR TmpVector, TmpNormal;                     // Temporary VECTOR Structures

   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );     // Clear The Buffers
   glLoadIdentity();                                         // Reset The Matrix

   if( outlineSmooth )              // Check To See If We Want Anti-Aliased Lines
   {
      glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );      // Use The Good Calculations
      glEnable( GL_LINE_SMOOTH );                    // Enable Anti-Aliasing
   }
   else                             // We Don't Want Smooth Lines
      glDisable( GL_LINE_SMOOTH );                   // Disable Anti-Aliasing

   glTranslatef( 0.0f, 0.0f, -2.0f );   // Move 2 Units Away From The Screen
   glRotatef( modelAngle, 0.0f, 1.0f, 0.0f );   // Rotate The Model On It's Y-Axis

   // Get The Generated Matrix
   glGetFloatv( GL_MODELVIEW_MATRIX, TmpMatrix.Data );

   // Cel-Shading Code //
   glEnable( GL_TEXTURE_1D );                   // Enable 1D Texturing
   glBindTexture( GL_TEXTURE_1D, shaderTexture[ 0 ] );   // Bind Our Texture

   glColor3f( 1.0f, 1.0f, 1.0f );               // Set The Color Of The Model

   glBegin( GL_TRIANGLES );            // Tell OpenGL That We're Drawing Triangles
      for( i = 0; i < polyNum; i++ )            // Loop Through Each Polygon
      {
         for( j = 0; j < 3; j++ )               // Loop Through Each Vertex
         {
            /*
             * Fill Up The TmpNormal Structure With The Current Vertices' Normal
             * Values
             */
            TmpNormal.X.val = polyData[ i ].Verts[ j ].Nor.X.val;
            TmpNormal.Y.val = polyData[ i ].Verts[ j ].Nor.Y.val;
            TmpNormal.Z.val = polyData[ i ].Verts[ j ].Nor.Z.val;

            // Rotate This By The Matrix
            [ self rotateVector:&TmpNormal with:&TmpMatrix into:&TmpVector ];

            [ self normalize:&TmpVector ];            // Normalize The New Normal

            // Calculate The Shade Value
            TmpShade = [ self dotProductOf:&TmpVector with:&lightAngle ];

            if( TmpShade < 0.0f )
               TmpShade = 0.0f;               // Clamp The Value to 0 If Negative

            // Set The Texture Co-ordinate As The Shade Value
            glTexCoord1f( TmpShade );
            // Send The Vertex Position
            glVertex3fv( &polyData[ i ].Verts[ j ].Pos.X.val );
         }
      }
   glEnd();                                  // Tell OpenGL To Finish Drawing

   glDisable( GL_TEXTURE_1D );               // Disable 1D Textures

   // Outline Code //
   if( outlineDraw )               // Check To See If We Want To Draw The Outline
   {
      glEnable( GL_BLEND );                  // Enable Blending
      glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );  // Set The Blend Mode

      // Draw Backfacing Polygons As Wireframes
      glPolygonMode( GL_BACK, GL_LINE );
      glLineWidth( outlineWidth );                         // Set The Line Width

      glCullFace( GL_FRONT );             // Don't Draw Any Front-Facing Polygons
      glDepthFunc( GL_LEQUAL );           // Change The Depth Mode

      glColor3fv( &outlineColor[ 0 ] );   // Set The Outline Color

      glBegin( GL_TRIANGLES );            // Tell OpenGL What We Want To Draw
         for( i = 0; i < polyNum; i++ )   // Loop Through Each Polygon
            for( j = 0; j < 3; j++ )      // Loop Through Each Vertex
            {
               // Send The Vertex Position
               glVertex3fv( &polyData[ i ].Verts[ j ].Pos.X.val );
            }
      glEnd();                            // Tell OpenGL We've Finished

      glDepthFunc( GL_LESS );             // Reset The Depth-Testing Mode
      glCullFace( GL_BACK );              // Reset The Face To Be Culled
      // Reset Back-Facing Polygon Drawing Mode
      glPolygonMode( GL_BACK, GL_FILL );
      glDisable( GL_BLEND );              // Disable Blending
   }

   [ [ self openGLContext ] flushBuffer ];
}


/*
 *Calculate The Angle Between The 2 Vectors
 */
- (float) dotProductOf:(VECTOR *)V1 with:(VECTOR *)V2
{
   // Return The Angle
   return V1->X.val * V2->X.val + V1->Y.val * V2->Y.val + V1->Z.val * V2->Z.val;
}


/*
 * Calculate The Length Of The Vector
 */
- (float) magnitudeOf:(VECTOR *)V
{
   // Return The Length Of The Vector
   return sqrt( V->X.val * V->X.val + V->Y.val * V->Y.val + V->Z.val * V->Z.val );
}


/*
 * Creates A Vector With A Unit Length Of 1
 */
- (void) normalize:(VECTOR *)V
{
   float M = [ self magnitudeOf:V ];   // Calculate The Length Of The Vector

   if( M != 0.0f )                     // Make Sure We Don't Divide By 0
   {
      V->X.val /= M;                   // Normalize The 3 Components
      V->Y.val /= M;
      V->Z.val /= M;
   }
}


/*
 * Rotate A Vector Using The Supplied Matrix
 */
- (void) rotateVector:(VECTOR *)V with:(MATRIX *)M into:(VECTOR *)D
{
   D->X.val = ( M->Data[ 0 ] * V->X.val ) + ( M->Data[ 4 ] * V->Y.val ) +
              ( M->Data[ 8 ] * V->Z.val );    // Rotate Around The X Axis
   D->Y.val = ( M->Data[ 1 ] * V->X.val ) + ( M->Data[ 5 ] * V->Y.val ) +
              ( M->Data[ 9 ] * V->Z.val );    // Rotate Around The Y Axis
   D->Z.val = ( M->Data[ 2 ] * V->X.val ) + ( M->Data[ 6 ] * V->Y.val ) +
              ( M->Data[ 10 ] * V->Z.val );   // Rotate Around The Z Axis
}


/*
 * Perform Motion Updates Here
 */
- (void) update:(long)milliseconds
{
   if( modelRotate )                   // Check To See If Rotation Is Enabled
      modelAngle += (float) milliseconds / 10.0f;
         // Update Angle Based On The Clock
}


- (void) toggleModelRotate
{
   modelRotate = !modelRotate;                  // Toggle Model Rotation On/Off
}


- (void) toggleOutlineDraw
{
   outlineDraw = !outlineDraw;                  // Toggle Outline Drawing On/Off
}


- (void) toggleOutlineSmooth
{
   outlineSmooth = !outlineSmooth;              // Toggle Anti-Aliasing On/Off
}


- (void) increaseLineWidth
{
   outlineWidth++;                              // Increase Line Width
}


- (void) decreaseLineWidth
{
   if( outlineWidth > 1 )
      outlineWidth--;                           // Decrease Line Width
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
   glDeleteTextures( 1, &shaderTexture[ 0 ] );      // Delete The Shader Texture
   free( polyData );                                // Free the polygon data

   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
