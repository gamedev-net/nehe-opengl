//
//  Lesson42Window.m
//  Lesson42_CocoaOSX
//
//  Created by Brian Holley on Tue May 20 2003.
//  http://tachyon.unl.edu
//  bholley@unlnotes.unl.edu
//  Copyright (c) 2003. All rights reserved.
//

#import "Lesson42Window.h"

/* ---------------------------------------------------------------------------------
 * Lesson42Window implementation
 * The Cocoa window class that inherits from an NSWindow
 * -------------------------------------------------------------------------------*/
@implementation Lesson42Window

/* ---------------------------------------------------------------------------------
 * canBecomeKeyWindow
 * Allow this window to receive keypress events?  Always return that YES, we will.
 * This function is called to prepare for keypresses */
- (BOOL)canBecomeKeyWindow
{
	return YES;
}

@end
