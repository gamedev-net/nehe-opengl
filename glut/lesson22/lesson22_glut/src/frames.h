/*****************************************
* frames.h
*
* Header file for calculating frame rate count
* in OpenGL application.
*
* Project Information:
*
* Author: Bruce "Sinner" Barrera
* E-mail: sinner@opengl.com.br
* Date  : around October 2003 :-)
* Glut Version: 3.7.6
*
* Very special thanks to all people who
* contributed with any online tutors or
* help files. Keep coding!
*
***********************************************

 Thanks to Toby Howard for the ideas on how to obtain microseconds in Linux,
 and for the struct and macros for Windows. Without him this would not be possible.

 ====================

 Usage Example:

    void glutDisplay(void) {
      glClear(GL_COLOR_BUFFER_BIT);

      // all the graphics code

      CalculateFrameRate();

      glutSwapBuffers();
    }
*****************************************/
#ifndef _FRAMES_H
#define _FRAMES_H

#ifndef _WIN32
#include <sys/time.h>
#else
#include <time.h>
/* Structure taken from the BSD file sys/time.h. */
typedef struct timeval {
        long    tv_sec;         /* seconds */
        long    tv_usec;        /* and microseconds */
}timeval;

/* Replacement gettimeofday
   It really just sets the microseconds to the clock() value
   (which under Windows is really milliseconds) */
void gettimeofday(timeval *t, void *__not_used_here__)
{
  t->tv_usec = (long)(clock());
  t->tv_sec += (long)(t->tv_usec / 1000); // transforms current miliseconds in secods to fill struct field
}

#endif
#include <stdio.h>

#endif
/* end of frames.h */
