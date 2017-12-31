/*
 * Original Windows comment:
 * "Radial Blur & Rendering To A Texture
 * How To Create A Radial Blur Effect
 * Dario Corno (rIo) / Jeff Molofee (NeHe)
 * http://www.spinningkids.org/rio
 * http://nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson36View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson36View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   NSSize viewSize;            // Size of view
   float angle;                // Used to rotate the helix
   GLuint blurTexture;         // The texture
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) update:(long)milliseconds;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
