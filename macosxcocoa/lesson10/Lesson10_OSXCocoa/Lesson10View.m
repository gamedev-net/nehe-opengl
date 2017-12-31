/*
 * Original Windows comment:
 * "This code was created by Lionel Brits & Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson10View.m */

#import "Lesson10View.h"

@interface Lesson10View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) setupWorld:(NSString *)worldFile;
- (void) readFrom:(FILE *)f intoString:(char *) string;
- (void) checkBlending;
@end

@implementation Lesson10View

const float piover180 = 0.0174532925f;

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   walkbias = walkbiasangle = lookupdown = 0.0f;
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

   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glBlendFunc( GL_SRC_ALPHA, GL_ONE );      // Blend function
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glDepthFunc( GL_LESS );                   // The type of depth test to do
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   [ self setupWorld:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "World.txt" ] ];

   [ self checkBlending ];

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
                                    "Mud.bmp" ] intoIndex:0 ] )
   {
      status = TRUE;

      glGenTextures( 3, &texture[ 0 ] );   // Create three textures

      // Create Nearest Filtered Texture
      glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );

      // Create Linear Filtered Texture
      glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );

      // Create MipMapped Texture
      glBindTexture( GL_TEXTURE_2D, texture[ 2 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, 
                       GL_LINEAR_MIPMAP_NEAREST );
      gluBuild2DMipmaps( GL_TEXTURE_2D, 3, texSize[ 0 ].width,
                         texSize[ 0 ].height, texFormat[ 0 ],
                         GL_UNSIGNED_BYTE, texBytes[ 0 ] );

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


- (void) setupWorld:(NSString *)worldFile
{
   FILE *filein;
   char oneline[ 255 ];
   int triloop, vertloop;
   float x, y, z, u, v;
   
   filein = fopen( [ worldFile cString ], "rt" );
   [ self readFrom:filein intoString:oneline ];
   sscanf( oneline, "NUMPOLLIES %d\n", &numTriangles );
   triangles = calloc( numTriangles, sizeof( TRIANGLE ) );
   // Step through each triangle in sector
   for( triloop = 0; triloop < numTriangles; triloop++ )
   {
      // Step through each vertex in triangle
      for( vertloop = 0; vertloop < 3; vertloop++ )
      {
         [ self readFrom:filein intoString:oneline ];
         sscanf( oneline, "%f %f %f %f %f", &x, &y, &z, &u, &v );
         // Store values into respective vertices
         triangles[ triloop ].vertex[ vertloop ].x = x;
         triangles[ triloop ].vertex[ vertloop ].y = y;
         triangles[ triloop ].vertex[ vertloop ].z = z;
         triangles[ triloop ].vertex[ vertloop ].u = u;
         triangles[ triloop ].vertex[ vertloop ].v = v;
      }
   }
   fclose( filein );
   
   return;
}


- (void) readFrom:(FILE *)f intoString:(char *) string
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
   GLfloat x_m, y_m, z_m, u_m, v_m;      // Temporary vertices
   int loop_m, vertexNum;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();   // Reset the current modelview matrix

   // Rotate to look up/down
   glRotatef( lookupdown, 1.0f, 0.0f, 0.0f );
   // Rotate depending on direction player is facing
   glRotatef( 360.0f - yrot, 0.0f, 1.0f, 0.0f );

   glTranslatef( -xpos, -walkbias - 0.25f, -zpos );
   glBindTexture( GL_TEXTURE_2D, texture[ filter ] );

   for( loop_m = 0; loop_m < numTriangles; loop_m++ )
   {
      glBegin( GL_TRIANGLES );
      glNormal3f( 0.0f, 0.0f, 1.0f );   // Normal points forward
      for( vertexNum = 0; vertexNum < 3; vertexNum++ )
      {
         x_m = triangles[ loop_m ].vertex[ vertexNum ].x;
         y_m = triangles[ loop_m ].vertex[ vertexNum ].y;
         z_m = triangles[ loop_m ].vertex[ vertexNum ].z;
         u_m = triangles[ loop_m ].vertex[ vertexNum ].u;
         v_m = triangles[ loop_m ].vertex[ vertexNum ].v;
         glTexCoord2f( u_m, v_m ); 
         glVertex3f( x_m, y_m, z_m );
      }
      glEnd();
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


- (void) toggleBlend
{  
   blend = !blend;
   [ self checkBlending ];
}


- (void) selectNextFilter
{
   filter = ( filter + 1 ) % 3;
}


- (void) turnRight
{
   heading -= 1.0f;
   yrot = heading;
}


- (void) turnLeft
{
   heading += 1.0f;
   yrot = heading;
}


- (void) moveForward
{
   xpos -= sin( heading * piover180 ) * 0.05f;
   zpos -= cos( heading * piover180 ) * 0.05f;
   if( walkbiasangle >= 359.0f )
      walkbiasangle = 0.0f;
   else
      walkbiasangle += 10.0f;
   walkbias = sin( walkbiasangle * piover180 ) / 20.0f;
}


- (void) moveBackward
{
   xpos += sin( heading * piover180 ) * 0.05f;
   zpos += cos( heading * piover180 ) * 0.05f;
   if( walkbiasangle <= 1.0f )
      walkbiasangle = 359.0f;
   else
      walkbiasangle -= 10.0f;
   walkbias = sin( walkbiasangle * piover180 ) / 20.0f;
}


- (void) lookUp
{
   lookupdown -= 1.0f;
}


- (void) lookDown
{
   lookupdown += 1.0f;
}


- (void) checkBlending
{
   if( !blend )
   {  
      glDisable( GL_BLEND );
      glEnable( GL_DEPTH_TEST );
   }
   else
   {
      glEnable( GL_BLEND );
      glDisable( GL_DEPTH_TEST );
   }
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
