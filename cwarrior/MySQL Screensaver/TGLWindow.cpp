//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: TGLWindow.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "TGLWindow.h"
#ifdef __BORLANDC__
#include <windowsx>
#else
#include <windowsx.h>
#endif

//ShowError displays the last error message produced by Windows
void ShowError(LPSTR pCaption)
{
	LPSTR msg;

   //format the message from its id to a text string
	FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
					  NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
				     (LPTSTR)&msg, 0, NULL);
   //throw a messagebox
	MessageBox(NULL, msg, pCaption, MB_OK | MB_ICONINFORMATION);
}

//for the rest of the code see the tutorial text - this is largely based on
//previous NeHe tutorials, but done in OOP style

TGLWindow::TGLWindow(HWND pParent, unsigned pId, WNDPROC pWindowProc,
  				  string pCaption, string pClassName, int pX, int pY, int pWidth, int pHeight,
              int pColorDepth, bool pFullscreen)
{
   if(pFullscreen)
      pX = pY = 0;

   Parent = pParent;
   Id = pId;
   WindowProc = pWindowProc;
   WindowCaption = pCaption;
   ClassName = pClassName;

   Left = pX;
   Top = pY;
   Width = pWidth;
   Height = pHeight;

   ColorDepth = pColorDepth;
   DepthBuffer = 16;
   bFullscreen = pFullscreen;
   bVisible = true;

   FieldOfView = 45.0f;
   DrawDistance = 25000.0f;
   NearPlane = .2f;

//STEP 1: register the window class
	if(!RegisterWindowClass())
   	return;

//STEP 2: change the resolution and bit depth
   if(!ChangeScreenSettings(pWidth, pHeight, ColorDepth, bFullscreen))
   	{
   	bFullscreen = !bFullscreen;
	   if(!ChangeScreenSettings(pWidth, pHeight, ColorDepth, bFullscreen))
      	return;
      }

//STEP 3: create the window
	if(!Create())
   	return;

//STEP 4: create the window
   if(RenderingContext == NULL)
	 	CreateRenderingContext();

//STEP 5: set the pixel format
   if(!UpdatePixelFormat())
   	return;

//STEP 6: set up the renderin context
   InitializeRenderingContext();
}

TGLWindow::~TGLWindow()
{

}

bool TGLWindow::CreateRenderingContext()
{
	RenderingContext = wglCreateContext(DeviceContext);

   return true;
}

bool TGLWindow::RegisterWindowClass()
{
   if(!ClassName.length())
	   ClassName = "TGLWindow";

   WNDCLASS Temp;

   if(GetClassInfo(GetModuleHandle(NULL), ClassName.c_str(), &Temp))
   	{
   	ShowError("TGLWindow::RegisterWindowClass() -> class already registered!");
      return false;
      }

	WindowClass.style				= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
	WindowClass.lpfnWndProc		= (WNDPROC)WindowProc;
	WindowClass.cbClsExtra		= 0;
	WindowClass.cbWndExtra		= 0;
	WindowClass.hInstance		= GetModuleHandle(NULL);
	WindowClass.hIcon				= LoadIcon(NULL, IDI_WINLOGO);
	WindowClass.hCursor			= LoadCursor(NULL, IDC_ARROW);
	WindowClass.hbrBackground	= NULL;
	WindowClass.lpszMenuName	= NULL;
	WindowClass.lpszClassName	= (LPSTR)ClassName.c_str();

	if(RegisterClass(&WindowClass) == NULL)
		{
      ShowError("TGLWindow::RegisterWindowClass()->RegisterClass() -> Unable to register TGLWindow.");
		return false;
		}

   return true;
}

bool TGLWindow::ChangeScreenSettings(int pWidth, int pHeight, int pColorDepth, bool pFullscreen)
{
	if(pFullscreen)
		{
		memset(&ScreenSettings, 0 ,sizeof(DEVMODE));
		ScreenSettings.dmSize = sizeof(DEVMODE);
		ScreenSettings.dmPelsWidth	= pWidth;
		ScreenSettings.dmPelsHeight = pHeight;
		ScreenSettings.dmBitsPerPel = pColorDepth;
		ScreenSettings.dmFields = DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT;

      SetLastError(0);

		if(ChangeDisplaySettings(&ScreenSettings, CDS_FULLSCREEN) != DISP_CHANGE_SUCCESSFUL)
      	{
         ShowError("TGLWindow::ChangeScreenSettings() -> ChangeDisplaySettings()");
         return false;
         }
		}

	return true;
}

bool TGLWindow::UpdatePixelFormat()
{
	//comments not removed from previous tutorials
	static PIXELFORMATDESCRIPTOR pfd =		// pfd Tells Windows How We Want Things To Be
		{
		sizeof(PIXELFORMATDESCRIPTOR),		// Size Of This Pixel Format Descriptor
		1,												// Version Number
		PFD_DRAW_TO_WINDOW |						// Format Must Support Window
		PFD_SUPPORT_OPENGL |						// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,							// Must Support Double Buffering
		PFD_TYPE_RGBA,								// Request An RGBA Format
		(BYTE)ColorDepth,									// Select Our Color Depth
		0, 0, 0, 0, 0, 0,							// Color Bits Ignored
		0,												// No Alpha Buffer
		0,												// Shift Bit Ignored
		0,												// No Accumulation Buffer
		0, 0, 0, 0,									// Accumulation Bits Ignored
		(BYTE)DepthBuffer,								// 16Bit/32bit Z-Buffer (Depth Buffer)
		0,	                           	   // use stencil
		0,												// No Auxiliary Buffer
		PFD_MAIN_PLANE,							// Main Drawing Layer
		0,												// Reserved
		0, 0, 0										// Layer Masks Ignored
		};

   SetLastError(0);

	if ((PixelFormat = ChoosePixelFormat(DeviceContext, &pfd)) == NULL)
		{
		Destroy();
		ShowError("TGLWindow::UpdatePixelFormat() -> ChoosePixelFormat()");
		return false;
		}

	if(SetPixelFormat(DeviceContext, PixelFormat, &pfd) == NULL)
		{
		Destroy();
		ShowError("TGLWindow::UpdatePixelFormat() -> SetPixelFormat()");
		return false;
		}

	return true;
}

TGLWindow* TGLWindow::Create()
{
	DWORD ExStyle, Style;

	if(bFullscreen)
		{
		ExStyle = WS_EX_APPWINDOW;
		Style = WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
		ShowCursor(FALSE);
		}
	else
		{
      if(!Parent)
      	{
			ExStyle = WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;
			Style = WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
         }
      else
      	{
			ExStyle = WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;
      	Style = WS_CHILDWINDOW | WS_VISIBLE | WS_BORDER | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
         }
		}

   RECT WindowRect = {0,0,0,0};

	AdjustWindowRectEx(&(RECT)WindowRect, Style, FALSE, ExStyle);

   SetLastError(0);

	if((Handle = CreateWindowEx(ExStyle, ClassName.c_str(), WindowCaption.c_str(), Style,
											Left, Top,	Width, Height,
											Parent, (HMENU)Id, GetModuleHandle(NULL), (LPVOID)NULL)) == NULL)
		{
		Destroy();
		ShowError("TGLWindow::Create() -> CreateWindowEx()");
		return NULL;
		}

   SetLastError(0);

	if((DeviceContext = GetDC(Handle)) == NULL)
		{
		Destroy();
		ShowError("TGLWindow::Create() -> GetDC()");
		return NULL;
		}

   SetLastError(0);

   GLOwnerProc = (TProc)SetWindowLong(Handle, GWL_WNDPROC, (DWORD)GLWindowProc);
   SetWindowLong(Handle, GWL_USERDATA, (DWORD)this);

   if(GLOwnerProc == NULL)
		{
		Destroy();
		ShowError("TGLWindow::Create() -> SetWindowLong()");
		return NULL;
		}

	return this;
}

bool TGLWindow::InitializeRenderingContext()
{
	if((RenderingContext = wglCreateContext(DeviceContext)) == NULL)
		{
		Destroy();
		ShowError("TGLWindow::InitializeRenderingContext() -> wglCreateContext()");
		return NULL;
		}

	if(!wglMakeCurrent(DeviceContext, RenderingContext))
		{
		Destroy();
		ShowError("TGLWindow::InitializeRenderingContext() -> wglMakeCurrent()");
		return NULL;
		}

	ShowWindow(Handle, SW_SHOW);

	SetForegroundWindow(Handle);

	SetFocus(Handle);

	Resize(Width, Height);

	return true;
}

//this part has to do with sublassing - see the tutorial text for a more thorough
//explanation on it!
LRESULT CALLBACK TGLWindow::GLWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	TGLWindow* Window = (TGLWindow*)GetWindowLong(hWnd, GWL_USERDATA);

   switch(uMsg)
   	{
      //these messages doen't really belong here - they're here to prove a point
      //related to sublassing only
//      case WM_RBUTTONDOWN:
      case WM_LBUTTONDOWN:
      case WM_RBUTTONUP:
      case WM_LBUTTONUP:
      case WM_RBUTTONDBLCLK:
      case WM_LBUTTONDBLCLK:
      case WM_MOUSEMOVE:
         return 0;
      //relay any command messages to the parent
		case WM_COMMAND:
			SendMessage(Window->Parent, uMsg, wParam, lParam);
         return 0;
      }

   return(CallWindowProc((WNDPROC)Window->GLOwnerProc, hWnd, uMsg, wParam, lParam));
}

void TGLWindow::Draw()
{
	Capture();
   //call the draw function we bound in WinMain()
	DrawFunc();
   Swap();
}

void TGLWindow::BindDrawFunc(FUNC_DrawFunc pDrawFunc)
{
	DrawFunc = pDrawFunc;
}

void TGLWindow::Resize(int pWidth, int pHeight)
{
	if(pHeight == 0)
   	return;

	glViewport(0, 0, pWidth, pHeight);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	gluPerspective(FieldOfView, (GLfloat)pWidth / (GLfloat)pHeight, NearPlane, DrawDistance);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

void TGLWindow::Swap()
{
	if(bVisible)
   	SwapBuffers(DeviceContext);
}

void TGLWindow::Destroy()
{

}

void TGLWindow::Capture()
{
	wglMakeCurrent(DeviceContext, RenderingContext);
}

unsigned TGLWindow::GetWidth()
{
	return Width;
}

unsigned TGLWindow::GetHeight()
{
	return Height;
}

HDC TGLWindow::DC()
{
	return DeviceContext;
}

HWND TGLWindow::GetHandle()
{
	return Handle;
}

//print a text with arguments using a font passd in as a parameter
void TGLWindow::Print(TGLFont * pFont, const char *pFmt, ...)
{
	char text[256];
	va_list ap;

	if(pFmt == NULL)
		return;

	va_start(ap, pFmt);
		wsprintf(text, pFmt, ap);
	va_end(ap);

	glPushAttrib(GL_LIST_BIT);
	glListBase(pFont->GetBase());
	glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);
	glPopAttrib();
}













