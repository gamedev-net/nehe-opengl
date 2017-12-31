/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.StringTokenizer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    5-August-2004
 *
 * Port of NeHe's Lesson 25 to LWJGL
 * Title: Morphing & Loading Objects From A File
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL.
 */
public class Lesson25 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 25 for LWJGL (Morphing & Loading Objects From A File)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    private float xrot,yrot,zrot,                             // X, Y & Z Rotation
                xspeed,yspeed,zspeed,                       // X, Y & Z Spin Speed
                cx,cy,cz=-15;                               // X, Y & Z Position

    int key = 1;                                      // Used To Make Sure Same Morph Key Is Not Pressed
    int step = 0;
    int steps = 200;                           // Step Counter And Maximum Number Of Steps
    boolean morph = false;                                // Default morph To False (Not Morphing)

    int maxver;                                     // Will Eventually Hold The Maximum Number Of Vertices
    WorldObject morph1, morph2, morph3, morph4,                // Our 4 Morphable Objects (morph1,2,3 & 4)
                helper, sour, dest;                         // Helper Object, Source Object, Destination Object

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson25 l25 = new Lesson25();
        l25.run(fullscreen);
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

        if(Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {                             // Is Page Up Being Pressed?
            zspeed+=0.01f;                              // Increase zspeed
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {                              // Is Page Down Being Pressed?
            zspeed-=0.01f;                              // Decrease zspeed
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {                              // Is Down Arrow Being Pressed?
            xspeed+=0.01f;                              // Increase xspeed
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_UP)) {                                // Is Up Arrow Being Pressed?
            xspeed-=0.01f;                              // Decrease xspeed
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {                             // Is Right Arrow Being Pressed?
            yspeed+=0.01f;                              // Increase yspeed
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {                              // Is Left Arrow Being Pressed?
            yspeed-=0.01f;                              // Decrease yspeed
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_Q)) {                                 // Is Q Key Being Pressed?
            cz-=0.01f;                                     // Move Object Away From Viewer
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_Z)) {                                 // Is Z Key Being Pressed?
            cz+=0.01f;                                     // Move Object Towards Viewer
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_W)) {                                 // Is W Key Being Pressed?
            cy+=0.01f;                                     // Move Object Up
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_S)) {                                 // Is S Key Being Pressed?
            cy-=0.01f;                                     // Move Object Down
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_D)) {                                 // Is D Key Being Pressed?
            cx+=0.01f;                                     // Move Object Right
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_A)) {                                 // Is A Key Being Pressed?
            cx-=0.01f;                                     // Move Object Left
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_1) && (key!=1) && !morph) {           // Is 1 Pressed, key Not Equal To 1 And Morph False?
            key = 1;                                      // Sets key To 1 (To Prevent Pressing 1 2x In A Row)
            morph = true;                                 // Set morph To True (Starts Morphing Process)
            dest = morph1;                               // Destination Object To Morph To Becomes morph1
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_2) && (key!=2) && !morph) {           // Is 2 Pressed, key Not Equal To 2 And Morph False?
            key = 2;                                      // Sets key To 2 (To Prevent Pressing 2 2x In A Row)
            morph = true;                                 // Set morph To True (Starts Morphing Process)
            dest = morph2;                               // Destination Object To Morph To Becomes morph2
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_3) && (key!=3) && !morph) {           // Is 3 Pressed, key Not Equal To 3 And Morph False?
            key = 3;                                      // Sets key To 3 (To Prevent Pressing 3 2x In A Row)
            morph = true;                                 // Set morph To True (Starts Morphing Process)
            dest = morph3;                               // Destination Object To Morph To Becomes morph3
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_4) && (key!=4) && !morph) {           // Is 4 Pressed, key Not Equal To 4 And Morph False?
            key = 4;                                      // Sets key To 4 (To Prevent Pressing 4 2x In A Row)
            morph = true;                                 // Set morph To True (Starts Morphing Process)
            dest = morph4;                               // Destination Object To Morph To Becomes morph4
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

        initGL();
    }


    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int width = 640;
        int height = 480;
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE);                   // Set The Blending Function For Translucency
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               // This Will Clear The Background Color To Black
        GL11.glClearDepth(1.0);                                  // Enables Clearing Of The Depth Buffer
        GL11.glDepthFunc(GL11.GL_LESS);                               // The Type Of Depth Test To Do
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enables Smooth Color Shading
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);  // Really Nice Perspective Calculations

        maxver = 0;                                           // Sets Max Vertices To 0 By Default
        morph1 = new WorldObject();
        morph2 = new WorldObject();
        morph3 = new WorldObject();
        morph4 = new WorldObject();
        helper = new WorldObject();
        objload("data/sphere.txt", morph1);                 // Load The First Object Into morph1 From File sphere.txt
        objload("data/torus.txt", morph2);                  // Load The Second Object Into morph2 From File torus.txt
        objload("data/tube.txt", morph3);                   // Load The Third Object Into morph3 From File tube.txt

        objallocate(morph4, 486);                           // Manually Reserver Ram For A 4th 468 Vertice Object (morph4)
        for(int i=0;i<486;i++)                              // Loop Through All 468 Vertices
        {
            morph4.points[i].x = ((float)(Math.random() * 14000) / 1000) - 7;  // morph4 x Point Becomes A Random Float Value From -7 to 7
            morph4.points[i].y = ((float)(Math.random() * 14000) / 1000) - 7;  // morph4 y Point Becomes A Random Float Value From -7 to 7
            morph4.points[i].z = ((float)(Math.random() * 14000) / 1000) - 7;  // morph4 z Point Becomes A Random Float Value From -7 to 7
        }

        objload("data/sphere.txt", helper);                 // Load sphere.txt Object Into Helper (Used As Starting Point)
        sour = dest = morph1;                                  // Source & Destination Are Set To Equal First Object (morph1)

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

    private void objallocate(WorldObject k, int n) {                      // Allocate Memory For Each Object
        k.verts = n;
        k.points = new Vertex[n];                       // Sets points Equal To VERTEX * Number Of Vertices
        for(int i=0;i<n;i++) {
            k.points[i] = new Vertex();
        }
    }                                                       // (3 Points For Each Vertice)
    private void objload(String name, WorldObject k) {                      // Loads Object From File (name)
        try {
            BufferedReader in = new BufferedReader(new FileReader(name));
            String line = in.readLine();
            int index = line.indexOf("Vertices:") + 9;
            objallocate(k, Integer.parseInt(line.substring(index).trim()));
            for(int i=0;i<k.verts;i++) {
                line = in.readLine();
                StringTokenizer st = new StringTokenizer(line, " ");
                while(st.hasMoreElements()) {
                    k.points[i].x = Float.parseFloat((String)st.nextElement());
                    k.points[i].y = Float.parseFloat((String)st.nextElement());
                    k.points[i].z = Float.parseFloat((String)st.nextElement());
                }
            }
            in.close();
            if(k.verts > maxver) {
                maxver = k.verts;
            }
        }
        catch(Exception e) {
            e.printStackTrace();
        }
    }                                                       // Keeps Track Of Highest Number Of Vertices Used In Any Of The
    private Vertex calculate(int i) {                                 // Calculates Movement Of Points During Morphing
        Vertex a = new Vertex();                                           // Temporary Vertex Called a

        a.x=(sour.points[i].x - dest.points[i].x) / steps;    // a.x Value Equals Source x - Destination x Divided By Steps
        a.y=(sour.points[i].y - dest.points[i].y) / steps;    // a.y Value Equals Source y - Destination y Divided By Steps
        a.z=(sour.points[i].z - dest.points[i].z) / steps;    // a.z Value Equals Source z - Destination z Divided By Steps

        return a;                                           // Return The Results
    }                                                       // This Makes Points Move At A Speed So They All Get To Their
    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                   // Reset The View
        GL11.glTranslatef(cx,cy,cz);                             // Translate The The Current Position To Start Drawing
        GL11.glRotatef(xrot,1,0,0);                              // Rotate On The X Axis By xrot
        GL11.glRotatef(yrot,0,1,0);                              // Rotate On The Y Axis By yrot
        GL11.glRotatef(zrot,0,0,1);                              // Rotate On The Z Axis By zrot

        xrot+=xspeed; yrot+=yspeed; zrot+=zspeed;           // Increase xrot,yrot & zrot by xspeed, yspeed & zspeed

        float tx,ty,tz;                                   // Temp X, Y & Z Variables
        Vertex q = new Vertex();                                           // Holds Returned Calculated Values For One Vertex

        GL11.glBegin(GL11.GL_POINTS);                                 // Begin Drawing Points
            for(int i=0;i<morph1.verts;i++)                 // Loop Through All The Verts Of morph1 (All Objects Have
            {                                               // The Same Amount Of Verts For Simplicity, Could Use maxver Also)
                if(morph) q=calculate(i); else q.x=q.y=q.z=0;   // If morph Is True Calculate Movement Otherwise Movement=0
                helper.points[i].x-=q.x;                    // Subtract q.x Units From helper.points[i].x (Move On X Axis)
                helper.points[i].y-=q.y;                    // Subtract q.y Units From helper.points[i].y (Move On Y Axis)
                helper.points[i].z-=q.z;                    // Subtract q.z Units From helper.points[i].z (Move On Z Axis)
                tx=helper.points[i].x;                      // Make Temp X Variable Equal To Helper's X Variable
                ty=helper.points[i].y;                      // Make Temp Y Variable Equal To Helper's Y Variable
                tz=helper.points[i].z;                      // Make Temp Z Variable Equal To Helper's Z Variable

                GL11.glColor3f(0,1,1);                           // Set Color To A Bright Shade Of Off Blue
                GL11.glVertex3f(tx,ty,tz);                       // Draw A Point At The Current Temp Values (Vertex)
                GL11.glColor3f(0,0.5f,1);                        // Darken Color A Bit
                tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;            // Calculate Two Positions Ahead
                GL11.glVertex3f(tx,ty,tz);                       // Draw A Second Point At The Newly Calculate Position
                GL11.glColor3f(0,0,1);                           // Set Color To A Very Dark Blue
                tx-=2*q.x; ty-=2*q.y; ty-=2*q.y;            // Calculate Two More Positions Ahead
                GL11.glVertex3f(tx,ty,tz);                       // Draw A Third Point At The Second New Position
            }                                               // This Creates A Ghostly Tail As Points Move
        GL11.glEnd();                                            // Done Drawing Points

        // If We're Morphing And We Haven't Gone Through All 200 Steps Increase Our Step Counter
        // Otherwise Set Morphing To False, Make Source=Destination And Set The Step Counter Back To Zero.
        if(morph && step <= steps) {
            step++;
        }
        else {
            morph = false;
            sour = dest;
            step = 0;
        }
    }

    private void cleanup() {
        Display.destroy();
    }
}
class Vertex {                                          // Structure For 3D Points
    float x, y, z;                                    // X, Y & Z Points
}

//had to change the name so it does not conflict with java.lang.Object
class WorldObject {                                          // Structure For An Object
    int verts;                                      // Number Of Vertices For The Object
    Vertex points[];                                    // One Vertice (Vertex x,y & z)
}
