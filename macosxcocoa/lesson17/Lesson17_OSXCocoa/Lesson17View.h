/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * and modified by Giuseppe D'Agata (waveform@tiscalinet.it)
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson17View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson17View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 2 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 2 ];     // Width and height
   char *texBytes[ 2 ];     // Texture data
   GLuint base;   // Base display list for the font
   GLuint texture[ 2 ];   // Storage for two textures
   GLfloat cnt1;   // 1st counter used to move text and for coloring
   GLfloat cnt2;   // 2nd counter used to move text and for coloring
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
