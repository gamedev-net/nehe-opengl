/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * and modified by Giuseppe D'Agata (waveform@tiscalinet.it)
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson20View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson20View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 5 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 5 ];     // Width and height
   char *texBytes[ 5 ];     // Texture data
   BOOL masking;   // Masking on/off
   BOOL scene;     // Which scene to draw
   GLfloat roll;   // Rolling texture
   GLuint texture[ 5 ];   // Storage for our five textures
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) toggleScene;
- (void) toggleMasking;
- (void) dealloc;

@end
