/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson21View.m */

#import "Lesson21View.h"

@interface Lesson21View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) buildFont;
- (void) glPrintAtX:(GLint)x Y:(GLint)y set:(int)set
         format:(char *)fmt, ...;
- (void) resetObjects;
- (void) checkFilled;
@end

@implementation Lesson21View

// Stepping values for slow video adjust
static int steps[] = { 1, 2, 4, 5, 10, 20 };

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;
   NSString *resourcePath = [ [ NSBundle mainBundle ] resourcePath ];

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   anti = TRUE;
   adjust = 3;
   lives = 5;
   level = level2 = 1;
   stage = 1;
   dieSound = [ [ NSSound alloc ] initWithContentsOfFile:[ NSString
                                     stringWithFormat:@"%@/%s",
                                     resourcePath, "Die.wav" ]
                                  byReference:YES ];
   completeSound = [ [ NSSound alloc ] initWithContentsOfFile:[ NSString
                                          stringWithFormat:@"%@/%s",
                                          resourcePath, "Complete.wav" ]
                                       byReference:YES ];
   freezeSound = [ [ NSSound alloc ] initWithContentsOfFile:[ NSString
                                        stringWithFormat:@"%@/%s",
                                        resourcePath, "Freeze.wav" ]
                                     byReference:YES ];
   [ freezeSound setDelegate:self ];   // So we can loop it
   hourglassSound = [ [ NSSound alloc ] initWithContentsOfFile:[ NSString
                                           stringWithFormat:@"%@/%s",
                                           resourcePath, "Hourglass.wav" ]
                                        byReference:YES ];
   [ self resetObjects ];
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

   [ self buildFont ];
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   // Set line antialiasing
   glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );
   glEnable( GL_BLEND );                     // Enable blending
   // Type of blending to use
   glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
   
   return TRUE;
}


/*    
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;
   int loop;

   if( [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Font.bmp" ] intoIndex:0 ] &&
       [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Image.bmp" ] intoIndex:1 ] )
   {
      status = TRUE;

      glGenTextures( 2, &texture[ 0 ] );   // Create the textures

      for( loop = 0; loop < 2; loop++ )
      {
         glBindTexture( GL_TEXTURE_2D, texture[ loop ] );
         glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ loop ].width,
                    texSize[ loop ].height, 0, texFormat[ loop ],
                    GL_UNSIGNED_BYTE, texBytes[ loop ] );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
         glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

         free( texBytes[ loop ] );
      }
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


- (void) buildFont
{
   float cx;
   float cy;
   int loop;

   base = glGenLists( 256 );   // Create 256 display lists
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select font texture
   for( loop = 0; loop < 256; loop++ )
   {
      // X position of current character
      cx = ( (float) ( loop % 16 ) ) / 16.0f;
      // Y position of current character
      cy = ( (float) ( loop / 16 ) ) / 16.0f;
      glNewList( base + loop, GL_COMPILE );   // Start building a list
      glBegin( GL_QUADS );
      // Texture coord, bottom left
      glTexCoord2f( cx, 1.0f - cy - 0.0625f );
      glVertex2d( 0, 16 );                      // Vertex coord, bottom left

      // Texture coord, bottom right
      glTexCoord2f( cx + 0.0625f, 1 - cy - 0.0625f );
      glVertex2d( 16, 16 );                     // Vertex coord, bottom right

      glTexCoord2f( cx + 0.0625f, 1 - cy );   // Texture coord, top right
      glVertex2i( 16, 0 ) ;                   // Vertex coord, top right

      glTexCoord2f( cx, 1 - cy );             // Texture coord, top left
      glVertex2i( 0, 0 );                     // Vertex coord, top left
      glEnd();
      glTranslated( 15, 0, 0 );   // Move to the right of the character
      glEndList();
   }
}


- (void) killFont
{
   glDeleteLists( base, 256 );   // Delete all 256 display lists
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
   // Create ortho view (0,0 at top left)
   glOrtho( 0.0f, sceneBounds.size.width, sceneBounds.size.height, 0.0f,
            -1.0f, 1.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   int loop1, loop2;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );   // Select font texture
   glColor3f( 1.0f, 0.5f, 1.0f );                  // Set color to purple
   // Write GRID CRAZY to the screen
   [ self glPrintAtX:207 Y:24 set:0 format:"GRID CRAZY" ];
   glColor3f( 1.0f, 1.0f, 0.0f );                  // Set color to yellow
   // Write actual level stats
   [ self glPrintAtX:20 Y:20 set:1 format:"Level:%2i", level2 ];
   // Write stage stats
   [ self glPrintAtX:20 Y:40 set:1 format:"Stage:%2i", stage ];

   if( gameover )
   {
      // Pick a random color
      glColor3ub( rand() % 255, rand() % 255, rand() % 255 );
      [ self glPrintAtX:472 Y:20 set:1 format:"GAME OVER" ];
      [ self glPrintAtX:456 Y:40 set:1 format:"PRESS SPACE" ];
   }

   for( loop1 = 0; loop1 < lives - 1; loop1++ )
   {
      glLoadIdentity();   // Reset the view
      // Move to the right of our title text
      glTranslatef( 490 + ( (float) loop1 ) * 40.0f, 40.0f, 0.0f );
      // Rotate counterclockwise
      glRotatef( -player.spin, 0.0f, 0.0f, 1.0f );
      glColor3f( 0.0f, 1.0f, 0.0f );   // Set player color to light green
      glBegin( GL_LINES );
      glVertex2d( -5, -5 );   // Top left of player
      glVertex2d(  5,  5 );   // Bottom right of player
      glVertex2d(  5, -5 );   // Top right of player
      glVertex2d( -5,  5 );   // Bottom left of player
      glEnd();
      // Rotate counterclockwise
      glRotatef( -player.spin * 0.5f, 0.0f, 0.0, 1.0f );
      glColor3f( 0.0f, 0.75f, 0.0f );   // Set player color to dark green
      glBegin( GL_LINES );
      glVertex2d( -7,  0 );   // Left center of player
      glVertex2d(  7,  0 );   // Right center of player
      glVertex2d(  0, -7 );   // Top center of player
      glVertex2d(  0,  7 );   // Bottom center of player
      glEnd();
   }

   filled = TRUE;                 // Set filled to tru before testing
   glLineWidth( 2.0f );           // Set line width for cells to 2.0
   glDisable( GL_LINE_SMOOTH );   // Disable antialiasing
   glLoadIdentity();              // Reset the modelview matrix
   for( loop1 = 0; loop1 < 11; loop1++ )   // Left to right
   {
      for( loop2 = 0; loop2 < 11; loop2++ )   // Top to bottom
      {
         glColor3f( 0.0f, 0.5f, 1.0f );   // Set line color to blue
         if( hline[ loop1 ][ loop2 ] )    // Has the horiz line been traced
            glColor3f( 1.0f, 1.0f, 1.0f );  // If so, use white
         if( loop1 < 10 )                 // Don't draw to far right
         {
            if( !hline[ loop1 ][ loop2 ] )   // If not filled
               filled = FALSE;
            glBegin( GL_LINES );
            // Left side of horizontal line
            glVertex2d( 20 + ( loop1 * 60 ), 70 + ( loop2 * 40 ) );
            // Right side of horizontal line
            glVertex2d( 80 + ( loop1 * 60 ), 70 + ( loop2 * 40 ) );
            glEnd();
         }
         glColor3f( 0.0f, 0.5f, 1.0f );   // Set color to blue
         if( vline[ loop1 ][ loop2 ] )    // Has the vert line been traced
            glColor3f( 1.0f, 1.0f, 1.0f );   // If so, use white
         if( loop2 < 10 )                 // Don't draw too far down
         {
            if( !vline[ loop1 ][ loop2 ] )   // If not filled
               filled = FALSE;
            glBegin( GL_LINES );
            // Top of vertical line
            glVertex2d( 20 + ( loop1 * 60 ), 70 + ( loop2 * 40 ) );
            // Bottom of vertical line
            glVertex2d( 20 + ( loop1 * 60 ), 110 + ( loop2 * 40 ) );
            glEnd();
         }

         glEnable( GL_TEXTURE_2D );
         glColor3f( 1.0f, 1.0f, 1.0f );   // Bright white
         // Select the tile image
         glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );
         // If in bounds, fill in traced boxes
         if( ( loop1 < 10 ) && ( loop2 < 10 ) )
         {
            // Are all the sides of the box traced?
            if( hline[ loop1 ][ loop2 ] && hline[ loop1 ][ loop2 + 1 ] &&
                vline[ loop1 ][ loop2 ] && vline[ loop1 + 1 ][ loop2 ] )
            {
               glBegin( GL_QUADS );
               glTexCoord2f( (float) loop1 / 10.0f + 0.1f,
                             1.0f - (float) loop2 / 10.0f );
               glVertex2d( 20 + ( loop1 * 60 ) + 59,
                           ( 70 + loop2 * 40 + 1 ) );    // Top Right
               glTexCoord2f( (float) loop1 / 10.0f,
                             1.0f - (float) loop2 / 10.0f );
               glVertex2d( 20 + ( loop1 * 60 ) + 1,
                           ( 70 + loop2 * 40 + 1 ) );    // Top Left
               glTexCoord2f( (float) loop1 / 10.0f,
                             1.0f - (float) loop2 / 10.0f + 0.1f );
               glVertex2d( 20 + ( loop1 * 60 ) + 1,
                           ( 70 + loop2 * 40 ) + 39 );   // Bottom Left
               glTexCoord2f( (float) loop1 / 10.0f + 0.1f,
                             1.0f - (float) loop2 / 10.0f + 0.1f );
               glVertex2d( 20 + ( loop1 * 60 ) + 59,
                           ( 70 + loop2 * 40 ) + 39 );   // Bottom Right
               glEnd();
            }
         }
         glDisable( GL_TEXTURE_2D );
      }
   }

   glLineWidth( 1.0f );   // Set line width to 1.0

   if( anti )
      glEnable( GL_LINE_SMOOTH );   // Enable antialiasing

   if( hourglass.fx == 1 )   // Draw hourglass when fx is 1
   {
      glLoadIdentity();
      // Position the hourglass
      glTranslatef( 20.0f + ( hourglass.x * 60 ),
                    70.0f + ( hourglass.y * 40 ), 0.0f );
      glRotatef( hourglass.spin, 0.0f, 0.0f, 1.0f );   // Rotate clockwise
      // Select a random color
      glColor3ub( rand() % 255, rand() % 255, rand() % 255 );
      glBegin( GL_LINES );
      glVertex2d( -5, -5 );   // Top left of hourglass
      glVertex2d(  5,  5 );   // Bottom right of hourglass
      glVertex2d(  5, -5 );   // Top right of hourglass
      glVertex2d( -5,  5 );   // Bottom left of hourglass
      glVertex2d( -5,  5 );   // Bottom left again
      glVertex2d(  5,  5 );   // Bottom right of hourglass
      glVertex2d( -5, -5 );   // Top left of hourglass
      glVertex2d(  5, -5 );   // Top right of hourglass
      glEnd();
   }

   glLoadIdentity();
   // Move to the fine player position
   glTranslatef( player.fx + 20.0f, player.fy + 70.0f, 0.0f );
   glRotatef( player.spin, 0.0f, 0.0f, 1.0f );   // Rotate clockwise
   glColor3f( 0.0f, 1.0f, 0.0f );          // Set player color to light green
   glBegin( GL_LINES );
   glVertex2d( -5, -5 );   // Top left of player
   glVertex2d(  5,  5 );   // Bottom right of player
   glVertex2d(  5, -5 );   // Top right of player
   glVertex2d( -5,  5 );   // Bottom left of player
   glEnd();

   glRotatef( player.spin * 0.5f, 0.0f, 0.0f, 1.0f );   // Rotate clockwise
   glColor3f( 0.0f, 0.75f, 0.0f );   // Set player color to dark green
   glBegin( GL_LINES );
   glVertex2d( -7,  0 );   // Left center of player
   glVertex2d(  7,  0 );   // Right center of player
   glVertex2d(  0, -7 );   // Top center of player
   glVertex2d(  0,  7 );   // Bottom center of player
   glEnd();

   for( loop1 = 0; loop1 < ( stage * level ); loop1++ )
   {
      glLoadIdentity();
      glTranslatef( enemy[ loop1 ].fx + 20.0f, enemy[ loop1 ].fy + 70.0f,
                    0.0f );
      glColor3f( 1.0f, 0.5f, 0.5f );   // Make enemy body pink
      glBegin( GL_LINES );
      glVertex2d(  0, -7 );   // Top point of body
      glVertex2d( -7,  0 );   // Left point of body
      glVertex2d( -7,  0 );   // Left point again
      glVertex2d(  0,  7 );   // Bottom point of body
      glVertex2d(  0,  7 );   // Bottom point
      glVertex2d(  7,  0 );   // Right point of body
      glVertex2d(  7,  0 );   // Right point
      glVertex2d(  0, -7 );   // Top point of body
      glEnd();
      // Rotate the enemy blade
      glRotatef( enemy[ loop1 ].spin, 0.0f, 0.0f, 1.0f );
      glColor3f( 1.0f, 0.0f, 0.0f );   // Make enemy blade red
      glBegin( GL_LINES );
      glVertex2d( -7, -7 );   // Top left of enemy
      glVertex2d(  7,  7 );   // Bottom right of enemy
      glVertex2d( -7,  7 );   // Bottom left of enemy
      glVertex2d(  7, -7 );   // Top right of enemy
      glEnd();
   }

   [ [ self openGLContext ] flushBuffer ];
}


- (void) glPrintAtX:(GLint)x Y:(GLint)y set:(int)set
         format:(char *)fmt, ...
{
   char text[ 256 ];   // Holds our string
   va_list ap;

   if( fmt == NULL )
      return;

   va_start( ap, fmt );
   vsnprintf( text, 256, fmt, ap );
   va_end( ap );

   if( set > 1 )
      set = 1;

   glEnable( GL_TEXTURE_2D );   // Enable texture mapping
   glLoadIdentity();            // Reset modelview matrix
   glTranslated( x, y, 0 );     // Position the text
   glListBase( base - 32 + ( 128 * set ) );   // Choose the font set
   if( set == 0 )
      glScalef( 1.5f, 2.0f, 1.0f );   // Enlarge font width and height
   // Write the text to the screen
   glCallLists( strlen( text ), GL_UNSIGNED_BYTE, text );
   glDisable( GL_TEXTURE_2D );   // Disable texture mapping
}


- (void) resetObjects
{
   int loop;

   player.x = 0;    // Reset player X position to far left of the screen
   player.y = 0;    // Reset player Y position to the top of the screen
   player.fx = 0;   // Set fine X position to match
   player.fy = 0;   // Set fine Y position to match
   for( loop = 0; loop < ( stage * level ); loop++ )
   {
      enemy[ loop ].x = 5 + rand() % 6;   // Random X position (5-10)
      enemy[ loop ].y = rand() % 11;      // Random Y position (0-10)
      enemy[ loop ].fx = enemy[ loop ].x * 60;   // Set fine X to match
      enemy[ loop ].fy = enemy[ loop ].y * 40;   // Set fine Y to match
   }
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (BOOL) gameIsOver
{
   return gameover;
}


- (void) toggleAntialiasing
{
   anti = !anti;
}


- (void) resetGame
{
   gameover = FALSE;
   filled = TRUE;
   level = level2 = 1;
   stage = 0;
   lives = 5;
   [ self checkFilled ];
}


- (void) updateGame
{
   int loop1, loop2;

   if( !gameover )
   {
      for( loop1 = 0; loop1 < ( stage * level ); loop1++ )
      {
         if( ( enemy[ loop1 ].x < player.x ) &&
             ( enemy[ loop1 ].fy == enemy[ loop1 ].y * 40 ) )
            enemy[ loop1 ].x++;   // Move enemy right

         if( ( enemy[ loop1 ].x > player.x ) &&
             ( enemy[ loop1 ].fy == enemy[ loop1 ].y * 40 ) )
            enemy[ loop1 ].x--;   // Move enemy left

         if( ( enemy[ loop1 ].y < player.y ) &&
             ( enemy[ loop1 ].fx == enemy[ loop1 ].x * 60 ) )
            enemy[ loop1 ].y++;   // Move enemy down

         if( ( enemy[ loop1 ].y > player.y ) &&
             ( enemy[ loop1 ].fx == enemy[ loop1 ].x * 60 ) )
            enemy[ loop1 ].y--;   // Move enemy up

         // If our delay is done and player doesn't have hourglass
         if( delay > ( 3 - level ) && ( hourglass.fx != 2 ) )
         {
            delay = 0;   // Reset the delay counter
            for( loop2 = 0; loop2 < ( stage * level ); loop2++ )
            {
               // Is fine position on X axis lower than intended position?
               if( enemy[ loop2 ].fx < enemy[ loop2 ].x * 60 )
               {
                  // Increase fine position on X axis
                  enemy[ loop2 ].fx += steps[ adjust ];
                  // Spin enemy clockwise
                  enemy[ loop2 ].spin += steps[ adjust ];
               }
               // Is fine position on X axis higher than intended position?
               if( enemy[ loop2 ].fx > enemy[ loop2 ].x * 60 )
               {
                  // Decrease fine position on X axis
                  enemy[ loop2 ].fx -= steps[ adjust ];
                  // Spin enemy counterclockwise
                  enemy[ loop2 ].spin -= steps[ adjust ];
               }
               // Is fine position on Y axis lower than intended position?
               if( enemy[ loop2 ].fy < enemy[ loop2 ].y * 40 )
               {
                  // Increase fine position on Y axis
                  enemy[ loop2 ].fy += steps[ adjust ];
                  // Spin enemy clockwise
                  enemy[ loop2 ].spin += steps[ adjust ];
               }
               // Is fine position on Y axis higher than intended position?
               if( enemy[ loop2 ].fy > enemy[ loop2 ].y * 40 )
               {
                  // Decrease fine position on Y axis
                  enemy[ loop2 ].fy -= steps[ adjust ];
                  // Spin enemy counterclockwise
                  enemy[ loop2 ].spin -= steps[ adjust ];
               }
            }
         }
         // are any of the enemies on top of the player?
         if( ( enemy[ loop1 ].fx == player.fx ) &&
             ( enemy[ loop1 ].fy == player.fy ) )
         {
            lives--;   // Player loses a life
            if( lives == 0 )
               gameover = TRUE;
            [ self resetObjects ];   // Reset player / enemy positions
            [ dieSound play ];
         }
      }

      // Is fine position on X axis lower than intended position?
      if( player.fx < player.x * 60 )
         player.fx += steps[ adjust ];   // Increase the fine X position
      // Is fine position on X axis greater than intended position?
      if( player.fx > player.x * 60 )
         player.fx -= steps[ adjust ];   // Decrease the fine X position
      // Is fine position on Y axis lower than intended position?
      if( player.fy < player.y * 40 )
         player.fy += steps[ adjust ];   // Increase the fine Y position
      // Is fine position on Y axis greater than intended position?
      if( player.fy > player.y * 40 )
         player.fy -= steps[ adjust ];   // Decrease the fine Y position
   }

   [ self checkFilled ];

   if( ( player.fx == hourglass.x * 60 ) &&
       ( player.fy == hourglass.y * 40 ) && ( hourglass.fx == 1 ) )
   {
      [ freezeSound play ];
      hourglass.fx = 2;   // Flag that player hit the hourglass
      hourglass.fy = 0;   // Set timer for display hourglass to 0
   }

   player.spin += 0.5f * steps[ adjust ];   // Spin the player clockwise
   if( player.spin > 360.0f )
      player.spin -= 360.0f;

   // Spin the hourglass counterclockwise
   hourglass.spin -= 0.25f * steps[ adjust ];
   if( hourglass.spin < 0.0f )
      hourglass.spin += 360.0f;

   hourglass.fy += steps[ adjust ];   // Increase hourglass timer
   if( ( hourglass.fx == 0 ) && ( hourglass.fy > 6000 / level ) )
   {
      [ hourglassSound play ];
      hourglass.x = rand() % 10 + 1;   // A random X value
      hourglass.y = rand() % 11;       // A random Y value
      hourglass.fx = 1;                // Hourglass is now visible
      hourglass.fy = 0;                // Reset hourglass timer
   }

   if( ( hourglass.fx == 1 ) && ( hourglass.fy > 6000 / level ) )
   {
      hourglass.fx = 0;   // Hourglass no longer visible
      hourglass.fy = 0;   // Reset hourglass timer
   }

   if( ( hourglass.fx == 2 ) && ( hourglass.fy > 500 + ( 500 * level ) ) )
   {
      hourglass.fx = 0;   // Hourglass no longer visible
      hourglass.fy = 0;   // Reset hourglass timer
   }

   delay++;   // Increase the enemy delay counter
}


- (void) checkFilled
{
   int loop1, loop2;

   if( filled )   // Is the grid filled in?
   {
      [ completeSound play ];
      stage++;   // Increase the stage
      if( stage > 3 )
      {
         stage = 1;   // Set stage back to one
         level++;     // Increase the level
         level2++;    // Increase the displayed level
         if( level > 3 )
         {
            level = 3;   // Set the level to 3
            lives++;     // Give the player a free life
            if( lives > 5 )
               lives = 5;   // Unless they already had the max of 5
         }
      }
      [ self resetObjects ];   // Reset player / enemy positions
      for( loop1 = 0; loop1 < 11; loop1++ )
      {
         for( loop2 = 0; loop2 < 11; loop2++ )
         {
            if( loop1 < 10 )
               hline[ loop1 ][ loop2 ] = FALSE;   // Set line fill to FALSE
            if( loop2 < 10 )
               vline[ loop1 ][ loop2 ] = FALSE;   // Set line fill to FALSE
         }
      }
   }
}


- (void) movePlayerRight
{
   if( ( player.x < 10 ) && ( player.fx == player.x * 60 ) &&
       ( player.fy == player.y * 40 ) )
   {
      // Mark the current horizontal border as filled
      hline[ player.x ][ player.y ] = TRUE;
      player.x++;   // Move the player right
   }
}


- (void) movePlayerLeft
{
   if( ( player.x > 0 ) && ( player.fx == player.x * 60 ) &&
       ( player.fy == player.y * 40 ) )
   {
      player.x--;   // Move the player left
      // Mark the current horizontal border as filled
      hline[ player.x ][ player.y ] = TRUE;
   }
}


- (void) movePlayerDown
{
   if( ( player.y < 10 ) && ( player.fx == player.x * 60 ) &&
       ( player.fy == player.y * 40 ) )
   {
      // Mark the current vertical border as filled
      vline[ player.x ][ player.y ] = TRUE;
      player.y++;   // Move the player down
   }
}


- (void) movePlayerUp
{
   if( ( player.y > 0 ) && ( player.fx == player.x * 60 ) &&
       ( player.fy == player.y * 40 ) )
   {
      player.y--;   // Move the player up
      // Mark the current vertical border as filled
      vline[ player.x ][ player.y ] = TRUE;
   }
}


- (void) sound:(NSSound *)sound didFinishPlaying:(BOOL)completed
{
   // Keep playing freeze until the freeze time is over
   if( ( sound == freezeSound ) && completed && ( hourglass.fx == 2 ) )
      [ freezeSound play ];
}


/*
 * Cleanup
 */
- (void) dealloc
{
   [ self killFont ];
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
   [ dieSound release ];
   [ completeSound release ];
   [ freezeSound release ];
   [ hourglassSound release ];
}

@end
