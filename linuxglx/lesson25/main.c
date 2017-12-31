/*
 * Nehe Lesson 25 Code (ported to Linux//GLX by Patrick Schubert 2003
 * with help from the lesson 1 basecode for Linux/GLX by Mihael Vrbanec)
 */

#include "nehe.h"
#include <GL/glx.h>
#include <GL/gl.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

BOOL		active = True;								/* Program's Active */
BOOL		fullscreen = True;							/* Default Fullscreen To True */

GLfloat		xrot,yrot,zrot,								/* X, Y & Z Rotation */
			xspeed,yspeed,zspeed,						/* X, Y & Z Spin Speed */
			cx,cy,cz = -15;								/* X, Y & Z Position */

int			key = 1;									/* Used To Make Sure Same Morph Key Is Not Pressed */
int			step = 0,steps = 200;						/* Step Counter And Maximum Number Of Steps */
BOOL		morph = False;								/* Default morph To False (Not Morphing) */

typedef struct											/* Structure For 3D Points */
{
	float	x, y, z;									/* X, Y & Z Points */
} VERTEX;												/* Called VERTEX */

typedef struct											/* Structure For An Object */
{
 int		verts;										/* Number Of Vertices For The Object */
 VERTEX		*points;									/* One Vertice (Vertex x,y & z) */
} OBJECT;												/* Called OBJECT */

int			maxver;										/* Will Eventually Hold The Maximum Number Of Vertices */
OBJECT		morph1,morph2,morph3,morph4,				/* Our 4 Morphable Objects (morph1,2,3 & 4) */
			helper,*sour,*dest;							/* Helper Object, Source Object, Destination Object */

void objallocate(OBJECT *k,int n)						/* Allocate Memory For Each Object */
{														/* And Defines points */
	k->points = malloc(sizeof(VERTEX)*n);				/* Sets points Equal To VERTEX * Number Of Vertices */
}														/* (3 Points For Each Vertice) */

void objfree(OBJECT *k)									/* Frees The Object (Releasing The Memory) */
{
	free(k->points);									/* Frees Points */
}

void readstr(FILE *f,char *string)						/* Reads A String From File (f) */
{
	do													/* Do This */
	{
		fgets(string, 255, f);							/* Gets A String Of 255 Chars Max From f (File) */
	}while ((string[0] == '/') || (string[0] == '\n'));/* Until End Of Line Is Reached */
	return;												/* Return */
}

void objload(const char *name,OBJECT *k)				/* Loads Object From File (name) */
{
	int 	i;											/* Loop index */
	int		ver;										/* Will Hold Vertice Count */
	float	rx,ry,rz;									/* Hold Vertex X, Y & Z Position */
	FILE	*filein;									/* Filename To Open */
	char	oneline[255];								/* Holds One Line Of Text (255 Chars Max) */

	filein = fopen(name, "rt");							/* Opens The File For Reading Text In Translated Mode */

	if(NULL == filein)									/* Test if file opening failed */
	{
		printf("Error loading file %s: objload\n",name);
		exit(1);										/* exit */
	}
														/* CTRL Z Symbolizes End Of File In Translated Mode */
	readstr(filein,oneline);							/* Jumps To Code That Reads One Line Of Text From The File */
	sscanf(oneline, "Vertices: %d\n", &ver);			/* Scans Text For "Vertices: ".  Number After Is Stored In ver */
	k->verts=ver;										/* Sets Objects verts Variable To Equal The Value Of ver */
	objallocate(k,ver);									/* Jumps To Code That Allocates Ram To Hold The Object */

	for(i = 0;i < ver;i++)								/* Loops Through The Vertices */
	{
		readstr(filein,oneline);						/* Reads In The Next Line Of Text */
		sscanf(oneline, "%f %f %f", &rx, &ry, &rz);		/* Searches For 3 Floating Point Numbers, Store In rx,ry & rz */
		k->points[i].x = rx;							/* Sets Objects (k) points.x Value To rx */
		k->points[i].y = ry;							/* Sets Objects (k) points.y Value To ry */
		k->points[i].z = rz;							/* Sets Objects (k) points.z Value To rz */
	}
	fclose(filein);										/* Close The File */

	if(ver > maxver)									/* If ver Is Greater Than maxver Set maxver Equal To ver */
		maxver = ver;									/* Keeps Track Of Highest Number Of Vertices Used In Any Of The Objects */
}
VERTEX calculate(int i)									/* Calculates Movement Of Points During Morphing */
{
	VERTEX a;											/* Temporary Vertex Called a */
	a.x=(sour->points[i].x-dest->points[i].x)/steps;	/* a.x Value Equals Source x - Destination x Divided By Steps */
	a.y=(sour->points[i].y-dest->points[i].y)/steps;	/* a.y Value Equals Source y - Destination y Divided By Steps */
	a.z=(sour->points[i].z-dest->points[i].z)/steps;	/* a.z Value Equals Source z - Destination z Divided By Steps */
	return a;											/* Return The Results */
}

int Initialize(GLvoid)									/* All Setup For OpenGL Goes Here */
{
	int 	i;											/* Loop index */
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);					/* Set The Blending Function For Translucency */
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);				/* This Will Clear The Background Color To Black */
	glClearDepth(1.0);									/* Enables Clearing Of The Depth Buffer */
	glDepthFunc(GL_LESS);								/* The Type Of Depth Test To Do */
	glEnable(GL_DEPTH_TEST);							/* Enables Depth Testing */
	glShadeModel(GL_SMOOTH);							/* Enables Smooth Color Shading */
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	/* Really Nice Perspective Calculations */

	maxver=0;											/* Sets Max Vertices To 0 By Default */
	objload("data/Sphere.txt",&morph1);					/* Load The First Object Into morph1 From File sphere.txt */
	objload("data/Torus.txt",&morph2);					/* Load The Second Object Into morph2 From File torus.txt */
	objload("data/Tube.txt",&morph3);					/* Load The Third Object Into morph3 From File tube.txt */

	objallocate(&morph4,486);							/* Manually Reserver Ram For A 4th 468 Vertice Object (morph4) */
	for(i = 0;i < 486;i++)									/* Loop Through All 468 Vertices */
	{
		morph4.points[i].x=((float)(rand()%14000)/1000)-7;	/* morph4 x Point Becomes A Random Float Value From -7 to 7 */
		morph4.points[i].y=((float)(rand()%14000)/1000)-7;	/* morph4 y Point Becomes A Random Float Value From -7 to 7 */
		morph4.points[i].z=((float)(rand()%14000)/1000)-7;	/* morph4 z Point Becomes A Random Float Value From -7 to 7 */
	}

	objload("data/Sphere.txt",&helper);					/* Load sphere.txt Object Into Helper (Used As Starting Point) */
	sour = dest = &morph1;								/* Source & Destination Are Set To Equal First Object (morph1) */

	return True;										/* Initialization Went OK */
}

void Deinitialize(void)									/* Release allocated memory */
{
	objfree(&morph1);									/* Jump To Code To Release morph1 Allocated Ram */
	objfree(&morph2);									/* Jump To Code To Release morph2 Allocated Ram */
	objfree(&morph3);									/* Jump To Code To Release morph3 Allocated Ram */
	objfree(&morph4);									/* Jump To Code To Release morph4 Allocated Ram */
	objfree(&helper);									/* Jump To Code To Release helper Allocated Ram */
}

void drawGLScene(void)									/* Here's Where We Do All The Drawing */
{
	int i;												/* Loop index */
	GLfloat tx,ty,tz;									/* Temp X, Y & Z Variables */
	VERTEX q;											/* Holds Returned Calculated Values For One Vertex */

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	/* Clear The Screen And The Depth Buffer */
	glLoadIdentity();									/* Reset The View */
	glTranslatef(cx,cy,cz);								/* Translate The The Current Position To Start Drawing */
	glRotatef(xrot,1,0,0);								/* Rotate On The X Axis By xrot */
	glRotatef(yrot,0,1,0);								/* Rotate On The Y Axis By yrot */
	glRotatef(zrot,0,0,1);								/* Rotate On The Z Axis By zrot */

	xrot += xspeed;yrot += yspeed;zrot += zspeed;		/* Increase xrot,yrot & zrot by xspeed, yspeed & zspeed */

	glBegin(GL_POINTS);									/* Begin Drawing Points */
	for(i = 0;i < morph1.verts;i++)						/* Loop Through All The Verts Of morph1 (All Objects Have */
	{													/* The Same Amount Of Verts For Simplicity, Could Use maxver Also) */
		if(morph) q=calculate(i); else q.x=q.y=q.z=0;	/* If morph Is True Calculate Movement Otherwise Movement=0 */
		helper.points[i].x-=q.x;						/* Subtract q.x Units From helper.points[i].x (Move On X Axis) */
		helper.points[i].y-=q.y;						/* Subtract q.y Units From helper.points[i].y (Move On Y Axis) */
		helper.points[i].z-=q.z;						/* Subtract q.z Units From helper.points[i].z (Move On Z Axis) */
		tx=helper.points[i].x;							/* Make Temp X Variable Equal To Helper's X Variable */
		ty=helper.points[i].y;							/* Make Temp Y Variable Equal To Helper's Y Variable */
		tz=helper.points[i].z;							/* Make Temp Z Variable Equal To Helper's Z Variable */

		glColor3f(0,1,1);								/* Set Color To A Bright Shade Of Off Blue */
		glVertex3f(tx,ty,tz);							/* Draw A Point At The Current Temp Values (Vertex) */
		glColor3f(0,0.5f,1);							/* Darken Color A Bit */
		tx -= 2*q.x;ty -= 2*q.y;ty -= 2*q.y;			/* Calculate Two Positions Ahead */
		glVertex3f(tx,ty,tz);							/* Draw A Second Point At The Newly Calculate Position */
		glColor3f(0,0,1);								/* Set Color To A Very Dark Blue */
		tx -= 2*q.x;ty -= 2*q.y;ty -= 2*q.y;			/* Calculate Two More Positions Ahead */
		glVertex3f(tx,ty,tz);							/* Draw A Third Point At The Second New Position */
	}													/* This Creates A Ghostly Tail As Points Move */
	glEnd();											/* Done Drawing Points */

	/* If We're Morphing And We Haven't Gone Through All 200 Steps Increase Our Step Counter
	   Otherwise Set Morphing To False, Make Source=Destination And Set The Step Counter Back To Zero. */
	if(morph && step <= steps)
		step++;
	else
	{
		morph = False;
		sour = dest;
		step = 0;
	}
}

void update(float elapsed)
{
	if(isKeyDown(WK_PRIOR))								/* Is Page Up Being Pressed? */
	{
		zspeed+=0.01f;									/* Increase zspeed */
		resetKey(WK_PRIOR);								/* Uncheck key */
	}

	if(isKeyDown(WK_NEXT))								/* Is Page Down Being Pressed? */
	{
		zspeed-=0.01f;									/* Decrease zspeed */
		resetKey(WK_NEXT);								/* Uncheck key */
	}

	if(isKeyDown(WK_DOWN))								/* Is Page Up Being Pressed? */
	{
		xspeed+=0.01f;									/* Increase xspeed */
		resetKey(WK_DOWN);								/* Uncheck key */
	}

	if(isKeyDown(WK_UP))								/* Is Page Up Being Pressed? */
	{
		xspeed-=0.01f;									/* Decrease xspeed */
		resetKey(WK_UP);								/* Uncheck key */
	}

	if(isKeyDown(WK_RIGHT))								/* Is Page Up Being Pressed? */
	{
		yspeed+=0.01f;									/* Increase yspeed */
		resetKey(WK_RIGHT);								/* Uncheck key */
	}

	if(isKeyDown(WK_LEFT))								/* Is Page Up Being Pressed? */
	{
	 	yspeed-=0.01f;									/* Decrease yspeed */
		resetKey(WK_LEFT);								/* Uncheck key */
	}

	if(isKeyDown(WK_Q))									/* Is Q Key Being Pressed? */
	{
		cz-=0.01f;										/* Move Object Away From Viewer */
		resetKey(WK_Q);									/* Uncheck key */
	}

	if(isKeyDown(WK_Z))									/* Is Z Key Being Pressed? */
	{
		cz+=0.01f;										/* Move Object Towards Viewer */
		resetKey(WK_Z);									/* Uncheck key */
	}

	if(isKeyDown(WK_W))									/* Is W Key Being Pressed? */
	{
		cy+=0.01f;										/* Move Object Up */
		resetKey(WK_W);									/* Uncheck key */
	}

	if(isKeyDown(WK_S))									/* Is S Key Being Pressed? */
	{
		cy-=0.01f;										/* Move Object Down */
		resetKey(WK_S);									/* Uncheck key */
	}

	if(isKeyDown(WK_D))									/* Is D Key Being Pressed? */
	{
		cx+=0.01f;										/* Move Object Right */
		resetKey(WK_D);									/* Uncheck key */
	}

	if(isKeyDown(WK_A))									/* Is A Key Being Pressed? */
	{
		cx-=0.01f;										/* Move Object Left */
		resetKey(WK_A);									/* Uncheck key */
	}

	if(isKeyDown(WK_1) && !morph)						/* Is 1 Pressed, key Not Equal To 1 And Morph False? */
	{
		morph = True;									/* Set morph To True (Starts Morphing Process) */
		dest = &morph1;									/* Destination Object To Morph To Becomes morph1 */
		resetKey(WK_1);									/* Uncheck key */
	}

	if(isKeyDown(WK_2) && !morph)						/* Is 2 Pressed, key Not Equal To 2 And Morph False? */
	{
		morph = True;									/* Set morph To True (Starts Morphing Process) */
		dest = &morph2;									/* Destination Object To Morph To Becomes morph2 */
		resetKey(WK_2);									/* Uncheck key */
	}

	if(isKeyDown(WK_3) && !morph)						/* Is 3 Pressed, key Not Equal To 3 And Morph False? */
	{
		morph = True;									/* Set morph To True (Starts Morphing Process) */
		dest = &morph3;									/* Destination Object To Morph To Becomes morph3 */
		resetKey(WK_3);									/* Uncheck key */
	}

	if(isKeyDown(WK_4) && !morph)						/* Is 4 Pressed, key Not Equal To 4 And Morph False? */
	{
		morph = True;									/* Set morph To True (Starts Morphing Process) */
		dest = &morph4;									/* Destination Object To Morph To Becomes morph4 */
		resetKey(WK_4);									/* Uncheck key */
	}
}

int main(void)
{
	createGLWindow("Piotr Cieslak & NeHe's Morphing Points Tutorial",640,480,24,False); /* Create our window*/

	Initialize(); 										/* Init Opengl*/

	run();												/* Start Event-Loop */

 	Deinitialize();										/* Release memory */

	killGLWindow();										/* shutdown window */

	return 0;
}
