/////////////////////////////////////////////////////////////////
//                                                             //
//  The OpenGL Basecode Used In This Project Was Created By	   //
//  Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code  //
//  Useful, Please Let Me Know.								   //
//                                                             //
//	Original Code & Tutorial Text By Andreas Löffler           //
//  Excellent Job Andreas!									   //
//                                                             //
//  Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )  //
//  Proper Image Structure, Better Blitter Code, Misc Fixes    //
//  Thanks Rob!												   //
//															   //
//	0% CPU Usage While Minimized Thanks To Jim Strong		   //
//  ( jim@scn.net ).  Thanks Jim!                              //
//                                                             //
//  This Code Also Has The ATI Fullscreen Fix!                 //
//                                                             //
//  Visit Me At nehe.gamedev.net							   //
//                                                             //
/////////////////////////////////////////////////////////////////

#include <windows.h>											// Header File For Windows
#include <gl\gl.h>												// Header File For The OpenGL32 Library
#include <gl\glu.h>												// Header File For The GLu32 Library
#include <stdio.h>												// Header File For File Operation needed

HDC			hDC=NULL;											// Private GDI Device Context
HGLRC		hRC=NULL;											// Permanent Rendering Context
HWND		hWnd=NULL;											// Holds Our Window Handle
HINSTANCE	hInstance = NULL;									// Holds The Instance Of The Application

bool		keys[256];											// Array Used For The Keyboard Routine
bool		active=TRUE;										// Window Active Flag Set To TRUE By Default
bool		fullscreen=TRUE;									// Fullscreen Flag Set To Fullscreen Mode By Default

DEVMODE		DMsaved;											// Saves The Previous Screen Settings (NEW)

GLfloat		xrot;												// X Rotation
GLfloat		yrot;												// Y Rotation
GLfloat		zrot;												// Z Rotation

GLuint		texture[1];											// Storage For 1 Texture

typedef struct
{
	int width;													// Width Of Image In Pixels
	int height;													// Height Of Image In Pixels
	int format;													// Number Of Bytes Per Pixel
	unsigned char *data;										// Texture Data
} TEXTURE_IMAGE;

typedef TEXTURE_IMAGE *P_TEXTURE_IMAGE;							// A Pointer To The Texture Image Data Type

P_TEXTURE_IMAGE t1;												// Pointer To The Texture Image Data Type
P_TEXTURE_IMAGE t2;												// Pointer To The Texture Image Data Type

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);			// Declaration For WndProc

// Allocate An Image Structure And Inside Allocate Its Memory Requirements
P_TEXTURE_IMAGE AllocateTextureBuffer( GLint w, GLint h, GLint f)
{
    P_TEXTURE_IMAGE ti=NULL;									// Pointer To Image Struct
    unsigned char *c=NULL;										// Pointer To Block Memory For Image

    ti = (P_TEXTURE_IMAGE)malloc(sizeof(TEXTURE_IMAGE));		// One Image Struct Please
    
    if( ti != NULL ) {
        ti->width  = w;											// Set Width
        ti->height = h;											// Set Height
        ti->format = f;											// Set Format
        c = (unsigned char *)malloc( w * h * f);
        if ( c != NULL ) {
            ti->data = c;
        }
        else {
			MessageBox(NULL,"Could Not Allocate Memory For A Texture Buffer","BUFFER ERROR",MB_OK | MB_ICONINFORMATION);
            return NULL;
        }
    }
    else
	{
		MessageBox(NULL,"Could Not Allocate An Image Structure","IMAGE STRUCTURE ERROR",MB_OK | MB_ICONINFORMATION);
		return NULL;
    }
	return ti;													// Return Pointer To Image Struct
}

// Free Up The Image Data
void DeallocateTexture( P_TEXTURE_IMAGE t )
{
	if(t)
	{
		if(t->data)
		{
			free(t->data);
		}

		free(t);
	}
}

// Read A .RAW File In To The Allocated Image Buffer Using Data In The Image Structure Header.
// Flip The Image Top To Bottom.  Returns 0 For Failure Of Read, Or Number Of Bytes Read.
int ReadTextureData ( char *filename, P_TEXTURE_IMAGE buffer)
{
	FILE *f;
	int i,j,k,done=0;
	int stride = buffer->width * buffer->format;				// Size Of A Row (Width * Bytes Per Pixel)
	unsigned char *p = NULL;

    f = fopen(filename, "rb");									// Open "filename" For Reading Bytes
    if( f != NULL )												// If File Exists
    {
		for( i = buffer->height-1; i >= 0 ; i-- )				// Loop Through Height (Bottoms Up - Flip Image)
		{
			p = buffer->data + (i * stride );					// 
			for ( j = 0; j < buffer->width ; j++ )				// Loop Through Width
			{
				for ( k = 0 ; k < buffer->format-1 ; k++, p++, done++ )
				{
					*p = fgetc(f);								// Read Value From File And Store In Memory
				}
				*p = 255; p++;									// Store 255 In Alpha Channel And Increase Pointer
			}
		}
		fclose(f);												// Close The File
	}
	else														// Otherwise
	{
		MessageBox(NULL,"Unable To Open Image File","IMAGE ERROR",MB_OK | MB_ICONINFORMATION);
    }
	return done;												// Returns Number Of Bytes Read In
}

void BuildTexture (P_TEXTURE_IMAGE tex)
{
	glGenTextures(1, &texture[0]);
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB, tex->width, tex->height, GL_RGBA, GL_UNSIGNED_BYTE, tex->data);
}

void Blit( P_TEXTURE_IMAGE src, P_TEXTURE_IMAGE dst, int src_xstart, int src_ystart, int src_width, int src_height,
           int dst_xstart, int dst_ystart, int blend, int alpha)
{
	int i,j,k;
	unsigned char *s, *d;										// Source & Destination

	// Clamp Alpha If Value Is Out Of Range
    if( alpha > 255 ) alpha = 255;
    if( alpha < 0 ) alpha = 0;

	// Check For Incorrect Blend Flag Values
    if( blend < 0 ) blend = 0;
    if( blend > 1 ) blend = 1;

    d = dst->data + (dst_ystart * dst->width * dst->format);    // Start Row - dst (Row * Width In Pixels * Bytes Per Pixel)
    s = src->data + (src_ystart * src->width * src->format);    // Start Row - src (Row * Width In Pixels * Bytes Per Pixel)

    for (i = 0 ; i < src_height ; i++ )							// Height Loop
    {
        s = s + (src_xstart * src->format);						// Move Through Src Data By Bytes Per Pixel
        d = d + (dst_xstart * dst->format);						// Move Through Dst Data By Bytes Per Pixel
        for (j = 0 ; j < src_width ; j++ )						// Width Loop
        {
            for( k = 0 ; k < src->format ; k++, d++, s++)		// "n" Bytes At A Time
            {
                if (blend)										// If Blending Is On
                    *d = ( (*s * alpha) + (*d * (255-alpha)) ) >> 8; // Multiply Src Data*alpha Add Dst Data*(255-alpha)
                else											// Keep in 0-255 Range With >> 8
                    *d = *s;									// No Blending Just Do A Straight Copy
            }
        }
        d = d + (dst->width - (src_width + dst_xstart))*dst->format;	// Add End Of Row */
        s = s + (src->width - (src_width + src_xstart))*src->format;	// Add End Of Row */
    }
}

int InitGL(GLvoid)												// This Will Be Called Right After The GL Window Is Created
{
    t1 = AllocateTextureBuffer( 256, 256, 4 );					// Get An Image Structure
    if (ReadTextureData("Data/Monitor.raw",t1)==0)				// Fill The Image Structure With Data
	{															// Nothing Read?
		MessageBox(NULL,"Could Not Read 'Monitor.raw' Image Data","TEXTURE ERROR",MB_OK | MB_ICONINFORMATION);
        return FALSE;
    }

    t2 = AllocateTextureBuffer( 256, 256, 4 );					// Second Image Structure
	if (ReadTextureData("Data/GL.raw",t2)==0)					// Fill The Image Structure With Data
	{															// Nothing Read?
		MessageBox(NULL,"Could Not Read 'GL.raw' Image Data","TEXTURE ERROR",MB_OK | MB_ICONINFORMATION);
        return FALSE;
    }

	// Image To Blend In, Original Image, Src Start X & Y, Src Width & Height, Dst Location X & Y, Blend Flag, Alpha Value
    Blit(t2,t1,127,127,128,128,64,64,1,127);					// Call The Blitter Routine

    BuildTexture (t1);											// Load The Texture Map Into Texture Memory

    DeallocateTexture( t1 );									// Clean Up Image Memory Because Texture Is
    DeallocateTexture( t2 );									// In GL Texture Memory Now

	glEnable(GL_TEXTURE_2D);									// Enable Texture Mapping

	glShadeModel(GL_SMOOTH);									// Enables Smooth Color Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);						// This Will Clear The Background Color To Black
	glClearDepth(1.0);											// Enables Clearing Of The Depth Buffer
	glEnable(GL_DEPTH_TEST);									// Enables Depth Testing
	glDepthFunc(GL_LESS);										// The Type Of Depth Test To Do

	return TRUE;
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)		// Resize And Initialize The GL Window
{
	if (height==0)										// Prevent A Divide By Zero By
	{
		height=1;										// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

GLvoid DrawGLScene(GLvoid)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear The Screen And The Depth Buffer
	glLoadIdentity();										// Reset The View
	glTranslatef(0.0f,0.0f,-5.0f);

	glRotatef(xrot,1.0f,0.0f,0.0f);
	glRotatef(yrot,0.0f,1.0f,0.0f);
	glRotatef(zrot,0.0f,0.0f,1.0f);

	glBindTexture(GL_TEXTURE_2D, texture[0]);

	glBegin(GL_QUADS);
		// Front Face
		glNormal3f( 0.0f, 0.0f, 1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		// Back Face
		glNormal3f( 0.0f, 0.0f,-1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		// Top Face
		glNormal3f( 0.0f, 1.0f, 0.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		// Bottom Face
		glNormal3f( 0.0f,-1.0f, 0.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		// Right Face
		glNormal3f( 1.0f, 0.0f, 0.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
		// Left Face
		glNormal3f(-1.0f, 0.0f, 0.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glEnd();

	xrot+=0.3f;
	yrot+=0.2f;
	zrot+=0.4f;
}

GLvoid KillGLWindow(GLvoid)								// Properly Kill The Window
{
	if (fullscreen)										// Are We In Fullscreen Mode?
	{
		if (!ChangeDisplaySettings(NULL,CDS_TEST)) {	// If The Shortcut Doesn't Work
			ChangeDisplaySettings(NULL,CDS_RESET);		// Do It Anyway (To Get The Values Out Of The Registry)
			ChangeDisplaySettings(&DMsaved,CDS_RESET);	// Change Resolution To The Saved Settings
		}
		else											// Not Fullscreen.
		{
			ChangeDisplaySettings(NULL,CDS_RESET);		// Do Nothing
		}
			
		ShowCursor(TRUE);								// Show Mouse Pointer
	}

	if (hRC)											// Do We Have A Rendering Context?
	{
		if (!wglMakeCurrent(NULL,NULL))					// Are We Able To Release The DC And RC Contexts?
		{
			MessageBox(NULL,"Release Of DC And RC Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))						// Are We Able To Delete The RC?
		{
			MessageBox(NULL,"Release Rendering Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC=NULL;										// Set RC To NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))					// Are We Able To Release The DC
	{
		MessageBox(NULL,"Release Device Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC=NULL;										// Set DC To NULL
	}

	if (hWnd && !DestroyWindow(hWnd))					// Are We Able To Destroy The Window?
	{
		MessageBox(NULL,"Could Not Release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd=NULL;										// Set hWnd To NULL
	}

	if (!UnregisterClass("OpenGL",hInstance))			// Are We Able To Unregister Class
	{
		MessageBox(NULL,"Could Not Unregister Class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance=NULL;									// Set hInstance To NULL
	}
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:					*
 *	title			- Title To Appear At The Top Of The Window				*
 *	width			- Width Of The GL Window Or Fullscreen Mode				*
 *	height			- Height Of The GL Window Or Fullscreen Mode			*
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)			*
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)	*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	GLuint		PixelFormat;							// Holds The Results After Searching For A Match
	WNDCLASS	wc;										// Windows Class Structure
	DWORD		dwExStyle;								// Window Extended Style
	DWORD		dwStyle;								// Window Style

	fullscreen=fullscreenflag;							// Set The Global Fullscreen Flag

	hInstance			= GetModuleHandle(NULL);		// Grab An Instance For Our Window
	wc.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraw On Size, And Own DC For Window.
	wc.lpfnWndProc		= (WNDPROC) WndProc;			// WndProc Handles Messages
	wc.cbClsExtra		= 0;							// No Extra Window Data
	wc.cbWndExtra		= 0;							// No Extra Window Data
	wc.hInstance		= hInstance;					// Set The Instance
	wc.hIcon			= LoadIcon(NULL, IDI_WINLOGO);	// Load The Default Icon
	wc.hCursor			= LoadCursor(NULL, IDC_ARROW);	// Load The Arrow Pointer
	wc.hbrBackground	= NULL;							// No Background Required For GL
	wc.lpszMenuName		= NULL;							// We Don't Want A Menu
	wc.lpszClassName	= "OpenGL";						// Set The Class Name

	EnumDisplaySettings(NULL, ENUM_CURRENT_SETTINGS, &DMsaved); // Save The Current Display State (NEW)

	if (fullscreen)												// Attempt Fullscreen Mode?
	{
		DEVMODE dmScreenSettings;								// Device Mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	// Makes Sure Memory's Cleared
		dmScreenSettings.dmSize=sizeof(dmScreenSettings);		// Size Of The Devmode Structure
		dmScreenSettings.dmPelsWidth	= width;				// Selected Screen Width
		dmScreenSettings.dmPelsHeight	= height;				// Selected Screen Height
		dmScreenSettings.dmBitsPerPel	= bits;					// Selected Bits Per Pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
			if (MessageBox(NULL,"The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen=FALSE;		// Windowed Mode Selected.  Fullscreen = FALSE
			}
			else
			{
				// Pop Up A Message Box Letting User Know The Program Is Closing.
				MessageBox(NULL,"Program Will Now Close.","ERROR",MB_OK|MB_ICONSTOP);
				return FALSE;									// Return FALSE
			}
		}
	}

	if (!RegisterClass(&wc))							// Attempt To Register The Window Class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}
	
	if (fullscreen)										// Are We Still In Fullscreen Mode?
	{
		dwExStyle=WS_EX_APPWINDOW;						// Window Extended Style
		dwStyle=WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;	// Windows Style
		ShowCursor(FALSE);								// Hide Mouse Pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;	// Window Extended Style
		dwStyle=WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;	// Windows Style
	}

	// Create The Window
	if (!(hWnd=CreateWindowEx(	dwExStyle,				// Extended Style For The Window
								"OpenGL",				// Class Name
								title,					// Window Title
								dwStyle,				// Window Style
								0, 0,					// Window Position
								width, height,			// Selected Width And Height
								NULL,					// No Parent Window
								NULL,					// No Menu
								hInstance,				// Instance
								NULL)))					// Dont Pass Anything To WM_CREATE
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd=					// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),					// Size Of This Pixel Format Descriptor
		1,												// Version Number
		PFD_DRAW_TO_WINDOW |							// Format Must Support Window
		PFD_SUPPORT_OPENGL |							// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,								// Must Support Double Buffering
		PFD_TYPE_RGBA,									// Request An RGBA Format
		bits,											// Select Our Color Depth
		0, 0, 0, 0, 0, 0,								// Color Bits Ignored
		0,												// No Alpha Buffer
		0,												// Shift Bit Ignored
		0,												// No Accumulation Buffer
		0, 0, 0, 0,										// Accumulation Bits Ignored
		16,												// 16Bit Z-Buffer (Depth Buffer)  
		1,												// Use Stencil Buffer ( * Important * )
		0,												// No Auxiliary Buffer
		PFD_MAIN_PLANE,									// Main Drawing Layer
		0,												// Reserved
		0, 0, 0											// Layer Masks Ignored
	};
	
	if (!(hDC=GetDC(hWnd)))								// Did We Get A Device Context?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Create A GL Device Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))		// Did Windows Find A Matching Pixel Format?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Find A Suitable PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))			// Are We Able To Set The Pixel Format?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Set The PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))					// Are We Able To Get A Rendering Context?
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Create A GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))						// Try To Activate The Rendering Context
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Can't Activate The GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);							// Show The Window
	SetForegroundWindow(hWnd);							// Slightly Higher Priority
	SetFocus(hWnd);										// Sets Keyboard Focus To The Window
	ReSizeGLScene(width, height);						// Set Up Our Perspective GL Screen

	if (!InitGL())										// Initialize Our Newly Created GL Window
	{
		KillGLWindow();									// Reset The Display
		MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;									// Return FALSE
	}

	return TRUE;										// Success
}

LRESULT CALLBACK WndProc(	HWND	hWnd,				// Handle For This Window
							UINT	uMsg,				// Message For This Window
							WPARAM	wParam,				// Additional Message Information
							LPARAM	lParam)				// Additional Message Information
{
	switch (uMsg)										// Check For Windows Messages
	{
		case WM_ACTIVATE:								// Watch For Window Activate Message
		{
			if (!HIWORD(wParam))						// Check Minimization State
			{
				active=TRUE;							// Program Is Active
			}
			else										// Otherwise
			{
				active=FALSE;							// Program Is No Longer Active
			}

			return 0;									// Return To The Message Loop
		}

		case WM_SYSCOMMAND:								// Intercept System Commands
		{
			switch (wParam)								// Check System Calls
			{
				case SC_SCREENSAVE:						// Screensaver Trying To Start?
				case SC_MONITORPOWER:					// Monitor Trying To Enter Powersave?
				return 0;								// Prevent From Happening
			}
			break;										// Exit
		}

		case WM_CLOSE:									// Did We Receive A Close Message?
		{
			PostQuitMessage(0);							// Send A Quit Message
			return 0;									// Jump Back
		}

		case WM_KEYDOWN:								// Is A Key Being Held Down?
		{
			keys[wParam] = TRUE;						// If So, Mark It As TRUE
			return 0;									// Jump Back
		}

		case WM_KEYUP:									// Has A Key Been Released?
		{
			keys[wParam] = FALSE;						// If So, Mark It As FALSE
			return 0;									// Jump Back
		}

		case WM_SIZE:									// Resize The OpenGL Window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord=Width, HiWord=Height
			return 0;									// Jump Back
		}
	}

	// Pass All Unhandled Messages To DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);		// Return Unhandled Messages
}

int WINAPI WinMain(	HINSTANCE	hInstance,				// Instance
					HINSTANCE	hPrevInstance,			// Previous Instance
					LPSTR		lpCmdLine,				// Command Line Parameters
					int			nCmdShow)				// Window Show State
{
	MSG		msg;										// Windows Message Structure
	BOOL	done=FALSE;									// Bool Variable To Exit Loop

	// Ask The User Which Screen Mode They Prefer
	if (MessageBox(NULL,"Would You Like To Run In Fullscreen Mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen=FALSE;								// Windowed Mode
	}

	// Create Our OpenGL Window
	if (!CreateGLWindow("Andreas Löffler, Rob Fletcher & NeHe's Blitter & Raw Image Loading Tutorial", 640, 480, 32, fullscreen))
	{
		return 0;										// Quit If Window Was Not Created
	}

	while(!done)										// Loop That Runs While done=FALSE
	{
		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))		// Is There A Message Waiting?
		{
			if (msg.message==WM_QUIT)					// Have We Received A Quit Message?
			{
				done=TRUE;								// If So done=TRUE
			}
			else										// If Not, Deal With Window Messages
			{
				TranslateMessage(&msg);					// Translate The Message
				DispatchMessage(&msg);					// Dispatch The Message
			}
		}

		if (!active)									// Program Inactive?
		{
			WaitMessage();								// Wait For A Message / Do Nothing ( NEW ... Thanks Jim Strong )
		}

		if (keys[VK_ESCAPE])							// Was Escape Pressed?
		{
			done=TRUE;									// ESC Signalled A Quit
		}

		if (keys[VK_F1])								// Is F1 Being Pressed?
		{
			keys[VK_F1]=FALSE;							// If So Make Key FALSE
			KillGLWindow();								// Kill Our Current Window
			fullscreen=!fullscreen;						// Toggle Fullscreen / Windowed Mode
			// Recreate Our OpenGL Window
			if (!CreateGLWindow("Andreas Löffler, Rob Fletcher & NeHe's Blitter & Raw Image Loading Tutorial",640,480,16,fullscreen))
			{
				return 0;								// Quit If Window Was Not Created
			}
		}

		DrawGLScene();									// Draw The Scene
		SwapBuffers(hDC);								// Swap Buffers (Double Buffering)
	}

	// Shutdown
	KillGLWindow();										// Kill The Window
	return (msg.wParam);								// Exit The Program
}
