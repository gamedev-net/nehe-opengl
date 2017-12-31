//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: Effect.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "Effect.h"

#ifndef __BORLANDC__
#include <math.h>  // for sin, cos
#endif

TSCTextEffect::TSCTextEffect()
{
}

TSCTextEffect::TSCTextEffect(int pDelay, float pLength, unsigned long pTime)
{
	//set the necessary parameters(add a one second delay for the entire text)
	Delay = BaseDelay = pDelay + 1000;
   Length = BaseLength = pLength;
   LastTime = pTime;
   //initially the text is active (it hasn't been displayed yet), but not
   //running (it's not being displayed just yet)
   Active = false;
   Running = true;
	NumKeyframes = 0;
	Reset();
}

void TSCTextEffect::Reset()
{
	//reset the text's internal tracker
	Tracker = 0;
}

float TSCTextEffect::Track(unsigned long pTime)
{
	static float Time;

   //if the text has finished up being displayed, bail out
   if(!Running)
   	return 0;

   //if it's not active or the tracker is not zero
	if(!Active || Tracker >= 1)
   	{
      //check if Delay milliseconds have passed
   	if(pTime - LastTime >= (unsigned)Delay)
      	{
         //if there have, start displaying the text
      	Active = true;
			Running = true;
	      LastTime = pTime;
         Reset();
         }
      }
   else
   	{
      //otherwise just increment the tracker, normalizing it to
      //[0, 1]
      Tracker += (pTime - LastTime) / Length;
  	   LastTime = pTime;
      }

   //return the new internal time
   return Tracker;
}






#include "SCCharacter.h"
#include "SCText.h"
#include "Main.h"

//one radian in degrees: Pi/180
#define RADIAN .01745329251994329f

//there are two functions that give the text a living look - a fade in and a fade
//out function. These are called SwoopIn() and SwoopOut(), respectively. They both
//take a character object and its parent text object as parameters and interpolate
//the character based on the keyframe value.

void SwoopIn(TSCCharacter * pChar, TSCText * pText)
{
	//if the character passed in isn't being displayed or has already been displayed,
   //do nothing
   if(!pChar->Running || !pChar->Active)
   	return;

   //if the character's tracker is non-zero
   if(pChar->Tracker >= 1)
    	{
      //increment the character's keyframe
      pChar->Next();

      //number of milliseconds over which the character fades completely out.
      //This parameter is necessary for SwoopOut()
		pChar->Length = 2000;
      pChar->Reset();
      }
   else
   	{
      //since the tracker is always running from 0 to 1, use its value as the alpha
      //for the character
   	pChar->Alpha = pChar->Tracker;

      //if there scatter has been enabled from the config dialog
      if(Scatter > 0)
      	{
         //incorporate it in the position calculations
	   	pChar->Pos.x += sin(pChar->Tracker * 180 * RADIAN) * .125 * Scatter / T;
		   pChar->Pos.y += cos(pChar->Tracker * 180 * RADIAN) * .125 * Scatter / T;
         }
      else
      	{
	   	pChar->Pos.x += sin(pChar->Tracker * 180 * RADIAN) / T;
		   pChar->Pos.y += cos(pChar->Tracker * 180 * RADIAN) / T;
         }
      }
}

void SwoopOut(TSCCharacter * pChar, TSCText * pText)
{
   if(!pChar->Running || !pChar->Active)
   	return;

   if(pChar->Tracker >= 1)
   	{
		pChar->Running = false;
		pChar->Active = false;

      //reset the character's color and scale
    	pChar->Color = pChar->BaseColor;
      pChar->Scale = pChar->BaseScale;

      //place it back to its original position
      pChar->Pos = pChar->DefPos;

      //set a new delay for it: when a character finishes being displayed,
      //in pText->GetLength() * T it will have to be displayed again - this
      //applies when the text is repeating
   	pChar->Delay = pText->GetLength() * T;
      }
   else
   	{
      //we're fading out - invert the alpha value
   	pChar->Alpha = 1 - pChar->Tracker;

		if(Scatter > 0)
      	{
		  	pChar->Pos.x += -sin(( pChar->Tracker) * 180 * RADIAN) * .125 * Scatter / T * .5;
	   	pChar->Pos.y += -cos(( pChar->Tracker) * 180 * RADIAN) * .125 * Scatter / T;
         }
		else
      	{
		  	pChar->Pos.x += -sin((pChar->Tracker) * 180 * RADIAN) / T * .5;
	   	pChar->Pos.y += -cos((pChar->Tracker) * 180 * RADIAN) / T;
         }
   	}
}


