// glHeightMap.cpp: implementation of the glHeightMap class.
//
//////////////////////////////////////////////////////////////////////

#include "glHeightMap.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

glHeightMap::glHeightMap()
{
	m_Texture = 0;
	m_Left = -(MAP_SIZE / 2);
	m_Right = MAP_SIZE / 2;
	m_Front = MAP_SIZE / 2;
	m_Back = -(MAP_SIZE / 2);
	m_HeightOffset = 128.0;
	m_ScaleValue = 12.0f;
}

glHeightMap::~glHeightMap()
{

}

bool glHeightMap::LoadRawFile(const char *strName, int nSize)
{
	FILE *pFile = NULL;

	// Open The File In Read / Binary Mode.
	pFile = fopen( strName, "rb" );

	// Check To See If We Found The File And Could Open It
	if ( pFile == NULL )	
	{
		// Display Error Message And Stop The Function
		return(false);
	}

	fread( m_HeightMap, 1, nSize, pFile );

	// After We Read The Data, It's A Good Idea To Check If Everything Read Fine
	int result = ferror( pFile );

	// Check If We Received An Error
	if (result)
	{
		return(false);
	}

	// Close The File.
	fclose(pFile);
	
	return(true);
}

GLfloat glHeightMap::GetHeight(GLfloat X, GLfloat Y)
{
	int x = int(X + (MAP_SIZE / 2)) % MAP_SIZE;								// Error Check Our x Value
	int y = int(Y + (MAP_SIZE / 2)) % MAP_SIZE;								// Error Check Our y Value

	if(!m_HeightMap) return 0;							// Make Sure Our Data Is Valid
	if(x >= 0 && x <= MAP_SIZE && y >= 0 && y <= MAP_SIZE)
	{
		return m_HeightMap[x + (y << 10)];
	}
	else
	{
		return(0.0f);
	}
}

bool glHeightMap::SetVertexColor(GLfloat x, GLfloat y)
{
	if(!m_HeightMap) return(false);								// Make Sure Our Height Data Is Valid

	GLfloat fColor = GLfloat((GetHeight(x, y ) / 256.0f) + 0.15);

	// Assign This Blue Shade To The Current Vertex
	glColor4f(fColor, fColor, fColor, 1.0f);

	return(true);
}

void glHeightMap::DrawHeightMap(void)
{
	GLfloat X = 0, Y = 0;									// Create Some Variables To Walk The Array With.
	GLfloat Heights[4];
	GLfloat Color[4];
	
	if(!m_HeightMap) return;							// Make Sure Our Height Data Is Valid

	if(m_Texture)
	{
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, m_Texture);
	}

	glBegin(GL_QUADS);
	for ( X = m_Left; X < m_Right; X += GLfloat(STEP_SIZE) )
	{
		for ( Y = m_Back; Y < m_Front; Y += GLfloat(STEP_SIZE) )
		{
			Heights[0] = GetHeight(X, Y);
			Heights[1] = GetHeight(X, Y + STEP_SIZE);
			Heights[2] = GetHeight(X + STEP_SIZE, Y + STEP_SIZE);
			Heights[3] = GetHeight(X + STEP_SIZE, Y);

			// Set the vertex color
			GetVertexColor(X, Y, Color);
			glColor4fv(Color);
		
			if(m_Texture) { glTexCoord2f(0.0f, 0.0f); }
			// Get The (X, Y, Z) Value For The Bottom Left Vertex
			glVertex3f( GLfloat(X),							
						Heights[0] - m_HeightOffset,	
						GLfloat(Y));
			
			// Set the vertex color
			GetVertexColor(X, Y + STEP_SIZE, Color);
			glColor4fv(Color);
		
			if(m_Texture) {	glTexCoord2f(0.0f, 1.0f); }
			// The (X, Y, Z) Value For The Top Left Vertex
			glVertex3f( GLfloat(X),
						Heights[1] - m_HeightOffset,
						GLfloat(Y + STEP_SIZE));
			
			// Set the vertex color
			GetVertexColor(X + STEP_SIZE, Y + STEP_SIZE, Color);
			glColor4fv(Color);

			if(m_Texture) {	glTexCoord2f(1.0f, 1.0f); }
			// Get The (X, Y, Z) Value For The Top Right Vertex
			glVertex3f( GLfloat(X + STEP_SIZE), 
						Heights[2] - m_HeightOffset,
						GLfloat(Y + STEP_SIZE));

			// Set the vertex color
			GetVertexColor(X + STEP_SIZE, Y, Color);
			glColor4fv(Color);

			if(m_Texture) {	glTexCoord2f(1.0f, 0.0f); }
			// Get The (X, Y, Z) Value For The Bottom Right Vertex
			glVertex3f( GLfloat(X + STEP_SIZE), 
						Heights[3] - m_HeightOffset,
						GLfloat(Y));
		}
	}
	glEnd();

	if(m_Texture != 0)
	{
		glDisable(GL_TEXTURE_2D);
	}
}

void glHeightMap::GetVertexColor(GLfloat x, GLfloat y, GLfloat *col)
{
	if(!col) return;
	
	GLfloat fColor = GLfloat((GetHeight(x, y ) / 256.0f) + 0.20);

	// Assign This Blue Shade To The Current Vertex
	col[0] = fColor;
	col[1] = fColor;
	col[2] = fColor;
	col[3] = 1.0f;
}

bool glHeightMap::LoadTexture(const char *Filename)
{
	FILE *File=NULL;									// File Handle
	AUX_RGBImageRec *TextureImage[1];					// Create Storage Space For The Texture

	memset(TextureImage,0,sizeof(void *)*1);           	// Set The Pointer To NULL

	if (!Filename)										// Make Sure A Filename Was Given
	{
		return(false);									// If Not Return NULL
	}

	File=fopen(Filename,"r");							// Check To See If The File Exists

	if (File) {											// Does The File Exist?
		fclose(File);									// Close The Handle
		TextureImage[0] = auxDIBImageLoad(Filename);				// Load The Bitmap And Return A Pointer
	}
	else {
		return(false);
	}

	if(TextureImage[0] != NULL)	{
		glGenTextures(1, &m_Texture);					// Create The Texture

		// Typical Texture Generation Using Data From The Bitmap
		glBindTexture(GL_TEXTURE_2D, m_Texture);
		glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[0]->sizeX, TextureImage[0]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[0]->data);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}
	else {
		return(false);
	}

	if (TextureImage[0])									// If Texture Exists
	{
		if (TextureImage[0]->data)							// If Texture Image Exists
		{
			free(TextureImage[0]->data);					// Free The Texture Image Memory
		}
		else {
			return(false);
		}

		free(TextureImage[0]);								// Free The Image Structure
	}
	else {
		return(false);
	}

	return(true);
}
