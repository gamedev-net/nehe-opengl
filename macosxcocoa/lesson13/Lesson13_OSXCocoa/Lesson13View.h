/*
 * Original Windows comment:
 * "This Code Was Created By Jeff Molofee 2000
 * Modified by Shawn T. to handle (%3.2f, num) parameters.
 * A HUGE Thanks To Fredric Echols For Cleaning Up
 * And Optimizing The Base Code, Making It More Flexible!
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson13View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface Lesson13View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   GLuint base;    // Base display list for the font set
   GLfloat cnt1;   // 1st Counter Used To Move Text & For Coloring
   GLfloat cnt2;   // 2nd Counter Used To Move Text & For Coloring
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
