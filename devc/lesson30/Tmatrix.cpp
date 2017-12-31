/*******************************************************************************/
/*********************************21/09/200*************************************/
/**********************Programmer: Dimitrios Christopoulos**********************/
/**********************for the oglchallenge contest*****************************/
/**********************COLLISION CRAZY******************************************/
/*******************************************************************************/

#include "tmatrix.h"

#include "tvector.h"





TMatrix33::TMatrix33() {

	_Mx[0][0]=1.0; _Mx[0][1]=0.0; _Mx[0][2]=0.0;

	_Mx[1][0]=0.0; _Mx[1][1]=1.0; _Mx[1][2]=0.0;

	_Mx[2][0]=0.0; _Mx[2][1]=0.0; _Mx[2][2]=1.0;

}



TMatrix33::TMatrix33(double mx00, double mx01, double mx02,

		 double mx10, double mx11, double mx12,

		 double mx20, double mx21, double mx22) {

	_Mx[0][0]=mx00; _Mx[0][1]=mx01; _Mx[0][2]=mx02;

	_Mx[1][0]=mx10; _Mx[1][1]=mx11; _Mx[1][2]=mx12;

	_Mx[2][0]=mx20; _Mx[2][1]=mx21; _Mx[2][2]=mx22;

}



TMatrix33::TMatrix33(double Phi, double Theta, double Psi) {

	double c1=cos(Phi), s1=sin(Phi), c2=cos(Theta), s2=sin(Theta), c3=cos(Psi), s3=sin(Psi);

	_Mx[0][0]=c2*c3;

	_Mx[0][1]=-c2*s3;

	_Mx[0][2]=s2;

	_Mx[1][0]=s1*s2*c3+c1*s3;

	_Mx[1][1]=-s1*s2*s3+c1*c3;

	_Mx[1][2]=-s1*c2;

	_Mx[2][0]=-c1*s2*c3+s1*s3;

	_Mx[2][1]=c1*s2*s3+s1*c3;

	_Mx[2][2]=c1*c2;

}



TMatrix33 &TMatrix33::add(const TMatrix33 &m1, const TMatrix33 &m2, TMatrix33 &result) {

	result._Mx[0][0] = m1._Mx[0][0] + m2._Mx[0][0];

	result._Mx[0][1] = m1._Mx[0][1] + m2._Mx[0][1];

	result._Mx[0][2] = m1._Mx[0][2] + m2._Mx[0][2];

	result._Mx[1][0] = m1._Mx[1][0] + m2._Mx[1][0];

	result._Mx[1][1] = m1._Mx[1][1] + m2._Mx[1][1];

	result._Mx[1][2] = m1._Mx[1][2] + m2._Mx[1][2];

	result._Mx[2][0] = m1._Mx[2][0] + m2._Mx[2][0];

	result._Mx[2][1] = m1._Mx[2][1] + m2._Mx[2][1];

	result._Mx[2][2] = m1._Mx[2][2] + m2._Mx[2][2];

	return result;

}



TMatrix33 &TMatrix33::subtract(const TMatrix33 &m1, const TMatrix33 &m2, TMatrix33 &result) {

	result._Mx[0][0] = m1._Mx[0][0] - m2._Mx[0][0];

	result._Mx[0][1] = m1._Mx[0][1] - m2._Mx[0][1];

	result._Mx[0][2] = m1._Mx[0][2] - m2._Mx[0][2];

	result._Mx[1][0] = m1._Mx[1][0] - m2._Mx[1][0];

	result._Mx[1][1] = m1._Mx[1][1] - m2._Mx[1][1];

	result._Mx[1][2] = m1._Mx[1][2] - m2._Mx[1][2];

	result._Mx[2][0] = m1._Mx[2][0] - m2._Mx[2][0];

	result._Mx[2][1] = m1._Mx[2][1] - m2._Mx[2][1];

	result._Mx[2][2] = m1._Mx[2][2] - m2._Mx[2][2];

	return result;

}



TMatrix33 &TMatrix33::multiply(const TMatrix33 &m1, const TMatrix33 &m2, TMatrix33 &result) {

	result._Mx[0][0] = m1._Mx[0][0]*m2._Mx[0][0] + m1._Mx[0][1]*m2._Mx[1][0] + m1._Mx[0][2]*m2._Mx[2][0];

	result._Mx[1][0] = m1._Mx[1][0]*m2._Mx[0][0] + m1._Mx[1][1]*m2._Mx[1][0] + m1._Mx[1][2]*m2._Mx[2][0];

	result._Mx[2][0] = m1._Mx[2][0]*m2._Mx[0][0] + m1._Mx[2][1]*m2._Mx[1][0] + m1._Mx[2][2]*m2._Mx[2][0];

	result._Mx[0][1] = m1._Mx[0][0]*m2._Mx[0][1] + m1._Mx[0][1]*m2._Mx[1][1] + m1._Mx[0][2]*m2._Mx[2][1];

	result._Mx[1][1] = m1._Mx[1][0]*m2._Mx[0][1] + m1._Mx[1][1]*m2._Mx[1][1] + m1._Mx[1][2]*m2._Mx[2][1];

	result._Mx[2][1] = m1._Mx[2][0]*m2._Mx[0][1] + m1._Mx[2][1]*m2._Mx[1][1] + m1._Mx[2][2]*m2._Mx[2][1];

	result._Mx[0][2] = m1._Mx[0][0]*m2._Mx[0][2] + m1._Mx[0][1]*m2._Mx[1][2] + m1._Mx[0][2]*m2._Mx[2][2];

	result._Mx[1][2] = m1._Mx[1][0]*m2._Mx[0][2] + m1._Mx[1][1]*m2._Mx[1][2] + m1._Mx[1][2]*m2._Mx[2][2];

	result._Mx[2][2] = m1._Mx[2][0]*m2._Mx[0][2] + m1._Mx[2][1]*m2._Mx[1][2] + m1._Mx[2][2]*m2._Mx[2][2];

	return result;

}



TMatrix33 &TMatrix33::multiply(const TMatrix33 &m1, const double &scale, TMatrix33 &result) {

	result._Mx[0][0] = m1._Mx[0][0] * scale;

	result._Mx[0][1] = m1._Mx[0][1] * scale;

	result._Mx[0][2] = m1._Mx[0][2] * scale;

	result._Mx[1][0] = m1._Mx[1][0] * scale;

	result._Mx[1][1] = m1._Mx[1][1] * scale;

	result._Mx[1][2] = m1._Mx[1][2] * scale;

	result._Mx[2][0] = m1._Mx[2][0] * scale;

	result._Mx[2][1] = m1._Mx[2][1] * scale;

	result._Mx[2][2] = m1._Mx[2][2] * scale;

	return result;

}



TVector &TMatrix33::multiply(const TMatrix33 &m1, const TVector &v, TVector &result) {

	result = TVector(

   	m1._Mx[0][0]*v.X() + m1._Mx[0][1]*v.Y() + m1._Mx[0][2]*v.Z(),

		m1._Mx[1][0]*v.X() + m1._Mx[1][1]*v.Y() + m1._Mx[1][2]*v.Z(),

		m1._Mx[2][0]*v.X() + m1._Mx[2][1]*v.Y() + m1._Mx[2][2]*v.Z() );

	return result;

}



double TMatrix33::determinant() const {

	return _Mx[0][0]*(_Mx[1][1]*_Mx[2][2]-_Mx[1][2]*_Mx[2][1])

		- _Mx[0][1]*(_Mx[1][0]*_Mx[2][2]-_Mx[1][2]*_Mx[2][0])

		+ _Mx[0][2]*(_Mx[1][0]*_Mx[2][1]-_Mx[1][1]*_Mx[2][0]);

}



TMatrix33 &TMatrix33::transpose() {

	double t=_Mx[0][2]; _Mx[0][2]=_Mx[2][0]; _Mx[2][0]=t;

	t=_Mx[0][1]; _Mx[0][1]=_Mx[1][0]; _Mx[1][0]=t;

	t=_Mx[1][2]; _Mx[1][2]=_Mx[2][1]; _Mx[2][1]=t;

	return *this;

}



TMatrix33 &TMatrix33::inverse(const TMatrix33 &m1, TMatrix33 &result) {

	double det = m1.determinant();

	if (fabs(det) < EPSILON) {

		result = TMatrix33();

		return result;

	} else {

		result._Mx[0][0] = m1._Mx[1][1]*m1._Mx[2][2] - m1._Mx[1][2]*m1._Mx[2][1];

		result._Mx[0][1] = m1._Mx[2][1]*m1._Mx[0][2] - m1._Mx[2][2]*m1._Mx[0][1];

		result._Mx[0][2] = m1._Mx[0][1]*m1._Mx[1][2] - m1._Mx[0][2]*m1._Mx[1][1];

		result._Mx[1][0] = m1._Mx[1][2]*m1._Mx[2][0] - m1._Mx[1][0]*m1._Mx[2][2];

		result._Mx[1][1] = m1._Mx[2][2]*m1._Mx[0][0] - m1._Mx[2][0]*m1._Mx[0][2];

		result._Mx[1][2] = m1._Mx[0][2]*m1._Mx[1][0] - m1._Mx[0][0]*m1._Mx[1][2];

		result._Mx[2][0] = m1._Mx[1][0]*m1._Mx[2][1] - m1._Mx[1][1]*m1._Mx[2][0];

		result._Mx[2][1] = m1._Mx[2][0]*m1._Mx[0][1] - m1._Mx[2][1]*m1._Mx[0][0];

		result._Mx[2][2] = m1._Mx[0][0]*m1._Mx[1][1] - m1._Mx[0][1]*m1._Mx[1][0];

		return multiply(result, 1.0/det, result);

	}

}



TVector TMatrix33::operator*(const TVector &v) const {

	TVector tv;

	return multiply(*this, v, tv);

}





ostream &TMatrix33::write(ostream &out) const {

	return out<<"("<<_Mx[0][0]<<","<<_Mx[0][1]<<","<<_Mx[0][2]<<")"<<endl

		<<"("<<_Mx[1][0]<<","<<_Mx[1][1]<<","<<_Mx[1][2]<<")"<<endl

		<<"("<<_Mx[2][0]<<","<<_Mx[2][1]<<","<<_Mx[2][2]<<")"<<endl;

}



istream &TMatrix33::read(istream &in) {

	char ch;

	return in>>ch>>_Mx[0][0]>>ch>>_Mx[0][1]>>ch>>_Mx[0][2]>>ch

		>>ch>>_Mx[1][0]>>ch>>_Mx[1][1]>>ch>>_Mx[1][2]>>ch

		>>ch>>_Mx[2][0]>>ch>>_Mx[2][1]>>ch>>_Mx[2][2]>>ch;

}



