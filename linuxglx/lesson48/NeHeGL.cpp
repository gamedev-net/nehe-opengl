/***********************************************
*                                              *
*    Jeff Molofee's Revised OpenGL Basecode    *
*  Huge Thanks To Maxwell Sayles & Peter Puck  *
*            http://nehe.gamedev.net           *
*                     2001                     *
*                                              *
***********************************************/

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glx.h>
#include <X11/Xlib.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>

#include "NeHeGL.h"

#include "math.h"

#include "ArcBall.h"

#define WM_TOGGLEFULLSCREEN (WM_USER+1)

static bool done = false;
static bool g_createFullScreen;											// If true, Then Create Fullscreen

extern ArcBallT    ArcBall;                                             //*NEW* ArcBall instance
extern Point2fT    MousePt;                                             //*NEW* Current mouse point
extern bool        isClicked;                                           //*NEW* Clicking the mouse?
extern bool        isRClicked;                                          //*NEW* Clicking the right mouse button?

static int attrListSgl[] = {
	GLX_RGBA,
	GLX_RED_SIZE, 4,
	GLX_GREEN_SIZE, 4,
	GLX_BLUE_SIZE, 4,
	GLX_DEPTH_SIZE, 16,
	None
};

static int attrListDbl[] = {
	GLX_RGBA, GLX_DOUBLEBUFFER,
	GLX_RED_SIZE, 4,
	GLX_GREEN_SIZE, 4,
	GLX_BLUE_SIZE, 4,
	GLX_DEPTH_SIZE, 16,
	None
};

void ReshapeGL (int width, int height)									// Reshape The Window When It's Moved Or Resized
{
	glViewport (0, 0, (GLsizei)(width), (GLsizei)(height));				// Reset The Current Viewport
	glMatrixMode (GL_PROJECTION);										// Select The Projection Matrix
	glLoadIdentity ();													// Reset The Projection Matrix
	gluPerspective (45.0f, (GLfloat)(width)/(GLfloat)(height),			// Calculate The Aspect Ratio Of The Window
					1.0f, 100.0f);		
	glMatrixMode (GL_MODELVIEW);										// Select The Modelview Matrix
	glLoadIdentity ();													// Reset The Modelview Matrix

    ArcBall.setBounds((GLfloat)width, (GLfloat)height);                 //*NEW* Update mouse bounds for arcball
}

bool CreateWindowGL (GL_Window* window) {
	XVisualInfo *vi;
	Colormap cmap;
	int dpyWidth, dpyHeight;
	int i;
	int glxMajorVersion, glxMinorVersion;
	int vidModeMajorVersion, vidModeMinorVersion;
	XF86VidModeModeInfo **modes;
	int modeNum;
	int bestMode;
	Atom wmDelete;
	Window winDummy;
	unsigned int borderDummy;
	int x, y;

	bestMode = 0;

	window->init.dpy = XOpenDisplay( NULL );
	window->init.screen = DefaultScreen( window->init.dpy );
	XF86VidModeQueryVersion( window->init.dpy, &vidModeMajorVersion,
													 &vidModeMinorVersion );
	
	printf( "XF86VMExt-Version %d.%d\n",
					vidModeMajorVersion, vidModeMinorVersion );
	XF86VidModeGetAllModeLines( window->init.dpy, window->init.screen,
															&modeNum, &modes );
	window->init.deskMode = *modes[0];

	for( i=0;i<modeNum;i++ ) {
		if( (modes[i]->hdisplay == window->init.width) &&
				(modes[i]->vdisplay == window->init.height) )
			bestMode = i;
	}

	vi = glXChooseVisual( window->init.dpy, window->init.screen, attrListDbl );
	if( vi == NULL ) {
		vi = glXChooseVisual( window->init.dpy, window->init.screen, attrListSgl );
		window->init.doubleBuffered = false;
		printf( "Single Buffered visual\n" );
	} else {
		window->init.doubleBuffered = true;
		printf( "Double Buffered visual\n" );
	}

	glXQueryVersion( window->init.dpy, &glxMajorVersion, &glxMinorVersion );
	printf( "glx-version %d.%d\n", glxMajorVersion, glxMinorVersion );

	window->init.ctx = glXCreateContext( window->init.dpy, vi, 0, GL_TRUE );

	cmap = XCreateColormap( window->init.dpy,
													RootWindow( window->init.dpy, vi->screen ),
													vi->visual, AllocNone );
	window->init.attr.colormap = cmap;
	window->init.attr.border_pixel = 0;

	if( window->init.isFullScreen ) {
		XF86VidModeSwitchToMode( window->init.dpy, window->init.screen,
														 modes[bestMode] );
		XF86VidModeSetViewPort( window->init.dpy, window->init.screen, 0, 0 );
		dpyWidth = modes[bestMode]->hdisplay;
		dpyHeight = modes[bestMode]->vdisplay;
		XFree( modes );

		window->init.attr.override_redirect = true;
		window->init.attr.event_mask =
			ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask |
			ButtonReleaseMask | StructureNotifyMask | PointerMotionMask;
		window->init.win =
			XCreateWindow( window->init.dpy,
										 RootWindow( window->init.dpy, vi->screen ),
										 0, 0, dpyWidth, dpyHeight, 0, vi->depth, InputOutput,
										 vi->visual, CWBorderPixel | CWColormap | CWEventMask |
										 CWOverrideRedirect, &window->init.attr );
		XWarpPointer( window->init.dpy, None, window->init.win, 0, 0, 0, 0, 0, 0 );
		XMapRaised( window->init.dpy, window->init.win );
		XGrabKeyboard( window->init.dpy, window->init.win, True, GrabModeAsync,
									 GrabModeAsync, CurrentTime );
		XGrabPointer( window->init.dpy, window->init.win, True, ButtonPressMask,
									GrabModeAsync, GrabModeAsync, window->init.win, None,
									CurrentTime );
	} else {
		window->init.attr.event_mask =
			ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask |
			ButtonReleaseMask | StructureNotifyMask | PointerMotionMask;
		window->init.win =
			XCreateWindow( window->init.dpy,
										 RootWindow( window->init.dpy, vi->screen ),
										 0, 0, window->init.width, window->init.height,
										 0, vi->depth, InputOutput, vi->visual,
										 CWBorderPixel | CWColormap | CWEventMask,
										 &window->init.attr );
		wmDelete = XInternAtom( window->init.dpy, "WM_DELETE_WINDOW", True );
		XSetWMProtocols( window->init.dpy, window->init.win, &wmDelete, 1 );
		XSetStandardProperties( window->init.dpy, window->init.win,
														window->init.title, window->init.title, None, NULL,
														0, NULL );
		XMapRaised( window->init.dpy, window->init.win );
	}

	glXMakeCurrent( window->init.dpy, window->init.win, window->init.ctx );
	XGetGeometry( window->init.dpy, window->init.win, &winDummy, &x, &y,
								&window->init.width, &window->init.height, &borderDummy,
								&window->init.depth );
	
	if( glXIsDirect( window->init.dpy, window->init.ctx ) )
		printf( "Direct rendering\n" );
	else
		printf( "Not Direct rendering\n" );

	return true;
}

void DestroyWindowGL(GL_Window* window) {
	if(window->init.ctx ) {
		if( !glXMakeCurrent(window->init.dpy, None, NULL ) ) {
			fprintf( stderr, "Error releasing drawing context\n" );
		}
		glXDestroyContext( window->init.dpy, window->init.ctx );
	}

	if(window->init.isFullScreen) {
		XF86VidModeSwitchToMode( window->init.dpy,
														 window->init.screen, &window->init.deskMode );
		XF86VidModeSetViewPort( window->init.dpy, window->init.screen, 0, 0 );
	}
	XCloseDisplay( window->init.dpy );
}

void initGL( GL_Window *window, Keys *keys ) {
	Initialize( window, keys );
	ReshapeGL( window->init.width, window->init.height );
}

int main( int argc, char *argv[] ) {
	XEvent event;
	GL_Window	window;
	Keys keys;
	KeySym key;
	struct timeval tv, tickCount;

	window.keys	= &keys;
	window.init.title	= "Lesson 48: NeHe & Terence J. Grant's ArcBall Rotation Tutorial";
	window.init.width	= 640;
	window.init.height = 480;
	window.init.depth = 32;
	window.init.isFullScreen = true;

	g_createFullScreen = window.init.isFullScreen;
	if( CreateWindowGL (&window) == false ) {
		exit( 1 );
	}

	initGL(&window, &keys);

	while( !done ) {
		while( XPending( window.init.dpy ) > 0 ) {
			XNextEvent( window.init.dpy, &event );
			switch( event.type ) {
				case Expose:
					if( event.xexpose.count != 0 )
						break;
					Draw();
					break;
				case ConfigureNotify:
					if( (event.xconfigure.width != window.init.width) ||
							(event.xconfigure.height != window.init.height) ) {
						window.init.width = event.xconfigure.width;
						window.init.height = event.xconfigure.height;
						ReshapeGL( window.init.width, window.init.height );
					}
					break;
				case ButtonPress:
					switch( event.xbutton.button ) {
						case 1: isClicked = true; break;
						case 3: isRClicked = true; break;
					}
					break;
				case ButtonRelease:
					switch( event.xbutton.button ) {
						case 1: isClicked = false; break;
						case 3: isRClicked = false; break;
					}
					break;
				case MotionNotify:
					MousePt.s.X = event.xmotion.x;
					MousePt.s.Y = event.xmotion.y;
					break;
				case KeyPress:
					key = XLookupKeysym( &event.xkey, 0 );
					if( key == XK_Escape )
						done = true;
					else if( key == XK_F1 ) {
						DestroyWindowGL( &window );
						window.init.isFullScreen = !window.init.isFullScreen;
						CreateWindowGL( &window );
						initGL(&window, &keys);
					} else {
						window.keys->keyDown[key] = true;
					}
					break;
				case KeyRelease:
					key = XLookupKeysym( &event.xkey, 0 );
					window.keys->keyDown[key] = false;
					break;
				case ClientMessage:
					if( *XGetAtomName( window.init.dpy, event.xclient.message_type)
								== *"WM_PROTOCOLS" ) {
						done = true;
					}
				default: break;
			}
		}

		gettimeofday( &tv, NULL );
		tickCount.tv_sec = tv.tv_sec - window.lastTickCount.tv_sec;
		tickCount.tv_usec = tv.tv_usec - window.lastTickCount.tv_usec;
		Update(tickCount.tv_usec / 1000 + tickCount.tv_sec * 1000 );
		window.lastTickCount = tickCount;
		Draw();

		if( window.init.doubleBuffered )
			glXSwapBuffers( window.init.dpy, window.init.win );
	}

	Deinitialize ();

	DestroyWindowGL (&window);
}
