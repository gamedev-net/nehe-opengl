/*
 * Original Windows comment:
 * "This Code Was Created By Brett Porter For NeHe Productions 2000
 * Visit NeHe Productions At http://nehe.gamedev.net
 *
 * Visit Brett Porter's Web Page at
 * http://www.geocities.com/brettporter/programming"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson31View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "MilkshapeModel.h"

@interface Lesson31View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   Model *pModel;
   GLfloat yrot;
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
