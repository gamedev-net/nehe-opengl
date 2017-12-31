/*
 * Original Windows comment:
 * "This Code Was Published By Jeff Molofee 2000
 * Code Was Created By David Nikdel For NeHe Productions
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson28Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson28View.h"

@interface Lesson28Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson28View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
