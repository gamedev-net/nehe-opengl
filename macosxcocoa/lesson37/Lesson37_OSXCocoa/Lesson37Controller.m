/*
 * Original Windows comment:
 * "Sami Hamlaoui's Cel-Shading Code
 *     http://nehe.gamedev.net
 *               2001"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson37Controller.m */

#import "Lesson37Controller.h"

@interface Lesson37Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

#define ESCAPE_KEY 0x1B

@implementation Lesson37Controller

- (void) awakeFromNib
{ 
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson37View alloc ] initWithFrame:[ glWindow frame ]
              colorBits:16 depthBits:16 fullscreen:FALSE ];
   if( glView != nil )
   {
      gettimeofday( &lastTime, NULL );
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
   long milliseconds;
   struct timeval rightNow;

   if( glView != nil )
   {
      gettimeofday( &rightNow, NULL );
      milliseconds = ( rightNow.tv_sec - lastTime.tv_sec ) * 1000;
      milliseconds += ( rightNow.tv_usec - lastTime.tv_usec ) / 1000;
      lastTime = rightNow;
      [ glView update:milliseconds ];
      [ glView drawRect:[ glView frame ] ];
   }
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
      case ' ':
         [ glView toggleModelRotate ];
         break;

      case '1':
         [ glView toggleOutlineDraw ];
         break;

      case '2':
         [ glView toggleOutlineSmooth ];
         break;

      case NSUpArrowFunctionKey:
         [ glView increaseLineWidth ];
         break;

      case NSDownArrowFunctionKey:
         [ glView decreaseLineWidth ];
         break;

      case ESCAPE_KEY:
         [ NSApp terminate:self ];
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
