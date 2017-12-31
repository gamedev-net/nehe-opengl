/*
 * This code was created by Jeff Molofee '99 (ported to Linux//GLX by Patrick Schubert 2003
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

typedef struct tagMATRIX
{
	float Data[16];
}
MATRIX;

typedef struct tagVECTOR
{
	float X, Y, Z;
}
VECTOR;

typedef struct tagVERTEX
{
	VECTOR Nor;
	VECTOR Pos;
}
VERTEX;

typedef struct tagPOLYGON
{
	VERTEX Verts[3];
}
POLYGON;

BOOL	outlineDraw		= True;
BOOL	outlineSmooth	= False;

float	outlineColor[3]	= { 0.0f, 0.0f, 0.0f };
float	outlineWidth	= 3.0f;

VECTOR	lightAngle;
BOOL	lightRotate		= False;

float	modelAngle		= 0.0f;
BOOL	modelRotate		= False;

POLYGON	*polyData		= NULL;
int		polyNum			= 0;

GLuint	shaderTexture[1];

BOOL ReadMesh()
{
	FILE *In = fopen ("Data/Model.txt", "rb");

	if (!In)
	{
		printf("Error loading file Model.txt: ReadMesh\n");
		return False;
	}

	fread (&polyNum, sizeof (int), 1, In);

	polyData = malloc(sizeof(POLYGON) * polyNum);

	if(NULL == polyData)
	{
		printf("Error allocate polyData memory: ReadMesh\n");
		exit(1);
	}

	fread (&polyData[0], sizeof (POLYGON) * polyNum, 1, In);

	fclose (In);

	return True;
}

float DotProduct (VECTOR *V1, VECTOR *V2)
{
	return V1->X * V2->X + V1->Y * V2->Y + V1->Z * V2->Z;
}

float Magnitude (VECTOR *V)
{
	return sqrt(V->X * V->X + V->Y * V->Y + V->Z * V->Z);
}

void Normalize (VECTOR *V)
{
	float M = Magnitude (V);

	if (M != 0.0f)
	{
		V->X /= M;
		V->Y /= M;
		V->Z /= M;
	}
}

void RotateVector (MATRIX *M, VECTOR *V, VECTOR *D)
{
	D->X = (M->Data[0] * V->X) + (M->Data[4] * V->Y) + (M->Data[8]  * V->Z);
	D->Y = (M->Data[1] * V->X) + (M->Data[5] * V->Y) + (M->Data[9]  * V->Z);
	D->Z = (M->Data[2] * V->X) + (M->Data[6] * V->Y) + (M->Data[10] * V->Z);
}

BOOL Initialize(void)
{
	int i;
	char Line[255];
	float shaderData[32][3];

	FILE *In	= NULL;

	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

	glClearColor (0.7f, 0.7f, 0.7f, 0.0f);
	glClearDepth (1.0f);

	glEnable (GL_DEPTH_TEST);
	glDepthFunc (GL_LESS);

	glShadeModel (GL_SMOOTH);
	glDisable (GL_LINE_SMOOTH);

	glEnable (GL_CULL_FACE);

	glDisable (GL_LIGHTING);

	In = fopen ("Data/Shader.txt", "r");

	if (In)
	{
		for (i = 0; i < 32; i++)
		{
			if (feof (In))
				break;

			fgets (Line, 255, In);

			shaderData[i][0] = shaderData[i][1] = shaderData[i][2] = (float)(atof (Line));
		}

		fclose (In);
	}
	else
	{
		printf("Error loading file Shader.txt: Initialize\n");
		return False;
	}
	glGenTextures (1, &shaderTexture[0]);

	glBindTexture (GL_TEXTURE_1D, shaderTexture[0]);

	glTexParameteri (GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri (GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

	glTexImage1D (GL_TEXTURE_1D, 0, GL_RGB, 32, 0, GL_RGB , GL_FLOAT, shaderData);

	lightAngle.X = 0.0f;
	lightAngle.Y = 0.0f;
	lightAngle.Z = 1.0f;

	Normalize (&lightAngle);

	return ReadMesh ();
}

void Deinitialize (void)
{
	glDeleteTextures (1, &shaderTexture[0]);

	free(polyData);
}

void update(float elapsed)
{
	if(isKeyDown(WK_1))
	{
		outlineDraw = outlineDraw == True ? False : True;
		resetKey(WK_1);
	}

	if(isKeyDown(WK_2))
	{
		outlineSmooth = outlineSmooth == True ? False : True;
		resetKey(WK_2);
	}

	if(isKeyDown(WK_UP))
	{
		outlineWidth++;
		resetKey(WK_UP);
	}

	if(isKeyDown(WK_DOWN))
	{
		outlineWidth--;
		resetKey(WK_DOWN);
	}

	if(isKeyDown(WK_SPACE))
	{
		modelRotate = modelRotate == True ? False : True;
		resetKey(WK_SPACE);
	}

	if(True == modelRotate)
		modelAngle += (elapsed * 25.0f);
}

void drawGLScene(void)
{
	int i, j;

	float TmpShade;

	MATRIX TmpMatrix;
	VECTOR TmpVector, TmpNormal;

	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity ();

	if (True == outlineSmooth)
	{
		glHint (GL_LINE_SMOOTH_HINT, GL_NICEST);
		glEnable (GL_LINE_SMOOTH);
	}
	else
		glDisable (GL_LINE_SMOOTH);

	glTranslatef (0.0f, 0.0f, -2.0f);
	glRotatef (modelAngle, 0.0f, 1.0f, 0.0f);

	glGetFloatv (GL_MODELVIEW_MATRIX, TmpMatrix.Data);

	glEnable (GL_TEXTURE_1D);
	glBindTexture (GL_TEXTURE_1D, shaderTexture[0]);

	glColor3f (1.0f, 1.0f, 1.0f);

	glBegin (GL_TRIANGLES);

	for (i = 0; i < polyNum; i++)
	{
		for (j = 0; j < 3; j++)
		{
			TmpNormal.X = polyData[i].Verts[j].Nor.X;
			TmpNormal.Y = polyData[i].Verts[j].Nor.Y;
			TmpNormal.Z = polyData[i].Verts[j].Nor.Z;

			RotateVector (&TmpMatrix, &TmpNormal, &TmpVector);

			Normalize (&TmpVector);

			TmpShade = DotProduct (&TmpVector,&lightAngle);

			if (TmpShade < 0.0f)
				TmpShade = 0.0f;

			glTexCoord1f (TmpShade);
			glVertex3fv (&polyData[i].Verts[j].Pos.X);
		}
	}

	glEnd ();

	glDisable (GL_TEXTURE_1D);

	if (True == outlineDraw)
	{
		glEnable (GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

		glPolygonMode (GL_BACK, GL_LINE);
		glLineWidth (outlineWidth);

		glCullFace (GL_FRONT);

		glDepthFunc (GL_LEQUAL);

		glColor3fv (&outlineColor[0]);

		glBegin (GL_TRIANGLES);

		for (i = 0; i < polyNum; i++)
		{
			for (j = 0; j < 3; j++)
			{
				glVertex3fv (&polyData[i].Verts[j].Pos.X);
			}
		}

		glEnd ();

		glDepthFunc (GL_LESS);

		glCullFace (GL_BACK);

		glPolygonMode (GL_BACK, GL_FILL);

		glDisable (GL_BLEND);
	}
}

int main(void)
{
	createGLWindow("NeHe's Lesson 37",640,480,24,False);

	Initialize();

	run();

	Deinitialize();

	killGLWindow();

	return 0;
}
