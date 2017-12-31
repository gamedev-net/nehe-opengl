/*
 * Original Windows comment:
 * "This code was created by Christopher Aliotta & Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up and optimizing
 * the base code, making it more flexible!  If you've found this code
 * useful, please let me know.  Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson16Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson16View.h"

@interface Lesson16Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson16View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
