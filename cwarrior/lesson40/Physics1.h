/**************************************************************************

  File: Physics1.h  

  Prepared by Erkin Tunca for nehe.gamedev.net

**************************************************************************/

#include <math.h>

// class Vector3D		---> An object to represent a 3D vector or a 3D point in space
class Vector3D
{
public:
	float x;									// the x value of this Vector3D
	float y;									// the y value of this Vector3D
	float z;									// the z value of this Vector3D

	Vector3D()									// Constructor to set x = y = z = 0
	{
		x = 0;
		y = 0;
		z = 0;
	}

	Vector3D(float x, float y, float z)			// Constructor that initializes this Vector3D to the intended values of x, y and z
	{
		this->x = x;
		this->y = y;
		this->z = z;
	}

	Vector3D& operator= (Vector3D v)			// operator= sets values of v to this Vector3D. example: v1 = v2 means that values of v2 are set onto v1
	{
		x = v.x;
		y = v.y;
		z = v.z;
		return *this;
	}

	Vector3D operator+ (Vector3D v)				// operator+ is used to add two Vector3D's. operator+ returns a new Vector3D
	{
		return Vector3D(x + v.x, y + v.y, z + v.z);
	}

	Vector3D operator- (Vector3D v)				// operator- is used to take difference of two Vector3D's. operator- returns a new Vector3D
	{
		return Vector3D(x - v.x, y - v.y, z - v.z);
	}

	Vector3D operator* (float value)			// operator* is used to scale a Vector3D by a value. This value multiplies the Vector3D's x, y and z.
	{
		return Vector3D(x * value, y * value, z * value);
	}

	Vector3D operator/ (float value)			// operator/ is used to scale a Vector3D by a value. This value divides the Vector3D's x, y and z.
	{
		return Vector3D(x / value, y / value, z / value);
	}

	Vector3D& operator+= (Vector3D v)			// operator+= is used to add another Vector3D to this Vector3D.
	{
		x += v.x;
		y += v.y;
		z += v.z;
		return *this;
	}

	Vector3D& operator-= (Vector3D v)			// operator-= is used to subtract another Vector3D from this Vector3D.
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return *this;
	}

	Vector3D& operator*= (float value)			// operator*= is used to scale this Vector3D by a value.
	{
		x *= value;
		y *= value;
		z *= value;
		return *this;
	}

	Vector3D& operator/= (float value)			// operator/= is used to scale this Vector3D by a value.
	{
		x /= value;
		y /= value;
		z /= value;
		return *this;
	}


	Vector3D operator- ()						// operator- is used to set this Vector3D's x, y, and z to the negative of them.
	{
		return Vector3D(-x, -y, -z);
	}

	float length()								// length() returns the length of this Vector3D
	{
		return sqrtf(x*x + y*y + z*z);
	};			   		

	void unitize()								// unitize() normalizes this Vector3D that its direction remains the same but its length is 1.
	{
		float length = this->length();

		if (length == 0)
			return;

		x /= length;
		y /= length;
		z /= length;
	}

	Vector3D unit()								// unit() returns a new Vector3D. The returned value is a unitized version of this Vector3D.
	{
		float length = this->length();

		if (length == 0)
			return *this;
		
		return Vector3D(x / length, y / length, z / length);
	}

};

// class Mass			---> An object to represent a mass
class Mass
{
public:
	float m;									// The mass value
	Vector3D pos;								// Position in space
	Vector3D vel;								// Velocity
	Vector3D force;								// Force applied on this mass at an instance

	Mass(float m)								// Constructor
	{
		this->m = m;
	}

	/*
	  void applyForce(Vector3D force) method is used to add external force to the mass. 
	  At an instance in time, several sources of force might affect the mass. The vector sum 
	  of these forces make up the net force applied to the mass at the instance.
	*/
	void applyForce(Vector3D force)
	{
		this->force += force;					// The external force is added to the force of the mass
	}

	/*
	  void init() method sets the force values to zero
	*/
	void init()
	{
		force.x = 0;
		force.y = 0;
		force.z = 0;
	}

	/*
	  void simulate(float dt) method calculates the new velocity and new position of 
	  the mass according to change in time (dt). Here, a simulation method called
	  "The Euler Method" is used. The Euler Method is not always accurate, but it is 
	  simple. It is suitable for most of physical simulations that we know in common 
	  computer and video games.
	*/
	void simulate(float dt)
	{
		vel += (force / m) * dt;				// Change in velocity is added to the velocity.
												// The change is proportinal with the acceleration (force / m) and change in time

		pos += vel * dt;						// Change in position is added to the position.
												// Change in position is velocity times the change in time
	}

};

// class Simulation		---> A container object for simulating masses
class Simulation
{
public:
	int numOfMasses;								// number of masses in this container
	Mass** masses;									// masses are held by pointer to pointer. (Here Mass** represents a 1 dimensional array)
	
	Simulation(int numOfMasses, float m)			// Constructor creates some masses with mass values m
	{
		this->numOfMasses = numOfMasses;
		
		masses = new Mass*[numOfMasses];			// Create an array of pointers

		for (int a = 0; a < numOfMasses; ++a)		// We will step to every pointer in the array
			masses[a] = new Mass(m);				// Create a Mass as a pointer and put it in the array
	}

	virtual void release()							// delete the masses created
	{
		for (int a = 0; a < numOfMasses; ++a)		// we will delete all of them
		{
			delete(masses[a]);
			masses[a] = NULL;
		}
			
		delete(masses);
		masses = NULL;
	}

	Mass* getMass(int index)
	{
		if (index < 0 || index >= numOfMasses)		// if the index is not in the array
			return NULL;							// then return NULL

		return masses[index];						// get the mass at the index
	}

	virtual void init()								// this method will call the init() method of every mass
	{
		for (int a = 0; a < numOfMasses; ++a)		// We will init() every mass
			masses[a]->init();						// call init() method of the mass
	}

	virtual void solve()							// no implementation because no forces are wanted in this basic container
	{
													// in advanced containers, this method will be overrided and some forces will act on masses
	}

	virtual void simulate(float dt)					// Iterate the masses by the change in time
	{
		for (int a = 0; a < numOfMasses; ++a)		// We will iterate every mass
			masses[a]->simulate(dt);				// Iterate the mass and obtain new position and new velocity
	}

	virtual void operate(float dt)					// The complete procedure of simulation
	{
		init();										// Step 1: reset forces to zero
		solve();									// Step 2: apply forces
		simulate(dt);								// Step 3: iterate the masses by the change in time
	}

};

/*
  class ConstantVelocity is derived from class Simulation
  It creates 1 mass with mass value 1 kg and sets its velocity to (1.0f, 0.0f, 0.0f)
  so that the mass moves in the x direction with 1 m/s velocity.
*/
class ConstantVelocity : public Simulation
{
public:
	ConstantVelocity() : Simulation(1, 1.0f)				//Constructor firstly constructs its super class with 1 mass and 1 kg
	{
		masses[0]->pos = Vector3D(0.0f, 0.0f, 0.0f);		//a mass was created and we set its position to the origin
		masses[0]->vel = Vector3D(1.0f, 0.0f, 0.0f);		//we set the mass's velocity to (1.0f, 0.0f, 0.0f)
	}

};

/*
  class MotionUnderGravitation is derived from class Simulation
  It creates 1 mass with mass value 1 kg and sets its velocity to (10.0f, 15.0f, 0.0f) and its position to 
  (-10.0f, 0.0f, 0.0f). The purpose of this application is to apply a gravitational force to the mass and 
  observe the path it follows. The above velocity and position provides a fine projectile path with a 
  9.81 m/s/s downward gravitational acceleration. 9.81 m/s/s is a very close value to the gravitational 
  acceleration we experience on the earth.
*/
class MotionUnderGravitation : public Simulation
{
public:
	Vector3D gravitation;													//the gravitational acceleration

	MotionUnderGravitation(Vector3D gravitation) : Simulation(1, 1.0f)		//Constructor firstly constructs its super class with 1 mass and 1 kg
	{																		//Vector3D gravitation, is the gravitational acceleration
		this->gravitation = gravitation;									//set this class's gravitation
		masses[0]->pos = Vector3D(-10.0f, 0.0f, 0.0f);						//set the position of the mass
		masses[0]->vel = Vector3D(10.0f, 15.0f, 0.0f);						//set the velocity of the mass
	}

	virtual void solve()													//gravitational force will be applied therefore we need a "solve" method.
	{
		for (int a = 0; a < numOfMasses; ++a)								//we will apply force to all masses (actually we have 1 mass, but we can extend it in the future)
			masses[a]->applyForce(gravitation * masses[a]->m);				//gravitational force is as F = m * g. (mass times the gravitational acceleration)
	}
	
};

/*
  class MassConnectedWithSpring is derived from class Simulation
  It creates 1 mass with mass value 1 kg and binds the mass to an arbitrary constant point with a spring. 
  This point is refered as the connectionPos and the spring has a springConstant value to represent its 
  stiffness.
*/
class MassConnectedWithSpring : public Simulation
{
public:
	float springConstant;													//more the springConstant, stiffer the spring force
	Vector3D connectionPos;													//the arbitrary constant point that the mass is connected

	MassConnectedWithSpring(float springConstant) : Simulation(1, 1.0f)		//Constructor firstly constructs its super class with 1 mass and 1 kg
	{
		this->springConstant = springConstant;								//set the springConstant

		connectionPos = Vector3D(0.0f, -5.0f, 0.0f);						//set the connectionPos

		masses[0]->pos = connectionPos + Vector3D(10.0f, 0.0f, 0.0f);		//set the position of the mass 10 meters to the right side of the connectionPos
		masses[0]->vel = Vector3D(0.0f, 0.0f, 0.0f);						//set the velocity of the mass to zero
	}

	virtual void solve()													//the spring force will be applied
	{
		for (int a = 0; a < numOfMasses; ++a)								//we will apply force to all masses (actually we have 1 mass, but we can extend it in the future)
		{
			Vector3D springVector = masses[a]->pos - connectionPos;			//find a vector from the position of the mass to the connectionPos
			masses[a]->applyForce(-springVector * springConstant);			//apply the force according to the famous spring force formulation
		}
	}
	
};
