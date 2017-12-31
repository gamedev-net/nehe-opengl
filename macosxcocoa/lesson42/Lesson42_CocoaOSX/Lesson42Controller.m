//
//  Lesson42Controller.m
//  Lesson42_CocoaOSX
//
//  Created by Brian Holley on Tue May 20 2003.
//  http://tachyon.unl.edu
//  bholley@unlnotes.unl.edu
//  Copyright (c) 2003. All rights reserved.
//
// Fullscreen information courtesy of Katherine Tattersaul
//      http://www.zerobyzero.ca/~ktatters/tutorials/Tutorial0.html
//  

#import "Lesson42Controller.h"
#import "Lesson42View.h"
#import "Lesson42Window.h"

/* ---------------------------------------------------------------------------------
 * Lesson42Controller implementation
 * The view window gui middleware class
 * -------------------------------------------------------------------------------*/
@implementation Lesson42Controller

/* ---------------------------------------------------------------------------------
 * applicationDidFinishLaunching
 * Create the fullscreen window and begin the initialization process.
 * This function is called after the NSApplication finishes fully launching
 * the application */
- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    // Start not in fullscreen
    fullscreen = NO;
    
    NSRect windowRect = {NSMakePoint(200, 100), NSMakeSize(640, 480)};
    // Create a new bordered, normal window
    window = [[Lesson42Window alloc] initWithContentRect:windowRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    // Create a Lesson42View object the size of the screen
    view = [[Lesson42View alloc] initWithFrame:[[NSScreen mainScreen] frame]];
    
    // If we successfully created the window, set its attributes
    if (window != nil)
    {
        [window setTitle:@"Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!"];
        [window setReleasedWhenClosed:YES];
        [window setContentView:view];
        [window makeKeyAndOrderFront:view];
        [window makeFirstResponder:view];
    }
    
    // Start up OpenGL
    [view initGL];
    [view startTimer];
    
    [view release];
}

/* applicationShouldTerminate
 * The application is attempting to close, should we let it? */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    return NSTerminateNow;
}

/* applicationWillTerminate
 * The application is dying, free resources used before it closes */
- (void)applicationWillTerminate:(NSNotification *)note
{
    [view deinitialize];
}

/* changeFullScreen
 * Flip flop fullscreen and not */
- (IBAction)changeFullScreen:(id)sender
{
    // Remove the old window entirely
    [window setContentView:nil];
    [window close];
    
    if (fullscreen == NO)
    {
        // Reallocate a new window the size of the screen
        window = [[Lesson42Window alloc] initWithContentRect:[[NSScreen mainScreen] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        // Set the properties of this full screen window
        [window setTitle:@"Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!"];
        [window setReleasedWhenClosed:YES];
        [window setContentView:view];
        [window makeKeyAndOrderFront:view];
        [window setLevel:NSScreenSaverWindowLevel - 1];
        [window makeFirstResponder:view];
        fullscreen = YES;
    }
    else
    {
        NSRect windowRect = {NSMakePoint(200, 100), NSMakeSize(640, 480)};
        // Create a new bordered, normal window
        window = [[Lesson42Window alloc] initWithContentRect:windowRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
        // Set the properties of this window
        [window setTitle:@"Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!"];
        [window setReleasedWhenClosed:YES];
        [window setContentView:view];
        [window makeKeyAndOrderFront:view];
        [window makeFirstResponder:view];
        fullscreen = NO;
    }
}

@end
