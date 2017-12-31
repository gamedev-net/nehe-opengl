/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson19Controller.m */

#import "Lesson19Controller.h"

@interface Lesson19Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation Lesson19Controller

- (void) awakeFromNib
{  
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson19View alloc ] initWithFrame:[ glWindow frame ]
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
      case '+':
         if( [ theEvent modifierFlags ] & NSNumericPadKeyMask )
            [ glView speedParticles ];
         break;

      case '-':
         if( [ theEvent modifierFlags ] & NSNumericPadKeyMask )
            [ glView slowParticles ];
         break;

      case NSPageUpFunctionKey:
         [ glView increaseZoom ];
         break;

      case NSPageDownFunctionKey:
         [ glView decreaseZoom ];
         break;

      case NSCarriageReturnCharacter:   // Return key
      case NSEnterCharacter:            // Enter key
         // The enter character needs to come from the numeric keypad
         // to be the enter key
         if( unicodeKey == NSCarriageReturnCharacter ||
             ( unicodeKey == NSEnterCharacter &&
               [ theEvent modifierFlags ] & NSNumericPadKeyMask ) &&
             ![ theEvent isARepeat ] )
            [ glView toggleRainbow ];
         break;

      case ' ':
         if( ![ theEvent isARepeat ] )
         {
            [ glView disableRainbow ];
            [ glView nextColor ];
         }
         break;

      case NSUpArrowFunctionKey:
         [ glView increaseYSpeed ];
         break;

      case NSDownArrowFunctionKey:
         [ glView decreaseYSpeed ];
         break;

      case NSRightArrowFunctionKey:
         [ glView increaseXSpeed ];
         break;

      case NSLeftArrowFunctionKey:
         [ glView decreaseXSpeed ];
         break;

      case '8':
         if( [ theEvent modifierFlags ] & NSNumericPadKeyMask )
            [ glView increaseYGravity ];
         break;

      case '2':
         if( [ theEvent modifierFlags ] & NSNumericPadKeyMask )
            [ glView decreaseYGravity ];
         break;

      case '6':
         if( [ theEvent modifierFlags ] & NSNumericPadKeyMask )
            [ glView increaseXGravity ];
         break;

      case '4':
         if( [ theEvent modifierFlags ] & NSNumericPadKeyMask )
            [ glView decreaseXGravity ];
         break;

      case NSTabCharacter:
         [ glView burst ];
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
