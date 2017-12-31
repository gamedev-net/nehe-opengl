/*
 * Original Windows comment:
 * "This code was created by Jens Schneider (WizardSoft) 2000
 * Lesson22 to the series of OpenGL tutorials by NeHe-Production
 *
 * This code is loosely based upon Lesson06 by Jeff Molofee.
 *
 * contact me at: schneide@pool.informatik.rwth-aachen.de
 *
 * Basecode was created by Jeff Molofee 2000 
 * If you've found this code useful, please let me know. 
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson22Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson22View.h"

@interface Lesson22Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson22View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
