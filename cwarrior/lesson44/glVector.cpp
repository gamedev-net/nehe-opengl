// Code writen by: Vic Hollis 09/07/2003
// I don't mind if you use this class in your own code. All I ask is 
// that you give me credit for it if you do.  And plug NeHe while your
// at it! :P  
//////////////////////////////////////////////////////////////////////
// glVector.cpp: implementation of the glVector class.
//////////////////////////////////////////////////////////////////////

#include "glVector.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

glVector::glVector()
{
	i = j = k = m_Mag = 0.0f;										// Initalize the i, j, k, and magnitude to 0.0
}

glVector::~glVector()
{

}

// Scale the vector times some number
void glVector::operator *=(GLfloat scalar)
{
	i *= scalar;
	j *= scalar;
	k *= scalar;
}

// Computes the magnitude and saves it in m_Mag also returns the 
// Magnitude
GLfloat glVector::Magnitude()
{
	GLfloat result; 
	
	result = GLfloat(sqrt(i * i + j * j + k * k));
	m_Mag = result;
	return(result);
}

// Makes the vector unit length.
void glVector::Normalize()
{
	if(m_Mag != 0.0f)
	{
		i /= m_Mag;
		j /= m_Mag;
		k /= m_Mag;

		Magnitude();
	}
}

// Multiply this vector times another and return the result
glVector glVector::operator *(GLfloat scalar)
{
	glVector r;

	r.i = i * scalar;
	r.j = j * scalar;
	r.k = k * scalar;

	return(r);
}

// Add this vector to another and return the result
glVector glVector::operator +(glVector v)
{
	glVector r;

	r.i = i + v.i;
	r.j = j + v.j;
	r.k = k + v.k;

	return(r);
}

// Assign this vector to the vector passed in.
void glVector::operator =(glVector v)
{
	i = v.i;
	j = v.j;
	k = v.k;
	m_Mag = v.m_Mag;
}
