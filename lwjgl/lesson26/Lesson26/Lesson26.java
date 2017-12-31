/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.DoubleBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.opengl.glu.Sphere;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    26-Jun-2004
 *
 * Port of NeHe's Lesson 26 to LWJGL
 * Title: Clipping & Reflections Using The Stencil Buffer
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
public class Lesson26 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 26 for LWJGL (Clipping & Reflections Using The Stencil Buffer)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    //  Light Parameters
    static float lightAmbient[] = {0.7f, 0.7f, 0.7f, 1.0f};  // Ambient Light
    static float lightDiffuse[] = {1.0f, 1.0f, 1.0f, 1.0f};  // Diffuse Light
    static float lightPosition[] = {4.0f, 4.0f, 6.0f, 1.0f};  // Light Position
    ByteBuffer lightBuffer;
    ByteBuffer reflectBuffer;

    Sphere q;

    float xrot = 0.0f;                        // X Rotation
    float yrot = 0.0f;                        // Y Rotation
    float xrotspeed = 0.0f;                        // X Rotation Speed
    float yrotspeed = 0.0f;                        // Y Rotation Speed
    float zoom = -7.0f;                        // Depth Into The Screen
    float height = 2.0f;                        // Height Of Ball From Floor

    int texture[];                                 // 3 Textures

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson26 l26 = new Lesson26();
        l26.run(fullscreen);
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

        if(Keyboard.isKeyDown(Keyboard.KEY_RIGHT))     yrotspeed += 0.08f;         // Right Arrow Pressed (Increase yrotspeed)
        if(Keyboard.isKeyDown(Keyboard.KEY_LEFT))      yrotspeed -= 0.08f;         // Left Arrow Pressed (Decrease yrotspeed)
        if(Keyboard.isKeyDown(Keyboard.KEY_DOWN))      xrotspeed += 0.08f;         // Down Arrow Pressed (Increase xrotspeed)
        if(Keyboard.isKeyDown(Keyboard.KEY_UP))        xrotspeed -= 0.08f;         // Up Arrow Pressed (Decrease xrotspeed)

        if(Keyboard.isKeyDown(Keyboard.KEY_A))          zoom +=0.05f;               // 'A' Key Pressed ... Zoom In
        if(Keyboard.isKeyDown(Keyboard.KEY_Z))          zoom -=0.05f;               // 'Z' Key Pressed ... Zoom Out

        if(Keyboard.isKeyDown(Keyboard.KEY_PRIOR))     height +=0.03f;             // Page Up Key Pressed Move Ball Up
        if(Keyboard.isKeyDown(Keyboard.KEY_NEXT))      height -=0.03f;             // Page Down Key Pressed Move Ball Down
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
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.2f, 0.5f, 1.0f, 1.0f);               // Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glClearStencil(0);                                  // Clear The Stencil Buffer To 0
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL);                             // The Type Of Depth Testing To Do
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);  // Really Nice Perspective Calculations
        GL11.glEnable(GL11.GL_TEXTURE_2D);                            // Enable 2D Texture Mapping

        reflectBuffer = ByteBuffer.allocateDirect(32);
        reflectBuffer.order(ByteOrder.nativeOrder());
        lightBuffer = ByteBuffer.allocateDirect(16);
        lightBuffer.order(ByteOrder.nativeOrder());
        GL11.glLight(GL11.GL_LIGHT0, GL11.GL_AMBIENT, (FloatBuffer)lightBuffer.asFloatBuffer().put(lightAmbient).flip());              // Setup The Ambient Light
        GL11.glLight(GL11.GL_LIGHT0, GL11.GL_DIFFUSE, (FloatBuffer)lightBuffer.asFloatBuffer().put(lightDiffuse).flip());              // Setup The Diffuse Light
        GL11.glLight(GL11.GL_LIGHT0, GL11.GL_POSITION, (FloatBuffer)lightBuffer.asFloatBuffer().put(lightPosition).flip());         // Position The Light

        GL11.glEnable(GL11.GL_LIGHT0);                                // Enable Light 0
        GL11.glEnable(GL11.GL_LIGHTING);                              // Enable Lighting

        q = new Sphere();
        q.setNormals(GL11.GL_SMOOTH);
        q.setTextureFlag(true);

        GL11.glTexGeni(GL11.GL_S, GL11.GL_TEXTURE_GEN_MODE, GL11.GL_SPHERE_MAP);    // Set Up Sphere Mapping
        GL11.glTexGeni(GL11.GL_T, GL11.GL_TEXTURE_GEN_MODE, GL11.GL_SPHERE_MAP);    // Set Up Sphere Mapping

        GL11.glViewport(0,0,width,height);                       // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                        // Select The Projection Matrix
        GL11.glLoadIdentity();                                   // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                         // Select The Modelview Matrix
        GL11.glLoadIdentity();                                   // Reset The Modelview Matrix
    }

    private void drawObject() {                                      // Draw Our Ball
        GL11.glColor3f(1.0f, 1.0f, 1.0f);                        // Set Color To White
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[1]);           // Select Texture 2 (1)
        q.draw(0.35f, 32, 16);                        // Draw First Sphere

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[2]);           // Select Texture 3 (2)
        GL11.glColor4f(1.0f, 1.0f, 1.0f, 0.4f);                  // Set Color To White With 40% Alpha
        GL11.glEnable(GL11.GL_BLEND);                                 // Enable Blending
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE);                  // Set Blending Mode To Mix Based On SRC Alpha
        GL11.glEnable(GL11.GL_TEXTURE_GEN_S);                         // Enable Sphere Mapping
        GL11.glEnable(GL11.GL_TEXTURE_GEN_T);                         // Enable Sphere Mapping

        q.draw(0.35f, 32, 16);                              // Draw Another Sphere Using New Texture
                                                            // Textures Will Mix Creating A MultiTexture Effect (Reflection)
        GL11.glDisable(GL11.GL_TEXTURE_GEN_S);                        // Disable Sphere Mapping
        GL11.glDisable(GL11.GL_TEXTURE_GEN_T);                        // Disable Sphere Mapping
        GL11.glDisable(GL11.GL_BLEND);                                // Disable Blending
    }

    private void drawFloor() {                                        // Draws The Floor
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);           // Select Texture 1 (0)
        GL11.glBegin(GL11.GL_QUADS);                                  // Begin Drawing A Quad
            GL11.glNormal3f(0.0f, 1.0f, 0.0f);                      // Normal Pointing Up
            GL11.glTexCoord2f(0.0f, 1.0f);                   // Bottom Left Of Texture
            GL11.glVertex3f(-2.0f, 0.0f, 2.0f);                 // Bottom Left Corner Of Floor

            GL11.glTexCoord2f(0.0f, 0.0f);                   // Top Left Of Texture
            GL11.glVertex3f(-2.0f, 0.0f,-2.0f);                 // Top Left Corner Of Floor

            GL11.glTexCoord2f(1.0f, 0.0f);                   // Top Right Of Texture
            GL11.glVertex3f( 2.0f, 0.0f,-2.0f);                 // Top Right Corner Of Floor

            GL11.glTexCoord2f(1.0f, 1.0f);                   // Bottom Right Of Texture
            GL11.glVertex3f( 2.0f, 0.0f, 2.0f);                 // Bottom Right Corner Of Floor
        GL11.glEnd();                                            // Done Drawing The Quad
    }

    private void render() {
        // Clear Screen, Depth Buffer & Stencil Buffer
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT | GL11.GL_STENCIL_BUFFER_BIT);

        // Clip Plane Equations
        double eqr[] = {0.0f,-1.0f, 0.0f, 0.0f};            // Plane Equation To Use For The Reflected Objects

        GL11.glLoadIdentity();                                   // Reset The Modelview Matrix
        GL11.glTranslatef(0.0f, -0.6f, zoom);                    // Zoom And Raise Camera Above The Floor (Up 0.6 Units)
        GL11.glColorMask(false, false, false, false);                               // Set Color Mask
        GL11.glEnable(GL11.GL_STENCIL_TEST);                          // Enable Stencil Buffer For "marking" The Floor
        GL11.glStencilFunc(GL11.GL_ALWAYS, 1, 255);                     // Always Passes, 1 Bit Plane, 1 As Mask
        GL11.glStencilOp(GL11.GL_KEEP, GL11.GL_KEEP, GL11.GL_REPLACE);          // We Set The Stencil Buffer To 1 Where We Draw Any Polygon
                                                            // Keep If Test Fails, Keep If Test Passes But Buffer Test Fails
                                                            // Replace If Test Passes
        GL11.glDisable(GL11.GL_DEPTH_TEST);                           // Disable Depth Testing
        drawFloor();                                        // Draw The Floor (Draws To The Stencil Buffer)
                                                            // We Only Want To Mark It In The Stencil Buffer
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enable Depth Testing
        GL11.glColorMask(true, true, true, true);                               // Set Color Mask to TRUE, TRUE, TRUE, TRUE
        GL11.glStencilFunc(GL11.GL_EQUAL, 1, 255);                      // We Draw Only Where The Stencil Is 1
                                                            // (I.E. Where The Floor Was Drawn)
        GL11.glStencilOp(GL11.GL_KEEP, GL11.GL_KEEP, GL11.GL_KEEP);             // Don't Change The Stencil Buffer
        GL11.glEnable(GL11.GL_CLIP_PLANE0);                           // Enable Clip Plane For Removing Artifacts
                                                            // (When The Object Crosses The Floor)
        GL11.glClipPlane(GL11.GL_CLIP_PLANE0, (DoubleBuffer)reflectBuffer.asDoubleBuffer().put(eqr).flip());                   // Equation For Reflected Objects
        GL11.glPushMatrix();                                     // Push The Matrix Onto The Stack
            GL11.glScalef(1.0f, -1.0f, 1.0f);                    // Mirror Y Axis
            GL11.glLight(GL11.GL_LIGHT0, GL11.GL_POSITION, (FloatBuffer)lightBuffer.asFloatBuffer().put(lightPosition).flip());    // Set Up Light0
            GL11.glTranslatef(0.0f, height, 0.0f);               // Position The Object
            GL11.glRotatef(xrot, 1.0f, 0.0f, 0.0f);              // Rotate Local Coordinate System On X Axis
            GL11.glRotatef(yrot, 0.0f, 1.0f, 0.0f);              // Rotate Local Coordinate System On Y Axis
            drawObject();                                   // Draw The Sphere (Reflection)
        GL11.glPopMatrix();                                      // Pop The Matrix Off The Stack
        GL11.glDisable(GL11.GL_CLIP_PLANE0);                          // Disable Clip Plane For Drawing The Floor
        GL11.glDisable(GL11.GL_STENCIL_TEST);                         // We Don't Need The Stencil Buffer Any More (Disable)
        GL11.glLight(GL11.GL_LIGHT0, GL11.GL_POSITION, (FloatBuffer)lightBuffer.asFloatBuffer().put(lightPosition).flip());        // Set Up Light0 Position
        GL11.glEnable(GL11.GL_BLEND);                                 // Enable Blending (Otherwise The Reflected Object Wont Show)
        GL11.glDisable(GL11.GL_LIGHTING);                             // Since We Use Blending, We Disable Lighting
        GL11.glColor4f(1.0f, 1.0f, 1.0f, 0.8f);                  // Set Color To White With 80% Alpha
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);  // Blending Based On Source Alpha And 1 Minus Dest Alpha
        drawFloor();                                        // Draw The Floor To The Screen
        GL11.glEnable(GL11.GL_LIGHTING);                              // Enable Lighting
        GL11.glDisable(GL11.GL_BLEND);                                // Disable Blending
        GL11.glTranslatef(0.0f, height, 0.0f);                   // Position The Ball At Proper Height
        GL11.glRotatef(xrot, 1.0f, 0.0f, 0.0f);                  // Rotate On The X Axis
        GL11.glRotatef(yrot, 0.0f, 1.0f, 0.0f);                  // Rotate On The Y Axis
        drawObject();                                       // Draw The Ball
        xrot += xrotspeed;                                  // Update X Rotation Angle By xrotspeed
        yrot += yrotspeed;                                  // Update Y Rotation Angle By yrotspeed
        GL11.glFlush();                                          // Flush The GL Pipeline
    }

    private void cleanup() {
        Display.destroy();
    }

    private void loadTextures() {                                   // Load Bitmaps And Convert To Textures
        texture = new int[3];
        texture[0] = loadTexture("Data/EnvWall.bmp");
        texture[1] = loadTexture("Data/Ball.bmp");
        texture[2] = loadTexture("Data/EnvRoll.bmp");
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
