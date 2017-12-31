/* This code was created by Jeff Molofee '99 (Ported to Linux/GLX by
 * Patrick Schubert 2000 with the help from lesson 1 basecode for Linux/GLX
 * by Mihael Vrbanec).
 *
 * Cleaned up and Hopefully easier to read version by Jason Schultz (2004)
 *
 * @File:			glx_base.h
 *
 * @Description: 	Main Header File for OpenGL/GLX Base code
 */
 
#ifndef _GLX_BASE_H_
#define _GLX_BASE_H_
 
/* Standard OpenGL/GLX header files */
#include <GL/glx.h>
#include <GL/gl.h>
#include <GL/glu.h>
/* Add the Cg Headers */
#include <Cg/cg.h>
#include <Cg/cgGL.h>
/* Headers needed for keys used in the program */
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>
/* Standard C header files */
#include <stdio.h>
#include <stdlib.h>
#include <math.h> 
#include <time.h>
 
/* Function Definitions */
 
void createGLWindow(const char* title, int width, int height, int bpp, BOOL fsflag);
void runGLScene(void);
void killGLWindow(void);
void resizeGLScene(void);
void swapBuffers(void);
void initKeys(void);
void updateGLScene(void);
BOOL initGLScene(void);
void cleanGLScene(void);
void drawGLScene(void);
 
 
#endif /* End of _GLX_BASE_H_ */
