package Bitmap_Fonts;

/*
 * This source uses the JoGL libraries found on the jogl.dev.java.net website.
 * This site (http://today.java.net/pub/a/today/2003/09/11/jogl2d.html) is the resource
 * I used to place the libraries into the proper directories...Setting up JoGL is pretty
 * simple follow these steps:
 *  - Download the libraries from https://jogl.dev.java.net/servlets/ProjectDocumentList
 *  - Extract the file jogl.jar to JRE_HOME/lib/ext
 *  - Extract the dll files to JRE_HOME/bin
 * The rest is the rest. If you do not understand java...Learn it somewhere else, 
 * this assumes a level of understanding about the language. Good luck and enjoy.
 *  - @see author
 */

/*
 * Lesson13.java
 *
 * Created on December 17, 2003, 9:05 PM
 * Used the JOGL2DBasics.java file from the aforementioned site for basic things.
 * Also, referenced the port of NeHe's Lesson01 by Kevin Duling (jattier@hotmail.com)
 * Thank you to these sources for the help.
 */

import LoadImageTypes.*;
import OptionFrame.Options;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.io.*;
import java.net.*;
import java.nio.*;
import javax.imageio.*;
import net.java.games.jogl.*;   //JoGL Lib Imports
import net.java.games.jogl.util.*; //Utilities of the Lib to import

/**This application create a bitmap font and displays a string on the screen which
 * oscillates left and right, and up and down while changing colors. Hope the port
 * helps those who choose to try to understand it.
 * @author Nicholas Campbell - campbelln@hartwick.edu
 * @since 20 DECEMBER 2003
 * @version 1.00
 */
public class Lesson13 extends Frame implements GLEventListener, KeyListener
{
    private final int SIZE_OF_KEYS = 250;
    
    private boolean fullscreen = true;
    private boolean[] keys = new boolean[SIZE_OF_KEYS];
    
    private GLCanvas glCanvas;
    private Animator animator;
    
    private int base;
    private float cnt1;
    private float cnt2;
    
    /** Creates a new instance of Lesson13 */
    public Lesson13(Dimension dim, boolean fscreen)
    {
        super("Display Lists");
        fullscreen = fscreen;
        if (fullscreen == true)
            super.setSize(Toolkit.getDefaultToolkit().getScreenSize().getSize());
        else
            super.setSize(dim);
        // create a GLCapabilities object for the requirements for GL
        GLCapabilities glCapabilities = new GLCapabilities();
        //create a GLCamvas based on the requirements from above
        glCanvas = GLDrawableFactory.getFactory().createGLCanvas(glCapabilities);
        // add a GLEventListener, which will get called when the
        // canvas is resized or needs to be repainted
        glCanvas.addGLEventListener(this);
        //add the content page to the frame
        add(glCanvas, java.awt.BorderLayout.CENTER);
        animator = new Animator(glCanvas);
    }
    
    /** Called in the beginning of the application to take grab the focus on the
     * monitor of all other apps.
     * @return glCanvas
     */
    public GLCanvas getGLCanvas()
    {
        return glCanvas;
    }
    
    /** Called in the beginning of the application to grab the animator for the
     * canvas
     * @return animator
     */
    public Animator getAnimator()
    {
        return animator;
    }
    
    /*
     * METHODS DEFINED BY GLEventListener
     */
    
    /** Called by drawable to initiate drawing
     * @param gLDrawable The GLDrawable Object
     */
    public void display(GLDrawable gLDrawable) 
    {
        GL gl = gLDrawable.getGL();
        GLUT glut = new GLUT();
        gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
        gl.glLoadIdentity();
        gl.glTranslatef(0.0f,0.0f,-1.0f);
        
        // Pulsing Colors Based On Text Position
	gl.glColor3f(1.0f*((float)(Math.cos(cnt1))),
                     1.0f*((float)(Math.sin(cnt2))),
                     1.0f-0.5f*((float)(Math.cos(cnt1+cnt2))));
        // Position The Text On The Screen...fullscreen goes much slower than the other
        //way so this is kind of necessary to not just see a blur in smaller windows
        //and even in the 640x480 method it will be a bit blurry...oh well you can
        //set it if you would like :)
        if (fullscreen)
            gl.glRasterPos2f(-0.25f+0.25f*((float)(Math.cos(cnt1))),
                              0.35f*((float)(Math.sin(cnt2))));
        else
            gl.glRasterPos2f(-0.25f+0.10f*((float)(Math.cos(cnt1))),
                              0.35f*((float)(Math.sin(cnt2))));
        //Take a string and make it a bitmap, put it in the 'gl' passed over and pick
        //the GLUT font, then provide the string to show
        glut.glutBitmapString(gl,
                              GLUT.BITMAP_HELVETICA_18,
                              "Active OpenGL, in JoGL, Text With NeHe - " + cnt1);
         cnt1+=0.102f;
         cnt2+=0.010f;
    }
    
    /** Called by drawable to show that a mode or device has changed <br>
     * <B>!! CURRENTLY NON-Functional IN JoGL !!</B>
     * @param gLDrawable The GLDrawable object.
     * @param modeChanged Indicates if the video mode has changed.
     * @param deviceChanged Indicates if the video device has changed.
     */
    public void displayChanged(GLDrawable gLDrawable, 
                                boolean modeChanged, 
                                boolean deviceChanged)
    {
    }
    
    /**  Called by the drawable immediately after the OpenGL context is 
     * initialized for the first time. Can be used to perform one-time OpenGL 
     * initialization such as setup of lights and display lists.
     * @param gLDrawable The GLDrawable object.
     */
    public void init(GLDrawable gLDrawable)
    {
        GL gl = gLDrawable.getGL();
        GLU glu = gLDrawable.getGLU();
        gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);    // Black Background
        gl.glClearDepth(1.0f);                      // Depth Buffer Setup
        
        gl.glShadeModel(GL.GL_SMOOTH);
        gl.glEnable(GL.GL_DEPTH_TEST);              // Enables Depth Testing
        gl.glDepthFunc(GL.GL_LEQUAL);               // The Type Of Depth Testing To Do
        gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// Really Nice Perspective Calculations
        gl.glEnable(GL.GL_TEXTURE_2D);
        gLDrawable.addKeyListener(this);            // Listening for key events
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
     * @param y The Y coordinate of the viewport rectangle.
     * @param width The new width of the window.
     * @param height The new height of the window.
     */
    public void reshape(GLDrawable gLDrawable, 
                        int x, 
                        int y, 
                        int width, 
                        int height)
    {
        GL gl = gLDrawable.getGL();
        GLU glu = gLDrawable.getGLU();

        height = (height == 0) ? 1 : height;
        float h = (float)width / (float)height;
        
        gl.glViewport(0, 0, width, height);
        gl.glMatrixMode(GL.GL_PROJECTION);
        gl.glLoadIdentity();
        
        glu.gluPerspective(45.0f, h, 1.0, 1000.0);
        gl.glMatrixMode(GL.GL_MODELVIEW);
        gl.glLoadIdentity();
    }
    
    public void keyPressed(KeyEvent ke)
    {
       switch(ke.getKeyCode())
       {
            case KeyEvent.VK_ESCAPE:    //close the application
            {
                 System.out.println("User closed application.");
                 animator.stop();
                 System.exit(0);
                 break;
            }
            case KeyEvent.VK_F1:    //resize the application
            {
                setVisible(false);
                setSize((fullscreen)?new Dimension(800,600):Toolkit.getDefaultToolkit().getScreenSize().getSize());
                fullscreen = !fullscreen;
                setVisible(true);
            }
            default :
               if(ke.getKeyCode()<250) // only interested in first 250 key codes, are there more?
                  keys[ke.getKeyCode()]=true;	
               break;
         }
    }
    
    public void keyReleased(KeyEvent ke)
    {
        if (ke.getKeyCode() < 250) { keys[ke.getKeyCode()] = false; }
    }
    
    public void keyTyped(KeyEvent ke)
    {
    }
        
    public static void main(String[] args)
    {
        Dimension dim = new Dimension(800, 600);
        boolean fscreen = false;
        
        Options options = new Options();
	while(!(options.getOK()) && !(options.getCancel()))
	{
            try { Thread.sleep(5); } catch(InterruptedException ie) {}
	}
	if (options.getCancel())
	{
            System.out.println("User closed application.");
            System.exit(0);
        }
	fscreen = (options.getFullscreen()? true:false);
        dim = options.getPixels();
        //options.getBPP();
	options.setOff();
	options = null;
        
        Lesson13 lesson13 = new Lesson13(dim, fscreen);
        lesson13.addWindowListener(new WindowAdapter()
        {
            public void windowClosing(WindowEvent e)
            {
                System.exit(0);
            }
        });
        lesson13.setUndecorated(true);
        lesson13.show();
        lesson13.getAnimator().start();
        lesson13.getGLCanvas().requestFocus();
    }
}