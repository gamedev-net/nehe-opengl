//---------------------------------------------------------------------------
/**************************************
*                                     *
*   Jeff Molofee's Picking Tutorial   *
*          nehe.gamedev.net           *
*                2001                 *
*                                     *
**************************************/

#include <windows.h>    // Header file for windows
#include <stdio.h>	// Header file for standard Input / Output
#include <stdarg.h>	// Header file for variable argument routines
#include <gl\gl.h>	// Header file for the OpenGL32 library
#include <gl\glu.h>	// Header file for the GLu32 library
#include <time.h>	// For random seed
#include "NeHeGL.h"	// Header file for NeHeGL
#pragma hdrstop
//---------------------------------------------------------------------------
#pragma argsused

#ifndef CDS_FULLSCREEN          // CDS_FULLSCREEN is not defined by some
#define CDS_FULLSCREEN 4	// compilers. By defining it this way,
#endif				// we can avoid errors

void DrawTargets();		// Declaration

GL_Window* g_window;
Keys* g_keys;

// User defined variables
GLuint base;			// Font display list
GLfloat roll;			// Rolling clouds
GLint level = 1;		// Current level
GLint miss;			// Missed targets
GLint kills;			// Level kill counter
GLint score;			// Current score
bool game;			// Game over?

typedef int (*compfn)(const void*, const void*);        // Typedef for our compare function

struct objects
{
	GLuint	rot;		// Rotation (0-none, 1-clockwise, 2-counter clockwise)
	bool	hit;		// Object hit?
	GLuint	frame;		// Current explosion frame
	GLuint	dir;		// Object direction (0-left, 1-right, 2-up, 3-down)
	GLuint	texid;		// Object texture ID
	GLfloat	x;													// Object X Position
	GLfloat y;													// Object Y Position
	GLfloat	spin;		// Object spin
	GLfloat	distance;	// Object distance
};

typedef struct			// Create a structure
{
	GLubyte	*imageData;	// Image data (Up to 32 bits)
	GLuint	bpp;		// Image color depth in bits per pixel.
	GLuint	width;		// Image width
	GLuint	height;		// Image height
	GLuint	texID;		// Texture ID used to select a texture
} TextureImage;			// Structure name

TextureImage textures[10];	// Storage for 10 textures

objects	object[30];		// Storage for 30 objects

struct dimensions {		// Object dimensions
	GLfloat	w;		// Object width
	GLfloat h;		// Object height
};

// Size of each object: blueface,     bucket,      target,       coke,         vase
dimensions size[5] = { {1.0f,1.0f}, {1.0f,1.0f}, {1.0f,1.0f}, {0.5f,1.0f}, {0.75f,1.5f} };

bool LoadTGA(TextureImage *texture, char *filename)			// Loads a TGA file into memory
{
	GLubyte		TGAheader[12]={0,0,2,0,0,0,0,0,0,0,0,0};	// Uncompressed TGA header
	GLubyte		TGAcompare[12];		// Used to compare TGA header
	GLubyte		header[6];		// First 6 useful bytes from the header
	GLuint		bytesPerPixel;		// Holds number of bytes per pixel used in the TGA file
	GLuint		imageSize;		// Used to store the image size when setting aside ram
	GLuint		temp;			// Temporary variable
	GLuint		type=GL_RGBA;		// Set the default GL mode to RBGA (32 BPP)

	FILE *file = fopen(filename, "rb");	// Open the TGA file

	if(	file==NULL ||								// Does file even exist?
		fread(TGAcompare,1,sizeof(TGAcompare),file)!=sizeof(TGAcompare) ||	// Are there 12 bytes to read?
		memcmp(TGAheader,TGAcompare,sizeof(TGAheader))!=0 ||                    // Does the header match what we want?
		fread(header,1,sizeof(header),file)!=sizeof(header))			// If so read next 6 header bytes
	{
		if (file == NULL)			// Did the file even exist? *Added Jim Strong*
			return FALSE;			// Return false
		else					// Otherwise
		{
			fclose(file);	// If anything failed, close the file
			return FALSE;	// Return false
		}
	}

	texture->width  = header[1] * 256 + header[0];	// Determine the TGA width	(highbyte*256+lowbyte)
	texture->height = header[3] * 256 + header[2];	// Determine the TGA height	(highbyte*256+lowbyte)

 	if(	texture->width	<=0	||		// Is the width less than or equal to zero
		texture->height	<=0	||		// Is the height less than or equal to zero
		(header[4]!=24 && header[4]!=32))	// Is the TGA 24 or 32 bit?
	{
		fclose(file);				// If anything failed, close the file
		return FALSE;				// Return false
	}

	texture->bpp	= header[4];			// Grab the TGA's bits per pixel (24 or 32)
	bytesPerPixel	= texture->bpp/8;		// Divide by 8 to get the bytes per pixel
	imageSize		= texture->width*texture->height*bytesPerPixel;	// Calculate the memory required for the TGA data

	texture->imageData=(GLubyte *)malloc(imageSize);			// Reserve memory to hold the TGA data

	if(	texture->imageData==NULL ||					// Does the storage memory exist?
		fread(texture->imageData, 1, imageSize, file)!=imageSize)	// Does the image size match the memory reserved?
	{
		if(texture->imageData!=NULL)				// Was image data loaded
			free(texture->imageData);			// If so, release the image data

		fclose(file);						// Close the file
		return FALSE;						// Return false
	}

	for(GLuint i=0; i<int(imageSize); i+=bytesPerPixel)		// Loop through the image data
	{								// Swaps the 1st and 3rd bytes ('R'ed and 'B'lue)
		temp=texture->imageData[i];				// Temporarily store the value at image data 'i'
		texture->imageData[i] = texture->imageData[i + 2];	// Set the 1st byte to the value of the 3rd byte
		texture->imageData[i + 2] = temp;			// Set the 3rd byte to the value in 'temp' (1st byte value)
	}

	fclose (file);					// Close the file

	// Build a texture from the data
	glGenTextures(1, &texture[0].texID);		// Generate OpenGL texture IDs

	glBindTexture(GL_TEXTURE_2D, texture[0].texID);				// Bind our texture
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// Linear filtered
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// Linear filtered
	
	if (texture[0].bpp==24)		// Was the TGA 24 bits
	{
		type=GL_RGB;		// If so set the 'type' to GL_RGB
	}

	glTexImage2D(GL_TEXTURE_2D, 0, type, texture[0].width, texture[0].height, 0, type, GL_UNSIGNED_BYTE, texture[0].imageData);

	return true;		// Texture building went ok, return true
}

GLvoid BuildFont(GLvoid)	// Build our font display list
{
	base=glGenLists(95);	// Creating 95 display lists
	glBindTexture(GL_TEXTURE_2D, textures[9].texID);	// Bind our font texture
	for (int loop=0; loop<95; loop++)			// Loop through all 95 lists
	{
		float cx=float(loop%16)/16.0f;			// X position of current character
		float cy=float(loop/16)/8.0f;			// Y position of current character

		glNewList(base+loop,GL_COMPILE);		// Start building a list
			glBegin(GL_QUADS);			// Use a quad for each character
				glTexCoord2f(cx,1.0f-cy-0.120f);        glVertex2i(0,0);	// Texture / vertex coord (Bottom left)
				glTexCoord2f(cx+0.0625f,1.0f-cy-0.120f);glVertex2i(16,0);	// Texutre / vertex coord (Bottom right)
				glTexCoord2f(cx+0.0625f,1.0f-cy);       glVertex2i(16,16);      // Texture / vertex coord (Top right)
				glTexCoord2f(cx,1.0f-cy);		glVertex2i(0,16);	// Texture / vertex coord (Top left)
			glEnd();								// Done building our quad (Character)
			glTranslated(10,0,0);	// Move to the right of the character
		glEndList();			// Done building the display list
	}					// Loop until all 256 are built
}

GLvoid glPrint(GLint x, GLint y, const char *string, ...)	// Where the printing happens
{
	char		text[256];		// Holds our string
	va_list		ap;			// Pointer to list of arguments

	if (string == NULL)			// If there's no text
		return;				// Do nothing

	va_start(ap, string);			// Parses the string for variables
	    vsprintf(text, string, ap);		// And converts symbols to actual numbers
	va_end(ap);				// Results are stored in text

	glBindTexture(GL_TEXTURE_2D, textures[9].texID);	// Select our font texture
	glPushMatrix();						// Store the modelview matrix
	glLoadIdentity();					// Reset the modelview matrix
	glTranslated(x,y,0);					// Position the text (0,0 - bottom left)
	glListBase(base-32);					// Choose the font set
	glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);	// Draws the display list text
	glPopMatrix();						// Restore the old projection matrix
}

int Compare(struct objects *elem1, struct objects *elem2)	// Compare function *** MSDN CODE MODIFIED FOR THIS TUT ***
{
   if ( elem1->distance < elem2->distance)			// If first structure distance is less than the second
      return -1;						// Return -1
   else if (elem1->distance > elem2->distance)			// If first structure distance is greater than the second
      return 1;							// Return 1
   else								// Otherwise (If the distance is equal)
      return 0;							// Return 0
}

GLvoid InitObject(int num)					// Initialize an object
{
	object[num].rot=1;					// Clockwise rotation
	object[num].frame=0;					// Reset the explosion frame to zero
	object[num].hit=FALSE;					// Reset object has been hit status to false
	object[num].texid=rand()%5;				// Assign a new texture
	object[num].distance=-(float(rand()%4001)/100.0f);	// Random distance
	object[num].y=-1.5f+(float(rand()%451)/100.0f);		// Random Y position
	// Random starting X position based on distance of object and random amount for a delay (Positive value)
	object[num].x=((object[num].distance-15.0f)/2.0f)-(5*level)-float(rand()%(5*level));
	object[num].dir=(rand()%2);		// Pick a random direction

	if (object[num].dir==0)			// Is random direction right
	{
		object[num].rot=2;		// Counter clockwise rotation
		object[num].x=-object[num].x;	// Start on the left side (Negative value)
	}

	if (object[num].texid==0)		// Blue face
		object[num].y=-2.0f;		// Always rolling on the ground

	if (object[num].texid==1)		// Bucket
	{
		object[num].dir=3;		// Falling down
		object[num].x=float(rand()%int(object[num].distance-10.0f))+((object[num].distance-10.0f)/2.0f);
		object[num].y=4.5f;		// Random X, start at top of the screen
	}

	if (object[num].texid==2)		// Target
	{
		object[num].dir=2;		// Start off flying up
		object[num].x=float(rand()%int(object[num].distance-10.0f))+((object[num].distance-10.0f)/2.0f);
		object[num].y=-3.0f-float(rand()%(5*level));	// Random X, start under ground + random value
	}

	// Sort objects by distance:	Beginning address of our object array	*** MSDN CODE MODIFIED FOR THIS TUT ***
	//								Number of elements to sort
	//								Size of each element
	//								Pointer to our compare function
	qsort((void *) &object, level, sizeof(struct objects), (compfn)Compare );
}

BOOL Initialize (GL_Window* window, Keys* keys)	        // Any OpenGL initialization goes here
{
	g_window	= window;
	g_keys		= keys;

	srand( (unsigned)time( NULL ) );		// Randomize things

	if ((!LoadTGA(&textures[0],"Data/BlueFace.tga")) ||		// Load the blueFace texture
		(!LoadTGA(&textures[1],"Data/Bucket.tga")) ||		// Load the bucket texture
		(!LoadTGA(&textures[2],"Data/Target.tga")) ||		// Load the target texture
		(!LoadTGA(&textures[3],"Data/Coke.tga")) ||		// Load the coke texture
		(!LoadTGA(&textures[4],"Data/Vase.tga")) ||		// Load the vase texture
		(!LoadTGA(&textures[5],"Data/Explode.tga")) ||		// Load the explosion texture
		(!LoadTGA(&textures[6],"Data/Ground.tga")) ||		// Load the ground texture
		(!LoadTGA(&textures[7],"Data/Sky.tga")) ||		// Load the sky texture
		(!LoadTGA(&textures[8],"Data/Crosshair.tga")) ||	// Load the crosshair texture
		(!LoadTGA(&textures[9],"Data/Font.tga")))		// Load the crosshair texture
	{
		return false;	// If loading failed, return false
	}

	BuildFont();            // Build our font display list

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);	// Black background
	glClearDepth(1.0f);			// Depth buffer setup
	glDepthFunc(GL_LEQUAL);			// Type of depth testing
	glEnable(GL_DEPTH_TEST);		// Enable depth testing
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);	// Enable alpha blending (Disable alpha testing)
	glEnable(GL_BLEND);			// Enable blending (Disable alpha testing)
	glEnable(GL_TEXTURE_2D);		// Enable texture mapping
	glEnable(GL_CULL_FACE);			// Remove back face

	for (int loop=0; loop<30; loop++)	// Loop through 30 objects
		InitObject(loop);		// Initialize each object

	return TRUE;				// Return true (Initialization successful)
}

void Deinitialize (void)	// Any user deinitialization goes here
{
	glDeleteLists(base,95);	// Delete all 95 font display lists
}

void Selection(void)		// This is where selection is done
{
	GLuint	buffer[512];	// Set up a selection buffer
	GLint	hits;		// The number of objects that we selected

	if (game)		// Is game over?
		return;		// If so, don't bother checking for hits
	
	PlaySound("data/shot.wav",NULL,SND_ASYNC);	// Play gun shot sound

	// The size of the viewport. [0] is <x>, [1] is <y>, [2] is <length>, [3] is <width>
	GLint	viewport[4];

	// This sets the array <viewport> to the size and location of the screen relative to the window
	glGetIntegerv(GL_VIEWPORT, viewport);
	glSelectBuffer(512, buffer);		// Tell OpenGL to use our array for selection

	// Puts OpenGL in selection mode. Nothing will be drawn. Object ID's and extents are stored in the buffer.
	(void) glRenderMode(GL_SELECT);

	glInitNames();			// Initializes the name stack
	glPushName(0);			// Push 0 (At least one entry) onto the stack

	glMatrixMode(GL_PROJECTION);	// Selects the projection matrix
	glPushMatrix();			// Push the projection matrix
	glLoadIdentity();		// Resets the matrix

	// This creates a matrix that will zoom up to a small portion of the screen, where the mouse is.
	gluPickMatrix((GLdouble) mouse_x, (GLdouble) (viewport[3]-mouse_y), 1.0f, 1.0f, viewport);

	// Apply the perspective matrix
	gluPerspective(45.0f, (GLfloat) (viewport[2]-viewport[0])/(GLfloat) (viewport[3]-viewport[1]), 0.1f, 100.0f);
	glMatrixMode(GL_MODELVIEW);		// Select the modelview matrix
	DrawTargets();				// Render the targets to the selection buffer
	glMatrixMode(GL_PROJECTION);		// Select the projection matrix
	glPopMatrix();				// Pop the projection matrix
	glMatrixMode(GL_MODELVIEW);		// Select the modelview matrix
	hits=glRenderMode(GL_RENDER);		// Switch to render mode, find out how many
						// Objects were drawn where the mouse was
	if (hits > 0)				// If there were more than 0 hits
	{
		int	choose = buffer[3];	// Make our selection the first object
		int depth = buffer[1];		// Store how far away it is

		for (int loop = 1; loop < hits; loop++)		// Loop through all the detected hits
		{
			// If this object is closer to us than the one we have selected
			if (buffer[loop*4+1] < GLuint(depth))
			{
				choose = buffer[loop*4+3];	// Select the closer object
				depth = buffer[loop*4+1];	// Store how far away it is
			}
		}

		if (!object[choose].hit)		// If the object hasn't already been hit
		{
			object[choose].hit=TRUE;	// Mark the object as bening hit
			score+=1;			// Increase score
			kills+=1;			// Increase level kills
			if (kills>level*5)		// New level yet?
			{
				miss=0;			// Misses reset back to zero
				kills=0;		// Reset level kills
				level+=1;		// Increase level
				if (level>30)		// Higher than 30?
					level=30;	// Set level to 30 (Are you a god?)
			}
		}
    }
}

void Update(DWORD milliseconds)				// Perform motion updates here
{
	if (g_keys->keyDown[VK_ESCAPE])			// Is ESC being pressed?
	{
		TerminateApplication (g_window);	// Terminate the program
	}

	if (g_keys->keyDown[' '] && game)		// Space bar being pressed after game has ended?
	{
		for (int loop=0; loop<30; loop++)	// Loop through 30 objects
			InitObject(loop);		// Initialize each object

		game=FALSE;			// Set game (Game over) to false
		score=0;			// Set score to 0
		level=1;			// Set level back to 1
		kills=0;			// Zero player kills
		miss=0;				// Set miss (Missed shots) to 0
	}

	if (g_keys->keyDown[VK_F1])		// Is F1 being pressed?
	{
		ToggleFullscreen (g_window);	// Toggle fullscreen mode
	}

	roll-=milliseconds*0.00005f;		// Roll the clouds

	for (int loop=0; loop<level; loop++)	// Loop through the objects
	{
		if (object[loop].rot==1)					// If rotation is clockwise
			object[loop].spin-=0.2f*(float(loop+milliseconds));	// Spin clockwise

		if (object[loop].rot==2)					// If rotation is counter clockwise
			object[loop].spin+=0.2f*(float(loop+milliseconds));	// Spin counter clockwise

		if (object[loop].dir==1)					// If direction is right
			object[loop].x+=0.012f*float(milliseconds);		// Move right

		if (object[loop].dir==0)					// If direction is left
			object[loop].x-=0.012f*float(milliseconds);		// Move left

		if (object[loop].dir==2)					// If direction is up
			object[loop].y+=0.012f*float(milliseconds);		// Move up

		if (object[loop].dir==3)					// If direction is down
			object[loop].y-=0.0025f*float(milliseconds);		// Move down

		// If we are to far left, direction is left and the object was not hit
		if ((object[loop].x<(object[loop].distance-15.0f)/2.0f) && (object[loop].dir==0) && !object[loop].hit)
		{
			miss+=1;			// Increase miss (Missed object)
			object[loop].hit=TRUE;		// Set hit to true to manually blow up the object
		}

		// If we are to far right, direction is left and the object was not hit
		if ((object[loop].x>-(object[loop].distance-15.0f)/2.0f) && (object[loop].dir==1) && !object[loop].hit)
		{
			miss+=1;			// Increase miss (Missed object)
			object[loop].hit=TRUE;		// Set hit to true to manually blow up the object
		}

		// If we are to far down, direction is down and the object was not hit
		if ((object[loop].y<-2.0f) && (object[loop].dir==3) && !object[loop].hit)
		{
			miss+=1;			// Increase miss (Missed Object)
			object[loop].hit=TRUE;		// Set hit to true to manually blow up the object
		}

		if ((object[loop].y>4.5f) && (object[loop].dir==2))	// If we are to far up and the direction is up
			object[loop].dir=3;		// Change the direction to down
	}
}

void Object(float width,float height,GLuint texid)	// Draw object using requested width, height and texture
{
	glBindTexture(GL_TEXTURE_2D, textures[texid].texID);	// Select the correct texture
	glBegin(GL_QUADS);					// Start drawing a quad
		glTexCoord2f(0.0f,0.0f); glVertex3f(-width,-height,0.0f);	// Bottom left
		glTexCoord2f(1.0f,0.0f); glVertex3f( width,-height,0.0f);	// Bottom right
		glTexCoord2f(1.0f,1.0f); glVertex3f( width, height,0.0f);	// Top right
		glTexCoord2f(0.0f,1.0f); glVertex3f(-width, height,0.0f);	// Top left
	glEnd();						// Done drawing quad
}

void Explosion(int num)						// Draws an animated explosion for object "num"
{
	float ex = (float)((object[num].frame/4)%4)/4.0f;	// Calculate explosion X frame (0.0f - 0.75f)
	float ey = (float)((object[num].frame/4)/4)/4.0f;	// Calculate explosion Y frame (0.0f - 0.75f)

	glBindTexture(GL_TEXTURE_2D, textures[5].texID);	// Select the explosion texture
	glBegin(GL_QUADS);					// Begin drawing a quad
		glTexCoord2f(ex      ,1.0f-(ey      )); glVertex3f(-1.0f,-1.0f,0.0f);	// Bottom left
		glTexCoord2f(ex+0.25f,1.0f-(ey      )); glVertex3f( 1.0f,-1.0f,0.0f);	// Bottom right
		glTexCoord2f(ex+0.25f,1.0f-(ey+0.25f)); glVertex3f( 1.0f, 1.0f,0.0f);	// Top right
		glTexCoord2f(ex      ,1.0f-(ey+0.25f)); glVertex3f(-1.0f, 1.0f,0.0f);	// Top left
	glEnd();				// Done drawing quad

	object[num].frame+=1;			// Increase current explosion frame
	if (object[num].frame>63)		// Have we gone through all 16 frames?
	{
		InitObject(num);		// Init the object (Assign New Values)
	}
}

void DrawTargets(void)				// Draws the targets (Needs to be seperate)
{
	glLoadIdentity();			// Reset the modelview matrix
	glTranslatef(0.0f,0.0f,-10.0f);		// Move into the screen 20 units
	for (int loop=0; loop<level; loop++)	// Loop through 9 objects
	{
		glLoadName(loop);		// Assign object a name (ID)
		glPushMatrix();			// Push the modelview matrix
		glTranslatef(object[loop].x,object[loop].y,object[loop].distance);	// Position the object (x,y)
		if (object[loop].hit)	        // If object has been hit
		{
			Explosion(loop);        // Draw an explosion
		}
		else				// Otherwise
		{
			glRotatef(object[loop].spin,0.0f,0.0f,1.0f);	                // Rotate the object
			Object(size[object[loop].texid].w,size[object[loop].texid].h,object[loop].texid);	// Draw the object
		}
		glPopMatrix();		        // Pop the modelview matrix
	}
}

void Draw(void)         // Draw our scene
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear screen and depth buffer
	glLoadIdentity();					// Reset the modelview matrix

	glPushMatrix();						// Push the modelview matrix
	glBindTexture(GL_TEXTURE_2D, textures[7].texID);	// Select the sky texture
	glBegin(GL_QUADS);					// Begin drawing quads
		glTexCoord2f(1.0f,roll/1.5f+1.0f); glVertex3f( 28.0f,+7.0f,-50.0f);	// Top right
		glTexCoord2f(0.0f,roll/1.5f+1.0f); glVertex3f(-28.0f,+7.0f,-50.0f);	// Top left
		glTexCoord2f(0.0f,roll/1.5f+0.0f); glVertex3f(-28.0f,-3.0f,-50.0f);	// Bottom left
		glTexCoord2f(1.0f,roll/1.5f+0.0f); glVertex3f( 28.0f,-3.0f,-50.0f);	// Bottom right

		glTexCoord2f(1.5f,roll+1.0f); glVertex3f( 28.0f,+7.0f,-50.0f);		// Top right
		glTexCoord2f(0.5f,roll+1.0f); glVertex3f(-28.0f,+7.0f,-50.0f);		// Top left
		glTexCoord2f(0.5f,roll+0.0f); glVertex3f(-28.0f,-3.0f,-50.0f);		// Bottom left
		glTexCoord2f(1.5f,roll+0.0f); glVertex3f( 28.0f,-3.0f,-50.0f);		// Bottom right

		glTexCoord2f(1.0f,roll/1.5f+1.0f); glVertex3f( 28.0f,+7.0f,0.0f);	// Top right
		glTexCoord2f(0.0f,roll/1.5f+1.0f); glVertex3f(-28.0f,+7.0f,0.0f);	// Top left
		glTexCoord2f(0.0f,roll/1.5f+0.0f); glVertex3f(-28.0f,+7.0f,-50.0f);	// Bottom left
		glTexCoord2f(1.0f,roll/1.5f+0.0f); glVertex3f( 28.0f,+7.0f,-50.0f);	// Bottom right

		glTexCoord2f(1.5f,roll+1.0f); glVertex3f( 28.0f,+7.0f,0.0f);		// Top right
		glTexCoord2f(0.5f,roll+1.0f); glVertex3f(-28.0f,+7.0f,0.0f);		// Top left
		glTexCoord2f(0.5f,roll+0.0f); glVertex3f(-28.0f,+7.0f,-50.0f);		// Bottom left
		glTexCoord2f(1.5f,roll+0.0f); glVertex3f( 28.0f,+7.0f,-50.0f);		// Bottom right
	glEnd();								// Done drawing quads

	glBindTexture(GL_TEXTURE_2D, textures[6].texID);			// Select the ground texture
	glBegin(GL_QUADS);							// Draw a quad
		glTexCoord2f(7.0f,4.0f-roll); glVertex3f( 27.0f,-3.0f,-50.0f);	// Top right
		glTexCoord2f(0.0f,4.0f-roll); glVertex3f(-27.0f,-3.0f,-50.0f);	// Top left
		glTexCoord2f(0.0f,0.0f-roll); glVertex3f(-27.0f,-3.0f,0.0f);	// Bottom left
		glTexCoord2f(7.0f,0.0f-roll); glVertex3f( 27.0f,-3.0f,0.0f);	// Bottom right
	glEnd();								// Done drawing quad

	DrawTargets();						// Draw our targets
	glPopMatrix();						// Pop the modelview matrix

	// Crosshair (In ortho view)
	RECT window;						// Storage for qindow dimensions
	GetClientRect (g_window->hWnd,&window);			// Get window dimensions
	glMatrixMode(GL_PROJECTION);				// Select the projection matrix
	glPushMatrix();						// Store the projection matrix
	glLoadIdentity();					// Reset the projection matrix
	glOrtho(0,window.right,0,window.bottom,-1,1);		// Set up an ortho screen
	glMatrixMode(GL_MODELVIEW);				// Select the modelview matrix
	glTranslated(mouse_x,window.bottom-mouse_y,0.0f);	// Move to the current mouse position
	Object(16,16,8);					// Draw the crosshair

	// Game Ssats / title
	glPrint(240,450,"NeHe Productions");	// Print title
	glPrint(10,10,"Level: %i",level);	// Print level
	glPrint(250,10,"Score: %i",score);	// Print score

	if (miss>9)				// Have we missed 10 objects?
	{
		miss = 9;			// Limit misses to 10
		game = true;			// Game over true
	}

	if (game)				// Is game over?
		glPrint(490,10,"GAME OVER");	// Game over message
	else
		glPrint(490,10,"Morale: %i/10",10-miss);	// Print morale #/10

	glMatrixMode(GL_PROJECTION);		// Select the projection matrix
	glPopMatrix();				// Restore the old projection matrix
	glMatrixMode(GL_MODELVIEW);		// Select the modelview matrix

	glFlush();				// Flush the GL rendering pipeline
}
