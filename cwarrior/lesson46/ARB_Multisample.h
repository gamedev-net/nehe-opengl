/*====================================
	Name: ARB_multisample.h
	Author: Colt "MainRoach" McAnlis
	Date: 4/29/04
	Desc:
		This file contains our external items

====================================*/

#ifndef __ARB_MULTISAMPLE_H__
#define __ARB_MULTISAMPLE_H__

#include <gl/wglext.h>		//WGL extensions
#include <gl/glext.h>		//GL extensions

//Globals
extern bool	arbMultisampleSupported;
extern int arbMultisampleFormat;

//If you don't want multisampling, set this to 0
#define CHECK_FOR_MULTISAMPLE 1

//to check for our sampling
bool InitMultisample(HINSTANCE hInstance,HWND hWnd,PIXELFORMATDESCRIPTOR pfd);

#endif