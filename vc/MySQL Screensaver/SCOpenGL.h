//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: SCOpenGL.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _SCOPENGL_H_
#define _SCOPENGL_H_

//include all OpenGL stuff
#ifdef __BORLANDC__
#include <windows>
#include "gl.h"
#include "glu.h"
#else
#include <windows.h>
#include <gl\gl.h>
#include <gl\glu.h>
#endif

#endif
