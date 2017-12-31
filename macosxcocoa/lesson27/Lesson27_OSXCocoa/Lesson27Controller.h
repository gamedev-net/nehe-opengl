/*
 * Original Windows comment:
 * "This code has been created by Banu Cosmin aka Choko - 20 may 2000
 * and uses NeHe tutorials as a starting point (window initialization,
 * texture loading, GL initialization and code for keypresses) - very good
 * tutorials, Jeff. If anyone is interested about the presented algorithm
 * please e-mail me at boct@romwest.ro
 * Attention!!! This code is not for beginners."
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson27Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson27View.h"

@interface Lesson27Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson27View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
