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
import java.util.StringTokenizer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.Util;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    26-Jun-2004
 *
 * Port of NeHe's Lesson 24 to LWJGL
 * Title: Tokens, Extensions, Scissor Testing And TGA Loading
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
public class Lesson24 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 24 for LWJGL (Tokens, Extensions, Scissor Testing And TGA Loading)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    int scroll;                                         // Used For Scrolling The Screen
    int maxtokens;                                      // Keeps Track Of The Number Of Extensions Supported
    int swidth;                                         // Scissor Width
    int sheight;                                        // Scissor Height

    int base;                                           // Base Display List For The Font

    int texture;                                   // Storage For One Texture

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson24 l24 = new Lesson24();
        l24.run(fullscreen);
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

        if (Keyboard.isKeyDown(Keyboard.KEY_UP) && (scroll > 0)) {                  // Is Up Arrow Being Pressed?
            scroll -= 2;                                  // If So, Decrease 'scroll' Moving Screen Down
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN) && (scroll < 32 * (maxtokens - 9)) ) {// Is Down Arrow Being Pressed?
            scroll += 2;                                  // If So, Increase 'scroll' Moving Screen Up
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
        buildFont();
    }


    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int width = 640;
        int height = 480;
        swidth=width;                                           // Set Scissor Width To Window Width
        sheight=height;                                         // Set Scissor Height To Window Height
        GL11.glEnable(GL11.GL_TEXTURE_2D);
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);               // Black Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture);

        GL11.glViewport(0,0,width,height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        GL11.glOrtho(0.0f,640,480,0.0f,-1.0f,1.0f);                  // Create Ortho 640x480 View (0,0 At Top Left)

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix
    }

    // made some minor changes here to make the printing look the same.
    private void buildFont() {                                  // Build Our Font Display List
        float   cx;                                             // Holds Our X Character Coord
        float   cy;                                             // Holds Our Y Character Coord

        base = GL11.glGenLists(256);                            // Creating 256 Display Lists
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture);     // Select Our Font Texture
        for (int i=0;i<256;i++) {                               // Loop Through All 256 Lists
            cx = ((float)(i % 16)) / 16.0f;                     // X Position Of Current Character
            cy = ((float)(i / 16)) / 16.0f;                     // Y Position Of Current Character

            GL11.glNewList(base + i, GL11.GL_COMPILE);          // Start Building A List
            GL11.glBegin(GL11.GL_QUADS);                        // Use A Quad For Each Character
            GL11.glTexCoord2f(cx, 1.0f - cy - 0.0625f);           // Texture Coord (Bottom Left)
            GL11.glVertex2i(0, 32);                           // Vertex Coord (Bottom Left)
            GL11.glTexCoord2f(cx + 0.0625f, 1.0f - cy - 0.0625f);   // Texture Coord (Bottom Right)
            GL11.glVertex2i(16, 32);                          // Vertex Coord (Bottom Right)
            GL11.glTexCoord2f(cx + 0.0625f, 1.0f - cy - 0.001f);    // Texture Coord (Top Right)
            GL11.glVertex2i(16, 0);                           // Vertex Coord (Top Right)
            GL11.glTexCoord2f(cx, 1.0f - cy - 0.001f);            // Texture Coord (Top Left)
            GL11.glVertex2i(0, 0);                            // Vertex Coord (Top Left)
            GL11.glEnd();                                       // Done Building Our Quad (Character)
            GL11.glTranslatef(14.0f, 0.0f, 0.0f);               // Move To The Right Of The Character
            GL11.glEndList();                                   // Done Building The Display List
        }                                                       // Loop Until All 256 Are Built
    }

    private void glPrint(int x, int y, int set, String msg) {   // Where The Printing Happens
        if (set>1) {
            set=1;
        }
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture);           // Select Our Font Texture
        GL11.glDisable(GL11.GL_DEPTH_TEST);                           // Disables Depth Testing
        GL11.glMatrixMode(GL11.GL_PROJECTION);                        // Select The Projection Matrix
        GL11.glPushMatrix();                                     // Store The Projection Matrix
        GL11.glLoadIdentity();                                   // Reset The Projection Matrix
        GL11.glOrtho(0, 640, 480, 0, -1, 1);                          // Set Up An Ortho Screen
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

    private void render() {
        int cnt = 0;
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);     // Clear Screen And Depth Buffer

        GL11.glColor3f(1.0f,0.5f,0.5f);                              // Set Color To Bright Red
        glPrint(50,16,1,"Renderer");                            // Display Renderer
        glPrint(80,48,1,"Vendor");                              // Display Vendor Name
        glPrint(66,80,1,"Version");                             // Display Version

        GL11.glColor3f(1.0f,0.7f,0.4f);                              // Set Color To Orange
        glPrint(200,16,1,GL11.glGetString(GL11.GL_RENDERER));     // Display Renderer
        glPrint(200,48,1,GL11.glGetString(GL11.GL_VENDOR));       // Display Vendor Name
        glPrint(200,80,1,GL11.glGetString(GL11.GL_VERSION));      // Display Version

        GL11.glColor3f(0.5f,0.5f,1.0f);                              // Set Color To Bright Blue
        glPrint(192,432,1,"NeHe Productions");                  // Write NeHe Productions At The Bottom Of The Screen

        GL11.glDisable(GL11.GL_TEXTURE_2D);
        GL11.glLoadIdentity();                                       // Reset The ModelView Matrix
        GL11.glColor3f(1.0f,1.0f,1.0f);                              // Set The Color To White
        GL11.glBegin(GL11.GL_LINE_STRIP);                                 // Start Drawing Line Strips (Something New)
            GL11.glVertex2i(639,417);                                // Top Right Of Bottom Box
            GL11.glVertex2i(  0,417);                                // Top Left Of Bottom Box
            GL11.glVertex2i(  0,480);                                // Lower Left Of Bottom Box
            GL11.glVertex2i(639,480);                                // Lower Right Of Bottom Box
            GL11.glVertex2i(639,128);                                // Up To Bottom Right Of Top Box
        GL11.glEnd();                                                // Done First Line Strip
        GL11.glBegin(GL11.GL_LINE_STRIP);                                 // Start Drawing Another Line Strip
            GL11.glVertex2i(  0,128);                                // Bottom Left Of Top Box
            GL11.glVertex2i(639,128);                                // Bottom Right Of Top Box
            GL11.glVertex2i(639,  1);                                // Top Right Of Top Box
            GL11.glVertex2i(  0,  1);                                // Top Left Of Top Box
            GL11.glVertex2i(  0,417);                                // Down To Top Left Of Bottom Box
        GL11.glEnd();                                                // Done Second Line Strip
        GL11.glEnable(GL11.GL_TEXTURE_2D);

        GL11.glScissor(1 ,((int)(0.135416f*sheight)),swidth-2,((int)(0.597916f*sheight)));   // Define Scissor Region
        Util.checkGLError();



        GL11.glEnable(GL11.GL_SCISSOR_TEST);                              // Enable Scissor Testing
        Util.checkGLError();

        String extensions = GL11.glGetString(GL11.GL_EXTENSIONS);
        StringTokenizer st = new StringTokenizer(extensions, " ");

        maxtokens = st.countTokens();
        while(st.hasMoreElements()) {
            cnt++;

            GL11.glColor3f(0.5f,1.0f,0.5f);                          // Set Color To Bright Green
            glPrint(0,96+(cnt*32)-scroll,0, "" + cnt);           // Print Current Extension Number
            GL11.glColor3f(1.0f,1.0f,0.5f);                          // Set Color To Yellow
            glPrint(50,96+(cnt*32)-scroll,0,(String)st.nextElement());             // Print The Current Token (Parsed Extension Name)
        }

        GL11.glDisable(GL11.GL_SCISSOR_TEST);                             // Disable Scissor Testing

        GL11.glFlush();                                              // Flush The Rendering Pipeline
    }

    private void cleanup() {
        Display.destroy();
    }

    private void loadTextures() {                                   // Load Bitmaps And Convert To Textures
        texture = loadTextureTga("Data/Font.tga");
    }

    private int loadTextureTga(String path) {
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
