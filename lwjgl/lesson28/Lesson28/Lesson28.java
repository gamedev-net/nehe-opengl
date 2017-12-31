/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.IntBuffer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    23-Aug-2004
 *
 * Port of NeHe's Lesson 28 to LWJGL
 * Title: Bezier Patches
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL and to use
 *             DevIL for image loading.
 */
public class Lesson28 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 28 for LWJGL (Bezier Patches)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    private boolean space = false;

    float rotz = 0.0f;        // Rotation about the Z axis
    BezierPatch mybezier;           // The bezier patch we're going to use (NEW)
    boolean showCPoints = true;   // Toggles displaying the control point grid (NEW)
    int divs = 7;           // Number of intrapolations (conrols poly resolution) (NEW)

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson28 l28 = new Lesson28();
        l28.run(fullscreen);
    }
    public void run(boolean fullscreen) {
        this.fullscreen = fullscreen;
        try {
            init();

            while (!done) {
                render();
                mainloop();
                Display.update();
            }
            cleanup();
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(0);
        }
    }
    private void mainloop() {
        if(Keyboard.isKeyDown(Keyboard.KEY_ESCAPE)) {       // Exit if Escape is pressed
            done = true;
        }
        if(Display.isCloseRequested()) {                     // Exit if window is closed
            done = true;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_F1) && !f1) {    // Is F1 Being Pressed?
            f1 = true;                                      // Tell Program F1 Is Being Held
            switchMode();                                   // Toggle Fullscreen / Windowed Mode
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_F1)) {          // Is F1 Being Pressed?
            f1 = false;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {
            rotz -= 0.8f;       // rotate left
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {
            rotz += 0.8f;       // rotate right
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_UP)) {                      // resolution up
            divs++;
            mybezier.dlBPatch = genBezier(mybezier, divs);  // Update the patch
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN) && divs > 1) {
            divs--;
            mybezier.dlBPatch = genBezier(mybezier, divs);  // Update the patch
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_SPACE) && !space) {                   // SPACE toggles showCPoints
            showCPoints = !showCPoints;
            space = true;
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_SPACE)) {          // Is F1 Being Pressed?
            space = false;
        }

    }

    private void switchMode() {
        fullscreen = !fullscreen;
        try {
            Display.setFullscreen(fullscreen);
        }
        catch(Exception e) {
            e.printStackTrace();
        }
    }

    private void createWindow() throws Exception {
        Display.setFullscreen(fullscreen);
        DisplayMode d[] = Display.getAvailableDisplayModes();
        for (int i = 0; i < d.length; i++) {
            if (d[i].getWidth() == 640
                && d[i].getHeight() == 480
                && d[i].getBitsPerPixel() == 32) {
                displayMode = d[i];
                break;
            }
        }
        Display.setDisplayMode(displayMode);
        Display.setTitle(windowTitle);
        Display.create();
    }
    private void init() throws Exception {
        createWindow();
        IL.create();

        initGL();
    }


    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int width = 640;
        int height = 480;
        GL11.glEnable(GL11.GL_TEXTURE_2D);                            // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.05f, 0.05f, 0.05f, 0.5f);            // Black Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL);                             // The Type Of Depth Testing To Do
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);  // Really Nice Perspective Calculations

        mybezier = new BezierPatch();
        initBezier();                                           // Initialize the Bezier's control grid
        mybezier.texture  = loadTexture("Data/NeHe.bmp");  // Load the texture
        mybezier.dlBPatch = genBezier(mybezier, divs);          // Generate the patch

        GL11.glViewport(0,0,width,height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix
    }

    private void render() {
        int i, j;
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear Screen And Depth Buffer
        GL11.glLoadIdentity();                                   // Reset The Current Modelview Matrix
        GL11.glTranslatef(0.0f,0.0f,-4.0f);                      // Move Left 1.5 Units And Into The Screen 6.0
        GL11.glRotatef(-75.0f,1.0f,0.0f,0.0f);
        GL11.glRotatef(rotz,0.0f,0.0f,1.0f);                     // Rotate The Triangle On The Z axis ( NEW )

        GL11.glCallList(mybezier.dlBPatch);                      // Call the Bezier's display list
                                                            // this need only be updated when the patch changes

        if(showCPoints) {                                  // If drawing the grid is toggled on
            GL11.glDisable(GL11.GL_TEXTURE_2D);
            GL11.glColor3f(1.0f,0.0f,0.0f);
            for(i=0;i<4;i++) {                              // draw the horizontal lines
                GL11.glBegin(GL11.GL_LINE_STRIP);
                for(j=0;j<4;j++) {
                    GL11.glVertex3f((float)mybezier.anchors[i][j].x, (float)mybezier.anchors[i][j].y, (float)mybezier.anchors[i][j].z);
                }
                GL11.glEnd();
            }
            for(i=0;i<4;i++) {                              // draw the vertical lines
                GL11.glBegin(GL11.GL_LINE_STRIP);
                for(j=0;j<4;j++) {
                    GL11.glVertex3f((float)mybezier.anchors[j][i].x, (float)mybezier.anchors[j][i].y, (float)mybezier.anchors[j][i].z);
                }
                GL11.glEnd();
            }
            GL11.glColor3f(1.0f,1.0f,1.0f);
            GL11.glEnable(GL11.GL_TEXTURE_2D);
        }
    }

    //  Generates a display list based on the data in the patch
    //  and the number of divisions
    private int genBezier(BezierPatch patch, int divs) {
        int u = 0, v;
        float py, px, pyold;
        int drawlist = GL11.glGenLists(1);       // make the display list
        Point3D temp[] = initializePoint3D(4);
        Point3D last[] = initializePoint3D(divs + 1); // array of points to mark the first line of polys

        if(patch.dlBPatch != 0) {                    // get rid of any old display lists
            GL11.glDeleteLists(patch.dlBPatch, 1);
        }

        temp[0] = patch.anchors[0][3];             // the first derived curve (along x axis)
        temp[1] = patch.anchors[1][3];
        temp[2] = patch.anchors[2][3];
        temp[3] = patch.anchors[3][3];

        for (v=0;v<=divs;v++) {                        // create the first line of points
            px = ((float)v)/((float)divs);         // percent along y axis
            // use the 4 points from the derives curve to calculate the points along that curve
            last[v] = Bernstein(px, temp);
        }

        GL11.glNewList(drawlist, GL11.GL_COMPILE);               // Start a new display list
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, patch.texture);   // Bind the texture

        for(u=1;u<=divs;u++) {
            py   = ((float)u)/((float)divs);           // Percent along Y axis
            pyold = ((float)u-1.0f)/((float)divs);     // Percent along old Y axis

            temp[0] = Bernstein(py, patch.anchors[0]); // Calculate new bezier points
            temp[1] = Bernstein(py, patch.anchors[1]);
            temp[2] = Bernstein(py, patch.anchors[2]);
            temp[3] = Bernstein(py, patch.anchors[3]);

            GL11.glBegin(GL11.GL_TRIANGLE_STRIP);                    // Begin a new triangle strip

            for (v=0;v<=divs;v++) {
                px = ((float)v)/((float)divs);         // Percent along the X axis

                GL11.glTexCoord2f(pyold, px);               // Apply the old texture coords
                GL11.glVertex3f((float)last[v].x, (float)last[v].y, (float)last[v].z);   // Old Point

                last[v] = Bernstein(px, temp);         // Generate new point
                GL11.glTexCoord2f(py, px);                  // Apply the new texture coords
                GL11.glVertex3f((float)last[v].x, (float)last[v].y, (float)last[v].z);   // New Point
            }

            GL11.glEnd();                                   // END the triangle srip
        }

        GL11.glEndList();                               // END the list

        return drawlist;                           // Return the display list
    }

    private Point3D[] initializePoint3D(int count) {
        Point3D temp[] = new Point3D[count];

        for(int i=0;i<count;i++) {
            temp[i] = new Point3D();
        }

        return temp;
    }

    //  Calculates 3rd degree polynomial based on array of 4 points
    //  and a single variable (u) which is generally between 0 and 1
    private Point3D Bernstein(float u, Point3D p[]) {
        Point3D result;

        Point3D a = p[0].pointTimes(Math.pow(u, 3.0));
        Point3D b = p[1].pointTimes(3.0 * Math.pow(u, 2.0) * (1.0 - u));
        Point3D c = p[2].pointTimes(3.0 * u * Math.pow((1.0 - u), 2.0));
        Point3D d = p[3].pointTimes(Math.pow((1.0 - u), 3.0));

        result = a.pointAdd(b).pointAdd(c.pointAdd(d));

        return result;
    }

    /************************************************************************************/

    private void initBezier() {
        mybezier.anchors[0][0] = new Point3D(-0.75,   -0.75,  -0.5);  // set the bezier vertices
        mybezier.anchors[0][1] = new Point3D(-0.25,   -0.75,  0.0);
        mybezier.anchors[0][2] = new Point3D(0.25,    -0.75,  0.0);
        mybezier.anchors[0][3] = new Point3D(0.75,    -0.75,  -0.5);
        mybezier.anchors[1][0] = new Point3D(-0.75,   -0.25,  -0.75);
        mybezier.anchors[1][1] = new Point3D(-0.25,   -0.25,  0.5);
        mybezier.anchors[1][2] = new Point3D(0.25,    -0.25,  0.5);
        mybezier.anchors[1][3] = new Point3D(0.75,    -0.25,  -0.75);
        mybezier.anchors[2][0] = new Point3D(-0.75,   0.25,   0.0);
        mybezier.anchors[2][1] = new Point3D(-0.25,   0.25,   -0.5);
        mybezier.anchors[2][2] = new Point3D(0.25,    0.25,   -0.5);
        mybezier.anchors[2][3] = new Point3D(0.75,    0.25,   0.0);
        mybezier.anchors[3][0] = new Point3D(-0.75,   0.75,   -0.5);
        mybezier.anchors[3][1] = new Point3D(-0.25,   0.75,   -1.0);
        mybezier.anchors[3][2] = new Point3D(0.25,    0.75,   -1.0);
        mybezier.anchors[3][3] = new Point3D(0.75,    0.75,   -0.5);
        mybezier.dlBPatch = 0;
    }

    private void cleanup() {
        Display.destroy();
    }

    /**
     * Texture loading directly from LWJGL examples
     */
    private int loadTexture(String path) {
        IntBuffer image = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        IL.ilGenImages(1, image);
        IL.ilBindImage(image.get(0));
        IL.ilLoadImage(path);
        IL.ilConvertImage(IL.IL_RGB, IL.IL_BYTE);
        ByteBuffer scratch = ByteBuffer.allocateDirect(IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * 3);
        IL.ilCopyPixels(0, 0, 0, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 1, IL.IL_RGB, IL.IL_BYTE, scratch);
        
        // Create A IntBuffer For Image Address In Memory
        IntBuffer buf = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        GL11.glGenTextures(buf); // Create Texture In OpenGL

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(0));
        // Typical Texture Generation Using Data From The Image

        // Linear Filtering
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR);
        // Linear Filtering
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        // Generate The Texture
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RGB, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 0, GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

        return buf.get(0); // Return Image Address In Memory
    }
}
class Point3D {           // Structure for a 3-dimensional point (NEW)
    public double x, y, z;

    public Point3D(){}

    public Point3D(double a, double b, double c) {
        x = a;
        y = b;
        z = c;
    }
    // Adds 2 points. Don't just use '+' ;)
    // returns a new object
    public Point3D pointAdd(Point3D p) {
        return new Point3D(x + p.x, y + p.y, z + p.z);
    }

    // Multiplies a point and a constant. Don't just use '*'
    // returns a new object
    public Point3D pointTimes(double c) {
        return new Point3D(x * c, y * c, z * c);
    }
}

class BezierPatch {             // Structure for a 3rd degree bezier patch (NEW)
    Point3D anchors[][];          // 4x4 grid of anchor points
    int dlBPatch;               // Display List for Bezier Patch
    int texture;                // Texture for the patch

    public BezierPatch() {
        anchors = new Point3D[4][4];          // 4x4 grid of anchor points
        for(int i=0;i<4;i++) {
            for(int j=0;j<4;j++) {
                anchors[i][j] = new Point3D();
            }
        }
    }
}
