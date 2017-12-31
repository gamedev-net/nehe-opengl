#if !defined(_3DOBJECT_H_)
#define _3DOBJECT_H_

#include <stdio.h>

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

// load object
inline int ReadObject(char *st, glObject *o){
  FILE *file;
  unsigned int i;

  file = fopen(st, "r");
  if (!file) return FALSE;
  //points
  fscanf(file, "%d", &(o->nPoints));
  for (i=1;i<=o->nPoints;i++){
    fscanf(file, "%f", &(o->points[i].x));
    fscanf(file, "%f", &(o->points[i].y));
    fscanf(file, "%f", &(o->points[i].z));
  }
  //planes
  fscanf(file, "%d", &(o->nPlanes));
  for (i=0;i<o->nPlanes;i++){
    fscanf(file, "%d", &(o->planes[i].p[0]));
    fscanf(file, "%d", &(o->planes[i].p[1]));
    fscanf(file, "%d", &(o->planes[i].p[2]));

    fscanf(file, "%f", &(o->planes[i].normals[0].x));
    fscanf(file, "%f", &(o->planes[i].normals[0].y));
    fscanf(file, "%f", &(o->planes[i].normals[0].z));
    fscanf(file, "%f", &(o->planes[i].normals[1].x));
    fscanf(file, "%f", &(o->planes[i].normals[1].y));
    fscanf(file, "%f", &(o->planes[i].normals[1].z));
    fscanf(file, "%f", &(o->planes[i].normals[2].x));
    fscanf(file, "%f", &(o->planes[i].normals[2].y));
    fscanf(file, "%f", &(o->planes[i].normals[2].z));
  }
  return TRUE;
}

// connectivity procedure - based on Gamasutra's article
// hard to explain here
inline void SetConnectivity(glObject *o){
	unsigned int p1i, p2i, p1j, p2j;
	unsigned int P1i, P2i, P1j, P2j;
	unsigned int i,j,ki,kj;

	for(i=0;i<o->nPlanes-1;i++)
		for(j=i+1;j<o->nPlanes;j++)
			for(ki=0;ki<3;ki++)
				if(!o->planes[i].neigh[ki]){
					for(kj=0;kj<3;kj++){
						p1i=ki;
						p1j=kj;
						p2i=(ki+1)%3;
						p2j=(kj+1)%3;

						p1i=o->planes[i].p[p1i];
						p2i=o->planes[i].p[p2i];
						p1j=o->planes[j].p[p1j];
						p2j=o->planes[j].p[p2j];

						P1i=((p1i+p2i)-abs(p1i-p2i))/2;
						P2i=((p1i+p2i)+abs(p1i-p2i))/2;
						P1j=((p1j+p2j)-abs(p1j-p2j))/2;
						P2j=((p1j+p2j)+abs(p1j-p2j))/2;

						if((P1i==P1j) && (P2i==P2j)){  //they are neighbours
							o->planes[i].neigh[ki] = j+1;	  
							o->planes[j].neigh[kj] = i+1;	  
						}
					}
				}
}

// function for computing a plane equation given 3 points
inline void CalcPlane(glObject o, sPlane *plane){
	sPoint v[4];
	int i;

	for (i=0;i<3;i++){
		v[i+1].x = o.points[plane->p[i]].x;
		v[i+1].y = o.points[plane->p[i]].y;
		v[i+1].z = o.points[plane->p[i]].z;
	}
	plane->PlaneEq.a = v[1].y*(v[2].z-v[3].z) + v[2].y*(v[3].z-v[1].z) + v[3].y*(v[1].z-v[2].z);
	plane->PlaneEq.b = v[1].z*(v[2].x-v[3].x) + v[2].z*(v[3].x-v[1].x) + v[3].z*(v[1].x-v[2].x);
	plane->PlaneEq.c = v[1].x*(v[2].y-v[3].y) + v[2].x*(v[3].y-v[1].y) + v[3].x*(v[1].y-v[2].y);
	plane->PlaneEq.d =-( v[1].x*(v[2].y*v[3].z - v[3].y*v[2].z) +
					  v[2].x*(v[3].y*v[1].z - v[1].y*v[3].z) +
					  v[3].x*(v[1].y*v[2].z - v[2].y*v[1].z) );
}

// procedure for drawing the object - very simple
void DrawGLObject(glObject o){
	unsigned int i, j;

	glBegin(GL_TRIANGLES);
	for (i=0; i<o.nPlanes; i++){
		for (j=0; j<3; j++){
			glNormal3f(o.planes[i].normals[j].x,
					o.planes[i].normals[j].y,
					o.planes[i].normals[j].z);
			glVertex3f(o.points[o.planes[i].p[j]].x,
					o.points[o.planes[i].p[j]].y,
					o.points[o.planes[i].p[j]].z);
		}
	}
	glEnd();
}

void  CastShadow(glObject *o, float *lp){
	unsigned int	i, j, k, jj;
	unsigned int	p1, p2;
	sPoint			v1, v2;
	float			side;

	//set visual parameter
	for (i=0;i<o->nPlanes;i++){
		// chech to see if light is in front or behind the plane (face plane)
		side =	o->planes[i].PlaneEq.a*lp[0]+
				o->planes[i].PlaneEq.b*lp[1]+
				o->planes[i].PlaneEq.c*lp[2]+
				o->planes[i].PlaneEq.d*lp[3];
		if (side >0) o->planes[i].visible = TRUE;
				else o->planes[i].visible = FALSE;
	}

 	glDisable(GL_LIGHTING);
	glDepthMask(GL_FALSE);
	glDepthFunc(GL_LEQUAL);

	glEnable(GL_STENCIL_TEST);
	glColorMask(0, 0, 0, 0);
	glStencilFunc(GL_ALWAYS, 1, 0xffffffff);

	// first pass, stencil operation decreases stencil value
	glFrontFace(GL_CCW);
	glStencilOp(GL_KEEP, GL_KEEP, GL_INCR);
	for (i=0; i<o->nPlanes;i++){
		if (o->planes[i].visible)
			for (j=0;j<3;j++){
				k = o->planes[i].neigh[j];
				if ((!k) || (!o->planes[k-1].visible)){
					// here we have an edge, we must draw a polygon
					p1 = o->planes[i].p[j];
					jj = (j+1)%3;
					p2 = o->planes[i].p[jj];

					//calculate the length of the vector
					v1.x = (o->points[p1].x - lp[0])*100;
					v1.y = (o->points[p1].y - lp[1])*100;
					v1.z = (o->points[p1].z - lp[2])*100;

					v2.x = (o->points[p2].x - lp[0])*100;
					v2.y = (o->points[p2].y - lp[1])*100;
					v2.z = (o->points[p2].z - lp[2])*100;
					
					//draw the polygon
					glBegin(GL_TRIANGLE_STRIP);
						glVertex3f(o->points[p1].x,
									o->points[p1].y,
									o->points[p1].z);
						glVertex3f(o->points[p1].x + v1.x,
									o->points[p1].y + v1.y,
									o->points[p1].z + v1.z);

						glVertex3f(o->points[p2].x,
									o->points[p2].y,
									o->points[p2].z);
						glVertex3f(o->points[p2].x + v2.x,
									o->points[p2].y + v2.y,
									o->points[p2].z + v2.z);
					glEnd();
				}
			}
	}

	// second pass, stencil operation increases stencil value
	glFrontFace(GL_CW);
	glStencilOp(GL_KEEP, GL_KEEP, GL_DECR);
	for (i=0; i<o->nPlanes;i++){
		if (o->planes[i].visible)
			for (j=0;j<3;j++){
				k = o->planes[i].neigh[j];
				if ((!k) || (!o->planes[k-1].visible)){
					// here we have an edge, we must draw a polygon
					p1 = o->planes[i].p[j];
					jj = (j+1)%3;
					p2 = o->planes[i].p[jj];

					//calculate the length of the vector
					v1.x = (o->points[p1].x - lp[0])*100;
					v1.y = (o->points[p1].y - lp[1])*100;
					v1.z = (o->points[p1].z - lp[2])*100;

					v2.x = (o->points[p2].x - lp[0])*100;
					v2.y = (o->points[p2].y - lp[1])*100;
					v2.z = (o->points[p2].z - lp[2])*100;
					
					//draw the polygon
					glBegin(GL_TRIANGLE_STRIP);
						glVertex3f(o->points[p1].x,
									o->points[p1].y,
									o->points[p1].z);
						glVertex3f(o->points[p1].x + v1.x,
									o->points[p1].y + v1.y,
									o->points[p1].z + v1.z);

						glVertex3f(o->points[p2].x,
									o->points[p2].y,
									o->points[p2].z);
						glVertex3f(o->points[p2].x + v2.x,
									o->points[p2].y + v2.y,
									o->points[p2].z + v2.z);
					glEnd();
				}
			}
	}

	glFrontFace(GL_CCW);
	glColorMask(1, 1, 1, 1);

	//draw a shadowing rectangle covering the entire screen
	glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glStencilFunc(GL_NOTEQUAL, 0, 0xffffffff);
	glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
	glPushMatrix();
	glLoadIdentity();
	glBegin(GL_TRIANGLE_STRIP);
		glVertex3f(-0.1f, 0.1f,-0.10f);
		glVertex3f(-0.1f,-0.1f,-0.10f);
		glVertex3f( 0.1f, 0.1f,-0.10f);
		glVertex3f( 0.1f,-0.1f,-0.10f);
	glEnd();
	glPopMatrix();
	glDisable(GL_BLEND);

	glDepthFunc(GL_LEQUAL);
	glDepthMask(GL_TRUE);
	glEnable(GL_LIGHTING);
	glDisable(GL_STENCIL_TEST);
	glShadeModel(GL_SMOOTH);
}

#endif // _3DOBJECT_H_