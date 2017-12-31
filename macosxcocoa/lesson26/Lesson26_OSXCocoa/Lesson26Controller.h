/*
 * Original Windows comment:
 * "This code has been created by Banu Cosmin aka Choko - 20 may 2000
 * and uses NeHe tutorials as a starting point (window initialization,
 * texture loading, GL initialization and code for keypresses) - very good
 * tutorials, Jeff. If anyone is interested about the presented algorithm
 * please e-mail me at boct@romwest.ro
 *
 * Code commmenting and clean up by Jeff Molofee ( NeHe )
 * NeHe Productions        ...             http://nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson26Controller.h */

#import <Cocoa/Cocoa.h>
#import "Lesson26View.h"

@interface Lesson26Controller : NSResponder
{
   IBOutlet NSWindow *glWindow;

   NSTimer *renderTimer;
   Lesson26View *glView;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@end
