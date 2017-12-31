/*
 NeHe (nehe.gamedev.net) OpenGL tutorial series
 GLUT port.in 2001 by milix (milix_gr@hotmail.com)
 Most comments are from the original tutorials found in NeHe.
 For VC++ users, create a Win32 Console project and link 
 the program with glut32.lib, glu32.lib, opengl32.lib
*/

#include <stdio.h>           // Standard C/C++ Input-Output
#include <windows.h>         // Standard Header For MSWindows Applications
#include <gl/glut.h>         // The GL Utility Toolkit (GLUT) Header

// The Following Directive Fixes The Problem With Extra Console Window
#pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")

#define WCX          640     // Window Width
#define WCY          480     // Window Height 
#define TEXTURES_NUM 2       // We Have 3 Textures (CHANGED)

// A Structure For RGB Bitmaps
typedef struct _RGBIMG {
	GLuint   w;    // Image's Width
	GLuint   h;    // Image's Height
	GLubyte* data; // Image's Data (Pixels)
} RGBIMG;

// Global Variables
bool    g_gamemode;            // GLUT GameMode ON/OFF
bool    g_fullscreen;          // Fullscreen Mode ON/OFF (When g_gamemode Is OFF)
GLuint	g_base;				   // Base Display List For The Font
GLuint	g_texid[TEXTURES_NUM]; // Storage For Our Font Texture
GLfloat	g_cnt1;				   // 1st Counter Used To Move Text & For Coloring
GLfloat	g_cnt2;				   // 2nd Counter Used To Move Text & For Coloring

// Loads A RGB Raw Image From A Disk File And Updates Our Image Reference
// Returns true On Success, False On Fail.
bool load_rgb_image(const char* file_name, int w, int h, RGBIMG* refimg)
{
	GLuint   sz;    // Our Image's Data Field Length In Bytes
	FILE*    file;  // The Image's File On Disk
	long     fsize; // File Size In Bytes
	GLubyte* p;     // Helper Pointer

	// Update The Image's Fields
	refimg->w = (GLuint) w;
	refimg->h = (GLuint) h;
	sz = (((3*refimg->w+3)>>2)<<2)*refimg->h;
	refimg->data = new GLubyte [sz];
	if (refimg->data == NULL) return false;

	// Open The File And Read The Pixels
	file = fopen(file_name , "rb");
	if (!file) return false;
	fseek(file, 0L, SEEK_END);
	fsize = ftell(file);
	if (fsize != (long)sz) {
		fclose(file);
		return false;
	}
	fseek(file, 0L, SEEK_SET);
	p = refimg->data;
	while (fsize > 0) {
		fread(p, 1, 1, file);
		p++;
		fsize--;
	}
	fclose(file); 
	return true;
}

// Setup Our Textures. Returns true On Success, false On Fail
bool setup_textures(void)
{
	RGBIMG img;

    // Create The Textures' Id List
	glGenTextures(TEXTURES_NUM, g_texid);          

	// Load The Image From A Disk File
	if (!load_rgb_image("font_256x256.raw", 256, 256, &img)) return false;
	// Create Nearest Filtered Texture
	glBindTexture(GL_TEXTURE_2D, g_texid[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, img.w, img.h, 0, GL_RGB, GL_UNSIGNED_BYTE, img.data);
	// Finished With Our Image, Free The Allocated Data
	delete img.data;

	// Load The Image From A Disk File
	if (!load_rgb_image("bumps_128x128.raw", 128, 128, &img)) return false;
	// Create Nearest Filtered Texture
	glBindTexture(GL_TEXTURE_2D, g_texid[1]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, img.w, img.h, 0, GL_RGB, GL_UNSIGNED_BYTE, img.data);
	// Finished With Our Image, Free The Allocated Data
	delete img.data;

	return true;
}

// Build Our Font Display List (NEW)
void build_font(void)								
{
	int i;
	float cx;											// Holds Our X Character Coord
	float cy;											// Holds Our Y Character Coord

	g_base = glGenLists(256);							// Creating 256 Display Lists
	glBindTexture(GL_TEXTURE_2D, g_texid[0]);			// Select Our Font Texture
	for (i=0 ; i<256 ; i++) {                           // Loop Through All 256 Lists
		cx = float(i%16)/16.0f;							// X Position Of Current Character
		cy = float(i/16)/16.0f;							// Y Position Of Current Character
		glNewList(g_base+i,GL_COMPILE);					// Start Building A List
			glBegin(GL_QUADS);							// Use A Quad For Each Character
				glTexCoord2f(cx,1-cy-0.0625f);			// Texture Coord (Bottom Left)
				glVertex2i(0,0);						// Vertex Coord (Bottom Left)
				glTexCoord2f(cx+0.0625f,1-cy-0.0625f);	// Texture Coord (Bottom Right)
				glVertex2i(16,0);						// Vertex Coord (Bottom Right)
				glTexCoord2f(cx+0.0625f,1-cy);			// Texture Coord (Top Right)
				glVertex2i(16,16);						// Vertex Coord (Top Right)
				glTexCoord2f(cx,1-cy);					// Texture Coord (Top Left)
				glVertex2i(0,16);						// Vertex Coord (Top Left)
			glEnd();									// Done Building Our Quad (Character)
			glTranslated(10,0,0);						// Move To The Right Of The Character
		glEndList();									// Done Building The Display List
	}													// Loop Until All 256 Are Built
}

// Delete The Font From Memory (NEW)
void kill_font(void)									
{
	glDeleteLists(g_base, 256);							// Delete All 256 Display Lists
}

// Where The Printing Happens (NEW)
void glPrint(GLint x, GLint y, char* string, int set)	
{
	if (set > 1) set = 1;
	glBindTexture(GL_TEXTURE_2D, g_texid[0]);			// Select Our Font Texture
	glDisable(GL_DEPTH_TEST);							// Disables Depth Testing
	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glPushMatrix();										// Store The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix
	glOrtho(0,640,0,480,-100,100);						// Set Up An Ortho Screen
	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glPushMatrix();										// Store The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
	glTranslated(x,y,0);								// Position The Text (0,0 - Bottom Left)
	glListBase(g_base-32+(128*set));					// Choose The Font Set (0 or 1)
	glCallLists(strlen(string),GL_BYTE,string);			// Write The Text To The Screen
	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glPopMatrix();										// Restore The Old Projection Matrix
	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glPopMatrix();										// Restore The Old Projection Matrix
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
}

// Our GL Specific Initializations. Returns true On Success, false On Fail.
bool init(void)
{
	if (!setup_textures()) return false;
	build_font();
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);				// Clear The Background Color To Black
	glClearDepth(1.0);									// Enables Clearing Of The Depth Buffer
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Test To Do
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Select The Type Of Blending
	glShadeModel(GL_SMOOTH);							// Enables Smooth Color Shading
	glEnable(GL_TEXTURE_2D);							// Enable 2D Texture Mapping
	return true;
}

// Our Rendering Is Done Here
void render(void)   
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The Modelview Matrix
	glBindTexture(GL_TEXTURE_2D, g_texid[1]);			// Select Our Second Texture
	glTranslatef(0.0f,0.0f,-5.0f);						// Move Into The Screen 5 Units
	glRotatef(45.0f,0.0f,0.0f,1.0f);					// Rotate On The Z Axis 45 Degrees (Clockwise)
	glRotatef(g_cnt1*30.0f,1.0f,1.0f,0.0f);				// Rotate On The X & Y Axis By cnt1 (Left To Right)
	glDisable(GL_BLEND);								// Disable Blending Before We Draw In 3D
	glColor3f(1.0f,1.0f,1.0f);							// Bright White
	glBegin(GL_QUADS);									// Draw Our First Texture Mapped Quad
		glTexCoord2d(0.0f,0.0f);						// First Texture Coord
		glVertex2f(-1.0f, 1.0f);						// First Vertex
		glTexCoord2d(1.0f,0.0f);						// Second Texture Coord
		glVertex2f( 1.0f, 1.0f);						// Second Vertex
		glTexCoord2d(1.0f,1.0f);						// Third Texture Coord
		glVertex2f( 1.0f,-1.0f);						// Third Vertex
		glTexCoord2d(0.0f,1.0f);						// Fourth Texture Coord
		glVertex2f(-1.0f,-1.0f);						// Fourth Vertex
	glEnd();											// Done Drawing The First Quad
	glRotatef(90.0f,1.0f,1.0f,0.0f);					// Rotate On The X & Y Axis By 90 Degrees (Left To Right)
	glBegin(GL_QUADS);									// Draw Our Second Texture Mapped Quad
		glTexCoord2d(0.0f,0.0f);						// First Texture Coord
		glVertex2f(-1.0f, 1.0f);						// First Vertex
		glTexCoord2d(1.0f,0.0f);						// Second Texture Coord
		glVertex2f( 1.0f, 1.0f);						// Second Vertex
		glTexCoord2d(1.0f,1.0f);						// Third Texture Coord
		glVertex2f( 1.0f,-1.0f);						// Third Vertex
		glTexCoord2d(0.0f,1.0f);						// Fourth Texture Coord
		glVertex2f(-1.0f,-1.0f);						// Fourth Vertex
	glEnd();											// Done Drawing Our Second Quad
	glEnable(GL_BLEND);									// Enable Blending

	glLoadIdentity();									// Reset The View
	// Pulsing Colors Based On Text Position
	glColor3f(1.0f*float(cos(g_cnt1)),1.0f*float(sin(g_cnt2)),1.0f-0.5f*float(cos(g_cnt1+g_cnt2)));
	glPrint(int((280+250*cos(g_cnt1))),int(235+200*sin(g_cnt2)),"NeHe",0);   // Print GL Text To The Screen

	glColor3f(1.0f*float(sin(g_cnt2)),1.0f-0.5f*float(cos(g_cnt1+g_cnt2)),1.0f*float(cos(g_cnt1)));
	glPrint(int((280+230*cos(g_cnt2))),int(235+200*sin(g_cnt1)),"OpenGL",1); // Print GL Text To The Screen

	glColor3f(0.0f,0.0f,1.0f);
	glPrint(int(240+200*cos((g_cnt2+g_cnt1)/5)),2,"Giuseppe D'Agata",0);

	glColor3f(1.0f,1.0f,1.0f);
	glPrint(int(242+200*cos((g_cnt2+g_cnt1)/5)),2,"Giuseppe D'Agata",0);

	g_cnt1 += 0.01f;									// Increase The Counters
	g_cnt2 += 0.0081f;	
	
    // Swap The Buffers To Become Our Rendering Visible
    glutSwapBuffers ( );
}

// Our Reshaping Handler (Required Even In Fullscreen-Only Modes)
void reshape(int w, int h)
{
	glViewport(0, 0, w, h);
	glMatrixMode(GL_PROJECTION);     // Select The Projection Matrix
	glLoadIdentity();                // Reset The Projection Matrix
	// Calculate The Aspect Ratio And Set The Clipping Volume
	if (h == 0) h = 1;
	gluPerspective(45, (float)w/(float)h, 0.1, 100.0);
	glMatrixMode(GL_MODELVIEW);      // Select The Modelview Matrix
	glLoadIdentity(); // Reset The Modelview Matrix
}


// Our Keyboard Handler (Normal Keys)
void keyboard(unsigned char key, int x, int y)
{
	switch (key) {
		case 27:         
			kill_font(); // (NEW)
			exit(0);     
		break;           
		default:
		break;
	}
}

// Our Keyboard Handler For Special Keys (Like Arrow Keys And Function Keys)
void special_keys(int a_keys, int x, int y)
{
	switch (a_keys) {
		case GLUT_KEY_F1:
			// We Can Switch Between Windowed Mode And Fullscreen Mode Only
			if (!g_gamemode) {
				g_fullscreen = !g_fullscreen;       // Toggle g_fullscreen Flag
				if (g_fullscreen) glutFullScreen(); // We Went In Fullscreen Mode
				else glutReshapeWindow(WCX, WCY);   // We Went In Windowed Mode
			}
		break;
		default:
		break;
	}
}

// Ask The User If He Wish To Enter GameMode Or Not
void ask_gamemode()
{
	int answer;
	// Use Windows MessageBox To Ask The User For Game Or Windowed Mode
	answer = MessageBox(NULL, "Do you want to enter game mode?", "Question",
						MB_ICONQUESTION | MB_YESNO);
	g_gamemode = (answer == IDYES);
	// If Not Game Mode Selected, Use Windowed Mode (User Can Change That With F1)
	g_fullscreen = false; 
}

// Main Function For Bringing It All Together.
int main(int argc, char** argv)
{
	ask_gamemode();                                  // Ask For Fullscreen Mode
	glutInit(&argc, argv);                           // GLUT Initializtion
	glutInitDisplayMode(GLUT_DEPTH | GLUT_RGB | GLUT_DOUBLE); 
	if (g_gamemode) {
		glutGameModeString("640x480:16");            // Select The 640x480 In 16bpp Mode
		if (glutGameModeGet(GLUT_GAME_MODE_POSSIBLE))
			glutEnterGameMode();                     // Enter Full Screen
		else g_gamemode = false;                     // Cannot Enter Game Mode, Switch To Windowed
	}
	if (!g_gamemode) {
		glutInitWindowSize(WCX, WCY);                // Window Size If We Start In Windowed Mode
		glutCreateWindow("NeHe's OpenGL Framework"); // Window Title 
	}
	if (!init()) {                                   // Our Initialization
		MessageBox(NULL,"Cannot initialize textures.","Error",MB_ICONSTOP);
		return -1;
	}
	glutDisplayFunc(render);                         // Register The Display Function
	glutReshapeFunc(reshape);                        // Register The Reshape Handler
	glutKeyboardFunc(keyboard);                      // Register The Keyboard Handler
	glutSpecialFunc(special_keys);                   // Register Special Keys Handler
	glutIdleFunc(render);                            // We Render In Idle Time
	glutMainLoop();                                  // Go To GLUT Main Loop
	return 0;
}
