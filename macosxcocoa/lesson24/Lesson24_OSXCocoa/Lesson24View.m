/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson24View.m */

#import "Lesson24View.h"

@interface Lesson24View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadTGAInto:(TextureImage *)texture fromFile:(const char *)filename;
- (void) buildFont;
- (void) glPrintAtX:(GLint)x Y:(GLint)y set:(int)set
         format:(const char *)fmt, ...;
@end

@implementation Lesson24View

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
   if( ![ self loadTGAInto:&textures[ 0 ]
               fromFile:[ [ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Font.tga" ] cString ] ] )
      return FALSE;

   [ self buildFont ];
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   // Select our font texture
   glBindTexture( GL_TEXTURE_2D, textures[ 0 ].texID );
   
   return TRUE;
}


/*
 * Loads a TGA file into memory
 */
- (BOOL) loadTGAInto:(TextureImage *)texture fromFile:(const char *)filename
{
   // Uncompressed TGA header
   GLubyte TGAheader[ 12 ] = { 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
   GLubyte TGAcompare[ 12 ];   // Used to compare TGA header
   GLubyte header[ 6 ];        // First 6 useful bytes from the header
   // Holds number of bytes per pixel used in the TGA file
   GLuint bytesPerPixel;
   // Used to store the image size when setting aside RAM
   GLuint imageSize;
   GLuint temp;
   GLuint type = GL_RGBA;      // Set the default GL mode to RGBA (32 bpp)
   GLuint i;
   FILE *file = fopen( filename, "rb" );   // Open the TGA file

   // Check if the file successfully opened, we can read its header, its
   // header matches what we want, and we can read the following 6 bytes
   if( file == NULL ||
       fread( TGAcompare, 1, sizeof( TGAcompare ), file ) !=
          sizeof( TGAcompare ) ||
       memcmp( TGAheader, TGAcompare, sizeof( TGAheader ) ) != 0 ||
       fread( header, 1, sizeof( header ), file ) != sizeof( header ) )
   {
      if( file != NULL )   // Close only if it successfully opened
         fclose( file );
      return FALSE;
   }

   // Determine the TGA width (highbyte * 256 + lowbyte)
   texture->width = header[ 1 ] * 256 + header[ 0 ];
   // Determine the TGA height (highbyte * 256 + lowbyte)
   texture->height = header[ 3 ] * 256 + header[ 2 ];

   // Make sure width and height are good, and TGA is 24 or 32 bit
   if( texture->width <= 0 || texture->height <= 0 ||
       ( header[ 4 ] != 24 && header[ 4 ] != 32 ) )
   {
      fclose( file );
      return FALSE;
   }

   texture->bpp = header[ 4 ];   // Grab the TGA's bits per pixel (24 or 32)
   bytesPerPixel = texture->bpp / 8;   // 8 bits in a byte...
   // Calculate the memory required for the TGA data
   imageSize = texture->width * texture->height * bytesPerPixel;

   // Reserve memory to hold the TGA data
   texture->imageData = (GLubyte *) malloc( imageSize );
   // If we failed to allocate or can't read the full amount of data
   if( texture->imageData == NULL ||
       fread( texture->imageData, 1, imageSize, file ) != imageSize )
   {
      if( texture->imageData != NULL )
         free( texture->imageData );
      fclose( file );
      return FALSE;
   }

   for( i = 0; i < imageSize; i += bytesPerPixel )
   {
      temp = texture->imageData[ i ];  // Temporarily store the value at i
      // Set the first byte to the value of the third byte
      texture->imageData[ i ] = texture->imageData[ i + 2 ];
      // Set the third byte to the value in temp (first byte value)
      texture->imageData[ i + 2 ] = temp;
   }

   fclose( file );

   glGenTextures( 1, &texture->texID );   // Generate OpenGL texture ID

   glBindTexture( GL_TEXTURE_2D, texture->texID );   // Bind our texture
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
   if( texture->bpp == 24 )
      type = GL_RGB;

   glTexImage2D( GL_TEXTURE_2D, 0, type, texture->width, texture->height,
                 0, type, GL_UNSIGNED_BYTE, texture->imageData );

   return TRUE;
}


- (void) buildFont
{
   float cx;
   float cy;
   int loop;

   base = glGenLists( 256 );   // Create 256 display lists
   // Select font texture
   glBindTexture( GL_TEXTURE_2D, textures[ 0 ].texID );
   for( loop = 0; loop < 256; loop++ )
   {
      // X position of current character
      cx = ( (float) ( loop % 16 ) ) / 16.0f;
      // Y position of current character
      cy = ( (float) ( loop / 16 ) ) / 16.0f;
      glNewList( base + loop, GL_COMPILE );   // Start building a list
      glBegin( GL_QUADS );
      glTexCoord2f( cx, 1 - cy - 0.0625f );   // Texture coord, bottom left
      glVertex2i( 0, 16 );                    // Vertex coord, bottom left

      // Texture coord, bottom right
      glTexCoord2f( cx + 0.0625f, 1 - cy - 0.0625f );
      glVertex2i( 16, 16 );                   // Vertex coord, bottom right

      // Texture coord, top right
      glTexCoord2f( cx + 0.0625f, 1 - cy - 0.001f );
      glVertex2i( 16, 0 );                    // Vertex coord, top right

      glTexCoord2f( cx, 1 - cy - 0.001f );    // Texture coord, top left
      glVertex2i( 0, 0 );                     // Vertex coord, top left
      glEnd();
      glTranslated( 14, 0, 0 );   // Move to the right of the character
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
   swidth = sceneBounds.size.width;
   sheight = sceneBounds.size.height;
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Create ortho 640x480 view (0,0 at top left)
   glOrtho( 0.0f, 640, 480, 0.0f, -1.0f, 1.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   char *text;
   char *token;
   int cnt = 0;

   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

   glColor3f( 1.0f, 0.5f, 0.5f );   // Set color to bright red
   [ self glPrintAtX:50 Y:16 set:1 format:"Renderer" ];   // Display Renderer
   [ self glPrintAtX:80 Y:48 set:1 format:"Vendor" ];     // Display Vendor
   [ self glPrintAtX:66 Y:80 set:1 format:"Version" ];    // Display Version

   glColor3f( 1.0f, 0.7f, 0.4f );   // SEt color to orange
   [ self glPrintAtX:200 Y:16 set:1 format:glGetString( GL_RENDERER ) ];
   [ self glPrintAtX:200 Y:48 set:1 format:glGetString( GL_VENDOR ) ];
   [ self glPrintAtX:200 Y:80 set:1 format:glGetString( GL_VERSION ) ];

   glColor3f( 0.5f, 0.5f, 1.0f );   // Set color to bright blue
   [ self glPrintAtX:192 Y:432 set:1 format:"NeHe Productions" ];

   glLoadIdentity();   // Reset the current modelview matrix

   glColor3f( 1.0f, 1.0f, 1.0f );   // Set color to white
   glBegin( GL_LINE_STRIP );        // Start drawing line strips
   glVertex2d( 639, 417 );          // Top right of bottom box
   glVertex2d(   0, 417 );          // Top left of bottom box
   glVertex2d(   0, 480 );          // Lower left of bottom box
   glVertex2d( 639, 480 );          // Lower right of bottom box
   glVertex2d( 639, 128 );          // Up to bottom right of top box
   glEnd();                         // Done first line strip
   glBegin( GL_LINE_STRIP );        // Start drawing another line strip
   glVertex2d(   0, 128 );          // Bottom left of top box
   glVertex2d( 639, 128 );          // Bottom right of top box
   glVertex2d( 639,   1 );          // Top right of top box
   glVertex2d(   0,   1 );          // Top left of top box
   glVertex2d(   0, 417 );          // Down to top left of bottom box
   glEnd();                         // Done second line strip

   // Define scissor region
   glScissor( 1, (int) ( 0.135416f * sheight ), swidth - 2,
              (int) ( 0.597916f * sheight ) );
   glEnable( GL_SCISSOR_TEST );   // Enable scissor testing

   // Allocate memory for our extension string
   text = malloc( strlen( glGetString( GL_EXTENSIONS ) ) + 1 );
   // Grab the extension list, store in text
   strcpy( text, glGetString( GL_EXTENSIONS ) );

   // Parse 'text' for words, separated by spaces
   token = strtok( text, " " );
   while( token != NULL )
   {
      cnt++;
      if( cnt > maxtokens )
         maxtokens = cnt;
      glColor3f( 0.5f, 1.0f, 0.5f );   // Set color to bright green
      // Print current extension number
      [ self glPrintAtX:0 Y:96 + ( cnt * 32 ) - scroll set:0
             format:"%i", cnt ];
      glColor3f( 1.0f, 1.0f, 0.5f );   // Set color to yellow
      // Print the current token (parsed extension name)
      [ self glPrintAtX:50 Y:96 + ( cnt * 32 ) - scroll set:0
             format:token ];
      token = strtok( NULL, " " );   // Search for the next token
   }

   glDisable( GL_SCISSOR_TEST );   // Disable scissor testing
   free( text );
   glFlush();   // Flush the rendering pipeline

   [ [ self openGLContext ] flushBuffer ];
}


- (void) glPrintAtX:(GLint)x Y:(GLint)y set:(int)set
         format:(const char *)fmt, ...
{
   char text[ 1024 ];
   va_list ap;

   if( fmt == NULL )
      return;

   va_start( ap, fmt );
   vsnprintf( text, 1024, fmt, ap );
   va_end( ap );

   if( set > 1 )
      set = 1;

   glEnable( GL_TEXTURE_2D );    // Enable texture mapping
   glLoadIdentity();
   glTranslated( x, y, 0 );     // Position the text (0,0 - top left)
   glListBase( base - 32 + ( 128 * set ) );   // Choose the font set
   glScalef( 1.0f, 2.0f, 1.0f );              // Make text 2X taller
   // Write the text to the screen
   glCallLists( strlen( text ), GL_UNSIGNED_BYTE, text );
   glDisable( GL_TEXTURE_2D );   // Disable texture mapping
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) scrollUp
{
   if( scroll > 0 )
      scroll -= 2;
}


- (void) scrollDown
{
   if( scroll < 32 * ( maxtokens - 9 ) )
      scroll += 2;
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
}

@end
