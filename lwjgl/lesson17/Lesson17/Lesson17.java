/*
 *      This Code Was Created By Jeff Molofee 2000
 *      And Modified By Giuseppe D'Agata (waveform@tiscalinet.it)
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
 * date:    26-May-2004
 *
 * Port of NeHe's Lesson 17 to LWJGL
 * Title: Bitmap Fonts
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * The main point of this tutorial is to get fonts on the screen.  The original OpenGL did
 * not port directly as it used Windows specific extensions and I could not get some OpenGL
 * commands to work.  In the end, what you see on the screen is the same, but it is written
 * somewhat differently.  I have noted the differences in the code with comments.
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL and to use
 *             DevIL for image loading.
 */
public class Lesson17 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 13 for LWJGL (Bitmap Fonts)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private int texture[];
    private int base;                       // Base Display List For The Font Set
    private float cnt1;                     // 1st Counter Used To Move Text & For Coloring
    private float cnt2;                     // 2nd Counter Used To Move Text & For Coloring

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson17 l17 = new Lesson17();
        l17.run(fullscreen);
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
        buildFont();                                            // Build The Font
    }
    private void loadTextures() {
        texture = new int[2];

        texture[0] = loadTexture("Data/Font.bmp");
        texture[1] = loadTexture("Data/Bumps.bmp");
    }
    private void initGL() {                                     // All Setup For OpenGL Goes Here
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);              // Clear The Background Color To Black
        GL11.glClearDepth(1.0);                                 // Enables Clearing Of The Depth Buffer
        GL11.glDepthFunc(GL11.GL_LEQUAL);                       // The Type Of Depth Test To Do
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE);       // Select The Type Of Blending
        GL11.glShadeModel(GL11.GL_SMOOTH);                      // Enables Smooth Color Shading
        GL11.glEnable(GL11.GL_TEXTURE_2D);                      // Enable 2D Texture Mapping
        GL11.glMatrixMode(GL11.GL_PROJECTION);
        // Select The Projection Matrix
        GL11.glLoadIdentity(); // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW);
    }
    private void cleanup() {
        GL11.glDeleteLists(base, 256);                            // Delete All 256 Display Lists
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

    private void buildFont() {                                  // Build Our Font Display List
        float   cx;                                             // Holds Our X Character Coord
        float   cy;                                             // Holds Our Y Character Coord

        base = GL11.glGenLists(256);                            // Creating 256 Display Lists
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);     // Select Our Font Texture
        for (int i=0;i<256;i++) {                               // Loop Through All 256 Lists
            cx = ((float)(i % 16)) / 16.0f;                     // X Position Of Current Character
            cy = ((float)(i / 16)) / 16.0f;                     // Y Position Of Current Character

            GL11.glNewList(base + i, GL11.GL_COMPILE);          // Start Building A List
            GL11.glBegin(GL11.GL_QUADS);                        // Use A Quad For Each Character
            GL11.glTexCoord2f(cx, 1 - cy - 0.0625f);            // Texture Coord (Bottom Left)
            GL11.glVertex2i(0, 0);                              // Vertex Coord (Bottom Left)
            GL11.glTexCoord2f(cx + 0.0625f, 1 - cy - 0.0625f);  // Texture Coord (Bottom Right)
            GL11.glVertex2i(16,0);                              // Vertex Coord (Bottom Right)
            GL11.glTexCoord2f(cx + 0.0625f, 1 - cy);            // Texture Coord (Top Right)
            GL11.glVertex2i(16,16);                             // Vertex Coord (Top Right)
            GL11.glTexCoord2f(cx, 1 - cy);                      // Texture Coord (Top Left)
            GL11.glVertex2i(0, 16);                             // Vertex Coord (Top Left)
            GL11.glEnd();                                       // Done Building Our Quad (Character)
            GL11.glTranslatef(10.0f, 0.0f, 0.0f);               // Move To The Right Of The Character
            GL11.glEndList();                                   // Done Building The Display List
        }                                                       // Loop Until All 256 Are Built
    }

    private void glPrint(int x, int y, String msg, int set) {   // Where The Printing Happens
        if (set>1) {
            set=1;
        }
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);           // Select Our Font Texture
        GL11.glDisable(GL11.GL_DEPTH_TEST);                           // Disables Depth Testing
        GL11.glMatrixMode(GL11.GL_PROJECTION);                        // Select The Projection Matrix
        GL11.glPushMatrix();                                     // Store The Projection Matrix
        GL11.glLoadIdentity();                                   // Reset The Projection Matrix
        GL11.glOrtho(0, 640, 0, 480, -1, 1);                          // Set Up An Ortho Screen
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                         // Select The Modelview Matrix
        GL11.glPushMatrix();                                     // Store The Modelview Matrix
        GL11.glLoadIdentity();                                   // Reset The Modelview Matrix
        GL11.glTranslatef(x, y, 0);                                // Position The Text (0,0 - Bottom Left)
        int baseOffset = base - 32 + (128 * set);                // Choose The Font Set (0 or 1)
        for(int i=0;i<msg.length();i++) {
            GL11.glCallList(baseOffset + msg.charAt(i));
            GL11.glTranslatef(1.0f, 0.0f, 0.0f);
        }
        GL11.glMatrixMode(GL11.GL_PROJECTION);                        // Select The Projection Matrix
        GL11.glPopMatrix();                                      // Restore The Old Projection Matrix
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                         // Select The Modelview Matrix
        GL11.glPopMatrix();                                      // Restore The Old Projection Matrix
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
    }


    private void render() {                                                 // Here's Where We Do All The Drawing
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);  // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                              // Reset The Modelview Matrix
        GL11.glTranslatef(0.0f, 0.0f, -5.0f);                               // Move Into The Screen 5 Units
        GL11.glRotatef(45.0f, 0.0f, 0.0f, 1.0f);                            // Rotate On The Z Axis 45 Degrees (Clockwise)
        GL11.glRotatef(cnt1 * 30.0f, 1.0f, 1.0f, 0.0f);                     // Rotate On The X & Y Axis By cnt1 (Left To Right)
        GL11.glDisable(GL11.GL_BLEND);                                      // Disable Blending Before We Draw In 3D
        GL11.glColor3f(1.0f, 1.0f, 1.0f);                                   // Bright White

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[1]);                 // Select Our Second Texture
        GL11.glBegin(GL11.GL_QUADS); {                                        // Draw Our First Texture Mapped Quad
            GL11.glTexCoord2f(0.0f, 1.0f);                                      // First Texture Coord
            GL11.glVertex3f(-1.0f, 1.0f, 0.0f);                                       // First Vertex
            GL11.glTexCoord2f(1.0f, 1.0f);                                      // Second Texture Coord
            GL11.glVertex3f( 1.0f, 1.0f, 0.0f);                                       // Second Vertex
            GL11.glTexCoord2f(1.0f, 0.0f);                                      // Third Texture Coord
            GL11.glVertex3f( 1.0f, -1.0f, 0.0f);                                      // Third Vertex
            GL11.glTexCoord2f(0.0f, 0.0f);                                      // Fourth Texture Coord
            GL11.glVertex3f(-1.0f, -1.0f, 0.0f);                                      // Fourth Vertex
        }
        GL11.glEnd();                                                       // Done Drawing The First Quad
        GL11.glRotatef(90.0f, 1.0f, 1.0f, 0.0f);                            // Rotate On The X & Y Axis By 90 Degrees (Left To Right)
        GL11.glBegin(GL11.GL_QUADS); {                                        // Draw Our Second Texture Mapped Quad
            GL11.glTexCoord2f(0.0f, 0.0f);                                      // First Texture Coord
            GL11.glVertex2f(-1.0f, 1.0f);                                       // First Vertex
            GL11.glTexCoord2f(1.0f, 0.0f);                                      // Second Texture Coord
            GL11.glVertex2f( 1.0f, 1.0f);                                       // Second Vertex
            GL11.glTexCoord2f(1.0f, 1.0f);                                      // Third Texture Coord
            GL11.glVertex2f( 1.0f, -1.0f);                                      // Third Vertex
            GL11.glTexCoord2f(0.0f, 1.0f);                                      // Fourth Texture Coord
            GL11.glVertex2f(-1.0f, -1.0f);                                      // Fourth Vertex
        }
        GL11.glEnd();                                                       // Done Drawing Our Second Quad
        GL11.glEnable(GL11.GL_BLEND);                                       // Enable Blending

        GL11.glLoadIdentity();                                              // Reset The View
        // Pulsing Colors Based On Text Position
        GL11.glColor3f(
            1.0f * ((float)Math.cos(cnt1)),
            1.0f * ((float)Math.sin(cnt2)),
            1.0f - 0.5f * ((float)Math.cos(cnt1 + cnt2)));
        glPrint(                                                            // Print GL Text To The Screen
            ((int)(280 + 250 * Math.cos(cnt1))),
            ((int)(235 + 200 * Math.sin(cnt2))),
            "NeHe", 0);

        GL11.glColor3f(
            1.0f * ((float)Math.sin(cnt2)),
            1.0f - 0.5f * ((float)Math.cos(cnt1 + cnt2)),
            1.0f * ((float)Math.cos(cnt1)));
        glPrint(                                                            // Print GL Text To The Screen
            ((int)(280 + 230 * Math.cos(cnt2))),
            ((int)(235 + 200 * Math.sin(cnt1))),
            "OpenGL", 1);


        GL11.glColor3f(0.0f, 0.0f, 1.0f);                                   // Set Color To Blue
        glPrint(
            ((int)(240 + 200 * Math.cos((cnt2 + cnt1) / 5))),
            2,
            "Giuseppe D'Agata", 0);

        GL11.glColor3f(1.0f, 1.0f, 1.0f);                                   // Set Color To White
        glPrint(
            ((int)(242 + 200 * Math.cos((cnt2 + cnt1) / 5))),
            2,
            "Giuseppe D'Agata",
            0);

        cnt1 += 0.01f;                                                        // Increase The First Counter
        cnt2 += 0.0081f;                                                      // Increase The Second Counter
    }
}