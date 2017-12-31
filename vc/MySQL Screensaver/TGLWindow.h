//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: TGLWindow.h
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#ifndef _TGLWINDOW_H_
#define _TGLWINDOW_H_

#ifdef __BORLANDC__
#include <cstring>
#else
#include <string>
using namespace std;
#endif
#include "TGLFont.h"

//a function we use to display Windows' errors
void ShowError(LPSTR pCaption);

//a predeclared class (needed in TGLWindow, but also uses the TGLWindow class name)
class TGLFont;

//a function pointer prototype for the draw function (used in TGLWindow)
typedef void (*FUNC_DrawFunc)();
//used in TGLWIndow
typedef FARPROC TProc;

class TGLWindow
{
	private:
   	bool bFullscreen;
      bool bVisible;

      int ColorDepth;
      int DepthBuffer;
      int Left, Top, Width, Height;
      DWORD WindowStyle, WindowExStyle;

      WNDCLASS WindowClass;
      WNDPROC WindowProc;
      DEVMODE ScreenSettings;
      HWND Handle;
      HWND Parent;

      HDC DeviceContext;
		HGLRC RenderingContext;

      unsigned Id;

      GLuint PixelFormat;
      GLdouble DrawDistance;
      GLdouble FieldOfView;
      GLdouble NearPlane;

      string ClassName;
      string WindowCaption;

      static LRESULT CALLBACK GLWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
      TProc GLOwnerProc;

      FUNC_DrawFunc DrawFunc;
   public:

   	TGLWindow() { }

      TGLWindow(HWND pParent, unsigned pId, WNDPROC pWindowProc,
      				  string pCaption, string pClassName, int pX, int pY, int pWidth, int pHeight,
                    int pColorDepth, bool pFullscreen = true);

      virtual ~TGLWindow();

      bool RegisterWindowClass();
      bool ChangeScreenSettings(int pWidth, int pHeight, int pColorDepth, bool pFullscreen);

      bool UpdatePixelFormat();

		void Draw();
		void BindDrawFunc(FUNC_DrawFunc pDrawFunc);

      TGLWindow* Create();

      bool InitializeRenderingContext();
		bool CreateRenderingContext();
      void Resize(int pWidth, int pHeight);

      void Swap();

		void Destroy();

      HWND GetHandle();
		HDC GetDeviceContext();
		HGLRC GetRenderingContext();

      void Capture();

		void Print(TGLFont * pFont, const char *pFmt, ...);     

      HDC DC();

		unsigned GetWidth();
		unsigned GetHeight();
};

#endif