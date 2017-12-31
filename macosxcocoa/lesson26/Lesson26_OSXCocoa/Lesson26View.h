/*
 * Original Windows comment:
 * "This code has been created by Banu Cosmin aka Choko - 20 may 2000
 * and uses NeHe tutorials as a starting point (window initialization,
 * texture loading, GL initialization and code for keypresses) - very good
 * tutorials, Jeff. If anyone is interested about the presented algorithm
 * please e-mail me at boct@romwest.ro
 *
 * Code commmenting and clean up by Jeff Molofee ( NeHe )
 * NeHe Productions        ...             http://nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson26View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson26View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 3 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 3 ];     // Width and height
   char *texBytes[ 3 ];     // Texture data
   GLUquadricObj *q;        // Quadric for drawing a sphere
   GLfloat xrot;            // X rotation
   GLfloat yrot;            // Y rotation
   GLfloat xrotspeed;       // X rotation speed
   GLfloat yrotspeed;       // Y rotation speed
   GLfloat zoom;            // Depth into screen
   GLfloat height;          // Height of ball from floor
   GLuint texture[ 3 ];     // 3 textures
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) decreaseYRotSpeed;
- (void) increaseYRotSpeed;
- (void) decreaseXRotSpeed;
- (void) increaseXRotSpeed;
- (void) decreaseZoom;
- (void) increaseZoom;
- (void) decreaseHeight;
- (void) increaseHeight;
- (void) dealloc;

@end
