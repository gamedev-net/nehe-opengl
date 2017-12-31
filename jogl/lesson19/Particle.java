/*
 * Created on Mar 3, 2004
 *
 * @author Irene Kam  (kaminc@cox.net)
 */

import java.util.Random;

/**
 * This class represents a Particle object used in NeHe's lesson 19.  
 * 
 * @author Irene Kam
 */
public class Particle {
   // This Particle's life. Full life has the value 1.0f.
   private float life;
   // Fade speed (i.e. how fast this particle's life decreases).
   private float fade;
   // Red, green, and blue colors for this particle.
   private float red;
   private float green;
   private float blue;
   // X, Y, Z locations for this particle.
   private float xLocation = 0f;
   private float yLocation = 0f;
   private float zLocation = 0f;
   // X, Y, Z directions and speeds for this particle.
   private float xSpeed;
   private float ySpeed;
   private float zSpeed;
   // X, Y, Z gravity on this particle(direction and pull force).
   private float xGravity;
   private float yGravity;
   private float zGravity;
   // The parent object.
   Lesson19 m_oParent;

   /**
    * Creates a Particle instance with it's properties initialized.
    */
   public Particle(Lesson19 parent) {
      m_oParent = parent;
      // Initialize the property values.
      reset(true);
   }

   /**
    * Resets the properties of this particle to their default values.
    * 
    * @param explode A boolean indicating if the particles should have the
    *        "explode" effect when starting out. If true, the particles'
    *        speed is so fast when starting out that they will look like
    *        they are exploding. If false, the particles' speed will not be
    *        fast enough to explode.
    */
   protected void reset(boolean explode) {
      resetCommonProperties();
      // Assign direction and speed for this particle.
      xSpeed = getRandomSpeed(explode);
      ySpeed = getRandomSpeed(explode);
      zSpeed = getRandomSpeed(explode);
      // Assign gravity. Initial gravity is pulling downwards (-y direction).
      xGravity = 0f;
      yGravity = -0.8f;
      zGravity = 0f;
   }

   /**
    * Resets the life, fade, color, and location of this Particle object.    *
    */
   private void resetCommonProperties() {
      // Give the particle full life when created.
      life = 1.0f;
      // Give the particle random fade value.
      fade = getRandomFadeValue();
      // Assign radom red, green and blue values. Instead of using a
      // set of pre-defined colors as was done on Nehe's lesson 19, we are
      // just using totally random colors in this application.
      red = getRandomIntensityValue();
      green = getRandomIntensityValue();
      blue = getRandomIntensityValue();
      // Initial location for the praticle is at 0,0,0.
      xLocation = 0f;
      yLocation = 0f;
      zLocation = 0f;
   }

   /**
    * Restarts this particle. When a particle is restarted, the user 
    * configurable X and Y speeds are taking into account.
    */
   protected void restart() {
      resetCommonProperties();
      Random generator = new Random();
      // Assign direction and speed for this particle.
      xSpeed = m_oParent.getXSpeed() + (float)generator.nextInt(60) - 32f;
      ySpeed = m_oParent.getYSpeed() + (float)generator.nextInt(60) - 30f;
      zSpeed = generator.nextInt(60) - 30f;
   }

   /**
    * Generates a random value for the particle's fade speed.
    * 
    * @return A random float value.
    */
   private float getRandomFadeValue() {
      return (float) (Math.random() * 100) / 1000f + .003f;
   }

   /**
    * Generates a random value form 0.0 to less than 1.0 for the color 
    * intensities.
    * 
    * @return A float between 0f and 1f.
    */
   private float getRandomIntensityValue() {
      return (float)Math.random();
   }

   /**
    * Generates a random float value for the particle's speed.
    * @param explode A boolean indicating if the particle's speed should
    *                be so fast that the particle looks like it's exploding.
    * @return A float value for the speed.
    */
   private float getRandomSpeed(boolean explode) {
      Random generator = new Random();
      // returns a value from -25 to 25 times 10.
      if (explode) {
         return (float) (generator.nextInt(50) - 25f) * 10f;
      } else {
         return (float)generator.nextInt(50) - 25f;
      }
   }

   /**
    * Checks to see if this particle is alive. The particle is alive if
    * it's life is >= 0. Else it's dead.
    * 
    * @return Returns true if particle is alive. Otherwise returns false.
    */
   public boolean isAlive() {
      if (life > 0.0f) {
         return true;
      } else {
         return false;
      }
   }

   /**
    * Retrieves it's blue intensity.
    * 
    * @return A float value for this particle's blue intensity.
    */
   public float getBlue() {
      return blue;
   }

   /**
    * Retrieves this particles' fade speed (how fast the particle dies).
    * 
    * @return A float value for this particle's fade speed.
    */
   public float getFade() {
      return fade;
   }

   /**
    * Retrieves this particle's green intensity.
    * 
    * @return A float value for this particle's green intensity.
    */
   public float getGreen() {
      return green;
   }

   /**
    * Retrieves this particle's life.
    * 
    * @return A float value for this particle's life.
    */
   public float getLife() {
      return life;
   }

   /**
    * Retrieves this particle's red intensity.
    * 
    * @return A float value for this particle's red intensity.
    */
   public float getRed() {
      return red;
   }

   /**
    * Retrieves this particle's pull along the x direction.
    * 
    * @return A float value for this particle's gravitational pull in the
    *          x direction.
    */
   public float getXGravity() {
      return xGravity;
   }

   /**
    * Retrieves this particle's current location on the x axis.
    * 
    * @return A float value for this particle's current location on the x
    *          axis.
    */
   public float getXLocation() {
      return xLocation;
   }

   /**
    * Retrieves this particle's speed along the x direction.
    * 
    * @return A float value for this particle's speed along the x direction.
    */
   public float getXSpeed() {
      return xSpeed;
   }

   /**
    * Retrieves this particle's gravitational pull in the y direction.
    * 
    * @return A float value for this particle's pull in the y direction.
    */
   public float getYGravity() {
      return yGravity;
   }

   /**
    * Retrieves this particle's current location on the y axis.
    * 
    * @return A float value for this particle's location on the y axis.
    */
   public float getYLocation() {
      return yLocation;
   }

   /**
    * Retrieves this particle's speed in the y direction.
    * 
    * @return A float value for this particle's speed in the y direction.
    */
   public float getYSpeed() {
      return ySpeed;
   }

   /**
    * Retrieves this particle's gravitational pull in the z direction.
    * 
    * @return A float value for this particle's pull in the z direction.
    */
   public float getZGravity() {
      return zGravity;
   }

   /**
    * Retrieves this particle's current location on the z axis.
    * 
    * @return A float value for this particle's location on the z axis.
    */
   public float getZLocation() {
      return zLocation;
   }

   /**
    * Retrieves this particle's speed in the z direction.
    * 
    * @return A float value for this particle's speed in the z direction.
    */
   public float getZSpeed() {
      return zSpeed;
   }

   /**
    * Sets this particle's blue intensity.
    * 
    * @parm A float value for this particle's blue intensity.
    */
   public void setBlue(float f) {
      blue = f;
   }

   /**
    * Sets this particle's fade speed.
    * 
    * @param A float value for the particle's fade speed.
    */
   public void setFade(float f) {
      fade = f;
   }

   /**
    * Sets this particle's green intensity.
    * 
    * @param A float value for this particle's green intensity.
    */
   public void setGreen(float f) {
      green = f;
   }

   /**
    * Sets this particle's life.
    * 
    * @param A float value for this particle's life.
    */
   public void setLife(float f) {
      life = f;
   }

   /**
    * Sets this particle's red intensity.
    * 
    * @param A float value for this particle's red intensity.
    */
   public void setRed(float f) {
      red = f;
   }

   /**
    * Sets this particle's gravitational pull in the X direction.
    * 
    * @param A float value for this particle's pull in the x direction.
    */
   public void setXGravity(float f) {
      xGravity = f;
   }

   /**
    * Sets this particle's current location on the x axis.
    * 
    * @param A float value for this particle's location on the x axis.
    */
   public void setXLocation(float f) {
      xLocation = f;
   }

   /**
    * Sets this particle's speed along the x axis.
    * 
    * @param A float value for this particle's speed along the x axis.
    */
   public void setXSpeed(float f) {
      xSpeed = f;
   }

   /**
    * Sets this particle's gravitational pull in the y direction.
    * 
    * @param A float value for this particle's pull along the y axis.
    */
   public void setYGravity(float f) {
      yGravity = f;
   }

   /**
    * Sets this particle's current location on the y axis.
    * 
    * @param A float value for this particle's location on the y axis.
    */
   public void setYLocation(float f) {
      yLocation = f;
   }

   /**
    * Sets this particle's speed along the y axis.
    * 
    * @param A float value for this particle's speed along the y axis.
    */
   public void setYSpeed(float f) {
      ySpeed = f;
   }

   /**
    * Sets this particle's gravitational pull along the z axis.
    * 
    * @param A float value for this particle's pull along the z axis.
    */
   public void setZGravity(float f) {
      zGravity = f;
   }

   /**
    * Sets this particle's current location on the z axis.
    * 
    * @param A float value for this particle's location on the z axis.
    */
   public void setZLocation(float f) {
      zLocation = f;
   }

   /**
    * Sets this particle's current speed along the z axis.
    * 
    * @param A float value for this particle's speed along the z axis.
    */
   public void setZSpeed(float f) {
      zSpeed = f;
   }

}
