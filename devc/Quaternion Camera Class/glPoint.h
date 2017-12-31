// glPoint.h: interface for the glPoint class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_GLPOINT_H__ADADC708_0176_471A_8241_5DD4D700BCB2__INCLUDED_)
#define AFX_GLPOINT_H__ADADC708_0176_471A_8241_5DD4D700BCB2__INCLUDED_

#include <windows.h>		// Header File For Windows
#include <gl\gl.h>			// Header File For The OpenGL32 Library
#include <gl\glu.h>			// Header File For The GLu32 Library
#include <gl\glaux.h>		// Header File For The Glaux Library

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

class glPoint  
{
public:
	glPoint();
	virtual ~glPoint();

	GLfloat z;
	GLfloat y;
	GLfloat x;
};

#endif // !defined(AFX_GLPOINT_H__ADADC708_0176_471A_8241_5DD4D700BCB2__INCLUDED_)
