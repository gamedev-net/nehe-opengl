// Code writen by: Vic Hollis 09/07/2003
// I don't mind if you use this class in your own code. All I ask is 
// that you give me credit for it if you do.  And plug NeHe while your
// at it! :P  Thanks go to David Steere, Cameron Tidwell, Bert Sammons,
// and Brannon Martindale for helping me test all the code!  Enjoy.
//////////////////////////////////////////////////////////////////////
// glCamera.h: interface for the glCamera class.
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
// Some minimal additions by rIO.Spinning Kids 
// For testing flares against occluding objects.
// Not using proprietary extensions, this is PURE OpenGL1.1
//
// Just call the IsOccluded function, passing it the glPoint to check
//
//////////////////////////////////////////////////////////////////////


#if !defined(AFX_GLCAMERA_H__8E3CD02E_6D82_437E_80DA_50023C60C146__INCLUDED_)
#define AFX_GLCAMERA_H__8E3CD02E_6D82_437E_80DA_50023C60C146__INCLUDED_

#include <windows.h>											// Header File For Windows
#include <gl\gl.h>												// Header File For The OpenGL32 Library
#include <gl\glu.h>												// Header File For The GLu32 Library
#include <math.h>
#include "glPoint.h"
#include "glVector.h"

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

class glCamera  
{
public:
	//////////// CONSTRUCTORS /////////////////////////////////////////
	glCamera();
	virtual ~glCamera();

	//////////// FRUSTUM TESTING FUNCTIONS ////////////////////////////
	BOOL SphereInFrustum(glPoint p, GLfloat Radius);
	BOOL SphereInFrustum(GLfloat x, GLfloat y, GLfloat z, GLfloat Radius);
	BOOL PointInFrustum(GLfloat x, GLfloat y, GLfloat z);
	BOOL PointInFrustum(glPoint p);

	//////////// FUNCTIONS TO RENDER LENS FLARES //////////////////////
	void RenderLensFlare(void);
	void RenderStreaks(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale);
	void RenderBigGlow(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale);
	void RenderGlow(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale);
	void RenderHalo(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale);
	
	//////////// FUNCTIONS TO UPDATE THE FRUSTUM //////////////////////
	void UpdateFrustumFaster(void);
	void UpdateFrustum(void);

	//////////// FUNCTIONS TO CHANGE CAMERA ORIENTATION AND SPEED /////
	void ChangeVelocity(GLfloat vel);
	void ChangeHeading(GLfloat degrees);
	void ChangePitch(GLfloat degrees);
	void SetPrespective(void);

	//############################### NEW STUFF ##########################
	/////////// OCCLUSION TESTING FUNCTIONS ///////////////////////////
	bool glCamera::IsOccluded(glPoint p);

	//////////// MEMBER VARIBLES //////////////////////////////////////
	glVector vLightSourceToCamera, vLightSourceToIntersect;
	glPoint ptIntersect, pt;
	GLsizei m_WindowHeight;
	GLsizei m_WindowWidth;
	GLuint m_StreakTexture;
	GLuint m_HaloTexture;
	GLuint m_GlowTexture;
	GLuint m_BigGlowTexture;
	GLfloat m_MaxPointSize;
	GLfloat m_Frustum[6][4];
	glPoint m_LightSourcePos;
	GLfloat m_MaxPitchRate;
	GLfloat m_MaxHeadingRate;
	GLfloat m_HeadingDegrees;
	GLfloat m_PitchDegrees;
	GLfloat m_MaxForwardVelocity;
	GLfloat m_ForwardVelocity;
	glPoint m_Position;
	glVector m_DirectionVector;
};

#endif // !defined(AFX_GLCAMERA_H__8E3CD02E_6D82_437E_80DA_50023C60C146__INCLUDED_)
