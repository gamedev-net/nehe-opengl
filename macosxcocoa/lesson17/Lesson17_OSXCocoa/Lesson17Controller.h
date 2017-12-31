/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * and modified by Giuseppe D'Agata (waveform@tiscalinet.it)
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson17Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson17View.h"

@interface Lesson17Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson17View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
