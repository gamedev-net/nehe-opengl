/*
 * Created on Mar 7, 2004
 * 
 * @author Irene Kam  (kaminc@cox.net)
 */

// Import classes needed to process key events.
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;

/**
 * This class provides key pressed/released events handling for NeHe's 
 * Lesson19.
 * 
 * @author Irene Kam
 */
public class KeyHandler implements KeyListener {

   // Reference to parent object.
   private Lesson19 m_oParent;

   /**
    * Creates an instance of this class.
    * 
    * @param parent The parent object which employs this KeyListener.
    */
   public KeyHandler(Lesson19 parent) {
      m_oParent = parent;
   }

   /**
    * Handles all key pressed events. Depending on the key pressed, 
    * different actions will take place.
    * 
    * @param e The KeyEvent that just took place. We can find out which key
    *        was pressed form this KeyEvent and take actions appropriately. 
    */
   public void keyPressed(KeyEvent e) {
      // Retrieve the key released.
      int keyCode = e.getKeyCode();

      // Depending on the key pressed, take appropriate actions.
      switch (keyCode) {
         case KeyEvent.VK_ESCAPE :
            // The key pressed is the "Esc" key. Close window and 
            // exit program.
            m_oParent.exitProgram();
            break;
         case KeyEvent.VK_F1 :
            // Key pressed is the "F1" key. Toggle between full
            // and windowed mode.
            m_oParent.toggleWindowMode();
            break;
         case KeyEvent.VK_PAGE_UP :
            // The page up key is pressed: Zoom in objects on display.
            m_oParent.m_fZoom += .5f;
            break;
         case KeyEvent.VK_PAGE_DOWN :
            // The page down key: Zoom out.
            m_oParent.m_fZoom += -.5f;
            break;
         case KeyEvent.VK_8 :
            // The number 8 key is pressed. Increase upward pull.
            m_oParent.changeYGravity(true);
            break;
         case KeyEvent.VK_2 :
            // The number 2 key should increase the downward pull.
            m_oParent.changeYGravity(false);
            break;
         case KeyEvent.VK_6 :
            // The number 6 key increases the pull to the right (positive X).
            m_oParent.changeXGravity(true);
            break;
         case KeyEvent.VK_4 :
            // The number 4 key increases the pull to the left.
            m_oParent.changeXGravity(false);
            break;
         case KeyEvent.VK_H :
            // The 'h' key restarts the particles ('h' for home)
            m_oParent.resetParticles = true;
            break;
         case KeyEvent.VK_F2 :
            // The F2 key speeds up particles (i.e. The slow-down factor
            // decreases.)
            m_oParent.changeSlowDown(false);
            break;
         case KeyEvent.VK_F3 :
            // The F3 key slows down particles (i.e. The slow-down factor
            // increases.)
            m_oParent.changeSlowDown(true);
            break;
         case KeyEvent.VK_UP :
            // The up arrow key increases the user configurable Y speed.
            m_oParent.changeYSpeed(true);
            break;
         case KeyEvent.VK_DOWN :
            // The down arrow key decreases the user configurable Y speed.
            m_oParent.changeYSpeed(false);
            break;
         case KeyEvent.VK_RIGHT :
            // The right arrow key increases the user configurable X speed.
            m_oParent.changeXSpeed(true);
            break;
         case KeyEvent.VK_LEFT :
            // The left arrow key decreases the user configurable X speed.
            m_oParent.changeXSpeed(false);
            break;
      }
   }

   /** 
    * Handles all key released events.
    * 
    * @param e The KeyEvent that just took place. 
    */
   public void keyReleased(KeyEvent e) {

   }

   /** 
    * Handles all key typed events.
    * 
    * @param e The KeyEvent that just took place.
    */
   public void keyTyped(KeyEvent e) {
   }
}
