/*
 * Original Windows comment:
 * "Radial Blur & Rendering To A Texture
 * How To Create A Radial Blur Effect
 * Dario Corno (rIo) / Jeff Molofee (NeHe)
 * http://www.spinningkids.org/rio
 * http://nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson36Controller.h */

#import <Cocoa/Cocoa.h>
#import <sys/time.h>
#import "Lesson36View.h"

@interface Lesson36Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson36View *glView;
   struct timeval lastTime;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
