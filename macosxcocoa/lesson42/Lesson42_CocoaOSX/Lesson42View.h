//
//  Lesson42View.h
//  Lesson42_CocoaOSX
//
//  Created by Brian Holley on Mon May 19 2003.
//  http://tachyon.unl.edu
//  bholley@unlnotes.unl.edu
//  Copyright (c) 2003. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>
#import <unistd.h>

@class Lesson42Data;

/* ---------------------------------------------------------------------------------
 * Lesson42View interface
 * The fullscreen display window and timing system
 * -------------------------------------------------------------------------------*/
@interface Lesson42View : NSOpenGLView 
{
    NSTimer * frameTimer;		// Timer to update the current frame

    int mx, my;					// General Loops (Used For Seeking)
    int width, height;			// Maze Width/Height  (Must Be A Power Of 2)
    BOOL done;					// Are we done?
    BOOL sp;					// Spacebar pressed?
    GLubyte r[4], g[4], b[4];	// Random colors (4 Red, 4 Green, 4 Blue)
    GLubyte * textureData;		// Holds Our Texture Data
    GLfloat xrot, yrot, zrot;	// Use For Rotation Of Objects
    GLUquadricObj * quadric;	// The Quadric Object
    AbsoluteTime frameTime;		// Time of last frame
}

/* initWithFrame
 * Initialize the NSWindow with a frame, creating an OpenGL context in the process.
 * This function is called when the NSWindow attached to this View is created */
- (id)initWithFrame:(NSRect) frame;

/* initGL
 * Initialize the OpenGL settings needed for this application */
- (void)initGL;

/* startTimer
 * Start the timer used to update and render each frame continuously */
- (void)startTimer;

/* reshape
 * Resize the OpenGL rendering context according to the window size.
 * This function is called when the window is resized */
- (void)reshape;

/* runFrame
 * Update and display the OpenGL scene.
 * This function is called for each frame */
- (void)runFrame;

/* updateFrame
 * Update the current frame */
- (void)updateFrame;

/* renderFrame
 * Render the current frame to the screen */
- (void)renderFrame;

/* keyDown
 * Receive keyboard input and act upon it.
 * This function is called for a keypress */
- (void)keyDown:(NSEvent *)theEvent;

/* responder functions */
- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

/* initialize
 * Initialize the maze data structures and return a pointer to the structure */
- (void)initialize;

/* deinitialize
 * Frees allocated texture memory */
- (void)deinitialize;

/* updateTexture
 * Set the given position (room) in the maze to a white pixel */
- (void)updateTex:(int)dmx :(int)dmy;

/* reset
 * Set all the values of the maze data structure to prepare for a new maze */
- (void)reset;

@end
