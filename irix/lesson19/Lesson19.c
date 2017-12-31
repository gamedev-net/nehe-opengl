///////////////////////////////////////////////////////////////////////////////
//    Lesson 19 code by Jeff Molofee 
//    Modified to run on Irix using GLUT by Dimitrios Christopoulos      
//    Date: 28/03/00
///////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#include "texture.h"


#define	MAX_PARTICLES	1000		// Number Of Particles To Create

int	keys[256];					// Array Used For The Keyboard Routine
int	active=1;				// Window Active Flag Set To 1 By Default
int	rainbow=0;				// Rainbow Mode?
float   df=0.2, df1=0.01, df2=-0.02;

float	slowdown=2.0f;				// Slow Down Particles
float	xspeed;						// Base X Speed (To Allow Keyboard Direction Of Tail)
float	yspeed;						// Base Y Speed (To Allow Keyboard Direction Of Tail)
float	zoom=-40.0f;				// Used To Zoom Out
float   spin=0, spin1=0, spin2=0;

GLuint	loop;						// Misc Loop Variable
GLuint	col;						// Current Color Selection
GLuint	delay=0;						// Rainbow Effect Delay
GLuint	image;						// Storage For Particle Image Display List
GLuint	texture[1];					// Storage For Our Particle Texture

typedef struct						// Create A Structure For Particle
{
	int	active;					// Active (Yes/No)
	float	life;					// Particle Life
	float	fade;					// Fade Speed
	float	r;						// Red Value
	float	g;						// Green Value
	float	b;						// Blue Value
	float	x;						// X Position
	float	y;						// Y Position
	float	z;						// Z Position
	float	xi;						// X Direction
	float	yi;						// Y Direction
	float	zi;						// Z Direction
	float	xg;						// X Gravity
	float	yg;						// Y Gravity
	float	zg;						// Z Gravity
}
particles;							// Particles Structure

particles particle[MAX_PARTICLES];	// Particle Array (Room For Particle Info)

static GLfloat colors[12][3]=		// Rainbow Of Colors
{
	{1.0f,0.5f,0.5f},{1.0f,0.75f,0.5f},{1.0f,1.0f,0.5f},{0.75f,1.0f,0.5f},
	{0.5f,1.0f,0.5f},{0.5f,1.0f,0.75f},{0.5f,1.0f,1.0f},{0.5f,0.75f,1.0f},
	{0.5f,0.5f,1.0f},{0.75f,0.5f,1.0f},{1.0f,0.5f,1.0f},{1.0f,0.5f,0.75f}
};


//Loads texture , the textures have to be in sgi(rgb) format
//I used the texture loading code code from the advanced siggraff 99 notes
// this code is in the texture.c .h files,  and is fairly easy to use.
int LoadGLTextures()								// Load Bitmap And Convert To Textures
{
        int Status=0;								// Status Indicator
        unsigned *TextureImage=NULL;				// Create Storage Space For The Textures
        int texwid, texht; /* dimensions of texture that was read */
	int texcomps; /* number of components in external format */

        if (TextureImage=read_texture("Data/Particle.rgb", &texwid, &texht, &texcomps)) // Load Particle Texture
        {
			Status=1;								// Set The Status To 1
			glGenTextures(1, &texture[0]);				// Create One Texture

			glBindTexture(GL_TEXTURE_2D, texture[0]);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, texcomps,texwid,texht, 0, GL_RGBA, GL_UNSIGNED_BYTE, TextureImage);
        }

        if (TextureImage)							// If Texture Exists
		{
		 	free(TextureImage);			// Free The Texture Image Memory
		}
               
        return Status;									// Return The Status
}

GLvoid MakeParticle(GLvoid)								// Build Our Particle Display List
{
	image=glGenLists(1);								// Generate Our Display List
	glNewList(image,GL_COMPILE);						// Build A Compiled Display List
		glBegin(GL_QUADS);								// Build A Quad
			glTexCoord2f(1.0f,1.0f); glVertex3f( 0.5f, 0.5f, 0.0f);	// Top Right
			glTexCoord2f(0.0f,1.0f); glVertex3f(-0.5f, 0.5f, 0.0f);	// Top Left
			glTexCoord2f(0.0f,0.0f); glVertex3f(-0.5f,-0.5f, 0.0f);	// Bottom Left
			glTexCoord2f(1.0f,0.0f); glVertex3f( 0.5f,-0.5f, 0.0f);	// Bottom Right
		glEnd();										// Done Building Our Quad
	glEndList();										// Done Building Our Display List
}

void reshape(int width, int height)		// Resize And Initialize The GL Window
{
	if (height==0)										// Prevent A Divide By Zero By
	{
		height=1;										// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,200.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

int InitGL(GLvoid)										// All Setup For OpenGL Goes Here
{
	if (!LoadGLTextures())								// Jump To Texture Loading Routine
	{
		return 0;									// If Texture Didn't Load Return 0
	}

	MakeParticle();										// Build Our Particle Display List

	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f,0.0f,0.0f,0.0f);					// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glDisable(GL_DEPTH_TEST);							// Disable Depth Testing
	glEnable(GL_BLEND);									// Enable Blending
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Type Of Blending To Perform
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);	// Really Nice Perspective Calculations
	glHint(GL_POINT_SMOOTH_HINT,GL_NICEST);				// Really Nice Point Smoothing
	glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
	glBindTexture(GL_TEXTURE_2D,texture[0]);			// Select Our Texture

	for (loop=0;loop<MAX_PARTICLES;loop++)				// Initials All The Textures
	{
		particle[loop].active=true;						// Make All The Particles Active
		particle[loop].life=1.0f;						// Give All The Particles Full Life
		particle[loop].fade=float(rand()%100)/1000.0f+0.003f;	// Random Fade Speed
		particle[loop].r=colors[(loop+1)/(MAX_PARTICLES/12)][0];	// Select Red Rainbow Color
		particle[loop].g=colors[(loop+1)/(MAX_PARTICLES/12)][1];	// Select Green Rainbow Color
		particle[loop].b=colors[(loop+1)/(MAX_PARTICLES/12)][2];	// Select Blue Rainbow Color
		particle[loop].xi=float((rand()%50)-26.0f)*10.0f;	// Random Speed On X Axis
		particle[loop].yi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Y Axis
		particle[loop].zi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Z Axis
		particle[loop].xg=0.0f;							// Set Horizontal Pull To Zero
		particle[loop].yg=-0.8f;						// Set Vertical Pull Downward
		particle[loop].zg=0.0f;							// Set Pull On Z Axis To Zero
	}

        for (int yu=0;yu<256;yu++) 
             keys[yu]=0;

	return 1;										// Initialization Went OK
}


void display()										// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// Clear Screen And Depth Buffer

	for (loop=0;loop<MAX_PARTICLES;loop++)					// Loop Through All The Particles
	{
		if (particle[loop].active)							// If The Particle Is Active
		{
			glLoadIdentity();								// Reset The ModelView Matrix
			// Position Each Particle On The Screen, Use Zoom To Move Into The Screen

                         //Spin me crazy mode*********************** 
                         if (keys[62])
                         {
                             glRotatef(spin, 0,0,1);
                             glTranslatef(spin1, spin2,0);
                         }
                         //*****************************************

                        glTranslatef(particle[loop].x,particle[loop].y,particle[loop].z+zoom);
                         
			// Draw The Particle Using Our RGB Values, Fade The Particle Based On It's Life
			glColor4f(particle[loop].r,particle[loop].g,particle[loop].b,particle[loop].life);
			glCallList(image);									// Draw Our Particle
			particle[loop].x+=particle[loop].xi/(slowdown*1000);// Move On The X Axis By X Speed
			particle[loop].y+=particle[loop].yi/(slowdown*1000);// Move On The Y Axis By Y Speed
			particle[loop].z+=particle[loop].zi/(slowdown*1000);// Move On The Z Axis By Z Speed

			particle[loop].xi+=particle[loop].xg;			// Take Pull On X Axis Into Account
			particle[loop].yi+=particle[loop].yg;			// Take Pull On Y Axis Into Account
			particle[loop].zi+=particle[loop].zg;			// Take Pull On Z Axis Into Account
			particle[loop].life-=particle[loop].fade;		// Reduce Particles Life By 'Fade'

			if (particle[loop].life<0.0f)					// If Particle Is Burned Out
			{
				particle[loop].life=1.0f;					// Give It New Life
				particle[loop].fade=float(rand()%100)/1000.0f+0.003f;	// Random Fade Value
				particle[loop].x=0.0f;						// Center On X Axis
				particle[loop].y=0.0f;						// Center On Y Axis
				particle[loop].z=0.0f;						// Center On Z Axis
				
                                if (keys[61]) //constant explosion mode *****************
                                    {
                                        particle[loop].xi=float((rand()%50)-26.0f)*10.0f;	// Random Speed On X Axis
         				particle[loop].yi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Y Axis
	        			particle[loop].zi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Z Axis
                                    }
                                else
                                    {
                                         particle[loop].xi=xspeed+float((rand()%60)-32.0f);	// X Axis Speed And Direction
				         particle[loop].yi=yspeed+float((rand()%60)-30.0f);	// Y Axis Speed And Direction
				         particle[loop].zi=float((rand()%60)-30.0f);	// Z Axis Speed And Direction
                                    }
				particle[loop].r=colors[col][0];			// Select Red From Color Table
				particle[loop].g=colors[col][1];			// Select Green From Color Table
				particle[loop].b=colors[col][2];			// Select Blue From Color Table
			}

			// If Number Pad 8 And Y Gravity Is Less Than 1.5 Increase Pull Upwards
			if (keys[8] && (particle[loop].yg<1.5f)) { particle[loop].yg+=0.2f;
                                                                 }

			// If Number Pad 2 And Y Gravity Is Greater Than -1.5 Increase Pull Downwards
			if (keys[2] && (particle[loop].yg>-1.5f)) { particle[loop].yg-=0.2f;
                                                                   }

			// If Number Pad 6 And X Gravity Is Less Than 1.5 Increase Pull Right
			if (keys[6] && (particle[loop].xg<1.5f)) { particle[loop].xg+=0.2f;
                                                                  }

			// If Number Pad 4 And X Gravity Is Greater Than -1.5 Increase Pull Left
			if (keys[4] && (particle[loop].xg>-1.5f)) { particle[loop].xg-=0.2f;
                                                                   }

			if (keys[60])										// Tab Key Causes A Burst
			{
				particle[loop].x=0.0f;								// Center On X Axis
				particle[loop].y=0.0f;								// Center On Y Axis
				particle[loop].z=0.0f;								// Center On Z Axis
				particle[loop].xi=float((rand()%50)-26.0f)*10.0f;	// Random Speed On X Axis
				particle[loop].yi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Y Axis
				particle[loop].zi=float((rand()%50)-25.0f)*10.0f;	// Random Speed On Z Axis
                         }
		}
    }
	keys[60]=0;
        keys[8]=0;
        keys[2]=0;
        keys[6]=0;
        keys[4]=0;
	glutSwapBuffers();								// Everything Went OK
}

void
keyboard(unsigned char key, int x, int y)
{
    
    switch (key) 
    {
     case 27:
        exit(0);
	break;
     case '8': keys[8]=1; break;
     case '2': keys[2]=1; break;
     case '6': keys[6]=1; break;
     case '4': keys[4]=1; break;
     case  9 : keys[60]=1; break;       //explosion
     case 'e': keys[61]^=1; break;      //continuous explosion
     case 'c': keys[62]^=1; break;      //going crazy
     case ' ': col++;                   // Change The Particle Color
               if (col>11)	col=0;	// If Color Is To High Reset It
               break;
     case '+': if (slowdown>1.0f) slowdown-=0.1f;
               break;
     case '-': if (slowdown<4.0f) slowdown+=0.1f; 
               break;
     case 13: rainbow^=1; 
                break;
     
    }
}


void specialfunc(int key, int x, int y)
{
     switch (key) 
    {
    case GLUT_KEY_LEFT :     if (xspeed>-200) xspeed-=1.0f;
                             break;
    case GLUT_KEY_UP   :     if (yspeed<200) yspeed+=1.0f;
                             break;
    case GLUT_KEY_RIGHT:     if (xspeed<200) xspeed+=1.0f;
                             break;
    case GLUT_KEY_DOWN :     if (yspeed>-200) yspeed-=1.0f;
                             break;
    case GLUT_KEY_PAGE_UP:   zoom+=0.1f;
                             break;
    case GLUT_KEY_PAGE_DOWN: zoom-=0.1f;
                             break;
    }
}


void idleFunc()
{
  //Are we in rainbow mode*******************
  if (rainbow && (delay>25))
     { 
         delay=0;              // Reset The Rainbow Color Cycling Delay
         col++;                // Change The Particle Color
         if (col>11)	col=0;	// If Color Is To High Reset It
     }

  if (rainbow)  delay++;
  //****************************************             
  
  //spin me crazy mode**********************
  if (keys[62])    
      {
          spin+=2;
          spin1+=df1;
          spin2+=df2;
        
          if (spin>360) spin-=360;
          if ((spin1>2)||(spin1<-2)) df1=-df1;
          if ((spin2>2)||(spin2<-2)) df2=-df2;
        
          zoom+=df;
          if ((zoom<-60)||(zoom>-10)) df=-df;
      } 
   //***************************************
  
 glutPostRedisplay();
}




int main(int argc, char** argv)
{
    glutInitDisplayMode(GLUT_RGB|GLUT_DOUBLE);
    glutInitWindowPosition(50, 50);
    glutInitWindowSize(800, 600);
    glutInit(&argc, argv);
    glutCreateWindow("Particles");
    glutDisplayFunc(display);
    glutReshapeFunc(reshape);
    glutIdleFunc(idleFunc);
    glutKeyboardFunc(keyboard);
    glutSpecialFunc(specialfunc);
    InitGL();
    glutMainLoop();
    return 0;
}
