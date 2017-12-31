/* 
 * NeHe Lesson #24 - Tokens, Extensions, TGA Loading.
 * Ashley Harvey (Hornet@ElucideX.com)
 * Revisions: Rob "Kormoc" Smith, kormoc@kormoc.com
 */
#define GLUT_DISABLE_ATEXIT_HACK

#ifdef _WIN32                        // Running on windows?
 #include <windows.h>                // Then include windows.h
#else                                // Running on a different platform?
 #include <stdlib.h>
 #include <string.h>
 #include <stdarg.h>
#endif

#include <GL/glut.h>
#include <stdio.h>
#include "tga.h"                                                        // Targa loading header file.

int	scroll,											                    // Used For Scrolling The Screen
	maxtokens,										                    // Keeps Track Of The Number Of Extensions Supported
    swidth,										  	                    // Scissor Width
    sheight;										                    // Scissor Height

GLuint base;										                    // Base Display List For The Font

TextureImage textures[1];									            // Storage For One Texture

void keyboard(unsigned char, int, int), special(int, int, int);         // Reshape function, keyboard function, special keys keyboard function.
GLvoid BuildFont(),                                                     // Building and killing font display lists.
       KillFont(),
       glPrint(GLint, GLint, int, const char *, ...),                   // Printing text function.
       ReSizeGLScene(GLsizei, GLsizei),                                 // Resize the window.
       DrawGLScene();                                                   // Main drawing happens here.

int InitGL(),
    Window = 0;                                                         // Initiation function and Window variable.
bool Fullscreen = false;                                                // GLUT Game Mode active?

int main(int argc, char *argv[])
{
 glutInit(&argc, argv);                                                 // Initiate GLUT.
 glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE);              // RGB, Depth Buffer, Double Buffered.
 glutInitWindowSize(640, 480);                                          // Initial resolution 640x480.
 glutInitWindowPosition(1, 1);                                          // Window position.
 glutCreateWindow("NeHe's Token, Extensions, Scissoring & TGA Loading Tutorial"); // Create the window.
 InitGL();                                                              // Run through the initiation function.
 glutDisplayFunc(DrawGLScene);                                          // Main drawing function.
 glutReshapeFunc(ReSizeGLScene);                                        // Reshape the window if need be.
 glutKeyboardFunc(keyboard);                                            // Normal keyboard input.
 glutSpecialFunc(special);                                              // Special keyboard input.
 glutMainLoop();
 return 0;
}

int InitGL()											     // All Setup For OpenGL Goes Here
{
 glutGameModeString("1024x768:32@60");
 if(!LoadTGA(&textures[0], "Data/Font.TGA"))				// Load The Font Texture
 {
  return 0;										            // If Loading Failed, Return False
 }
 BuildFont();											    // Build The Font
 glShadeModel(GL_SMOOTH);								    // Enable Smooth Shading
 glClearColor(0.0f, 0.0f, 0.0f, 0.5f);			 		    // Black Background
 glClearDepth(1.0f);										// Depth Buffer Setup
 glBindTexture(GL_TEXTURE_2D, textures[0].texID);		    // Select Our Font Texture
 return 1;											        // Initialization Went OK
}

void special(int key, int x, int y)
{
 switch(key)
 {
  case GLUT_KEY_F1:                                         // Did user hit F1?
   if(glutGet(GLUT_GAME_MODE_POSSIBLE) && !Fullscreen)      // Is the mode possible, and are we currenty in windowed mode?
   {
    Window = glutGetWindow();                               // To return control back to window when we come back out of Glut Game Mode.
    Fullscreen = 1;                                         // Entering fullscreen mode.
    glutEnterGameMode();                                    // Enter fullscreen mode.
     InitGL();                                              // Run through functions.
     glutDisplayFunc(DrawGLScene);
     glutReshapeFunc(ReSizeGLScene);
     glutKeyboardFunc(keyboard);
     glutSpecialFunc(special);
     glutMainLoop();
   }
   else
   {
    Fullscreen = 0;                                        // Not fullscreen anymore.
    glutLeaveGameMode();                                   // Leave fullscreen mode.
    glutSetWindow(Window);                                 // Return control to previous, non-fullscreen, window.
    ReSizeGLScene(640, 480);                               // Resize to 640x480.
   }
   break;
  case GLUT_KEY_UP:                                        // Scroll up.
   if(scroll > 0)
    scroll -= 3;
   break;
  case GLUT_KEY_DOWN:                                      // Scroll down.
   if(scroll < 32 * (maxtokens - 9))
    scroll += 3;
   break;
  default:
   break;
 }
 glutPostRedisplay();                                       // Notify GLUT that window needs to be redrawn.
}

void keyboard(unsigned char key, int x, int y)
{
 switch(key)
 {
  case 27:                                             // Did user hit ESC?
   KillFont();                                         // Release display list memory.
   exit(0);                                            // Kill app.
   break;
  default:
   break;
 }
}

GLvoid BuildFont()									    // Build Our Font Display List
{
 base = glGenLists(256);									// Creating 256 Display Lists
 glBindTexture(GL_TEXTURE_2D, textures[0].texID);		    // Select Our Font Texture
 for(int loop1 = 0; loop1 < 256; loop1++)					// Loop Through All 256 Lists
 {
  float cx = float(loop1%16)/16.0f;						// X Position Of Current Character
  float cy = float(loop1/16)/16.0f;						// Y Position Of Current Character
  glNewList(base + loop1, GL_COMPILE);					// Start Building A List
   glBegin(GL_QUADS);								    // Use A Quad For Each Character
    glTexCoord2f(cx, 1.0f - cy - 0.0625f);			        // Texture Coord (Bottom Left)
     glVertex2d(0, 16);							        // Vertex Coord (Bottom Left)
    glTexCoord2f(cx + 0.0625f, 1.0f - cy - 0.0625f);	// Texture Coord (Bottom Right)
     glVertex2i(16, 16);							    // Vertex Coord (Bottom Right)
    glTexCoord2f(cx + 0.0625f, 1.0f - cy - 0.001f);	    // Texture Coord (Top Right)
     glVertex2i(16, 0);							        // Vertex Coord (Top Right)
    glTexCoord2f(cx, 1.0f - cy - 0.001f);			    // Texture Coord (Top Left)
     glVertex2i(0, 0);							        // Vertex Coord (Top Left)
   glEnd();										        // Done Building Our Quad (Character)
   glTranslated(14, 0, 0);							    // Move To The Right Of The Character
  glEndList();										    // Done Building The Display List
 }														// Loop Until All 256 Are Built
}

GLvoid KillFont()									    // Delete The Font From Memory
{
 glDeleteLists(base,256);								// Delete All 256 Display Lists
}

GLvoid glPrint(GLint x, GLint y, int set, const char *fmt, ...)	// Where The Printing Happens
{
 char text[1024];									            // Holds Our String
 va_list ap;											        // Pointer To List Of Arguments
 if (fmt == NULL)										        // If There's No Text
  return;												        // Do Nothing

 va_start(ap, fmt);										        // Parses The String For Variables
  vsprintf(text, fmt, ap);							            // And Converts Symbols To Actual Numbers
 va_end(ap);												    // Results Are Stored In Text
 if(set > 1)												    // Did User Choose An Invalid Character Set?
 {
  set = 1;												        // If So, Select Set 1 (Italic)
 }
 glEnable(GL_TEXTURE_2D);								// Enable Texture Mapping
 glLoadIdentity();										// Reset The Modelview Matrix
 glTranslated(x, y, 0);									// Position The Text (0,0 - Top Left)
 glListBase(base - 32 + (128 * set));					// Choose The Font Set (0 or 1)
 glScalef(1.0f, 2.0f, 1.0f);							// Make The Text 2X Taller
 glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);		// Write The Text To The Screen
 glDisable(GL_TEXTURE_2D);								// Disable Texture Mapping
}

GLvoid ReSizeGLScene(GLsizei width, GLsizei height)			// Resize And Initialize The GL Window
{
 swidth = width;											// Set Scissor Width To Window Width
 sheight = height;											// Set Scissor Height To Window Height
 if(height == 0)											// Prevent A Divide By Zero By
 {
  height = 1;											    // Making Height Equal One
 }
 glViewport(0, 0, width, height);							// Reset The Current Viewport
 glMatrixMode(GL_PROJECTION);							    // Select The Projection Matrix
 glLoadIdentity();										    // Reset The Projection Matrix
 glOrtho(0.0f, 640, 480, 0.0f, -1.0f, 1.0f);				// Create Ortho 640x480 View (0,0 At Top Left)
 glMatrixMode(GL_MODELVIEW);								// Select The Modelview Matrix
 glLoadIdentity();										    // Reset The Modelview Matrix
}


void DrawGLScene()										// Here's Where We Do All The Drawing
{
 char *token;											// Storage For Our Token
 int cnt = 0;											// Local Counter Variable

 glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer

 glColor3f(1.0f,0.5f,0.5f);								// Set Color To Bright Red
 glPrint(50, 16, 1, "Renderer");						// Display Renderer
 glPrint(80, 48, 1, "Vendor");							// Display Vendor Name
 glPrint(66, 80, 1, "Version");							// Display Version

 glColor3f(1.0f, 0.7f, 0.4f);								// Set Color To Orange
 glPrint(200, 16, 1,(char *)glGetString(GL_RENDERER));	    // Display Renderer
 glPrint(200, 48, 1,(char *)glGetString(GL_VENDOR));		// Display Vendor Name
 glPrint(200, 80, 1,(char *)glGetString(GL_VERSION));		// Display Version

 glColor3f(0.5f, 0.5f, 1.0f);								// Set Color To Bright Blue
 glPrint(192, 432, 1, "NeHe Productions");					// Write NeHe Productions At The Bottom Of The Screen

 glLoadIdentity();										// Reset The ModelView Matrix
 glColor3f(1.0f, 1.0f, 1.0f);							// Set The Color To White
 glBegin(GL_LINE_STRIP);								// Start Drawing Line Strips (Something New)
  glVertex2d(639, 417);								    // Top Right Of Bottom Box
  glVertex2d(0, 417);								    // Top Left Of Bottom Box
  glVertex2d(0, 480);								    // Lower Left Of Bottom Box
  glVertex2d(639, 480);								    // Lower Right Of Bottom Box
  glVertex2d(639, 128);								    // Up To Bottom Right Of Top Box
 glEnd();												// Done First Line Strip
 glBegin(GL_LINE_STRIP);								// Start Drawing Another Line Strip
  glVertex2d(0, 128);								    // Bottom Left Of Top Box
  glVertex2d(639, 128);								    // Bottom Right Of Top Box								
  glVertex2d(639, 1);								    // Top Right Of Top Box
  glVertex2d(0, 1);								        // Top Left Of Top Box
  glVertex2d(0, 417);								    // Down To Top Left Of Bottom Box
 glEnd();												// Done Second Line Strip

 glScissor(1, int(0.135416f * sheight), swidth - 2, int(0.597916f * sheight));	// Define Scissor Region
 glEnable(GL_SCISSOR_TEST);								                        // Enable Scissor Testing

 char *text = (char *)malloc(strlen((char *)glGetString(GL_EXTENSIONS)) + 1);	// Allocate Memory For Our Extension String
 strcpy (text, (char *)glGetString(GL_EXTENSIONS));		                        // Grab The Extension List, Store In Text

 token = strtok(text, " ");									                    // Parse 'text' For Words, Seperated By " " (spaces)
 while(token != NULL)										                    // While The Token Isn't NULL
 {
  cnt++;												// Increase The Counter
  if(cnt > maxtokens)									// Is 'maxtokens' Less Than 'cnt'
   maxtokens=cnt;									    // If So, Set 'maxtokens' Equal To 'cnt'
  glColor3f(0.5f, 1.0f, 0.5f);							// Set Color To Bright Green
  glPrint(0, 96 + (cnt*32) - scroll, 0, "%i", cnt);		// Print Current Extension Number
  glColor3f(1.0f, 1.0f, 0.5f);							// Set Color To Yellow
  glPrint(50, 96 + (cnt*32) - scroll, 0, token);		// Print The Current Token (Parsed Extension Name)
  token = strtok(NULL, " ");							// Search For The Next Token
 }

 glDisable(GL_SCISSOR_TEST);							// Disable Scissor Testing
 free(text);											// Free Allocated Memory
 glutSwapBuffers();
}
