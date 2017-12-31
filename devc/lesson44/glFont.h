// Code writen by: Vic Hollis 09/07/2003
// I don't mind if you use this class in your own code. All I ask is 
// that you give me and Giuseppe D'Agata credit for it if you do.  
// And plug NeHe while your at it! :P  Thanks go to Giuseppe D'Agata
// for the code that this class is based off of. Thanks Enjoy.
//////////////////////////////////////////////////////////////////////
// glFont.h: interface for the glFont class.
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_GLFONT_H__F5069B5F_9D05_4832_8200_1EC9B4BFECE6__INCLUDED_)
#define AFX_GLFONT_H__F5069B5F_9D05_4832_8200_1EC9B4BFECE6__INCLUDED_

#include <windows.h>
#include <GL/gl.h>

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

class glFont  
{
public:
	GLuint GetListBase(void);
	GLuint GetTexture(void);
	void SetWindowSize(GLint width, GLint height);
	void glPrintf(GLint x, GLint y, GLint set, const char *Format, ...);
	void BuildFont(GLfloat Scale=1.0f);
	void SetFontTexture(GLuint tex);
	glFont();
	virtual ~glFont();

protected:
	GLdouble m_WindowWidth;
	GLdouble m_WindowHeight;
	GLuint m_ListBase;
	GLuint m_FontTexture;
};

#endif // !defined(AFX_GLFONT_H__F5069B5F_9D05_4832_8200_1EC9B4BFECE6__INCLUDED_)
