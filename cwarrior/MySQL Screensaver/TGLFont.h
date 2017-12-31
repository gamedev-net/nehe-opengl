//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: TGLFont.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _TGLFONT_H_
#define _TGLFONT_H_

#ifdef __BORLANDC__
#include <windows>
#else
#include <windows.h>
#endif
#include "gl.h"
#include "glu.h"
#include "TGLWindow.h"

class TGLWindow;

//this is the base class that TGLFont is built on - it contains some
//basic variables and functions to set up a font
class TFont
{
	protected:
   	HFONT Font;
      LOGFONT LogFont;
      HWND Target;

   public:
   	TFont(LOGFONT pFont);
   	TFont(TFont * pFont);

      HFONT GetFont();

      HFONT Build();
};

//based on TFont, this font class is geared towards OpenGL and contains all of the
//necessary functions (except the draw/render function which is contained in TGLWindow)
//to maintain a proper outline font object
class TGLFont : public TFont
{
	private:
   	GLuint Base;
      GLfloat Deviation;
      GLfloat Extrusion;
      GLuint Type;

		GLYPHMETRICSFLOAT gmf[256];

   public:
   	TGLFont(TFont * pFont);

      ~TGLFont();

      void AcquireBase();

      GLuint GetBase();
      GLuint GetType();
      GLfloat GetExtrusion();
      GLfloat GetDeviation();

      void ModifyType(GLuint pType);

      void SetExtrusion(GLfloat pExtrusion);

		GLYPHMETRICSFLOAT* GetGlyphMetrics();

      void SetTarget(TGLWindow * pWindow);

      HWND GetTarget();

      void Update();
};

#endif