//////////////////////////////////////////////////////////////////////
//
// glCamera.cpp: implementation of the glCamera class.
//
//////////////////////////////////////////////////////////////////////

#include "glCamera.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////
glCamera::glCamera()
{
    // Initalize all our member varibles.
    m_MaxPitchRate			= 0.0f;
    m_MaxHeadingRate		= 0.0f;
    m_HeadingDegrees		= 0.0f;
    m_PitchDegrees			= 0.0f;
    m_MaxForwardVelocity	= 0.0f;
    m_ForwardVelocity		= 0.0f;
}

glCamera::~glCamera()
{
}


//////////////////////////////////////////////////////////////////////
// Set perspective and move the camera
//////////////////////////////////////////////////////////////////////
void glCamera::SetPrespective()
{
    GLfloat Matrix[16];
    glQuaternion q;

    // Make the Quaternions that will represent our rotations
    m_qPitch.CreateFromAxisAngle(1.0f, 0.0f, 0.0f, m_PitchDegrees);
    m_qHeading.CreateFromAxisAngle(0.0f, 1.0f, 0.0f, m_HeadingDegrees);
	
    // Combine the pitch and heading rotations and store the results in q
    q = m_qPitch * m_qHeading;
    q.CreateMatrix(Matrix);

    // Let OpenGL set our new prespective on the world!
    glMultMatrixf(Matrix);

    // Create a matrix from the pitch Quaternion and get the j vector 
    // for our direction.
    m_qPitch.CreateMatrix(Matrix);
    m_DirectionVector.j = Matrix[9];

    // Combine the heading and pitch rotations and make a matrix to get
    // the i and j vectors for our direction.
    q = m_qHeading * m_qPitch;
    q.CreateMatrix(Matrix);
    m_DirectionVector.i = Matrix[8];
    m_DirectionVector.k = Matrix[10];

    // Scale the direction by our speed.
    m_DirectionVector *= m_ForwardVelocity;

    // Increment our position by the vector
    m_Position.x += m_DirectionVector.i;
    m_Position.y += m_DirectionVector.j;
    m_Position.z += m_DirectionVector.k;

    // Translate to our new position.
    glTranslatef(-m_Position.x, -m_Position.y, m_Position.z);
}

//////////////////////////////////////////////////////////////////////
// Changing the direction
//////////////////////////////////////////////////////////////////////
void glCamera::ChangePitch(GLfloat degrees)
{
    if(fabs(degrees) < fabs(m_MaxPitchRate))
    {
	// Our pitch is less than the max pitch rate that we 
	// defined so lets increment it.
	m_PitchDegrees += degrees;
    }
    else
    {
	// Our pitch is greater than the max pitch rate that
	// we defined so we can only increment our pitch by the 
	// maximum allowed value.
	if(degrees < 0)
	{
	    // We are pitching down so decrement
	    m_PitchDegrees -= m_MaxPitchRate;
	}
	else
	{
	    // We are pitching up so increment
	    m_PitchDegrees += m_MaxPitchRate;
	}
    }
    // We don't want our pitch to run away from us. Although it
    // really doesn't matter I prefer to have my pitch degrees
    // within the range of -360.0f to 360.0f
    if(m_PitchDegrees > 360.0f)
    {
	m_PitchDegrees -= 360.0f;
    }
    else if(m_PitchDegrees < -360.0f)
    {
	m_PitchDegrees += 360.0f;
    }
}


void glCamera::ChangeHeading(GLfloat degrees)
{
    if(fabs(degrees) < fabs(m_MaxHeadingRate))
    {
	// Our Heading is less than the max heading rate that we 
	// defined so lets increment it but first we must check
	// to see if we are inverted so that our heading will not
	// become inverted.
	if(m_PitchDegrees > 90 && m_PitchDegrees < 270
	   || (m_PitchDegrees < -90 && m_PitchDegrees > -270))
	{
	    m_HeadingDegrees -= degrees;
	}
	else
	{
	    m_HeadingDegrees += degrees;
	}
    }
    else
    {
	// Our heading is greater than the max heading rate that
	// we defined so we can only increment our heading by the 
	// maximum allowed value.
	if(degrees < 0)
	{
	    // Check to see if we are upside down.
	    if((m_PitchDegrees > 90 && m_PitchDegrees < 270)
	       || (m_PitchDegrees < -90 && m_PitchDegrees > -270))
	    {
		// Ok we would normally decrement here but since we are upside
		// down then we need to increment our heading
		m_HeadingDegrees += m_MaxHeadingRate;
	    }
	    else
	    {
		// We are not upside down so decrement as usual
		m_HeadingDegrees -= m_MaxHeadingRate;
	    }
	}
	else
	{
	    // Check to see if we are upside down.
	    if(m_PitchDegrees > 90 && m_PitchDegrees < 270
	       || (m_PitchDegrees < -90 && m_PitchDegrees > -270))
	    {
		// Ok we would normally increment here but since we are upside
		// down then we need to decrement our heading.
		m_HeadingDegrees -= m_MaxHeadingRate;
	    }
	    else
	    {
		// We are not upside down so increment as usual.
		m_HeadingDegrees += m_MaxHeadingRate;
	    }
	}
    }
	
    // We don't want our heading to run away from us either. Although it
    // really doesn't matter I prefer to have my heading degrees
    // within the range of -360.0f to 360.0f
    if(m_HeadingDegrees > 360.0f)
    {
	m_HeadingDegrees -= 360.0f;
    }
    else if(m_HeadingDegrees < -360.0f)
    {
	m_HeadingDegrees += 360.0f;
    }
}


void glCamera::ChangeVelocity(GLfloat vel)
{
    if(fabs(vel) < fabs(m_MaxForwardVelocity))
    {
	// Our velocity is less than the max velocity increment that we 
	// defined so lets increment it.
	m_ForwardVelocity += vel;
    }
    else
    {
	// Our velocity is greater than the max velocity increment that
	// we defined so we can only increment our velocity by the 
	// maximum allowed value.
	if(vel < 0)
	{
	    // We are slowing down so decrement
	    m_ForwardVelocity -= -m_MaxForwardVelocity;
	}
	else
	{
	    // We are speeding up so increment
	    m_ForwardVelocity += m_MaxForwardVelocity;
	}
    }
}
