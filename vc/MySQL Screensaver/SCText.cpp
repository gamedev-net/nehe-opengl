//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: SSCText.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "SCText.h"
#include "Main.h"

TSCText::TSCText()
{
	Loop = true;
   Running = false;
}

TSCText::TSCText(TGLWindow * pWindow, TFont * pFont)
{
	Window = pWindow;
   Font = pFont;
   Loop = true;
   Running = false;
}

//start displaying the text
void TSCText::Start()
{
	Running = true;
}

//stop displaying the text
void TSCText::Stop()
{
	Running = false;
}

//set looping/not looping
void TSCText::SetLoop(bool pValue)
{
	Loop = pValue;
}

//get the length of the text (the number of characters in it)
int TSCText::GetLength()
{
	int Size = 0;

   //loop through all lines in the text and count the characters
	for(int i = 0; i < Line.size(); i++)
   	Size += Line[i]->Length();

   return Size;
}

//find the length of a string in screen units
float FindStringLength(TGLWindow * pWindow, const char * pText)
{
	float Length = 0.0f;

   float* w = new float[256];

   //get the widths of all characters in the currently used character set
	GetCharWidthFloat(pWindow->DC(), 0, 255, w);

   //add the widths of individual characters based on the characters in the string
	for(unsigned i = 0; i < strlen(pText); i++)
     	Length += w[pText[i]];

	return Length;
}

//add a line to the text
void TSCText::AddLine(const char * pText, int pDelay, TVector3f pColor, TVector3f pScale, TVector3f pCharacterSpacingScale)
{
	static TVector3f Position;
   static float Length, FreeWidth, FreeHeight, Depth;

   //add a multiplier to normalize the result
   Length = FindStringLength(Window, pText) * 3;

   if(pScale.x > 1)
   	Length *= pScale.x;

   Depth = 15/*default depth*/ + 5/*added depth*/;
   FreeWidth = Depth - Length;

   //finds a random position on the screen so that the line doesn't clip
   //outside
  	Position.x = (random((int)(FreeWidth * 100) / 100.f)) - ((int)Depth >> 1);
  	Position.y = -Depth / 3.f + (random((int)((Depth * 2) / 3.f) * 100) / 100.f);
   Position.z = -5;

	Line.push_back(new TSCString(Window, Font, this, GetAppTime(), pText, Position, pDelay, pColor, pScale, pCharacterSpacingScale));
}

//render the text
void TSCText::Render()
{
	//if the text isn't being displayed, return
	if(!Running)
   	return;

   //render each line individually
	for(int i = 0; i < Line.size(); i++)
   	Line[i]->Render();
}

//iterating the TSCText class hierarchically iterates
//all strings (or lines) in the text which in turn
//iterate all characters in themselves
void TSCText::Iterate()
{
	//if the text is "running", or more appropriately:
   //if it is being displayed at this moment (which
   //means that at least some of the lines in the text
   //have not finished displaying)
	if(!Running)
   	return;

   //iterate all lines in the text
    int i;
	for(i = 0; i < Line.size(); i++)
   	Line[i]->Iterate();

   //check if ANY of the lines are still being displayed;
   //if so, bail out early, leaving the entire text
   //running
	for(i = 0; i < Line.size(); i++)
   	if(Line[i]->Running)
      	return;

   //is the text looping?
	if(Loop)
   	{
      //we are here because the text is looping and all the
      //lines have been displayed - in other words it is time
      //to reset them and start from the top
		for(i = 0; i < Line.size(); i++)
      	//feed each line a new starting time
   		Line[i]->Reset(GetAppTime());
      }
   else
   	//if we're not looping and everything has been displayed,
      //just stop
		Running = false;
}

void TSCText::AddKeyframe(FUNC_CharacterEffectFunc pFunc)
{
	for(int i = 0; i < Line.size(); i++)
   	Line[i]->AddCharacterKeyframe(pFunc);
}

void TSCText::Parse(const char * pText)
{
   //some tokes are expected that are treated a little differently;
   //first of all: bind some color to the poem itself (the body text)
   //secondly: bind some color to the autor line and the name

   //these two lines define two colors from (0.5, 0.5, 0.5) to (1, 1, 1)
   TVector3f BodyColor = TVector3f((random(128) + 128) / 256.f, (random(128) + 128) / 256.f, (random(128) + 128) / 256.f);
   TVector3f HeaderColor = TVector3f((random(128) + 128) / 256.f, (random(128) + 128) / 256.f, (random(128) + 128) / 256.f);


   char* NewText = NULL;

	//get the first token up to a newline and store a pointer to it in NewText
	if((NewText = strtok((char*)pText, "\n")) == NULL)
   	return;

   //make a custom-sized separator line (an empty line) that follows this logic:
   //the length of the line is at point zero if T = 200 each 5 milliseconds below
   //it adds another space, each 50 milliseconds over it, removes one. At T = 200
   //there are 10 whitesapces in the string. Don't ask why this has to bo so fancy :)
	int P = 10;

   T >= 200 ? P += (T - 200) / 50.f : P += (200 - T) / 5.f;
   char* WhiteString = new char[P];
   memset(WhiteString, ' ', P);
   WhiteString[P] = '\0';

   do
   	{
#ifndef __BORLANDC__
#pragma warning (disable: 4305) // warning C4305: 'argument' : truncation from 'const double' to 'float'
#endif
      //if the first character of the current token is the XOR-character
		if(NewText[0] == '^')
      	//create an empty line
		   AddLine(WhiteString, GetLength() * T, BodyColor, TVector3f(.6, .6, .6), TVector3f(.8, .8, .8));
      //if it's the name of the poem (strstr() checks of the first argument string contains the second)
      else if(strstr(NewText, "TOKEN_NAME:"))
      	//skip the first 11 characters that are taken up by "TOKEN_NAME:";
         //GetLength() * T is the length of the text so far (in characters) multiplied by the "chacater time" T -
         //in effect this means that if there is one 20-byte line in this text already and T = 75 then the
         //this parameter will become 20 * 75 = 1500 milliseconds, or 1.5 seconds must elapse before this line
         //is displayed
		   AddLine(&NewText[11], GetLength() * T, HeaderColor, TVector3f(4, 4, 4), TVector3f(1.1, 1.1, 1.1));
      //if it's the author's name
      else if(strstr(NewText, "TOKEN_AUTHOR:"))
		   AddLine(&NewText[13], GetLength() * T, HeaderColor, TVector3f(2.4, 2.4, 2.4), TVector3f(1.2, 1.2, 1.2));
      //or finally, if it's just another line
      else
		   AddLine(NewText, GetLength() * T, BodyColor, TVector3f(.6, .6, .6), TVector3f(.8, .8, .8));
#ifndef __BORLANDC__
#pragma warning (default: 4305)
#endif
      }
      //get the next token
	   while((NewText = strtok(NULL, "\n")) != NULL);
}
