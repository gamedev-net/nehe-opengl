/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson09View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct
{
   int r, g, b;     // Star color
   GLfloat dist;    // Star's distance from center
   GLfloat angle;   // Star's current angle
} stars;

@interface Lesson09View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 1 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 1 ];     // Width and height
   char *texBytes[ 1 ];     // Texture data
   BOOL twinkle;       // Twinkling stars
   GLfloat zoom;       // Viewing distance away from stars
   GLfloat tilt;       // Tilt the view
   GLfloat spin;       // Spin twinkling stars
   stars *starInfo;    // Info on stars
   GLuint texture[ 1 ];     // Storage for one texture
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (void) toggleTwinkle;
- (void) decreaseTilt;
- (void) increaseTilt;
- (void) decreaseZoom;
- (void) increaseZoom;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
