package Texture_Font;

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
 * Lesson17.java
 * This port is best viewed at fullscreen using either 1024x768 or 1280x1024...below 
 * that the text doesn't circulate well and i haven't tested above that.
 *
 * Created on May 12, 2003, 3:15 PM
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
public class Lesson17 extends Frame implements GLEventListener, KeyListener
{
    private final int SIZE_OF_KEYS = 250;
    private final int NUM_TEXTURES = 2;
    
    private boolean fullscreen = true;
    private Dimension screensize;
    private boolean[] keys = new boolean[SIZE_OF_KEYS];
    
    private GLCanvas glCanvas;
    private Animator animator;

    private int[] texture = new int[NUM_TEXTURES];
    private int base;
    private int loop;
    
    private float cnt1;
    private float cnt2;
    
    private GL glObj;
    
    /** Creates a new instance of Lesson6 */
    public Lesson17(Dimension dim, boolean fscreen)
    {
        super("Texture Font");
        fullscreen = fscreen;
        screensize = dim;
        if (fullscreen == true)
            super.setSize(Toolkit.getDefaultToolkit().getScreenSize().getSize());
        else
            super.setSize(dim);
        // create a GLCapabilities object for the requirements for GL
        GLCapabilities glCapabilities = new GLCapabilities();
        glCapabilities.setHardwareAccelerated(true);
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
    public GLCanvas getGLCanvas() { return glCanvas; }
    
    /** Called in the beginning of the application to grab the animator for the
     * canvas
     * @return animator
     */
    public Animator getAnimator() { return animator; }
    
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
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[1]);
        gl.glTranslatef(0.0f, 0.0f, -5.0f);
        gl.glRotatef(45.0f, 0.0f, 0.0f, 1.0f);
        gl.glRotatef(cnt1*30.0f, 1.0f, 1.0f, 0.0f);
        gl.glDisable(GL.GL_BLEND);
        gl.glColor3f(1.0f, 1.0f, 1.0f);
        gl.glBegin(GL.GL_QUADS);
            gl.glTexCoord2d(0.0f,0.0f);					// First Texture Coord
            gl.glVertex2f(-1.0f, 1.0f);					// First Vertex
            gl.glTexCoord2d(1.0f,0.0f);					// Second Texture Coord
            gl.glVertex2f( 1.0f, 1.0f);					// Second Vertex
            gl.glTexCoord2d(1.0f,1.0f);					// Third Texture Coord
            gl.glVertex2f( 1.0f,-1.0f);					// Third Vertex
            gl.glTexCoord2d(0.0f,1.0f);					// Fourth Texture Coord
            gl.glVertex2f(-1.0f,-1.0f);					// Fourth Vertex
        gl.glEnd();
        
        gl.glRotatef(90.0f, 1.0f, 1.0f, 0.0f);
        gl.glBegin(GL.GL_QUADS);
            gl.glTexCoord2d(0.0f,0.0f);					// First Texture Coord
            gl.glVertex2f(-1.0f, 1.0f);					// First Vertex
            gl.glTexCoord2d(1.0f,0.0f);					// Second Texture Coord
            gl.glVertex2f( 1.0f, 1.0f);					// Second Vertex
            gl.glTexCoord2d(1.0f,1.0f);					// Third Texture Coord
            gl.glVertex2f( 1.0f,-1.0f);					// Third Vertex
            gl.glTexCoord2d(0.0f,1.0f);					// Fourth Texture Coord
            gl.glVertex2f(-1.0f,-1.0f);					// Fourth Vertex
        gl.glEnd();
        
        gl.glEnable(GL.GL_BLEND);
        gl.glLoadIdentity();
        
        //set color based on position of string...
        gl.glColor3f(1.0f*((float)(Math.cos(cnt1))),
                  1.0f*((float)(Math.sin(cnt2))),
                  1.0f-0.5f*((float)(Math.cos(cnt1+cnt2))));
        //pring string...
        glPrint(((int)((480+(screensize.width-500)*Math.cos(cnt1)))),
                ((int)(335+(screensize.height-455)*Math.sin(cnt2))),
                "NeHe",
                0, 
                gl);	// Print GL Text To The Screen

	gl.glColor3f(1.0f*((float)(Math.sin(cnt2))),
                     1.0f-0.5f*((float)(Math.cos(cnt1+cnt2))),
                     1.0f*((float)(Math.cos(cnt1))));
	glPrint(((int)((480+(screensize.width-500)*Math.cos(cnt2)))),
                ((int)(335+(screensize.height-455)*Math.sin(cnt1))),
                "OpenGL",
                1,
                gl);	// Print GL Text To The Screen
        
	gl.glColor3f(0.0f, 0.0f, 1.0f);						// Set Color To Blue
	glPrint(((int)(380+(screensize.width-500)*Math.cos((cnt2+cnt1)/5))),
                100,
                "Giuseppe D'Agata/Nick Campbell",
                0,
                gl);	// Draw Text To The Screen

	gl.glColor3f(1.0f, 1.0f, 1.0f);						// Set Color To White
	glPrint(((int)(382+(screensize.width-500)*Math.cos((cnt2+cnt1)/5))),
                100,
                "Giuseppe D'Agata/Nick Campbell",
                0,
                gl);	// Draw Offset Text To The Screen
        if (!(fullscreen))
        {
            cnt1 += 0.01f;
            cnt2 += 0.0081f;
        }
        else
        {
            cnt1 += 0.07f;
            cnt2 += 0.0581f;
        }
    }
    
    /** Called by drawable to show that a mode or device has changed <br>
     * <B>!! CURRENTLY NON-Functional IN JoGL !!</B>
     * @param gLDrawable The GLDrawable object.
     * @param modeChanged Indicates if the video mode has changed.
     * @param deviceChanged Indicates if the video device has changed.
     */
    public void displayChanged(GLDrawable gLDrawable, boolean modeChanged, boolean deviceChanged) { }
    
    /**  Called by the drawable immediately after the OpenGL context is 
     * initialized for the first time. Can be used to perform one-time OpenGL 
     * initialization such as setup of lights and display lists.
     * @param gLDrawable The GLDrawable object.
     */
    public void init(GLDrawable gLDrawable)
    {
        GL gl = gLDrawable.getGL();
        GLU glu = gLDrawable.getGLU();
        
        glObj = gl;
        
        //I don't know why, as of now, the PNG images come out crappy and messed up. Once i do i'll send an update to NeHe...for now it's
        //BMP's...
        String[] imgLoc = {"data/Font.bmp", "data/Bumps.bmp"};
        loadGLTextures(gl, glu, imgLoc);    // load the textures
        
        generateFont(gl);
        
        gl.glShadeModel(GL.GL_SMOOTH);
        gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);    // Black Background
        gl.glClearDepth(1.0f);                      // Depth Buffer Setup
        gl.glDepthFunc(GL.GL_LEQUAL);               // The Type Of Depth Testing To Do
        gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);	// Really Nice Perspective Calculations
        gl.glEnable(GL.GL_TEXTURE_2D);
        gLDrawable.addKeyListener(this);            // Listening for key events
    }
    
    /** Called by init(). This method is used to create our font as a display list. This list gets stored in the int base and 
     * is then created. This is not just one list btw, it is 256 lists for 256 characters. We create a list for each character.
     * @param gl send the gl object to this method for use.
     */
    public void generateFont(GL gl)
    {
        //character coords
        float cx;
        float cy;
        
        base = gl.glGenLists(256);
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);
        
        for (loop = 0; loop < 256; loop++)
        {
            cx = ((float)(loop%16))/16.0f;    // X Position Of Current Character
            cy = ((float)(loop/16))/16.0f;	// Y Position Of Current Character
            gl.glNewList(base+loop, GL.GL_COMPILE);
                gl.glBegin(GL.GL_QUADS);
                    gl.glTexCoord2f(cx,1-cy-0.0625f);   // Texture Coord (Bottom Left)
                    gl.glVertex2i(0,0);	// Vertex Coord (Bottom Left)
                    gl.glTexCoord2f(cx+0.0625f,1-cy-0.0625f);   // Texture Coord (Bottom Right)
                    gl.glVertex2i(16,0);    // Vertex Coord (Bottom Right)
                    gl.glTexCoord2f(cx+0.0625f,1-cy);   // Texture Coord (Top Right)
                    gl.glVertex2i(16,16);	// Vertex Coord (Top Right)
                    gl.glTexCoord2f(cx,1-cy);   // Texture Coord (Top Left)
                    gl.glVertex2i(0,16);    // Vertex Coord (Top Left)
                gl.glEnd(); // Done Building Our Quad (Character)
                gl.glTranslated(10,0,0);    // Move To The Right Of The Character
            gl.glEndList();		
        }
    }
    
    /** This method is called when the canvas is destroyed...When the user presses esc. This method deletes the font list we created.
     * @param gl send the gl object to this method for use.
     */
    public void killFont(GL gl)
    {
        gl.glDeleteLists(base,256);
    }
    
    /** Called by init(). This method is used to create our font as a display list. This list gets stored in the int base and 
     * is then created. This is not just one list btw, it is 256 lists for 256 characters. We create a list for each character.
     * @param x where to place the string on the x axis
     * @param y where to place the string on the y axis
     * @param text the string to display
     * @param set are we using the first character set or the second...
     * @param gl send the gl object to this method for use.
     */
    public void glPrint(int x, int y, String text, int set, GL gl)
    {
        int tmp = 0;
        if (set > 1) { set = 1; }
        gl.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);
        gl.glDisable(GL.GL_DEPTH_TEST);
        gl.glMatrixMode(GL.GL_PROJECTION);    // Select The Projection Matrix
	gl.glPushMatrix();			// Store The Projection Matrix
            gl.glLoadIdentity();
            gl.glOrtho(0, screensize.width, 0, screensize.height, -1, 1);
            gl.glMatrixMode(GL.GL_MODELVIEW);
            gl.glPushMatrix();
                gl.glLoadIdentity();
                gl.glTranslated(x, y, 0);
                gl.glListBase(base-32+(128*set));
                gl.glCallLists(text.length(), GL.GL_BYTE, text.getBytes());
            gl.glMatrixMode(GL.GL_PROJECTION);	// Select The Projection Matrix
            gl.glPopMatrix();	// Restore The Old Projection Matrix
        gl.glMatrixMode(GL.GL_MODELVIEW);
	gl.glPopMatrix();
        gl.glEnable(GL.GL_DEPTH_TEST);
    }
    
    /** This method loads textures into the texture array
     * @param gl A GL object to reference when setting values for it
     * @param glu A GLU object to reference when setting values for it
     * @param imgLoc The string location of the image/texture to load.
     */    
    public void loadGLTextures(GL gl, GLU glu, String[] imgLoc)
    {
        // make room for the number of textures/filters
        gl.glGenTextures(NUM_TEXTURES, texture);
        
        for (int i = 0; i < NUM_TEXTURES; i++)
        {
            // Create Linear Filtered Texture
            gl.glBindTexture(GL.GL_TEXTURE_2D, texture[i]);
            gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
            gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
            makeTexture(gl, glu, readImage(imgLoc[i]), GL.GL_TEXTURE_2D, false);
        }
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
    public void reshape(GLDrawable gLDrawable, int x, int y, int width, int height)
    {
        GL gl = gLDrawable.getGL();
        GLU glu = gLDrawable.getGLU();

        if (height <= 0) // avoid a divide by zero error!
            height = 1;
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
                 killFont(glObj);
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
    
    public void keyTyped(KeyEvent ke)
    {
    }
    
    
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
        else { return null; }
    }
    
    /* Helper methods for getting textures */
    //Definitely gotten from Kevin Duling (jattier@hotmail.com) in his ports to the NeHe
    //tuts. Same with the few methods that follow. I had to change the method getResource() to work 
    //better for locating the image and returning a valid resource. I have also changed some other
    //things but just to make it nicer and so that it fits better with my scheme of programming.
    private void makeTexture(GL gl, GLU glu, Object img, int target, boolean mipmapped)
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
      URL url = getClass().getResource(filename);
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
      // Try to load resource
      InputStream stream = getClass().getResourceAsStream(filename);
      if (stream == null)
      {
        System.out.println("stream is null...");
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
        
        Lesson17 lesson17 = new Lesson17(dim, fscreen);
        lesson17.addWindowListener(new WindowAdapter()
        {
            public void windowClosing(WindowEvent e)
            {
                System.exit(0);
            }
        });
        lesson17.setUndecorated(true);
        lesson17.setVisible(true);
        lesson17.getAnimator().start();
        lesson17.getGLCanvas().requestFocus();
    }
}