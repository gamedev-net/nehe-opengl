/*
 * Original Windows comment:
 * "Sami Hamlaoui's Cel-Shading Code
 *     http://nehe.gamedev.net
 *               2001"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson37Controller.h */

#import <Cocoa/Cocoa.h>
#import <sys/time.h>
#import "Lesson37View.h"

@interface Lesson37Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson37View *glView;
   struct timeval lastTime;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
