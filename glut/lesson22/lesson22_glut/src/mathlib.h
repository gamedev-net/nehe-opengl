/************************************************
* Project Information:
*
* Filename:mathlib.h
* Version :1.0
* Last Update: May 2003
*
* Author: Bruce Christopher Barrera
* E-mail: bruce@opengl.com.br
* Date  : around May 2003 :-)
*
* Comment: This is the header file for math lib
*
***********************************************/

#ifndef _MATHLIB_H
#define _MATHLIB_H

#include <math.h>

/// This is our 3D point class.  This will be used to store the vertices of our model.
class CVector3
{
public:
	float x, y, z;
};

/// This is our 2D point class.  This will be used to store the UV coordinates.
class CVector2
{
public:
	float x, y;
};

/// This is our Color class. It is used to hold r,g,b values.
class COLOR
{
public:
	float r, g, b;
};


//////////////////////////////////////////////////////////////
/// Function Prototypes
//////////////////////////////////////////////////////////////

// This computes the magnitude of a normal.   (magnitude = sqrt(x^2 + y^2 + z^2)
#define Mag(Normal) (sqrt(Normal.x*Normal.x + Normal.y*Normal.y + Normal.z*Normal.z))

// This calculates a vector between 2 points and returns the result
CVector3 Vector(CVector3 vPoint1, CVector3 vPoint2);

// This adds 2 vectors together and returns the result
CVector3 AddVector(CVector3 vVector1, CVector3 vVector2);

// This divides a vector by a single number (scalar) and returns the result
CVector3 DivideVectorByScaler(CVector3 vVector1, float Scaler);

// This returns the cross product between 2 vectors
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);

// This returns the normal of a vector
CVector3 Normalize(CVector3 vNormal);

#endif //_MATHLIB_H