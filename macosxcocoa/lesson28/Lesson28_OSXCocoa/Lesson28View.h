/*
 * Original Windows comment:
 * "This Code Was Published By Jeff Molofee 2000
 * Code Was Created By David Nikdel For NeHe Productions
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson28View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

// Structure for a 3-dimensional point
typedef struct point_3d
{
   double x, y, z;
} POINT_3D;

// Structure for a 3rd degree bezier patch
typedef struct bpatch
{
   POINT_3D anchors[ 4 ][ 4 ];   // 4x4 grid of anchor points
   GLuint   dlBPatch;            // Display List for Bezier Patch
   GLuint   texture;             // Texture for the patch
} BEZIER_PATCH;

@interface Lesson28View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 1 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 1 ];     // Width and height
   char *texBytes[ 1 ];     // Texture data
   GLfloat rotz;            // Rotation about the Z axis
   BEZIER_PATCH mybezier;   // The bezier patch we're going to use
   BOOL showCPoints;        // Toggles displaying the control point grid
   int divs;                // Number of intrapolations (conrols poly resolution)
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) rotateLeft;
- (void) rotateRight;
- (void) increaseBezierResolution;
- (void) decreaseBezierResolution;
- (void) toggleShowControlPoints;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
