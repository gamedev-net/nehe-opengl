/*
 * Lesson06.java
 *
 * Created on July 16, 2003, 11:30 AM
 */

import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.io.*;
import java.net.*;
import java.nio.*;
import javax.imageio.*;

import net.java.games.jogl.*;
import net.java.games.jogl.util.*;

/** Port of the NeHe OpenGL Tutorial (Lesson 6)
 * to Java using the Jogl interface to OpenGL.  Jogl can be obtained
 * at http://jogl.dev.java.net/
 *
 * @author Kevin Duling (jattier@hotmail.com)
 */
public class Lesson06
{
  static Animator animator = null;
  
  static class Renderer
    implements GLEventListener,
               KeyListener
  {
    private float	xrot;				// X Rotation ( NEW )
    private float	yrot;				// Y Rotation ( NEW )
    private float	zrot;				// Z Rotation ( NEW )
    private int texture;
    
    /** Called by the drawable to initiate OpenGL rendering by the client.
     * After all GLEventListeners have been notified of a display event, the
     * drawable will swap its buffers if necessary.
     * @param gLDrawable The GLDrawable object.
     */
    public void display(GLDrawable gLDrawable)
    {
      final GL gl = gLDrawable.getGL();
      gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
      gl.glLoadIdentity();									// Reset The View
      gl.glTranslatef(0.0f,0.0f,-5.0f);

      gl.glRotatef(xrot,1.0f,0.0f,0.0f);
      gl.glRotatef(yrot,0.0f,1.0f,0.0f);
      gl.glRotatef(zrot,0.0f,0.0f,1.0f);

      gl.glBindTexture(GL.GL_TEXTURE_2D, texture);

      gl.glBegin(GL.GL_QUADS);
        // Front Face
        gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
        gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
        gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
        gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
        // Back Face
        gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
        gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
        gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
        gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
        // Top Face
        gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
        gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
        gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
        gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
        // Bottom Face
        gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
        gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
        gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
        gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
        // Right face
        gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
        gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
        gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
        gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
        // Left Face
        gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
        gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
        gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
        gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
      gl.glEnd();

      xrot+=0.3f;
      yrot+=0.2f;
      zrot+=0.4f;
    }
    
    
    /** Called when the display mode has been changed.  <B>!! CURRENTLY UNIMPLEMENTED IN JOGL !!</B>
     * @param gLDrawable The GLDrawable object.
     * @param modeChanged Indicates if the video mode has changed.
     * @param deviceChanged Indicates if the video device has changed.
     */
    public void displayChanged(GLDrawable gLDrawable, boolean modeChanged, boolean deviceChanged)
    {
    }
    
    /** Called by the drawable immediately after the OpenGL context is
     * initialized for the first time. Can be used to perform one-time OpenGL
     * initialization such as setup of lights and display lists.
     * @param gLDrawable The GLDrawable object.
     */
    public void init(GLDrawable gLDrawable)
    {
      final GL gl = gLDrawable.getGL();
      gl.glShadeModel(GL.GL_SMOOTH);              // Enable Smooth Shading
      gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);    // Black Background
      gl.glClearDepth(1.0f);                      // Depth Buffer Setup
      gl.glEnable(GL.GL_DEPTH_TEST);							// Enables Depth Testing
      gl.glDepthFunc(GL.GL_LEQUAL);								// The Type Of Depth Testing To Do
      gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// Really Nice Perspective Calculations
      gl.glEnable(GL.GL_TEXTURE_2D);
      gLDrawable.addKeyListener(this);
      texture = genTexture(gl);
      gl.glBindTexture(GL.GL_TEXTURE_2D, texture);
      BufferedImage img = readPNGImage("data/NeHe.png");
      makeRGBTexture(gl, gLDrawable.getGLU(), img, GL.GL_TEXTURE_2D, false);
  		gl.glTexParameteri(GL.GL_TEXTURE_2D,GL.GL_TEXTURE_MIN_FILTER,GL.GL_LINEAR);
  		gl.glTexParameteri(GL.GL_TEXTURE_2D,GL.GL_TEXTURE_MAG_FILTER,GL.GL_LINEAR);
    }

    /** Called by the drawable during the first repaint after the component has
     * been resized. The client can update the viewport and view volume of the
     * window appropriately, for example by a call to
     * GL.glViewport(int, int, int, int); note that for convenience the component
     * has already called GL.glViewport(int, int, int, int)(x, y, width, height)
     * when this method is called, so the client may not have to do anything in
     * this method.
     * @param gLDrawable The GLDrawable object.
     * @param x The X Coordinate of the viewport rectangle.
     * @param y The Y coordinate of the viewport rectanble.
     * @param width The new width of the window.
     * @param height The new height of the window.
     */
    public void reshape(GLDrawable gLDrawable, int x, int y, int width, int height)
    {
      final GL gl = gLDrawable.getGL();
      final GLU glu = gLDrawable.getGLU();
      
      if (height <= 0) // avoid a divide by zero error!
        height = 1;
      final float h = (float)width / (float)height;
      gl.glViewport(0, 0, width, height);
      gl.glMatrixMode(GL.GL_PROJECTION);
      gl.glLoadIdentity();
      glu.gluPerspective(45.0f, h, 1.0, 20.0);
      gl.glMatrixMode(GL.GL_MODELVIEW);
      gl.glLoadIdentity();
    }
    
    /** Invoked when a key has been pressed.
     * See the class description for {@link KeyEvent} for a definition of
     * a key pressed event.
     * @param e The KeyEvent.
     */
    public void keyPressed(KeyEvent e)
    {
      if (e.getKeyCode() == KeyEvent.VK_ESCAPE)
      {
        animator.stop();
        System.exit(0);
      }
    }
    
    /** Invoked when a key has been released.
     * See the class description for {@link KeyEvent} for a definition of
     * a key released event.
     * @param e The KeyEvent.
     */
    public void keyReleased(KeyEvent e) {}
    
    /** Invoked when a key has been typed.
     * See the class description for {@link KeyEvent} for a definition of
     * a key typed event.
     * @param e The KeyEvent.
     */
    public void keyTyped(KeyEvent e) {}
    
    private BufferedImage readPNGImage(String resourceName)
    {
      try
      {
        URL url = getResource(resourceName);
        if (url == null)
        {
          throw new RuntimeException("Error reading resource " + resourceName);
        }
        BufferedImage img = ImageIO.read(url);
        java.awt.geom.AffineTransform tx = java.awt.geom.AffineTransform.getScaleInstance(1, -1); 
        tx.translate(0, -img.getHeight(null)); 
        AffineTransformOp op = new AffineTransformOp(tx, AffineTransformOp.TYPE_NEAREST_NEIGHBOR); 
        img = op.filter(img, null); 
        return img;
      }
      catch (IOException e)
      {
        throw new RuntimeException(e);
      }
    }
    
    private void makeRGBTexture(GL gl, GLU glu, BufferedImage img, int target, boolean mipmapped)
    {
      ByteBuffer dest = null;
      switch (img.getType())
      {
        case BufferedImage.TYPE_3BYTE_BGR:
        case BufferedImage.TYPE_CUSTOM:
        {
          byte[] data = ((DataBufferByte) img.getRaster().getDataBuffer()).getData();
          dest = ByteBuffer.allocateDirect(data.length);
          dest.order(ByteOrder.nativeOrder());
          dest.put(data, 0, data.length);
          break;
        }
        case BufferedImage.TYPE_INT_RGB:
        {
          int[] data = ((DataBufferInt) img.getRaster().getDataBuffer()).getData();
          dest = ByteBuffer.allocateDirect(data.length * BufferUtils.SIZEOF_INT);
          dest.order(ByteOrder.nativeOrder());
          dest.asIntBuffer().put(data, 0, data.length);
          break;
        }
        default:
          throw new RuntimeException("Unsupported image type " + img.getType());
      }
      
      if (mipmapped)
      {
        glu.gluBuild2DMipmaps(target, GL.GL_RGB8, img.getWidth(), img.getHeight(), GL.GL_RGB, GL.GL_UNSIGNED_BYTE, dest);
      }
      else
      {
        gl.glTexImage2D(target, 0, GL.GL_RGB, img.getWidth(), img.getHeight(), 0, GL.GL_RGB, GL.GL_UNSIGNED_BYTE, dest);
      }
    }

    private int genTexture(GL gl)
    {
      final int[] tmp = new int[1];
      gl.glGenTextures(1, tmp);
      return tmp[0];
    }
  }

  /** Retrieve a URL resource from the jar.  If the resource is not found, then
   * the local disk is also checked.
   * @param filename Complete filename, including parent path
   * @return a URL object if resource is found, otherwise null.
   */  
  public final static URL getResource(final String filename)
  {
    // Try to load resource from jar
    URL url = ClassLoader.getSystemResource(filename);
    // If not found in jar, then load from disk
    if (url == null)
    {
      try
      {
        url = new URL("file", "localhost", filename);
      }
      catch (Exception urlException){} // ignore
    }
    return url;
  }

  /** Program's main entry point
   * @param args command line arguments.
   */
  public static void main(String[] args)
  {
    Frame frame = new Frame("Lesson 6: Texture Mapping");
    GLCanvas canvas = GLDrawableFactory.getFactory().createGLCanvas(new GLCapabilities());
    canvas.addGLEventListener(new Renderer());
    frame.add(canvas);
    frame.setSize(640, 480);
    animator = new Animator(canvas);
    frame.addWindowListener(new WindowAdapter()
    {
      public void windowClosing(WindowEvent e)
      {
        animator.stop();
        System.exit(0);
      }
    });
    frame.show();
    animator.start();
    canvas.requestFocus();
  }
}
