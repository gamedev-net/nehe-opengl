/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee and GB Schmick 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit our sites at www.tiptup.com and nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson18View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson18View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 1 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 1 ];     // Width and height
   char *texBytes[ 1 ];     // Texture data
   BOOL light;         // Lighting on/off
   int part1;          // Start of disc
   int part2;          // End of disc
   int p1;             // Increase 1
   int p2;             // Increase 2
   GLfloat xrot;       // X rotation
   GLfloat yrot;       // Y rotation
   GLfloat xspeed;     // X rotation speed
   GLfloat yspeed;     // Y rotation speed
   GLfloat z;          // Depth into screen
   GLUquadricObj *quadric;   // Storage for our quadric objects
   GLuint filter;                // Which filter to use
   GLuint texture[ 3 ];          // Storage for three textures
   GLuint object;                // Which object to draw
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (void) toggleLight;
- (void) selectNextFilter;
- (void) selectNextObject;
- (void) decreaseZPos;
- (void) increaseZPos;
- (void) decreaseXSpeed;
- (void) increaseXSpeed;
- (void) decreaseYSpeed;
- (void) increaseYSpeed;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
