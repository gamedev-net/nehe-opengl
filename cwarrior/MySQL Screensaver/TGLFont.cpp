//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: TGLFont.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "TGLFont.h"

//our font base class - a very rudimentary groundwork for the TGLFont class

TFont::TFont(LOGFONT pFont)
{
	LogFont = pFont;
   Target = NULL;
   Build();
}

TFont::TFont(TFont * pFont)
{
	*this = *pFont;
}

HFONT TFont::GetFont()
{
	return Font;
}

HFONT TFont::Build()
{
	Target = NULL;
   return(Font = CreateFontIndirect(&LogFont));
}









TGLFont::TGLFont(TFont * pFont)
	: TFont(pFont), Extrusion(0.1f), Deviation(0.0f), Type(WGL_FONT_POLYGONS)
{
	AcquireBase();
}

TGLFont::~TGLFont()
{
	//delete the currently allocated display list
	glDeleteLists(Base, 96);
}

void TGLFont::AcquireBase()
{
	//create a new 96-character display list
	Base = glGenLists(96);
}

GLuint TGLFont::GetBase()
{
	return Base;
}

GLuint TGLFont::GetType()
{
	return Type;
}

GLfloat TGLFont::GetExtrusion()
{
	return Extrusion;
}

GLfloat TGLFont::GetDeviation()
{
	return Deviation;
}

void TGLFont::ModifyType(GLuint pType)
{
	Type = pType;
   Target = NULL;
}

void TGLFont::SetExtrusion(GLfloat pExtrusion)
{
	Extrusion = pExtrusion;
}

GLYPHMETRICSFLOAT* TGLFont::GetGlyphMetrics()
{
	return gmf;
}

//setting the target of the font allows us to apply the font to several
//windows (us it in many OpenGL windows without having to create a new
//TGLFont for each one of them)
void TGLFont::SetTarget(TGLWindow * pWindow)
{
	//select the font into the device context of the currently targeted window
	SelectObject(pWindow->DC(), GetFont());

   //create the OpenGL side of the font
   wglUseFontOutlines(pWindow->DC(), 0, 255,	Base,
   					 Deviation, Extrusion, Type, gmf);

	//memorize the target window
   Target = pWindow->GetHandle();
}

HWND TGLFont::GetTarget()
{
	return Target;
}

void TGLFont::Update()
{
	Target = NULL;
}


