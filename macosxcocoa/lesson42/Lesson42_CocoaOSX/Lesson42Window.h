//
//  Lesson42Window.h
//  Lesson42_CocoaOSX
//
//  Created by Brian Holley on Tue May 20 2003.
//  http://tachyon.unl.edu
//  bholley@unlnotes.unl.edu
//  Copyright (c) 2003. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* ---------------------------------------------------------------------------------
 * Lesson42Window interface
 * The Cocoa window class that inherits from an NSWindow
 * -------------------------------------------------------------------------------*/
@interface Lesson42Window : NSWindow 

/* canBecomeKeyWindow
 * Allow this window to receive keypress events?  Always return that YES, we will.
 * This function is called to prepare for keypresses */
- (BOOL)canBecomeKeyWindow;

@end
