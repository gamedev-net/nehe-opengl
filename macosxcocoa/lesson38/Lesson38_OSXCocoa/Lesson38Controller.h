/*
 * Original Windows comment:
 * "Jeff Molofee's Lesson 38
 *     nehe.gamedev.net
 *           2002"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson38Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson38View.h"

@interface Lesson38Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson38View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
