/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.Cylinder;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.opengl.glu.Sphere;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    26-Jun-2004
 *
 * Port of NeHe's Lesson 23 to LWJGL
 * Title: Sphere Mapping Quadrics In OpenGL
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
public class Lesson23 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 23 for LWJGL (Sphere Mapping Quadrics In OpenGL)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    boolean light;              // Lighting ON/OFF
    boolean lp;                 // L Pressed?
    boolean fp;                 // F Pressed?
    boolean sp;                 // Spacebar Pressed?

    int part1;              // Start Of Disc
    int part2;              // End Of Disc
    int p1=0;               // Increase 1
    int p2=1;               // Increase 2

    float xrot;               // X Rotation
    float yrot;               // Y Rotation
    float xspeed;             // X Rotation Speed
    float yspeed;             // Y Rotation Speed
    float z=-10.0f;           // Depth Into The Screen

//    GLUquadricObj *quadratic;   // Storage For Our Quadratic Objects
    Cylinder cylinder;
    Sphere sphere;

    float lightAmbient[]=     { 0.5f, 0.5f, 0.5f, 1.0f };
    float lightDiffuse[]=     { 1.0f, 1.0f, 1.0f, 1.0f };
    float lightPosition[]=    { 0.0f, 0.0f, 2.0f, 1.0f };

    int filter;             // Which Filter To Use
    int texture[];         // Storage For 6 Textures (MODIFIED)
    int object=1;           // Which Object To Draw

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson23 l23 = new Lesson23();
        l23.run(fullscreen);
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

        if(Keyboard.isKeyDown(Keyboard.KEY_L) && !lp) {
            lp = true;
            light = !light;
            if(!light) {
                GL11.glDisable(GL11.GL_LIGHTING);
            }
            else {
                GL11.glEnable(GL11.GL_LIGHTING);
            }
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_L)) {
            lp = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_F) && !fp) {
            fp = true;
            filter++;
            if(filter > 2) {
                filter = 0;
            }
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_F)) {
            fp = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_SPACE) && !sp) {
            sp = true;
            object++;
            if(object > 3) {
                object = 0;
            }
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_SPACE)) {
            sp = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {
            z -= 0.02f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {
            z += 0.02f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_UP)) {
            xspeed -= 0.01f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            xspeed += 0.01f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_UP)) {
            yspeed -= 0.01f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            yspeed += 0.01f;
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

        loadTextures();
    }


    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int width = 640;
        int height = 480;
        GL11.glEnable(GL11.GL_TEXTURE_2D);                            // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);               // Black Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL);                             // The Type Of Depth Testing To Do
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);  // Really Nice Perspective Calculations

        ByteBuffer temp = ByteBuffer.allocateDirect(16);
        temp.order(ByteOrder.nativeOrder());
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_AMBIENT, (FloatBuffer)temp.asFloatBuffer().put(lightAmbient).flip());              // Setup The Ambient Light
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_DIFFUSE, (FloatBuffer)temp.asFloatBuffer().put(lightDiffuse).flip());              // Setup The Diffuse Light
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_POSITION,(FloatBuffer)temp.asFloatBuffer().put(lightPosition).flip());         // Position The Light
        GL11.glEnable(GL11.GL_LIGHT1);                          // Enable Light One

        cylinder = new Cylinder();
        cylinder.setNormals(GLU.GLU_SMOOTH);           // Create Smooth Normals
        cylinder.setTextureFlag(true);              // Create Texture Coords
        sphere = new Sphere();
        sphere.setNormals(GLU.GLU_SMOOTH);           // Create Smooth Normals
        sphere.setTextureFlag(true);              // Create Texture Coords

        GL11.glTexGeni(GL11.GL_S, GL11.GL_TEXTURE_GEN_MODE, GL11.GL_SPHERE_MAP); // Set The Texture Generation Mode For S To Sphere Mapping (NEW)
        GL11.glTexGeni(GL11.GL_T, GL11.GL_TEXTURE_GEN_MODE, GL11.GL_SPHERE_MAP); // Set The Texture Generation Mode For T To Sphere Mapping (NEW)

        GL11.glViewport(0, 0, width, height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,(float)width/(float)height,0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix
    }

    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                   // Reset The View

        GL11.glTranslatef(0.0f,0.0f,z);

        GL11.glEnable(GL11.GL_TEXTURE_GEN_S);                         // Enable Texture Coord Generation For S (NEW)
        GL11.glEnable(GL11.GL_TEXTURE_GEN_T);                         // Enable Texture Coord Generation For T (NEW)

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[filter+(filter+1)]); // This Will Select The Sphere Map
        GL11.glPushMatrix();
        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);
        switch(object) {
            case 0:
                glDrawCube();
                break;
            case 1:
                GL11.glTranslatef(0.0f,0.0f,-1.5f);                  // Center The Cylinder
                cylinder.draw(1.0f,1.0f,3.0f,32,32);    // A Cylinder With A Radius Of 0.5 And A Height Of 2
                break;
            case 2:
                sphere.draw(1.3f,32,32);                // Draw A Sphere With A Radius Of 1 And 16 Longitude And 16 Latitude Segments
                break;
            case 3:
                GL11.glTranslatef(0.0f,0.0f,-1.5f);                  // Center The Cone
                cylinder.draw(1.0f,0.0f,3.0f,32,32);    // A Cone With A Bottom Radius Of .5 And A Height Of 2
                break;
        }

        GL11.glPopMatrix();
        GL11.glDisable(GL11.GL_TEXTURE_GEN_S);
        GL11.glDisable(GL11.GL_TEXTURE_GEN_T);

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[filter*2]);    // This Will Select The BG Maps...
        GL11.glPushMatrix();
        GL11.glTranslatef(0.0f, 0.0f, -24.0f);
        GL11.glBegin(GL11.GL_QUADS);
        GL11.glNormal3f( 0.0f, 0.0f, 1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-13.3f, -10.0f,  10.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 13.3f, -10.0f,  10.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 13.3f,  10.0f,  10.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-13.3f,  10.0f,  10.0f);
        GL11.glEnd();
        GL11.glPopMatrix();

        xrot+=xspeed;
        yrot+=yspeed;
    }

    private void glDrawCube() {
        GL11.glBegin(GL11.GL_QUADS);
        // Front Face
        GL11.glNormal3f( 0.0f, 0.0f, 0.5f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
        // Back Face
        GL11.glNormal3f( 0.0f, 0.0f,-0.5f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
        // Top Face
        GL11.glNormal3f( 0.0f, 0.5f, 0.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
        // Bottom Face
        GL11.glNormal3f( 0.0f,-0.5f, 0.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
        // Right Face
        GL11.glNormal3f( 0.5f, 0.0f, 0.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
        // Left Face
        GL11.glNormal3f(-0.5f, 0.0f, 0.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
        GL11.glEnd();
    }

    private void cleanup() {
        Display.destroy();
    }

    private void loadTextures() {                                   // Load Bitmaps And Convert To Textures
        texture = new int[6];
        int temp[] = loadTexture("Data/BG.bmp");
        texture[0] = temp[0];
        texture[2] = temp[1];
        texture[4] = temp[2];
        temp = loadTexture("Data/Reflect.bmp");
        texture[1] = temp[0];
        texture[3] = temp[1];
        texture[5] = temp[2];
    }

    /**
     * Texture loading directly from LWJGL examples
     */
    private int[] loadTexture(String path) {
        IntBuffer image = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        IL.ilGenImages(1, image);
        IL.ilBindImage(image.get(0));
        IL.ilLoadImage(path);
        IL.ilConvertImage(IL.IL_RGB, IL.IL_BYTE);
        ByteBuffer scratch = ByteBuffer.allocateDirect(IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * 3);
        IL.ilCopyPixels(0, 0, 0, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 1, IL.IL_RGB, IL.IL_BYTE, scratch);

        // Create A IntBuffer For Image Address In Memory
        IntBuffer buf = ByteBuffer.allocateDirect(12).order(ByteOrder.nativeOrder()).asIntBuffer();
        GL11.glGenTextures(buf); // Create Texture In OpenGL

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(0));
        // Typical Texture Generation Using Data From The Image

        // Create Nearest Filtered Texture
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(0));
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_NEAREST);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_NEAREST);
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RGB, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 0, GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

        // Create Linear Filtered Texture
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(1));
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR);
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RGB, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 0, GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

        // Create MipMapped Texture
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(2));
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR_MIPMAP_NEAREST);
        GLU.gluBuild2DMipmaps(GL11.GL_TEXTURE_2D, 3, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

      return new int[]{ buf.get(0), buf.get(1), buf.get(2) };     // Return Image Addresses In Memory
    }
}
