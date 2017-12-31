/*
 * Original Windows comment:
 * "   Jeff Molofee's Picking Tutorial   *
 *          nehe.gamedev.net             *
 *                2001                   *"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson32View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct
{
   GLuint  rot;        // Rotation (0-None, 1-Clockwise, 2-Counter Clockwise)
   BOOL    hit;        // Object Hit?
   GLuint  frame;      // Current Explosion Frame
   GLuint  dir;        // Object Direction (0-Left, 1-Right, 2-Up, 3-Down)
   GLuint  texid;      // Object Texture ID
   GLfloat x;          // Object X Position
   GLfloat y;          // Object Y Position
   GLfloat spin;       // Object Spin
   GLfloat distance;   // Object Distance
} objects;

typedef struct
{
   GLubyte *imageData;   // Image Data (Up To 32 Bits)
   GLuint  bpp;          // Image Color Depth In Bits Per Pixel.
   GLuint  width;        // Image Width
   GLuint  height;       // Image Height
   GLuint  texID;        // Texture ID Used To Select A Texture
} TextureImage;

// Typedef For Our Compare Function
typedef int ( *compfn )( const void *, const void * );

@interface Lesson32View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLuint  base;    // Font Display List
   GLfloat roll;    // Rolling Clouds
   GLint   level;   // Current Level
   GLint   miss;    // Missed Targets
   GLint   kills;   // Level Kill Counter
   GLint   score;   // Current Score
   BOOL    gameOver;    // Game Over?
   TextureImage textures[ 10 ];   // Storage For 10 Textures
   objects object[ 30 ];          // Storage For 30 Objects
   NSSound *shotSound;
   BOOL restartRequested;
   NSTrackingRectTag trackTag;
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) update:(long)milliseconds;
- (void) requestRestart;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
