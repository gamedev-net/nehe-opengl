/**************************************
*                                     *
*   Jeff Molofee's Picking Tutorial   *
*          nehe.gamedev.net           *
*                2001                 *
*                                     *
**************************************/

#include <windows.h>											// Header File For Windows
#include <stdio.h>												// Header File For Standard Input / Output
#include <stdarg.h>												// Header File For Variable Argument Routines
#include <gl\gl.h>												// Header File For The OpenGL32 Library
#include <gl\glu.h>												// Header File For The GLu32 Library
#include <time.h>												// For Random Seed
#include "NeHeGL.h"												// Header File For NeHeGL

#pragma comment( lib, "opengl32.lib" )							// Search For OpenGL32.lib While Linking
#pragma comment( lib, "glu32.lib" )								// Search For GLu32.lib While Linking
#pragma comment( lib, "winmm.lib" )								// Search For WinMM Library While Linking

#ifndef		CDS_FULLSCREEN										// CDS_FULLSCREEN Is Not Defined By Some
#define		CDS_FULLSCREEN 4									// Compilers. By Defining It This Way,
#endif															// We Can Avoid Errors

void DrawTargets();												// Declaration

GL_Window*	g_window;
Keys*		g_keys;

// User Defined Variables
GLuint		base;												// Font Display List
GLfloat		roll;												// Rolling Clouds
GLint		level=1;											// Current Level
GLint		miss;												// Missed Targets
GLint		kills;												// Level Kill Counter
GLint		score;												// Current Score
bool		game;												// Game Over?

typedef int (*compfn)(const void*, const void*);				// Typedef For Our Compare Function

struct objects {
	GLuint	rot;												// Rotation (0-None, 1-Clockwise, 2-Counter Clockwise)
	bool	hit;												// Object Hit?
	GLuint	frame;												// Current Explosion Frame
	GLuint	dir;												// Object Direction (0-Left, 1-Right, 2-Up, 3-Down)
	GLuint	texid;												// Object Texture ID
	GLfloat	x;													// Object X Position
	GLfloat y;													// Object Y Position
	GLfloat	spin;												// Object Spin
	GLfloat	distance;											// Object Distance
};

typedef struct													// Create A Structure
{
	GLubyte	*imageData;											// Image Data (Up To 32 Bits)
	GLuint	bpp;												// Image Color Depth In Bits Per Pixel.
	GLuint	width;												// Image Width
	GLuint	height;												// Image Height
	GLuint	texID;												// Texture ID Used To Select A Texture
} TextureImage;													// Structure Name

TextureImage textures[10];										// Storage For 10 Textures

objects	object[30];												// Storage For 30 Objects

struct dimensions {												// Object Dimensions
	GLfloat	w;													// Object Width
	GLfloat h;													// Object Height
};

// Size Of Each Object: Blueface,     Bucket,      Target,       Coke,         Vase
dimensions size[5] = { {1.0f,1.0f}, {1.0f,1.0f}, {1.0f,1.0f}, {0.5f,1.0f}, {0.75f,1.5f} };

bool LoadTGA(TextureImage *texture, char *filename)				// Loads A TGA File Into Memory
{    
	GLubyte		TGAheader[12]={0,0,2,0,0,0,0,0,0,0,0,0};		// Uncompressed TGA Header
	GLubyte		TGAcompare[12];									// Used To Compare TGA Header
	GLubyte		header[6];										// First 6 Useful Bytes From The Header
	GLuint		bytesPerPixel;									// Holds Number Of Bytes Per Pixel Used In The TGA File
	GLuint		imageSize;										// Used To Store The Image Size When Setting Aside Ram
	GLuint		temp;											// Temporary Variable
	GLuint		type=GL_RGBA;									// Set The Default GL Mode To RBGA (32 BPP)

	FILE *file = fopen(filename, "rb");							// Open The TGA File

	if(	file==NULL ||											// Does File Even Exist?
		fread(TGAcompare,1,sizeof(TGAcompare),file)!=sizeof(TGAcompare) ||	// Are There 12 Bytes To Read?
		memcmp(TGAheader,TGAcompare,sizeof(TGAheader))!=0				||	// Does The Header Match What We Want?
		fread(header,1,sizeof(header),file)!=sizeof(header))				// If So Read Next 6 Header Bytes
	{
		if (file == NULL)										// Did The File Even Exist? *Added Jim Strong*
			return FALSE;										// Return False
		else													// Otherwise
		{
			fclose(file);										// If Anything Failed, Close The File
			return FALSE;										// Return False
		}
	}

	texture->width  = header[1] * 256 + header[0];				// Determine The TGA Width	(highbyte*256+lowbyte)
	texture->height = header[3] * 256 + header[2];				// Determine The TGA Height	(highbyte*256+lowbyte)
    
 	if(	texture->width	<=0	||									// Is The Width Less Than Or Equal To Zero
		texture->height	<=0	||									// Is The Height Less Than Or Equal To Zero
		(header[4]!=24 && header[4]!=32))						// Is The TGA 24 or 32 Bit?
	{
		fclose(file);											// If Anything Failed, Close The File
		return FALSE;											// Return False
	}

	texture->bpp	= header[4];								// Grab The TGA's Bits Per Pixel (24 or 32)
	bytesPerPixel	= texture->bpp/8;							// Divide By 8 To Get The Bytes Per Pixel
	imageSize		= texture->width*texture->height*bytesPerPixel;	// Calculate The Memory Required For The TGA Data

	texture->imageData=(GLubyte *)malloc(imageSize);			// Reserve Memory To Hold The TGA Data

	if(	texture->imageData==NULL ||								// Does The Storage Memory Exist?
		fread(texture->imageData, 1, imageSize, file)!=imageSize)	// Does The Image Size Match The Memory Reserved?
	{
		if(texture->imageData!=NULL)							// Was Image Data Loaded
			free(texture->imageData);							// If So, Release The Image Data

		fclose(file);											// Close The File
		return FALSE;											// Return False
	}

	for(GLuint i=0; i<int(imageSize); i+=bytesPerPixel)			// Loop Through The Image Data
	{															// Swaps The 1st And 3rd Bytes ('R'ed and 'B'lue)
		temp=texture->imageData[i];								// Temporarily Store The Value At Image Data 'i'
		texture->imageData[i] = texture->imageData[i + 2];		// Set The 1st Byte To The Value Of The 3rd Byte
		texture->imageData[i + 2] = temp;						// Set The 3rd Byte To The Value In 'temp' (1st Byte Value)
	}

	fclose (file);												// Close The File

	// Build A Texture From The Data
	glGenTextures(1, &texture[0].texID);						// Generate OpenGL texture IDs

	glBindTexture(GL_TEXTURE_2D, texture[0].texID);				// Bind Our Texture
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// Linear Filtered
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// Linear Filtered
	
	if (texture[0].bpp==24)										// Was The TGA 24 Bits
	{
		type=GL_RGB;											// If So Set The 'type' To GL_RGB
	}

	glTexImage2D(GL_TEXTURE_2D, 0, type, texture[0].width, texture[0].height, 0, type, GL_UNSIGNED_BYTE, texture[0].imageData);

	return true;												// Texture Building Went Ok, Return True
}

GLvoid BuildFont(GLvoid)										// Build Our Font Display List
{
	base=glGenLists(95);										// Creating 95 Display Lists
	glBindTexture(GL_TEXTURE_2D, textures[9].texID);			// Bind Our Font Texture
	for (int loop=0; loop<95; loop++)							// Loop Through All 95 Lists
	{
		float cx=float(loop%16)/16.0f;							// X Position Of Current Character
		float cy=float(loop/16)/8.0f;							// Y Position Of Current Character

		glNewList(base+loop,GL_COMPILE);						// Start Building A List
			glBegin(GL_QUADS);									// Use A Quad For Each Character
				glTexCoord2f(cx,         1.0f-cy-0.120f); glVertex2i(0,0);	// Texture / Vertex Coord (Bottom Left)
				glTexCoord2f(cx+0.0625f, 1.0f-cy-0.120f); glVertex2i(16,0);	// Texutre / Vertex Coord (Bottom Right)
				glTexCoord2f(cx+0.0625f, 1.0f-cy);		  glVertex2i(16,16);// Texture / Vertex Coord (Top Right)
				glTexCoord2f(cx,         1.0f-cy);		  glVertex2i(0,16);	// Texture / Vertex Coord (Top Left)
			glEnd();											// Done Building Our Quad (Character)
			glTranslated(10,0,0);								// Move To The Right Of The Character
		glEndList();											// Done Building The Display List
	}															// Loop Until All 256 Are Built
}

GLvoid glPrint(GLint x, GLint y, const char *string, ...)		// Where The Printing Happens
{
	char		text[256];										// Holds Our String
	va_list		ap;												// Pointer To List Of Arguments

	if (string == NULL)											// If There's No Text
		return;													// Do Nothing

	va_start(ap, string);										// Parses The String For Variables
	    vsprintf(text, string, ap);								// And Converts Symbols To Actual Numbers
	va_end(ap);													// Results Are Stored In Text

	glBindTexture(GL_TEXTURE_2D, textures[9].texID);			// Select Our Font Texture
	glPushMatrix();												// Store The Modelview Matrix
	glLoadIdentity();											// Reset The Modelview Matrix
	glTranslated(x,y,0);										// Position The Text (0,0 - Bottom Left)
	glListBase(base-32);										// Choose The Font Set
	glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);			// Draws The Display List Text
	glPopMatrix();												// Restore The Old Projection Matrix
}

int Compare(struct objects *elem1, struct objects *elem2)		// Compare Function *** MSDN CODE MODIFIED FOR THIS TUT ***
{
   if ( elem1->distance < elem2->distance)						// If First Structure distance Is Less Than The Second
      return -1;												// Return -1
   else if (elem1->distance > elem2->distance)					// If First Structure distance Is Greater Than The Second
      return 1;													// Return 1
   else															// Otherwise (If The distance Is Equal)
      return 0;													// Return 0
}

GLvoid InitObject(int num)										// Initialize An Object
{
	object[num].rot=1;											// Clockwise Rotation
	object[num].frame=0;										// Reset The Explosion Frame To Zero
	object[num].hit=FALSE;										// Reset Object Has Been Hit Status To False
	object[num].texid=rand()%5;									// Assign A New Texture
	object[num].distance=-(float(rand()%4001)/100.0f);			// Random Distance
	object[num].y=-1.5f+(float(rand()%451)/100.0f);				// Random Y Position
	// Random Starting X Position Based On Distance Of Object And Random Amount For A Delay (Positive Value)
	object[num].x=((object[num].distance-15.0f)/2.0f)-(5*level)-float(rand()%(5*level));
	object[num].dir=(rand()%2);									// Pick A Random Direction

	if (object[num].dir==0)										// Is Random Direction Right
	{
		object[num].rot=2;										// Counter Clockwise Rotation
		object[num].x=-object[num].x;							// Start On The Left Side (Negative Value)
	}

	if (object[num].texid==0)									// Blue Face
		object[num].y=-2.0f;									// Always Rolling On The Ground

	if (object[num].texid==1)									// Bucket
	{
		object[num].dir=3;										// Falling Down
		object[num].x=float(rand()%int(object[num].distance-10.0f))+((object[num].distance-10.0f)/2.0f);
		object[num].y=4.5f;										// Random X, Start At Top Of The Screen
	}

	if (object[num].texid==2)									// Target
	{
		object[num].dir=2;										// Start Off Flying Up
		object[num].x=float(rand()%int(object[num].distance-10.0f))+((object[num].distance-10.0f)/2.0f);
		object[num].y=-3.0f-float(rand()%(5*level));			// Random X, Start Under Ground + Random Value
	}

	// Sort Objects By Distance:	Beginning Address Of Our object Array	*** MSDN CODE MODIFIED FOR THIS TUT ***
	//								Number Of Elements To Sort
	//								Size Of Each Element
	//								Pointer To Our Compare Function
	qsort((void *) &object, level, sizeof(struct objects), (compfn)Compare );
}

BOOL Initialize (GL_Window* window, Keys* keys)					// Any OpenGL Initialization Goes Here
{
	g_window	= window;
	g_keys		= keys;

	srand( (unsigned)time( NULL ) );							// Randomize Things

	if ((!LoadTGA(&textures[0],"Data/BlueFace.tga")) ||			// Load The BlueFace Texture
		(!LoadTGA(&textures[1],"Data/Bucket.tga")) ||			// Load The Bucket Texture
		(!LoadTGA(&textures[2],"Data/Target.tga")) ||			// Load The Target Texture
		(!LoadTGA(&textures[3],"Data/Coke.tga")) ||				// Load The Coke Texture
		(!LoadTGA(&textures[4],"Data/Vase.tga")) ||				// Load The Vase Texture
		(!LoadTGA(&textures[5],"Data/Explode.tga")) ||			// Load The Explosion Texture
		(!LoadTGA(&textures[6],"Data/Ground.tga")) ||			// Load The Ground Texture
		(!LoadTGA(&textures[7],"Data/Sky.tga")) ||				// Load The Sky Texture
		(!LoadTGA(&textures[8],"Data/Crosshair.tga")) ||		// Load The Crosshair Texture
		(!LoadTGA(&textures[9],"Data/Font.tga")))				// Load The Crosshair Texture
	{
		return FALSE;											// If Loading Failed, Return False
	}

	BuildFont();												// Build Our Font Display List

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);						// Black Background
	glClearDepth(1.0f);											// Depth Buffer Setup
	glDepthFunc(GL_LEQUAL);										// Type Of Depth Testing
	glEnable(GL_DEPTH_TEST);									// Enable Depth Testing
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);			// Enable Alpha Blending (disable alpha testing)
	glEnable(GL_BLEND);											// Enable Blending       (disable alpha testing)
//	glAlphaFunc(GL_GREATER,0.1f);								// Set Alpha Testing     (disable blending)
//	glEnable(GL_ALPHA_TEST);									// Enable Alpha Testing  (disable blending)
	glEnable(GL_TEXTURE_2D);									// Enable Texture Mapping
	glEnable(GL_CULL_FACE);										// Remove Back Face

	for (int loop=0; loop<30; loop++)							// Loop Through 30 Objects
		InitObject(loop);										// Initialize Each Object
	
	return TRUE;												// Return TRUE (Initialization Successful)
}

void Deinitialize (void)										// Any User DeInitialization Goes Here
{
	glDeleteLists(base,95);										// Delete All 95 Font Display Lists
}

void Selection(void)											// This Is Where Selection Is Done
{
	GLuint	buffer[512];										// Set Up A Selection Buffer
	GLint	hits;												// The Number Of Objects That We Selected

	if (game)													// Is Game Over?
		return;													// If So, Don't Bother Checking For Hits
	
	PlaySound("data/shot.wav",NULL,SND_ASYNC);					// Play Gun Shot Sound

	// The Size Of The Viewport. [0] Is <x>, [1] Is <y>, [2] Is <length>, [3] Is <width>
	GLint	viewport[4];

	// This Sets The Array <viewport> To The Size And Location Of The Screen Relative To The Window
	glGetIntegerv(GL_VIEWPORT, viewport);
	glSelectBuffer(512, buffer);								// Tell OpenGL To Use Our Array For Selection

	// Puts OpenGL In Selection Mode. Nothing Will Be Drawn.  Object ID's and Extents Are Stored In The Buffer.
	(void) glRenderMode(GL_SELECT);

	glInitNames();												// Initializes The Name Stack
	glPushName(0);												// Push 0 (At Least One Entry) Onto The Stack

	glMatrixMode(GL_PROJECTION);								// Selects The Projection Matrix
	glPushMatrix();												// Push The Projection Matrix
	glLoadIdentity();											// Resets The Matrix

	// This Creates A Matrix That Will Zoom Up To A Small Portion Of The Screen, Where The Mouse Is.
	gluPickMatrix((GLdouble) mouse_x, (GLdouble) (viewport[3]-mouse_y), 1.0f, 1.0f, viewport);

	// Apply The Perspective Matrix
	gluPerspective(45.0f, (GLfloat) (viewport[2]-viewport[0])/(GLfloat) (viewport[3]-viewport[1]), 0.1f, 100.0f);
	glMatrixMode(GL_MODELVIEW);									// Select The Modelview Matrix
	DrawTargets();												// Render The Targets To The Selection Buffer
	glMatrixMode(GL_PROJECTION);								// Select The Projection Matrix
	glPopMatrix();												// Pop The Projection Matrix
	glMatrixMode(GL_MODELVIEW);									// Select The Modelview Matrix
	hits=glRenderMode(GL_RENDER);								// Switch To Render Mode, Find Out How Many
																// Objects Were Drawn Where The Mouse Was
	if (hits > 0)												// If There Were More Than 0 Hits
	{
		int	choose = buffer[3];									// Make Our Selection The First Object
		int depth = buffer[1];									// Store How Far Away It Is 

		for (int loop = 1; loop < hits; loop++)					// Loop Through All The Detected Hits
		{
			// If This Object Is Closer To Us Than The One We Have Selected
			if (buffer[loop*4+1] < GLuint(depth))
			{
				choose = buffer[loop*4+3];						// Select The Closer Object
				depth = buffer[loop*4+1];						// Store How Far Away It Is
			}       
		}

		if (!object[choose].hit)								// If The Object Hasn't Already Been Hit
		{
			object[choose].hit=TRUE;							// Mark The Object As Being Hit
			score+=1;											// Increase Score
			kills+=1;											// Increase Level Kills
			if (kills>level*5)									// New Level Yet?
			{
				miss=0;											// Misses Reset Back To Zero
				kills=0;										// Reset Level Kills
				level+=1;										// Increase Level
				if (level>30)									// Higher Than 30?
					level=30;									// Set Level To 30 (Are You A God?)
			}
		}
    }
}

void Update(DWORD milliseconds)									// Perform Motion Updates Here
{
	if (g_keys->keyDown[VK_ESCAPE])								// Is ESC Being Pressed?
	{
		TerminateApplication (g_window);						// Terminate The Program
	}

	if (g_keys->keyDown[' '] && game)							// Space Bar Being Pressed After Game Has Ended?
	{
		for (int loop=0; loop<30; loop++)							// Loop Through 30 Objects
			InitObject(loop);										// Initialize Each Object

		game=FALSE;												// Set game (Game Over) To False
		score=0;												// Set score To 0
		level=1;												// Set level Back To 1
		kills=0;												// Zero Player Kills
		miss=0;													// Set miss (Missed Shots) To 0
	}

	if (g_keys->keyDown[VK_F1])									// Is F1 Being Pressed?
	{
		ToggleFullscreen (g_window);							// Toggle Fullscreen Mode
	}

	roll-=milliseconds*0.00005f;								// Roll The Clouds

	for (int loop=0; loop<level; loop++)						// Loop Through The Objects
	{
		if (object[loop].rot==1)								// If Rotation Is Clockwise
			object[loop].spin-=0.2f*(float(loop+milliseconds));	// Spin Clockwise

		if (object[loop].rot==2)								// If Rotation Is Counter Clockwise
			object[loop].spin+=0.2f*(float(loop+milliseconds));	// Spin Counter Clockwise
		
		if (object[loop].dir==1)								// If Direction Is Right
			object[loop].x+=0.012f*float(milliseconds);			// Move Right

		if (object[loop].dir==0)								// If Direction Is Left
			object[loop].x-=0.012f*float(milliseconds);			// Move Left

		if (object[loop].dir==2)								// If Direction Is Up
			object[loop].y+=0.012f*float(milliseconds);			// Move Up

		if (object[loop].dir==3)								// If Direction Is Down
			object[loop].y-=0.0025f*float(milliseconds);		// Move Down

		// If We Are To Far Left, Direction Is Left And The Object Was Not Hit
		if ((object[loop].x<(object[loop].distance-15.0f)/2.0f) && (object[loop].dir==0) && !object[loop].hit)
		{
			miss+=1;											// Increase miss (Missed Object)
			object[loop].hit=TRUE;								// Set hit To True To Manually Blow Up The Object
		}

		// If We Are To Far Right, Direction Is Left And The Object Was Not Hit
		if ((object[loop].x>-(object[loop].distance-15.0f)/2.0f) && (object[loop].dir==1) && !object[loop].hit)
		{
			miss+=1;											// Increase miss (Missed Object)
			object[loop].hit=TRUE;								// Set hit To True To Manually Blow Up The Object
		}

		// If We Are To Far Down, Direction Is Down And The Object Was Not Hit
		if ((object[loop].y<-2.0f) && (object[loop].dir==3) && !object[loop].hit)
		{
			miss+=1;											// Increase miss (Missed Object)
			object[loop].hit=TRUE;								// Set hit To True To Manually Blow Up The Object
		}

		if ((object[loop].y>4.5f) && (object[loop].dir==2))		// If We Are To Far Up And The Direction Is Up
			object[loop].dir=3;									// Change The Direction To Down
	}
}

void Object(float width,float height,GLuint texid)				// Draw Object Using Requested Width, Height And Texture
{
	glBindTexture(GL_TEXTURE_2D, textures[texid].texID);		// Select The Correct Texture
	glBegin(GL_QUADS);											// Start Drawing A Quad
		glTexCoord2f(0.0f,0.0f); glVertex3f(-width,-height,0.0f);	// Bottom Left
		glTexCoord2f(1.0f,0.0f); glVertex3f( width,-height,0.0f);	// Bottom Right
		glTexCoord2f(1.0f,1.0f); glVertex3f( width, height,0.0f);	// Top Right
		glTexCoord2f(0.0f,1.0f); glVertex3f(-width, height,0.0f);	// Top Left
	glEnd();													// Done Drawing Quad
}

void Explosion(int num)											// Draws An Animated Explosion For Object "num"
{
	float ex = (float)((object[num].frame/4)%4)/4.0f;			// Calculate Explosion X Frame (0.0f - 0.75f)
	float ey = (float)((object[num].frame/4)/4)/4.0f;			// Calculate Explosion Y Frame (0.0f - 0.75f)

	glBindTexture(GL_TEXTURE_2D, textures[5].texID);			// Select The Explosion Texture
	glBegin(GL_QUADS);											// Begin Drawing A Quad
		glTexCoord2f(ex      ,1.0f-(ey      )); glVertex3f(-1.0f,-1.0f,0.0f);	// Bottom Left
		glTexCoord2f(ex+0.25f,1.0f-(ey      )); glVertex3f( 1.0f,-1.0f,0.0f);	// Bottom Right
		glTexCoord2f(ex+0.25f,1.0f-(ey+0.25f)); glVertex3f( 1.0f, 1.0f,0.0f);	// Top Right
		glTexCoord2f(ex      ,1.0f-(ey+0.25f)); glVertex3f(-1.0f, 1.0f,0.0f);	// Top Left
	glEnd();													// Done Drawing Quad

	object[num].frame+=1;										// Increase Current Explosion Frame
	if (object[num].frame>63)									// Have We Gone Through All 16 Frames?
	{
		InitObject(num);										// Init The Object (Assign New Values)
	}
}

void DrawTargets(void)											// Draws The Targets (Needs To Be Seperate)
{
	glLoadIdentity();											// Reset The Modelview Matrix
	glTranslatef(0.0f,0.0f,-10.0f);								// Move Into The Screen 20 Units
	for (int loop=0; loop<level; loop++)						// Loop Through 9 Objects
	{
		glLoadName(loop);										// Assign Object A Name (ID)
		glPushMatrix();											// Push The Modelview Matrix
		glTranslatef(object[loop].x,object[loop].y,object[loop].distance);		// Position The Object (x,y)
		if (object[loop].hit)									// If Object Has Been Hit
		{
			Explosion(loop);									// Draw An Explosion
		}
		else													// Otherwise
		{
			glRotatef(object[loop].spin,0.0f,0.0f,1.0f);		// Rotate The Object
			Object(size[object[loop].texid].w,size[object[loop].texid].h,object[loop].texid);	// Draw The Object
		}
		glPopMatrix();											// Pop The Modelview Matrix
	}
}

void Draw(void)													// Draw Our Scene
{
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glLoadIdentity();											// Reset The Modelview Matrix

	glPushMatrix();												// Push The Modelview Matrix
	glBindTexture(GL_TEXTURE_2D, textures[7].texID);			// Select The Sky Texture
	glBegin(GL_QUADS);											// Begin Drawing Quads
		glTexCoord2f(1.0f,roll/1.5f+1.0f); glVertex3f( 28.0f,+7.0f,-50.0f);	// Top Right
		glTexCoord2f(0.0f,roll/1.5f+1.0f); glVertex3f(-28.0f,+7.0f,-50.0f);	// Top Left
		glTexCoord2f(0.0f,roll/1.5f+0.0f); glVertex3f(-28.0f,-3.0f,-50.0f);	// Bottom Left
		glTexCoord2f(1.0f,roll/1.5f+0.0f); glVertex3f( 28.0f,-3.0f,-50.0f);	// Bottom Right

		glTexCoord2f(1.5f,roll+1.0f); glVertex3f( 28.0f,+7.0f,-50.0f);		// Top Right
		glTexCoord2f(0.5f,roll+1.0f); glVertex3f(-28.0f,+7.0f,-50.0f);		// Top Left
		glTexCoord2f(0.5f,roll+0.0f); glVertex3f(-28.0f,-3.0f,-50.0f);		// Bottom Left
		glTexCoord2f(1.5f,roll+0.0f); glVertex3f( 28.0f,-3.0f,-50.0f);		// Bottom Right

		glTexCoord2f(1.0f,roll/1.5f+1.0f); glVertex3f( 28.0f,+7.0f,0.0f);	// Top Right
		glTexCoord2f(0.0f,roll/1.5f+1.0f); glVertex3f(-28.0f,+7.0f,0.0f);	// Top Left
		glTexCoord2f(0.0f,roll/1.5f+0.0f); glVertex3f(-28.0f,+7.0f,-50.0f);	// Bottom Left
		glTexCoord2f(1.0f,roll/1.5f+0.0f); glVertex3f( 28.0f,+7.0f,-50.0f);	// Bottom Right

		glTexCoord2f(1.5f,roll+1.0f); glVertex3f( 28.0f,+7.0f,0.0f);		// Top Right
		glTexCoord2f(0.5f,roll+1.0f); glVertex3f(-28.0f,+7.0f,0.0f);		// Top Left
		glTexCoord2f(0.5f,roll+0.0f); glVertex3f(-28.0f,+7.0f,-50.0f);		// Bottom Left
		glTexCoord2f(1.5f,roll+0.0f); glVertex3f( 28.0f,+7.0f,-50.0f);		// Bottom Right
	glEnd();													// Done Drawing Quads

	glBindTexture(GL_TEXTURE_2D, textures[6].texID);			// Select The Ground Texture
	glBegin(GL_QUADS);											// Draw A Quad
		glTexCoord2f(7.0f,4.0f-roll); glVertex3f( 27.0f,-3.0f,-50.0f);	// Top Right
		glTexCoord2f(0.0f,4.0f-roll); glVertex3f(-27.0f,-3.0f,-50.0f);	// Top Left
		glTexCoord2f(0.0f,0.0f-roll); glVertex3f(-27.0f,-3.0f,0.0f);	// Bottom Left
		glTexCoord2f(7.0f,0.0f-roll); glVertex3f( 27.0f,-3.0f,0.0f);	// Bottom Right
	glEnd();													// Done Drawing Quad

	DrawTargets();												// Draw Our Targets
	glPopMatrix();												// Pop The Modelview Matrix

	// Crosshair (In Ortho View)
	RECT window;												// Storage For Window Dimensions
	GetClientRect (g_window->hWnd,&window);						// Get Window Dimensions
	glMatrixMode(GL_PROJECTION);								// Select The Projection Matrix
	glPushMatrix();												// Store The Projection Matrix
	glLoadIdentity();											// Reset The Projection Matrix
	glOrtho(0,window.right,0,window.bottom,-1,1);				// Set Up An Ortho Screen
	glMatrixMode(GL_MODELVIEW);									// Select The Modelview Matrix
	glTranslated(mouse_x,window.bottom-mouse_y,0.0f);			// Move To The Current Mouse Position
	Object(16,16,8);											// Draw The Crosshair

	// Game Stats / Title
	glPrint(240,450,"NeHe Productions");						// Print Title
	glPrint(10,10,"Level: %i",level);							// Print Level
	glPrint(250,10,"Score: %i",score);							// Print Score

	if (miss>9)													// Have We Missed 10 Objects?
	{
		miss=9;													// Limit Misses To 10
		game=TRUE;												// Game Over TRUE
	}

	if (game)													// Is Game Over?
		glPrint(490,10,"GAME OVER");							// Game Over Message
	else
		glPrint(490,10,"Morale: %i/10",10-miss);				// Print Morale #/10

	glMatrixMode(GL_PROJECTION);								// Select The Projection Matrix
	glPopMatrix();												// Restore The Old Projection Matrix
	glMatrixMode(GL_MODELVIEW);									// Select The Modelview Matrix

	glFlush();													// Flush The GL Rendering Pipeline
}
