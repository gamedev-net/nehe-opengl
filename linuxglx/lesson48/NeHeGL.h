/********************
*                   *
*   NeHeGL Header   *
*                   *
**********************************************************************************
*                                                                                *
*	You Need To Provide The Following Functions:                                 *
*                                                                                *
*	bool Initialize (GL_Window* window, Keys* keys);                             *
*		Performs All Your Initialization                                         *
*		Returns TRUE If Initialization Was Successful, FALSE If Not              *
*		'window' Is A Parameter Used In Calls To NeHeGL                          *
*		'keys' Is A Structure Containing The Up/Down Status Of keys              *
*                                                                                *
*	void Deinitialize (void);                                                    *
*		Performs All Your DeInitialization                                       *
*                                                                                *
*	void Update (DWORD milliseconds);                                            *
*		Perform Motion Updates                                                   *
*		'milliseconds' Is The Number Of Milliseconds Passed Since The Last Call  *
*		With Whatever Accuracy GetTickCount() Provides                           *
*                                                                                *
*	void Draw (void);                                                            *
*		Perform All Your Scene Drawing                                           *
*                                                                                *
*********************************************************************************/

#ifndef GL_FRAMEWORK__INCLUDED
#define GL_FRAMEWORK__INCLUDED

typedef struct {									// Structure For Keyboard Stuff
	bool keyDown [256];								// Holds TRUE / FALSE For Each Key
} Keys;												// Keys

typedef struct {									// Window Creation Info
	Display			*dpy;
	Window			win;
	GLXContext	ctx;
	XSetWindowAttributes attr;
	XF86VidModeModeInfo deskMode;
	bool doubleBuffered;
	int	screen;
	const char *title;
	unsigned int width;
	unsigned int height;
	unsigned int depth;
	bool isFullScreen;
} GL_WindowInit;

typedef struct {									// Contains Information Vital To A Window
	Keys*	keys;						// Key Structure
	GL_WindowInit	init;						// Window Init
	struct timeval lastTickCount;				// Tick Counter
} GL_Window;										// GL_Window

void TerminateApplication (GL_Window* window);		// Terminate The Application

void ToggleFullscreen (GL_Window* window);			// Toggle Fullscreen / Windowed Mode

// These Are The Function You Must Provide
bool Initialize (GL_Window* window, Keys* keys);	// Performs All Your Initialization

void Deinitialize (void);							// Performs All Your DeInitialization

void Update (long milliseconds);					// Perform Motion Updates

void Draw (void);									// Perform All Your Scene Drawing

#endif												// GL_FRAMEWORK__INCLUDED
