//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: Effect.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _EFFECT_H_
#define _EFFECT_H_

class TSCTextEffect
{
	private:

   public:
   	float Tracker;
      float Length, BaseLength;
      unsigned long LastTime;
      int Delay, BaseDelay;
      bool Active;
      bool Running;
      bool Waiting;

      int NumKeyframes;
      int Keyframe;


		TSCTextEffect();
      //delay is in milliseconds and denotes the number of milliseconds that have
      //to pass befor the effect tracker starts iterating
		TSCTextEffect(int pDelay, float pLength, unsigned long pTime);

      void Reset();

      //iterates from 0 to 1 over n milliseconds
      float Track(unsigned long pTime);
};

class TSCCharacter;
class TSCText;

void SwoopIn(TSCCharacter * pChar, TSCText * pText);
void SwoopOut(TSCCharacter * pChar, TSCText * pText);

#endif