// Code writen by: Vic Hollis 09/07/2003
// I don't mind if you use this class in your own code. All I ask is 
// that you give me and Giuseppe D'Agata credit for it if you do.  
// And plug NeHe while your at it! :P  Thanks go to Giuseppe D'Agata
// for the code that this class is based off of. Thanks Enjoy.
//////////////////////////////////////////////////////////////////////
// glFont.cpp: implementation of the glFont class.
//////////////////////////////////////////////////////////////////////

#include "glFont.h"
#include <stdio.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

glFont::glFont()
{
	m_FontTexture = 0;												// Initalize the texture to 0
	m_ListBase = 0;													// Initalize the List base to 0
}

glFont::~glFont()
{
	if(m_FontTexture != 0) {										// If the texture is valid.
		glDeleteTextures(1, &m_FontTexture);						// delete the texture.
	}

	if(m_ListBase != 0)	{											// If the Listbase is valid
		glDeleteLists(m_ListBase,256);								// delete the list
	}
}

void glFont::SetFontTexture(GLuint tex)
{
	if(tex != 0) {													// If the texture is valid
		m_FontTexture = tex;										// Set the font texture
	}
}

void glFont::BuildFont(GLfloat Scale)
{
	float	cx;														// Holds Our X Character Coord
	float	cy;														// Holds Our Y Character Coord
	GLuint  loop;

	m_ListBase=glGenLists(256);										// Creating 256 Display Lists
	if(m_FontTexture != 0)
	{
		glBindTexture(GL_TEXTURE_2D, m_FontTexture);				// Select Our Font Texture
		for (loop=0; loop<256; loop++)								// Loop Through All 256 Lists
		{
			cx=float(loop%16)/16.0f;								// X Position Of Current Character
			cy=float(loop/16)/16.0f;								// Y Position Of Current Character

			glNewList(m_ListBase+loop,GL_COMPILE);					// Start Building A List
				glBegin(GL_QUADS);									// Use A Quad For Each Character
					glTexCoord2f(cx, 1 - cy - 0.0625f);				// Texture Coord (Bottom Left)
					glVertex2f(0,0);								// Vertex Coord (Bottom Left)
					glTexCoord2f(cx + 0.0625f, 1 - cy - 0.0625f);	// Texture Coord (Bottom Right)
					glVertex2f(16 * Scale,0);						// Vertex Coord (Bottom Right)
					glTexCoord2f(cx + 0.0625f, 1 - cy);				// Texture Coord (Top Right)
					glVertex2f(16 * Scale, 16 * Scale);				// Vertex Coord (Top Right)
					glTexCoord2f(cx, 1 - cy);						// Texture Coord (Top Left)
					glVertex2f(0, 16 * Scale);						// Vertex Coord (Top Left)
				glEnd();											// Done Building Our Quad (Character)
				glTranslated(10*Scale,0,0);							// Move To The Right Of The Character
			glEndList();											// Done Building The Display List
		}															// Loop Until All 256 Are Built
	}
}

void glFont::glPrintf(GLint x, GLint y, GLint set, const char *Format, ...)
{
	char		text[256];											// Holds Our String
	va_list		ap;													// Pointer To List Of Arguments

	if (Format == NULL)												// If There's No Text
	{
		return;														// Do Nothing
	}

	va_start(ap, Format);											// Parses The String For Variables
	    vsprintf(text, Format, ap);									// And Converts Symbols To Actual Numbers
	va_end(ap);														// Results Are Stored In Text

	if (set>1)
	{
		set=1;
	}
	
	glEnable(GL_TEXTURE_2D);										// Enable 2d Textures
	glEnable(GL_BLEND);												// Enable Blending
	glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);
	glBindTexture(GL_TEXTURE_2D, m_FontTexture);					// Select Our Font Texture
	glDisable(GL_DEPTH_TEST);										// Disables Depth Testing
	glMatrixMode(GL_PROJECTION);									// Select The Projection Matrix
	glPushMatrix();													// Store The Projection Matrix
	glLoadIdentity();												// Reset The Projection Matrix
	glOrtho(0,m_WindowWidth,0,m_WindowHeight,-1,1);					// Set Up An Ortho Screen
	glMatrixMode(GL_MODELVIEW);										// Select The Modelview Matrix
	glPushMatrix();													// Store The Modelview Matrix
	glLoadIdentity();												// Reset The Modelview Matrix
	glTranslated(x,y,0);											// Position The Text (0,0 - Bottom Left)
	glListBase(m_ListBase-32+(128*set));							// Choose The Font Set (0 or 1)
	glCallLists(strlen(text),GL_BYTE,text);							// Write The Text To The Screen
	glMatrixMode(GL_PROJECTION);									// Select The Projection Matrix
	glPopMatrix();													// Restore The Old Projection Matrix
	glMatrixMode(GL_MODELVIEW);										// Select The Modelview Matrix
	glPopMatrix();													// Restore The Old Projection Matrix
	glEnable(GL_DEPTH_TEST);
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
}

void glFont::SetWindowSize(GLint width, GLint height)
{
	m_WindowWidth = width;											// Set the window size width
	m_WindowHeight = height;										// Set the window size height
}

GLuint glFont::GetTexture()
{
	GLuint result = m_FontTexture;									// Return the currently set texture
	return(result);
}

GLuint glFont::GetListBase()
{
	GLuint result = m_ListBase;										// Return the curretnly set list base
	return(result);
}
