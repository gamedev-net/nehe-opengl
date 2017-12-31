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

/* Lesson22Controller.m */

#import "Lesson22Controller.h"

@interface Lesson22Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation Lesson22Controller

- (void) awakeFromNib
{  
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson22View alloc ] initWithFrame:[ glWindow frame ]
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
      case 'e':
      case 'E':
         if( ![ theEvent isARepeat ] )
            [ glView toggleEmboss ];
         break;

      case 'm':
      case 'M':
         if( ![ theEvent isARepeat ] )
            [ glView toggleMultitexture ];
         break;

      case 'b':
      case 'B':
         if( ![ theEvent isARepeat ] )
            [ glView toggleBumps ];
         break;

      case 'f':
      case 'F':
         if( ![ theEvent isARepeat ] )
            [ glView selectNextFilter ];
         break;

      case NSPageUpFunctionKey:
         [ glView decreaseZ ];
         break;

      case NSPageDownFunctionKey:
         [ glView increaseZ ];
         break;

      case NSUpArrowFunctionKey:
         [ glView decreaseXSpeed ];
         break;

      case NSDownArrowFunctionKey:
         [ glView increaseXSpeed ];
         break;

      case NSLeftArrowFunctionKey:
         [ glView decreaseYSpeed ];
         break;

      case NSRightArrowFunctionKey:
         [ glView increaseYSpeed ];
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
