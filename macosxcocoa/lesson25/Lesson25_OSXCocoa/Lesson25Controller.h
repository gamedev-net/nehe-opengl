/*
 * Original Windows comment:
 * "This code was created by Pet & Commented/Cleaned Up By Jeff Molofee
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson25Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson25View.h"

@interface Lesson25Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson25View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
