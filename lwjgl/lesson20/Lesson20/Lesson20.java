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
 * date:    26-Jun-2004
 *
 * Port of NeHe's Lesson 20 to LWJGL
 * Title: Masking
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
public class Lesson20 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 20 for LWJGL (Masking)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    boolean masking = true;     // Masking On/Off
    boolean mp;                 // M Pressed?
    boolean sp;                 // Space Pressed?
    boolean scene;              // Which Scene To Draw

    int  texture[];             // Storage For Our Five Textures

    float roll;                 // Rolling Texture


    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson20 l20 = new Lesson20();
        l20.run(fullscreen);
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
        if(Keyboard.isKeyDown(Keyboard.KEY_SPACE) && !sp) { // Is Space Being Pressed?
            sp = true;                                      // Tell Program Spacebar Is Being Held
            scene = !scene;                                 // Toggle From One Scene To The Other
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_SPACE)) {       // Has Spacebar Been Released?
            sp = false;                                     // Tell Program Spacebar Has Been Released
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_M) && !mp) {     // Is M Being Pressed?
            mp = true;                                      // Tell Program M Is Being Held
            masking = !masking;                             // Toggle Masking Mode OFF/ON
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_M)) {           // Has M Been Released?
            mp = false;                                     // Tell Program That M Has Been Released
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

        loadTextures();
        initGL();
    }
    private void loadTextures() {                                    // Load Bitmaps And Convert To Textures
        texture = new int[5];
        texture[0] = loadTexture("Data/Logo.bmp");
        texture[1] = loadTexture("Data/Mask1.bmp");
        texture[2] = loadTexture("Data/Image1.bmp");
        texture[3] = loadTexture("Data/Mask2.bmp");
        texture[4] = loadTexture("Data/Image2.bmp");
    }
    private void initGL() {                                     // All Setup For OpenGL Goes Here
        GL11.glEnable(GL11.GL_TEXTURE_2D);                            // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);               // Black Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glMatrixMode(GL11.GL_PROJECTION); // Select The Projection Matrix
        GL11.glLoadIdentity(); // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW); // Select The Modelview Matrix
        GL11.glLoadIdentity(); // Reset The Modelview Matrix

        // Really Nice Perspective Calculations
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);
    }

    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);     // Clear Screen And Depth Buffer
        GL11.glLoadIdentity();                                       // Reset The ModelView Matrix
        GL11.glTranslatef(0.0f,0.0f,-2.0f);                      // Move Into The Screen 5 Units

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);           // Select Our Logo Texture
        GL11.glBegin(GL11.GL_QUADS);                                  // Start Drawing A Textured Quad
            GL11.glTexCoord2f(0.0f, -roll+0.0f); GL11.glVertex3f(-1.1f, -1.1f,  0.0f);    // Bottom Left
            GL11.glTexCoord2f(3.0f, -roll+0.0f); GL11.glVertex3f( 1.1f, -1.1f,  0.0f);    // Bottom Right
            GL11.glTexCoord2f(3.0f, -roll+3.0f); GL11.glVertex3f( 1.1f,  1.1f,  0.0f);    // Top Right
            GL11.glTexCoord2f(0.0f, -roll+3.0f); GL11.glVertex3f(-1.1f,  1.1f,  0.0f);    // Top Left
        GL11.glEnd();                                            // Done Drawing The Quad

        GL11.glEnable(GL11.GL_BLEND);                                 // Enable Blending
        GL11.glDisable(GL11.GL_DEPTH_TEST);                           // Disable Depth Testing

        if (masking)                                        // Is Masking Enabled?
        {
            GL11.glBlendFunc(GL11.GL_DST_COLOR,GL11.GL_ZERO);              // Blend Screen Color With Zero (Black)
        }

        if (scene)                                          // Are We Drawing The Second Scene?
        {
            GL11.glTranslatef(0.0f,0.0f,-1.0f);                  // Translate Into The Screen One Unit
            GL11.glRotatef(roll*360,0.0f,0.0f,1.0f);             // Rotate On The Z Axis 360 Degrees.
            if (masking)                                    // Is Masking On?
            {
                GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[3]);   // Select The Second Mask Texture
                GL11.glBegin(GL11.GL_QUADS);                          // Start Drawing A Textured Quad
                    GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.1f, -1.1f,  0.0f);  // Bottom Left
                    GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.1f, -1.1f,  0.0f);  // Bottom Right
                    GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.1f,  1.1f,  0.0f);  // Top Right
                    GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.1f,  1.1f,  0.0f);  // Top Left
                GL11.glEnd();                                    // Done Drawing The Quad
            }

            GL11.glBlendFunc(GL11.GL_ONE, GL11.GL_ONE);                    // Copy Image 2 Color To The Screen
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[4]);       // Select The Second Image Texture
            GL11.glBegin(GL11.GL_QUADS);                              // Start Drawing A Textured Quad
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.1f, -1.1f,  0.0f);  // Bottom Left
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.1f, -1.1f,  0.0f);  // Bottom Right
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.1f,  1.1f,  0.0f);  // Top Right
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.1f,  1.1f,  0.0f);  // Top Left
            GL11.glEnd();                                        // Done Drawing The Quad
        }
        else                                                // Otherwise
        {
            if (masking)                                    // Is Masking On?
            {
                GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[1]);   // Select The First Mask Texture
                GL11.glBegin(GL11.GL_QUADS);                          // Start Drawing A Textured Quad
                    GL11.glTexCoord2f(roll+0.0f, 0.0f); GL11.glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
                    GL11.glTexCoord2f(roll+4.0f, 0.0f); GL11.glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
                    GL11.glTexCoord2f(roll+4.0f, 4.0f); GL11.glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
                    GL11.glTexCoord2f(roll+0.0f, 4.0f); GL11.glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
                GL11.glEnd();                                    // Done Drawing The Quad
            }

            GL11.glBlendFunc(GL11.GL_ONE, GL11.GL_ONE);                    // Copy Image 1 Color To The Screen
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[2]);       // Select The First Image Texture
            GL11.glBegin(GL11.GL_QUADS);                              // Start Drawing A Textured Quad
                GL11.glTexCoord2f(roll+0.0f, 0.0f); GL11.glVertex3f(-1.1f, -1.1f,  0.0f); // Bottom Left
                GL11.glTexCoord2f(roll+4.0f, 0.0f); GL11.glVertex3f( 1.1f, -1.1f,  0.0f); // Bottom Right
                GL11.glTexCoord2f(roll+4.0f, 4.0f); GL11.glVertex3f( 1.1f,  1.1f,  0.0f); // Top Right
                GL11.glTexCoord2f(roll+0.0f, 4.0f); GL11.glVertex3f(-1.1f,  1.1f,  0.0f); // Top Left
            GL11.glEnd();                                        // Done Drawing The Quad
        }

        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enable Depth Testing
        GL11.glDisable(GL11.GL_BLEND);                                // Disable Blending

        roll+=0.002f;                                       // Increase Our Texture Roll Variable
        if (roll>1.0f)                                      // Is Roll Greater Than One
        {
            roll-=1.0f;                                     // Subtract 1 From Roll
        }
    }

    private void cleanup() {
        Display.destroy();
    }

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
