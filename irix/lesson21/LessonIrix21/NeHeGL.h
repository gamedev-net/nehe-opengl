/****************************************************************
*   20/03/2002 DImitrios Christopoulos                          *
*   Modified NeHeGL Header                                      *
*   using the GLUT Framework                                    * 
*   Needs Glut 3.7 and upward to compile                        * 
**********************************************************************************
*                                                                                *
*	You Need To Provide The Following Functions:                             *
*                                                                                *
*	int Initialize ();                                                       *
*		Performs All Your Initialization                                 *
*		Returns 1 If Initialization Was Successful, 0 If Not             *
*                                                                                *
*	void Update ();                                                          *
*		Perform Motion Updates                                           *
*                                                                                *
*	void Draw (void);                                                        *
*		Perform All Your Scene Drawing                                   *
*                                                                                *
*       void getKey(int keycode);                                                * 
*       int getSpecialKey(int keycode);                                          *
*                Read if key was pressed, set keybuffer after read to 0.         * 
*                                                                                *                                                                      *
*       void peekKey(int keycode);                                               * 
*       int peekSpecialKey(int keycode);                                         *
*                Read if key was pressed, lets keybuffer untouched.              *
*                                                                                *
*        int getTimer();                                                         *
*                Return time in milliseconds since program start                 *
*********************************************************************************/

#ifndef GL_FRAMEWORK_INCLUDED
#define GL_FRAMEWORK_INCLUDED

#define ESCAPE 27
#define ENTER 13
#define InitPos_X 50                    // Initial positions
#define InitPos_Y 50
#define InitWidth 640
#define InitHeight 480

extern int window_height;               // these global vars can be accesed and
extern int window_width;                // store the size of the current window 

// Through this function you can access Keyboard info. 
// For keycode use the GLUT enumerators for the special keys.
// The key buffer entry is set to 0 after read.
int getKey(int keycode);                  
int getSpecialKey(int keycode); 
          
// Same as above get functions but do not zero the key buffer when retrieved.
int peekKey(int keycode);                 
int peekSpecialKey(int keycode);          

//Get time since startup
int getTimer();  

// These Are The Function You Must Provide
int Initialize ();                        // Performs All Your Initialization

void Update ();      	          	  // Perform Motion Updates

void Draw (void);		       	  // Perform All Your Scene Drawing

#endif					  // GL_FRAMEWORK_INCLUDED
