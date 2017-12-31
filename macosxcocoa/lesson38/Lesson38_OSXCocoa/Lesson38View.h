/*
 * Original Windows comment:
 * "Jeff Molofee's Lesson 38
 *     nehe.gamedev.net
 *           2002"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson38View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct object_tag             // Create A Structure Called Object
{
   int   tex;      // Integer Used To Select Our Texture
   float x;        // X Position
   float y;        // Y Position
   float z;        // Z Position
   float yi;       // Y Increase Speed (Fall Speed)
   float spinz;    // Z Axis Spin
   float spinzi;   // Z Axis Spin Speed
   float flap;     // Flapping Triangles :)
   float fi;       // Flap Direction (Increase Value)
} object;


@interface Lesson38View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 4 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 4 ];     // Width and height
   char *texBytes[ 4 ];     // Texture data
   GLuint texture[ 4 ];            // Storage For 4 Textures
   object obj[ 50 ];               // Create 50 Objects Using The Object Structure
   float tilt;                     // Butterfly Fall Angle
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) increaseTilt;
- (void) decreaseTilt;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
