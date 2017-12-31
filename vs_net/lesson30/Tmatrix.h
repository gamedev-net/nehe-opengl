#ifndef matrix_h
#define matrix_h

#include <iostream.h>
#include "mathex.h"

class TVector;

class TMatrix33
{
	private:
		double _Mx[3][3];

		// Input output
		ostream &write(ostream &out) const;
		istream &read(istream &in);

	public:
		// Constructors
		TMatrix33();
		TMatrix33(double Phi, double Theta, double Psi);
		TMatrix33(double mx00, double mx01, double mx02, double mx10, double mx11, double mx12, double mx20, double mx21, double mx22);

		// Selectors
		double operator()(int Row, int Column) const { return _Mx[Row][Column]; }
		double &operator()(int Row, int Column) { return _Mx[Row][Column]; }

		// Optimised artimetric methods
		static TMatrix33 &add(const TMatrix33 &m1, const TMatrix33 &m2, TMatrix33 &result);
		static TMatrix33 &subtract(const TMatrix33 &m1, const TMatrix33 &m2, TMatrix33 &result);
		static TMatrix33 &multiply(const TMatrix33 &m1, const TMatrix33 &m2, TMatrix33 &result);
		static TMatrix33 &multiply(const TMatrix33 &m1, const double &scale, TMatrix33 &result);
		static TVector &multiply(const TMatrix33 &m1, const TVector &v, TVector &result);

		// Matrix arithmetic
		TMatrix33 &operator+=(const TMatrix33 &m) { return add(*this, m, *this); }
		TMatrix33 &operator-=(const TMatrix33 &m) { return subtract(*this, m, *this); }
		TMatrix33 &operator*=(const TMatrix33 &m) { TMatrix33 tm(*this); return multiply(tm, m, *this); }
		TMatrix33 &operator*=(const double &scale) { return multiply(*this, scale, *this); }
		TMatrix33 operator+(const TMatrix33 &m) const { TMatrix33 tm; return add(*this, m, tm); }
		TMatrix33 operator-(const TMatrix33 &m) const { TMatrix33 tm; return subtract(*this, m, tm); }
		TMatrix33 operator*(const TMatrix33 &m) const { TMatrix33 tm; return multiply(*this, m, tm); }
		TMatrix33 operator*(const double &scale) const { TMatrix33 tm; return multiply(*this, scale, tm); }
		TVector operator*(const TVector &v) const;

		// Determinants
		double determinant() const;
		static double determinant(const TMatrix33 &m) { return m.determinant(); }

		// Transpose
		TMatrix33 &transpose();
		static TMatrix33 &transpose(const TMatrix33 &m, TMatrix33 &result) { result = m; return result.transpose(); }
		static TMatrix33 transpose(const TMatrix33 &m) { return TMatrix33(m).transpose(); }

		// Inverse
		static TMatrix33 &TMatrix33::inverse(const TMatrix33 &m1, TMatrix33 &result);
		static TMatrix33 TMatrix33::inverse(const TMatrix33 &m1) { TMatrix33 tm; return inverse(m1, tm); }
		TMatrix33 inverse() const { TMatrix33 tm; return inverse(*this, tm); }

		// Stream
		friend ostream &operator<<(ostream &out, const TMatrix33 &o) { return o.write(out); }
		friend istream &operator>>(istream &in, TMatrix33 &o) { return o.read(in); }
};
#endif
