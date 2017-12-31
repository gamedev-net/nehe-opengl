/**
 * Created on Mar 7, 2004
 * 
 * @author Irene Kam (kaminc@cox.net)
 */

// Import classes used for reading in the byte data for images.
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
// Import classes for OpenGL.
import net.java.games.jogl.Animator;
import net.java.games.jogl.GLException;
import net.java.games.jogl.GLEventListener;
import net.java.games.jogl.GL;
import net.java.games.jogl.GLDrawable;
import net.java.games.jogl.GLU;

/**
 * This class provides handling for OpenGL events in NeHe's Lesson 19.
 * 
 * @author Irene Kam
 *
 */
public class GLEventHandler implements GLEventListener {
   // The parent object which employs this event handler.
   private Lesson19 m_oParent;
   // Create an array of 1 elements holding the texture names.
   private int[] m_aTextures = new int[1];
   // Array of bytes from the texture image.
   private byte[] m_aImagePixelBytes;
   // Buffered image for the texture.
   private BufferedImage m_oBufferedImage;
   // Number of particles to display.
   private static final int MAX_PARTICLES = 1000;
   // The array of particles.
   private Particle[] m_aParticles = new Particle[MAX_PARTICLES];
   // The animator to drive the display method.
   private Animator m_oAnimator;

   /**
    * Constructor for this event handler.
    * 
    * @param parent The parent object which employs this event handler.
    */
   public GLEventHandler(Lesson19 parent) {
      m_oParent = parent;
   }

   /**
    * Called only once, after OpenGL is initialized. Perform one time 
    * initialization tasks here.
    * 
    * @param drawable The object capablable of drawing OpenGL objects.
    */
   public void init(GLDrawable drawable) {
      // Obtain the GL instance so we can perform OpenGL functions.
      GL gl = drawable.getGL();
      // Set up the animator for the drawable.
      m_oAnimator = new Animator(drawable);
      // Enable smooth shading.
      gl.glShadeModel(GL.GL_SMOOTH);
      // Bind texture to 2D.
      gl.glBindTexture(GL.GL_TEXTURE_2D, m_aTextures[0]);
      // Set the background / clear color.
      gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);
      // Clear the depth
      gl.glClearDepth(1.0);
      // Disable depth testing.
      gl.glDisable(GL.GL_DEPTH_TEST);
      // Type of depth testing.
      //gl.glDepthFunc(GL.GL_LEQUAL);
      // Enable blending and specify blening function.
      gl.glEnable(GL.GL_BLEND);
      gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
      // Get nice perspective calculations. 
      gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);
      // Nice point smoothing.
      gl.glHint(GL.GL_POINT_SMOOTH_HINT, GL.GL_NICEST);
      // Enable texture mapping.
      gl.glEnable(GL.GL_TEXTURE_2D);
      // Load the texture image.
      loadBMP("data/Particle.jpg");
      // Set up texture mappings from the image we have loaded.
      loadGLTextures(drawable);
      // Create and initialize the 1000 particles.
      initParticles();
      // Reset the OpenGL drawable first.
      resizeGLScene(
         drawable,
         drawable.getSize().getWidth(),
         drawable.getSize().getHeight());
      // Start the animator so our scene is animated.
      m_oAnimator.start();
   }

   /**
    * Causes OpenGL rendering to the given GLDrawable. In this application,
    * draws the 1000 particles on the screen.
    * 
    * @param drawable The OpenGL drawable used to display the particles. 
    */
   public void display(GLDrawable drawable) {
      // Obtain the GL instance so we can perform OpenGL functions.
      GL gl = drawable.getGL();
      // Clear the screen and depth buffer.
      gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
      // Reset the view.
      gl.glLoadIdentity();

      Particle particle = null;
      // Test if we should reset the particles.
      if (m_oParent.resetParticles) {
         // We should reset the particles.
         for (int i = 0; i < MAX_PARTICLES; i++) {
            ((Particle)m_aParticles[i]).reset(true);
         }
         m_oParent.resetParticles = false;
      }
      
      // Loop through the Particles array and draw each particle.
      for (int i = 0; i < MAX_PARTICLES; i++) {
         // Each particle is handled differently depending on whether it's
         // alive or not.
         particle = m_aParticles[i];
         if (particle.isAlive()) {
            // This particular particle is alive. 
            handleLiveParticle(gl, particle);
         } else {
            // This particular particle is dead.
            handleDeadParticle(gl, particle);
         }
      }
   }

   public void reshape(
      GLDrawable drawable,
      int x,
      int y,
      int width,
      int height) {

   }

   /**
    * Called when the display device has been changed. Not used in this
    * application.
    */
   public void displayChanged(
      GLDrawable drawable,
      boolean modeChanged,
      boolean deviceChanged) {
      System.out.println("In displayChanged() method.");
   }

   /**
    * Resets the OpenGL's viewport, projection matrix, etc.
    * 
    * @param width Current width of window.
    * @param height Current height of window.
    */
   private void resizeGLScene(
      GLDrawable drawable,
      double width,
      double height) {
      // Obtain the GL and GLU instance so we can perform OpenGL functions.
      GL gl = drawable.getGL();
      GLU glu = drawable.getGLU();

      // Make sure height is > 0.
      if (height == 0) {
         height = 1;
      }

      // Reset view port.
      Double widthDouble = new Double(width);
      Double heightDouble = new Double(height);
      gl.glViewport(0, 0, widthDouble.intValue(), heightDouble.intValue());

      // Select and reset the Projection Matrix.
      gl.glMatrixMode(GL.GL_PROJECTION);
      gl.glLoadIdentity();

      // Calculate The Aspect Ratio Of The Window
      glu.gluPerspective(45.0d, width / height, 0.1d, 100.0d);

      gl.glMatrixMode(GL.GL_MODELVIEW); // Select The Modelview Matrix
      gl.glLoadIdentity();
   }

   /**
    * Loads in the texture image and retrieve it's bytes as an array.
    * 
    * @param filename The path to the texture image file.
    */
   private void loadBMP(String filename) {
      // Check if file path given exists. If yes, load in the image.
      File imageFile = new File(filename);
      if (imageFile.exists() && imageFile.isFile()) {
         try {
            // Create a buffered image from the file.
            m_oBufferedImage = ImageIO.read(imageFile);
         } catch (IOException e) {
            // Some error occurred. Show error.
            m_oParent.showError(
               e,
               "Error reading image file: " + e.getMessage());
         }
         // Get the bytes to the image file.
         m_aImagePixelBytes =
            ((DataBufferByte)m_oBufferedImage.getRaster().getDataBuffer())
               .getData();
      } else {
         // The path given is not a file. Show error and exit application.
         m_oParent.showError(
            null,
            "The image file does not exist or is not a file: '"
               + filename
               + "'");
         m_oParent.exitProgram();
      }
   }

   /**
    * Creates OpenGL textures using the pixels loaded from the image file.
    *
    * @param drawable The OpenGL drawable used to display objects.
    */
   private void loadGLTextures(GLDrawable drawable) {
      GL gl = drawable.getGL();
      GLU glu = drawable.getGLU();
      // Set up OpenGL to generate 1 texture.
      gl.glGenTextures(1, m_aTextures);
      // Generate nice texture.
      generateTexture(gl, 0, GL.GL_LINEAR, GL.GL_LINEAR);
   }

   /**
    * Generates OpenGL textures using the given parameters.
    * 
    * @param gl The GL instance.
    * @param id The texture ID.
    * @param filterTypeMin The filter type to use for image is smaller 
    *        than the object.
    * @param filterTypeMax The filter type to use when image is larger 
    *        than the object.
    */
   private void generateTexture(
      GL gl,
      int id,
      int filterTypeMin,
      int filterTypeMax) {
      // Bind the texture to 2D
      gl.glBindTexture(GL.GL_TEXTURE_2D, m_aTextures[id]);
      // Create the actual texture passing in the pixel byte array.
      gl.glTexImage2D(
         GL.GL_TEXTURE_2D,
         0,
         3,
         m_oBufferedImage.getWidth(),
         m_oBufferedImage.getHeight(),
         0,
         GL.GL_RGB,
         GL.GL_UNSIGNED_BYTE,
         m_aImagePixelBytes);
      gl.glTexParameteri(
         GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MAG_FILTER,
         filterTypeMax);
      gl.glTexParameteri(
         GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MIN_FILTER,
         filterTypeMin);
   }

   /**
    * Initializes the array of particles.
    */
   private void initParticles() {
      // Create new particles for the array and ask each particle 
      // to initialize itself.
      for (int i = 0; i < MAX_PARTICLES; i++) {
         m_aParticles[i] = new Particle(m_oParent);
      }
   }

   /**
    * Draw the live particle using triangle strips.
    * 
    * @param gl The OpenGL reference.
    * @param particle The Particle object to display.
    */
   private void handleLiveParticle(GL gl, Particle particle) {
      // The current location of the particle; Need to account for the zoom
      // distance so user can zoom in and out the particles.
      float x = particle.getXLocation();
      float y = particle.getYLocation();
      float z = particle.getZLocation() + m_oParent.m_fZoom;

      // Set the color to draw this particle. The particle's life value
      // will act as the alpha.
      gl.glColor4f(
         particle.getRed(),
         particle.getGreen(),
         particle.getBlue(),
         particle.getLife());
      // Draw the particle using triangle strips.
      gl.glBegin(GL.GL_TRIANGLE_STRIP);
      // Map the texture and create the vertices for the particle.
      gl.glTexCoord2d(1, 1);
      gl.glVertex3f(x + .5f, y + .5f, z);
      gl.glTexCoord2d(0, 1);
      gl.glVertex3f(x - .5f, y + .5f, z);
      gl.glTexCoord2d(1, 0);
      gl.glVertex3f(x + .5f, y - .5f, z);
      gl.glTexCoord2d(0, 0);
      gl.glVertex3f(x - .5f, y - .5f, z);
      gl.glEnd();

      // Update the particles' properties.
      updateParticle(particle);
   }

   /**
    * Updates the properties of the given particle. For example, its life,
    * location, etc. must be updated.
    * 
    * @param particle The Particle to be updated.
    */
   private void updateParticle(Particle particle) {
      // Update the particles' life. Each particle's life decreases.
      particle.setLife(particle.getLife() - particle.getFade());
      // Update the particles's location. The particle's new location is
      // equal to it's current location + it's directional speed/slowdown.
      particle.setXLocation(
         particle.getXLocation()
            + particle.getXSpeed() / (m_oParent.m_fSlowDown * 1000));
      particle.setYLocation(
         particle.getYLocation()
            + particle.getYSpeed() / (m_oParent.m_fSlowDown * 1000));
      particle.setZLocation(
         particle.getZLocation()
            + particle.getZSpeed() / (m_oParent.m_fSlowDown * 1000));
      // Update the particle's directional speed. It's directional speed
      // is affected by the direction's gravitional pull.
      particle.setXSpeed(particle.getXSpeed() + particle.getXGravity());
      particle.setYSpeed(particle.getYSpeed() + particle.getYGravity());
      particle.setZSpeed(particle.getZSpeed() + particle.getZGravity());
      // Update the particle's X and Y gravitional pulls. The gravitational
      // pulls can be modified by the user.
      particle.setXGravity(
         particle.getXGravity() + m_oParent.m_fXGravityChange);
      particle.setYGravity(
         particle.getYGravity() + m_oParent.m_fYGravityChange);
   }

   /**
    * Handles the dead particle given. A dead particle is restarted by
    * given it full life, new color, new speeds, etc.
    * 
    * @param gl The OpenGL reference.
    * @param particle The dead particle to be processed.
    */
   private void handleDeadParticle(GL gl, Particle particle) {
      // Ask the particle to restart itself.
      particle.restart();
   }

   /**
    * Stops the Animator. 
    */
   protected void stopAnimator() {
      m_oAnimator.stop();
   }

   /**
    * Starts the Animator.
    */
   protected void startAnimator() {
      try {
         m_oAnimator.start();
      } catch (GLException e) {
         // Ignore error. Sometimes an exception will be thrown saying
         // the animator is already started.
      }
   }
}
