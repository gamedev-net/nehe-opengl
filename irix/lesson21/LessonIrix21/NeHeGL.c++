///////////////////////////////////////////////////////////////////////////////
//    Lesson 37 code by Jeff Molofee 
//    Modified to run on Irix using GLUT by Dimitrios Christopoulos      
//    Date: 20/03/2002
//    Needs GLUT 3.7 to compile
///////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#include "NeHeGL.h"

int	keys[256];				// Array Used For The Keyboard Routine
int     special_keys[22];       
int window_width=InitWidth;                     //Store the height and width of window
int window_height=InitHeight;

void Reshape(int width, int height)		// Resize And Initialize The GL Window
{
    if (height==0)					 // Prevent A Divide By Zero By
    {
	height=1;					 // Making Height Equal One
    }

    glViewport(0,0,width,height);			 // Reset The Current Viewport

    glMatrixMode(GL_PROJECTION);			 // Select The Projection Matrix
    glLoadIdentity();					 // Reset The Projection Matrix

    glOrtho(0.0f,InitWidth,InitHeight,0.0f,-1.0f,1.0f);	 // Create Ortho 640x480 View (0,0 At Top Left)

    glMatrixMode(GL_MODELVIEW);				 // Select The Modelview Matrix
    glLoadIdentity();					 // Reset The Modelview Matrix
}


/**********************************************************************/
/* Functions to retrieve if keys have been pressed.                   */
/* Return 1 if key is pressed.                                        */
/* Get functions remove the event from the keys[] array, once called. */
/* Peek functions do not remove the event from the keys[] array.      */
/* In the keys[] array the keyboard state is stored at any time.      */
/*                                                                    */
/* The get/peekKey functions retrieve normal keybord state.           */
/* The get/peekSpeciaKey functions retrieve state for special keys    */
/* like F1-F9, Cursor keys and others. Look at the glut.h file for    */
/* definitions.                                                       */
/**********************************************************************/
int getKey(int keycode)
{
   int temp=0;
   if ( (keycode>=0) && (keycode<=255) )
   {
       temp=keys[keycode];
       keys[keycode]=0;
   }
   return temp;
}

int peekKey(int keycode)
{
   if ( (keycode>=0) && (keycode<=255) )
       return keys[keycode];        
   else
       return 0;
}

int getSpecialKey(int keycode)
{
    int temp=0;

    if ( (keycode>=GLUT_KEY_F1) && (keycode<=GLUT_KEY_F12) ) 
    {
        temp=special_keys[keycode];
        special_keys[keycode]=0;
    }
    else if ( (keycode>=GLUT_KEY_LEFT) && (keycode<=GLUT_KEY_INSERT) ) 
    {
        temp=special_keys[(GLUT_KEY_F12+1)+(keycode-GLUT_KEY_LEFT)];
        special_keys[(GLUT_KEY_F12+1)+(keycode-GLUT_KEY_LEFT)]=0;
    }
    return temp;
}

int peekSpecialKey(int keycode)
{
    if ( (keycode>=GLUT_KEY_F1) && (keycode<=GLUT_KEY_F12) ) 
    {
        return special_keys[keycode];
    }
    else if ( (keycode>=GLUT_KEY_LEFT) && (keycode<=GLUT_KEY_INSERT) ) 
    {
        return special_keys[(GLUT_KEY_F12+1)+(keycode-GLUT_KEY_LEFT)];
    }
    return 0;
}


/*******************************************************************/
/*         Callbacks to register key presses and releases.         */
/*         The keys[] array is updated.                            */
/*******************************************************************/
void Keyboard(unsigned char key, int x, int y)
{
     keys[key]=1;
}

void Specialfunc(int key, int x, int y)
{
    if ( (key>=GLUT_KEY_F1) && (key<=GLUT_KEY_F12) )
        special_keys[key]=1;
    else if ( (key>=GLUT_KEY_LEFT) && (key<=GLUT_KEY_INSERT) )
        special_keys[(GLUT_KEY_F12+1)+(key-GLUT_KEY_LEFT)]=1;
}

void KeyboardUp(unsigned char key, int x, int y)
{
     keys[key]=0;
}

void SpecialfuncUp(int key, int x, int y)
{
    if ( (key>=GLUT_KEY_F1) && (key<=GLUT_KEY_F12) )
        special_keys[key]=0;
    else if ( (key>=GLUT_KEY_LEFT) && (key<=GLUT_KEY_INSERT) )
        special_keys[(GLUT_KEY_F12+1)+(key-GLUT_KEY_LEFT)]=0;
}


/*******************************************************************/
/*                Return miliseconds since start.                  */
/*******************************************************************/
int getTimer()
{
    return glutGet(GLUT_ELAPSED_TIME);
}


/*******************************************************************/
/*                 Main startup program.                           */
/*                 Use -f for fullscreen at startup.               */
/*******************************************************************/                             
int main(int argc, char** argv)
{
    // Zeros keys[] array
    for(int y=0;y<256;y++) 
       keys[y]=0;
    for(y=0;y<22;y++) 
       special_keys[y]=0;

    //Setup GLUT
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
    glutInitWindowPosition(InitPos_X, InitPos_Y);
    glutInitWindowSize(window_width, window_height);
    glutCreateWindow("GRID CRAZY");
    if (argc > 1 && !strcmp(argv[1], "-f")) // Read commadline and enter fullscreen
        glutFullScreen();
    glutIgnoreKeyRepeat(1);           // Ignore Key repeats Glut 3.7
    glutDisplayFunc(Draw);
    glutReshapeFunc(Reshape);
    glutIdleFunc(Update);
                                      // Callbacks for normal keys like (a,b,c...z)
    glutKeyboardFunc(Keyboard);       // Callback for press keys events
    glutKeyboardUpFunc(KeyboardUp);   // Callback for release key events Glut 3.7
                                      // Callbacks for special keys like F1...F9, CursorKeys...
    glutSpecialFunc(Specialfunc);     // Callback for key press 
    glutSpecialUpFunc(SpecialfuncUp); // Callback for key release
    Initialize();                     // Call user supplied Initialisation function
    glutMainLoop();                   // Enter Simulation loop
    return 0;
}
