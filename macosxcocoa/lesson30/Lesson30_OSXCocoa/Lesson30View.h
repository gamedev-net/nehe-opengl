/*
 * Original Windows comment:
 * "Programmer: Dimitrios Christopoulos
 *
 * Windows Frame Code Was Published By Jeff Molofee 2000
 * Code Was Created By David Nikdel For NeHe Productions
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson30View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "Tvector.h"
#import "Tmatrix.h"
#import "Tray.h"
#import "Image.h"

// Plane structure
struct Plane
{
   TVector _Position;
   TVector _Normal;
};

// Cylinder structure
struct Cylinder
{
   TVector _Position;
   TVector _Axis;
   double _Radius;
};

// Explosion structure
struct Explosion
{
   TVector _Position;
   float   _Alpha;
   float   _Scale;
};

@interface Lesson30View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   NSSound *explodeSound;
   float camera_rotation;
   TVector ArrayVel[ 10 ];      // holds velocity of balls
   TVector ArrayPos[ 10 ];      // position of balls
   TVector OldPos[ 10 ];        // old position of balls
   int NrOfBalls;               // sets the number of balls
   double Time;                 // timestep of simulation
   BOOL hook_toball1, sounds;   // hook camera on ball, and sound on/off
   Plane pl1, pl2, pl3, pl4, pl5;   // the 5 planes of the room
   Cylinder cyl1, cyl2, cyl3;       // the 2 cylinders of the room
   // Quadratic object to render the cylinders
   GLUquadricObj *cylinder_obj;
   // stores texture objects and display list
   GLuint texture[ 4 ], dlist;      
   Explosion ExplosionArray[ 20 ];   // holds max 20 explosions at once
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) advanceSimulation;
- (void) drawRect:(NSRect)rect;
- (void) decreaseCameraPos;
- (void) increaseCameraPos;
- (void) decreaseCameraRot;
- (void) increaseCameraRot;
- (void) decreaseTime;
- (void) increaseTime;
- (void) toggleSounds;
- (void) toggleHook;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
