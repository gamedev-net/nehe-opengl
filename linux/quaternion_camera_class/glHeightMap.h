//////////////////////////////////////////////////////////////////////
//
// glHeightMap.h: interface for the glHeightMap class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_GLHEIGHTMAP_H__92B4A3BB_D357_4A94_A2F6_AB85EC44F719__INCLUDED_)
#define AFX_GLHEIGHTMAP_H__92B4A3BB_D357_4A94_A2F6_AB85EC44F719__INCLUDED_

#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library
#include <stdio.h>


#define		MAP_SIZE			1024	// Size Of Our .RAW Height Map (NEW)
#define		STEP_SIZE			16		// Width And Height Of Each Quad (NEW)
#define		HEIGHT_RATIO		1.2f	// Ratio That The Y Is Scaled According To The X And Z (NEW)

#define BYTE unsigned char

class glHeightMap  
{
public:
	bool LoadTexture(const char *Filename);
	void GetVertexColor(GLfloat x, GLfloat y, GLfloat *col);
	bool SetVertexColor(GLfloat x, GLfloat y);
	GLfloat GetHeight(GLfloat X, GLfloat Y);
	bool LoadRawFile(const char *strName, int nSize);
	void DrawHeightMap(void);
	glHeightMap();
	virtual ~glHeightMap();
	GLfloat m_ScaleValue;

private:
	GLuint m_Texture;
	BYTE m_HeightMap[MAP_SIZE*MAP_SIZE];
	GLfloat m_Left;
	GLfloat m_Right;
	GLfloat m_Front;
	GLfloat m_Back;
	GLfloat m_HeightOffset;
};

#endif // !defined(AFX_GLHEIGHTMAP_H__92B4A3BB_D357_4A94_A2F6_AB85EC44F719__INCLUDED_)
