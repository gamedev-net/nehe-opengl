/*
 * Original Windows comment:
 * "The OpenGL Basecode Used In This Project Was Created By
 * Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code
 * Useful, Please Let Me Know.
 *
 * Original Code & Tutorial Text By Andreas Lšffler
 * Excellent Job Andreas!
 *
 * Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )
 * Proper Image Structure, Better Blitter Code, Misc Fixes
 * Thanks Rob!
 *
 * 0% CPU Usage While Minimized Thanks To Jim Strong
 * ( jim@scn.net ).  Thanks Jim!
 *
 * This Code Also Has The ATI Fullscreen Fix!
 *
 * Visit Me At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson29Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson29View.h"

@interface Lesson29Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson29View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
