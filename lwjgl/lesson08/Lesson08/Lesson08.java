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
import java.nio.FloatBuffer;

import org.lwjgl.devil.IL;
import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    16-Nov-2003
 *
 * Port of NeHe's Lesson 8 to LWJGL
 * Title: Blending
 * Uses version 0.8alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * 2004-05-08: Updated to version 0.9alpha of LWJGL.
 *             Changed from all static to all instance objects.
 * 2004-09-22: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL and to use
 *             DevIL for image loading.
 */
public class Lesson08 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 8 for LWJGL (Blending)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private boolean light;                                      // Lighting ON / OFF
    private boolean blend;                                      // Blending OFF/ON? ( NEW )
    private boolean lp;                                         // L Pressed?
    private boolean fp;                                         // F Pressed?
    private boolean bp;                                         // B Pressed? ( NEW )
    private float xrot;                                         // X Rotation
    private float yrot;                                         // Y Rotation
    private float xspeed;                                       // X Rotation Speed
    private float yspeed;                                       // Y Rotation Speed
    private float z=-5.0f;                                      // Depth Into The Screen
    private float lightAmbient[]={ 0.5f, 0.5f, 0.5f, 1.0f };    // Ambient Light Values ( NEW )
    private float lightDiffuse[]={ 1.0f, 1.0f, 1.0f, 1.0f };    // Diffuse Light Values ( NEW )
    private float lightPosition[]={ 0.0f, 0.0f, 2.0f, 1.0f };   // Light Position ( NEW )
    private int filter;                                         // Which Filter To Use
    private int texture[]=new int[3];                           // Storage for 3 textures
    private boolean keys[]=new boolean[9];

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson08 l8 = new Lesson08();
        l8.run(fullscreen);
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
        if (Keyboard.isKeyDown(Keyboard.KEY_L) && !lp) {
            lp=true;
            light=!light;
            if (!light)                             // If Not Light
            {
                GL11.glDisable(GL11.GL_LIGHTING);       // Disable Lighting
            }
            else                                    // Otherwise
            {
                GL11.glEnable(GL11.GL_LIGHTING);        // Enable Lighting
            }
        }
        else if (!Keyboard.isKeyDown(Keyboard.KEY_L)) {
            lp=false;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_B) && !bp)              // Is B Key Pressed And bp FALSE?
        {
            bp=true;                            // If So, bp Becomes TRUE
            blend = !blend;                     // Toggle blend TRUE / FALSE
            if(blend)                           // Is blend TRUE?
            {
                GL11.glEnable(GL11.GL_BLEND);       // Turn Blending On
                GL11.glDisable(GL11.GL_DEPTH_TEST); // Turn Depth Testing Off
            }
            else                                // Otherwise
            {
                GL11.glDisable(GL11.GL_BLEND);      // Turn Blending Off
                GL11.glEnable(GL11.GL_DEPTH_TEST);  // Turn Depth Testing On
            }
        }
        if (!Keyboard.isKeyDown(Keyboard.KEY_B))        // Has B Key Been Released?
        {
            bp = false;                                 // If So, bp Becomes FALSE
        }

        if (Keyboard.isKeyDown(Keyboard.KEY_F) && !fp) {// Is F Key Being Pressed?
            fp = true;                                  // fp Becomes TRUE
            filter += 1;                                // filter Value Increases By One
            if (filter > 2)                             // Is Value Greater Than 2?
            {
                filter = 0;                             // If So, Set filter To 0
            }
        }
        else if (!Keyboard.isKeyDown(Keyboard.KEY_F)) {     // Has F Key Been Released?
            fp = false;                                     // If So, fp Becomes FALSE
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {       // Is Page Up Being Pressed?
            z -= 0.02f;                                     // If So, Move Into The Screen
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {        // Is Page Down Being Pressed?
            z += 0.02f;                                     // If So, Move Towards The Viewer
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_UP)) {          // Is Up Arrow Being Pressed?
            xspeed -= 0.01f;                                // If So, Decrease xspeed
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {        // Is Down Arrow Being Pressed?
            xspeed += 0.01f;                                // If So, Increase xspeed
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {       // Is Right Arrow Being Pressed?
            yspeed += 0.01f;                                // If So, Increase yspeed
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {        // Is Left Arrow Being Pressed?
            yspeed -= 0.01f;                                // If So, Decrease yspeed
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
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);          // Clear The Screen And The Depth Buffer

        GL11.glLoadIdentity();                          // Reset The Current Modelview Matrix

        GL11.glTranslatef(0.0f,0.0f,z);                     // Translate Into/Out Of The Screen By z

        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);                        // Rotate On The X Axis By xrot
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);                        // Rotate On The Y Axis By yrot
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[filter]);                // Select A Texture Based On filter

        GL11.glBegin(GL11.GL_QUADS);                            // Start Drawing Quads
        // Front Face
        GL11.glNormal3f( 0.0f, 0.0f, 1.0f);                 // Normal Pointing Towards Viewer
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);    // Point 1 (Front)
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);    // Point 2 (Front)
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);    // Point 3 (Front)
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);    // Point 4 (Front)
        // Back Face
        GL11.glNormal3f( 0.0f, 0.0f,-1.0f);                 // Normal Pointing Away From Viewer
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);    // Point 1 (Back)
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);    // Point 2 (Back)
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);    // Point 3 (Back)
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);    // Point 4 (Back)
        // Top Face
        GL11.glNormal3f( 0.0f, 1.0f, 0.0f);                 // Normal Pointing Up
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);    // Point 1 (Top)
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);    // Point 2 (Top)
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);    // Point 3 (Top)
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);    // Point 4 (Top)
        // Bottom Face
        GL11.glNormal3f( 0.0f,-1.0f, 0.0f);                 // Normal Pointing Down
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);    // Point 1 (Bottom)
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);    // Point 2 (Bottom)
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);    // Point 3 (Bottom)
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);    // Point 4 (Bottom)
        // Right face
        GL11.glNormal3f( 1.0f, 0.0f, 0.0f);                 // Normal Pointing Right
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);    // Point 1 (Right)
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);    // Point 2 (Right)
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);    // Point 3 (Right)
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);    // Point 4 (Right)
        // Left Face
        GL11.glNormal3f(-1.0f, 0.0f, 0.0f);                 // Normal Pointing Left
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);    // Point 1 (Left)
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);    // Point 2 (Left)
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);    // Point 3 (Left)
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);    // Point 4 (Left)
        GL11.glEnd();                               // Done Drawing Quads

        xrot+=xspeed;                               // Add xspeed To xrot
        yrot+=yspeed;                               // Add yspeed To yrot
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
    }
    private void loadTextures() {
        texture = loadTexture("Data/Glass.bmp");
    }
    private void initGL() {
        GL11.glEnable(GL11.GL_TEXTURE_2D); // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH); // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f); // Black Background
        GL11.glClearDepth(1.0f); // Depth Buffer Setup
        GL11.glEnable(GL11.GL_DEPTH_TEST); // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL); // The Type Of Depth Testing To Do

        GL11.glMatrixMode(GL11.GL_PROJECTION); // Select The Projection Matrix
        GL11.glLoadIdentity(); // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f, (float) displayMode.getWidth() / (float) displayMode.getHeight(),0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW); // Select The Modelview Matrix

        GL11.glColor4f(1.0f,1.0f,1.0f,0.5f);              // Full Brightness, 50% Alpha ( NEW )
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA,GL11.GL_ONE);      // Blending Function For Translucency Based On Source Alpha Value ( NEW )

        // Really Nice Perspective Calculations
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);
        ByteBuffer temp = ByteBuffer.allocateDirect(16);
        temp.order(ByteOrder.nativeOrder());
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_AMBIENT, (FloatBuffer)temp.asFloatBuffer().put(lightAmbient).flip());              // Setup The Ambient Light
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_DIFFUSE, (FloatBuffer)temp.asFloatBuffer().put(lightDiffuse).flip());              // Setup The Diffuse Light
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_POSITION,(FloatBuffer)temp.asFloatBuffer().put(lightPosition).flip());         // Position The Light
        GL11.glEnable(GL11.GL_LIGHT1);                          // Enable Light One
    }
    private void cleanup() {
        Display.destroy();
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
