/*
 NeHe (nehe.gamedev.net) OpenGL tutorial series
 GLUT port.in 2001 by milix (milix_gr@hotmail.com)
 Most comments are from the original tutorials found in NeHe.
 For VC++ users, create a Win32 Console project and link 
 the program with glut32.lib, glu32.lib, opengl32.lib
*/

#include <stdio.h>           // Standard C/C++ Input-Output
#include <math.h>            // Math Functions (NEW)
#include <windows.h>         // Standard Header For MSWindows Applications
#include <gl/glut.h>         // The GL Utility Toolkit (GLUT) Header

// The Following Directive Fixes The Problem With Extra Console Window
#pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")

#define TEXTURES_NUM 3       // We Have 3 Textures 
#define PI_OVER_180  0.0174532925f

// A Structure For RGB Bitmaps
typedef struct _RGBIMG {
	GLuint   w;    // Image's Width
	GLuint   h;    // Image's Height
	GLubyte* data; // Image's Data (Pixels)
} RGBIMG;

typedef struct _VERTEX {
	float x, y, z;
	float u, v;
} VERTEX;

typedef struct _TRIANGLE {
	VERTEX vertex[3];
} TRIANGLE;

typedef struct _SECTOR {
	int numtriangles;
	TRIANGLE* triangle;
} SECTOR;

// Global Variables
bool    g_gamemode;             // GLUT GameMode ON/OFF
bool    g_fullscreen;           // Fullscreen Mode ON/OFF (When g_gamemode Is OFF)
bool    g_blend = false;        // Blending ON/OFF
GLfloat g_xpos = 0.0f;          // Position In X-Axis 
GLfloat g_zpos = 0.0f;          // Position In Z-Axis 
GLfloat	g_yrot = 0.0f;          // Y Rotation 
GLfloat g_xspeed = 0.0f;	    // X Rotation Speed
GLfloat g_yspeed = 0.0f;	    // Y Rotation Speed
GLfloat	g_z = 0.0f;	            // Depth Into The Screen 
GLfloat g_heading = 0.0f;
GLfloat g_walkbias = 0.0f;      // Gives The Illusion That We Are Walking (NEW) 
GLfloat g_walkbiasangle = 0.0f; // Gives The Illusion That We Are Walking (NEW) 
GLfloat g_lookupdown = 0.0f;    // Look Position In The Z-Axis (NEW) 
GLuint	g_filter;			    // Which Filter To Use 
GLuint	g_texid[TEXTURES_NUM];  // Our Textures' Id List 
SECTOR  g_sector1;              // Our Model Goes Here:
bool    g_key[255];             // Lookup Table For Key's State (NEW)


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

void readstr(FILE* f, char* string)
{
	do {
		fgets(string, 255, f);
	} while ((string[0] == '/') || (string[0] == '\n'));
}

void setupWorld()
{
	float x, y, z, u, v;
	int numtriangles;
	FILE *filein;
	char oneline[255];
	filein = fopen("world.txt", "rt"); // File To Load World Data From

	readstr(filein, oneline);
	sscanf(oneline, "NUMPOLLIES %d\n", &numtriangles);
	g_sector1.triangle = new TRIANGLE[numtriangles];
	g_sector1.numtriangles = numtriangles;
	for (int loop = 0; loop < numtriangles; loop++) {
		for (int vert = 0; vert < 3; vert++) {
			readstr(filein, oneline);
			sscanf(oneline, "%f %f %f %f %f %f %f", &x, &y, &z, &u, &v);
			g_sector1.triangle[loop].vertex[vert].x = x;
			g_sector1.triangle[loop].vertex[vert].y = y;
			g_sector1.triangle[loop].vertex[vert].z = z;
			g_sector1.triangle[loop].vertex[vert].u = u;
			g_sector1.triangle[loop].vertex[vert].v = v;
		}
	}
	fclose(filein);
	return;
}

// Setup Our Textures. Returns true On Success, false On Fail
bool setup_textures()
{
	RGBIMG img;

    // Create The Textures' Id List
	glGenTextures(TEXTURES_NUM, g_texid);          
	// Load The Image From A Disk File
	if (!load_rgb_image("mud_256x256.raw", 256, 256, &img)) return false;
	// Create Nearest Filtered Texture
	glBindTexture(GL_TEXTURE_2D, g_texid[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, img.w, img.h, 0, GL_RGB, GL_UNSIGNED_BYTE, img.data);
	// Create Linear Filtered Texture
	glBindTexture(GL_TEXTURE_2D, g_texid[1]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, img.w, img.h, 0, GL_RGB, GL_UNSIGNED_BYTE, img.data);
	// Create MipMapped Texture
	glBindTexture(GL_TEXTURE_2D, g_texid[2]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
	gluBuild2DMipmaps(GL_TEXTURE_2D, 3, img.w, img.h, GL_RGB, GL_UNSIGNED_BYTE, img.data);
	// Finished With Our Image, Free The Allocated Data
	delete img.data;
	return true;
}

// Our GL Specific Initializations. Returns true On Success, false On Fail.
bool init(void)
{
	if (!setup_textures()) return false;
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);             // Pixel Storage Mode To Byte Alignment
	glEnable(GL_TEXTURE_2D);                           // Enable Texture Mapping 
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);                 // Set The Blending Function (NEW)
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);			   // Black Background (CHANGED)
    glClearDepth(1.0f);								   // Depth Buffer Setup
    glDepthFunc(GL_LESS);							   // The Type Of Depth Testing To Do
    glEnable(GL_DEPTH_TEST);						   // Enables Depth Testing
    glShadeModel(GL_SMOOTH);						   // Enable Smooth Shading
    ShowCursor(FALSE);                                 // WiN API - Hides The Mouse Pointer (NEW)
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	setupWorld();
	memset(g_key, 0, sizeof(g_key));

	return true;
}

// Our Rendering Is Done Here
void render(void)   
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The View

	GLfloat x_m, y_m, z_m, u_m, v_m;
	GLfloat xtrans = -g_xpos;
	GLfloat ztrans = -g_zpos;
	GLfloat ytrans = -g_walkbias - 0.25f;
	GLfloat sceneroty = 360.0f - g_yrot;

	int numtriangles;

	glRotatef(g_lookupdown,1.0f,0,0);
	glRotatef(sceneroty,0,1.0f,0);
	
	glTranslatef(xtrans, ytrans, ztrans);
	glBindTexture(GL_TEXTURE_2D, g_texid[g_filter]);
	
	numtriangles = g_sector1.numtriangles;
	
	// Process Each Triangle
	for (int loop_m = 0; loop_m < numtriangles; loop_m++)
	{
		glBegin(GL_TRIANGLES);
			glNormal3f( 0.0f, 0.0f, 1.0f);
			x_m = g_sector1.triangle[loop_m].vertex[0].x;
			y_m = g_sector1.triangle[loop_m].vertex[0].y;
			z_m = g_sector1.triangle[loop_m].vertex[0].z;
			u_m = g_sector1.triangle[loop_m].vertex[0].u;
			v_m = g_sector1.triangle[loop_m].vertex[0].v;
			glTexCoord2f(u_m,v_m); glVertex3f(x_m,y_m,z_m);
			
			x_m = g_sector1.triangle[loop_m].vertex[1].x;
			y_m = g_sector1.triangle[loop_m].vertex[1].y;
			z_m = g_sector1.triangle[loop_m].vertex[1].z;
			u_m = g_sector1.triangle[loop_m].vertex[1].u;
			v_m = g_sector1.triangle[loop_m].vertex[1].v;
			glTexCoord2f(u_m,v_m); glVertex3f(x_m,y_m,z_m);
			
			x_m = g_sector1.triangle[loop_m].vertex[2].x;
			y_m = g_sector1.triangle[loop_m].vertex[2].y;
			z_m = g_sector1.triangle[loop_m].vertex[2].z;
			u_m = g_sector1.triangle[loop_m].vertex[2].u;
			v_m = g_sector1.triangle[loop_m].vertex[2].v;
			glTexCoord2f(u_m,v_m); glVertex3f(x_m,y_m,z_m);
		glEnd();
	}

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
	gluPerspective(45.0f, (float)w/(float)h, 0.1, 100.0);
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
		case 'F': case 'f':
			g_filter += 1;
			if (g_filter > 2) g_filter = 0;
		break;
        case 'B': case 'b':
			g_blend = !g_blend;
			if (g_blend) {
				glEnable(GL_BLEND);			// Turn Blending On (NEW)
				glDisable(GL_DEPTH_TEST);	// Turn Depth Testing Off (NEW)
			} else {
				glDisable(GL_BLEND);		// Turn Blending Off (NEW)
				glEnable(GL_DEPTH_TEST);	// Turn Depth Testing On (NEW)
			}
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
		default:
			g_key[a_keys] = true;
		break;
	}
}

// Our Keyboard Handler For Special Key Releases.
void special_keys_up(int key, int x, int y)
{
	g_key[key] = false;
}

// Our Game Function. Check The User Input And Performs The Rendering
void game_function()
{
	// Process User Input
	if (g_key[GLUT_KEY_PAGE_UP]) {
		g_z -= 0.02f;
		g_lookupdown -= 1.0f;
	}
	if (g_key[GLUT_KEY_PAGE_DOWN]) {
		g_z += 0.02f;
		g_lookupdown += 1.0f;
	}
	if (g_key[GLUT_KEY_UP]) {
		g_xpos -= (float)sin(g_heading*PI_OVER_180) * 0.05f;
		g_zpos -= (float)cos(g_heading*PI_OVER_180) * 0.05f;
		if (g_walkbiasangle >= 359.0f) g_walkbiasangle = 0.0f;
		else g_walkbiasangle += 10;
		g_walkbias = (float)sin(g_walkbiasangle*PI_OVER_180) / 20.0f;
	}
	if (g_key[GLUT_KEY_DOWN]) {
		g_xpos += (float)sin(g_heading*PI_OVER_180) * 0.05f;
		g_zpos += (float)cos(g_heading*PI_OVER_180) * 0.05f;
		if (g_walkbiasangle <= 1.0f) g_walkbiasangle = 359.0f;
		else g_walkbiasangle -= 10;
		g_walkbias = (float)sin(g_walkbiasangle*PI_OVER_180) / 20.0f;
	}
	if (g_key[GLUT_KEY_RIGHT]) {
		g_heading -= 1.0f;
		g_yrot = g_heading;
	}
	if (g_key[GLUT_KEY_LEFT]) {
		g_heading += 1.0f;
		g_yrot = g_heading;
	}

	// Do The Rendering
	render();
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
	glutInitDisplayMode(GLUT_DEPTH | GLUT_RGBA | GLUT_DOUBLE); // (CHANGED)
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
	glutIgnoreKeyRepeat(true);                       // Disable Auto Repeat (NEW)
	glutDisplayFunc(render);                         // Register The Display Function
	glutReshapeFunc(reshape);                        // Register The Reshape Handler
	glutKeyboardFunc(keyboard);                      // Register The Keyboard Handler
	glutSpecialFunc(special_keys);                   // Register Special Keys Handler
	glutSpecialUpFunc(special_keys_up);              // Called When A Special Key Released (NEW)
	glutIdleFunc(game_function);                     // Process User Input And Does Rendering (CHANGED)
	glutMainLoop();                                  // Go To GLUT Main Loop
	return 0;
}
