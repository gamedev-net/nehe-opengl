/**************************************************************************

  File: Physics2.h  

  Prepared by Erkin Tunca for nehe.gamedev.net

**************************************************************************/

#include "Physics1.h"									//Physics1.h is a must for Physics2.h simulations

class Spring											//An object to represent a spring with inner friction binding two masses. The spring 
														//has a normal length (the length that the spring does not exert any force)
{
public:
	Mass* mass1;										//The first mass at one tip of the spring
	Mass* mass2;										//The second mass at the other tip of the spring

	float springConstant;								//A constant to represent the stiffness of the spring
	float springLength;									//The length that the spring does not exert any force
	float frictionConstant;								//A constant to be used for the inner friction of the spring

	Spring(Mass* mass1, Mass* mass2, 
		float springConstant, float springLength, float frictionConstant)		//Constructor
	{
		this->springConstant = springConstant;									//set the springConstant
		this->springLength = springLength;										//set the springLength
		this->frictionConstant = frictionConstant;								//set the frictionConstant

		this->mass1 = mass1;													//set mass1
		this->mass2 = mass2;													//set mass2
	}

	void solve()																	//solve() method: the method where forces can be applied
	{
		Vector3D springVector = mass1->pos - mass2->pos;							//vector between the two masses
		
		float r = springVector.length();											//distance between the two masses

		Vector3D force;																//force initially has a zero value
		
		if (r != 0)																	//to avoid a division by zero check if r is zero
			force += (springVector / r) * (r - springLength) * (-springConstant);	//the spring force is added to the force

		force += -(mass1->vel - mass2->vel) * frictionConstant;						//the friction force is added to the force
																					//with this addition we obtain the net force of the spring

		mass1->applyForce(force);													//force is applied to mass1
		mass2->applyForce(-force);													//the opposite of force is applied to mass2
	}

};

/*
  class RopeSimulation is derived from class Simulation (see Physics1.h). It simulates a rope with 
  point-like particles binded with springs. The springs have inner friction and normal length. One tip of 
  the rope is stabilized at a point in space called "Vector3D ropeConnectionPos". This point can be 
  moved externally by a method "void setRopeConnectionVel(Vector3D ropeConnectionVel)". RopeSimulation 
  creates air friction and a planer surface (or ground) with a normal in +y direction. RopeSimulation 
  implements the force applied by this surface. In the code, the surface is refered as "ground".
*/
class RopeSimulation : public Simulation				//An object to simulate a rope interacting with a planer surface and air
{
public:
	Spring** springs;									//Springs binding the masses (there shall be [numOfMasses - 1] of them)

	Vector3D gravitation;								//gravitational acceleration (gravity will be applied to all masses)

	Vector3D ropeConnectionPos;							//A point in space that is used to set the position of the 
														//first mass in the system (mass with index 0)
	
	Vector3D ropeConnectionVel;							//a variable to move the ropeConnectionPos (by this, we can swing the rope)

	float groundRepulsionConstant;						//a constant to represent how much the ground shall repel the masses
	
	float groundFrictionConstant;						//a constant of friction applied to masses by the ground
														//(used for the sliding of rope on the ground)
	
	float groundAbsorptionConstant;						//a constant of absorption friction applied to masses by the ground
														//(used for vertical collisions of the rope with the ground)
	
	float groundHeight;									//a value to represent the y position value of the ground
														//(the ground is a planer surface facing +y direction)

	float airFrictionConstant;							//a constant of air friction applied to masses

	RopeSimulation(										//a long long constructor with 11 parameters starts here
		int numOfMasses,								//1. the number of masses
		float m,										//2. weight of each mass
		float springConstant,							//3. how stiff the springs are
		float springLength,								//4. the length that a spring does not exert any force
		float springFrictionConstant,					//5. inner friction constant of spring
		Vector3D gravitation,							//6. gravitational acceleration
		float airFrictionConstant,						//7. air friction constant
		float groundRepulsionConstant,					//8. ground repulsion constant
		float groundFrictionConstant,					//9. ground friction constant
		float groundAbsorptionConstant,					//10. ground absorption constant
		float groundHeight								//11. height of the ground (y position)
		) : Simulation(numOfMasses, m)					//The super class creates masses with weights m of each
	{
		this->gravitation = gravitation;
		
		this->airFrictionConstant = airFrictionConstant;

		this->groundFrictionConstant = groundFrictionConstant;
		this->groundRepulsionConstant = groundRepulsionConstant;
		this->groundAbsorptionConstant = groundAbsorptionConstant;
		this->groundHeight = groundHeight;

		for (int a = 0; a < numOfMasses; ++a)			//To set the initial positions of masses loop with for(;;)
		{
			masses[a]->pos.x = a * springLength;		//Set x position of masses[a] with springLength distance to its neighbor
			masses[a]->pos.y = 0;						//Set y position as 0 so that it stand horizontal with respect to the ground
			masses[a]->pos.z = 0;						//Set z position as 0 so that it looks simple
		}

		springs = new Spring*[numOfMasses - 1];			//create [numOfMasses - 1] pointers for springs
														//([numOfMasses - 1] springs are necessary for numOfMasses)
		
		for (a = 0; a < numOfMasses - 1; ++a)			//to create each spring, start a loop
		{
			//Create the spring with index "a" by the mass with index "a" and another mass with index "a + 1".
			springs[a] = new Spring(masses[a], masses[a + 1], 
				springConstant, springLength, springFrictionConstant);
		}
	}

	void release()										//release() is overriden because we have springs to delete
	{
		Simulation::release();							//Have the super class release itself

		for (int a = 0; a < numOfMasses - 1; ++a)		//to delete all springs, start a loop
		{
			delete(springs[a]);
			springs[a] = NULL;
		}
		
		delete(springs);
		springs = NULL;
	}

	void solve()										//solve() is overriden because we have forces to be applied
	{
		for (int a = 0; a < numOfMasses - 1; ++a)		//apply force of all springs
		{
			springs[a]->solve();						//Spring with index "a" should apply its force
		}

		for (a = 0; a < numOfMasses; ++a)				//Start a loop to apply forces which are common for all masses
		{
			masses[a]->applyForce(gravitation * masses[a]->m);				//The gravitational force
			
			masses[a]->applyForce(-masses[a]->vel * airFrictionConstant);	//The air friction

			if (masses[a]->pos.y < groundHeight)		//Forces from the ground are applied if a mass collides with the ground
			{
				Vector3D v;								//A temporary Vector3D

				v = masses[a]->vel;						//get the velocity
				v.y = 0;								//omit the velocity component in y direction

				//The velocity in y direction is omited because we will apply a friction force to create 
				//a sliding effect. Sliding is parallel to the ground. Velocity in y direction will be used
				//in the absorption effect.
				masses[a]->applyForce(-v * groundFrictionConstant);		//ground friction force is applied

				v = masses[a]->vel;						//get the velocity
				v.x = 0;								//omit the x and z components of the velocity
				v.z = 0;								//we will use v in the absorption effect
				
				//above, we obtained a velocity which is vertical to the ground and it will be used in 
				//the absorption force

				if (v.y < 0)							//let's absorb energy only when a mass collides towards the ground
					masses[a]->applyForce(-v * groundAbsorptionConstant);		//the absorption force is applied
				
				//The ground shall repel a mass like a spring. 
				//By "Vector3D(0, groundRepulsionConstant, 0)" we create a vector in the plane normal direction 
				//with a magnitude of groundRepulsionConstant.
				//By (groundHeight - masses[a]->pos.y) we repel a mass as much as it crashes into the ground.
				Vector3D force = Vector3D(0, groundRepulsionConstant, 0) * 
					(groundHeight - masses[a]->pos.y);

				masses[a]->applyForce(force);			//The ground repulsion force is applied
			}
				
		}


	}

	void simulate(float dt)								//simulate(float dt) is overriden because we want to simulate 
														//the motion of the ropeConnectionPos
	{
		Simulation::simulate(dt);						//the super class shall simulate the masses

		ropeConnectionPos += ropeConnectionVel * dt;	//iterate the positon of ropeConnectionPos

		if (ropeConnectionPos.y < groundHeight)			//ropeConnectionPos shall not go under the ground
		{
			ropeConnectionPos.y = groundHeight;
			ropeConnectionVel.y = 0;
		}

		masses[0]->pos = ropeConnectionPos;				//mass with index "0" shall position at ropeConnectionPos
		masses[0]->vel = ropeConnectionVel;				//the mass's velocity is set to be equal to ropeConnectionVel
	}

	void setRopeConnectionVel(Vector3D ropeConnectionVel)	//the method to set ropeConnectionVel
	{
		this->ropeConnectionVel = ropeConnectionVel;
	}

};