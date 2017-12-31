/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson19View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#define MAX_PARTICLES 1000

typedef struct
{
   BOOL active;   // Particle active?
   float life;    // Particle life
   float fade;    // Fade speed
   float r;       // Red value
   float g;       // Green value
   float b;       // Blue value
   float x;       // X position
   float y;       // Y position
   float z;       // Z position
   float xi;      // X direction
   float yi;      // Y direction
   float zi;      // Z direction
   float xg;      // X gravity
   float yg;      // Y gravity
   float zg;      // Z gravity
} particles;

@interface Lesson19View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 1 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 1 ];     // Width and height
   char *texBytes[ 1 ];     // Texture data
   BOOL rainbow;     // Rainbow mode on/off
   float slowdown;   // Slow down particles
   float xspeed;     // Base X speed (to allow keyboard direction of tail)
   float yspeed;     // Base Y speed (to allow keyboard direction of tail)
   float zoom;       // Used to zoom out
   GLuint col;       // Current color selection
   GLuint delay;     // Rainbow effect delay
   GLuint texture[ 1 ];   // Storage for our particle texture
   particles particle[ MAX_PARTICLES ];   // Particle array
   BOOL doIncreaseYGravity;   // User requested to increase Y gravity
   BOOL doDecreaseYGravity;   // User requested to decrease Y gravity
   BOOL doIncreaseXGravity;   // User requested to increase X gravity
   BOOL doDecreaseXGravity;   // User requested to decrease X gravity
   BOOL doBurst;              // User requested to do burst
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) speedParticles;
- (void) slowParticles;
- (void) increaseZoom;
- (void) decreaseZoom;
- (void) toggleRainbow;
- (void) disableRainbow;
- (void) nextColor;
- (void) increaseYSpeed;
- (void) decreaseYSpeed;
- (void) increaseXSpeed;
- (void) decreaseXSpeed;
- (void) increaseYGravity;
- (void) decreaseYGravity;
- (void) increaseXGravity;
- (void) decreaseXGravity;
- (void) burst;
- (void) dealloc;

@end
