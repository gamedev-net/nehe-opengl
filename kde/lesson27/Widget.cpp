
//		This code has been created by Banu Cosmin aka Choko - 20 may 2000
//		and uses NeHe tutorials as a starting point (window initialization,
//		texture loading, GL initialization and code for keypresses) - very good
//		tutorials, Jeff. If anyone is interested about the presented algorithm
//		please e-mail me at boct@romwest.ro
//		Attention!!! This code is not for beginners.
//   
//    Linux KDE C++ port by Zsolt Hajdu

#include <kfiledialog.h>
#include <kapp.h>
#include <kmenubar.h>
#include <klocale.h>
#include <kmessagebox.h>
#include <kpopupmenu.h>
#include <qtextview.h>

#include <string>
#include <iostream>
using namespace std;

#include <string>
#include <iostream>

#include "Widget.h"
using namespace NeHe;

Lesson27Widget::Lesson27Widget( const QGLFormat &form,
									QWidget* parent, const char * name ) :
          	QGLWidget( form, parent, name),
				LightPos_( 0.0f, 5.0f, -4.0f, 1.0f ),
				LightAmb_( 0.2f, 0.2f, 0.2f, 1.0f ),
				LightDif_( 0.6f, 0.6f, 0.6f, 1.0f ),
				LightSpc_( -0.2f, -0.2f, -0.2f, 1.0f ),
				MatAmb_( 0.4f, 0.4f, 0.4f, 1.0f ),
				MatDif_( 0.2f, 0.6f, 0.9f, 1.0f ),
				MatSpc_( 0.0f, 0.0f, 0.0f, 1.0f ),
				ObjPos_( -2.0f,-2.0f,-5.0f ),
				SpherePos_( -4.0f,-5.0f,-6.0f )
{
	MatShn_[0] = 0.0f;
	lFrames_ = 0;
	pParent_ = parent;

	xrot_ = yrot_ = xspeed_ = yspeed_ = 0;
	setFocusPolicy( QWidget::StrongFocus );
	startTimer( 5 );
	currObject_ = 2;
}

Lesson27Widget::~Lesson27Widget()
{
}

// return current time (in seconds)
int Lesson27Widget::CurrTime()
{
   struct timeval tv;
   struct timezone tz;
   (void) gettimeofday(&tv, &tz);
   return (int) tv.tv_sec;
}

void Lesson27Widget::timerEvent( QTimerEvent* )
{
	updateGL();
}

// connectivity procedure - based on Gamasutra's article
// hard to explain here
void Lesson27Widget::SetConnectivity(glObject *o)
{
	long p1i, p2i, p1j, p2j;
	long P1i, P2i, P1j, P2j;
	long i,j,ki,kj;

	for ( i=0 ; i<o->nPlanes-1 ; i++ )
		for ( j=i+1 ; j<o->nPlanes ; j++ )
			for ( ki=0 ; ki<3 ; ki++ )
				if ( !o->planes[i].neigh[ki] ) {
					for ( kj=0 ; kj<3 ; kj++ ) {
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

						if ( (P1i==P1j) && (P2i==P2j) ) {  //they are neighbours
							o->planes[i].neigh[ki] = j+1;
							o->planes[j].neigh[kj] = i+1;
						}
					}
				}
}

// function for computing a plane equation given 3 points
void Lesson27Widget::CalcPlane(glObject o, sPlane *plane)
{
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
void Lesson27Widget::DrawGLObject()
{
	unsigned int i, j;
	glObject &o( obj_[ currObject_ ] );

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

void Lesson27Widget::CastShadow(glObject *o, float *lp)
{
	unsigned int	i, j, k, jj;
	unsigned int	p1, p2;
	sPoint			v1, v2;
	float			side;

	//set visual parameter
	for (i=0;i<o->nPlanes;i++){
		// chech to see if light is in front or behind the plane (face plane)
		side = o->planes[i].PlaneEq.a * lp[0] + o->planes[i].PlaneEq.b * lp[1] +
					o->planes[i].PlaneEq.c * lp[2] + o->planes[i].PlaneEq.d * lp[3];
		o->planes[i].visible = side > 0;
	}

	glDisable(GL_LIGHTING);
	glDepthMask(GL_FALSE);
	glDepthFunc(GL_LEQUAL);

	glEnable(GL_STENCIL_TEST);
	glColorMask(0, 0, 0, 0);
	glStencilFunc(GL_ALWAYS, 1, 0xffffffff);

	// first pass, stencil operation increases stencil value
	glFrontFace(GL_CCW);
	glStencilOp(GL_KEEP, GL_KEEP, GL_INCR);

	for ( i=0 ; i < o->nPlanes ; i++ ) {
		if ( o->planes[i].visible )
			for ( j=0 ; j < 3 ; j++ ) {
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

	// second pass, stencil operation decreases stencil value
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
						glVertex3f( o->points[p1].x,
											o->points[p1].y,
												o->points[p1].z );
						glVertex3f( o->points[p1].x + v1.x,
											o->points[p1].y + v1.y,
												o->points[p1].z + v1.z );

						glVertex3f( o->points[p2].x,
											o->points[p2].y,
												o->points[p2].z );
						glVertex3f( o->points[p2].x + v2.x,
											o->points[p2].y + v2.y,
												o->points[p2].z + v2.z );
					glEnd();
				}
			}
	}

	glFrontFace( GL_CCW );
	glColorMask( GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE );

	//draw a shadowing rectangle covering the entire screen
	glColor4f( 0.0f, 0.0f, 0.0f, 0.4f );
	glEnable( GL_BLEND );
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glStencilFunc( GL_NOTEQUAL, 0, 0xffffffff );
	glStencilOp( GL_KEEP, GL_KEEP, GL_KEEP );
	glPushMatrix();
	glLoadIdentity();
	glBegin( GL_TRIANGLE_STRIP );
		glVertex3f( -1.1f,  1.1f, -2.5f );
		glVertex3f( -1.1f, -1.1f, -2.5f );
		glVertex3f(  1.1f,  1.1f, -2.5f );
		glVertex3f(  1.1f, -1.1f, -2.5f );
	glEnd();
	glPopMatrix();
	glDisable(GL_BLEND);

	glDepthFunc(GL_LEQUAL);
	glDepthMask(GL_TRUE);
	glEnable(GL_LIGHTING);
	glDisable(GL_STENCIL_TEST);
	glShadeModel(GL_SMOOTH);
}

int Lesson27Widget::InitGLObjects()										// Initialize Objects
{
	if ( !obj_[0].ReadObject( "Data/Object.txt" ) )		// Read Object.txt Into obj_
		return FALSE;											// If Failed Return False
	if ( !obj_[1].ReadObject( "Data/Object1.txt" ) )	// Read Object1.txt Into obj_
		return FALSE;
	if ( !obj_[2].ReadObject( "Data/Object2.txt" ) )	// Read Object2.txt Into obj_
		return FALSE;

	SetConnectivity( &obj_[0] );						// Set Face To Face Connectivity
	SetConnectivity( &obj_[1] );						// Set Face To Face Connectivity
	SetConnectivity( &obj_[2] );						// Set Face To Face Connectivity

	for (unsigned int i=0 ; i < obj_[0].nPlanes ; i++ )			// Loop Through All Object Planes
		CalcPlane( obj_[0], &(obj_[0].planes[i] ) );				// Compute Plane Equations For All Faces

	for (unsigned int i=0 ; i < obj_[1].nPlanes ; i++ )			// Loop Through All Object Planes
		CalcPlane( obj_[1], &(obj_[1].planes[i] ) );				// Compute Plane Equations For All Faces

	for (unsigned int i=0 ; i < obj_[2].nPlanes ; i++ )			// Loop Through All Object Planes
		CalcPlane( obj_[2], &(obj_[2].planes[i] ) );				// Compute Plane Equations For All Faces

	return TRUE;										// Return True
}

void Lesson27Widget::initializeGL()
{
   cout << " gl_init() Starts " << endl;

	InitGLObjects();										// Function For Initializing Our Object(s)
	glShadeModel( GL_SMOOTH );							// Enable Smooth Shading
	glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );		// Black Background
	glClearDepth( 1.0f );								// Depth Buffer Setup
	glClearStencil( 0 );									// Stencil Buffer Setup
	glEnable( GL_DEPTH_TEST );							// Enables Depth Testing
	glDepthFunc( GL_LEQUAL );							// The Type Of Depth Testing To Do
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);// Really Nice Perspective Calculations

	glLightfv( GL_LIGHT1, GL_POSITION, (GLfloat*)&LightPos_[0] );	// Set Light1 Position
	glLightfv( GL_LIGHT1, GL_AMBIENT,  (GLfloat*)&LightAmb_[0] );	// Set Light1 Ambience
	glLightfv( GL_LIGHT1, GL_DIFFUSE,  (GLfloat*)&LightDif_[0] );	// Set Light1 Diffuse
	glLightfv( GL_LIGHT1, GL_SPECULAR, (GLfloat*)&LightSpc_[0] );	// Set Light1 Specular
	glEnable( GL_LIGHT1 );								// Enable Light1
	glEnable( GL_LIGHTING );							// Enable Lighting

	glMaterialfv( GL_FRONT, GL_AMBIENT, (GLfloat*)&MatAmb_[0] );		// Set Material Ambience
	glMaterialfv( GL_FRONT, GL_DIFFUSE, (GLfloat*)&MatDif_[0] );		// Set Material Diffuse
	glMaterialfv( GL_FRONT, GL_SPECULAR, (GLfloat*)&MatSpc_[0] );	// Set Material Specular
	glMaterialfv( GL_FRONT, GL_SHININESS, MatShn_ );	// Set Material Shininess

	glCullFace( GL_BACK );								// Set Culling Face To Back Face
	glEnable(GL_CULL_FACE);							// Enable Culling
	glClearColor(0.1f, 1.0f, 0.5f, 1.0f);		// Set Clear Color (Greenish Color)

	q_ = gluNewQuadric();								// Initialize Quadratic
	gluQuadricNormals( q_, GL_SMOOTH);				// Enable Smooth Normal Generation
	gluQuadricTexture( q_, GL_FALSE);				// Disable Auto Texture Coords

   cout << " gl_init() Finished " << endl;
}

void Lesson27Widget::DrawGLRoom()					// Draw The Room (Box)
{
	glBegin(GL_QUADS);									// Begin Drawing Quads
		// Floor
		glNormal3f(0.0f, 1.0f, 0.0f);					// Normal Pointing Up
		glVertex3f(-10.0f,-10.0f,-20.0f);				// Back Left
		glVertex3f(-10.0f,-10.0f, 20.0f);				// Front Left
		glVertex3f( 10.0f,-10.0f, 20.0f);				// Front Right
		glVertex3f( 10.0f,-10.0f,-20.0f);				// Back Right
		// Ceiling
		glNormal3f(0.0f,-1.0f, 0.0f);					// Normal Point Down
		glVertex3f(-10.0f, 10.0f, 20.0f);				// Front Left
		glVertex3f(-10.0f, 10.0f,-20.0f);				// Back Left
		glVertex3f( 10.0f, 10.0f,-20.0f);				// Back Right
		glVertex3f( 10.0f, 10.0f, 20.0f);				// Front Right
		// Front Wall
		glNormal3f(0.0f, 0.0f, 1.0f);					// Normal Pointing Away From Viewer
		glVertex3f(-10.0f, 10.0f,-20.0f);				// Top Left
		glVertex3f(-10.0f,-10.0f,-20.0f);				// Bottom Left
		glVertex3f( 10.0f,-10.0f,-20.0f);				// Bottom Right
		glVertex3f( 10.0f, 10.0f,-20.0f);				// Top Right
		// Back Wall
		glNormal3f(0.0f, 0.0f,-1.0f);					// Normal Pointing Towards Viewer
		glVertex3f( 10.0f, 10.0f, 20.0f);				// Top Right
		glVertex3f( 10.0f,-10.0f, 20.0f);				// Bottom Right
		glVertex3f(-10.0f,-10.0f, 20.0f);				// Bottom Left
		glVertex3f(-10.0f, 10.0f, 20.0f);				// Top Left
		// Left Wall
		glNormal3f(1.0f, 0.0f, 0.0f);					// Normal Pointing Right
		glVertex3f(-10.0f, 10.0f, 20.0f);				// Top Front
		glVertex3f(-10.0f,-10.0f, 20.0f);				// Bottom Front
		glVertex3f(-10.0f,-10.0f,-20.0f);				// Bottom Back
		glVertex3f(-10.0f, 10.0f,-20.0f);				// Top Back
		// Right Wall
		glNormal3f(-1.0f, 0.0f, 0.0f);					// Normal Pointing Left
		glVertex3f( 10.0f, 10.0f,-20.0f);				// Top Back
		glVertex3f( 10.0f,-10.0f,-20.0f);				// Bottom Back
		glVertex3f( 10.0f,-10.0f, 20.0f);				// Bottom Front
		glVertex3f( 10.0f, 10.0f, 20.0f);				// Top Front
	glEnd();											// Done Drawing Quads
}

//
// Lesson27Widget::DrawScene()
//
// The work of the application is done here. This is called every frame, and
// handles the actual rendering of the scene.
//
void Lesson27Widget::DrawScene()
{
	GLmatrix16f Minv;
	GLvector4f wlp, lp;

	// Clear Color Buffer, Depth Buffer, Stencil Buffer
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

	glLoadIdentity();									// Reset Modelview Matrix
	glTranslatef(0.0f, 0.0f, -20.0f);					// Zoom Into Screen 20 Units
	glLightfv( GL_LIGHT1, GL_POSITION, (GLfloat*)&LightPos_[0] );		// Position Light1
	glTranslatef( SpherePos_[0], SpherePos_[1], SpherePos_[2] );	// Position The Sphere
	gluSphere( q_, 1.5f, 32, 16);							// Draw A Sphere

	// calculate light's position relative to local coordinate system
	// dunno if this is the best way to do it, but it actually works
	// if u find another aproach, let me know ;)

	// we build the inversed matrix by doing all the actions in reverse order
	// and with reverse parameters (notice -xrot, -yrot, -ObjPos[], etc.)
	glLoadIdentity();									// Reset Matrix
	glRotatef( -yrot_, 0.0f, 1.0f, 0.0f );					// Rotate By -yrot On Y Axis
	glRotatef( -xrot_, 1.0f, 0.0f, 0.0f );					// Rotate By -xrot On X Axis
	glGetFloatv(GL_MODELVIEW_MATRIX,Minv);				// Retrieve ModelView Matrix (Stores In Minv)
	lp[0] = LightPos_[0];								// Store Light Position X In lp[0]
	lp[1] = LightPos_[1];								// Store Light Position Y In lp[1]
	lp[2] = LightPos_[2];								// Store Light Position Z In lp[2]
	lp[3] = LightPos_[3];								// Store Light Direction In lp[3]
	VMatMult( Minv, lp );									// We Store Rotated Light Vector In 'lp' Array
	glTranslatef( -ObjPos_[0], -ObjPos_[1], -ObjPos_[2]);	// Move Negative On All Axis Based On ObjPos[] Values (X, Y, Z)
	glGetFloatv( GL_MODELVIEW_MATRIX, Minv );				// Retrieve ModelView Matrix From Minv
	wlp[0] = 0.0f;										// World Local Coord X To 0
	wlp[1] = 0.0f;										// World Local Coord Y To 0
	wlp[2] = 0.0f;										// World Local Coord Z To 0
	wlp[3] = 1.0f;
	VMatMult( Minv, wlp );								// We Store The Position Of The World Origin Relative To The
														// Local Coord. System In 'wlp' Array
	lp[0] += wlp[0];									// Adding These Two Gives Us The
	lp[1] += wlp[1];									// Position Of The Light Relative To
	lp[2] += wlp[2];									// The Local Coordinate System

	glColor4f( 0.7f, 0.4f, 0.0f, 1.0f );		// Set Color To An Orange
	glLoadIdentity();									// Reset Modelview Matrix
	glTranslatef( 0.0f, 0.0f, -20.0f );			// Zoom Into The Screen 20 Units
	DrawGLRoom();										// Draw The Room
	glTranslatef( ObjPos_[0], ObjPos_[1], ObjPos_[2] );		// Position The Object
	glRotatef( xrot_, 1.0f, 0.0f, 0.0f );		// Spin It On The X Axis By xrot
	glRotatef( yrot_, 0.0f, 1.0f, 0.0f );		// Spin It On The Y Axis By yrot
	DrawGLObject();							// Procedure For Drawing The Loaded Object
	CastShadow( &obj_[currObject_], lp );		// Procedure For Casting The Shadow Based On The Silhouette

	glColor4f(0.7f, 0.4f, 0.0f, 1.0f);			// Set Color To Purplish Blue
	glDisable(GL_LIGHTING);							// Disable Lighting
	glDepthMask(GL_FALSE);							// Disable Depth Mask
	glTranslatef(lp[0], lp[1], lp[2]);			// Translate To Light's Position
														// Notice We're Still In Local Coordinate System
	gluSphere( q_, 0.2f, 16, 8);					// Draw A Little Yellow Sphere (Represents Light)
	glEnable(GL_LIGHTING);							// Enable Lighting
	glDepthMask(GL_TRUE);							// Enable Depth Mask

	xrot_ += xspeed_;									// Increase xrot By xspeed
	yrot_ += yspeed_;									// Increase yrot By yspeed
}

void Lesson27Widget::paintGL()
{
   glTranslatef( -15.0f, -10.0f, -50.0f );
   DrawScene();

   //lFrames_++;
   //int now = CurrTime();
   //if ( now - startTime_ >= 2.0 ) {
   //   GLfloat seconds = now - startTime_;
   //   GLfloat fps = lFrames_ / seconds;
   //   char szCaption[42];

   //   lFrames_ = 0;
   //   startTime_ = now;
   //}

   // draw everything and swap the display buffer
   glFlush();
}

void Lesson27Widget::resizeGL( int width, int height )
{
   glViewport( 0, 0, width, height );

   glMatrixMode( GL_PROJECTION);
   glLoadIdentity();

   gluPerspective( 54.0f, (GLfloat)width/(GLfloat)height, 1.0f, 1000.0f );

   glMatrixMode( GL_MODELVIEW );
   glLoadIdentity();
}

void Lesson27Widget::VMatMult(GLmatrix16f M, GLvector4f v)
{
	GLfloat res[4];										// Hold Calculated Results
	res[0]=M[ 0]*v[0]+M[ 4]*v[1]+M[ 8]*v[2]+M[12]*v[3];
	res[1]=M[ 1]*v[0]+M[ 5]*v[1]+M[ 9]*v[2]+M[13]*v[3];
	res[2]=M[ 2]*v[0]+M[ 6]*v[1]+M[10]*v[2]+M[14]*v[3];
	res[3]=M[ 3]*v[0]+M[ 7]*v[1]+M[11]*v[2]+M[15]*v[3];
	v[0]=res[0];										// Results Are Stored Back In v[]
	v[1]=res[1];
	v[2]=res[2];
	v[3]=res[3];										// Homogenous Coordinate
}

const float flStep = 0.05f;

void Lesson27Widget::keyPressEvent( QKeyEvent *k )
{

	switch ( k->key() ) {
		// Adjust Light's Position
	  case Key_L:
			LightPos_[0] += flStep;				// 'L' Moves Light Right
			break;
	  case Key_J:
			LightPos_[0] -= flStep;				// 'J' Moves Light Left
			break;

	  case Key_I:
			LightPos_[1] += flStep;				// 'I' Moves Light Up
			break;
	  case Key_K:
			LightPos_[1] -= flStep;				// 'K' Moves Light Down
			break;

	  case Key_O:
			LightPos_[2] += flStep;				// 'O' Moves Light Toward Viewer
			break;
	  case Key_U:
			LightPos_[2] -= flStep;				// 'U' Moves Light Away From Viewer
			break;

// Adjust Object's Position
	  case Key_6:
			ObjPos_[0] += flStep;			// 'Numpad6' Move Object Right
			break;
	  case Key_4:
			ObjPos_[0] -= flStep;			// 'Numpad4' Move Object Left
			break;

	  case Key_8:
			ObjPos_[1] += flStep;			// 'Numpad8' Move Object Up
			break;
	  case Key_5:
			ObjPos_[1] -= flStep;			// 'Numpad5' Move Object Down
			break;

	  case Key_9:
			ObjPos_[2] += flStep;			// 'Numpad9' Move Object Toward Viewer
			break;
	  case Key_7:
			ObjPos_[2] -= flStep;			// 'Numpad7' Move Object Away From Viewer
			break;

// Adjust Ball's Position
	  case Key_D:
			SpherePos_[0] += flStep;				// 'D' Move Ball Right
			break;
	  case Key_A:
			SpherePos_[0] -= flStep;				// 'A' Move Ball Left
			break;

	  case Key_W:
			SpherePos_[1] += flStep;				// 'W' Move Ball Up
			break;
	  case Key_S:
			SpherePos_[1] -= flStep;				// 'S' Move Ball Down
			break;

	  case Key_E:
			SpherePos_[2] += flStep;				// 'E' Move Ball Toward Viewer
			break;
	  case Key_Q:
			SpherePos_[2] -= flStep;				// 'Q' Move Ball Away From Viewer
			break;

	  case Key_Escape:    //Escape key
			exit(0);

     case Key_Left:
            yspeed_ -= 0.2f;					// 'Arrow Left' Decrease yspeed
            break;
     case Key_Right:
            yspeed_ += 0.2f;					// 'Arrow Right' Increase yspeed
            break;
     case Key_Up:
            xspeed_ -= 0.2f;					// 'Arrow Up' Decrease xspeed
            break;
     case Key_Down:
            xspeed_ += 0.2f;					// 'Arrow Down' Increase xspeed
            break;
			
	  default:
			break;
   }
}

void Lesson27Widget::Rotate()
{
	currObject_<2 ? currObject_++ : currObject_ = 0;
}

