/*
 * Original Windows comment:
 * "This code was created by Pet & Commented/Cleaned Up By Jeff Molofee
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson25View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct
{
   float x, y, z;
} VERTEX;

typedef struct
{
   int verts;        // Number of vertices for the object
   VERTEX *points;   // The set of VERTEX's
} OBJECT;
@interface Lesson25View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLfloat xrot, yrot, zrot;         // X, Y, and Z rotation
   GLfloat xspeed, yspeed, zspeed;   // X, Y, and Z spin speed
   GLfloat cx, cy, cz;               // X, Y, and Z position
   int key;              // Used to make sure same morph key is not pressed
   int step;             // Step counter
   int steps;            // Maximum number of steps;
   BOOL morph;           // Default morph to false (not morphing)
   int maxver;           // Will eventually hold the max number of vertices
   OBJECT morph1, morph2, morph3, morph4;   // Our 4 morphable objects
   OBJECT helper;                           // Helper object
   OBJECT *sour;                            // Source object
   OBJECT *dest;                            // Destination object
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) decreaseZSpeed;
- (void) increaseZSpeed;
- (void) decreaseXSpeed;
- (void) increaseXSpeed;
- (void) decreaseYSpeed;
- (void) increaseYSpeed;
- (void) decreaseZPos;
- (void) increaseZPos;
- (void) decreaseYPos;
- (void) increaseYPos;
- (void) decreaseXPos;
- (void) increaseXPos;
- (void) setMorphTo1;
- (void) setMorphTo2;
- (void) setMorphTo3;
- (void) setMorphTo4;
- (void) dealloc;

@end
