//////////////////////////////////////////////////////////////////////
//
// glCamera.h: interface for the glCamera class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_GLCAMERA_H__8E3CD02E_6D82_437E_80DA_50023C60C146__INCLUDED_)
#define AFX_GLCAMERA_H__8E3CD02E_6D82_437E_80DA_50023C60C146__INCLUDED_

#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library

#include "glQuaternion.h"
#include "glPoint.h"
#include "glVector.h"


class glCamera  
{
public:
	GLfloat m_MaxPitchRate;
	GLfloat m_MaxHeadingRate;
	GLfloat m_HeadingDegrees;
	GLfloat m_PitchDegrees;
	GLfloat m_MaxForwardVelocity;
	GLfloat m_ForwardVelocity;
	glQuaternion m_qHeading;
	glQuaternion m_qPitch;
	glPoint m_Position;
	glVector m_DirectionVector;

	void ChangeVelocity(GLfloat vel);
	void ChangeHeading(GLfloat degrees);
	void ChangePitch(GLfloat degrees);
	void SetPrespective(void);
	void IncrementPosition();
	glCamera();
	virtual ~glCamera();
};

#endif // !defined(AFX_GLCAMERA_H__8E3CD02E_6D82_437E_80DA_50023C60C146__INCLUDED_)
