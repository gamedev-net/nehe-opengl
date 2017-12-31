/*
 * Original Windows comment:
 * "Based On Lesson 6"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson33Controller.h */

#import <Cocoa/Cocoa.h>
#import <Lesson33View.h>

@interface Lesson33Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson33View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
