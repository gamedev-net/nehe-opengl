/*====================================
	Name: ARB_multisample.cpp
	Author: Colt "MainRoach" McAnlis
	Date: 4/29/04
	Desc:
		This file contains the context to load a WGL extension from a string
		As well as collect the sample format available based upon the graphics card.

====================================*/


#include <windows.h>
#include <gl/gl.h>
#include <gl/glu.h>


#include "arb_multisample.h"

//declairations we'll use
#define WGL_SAMPLE_BUFFERS_ARB		 0x2041
#define WGL_SAMPLES_ARB			     0x2042



bool	arbMultisampleSupported = false;
int		arbMultisampleFormat = 0;

/*Preface
	Fullscreen AntiAliasing is something that non-realtime rendering programs 
	have always had an advantage in. However, with current hardware, we're able
	to pull off the same effect real time.

	the ARB_MULTISAMPLE extension allows us to do this. Essencially, each pixel is 
	sampled by it's neighbors to find out the optomial antialias to preform. 
	This comes at a cost however, and can slow down preformance.
	Vid_mem =
		sizeof(Front_buffer) +
		sizeof(Back_buffer) +
		num_samples * (sizeof(Front_buffer) +sizeof(ZS_buffer))

  Our process shall go as follows
	1) create our window as normal
	2) Queary the possible Multisample pixel values	(InitMultisample)
	3) If Multisampling is available, distroy this window
		and recreate it with our NEW pixelFormat
	4) For parts we want to antialias, simply call glEnable(GL_ARB_MULTISAMPLE);

  Simple as that. ENJOY!

  NOTE: Any code modified in the files given will be between tags
  //ROACH
	....
  //ENDROACH 

  Additionally, a description accompanies every modification
  
  */





/*=======
WGLisExtensionSupported

	This is a form of the extension for WGL
=======*/
bool WGLisExtensionSupported(const char *extension)
{
	//make sure our WGL extenstion string exists
	PFNWGLGETEXTENSIONSSTRINGARBPROC wglGetExtensionsStringARB = (PFNWGLGETEXTENSIONSSTRINGARBPROC)wglGetProcAddress("wglGetExtensionsStringARB");

	//if it does, get our current device context
	if(wglGetExtensionsStringARB)
	{
		const char *winsys_extensions = wglGetExtensionsStringARB(wglGetCurrentDC());
		//check that our given extension exists
		if (winsys_extensions && (strstr(winsys_extensions,extension)))
			return true;
	}

	//if we didn't get a WGL context, check to see if it exists in our standard string
	//Get our extensions string
	char *glExtensions = (char*)glGetString(GL_EXTENSIONS);
	if (!glExtensions)
		return false;

	//return if our extension is in the available extension string
	return (strcmp(glExtensions,extension) != NULL);
}

/*=======
InitMultisample

	Used to query the multisample frequencies
=======*/

bool InitMultisample(HINSTANCE hInstance,HWND hWnd,PIXELFORMATDESCRIPTOR pfd)
{  

	 //SEE IF THE STRING EXISTS IN WGL!
	if (!WGLisExtensionSupported("WGL_ARB_multisample "))
	{
		arbMultisampleSupported=false;
		return false;
	}


	//GET OUR PIXEL CHOOSER FORMAT
	PFNWGLCHOOSEPIXELFORMATARBPROC wglChoosePixelFormatARB = (PFNWGLCHOOSEPIXELFORMATARBPROC)wglGetProcAddress("wglChoosePixelFormatARB");	
	if (!wglChoosePixelFormatARB) 
	{
		arbMultisampleSupported=false;
		return false;
	}

	//get our current device context
	HDC hDC = GetDC(hWnd);

	int pixelFormat;
	int valid;
	UINT numFormats;
	float fAttributes[] = {0,0};
	//these attributes are the bits we want to test for in our sample
	//everything is pretty standard, the only one we want to 
	// really focus on is the SAMPLE BUFFERS ARB and WGL SAMPLES
	//these two are going to do the main testing for weather or not
	//we support multisampling on this hardware.
	int iAttributes[] = { WGL_DRAW_TO_WINDOW_ARB,GL_TRUE,
		WGL_SUPPORT_OPENGL_ARB,GL_TRUE,
		WGL_ACCELERATION_ARB,WGL_FULL_ACCELERATION_ARB,
		WGL_COLOR_BITS_ARB,24,
		WGL_ALPHA_BITS_ARB,8,
		WGL_DEPTH_BITS_ARB,16,
		WGL_STENCIL_BITS_ARB,0,
		WGL_DOUBLE_BUFFER_ARB,GL_TRUE,
		WGL_SAMPLE_BUFFERS_ARB,GL_TRUE,
		WGL_SAMPLES_ARB,4,
		0,0};

	//First we check to see if we can get a pixel format for 4 samples
	valid = wglChoosePixelFormatARB(hDC,iAttributes,fAttributes,1,&pixelFormat,&numFormats);
 
	//if we returned true, and our format count is greater than 1
	if (valid && numFormats >= 1)
	{
		arbMultisampleSupported = true;
		arbMultisampleFormat = pixelFormat;	
		return arbMultisampleSupported;
	}

	//Our pixel format with 4 samples failed, test for 2 samples
	iAttributes[19] = 2;
	valid = wglChoosePixelFormatARB(hDC,iAttributes,fAttributes,1,&pixelFormat,&numFormats);
	if (valid && numFormats >= 1)
	{
		arbMultisampleSupported = true;
		arbMultisampleFormat = pixelFormat;	 
		return arbMultisampleSupported;
	}

	  
	//return the valid format
	return  arbMultisampleSupported;
}