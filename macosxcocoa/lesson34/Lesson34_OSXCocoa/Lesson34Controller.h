/*
 * Original Windows comment:
 * "This Code Was Created By Ben Humphrey 2001
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit NeHe Productions At http://nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson34Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson34View.h"

@interface Lesson34Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson34View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
