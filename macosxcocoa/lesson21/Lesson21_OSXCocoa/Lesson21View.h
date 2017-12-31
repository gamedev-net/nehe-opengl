/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson21View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

struct object
{
   int fx, fy;   // Fine movement position
   int x, y;     // Current player position
   float spin;   // Spin direction
};

@interface Lesson21View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 2 ];      // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 2 ];        // Width and height
   char *texBytes[ 2 ];        // Texture data
   BOOL vline[ 11 ][ 11 ];     // Keeps track of vertical lines
   BOOL hline[ 11 ][ 11 ];     // Keeps track of horizontal lines
   BOOL filled;                // Done filling the grid?
   BOOL gameover;              // Is the game over?
   BOOL anti;                  // Antialiasing
   int delay;                  // Enemy delay
   int adjust;                 // Speed adjust for really slow video cards
   int lives;                  // Player lives
   int level;                  // Internal game level
   int level2;                 // Displayed game level
   int stage;                  // Game stage
   struct object player;       // Player information
   struct object enemy[ 9 ];   // Enemy information
   struct object hourglass;    // Hourglass information
   GLuint texture[ 2 ];        // Font texture storage space
   GLuint base;                // Base display list for the font
   NSSound *dieSound;          // Sound made when player dies
   NSSound *completeSound;     // Sound made when level completed
   NSSound *freezeSound;       // Sound played when enemies freeze
   NSSound *hourglassSound;    // Sound when hourglass appears
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (BOOL) gameIsOver;
- (void) toggleAntialiasing;
- (void) resetGame;
- (void) updateGame;
- (void) movePlayerRight;
- (void) movePlayerLeft;
- (void) movePlayerDown;
- (void) movePlayerUp;
- (void) dealloc;

@end
