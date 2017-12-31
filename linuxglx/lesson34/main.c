/*
 * Nehe Lesson 34 Code (ported to Linux//GLX by Patrick Schubert 2003
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

#define		MAP_SIZE	  1024							/* Size Of Our .RAW Height Map */
#define		STEP_SIZE	  16							/* Width And Height Of Each Quad */
#define		HEIGHT_RATIO  1.5f							/* Ratio That The Y Is Scaled According To The X And Z */

BOOL		bRender = True;								/* Polygon Flag Set To TRUE By Default */

unsigned char g_HeightMap[MAP_SIZE*MAP_SIZE];			/* Holds The Height Map Data */

float scaleValue = 0.15f;								/* Scale Value For The Terrain */


void gluLookAt(GLdouble eyex,GLdouble eyey,GLdouble eyez,
			   GLdouble centerx, GLdouble centery, GLdouble centerz,
			   GLdouble upx,GLdouble upy, GLdouble upz)
{
	GLdouble m[16];
	GLdouble x[3], y[3],z[3];
	GLdouble mag;
	z[0] = eyex - centerx;
	z[1] = eyey - centery;
	z[2] = eyez - centerz;

	if((mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2])))
		z[0] /= mag,z[1] /= mag,z[2] /= mag;

	y[0] = upx;
	y[1] = upy;
	y[2] = upz;
	x[0] = y[1] * z[2] - y[2] * z[1];
	x[1] = -y[0] *z[2] + y[2] * z[0];
	x[2] = y[0] * z[1] - y[1] * z[0];

	y[0] = z[1] * x[2] - z[2] * x[1];
	y[1] = -z[0] * x[2] + z[2] * x[0];
	y[2] = z[0] * x[1] - z[1] * x[0];

	if((mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2])))
		x[0] /= mag,x[1] /= mag,x[2] /= mag;

	if((mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2])))
		y[0] /= mag,y[1] /= mag,y[2] /= mag;

	m[0] = x[0];m[4] = x[1];m[8] = x[2];m[12] = 0.0;
	m[1] = y[0];m[5] = y[1];m[9] = y[2];m[13] = 0.0;
	m[2] = z[0];m[6] = z[1];m[10] = z[2];m[14] = 0.0;
	m[3] = m[7] = m[11] = 0.0;
	m[15] = 1.0;

	glMultMatrixd(m);
	glTranslated(-eyex,-eyey, -eyez);
}

/* Loads The .RAW File And Stores It In pHeightMap */
void LoadRawFile(const char* strName, int nSize,unsigned char *pHeightMap)
{
	int result;
	FILE *pFile = NULL;

	/* Open The File In Read / Binary Mode. */
	pFile = fopen( strName, "rb" );

	/* Check To See If We Found The File And Could Open It */
	if ( pFile == NULL )
	{
		/* Display Error Message And Stop The Function */
		printf("Error can't Find The Height Map!\n");
		return;
	}

	fread( pHeightMap, 1, nSize, pFile );

	/* After We Read The Data, It's A Good Idea To Check If Everything Read Fine */
	result = ferror( pFile );

	/* Check If We Received An Error */
	if (result)
	{
		printf("Error failed To Get Data!\n");
	}

	/* Close The File. */
	fclose(pFile);
}

int Height(unsigned char *pHeightMap, int X, int Y)		/* This Returns The Height From A Height Map Index */
{
	int x = X % MAP_SIZE;								/* Error Check Our x Value */
	int y = Y % MAP_SIZE;								/* Error Check Our y Value */

	if(!pHeightMap) return 0;							/* Make Sure Our Data Is Valid */

	return pHeightMap[x + (y * MAP_SIZE)];				/* Index Into Our Height Array And Return The Height */
}

void SetVertexColor(unsigned char *pHeightMap, int x, int y)	/* Sets The Color Value For A Particular Index, Depending On The Height Index */
{
	if(!pHeightMap)
		return;								/* Make Sure Our Height Data Is Valid */
	else
	{
		float fColor = -0.15f + (Height(pHeightMap, x, y ) / 256.0f);
		/* Assign This Blue Shade To The Current Vertex */
		glColor3f(0, 0, fColor );
	}
}

void RenderHeightMap(unsigned char pHeightMap[])		/* This Renders The Height Map As Quads */
{
	int X = 0, Y = 0;									/* Create Some Variables To Walk The Array With. */
	int x, y, z;										/* Create Some Variables For Readability */

	if(!pHeightMap) return;							/* Make Sure Our Height Data Is Valid */

	if(bRender)											/* What We Want To Render */
		glBegin( GL_QUADS );							/* Render Polygons */
	else
		glBegin( GL_LINES );							/* Render Lines Instead */

	for ( X = 0; X < MAP_SIZE; X += STEP_SIZE )
		for ( Y = 0; Y < MAP_SIZE; Y += STEP_SIZE )
		{
			/* Get The (X, Y, Z) Value For The Bottom Left Vertex */
			x = X;							
			y = Height(pHeightMap, X, Y );
			z = Y;

			/* Set The Color Value Of The Current Vertex */
			SetVertexColor(pHeightMap, x, z);

			glVertex3i(x, y, z);						/* Send This Vertex To OpenGL To Be Rendered (Integer Points Are Faster) */

			/* Get The (X, Y, Z) Value For The Top Left Vertex */
			x = X;										
			y = Height(pHeightMap, X, Y + STEP_SIZE );
			z = Y + STEP_SIZE ;

			/* Set The Color Value Of The Current Vertex */
			SetVertexColor(pHeightMap, x, z);

			glVertex3i(x, y, z);						/* Send This Vertex To OpenGL To Be Rendered */

			/* Get The (X, Y, Z) Value For The Top Right Vertex */
			x = X + STEP_SIZE;
			y = Height(pHeightMap, X + STEP_SIZE, Y + STEP_SIZE );
			z = Y + STEP_SIZE ;

			/* Set The Color Value Of The Current Vertex */
			SetVertexColor(pHeightMap, x, z);
			
			glVertex3i(x, y, z);						/* Send This Vertex To OpenGL To Be Rendered */

			/* Get The (X, Y, Z) Value For The Bottom Right Vertex */
			x = X + STEP_SIZE;
			y = Height(pHeightMap, X + STEP_SIZE, Y ); 
			z = Y;

			/* Set The Color Value Of The Current Vertex */
			SetVertexColor(pHeightMap, x, z);

			glVertex3i(x, y, z);						/* Send This Vertex To OpenGL To Be Rendered */
		}
	glEnd();

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);					/*Reset The Color */
}

int drawGLScene(GLvoid)									/* Here's Where We Do All The Drawing */
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	/* Clear The Screen And The Depth Buffer */
	glLoadIdentity();									/* Reset The Matrix */

	/* 			 Position	      View		Up Vector */
	gluLookAt(212, 60, 194,  186, 55, 171,  0, 1, 0);	/* This Determines Where The Camera's Position And View Is */

	glScalef(scaleValue, scaleValue * HEIGHT_RATIO, scaleValue);

	RenderHeightMap(g_HeightMap);						/* Render The Height Map */

	return True;										/* Keep Going */
}

void update()
{
	if(isKeyDown(WK_UP))						/* Is the UP ARROW key Being Pressed? */
	{
		scaleValue += 0.001f;					/* Increase the scale value to zoom in */
		resetKey(WK_UP);
	}

	if(isKeyDown(WK_DOWN))						/* Is the DOWN ARROW key Being Pressed? */
	{
		scaleValue -= 0.001f;					/* Decrease the scale value to zoom out */
		resetKey(WK_DOWN);
	}

	if(isKeyDown(WK_SPACE))						/* Is SPACE kes being pressed? */
	{
		bRender = !bRender;						/* toggle wireframe/fill mode*/
		resetKey(WK_SPACE);
	}
}

int main(void)
{
	createGLWindow("Nehe's Lesson 34",640,480,24,False); /* Create our window*/

	LoadRawFile("Data/Terrain.raw", MAP_SIZE * MAP_SIZE, g_HeightMap); /* Load raw data */

	run();												/* Start Event-Loop */

	killGLWindow();										/* shutdown window */

	return 0;
}
