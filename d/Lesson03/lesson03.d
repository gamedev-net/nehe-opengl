/************************************************************
*																				*
* This code was made with DedicateD's testgl.d file as a		*
* base, and using their D ports of SDL and OpenGL, their		*
* website is http://int19h.tamb.ru/									*
*																				*
* D language compiler is available for download at				*
* http://www.digitalmars.com/d/dcompiler.html					*
*																				*
* This code was created by Jeff Molofee '99 						*
*																				*
* If you've found this code useful, please let me know.		*
*																				*
* Visit Jeff at http://nehe.gamedev.net/							*
*																				*
* Code modified/ported to D programming language				*
* by Garibaldi Pineda Garcia (ChaNoKiN)							*
* chanok_lobo@hotmail.com												*
* 2004																		*
*																				*
************************************************************/

import SDL;								// Import the SDL modules
import opengl;							// Import the opengl modules
import openglu;
import std.string;					// Import string modules
import std.c.stdio;					// Import the C stdio modules


bit USE_DEPRECATED_OPENGLBLIT = false;



/*This function changes from windowed to fullscreen
  mode and viceversa*/

void HotKey_ToggleFullScreen()
{
	SDL_Surface *screen;														//Make a surface pointer to screen

	screen = SDL_GetVideoSurface();										//Get current video surface
	if ( SDL_WM_ToggleFullScreen(screen) )								//If the toggle worked
	{
	  printf("Toggled fullscreen mode - now %s\n",					//print current window mode
	  (screen.flags & SDL_FULLSCREEN) ? "fullscrn" : "windowed");
	}
	else
	{
		printf("Unable to toggle fullscreen mode\n");				//else, just tell us we can't do it.
	}
}


/* This function will keep the mouse pointer
	"trapped" inside the GL window
*/
void HotKey_ToggleGrab()
{
	SDL_GrabMode mode;

	printf("Ctrl-G: toggling input grab!\n"); //Print the action taking place
	mode = SDL_WM_GrabInput(SDL_GRAB_QUERY);  //Check wether grab is on
	if ( mode == SDL_GRAB_ON )						//Print previous grab mode status
	{
		printf("Grab was on\n");
	}
	else
	{
		printf("Grab was off\n");
	}
	
	mode = SDL_WM_GrabInput(!mode);				//Change grab mode
	
	if ( mode == SDL_GRAB_ON )						//Print current grab mode status
	{
		printf("Grab is now on\n");
	}
	else
	{
		printf("Grab is now off\n");
	}
}



/* This will iconify or minimize the
	GL window.
*/
void HotKey_Iconify()
{
	printf("Ctrl-Z: iconifying window!\n"); //Print action
	SDL_WM_IconifyWindow();						 //Minimize
}


/*
  Main Event Handling function
*/
int HandleEvent(SDL_Event *event)
{
	int done;									//used to check if we want to quit

	done = 0;									//state that we still want to go on
	switch( event.type )						//Process events
	{
	    case SDL_ACTIVEEVENT:				//did we loose or gained input/mouse
													//focus?
			printf( "app %.*s ", event.active.gain ? "gain" : "lost" );
			if ( event.active.state & SDL_APPACTIVE )
			{
				printf( "active " );
			}
			else if ( event.active.state & SDL_APPMOUSEFOCUS )
				  {
					printf( "mouse " );
				  }
				  else if ( event.active.state & SDL_APPINPUTFOCUS )
				  {
					printf( "input " );
				  }
			printf( "focus\n" );
			break;
		

	    case SDL_KEYDOWN:										//Did we press any key
			if ( event.key.keysym.sym == SDLK_ESCAPE )	//If Escape Key then quit
			{
				done = 1;
			}
			if ( (event.key.keysym.sym == SDLK_g) &&		//If ctrl+g then loose/gain grab
			     (event.key.keysym.mod & KMOD_CTRL) )
			{
				HotKey_ToggleGrab();
			}
		if ( (event.key.keysym.sym == SDLK_z) &&			//if ctrl+z minimize
		     (event.key.keysym.mod & KMOD_CTRL) )
		{
			HotKey_Iconify();
		}
		if ( (event.key.keysym.sym == SDLK_RETURN) &&	//if alt+enter toggle fullscreen mode
		     (event.key.keysym.mod & KMOD_ALT) )
		{
			HotKey_ToggleFullScreen();
		}
		
		printf("key '%s' pressed\n", 
			SDL_GetKeyName(event.key.keysym.sym));			//Print which key was pressed
		break;

	    case SDL_QUIT:											//On quit event termnate loop
			done = 1;
			break;
		
		 default:
	}
	return(done);
}

void SDL_GL_Enter2DMode()
{
	SDL_Surface *screen = SDL_GetVideoSurface();				//Get a pointer to video surface

	/* Note, there may be other things you need to change,
	   depending on how you have your OpenGL state set up.
	*/
	glPushAttrib(GL_ENABLE_BIT);									//Save current enables
	glDisable(GL_DEPTH_TEST);										//Disable depth test
	glDisable(GL_CULL_FACE);										//Disable face culling
	glEnable(GL_TEXTURE_2D);										//Enable 2D textures

	glViewport(0, 0, screen.w, screen.h);						//Set viewport 

	glMatrixMode(GL_PROJECTION);									
	glPushMatrix();													//Save projection matrix
	glLoadIdentity();													//And reset it

	glOrtho(0.0, cast(GLdouble)(screen.w), cast(GLdouble)(screen.h), 0.0, 0.0, 1.0);
																			//Set orthographic projection
	glMatrixMode(GL_MODELVIEW);						
	glPushMatrix();													//Save modelview matrix
	glLoadIdentity();													//Reset it

	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);	
}

void SDL_GL_Leave2DMode()
{
	glMatrixMode(GL_MODELVIEW);									//Restore previous modelview matrix
	glPopMatrix();

	glMatrixMode(GL_PROJECTION);									//Restore previous projection matrix
	glPopMatrix();

	glPopAttrib();														//Restore previous enables
}

bool CreateWindowGL(int w, int h, int bpp, Uint32 video_flags)					// This Code Creates Our OpenGL Window
{
	int value;																		//Used as a recipient for some info
	int[3] rgb_size;																//Used to save the number of Red, Green and
	/* Initialize the display */												//Blue bits
	
	switch (bpp)
	{																					//Asing how may bits we want to use
	  
	  case 8:																		//depending of the bits per pixel
		rgb_size[0] = 2;															//passed as an argument to this function.
		rgb_size[1] = 3;
		rgb_size[2] = 3;
		break;
	  
	  case 15:
	  case 16:
		rgb_size[0] = 5;
		rgb_size[1] = 5;
		rgb_size[2] = 5;
		break;
	  
     default:
		rgb_size[0] = 8;
		rgb_size[1] = 8;
		rgb_size[2] = 8;
		break;
		
	}
	
	SDL_GL_SetAttribute( SDL_GL_RED_SIZE, rgb_size[0] );				//Try setting Red size (bits)
	SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, rgb_size[1] );			//Try setting Green size (bits)
	SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, rgb_size[2] );				//Try setting Blue size (bits)
	SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16 );						//Try setting the depth buffer size (bits)
	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );						//Try setting a double buffer
	
	if ( SDL_SetVideoMode( w, h, bpp, video_flags ) == null ) {		//Try to set the video mode
		printf("Couldn't set GL mode: %s\n", SDL_GetError());			//If it can't print error message
		SDL_Quit();																	//And then quit the app.
		return false;
	}

	//Print the characteristics of our VideoSurface and OpenGL capabilities
	printf("Screen BPP: %d\n", SDL_GetVideoSurface().format.BitsPerPixel);
	printf("\n");
	printf( "Vendor     : %s\n", glGetString( GL_VENDOR ) );
	printf( "Renderer   : %s\n", glGetString( GL_RENDERER ) );
	printf( "Version    : %s\n", glGetString( GL_VERSION ) );
	printf( "Extensions : %s\n", glGetString( GL_EXTENSIONS ) );
	printf("\n");

	//Print the OpenGL attributes, Red, Green and Blue bit sizes
	//Depth buffer size and if we got a double buffer or not
	SDL_GL_GetAttribute( SDL_GL_RED_SIZE, &value );
	printf( "SDL_GL_RED_SIZE: requested %d, got %d\n", rgb_size[0],value);
	SDL_GL_GetAttribute( SDL_GL_GREEN_SIZE, &value );
	printf( "SDL_GL_GREEN_SIZE: requested %d, got %d\n", rgb_size[1],value);
	SDL_GL_GetAttribute( SDL_GL_BLUE_SIZE, &value );
	printf( "SDL_GL_BLUE_SIZE: requested %d, got %d\n", rgb_size[2],value);
	SDL_GL_GetAttribute( SDL_GL_DEPTH_SIZE, &value );
	printf( "SDL_GL_DEPTH_SIZE: requested %d, got %d\n", bpp, value );
	SDL_GL_GetAttribute( SDL_GL_DOUBLEBUFFER, &value );
	printf( "SDL_GL_DOUBLEBUFFER: requested 1, got %d\n", value );
	
	//All went well, return true
	return true;
}

void ReshapeGL(int width, int height)										// Reshape The Window When It's Moved Or Resized
{
	glViewport(0,0,cast(GLsizei)(width),cast(GLsizei)(height));						// Reset The Current Viewport
	glMatrixMode(GL_PROJECTION);											// Select The Projection Matrix
	glLoadIdentity();														// Reset The Projection Matrix */

	gluPerspective(45.0f,(cast(GLfloat)width/cast(GLfloat)height),1.0f,100.0f);	// Calculate The Aspect Ratio Of The Window
	glMatrixMode(GL_MODELVIEW);												// Select The Modelview Matrix
	glLoadIdentity();														// Reset The Modelview Matrix

	return;																	// Always Return, We're Standard :)
}

bool InitGL()															// Any OpenGL Initialization Code Goes Here
{
	glClearColor(0.0f,0.0f,0.0f,0.5f);							// Black Background
	glClearDepth(1.0f);											// Depth Buffer Setup
	glDepthFunc(GL_LEQUAL);										// The Type Of Depth Testing (Less Or Equal)
	glEnable(GL_DEPTH_TEST);									// Enable Depth Testing
	glShadeModel(GL_SMOOTH);									// Select Smooth Shading
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Set Perspective Calculations To Most Accurate

	return true;												// Return TRUE (Initialization Successful)
}

void Draw3D()
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glLoadIdentity();											// Reset The Modelview Matrix

	glTranslatef(-1.5f,0.0f,-6.0f);					// Move Left 1.5 Units And Into The Screen 6.0
	
	glBegin(GL_TRIANGLES);						// Drawing Using Triangles
		glColor3f(1.0f,0.0f,0.0f);			// Set The Color To Red
		glVertex3f( 0.0f, 1.0f, 0.0f);				// Top
		glColor3f(0.0f,1.0f,0.0f);			// Set The Color To Green
		glVertex3f(-1.0f,-1.0f, 0.0f);				// Bottom Left
		glColor3f(0.0f,0.0f,1.0f);			// Set The Color To Blue
		glVertex3f( 1.0f,-1.0f, 0.0f);				// Bottom Right
	glEnd();

	glTranslatef(3.0f,0.0f,0.0f);					// Move Right 3 Units

	glColor3f(0.5f,0.5f,1.0f);				// Set The Color To Blue One Time Only
	glBegin(GL_QUADS);						// Draw A Quad
		glVertex3f(-1.0f, 1.0f, 0.0f);				// Top Left
		glVertex3f( 1.0f, 1.0f, 0.0f);				// Top Right
		glVertex3f( 1.0f,-1.0f, 0.0f);				// Bottom Right
		glVertex3f(-1.0f,-1.0f, 0.0f);				// Bottom Left
	glEnd();							// Done Drawing The Quad

	glFlush();													// Flush The GL Rendering Pipelines
	
	SDL_GL_SwapBuffers();										// And Swap The Buffers (We're Double-Buffering, Remember?)
}

int main(char[][] argv)
{
	int argc = argv.length;										//Get the argument count
	int i;															//loop variable
	int w = 640;													//window width
	int h = 480;													//window heigth
	int bpp = 24;													//window bits per pixel
	int done = 0;													//variable to check if the app is ging on
	int frames;														//frame counting var
	Uint32 start_time, this_time;								//time storage variables
	Uint32 video_flags;											//video flags
								

	if( SDL_Init( SDL_INIT_VIDEO ) < 0 )					//Try to init SDL
	{
		printf("Couldn't initialize SDL: %s\n",SDL_GetError());
		return ( 1 );												//if we can't then just quit 
	}

	/* See if we need to detect the display depth */
	if ( bpp == 0 )
	{
		if ( SDL_GetVideoInfo().vfmt.BitsPerPixel <= 8 ) {
			bpp = 8;
		} else {
			bpp = 16;  /* More doesn't seem to work */
		}
	}

	/* Set the flags we want to use for setting the video mode */
	video_flags = SDL_OPENGL;										//Set video flags to use OpenGL

	for ( i=1; i < argc; ++i ) {									//If any of our args was "-fullscreen"
		if ( strcmp(argv[1], "-fullscreen") == 0 ) {			//add fullscrren mode to our video flags
			video_flags |= SDL_FULLSCREEN;
		}
	}

   CreateWindowGL(w, h, bpp, video_flags);					//Create our OpenGL Window

	SDL_WM_SetCaption( "NeHe Lesson 03", "Lesson 03" );			//Set the window manager title bar

   ReshapeGL(w,h);													//Set our viewport/perspective
   
   InitGL();															//Set our OpengGL attributes

	/* Loop until done. */
	start_time = SDL_GetTicks();									//Get our starting time
	frames = 0;															//No frames have been rendered yet
	while( !done )
	{	
		GLenum gl_error;												//OpenGL error storaging variable
		char* sdl_error;												//SDL error storaging variable
		SDL_Event event;												//SDL event storing variable

		Draw3D();														//Draw our 3D Graphics

		gl_error = glGetError( );									//Check for OpenGL error conditions. 

		if( gl_error != GL_NO_ERROR ) {
			printf("testgl: OpenGL error: %d\n", gl_error );//If we got OpenGL errors, print them
		}

		sdl_error = SDL_GetError( );								//Check for SDL error conditions.	

		if( sdl_error[0] != 0 ) {
			printf("testgl: SDL error '%s'\n", sdl_error);	//If we got DLL errors, print 
			SDL_ClearError();											//And deal with them
		}

		
		SDL_Delay( 1 );												//Set a delay, usefull on really fast Computers
		

		
		while( SDL_PollEvent( &event ) )						  //Check if there's a pending event.
		{
			done = HandleEvent(&event);						  //Handle them.
		}
		++frames;													  //Increase our frame count
	}

	/* Print out the frames per second */
	this_time = SDL_GetTicks();
	if ( this_time != start_time ) {
		printf("%2.2f FPS\n",
			(cast(float)(frames)/(this_time-start_time))*1000.0);
	}

	/* Destroy our GL context, etc. */
	SDL_Quit( );
	return(0);

	return 0;
}

