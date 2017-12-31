//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: SSCString.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "SCString.h"
#include "Main.h"

//the default contructor
TSCString::TSCString()
{
	Running = true;
}

TSCString::TSCString(TGLWindow * pWindow, TFont * pFont, TSCText * pParent, unsigned long pTime,
							string pString, TVector3f pS, int pBaseDelay,
                     TVector3f pColor, TVector3f pScale, TVector3f pCharacterSpacingScale)
{
	//make the string ready for displaying
	Running = true;
   //initially the string is inactive (it is activated when
   //its BaseDelay elapses)
   Active = false;

   //store the actual string contents
   TextString = pString;

   //we're using the TGLWindow->Print() procedure to output
   //the text on the screen. We therefore need a handle to
   //the window
   Window = pWindow;
   //we also need the font
   Font = pFont;
   //TSCString is a part of TSCText - store the handle to
   //daddy for later reference (see SwoopIn() and SwoopOut())
   Parent = pParent;

   //within a string, we want each character to wait before
   //becoming visible - this leaves the impression of text
   //appearing letter by letter. This is similar for TSCTeExt
   //where lines of text have to wait before they can begin
   //to appear letter by letter. BaseDelay is this time in
   //milliseconds
   BaseDelay = pBaseDelay;
   //physical visible scale vector (as applied by glScalef())
   Scale = pScale;
   //we also want to have control over character spacing
   CharacterSpacingScale = pCharacterSpacingScale;
   //our text is moving and is actually given a random position
   //on the screen
	Position = pS;
   //and a color...
   Color = pColor;

   //reset the text's timer
   Reset(pTime);
}

//add a keyframe function to the keyframe list
void TSCString::AddCharacterKeyframe(FUNC_CharacterEffectFunc pFunc)
{
	KeyframeFunc.push_back(pFunc);
}

//creates everything related to the text- namely the individual characters
//
//further references:
// - MSDN for GetCharWidthFloat()
//	  http://msdn.microsoft.com/library/default.asp?url=/library/en-us/gdi/fontext_9ltg.asp
//
//pTime is the base delay for the entire string in the TSCText object.
//Individual character delays will consider this as a starting point.
void TSCString::Build(unsigned long pTime)
{
	//the array of caracater width's
   float* w = new float[256];

   //a temp
   float q = 0;

   //get the character width values from Windows
	GetCharWidthFloat(Window->DC(), 0, 255, w);

   //for every character in this string
	for(unsigned i = 0; i < TextString.length(); i++)
   	{
      q = 0;
      //add a bew character to the array
   	Text.push_back(new TSCCharacter(TextString[i], i * T + BaseDelay, 1000.f + TextString.length() * T, pTime));

      //mess aroun with the width
		for(unsigned j = 0; j < i; j++)
      	q += w[TextString[j]] * 3;

      //and apply the spacing scale (we don't want to sapce
      //the characters too close - hence the > 1 condition)
      if(Scale.x > 1)
      	q *= Scale.x;

      //depth of 15 is a CONSTANT - it will never be changed
      Text.back()->Pos = TVector3f(Position.x + q * CharacterSpacingScale.x, Position.y + 0, Position.z + -15);
		Text.back()->DefPos = Text.back()->Pos;
      //reset all parameters
      Text.back()->Alpha = 0;
		Text.back()->AddKeyframe();
		Text.back()->Keyframe = 0;
		Text.back()->Tracker = 0;
		Text.back()->Window = Window;
		Text.back()->Font = Font;
		Text.back()->Color = Text.back()->BaseColor = Color;
		Text.back()->Scale = Text.back()->BaseScale = Scale;
      }

   //mod things up
   delete[] w;
}

//resetting a string means setting everything back to their default values
void TSCString::Reset(unsigned long pTime)
{
	//first delete all characters in the string
	for(unsigned i = 0; i < Text.size(); i++)
      delete Text[i];

   //also empty the C string itself
   Text.erase(Text.begin(), Text.end());

   //and do everything all over
   Build(pTime);

   //also do a logical reset
   Running = true;
}

//iterating the text means applying an offset of time
//that has elapsed since the last iteration to all the
//elements in the string
void TSCString::Iterate()
{
	//if this string is inactive (eg it has outlived its
   //existence - it has already haded out and is no
   //longer needed), don't do anything
	if(!Running)
   	return;

   if(!Active)
   	if(GetAppTime() > BaseDelay)
      	Active = true;

   if(!Active)
   	return;

   unsigned int i;
   //for each character
	for(i = 0; i < Text.size(); i++)
   	//if it has not finished displaying
   	if(Text[i]->Running)
      	{
         //iterate the text effect (based on time)
			Text[i]->Track(GetAppTime());
      	//apply its current keyframe function (SwoopIn() or SwoopOut())
	      KeyframeFunc[Text[i]->Keyframe](Text[i], Parent);
         }

	//check if ANY character in this string is still being displayed
	for(i = 0; i < Text.size(); i++)
   	if(Text[i]->Running)
      	return;

   //if none were, also make the string inactive
	Running = false;
}

//render ouputs the string onto the screen in its current state
void TSCString::Render()
{
	//for every character in the string
	for(unsigned i = 0; i < Text.size(); i++)
   	{
      //store our current matrix configuration
      glPushMatrix();
      //might want to enable this for a somewhat cool but slower
      //effect - adding stuff like this to the settings dialog
      //would also be kinda cool
//		glPolygonMode(GL_FRONT, GL_LINE);
		//render each character individually only if it is still
      //visible
      if(Text[i]->Running && Text[i]->Alpha > 0)
			Text[i]->Render();
      //restore the old matrix configuration
      glPopMatrix();
      }
}

//return the number of elements in this string
int TSCString::Length()
{
	return Text.size();
}
