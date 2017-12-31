This is (scalp)'s asm conversion of Nehe's opengl tuts.
This first lesson just create an opengl black window. Not
that F1 change from fullscreen to window mode, but this
thing doesn't work very well.

New include files for Masm32 can
could be find at hardcode site :
http://bizarrecreations.webjump.com
(the last i had is in the zip file)

*-------------------------------------------*
*Setting up OpenGL with Masm32 under Windows*
*-------------------------------------------*

First, you'll need the Masm32 package wich can
be found at masm32.cjb.net
Next, you'll have to download the latest include
file for OpenGL hardcode site :
http://bizarrecreations.webjump.com (i have include
here the one i had when i wrote this).
Be careful :
  include \masm32\include\ogl\kernel32.inc
  include \masm32\include\ogl\user32.inc
  include \masm32\include\ogl\gdi32.inc
I've include here a modified version of user32, gdi32
and kernel32 (the one found in Harcode package).
I also had some macro definitions that we need in the
file include.def
With all that you should be able to compile it like
any other project.

If you have any question, mail me at scalp@bigfoot.com
(s)

