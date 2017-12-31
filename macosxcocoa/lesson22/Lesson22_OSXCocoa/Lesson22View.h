/*
 * Original Windows comment:
 * "This code was created by Jens Schneider (WizardSoft) 2000
 * Lesson22 to the series of OpenGL tutorials by NeHe-Production
 *
 * This code is loosely based upon Lesson06 by Jeff Molofee.
 *
 * contact me at: schneide@pool.informatik.rwth-aachen.de
 *
 * Basecode was created by Jeff Molofee 2000 
 * If you've found this code useful, please let me know. 
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson2View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/glext.h>

// Maximum emboss-translate; increase to get higher immersion
#define MAX_EMBOSS (GLfloat) 0.008f;

#define __ARB_ENABLE TRUE   // Used to disable ARB extensions entirely
//#define EXT_INFO         // Uncomment to see your extensions at startup

@interface Lesson22View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLenum texFormat[ 6 ];   // Format of texture (GL_RGB, GL_RGBA)
   NSSize texSize[ 6 ];     // Width and height
   char *texBytes[ 6 ];     // Texture data
   GLfloat xrot;       // X rotation
   GLfloat yrot;       // Y rotation
   GLfloat xspeed;     // X rotation speed
   GLfloat yspeed;     // Y rotation speed
   GLfloat z;          // Depth into screen
   GLuint texture[ 3 ];          // Storage for one texture
   BOOL emboss;                  // Emboss only, no base texture?
   BOOL bumps;                   // Do bumpmapping?
   BOOL multitextureSupported;   // Whether multitexturing is supported
   BOOL useMultitexture;         // Use it if it is supported
   GLint maxTexelUnits;          // Number of texel-pipelines; at least 1
   GLuint filter;                // Which filter to use
   GLuint bump[ 3 ];             // Our bumpmappings
   GLuint invbump[ 3 ];          // Inverted bumpmaps
   GLuint glLogo;                // Handle for OpenGL logo
   GLuint multiLogo;             // Handle for multitexture-enabled logo
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) toggleEmboss;
- (void) toggleMultitexture;
- (void) toggleBumps;
- (void) selectNextFilter;
- (void) decreaseZ;
- (void) increaseZ;
- (void) decreaseXSpeed;
- (void) increaseXSpeed;
- (void) decreaseYSpeed;
- (void) increaseYSpeed;
- (void) dealloc;

@end
