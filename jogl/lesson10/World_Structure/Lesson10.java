package World_Structure;

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
 * Lesson10.java
 *
 * Created on December 20, 2003, 9:05 PM
 */

import OptionFrame.Options; //the only class in the package but it was easier to do this in porting the OpenGL tuts
import LoadImageTypes.*;    //the classes talked of above
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.StringTokenizer;
import java.net.*;
import net.java.games.jogl.*;   //JoGL Lib Imports

/** Used the JOGL2DBasics.java file from the aforementioned site for basic understanding.
 * Also, referenced the port of the NeHe's lessons by Kevin Duling (jattier@hotmail.com)
 * to gain my understanding of JoGL. I used his PNG loading methods and put the concepts
 * into a package. Also, I have used Abdul Bezrati's (abezrati@hotmail.com) *.bmp loader
 * and placed that in the same package. I created a jar for them and placed them in my
 * JRE_HOME/lib/ext directory. I have also created an OptionFrame which allows the user
 * to select different options and then load them into the main application. This was
 * put in it's own package and placed in the above directory. These two packages have
 * been included as folders in the jar, but i have also included the .jar files.
 * Thank you to the sources for the help and i hope that my contributions help anyone who
 * wishes for them to. Also, with the above package LoadImageTypes i have developed the
 * classes that are a part of that package so they may not be exactly as they were
 * but the main content is the same. It was easier to do this then to create it myself.
 * @author Nicholas Campbell - campbelln@hartwick.edu
 * @since 20 DECEMBER 2003
 * @version 1.00
 */
public class Lesson10 extends Frame implements GLEventListener, KeyListener
{
    /** the number of textures, really the number of filters but it produces 3
     *  different looking textures, thus the name
     */
    private final int NUM_TEXTURES = 3;
    
    /** the number of keys that we want to pay attention to */
    private final int NUM_KEYS = 250;
    
    /** the float value of PI/180 */
    private final float PI_OVER_180 = (float)(Math.PI/180.0);
    
    /** fullscreen or not, true means yes */
    private boolean fullscreen = true;
    /** is blending on or off */
    private boolean blending;
    /** is the key 'B' pressed or not, referenced in display() for blending*/
    private boolean bp;
    /** is the key 'F' pressed or not, referenced in display() for filtering*/
    private boolean fp;
    
    /** the array of textures for our objects */
    private int[] textures = new int[NUM_TEXTURES];
    /** the array of keys to store whether certain actions should be taken based on
     * their values
     */
    private boolean[] keys = new boolean[NUM_KEYS];
    /** the value of filtering determines the filter value */
    private int filtering = 0;
    /** the x position */
    private float xpos;
    /** the rotation value on the y axis */
    private float yrot;
    /** the z position */
    private float zpos;
    private float heading;
    /** walkbias for head bobbing effect */
    private float walkbias = 0.0f;
    /** the angle used in calculating walkbias */
    private float walkbiasangle = 0.0f;
    /** the value used for looking up or down pgup or pgdown */
    private float lookupdown = 0.0f;

    /** a GLCanvas object */
    private GLCanvas glCanvas;
    /** an Animator object */
    private Animator animator;
    /** a sector which holds a series of triangles*/
    private Sector sector;
    
    //holds a series of polygons, in this case triangles
    class Sector
    {
        //holds 3 vertices, points
        class Triangle
        {    
            //holds the values for each Vertex in a triangle
            class Vertex
            {
                private float x;  // 3D coords
                private float y;
                private float z;
                private float u;  //texture coords
                private float v;

                /** A Vertex of a Triangle.
                 * @param x X-Coordinate
                 * @param y Y-Coordinate
                 * @param z Z-Coordinate
                 * @param u U-Coordinate, for the texture
                 * @param v V-Coordinate, for the texture
                 */                
                public Vertex(float x, float y, float z, float u, float v)
                { this.x = x; this.y = y; this.z = z; this.u = u; this.v = v; }

                /** Return the X coordinate
                 * @return Return the X coordinate
                 */                
                public float getX() { return x; }
                /** Return the Y coordinate
                 * @return Return the Y coordinate
                 */                
                public float getY() { return y; }
                /** Return the Z coordinate
                 * @return Return the Z coordinate
                 */                
                public float getZ() { return z; }
                /** Return the U coordinate, for textures
                 * @return Return the U coordinate, for textures
                 */                
                public float getU() { return u; }
                /** Return the V coordinate, for textures
                 * @return Return the V coordinate, for textures
                 */                
                public float getV() { return v; }
                /** Returns the Vertex information in an array of floats
                 * @return Return an array of floats that are the coord info
                 */                
                public float[] getVertexInfo() { float[] f = { x, y, z, u, v }; return f; }

                /** Sets the X coordinate to x
                 * @param x Set the X coordinate to x
                 */                
                public void setX(float x) { this.x = x; }
                /** Set the Y coordinate to y
                 * @param y Set the Y coordinate to y
                 */                
                public void setY(float y) { this.y = y; }
                /** Set the Z coordinate to z
                 * @param z Set the Z coordinate to z
                 */                
                public void setZ(float z) { this.z = z; }
                /** Set the U coordinate to u
                 * @param u Set the U coordinate to u
                 */                
                public void setU(float u) { this.u = u; }
                /** Set the V coordinate to V
                 * @param v Set the V coordinate to V
                 */                
                public void setV(float v) { this.v = v; }
                //this last one will crash unless you have EXACTLY 5 elements in the array
                /** Set the Vertex info using the data in the array that is sent as a parameter
                 * @param f Set the Vertex information using the float array f
                 */                
                public void setVertexInfo(float[] f) 
                { f[0] = x; f[1] = y; f[2] = z; f[3] = u; f[4] = v; }
            }
    
            private final int NUM_VERTICES = 3;
            private Vertex[] vertex = new Vertex[NUM_VERTICES];
            
            /** Triangle class that has Vertices and has methods for
             * manipulating those Vertices.
             * @param f A multidimensional array; the first [] is
             * for the number of the vertex for that
             * Triangle and the second [] is for the value
             * x, y, z, u, or v
             */            
            public Triangle(float[][] f)
            {
                vertex[0] = new Vertex(f[0][0],
                                        f[0][1],
                                        f[0][2],
                                        f[0][3],
                                        f[0][4]);
                vertex[1] = new Vertex(f[1][0],
                                        f[1][1],
                                        f[1][2],
                                        f[1][3],
                                        f[1][4]);
                vertex[2] = new Vertex(f[2][0],
                                        f[2][1],
                                        f[2][2],
                                        f[2][3],
                                        f[2][4]);
            }
            
            /** Get the information, coordinates for placement and texture,
             * about the vertex specified.
             * @param which Which vertex to get info from
             * @return An array of float's are sent back holding the vertex coords
             */            
            public float[] getVertexInfo(int which) { return vertex[which].getVertexInfo(); }
            /** Sets the specified vertex's information using the
             * array sent.
             * @param which Which vertex to set
             * @param f An array of floats holding coordinate information
             */            
            public void setVertexInfo(int which, float[] f) { vertex[which].setVertexInfo(f); }
            /** Gets the information of the Triangle.
             * @return Sends back a multidimensional array of floats
             * detailing the information of the Triangle
             */            
            public float[][] getTriangleInfo()
            {
                float[][] f = { getVertexInfo(0), getVertexInfo(1), getVertexInfo(2) };
                //f[0] = getVertexInfo(0);
                //f[1] = getVertexInfo(1);
                //f[2] = getVertexInfo(2);
                return f;
            }
        }
        
        private int numTriangles;
        Triangle[] tri = null;
        
        /** A class that holds polygons, in this case Triangles,
         * and methods that manipulate those polygons.
         * @param s Takes an array of values so that the
         * polygons can be created, the first line
         * must be of format NUMPOLLIES ##<br>
         * and the others must have a format of
         * ## ## ## ## ##<br>
         * 5 numbers
         */        
        public Sector(String[] s)
        {
            StringTokenizer sT = new StringTokenizer(s[0], " ");
            String t = sT.nextToken();
            t = sT.nextToken();
            numTriangles = (new Integer(t)).intValue();
            tri = new Triangle[numTriangles];
            createTris(s);
        }
        
        /** Get the number of triangles
         * @return Returns the number of triangles
         */        
        public int getNumTriangles()
        {
            return numTriangles;
        }
        
        /** Return the coordinates of the triangle and it's
         * texture info.
         * @param whichTri Which Triangle of the number of triangles do you want
         * @return Return a multidimensional array of floats
         */        
        public float[][] getTriangleInfo(int whichTri)
        {
            return tri[whichTri].getTriangleInfo();
        }
        
        /** StringTokenizer breaks the strings up and with for loops
         * the information is added to it's correct Triangle
         * @param s An array of strings; formating of strings is specific
         */        
        public void createTris(String[] s)
        {
            int j = 0;
            int k = 1;
            String str;
            float[][] vertices = new float[3][5];
            for(int i = 1; i < (numTriangles + 1); i++)
            {
                for (j = 0; j < 3; j++)
                {
                    str = s[k];
                    StringTokenizer sT = new StringTokenizer(str, " ");
                    vertices[j][0] = (new Float(sT.nextToken())).floatValue();
                    vertices[j][1] = (new Float(sT.nextToken())).floatValue();
                    vertices[j][2] = (new Float(sT.nextToken())).floatValue();
                    vertices[j][3] = (new Float(sT.nextToken())).floatValue();
                    vertices[j][4] = (new Float(sT.nextToken())).floatValue();
                    k++;
                }
                tri[(i-1)] = new Triangle(vertices);
            }
        }
    }
    
    /** Creates a new instance of Lesson10
     * @param dim The Dimension of the Frame by which to view the canvas.
     * @param fscreen A boolean value to set fullscreen or not
     */
    public Lesson10(Dimension dim, boolean fscreen)
    {
        super("Creating a World...");
        fullscreen = fscreen;
        if (fullscreen == true)
            super.setSize(Toolkit.getDefaultToolkit().getScreenSize().getSize());
        else
            super.setSize(dim);
        filtering = 0;
        blending = false;
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
        // Clear Color Buffer, Depth Buffer
        gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT );
        gl.glLoadIdentity();
        
        float xTrans = -xpos;
        float yTrans = -walkbias - 0.43f;
        float zTrans = -zpos;
        float sceneroty = 360.0f - yrot;
        
        gl.glRotatef(lookupdown, 1.0f, 0.0f, 0.0f);
	gl.glRotatef(sceneroty, 0.0f, 1.0f, 0.0f);
	
	gl.glTranslatef(xTrans, yTrans, zTrans);
        gl.glBindTexture(gl.GL_TEXTURE_2D, textures[filtering]);
        float[][] f = null;
        for (int i = 0; i < sector.getNumTriangles(); i++)
        {
            f = sector.getTriangleInfo(i);
            gl.glBegin(GL.GL_TRIANGLES);
                gl.glNormal3f( 0.0f, 0.0f, 1.0f);
                //first vertex
                gl.glTexCoord2f(f[0][3], f[0][4]); gl.glVertex3f(f[0][0], f[0][1], f[0][2]);
                //second vertex
                gl.glTexCoord2f(f[1][3], f[1][4]); gl.glVertex3f(f[1][0], f[1][1], f[1][2]);
                //third vertex
                gl.glTexCoord2f(f[2][3], f[2][4]); gl.glVertex3f(f[2][0], f[2][1], f[2][2]);
            gl.glEnd();
        }
        
        if (keys['F'] && !fp)
        {
            fp = true;
            filtering++;
            if (filtering > 2)
                filtering = 0;
        }
        else if (!(keys['F']))
        {
            fp = false;
        }
        if (keys['B'] && !bp)
        {
            bp = true;
            blending = !blending;
            if (blending) { gl.glDisable(GL.GL_BLEND); gl.glEnable(GL.GL_DEPTH_TEST); }
            else { gl.glEnable(GL.GL_BLEND); gl.glDisable(GL.GL_DEPTH_TEST); }
        }
        else if (!(keys['B']))
        {
            bp = false;
        }
        if (keys[KeyEvent.VK_RIGHT])
        {
            heading -= 3.0f;
            yrot = heading;
        }
        else if (keys[KeyEvent.VK_LEFT])
        {
            heading += 3.0f;
            yrot = heading;
        }
        if (keys[KeyEvent.VK_UP])
        {
            xpos -= (float)Math.sin(heading*PI_OVER_180) * 0.1f;   // Move On The X-Plane Based On Player Direction
            zpos -= (float)Math.cos(heading*PI_OVER_180) * 0.1f;   // Move On The Z-Plane Based On Player Direction
            if (walkbiasangle >= 359.0f) { walkbiasangle = 0.0f; }
            else { walkbiasangle += 10.0f; }
            walkbias = (float)Math.sin(walkbiasangle * PI_OVER_180)/20.0f;  // Causes The Player To Bounce
        }
        else if (keys[KeyEvent.VK_DOWN])
        {
            xpos += (float)Math.sin(heading*PI_OVER_180) * 0.1f;    // Move On The X-Plane Based On Player Direction
            zpos += (float)Math.cos(heading*PI_OVER_180) * 0.1f;    // Move On The Z-Plane Based On Player Direction
            if (walkbiasangle <= 1.0f) { walkbiasangle = 359.0f; }
            else { walkbiasangle-= 10.0f; }
            walkbias = (float)Math.sin(walkbiasangle * PI_OVER_180)/20.0f;   // Causes The Player To Bounce
        }
        if (keys[KeyEvent.VK_PAGE_UP])
        {
            lookupdown += 2.0f;
        }
        else if (keys[KeyEvent.VK_PAGE_DOWN])
        {
            lookupdown -= 2.0f;
        }
        //gl.glFlush();
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
        GLU glu = gLDrawable.getGLU();
        GL gl = gLDrawable.getGL();
        gLDrawable.setGL( new DebugGL(gLDrawable.getGL()));
        
        gl.glShadeModel(GL.GL_SMOOTH);
        gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);    // Black Background
        gl.glClearDepth(1.0f);                      // Depth Buffer Setup
        gl.glEnable(GL.GL_DEPTH_TEST);              // Enables Depth Testing
        gl.glDepthFunc(GL.GL_LEQUAL);               // The Type Of Depth Testing To Do
        gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// Really Nice Perspective Calculations
        gl.glEnable(GL.GL_TEXTURE_2D);
        gLDrawable.addKeyListener(this);            // Listening for key events
        
        String imgLoc = "data/Mud.bmp";
        String worldDataLoc = "data/World.txt";
	gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);		// Blending Function For Translucency Based On Source Alpha Value ( NEW )
        gl.glDisable(GL.GL_BLEND);
        
        setupWorld(getResourceB(worldDataLoc));
        loadGLTextures(gl, glu, imgLoc);
    }
    
    /** This method loads textures into the texture array
     * @param gl A GL object to reference when setting values for it
     * @param glu A GLU object to reference when setting values for it
     * @param imgLoc The string location of the image/texture to load.
     */    
    public void loadGLTextures(GL gl, GLU glu, String imgLoc)
    {
        gl.glGenTextures(3, textures);
        
        // Create Nearest Filtered Texture
        gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
        makeTexture(gl, glu, readImage(imgLoc), GL.GL_TEXTURE_2D, false);
        gl.glBindTexture(GL.GL_TEXTURE_2D, textures[1]);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
        makeTexture(gl, glu, readImage(imgLoc), GL.GL_TEXTURE_2D, false);
        gl.glBindTexture(GL.GL_TEXTURE_2D, textures[2]);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
        makeTexture(gl, glu, readImage(imgLoc), GL.GL_TEXTURE_2D, true);
    }
    
    /** Reads the lines of the textfile sent as a parameter and loads them
     * into the sector
     * @param worldDataLoc The location of the textfile with the data
     */
    public void setupWorld(String worldDataLoc)
    {
        File file = new File(worldDataLoc);
        BufferedReader bR = null;
        try { bR = new BufferedReader(new FileReader(file)); }
        catch (FileNotFoundException fNFE) { System.out.println(fNFE); }
        try
        {
            while (!(bR.ready()))
            {
                try { Thread.sleep(200); } catch (InterruptedException ie) {}
            }
        }
        catch (IOException iOE) {}
        
        int i = 0;
        String[] s = new String[150];
        try
        {
            while (!(s[i]=(!((s[i] = bR.readLine()).trim().equals("EOF") || (s[i].trim().length() == 0) || (s[i].trim().startsWith("//"))))?s[i]:s[i--]).equals("EOF"))
            { i++; if (i == s.length) { break; } }
        }
        catch (IOException iOE) {}
        sector = new Sector(s);
        try { bR.close(); } catch (IOException ioe) {}
    }
    
    public void setupWorld(InputStream worldDataStream)
    {
        //File file = new File(worldDataLoc);
        
        BufferedReader bR = null;
        bR = new BufferedReader(new InputStreamReader(worldDataStream));
        //try { /*new FileReader(file));*/ }
        //try { bR = new BufferedReader(new FileReader(file)); }
        //catch (FileNotFoundException fNFE) { System.out.println(fNFE); }
        try
        {
            while (!(bR.ready()))
            {
                try { Thread.sleep(200); } catch (InterruptedException ie) {}
            }
        }
        catch (IOException iOE) {}
        
        int i = 0;
        String[] s = new String[150];
        try
        {
            while (!(s[i]=(!((s[i] = bR.readLine()).trim().equals("EOF") || (s[i].trim().length() == 0) || (s[i].trim().startsWith("//"))))?s[i]:s[i--]).equals("EOF"))
            { i++; if (i == s.length) { break; } }
        }
        catch (IOException iOE) {}
        sector = new Sector(s);
        try { bR.close(); } catch (IOException ioe) {}
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
        GLU glu = gLDrawable.getGLU();
        GL gl = gLDrawable.getGL();

        if (height <= 0) // avoid a divide by zero error!
            height = 1;
        float h = (float)width / (float)height;
        gl.glViewport(0, 0, width, height);
        gl.glMatrixMode(GL.GL_PROJECTION);
        gl.glLoadIdentity();
        glu.gluPerspective(45.0f, h, 1, 1000);
        gl.glMatrixMode(GL.GL_MODELVIEW);
        gl.glLoadIdentity();
    }
    
    /** Forced by KeyListener; listens for keypresses and
     * sets a value in an array if they are not of
     * KeyEvent.VK_ESCAPE or KeyEvent.VK_F1
     * @param ke The KeyEvent passed from the KeyListener
     */    
    public void keyPressed(KeyEvent ke)
    {
       switch(ke.getKeyCode())
       {
            case KeyEvent.VK_ESCAPE:
            {
                 System.out.println("User closed application.");
                 animator.stop();
                 System.exit(0);
                 break;
            }
            case KeyEvent.VK_F1:
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
    
    /** Unsets the value in the array for the key pressed.
     * @param ke The KeyEvent passed from the KeyListener
     */    
    public void keyReleased(KeyEvent ke)
    {
        if (ke.getKeyCode() < 250) { keys[ke.getKeyCode()] = false; }
    }
    
    /** ...has no purpose in this class :)
     * @param ke The KeyEvent passed from the KeyListener
     */    
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
    /** The main method of the application
     * @param args a parameter array
     */    
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
        
        Lesson10 lesson10 = new Lesson10(dim, fscreen);
        lesson10.addWindowListener(new WindowAdapter()
        {
            public void windowClosing(WindowEvent e)
            {
                System.exit(0);
            }
        });
        lesson10.setUndecorated(true);
        lesson10.show();
        lesson10.getAnimator().start();
        lesson10.getGLCanvas().requestFocus();
    }
}