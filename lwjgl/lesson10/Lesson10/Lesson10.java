/*
 *      This Code Was Created By Jeff Molofee 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit My Site At nehe.gamedev.net
 */

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.IntBuffer;
import java.util.StringTokenizer;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    16-Nov-2003
 *
 * Port of NeHe's Lesson 10 to LWJGL
 * Title: Loading And Moving Through A 3D World
 * Uses version 0.8alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * 2004-05-08: Updated to version 0.9alpha of LWJGL.
 *             Changed from all static to all instance objects.
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL and to use
 *             DevIL for image loading.
 */
public class Lesson10 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 10 for LWJGL (Loading And Moving Through A 3D World)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private boolean blend;              // Blending ON/OFF
    private boolean bp;                 // B Pressed?
    private boolean fp;                 // F Pressed?
    private final float piover180 = 0.0174532925f;
    private float heading;
    private float xpos;
    private float zpos;
    private float yrot;                 // Y Rotation
    private float walkbias = 0;
    private float walkbiasangle = 0;
    private float lookupdown = 0.0f;
    private float z=0.0f;               // Depth Into The Screen
    private int filter;                 // Which Filter To Use
    private int texture[]=new int[3];   // Storage For 3 Textures

    private Sector sector1;

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson10 l10 = new Lesson10();
        l10.run(fullscreen);
    }
    public void run(boolean fullscreen) {
        this.fullscreen = fullscreen;
        try {
            init();
            while (!done) {
                mainloop();
                render();
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
        if (Keyboard.isKeyDown(Keyboard.KEY_B) && !bp) {
            bp = true;
            blend = !blend;
            if (!blend) {
                GL11.glDisable(GL11.GL_BLEND);
                GL11.glEnable(GL11.GL_DEPTH_TEST);
            }
            else {
                GL11.glEnable(GL11.GL_BLEND);
                GL11.glDisable(GL11.GL_DEPTH_TEST);
            }
        }
        if (!Keyboard.isKeyDown(Keyboard.KEY_B)) {
            bp = false;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_F) && !fp) {
            fp = true;
            filter += 1;
            if (filter > 2) {
                filter = 0;
            }
        }
        if (!Keyboard.isKeyDown(Keyboard.KEY_F)) {
            fp = false;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {
            z -= 0.02f;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {
            z += 0.02f;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_UP)) {

            xpos -= (float) Math.sin(heading * piover180) * 0.05f;
            zpos -= (float) Math.cos(heading * piover180) * 0.05f;
            if (walkbiasangle >= 359.0f) {
                walkbiasangle = 0.0f;
            }
            else {
                walkbiasangle += 10;
            }
            walkbias = (float) Math.sin(walkbiasangle * piover180) / 20.0f;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            xpos += (float) Math.sin(heading * piover180) * 0.05f;
            zpos += (float) Math.cos(heading * piover180) * 0.05f;
            if (walkbiasangle <= 1.0f) {
                walkbiasangle = 359.0f;
            }
            else {
                walkbiasangle -= 10;
            }
            walkbias = (float) Math.sin(walkbiasangle * piover180) / 20.0f;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {
            heading -= 1.0f;
            yrot = heading;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {
            heading += 1.0f;
            yrot = heading;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {
            lookupdown -= 1.0f;
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {
            lookupdown += 1.0f;
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

    private boolean render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);  // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                  // Reset The View

        float x_m, y_m, z_m, u_m, v_m;
        float xtrans = -xpos;
        float ztrans = -zpos;
        float ytrans = -walkbias-0.25f;
        float sceneroty = 360.0f - yrot;

        int numTriangles;

        GL11.glRotatef(lookupdown,1.0f,0,0);
        GL11.glRotatef(sceneroty,0,1.0f,0);

        GL11.glTranslatef(xtrans, ytrans, ztrans);
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[filter]);

        numTriangles = sector1.numTriangles;

        // Process Each Triangle
        for (int loop_m = 0; loop_m < numTriangles; loop_m++)
        {
            GL11.glBegin(GL11.GL_TRIANGLES);
                GL11.glNormal3f( 0.0f, 0.0f, 1.0f);
                x_m = sector1.triangle[loop_m].vertex[0].x;
                y_m = sector1.triangle[loop_m].vertex[0].y;
                z_m = sector1.triangle[loop_m].vertex[0].z;
                u_m = sector1.triangle[loop_m].vertex[0].u;
                v_m = sector1.triangle[loop_m].vertex[0].v;
                GL11.glTexCoord2f(u_m,v_m); GL11.glVertex3f(x_m,y_m,z_m);

                x_m = sector1.triangle[loop_m].vertex[1].x;
                y_m = sector1.triangle[loop_m].vertex[1].y;
                z_m = sector1.triangle[loop_m].vertex[1].z;
                u_m = sector1.triangle[loop_m].vertex[1].u;
                v_m = sector1.triangle[loop_m].vertex[1].v;
                GL11.glTexCoord2f(u_m,v_m); GL11.glVertex3f(x_m,y_m,z_m);

                x_m = sector1.triangle[loop_m].vertex[2].x;
                y_m = sector1.triangle[loop_m].vertex[2].y;
                z_m = sector1.triangle[loop_m].vertex[2].z;
                u_m = sector1.triangle[loop_m].vertex[2].u;
                v_m = sector1.triangle[loop_m].vertex[2].v;
                GL11.glTexCoord2f(u_m,v_m); GL11.glVertex3f(x_m,y_m,z_m);
            GL11.glEnd();
        }
        return true;
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

        setupWorld();

        loadTextures();
        initGL();
    }

    private void loadTextures() {
        texture[0] = loadTexture("Data/Mud.bmp");
    }
    private void initGL() {
        GL11.glEnable(GL11.GL_TEXTURE_2D); // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH); // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f); // Black Background
        GL11.glClearDepth(1.0f); // Depth Buffer Setup
        // Really Nice Perspective Calculations
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);

        GL11.glMatrixMode(GL11.GL_PROJECTION); // Select The Projection Matrix
        GL11.glLoadIdentity(); // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW); // Select The Modelview Matrix
    }
    private static void cleanup() {
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

    private final void setupWorld() {
        float x, y, z, u, v;
        int numtriangles;

        try {
            String line;
            BufferedReader dis = new BufferedReader(new FileReader("data/world.txt"));

            while ((line = dis.readLine()) != null) {
                if (line.trim().length() == 0 || line.trim().startsWith("//"))
                    continue;

                if (line.startsWith("NUMPOLLIES")) {
                    int numTriangles;

                    numTriangles = Integer.parseInt(line.substring(line.indexOf("NUMPOLLIES") + "NUMPOLLIES".length() + 1));
                    sector1 = new Sector(numTriangles);

                    break;
                }
            }

            for (int i = 0; i < sector1.numTriangles; i++) {
                for (int vert = 0; vert < 3; vert++) {

                    while ((line = dis.readLine()) != null) {
                        if (line.trim().length() == 0 || line.trim().startsWith("//"))
                            continue;

                        break;
                    }

                    if (line != null) {
                        StringTokenizer st = new StringTokenizer(line, " ");

                        sector1.triangle[i].vertex[vert].x = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangle[i].vertex[vert].y = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangle[i].vertex[vert].z = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangle[i].vertex[vert].u = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangle[i].vertex[vert].v = Float.valueOf(st.nextToken()).floatValue();
                    }
                }
            }

            dis.close();

        }
        catch (IOException ioe) {
            ioe.printStackTrace();
        }
    }
}
class Vertex {
    public float x, y, z;
    public float u, v;
}

class Triangle {
    public Vertex vertex[];

    public Triangle() {
        vertex=new Vertex[3];
        for(int i=0;i<3;i++) {
            vertex[i]=new Vertex();
        }
    }
}

class Sector {
    public int numTriangles;
    Triangle triangle[]; //holds class Triangle objects
    public Sector(int num) {
        numTriangles=num;
        triangle=new Triangle[numTriangles];
        for(int i=0;i<numTriangles;i++) {
            triangle[i]=new Triangle();
        }
    }
}