#if !defined(_3DOBJECT_H_)
#define _3DOBJECT_H_

#include <stdio.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

// vertex in 3d-coordinate system
struct sPoint{
	float x, y, z;
};

// plane equation
struct sPlaneEq{
	float a, b, c, d;
};

// structure describing an object's face
struct sPlane{
	unsigned int p[3];
	sPoint normals[3];
	unsigned int neigh[3];
	sPlaneEq PlaneEq;
	bool visible;
};

// object structure
struct glObject{
	GLuint nPlanes, nPoints;
	sPoint points[100];
	sPlane planes[200];
};

int ReadObject(const char *st, glObject *o);
void SetConnectivity(glObject *o);
void CalcPlane(glObject o, sPlane *plane);
void DrawGLObject(glObject o);
void  CastShadow(glObject *o, float *lp);

#endif // _3DOBJECT_H_
