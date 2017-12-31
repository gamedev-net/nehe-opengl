/*
 * Original Windows comment:
 * "This code has been created by Banu Cosmin aka Choko - 20 may 2000
 * and uses NeHe tutorials as a starting point (window initialization,
 * texture loading, GL initialization and code for keypresses) - very good
 * tutorials, Jeff. If anyone is interested about the presented algorithm
 * please e-mail me at boct@romwest.ro
 * Attention!!! This code is not for beginners."
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson27View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "3Dobject.h"

@interface Lesson27View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   glObject obj;                   // Object
   GLfloat xrot, xspeed;           // X Rotation & X Speed
   GLfloat yrot, yspeed;           // Y Rotation & Y Speed
   float lightPos[ 4 ];            // Light Position
   float objPos[ 3 ];              // Object position
   GLUquadricObj *q;               // Quadric For Drawing A Sphere
   float spherePos[ 3 ];           // Sphere position
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) decreaseYSpeed;
- (void) increaseYSpeed;
- (void) decreaseXSpeed;
- (void) increaseXSpeed;
- (void) moveLightRight;
- (void) moveLightLeft;
- (void) moveLightUp;
- (void) moveLightDown;
- (void) moveLightToViewer;
- (void) moveLightFromViewer;
- (void) moveObjectRight;
- (void) moveObjectLeft;
- (void) moveObjectUp;
- (void) moveObjectDown;
- (void) moveObjectToViewer;
- (void) moveObjectFromViewer;
- (void) moveBallRight;
- (void) moveBallLeft;
- (void) moveBallUp;
- (void) moveBallDown;
- (void) moveBallToViewer;
- (void) moveBallFromViewer;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
