
#ifndef _LESSON27WIDGET_H_
#define _LESSON27WIDGET_H_


#include <stdlib.h>
#include <stdarg.h>
#include <sys/time.h>
#include <math.h>

#include <qgl.h>
#include <qwidget.h>

namespace NeHe {

typedef float GLvector4f[4];							// Typedef's For VMatMult Procedure
typedef float GLmatrix16f[16];							// Typedef's For VMatMult Procedure

// To encapsulate access to arrays that store four values.	
struct sQuad
{
	float values_[4];

	sQuad() {};
	sQuad( float v1, float v2, float v3, float v4 ) {
		values_[0]=v1; values_[1]=v2; values_[2]=v3; values_[3]=v4;
	}

	float &operator[](int i) { return values_[i]; }
};

// vertex in 3d-coordinate system
struct sPoint
{
	union {
		struct {
			float x;
			float y;
			float z;
		};
		float coor[3];
	};

	sPoint() {};
	sPoint( float x1, float y1, float z1 ) {
		x = x1; y = y1; z = z1;
	}

	GLfloat& operator[](int d) { return coor[d]; }
};

// plane equation
struct sPlaneEq
{
	float a, b, c, d;
};

// structure describing an object's face
struct sPlane{
	unsigned int p[3];
	sPoint normals[3];
	unsigned int neigh[3];
	sPlaneEq PlaneEq;
	bool visible;

	sPlane::sPlane() { memset( neigh, 0, sizeof neigh ); }
};

// object structure
struct glObject
{
	GLuint nPlanes, nPoints;
	sPoint points[100];
	sPlane planes[200];

	bool ReadObject( const char *pFile )
	{
  		FILE *file;
  		unsigned int i;

  		file = fopen( pFile, "r");
  		if ( !file ) return false;
  		//points
  		fscanf(file, "%d", &nPoints );
  		for (i=1 ; i<=nPoints ; i++){
    		fscanf( file, "%f", &points[i].x );
    		fscanf( file, "%f", &points[i].y );
    		fscanf( file, "%f", &points[i].z );
  		}
  		//planes
  		fscanf(file, "%d", &nPlanes );
  		for (i=0 ; i<nPlanes;i++){
    		fscanf(file, "%d", &planes[i].p[0] );
    		fscanf(file, "%d", &planes[i].p[1] );
    		fscanf(file, "%d", &planes[i].p[2] );

    		fscanf(file, "%f", &planes[i].normals[0].x );
    		fscanf(file, "%f", &planes[i].normals[0].y );
    		fscanf(file, "%f", &planes[i].normals[0].z );
    		fscanf(file, "%f", &planes[i].normals[1].x );
    		fscanf(file, "%f", &planes[i].normals[1].y );
    		fscanf(file, "%f", &planes[i].normals[1].z );
   	 	fscanf(file, "%f", &planes[i].normals[2].x );
    		fscanf(file, "%f", &planes[i].normals[2].y );
    		fscanf(file, "%f", &planes[i].normals[2].z );
  		}
		return true;
	}
};

class Lesson27Widget : public QGLWidget
{
	Q_OBJECT

   GLfloat   RotationAngle_;

   unsigned long lFrames_;

	QWidget* pParent_;
	glObject obj_[3];					// Holds the data for the objects
	GLfloat	xrot_, xspeed_;		// X Rotation & X Speed
	GLfloat	yrot_, yspeed_;		// Y Rotation & Y Speed
	sQuad    LightPos_;
	sQuad    LightAmb_;
	sQuad    LightDif_, LightSpc_;
	sQuad    MatAmb_, MatDif_, MatSpc_;
	GLfloat  MatShn_[1];
	sPoint   ObjPos_;
	sPoint   SpherePos_;
	GLUquadricObj	*q_;				// Quadratic For Drawing A Sphere
	int      startTime_;
	int		currObject_; 		// obj_ index of currently displayed object

public:
    Lesson27Widget( const QGLFormat &, QWidget *parent=0, const char *name=0 );
    ~Lesson27Widget();
	 void Rotate();

protected:
   void 	initializeGL();
   void 	resizeGL( int, int );
   void 	paintGL();
	void 	timerEvent( QTimerEvent* );
	void	keyPressEvent( QKeyEvent *k );
	int   CurrTime();

   void  DrawScene();
	void	DrawGLRoom();
	void	DrawGLObject();
	int	InitGLObjects();
	void 	CalcPlane(glObject o, sPlane *plane);
	void 	SetConnectivity(glObject *o);
	void 	CastShadow(glObject *o, float *lp);
	void 	VMatMult(GLmatrix16f M, GLvector4f v);
};

} // namespace

#endif

