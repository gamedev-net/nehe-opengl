//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <stdio.h>      // Header file for standard Input / Output
#include <stdarg.h>     // Header file for variable argument routines
#include <string.h>     // Header file for string management
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#pragma hdrstop

//---------------------------------------------------------------------------
#pragma argsused

HGLRC hRC = NULL;               // Permanent rendering context
HDC hDC = NULL;                 // Private GDI device context
HWND hWnd = NULL;               // Holds our window handle
HINSTANCE hInstance = NULL;     // Holds the instance of the application

bool keys[256];                 // Array used for the keyboard routine
bool active = true;             // Window active flag set to TRUE by default
bool fullscreen = true;         // Fullscreen flag set to fullscreen mode by default

int scroll;			// Used for scrolling the screen
int maxtokens;			// Keeps track of the number of extensions supported
int swidth; 			// Scissor width
int sheight;			// Scissor height

GLuint base;			// Base display list for the font

typedef	struct			// Create a structure
{
	GLubyte	*imageData;	// Image data (Up To 32 Bits)
	GLuint bpp;     	// Image color depth in bits per pixel
	GLuint width;		// Image width
	GLuint height;		// Image height
	GLuint texID;		// Texture ID used to select a texture
} TextureImage;			// Structure name

TextureImage textures[1];								// Storage For One Texture

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

bool LoadTGA(TextureImage *texture, char *filename)	// Loads A TGA File Into Memory
{
	GLubyte TGAheader[12] = {0,0,2,0,0,0,0,0,0,0,0,0};      // Uncompressed TGA header
	GLubyte TGAcompare[12];					// Used to compare TGA header
	GLubyte header[6];					// First 6 useful bytes from the header
	GLuint bytesPerPixel;					// Holds number of bytes per pixel used in the TGA file
	GLuint imageSize;					// Used to store the image size when setting aside ram
	GLuint temp;						// Temporary variable
	GLuint type = GL_RGBA;					// Set the default GL mode to RBGA (32 BPP)

	FILE *file = fopen(filename, "rb");			// Open the TGA file

	if(	file==NULL ||					// Does file even exist?
		fread(TGAcompare,1,sizeof(TGAcompare),file)!=sizeof(TGAcompare) ||	// Are there 12 bytes to read?
		memcmp(TGAheader,TGAcompare,sizeof(TGAheader))!=0 ||                    // Does the header match what we want?
		fread(header,1,sizeof(header),file)!=sizeof(header))			// If so read next 6 header bytes
	{
		if (file == NULL)				// Did the file even exist? *Added Jim Strong*
			return false;				// Return false
		else
		{
			fclose(file);				// If anything failed, close the file
			return false;				// Return false
		}
	}

	texture->width  = header[1] * 256 + header[0];		// Determine the TGA width (highbyte*256+lowbyte)
	texture->height = header[3] * 256 + header[2];		// Determine the TGA height (highbyte*256+lowbyte)
    
 	if(	texture->width	<=0	||			// Is the width less than or equal to zero
		texture->height	<=0	||			// Is the height less than or equal to zero
		(header[4]!=24 && header[4]!=32))		// Is the TGA 24 or 32 bit?
	{
		fclose(file);					// If anything failed, close the file
		return false;					// Return false
	}

	texture->bpp = header[4];			        	// Grab the TGA's bits per pixel (24 or 32)
	bytesPerPixel = texture->bpp/8;			                // Divide by 8 to get the bytes per pixel
	imageSize = texture->width*texture->height*bytesPerPixel;	// Calculate the memory required for the TGA data

	texture->imageData=(GLubyte *)malloc(imageSize);		// Reserve memory to hold the TGA data

	if(	texture->imageData==NULL ||				        // Does the storage memory exist?
		fread(texture->imageData, 1, imageSize, file)!=imageSize)	// Does the image size match the memory reserved?
	{
		if(texture->imageData!=NULL)				// Was image data loaded
			free(texture->imageData);			// If so, release the image data

		fclose(file);						// Close the file
		return false;						// Return false
	}

	for(GLuint i=0; i<int(imageSize); i+=bytesPerPixel)		// Loop through the image data
	{								// Swaps the 1st and 3rd bytes ('R'ed and 'B'lue)
		temp=texture->imageData[i];				// Temporarily store the value at image data 'i'
		texture->imageData[i] = texture->imageData[i + 2];	// Set the 1st byte to the value of the 3rd byte
		texture->imageData[i + 2] = temp;			// Set the 3rd byte to the value in 'temp' (1st byte value)
	}

	fclose (file);							// Close the file

	// Build A Texture From The Data
	glGenTextures(1, &texture[0].texID);				// Generate OpenGL texture IDs

	glBindTexture(GL_TEXTURE_2D, texture[0].texID);			// Bind Our Texture
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);       // Linear filtered
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// Linear filtered
	
	if (texture[0].bpp==24)						// Was the TGA 24 bits
	{
		type=GL_RGB;						// If so set the 'type' to GL_RGB
	}

	glTexImage2D(GL_TEXTURE_2D, 0, type, texture[0].width, texture[0].height, 0, type, GL_UNSIGNED_BYTE, texture[0].imageData);

	return true;	        // Texture building went Ok, return true
}

GLvoid BuildFont(GLvoid)	// Build our font display list
{
	base = glGenLists(256);	// Creating 256 display lists
	glBindTexture(GL_TEXTURE_2D, textures[0].texID);	// Select our font texture
	for (int loop1=0; loop1<256; loop1++)			// Loop through all 256 lists
	{
		float cx=float(loop1%16)/16.0f;		// X position of current character
		float cy=float(loop1/16)/16.0f;		// Y position of current character

		glNewList(base+loop1,GL_COMPILE);	// Start building a list
			glBegin(GL_QUADS);					// Use a quad for each character
				glTexCoord2f(cx,1.0f-cy-0.0625f);		// Texture coord (Bottom left)
				glVertex2d(0,16);				// Vertex coord (Bottom left)
				glTexCoord2f(cx+0.0625f,1.0f-cy-0.0625f);	// Texture coord (Bottom right)
				glVertex2i(16,16);				// Vertex coord (Bottom right)
				glTexCoord2f(cx+0.0625f,1.0f-cy-0.001f);	// Texture coord (Top right)
				glVertex2i(16,0);				// Vertex coord (Top right)
				glTexCoord2f(cx,1.0f-cy-0.001f);		// Texture coord (Top left)
				glVertex2i(0,0);				// Vertex coord (Top left)
			glEnd();			// Done building our quad (Character)
			glTranslated(14,0,0);		// Move to the right of the character
		glEndList();				// Done building the display list
	}						// Loop until all 256 are built
}

GLvoid KillFont(GLvoid)			// Delete the font from memory
{
	glDeleteLists(base,256);	// Delete all 256 display lists
}

GLvoid glPrint(GLint x, GLint y, int set, const char *fmt, ...)         // Where the printing happens
{
	char text[1024];                // Holds our string
	va_list ap;			// Pointer to list of arguments

	if (fmt == NULL)		// If there's no text
		return;			// Do nothing

	va_start(ap, fmt);		// Parses the string for variables
	    vsprintf(text, fmt, ap);	// And converts symbols to actual numbers
	va_end(ap);			// Results are stored in text

	if (set>1)			// Did user choose an invalid character set?
	{
		set = 1;		// If so, select set 1 (Italic)
	}                               

	glEnable(GL_TEXTURE_2D);	// Enable texture mapping
	glLoadIdentity();		// Reset the modelview matrix
	glTranslated(x,y,0);		// Position the text (0,0 - Top left)
	glListBase(base-32+(128*set));	// Choose the font set (0 or 1)

	glScalef(1.0f,2.0f,1.0f);	// Make the text 2X taller

	glCallLists(strlen(text),GL_UNSIGNED_BYTE, text);	// Write the text to the screen
	glDisable(GL_TEXTURE_2D);				// Disable texture mapping
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)     // Resize and initialize the GL window
{
        swidth = width;				// Set scissor width to window width
	sheight = height;			// Set scissor height to window height
	if (height == 0) 			// Prevent a divide by zero by
	{
		height = 1;			// Making height equal one
	}
	glViewport(0,0,width,height);		// Reset the current viewport
	glMatrixMode(GL_PROJECTION);		// Select the projection matrix
	glLoadIdentity();			// Reset the projection matrix
	glOrtho(0.0f,640,480,0.0f,-1.0f,1.0f);	// Create ortho 640x480 view (0,0 At Top left)
	glMatrixMode(GL_MODELVIEW);		// Select the modelview matrix
	glLoadIdentity();			// Reset the modelview matrix
}

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
	if (!LoadTGA(&textures[0],"Data/Font.TGA"))	// Load the font texture
	{
		return false;				// If loading failed, return false
	}

	BuildFont();					// Build the font

	glShadeModel(GL_SMOOTH);			// Enable smooth shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);		// Black background
	glClearDepth(1.0f);				// Depth buffer setup
	glBindTexture(GL_TEXTURE_2D, textures[0].texID);// Select our font texture

	return true;            // Initialization went OK
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
	char *token;					    	// Storage for our token
	int cnt = 0;					    	// Local counter variable

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); 	// Clear screen and depth buffer

	glColor3f(1.0f,0.5f,0.5f);			    	// Set color to bright red
	glPrint(50,16,1,"Renderer");			    	// Display renderer
	glPrint(80,48,1,"Vendor"); 			    	// Display vendor name
	glPrint(66,80,1,"Version");			    	// Display version

	glColor3f(1.0f,0.7f,0.4f);			    	// Set color to orange
	glPrint(200,16,1,(char *)glGetString(GL_RENDERER)); 	// Display renderer
	glPrint(200,48,1,(char *)glGetString(GL_VENDOR));   	// Display vendor name
	glPrint(200,80,1,(char *)glGetString(GL_VERSION));  	// Display version

	glColor3f(0.5f,0.5f,1.0f);	      			// Set color to bright blue
	glPrint(192,432,1,"NeHe Productions");			// Write NeHe Productions at the bottom of the screen

	glLoadIdentity();	    				// Reset the modelview matrix
	glColor3f(1.0f,1.0f,1.0f);  				// Set the color to white
	glBegin(GL_LINE_STRIP);	    				// Start drawing line strips (Something new)
		glVertex2d(639,417);				// Top right of bottom box
		glVertex2d(  0,417);				// Top left of bottom box
		glVertex2d(  0,480);				// Lower left of bottom box
		glVertex2d(639,480);				// Lower right of bottom box
		glVertex2d(639,128);				// Up to bottom right of top box
	glEnd();						// Done first line strip
	glBegin(GL_LINE_STRIP);	    				// Start drawing another line strip
		glVertex2d(  0,128);				// Bottom left of top box
		glVertex2d(639,128);				// Bottom right of top box
		glVertex2d(639,  1);				// Top right of top box
		glVertex2d(  0,  1);				// Top left of top box
		glVertex2d(  0,417);				// Down to top left of bottom box
	glEnd();		    				// Done second line strip

	glScissor(1	,int(0.135416f*sheight),swidth-2,int(0.597916f*sheight));	// Define scissor region
	glEnable(GL_SCISSOR_TEST);							// Enable scissor testing

	char* text=(char *)malloc(strlen((char *)glGetString(GL_EXTENSIONS))+1);	// Allocate memory for our extension string
	strcpy (text,(char *)glGetString(GL_EXTENSIONS));	// Grab the extension list, store in text

	token=strtok(text," ");		// Parse 'text' for words, seperated by " " (spaces)
	while(token!=NULL)		// While the token isn't NULL
	{
		cnt++;			// Increase the counter
		if (cnt>maxtokens)	// Is 'maxtokens' less than 'cnt'
		{
			maxtokens=cnt;	// If so, set 'maxtokens' equal to 'cnt'
		}

		glColor3f(0.5f,1.0f,0.5f);	         	// Set color to bright green
		glPrint(0,96+(cnt*32)-scroll,0,"%i",cnt);   	// Print current extension number
		glColor3f(1.0f,1.0f,0.5f);	       		// Set color to yellow
		glPrint(50,96+(cnt*32)-scroll,0,token);		// Print the current token (Parsed extension name)
		token=strtok(NULL," ");		       		// Search for the next token
	}

	glDisable(GL_SCISSOR_TEST);     // Disable scissor testing

	free(text);	// Free allocated memory

	glFlush();

	return true;    // Everything went OK
}

GLvoid KillGLWindow(GLvoid)     // Properly kill the window
{
	if (fullscreen)         // Are we in fullscreen mode?
	{
		ChangeDisplaySettings(NULL,0);  // If so switch back to the desktop
		ShowCursor(true);               // Show mouse pointer
	}

	if (hRC)        // Do we have a rendering context?
	{
		if (!wglMakeCurrent(NULL,NULL))         // Are we able to release the DC and RC contexts?
		{
			MessageBox(NULL,"Release of DC and RC failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))             // Are we able to delete the RC?
		{
			MessageBox(NULL,"Release rendering context failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC = NULL;             // Set RC to NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))        // Are we able to release the DC
	{
		MessageBox(NULL,"Release device context failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC = NULL;             // Set DC to NULL
	}

	if (hWnd && !DestroyWindow(hWnd))       // Are we able to destroy the window?
	{
		MessageBox(NULL,"Could not release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd = NULL;            // Set hWnd to NULL
	}

	if (!UnregisterClass("OpenGL",hInstance))       // Are we able to unregister class
	{
		MessageBox(NULL,"Could not unregister class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance = NULL;       // Set hInstance to NULL
	}

        KillFont();             // Kill the font
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:
 *	title			- Title To Appear At The Top Of The Window
 *	width			- Width Of The GL Window Or Fullscreen Mode
 *	height			- Height Of The GL Window Or Fullscreen Mode
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	GLuint		PixelFormat;		// Holds the results after searching for a match
	WNDCLASS	wc;		        // Windows class structure
	DWORD		dwExStyle;              // Window extended style
	DWORD		dwStyle;                // Window style
	RECT		WindowRect;             // Grabs rctangle upper left / lower right values
	WindowRect.left = (long)0;              // Set left value to 0
	WindowRect.right = (long)width;		// Set right value to requested width
	WindowRect.top = (long)0;               // Set top value to 0
	WindowRect.bottom = (long)height;       // Set bottom value to requested height

	fullscreen = fullscreenflag;              // Set the global fullscreen flag

	hInstance               = GetModuleHandle(NULL);		// Grab an instance for our window
	wc.style                = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;   // Redraw on size, and own DC for window
	wc.lpfnWndProc          = (WNDPROC) WndProc;			// WndProc handles messages
	wc.cbClsExtra           = 0;					// No extra window data
	wc.cbWndExtra           = 0;					// No extra window data
	wc.hInstance            = hInstance;				// Set the Instance
	wc.hIcon                = LoadIcon(NULL, IDI_WINLOGO);		// Load the default icon
	wc.hCursor              = LoadCursor(NULL, IDC_ARROW);		// Load the arrow pointer
	wc.hbrBackground        = NULL;					// No background required for GL
	wc.lpszMenuName		= NULL;					// We don't want a menu
	wc.lpszClassName	= "OpenGL";				// Set the class name

	if (!RegisterClass(&wc))					// Attempt to register the window class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);

		return false;   // Return FALSE
	}
	
	if (fullscreen)         // Attempt fullscreen mode?
	{
		DEVMODE dmScreenSettings;                                       // Device mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	        // Makes sure memory's cleared
		dmScreenSettings.dmSize         = sizeof(dmScreenSettings);     // Size of the devmode structure
		dmScreenSettings.dmPelsWidth	= width;                        // Selected screen width
		dmScreenSettings.dmPelsHeight	= height;                       // Selected screen height
		dmScreenSettings.dmBitsPerPel	= bits;	                        // Selected bits per pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try to set selected mode and get results. NOTE: CDS_FULLSCREEN gets rid of start bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If the mode fails, offer two options. Quit or use windowed mode.
			if (MessageBox(NULL,"The requested fullscreen mode is not supported by\nyour video card. Use windowed mode instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen = false;       // Windowed mode selected. Fullscreen = FALSE
			}
			else
			{
				// Pop up a message box letting user know the program is closing.
				MessageBox(NULL,"Program will now close.","ERROR",MB_OK|MB_ICONSTOP);
				return false;           // Return FALSE
			}
		}
	}

	if (fullscreen)                         // Are We Still In Fullscreen Mode?
	{
		dwExStyle = WS_EX_APPWINDOW;    // Window extended style
		dwStyle = WS_POPUP;		// Windows style
		ShowCursor(false);		// Hide mouse pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;           // Window extended style
		dwStyle=WS_OVERLAPPEDWINDOW;                            // Windows style
	}

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);     // Adjust window to true requested size

	// Create the window
	if (!(hWnd = CreateWindowEx(dwExStyle,          // Extended Style For The Window
                "OpenGL",				// Class name
		title,					// Window title
		dwStyle |				// Defined window style
		WS_CLIPSIBLINGS |			// Required window style
		WS_CLIPCHILDREN,			// Required window style
		0, 0,					// Window position
		WindowRect.right-WindowRect.left,	// Calculate window width
		WindowRect.bottom-WindowRect.top,	// Calculate window height
		NULL,					// No parent window
		NULL,					// No menu
		hInstance,				// Instance
		NULL)))					// Dont pass anything to WM_CREATE
	{
		KillGLWindow();                         // Reset the display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;                           // Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd =             // pfd tells windows how we want things to be
	{
		sizeof(PIXELFORMATDESCRIPTOR),          // Size of this pixel format descriptor
		1,					// Version number
		PFD_DRAW_TO_WINDOW |			// Format must support window
		PFD_SUPPORT_OPENGL |			// Format must support OpenGL
		PFD_DOUBLEBUFFER,			// Must support double buffering
		PFD_TYPE_RGBA,				// Request an RGBA format
		bits,					// Select our color depth
		0, 0, 0, 0, 0, 0,			// Color bits ignored
		0,					// No alpha buffer
		0,					// Shift bit ignored
		0,					// No accumulation buffer
		0, 0, 0, 0,				// Accumulation bits ignored
		16,					// 16Bit Z-Buffer (Depth buffer)
		0,					// No stencil buffer
		0,					// No auxiliary buffer
		PFD_MAIN_PLANE,				// Main drawing layer
		0,					// Reserved
		0, 0, 0					// Layer masks ignored
	};
	
	if (!(hDC=GetDC(hWnd)))         // Did we get a device context?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't create a GL device context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))	// Did windows find a matching pixel format?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't find a suitable pixelformat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))       // Are we able to set the pixel format?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't set the pixelformat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))               // Are we able to get a rendering context?
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't create a GL rendering context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))    // Try to activate the rendering context
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Can't activate the GL rendering context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);       // Show the window
	SetForegroundWindow(hWnd);      // Slightly higher priority
	SetFocus(hWnd);                 // Sets keyboard focus to the window
	ReSizeGLScene(width, height);   // Set up our perspective GL screen

	if (!InitGL())                  // Initialize our newly created GL window
	{
		KillGLWindow();         // Reset the display
		MessageBox(NULL,"Initialization failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return false;           // Return FALSE
	}

	return true;                    // Success
}

LRESULT CALLBACK WndProc(HWND hWnd,     // Handle for this window
                        UINT uMsg,      // Message for this window
			WPARAM wParam,  // Additional message information
			LPARAM lParam)  // Additional message information
{
	switch (uMsg)                           // Check for windows messages
	{
		case WM_ACTIVATE:               // Watch for window activate message
		{
			if (!HIWORD(wParam))    // Check minimization state
			{
				active = true;  // Program is active
			}
			else
			{
				active = false; // Program is no longer active
			}

			return 0;               // Return to the message loop
		}

		case WM_SYSCOMMAND:             // Intercept system commands
		{
			switch (wParam)         // Check system calls
			{
				case SC_SCREENSAVE:     // Screensaver trying to start?
				case SC_MONITORPOWER:	// Monitor trying to enter powersave?
				return 0;       // Prevent from happening
			}
			break;                  // Exit
		}

		case WM_CLOSE:                  // Did we receive a close message?
		{
			PostQuitMessage(0);     // Send a quit message
			return 0;               // Jump back
		}

		case WM_KEYDOWN:                // Is a key being held down?
		{
			keys[wParam] = true;    // If so, mark it as TRUE
			return 0;               // Jump back
		}

		case WM_KEYUP:                  // Has a key been released?
		{
			keys[wParam] = false;   // If so, mark it as FALSE
			return 0;               // Jump back
		}

		case WM_SIZE:                   // Resize the OpenGL window
		{
			ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord = Width, HiWord = Height
			return 0;               // Jump back
		}
	}

	// Pass all unhandled messages to DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
        MSG msg;                // Windows message structure
	bool done = false;      // Bool variable to exit loop

	// Ask the user which screen mode they prefer
	if (MessageBox(NULL,"Would you like to run in fullscreen mode?", "Start FullScreen?",MB_YESNO|MB_ICONQUESTION)==IDNO)
	{
		fullscreen = false;       // Windowed mode
	}

	// Create our OpenGL window
	if (!CreateGLWindow("NeHe's Token, Extensions, Scissoring & TGA Loading Tutorial",640,480,16,fullscreen))
	{
		return 0;               // Quit if window was not created
	}

	while(!done)            // Loop that runs while done = FALSE
	{
		if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))	// Is there a message waiting?
		{
			if (msg.message == WM_QUIT)             // Have we received a quit message?
			{
				done = true;                    // If so done = TRUE
			}
			else                                    // If not, deal with window messages
			{
				TranslateMessage(&msg);         // Translate the message
				DispatchMessage(&msg);          // Dispatch the message
			}
		}
		else            // If there are no messages
		{
			// Draw the scene. Watch for ESC key and quit messages from DrawGLScene()
			if ((active && !DrawGLScene()) || keys[VK_ESCAPE])	// Active?  Was there a quit received?
			{
				done=TRUE;				// ESC or DrawGLScene signalled a quit
			}
			else						// Not time to quit, update screen
			{
				SwapBuffers(hDC);			// Swap buffers (double buffering)

				if (keys[VK_F1])			// Is F1 being pressed?
				{
					keys[VK_F1]=FALSE;		// If so make key FALSE
					KillGLWindow();			// Kill our current window
					fullscreen=!fullscreen;		// Toggle fullscreen / windowed mode
					// Recreate Our OpenGL Window
					if (!CreateGLWindow("NeHe's Token, Extensions, Scissoring & TGA Loading Tutorial",640,480,16,fullscreen))
					{
						return 0;		// Quit if window was not created
					}
				}

				if (keys[VK_UP] && (scroll>0))		// Is up arrow being pressed?
				{
					scroll-=2;			// If so, decrease 'scroll' moving screen down
				}

				if (keys[VK_DOWN] && (scroll<32*(maxtokens-9)))	// Is down arrow being pressed?
				{
					scroll+=2;			// If so, increase 'scroll' moving screen up
				}
			}
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//---------------------------------------------------------------------------
