/*
 * Original Windows comment:
 * "This code was created by Lionel Brits & Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson10View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct tagVERTEX
{
   GLfloat x, y, z;   // Vertex coordinates
   GLfloat u, v;      // Texture coordinates
} VERTEX;

typedef struct tagTRIANGLE
{
   VERTEX vertex[ 3 ];
} TRIANGLE;

@interface Lesson10View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 1 ];     // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 1 ];       // Width and height
   char *texBytes[ 1 ];       // Texture data
   int numTriangles;      // Number of triangles in the sector
   TRIANGLE *triangles;   // Pointer to triangles
   BOOL blend;            // Blending on/off
   GLfloat heading;
   GLfloat xpos;
   GLfloat zpos;
   GLfloat yrot;       // Y rotation
   GLfloat walkbias;
   GLfloat walkbiasangle;
   GLfloat lookupdown;
   GLuint filter;      // Filter
   GLuint texture[ 3 ];   // Storage for three textures
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (void) toggleBlend;
- (void) selectNextFilter;
- (void) turnRight;
- (void) turnLeft;
- (void) moveForward;
- (void) moveBackward;
- (void) lookUp;
- (void) lookDown;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
