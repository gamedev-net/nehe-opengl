//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: SCCharacter.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _SCCHARACTER_H_
#define _SCCHARACTER_H_

#include "Effect.h"
#include "SCOpenGL.h"
#include "TGLWindow.h"

//our _very_ basic vector class
class TVector3f
{
	//all class members are private by default
   public:
		float x, y, z;

  		TVector3f() { };

		TVector3f(float pX, float pY, float pZ) : x(pX), y(pY), z(pZ) { }
};

class TSCCharacter : public TSCTextEffect
{
	public:
   	unsigned char Char;

   public:
   	TSCCharacter();
		TSCCharacter(unsigned char pChar, int pDelay, float pLength, unsigned long pTime);

      void Render();
      int Next();
      void AddKeyframe();

      TFont* Font;
      TGLWindow* Window;

      float Alpha;
      TVector3f Color, BaseColor;
   	TVector3f Pos;
   	TVector3f DefPos;
   	TVector3f Scale, BaseScale;
};

#endif