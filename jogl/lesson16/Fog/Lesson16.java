package Fog;

/*
 * This source uses the JoGL libraries found on the jogl.dev.java.net website.
 * This site (http://today.java.net/pub/a/today/2003/09/11/jogl2d.html) is the resource
 * I used to place the libraries into the proper directories...I will not tell you how
 * to set up your machine, just go to this site; it's pretty simple. The rest is the 
 * rest. If you do not understand java...Learn it somewhere else, this assumes a level
 * of understanding about the language. Good luck and enjoy.
 *  - @see author
 */

/*
 * Lesson16.java
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

/**
 * @author Nicholas Campbell - campbelln@hartwick.edu
 */
public class Lesson16 extends Frame implements GLEventListener, KeyListener
{
    private final int SIZE_OF_KEYS = 250;
    private final int NUM_COORDS = 3;
    private final int NUM_GL_FILTERS = 3;
    private final int NUM_FOG_TYPES = 3;
    
    private boolean fullscreen = true;
    private boolean[] keys = new boolean[SIZE_OF_KEYS];
    private boolean active = true;
    private boolean light;
    private boolean lp;
    private boolean fp;
    private boolean gp;
    
    private GLCanvas glCanvas;
    private Animator animator;
    
    private float[] lightAmbient = { 0.5f, 0.5f, 0.5f, 1.0f };
    private float[] lightDiffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
    private float[] lightPosition = { 0.0f, 0.0f, 2.0f, 1.0f };
    private float[] fogColor = { 0.5f, 0.5f, 0.5f, 1.0f};
    private float[] rotArray = new float[NUM_COORDS];   //there are 3 dimensions
    private float[] rotSpeed = new float[NUM_COORDS];   //there are 3 dimensions
    private float[] cubePlacement = new float[NUM_COORDS];  //there are 3 dimensions
    private int[] texture = new int[NUM_GL_FILTERS];
    private int[] fogMode = { GL.GL_EXP, GL.GL_EXP2, GL.GL_LINEAR };
    private int filter;
    private int fogFilter;
    
    
    /** Creates a new instance of Lesson16 */
    public Lesson16(Dimension dim, boolean fscreen)
    {
        super("FOG!!!!");
        fullscreen = fscreen;
        if (fullscreen == true)
            super.setSize(Toolkit.getDefaultToolkit().getScreenSize().getSize());
        else
            super.setSize(dim);
        rotArray[0] = 0.0f; rotArray[1] = 0.0f; rotArray[2] = 0.0f;
        rotSpeed[0] = 1.0f; rotSpeed[1] = 1.0f; rotSpeed[2] = 0.0f;
        cubePlacement[0] = 0.0f; cubePlacement[1] = 0.0f; cubePlacement[2] =-5.0f;
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
        gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
        
        gl.glLoadIdentity();
        //cube placement
        gl.glTranslatef( cubePlacement[0], cubePlacement[1], cubePlacement[2]);
        gl.glRotatef(rotArray[0], 1.0f, 0.0f, 0.0f);    //the rotations
        gl.glRotatef(rotArray[1], 0.0f, 1.0f, 0.0f);
        
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[filter]);
        if (light)  //because when it's foggy lighting really matters....heh
            gl.glEnable(GL.GL_LIGHTING);
        else
            gl.glDisable(GL.GL_LIGHTING);
        
        gl.glBegin(GL.GL_QUADS);
            // Front Face
            gl.glNormal3f(0.0f, 0.0f, 1.0f);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
            // Back Face
            gl.glNormal3f(0.0f, 0.0f, -1.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
            // Top Face
            gl.glNormal3f(0.0f, 1.0f, 0.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
            // Bottom Face
            gl.glNormal3f(0.0f, -1.0f, 0.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
            // Right face
            gl.glNormal3f(1.0f, 0.0f, 0.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
            // Left Face
            gl.glNormal3f(-1.0f, 0.0f, 0.0f);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
        gl.glEnd();
        
        //using a bunch of if...else to save some proc. speed because if the oposite of 
        //what was done is checked it's wasted time...in java we need to muster all the
        //speed we can
        if (keys['F'] && !fp)
        {
            fp = true;
            filter++;
            if (filter > 2)
                filter = 0;
        }
        else if (!(keys['F'])) { fp = false; }
        if (keys['L'] && !lp)
        {
            lp = true;
            light = true;
            gl.glEnable(GL.GL_LIGHTING);
        }
        else if (!(keys['L'])) { lp = false; gl.glDisable(GL.GL_LIGHTING); }
        if (keys['G'] && !gp)
        {
            gp = true;
            fogFilter = ((++fogFilter) > 2)?0:fogFilter;
            gl.glFogi(GL.GL_FOG_MODE, fogMode[fogFilter]);	// Fog Mode
        }
        else if (!(keys['G'])) { gp = false; }
        if (keys[KeyEvent.VK_RIGHT])
        {
            rotArray[1] += rotSpeed[1];
        }
        else if (keys[KeyEvent.VK_LEFT])
        {
            rotArray[1] -= rotSpeed[1];
        }
        if (keys[KeyEvent.VK_UP])
        {
            rotArray[0] -= rotSpeed[0];
        }
        else if (keys[KeyEvent.VK_DOWN])
        {
            rotArray[0] += rotSpeed[0];
        }
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
        
        gl.glShadeModel(GL.GL_SMOOTH);
        gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);    // Black Background
        gl.glClearDepth(1.0f);                      // Depth Buffer Setup
        gl.glEnable(GL.GL_DEPTH_TEST);              // Enables Depth Testing
        gl.glDepthFunc(GL.GL_LEQUAL);               // The Type Of Depth Testing To Do
        gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// Really Nice Perspective Calculations
        gl.glEnable(GL.GL_TEXTURE_2D);
        gLDrawable.addKeyListener(this);            // Listening for key events
        
        String imgLoc = "data/crate.png";
        
        // Set up lighting
        gl.glLightfv(GL.GL_LIGHT1, GL.GL_AMBIENT, lightAmbient);
        gl.glLightfv(GL.GL_LIGHT1, GL.GL_DIFFUSE, lightDiffuse);
        gl.glLightfv(GL.GL_LIGHT1, GL.GL_POSITION, lightPosition);
        gl.glEnable(GL.GL_LIGHT1);
        gl.glEnable(GL.GL_LIGHTING);
        light = true;
        
        //set up fog
        gl.glClearColor( 0.5f, 0.5f, 0.5f, 1.0f);
        gl.glFogi(GL.GL_FOG_MODE, fogMode[fogFilter]);
        gl.glFogfv(GL.GL_FOG_COLOR, fogColor);
        gl.glFogf(GL.GL_FOG_DENSITY, 0.35f);
        gl.glHint(GL.GL_FOG_HINT, GL.GL_NICEST);
        gl.glFogf(GL.GL_FOG_START, 1.0f);
        gl.glFogf(GL.GL_FOG_END, 5.0f);
        gl.glEnable(GL.GL_FOG);
        
        loadGLTextures(gl, glu, imgLoc);    // load the textures
    }
    
    /** This method loads textures into the texture array
     * @param gl A GL object to reference when setting values for it
     * @param glu A GLU object to reference when setting values for it
     * @param imgLoc The string location of the image/texture to load.
     */    
    public void loadGLTextures(GL gl, GLU glu, String imgLoc)
    {
        // make room for 3 textures/filters
        gl.glGenTextures(3, texture);
        
        // Create Nearest Filtered Texture
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
        makeTexture(gl, glu, readImage(imgLoc), GL.GL_TEXTURE_2D, false);
        // Create Linear Filtered Texture
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[1]);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
        makeTexture(gl, glu, readImage(imgLoc), GL.GL_TEXTURE_2D, false);
        // Mipmapped Filter Texture
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[2]);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
        makeTexture(gl, glu, readImage(imgLoc), GL.GL_TEXTURE_2D, true);
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

        if (height <= 0) // avoid a divide by zero error!
            height = 1;
        float h = (float)width / (float)height;
        gl.glViewport(0, 0, width, height);
        gl.glMatrixMode(GL.GL_PROJECTION);
        gl.glLoadIdentity();
        glu.gluPerspective(45.0f, h, 1.0, 20.0);
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
                if (fullscreen)
                    setSize(800,600);
                else
                    setSize(Toolkit.getDefaultToolkit().getScreenSize().getSize());
                fullscreen = !fullscreen;
                //reshape();
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
    
    public void keyTyped(KeyEvent ke) {}

    //method made to load images based on if it is a bmp or png file...
    //the different types create diff. objects which are returned and tested for
    //when the textures are loaded...
    //the classes themselves were created by other people whos credit is in the file
    //however those files are edited by me to best suit my needs and wants for my apps
    /** This program makes a series of calls to read an image
     * and return an Object that has already been run just
     * so that information can be obtained about the image.
     * @param resource Tells the program which image to use.
     * @return Returns an Object that is from the package
     * LoadImageTypes
     */    
    public Object readImage(String resource)
    {
        if (resource.endsWith("png"))
        {
            LoadPNGImages loadPNGImage = new LoadPNGImages();
            loadPNGImage.getDataAsByteBuffer(getResourceA(resource));
            return loadPNGImage;
        }
        else if (resource.endsWith("bmp"))
        {
            LoadBMPImages loadBMPImage = new LoadBMPImages();
            //needed to load a stream in, plus it is better for this anyway
            //check the source of LoadBMPImages if you really want to know
            loadBMPImage.generateTextureInfo(getResourceB(resource), resource, false);
            return loadBMPImage;
        }
        else
        { return null; }
    }
    
    /* Helper methods for getting textures */
    //Definitely gotten from Kevin Duling (jattier@hotmail.com) in his ports to the NeHe
    //tuts. Same with the few methods that follow. I had to change the method getResource() to work 
    //better for locating the image and returning a valid resource URL.

    private void makeTexture(GL gl, 
                                GLU glu, 
                                Object img, 
                                int target, 
                                boolean mipmapped)
    {
      if (mipmapped)
      {
        if (img instanceof LoadBMPImages)
            glu.gluBuild2DMipmaps(target, 
                                    GL.GL_RGB8, 
                                    ((LoadBMPImages)img).getWidth(), 
                                    ((LoadBMPImages)img).getHeight(), 
                                    GL.GL_RGB, 
                                    GL.GL_UNSIGNED_BYTE, 
                                    ((LoadBMPImages)img).getData());
        else if (img instanceof LoadPNGImages)
            glu.gluBuild2DMipmaps(target, 
                                    GL.GL_RGB8, 
                                    ((LoadPNGImages)img).getWidth(), 
                                    ((LoadPNGImages)img).getHeight(), 
                                    GL.GL_RGB, 
                                    GL.GL_UNSIGNED_BYTE, 
                                    ((LoadPNGImages)img).getDest());
      }
      else
      {
        if (img instanceof LoadBMPImages)
            gl.glTexImage2D(target, 
                            0, 
                            3, 
                            ((LoadBMPImages)img).getWidth(), 
                            ((LoadBMPImages)img).getHeight(), 
                            0,
                            GL.GL_RGB, 
                            GL.GL_UNSIGNED_BYTE, 
                            ((LoadBMPImages)img).getData());
        else if (img instanceof LoadPNGImages)
            gl.glTexImage2D(target, 
                            0, 
                            3,  
                            ((LoadPNGImages)img).getWidth(), 
                            ((LoadPNGImages)img).getHeight(), 
                            0,
                            GL.GL_RGB, 
                            GL.GL_UNSIGNED_BYTE, 
                            ((LoadPNGImages)img).getDest());
      }
    }

    /** Retrieve a URL resource from the jar.  If the resource is not found, then
     * the local disk is also checked.
     * @param filename Complete filename, including parent path
     * @return a URL object if resource is found, otherwise null.
     */  
    public URL getResourceA(String filename)
    {
      // Try to load resource from jar
      URL url = getClass().getResource(filename);
      // If not found in jar, then load from disk
      if (url == null)
      {
        System.out.println("URL is null...");
        try { url = new URL("file", "localhost", filename); }
        catch (Exception urlException) {} // ignore
      }
      return url;
    }
    
    /** Retrieve an InputStream resource from the jar.  If the resource is not found, then
     * the local disk is also checked.
     * @param filename Complete filename, including parent path
     * @return a InputStream object if resource is found, otherwise null.
     */  
    public InputStream getResourceB(String filename)
    {
      // Try to load resource from jar
      InputStream stream = getClass().getResourceAsStream(filename);
      // If not found in jar, then load from disk
      if (stream == null)
      {
        System.out.println("stream is null...");
        //try { url = new URL("file", "localhost", filename); }
        //catch (Exception urlException) {} // ignore
      }
      return stream;
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
        
        Lesson16 lesson16 = new Lesson16(dim, fscreen);
        lesson16.addWindowListener(new WindowAdapter()
        {
            public void windowClosing(WindowEvent e)
            {
                System.exit(0);
            }
        });
        lesson16.setUndecorated(true);
        lesson16.show();
        lesson16.getAnimator().start();
        lesson16.getGLCanvas().requestFocus();
    }
}