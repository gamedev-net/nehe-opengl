/*
 * @author Irene Kam (kaminc@cox.net)
 */


// Import classes needed for the window environment.
import java.awt.BorderLayout;
import java.awt.DisplayMode;
import java.awt.Frame;
import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;
import java.awt.HeadlessException;
import java.awt.IllegalComponentStateException;
import javax.swing.JOptionPane;
// Import classes needed for JOGL.
import net.java.games.jogl.GLCanvas;
import net.java.games.jogl.GLDrawableFactory;
import net.java.games.jogl.GLCapabilities;

/**
 * JOGL port for NeHe OpenGL Lesson 19: Particle Engine
 */
public class Lesson19 {
   //	The height and width for the window, if in windowed mode.
   private final int WIN_HEIGHT = 400;
   private final int WIN_WIDTH = 500;
   // The color depth to use.
   private int m_nBits = 16;
   // Variable to record screen mode: full screen or windowed mode.
   private static boolean m_bIsFullScreen = false;
   private DisplayMode m_oOldDisplayMode;
   // The main window.
   private Frame m_oMainWindow;
   // The GL canvas used to display all OpenGL objects.
   private GLCanvas m_oCanvas;
   // The KeyListener used to process key pressed/released events.
   private KeyHandler m_oKeyHandler;
   // The GLEventListener used to process OpenGL events.
   private GLEventHandler m_oGLEventHandler;
   // The zoom distance. Used to zoom the objects in and out on the Z axis.
   protected float m_fZoom = -30f;
   // Current texture filter. This counter is used to signify which texture
   // mapping we will use.
   protected int m_nCurrentFilter = 0;
   // Change in y gravitional pull.
   protected float m_fYGravityChange = 0f;
   // Change in x gravitional pull.
   protected float m_fXGravityChange = 0f;
   // Variable to slow down/speed up particles. The higher the value, 
   // the slower the particles will be. The smaller the value, the faster 
   // the particles will travel.
   protected float m_fSlowDown = 2f;
   // Reset the particles? Particles are reset after they become "dead"
   // (i.e. the particle's life becomes <= 0).
   protected boolean resetParticles = false;
   // Variable for user to control the particles' speed in the X direction.
   // Depending on the value of this variable, the user can even change
   // the direction (positive X or negative X) the particles travel.
   protected float m_fXSpeed;
   // Variable for user to control the particles' speed in the Y direction.
   protected float m_fYSpeed;

   /**
    * Main method which prompts the user for screen mode (full? windowed?)
    * and creates an instance of the OpenGL window.
    */
   public static void main(String[] args) {
      // Create the OpenGL window displaying particles.
      new Lesson19();
   }

   /**
    * Constructor for this class.
    */
   public Lesson19() {
      // Ask the user which screen mode they prefer.
      promptScreenMode();
      // Create a KeyListener to handle key events.
      m_oKeyHandler = new KeyHandler(this);
      // Create a GL Event Listener.
      m_oGLEventHandler = new GLEventHandler(this);
      // Create the OpenGL window used to display OpenGL objects.
      createGLWindow("JOGL Port for NeHe OpenGL Lession 19", WIN_WIDTH, WIN_HEIGHT, m_nBits);
      // Show window in full screen mode if needed.
      if (m_oMainWindow != null) {
         if (m_bIsFullScreen) {
            // User wants to display in full screen mode.
            setFullScreenMode(getDefaultScreen());
         } else {
            // User wants to display in windowed mode.
            setWindowedMode(getDefaultScreen());
         }
         // Request focus to the canvas so it can intercept KeyEvents.
         m_oCanvas.requestFocus();
      }
   }

   /**
     * Brings up a JOptionPane dialog to prompt user for preferred window
     * mode (full screen? windowed mode?). 
     */
   private void promptScreenMode() {
      String message = "Run application in full screen mode?";
      int option =
         JOptionPane.showOptionDialog(
            null,
            message,
            "Full Screen Prompt",
            JOptionPane.YES_NO_CANCEL_OPTION,
            JOptionPane.QUESTION_MESSAGE,
            null,
            null,
            null);
      if (option == JOptionPane.YES_OPTION) {
         // The user would like to run application in full screen mod.
         m_bIsFullScreen = true;
      } else if (option == JOptionPane.NO_OPTION) {
         // The user would like to run application in windowed mode.
         m_bIsFullScreen = false;
      } else if (option == JOptionPane.CANCEL_OPTION) {
         // The user wants to exit the application.
         System.exit(0);
      }
   }

   /**
    * Creates the OpenGL window using the given parameters.
    * 
    * @param title  The title of the window.
    * @param width  The width of the window.
    * @param height The height of the window.
    * @param bit	 The number of bits to use for color.
    */
   private void createGLWindow(String title, int width, int height, int bit) {
      // First, create a Frame which is initialized to display OpenGL
      // components.
      m_oMainWindow = new Frame();
      // Now create components inside this frame which is OpenGL enabled. 
      createGLEnabledFrame(width, height, bit);

      if (!m_bIsFullScreen) {
         // If not in full screen mode, then set the window's title.
         m_oMainWindow.setTitle(title);
      }
   }

   /**
    * Initializes the main window frame with JOGL components
    * which are able to display OpenGL objects. 
    * 
    * @param width  The width of the window.
    * @param height The height of hte window.
    * @param bit	 The number of bits to use for color.
    * 
    */
   private void createGLEnabledFrame(int width, int height, int bit) {
      // Create a GLCapabilities.
      GLCapabilities capabilities = new GLCapabilities();
      // Try to set the color bits to use.
      capabilities.setDepthBits(bit);
      // Create a GLCanvas from the factory.
      m_oCanvas = GLDrawableFactory.getFactory().createGLCanvas(capabilities);
      // Add a GLEventListener to the canvas, to handle window
      // resize and repaint. Also add the KeyListener to the canvas so it
      // an handle key pressed/released events.
      m_oCanvas.addGLEventListener(m_oGLEventHandler);
      m_oCanvas.addKeyListener(m_oKeyHandler);
      // Set the width and height of the canvas (i.e. the display area).
      m_oCanvas.setSize(width, height);
      m_oMainWindow.add(m_oCanvas, BorderLayout.CENTER);
   }

   /**
    * Closes the main window and exits the program.
    */
   protected void exitProgram() {
      // If in full screen mode, then toggle back to windowed mode first.
      /*
      if (m_bIsFullScreen) {
         toggleWindowMode();
      }
      
      if (m_oMainWindow != null) {
         m_oMainWindow.dispose();
      } */

      m_oGLEventHandler.stopAnimator();
      System.exit(0);
   }

   /**
    * Retrieves the default screen on the current system.
    * 
    * @return A GraphicsDevice object for the default screen.
    * @throws HeadlessException If the current system does not support 
    *          a display.
    */
   private GraphicsDevice getDefaultScreen() throws HeadlessException {
      // Get the local graphic environment.
      GraphicsEnvironment graphicsEnv =
         GraphicsEnvironment.getLocalGraphicsEnvironment();
      // Get the default screen device.
      return graphicsEnv.getDefaultScreenDevice();
   }

   /**
    * Toggles the application window between full screen mode
    * and windowed mode. If the application is in full screen mode, then
    * change it to windowed mode. If the app is in windowed mode, then 
    * change it to full screen mode.
    */
   protected void toggleWindowMode() {
      // Get the local graphic environment.
      GraphicsEnvironment graphicsEnv =
         GraphicsEnvironment.getLocalGraphicsEnvironment();
      GraphicsDevice defaultScreen = null;

      try {
         // Get the default screen device.
         defaultScreen = getDefaultScreen();
      } catch (HeadlessException eHeadless) {
         // Alright, where did the head go??!! Must have been eaten by 
         // Diablo ... or was it Baal??
         showError(
            eHeadless,
            "Cannot switch between windowed and full "
               + "screen mode: "
               + eHeadless.getMessage());
         return;
      }
      // Must stop the Animator thread before switching window modes, or
      // else the JOGL GLException will be thrown (error swapping buffers).
      m_oGLEventHandler.stopAnimator();
      if (defaultScreen != null) {
         if (!m_bIsFullScreen) {
            // Current window is not in full screen mode. Try to set it to
            // full screen mode.
            setFullScreenMode(defaultScreen);
         } else {
            // Current window is in full screen mode. Try to set it back to
            // windowed mode.
            setWindowedMode(defaultScreen);
         }
      }
      // Start up animator again.
      m_oGLEventHandler.startAnimator();
   }

   /**
    * Attempts to set the main window to windowed mode.
    * 
    * @param defaultScreen The default screen where the window resides.
    */
   private void setWindowedMode(GraphicsDevice defaultScreen) {
      // Reset original display mode. We can only change the display mode
      // when in full screen mode.
      if (defaultScreen.isDisplayChangeSupported()) {
         defaultScreen.setDisplayMode(m_oOldDisplayMode);
      }

      try {
         // Set the window to undisplayable first.
         m_oMainWindow.dispose();
         // Set window decorated.
         setWindowUndecorated(false);
         defaultScreen.setFullScreenWindow(null);
         // Since window is in windowed mode, make it resizable again.
         m_oMainWindow.setResizable(true);
         m_bIsFullScreen = false;
         // Set the main window to displayable again.
         m_oMainWindow.pack();
         m_oMainWindow.validate();
         m_oMainWindow.setVisible(true);
         m_oCanvas.requestFocus();
         m_oMainWindow.setSize(WIN_WIDTH, WIN_HEIGHT);
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   /**
    * Attempts to set the main window to full screen mode.
    * 
    * @param defaultScreen The default screen where the window resides.
    */
   private void setFullScreenMode(GraphicsDevice defaultScreen) {
      if (defaultScreen.isFullScreenSupported()) {
         // Record the original display mode first, so when we toggle
         // window back to windowed mode, we can restore the original
         // display mode (window size, etc.);
         m_oOldDisplayMode = defaultScreen.getDisplayMode();

         try {
            // Make sure window is undisplayable first.
            m_oMainWindow.dispose();
            // Turn off decorations on window.
            setWindowUndecorated(true);
            // Turn off resizing in full screen mode.
            m_oMainWindow.setResizable(false);
            // Set window full screen.
            defaultScreen.setFullScreenWindow(m_oMainWindow);
            m_oCanvas.requestFocus();
            // Validate the window
            m_oMainWindow.validate();
            m_bIsFullScreen = true;
         } catch (Exception e) {
            e.printStackTrace();
            // Some error occurred. Switch back to windowed mode then 
            // show error.
            System.out.println(
               "Error while attempting to switch to full screen"
                  + " mode: \n"
                  + e.getMessage());
         } finally {
            //defaultScreen.setFullScreenWindow(null);
         }
      } else {
         // Full screen mode is not supported. Show error.
         System.out.println(
            "Full screen mode is not supported on this device.");
      }
   }

   /**
    * Turns on/off the decorated property of the main window by first
    * making the window undisplayable, then set the decorated property.
    * 
    * NOTES: After this method has been executed successfully, the window
    *    will be in the undisplayable state. It is the responsibility of
    *    the calling method to enable the displayability of the window 
    *    again.
    * 
    * @param decorated A boolean indicating if the window should be
    *        decorated (i.e. show title bar, etc.)
    */
   private void setWindowUndecorated(boolean decorated) {
      // Test if the main window is displayable. If so, make it 
      // undisplayable before setting it's decorated property.
      if (m_oMainWindow.isDisplayable()) {
         System.out.println(
            "In setWindowUndecorated(), window is displayable. Disposing "
               + "window now to make it undisplayable ....");
         m_oMainWindow.dispose();
      }
      // The main window should now be undisplayable. Set its decorated
      // property.
      try {
         // Turn on or off the decorated property.
         m_oMainWindow.setUndecorated(decorated);
      } catch (IllegalComponentStateException e) {
         System.out.println(
            "Error while setting window decorated property. " + e.getMessage());
      }
   }

   /**
    * Displays error messages by popping up an error dialog box.
    * 
    * @param error  The error generated. Can be null. If error is null, then
    *        displays the string represented by the param 'errorMessage'.
    * @param errorMessage Any special error messages to display.  If errorMessage
    *        is null, then display the message associated with the exception.
    */
   protected void showError(Exception error, String errorMessage) {
      String displayMessage = "Error occurred:\n";
      if (error != null) {
         // Print stack trace if exception is not null.
         error.printStackTrace();
      }
      if ((errorMessage != null) && (!errorMessage.trim().equals(""))) {
         // There are some special error messages to display.
         displayMessage += errorMessage;
      } else if (error != null) {
         // No special error messages to display. Display the error message
         // associated with the exception.
         displayMessage += error.getMessage();
      }

      //if (!m_bIsFullScreen) {
      // If in windowed mode, show the modal error using a popup dialog.
      JOptionPane.showMessageDialog(
         m_oMainWindow,
         displayMessage,
         "Error",
         JOptionPane.ERROR_MESSAGE);
      //} 
   }

   /**
    * Toggles the currently displayed texture. The counter m_nCurrentFilter
    * is used to select which texture filter to use. We will create 3 
    * texture mappings later on in the application. Therefore, the counter
    * will range from 0 to 2, inclusive. Each time this method is called,
    * the counter will increase by 1.
    */
   protected void toggleFilter() {
      if (m_nCurrentFilter < 2) {
         m_nCurrentFilter += 1;
      } else {
         m_nCurrentFilter = 0;
      }
   }

   /**
    * Changes the downward pull/gravity on the particles.
    * 
    * @param increase A boolean indicating if the downward pull on the 
    *        particles should increase. If true, the downward pull (negative
    *        Y) increases. If false, the downward pull deceases. 
    */
   protected void changeYGravity(boolean increase) {
      if (increase) {
         m_fYGravityChange += 0.01f;
      } else {
         m_fYGravityChange += -0.01f;
      }
   }

   /**
    * Changes the downward pull/gravity on the particles.
    * 
    * @param increase A boolean indicating if the downward pull on the 
    *        particles should increase. If true, the downward pull (negative
    *        Y) increases. If false, the downward pull deceases (or upward
    *        pull increases). 
    */
   protected void changeXGravity(boolean increase) {
      if (increase) {
         m_fXGravityChange += 0.01f;
      } else {
         m_fXGravityChange += -0.01;
      }
   }

   /**
    * Speeds up or slows down the particles by decreasing or increaseing
    * the slow down factor.
    *
    * @param increase A boolean indicating if the particles should travel
    *        faster or slower. If true, the slow-down factor increases,
    *        therefore the particles travel slower. If false, the slow-down
    *        factor decreases, therefore the particles travel faster.
    */
   protected void changeSlowDown(boolean increase) {
      if (increase) {
         m_fSlowDown += 0.01f;
      } else {
         m_fSlowDown += -0.01f;
      }
   }

   /**
    * Changes the user configurable direction and speed the particles are
    * traveling the along the X direction.
    * 
    * @param increase A boolean indication whether to increase or decrease
    *        the speed in the x direction. If true, the particles' speed in
    *        the positive x direction increases. If false, the particles'
    *        speed in the negative x direction increases.
    *        
    */
   protected void changeXSpeed(boolean increase) {
      if (increase) {
         m_fXSpeed += 1f;
      } else {
         m_fXSpeed += -1f;
      }
   }

   /**
    * Changes the user configurable direction and speed the particles are
    * traveling the along the Y direction.
    * 
    * @param increase A boolean indication whether to increase or decrease
    *        the speed in the y direction. If true, the particles' speed in
    *        the positive y direction increases. If false, the particles'
    *        speed in the negative y direction increases.
    *        
    */
   protected void changeYSpeed(boolean increase) {
      if (increase) {
         m_fYSpeed += 1f;
      } else {
         m_fYSpeed += -1f;
      }
   }

   /**
    * Retrieves the user configurable X speed.
    * 
    * @return Current float value of the x speed.
    */
   protected float getXSpeed() {
      return m_fXSpeed;
   }

   /**
    * Retrieves the user configurable Y speed.
    * 
    * @return Current float value of the y speed.
    */
   protected float getYSpeed() {
      return m_fYSpeed;
   }

}