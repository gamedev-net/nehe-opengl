/*
 * Nehe Lesson 33 Code (ported to Linux//GLX by Patrick Schubert 2003
 * with help from the lesson 1 basecode for Linux/GLX by Mihael Vrbanec)
 */

#include "nehe.h"
#include "Texture.h"
#include <GL/glx.h>
#include <GL/gl.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

BOOL LoadTGA(Texture *,const char *);							/* Function Prototype For LoadTGA */

float	spin;													/* Spin Variable */

Texture texture[2];												/* Storage For 2 Textures */

int LoadGLTextures(void)										/* Load Bitmaps And Convert To Textures */
{
	int Stat = False;											/* Status Indicator */
	int loop;													/* Loop index */

	/* Load The Bitmap, Check For Errors. */
	if (LoadTGA(&texture[0], "Data/Uncompressed.tga") &&
		LoadTGA(&texture[1], "Data/Compressed.tga"))
	{
		Stat = True;											/* Set The Status To True */

		for(loop = 0;loop < 2;loop++)							/* Loop Through Both Textures */
		{
			/* Typical Texture Generation Using Data From The TGA */
			glGenTextures(1, &texture[loop].texID);				/* Create The Texture */
			glBindTexture(GL_TEXTURE_2D, texture[loop].texID);
			glTexImage2D(GL_TEXTURE_2D, 0, 3, texture[loop].width, texture[loop].height, 0, GL_RGB, 									 GL_UNSIGNED_BYTE, texture[loop].imageData);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

			if (texture[loop].imageData)						/* If Texture Image Exists */
			{
				free(texture[loop].imageData);					/* Free The Texture Image Memory */
			}
		}
	}
	return Stat;												/* Return The Status */
}


int drawGLScene(GLvoid)											/* Here's Where We Do All The Drawing */
{
	int loop;
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);			/* Clear The Screen And The Depth Buffer */
	glLoadIdentity();											/* Reset The Modelview Matrix */
	glTranslatef(0.0f,0.0f,-10.0f);								/* Translate 20 Units Into The Screen */

	spin += 0.05f;												/* Increase Spin */

	for(loop = 0;loop < 20;loop++)								/* Loop Of 20 */
	{
		glPushMatrix();											/* Push The Matrix */
		glRotatef(spin+loop*18.0f,1.0f,0.0f,0.0f);				/* Rotate On The X-Axis (Up - Down) */
		glTranslatef(-2.0f,2.0f,0.0f);							/* Translate 2 Units Left And 2 Up */

		glBindTexture(GL_TEXTURE_2D, texture[0].texID);
		glBegin(GL_QUADS);										/* Draw Our Quad */
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, 0.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, 0.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, 0.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, 0.0f);
		glEnd();												/* Done Drawing The Quad */
		glPopMatrix();											/* Pop The Matrix */

		glPushMatrix();											/* Push The Matrix */
		glTranslatef(2.0f,0.0f,0.0f);							/* Translate 2 Units To The Right */
		glRotatef(spin+loop*36.0f,0.0f,1.0f,0.0f);				/* Rotate On The Y-Axis (Left - Right) */
		glTranslatef(1.0f,0.0f,0.0f);							/* Move One Unit Right */

		glBindTexture(GL_TEXTURE_2D, texture[1].texID);
		glBegin(GL_QUADS);										/* Draw Our Quad */
			glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f, 0.0f);
			glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f, 0.0f);
			glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f, -1.0f, 0.0f);
			glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f, -1.0f, 0.0f);
		glEnd();												/* Done Drawing The Quad */
		glPopMatrix();											/* Pop The Matrix */
	}
	return True;												/* Keep Going */
}

int main(void)
{
	createGLWindow("NeHe's Lesson 33",640,480,24,False); 		/* Create our window*/

	run();														/* Start Event-Loop */

	killGLWindow();												/* shutdown window */

	return 0;
}
