/*
 * Original Windows comment:
 * "This Code Was Published By Jeff Molofee 2000
 * Code Was Created By David Nikdel For NeHe Productions
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson28View.m */

#import "Lesson28View.h"

@interface Lesson28View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) initBezier;
- (GLuint) genBezier:(BEZIER_PATCH)patch divisions:(int)divs;
- (POINT_3D) makePointX:(double)a Y:(double)b Z:(double)c;
- (POINT_3D) bernstein:(float)u points:(POINT_3D *)p;
- (POINT_3D) addPoint:(POINT_3D)p to:(POINT_3D)q;
- (POINT_3D) multPoint:(POINT_3D)p by:(double)c;
@end

@implementation Lesson28View

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   rotz = 0;
   showCPoints = TRUE;
   divs = 7;
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
   [ self initBezier ];
   mybezier.dlBPatch = [ self genBezier:mybezier divisions:divs ];

   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.05f, 0.05f, 0.05f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   
   return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;

   if( [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "NeHe.bmp" ] intoIndex:0 ] )
   {
      status = TRUE;

      glGenTextures( 1, &mybezier.texture );   // Create the texture

      // Typical texture generation using data from the bitmap
      glBindTexture( GL_TEXTURE_2D, mybezier.texture );

      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );
      // Linear filtering
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

      free( texBytes[ 0 ] );
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


- (void) initBezier
{
   // Set the bezier vertices
   mybezier.anchors[ 0 ][ 0 ] = [ self makePointX:-0.75 Y:-0.75 Z: -0.5 ];
   mybezier.anchors[ 0 ][ 1 ] = [ self makePointX:-0.25 Y:-0.75 Z:  0.0 ];
   mybezier.anchors[ 0 ][ 2 ] = [ self makePointX: 0.25 Y:-0.75 Z:  0.0 ];
   mybezier.anchors[ 0 ][ 3 ] = [ self makePointX: 0.75 Y:-0.75 Z: -0.5 ];
   mybezier.anchors[ 1 ][ 0 ] = [ self makePointX:-0.75 Y:-0.25 Z:-0.75 ];
   mybezier.anchors[ 1 ][ 1 ] = [ self makePointX:-0.25 Y:-0.25 Z:  0.5 ];
   mybezier.anchors[ 1 ][ 2 ] = [ self makePointX: 0.25 Y:-0.25 Z:  0.5 ];
   mybezier.anchors[ 1 ][ 3 ] = [ self makePointX: 0.75 Y:-0.25 Z:-0.75 ];
   mybezier.anchors[ 2 ][ 0 ] = [ self makePointX:-0.75 Y: 0.25 Z:  0.0 ];
   mybezier.anchors[ 2 ][ 1 ] = [ self makePointX:-0.25 Y: 0.25 Z: -0.5 ];
   mybezier.anchors[ 2 ][ 2 ] = [ self makePointX: 0.25 Y: 0.25 Z: -0.5 ];
   mybezier.anchors[ 2 ][ 3 ] = [ self makePointX: 0.75 Y: 0.25 Z:  0.0 ];
   mybezier.anchors[ 3 ][ 0 ] = [ self makePointX:-0.75 Y: 0.75 Z: -0.5 ];
   mybezier.anchors[ 3 ][ 1 ] = [ self makePointX:-0.25 Y: 0.75 Z: -1.0 ];
   mybezier.anchors[ 3 ][ 2 ] = [ self makePointX: 0.25 Y: 0.75 Z:- 1.0 ];
   mybezier.anchors[ 3 ][ 3 ] = [ self makePointX: 0.75 Y: 0.75 Z: -0.5 ];
   mybezier.dlBPatch = NULL;
}


/*
 * Generates a display list based on the data in the patch
 * and the number of divisions
 */
- (GLuint) genBezier:(BEZIER_PATCH)patch divisions:(int)newDivs
{
   int      u = 0, v;
   float    py, px, pyold;
   GLuint   drawlist = glGenLists( 1 );               // make the display list
   POINT_3D temp[ 4 ];
   // array of points to mark the first line of polys
   POINT_3D *last = (POINT_3D*) malloc( sizeof( POINT_3D ) * ( newDivs + 1 ) );

   if( patch.dlBPatch != NULL )   // get rid of any old display lists
      glDeleteLists( patch.dlBPatch, 1 );

   temp[ 0 ] = patch.anchors[ 0 ][ 3 ];   // the first derived curve (along x axis)
   temp[ 1 ] = patch.anchors[ 1 ][ 3 ];
   temp[ 2 ] = patch.anchors[ 2 ][ 3 ];
   temp[ 3 ] = patch.anchors[ 3 ][ 3 ];

   // create the first line of points
   for( v = 0; v <= newDivs; v++ )
   {
      px = ( (float) v ) / ( (float) newDivs );   // percent along y axis
      // use the 4 points from the derives curve to calculate the points along that
      // curve
      last[ v ] = [ self bernstein:px points:temp ];
   }

   glNewList( drawlist, GL_COMPILE );               // Start a new display list
   glBindTexture( GL_TEXTURE_2D, patch.texture );   // Bind the texture
   for( u = 1; u <= newDivs; u++ )
   {
      py    = ( (float) u ) / ( (float) newDivs );          // Percent along Y axis
      pyold = ( (float) u - 1.0f ) / ( (float) newDivs );   // Percent along old Y axis

      // Calculate new bezier points
      temp[ 0 ] = [ self bernstein:py points:patch.anchors[ 0 ] ];
      temp[ 1 ] = [ self bernstein:py points:patch.anchors[ 1 ] ];
      temp[ 2 ] = [ self bernstein:py points:patch.anchors[ 2 ] ];
      temp[ 3 ] = [ self bernstein:py points:patch.anchors[ 3 ] ];

      glBegin( GL_TRIANGLE_STRIP );   // Begin a new triangle strip

      for( v = 0; v <= divs; v++)
      {
         px = ( (float) v ) / ( (float) newDivs );   // Percent along the X axis

         glTexCoord2f( pyold, px );               // Apply the old texture coords
         glVertex3d( last[ v ].x, last[ v ].y, last[ v ].z );   // Old Point

         last[ v ] = [ self bernstein:px points:temp ];   // Generate new point
         glTexCoord2f( py, px );                        // Apply the new texture coords
         glVertex3d( last[ v ].x, last[ v ].y, last[ v ].z );   // New Point
      }

      glEnd();   // END the triangle srip
   }

   glEndList();   // END the list

   free( last );   // Free the old vertices array

   return drawlist;   // Return the display list
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
   int i, j;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix

   glTranslatef( 0.0f, 0.0f, -4.0f );       // Move into screen 4 units
   glRotatef( -75.0f, 1.0f, 0.0f, 0.0f );
   glRotatef( rotz, 0.0f, 0.0f, 1.0f );     // Rotate The Triangle On The Z axis

   glCallList( mybezier.dlBPatch );   // Call the Bezier's display list

   // this need only be updated when the patch changes
   if( showCPoints )   // If drawing the grid is toggled on
   {
      glDisable( GL_TEXTURE_2D );
      glColor3f( 1.0f, 0.0f, 0.0f );
      // draw the horizontal lines
      for( i = 0; i < 4; i++ )
      {
         glBegin( GL_LINE_STRIP );
         for( j = 0; j < 4; j++ )
            glVertex3d( mybezier.anchors[ i ][ j ].x, mybezier.anchors[ i ][ j ].y,
                        mybezier.anchors[ i ][ j ].z );
         glEnd();
      }

      // draw the vertical lines
      for( i = 0; i < 4; i++ )
      {
         glBegin( GL_LINE_STRIP );
         for( j = 0; j < 4; j++ )
            glVertex3d( mybezier.anchors[ j ][ i ].x, mybezier.anchors[ j ][ i ].y,
                        mybezier.anchors[ j ][ i ].z );
         glEnd();
      }
      glColor3f( 1.0f, 1.0f, 1.0f );
      glEnable(GL_TEXTURE_2D);
   }

   [ [ self openGLContext ] flushBuffer ];

}


/*
 * Function for quick point creation
 */
- (POINT_3D) makePointX:(double)a Y:(double)b Z:(double)c
{
   POINT_3D p;

   p.x = a;
   p.y = b;
   p.z = c;

   return p;
}


/*
 * Calculates 3rd degree polynomial based on array of 4 points
 * and a single variable (u) which is generally between 0 and 1
 */
- (POINT_3D) bernstein:(float)u points:(POINT_3D *)p
{
   POINT_3D        a, b, c, d, r;

   a = [ self multPoint:p[ 0 ] by:pow( u, 3 ) ];
   b = [ self multPoint:p[ 1 ] by:3 * pow( u, 2 ) * ( 1 - u ) ];
   c = [ self multPoint:p[ 2 ] by:3 * u * pow( 1 - u, 2 ) ];
   d = [ self multPoint:p[ 3 ] by:pow( 1 - u, 3 ) ];

   r = [ self addPoint:[ self addPoint:a to:b ] to:[ self addPoint:c to:d ] ];

   return r;
}


/*
 * Adds 2 points. Don't just use '+' ;)
 */
- (POINT_3D) addPoint:(POINT_3D)p to:(POINT_3D)q
{
   p.x += q.x;
   p.y += q.y;
   p.z += q.z;

   return p;
}

/*
 * Multiplies a point and a constant. Don't just use '*'
 */
- (POINT_3D) multPoint:(POINT_3D)p by:(double)c
{
   p.x *= c;
   p.y *= c;
   p.z *= c;

   return p;
}


- (void) rotateLeft
{
   rotz -= 0.8f;
}


- (void) rotateRight
{
   rotz += 0.8f;
}


- (void) increaseBezierResolution
{
   divs++;
   mybezier.dlBPatch = [ self genBezier:mybezier divisions:divs ];
}


- (void) decreaseBezierResolution
{
   if( divs > 1 )
   {
      divs--;
      mybezier.dlBPatch = [ self genBezier:mybezier divisions:divs ];
   }
}


- (void) toggleShowControlPoints
{
   showCPoints = !showCPoints;
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
