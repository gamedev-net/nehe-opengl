#ifndef tray_h
#define tray_h

#include <iostream>
#include "mathex.h"
#include "tvector.h"


///////////////////////////////////////////////////////////////////////
//  Class Line
///////////////////////////////////////////////////////////////////////

class TRay
{
	private:
		TVector _P; // Any point on the line
		TVector _V; // Direction of the line

		// Input and output
		std::ostream &write(std::ostream &out) const;
		std::istream &read(std::istream &in);

      // Close

	public:
		// Constructors
		TRay() {}

		// Line betwen two points OR point and a direction
		TRay(const TVector &point1, const TVector &point2);

		// Adjacent points on both lines
		bool adjacentPoints(const TRay &ray, TVector &point1, TVector &point2) const;

		// Unary operator
		static TRay &invert(const TRay &r, TRay &result) { result._P = r._P; TVector::invert(r._V, result._V); return result; }
		TRay operator-() const { TRay tmp; return invert(*this, tmp); }

		// Selectors
		TVector P() const { return _P; }
		TVector V() const { return _V; }
		int isValid() const { return V().isUnit() && P().isValid(); }

		// Distances
		double dist(const TRay &ray) const;
		double dist(const TVector &point) const;

		// Streaming
		friend std::ostream &operator<<(std::ostream &out, const TRay &o) { return o.write(out); }
		friend std::istream &operator>>(std::istream &in, TRay &o) { return o.read(in); }
};
#endif
