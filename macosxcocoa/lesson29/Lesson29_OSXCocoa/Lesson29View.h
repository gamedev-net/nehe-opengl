/*
 * Original Windows comment:
 * "The OpenGL Basecode Used In This Project Was Created By
 * Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code
 * Useful, Please Let Me Know.
 *
 * Original Code & Tutorial Text By Andreas Lšffler
 * Excellent Job Andreas!
 *
 * Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )
 * Proper Image Structure, Better Blitter Code, Misc Fixes
 * Thanks Rob!
 *
 * 0% CPU Usage While Minimized Thanks To Jim Strong
 * ( jim@scn.net ).  Thanks Jim!
 *
 * This Code Also Has The ATI Fullscreen Fix!
 *
 * Visit Me At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson29View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson29View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 2 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 2 ];     // Width and height
   char *texBytes[ 2 ];     // Texture data
   GLfloat xrot;       // X rotation
   GLfloat yrot;       // Y rotation
   GLfloat zrot;       // Z rotation
   GLuint texture[ 1 ];     // Storage for one texture
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
