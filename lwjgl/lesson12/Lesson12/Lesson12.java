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

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    18-Nov-2003
 *
 * Port of NeHe's Lesson 12 to LWJGL
 * Title: Display Lists
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
public class Lesson12 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's Lesson 12 (Display Lists)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private int box;                // Storage For The Box Display List
    private int top;                // Storage For The Top Display List
    private int xloop;              // Loop For X Axis
    private int yloop;              // Loop For Y Axis

    private float xrot;             // Rotates Cube On The X Axis
    private float yrot;             // Rotates Cube On The Y Axis

    private float boxcol[][] = {
        {1.0f,0.0f,0.0f},
        {1.0f,0.5f,0.0f},
        {1.0f,1.0f,0.0f},
        {0.0f,1.0f,0.0f},
        {0.0f,1.0f,1.0f}
    };

    private float topcol[][] = {
        {.5f,0.0f,0.0f},
        {0.5f,0.25f,0.0f},
        {0.5f,0.5f,0.0f},
        {0.0f,0.5f,0.0f},
        {0.0f,0.5f,0.5f}
    };

    private int texture[] = new int[1]; // Storage For 1 Textures

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson12 l12 = new Lesson12();
        l12.run(fullscreen);
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
        if (Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {
            yrot -= 0.2f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {
            yrot += 0.2f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_UP)) {
            xrot -= 0.2f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            xrot += 0.2f;
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

    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);  // Clear The Screen And The Depth Buffer

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);
        for (int i=1;i<6;i++) {
            for (int j=0;j<i;j++) {
                GL11.glLoadIdentity();                          // Reset The View
                GL11.glTranslatef(1.4f+((float)j*2.8f)-((float)i*1.4f),((6.0f-(float)i)*2.4f)-7.0f,-20.0f);
                GL11.glRotatef(45.0f-(2.0f*i)+xrot,1.0f,0.0f,0.0f);
                GL11.glRotatef(45.0f+yrot,0.0f,1.0f,0.0f);
                GL11.glColor3f(boxcol[i-1][0],boxcol[i-1][1],boxcol[i-1][2]);
                GL11.glCallList(box);
                GL11.glColor3f(topcol[i-1][0],topcol[i-1][1],topcol[i-1][2]);
                GL11.glCallList(top);
            }
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

        loadTextures();
        buildLists();
        initGL();
    }

    private void loadTextures() {
        texture = loadTexture("Data/Cube.bmp");
    }

    private void initGL() {
        GL11.glEnable(GL11.GL_TEXTURE_2D);                          // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH);                          // Enables Smooth Color Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);                // This Will Clear The Background Color To Black
        GL11.glClearDepth(1.0);                                   // Enables Clearing Of The Depth Buffer
        GL11.glEnable(GL11.GL_DEPTH_TEST);                          // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL);                           // The Type Of Depth Test To Do
        GL11.glEnable(GL11.GL_LIGHT0);                              // Quick And Dirty Lighting (Assumes Light0 Is Set Up)
        GL11.glEnable(GL11.GL_LIGHTING);                            // Enable Lighting
        GL11.glEnable(GL11.GL_COLOR_MATERIAL);                      // Enable Material Coloring

        GL11.glMatrixMode(GL11.GL_PROJECTION);                      // Select The Projection Matrix
        GL11.glLoadIdentity();                                    // Reset The Projection Matrix
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                       // Select The Modelview Matrix
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST); // Really Nice Perspective Calculations
    }
    private void cleanup() {
        Display.destroy();
    }

    private final int[] loadTexture(String path) {
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
    // Build Cube Display Lists
    private void buildLists() {
        box = GL11.glGenLists(2);                                   // Generate 2 Different Lists
        GL11.glNewList(box,GL11.GL_COMPILE);                            // Start With The Box List
            GL11.glBegin(GL11.GL_QUADS);
                // Bottom Face
                GL11.glNormal3f( 0.0f,-1.0f, 0.0f);
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
                // Front Face
                GL11.glNormal3f( 0.0f, 0.0f, 1.0f);
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
                // Back Face
                GL11.glNormal3f( 0.0f, 0.0f,-1.0f);
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
                // Right face
                GL11.glNormal3f( 1.0f, 0.0f, 0.0f);
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
                // Left Face
                GL11.glNormal3f(-1.0f, 0.0f, 0.0f);
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
            GL11.glEnd();
        GL11.glEndList();
        top = box+1;                                            // Storage For "Top" Is "Box" Plus One
        GL11.glNewList(top,GL11.GL_COMPILE);                            // Now The "Top" Display List
            GL11.glBegin(GL11.GL_QUADS);
                // Top Face
                GL11.glNormal3f( 0.0f, 1.0f, 0.0f);
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
            GL11.glEnd();
        GL11.glEndList();
    }
}
