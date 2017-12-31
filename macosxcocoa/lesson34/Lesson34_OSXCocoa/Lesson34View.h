/*
 * Original Windows comment:
 * "This Code Was Created By Ben Humphrey 2001
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit NeHe Productions At http://nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson34View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#define MAP_SIZE     1024    // Size of our .raw height map
#define STEP_SIZE      16    // Width and height of each quad
#define HEIGHT_RATIO  1.5f   // Ratio that the Y is scaled according to X and Z

@interface Lesson34View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   BOOL solidPolys;   // Polygon flag
   GLubyte heightMap[ MAP_SIZE * MAP_SIZE ];   // Holds the height map data
   float scaleValue;   // Scale value for the terrain
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) toggleSolidPolys;
- (void) increaseScaleValue;
- (void) decreaseScaleValue;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
