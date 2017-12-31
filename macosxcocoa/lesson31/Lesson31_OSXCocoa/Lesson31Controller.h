/*
 * Original Windows comment:
 * "This Code Was Created By Brett Porter For NeHe Productions 2000
 * Visit NeHe Productions At http://nehe.gamedev.net
 *
 * Visit Brett Porter's Web Page at
 * http://www.geocities.com/brettporter/programming"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson31Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson31View.h"

@interface Lesson31Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson31View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
