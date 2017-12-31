/*
 *      This Code Was Created By Christopher Aliotta & Jeff Molofee 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up And Optimizing
 *      The Base Code, Making It More Flexible!  If You've Found This Code
 *      Useful, Please Let Me Know.  Visit My Site At nehe.gamedev.net
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
 * date:    19-Nov-2003
 *
 * Port of NeHe's Lesson 16 to LWJGL
 * Title: Cool Looking Fog
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
public class Lesson16 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's Lesson 16 (Cool Looking Fog)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private boolean light;                                  // Lighting ON/OFF
    private boolean lp;                                     // L Pressed?
    private boolean fp;                                     // F Pressed?
    private boolean gp;                                     // G Pressed? ( NEW )

    private float xrot;                                     // X Rotation
    private float yrot;                                     // Y Rotation
    private float xspeed;                                   // X Rotation Speed
    private float yspeed;                                   // Y Rotation Speed
    private float z = -5.0f;                                    // Depth Into The Screen

    private float lightAmbient[] = { 0.5f, 0.5f, 0.5f, 1.0f };
    private float lightDiffuse[] = { 1.0f, 1.0f, 1.0f, 1.0f };
    private float lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };
    private int filter;                                     // Which Filter To Use
    private int texture[] = new int[3];                     // Storage For 3 Textures
    private int fogMode[] = { GL11.GL_EXP, GL11.GL_EXP2, GL11.GL_LINEAR };  // Storage For Three Types Of Fog
    private int fogfilter = 0;                              // Which Fog Mode To Use
    private float fogColor[] = {0.5f, 0.5f, 0.5f, 1.0f};        // Fog Color

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson16 l16 = new Lesson16();
        l16.run(fullscreen);
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
            lp = true;
            light = !light;
            if (!light) {
                GL11.glDisable(GL11.GL_LIGHTING);
            }
            else {
                GL11.glEnable(GL11.GL_LIGHTING);
            }
        }
        if (!Keyboard.isKeyDown(Keyboard.KEY_L)) {
            lp = false;
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
            xspeed -= 0.01f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            xspeed += 0.01f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {
            yspeed += 0.01f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {
            yspeed -= 0.01f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_G) && !gp) {
            gp = true;
            fogfilter += 1;
            if (fogfilter > 2) {
                fogfilter = 0;
            }
            GL11.glFogi (GL11.GL_FOG_MODE, fogMode[fogfilter]); // Fog Mode
        }
        if (!Keyboard.isKeyDown(Keyboard.KEY_G)) {
            gp = false;
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
        GL11.glLoadIdentity();                                  // Reset The View
        GL11.glTranslatef(0.0f, 0.0f, z);

        GL11.glRotatef(xrot, 1.0f, 0.0f, 0.0f);
        GL11.glRotatef(yrot, 0.0f, 1.0f, 0.0f);

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[filter]);

        GL11.glBegin(GL11.GL_QUADS);
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
            // Top Face
            GL11.glNormal3f( 0.0f, 1.0f, 0.0f);
            GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
            GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
            GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
            GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
            // Bottom Face
            GL11.glNormal3f( 0.0f,-1.0f, 0.0f);
            GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
            GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
            GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
            GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
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

        xrot += xspeed;
        yrot += yspeed;
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
        texture = loadTexture("Data/Crate.bmp");
    }
    private void initGL() {
        GL11.glEnable(GL11.GL_TEXTURE_2D);                                  // Enable Texture Mapping
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE);                   // Set The Blending Function For Translucency
        GL11.glClearColor(0.5f, 0.5f, 0.5f, 0.0f);                          // This Will Clear The Background Color To Black
        GL11.glClearDepth(1.0);                                             // Enables Clearing Of The Depth Buffer
        GL11.glDepthFunc(GL11.GL_LESS);                                     // The Type Of Depth Test To Do
        GL11.glEnable(GL11.GL_DEPTH_TEST);                                  // Enables Depth Testing
        GL11.glShadeModel(GL11.GL_SMOOTH);                                  // Enables Smooth Color Shading
        GL11.glMatrixMode(GL11.GL_PROJECTION);                              // Select The Projection Matrix
        GL11.glLoadIdentity();                                              // Reset The Projection Matrix
        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                               // Select The Modelview Matrix
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);   // Really Nice Perspective Calculations

        ByteBuffer temp = ByteBuffer.allocateDirect(16);
        temp.order(ByteOrder.nativeOrder());
        temp.asFloatBuffer().put(lightAmbient).flip();
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_AMBIENT, temp.asFloatBuffer());    // Setup The Ambient Light
        temp.asFloatBuffer().put(lightDiffuse).flip();
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_DIFFUSE, temp.asFloatBuffer());    // Setup The Diffuse Light
        temp.asFloatBuffer().put(lightPosition).flip();
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_POSITION,temp.asFloatBuffer());    // Position The Light
        GL11.glEnable(GL11.GL_LIGHT1);                                      // Enable Light One

        GL11.glFogi(GL11.GL_FOG_MODE, fogMode[fogfilter]);                  // Fog Mode
        temp.asFloatBuffer().put(fogColor).flip();
        GL11.glFog(GL11.GL_FOG_COLOR, temp.asFloatBuffer());                // Set Fog Color
        GL11.glFogf(GL11.GL_FOG_DENSITY, 0.35f);                            // How Dense Will The Fog Be
        GL11.glHint(GL11.GL_FOG_HINT, GL11.GL_DONT_CARE);                   // Fog Hint Value
        GL11.glFogf(GL11.GL_FOG_START, 1.0f);                               // Fog Start Depth
        GL11.glFogf(GL11.GL_FOG_END, 5.0f);                                 // Fog End Depth
        GL11.glEnable(GL11.GL_FOG);                                         // Enables GL_FOG
    }
    private void cleanup() {
        Display.destroy();
    }

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
