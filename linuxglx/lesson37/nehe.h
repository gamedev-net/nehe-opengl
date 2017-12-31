/*
 * This code was created by Jeff Molofee '99 (ported to Linux//GLX by Patrick Schubert 2003
 * with help from the lesson 1 basecode for Linux/GLX by Mihael Vrbanec)
 */

#ifndef NEHE_BASE_H
#define NEHE_BASE_H

enum KEYCODES {WK_1,WK_2,WK_3,WK_4,WK_UP,WK_DOWN,WK_LEFT,WK_RIGHT,WK_SPACE,WK_PRIOR,WK_NEXT,
				WK_Q,WK_Z,WK_W,WK_S,WK_D,WK_A};

void createGLWindow(const char*,int,int,int,int);
void killGLWindow(void);
void run(void);
int isKeyDown(int);
void resetKey(int);

#endif
