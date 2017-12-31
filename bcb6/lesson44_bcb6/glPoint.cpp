// Code writen by: Vic Hollis 09/07/2003
// I don't mind if you use this class in your own code. All I ask is 
// that you give me credit for it if you do.  And plug NeHe while your
// at it! :P  
//////////////////////////////////////////////////////////////////////
// glPoint.cpp: implementation of the glPoint class.
//////////////////////////////////////////////////////////////////////

#include "glPoint.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

glPoint::glPoint()
{
	x = y = z = 0.0f;												// Initalize the x, y, z components to zero
}

glPoint::~glPoint()
{

}

void glPoint::operator =(glPoint p)
{
	x = p.x;														// Set this point to = the point passed in.
	y = p.y;
	z = p.z;
}

// Usually this operator get called when we scaled a vector to get
// a 3D point IE  point = unit_vector * 25.0f;
void glPoint::operator =(glVector v)
{
	x = v.i;														// Set this point to the vectors i component
	y = v.j;														// Set this point to the vectors j component
	z = v.k;														// Set this point to the vectors k component
}

// Subrtacts the components of two points to get a vector.
glVector glPoint::operator -(glPoint p)
{
	glVector r;

	r.i = x - p.x;
	r.j = y - p.y;
	r.k = z - p.z;

	return(r);
}

// Technically your not supposed to be able to add 2 points 
// together by mathmatical definations but I don't mind 
// bending the rules a little.
glPoint glPoint::operator +(glPoint p)
{
	glPoint r;

	r.x = x + p.x;
	r.y = y + p.y;
	r.z = z + p.z;

	return(r);
}

// Technically your not supposed to be able to add 2 points 
// together by mathmatical definations but I don't mind 
// bending the rules a little.
void glPoint::operator +=(glPoint p)
{
	x += p.x;
	y += p.y;
	z += p.z;
}
