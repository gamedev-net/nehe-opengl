/*
 * Original Windows comment:
 * "   Jeff Molofee's Picking Tutorial   *
 *          nehe.gamedev.net             *
 *                2001                   *"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson32Controller.h */

#import <Cocoa/Cocoa.h>
#import <sys/time.h>
#import "Lesson32View.h"

@interface Lesson32Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson32View *glView;
   struct timeval lastTime;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
