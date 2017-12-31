//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: Main.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifdef __BORLANDC__
#include "tglwindow.h"
#include "main.h"
#include "SCText.h"
#include "def.rcd"
#include "defpoem.txt"
#include "timer.h"
#include <commctrl>
#include <windowsx>
#else
#include "tglwindow.h"
#include "main.h"
#include "SCText.h"
#include "resource.h"
#include "defpoem.txt"
#include "timer.h"
#include <commctrl.h>
#include <windowsx.h>
#endif

//see main.h for an explanation on what the below declarations are about
TGLWindow* Window;
TGLFont* Font;
TTimer* Timer;

int T;
float Scatter;
char* ServerIP;
char* Username;
char* Password;
char* Databasename;
int ServerPort;
char* QueryText;
TSCText* Txt;

//Timer->Pop() cannot be called from outside this module - that's why we're
//using a global function called GetAppTime()
unsigned long GetAppTime()
{
	return Timer->Pop();
}

//this function is the absolute minimum to which we could take the render function,
//putting all render code in objects themselves. Believe it or not, this was once
//the mighty DrawGLScene() you can see in other NeHe tutorials. Note that this
//function is called by TGLWindow, not directly from the main loop!
void DrawGLScene()
{
  	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
   glLoadIdentity();
	//iterating the text inside the draw function isn't actually that smart, but oh well...
   Txt->Iterate();
   Txt->Render();
}

//this is the system callback (check out the return type - it has WINAPI in it!)
//for the screensaver. This callback is subclassed by the main window (TGLWindow).
//Either of these instances handle different system messages - see the TGLWindow
//class for a more comprehensive explanation.
LONG WINAPI ScreenSaverWindowProc(HWND	hWnd, UINT uMsg, WPARAM wParam, LPARAM	lParam)
{
	//exit if the user presses a key or Alt + F4 (or there's some other indication
   //that the program should be terminated)
	switch(uMsg)
		{
		case WM_CLOSE:
		case WM_KEYDOWN:
			PostQuitMessage(0);
			return 0;
		}

	return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

//This function is largely taken from previous tutorials. I have removed all the comments -
//you should be able to dig your way through it on your own.
void InitializeOpenGL()
{
	glShadeModel(GL_SMOOTH);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClearDepth(1.0f);
	glClearStencil(0);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	glEnable(GL_TEXTURE_2D);

	glEnable(GL_COLOR_MATERIAL);
   glShadeModel(GL_SMOOTH);
   glColorMaterial(GL_FRONT, GL_DIFFUSE);
	glEnable(GL_LIGHTING);
}

//check out NeHe's tutorial on fonts for what the below code does
void BuildFont()
{
   LOGFONT LogFont;
	ZeroMemory(&LogFont, sizeof(LOGFONT));

   LogFont.lfHeight = 3;
   LogFont.lfWidth = 1;
	LogFont.lfWeight = FW_NORMAL;
	LogFont.lfEscapement = 0;
   LogFont.lfOrientation = 0;
	LogFont.lfItalic = false;
   LogFont.lfUnderline = false;
	LogFont.lfStrikeOut = false;
   LogFont.lfCharSet = ANSI_CHARSET;
	LogFont.lfOutPrecision = OUT_TT_PRECIS;
   LogFont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
	LogFont.lfQuality = ANTIALIASED_QUALITY;
   LogFont.lfPitchAndFamily = FF_DONTCARE | DEFAULT_PITCH;
	strcpy(LogFont.lfFaceName, "Arial");

   //create a new TGLFont object from the LOGFONT structure
   Font = new TGLFont(new TFont(LogFont));
   //we don't want the font to have extrustion
	Font->SetExtrusion(0);
   //apply it to our main window. Note that if you have several windows,
   //just set the target as needed (can be done several times during a frame)
	Font->SetTarget(Window);
}

int Mode;

enum ScreensaverModes { ModeCfg = 0x0, ModePreview, ModePwd, ModeNormal };

#ifdef __BORLANDC__
#pragma argsused
#else
#endif
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HWND Handle = NULL;

   //skip over the path (the first argument)
	char* p = strtok(GetCommandLine(), " ");

	p = strtok(NULL, " ");

   if(p != NULL)
	  	{
   	//there's a backslash or a dash here - skip over it (and any other such stuff)
		while(!isalpha(*p))
   		p++;

      //check for the argument flag
		switch(*p)
	     	{
			case 's': case 'S':
        		Mode = ModeNormal;
	         goto End;
			case 'p': case 'P':
			case 'l': case 'L':
		      Mode = ModePreview;
	         goto GetHWND;
			case 'c': case 'C':
		      Mode = ModeCfg;
	         goto GetHWND;
			case 'a': case 'A':
		      Mode = ModePwd;
	         goto GetHWND;
	      }

      GetHWND:
      	//skip over any non-digits
			while(!isdigit(*p))
       		p++;

         //now acquire the window into which we're going to be drawing later on
			Handle = (p == NULL) ? GetForegroundWindow() : (HWND)atol(p);
      End:;
      }
   else
   	Mode = ModeCfg;

   //set all OpenGL-specific stuff
   InitializeOpenGL();

   ReadRegistry();
   
   //the configuration dialog contains slider controls - we must
   //initialize Windows common controls for this module if we want
   //to be ablt to use that built-in class. Note that this library
   //could already be loaded, but we can't be sure
	InitCommonControls();

   //we will be storing the handle to the COnfiguration Dialog in
   //this variable
   int ConfigDlg;

   //now comes another important part - the initialization of the
   //screensaver in the appropriate mode
   switch(Mode)
   	{
      //if we're in preview mode, we want to create the saver in a
      //smaller window (for which we have stored the handle in Handle).
      case ModePreview:
	      RECT rc;
	      //Since we don't know the precise size of the preview window,
         //we must retrieve it
   	   GetWindowRect(Handle, &rc);
         //see the TGLWindow class for specs on this function call
			Window = new TGLWindow(Handle, NULL, ScreenSaverWindowProc,
   				 "ScreenSaverPreview","SaverPreview", 0, 0, rc.right - rc.left,
                rc.bottom - rc.top, 32, false);
         break;
      //in normal mode we do the same, but also switch to fullscreen.
      //GetSystemMetrics() with the appropriate arguments retrieves
      //the current desktop resolution
		case ModeNormal:
			Window = new TGLWindow(Handle, NULL, ScreenSaverWindowProc,
   				 "Poetic Saver", "SaverMain", 0, 0, GetSystemMetrics(SM_CXSCREEN),
                GetSystemMetrics(SM_CYSCREEN), 32, true);
         break;
      //if we must initialize in the Configuration mode, we simply
      //create the dialog box for which we have given the ID
      //DLG_SCRNSAVECONFIGURE, stored in the resource file. DialogBox()
      //is a standar WinAPI call - check it out on MSDN
   	case ModeCfg:
	      ConfigDlg = DialogBox(hInstance, MAKEINTRESOURCE(DLG_SCRNSAVECOFIGURE), Handle, ScreenSaverConfigureDialog);
      	break;
      //we don't handle password stuff! For NT Windowses, the OS does
      //it for us. For non-NT OS'es, the password must be disabled.
      case ModePwd:
			return 0;
      }

	//if we're not in configuration or password mode
   if(Mode != ModeCfg && Mode != ModePwd)
   	{
      //tell our main window that we're doing our drawing stuff in the
      //DrawGLScene function
   	Window->BindDrawFunc(DrawGLScene);
      //capture the rendering context
   	Window->Capture();

      //create a timer and reset it
   	Timer = new TTimer();
	   Timer->Push();

      //we're using a custom font
      BuildFont();

      //try to retrieve a poem from the online database
      char* Text = NULL;

      if(strlen(QueryText) > 0)
      	Text = RetrieveText();

      //if something went wrong and we don't have a poem, use the built-in one
		if(Text == NULL)
  			Text = Poem;

      //set it read to to be drawn - build a TSCText class to hold the entire
      //poem text
      Txt = new TSCText(Window, Font);
      //the poem text is formatted unsuitably for direct displaying, so parse it
   	Txt->Parse(Text);

      //we want to use two different effects, so register them
	   Txt->AddKeyframe(SwoopIn);
   	Txt->AddKeyframe(SwoopOut);
      //run the text!
	   Txt->Start();
 		}

	MSG msg;

	//you should be familiar with first part of this loop
	bool done = false;
	while(!done)
		{
		if(PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
			{
			if(msg.message == WM_QUIT)
				done = TRUE;
			else
				{
				TranslateMessage(&msg);
				DispatchMessage(&msg);
				}
			}
		else
			{
         //this is new. this means that, if we're not in config or password mode,
         //we should draw in the main window
         if(Mode != ModeCfg && Mode != ModePwd)
	         Window->Draw();
         //give the cpu some slack
         Sleep(5);
			}
		}

	return 0;
}


