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
#define TEXTURES_NUM 3       // We Have 3 Textures 

// A Structure For RGB Bitmaps
typedef struct _RGBIMG {
	GLuint   w;    // Image's Width
	GLuint   h;    // Image's Height
	GLubyte* data; // Image's Data (Pixels)
} RGBIMG;

// Global Variables
bool    g_gamemode;            // GLUT GameMode ON/OFF
bool    g_fullscreen;          // Fullscreen Mode ON/OFF (When g_gamemode Is OFF)
bool	g_light = false;	   // Lighting ON/OFF 
GLfloat	g_xrot = 0.0f;         // X Rotation 
GLfloat	g_yrot = 0.0f;         // Y Rotation 
GLfloat g_xspeed = 0.0f;	   // X Rotation Speed 
GLfloat g_yspeed = 0.0f;	   // Y Rotation Speed 
GLfloat	g_z = -5.0f;		   // Depth Into The Screen 
GLfloat g_lightAmbient[]  =	{ 0.5f, 0.5f, 0.5f, 1.0f }; // Ambient Light 
GLfloat g_lightDiffuse[]  =	{ 1.0f, 1.0f, 1.0f, 1.0f }; // Fiffuse Light 
GLfloat g_lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f }; // Light Source Position 
GLuint	g_filter;			   // Which Filter To Use 
GLuint	g_texid[TEXTURES_NUM]; // Our Textures' Id List 
int     g_part1;               // Start Of Disc (NEW)
int     g_part2;               // End Of Disc (NEW)
int     g_p1 = 0;              // Increase 1 (NEW)
int     g_p2 = 1;              // Increase 2 (NEW)
GLuint  g_object = 0;          // Which Object To Draw (NEW)
GLUquadricObj* g_quadratic;    // Storage For Our Quadratic Objects (NEW)





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
	if (!load_rgb_image("wall_64x64.raw", 64, 64, &img)) return false;
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
    glShadeModel(GL_SMOOTH);						   // Enable Smooth Shading
    glClearColor(0.0f, 0.0f, 0.0f, 0.5f);			   // Black Background
    glClearDepth(1.0f);								   // Depth Buffer Setup
    glEnable(GL_DEPTH_TEST);						   // Enables Depth Testing
    glDepthFunc(GL_LEQUAL);							   // The Type Of Depth Testing To Do
	if (!setup_textures()) return false;
	glEnable(GL_TEXTURE_2D);                           // Enable Texture Mapping 
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);             // Pixel Storage Mode To Byte Alignment
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	glLightfv(GL_LIGHT1, GL_AMBIENT, g_lightAmbient);  // Setup The Ambient Light 
	glLightfv(GL_LIGHT1, GL_DIFFUSE, g_lightDiffuse);  // Setup The Diffuse Light 
	glLightfv(GL_LIGHT1, GL_POSITION,g_lightPosition); // Position The Light 
	glEnable(GL_LIGHT1);                               // Enable Ligh 
	g_quadratic = gluNewQuadric();                     // Create A Pointer To The Quadric Object (Return 0 If No Memory) (NEW)
	if (g_quadratic == 0) return false;
	gluQuadricNormals(g_quadratic, GLU_SMOOTH);        // Create Smooth Normals (NEW)
	gluQuadricTexture(g_quadratic, GL_TRUE);           // Create Texture Coords (NEW)
	return true;
}

void glDrawCube(void)
{
	glBegin(GL_QUADS);
	// Front Face
	glNormal3f( 0.0f, 0.0f, 1.0f);
	glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
	// Back Face
	glNormal3f( 0.0f, 0.0f,-1.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
	glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
	// Top Face
	glNormal3f( 0.0f, 1.0f, 0.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
	// Bottom Face
	glNormal3f( 0.0f,-1.0f, 0.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
	glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
	// Right Face
	glNormal3f( 1.0f, 0.0f, 0.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);
	glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);
	// Left Face
	glNormal3f(-1.0f, 0.0f, 0.0f);
	glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);
	glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);
	glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);
	glEnd();
}

int DrawGLScene(GLvoid)									// Here's Where We Do All The Drawing
{
	return TRUE;										// Keep Going
}

// Our Rendering Is Done Here
void render(void)   
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The View
	glTranslatef(0.0f,0.0f,g_z);

	glRotatef(g_xrot,1.0f,0.0f,0.0f);
	glRotatef(g_yrot,0.0f,1.0f,0.0f);

	glBindTexture(GL_TEXTURE_2D, g_texid[g_filter]);

	switch(g_object)
	{
		case 0:
			glDrawCube();
		break;
		case 1:
			glTranslatef(0.0f,0.0f,-1.5f);					// Center The Cylinder
			gluCylinder(g_quadratic,1.0f,1.0f,3.0f,32,32);	// A Cylinder With A Radius Of 0.5 And A Height Of 2
		break;
		case 2:
			gluDisk(g_quadratic,0.5f,1.5f,32,32);			// Draw A Disc (CD Shape) With An Inner Radius Of 0.5, And An Outer Radius Of 2.  Plus A Lot Of Segments ;)
		break;
		case 3:
			gluSphere(g_quadratic,1.3f,32,32);				// Draw A Sphere With A Radius Of 1 And 16 Longitude And 16 Latitude Segments
		break;
		case 4:
			glTranslatef(0.0f,0.0f,-1.5f);					// Center The Cone
			gluCylinder(g_quadratic,1.0f,0.0f,3.0f,32,32);	// A Cone With A Bottom Radius Of .5 And A Height Of 2
		break;
		case 5:
			g_part1 += g_p1;
			g_part2 += g_p2;
			if (g_part1 > 359) {							// 360 Degrees
				g_p1    = 0;
				g_part1 = 0;
				g_p2    = 1;
				g_part2 = 0;
			}
			if (g_part2 > 359) {							// 360 Degrees
				g_p1 = 1;
				g_p2 = 0;
			}
			gluPartialDisk(g_quadratic,0.5f,1.5f,32,32,g_part1,g_part2-g_part1); // A Disk Like The One Before
		break;
	}

	g_xrot += g_xspeed;
	g_yrot += g_yspeed;

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
			exit(0);
		break;
		case 'L': case 'l':
			g_light = !g_light;
			if (!g_light) glDisable(GL_LIGHTING);
			else glEnable(GL_LIGHTING);
		break;
		case 'F': case 'f':
			g_filter += 1;
			if (g_filter > 2) g_filter = 0;
		break;
		case ' ':
			g_object++;
			if (g_object > 5) g_object = 0;
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
		case GLUT_KEY_PAGE_UP:
			g_z -= 0.02f;
		break;
		case GLUT_KEY_PAGE_DOWN:
			g_z += 0.02f;
		break;
		case GLUT_KEY_UP:
			g_xspeed -= 0.01f;
		break;
		case GLUT_KEY_DOWN:
			g_xspeed += 0.01f;
		break;
		case GLUT_KEY_RIGHT:
			g_yspeed += 0.01f;
		break;
		case GLUT_KEY_LEFT:
			g_yspeed -= 0.01f;
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
