//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: SCString.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee


#ifndef _SCSTRING_H_
#define _SCSTRING_H_

#include "SCCharacter.h"
#include <vector>

class TSCString;
class TSCText;

//the function pointer prototype for the character effect functions. The two
//default ones used are SwoopIn() and SwoopOut(). Based on this prototype,
//tou can implement your own, totally different kinds of effects
typedef void(*FUNC_CharacterEffectFunc)(TSCCharacter *, TSCText *);

class TSCString
{
	public:
   	//we keep the string as a text string
   	string TextString;
      //and as individual character objects
   	std::vector<TSCCharacter*>Text;
      //a list of keyframes
      std::vector<FUNC_CharacterEffectFunc>KeyframeFunc;

      //a reference to the window in which we draw stuff
      TGLWindow* Window;
      //and the font that we use to draw out text
      TFont* Font;
      //an a reference to the text object that this string/line is a part of
      TSCText* Parent;

      //basedelay indicates the amount of time that has to pass before this
      //string is displayed
      int BaseDelay;

      TVector3f Scale, Position, Color, CharacterSpacingScale;

      void Build(unsigned long pTime);

   public:
      bool Running;
      bool Active;

		TSCString();
		TSCString(TGLWindow * pWindow, TFont * pFont,
      			 TSCText * pParent, unsigned long pTime,
                string pString, TVector3f pS, int pBaseDelay,
                TVector3f pColor, TVector3f pScale,
                TVector3f pCharacterSpacingScale);

		void AddCharacterKeyframe(FUNC_CharacterEffectFunc pFunc);

		void Iterate();
      void Render();
      void Reset(unsigned long pTime);

      int Length();
};

#endif