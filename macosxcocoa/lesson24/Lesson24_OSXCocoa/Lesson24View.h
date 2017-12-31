/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson24View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct
{
   GLubyte *imageData;   // Image data (up to 32 bits)
   GLuint bpp;           // Image color depth in bits per pixel
   GLuint width;         // Image width
   GLuint height;        // Image height
   GLuint texID;         // Texture ID used to select a texture
} TextureImage;

@interface Lesson24View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   TextureImage textures[ 1 ];   // Storage for one texture
   int scroll;      // Used for scrolling the screen
   int maxtokens;   // Keeps track of the number of extensions supported
   int swidth;      // Scissor width
   int sheight;     // Scissor height
   GLuint base;     // Base display list for the font
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) scrollUp;
- (void) scrollDown;
- (void) dealloc;

@end
