// Code writen by: Vic Hollis 09/07/2003
// I don't mind if you use this class in your own code. All I ask is 
// that you give me credit for it if you do.  And plug NeHe while your
// at it! :P  Thanks go to David Steere, Cameron Tidwell, Bert Sammons,
// and Brannon Martindale for helping me test all the code!  Enjoy.

// glCamera.cpp: implementation of the glCamera class.
//
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Some minimal additions by rIO.Spinning Kids 
// For testing flares against occluding objects.
// Not using proprietary extensions, this is PURE OpenGL1.1
//
// Just call the IsOccluded function, passing it the glPoint to check
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
	m_LightSourcePos.x      = 0.0f;
	m_LightSourcePos.y      = 0.0f;
	m_LightSourcePos.z      = 0.0f;
	m_GlowTexture           = 0;
	m_HaloTexture			= 0;
	m_StreakTexture			= 0;
	m_MaxPointSize			= 0.0f;
}

glCamera::~glCamera()
{
	if(m_GlowTexture != 0) {										// If the glow texture is valid 
		glDeleteTextures(1, &m_GlowTexture);						// delete the glow texture
	}

	if(m_HaloTexture != 0) {										// If the halo texture is valid
		glDeleteTextures(1, &m_HaloTexture);						// delete the halo texture
	}

	if(m_BigGlowTexture != 0) {										// If the BigGlow texture is valid
		glDeleteTextures(1, &m_BigGlowTexture);						// delete the BigGlow texture
	}

	if(m_StreakTexture != 0) {										// If the Streak texture is valid
		glDeleteTextures(1, &m_StreakTexture);						// delete the StreakTexture
	}
}

void glCamera::SetPrespective()
{
	GLfloat Matrix[16];												// A array to hold the model view matrix.
	glVector v;														// A vector to hold our cameras direction * the forward velocity
																	// we don't want to destory the Direction vector by using it instead.

	// Going to use glRotate to calculate our direction vector
	glRotatef(m_HeadingDegrees, 0.0f, 1.0f, 0.0f);
	glRotatef(m_PitchDegrees, 1.0f, 0.0f, 0.0f);

	// Get the resulting matrix from OpenGL it will have our
	// direction vector in the 3rd row.
	glGetFloatv(GL_MODELVIEW_MATRIX, Matrix);

	// Get the direction vector from the matrix. Element 10 must
	// be inverted!
	m_DirectionVector.i = Matrix[8];
	m_DirectionVector.j = Matrix[9];
	m_DirectionVector.k = -Matrix[10];

	// Ok erase the results of the last computation.
	glLoadIdentity();

	// Rotate the scene to get the right orientation.
	glRotatef(m_PitchDegrees, 1.0f, 0.0f, 0.0f);
	glRotatef(m_HeadingDegrees, 0.0f, 1.0f, 0.0f);

	// Scale the direction by our speed.
	v = m_DirectionVector;
	v *= m_ForwardVelocity;

	// Increment our position by the vector
	m_Position.x += v.i;
	m_Position.y += v.j;
	m_Position.z += v.k;

	// Translate to our new position.
	glTranslatef(-m_Position.x, -m_Position.y, -m_Position.z);
}

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
		if(m_PitchDegrees > 90 && m_PitchDegrees < 270 || (m_PitchDegrees < -90 && m_PitchDegrees > -270))
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
			if((m_PitchDegrees > 90 && m_PitchDegrees < 270) || (m_PitchDegrees < -90 && m_PitchDegrees > -270))
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
			if(m_PitchDegrees > 90 && m_PitchDegrees < 270 || (m_PitchDegrees < -90 && m_PitchDegrees > -270))
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

// I found this code here: http://www.markmorley.com/opengl/frustumculling.html
// and decided to make it part of
// the camera class just in case I might want to rotate
// and translate the projection matrix. This code will
// make sure that the Frustum is updated correctly but
// this member is computational expensive with:
// 82 muliplications, 72 additions, 24 divisions, and
// 12 subtractions for a total of 190 operations. Ouch!
void glCamera::UpdateFrustum()
{
    GLfloat   clip[16];
	GLfloat   proj[16];
    GLfloat   modl[16];
    GLfloat   t;

    /* Get the current PROJECTION matrix from OpenGL */
    glGetFloatv( GL_PROJECTION_MATRIX, proj );

    /* Get the current MODELVIEW matrix from OpenGL */
    glGetFloatv( GL_MODELVIEW_MATRIX, modl );

    /* Combine the two matrices (multiply projection by modelview) */
    clip[ 0] = modl[ 0] * proj[ 0] + modl[ 1] * proj[ 4] + modl[ 2] * proj[ 8] + modl[ 3] * proj[12];
    clip[ 1] = modl[ 0] * proj[ 1] + modl[ 1] * proj[ 5] + modl[ 2] * proj[ 9] + modl[ 3] * proj[13];
    clip[ 2] = modl[ 0] * proj[ 2] + modl[ 1] * proj[ 6] + modl[ 2] * proj[10] + modl[ 3] * proj[14];
    clip[ 3] = modl[ 0] * proj[ 3] + modl[ 1] * proj[ 7] + modl[ 2] * proj[11] + modl[ 3] * proj[15];

    clip[ 4] = modl[ 4] * proj[ 0] + modl[ 5] * proj[ 4] + modl[ 6] * proj[ 8] + modl[ 7] * proj[12];
    clip[ 5] = modl[ 4] * proj[ 1] + modl[ 5] * proj[ 5] + modl[ 6] * proj[ 9] + modl[ 7] * proj[13];
    clip[ 6] = modl[ 4] * proj[ 2] + modl[ 5] * proj[ 6] + modl[ 6] * proj[10] + modl[ 7] * proj[14];
    clip[ 7] = modl[ 4] * proj[ 3] + modl[ 5] * proj[ 7] + modl[ 6] * proj[11] + modl[ 7] * proj[15];

    clip[ 8] = modl[ 8] * proj[ 0] + modl[ 9] * proj[ 4] + modl[10] * proj[ 8] + modl[11] * proj[12];
    clip[ 9] = modl[ 8] * proj[ 1] + modl[ 9] * proj[ 5] + modl[10] * proj[ 9] + modl[11] * proj[13];
    clip[10] = modl[ 8] * proj[ 2] + modl[ 9] * proj[ 6] + modl[10] * proj[10] + modl[11] * proj[14];
    clip[11] = modl[ 8] * proj[ 3] + modl[ 9] * proj[ 7] + modl[10] * proj[11] + modl[11] * proj[15];

    clip[12] = modl[12] * proj[ 0] + modl[13] * proj[ 4] + modl[14] * proj[ 8] + modl[15] * proj[12];
    clip[13] = modl[12] * proj[ 1] + modl[13] * proj[ 5] + modl[14] * proj[ 9] + modl[15] * proj[13];
    clip[14] = modl[12] * proj[ 2] + modl[13] * proj[ 6] + modl[14] * proj[10] + modl[15] * proj[14];
    clip[15] = modl[12] * proj[ 3] + modl[13] * proj[ 7] + modl[14] * proj[11] + modl[15] * proj[15];

    /* Extract the numbers for the RIGHT plane */
    m_Frustum[0][0] = clip[ 3] - clip[ 0];
    m_Frustum[0][1] = clip[ 7] - clip[ 4];
    m_Frustum[0][2] = clip[11] - clip[ 8];
    m_Frustum[0][3] = clip[15] - clip[12];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[0][0] * m_Frustum[0][0] + m_Frustum[0][1] * m_Frustum[0][1] + m_Frustum[0][2] * m_Frustum[0][2] ));
    m_Frustum[0][0] /= t;
    m_Frustum[0][1] /= t;
    m_Frustum[0][2] /= t;
    m_Frustum[0][3] /= t;

    /* Extract the numbers for the LEFT plane */
    m_Frustum[1][0] = clip[ 3] + clip[ 0];
    m_Frustum[1][1] = clip[ 7] + clip[ 4];
    m_Frustum[1][2] = clip[11] + clip[ 8];
    m_Frustum[1][3] = clip[15] + clip[12];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[1][0] * m_Frustum[1][0] + m_Frustum[1][1] * m_Frustum[1][1] + m_Frustum[1][2] * m_Frustum[1][2] ));
    m_Frustum[1][0] /= t;
    m_Frustum[1][1] /= t;
    m_Frustum[1][2] /= t;
    m_Frustum[1][3] /= t;

    /* Extract the BOTTOM plane */
    m_Frustum[2][0] = clip[ 3] + clip[ 1];
    m_Frustum[2][1] = clip[ 7] + clip[ 5];
    m_Frustum[2][2] = clip[11] + clip[ 9];
    m_Frustum[2][3] = clip[15] + clip[13];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[2][0] * m_Frustum[2][0] + m_Frustum[2][1] * m_Frustum[2][1] + m_Frustum[2][2] * m_Frustum[2][2] ));
    m_Frustum[2][0] /= t;
    m_Frustum[2][1] /= t;
    m_Frustum[2][2] /= t;
    m_Frustum[2][3] /= t;

    /* Extract the TOP plane */
    m_Frustum[3][0] = clip[ 3] - clip[ 1];
    m_Frustum[3][1] = clip[ 7] - clip[ 5];
    m_Frustum[3][2] = clip[11] - clip[ 9];
    m_Frustum[3][3] = clip[15] - clip[13];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[3][0] * m_Frustum[3][0] + m_Frustum[3][1] * m_Frustum[3][1] + m_Frustum[3][2] * m_Frustum[3][2] ));
    m_Frustum[3][0] /= t;
    m_Frustum[3][1] /= t;
    m_Frustum[3][2] /= t;
    m_Frustum[3][3] /= t;

    /* Extract the FAR plane */
    m_Frustum[4][0] = clip[ 3] - clip[ 2];
    m_Frustum[4][1] = clip[ 7] - clip[ 6];
    m_Frustum[4][2] = clip[11] - clip[10];
    m_Frustum[4][3] = clip[15] - clip[14];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[4][0] * m_Frustum[4][0] + m_Frustum[4][1] * m_Frustum[4][1] + m_Frustum[4][2] * m_Frustum[4][2] ));
    m_Frustum[4][0] /= t;
    m_Frustum[4][1] /= t;
    m_Frustum[4][2] /= t;
    m_Frustum[4][3] /= t;

    /* Extract the NEAR plane */
    m_Frustum[5][0] = clip[ 3] + clip[ 2];
    m_Frustum[5][1] = clip[ 7] + clip[ 6];
    m_Frustum[5][2] = clip[11] + clip[10];
    m_Frustum[5][3] = clip[15] + clip[14];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[5][0] * m_Frustum[5][0] + m_Frustum[5][1] * m_Frustum[5][1] + m_Frustum[5][2] * m_Frustum[5][2] ));
    m_Frustum[5][0] /= t;
    m_Frustum[5][1] /= t;
    m_Frustum[5][2] /= t;
    m_Frustum[5][3] /= t;
}

// This is the much faster version of the above member 
// function, however the speed increase is not gained 
// without a cost. If you rotate or translate the projection
// matrix then this member will not work correctly. That is acceptable
// in my book considering I very rarely do such a thing.
// This function has far fewer operations in it and I 
// shaved off 2 square root functions by passing in the
// near and far values. This member has:
// 38 muliplications, 28 additions, 24 divisions, and
// 12 subtractions for a total of 102 operations. Still hurts
// but at least it is decent now. In practice this will 
// run about 2 times faster than the above function.
void glCamera::UpdateFrustumFaster()
{
	GLfloat   clip[16];
	GLfloat   proj[16];
	GLfloat   modl[16];
	GLfloat   t;

	/* Get the current PROJECTION matrix from OpenGL */
	glGetFloatv( GL_PROJECTION_MATRIX, proj );

	/* Get the current MODELVIEW matrix from OpenGL */
	glGetFloatv( GL_MODELVIEW_MATRIX, modl );

	/* Combine the two matrices (multiply projection by modelview) 
	   but keep in mind this function will only work if you do NOT
	   rotate or translate your projection matrix                  */
	clip[ 0] = modl[ 0] * proj[ 0];
    clip[ 1] = modl[ 1] * proj[ 5];
    clip[ 2] = modl[ 2] * proj[10] + modl[ 3] * proj[14];
    clip[ 3] = modl[ 2] * proj[11];

    clip[ 4] = modl[ 4] * proj[ 0];
    clip[ 5] = modl[ 5] * proj[ 5];
    clip[ 6] = modl[ 6] * proj[10] + modl[ 7] * proj[14];
    clip[ 7] = modl[ 6] * proj[11];

    clip[ 8] = modl[ 8] * proj[ 0];
    clip[ 9] = modl[ 9] * proj[ 5];
    clip[10] = modl[10] * proj[10] + modl[11] * proj[14];
    clip[11] = modl[10] * proj[11];

    clip[12] = modl[12] * proj[ 0];
    clip[13] = modl[13] * proj[ 5];
    clip[14] = modl[14] * proj[10] + modl[15] * proj[14];
    clip[15] = modl[14] * proj[11];

	/* Extract the numbers for the RIGHT plane */
	m_Frustum[0][0] = clip[ 3] - clip[ 0];
	m_Frustum[0][1] = clip[ 7] - clip[ 4];
	m_Frustum[0][2] = clip[11] - clip[ 8];
	m_Frustum[0][3] = clip[15] - clip[12];

	/* Normalize the result */
	t = GLfloat(sqrt( m_Frustum[0][0] * m_Frustum[0][0] + m_Frustum[0][1] * m_Frustum[0][1] + m_Frustum[0][2] * m_Frustum[0][2] ));
	m_Frustum[0][0] /= t;
	m_Frustum[0][1] /= t;
	m_Frustum[0][2] /= t;
	m_Frustum[0][3] /= t;

    /* Extract the numbers for the LEFT plane */
    m_Frustum[1][0] = clip[ 3] + clip[ 0];
    m_Frustum[1][1] = clip[ 7] + clip[ 4];
    m_Frustum[1][2] = clip[11] + clip[ 8];
    m_Frustum[1][3] = clip[15] + clip[12];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[1][0] * m_Frustum[1][0] + m_Frustum[1][1] * m_Frustum[1][1] + m_Frustum[1][2] * m_Frustum[1][2] ));
    m_Frustum[1][0] /= t;
    m_Frustum[1][1] /= t;
    m_Frustum[1][2] /= t;
    m_Frustum[1][3] /= t;

	/* Extract the BOTTOM plane */
    m_Frustum[2][0] = clip[ 3] + clip[ 1];
    m_Frustum[2][1] = clip[ 7] + clip[ 5];
    m_Frustum[2][2] = clip[11] + clip[ 9];
    m_Frustum[2][3] = clip[15] + clip[13];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[2][0] * m_Frustum[2][0] + m_Frustum[2][1] * m_Frustum[2][1] + m_Frustum[2][2] * m_Frustum[2][2] ));
    m_Frustum[2][0] /= t;
    m_Frustum[2][1] /= t;
    m_Frustum[2][2] /= t;
    m_Frustum[2][3] /= t;

    /* Extract the TOP plane */
    m_Frustum[3][0] = clip[ 3] - clip[ 1];
    m_Frustum[3][1] = clip[ 7] - clip[ 5];
    m_Frustum[3][2] = clip[11] - clip[ 9];
    m_Frustum[3][3] = clip[15] - clip[13];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[3][0] * m_Frustum[3][0] + m_Frustum[3][1] * m_Frustum[3][1] + m_Frustum[3][2] * m_Frustum[3][2] ));
    m_Frustum[3][0] /= t;
    m_Frustum[3][1] /= t;
    m_Frustum[3][2] /= t;
    m_Frustum[3][3] /= t;

    /* Extract the FAR plane */
    m_Frustum[4][0] = clip[ 3] - clip[ 2];
    m_Frustum[4][1] = clip[ 7] - clip[ 6];
    m_Frustum[4][2] = clip[11] - clip[10];
    m_Frustum[4][3] = clip[15] - clip[14];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[4][0] * m_Frustum[4][0] + m_Frustum[4][1] * m_Frustum[4][1] + m_Frustum[4][2] * m_Frustum[4][2] ));
    m_Frustum[4][0] /= t;
    m_Frustum[4][1] /= t;
    m_Frustum[4][2] /= t;
    m_Frustum[4][3] /= t;

    /* Extract the NEAR plane */
    m_Frustum[5][0] = clip[ 3] + clip[ 2];
    m_Frustum[5][1] = clip[ 7] + clip[ 6];
    m_Frustum[5][2] = clip[11] + clip[10];
    m_Frustum[5][3] = clip[15] + clip[14];

    /* Normalize the result */
    t = GLfloat(sqrt( m_Frustum[5][0] * m_Frustum[5][0] + m_Frustum[5][1] * m_Frustum[5][1] + m_Frustum[5][2] * m_Frustum[5][2] ));
    m_Frustum[5][0] /= t;
    m_Frustum[5][1] /= t;
    m_Frustum[5][2] /= t;
    m_Frustum[5][3] /= t;
}

// This member function checks to see if a sphere is in
// the viewing volume.  
BOOL glCamera::SphereInFrustum(glPoint p, GLfloat Radius)
{
	int i;

	// The idea here is the same as the PointInFrustum function.

	for(i = 0; i < 6; i++)
	{
		// If the point is outside of the plane then its not in the viewing volume.
		if(m_Frustum[i][0] * p.x + m_Frustum[i][1] * p.y + m_Frustum[i][2] * p.z + m_Frustum[i][3] <= -Radius)
		{
			return(FALSE);
		}
	}
	
	return(TRUE);
}

// This member fuction checks to see if a point is in
// the viewing volume.
BOOL glCamera::PointInFrustum(glPoint p)
{
	int i;

	// The idea behind this algorithum is that if the point
	// is inside all 6 clipping planes then it is inside our
	// viewing volume so we can return true.

	for(i = 0; i < 6; i++)
	{
		if(m_Frustum[i][0] * p.x + m_Frustum[i][1] * p.y + m_Frustum[i][2] * p.z + m_Frustum[i][3] <= 0)
		{
			return(FALSE);
		}
	}

    return(TRUE);
}

// This member function checks to see if a sphere is in
// the viewing volume.  
BOOL glCamera::SphereInFrustum(GLfloat x, GLfloat y, GLfloat z, GLfloat Radius)
{
	int i;

	// The idea here is the same as the PointInFrustum function.
		
	for(i = 0; i < 6; i++)
	{
		// If the point is outside of the plane then its not in the viewing volume.
		if(m_Frustum[i][0] * x + m_Frustum[i][1] * y + m_Frustum[i][2] * z + m_Frustum[i][3] <= -Radius)
		{
			return(FALSE);
		}
	}
	
	return(TRUE);
}

// This member fuction checks to see if a point is in
// the viewing volume.
BOOL glCamera::PointInFrustum(GLfloat x, GLfloat y, GLfloat z)
{
	int i;
	
	// The idea behind this algorithum is that if the point
	// is inside all 6 clipping planes then it is inside our
	// viewing volume so we can return true.

	for(i = 0; i < 6; i++)	// Loop through all our clipping planes
	{
		// If the point is outside of the plane then its not in the viewing volume.
		if(m_Frustum[i][0] * x + m_Frustum[i][1] * y + m_Frustum[i][2] * z + m_Frustum[i][3] <= 0)
		{
			return(FALSE);
		}
	}

    return(TRUE);
}

bool glCamera::IsOccluded(glPoint p)
{
  GLint viewport[4];											//space for viewport data
  GLdouble mvmatrix[16], projmatrix[16];  //space for transform matricex
	GLdouble winx, winy, winz;							//space for returned projected coords
	GLdouble flareZ;												//here we will store the transformed flare Z
	GLfloat bufferZ;												//here we will store the read Z from the buffer

	// Now we will ask OGL to project some geometry for us using the gluProject function.
	// Practically we ask OGL to guess where a point in space will be projected in our current viewport,
	// using arbitrary viewport and transform matrices we pass to the function.
	// If we pass to the function the current matrices  (retrievede with the glGet funcs)
	// we will have the real position on screen where the dot will be drawn.
	// The interesting part is that we also get a Z value back, this means that 
	// reading the REAL buffer for Z values we can discover if the flare is in front or
	// if it's occluded by some objects.


	glGetIntegerv (GL_VIEWPORT, viewport);						//get actual viewport
  glGetDoublev (GL_MODELVIEW_MATRIX, mvmatrix);			//get actual model view matrix
  glGetDoublev (GL_PROJECTION_MATRIX, projmatrix);	//get actual projiection matrix

	// this asks OGL to guess the 2d position of a 3d point inside the viewport
	gluProject(p.x, p.y, p.z, mvmatrix, projmatrix, viewport, &winx, &winy, &winz);
	flareZ = winz;

	// we read back one pixel from th depth buffer (exactly where our flare should be drawn)
	glReadPixels(winx, winy,1,1,GL_DEPTH_COMPONENT, GL_FLOAT, &bufferZ);

	// if the buffer Z is lower than our flare guessed Z then don't draw 
	// this means there is something in front of our flare
	if (bufferZ < flareZ)
		return true;
	else
		return false;
}

void glCamera::RenderLensFlare()
{
	GLfloat Length = 0.0f;

	// Draw the flare only If the light source is in our line of sight
	if(SphereInFrustum(m_LightSourcePos, 1.0f) == TRUE)
	{
		vLightSourceToCamera = m_Position - m_LightSourcePos;		// Lets compute the vector that points to the camera from
																	// the light source.

		Length = vLightSourceToCamera.Magnitude();					// Save the length we will need it in a minute

		ptIntersect = m_DirectionVector * Length;					// Now lets find an point along the cameras direction
																	// vector that we can use as an intersection point. 
																	// Lets translate down this vector the same distance
																	// that the camera is away from the light source.
		ptIntersect += m_Position;

		vLightSourceToIntersect = ptIntersect - m_LightSourcePos;	// Lets compute the vector that points to the Intersect
																	// point from the light source
		Length = vLightSourceToIntersect.Magnitude();				// Save the length we will need it later.
		vLightSourceToIntersect.Normalize();						// Normalize the vector so its unit length
		
		glEnable(GL_BLEND);											// You should already know what this does
		glBlendFunc(GL_SRC_ALPHA, GL_ONE);							// You should already know what this does
		glDisable(GL_DEPTH_TEST);									// You should already know what this does
		glEnable(GL_TEXTURE_2D);									// You should already know what this does
			
		/////////// Differenet Color Glows & Streaks /////////////////////
		//RenderBigGlow(1.0f, 1.0f, 1.0f, 1.0f, m_LightSourcePos, 1.0f);
		//RenderStreaks(1.0f, 1.0f, 0.8f, 1.0f, m_LightSourcePos, 0.7f);
		//
		//RenderBigGlow(1.0f, 0.9f, 1.0f, 1.0f, m_LightSourcePos, 1.0f);
		//RenderStreaks(1.0f, 0.9f, 1.0f, 1.0f, m_LightSourcePos, 0.7f);
		//////////////////////////////////////////////////////////////////


		//########################## NEW STUFF ##################################

		if (!IsOccluded(m_LightSourcePos))	//Check if the center of the flare is occluded
		{
			// Render the large hazy glow
			RenderBigGlow(0.60f, 0.60f, 0.8f, 1.0f, m_LightSourcePos, 16.0f);
			// Render the streaks
			RenderStreaks(0.60f, 0.60f, 0.8f, 1.0f, m_LightSourcePos, 16.0f);
			// Render the small Glow
			RenderGlow(0.8f, 0.8f, 1.0f, 0.5f, m_LightSourcePos, 3.5f);

			pt = vLightSourceToIntersect * (Length * 0.1f);				// Lets compute a point that is 20%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.9f, 0.6f, 0.4f, 0.5f, pt, 0.6f);				// Render the small Glow

			pt = vLightSourceToIntersect * (Length * 0.15f);			// Lets compute a point that is 30%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.		
		
			RenderHalo(0.8f, 0.5f, 0.6f, 0.5f, pt, 1.7f);				// Render the a Halo
		
			pt = vLightSourceToIntersect * (Length * 0.175f);			// Lets compute a point that is 35%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderHalo(0.9f, 0.2f, 0.1f, 0.5f, pt, 0.83f);				// Render the a Halo

			pt = vLightSourceToIntersect * (Length * 0.285f);			// Lets compute a point that is 57%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderHalo(0.7f, 0.7f, 0.4f, 0.5f, pt, 1.6f);				// Render the a Halo
		
			pt = vLightSourceToIntersect * (Length * 0.2755f);			// Lets compute a point that is 55.1%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.9f, 0.9f, 0.2f, 0.5f, pt, 0.8f);				// Render the small Glow

			pt = vLightSourceToIntersect * (Length * 0.4775f);			// Lets compute a point that is 95.5%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.93f, 0.82f, 0.73f, 0.5f, pt, 1.0f);			// Render the small Glow
		
			pt = vLightSourceToIntersect * (Length * 0.49f);			// Lets compute a point that is 98%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderHalo(0.7f, 0.6f, 0.5f, 0.5f, pt, 1.4f);				// Render the a Halo

			pt = vLightSourceToIntersect * (Length * 0.65f);			// Lets compute a point that is 130%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.7f, 0.8f, 0.3f, 0.5f, pt, 1.8f);				// Render the small Glow
		
			pt = vLightSourceToIntersect * (Length * 0.63f);			// Lets compute a point that is 126%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.4f, 0.3f, 0.2f, 0.5f, pt, 1.4f);				// Render the small Glow

			pt = vLightSourceToIntersect * (Length * 0.8f);				// Lets compute a point that is 160%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderHalo(0.7f, 0.5f, 0.5f, 0.5f, pt, 1.4f);				// Render the a Halo
		
			pt = vLightSourceToIntersect * (Length * 0.7825f);			// Lets compute a point that is 156.5%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.8f, 0.5f, 0.1f, 0.5f, pt, 0.6f);				// Render the small Glow

			pt = vLightSourceToIntersect * (Length * 1.0f);				// Lets compute a point that is 200%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderHalo(0.5f, 0.5f, 0.7f, 0.5f, pt, 1.7f);				// Render the a Halo
		
			pt = vLightSourceToIntersect * (Length * 0.975f);			// Lets compute a point that is 195%
			pt += m_LightSourcePos;										// away from the light source in the
																	// direction of the intersection point.
		
			RenderGlow(0.4f, 0.1f, 0.9f, 0.5f, pt, 2.0f);				// Render the small Glow

		}
		glDisable(GL_BLEND );										// You should already know what this does
		glEnable(GL_DEPTH_TEST);									// You should already know what this does
		glDisable(GL_TEXTURE_2D);									// You should already know what this does
	}
}

void glCamera::RenderHalo(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale)
{
	glPoint q[4];
	
	// Basically we are just going to make a 2D box
	// from four points we don't need a z coord because
	// we are rotating the camera by the inverse so the 
	// texture mapped quads will always face us.
	q[0].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[0].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[1].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[1].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	q[2].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[2].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[3].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[3].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	glPushMatrix();													// Save the model view matrix
	glTranslatef(p.x, p.y, p.z);									// Translate to our point
	glRotatef(-m_HeadingDegrees, 0.0f, 1.0f, 0.0f);
	glRotatef(-m_PitchDegrees, 1.0f, 0.0f, 0.0f);
	glBindTexture(GL_TEXTURE_2D, m_HaloTexture);					// Bind to the Big Glow texture
	glColor4f(r, g, b, a);											// Set the color since the texture is a gray scale
	
	glBegin(GL_TRIANGLE_STRIP);										// Draw the Big Glow on a Triangle Strip
		glTexCoord2f(0.0f, 0.0f);					
		glVertex2f(q[0].x, q[0].y);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(q[1].x, q[1].y);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(q[2].x, q[2].y);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(q[3].x, q[3].y);
	glEnd();										
	glPopMatrix();													// Restore the model view matrix
}

void glCamera::RenderGlow(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale)
{
	glPoint q[4];
	
	// Basically we are just going to make a 2D box
	// from four points we don't need a z coord because
	// we are rotating the camera by the inverse so the 
	// texture mapped quads will always face us.
	q[0].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[0].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.

	q[1].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[1].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	q[2].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[2].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[3].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[3].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	glPushMatrix();													// Save the model view matrix
	glTranslatef(p.x, p.y, p.z);									// Translate to our point
	glRotatef(-m_HeadingDegrees, 0.0f, 1.0f, 0.0f);
	glRotatef(-m_PitchDegrees, 1.0f, 0.0f, 0.0f);
	glBindTexture(GL_TEXTURE_2D, m_GlowTexture);					// Bind to the Big Glow texture
	glColor4f(r, g, b, a);											// Set the color since the texture is a gray scale
	
	glBegin(GL_TRIANGLE_STRIP);										// Draw the Big Glow on a Triangle Strip
		glTexCoord2f(0.0f, 0.0f);					
		glVertex2f(q[0].x, q[0].y);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(q[1].x, q[1].y);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(q[2].x, q[2].y);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(q[3].x, q[3].y);
	glEnd();										
	glPopMatrix();													// Restore the model view matrix
}

void glCamera::RenderBigGlow(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale)
{
	glPoint q[4];
	
	// Basically we are just going to make a 2D box
	// from four points we don't need a z coord because
	// we are rotating the camera by the inverse so the 
	// texture mapped quads will always face us.
	q[0].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[0].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[1].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[1].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	q[2].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[2].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[3].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[3].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	glPushMatrix();													// Save the model view matrix
	glTranslatef(p.x, p.y, p.z);									// Translate to our point
	glRotatef(-m_HeadingDegrees, 0.0f, 1.0f, 0.0f);
	glRotatef(-m_PitchDegrees, 1.0f, 0.0f, 0.0f);
	glBindTexture(GL_TEXTURE_2D, m_BigGlowTexture);					// Bind to the Big Glow texture
	glColor4f(r, g, b, a);											// Set the color since the texture is a gray scale
	
	glBegin(GL_TRIANGLE_STRIP);										// Draw the Big Glow on a Triangle Strip
		glTexCoord2f(0.0f, 0.0f);					
		glVertex2f(q[0].x, q[0].y);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(q[1].x, q[1].y);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(q[2].x, q[2].y);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(q[3].x, q[3].y);
	glEnd();										
	glPopMatrix();													// Restore the model view matrix
}

void glCamera::RenderStreaks(GLfloat r, GLfloat g, GLfloat b, GLfloat a, glPoint p, GLfloat scale)
{
	glPoint q[4];
	
	// Basically we are just going to make a 2D box
	// from four points we don't need a z coord because
	// we are rotating the camera by the inverse so the 
	// texture mapped quads will always face us.
	q[0].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[0].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[1].x = (p.x - scale);											// Set the x coordinate -scale units from the center point.
	q[1].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	q[2].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[2].y = (p.y - scale);											// Set the y coordinate -scale units from the center point.
		
	q[3].x = (p.x + scale);											// Set the x coordinate scale units from the center point.
	q[3].y = (p.y + scale);											// Set the y coordinate scale units from the center point.
		
	glPushMatrix();													// Save the model view matrix
	glTranslatef(p.x, p.y, p.z);									// Translate to our point
	glRotatef(-m_HeadingDegrees, 0.0f, 1.0f, 0.0f);
	glRotatef(-m_PitchDegrees, 1.0f, 0.0f, 0.0f);
	glBindTexture(GL_TEXTURE_2D, m_StreakTexture);					// Bind to the Big Glow texture
	glColor4f(r, g, b, a);											// Set the color since the texture is a gray scale
	
	glBegin(GL_TRIANGLE_STRIP);										// Draw the Big Glow on a Triangle Strip
		glTexCoord2f(0.0f, 0.0f);					
		glVertex2f(q[0].x, q[0].y);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(q[1].x, q[1].y);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(q[2].x, q[2].y);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(q[3].x, q[3].y);
	glEnd();										
	glPopMatrix();													// Restore the model view matrix
}
