//////////////////////////////////////////////////////////////////////
//
// glVector.h: interface for the glVector class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_GLVECTOR_H__F526A5CF_89B5_4F20_8F2C_517D83879D35__INCLUDED_)
#define AFX_GLVECTOR_H__F526A5CF_89B5_4F20_8F2C_517D83879D35__INCLUDED_

#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library


class glVector  
{
public:
	void operator *=(GLfloat scalar);
	glVector();
	virtual ~glVector();
	GLfloat k;
	GLfloat j;
	GLfloat i;
};

#endif // !defined(AFX_GLVECTOR_H__F526A5CF_89B5_4F20_8F2C_517D83879D35__INCLUDED_)
