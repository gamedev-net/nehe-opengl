/*
 *		This Code Was Created By Pet & Commented/Cleaned Up By Jeff Molofee
 *		If You've Found This Code Useful, Please Let Me Know.
 *		Visit NeHe Productions At http://nehe.gamedev.net
 *
 *		glut port by tsuraan
 */

#include <stdlib.h>                                     // For malloc, free
#include <math.h>										// Math Library Header File
#include <stdio.h>										// Header File For Standard Input/Output
#include <GL/gl.h>										// Header File For The OpenGL32 Library
#include <GL/glu.h>										// Header File For The GLu32 Library
#include <GL/glut.h>

GLfloat		xrot,yrot,zrot,								// X, Y & Z Rotation
			xspeed,yspeed,zspeed,						// X, Y & Z Spin Speed
			cx,cy,cz=-15;								// X, Y & Z Position

int			key=1;										// Used To Make Sure Same Morph Key Is Not Pressed
int			step=0,steps=200;							// Step Counter And Maximum Number Of Steps
bool		morph=false;								// Default morph To False (Not Morphing)

typedef struct											// Structure For 3D Points
{
	float	x, y, z;									// X, Y & Z Points
} VERTEX;												// Called VERTEX

typedef struct											// Structure For An Object
{
 int		verts;										// Number Of Vertices For The Object
 VERTEX		*points;									// One Vertice (Vertex x,y & z)
} OBJECT;												// Called OBJECT

int			maxver;										// Will Eventually Hold The Maximum Number Of Vertices
OBJECT		morph1,morph2,morph3,morph4,				// Our 4 Morphable Objects (morph1,2,3 & 4)
			helper,*sour,*dest;							// Helper Object, Source Object, Destination Object

void objallocate(OBJECT *k,int n)						// Allocate Memory For Each Object
{														// And Defines points
	k->points=(VERTEX*)malloc(sizeof(VERTEX)*n);		// Sets points Equal To VERTEX * Number Of Vertices
}														// (3 Points For Each Vertice)

void objfree(OBJECT *k)									// Frees The Object (Releasing The Memory)
{
	free(k->points);									// Frees Points
}

void readstr(FILE *f,char *string)						// Reads A String From File (f)
{
	do													// Do This
	{
		fgets(string, 255, f);							// Gets A String Of 255 Chars Max From f (File)
	} while ((string[0] == '/') || (string[0] == '\n'));// Until End Of Line Is Reached
	return;												// Return
}

void objload(char *name,OBJECT *k)						// Loads Object From File (name)
{
	int		ver;										// Will Hold Vertice Count
	float	rx,ry,rz;									// Hold Vertex X, Y & Z Position
	FILE	*filein;									// Filename To Open
	char	oneline[255];								// Holds One Line Of Text (255 Chars Max)

	filein = fopen(name, "rt");							// Opens The File For Reading Text In Translated Mode
    if(!filein) {
        printf("failed to open file: %s\n", name);
        exit(0);
    }
														// CTRL Z Symbolizes End Of File In Translated Mode
	readstr(filein,oneline);							// Jumps To Code That Reads One Line Of Text From The File
	sscanf(oneline, "Vertices: %d\n", &ver);			// Scans Text For "Vertices: ".  Number After Is Stored In ver
	k->verts=ver;										// Sets Objects verts Variable To Equal The Value Of ver
	objallocate(k,ver);									// Jumps To Code That Allocates Ram To Hold The Object

	for (int i=0;i<ver;i++)								// Loops Through The Vertices
	{
		readstr(filein,oneline);						// Reads In The Next Line Of Text
		sscanf(oneline, "%f %f %f", &rx, &ry, &rz);		// Searches For 3 Floating Point Numbers, Store In rx,ry & rz
		k->points[i].x = rx;							// Sets Objects (k) points.x Value To rx
		k->points[i].y = ry;							// Sets Objects (k) points.y Value To ry
		k->points[i].z = rz;							// Sets Objects (k) points.z Value To rz
	}
	fclose(filein);										// Close The File

	if(ver>maxver) maxver=ver;							// If ver Is Greater Than maxver Set maxver Equal To ver
}														// Keeps Track Of Highest Number Of Vertices Used In Any Of The
														// Objects
VERTEX calculate(int i)									// Calculates Movement Of Points During Morphing
{
	VERTEX a;											// Temporary Vertex Called a
	a.x=(sour->points[i].x-dest->points[i].x)/steps;	// a.x Value Equals Source x - Destination x Divided By Steps
	a.y=(sour->points[i].y-dest->points[i].y)/steps;	// a.y Value Equals Source y - Destination y Divided By Steps
	a.z=(sour->points[i].z-dest->points[i].z)/steps;	// a.z Value Equals Source z - Destination z Divided By Steps
	return a;											// Return The Results
}														// This Makes Points Move At A Speed So They All Get To Their
														// Destination At The Same Time
void Resize(int width, int height)		// Resize And Initialize The GL Window
{
	if (height==0)										// Prevent A Divide By Zero By
	{
		height=1;										// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

int InitGL(GLvoid)										// All Setup For OpenGL Goes Here
{
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Set The Blending Function For Translucency
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);				// This Will Clear The Background Color To Black
	glClearDepth(1.0);									// Enables Clearing Of The Depth Buffer
	glDepthFunc(GL_LESS);								// The Type Of Depth Test To Do
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glShadeModel(GL_SMOOTH);							// Enables Smooth Color Shading
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations

	maxver=0;											// Sets Max Vertices To 0 By Default
	objload("Data/Sphere.txt",&morph1);					// Load The First Object Into morph1 From File sphere.txt
	objload("Data/Torus.txt",&morph2);					// Load The Second Object Into morph2 From File torus.txt
	objload("Data/Tube.txt",&morph3);					// Load The Third Object Into morph3 From File tube.txt

	objallocate(&morph4,486);							// Manually Reserver Ram For A 4th 468 Vertice Object (morph4)
	for(int i=0;i<486;i++)								// Loop Through All 468 Vertices
	{
		morph4.points[i].x=((float)(rand()%14000)/1000)-7;	// morph4 x Point Becomes A Random Float Value From -7 to 7
		morph4.points[i].y=((float)(rand()%14000)/1000)-7;	// morph4 y Point Becomes A Random Float Value From -7 to 7
		morph4.points[i].z=((float)(rand()%14000)/1000)-7;	// morph4 z Point Becomes A Random Float Value From -7 to 7
	}

	objload("Data/Sphere.txt",&helper);					// Load sphere.txt Object Into Helper (Used As Starting Point)
	sour=dest=&morph1;									// Source & Destination Are Set To Equal First Object (morph1)

	return true;										// Initialization Went OK
}

void DrawGLScene(GLvoid)								// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	glLoadIdentity();									// Reset The View
	glTranslatef(cx,cy,cz);								// Translate The The Current Position To Start Drawing
	glRotatef(xrot,1,0,0);								// Rotate On The X Axis By xrot
	glRotatef(yrot,0,1,0);								// Rotate On The Y Axis By yrot
	glRotatef(zrot,0,0,1);								// Rotate On The Z Axis By zrot

	xrot+=xspeed; yrot+=yspeed; zrot+=zspeed;			// Increase xrot,yrot & zrot by xspeed, yspeed & zspeed

	GLfloat tx,ty,tz;									// Temp X, Y & Z Variables
	VERTEX q;											// Holds Returned Calculated Values For One Vertex

	glBegin(GL_POINTS);									// Begin Drawing Points
		for(int i=0;i<morph1.verts;i++)					// Loop Through All The Verts Of morph1 (All Objects Have
		{												// The Same Amount Of Verts For Simplicity, Could Use maxver Also)
			if(morph) q=calculate(i); else q.x=q.y=q.z=0;	// If morph Is True Calculate Movement Otherwise Movement=0
			helper.points[i].x-=q.x;					// Subtract q.x Units From helper.points[i].x (Move On X Axis)
			helper.points[i].y-=q.y;					// Subtract q.y Units From helper.points[i].y (Move On Y Axis)
			helper.points[i].z-=q.z;					// Subtract q.z Units From helper.points[i].z (Move On Z Axis)
			tx=helper.points[i].x;						// Make Temp X Variable Equal To Helper's X Variable
			ty=helper.points[i].y;						// Make Temp Y Variable Equal To Helper's Y Variable
			tz=helper.points[i].z;						// Make Temp Z Variable Equal To Helper's Z Variable

			glColor3f(0,1,1);							// Set Color To A Bright Shade Of Off Blue
			glVertex3f(tx,ty,tz);						// Draw A Point At The Current Temp Values (Vertex)
			glColor3f(0,0.5f,1);						// Darken Color A Bit
			tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;			// Calculate Two Positions Ahead
			glVertex3f(tx,ty,tz);						// Draw A Second Point At The Newly Calculate Position
			glColor3f(0,0,1);							// Set Color To A Very Dark Blue
			tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;			// Calculate Two More Positions Ahead
			glVertex3f(tx,ty,tz);						// Draw A Third Point At The Second New Position
		}												// This Creates A Ghostly Tail As Points Move
	glEnd();											// Done Drawing Points

	// If We're Morphing And We Haven't Gone Through All 200 Steps Increase Our Step Counter
	// Otherwise Set Morphing To False, Make Source=Destination And Set The Step Counter Back To Zero.
	if(morph && step<=steps)step++; else { morph=false; sour=dest; step=0;}
    glutSwapBuffers();
}

void SpecialFunc(int key, int x, int y) {
    switch(key) {
        case GLUT_KEY_PAGE_UP:								// Is Page Up Being Pressed?
			zspeed+=0.01f;								// Increase zspeed
            break;

        case GLUT_KEY_PAGE_DOWN:								// Is Page Down Being Pressed?
			zspeed-=0.01f;								// Decrease zspeed
            break;

        case GLUT_KEY_DOWN:								// Is Down Being Pressed?
			xspeed+=0.01f;								// Increase xspeed
            break;

        case GLUT_KEY_UP:									// Is Up Being Pressed?
			xspeed-=0.01f;								// Decrease xspeed
            break;

        case GLUT_KEY_RIGHT:								// Is Right Being Pressed?
			yspeed+=0.01f;								// Increase yspeed
            break;

        case GLUT_KEY_LEFT:								// Is Left Being Pressed?
			yspeed-=0.01f;								// Decrease yspeed
            break;
        default:
            break;
    }
}

void KeyFunc(unsigned char key, int x, int y) {
    switch(key) {
        case 'Q':									// Is Q Key Being Pressed?
			 cz-=0.01f;										// Move Object Away From Viewer
             break;

        case 'Z':									// Is Z Key Being Pressed?
			 cz+=0.01f;										// Move Object Towards Viewer
             break;

        case 'W':									// Is W Key Being Pressed?
			 cy+=0.01f;										// Move Object Up
             break;

        case 'S':									// Is S Key Being Pressed?
			 cy-=0.01f;										// Move Object Down
             break;

        case 'D':									// Is D Key Being Pressed?
			 cx+=0.01f;										// Move Object Right
             break;

        case 'A':									// Is A Key Being Pressed?
			 cx-=0.01f;										// Move Object Left
             break;

        case '1': 
            if((key!=1) && !morph)			// Is 1 Pressed, key Not Equal To 1 And Morph False?
			{
				key=1;										// Sets key To 1 (To Prevent Pressing 1 2x In A Row)
				morph=true;									// Set morph To True (Starts Morphing Process)
				dest=&morph1;								// Destination Object To Morph To Becomes morph1
			}
            break;
        case '2': 
            if((key!=2) && !morph)			// Is 2 Pressed, key Not Equal To 2 And Morph False?
			{
				key=2;										// Sets key To 2 (To Prevent Pressing 2 2x In A Row)
				morph=true;									// Set morph To True (Starts Morphing Process)
				dest=&morph2;								// Destination Object To Morph To Becomes morph2
			}
            break;
        case '3': 
            if((key!=3) && !morph)			// Is 3 Pressed, key Not Equal To 3 And Morph False?
			{
				key=3;										// Sets key To 3 (To Prevent Pressing 3 2x In A Row)
				morph=true;									// Set morph To True (Starts Morphing Process)
				dest=&morph3;								// Destination Object To Morph To Becomes morph3
			}
            break;
        case '4': 
            if((key!=4) && !morph)			// Is 4 Pressed, key Not Equal To 4 And Morph False?
			{
				key=4;										// Sets key To 4 (To Prevent Pressing 4 2x In A Row)
				morph=true;									// Set morph To True (Starts Morphing Process)
				dest=&morph4;								// Destination Object To Morph To Becomes morph4
			}
            break;
        case 27:                            // Escape key is pressed
            exit(0);
            break;
        default:
            break;
    }
}

int main(int argc, char **argv)
{
    glutInit(&argc, argv);
    glutInitWindowSize(640, 480);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
	glutCreateWindow("Piotr Cieslak & NeHe's Morphing Points Tutorial");
    glutDisplayFunc(DrawGLScene);
    glutIdleFunc(DrawGLScene);
    glutKeyboardFunc(KeyFunc);
    glutSpecialFunc(SpecialFunc);
    glutReshapeFunc(Resize);
    InitGL();
    glutMainLoop();
    return 0;
}
