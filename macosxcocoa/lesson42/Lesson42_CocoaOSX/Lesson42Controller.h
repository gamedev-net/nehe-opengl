//
//  Lesson42Controller.h
//  Lesson42_CocoaOSX
//
//  Created by Brian Holley on Tue May 20 2003.
//  http://tachyon.unl.edu
//  bholley@unlnotes.unl.edu
//  Copyright (c) 2003. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Lesson42View;
@class Lesson42Window;

/* ---------------------------------------------------------------------------------
 * Lesson42Controller interface
 * The view window gui middleware class
 * -------------------------------------------------------------------------------*/
@interface Lesson42Controller : NSObject 
{
    Lesson42View * view;				// View logic class
    Lesson42Window * window;			// Viewing window
    BOOL fullscreen;					// Running fullscreen?
}

/* applicationDidFinishLaunching
 * Create the fullscreen window and begin the initialization process.
 * This function is called after the NSApplication finishes fully launching
 * the application */
- (void)applicationDidFinishLaunching:(NSNotification *)note;

/* applicationShouldTerminate
 * The application is attempting to close, should we let it? */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

/* applicationWillTerminate
 * The application is dying, free resources used before it closes */
- (void)applicationWillTerminate:(NSNotification *)note;

/* changeFullScreen
 * Flip flop fullscreen and not */
- (IBAction)changeFullScreen:(id)sender;

@end
