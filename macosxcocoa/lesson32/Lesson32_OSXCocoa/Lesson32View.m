/*
 * Original Windows comment:
 * "   Jeff Molofee's Picking Tutorial   *
 *          nehe.gamedev.net             *
 *                2001                   *"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson32View.m */

#import "Lesson32View.h"
#import <Carbon/Carbon.h>

@interface Lesson32View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadTGA:(TextureImage *)texture fromFile:(char *)filename;
- (void) buildFont;
- (void) glPrintAtX:(GLint)x Y:(GLint)y string:(const char *)string, ...;
- (void) initObject:(int)num;
- (void) selection;
- (void) objectWidth:(float)width height:(float)height texture:(GLuint)texid;
- (void) explosion:(int)num;
- (void) drawTargets;
- (NSPoint) currentMousePosition;
@end

OSStatus evtMouseDown( EventHandlerCallRef evtHandlerCallRef,
                       EventRef inEvent, void *inUserData );

@implementation Lesson32View

static NSSize objSize[ 5 ] =
   {
      {  1.0f, 1.0f },   // Blueface
      {  1.0f, 1.0f },   // Bucket
      {  1.0f, 1.0f },   // Target
      {  0.5f, 1.0f },   // Coke
      { 0.75f, 1.5f }    // Vase
   };

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;
   struct EventTypeSpec evtSpec;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   // This gets mouse clicks in full screen (mouseDown: receives them in
   // windowed mode)
   evtSpec.eventClass = kEventClassMouse;
   evtSpec.eventKind = kEventMouseDown;
   InstallEventHandler( GetApplicationEventTarget(),
                        NewEventHandlerUPP( evtMouseDown ),
                        1, &evtSpec, self, NULL );

   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   level = 1;
   shotSound = [ [ NSSound alloc ] initWithContentsOfFile:[ [ [ NSBundle mainBundle ]
                                      resourcePath ] stringByAppendingFormat:@"/%s",
                                      "Shot.wav" ]
                                   byReference:YES ];
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
   int loop;

   srand( (unsigned) time( NULL ) );   // Randomize Things

   if( ( ![ self loadTGA:&textures[ 0 ] fromFile:"BlueFace.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 1 ] fromFile:"Bucket.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 2 ] fromFile:"Target.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 3 ] fromFile:"Coke.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 4 ] fromFile:"Vase.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 5 ] fromFile:"Explode.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 6 ] fromFile:"Ground.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 7 ] fromFile:"Sky.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 8 ] fromFile:"Crosshair.tga" ] ) ||
       ( ![ self loadTGA:&textures[ 9 ] fromFile:"Font.tga" ] ) )
      return FALSE;       // If Loading Failed, Return False

   [ self buildFont ];    // Build Our Font Display List

   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );   // Black Background
   glClearDepth( 1.0f );                     // Depth Buffer Setup
   glDepthFunc( GL_LEQUAL );                 // Type Of Depth Testing
   glEnable( GL_DEPTH_TEST );                // Enable Depth Testing
   // Enable Alpha Blending (disable alpha testing)
   glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
   glEnable( GL_BLEND );   // Enable Blending       (disable alpha testing)
//   glAlphaFunc( GL_GREATER, 0.1f );      // Set Alpha Testing     (disable blending)
//   glEnable( GL_ALPHA_TEST );            // Enable Alpha Testing  (disable blending)
   glEnable( GL_TEXTURE_2D );            // Enable Texture Mapping
   glEnable( GL_CULL_FACE );             // Remove Back Face

   for( loop = 0; loop < 30; loop++ )
      [ self initObject:loop ];          // Initialize Each Object

   return TRUE;
}


/*
 * Loads A TGA File Into Memory
 */
- (BOOL) loadTGA:(TextureImage *)texture fromFile:(char *)filename
{
   // Uncompressed TGA Header
   GLubyte TGAheader[ 12 ] = { 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
   GLubyte TGAcompare[ 12 ];   // Used To Compare TGA Header
   GLubyte header[ 6 ];        // First 6 Useful Bytes From The Header
   GLuint  bytesPerPixel;      // No. Of Bytes Per Pixel Used In The TGA File
   GLuint  imageSize;          // Store Image Size When Setting Aside Ram
   GLuint  temp;               // Temporary Variable
   GLuint  type = GL_RGBA;     // Set The Default GL Mode To RBGA (32 BPP)
   GLuint  i;
   FILE    *file = fopen( [ [ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    filename ] cString ], "rb" );

   /*
    * If file couldn't be opened, or doesn't have the right data (12 bytes
    * first, which we like, then another 6 for the header), then we return
    * FALSE
    */
   if( file == NULL ||
       fread( TGAcompare, 1, sizeof( TGAcompare ), file ) !=
          sizeof( TGAcompare ) ||
       memcmp( TGAheader, TGAcompare, sizeof( TGAheader ) ) != 0 ||
       fread( header, 1, sizeof( header ), file ) != sizeof( header ) )
   {
      if( file != NULL )
         fclose( file );
      return FALSE;
   }

   // Determine The TGA Width      (highbyte*256+lowbyte)
   texture->width  = header[ 1 ] * 256 + header[ 0 ];
   // Determine The TGA Height     (highbyte*256+lowbyte)
   texture->height = header[ 3 ] * 256 + header[ 2 ];

   /*
    * If the width or height is invalid, or isn't 24 or 32 bit, we take off
    */
   if( texture->width  <= 0 ||
       texture->height <= 0 ||
       ( header[ 4 ] != 24 && header[ 4 ] != 32 ) )
   {
      fclose( file );
      return FALSE;
   }

   texture->bpp    = header[ 4 ];  // Grab The TGA's Bits Per Pixel (24 or 32)
   bytesPerPixel   = texture->bpp / 8;   // Divide By 8 To Get The Bytes Per Pixel
   // Calculate The Memory Required For The TGA Data
   imageSize = texture->width * texture->height * bytesPerPixel;

   // Reserve Memory To Hold The TGA Data
   texture->imageData = (GLubyte *) malloc( imageSize );

   /*
    * If we can create the memory, or don't read in enough data, we leave
    */
   if( texture->imageData == NULL ||
       fread( texture->imageData, 1, imageSize, file ) != imageSize )
   {
      if( texture->imageData != NULL )   // Was Image Data Loaded
         free( texture->imageData );     // If So, Release The Image Data

      fclose( file );   // Close The File
      return FALSE;
   }

   /*
    * Loop through the image data; swaps the first and third bytes (red and blue)
    */
   for( i = 0; i < (int) imageSize; i += bytesPerPixel )
   {
      // Temporarily Store The Value At Image Data 'i'
      temp=texture->imageData[ i ];
      // Set The 1st Byte To The Value Of The 3rd Byte
      texture->imageData[ i ] = texture->imageData[ i + 2 ];
      // Set The 3rd Byte To The Value In 'temp' (1st Byte Value)
      texture->imageData[ i + 2 ] = temp;
   }

   fclose( file );   // Close The File

   // Build A Texture From The Data
   glGenTextures( 1, &texture[ 0 ].texID );   // Generate OpenGL texture IDs

   glBindTexture( GL_TEXTURE_2D, texture[ 0 ].texID );   // Bind Our Texture
   // Linear filtered
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

   if( texture[ 0 ].bpp == 24 )   // Was The TGA 24 Bits
      type = GL_RGB;              // If So Set The 'type' To GL_RGB

   glTexImage2D( GL_TEXTURE_2D, 0, type, texture[ 0 ].width, texture[ 0 ].height,
                 0, type, GL_UNSIGNED_BYTE, texture[ 0 ].imageData );

   return TRUE;
}


/*
 * Build our font display list
 */
- (void) buildFont
{
   int loop;

   base = glGenLists( 95 );   // Creating 95 Display Lists
   glBindTexture( GL_TEXTURE_2D, textures[ 9 ].texID );   // Bind Our Font Texture
   for( loop = 0; loop < 95; loop++ )
   {
      float cx = (float) ( loop % 16 ) / 16.0f;   // X Position Of Current Character
      float cy = (float) ( loop / 16 ) / 8.0f;    // Y Position Of Current Character

      glNewList( base + loop, GL_COMPILE );   // Start Building A List
      glBegin( GL_QUADS );                    // Use A Quad For Each Character
         glTexCoord2f( cx, 1.0f - cy - 0.120f );
         glVertex2i( 0, 0 );              // Texture / Vertex Coord (Bottom Left)
         glTexCoord2f( cx + 0.0625f, 1.0f - cy - 0.120f );
         glVertex2i( 16, 0 );             // Texutre / Vertex Coord (Bottom Right)
         glTexCoord2f( cx + 0.0625f, 1.0f - cy );
         glVertex2i( 16, 16 );            // Texture / Vertex Coord (Top Right)
         glTexCoord2f( cx, 1.0f - cy );
         glVertex2i( 0, 16 );             // Texture / Vertex Coord (Top Left)
      glEnd();                    // Done Building Our Quad (Character)
      glTranslated( 10, 0, 0 );   // Move To The Right Of The Character
      glEndList();                // Done Building The Display List
   }
}


/*
 * Resize ourself
 */
- (void) reshape
{ 
   NSRect sceneBounds;

   [ [ self openGLContext ] update ];
   sceneBounds = [ self bounds ];
   if( trackTag )
      [ self removeTrackingRect:trackTag ];
   // This sets up so we receive mouseEntered: and mouseExited:
   trackTag = [ self addTrackingRect:sceneBounds owner:self userData:nil
                assumeInside:NO ];
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   1.0f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
   NSPoint mouseLoc = [ self currentMousePosition ];
   NSRect window;

   // Clear Screen And Depth Buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glLoadIdentity();                          // Reset The Modelview Matrix
   glPushMatrix();                            // Push The Modelview Matrix

   glBindTexture( GL_TEXTURE_2D, textures[ 7 ].texID );     // Select The Sky Texture
   glBegin( GL_QUADS );                                     // Begin Drawing Quads
      glTexCoord2f( 1.0f, roll / 1.5f + 1.0f );
      glVertex3f(  28.0f,  7.0f, -50.0f );          // Top Right
      glTexCoord2f( 0.0f, roll / 1.5f + 1.0f );
      glVertex3f( -28.0f,  7.0f, -50.0f );          // Top Left
      glTexCoord2f( 0.0f, roll / 1.5f + 0.0f );
      glVertex3f( -28.0f, -3.0f, -50.0f );          // Bottom Left
      glTexCoord2f( 1.0f, roll / 1.5f + 0.0f );
      glVertex3f(  28.0f, -3.0f, -50.0f );          // Bottom Right

      glTexCoord2f( 1.5f, roll + 1.0f );
      glVertex3f(  28.0f,  7.0f, -50.0f );          // Top Right
      glTexCoord2f( 0.5f, roll + 1.0f );
      glVertex3f( -28.0f,  7.0f, -50.0f );          // Top Left
      glTexCoord2f( 0.5f, roll + 0.0f );
      glVertex3f( -28.0f, -3.0f, -50.0f );          // Bottom Left
      glTexCoord2f( 1.5f, roll + 0.0f );
      glVertex3f(  28.0f, -3.0f, -50.0f );          // Bottom Right

      glTexCoord2f( 1.0f, roll / 1.5f + 1.0f );
      glVertex3f(  28.0f, 7.0f,   0.0f );           // Top Right
      glTexCoord2f( 0.0f, roll / 1.5f + 1.0f );
      glVertex3f( -28.0f, 7.0f,   0.0f );           // Top Left
      glTexCoord2f( 0.0f, roll / 1.5f + 0.0f );
      glVertex3f( -28.0f, 7.0f, -50.0f );           // Bottom Left
      glTexCoord2f( 1.0f, roll / 1.5f + 0.0f );
      glVertex3f(  28.0f, 7.0f, -50.0f );           // Bottom Right

      glTexCoord2f( 1.5f, roll + 1.0f );
      glVertex3f(  28.0f, 7.0f,   0.0f );           // Top Right
      glTexCoord2f( 0.5f, roll + 1.0f );
      glVertex3f( -28.0f, 7.0f,   0.0f );           // Top Left
      glTexCoord2f( 0.5f, roll + 0.0f );
      glVertex3f( -28.0f, 7.0f, -50.0f );           // Bottom Left
      glTexCoord2f( 1.5f, roll + 0.0f );
      glVertex3f(  28.0f, 7.0f, -50.0f );           // Bottom Right
   glEnd();                                         // Done Drawing Quads

   glBindTexture( GL_TEXTURE_2D, textures[ 6 ].texID );   // Select The Ground Texture
   glBegin( GL_QUADS );                       // Draw A Quad
      glTexCoord2f( 7.0f, 4.0f - roll );
      glVertex3f(  27.0f, -3.0f, -50.0f );    // Top Right
      glTexCoord2f( 0.0f, 4.0f - roll );
      glVertex3f( -27.0f, -3.0f, -50.0f );    // Top Left
      glTexCoord2f( 0.0f, 0.0f - roll );
      glVertex3f( -27.0f, -3.0f,   0.0f );    // Bottom Left
      glTexCoord2f( 7.0f, 0.0f - roll );
      glVertex3f(  27.0f, -3.0f,   0.0f );    // Bottom Right
   glEnd();                                   // Done Drawing Quad

   [ self drawTargets ];                      // Draw Our Targets
   glPopMatrix();                             // Pop The Modelview Matrix

   // Crosshair (In Ortho View)
   window = [ self bounds ];
   glMatrixMode( GL_PROJECTION );             // Select The Projection Matrix
   glPushMatrix();                            // Store The Projection Matrix
   glLoadIdentity();                          // Reset The Projection Matrix
   // Set Up An Ortho Screen
   glOrtho( 0, window.size.width, 0, window.size.height, -1, 1 );
   glMatrixMode( GL_MODELVIEW );              // Select The Modelview Matrix
   // Move To The Current Mouse Position
   glTranslated( mouseLoc.x, mouseLoc.y, 0.0f );
   [ self objectWidth:16 height:16 texture:8 ];         // Draw The Crosshair

   // Game Stats / Title
   [ self glPrintAtX:240 Y:450 string:"NeHe Productions" ];           // Print Title
   [ self glPrintAtX:10  Y:10  string:"Level: %i", level ];           // Print Level
   [ self glPrintAtX:250 Y:10  string:"Score: %i", score ];           // Print Score

   if( miss > 9 )                                       // Have We Missed 10 Objects?
   {
      miss = 9;                                         // Limit Misses To 10
      gameOver = TRUE;                                  // Game Over TRUE
   }

   if( gameOver )                                        // Is Game Over?
      [ self glPrintAtX:490 Y:10 string:"GAME OVER" ];   // Game Over Message
   else                                                  // Print Morale #/10
      [ self glPrintAtX:490 Y:10 string:"Morale: %i / 10", 10 - miss ];

   glMatrixMode( GL_PROJECTION );              // Select The Projection Matrix
   glPopMatrix();                              // Restore The Old Projection Matrix
   glMatrixMode( GL_MODELVIEW );               // Select The Modelview Matrix

   [ [ self openGLContext ] flushBuffer ];
}


/*
 * Where the printing happens
 */
- (void) glPrintAtX:(GLint)x Y:(GLint)y string:(const char *)string, ...
{
   char    text[ 256 ];   // Holds Our String
   va_list ap;            // Pointer To List Of Arguments

   if( string == NULL )   // If There's No Text
      return;             // Do Nothing

   va_start( ap, string );               // Parses The String For Variables
   vsnprintf( text, 256, string, ap );   // And Converts Symbols To Actual Numbers
   va_end( ap );                         // Results Are Stored In Text

   // Select Our Font Texture
   glBindTexture( GL_TEXTURE_2D, textures[ 9 ].texID );
   glPushMatrix();                     // Store The Modelview Matrix
   glLoadIdentity();                   // Reset The Modelview Matrix
   glTranslated( x, y, 0 );            // Position The Text (0,0 - Bottom Left)
   glListBase( base - 32 );            // Choose The Font Set
   // Draws The Display List Text
   glCallLists( strlen( text ), GL_UNSIGNED_BYTE, text );
   glPopMatrix();                      // Restore The Old Projection Matrix
}


/*
 * Compare Function *** MSDN CODE MODIFIED FOR THIS TUT ***
 *
 * Cocoa note:  this is a C function, not an Objective-C method, as it needs to be
 * passed to qsort()
 */
int Compare( objects *elem1, objects *elem2 )
{
   if( elem1->distance < elem2->distance )
      return -1;   // If First Structure distance Is Less Than The Second, return -1
   else if( elem1->distance > elem2->distance )
      return 1;    // If First Structure distance Is Greater Than The Second, return 1
   else
      return 0;    // Otherwise (If The distance Is Equal), return 0
}


/*
 * Initialize an object
 */
- (void) initObject:(int)num
{
   object[ num ].rot = 1;              // Clockwise Rotation
   object[ num ].frame = 0;            // Reset The Explosion Frame To Zero
   object[ num ].hit = FALSE;          // Reset Object Has Been Hit Status To False
   object[ num ].texid = rand() % 5;   // Assign A New Texture
   // Random Distance
   object[ num ].distance = -( (float) ( rand() % 4001 ) / 100.0f );
   // Random Y Position
   object[ num ].y= -1.5f + ( (float) ( rand() % 451 ) / 100.0f );
   // Random Starting X Position Based On Distance Of Object And Random Amount For A
   // Delay (Positive Value)
   object[ num ].x = ( ( object[ num ].distance - 15.0f ) / 2.0f ) -
                     ( 5 * level ) - (float) ( rand() % ( 5 * level ) );
   object[ num ].dir = ( rand() % 2 );      // Pick A Random Direction

   if( object[ num ].dir == 0 )             // Is Random Direction Left
   {
      object[ num ].rot = 2;                // Counter Clockwise Rotation
      object[ num ].x = -object[ num ].x;   // Start On The Right Side (Negative Value)
   }

   if( object[ num ].texid == 0 )           // Blue Face
      object[ num ].y = -2.0f;              // Always Rolling On The Ground
   else if( object[ num ].texid == 1 )      // Bucket
   {
      object[ num ].dir = 3;                // Falling Down
      object[ num ].x = (float) ( rand() % (int) ( object[ num ].distance - 10.0f ) ) +
                        ( ( object[ num ].distance - 10.0f ) / 2.0f );
      object[ num ].y = 4.5f;               // Random X, Start At Top Of The Screen
   }
   else if( object[ num ].texid == 2 )      // Target
   {
      object[ num ].dir = 2;                // Start Off Flying Up
      object[ num ].x = (float) ( rand() % (int) ( object[ num ].distance - 10.0f ) ) +
                        ( ( object[ num ].distance - 10.0f ) / 2.0f );
      // Random X, Start Under Ground + Random Value
      object[ num ].y = -3.0f - (float) ( rand() % ( 5 * level ) );
   }

   /* Sort Objects By Distance:    Beginning Address Of Our object Array
    *                              *** MSDN CODE MODIFIED FOR THIS TUT ***
    *                              Number Of Elements To Sort
    *                              Size Of Each Element
    *                              Pointer To Our Compare Function
    */
   qsort( (void *) &object, level, sizeof( objects ), (compfn) Compare );
}


/*
 * This Is Where Selection Is Done
 */
- (void) selection
{
   GLuint buffer[ 512 ];   // Set Up A Selection Buffer
   GLint  hits;            // The Number Of Objects That We Selected
   // The Size Of The Viewport. [0] Is <x>, [1] Is <y>, [2] Is <length>, [3] Is <width>
   GLint   viewport[4];
   NSPoint mouseLoc = [ self currentMousePosition ];

   if( gameOver )          // Is Game Over?
      return;              // If So, Don't Bother Checking For Hits

   [ shotSound play ];     // Play Gun Shot Sound


   /*
    * This Sets The Array <viewport> To The Size And Location Of The Screen Relative
    * To The Window
    */
   glGetIntegerv( GL_VIEWPORT, viewport );
   glSelectBuffer( 512, buffer );        // Tell OpenGL To Use Our Array For Selection

   /*
    * Puts OpenGL In Selection Mode. Nothing Will Be Drawn.  Object ID's and Extents
    * Are Stored In The Buffer.
    */
   glRenderMode( GL_SELECT );

   glInitNames();     // Initializes The Name Stack
   glPushName( 0 );   // Push 0 (At Least One Entry) Onto The Stack

   glMatrixMode( GL_PROJECTION );   // Selects The Projection Matrix
   glPushMatrix();                  // Push The Projection Matrix
   glLoadIdentity();                // Resets The Matrix
   /*
    * This Creates A Matrix That Will Zoom Up To A Small Portion Of The Screen, Where
    * The Mouse Is.
    */
   gluPickMatrix( (GLdouble) mouseLoc.x, (GLdouble) mouseLoc.y,
                  1.0f, 1.0f, viewport );

   // Apply The Perspective Matrix
   gluPerspective( 45.0f, (GLfloat) ( viewport[ 2 ] - viewport[ 0 ] ) /
                   (GLfloat) ( viewport[ 3 ] - viewport[ 1 ] ), 0.1f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select The Modelview Matrix
   [ self drawTargets ];            // Render The Targets To The Selection Buffer
   glMatrixMode( GL_PROJECTION );   // Select The Projection Matrix
   glPopMatrix();                   // Pop The Projection Matrix
   glMatrixMode( GL_MODELVIEW );    // Select The Modelview Matrix
   // Switch To Render Mode, Find Out How Many Objects Were Drawn Where The Mouse Was
   hits = glRenderMode( GL_RENDER );

   if( hits > 0 )                      // If There Were More Than 0 Hits
   {
      int choose = buffer[ 3 ];   // Make Our Selection The First Object
      int depth = buffer[ 1 ];    // Store How Far Away It Is
      int loop;

      for( loop = 1; loop < hits; loop++ )   // Loop Through All The Detected Hits
      {
         // If This Object Is Closer To Us Than The One We Have Selected
         if( buffer[ loop * 4 + 1 ] < (GLuint) depth )
         {
            choose = buffer[ loop * 4 + 3 ];   // Select The Closer Object
            depth = buffer[ loop * 4 + 1 ];    // Store How Far Away It Is
         }
      }

      if( !object[ choose ].hit )       // If The Object Hasn't Already Been Hit
      {
         object[ choose ].hit = TRUE;   // Mark The Object As Being Hit
         score += 1;                    // Increase Score
         kills += 1;                    // Increase Level Kills
         if( kills > level * 5 )        // New Level Yet?
         {
            miss = 0;                   // Misses Reset Back To Zero
            kills = 0;                  // Reset Level Kills
            level += 1;                 // Increase Level
            if( level > 30 )            // Higher Than 30?
               level = 30;              // Set Level To 30 (Are You A God?)
         }
      }
   }
}


/*
 * Perform Motion Updates Here
 */
- (void) update:(long)milliseconds
{
   int loop;

   // Was a restart requested after game has ended?
   if( restartRequested && gameOver )
   {
      for( loop = 0; loop < 30; loop++ )
         [ self initObject:loop ];    // Initialize Each Object

      gameOver = FALSE;               // Set game (Game Over) To False
      score = 0;                      // Set score To 0
      level = 1;                      // Set level Back To 1
      kills = 0;                      // Zero Player Kills
      miss = 0;                       // Set miss (Missed Shots) To 0
   }
   restartRequested = FALSE;

   roll -= milliseconds * 0.00005f;   // Roll The Clouds

   for( loop = 0; loop < level; loop++ )         // Loop Through The Objects
   {
      // Spin the object in the correct direction
      if( object[ loop ].rot == 1 )                // If Rotation Is Clockwise
         object[ loop ].spin -= 0.2f * (float) ( loop + milliseconds );
      else if( object[ loop ].rot == 2 )           // If Rotation Is Counter Clockwise
         object[ loop ].spin += 0.2f * (float) ( loop + milliseconds );

      // Move the object in the correct direction
      if( object[ loop ].dir == 0 )                // If Direction Is Left
         object[ loop ].x -= 0.012f * (float) milliseconds;
      else if( object[ loop ].dir == 1 )           // If Direction Is Right
         object[ loop ].x += 0.012f * (float) milliseconds;
      else if( object[ loop ].dir == 2 )           // If Direction Is Up
         object[ loop ].y += 0.012f * (float) milliseconds;
      else if( object[ loop ].dir == 3 )           // If Direction Is Down
         object[ loop ].y -= 0.0025f * (float) milliseconds;

      // If We Are Too Far Left, Direction Is Left And The Object Was Not Hit
      if( ( object[ loop ].x < ( object[ loop ].distance - 15.0f ) / 2.0f ) &&
          ( object[ loop ].dir == 0 ) && !object[ loop ].hit )
      {
         miss += 1;                   // Increase miss (Missed Object)
         object[ loop ].hit = TRUE;   // Set hit To True To Manually Blow Up The Object
      }

      // If We Are Too Far Right, Direction Is Left And The Object Was Not Hit
      if( ( object[ loop ].x > -( object[ loop ].distance - 15.0f ) / 2.0f ) &&
          ( object[ loop ].dir == 1 ) && !object[ loop ].hit )
      {
         miss += 1;                   // Increase miss (Missed Object)
         object[ loop ].hit = TRUE;   // Set hit To True To Manually Blow Up The Object
      }

      // If We Are Too Far Down, Direction Is Down And The Object Was Not Hit
      if( ( object[ loop ].y < -2.0f ) && ( object[ loop ].dir == 3 ) &&
            !object[ loop ].hit )
      {
         miss += 1;                   // Increase miss (Missed Object)
         object[ loop ].hit = TRUE;   // Set hit To True To Manually Blow Up The Object
      }

      // If We Are Too Far Up And The Direction Is Up
      if( ( object[ loop ].y > 4.5f ) && ( object[ loop ].dir == 2 ) )
         object[ loop ].dir = 3;   // Change The Direction To Down
   }
}


/*
 * Draw Object Using Requested Width, Height And Texture
 */
- (void) objectWidth:(float)width height:(float)height texture:(GLuint)texid
{
   // Select The Correct Texture
   glBindTexture( GL_TEXTURE_2D, textures[ texid ].texID );
   glBegin( GL_QUADS );                          // Start Drawing A Quad
      glTexCoord2f( 0.0f, 0.0f );
      glVertex3f( -width, -height, 0.0f );       // Bottom Left
      glTexCoord2f( 1.0f, 0.0f );
      glVertex3f(  width, -height, 0.0f );       // Bottom Right
      glTexCoord2f( 1.0f, 1.0f );
      glVertex3f(  width,  height, 0.0f );       // Top Right
      glTexCoord2f( 0.0f, 1.0f );
      glVertex3f( -width,  height, 0.0f );       // Top Left
   glEnd();                                      // Done Drawing Quad
}


/*
 * Draws An Animated Explosion For Object "num"
 */
- (void) explosion:(int)num
{
   // Calculate Explosion X Frame (0.0f - 0.75f)
   float ex = (float) ( ( object[ num ].frame / 4 ) % 4 ) / 4.0f;
   // Calculate Explosion Y Frame (0.0f - 0.75f)
   float ey = (float) ( ( object[ num ].frame / 4 ) / 4 ) / 4.0f;

   // Select The Explosion Texture
   glBindTexture( GL_TEXTURE_2D, textures[ 5 ].texID );
   glBegin( GL_QUADS );                                    // Begin Drawing A Quad
      glTexCoord2f( ex, 1.0f - ey );
      glVertex3f( -1.0f, -1.0f, 0.0f );                    // Bottom Left
      glTexCoord2f( ex + 0.25f, 1.0f - ey );
      glVertex3f(  1.0f, -1.0f, 0.0f );                    // Bottom Right
      glTexCoord2f( ex + 0.25f, 1.0f - ( ey + 0.25f ) );
      glVertex3f(  1.0f,  1.0f, 0.0f );                    // Top Right
      glTexCoord2f( ex, 1.0f - ( ey + 0.25f ) );
      glVertex3f( -1.0f,  1.0f, 0.0f );                    // Top Left
   glEnd();                                                // Done Drawing Quad

   object[ num ].frame += 1;        // Increase Current Explosion Frame
   if( object[ num ].frame > 63 )   // Have We Gone Through All 16 Frames?
      [ self initObject:num ];      // Init The Object (Assign New Values)
}


/*
 * Draws The Targets (Needs To Be Seperate)
 */
- (void) drawTargets
{
   int loop;

   glLoadIdentity();                           // Reset The Modelview Matrix
   glTranslatef( 0.0f, 0.0f, -10.0f );         // Move Into The Screen 20 Units
   for( loop = 0; loop < level; loop++ )       // Loop Through 9 Objects
   {
      glLoadName( loop );                      // Assign Object A Name (ID)
      glPushMatrix();                          // Push The Modelview Matrix
      // Position The Object (x,y)
      glTranslatef( object[ loop ].x, object[ loop ].y, object[ loop ].distance );
      if( object[ loop ].hit )                 // If Object Has Been Hit
         [ self explosion:loop ];              // Draw An Explosion
      else
      {
         glRotatef( object[ loop ].spin, 0.0f, 0.0f, 1.0f );   // Rotate The Object
         [ self objectWidth:objSize[ object[ loop ].texid ].width
                height:objSize[ object[ loop ].texid ].height
                texture:object[ loop ].texid ];       // Draw The Object
      }
      glPopMatrix();                           // Pop The Modelview Matrix
   }
}


- (void) requestRestart
{
   restartRequested = TRUE;
}


- (void) mouseEntered:(NSEvent *)theEvent
{
   [ NSCursor hide ];
}


- (void) mouseExited:(NSEvent *)theEvent
{
   [ NSCursor unhide ];
}


/*
 * Mouse clicks in windowed mode
 */
- (void) mouseDown:(NSEvent *)theEvent
{
   [ self selection ];
}


/*
 * Mouse clicks in full screen
 */
OSStatus evtMouseDown( EventHandlerCallRef evtHandlerCallRef,
                       EventRef inEvent, void *inUserData )
{
   // This is the equivalent of [ self selection ]
   objc_msgSend( inUserData, @selector( selection ) );
   return noErr;
}


/*
 * Return the current mouse position; handles both windowed mode (using Cocoa) and
 * fullscreen (via Carbon).
 */
- (NSPoint) currentMousePosition
{
   NSPoint mouseLoc;

   if( !runningFullScreen )
      mouseLoc = [ [ self window ] convertScreenToBase:[ NSEvent mouseLocation ] ];
   else
   {
      Point carbonPoint;
      GetMouse( &carbonPoint );
      mouseLoc.x = carbonPoint.h;
      mouseLoc.y = [ self bounds ].size.height - carbonPoint.v;
   }

   return mouseLoc;
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
   glDeleteLists( base, 95 );   // Delete All 95 Font Display Lists
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
