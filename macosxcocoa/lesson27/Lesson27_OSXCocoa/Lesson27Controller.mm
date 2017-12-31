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

/* Lesson27Controller.mm */

#import "Lesson27Controller.h"

@interface Lesson27Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation Lesson27Controller

- (void) awakeFromNib
{ 
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson27View alloc ] initWithFrame:[ glWindow frame ]
              colorBits:16 depthBits:16 fullscreen:FALSE ];
   if( glView != nil )
   {
      [ glWindow setContentView:glView ];
      [ glWindow makeKeyAndOrderFront:self ];
      [ self setupRenderTimer ];
   }
   else
      [ self createFailed ];
}


/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
   NSTimeInterval timeInterval = 0.005;

   renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                             target:self
                             selector:@selector( updateGLView: )
                             userInfo:nil repeats:YES ] retain ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSEventTrackingRunLoopMode ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSModalPanelRunLoopMode ];
}


/*
 * Called by the rendering timer.
 */
- (void) updateGLView:(NSTimer *)timer
{
   if( glView != nil )
      [ glView drawRect:[ glView frame ] ];
}


/*
 * Handle key presses
 */
- (void) keyDown:(NSEvent *)theEvent
{ 
   unichar unicodeKey;
   
   unicodeKey = [ [ theEvent characters ] characterAtIndex:0 ];
   switch( unicodeKey )
   {
      case NSLeftArrowFunctionKey:
         [ glView decreaseYSpeed ];
         break;

      case NSRightArrowFunctionKey:
         [ glView increaseYSpeed ];
         break;

      case NSUpArrowFunctionKey:
         [ glView decreaseXSpeed ];
         break;

      case NSDownArrowFunctionKey:
         [ glView increaseXSpeed ];
         break;

      case 'l':
      case 'L':
         [ glView moveLightRight ];
         break;

      case 'j':
      case 'J':
         [ glView moveLightLeft ];
         break;

      case 'i':
      case 'I':
         [ glView moveLightUp ];
         break;

      case 'k':
      case 'K':
         [ glView moveLightDown ];
         break;

      case 'o':
      case 'O':
         [ glView moveLightToViewer ];
         break;

      case 'u':
      case 'U':
         [ glView moveLightFromViewer ];
         break;

      case '6':
         [ glView moveObjectRight ];
         break;

      case '4':
         [ glView moveObjectLeft ];
         break;

      case '8':
         [ glView moveObjectUp ];
         break;

      case '5':
         [ glView moveObjectDown ];
         break;

      case '9':
         [ glView moveObjectToViewer ];
         break;

      case '7':
         [ glView moveObjectFromViewer ];
         break;

      case 'd':
      case 'D':
         [ glView moveBallRight ];
         break;

      case 'a':
      case 'A':
         [ glView moveBallLeft ];
         break;

      case 'w':
      case 'W':
         [ glView moveBallUp ];
         break;

      case 's':
      case 'S':
         [ glView moveBallDown ];
         break;

      case 'e':
      case 'E':
         [ glView moveBallToViewer ];
         break;

      case 'q':
      case 'Q':
         [ glView moveBallFromViewer ];
         break;
   }
}  


/*
 * Set full screen.
 */
- (IBAction)setFullScreen:(id)sender
{ 
   [ glWindow setContentView:nil ];
   if( [ glView isFullScreen ] ) 
   {
      if( ![ glView setFullScreen:FALSE inFrame:[ glWindow frame ] ] )
         [ self createFailed ];
      else 
         [ glWindow setContentView:glView ];
   }
   else
   {
      if( ![ glView setFullScreen:TRUE
                    inFrame:NSMakeRect( 0, 0, 800, 600 ) ] )
         [ self createFailed ];
   }
}  


/*
 * Called if we fail to create a valid OpenGL view
 */
- (void) createFailed
{
   NSWindow *infoWindow;

   infoWindow = NSGetCriticalAlertPanel( @"Initialization failed",
                                         @"Failed to initialize OpenGL",
                                         @"OK", nil, nil );
   [ NSApp runModalForWindow:infoWindow ];
   [ infoWindow close ];
   [ NSApp terminate:self ];
}


/*
 * Cleanup
 */
- (void) dealloc
{
   [ glWindow release ];
   [ glView release ];
   if( renderTimer != nil && [ renderTimer isValid ] )
      [ renderTimer invalidate ];
}

@end
