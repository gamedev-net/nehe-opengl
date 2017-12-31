//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: SCCharacter.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "SCCharacter.h"

TSCCharacter::TSCCharacter()
{
}

TSCCharacter::TSCCharacter(unsigned char pChar, int pDelay, float pLength, unsigned long pTime)
	: TSCTextEffect(pDelay, pLength, pTime)
{
   Char = pChar;
   Keyframe = 0;
}

//imcrements the character's keyframe (rotating it, eg it runs from
//0 to NumKeyframes and then goes back to 0)
int TSCCharacter::Next()
{
	if(++Keyframe > NumKeyframes)
   	Keyframe = 0;

   return Keyframe;
}

//adds a new keyframe
void TSCCharacter::AddKeyframe()
{
	NumKeyframes++;
}

void TSCCharacter::Render()
{
	//render the character
	glTranslatef(Pos.x, Pos.y, Pos.z);
   glColor4f(Color.x, Color.y, Color.z, Alpha);
 	glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

   glScalef(Scale.x, Scale.y, Scale.z);
   //print it through the window, using our only font
  	Window->Print((TGLFont*)Font, "%s", Char);
}
