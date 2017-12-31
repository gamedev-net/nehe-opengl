//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: Main.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _MAIN_H_
#define _MAIN_H_

#ifdef __BORLANDC__
#include <stdio>
#include "SCOpenGL.h"
#include "TGLWindow.h"
#include <Win32\scrnsave>
#else
#include <stdio.h>
#include "SCOpenGL.h"
#include "TGLWindow.h"
#include <scrnsave.h>
#endif

//a shortcut for MessageBox()
#define WinError(a) MessageBox(0, a, "Error", MB_OK | MB_ICONERROR)

//MSVC, differently from Borland C++, doesn't support the random() function
#ifndef __BORLANDC__
#define random(a)  (rand() % (int)(a))
#endif

//our main window
extern TGLWindow* Window;
//our only font
extern TGLFont* Font;

//the amount of time in milliseconds that is meant be spent on reading
//one character (no matter which one)
extern int T;
//scatter defines how much the characters "wobble" as they move
extern float Scatter;

BOOL WINAPI ScreenSaverConfigureDialog(HWND hDlg, UINT message, UINT wParam, LONG lParam);
LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void DrawGLScene();

//data taken from the config dialog is stored in these
extern char* ServerIP;
extern char* Username;
extern char* Password;
extern char* Databasename;
extern int ServerPort;
extern char* QueryText;

//Windows Registry manipulation functions
int ReadRegistry();
void UpdateRegistry();
int RemoveRegistry();

//handles for all of the controls in the config dialog
extern HWND SpeedHandle;
extern HWND ScatterHandle;
extern HWND ScatterLEDHandle;
extern HWND SpeedLEDHandle;
extern HWND ServerIPHandle;
extern HWND ServerPortHandle;
extern HWND DatabaseNameHandle;
extern HWND UsernameHandle;
extern HWND PasswordHandle;
extern HWND SQLStatementHandle;

//a couple of global functions related to time
unsigned long GetAppTime();
void PushAppTime();

//this function tries to retrieve a poem from the online database
char* RetrieveText();

#endif
