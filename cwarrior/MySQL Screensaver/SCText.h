//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: TSCText.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _SCTEXT_H_
#define _SCTEXT_H_

#include "SCString.h"
#ifdef __BORLANDC__
#include "Timer"
#else
#endif

//a list of constant identifier that can be shuffled to place the text differently
//on the screen. Currently, only random position is supported
#define FIND_RANDOM_POSITION 0x0

class TSCText
{
	private:
   	//a reference to the target window
   	TGLWindow* Window;
      //and the font used to draw this text
      TFont* Font;

      //is this text looping? is it being displayed?
      bool Loop, Running;

   public:
   	//a list of strings/line that make up the text
   	std::vector<TSCString*>Line;

   	TSCText();
   	TSCText(TGLWindow * pWindow, TFont * pFont);

		void AddLine(const char * pText, int pDelay, TVector3f pColor, TVector3f pScale, TVector3f pCharacterSpacingScale);
      void Render();
      void Iterate();

      void AddKeyframe(FUNC_CharacterEffectFunc pFunc);

		int GetLength();
      void Parse(const char * pText);

		void Start();
      void Stop();
      void SetLoop(bool pValue);
};

#endif