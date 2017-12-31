/*
 NeHe (nehe.gamedev.net) OpenGL tutorial series
 GLUT port.in 2001 by milix (milix_gr@hotmail.com)
 Most comments are from the original tutorials found in NeHe.
 For VC++ users, create a Win32 Console project and link 
 the program with glut32.lib, glu32.lib, opengl32.lib
*/

#include <stdio.h>           // Standard C/C++ Input-Output 
#include <stdlib.h>          // Standard C/C++ Library (NEW)
#include <windows.h>         // Standard Header For MSWindows Applications
#include <gl/glut.h>         // The GL Utility Toolkit (GLUT) Header

// The Following Directive Fixes The Problem With Extra Console Window
#pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")

#define TEXTURES_NUM 1       // We Have 1 Texture (CHANGED)
#define STARSNUM     50      // Number Of Stars To Draw (NEW)

// A Structure For RGB Bitmaps
typedef struct _RGBIMG {
	GLuint   w;    // Image's Width
	GLuint   h;    // Image's Height
	GLubyte* data; // Image's Data (Pixels)
} RGBIMG;

// Create A Structure For Star
typedef struct {
	int r, g, b;   // Stars Color
	GLfloat dist,  // Stars Distance From Center
			angle; // Stars Current Angle
} stars;

// Global Variables
bool    g_gamemode;            // GLUT GameMode ON/OFF
bool    g_fullscreen;          // Fullscreen Mode ON/OFF (When g_gamemode Is OFF)
bool	g_twinkle = false;     // Twinkling Starsbool	
stars   g_star[STARSNUM];      // Need To Keep Track Of 'num' Stars
GLfloat	g_zoom = -15.0f;       // Distance Away From Stars
GLfloat g_tilt = 90.0f;        // Tilt The View
GLfloat	g_spin = 0.0f;		   // Spin Stars
GLuint	g_texid[TEXTURES_NUM]; // Our Textures' Id List 

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
bool setup_textures()
{
	RGBIMG img;

    // Create The Textures' Id List
	glGenTextures(TEXTURES_NUM, g_texid);          
	// Load The Image From A Disk File
	if (!load_rgb_image("star_128x128.raw", 128, 128, &img)) return false;
	// Create Nearest Filtered Texture
	glBindTexture(GL_TEXTURE_2D, g_texid[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, img.w, img.h, 0, GL_RGB, GL_UNSIGNED_BYTE, img.data);
	// Finished With Our Image, Free The Allocated Data
	delete img.data;
	return true;
}

// Our GL Specific Initializations. Returns true On Success, false On Fail.
bool init(void)
{
	int i;

	if (!setup_textures()) return false;
	glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Set The Blending Function For Translucency
	glEnable(GL_BLEND);
	for (i = 0 ; i < STARSNUM ; i++) {
		g_star[i].angle = 0.0f;
		g_star[i].dist = (float(i)/STARSNUM)*5.0f;
		g_star[i].r = rand()%256;
		g_star[i].g = rand()%256;
		g_star[i].b = rand()%256;
	}

	return true;
}

// Our Rendering Is Done Here
void render(void)   
{
	int i;

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glBindTexture(GL_TEXTURE_2D, g_texid[0]);			// Select Our Texture

	for (i=0; i<STARSNUM; i++)					        // Loop Through All The Stars
	{
		glLoadIdentity();								// Reset The View Before We Draw Each Star
		glTranslatef(0.0f,0.0f,g_zoom);					// Zoom Into The Screen (Using The Value In 'zoom')
		glRotatef(g_tilt,1.0f,0.0f,0.0f);				// Tilt The View (Using The Value In 'tilt')
		glRotatef(g_star[i].angle,0.0f,1.0f,0.0f);		// Rotate To The Current Stars Angle
		glTranslatef(g_star[i].dist,0.0f,0.0f);		    // Move Forward On The X Plane
		glRotatef(-g_star[i].angle,0.0f,1.0f,0.0f);	    // Cancel The Current Stars Angle
		glRotatef(-g_tilt,1.0f,0.0f,0.0f);				// Cancel The Screen Tilt
		
		if (g_twinkle)
		{
			glColor4ub(g_star[(STARSNUM-i)-1].r,g_star[(STARSNUM-i)-1].g,g_star[(STARSNUM-i)-1].b,255);
			glBegin(GL_QUADS);
				glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);
				glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,-1.0f, 0.0f);
				glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);
				glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f, 1.0f, 0.0f);
			glEnd();
		}

		glRotatef(g_spin,0.0f,0.0f,1.0f);
		glColor4ub(g_star[i].r,g_star[i].g,g_star[i].b,255);
		glBegin(GL_QUADS);
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,-1.0f, 0.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f, 1.0f, 0.0f);
		glEnd();

		g_spin += 0.01f;
		g_star[i].angle += float(i)/STARSNUM;
		g_star[i].dist -= 0.01f;
		if (g_star[i].dist < 0.0f)
		{
			g_star[i].dist += 5.0f;
			g_star[i].r = rand()%256;
			g_star[i].g = rand()%256;
			g_star[i].b = rand()%256;
		}
	}
    // Swap The Buffers To Become Our Rendering Visible
    glutSwapBuffers( );
}

// Our Reshaping Handler (Required Even In Fullscreen-Only Modes)
void reshape(int w, int h)
{
	glViewport(0, 0, w, h);
	glMatrixMode(GL_PROJECTION);     // Select The Projection Matrix
	glLoadIdentity();                // Reset The Projection Matrix
	// Calculate The Aspect Ratio And Set The Clipping Volume
	if (h == 0) h = 1;
	gluPerspective(80.0f,(float)w/(float)h,1.0f,5000.0f);
	glMatrixMode(GL_MODELVIEW);      // Select The Modelview Matrix
	glLoadIdentity(); // Reset The Modelview Matrix
}


// Our Keyboard Handler (Normal Keys)
void keyboard(unsigned char key, int x, int y)
{
	switch (key) {
		case 27:        // When Escape Is Pressed...
			exit(0);    // Exit The Program
		break;          // Ready For Next Case
		case 'T': case 't':
			g_twinkle = !g_twinkle;
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
				else glutReshapeWindow(500, 500);   // We Went In Windowed Mode
			}
		break;
		case GLUT_KEY_PAGE_UP:
			g_zoom -= 0.2f;
		break;
		case GLUT_KEY_PAGE_DOWN:
			g_zoom += 0.2f;
		break;
		case GLUT_KEY_UP:
			g_tilt -= 0.5f;
		break;
		case GLUT_KEY_DOWN:
			g_tilt += 0.5f;
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
	glutInitDisplayMode(GLUT_DEPTH | GLUT_RGBA | GLUT_DOUBLE);
	if (g_gamemode) {
		glutGameModeString("640x480:16");            // Select The 640x480 In 16bpp Mode
		if (glutGameModeGet(GLUT_GAME_MODE_POSSIBLE))
			glutEnterGameMode();                     // Enter Full Screen
		else g_gamemode = false;                     // Cannot Enter Game Mode, Switch To Windowed
	}
	if (!g_gamemode) {
		glutInitWindowSize(500, 500);                // Window Size If We Start In Windowed Mode
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
