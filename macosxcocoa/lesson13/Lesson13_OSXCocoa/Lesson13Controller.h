/*
 * Original Windows comment:
 * "This Code Was Created By Jeff Molofee 2000
 * Modified by Shawn T. to handle (%3.2f, num) parameters.
 * A HUGE Thanks To Fredric Echols For Cleaning Up
 * And Optimizing The Base Code, Making It More Flexible!
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson13Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson13View.h"

@interface Lesson13Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson13View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
