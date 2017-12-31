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
 * date:    16-Nov-2003
 *
 * Port of NeHe's Lesson 9 to LWJGL
 * Title: Moving Bitmaps In 3D Space
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
public class Lesson09 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 9 for LWJGL (Moving Bitmaps In 3D Space)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private boolean twinkle; // Twinkling Stars
    private boolean tp; // 'T' Key Pressed?
    private final int num = 50; // Number Of Stars To Draw
    private boolean keys[] = new boolean[9]; // Array Used For The Keyboard Routine
    private Stars star[] = new Stars[num]; // Need To Keep Track Of 'num' Stars
    private float zoom = -15.0f; // Distance Away From Stars
    private float tilt = 90.0f; // Tilt The View
    private float spin; // Spin Stars
    private int texture[] = new int[1]; // Storage for 1 texture

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson09 l9 = new Lesson09();
        l9.run(fullscreen);
    }
    public void run(boolean fullscreen) {
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
        if (Keyboard.isKeyDown(Keyboard.KEY_T) && !tp) {
            tp = true;
            twinkle = !twinkle;
        }
        else if (!Keyboard.isKeyDown(Keyboard.KEY_T)) {
            tp = false;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) { // Is Page Up Being Pressed?
            zoom -= 0.02f; // If So, Move Into The Screen
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_NEXT)) { // Is Page Down Being Pressed?
            zoom += 0.02f; // If So, Move Towards The Viewer
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_UP)) { // Is Up Arrow Being Pressed?
            tilt -= 0.01f; // If So, Decrease xspeed
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN)) { // Is Down Arrow Being Pressed?
            tilt += 0.01f; // If So, Increase xspeed
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
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]); // Select Our Texture

        for (int i = 0; i < num; i++) // Loop Through All The Stars
            {
            GL11.glLoadIdentity(); // Reset The View Before We Draw Each Star
            GL11.glTranslatef(0.0f, 0.0f, zoom); // Zoom Into The Screen (Using The Value In 'zoom')
            GL11.glRotatef(tilt, 1.0f, 0.0f, 0.0f); // Tilt The View (Using The Value In 'tilt')
            GL11.glRotatef(star[i].angle, 0.0f, 1.0f, 0.0f); // Rotate To The Current Stars Angle
            GL11.glTranslatef(star[i].dist, 0.0f, 0.0f); // Move Forward On The X Plane
            GL11.glRotatef(-star[i].angle, 0.0f, 1.0f, 0.0f); // Cancel The Current Stars Angle
            GL11.glRotatef(-tilt, 1.0f, 0.0f, 0.0f); // Cancel The Screen Tilt

            if (twinkle) {
                GL11.glColor4ub(star[(num - i) - 1].r, star[(num - i) - 1].g, star[(num - i) - 1].b, (byte) 255);
                GL11.glBegin(GL11.GL_QUADS);
                GL11.glTexCoord2f(0.0f, 0.0f);
                GL11.glVertex3f(-1.0f, -1.0f, 0.0f);
                GL11.glTexCoord2f(1.0f, 0.0f);
                GL11.glVertex3f(1.0f, -1.0f, 0.0f);
                GL11.glTexCoord2f(1.0f, 1.0f);
                GL11.glVertex3f(1.0f, 1.0f, 0.0f);
                GL11.glTexCoord2f(0.0f, 1.0f);
                GL11.glVertex3f(-1.0f, 1.0f, 0.0f);
                GL11.glEnd();
            }

            GL11.glRotatef(spin, 0.0f, 0.0f, 1.0f);
            GL11.glColor4ub(star[i].r, star[i].g, star[i].b, (byte) 255);
            GL11.glBegin(GL11.GL_QUADS);
            GL11.glTexCoord2f(0.0f, 0.0f);
            GL11.glVertex3f(-1.0f, -1.0f, 0.0f);
            GL11.glTexCoord2f(1.0f, 0.0f);
            GL11.glVertex3f(1.0f, -1.0f, 0.0f);
            GL11.glTexCoord2f(1.0f, 1.0f);
            GL11.glVertex3f(1.0f, 1.0f, 0.0f);
            GL11.glTexCoord2f(0.0f, 1.0f);
            GL11.glVertex3f(-1.0f, 1.0f, 0.0f);
            GL11.glEnd();

            spin += 0.01f;
            star[i].angle += (float) i / (float) num;
            star[i].dist -= 0.01f;
            if (star[i].dist < 0.0f) {
                star[i].dist += 5.0f;
                star[i].r = (byte) (Math.random() * 256.0);
                star[i].g = (byte) (Math.random() * 256.0);
                star[i].b = (byte) (Math.random() * 256.0);
            }
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

        loadTextures();
        initGL();

        for (int i = 0; i < num; i++) {
            star[i] = new Stars();
            star[i].angle = 0.0f;
            star[i].dist = ((float) i / (float) num) * 5.0f;
            star[i].r = (byte) (Math.random() * 256.0);
            star[i].g = (byte) (Math.random() * 256.0);
            star[i].b = (byte) (Math.random() * 256.0);
        }
    }

    private void loadTextures() {
        texture[0] = loadTexture("Data/Star.bmp");
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

        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE); // Blending Function For Translucency Based On Source Alpha Value ( NEW )
        GL11.glEnable(GL11.GL_BLEND);
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
class Stars {
    public byte r, g, b; // Stars Color
    public float dist; // Stars Distance From Center
    public float angle; // Stars Current Angle
}