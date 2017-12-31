//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: Configure.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "main.h"
#ifdef __BORLANDC__
#include "def.rcd"
#include <commctrl> //we need commctrl.h for managing TBM_xxx messages
#include <windowsx> //we need windowsx.h for the GET_WM_COMMAND_ID() macro
#else
#include "resource.h"
#include <commctrl.h> //we need commctrl.h for managing TBM_xxx messages
#include <windowsx.h> //we need windowsx.h for the GET_WM_COMMAND_ID() macro
#endif

//declare the handles for all of the controls in the dialog box
HWND SpeedHandle = NULL;				//tracker bar
HWND ScatterHandle = NULL;				//tracker bar
HWND ScatterLEDHandle = NULL;			//static text
HWND SpeedLEDHandle = NULL;			//static text
HWND ServerIPHandle = NULL;			//edit box
HWND ServerPortHandle = NULL;			//edit box
HWND DatabaseNameHandle = NULL;		//edit box
HWND UsernameHandle = NULL;			//edit box
HWND PasswordHandle = NULL;			//edit box
HWND SQLStatementHandle = NULL;		//edit box

BOOL WINAPI ScreenSaverConfigureDialog(HWND hDlg, UINT message, UINT wParam, LONG lParam)
{
   //some needy variables
   int Value;
   char str[12];

   //handle the messages
   switch(message)
		{
      //upon creation of the dialog
      case WM_INITDIALOG:
		   //acquire the correct handles from the resource (see Screensaver.rc)
		   SpeedHandle = GetDlgItem(hDlg, IDC_TEXT_SPEED);
		   SpeedLEDHandle = GetDlgItem(hDlg, IDC_TEXT_SPEED_LED);
		   ScatterHandle = GetDlgItem(hDlg, IDC_SCATTER);
		   ScatterLEDHandle = GetDlgItem(hDlg, IDC_SCATTER_LED);
		   ServerIPHandle = GetDlgItem(hDlg, IDC_SERVERIP);
		   ServerPortHandle = GetDlgItem(hDlg, IDC_SERVERPORT);
		   DatabaseNameHandle = GetDlgItem(hDlg, IDC_DATABASENAME);
		   UsernameHandle = GetDlgItem(hDlg, IDC_USERNAME);
		   PasswordHandle = GetDlgItem(hDlg, IDC_PASSWORD);
		   SQLStatementHandle = GetDlgItem(hDlg, IDC_SQLSTATEMENT);

    		//set the range of the text speed to [25, 250]
      	SendMessage(SpeedHandle, TBM_SETRANGE, true, MAKELONG(25, 250));
         //set the step size when moving the slider on the tracker bar
         //(it now increments by steps of 25)
      	SendMessage(SpeedHandle, TBM_SETPAGESIZE, 0, 25L);
         //set the position of the slider to a predefined (preloaded)
         //value (stored in T)
	      SendMessage(SpeedHandle, TBM_SETPOS, true, T);
			//set the led to reflect the value
         sprintf(str, "%i", T);
      	SendMessage(SpeedLEDHandle, WM_SETTEXT, 0, (LPARAM)str);

         //do the same for the scatter value, this time with a small exception
         //in mind: we will later on be using values ten times smaller than
         //those indicated by the slider bar. That is, if the slider is moved
			//all the way to the end (eg 250), we will be using the value 250 / 10
         //or 25.0 internally instead. Can you figure out why? Hint: see help
			//on the TBM_SETRANGE message
      	SendMessage(ScatterHandle, TBM_SETRANGE, true, MAKELONG(0, 250));
      	SendMessage(ScatterHandle, TBM_SETPAGESIZE, 0, 5L);

	      SendMessage(ScatterHandle, TBM_SETPOS, true, Scatter * 10);
         sprintf(str, "%.2f", Scatter);
      	SendMessage(ScatterLEDHandle, WM_SETTEXT, 0, (LPARAM)str);

         sprintf(str, "%i", ServerPort);
      	SendMessage(ServerPortHandle, WM_SETTEXT, 0, (LPARAM)str);

      	SendMessage(ServerIPHandle, WM_SETTEXT, 0, (LPARAM)ServerIP);
      	SendMessage(DatabaseNameHandle, WM_SETTEXT, 0, (LPARAM)Databasename);
      	SendMessage(SQLStatementHandle, WM_SETTEXT, 0, (LPARAM)QueryText);
      	SendMessage(UsernameHandle, WM_SETTEXT, 0, (LPARAM)Username);
      	SendMessage(PasswordHandle, WM_SETTEXT, 0, (LPARAM)Password);
      	return true;
		case WM_CLOSE:
		   //we're exiting - let's destroy all the evidence!      
	   	EndDialog(hDlg, 0);
         PostQuitMessage(0);
         break;
      case WM_COMMAND:
      	switch(GET_WM_COMMAND_ID(wParam, lParam))
         	{
         	case IDCANCEL:
			   	EndDialog(hDlg, 0);
      	      PostQuitMessage(0);
               break;
         	case IDUPDATE:
            	UpdateRegistry();
			   	EndDialog(hDlg, 0);
   		      PostQuitMessage(0);
               break;
         	case IDREMOVEFROMREGISTRY:
            	RemoveRegistry();
			   	EndDialog(hDlg, 0);
   		      PostQuitMessage(0);
               break;
            }
         return false;
      //if the user scrolled something (anything) on the dialog box, we're
      //notified through the WM_HSCROLL and WM_VSCROLL messages. We only
      //have horizontal scrollbars
      case WM_HSCROLL:
      	//the handle to the tracker bar is passed to use as lParam, so all
         //we need to do, is match it
      	if((HWND)lParam == SpeedHandle)
         	{
            //get the position of the tracker bar
		      Value = SendMessage(SpeedHandle, TBM_GETPOS, 0, 0);
            //make it a string
  	      	sprintf(str, "%i", Value);
            //store the speed value in T (global variable)
     		   T = Value;
            //set the LED (the number underneath the scrollbar) to reflect
            //the current value
     			SendMessage(SpeedLEDHandle, WM_SETTEXT, 0, (LPARAM)str);
	         return false;
	         }
         //do the same for the scatter parameter
         else if((HWND)lParam == ScatterHandle)
         	{
		      Value = SendMessage(ScatterHandle, TBM_GETPOS, 0, 0);
            //normalize the number by dividing it by 10 - makes the number
            //seem a little more user friendly
  	      	sprintf(str, "%.2f", Value / 10.f);
     		   Scatter = Value / 10.f;
     			SendMessage(ScatterLEDHandle, WM_SETTEXT, 0, (LPARAM)str);
	         return false;
            }
      }

	return false;
}

