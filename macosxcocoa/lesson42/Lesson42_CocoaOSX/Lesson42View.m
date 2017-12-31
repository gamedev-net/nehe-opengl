//
//  Lesson42View.m
//  Lesson42_CocoaOSX
//
//  Created by Brian Holley on Mon May 19 2003.
//  http://tachyon.unl.edu
//  bholley@unlnotes.unl.edu
//  Copyright (c) 2003. All rights reserved.
//
//  Fullscreen information courtesy of Katherine Tattersaul
//      http://www.zerobyzero.ca/~ktatters/tutorials/Tutorial0.html
//  Maze code adapted from Jeff Molofee's (NeHe's) Lesson 42 
//      http://nehe.gamedev.net/
//

#import "Lesson42View.h"


/* ---------------------------------------------------------------------------------
 * Lesson42View implementation
 * The fullscreen display window and timing system
 * -------------------------------------------------------------------------------*/
@implementation Lesson42View

/* ---------------------------------------------------------------------------------
 * initWithFrame
 * Initialize the NSWindow with a frame, creating an OpenGL context in the process.
 * This function is called when the NSWindow attached to this View is created */
- (id)initWithFrame:(NSRect)frame 
{
    // Set up an array of desired attributes for this OpenGL context
    NSOpenGLPixelFormatAttribute attribsNice[] = 
		{NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFANoRecovery,
		kCGLPFASampleBuffers, 1, kCGLPFASamples, 2,
		0};

    // Set up an array of acceptable attributes for this OpenGL context
	NSOpenGLPixelFormatAttribute attribsJaggy[] = 
		{NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFANoRecovery,
		0};
	
    // Choose a pixel format, desirable version first
	NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribsNice];
	if(!fmt)
		fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribsJaggy];
    
    // Create the window from the super constructor
	if (self = [super initWithFrame:frame pixelFormat:fmt])
    {
        [self setPostsFrameChangedNotifications: YES];
        [[self openGLContext] makeCurrentContext];
    }
    // Release the pixel format
    [fmt release];
    
    return self;
}

/* ---------------------------------------------------------------------------------
 * initGL
 * Initialize the OpenGL settings needed for this application */
- (void)initGL
{
    // Set the OpenGL attributes to use with glClear
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    
    // Set up the depth buffer
    glDepthFunc(GL_LESS);
    glEnable(GL_DEPTH_TEST);
    
    // Set up antialiasing
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
    
   // Enable blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Enable materials, texturing and the default OpenGL light
    glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_LIGHT0);
    
    [self initialize];
}

/* ---------------------------------------------------------------------------------
 * startTimer
 * Start the timer used to update and render each frame continuously */
- (void)startTimer
{
    // Start the timer for 0.001 sec (1000 frames per second, max)
    frameTimer = [[NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(runFrame) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:frameTimer forMode:NSEventTrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:frameTimer forMode:NSModalPanelRunLoopMode];
}

/* ---------------------------------------------------------------------------------
 * reshape
 * Resize the OpenGL rendering context according to the window size.
 * This function is called when the window is resized */
- (void)reshape
{
    // Reset the viewport based on the new size
    glViewport(0, 0, [self frame].size.width, [self frame].size.height);
    
    // Use the projection matrix and recalculate the aspect ratio
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0f, (GLfloat)([self frame].size.width / [self frame].size.height), 0.1f, 100.0f);
    
    // Use the modelview matrix and reload the identity
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

/* ---------------------------------------------------------------------------------
 * runFrame
 * Update and display the OpenGL scene.
 * This function is called for each frame */
- (void)runFrame
{
    // Clear out the backbuffer to prepare for rendering
    glLoadIdentity();
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Update, render and flush the buffer
    [self updateFrame];
    [self renderFrame];
    [[self openGLContext] flushBuffer];
}

/* ---------------------------------------------------------------------------------
 * updateFrame
 * Update the current frame */
- (void)updateFrame
{
    // The direction we will end up going
    int dir = 0, x = 0, y = 0;
    
    // Establish the duration of last frame (in msecs)
    AbsoluteTime thisFrame = UpTime();
    double frameDuration = abs(AbsoluteDeltaToDuration(thisFrame, frameTime)) * 0.001;
    frameTime = thisFrame;
    
    // Use that duration to rotate the quadratic objects
    xrot += (float)frameDuration * 0.02f;
	yrot += (float)frameDuration * 0.03f;
	zrot += (float)frameDuration * 0.015f;

    done = YES;
    // Search through the maze to find out if we've hit all the rooms
    for (x=0; x < width && done; x += 2)
    {
        for (y=0; y < height && done; y += 2)
        {
            if (textureData[(x+(width*y))*3] == 0)
                done = NO;
        }
    }
    
    // If we're done, change the title, wait and restart the maze generation
    if (done == YES)
    {
        [[self window] setTitle:@"Lesson 42: Multiple Viewports... 2003 NeHe Productions... Maze Complete!"];
        sleep(5);
        [[self window] setTitle:@"Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!"];
        [self reset];
    }
    
    // Check to see if we're trapped (all four sides are full or are walls)
    if (((textureData[((mx+2)+(width*my))*3]==255) || mx>(width-4)) && ((textureData[((mx-2)+(width*my))*3]==255) || mx<2) && ((textureData[(mx+(width*(my+2)))*3]==255) || my>(height-4)) && ((textureData[(mx+(width*(my-2)))*3]==255) || my<2))
	{
        // If so, find a new starting point in the maze
		do
        {
			mx = ((rand() >> 5) % (width >> 1)) << 1;
			my = ((rand() >> 5) % (height >> 1)) << 1;
        } while (textureData[(mx+(width*my))*3] == 0);
    }

    // Choose a random direction
	dir = (rand() >> 7) % 4;
    
    // If we're trying to move right and we're not at the far right
    // And the room to the right is empty, update the path and the move position
	if (dir == 0 && mx <= width - 4)
	{
		if (textureData[((mx+2)+(width*my))*3] == 0)
		{
			[self updateTex:mx+1:my];
			mx += 2;
        }
	}
	// If we're trying to move down and we're not at the bottom
    // And the room below is empty, update the path and the move position
	else if (dir == 1 && my <= height - 4)
	{
		if (textureData[(mx+(width*(my+2)))*3] == 0)
		{
			[self updateTex:mx:my+1];
			my += 2;
        }
	}
	// If we're trying to move left and we're not at the far left
    // And the room to the left is empty, update the path and the move position
	else if (dir == 2 && mx >= 2)
	{
		if (textureData[((mx-2)+(width*my))*3] == 0)
		{
			[self updateTex:mx-1:my];
			mx -= 2;
        }
	}
    // If we're trying to move up and we're not at the top
    // And the room above is empty, update the path and the move position
	else if (dir == 3 && my >= 2)
	{
		if (textureData[(mx+(width*(my-2)))*3] == 0)
		{
			[self updateTex:mx:my-1];
			my -= 2;
        }
	}

    // Update the texture at the new position and remove a room from availability
    [self updateTex:mx:my];
}

/* ---------------------------------------------------------------------------------
 * renderFrame
 * Render the current frame to the screen */
- (void)renderFrame
{
    int i = 0;
    // Grab the window width and height
    int windowWidth = [self frame].size.width, windowHeight = [self frame].size.height;
    
    // Reload the maze texture into OpenGL texture memory
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, textureData);

    // Draw the 4 views of the screen
	for (i=0; i < 4; i++)
	{
        // Set the color for each view (GLubytes, not GLfloats)
		glColor3ub(r[i], g[i], b[i]);

        switch (i)
        {
            // 0: First scene in the top left
            case 0:	
            {
                // Set the viewport to the first quadrant 
                glViewport(0, windowHeight >> 1, windowWidth >> 1, windowHeight >> 1);
                // Set the projection matrix to ortho view (for the basic maze)
                glMatrixMode(GL_PROJECTION);
                glLoadIdentity();
                gluOrtho2D(0, windowWidth >> 1, windowHeight >> 1, 0);
                break;
            }
            // 1: Second scene in the top right
            case 1:
            {
                // Set the viewport to the second quadrant
                glViewport(windowWidth >> 1, windowHeight >> 1, windowWidth >> 1, windowHeight >> 1);
                // Set the projection matrix to perspective view (for a sphere)
                glMatrixMode(GL_PROJECTION);
                glLoadIdentity();
                gluPerspective(45.0, (GLfloat)width/(GLfloat)height, 0.1f, 500.0); 
                break;
            }
            // 2: Third scene in the bottom right
            case 2:
            {
                // Set the viewport to the third quadrant
                glViewport(windowWidth >> 1, 0, windowWidth >> 1, windowHeight >> 1);
                // Set the projection matrix to perspective view (for an iso quad)
                glMatrixMode(GL_PROJECTION);
                glLoadIdentity();
                gluPerspective(45.0, (GLfloat)width/(GLfloat)height, 0.1f, 500.0); 
                break;
            }
            // 3: Fourth scene in the bottom left
            case 3:
            {
                // Set the viewport to the fourth quadrant
                glViewport(0, 0, windowWidth >> 1, windowHeight >> 1);
                // Set the projection matrix to perspective view (for a cylindar)
                glMatrixMode(GL_PROJECTION);
                glLoadIdentity();
                gluPerspective(45.0, (GLfloat)width/(GLfloat)height, 0.1f, 500.0); 
                break;
            }
        }

        // Reset and clear the modelview matrix
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
        
        glClear(GL_DEPTH_BUFFER_BIT);

		switch (i)
        {
            // 0: First scene, draw the ortho quad maze
            case 0:
            {
                //glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
                // Draw a single quad the size of the quadrant
                glBegin(GL_QUADS);
                    glTexCoord2f(0.0f, 0.0f); glVertex2i(windowWidth >> 1, 0);
                    glTexCoord2f(1.0f, 0.0f); glVertex2i(0, 0);
                    glTexCoord2f(1.0f, 1.0f); glVertex2i(0, windowHeight >> 1);
                    glTexCoord2f(0.0f, 1.0f); glVertex2i(windowWidth >> 1, windowHeight >> 1);
                glEnd();
                //glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);                
                break;
            }
            // 1: Second scene, draw the quadratic sphere maze
            case 1:
            {
                // Translate to a good position for the sphere
                glTranslatef(0.0f, 0.0f, -12.0f);
                // Rotate the object by the incremented values
                glRotatef(xrot, 1.0f, 0.0f, 0.0f);
                glRotatef(yrot, 0.0f, 1.0f, 0.0f);
                glRotatef(zrot, 0.0f, 0.0f, 1.0f);

                // Enable lighting, disable depth testing, draw the sphere
                glEnable(GL_LIGHTING);
                gluSphere(quadric, 3.0f, 32, 32);
                glDisable(GL_LIGHTING);
                break;
            }
            // 2: Third scene, draw the iso quad maze
            case 2:	
            {
                // Translate to a good position for the center of the quad
                glTranslatef(0.0f, 0.0f, -2.0f);
                // Tilt back 45deg for the iso effect
                glRotatef(-45.0f, 1.0f, 0.0f, 0.0f);
                // Rotate slowly on the Z axis
                glRotatef(zrot/1.5f, 0.0f, 0.0f, 1.0f);

                // Draw a single GL quad
                glBegin(GL_QUADS);
                    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, 0.0f);
                    glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, 0.0f);
                    glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, 0.0f);
                    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, 0.0f);
                glEnd();
                break;
            }
            // 3: Fourth scene, draw the quadratic cylinder maze
            case 3:
            {
                // Translate to a good position for the cylinder
                glTranslatef(0.0f, 0.0f, -7.0f);
                // Rotate slowly by the incremented values
                glRotatef(-xrot/2.0f, 1.0f, 0.0f, 0.0f);
                glRotatef(-yrot/2.0f, 0.0f, 1.0f, 0.0f);
                glRotatef(-zrot/2.0f, 0.0f, 0.0f, 1.0f);

                // Enable lighting, disable depth testing, translate to rotate around center, draw the cylinder
                glEnable(GL_LIGHTING);
                glTranslatef(0.0f, 0.0f, -2.0f);
                gluCylinder(quadric, 1.5f, 1.5f, 4.0f, 32, 16);
                glDisable(GL_LIGHTING);
                break;
            }
        }
    }
}

/* ---------------------------------------------------------------------------------
 * keyDown
 * Receive keyboard input and act upon it.
 * This function is called for a keypress */
- (void)keyDown:(NSEvent *)theEvent
{
    NSString * string;
	unsigned int i;
	
    // Get a list of the characters associated with this event
	string = [theEvent charactersIgnoringModifiers];
	
    // For each character in the string
    for (i = 0; i < [string length]; i++) 
    {
        // Switch on the character at this index
        switch ((int)[string characterAtIndex:i])
        {
            // 32: Space bar key
            case 32:
            {
                // Reset the maze and begin again
                [self reset];
                break;
            }
            // 27: Escape key
            case 27:
            {
                [NSApp terminate:nil];
                break;
            }
        }
	}
}

/* ---------------------------------------------------------------------------------
 * acceptsFirstResponder */
- (BOOL)acceptsFirstResponder
{
	return YES;
}

/* ---------------------------------------------------------------------------------
 * becomeFirstResponder */
- (BOOL)becomeFirstResponder
{
	return YES;
}

/* ---------------------------------------------------------------------------------
 * resignFirstResponder */
- (BOOL)resignFirstResponder
{
	return YES;
}

/* ---------------------------------------------------------------------------------
 * initialize
 * Initialize the maze data structures and return a pointer to the structure */
- (void)initialize
{
    // Seed the random number generator with the low 4 bytes of the uptime
    srand(AbsoluteToNanoseconds(UpTime()).lo);
    
    // Set the size of the texture and allocate space for the image data
    width = height = 128;
    textureData = (GLubyte *)malloc(width * height * 3);
    if (!textureData)
        return;
    // Tell OpenGL to use this texture that we have created
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, textureData);

    // Set the rotational angles for the objects and create a new quadratic object
    xrot = yrot = zrot = 0.0f;
    quadric = gluNewQuadric();
	gluQuadricNormals(quadric, GLU_SMOOTH);
	gluQuadricTexture(quadric, GL_TRUE);

    // Call reset to begin a new maze
    [self reset];
    
    // Start the frame time counter
    frameTime = UpTime();
}

/* ---------------------------------------------------------------------------------
 * deinitialize
 * Frees allocated texture memory */
- (void)deinitialize
{
    free(textureData);
}

/* ---------------------------------------------------------------------------------
 * updateTexture
 * Set the given position (room) in the maze to a white pixel */
- (void)updateTex:(int)dmx :(int)dmy
{
    // Calculate the offset into the texture array
    int offset = ((dmx + (width * dmy)) * 3);
    if (textureData)
    {
        // Set all pixels to full brightness
        textureData[0 + offset] = 255;
        textureData[1 + offset] = 255;
        textureData[2 + offset] = 255;
    }
}

/* ---------------------------------------------------------------------------------
 * reset
 * Set all the values of the maze data structure to prepare for a new maze */
- (void)reset
{
    int i;
    
    // Blank the starting position
    mx = my = 0;
    
    // Blank out the texture data (wipe to 0)
    memset(textureData, 0, width * height * 3);
    
	for (i=0; i < 4; ++i)
	{
        // Choose a random RGB color for the viewport
		r[i] = rand() % 128 + 128;
		g[i] = rand() % 128 + 128;
		b[i] = rand() % 128 + 128;
    }
    
    // Start the maze at a random location
	mx = ((rand() >> 3) % (width >> 1)) << 1;
	my = ((rand() >> 3) % (height >> 1)) << 1;
}

@end
