#include <GL/glut.h>   // The GL Utility Toolkit (GLUT) Header

bool g_gamemode;       // GLUT GameMode ON/OFF
bool g_fullscreen;     // Fullscreen Mode ON/OFF (When g_gamemode Is OFF)

GLfloat		rtri;						// Angle For The Triangle ( NEW )
GLfloat		rquad;						// Angle For The Quad     ( NEW )

// Our GL Specific Initializations
bool init(void)
{
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
	return true;
}

// Our Rendering Is Done Here
void render(void)   
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
    glLoadIdentity();									// Reset The Current Modelview Matrix
	glTranslatef(-1.5f,0.0f,-6.0f);						// Move Left 1.5 Units And Into The Screen 6.0
	glRotatef(rtri,0.0f,1.0f,0.0f);				// Rotate The Triangle On The Y axis ( NEW )
	
	glBegin(GL_TRIANGLES);					// Start Drawing A Triangle
		glColor3f(1.0f,0.0f,0.0f);			// Set Top Point Of Triangle To Red
		glVertex3f( 0.0f, 1.0f, 0.0f);			// First Point Of The Triangle
		glColor3f(0.0f,1.0f,0.0f);			// Set Left Point Of Triangle To Green
		glVertex3f(-1.0f,-1.0f, 0.0f);			// Second Point Of The Triangle
		glColor3f(0.0f,0.0f,1.0f);			// Set Right Point Of Triangle To Blue
		glVertex3f( 1.0f,-1.0f, 0.0f);			// Third Point Of The Triangle
	glEnd();						// Done Drawing The Triangle
	
	glLoadIdentity();					// Reset The Current Modelview Matrix
	glTranslatef(1.5f,0.0f,-6.0f);				// Move Right 1.5 Units And Into The Screen 6.0
	glRotatef(rquad,1.0f,0.0f,0.0f);			// Rotate The Quad On The X axis ( NEW )
	
	glColor3f(0.5f,0.5f,1.0f);				// Set The Color To A Nice Blue Shade
	glBegin(GL_QUADS);					// Start Drawing A Quad
		glVertex3f(-1.0f, 1.0f, 0.0f);			// Top Left Of The Quad
		glVertex3f( 1.0f, 1.0f, 0.0f);			// Top Right Of The Quad
		glVertex3f( 1.0f,-1.0f, 0.0f);			// Bottom Right Of The Quad
		glVertex3f(-1.0f,-1.0f, 0.0f);			// Bottom Left Of The Quad
	glEnd();						// Done Drawing The Quad
	
	rtri+=0.2f;						// Increase The Rotation Variable For The Triangle ( NEW )
	rquad-=0.15f;						// Decrease The Rotation Variable For The Quad     ( NEW )

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
	gluPerspective(80, (float)w/(float)h, 1.0, 5000.0);
	glMatrixMode(GL_MODELVIEW);      // Select The Modelview Matrix
	glLoadIdentity();                // Reset The Modelview Matrix
}

// Our Keyboard Handler (Normal Keys)
void keyboard(unsigned char key, int x, int y)
{
	switch (key) {
		case 27:        // When Escape Is Pressed...
			exit(0);    // Exit The Program
		break;          // Ready For Next Case
		default:        // Now Wrap It Up
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
		break;
	}
}

// Main Function For Bringing It All Together.
int main(int argc, char** argv)
{

	glutInit(&argc, argv);                           // GLUT Initializtion
	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE);     // Display Mode (Rgb And Double Buffered)
	glutInitWindowSize(500, 500);                // Window Size If We Start In Windowed Mode
	glutCreateWindow("NeHe's OpenGL Framework"); // Window Title 

	init();                                          // Our Initialization
	glutDisplayFunc(render);                         // Register The Display Function
	glutReshapeFunc(reshape);                        // Register The Reshape Handler
	glutKeyboardFunc(keyboard);                      // Register The Keyboard Handler
	glutSpecialFunc(special_keys);                   // Register Special Keys Handler
	glutMainLoop();                                  // Go To GLUT Main Loop
	return 0;
}
