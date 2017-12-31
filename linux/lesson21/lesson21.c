//
// This code was created by Jeff Molofee '99
// (ported to SDL by Marius Andra '2000 (marius@hot.ee))
// (ImageLoad function created by Sam Lantinga '2000)
// (Background tune by the Lizardking)
//
// If you've found this code useful, please let me know.
//
// Visit me at http://nehe.gamedev.net (nehe)
// or me at http://www.hot.ee/marius (marius)
//

#define SOUND // Comment this out if you don't want sound...

#ifdef WIN32
#include <windows.h>
#endif
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <GL/gl.h>	// Header File For The OpenGL32 Library
#include <GL/glu.h>	// Header File For The GLu32 Library
#include <SDL/SDL.h>
#include <SDL/SDL_timer.h>

#ifdef SOUND
#include <SDL/SDL_mixer.h>
#endif

char vline[11][10];
char hline[10][11];
char ap,filled,gameover,anti=1,active=1,fullscreen=1;


#ifdef SOUND
Mix_Chunk *complete, *die, *freeze, *hglass;                  // sfx
Mix_Music *music;                                             // music
#endif
int loop1,loop2,delay,adjust=3,lives=5,level=1,level2=1,stage=1;

struct object
{
  int fx,fy,x,y;
  float spin;
};

struct object player;
struct object enemy[9];
struct object hourglass;

int steps[6]={1,2,4,5,10,20};

GLuint texture[2], base;

float TimerGetTime()
{
  return SDL_GetTicks();
}

#ifdef SOUND
Mix_Chunk * load_sound(char * file)                     // Load a sound file
{
  Mix_Chunk * sound;
  sound = Mix_LoadWAV(file);
  if (!sound)
  {
    fprintf(stderr, "Error: %s\n\n", SDL_GetError());
    exit(2);
  }
  return(sound);
}
#endif

void ResetObjects()
{
  player.x=0;
  player.y=0;
  player.fx=0;
  player.fy=0;

  for(loop1=0;loop1<(stage*level);loop1++)
  {
    enemy[loop1].x=5+rand()%6;
    enemy[loop1].y=rand()%11;
    enemy[loop1].fx=enemy[loop1].x*60;
    enemy[loop1].fy=enemy[loop1].y*40;

  }

}


SDL_Surface *ImageLoad(char *filename)
{
    Uint8 *rowhi, *rowlo;
    Uint8 *tmpbuf, tmpch;
    SDL_Surface *image;
    int i, j;

    image = SDL_LoadBMP(filename);
    if ( image == NULL ) {
        fprintf(stderr, "Unable to load %s: %s\n", filename, SDL_GetError());
        return(NULL);
    }

    /* GL surfaces are upsidedown and RGB, not BGR :-) */
    tmpbuf = (Uint8 *)malloc(image->pitch);
    if ( tmpbuf == NULL ) {
        fprintf(stderr, "Out of memory\n");
        return(NULL);
    }
    rowhi = (Uint8 *)image->pixels;
    rowlo = rowhi + (image->h * image->pitch) - image->pitch;
    for ( i=0; i<image->h/2; ++i ) {
        for ( j=0; j<image->w; ++j ) {
            tmpch = rowhi[j*3];
            rowhi[j*3] = rowhi[j*3+2];
            rowhi[j*3+2] = tmpch;
            tmpch = rowlo[j*3];
            rowlo[j*3] = rowlo[j*3+2];
            rowlo[j*3+2] = tmpch;
        }
        memcpy(tmpbuf, rowhi, image->pitch);
        memcpy(rowhi, rowlo, image->pitch);
        memcpy(rowlo, tmpbuf, image->pitch);
        rowhi += image->pitch;
        rowlo -= image->pitch;
    }
    free(tmpbuf);
    return(image);
}

// Load Bitmaps And Convert To Textures
void LoadGLTextures(void)
{
     // A bit messy, isn't it?

    // Load Texture
    SDL_Surface *image1;

    image1 = ImageLoad("Data/Font.bmp");
    if (!image1) {
        SDL_Quit();
        exit(1);
    }

    // Create Texture
    glGenTextures(1, &texture[0]);
    glBindTexture(GL_TEXTURE_2D, texture[0]);   // 2d texture (x and y size)

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); // scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); // scale linearly when image smalled than texture

    // 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image,
    // border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->w, image1->h, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->pixels);


    image1 = ImageLoad("Data/Image.bmp");
    if (!image1) {
        SDL_Quit();
        exit(1);
    }

    // Create Texture
    glGenTextures(1, &texture[1]);
    glBindTexture(GL_TEXTURE_2D, texture[1]);   // 2d texture (x and y size)

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); // scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); // scale linearly when image smalled than texture

    // 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image,
    // border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1->w, image1->h, 0, GL_RGB, GL_UNSIGNED_BYTE, image1->pixels);

};

GLvoid BuildFont(GLvoid)
{
 float cx,cy;
	base=glGenLists(256);									// Creating 256 Display Lists
	glBindTexture(GL_TEXTURE_2D, texture[0]);				// Select Our Font Texture
	for (loop1=0; loop1<256; loop1++)						// Loop Through All 256 Lists
	{
		cx=(float)(loop1%16)/16.0f;						// X Position Of Current Character
		cy=(float)(loop1/16)/16.0f;						// Y Position Of Current Character

		glNewList(base+loop1,GL_COMPILE);					// Start Building A List
			glBegin(GL_QUADS);								// Use A Quad For Each Character
				glTexCoord2f(cx,1.0f-cy-0.0625f);			// Texture Coord (Bottom Left)
				glVertex2d(0,16);							// Vertex Coord (Bottom Left)
				glTexCoord2f(cx+0.0625f,1.0f-cy-0.0625f);	// Texture Coord (Bottom Right)
				glVertex2i(16,16);							// Vertex Coord (Bottom Right)
				glTexCoord2f(cx+0.0625f,1.0f-cy);			// Texture Coord (Top Right)
				glVertex2i(16,0);							// Vertex Coord (Top Right)
				glTexCoord2f(cx,1.0f-cy);					// Texture Coord (Top Left)
				glVertex2i(0,0);							// Vertex Coord (Top Left)
			glEnd();										// Done Building Our Quad (Character)
			glTranslated(15,0,0);							// Move To The Right Of The Character
		glEndList();										// Done Building The Display List
	}														// Loop Until All 256 Are Built
}


GLvoid KillFont(GLvoid)
{
 glDeleteLists(base,256);
}

GLvoid glPrint(GLint x,GLint y,int set, const char *text)
{
	if (set>1)												// Did User Choose An Invalid Character Set?
	{
		set=1;												// If So, Select Set 1 (Italic)
	}
	glEnable(GL_TEXTURE_2D);								// Enable Texture Mapping
	glLoadIdentity();										// Reset The Modelview Matrix
	glTranslated(x,y,0);									// Position The Text (0,0 - Bottom Left)
	glListBase(base-32+(128*set));							// Choose The Font Set (0 or 1)

	if (set==0)												// If Set 0 Is Being Used Enlarge Font
	{
		glScalef(1.5f,2.0f,1.0f);							// Enlarge Font Width And Height
	}

	glCallLists(strlen(text),GL_UNSIGNED_BYTE, text);		// Write The Text To The Screen
	glDisable(GL_TEXTURE_2D);								// Disable Texture Mapping
}

/* A general OpenGL initialization function.  Sets all of the initial parameters. */
void InitGL(int Width, int Height)	        // We call this right after our OpenGL window is created.
{
    LoadGLTextures();				// Load The Texture(s)
    BuildFont();
    glShadeModel(GL_SMOOTH);

    glClearColor(0.0f, 0.0f, 0.0f, 0.5f);	// Clear The Background Color To Blue
    glClearDepth(1.0);				// Enables Clearing Of The Depth Buffer
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glViewport(0, 0, Width, Height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();				// Reset The Projection Matrix

    glOrtho(0.0f,Width,Height,0.0f,-1.0f,1.0f);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}


/* The main drawing function. */
int DrawGLScene()
{
        char temp[256];
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer
	glBindTexture(GL_TEXTURE_2D, texture[0]);				// Select Our Font Texture
	glColor3f(1.0f,0.5f,1.0f);								// Set Color To Purple
	glPrint(207,24,0,"GRID CRAZY");							// Write GRID CRAZY On The Screen
	glColor3f(1.0f,1.0f,0.0f);								// Set Color To Yellow

        sprintf(temp,"Level:%2i",level2);
        glPrint(20,20,1,temp);					// Write Actual Level Stats
        sprintf(temp,"Stage:%2i",stage);
	glPrint(20,40,1,temp);						// Write Stage Stats

	if (gameover)											// Is The Game Over?
	{
		glColor3ub(rand()%255,rand()%255,rand()%255);		// Pick A Random Color
		glPrint(472,20,1,"GAME OVER");						// Write GAME OVER To The Screen
		glPrint(456,40,1,"PRESS SPACE");					// Write PRESS SPACE To The Screen
	}

	for (loop1=0; loop1<lives-1; loop1++)					// Loop Through Lives Minus Current Life
	{
		glLoadIdentity();									// Reset The View
		glTranslatef(490+(loop1*40.0f),40.0f,0.0f);			// Move To The Right Of Our Title Text
		glRotatef(-player.spin,0.0f,0.0f,1.0f);				// Rotate Counter Clockwise
		glColor3f(0.0f,1.0f,0.0f);							// Set Player Color To Light Green
		glBegin(GL_LINES);									// Start Drawing Our Player Using Lines
			glVertex2d(-5,-5);								// Top Left Of Player
			glVertex2d( 5, 5);								// Bottom Right Of Player
			glVertex2d( 5,-5);								// Top Right Of Player
			glVertex2d(-5, 5);								// Bottom Left Of Player
		glEnd();											// Done Drawing The Player
		glRotatef(-player.spin*0.5f,0.0f,0.0f,1.0f);		// Rotate Counter Clockwise
		glColor3f(0.0f,0.75f,0.0f);							// Set Player Color To Dark Green
		glBegin(GL_LINES);									// Start Drawing Our Player Using Lines
			glVertex2d(-7, 0);								// Left Center Of Player
			glVertex2d( 7, 0);								// Right Center Of Player
			glVertex2d( 0,-7);								// Top Center Of Player
			glVertex2d( 0, 7);								// Bottom Center Of Player
		glEnd();											// Done Drawing The Player
	}

	filled=1;											// Set Filled To 1 Before Testing
	glLineWidth(2.0f);										// Set Line Width For Cells To 2.0f
	glDisable(GL_LINE_SMOOTH);								// Disable Antialiasing
	glLoadIdentity();										// Reset The Current Modelview Matrix
	for (loop1=0; loop1<11; loop1++)						// Loop From Left To Right
	{
		for (loop2=0; loop2<11; loop2++)					// Loop From Top To Bottom
		{
			glColor3f(0.0f,0.5f,1.0f);						// Set Line Color To Blue
			if (hline[loop1][loop2])						// Has The Horizontal Line Been Traced
			{
				glColor3f(1.0f,1.0f,1.0f);					// If So, Set Line Color To White
			}

			if (loop1<10)									// Dont Draw To Far Right
			{
				if (!hline[loop1][loop2])					// If A Horizontal Line Isn't Filled
				{
					filled=0;							// filled Becomes 0
				}
				glBegin(GL_LINES);							// Start Drawing Horizontal Cell Borders
					glVertex2d(20+(loop1*60),70+(loop2*40));// Left Side Of Horizontal Line
					glVertex2d(80+(loop1*60),70+(loop2*40));// Right Side Of Horizontal Line
				glEnd();									// Done Drawing Horizontal Cell Borders
			}

			glColor3f(0.0f,0.5f,1.0f);						// Set Line Color To Blue
			if (vline[loop1][loop2])						// Has The Horizontal Line Been Traced
			{
				glColor3f(1.0f,1.0f,1.0f);					// If So, Set Line Color To White
			}
			if (loop2<10)									// Dont Draw To Far Down
			{
				if (!vline[loop1][loop2])					// If A Verticle Line Isn't Filled
				{
					filled=0;							// filled Becomes 0
				}
				glBegin(GL_LINES);							// Start Drawing Verticle Cell Borders
					glVertex2d(20+(loop1*60),70+(loop2*40));// Left Side Of Horizontal Line
					glVertex2d(20+(loop1*60),110+(loop2*40));// Right Side Of Horizontal Line
				glEnd();									// Done Drawing Verticle Cell Borders
			}

			glEnable(GL_TEXTURE_2D);						// Enable Texture Mapping
			glColor3f(1.0f,1.0f,1.0f);						// Bright White Color
			glBindTexture(GL_TEXTURE_2D, texture[1]);		// Select The Tile Image
			if ((loop1<10) && (loop2<10))					// If In Bounds, Fill In Traced Boxes
			{
				// Are All Sides Of The Box Traced?
				if (hline[loop1][loop2] && hline[loop1][loop2+1] && vline[loop1][loop2] && vline[loop1+1][loop2])
				{
					glBegin(GL_QUADS);						// Draw A Textured Quad
						glTexCoord2f((float)(loop1/10.0f)+0.1f,1.0f-((float)(loop2/10.0f)));
						glVertex2d(20+(loop1*60)+59,(70+loop2*40+1));	// Top Right
						glTexCoord2f((float)(loop1/10.0f),1.0f-((float)(loop2/10.0f)));
						glVertex2d(20+(loop1*60)+1,(70+loop2*40+1));	// Top Left
						glTexCoord2f((float)(loop1/10.0f),1.0f-((float)(loop2/10.0f)+0.1f));
						glVertex2d(20+(loop1*60)+1,(70+loop2*40)+39);	// Bottom Left
						glTexCoord2f((float)(loop1/10.0f)+0.1f,1.0f-((float)(loop2/10.0f)+0.1f));
						glVertex2d(20+(loop1*60)+59,(70+loop2*40)+39);	// Bottom Right
					glEnd();								// Done Texturing The Box
				}
			}
			glDisable(GL_TEXTURE_2D);						// Disable Texture Mapping
		}
	}
	glLineWidth(1.0f);										// Set The Line Width To 1.0f

	if (anti)												// Is Anti 1?
	{
		glEnable(GL_LINE_SMOOTH);							// If So, Enable Antialiasing
	}

	if (hourglass.fx==1)									// If fx=1 Draw The Hourglass
	{
		glLoadIdentity();									// Reset The Modelview Matrix
		glTranslatef(20.0f+(hourglass.x*60),70.0f+(hourglass.y*40),0.0f);	// Move To The Fine Hourglass Position
		glRotatef(hourglass.spin,0.0f,0.0f,1.0f);			// Rotate Clockwise
		glColor3ub(rand()%255,rand()%255,rand()%255);		// Set Hourglass Color To Random Color
		glBegin(GL_LINES);									// Start Drawing Our Hourglass Using Lines
			glVertex2d(-5,-5);								// Top Left Of Hourglass
			glVertex2d( 5, 5);								// Bottom Right Of Hourglass
			glVertex2d( 5,-5);								// Top Right Of Hourglass
			glVertex2d(-5, 5);								// Bottom Left Of Hourglass
			glVertex2d(-5, 5);								// Bottom Left Of Hourglass
			glVertex2d( 5, 5);								// Bottom Right Of Hourglass
			glVertex2d(-5,-5);								// Top Left Of Hourglass
			glVertex2d( 5,-5);								// Top Right Of Hourglass
		glEnd();											// Done Drawing The Hourglass
	}

	glLoadIdentity();										// Reset The Modelview Matrix
	glTranslatef(player.fx+20.0f,player.fy+70.0f,0.0f);		// Move To The Fine Player Position
	glRotatef(player.spin,0.0f,0.0f,1.0f);					// Rotate Clockwise
	glColor3f(0.0f,1.0f,0.0f);								// Set Player Color To Light Green
	glBegin(GL_LINES);										// Start Drawing Our Player Using Lines
		glVertex2d(-5,-5);									// Top Left Of Player
		glVertex2d( 5, 5);									// Bottom Right Of Player
		glVertex2d( 5,-5);									// Top Right Of Player
		glVertex2d(-5, 5);									// Bottom Left Of Player
	glEnd();												// Done Drawing The Player
	glRotatef(player.spin*0.5f,0.0f,0.0f,1.0f);				// Rotate Clockwise
	glColor3f(0.0f,0.75f,0.0f);								// Set Player Color To Dark Green
	glBegin(GL_LINES);										// Start Drawing Our Player Using Lines
		glVertex2d(-7, 0);									// Left Center Of Player
		glVertex2d( 7, 0);									// Right Center Of Player
		glVertex2d( 0,-7);									// Top Center Of Player
		glVertex2d( 0, 7);									// Bottom Center Of Player
	glEnd();												// Done Drawing The Player

	for (loop1=0; loop1<(stage*level); loop1++)				// Loop To Draw Enemies
	{
		glLoadIdentity();									// Reset The Modelview Matrix
		glTranslatef(enemy[loop1].fx+20.0f,enemy[loop1].fy+70.0f,0.0f);
		glColor3f(1.0f,0.5f,0.5f);							// Make Enemy Body Pink
		glBegin(GL_LINES);									// Start Drawing Enemy
			glVertex2d( 0,-7);								// Top Point Of Body
			glVertex2d(-7, 0);								// Left Point Of Body
			glVertex2d(-7, 0);								// Left Point Of Body
			glVertex2d( 0, 7);								// Bottom Point Of Body
			glVertex2d( 0, 7);								// Bottom Point Of Body
			glVertex2d( 7, 0);								// Right Point Of Body
			glVertex2d( 7, 0);								// Right Point Of Body
			glVertex2d( 0,-7);								// Top Point Of Body
		glEnd();											// Done Drawing Enemy Body
		glRotatef(enemy[loop1].spin,0.0f,0.0f,1.0f);		// Rotate The Enemy Blade
		glColor3f(1.0f,0.0f,0.0f);							// Make Enemy Blade Red
		glBegin(GL_LINES);									// Start Drawing Enemy Blade
			glVertex2d(-7,-7);								// Top Left Of Enemy
			glVertex2d( 7, 7);								// Bottom Right Of Enemy
			glVertex2d(-7, 7);								// Bottom Left Of Enemy
			glVertex2d( 7,-7);								// Top Right Of Enemy
		glEnd();											// Done Drawing Enemy Blade
	}
	return 1;											// Everything Went OK

}

int main(int argc, char **argv)
{
  int done;
  float start;

  Uint8 *keys;
  /* Initialize SDL for video output */
  if ( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
    fprintf(stderr, "Unable to initialize SDL: %s\n", SDL_GetError());
    exit(1);
  }
  if ( SDL_Init(SDL_INIT_AUDIO) < 0 ) {
    fprintf(stderr, "Unable to initialize SDL: %s\n", SDL_GetError());
    exit(1);
  }

  #ifdef SOUND
  if (Mix_OpenAudio(22050, AUDIO_S16, 2, 512) < 0)
  {
    fprintf(stderr, "Error: %s\n\n", SDL_GetError());
  }

  complete = load_sound("Data/Complete.wav");                 // Load Sounds
  die = load_sound("Data/Die.wav");
  freeze = load_sound("Data/Freeze.wav");
  hglass = load_sound("Data/Hourglass.wav");
  music = Mix_LoadMUS("Data/lktheme.mod");                    // Load music
  #endif


  /* Create a 640x480 OpenGL screen */
  if ( SDL_SetVideoMode(640, 480, 0, SDL_OPENGL) == NULL ) {
    fprintf(stderr, "Unable to create OpenGL screen: %s\n", SDL_GetError());
    SDL_Quit();
    exit(2);
  }

  /* Set the title bar in environments that support it */
  SDL_WM_SetCaption("Jeff Molofee's GL Code Tutorial ... NeHe '99", NULL);

  /* Loop, drawing and checking events */
  InitGL(640, 480);
  done = 0;

  ResetObjects();
#ifdef SOUND
  Mix_PlayMusic(music,-1);
#endif

  while ( ! done ) {

    start=TimerGetTime();

    keys = SDL_GetKeyState(NULL);
    if((active && !DrawGLScene()) || keys[SDLK_ESCAPE])
      done=1;
    else
      SDL_GL_SwapBuffers();


    while(TimerGetTime()<start+(float)(steps[adjust]*2.0f)) ;


			if (!gameover && active)							// If Game Isn't Over And Programs Active Move Objects
			{
				for (loop1=0; loop1<(stage*level); loop1++)		// Loop Through The Different Stages
				{
					if ((enemy[loop1].x<player.x) && (enemy[loop1].fy==enemy[loop1].y*40))
					{
						enemy[loop1].x++;						// Move The Enemy Right
					}

					if ((enemy[loop1].x>player.x) && (enemy[loop1].fy==enemy[loop1].y*40))
					{
						enemy[loop1].x--;						// Move The Enemy Left
					}

					if ((enemy[loop1].y<player.y) && (enemy[loop1].fx==enemy[loop1].x*60))
					{
						enemy[loop1].y++;						// Move The Enemy Down
					}

					if ((enemy[loop1].y>player.y) && (enemy[loop1].fx==enemy[loop1].x*60))
					{
						enemy[loop1].y--;						// Move The Enemy Up
					}

					if (delay>(3-level) && (hourglass.fx!=2))	// If Our Delay Is Done And Player Doesn't Have Hourglass
					{
						delay=0;								// Reset The Delay Counter Back To Zero
						for (loop2=0; loop2<(stage*level); loop2++)	// Loop Through All The Enemies
						{
							if (enemy[loop2].fx<enemy[loop2].x*60)	// Is Fine Position On X Axis Lower Than Intended Position?
							{
								enemy[loop2].fx+=steps[adjust];	// If So, Increase Fine Position On X Axis
								enemy[loop2].spin+=steps[adjust];	// Spin Enemy Clockwise
							}
							if (enemy[loop2].fx>enemy[loop2].x*60)	// Is Fine Position On X Axis Higher Than Intended Position?
							{
								enemy[loop2].fx-=steps[adjust];	// If So, Decrease Fine Position On X Axis
								enemy[loop2].spin-=steps[adjust];	// Spin Enemy Counter Clockwise
							}
							if (enemy[loop2].fy<enemy[loop2].y*40)	// Is Fine Position On Y Axis Lower Than Intended Position?
							{
								enemy[loop2].fy+=steps[adjust];	// If So, Increase Fine Position On Y Axis
								enemy[loop2].spin+=steps[adjust];	// Spin Enemy Clockwise
							}
							if (enemy[loop2].fy>enemy[loop2].y*40)	// Is Fine Position On Y Axis Higher Than Intended Position?
							{
								enemy[loop2].fy-=steps[adjust];	// If So, Decrease Fine Position On Y Axis
								enemy[loop2].spin-=steps[adjust];	// Spin Enemy Counter Clockwise
							}
						}
					}

					// Are Any Of The Enemies On Top Of The Player?
					if ((enemy[loop1].fx==player.fx) && (enemy[loop1].fy==player.fy))
					{
						lives--;								// If So, Player Loses A Life

						if (lives==0)							// Are We Out Of Lives?
						{
							gameover=1;						// If So, gameover Becomes 1
						}

						ResetObjects();							// Reset Player / Enemy Positions
#ifdef SOUND
                                                Mix_PlayChannel(-1, die, 0);
#endif
                                        }
				}

				if (keys[SDLK_RIGHT] && (player.x<10) && (player.fx==player.x*60) && (player.fy==player.y*40))
				{
					hline[player.x][player.y]=1;				// Mark The Current Horizontal Border As Filled
					player.x++;									// Move The Player Right
				}
				if (keys[SDLK_LEFT] && (player.x>0) && (player.fx==player.x*60) && (player.fy==player.y*40))
				{
					player.x--;									// Move The Player Left
					hline[player.x][player.y]=1;				// Mark The Current Horizontal Border As Filled
				}
				if (keys[SDLK_DOWN] && (player.y<10) && (player.fx==player.x*60) && (player.fy==player.y*40))
				{
					vline[player.x][player.y]=1;				// Mark The Current Verticle Border As Filled
					player.y++;									// Move The Player Down
				}
				if (keys[SDLK_UP] && (player.y>0) && (player.fx==player.x*60) && (player.fy==player.y*40))
				{
					player.y--;									// Move The Player Up
					vline[player.x][player.y]=1;				// Mark The Current Verticle Border As Filled
				}

				if (player.fx<player.x*60)						// Is Fine Position On X Axis Lower Than Intended Position?
				{
					player.fx+=steps[adjust];					// If So, Increase The Fine X Position
				}
				if (player.fx>player.x*60)						// Is Fine Position On X Axis Greater Than Intended Position?
				{
					player.fx-=steps[adjust];					// If So, Decrease The Fine X Position
				}
				if (player.fy<player.y*40)						// Is Fine Position On Y Axis Lower Than Intended Position?
				{
					player.fy+=steps[adjust];					// If So, Increase The Fine Y Position
				}
				if (player.fy>player.y*40)						// Is Fine Position On Y Axis Lower Than Intended Position?
				{
					player.fy-=steps[adjust];					// If So, Decrease The Fine Y Position
				}
			}
			else												// Otherwise
			{
				if (keys[' '])									// If Spacebar Is Being Pressed
				{
					gameover=0;								// gameover Becomes 0
					filled=1;								// filled Becomes 1
					level=1;									// Starting Level Is Set Back To One
					level2=1;									// Displayed Level Is Also Set To One
					stage=0;									// Game Stage Is Set To Zero
					lives=5;									// Lives Is Set To Five
				}
			}

			if (filled)											// Is The Grid Filled In?
			{
#ifdef SOUND
                                Mix_PlayChannel(-1, complete, 0);
#endif
                                stage++;										// Increase The Stage
				if (stage>3)									// Is The Stage Higher Than 3?
				{
					stage=1;									// If So, Set The Stage To One
					level++;									// Increase The Level
					level2++;									// Increase The Displayed Level
					if (level>3)								// Is The Level Greater Than 3?
					{
						level=3;								// If So, Set The Level To 3
						lives++;								// Give The Player A Free Life
						if (lives>5)							// Does The Player Have More Than 5 Lives?
						{
							lives=5;							// If So, Set Lives To Five
						}
					}
				}

				ResetObjects();									// Reset Player / Enemy Positions

				for (loop1=0; loop1<11; loop1++)				// Loop Through The Grid X Coordinates
				{
					for (loop2=0; loop2<11; loop2++)			// Loop Through The Grid Y Coordinates
					{
						if (loop1<10)							// If X Coordinate Is Less Than 10
						{
							hline[loop1][loop2]=0;			// Set The Current Horizontal Value To 0
						}
						if (loop2<10)							// If Y Coordinate Is Less Than 10
						{
							vline[loop1][loop2]=0;			// Set The Current Vertical Value To 0
						}
					}
				}
			}

			// If The Player Hits The Hourglass While It's Being Displayed On The Screen
			if ((player.fx==hourglass.x*60) && (player.fy==hourglass.y*40) && (hourglass.fx==1))
			{
				// Play Freeze Enemy Sound
#ifdef SOUND
                                Mix_PlayChannel(-1, freeze, 0);
#endif
                                hourglass.fx=2;									// Set The hourglass fx Variable To Two
				hourglass.fy=0;									// Set The hourglass fy Variable To Zero
			}

			player.spin+=0.5f*steps[adjust];					// Spin The Player Clockwise
			if (player.spin>360.0f)								// Is The spin Value Greater Than 360?
			{
				player.spin-=360;								// If So, Subtract 360
			}

			hourglass.spin-=0.25f*steps[adjust];				// Spin The Hourglass Counter Clockwise
			if (hourglass.spin<0.0f)							// Is The spin Value Less Than 0?
			{
				hourglass.spin+=360.0f;							// If So, Add 360
			}

			hourglass.fy+=steps[adjust];						// Increase The hourglass fy Variable
			if ((hourglass.fx==0) && (hourglass.fy>6000/level))	// Is The hourglass fx Variable Equal To 0 And The fy
			{													// Variable Greater Than 6000 Divided By The Current Level?
#ifdef SOUND

                                Mix_PlayChannel(-1, hglass, 0);
#endif
                                hourglass.x=rand()%10+1;						// Give The Hourglass A Random X Value
				hourglass.y=rand()%11;							// Give The Hourglass A Random Y Value
				hourglass.fx=1;									// Set hourglass fx Variable To One (Hourglass Stage)
				hourglass.fy=0;									// Set hourglass fy Variable To Zero (Counter)
			}

			if ((hourglass.fx==1) && (hourglass.fy>6000/level))	// Is The hourglass fx Variable Equal To 1 And The fy
			{													// Variable Greater Than 6000 Divided By The Current Level?
				hourglass.fx=0;									// If So, Set fx To Zero (Hourglass Will Vanish)
				hourglass.fy=0;									// Set fy to Zero (Counter Is Reset)
			}

			if ((hourglass.fx==2) && (hourglass.fy>500+(500*level)))	// Is The hourglass fx Variable Equal To 2 And The fy
			{													// Variable Greater Than 500 Plus 500 Times The Current Level?
				//PlaySound(NULL, NULL, 0);						// If So, Kill The Freeze Sound
				hourglass.fx=0;									// Set hourglass fx Variable To Zero
				hourglass.fy=0;									// Set hourglass fy Variable To Zero
			}

			delay++;											// Increase The Enemy Delay Counter



    /* This could go in a separate function */
    { SDL_Event event;
      while ( SDL_PollEvent(&event) ) {
        if ( event.type == SDL_QUIT ) {
#ifdef SOUND
            Mix_HaltChannel(-1);
            Mix_CloseAudio();
#endif
          done = 1;
        }
        if ( event.type == SDL_KEYDOWN ) {
          if ( event.key.keysym.sym == SDLK_ESCAPE ) {
#ifdef SOUND

            Mix_HaltChannel(-1);
            Mix_CloseAudio();
#endif
            done = 1;
          }
          if ( event.key.keysym.sym == SDLK_a ) {
            anti = !anti;
          }
        }
      }
    }
  }
  SDL_Quit();
  return 1;
}
