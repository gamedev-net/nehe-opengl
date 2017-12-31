//---------------------------------------------------------------------------

#include <vcl.h>
#include <windows.h>    // Header file for windows
#include <stdio.h>	// Standard Input / Output
#include <stdarg.h>	// Header file for variable argument routines
#include <mmsystem.h>   // Header file needed to access the timeGetTime() fucntion in BCB6
#include <gl\gl.h>      // Header file for the OpenGL32 library
#include <gl\glu.h>     // Header file for the GLu32 library
#include <gl\glaux.h>   // Header file for the GLaux library
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

bool vline[11][10];		// Keeps track of verticle lines
bool hline[10][11];		// Keeps track of horizontal lines
bool ap;			// 'A' key pressed?
bool filled;			// Done filling in the grid?
bool gameover;		        // Is the game over?
bool anti = true;       	// Antialiasing?

int loop1;	        	// Generic loop1
int loop2;      		// Generic loop2
int delay;		        // Enemy delay
int adjust = 3;                 // Speed adjustment for really slow video cards
int lives = 5;                  // Player lives
int level = 1;	                // Internal game level
int level2 = level;     	// Displayed game level
int stage = 1;	                // Game stage

struct object			// Create a structure for our player
{
	int fx, fy;		// Fine movement position
	int x, y;		// Current player position
	float spin;		// Spin direction
};

struct object player;		// Player information
struct object enemy[9]; 	// Enemy information
struct object hourglass;	// Hourglass information

struct			 	// Create a structure for the timer information
{
        __int64 frequency;	                // Timer frequency
        float resolution;               	// Timer resolution
        unsigned long mm_timer_start;   	// Multimedia timer start value
        unsigned long mm_timer_elapsed; 	// Multimedia timer elapsed time
        bool performance_timer;	        	// Using the performance timer?
        __int64 performance_timer_start;        // Performance timer start value
        __int64 performance_timer_elapsed;	// Performance timer elapsed time
} timer;					// Structure is named timer

int steps[6]={ 1, 2, 4, 5, 10, 20 };            // Stepping values for slow video adjustment

GLuint texture[2];		// Font texture storage space
GLuint base;

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);   // Declaration for WndProc

void TimerInit(void)	        // Initialize our timer (Get it ready)
{
	memset(&timer, 0, sizeof(timer));		// Clear our timer structure

	// Check to see if a performance counter is available
	// If one is available the timer frequency will be updated
	if (!QueryPerformanceFrequency((LARGE_INTEGER *) &timer.frequency))
	{
		// No Performace Counter Available
		timer.performance_timer	= false;        	// Set performance timer to FALSE
		timer.mm_timer_start = timeGetTime();           // Use timeGetTime() to get current time
		timer.resolution = 1.0f/1000.0f;                // Set our timer resolution to .001f
		timer.frequency	= 1000;		        	// Set our timer frequency to 1000
		timer.mm_timer_elapsed = timer.mm_timer_start;  // Set the elapsed time to the current time
	}
	else
	{
		// Performance counter is available, use it instead of the multimedia timer
		// Get the current time and store it in performance_timer_start
		QueryPerformanceCounter((LARGE_INTEGER *) &timer.performance_timer_start);
		timer.performance_timer = true;                 // Set performance timer to TRUE
		// Calculate the timer resolution using the timer frequency
		timer.resolution = (float) (((double)1.0f)/((double)timer.frequency));
		// Set the elapsed time to the current time
		timer.performance_timer_elapsed	= timer.performance_timer_start;
	}
}

float TimerGetTime()            // Get time in milliseconds
{
	__int64 time;		// time will hold a 64 bit integer

	if (timer.performance_timer)    // Are we using the performance timer?
	{
		QueryPerformanceCounter((LARGE_INTEGER *) &time);	// Grab the current performance time
		// Return the current time minus the start time multiplied by the resolution and 1000 (To get MS)
		return ( (float) ( time - timer.performance_timer_start) * timer.resolution)*1000.0f;
	}
	else
	{
		// Return the current time minus the start time multiplied by the resolution and 1000 (To get MS)
		return( (float) ( timeGetTime() - timer.mm_timer_start) * timer.resolution)*1000.0f;
	}
}

void ResetObjects(void)	        // Reset player and enemies
{
	player.x = 0;		// Reset player X position to far left of the screen
	player.y = 0;		// Reset player Y position to the top of the screen
	player.fx = 0;		// Set fine X position to match
	player.fy = 0;		// Set fine Y position to match

	for (loop1 = 0; loop1 < (stage*level); loop1++) // Loop through all the enemies
	{
		enemy[loop1].x = 5+rand()%6;		// Select a random X position
		enemy[loop1].y = rand()%11;		// Select a random Y position
		enemy[loop1].fx = enemy[loop1].x*60;	// Set fine X to match
		enemy[loop1].fy = enemy[loop1].y*40;	// Set fine Y to match
	}
}

AUX_RGBImageRec *LoadBMP(char *Filename)        // Loads the bitmap images
{
		FILE *File = NULL;		// File handle
		if (!Filename)			// Make sure a filename was given
		{
			return NULL;		// If not return NULL
		}
		File = fopen(Filename,"r");     // Check to see if the file exists
		if (File)			// Does the file exist?
		{
			fclose(File);	        // Close the handle
			return auxDIBImageLoad(Filename);       // Load the bitmap and return a pointer
		}
		return NULL;			// If load failed return NULL
}

int LoadGLTextures()    // Load bitmaps and convert to textures
{
        int Status = false;                             // Status indicator
        AUX_RGBImageRec *TextureImage[2];               // Create storage space for the textures
        memset(TextureImage,0,sizeof(void *)*2);        // Set the pointer to NULL

        if ((TextureImage[0]=LoadBMP("Data/Font.bmp")) &&               // Load the font
			(TextureImage[1]=LoadBMP("Data/Image.bmp")))	// Load background image
        {
			Status = true;                          // Set the status to TRUE

			glGenTextures(2, &texture[0]);		// Create the texture

			for (loop1 = 0; loop1 < 2; loop1++)	// Loop through 2 textures
			{
				glBindTexture(GL_TEXTURE_2D, texture[loop1]);
				glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage[loop1]->sizeX, TextureImage[loop1]->sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage[loop1]->data);
				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			}

			for (loop1=0; loop1<2; loop1++)		                // Loop through 2 textures
			{
				if (TextureImage[loop1])                	// If texture exists
				{
					if (TextureImage[loop1]->data)          // If texture image exists
					{
						free(TextureImage[loop1]->data);// Free the texture image memory
					}
					free(TextureImage[loop1]);		// Free the image structure
				}
			}
		}
	return Status;          // Return the status
}

GLvoid BuildFont(GLvoid)        // Build our font display list
{
	base=glGenLists(256);	                        // Creating 256 display lists
	glBindTexture(GL_TEXTURE_2D, texture[0]);	// Select our font texture
	for (loop1 = 0; loop1 < 256; loop1++)		// Loop through all 256 lists
	{
		float cx=float(loop1%16)/16.0f;		// X position of current character
		float cy=float(loop1/16)/16.0f;		// Y position of current character

		glNewList(base+loop1,GL_COMPILE);	// Start building a list
			glBegin(GL_QUADS);		                        // Use a quad for each character
				glTexCoord2f(cx,1.0f-cy-0.0625f);               // Texture coord (Bottom left)
				glVertex2d(0,16);				// Vertex coord (Bottom left)
				glTexCoord2f(cx+0.0625f,1.0f-cy-0.0625f);	// Texture coord (Bottom right)
				glVertex2i(16,16);				// Vertex coord (Bottom right)
				glTexCoord2f(cx+0.0625f,1.0f-cy);		// Texture coord (Top right)
				glVertex2i(16,0);				// Vertex coord (Top right)
				glTexCoord2f(cx,1.0f-cy);			// Texture coord (Top left)
				glVertex2i(0,0);				// Vertex coord (Top left)
			glEnd();						// Done building our quad (Character)
			glTranslated(15,0,0);		// Move to rhe right of the character
		glEndList();				// Done building the display list
	}						// Loop until all 256 are built
}

GLvoid KillFont(GLvoid)                 // Delete the font from memory
{
	glDeleteLists(base,256);	// Delete all 256 display lists
}

GLvoid glPrint(GLint x, GLint y, int set, const char *fmt, ...) // Where the printing happens
{
	char text[256];                 // Holds our string
	va_list ap;			// Pointer to list of arguments

	if (fmt == NULL)		// If there's no text
		return;			// Do nothing

	va_start(ap, fmt);		// Parses the string for variables
	    vsprintf(text, fmt, ap);	// And converts symbols to actual numbers
	va_end(ap);			// Results are stored in text

	if (set > 1)			// Did user choose an invalid character set?
	{
		set = 1;		// If so, select set 1 (Italic)
	}
	glEnable(GL_TEXTURE_2D);	// Enable texture mapping
	glLoadIdentity();		// Reset the modelview matrix
	glTranslated(x,y,0);		// Position the text (0,0 - Bottom left)
	glListBase(base-32+(128*set));	// Choose the font set (0 or 1)

	if (set == 0)			// If set 0 is being used enlarge font
	{
		glScalef(1.5f,2.0f,1.0f);       // Enlarge font width and height
	}

	glCallLists(strlen(text),GL_UNSIGNED_BYTE, text);       // Write the text to the screen
	glDisable(GL_TEXTURE_2D);				// Disable texture mapping
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)     // Resize and initialize the GL window
{
        if (height==0)					// Prevent a divide by zero by
	{
		height=1;				// Making height equal one
	}

	glViewport(0,0,width,height);			// Reset the current viewport

	glMatrixMode(GL_PROJECTION);			// Select the projection matrix
	glLoadIdentity();				// Reset the projection matrix

	glOrtho(0.0f,width,height,0.0f,-1.0f,1.0f);	// Create ortho 640x480 view (0,0 At top left)

	glMatrixMode(GL_MODELVIEW);			// Select the modelview matrix
	glLoadIdentity();				// Reset the modelview matrix
}

int InitGL(GLvoid)      // All setup for OpenGL goes here
{
        if (!LoadGLTextures())			// Jump to texture loading routine
	{
		return false;			// If texture didn't load return FALSE
	}

	BuildFont();                            // Build the font

	glShadeModel(GL_SMOOTH);                // Enable smooth shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);   // Black background
	glClearDepth(1.0f);                     // Depth buffer setup
        glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);	// Set line antialiasing
        glEnable(GL_BLEND);			// Enable nlending
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);      // Type of blending to use

	return true;                            // Initialization went OK
}

int DrawGLScene(GLvoid)         // Here's where we do all the drawing
{
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear screen and depth buffer
	glBindTexture(GL_TEXTURE_2D, texture[0]);			// Select our font texture
	glColor3f(1.0f,0.5f,1.0f);					// Set color to purple
	glPrint(207,24,0,"GRID CRAZY");					// Write GRID CRAZY on the screen
	glColor3f(1.0f,1.0f,0.0f);					// Set color to yellow
	glPrint(20,20,1,"Level:%2i",level2);				// Write actual level stats
	glPrint(20,40,1,"Stage:%2i",stage);				// Write stage stats

	if (gameover)							// Is the game over?
	{
		glColor3ub(rand()%255,rand()%255,rand()%255);		// Pick a random color
		glPrint(472,20,1,"GAME OVER");				// Write GAME OVER to the screen
		glPrint(456,40,1,"PRESS SPACE");			// Write PRESS SPACE to the screen
	}

	for (loop1=0; loop1<lives-1; loop1++)				// Loop through lives minus current life
	{
		glLoadIdentity();					// Reset the view
		glTranslatef(490+(loop1*40.0f),40.0f,0.0f);		// Move to the right of our title text
		glRotatef(-player.spin,0.0f,0.0f,1.0f);			// Rotate counter clockwise
		glColor3f(0.0f,1.0f,0.0f);				// Set player color to light green
		glBegin(GL_LINES);					// Start drawing our player using lines
			glVertex2d(-5,-5);				// Top left of player
			glVertex2d( 5, 5);				// Bottom right of player
			glVertex2d( 5,-5);				// Top right of player
			glVertex2d(-5, 5);				// Bottom left of player
		glEnd();						// Done drawing the player
		glRotatef(-player.spin*0.5f,0.0f,0.0f,1.0f);		// Rotate counter clockwise
		glColor3f(0.0f,0.75f,0.0f);				// Set player color to dark green
		glBegin(GL_LINES);					// Start drawing our player using lines
			glVertex2d(-7, 0);				// Left center of player
			glVertex2d( 7, 0);				// Right center of player
			glVertex2d( 0,-7);				// Top center of player
			glVertex2d( 0, 7);				// Bottom center of player
		glEnd();						// Done drawing the player
	}

	filled=TRUE;							// Set filled to true before testing
	glLineWidth(2.0f);						// Set line width for cells to 2.0f
	glDisable(GL_LINE_SMOOTH);					// Disable antialiasing
	glLoadIdentity();						// Reset the current modelview matrix
	for (loop1 = 0; loop1 < 11; loop1++)				// Loop from left to right
	{
		for (loop2 = 0; loop2 < 11; loop2++)			// Loop from top to bottom
		{
			glColor3f(0.0f,0.5f,1.0f);			// Set line color to blue
			if (hline[loop1][loop2])			// Has the horizontal line been traced
			{
				glColor3f(1.0f,1.0f,1.0f);		// If so, set line color to white
			}

			if (loop1<10)					// Dont draw to far right
			{
				if (!hline[loop1][loop2])		// If a horizontal line isn't filled
				{
					filled = false;			// filled becomes false
				}
				glBegin(GL_LINES);			// Start drawing horizontal cell borders
					glVertex2d(20+(loop1*60),70+(loop2*40));// Left side of horizontal line
					glVertex2d(80+(loop1*60),70+(loop2*40));// Right side of horizontal line
				glEnd();				// Done Drawing Horizontal Cell Borders
			}

			glColor3f(0.0f,0.5f,1.0f);			// Set line color to blue
			if (vline[loop1][loop2])			// Has the horizontal line been traced
			{
				glColor3f(1.0f,1.0f,1.0f);		// If so, set line color to white
			}
			if (loop2<10)					// Dont draw to far down
			{
				if (!vline[loop1][loop2])		// If a verticle line isn't filled
				{
					filled=FALSE;			// filled becomes false
				}
				glBegin(GL_LINES);			// Start drawing verticle cell borders
					glVertex2d(20+(loop1*60),70+(loop2*40));// Left side of horizontal line
					glVertex2d(20+(loop1*60),110+(loop2*40));// Right side of horizontal line
				glEnd();				// Done drawing verticle cell borders
			}

			glEnable(GL_TEXTURE_2D);			// Enable texture mapping
			glColor3f(1.0f,1.0f,1.0f);			// Bright white color
			glBindTexture(GL_TEXTURE_2D, texture[1]);	// Select the tile image
			if ((loop1<10) && (loop2<10))			// If in bounds, fill in traced boxes
			{
				// Are all sides of the box traced?
				if (hline[loop1][loop2] && hline[loop1][loop2+1] && vline[loop1][loop2] && vline[loop1+1][loop2])
				{
					glBegin(GL_QUADS);		// Draw a textured quad
						glTexCoord2f(float(loop1/10.0f)+0.1f,1.0f-(float(loop2/10.0f)));
						glVertex2d(20+(loop1*60)+59,(70+loop2*40+1));	// Top Right
						glTexCoord2f(float(loop1/10.0f),1.0f-(float(loop2/10.0f)));
						glVertex2d(20+(loop1*60)+1,(70+loop2*40+1));	// Top Left
						glTexCoord2f(float(loop1/10.0f),1.0f-(float(loop2/10.0f)+0.1f));
						glVertex2d(20+(loop1*60)+1,(70+loop2*40)+39);	// Bottom Left
						glTexCoord2f(float(loop1/10.0f)+0.1f,1.0f-(float(loop2/10.0f)+0.1f));
						glVertex2d(20+(loop1*60)+59,(70+loop2*40)+39);	// Bottom Right
					glEnd();			// Done texturing the box
				}
			}
			glDisable(GL_TEXTURE_2D);			// Disable texture mapping
		}
	}
	glLineWidth(1.0f);						// Set the line width to 1.0f

	if (anti)							// Is anti TRUE?
	{
		glEnable(GL_LINE_SMOOTH);				// If so, enable antialiasing
	}

	if (hourglass.fx==1)						// If fx = 1 draw the hourglass
	{
		glLoadIdentity();					// Reset the modelview matrix
		glTranslatef(20.0f+(hourglass.x*60),70.0f+(hourglass.y*40),0.0f);	// Move to the fine hourglass position
		glRotatef(hourglass.spin,0.0f,0.0f,1.0f);		// Rotate clockwise
		glColor3ub(rand()%255,rand()%255,rand()%255);		// Set hourglass color to random color
		glBegin(GL_LINES);					// Start drawing our hourglass using lines
			glVertex2d(-5,-5);				// Top left of hourglass
			glVertex2d( 5, 5);				// Bottom right of hourglass
			glVertex2d( 5,-5);				// Top right of hourglass
			glVertex2d(-5, 5);				// Bottom left of hourglass
			glVertex2d(-5, 5);				// Bottom left of hourglass
			glVertex2d( 5, 5);				// Bottom right of hourglass
			glVertex2d(-5,-5);				// Top left of hourglass
			glVertex2d( 5,-5);				// Top right of hourglass
		glEnd();						// Done drawing the hourglass
	}

	glLoadIdentity();						// Reset the modelview matrix
	glTranslatef(player.fx+20.0f,player.fy+70.0f,0.0f);		// Move to the fine player position
	glRotatef(player.spin,0.0f,0.0f,1.0f);				// Rotate clockwise
	glColor3f(0.0f,1.0f,0.0f);					// Set player color to light green
	glBegin(GL_LINES);						// Start drawing our player using lines
		glVertex2d(-5,-5);					// Top left of player
		glVertex2d( 5, 5);					// Bottom right of player
		glVertex2d( 5,-5);					// Top right of player
		glVertex2d(-5, 5);					// Bottom left of player
	glEnd();							// Done drawing the player
	glRotatef(player.spin*0.5f,0.0f,0.0f,1.0f);			// Rotate clockwise
	glColor3f(0.0f,0.75f,0.0f);					// Set player color to dark green
	glBegin(GL_LINES);						// Start drawing our player using lines
		glVertex2d(-7, 0);					// Left center of player
		glVertex2d( 7, 0);					// Right center of player
		glVertex2d( 0,-7);					// Top center of player
		glVertex2d( 0, 7);					// Bottom center of player
	glEnd();							// Done drawing the player

	for (loop1=0; loop1<(stage*level); loop1++)			// Loop to draw enemies
	{
		glLoadIdentity();					// Reset the modelview matrix
		glTranslatef(enemy[loop1].fx+20.0f,enemy[loop1].fy+70.0f,0.0f);
		glColor3f(1.0f,0.5f,0.5f);				// Make enemy body pink
		glBegin(GL_LINES);					// Start drawing enemy
			glVertex2d( 0,-7);				// Top point of body
			glVertex2d(-7, 0);				// Left point of body
			glVertex2d(-7, 0);				// Left point of body
			glVertex2d( 0, 7);				// Bottom point of body
			glVertex2d( 0, 7);				// Bottom point of body
			glVertex2d( 7, 0);				// Right point of body
			glVertex2d( 7, 0);				// Right point of body
			glVertex2d( 0,-7);				// Top point of body
		glEnd();						// Done drawing enemy body
		glRotatef(enemy[loop1].spin,0.0f,0.0f,1.0f);		// Rotate the enemy blade
		glColor3f(1.0f,0.0f,0.0f);				// Make enemy blade red
		glBegin(GL_LINES);					// Start drawing enemy blade
			glVertex2d(-7,-7);				// Top left of enemy
			glVertex2d( 7, 7);				// Bottom right of enemy
			glVertex2d(-7, 7);				// Bottom left of enemy
			glVertex2d( 7,-7);				// Top right of enemy
		glEnd();						// Done drawing enemy blade
	}

	return true;            // Everything went OK
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

        KillFont();                     // Kill the font we built
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
	if (!CreateGLWindow("NeHe's Line Tutorial",640,480,16,fullscreen))
	{
		return 0;               // Quit if window was not created
	}

        ResetObjects();								// Set Player / Enemy Starting Positions
	TimerInit();								// Initialize The Timer

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
			float start=TimerGetTime();                             // Grab timer value before we draw
			
			// Draw the scene. Watch for ESC key and quit messages from DrawGLScene()
			if ((active && !DrawGLScene()) || keys[VK_ESCAPE])	// Active?  Was there a quit received?
			{
				done = true;					// ESC or DrawGLScene signalled a quit
			}
			else							// Not time to quit, update screen
			{
				SwapBuffers(hDC);				// Swap buffers (double buffering)
			}

			while(TimerGetTime()<start+float(steps[adjust]*2.0f)) {}// Waste cycles on fast systems

			if (keys[VK_F1])					// Is F1 being pressed?
			{
				keys[VK_F1]=FALSE;				// If so make key FALSE
				KillGLWindow();					// Kill our current window
				fullscreen=!fullscreen;				// Toggle fullscreen / windowed mode
				// Recreate Our OpenGL Window
				if (!CreateGLWindow("NeHe's Line Tutorial",640,480,16,fullscreen))
				{
					return 0;				// Quit if window was not created
				}
			}

			if (keys['A'] && !ap)					// If 'A' key is pressed and not held
			{
				ap=TRUE;					// ap becomes TRUE
				anti=!anti;					// Toggle antialiasing
			}
			if (!keys['A'])						// If 'A' key has been released
			{
				ap=FALSE;					// ap becomes FALSE
			}

			if (!gameover && active)				// If game isn't over and programs active move objects
			{
				for (loop1=0; loop1<(stage*level); loop1++)	// Loop through the different stages
				{
					if ((enemy[loop1].x<player.x) && (enemy[loop1].fy == enemy[loop1].y*40))
					{
						enemy[loop1].x++;		// Move the enemy right
					}

					if ((enemy[loop1].x>player.x) && (enemy[loop1].fy == enemy[loop1].y*40))
					{
						enemy[loop1].x--;		// Move the enemy left
					}

					if ((enemy[loop1].y<player.y) && (enemy[loop1].fx == enemy[loop1].x*60))
					{
						enemy[loop1].y++;		// Move the enemy down
					}

					if ((enemy[loop1].y>player.y) && (enemy[loop1].fx == enemy[loop1].x*60))
					{
						enemy[loop1].y--;		// Move the enemy up
					}

					if (delay>(3-level) && (hourglass.fx!=2))       	// If our delay is done and player doesn't have hourglass
					{
						delay=0;					// Reset the delay counter back to zero
						for (loop2=0; loop2<(stage*level); loop2++)	// Loop through all the enemies
						{
							if (enemy[loop2].fx<enemy[loop2].x*60)	// Is fine position on X axis lower than intended position?
							{
								enemy[loop2].fx+=steps[adjust];	// If so, increase fine position on X axis
								enemy[loop2].spin+=steps[adjust];       // Spin enemy clockwise
							}
							if (enemy[loop2].fx>enemy[loop2].x*60)	// Is fine position on X Axis higher than intended position?
							{
								enemy[loop2].fx-=steps[adjust];	// If So, Decrease Fine Position On X Axis
								enemy[loop2].spin-=steps[adjust];	// Spin enemy counter clockwise
							}
							if (enemy[loop2].fy<enemy[loop2].y*40)	// Is fine position on Y Axis lower than intended position?
							{
								enemy[loop2].fy+=steps[adjust];	// If So, Increase Fine Position On Y Axis
								enemy[loop2].spin+=steps[adjust];	// Spin enemy clockwise
							}
							if (enemy[loop2].fy>enemy[loop2].y*40)	// Is fine position on Y Axis higher than intended position?
							{
								enemy[loop2].fy-=steps[adjust];	// If So, Decrease Fine Position On Y Axis
								enemy[loop2].spin-=steps[adjust];	// Spin enemy counter clockwise
							}
						}
					}

					// Are any of the enemies on top of the player?
					if ((enemy[loop1].fx == player.fx) && (enemy[loop1].fy == player.fy))
					{
						lives--;			// If so, player loses a life

						if (lives == 0)			// Are we out of lives?
						{
							gameover = true;	// If so, gameover becomes TRUE
						}

						ResetObjects();			// Reset player / enemy positions
						PlaySound("Data/Die.wav", NULL, SND_SYNC);	// Play the death sound
					}
				}

				if (keys[VK_RIGHT] && (player.x < 10) && (player.fx == player.x*60) && (player.fy == player.y*40))
				{
					hline[player.x][player.y] = true;	// Mark the current horizontal border as filled
					player.x++;				// Move the player right
				}
				if (keys[VK_LEFT] && (player.x > 0) && (player.fx == player.x*60) && (player.fy == player.y*40))
				{
					player.x--;				// Move the player left
					hline[player.x][player.y] = true;	// Mark the current horizontal border as filled
				}
				if (keys[VK_DOWN] && (player.y < 10) && (player.fx == player.x*60) && (player.fy == player.y*40))
				{
					vline[player.x][player.y] = true;	// Mark the current verticle border as filled
					player.y++;				// Move the player down
				}
				if (keys[VK_UP] && (player.y > 0) && (player.fx == player.x*60) && (player.fy == player.y*40))
				{
					player.y--;				// Move the player up
					vline[player.x][player.y] = true;	// Mark the current verticle border as filled
				}

				if (player.fx < player.x*60)			// Is fine position on X axis lower than intended position?
				{
					player.fx += steps[adjust];		// If so, increase the fine X position
				}
				if (player.fx > player.x*60)			// Is fine position on X axis greater than intended position?
				{
					player.fx -= steps[adjust];		// If so, decrease the fine X position
				}
				if (player.fy < player.y*40)			// Is fine position on Y axis lower than intended position?
				{
					player.fy += steps[adjust];		// If so, increase the fine Y position
				}
				if (player.fy > player.y*40)			// Is fine position on Y axis lower than intended position?
				{
					player.fy -= steps[adjust];		// If so, decrease the fine Y position
				}
			}
			else					// Otherwise
			{
				if (keys[' '])			// If spacebar is being pressed
				{
					gameover=FALSE;		// gameover becomes FALSE
					filled=TRUE;		// filled becomes TRUE
					level=1;		// Starting level is set back to one
					level2=1;		// Displayed level is also set to one
					stage=0;		// Game stage is set to zero
					lives=5;		// Lives is set to five
				}
			}

			if (filled)				// Is the grid filled in?
			{
				PlaySound("Data/Complete.wav", NULL, SND_SYNC);	        // If so, play the level complete sound
				stage++;						// Increase the stage
				if (stage>3)						// Is the stage higher than 3?
				{
					stage=1;					// If so, set the stage to one
					level++;					// Increase the level
					level2++;					// Increase the displayed level
					if (level > 3)					// Is the level greater than 3?
					{
						level = 3;				// If so, set the level to 3
						lives++;				// Give the player a free life
						if (lives > 5)				// Does the player have more than 5 lives?
						{
							lives = 5;			// If so, set lives to Five
						}
					} 
				}

				ResetObjects();						// Reset payer / eemy psitions

				for (loop1=0; loop1 < 11; loop1++)			// Loop trough te gid X coordinates
				{
					for (loop2 = 0; loop2 < 11; loop2++)		// Loop through the grid Y coordinates
					{
						if (loop1 < 10)				// If X coordinate is less than 10
						{
							hline[loop1][loop2] = false;	// Set the current horizontal value to FALSE
						}
						if (loop2 < 10)			    	// If Y coordinate is less than 10
						{
							vline[loop1][loop2] = false;	// Set the current vertical value to FALSE
						}
					}
				}
			}

			// If the player hits the hourglass while it's beingdDisplayed on the screen
			if ((player.fx == hourglass.x*60) && (player.fy == hourglass.y*40) && (hourglass.fx==1))
			{
				// Play freeze enemy sound
				PlaySound("Data/freeze.wav", NULL, SND_ASYNC | SND_LOOP);
				hourglass.fx = 2;                                       // Set the hourglass fx variable to two
				hourglass.fy = 0;					// Set the hourglass fy variable to zero
			}

			player.spin+=0.5f*steps[adjust];				// Spin the player clockwise
			if (player.spin>360.0f)						// Is the spin value greater than 360?
			{
				player.spin-=360;					// If so, subtract 360
			}

			hourglass.spin -= 0.25f*steps[adjust];				// Spin the hourglass counter clockwise
			if (hourglass.spin < 0.0f)					// Is the spin value less than 0?
			{
				hourglass.spin += 360.0f;				// If so, add 360
			}

			hourglass.fy += steps[adjust];					// Increase the hourglass fy variable
			if ((hourglass.fx == 0) && (hourglass.fy > 6000/level))	        // Is the hourglass fx variable equal to 0 and The fy
			{								// Variable greater than 6000 divided by the current level?
				PlaySound("Data/hourglass.wav", NULL, SND_ASYNC);	// If so, play the hourglass appears sound
				hourglass.x = rand()%10+1;      			// Give the hourglass a random X value
				hourglass.y = rand()%11;				// Give the hourglass a random Y value
				hourglass.fx = 1;					// Set hourglass fx variable to one (Hourglass stage)
				hourglass.fy = 0;					// Set hourglass fy variable to zero (Counter)
			}

			if ((hourglass.fx == 1) && (hourglass.fy > 6000/level))         // Is the hourglass fx variable equal to 1 and the fy
			{								// Variable greater than 6000 divided by the current level?
				hourglass.fx = 0;					// If so, set fx to zero (Hourglass will vanish)
				hourglass.fy = 0;					// Set fy to zero (Counter is reset)
			}

			if ((hourglass.fx == 2) && (hourglass.fy > 500+(500*level)))	// Is the hourglass fx variable equal to 2 and the fy
			{								// Variable greater than 500 plus 500 times the current level?
				PlaySound(NULL, NULL, 0);				// If so, kill the freeze sound
				hourglass.fx = 0;					// Set hourglass fx variable to zero
				hourglass.fy = 0;					// Set hourglass fy variable to zero
			}

			delay++;
		}
	}

	// Shutdown
	KillGLWindow();         // Kill the window
	return (msg.wParam);    // Exit the program
}
//---------------------------------------------------------------------------
