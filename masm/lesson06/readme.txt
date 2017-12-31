LESSON 06

This is (scalp)'s asm conversion of Nehe's opengl tuts.
(without all error detections)

OpenGL include files for Masm32 can
could be find at hardcode site :
http://bizarrecreations.webjump.com

Masm32 can be found at masm32.cjb.net

We here learn to use texture mapping (which is very powerful !).
Glaux is not so powerful and is difficult to use in asm, so if
you can, don't use it... Here we use resource instead of opening
a file with glaux.
The original C LoadGLTextures function was also made by Nehe,
i give here the asm version converted by myself.
Note that this version of LoadGLTexture doesn't work with
256 color bitmap.

F1 : change from fullscreen to window mode or from window to fullscreen

Again, please excuse my bad english !
(s)
