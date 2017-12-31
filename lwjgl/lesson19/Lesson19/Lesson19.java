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
 * date:    23-Jun-2004
 *
 * Port of NeHe's Lesson 19 to LWJGL
 * Title: Particle Engine Using Triangle Strips
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
public class Lesson19 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 19 for LWJGL (Particle Engine Using Triangle Strips)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private final int MAX_PARTICLES = 1000;
    private Particle particle[];
    boolean rainbow = true;             // Rainbow Mode?
    boolean sp;                         // Spacebar Pressed?
    boolean rp;                         // Enter Key Pressed?

    float slowdown = 2.0f;              // Slow Down Particles
    float xspeed;                       // Base X Speed (To Allow Keyboard Direction Of Tail)
    float yspeed;                       // Base Y Speed (To Allow Keyboard Direction Of Tail)
    float zoom = -40.0f;                // Used To Zoom Out

    int col;                            // Current Color Selection
    int delay;                          // Rainbow Effect Delay
    int texture;                        // Storage For Our Particle Texture

    private static float colors[][]=       // Rainbow Of Colors
    {
        {1.0f,0.5f,0.5f},{1.0f,0.75f,0.5f},{1.0f,1.0f,0.5f},{0.75f,1.0f,0.5f},
        {0.5f,1.0f,0.5f},{0.5f,1.0f,0.75f},{0.5f,1.0f,1.0f},{0.5f,0.75f,1.0f},
        {0.5f,0.5f,1.0f},{0.75f,0.5f,1.0f},{1.0f,0.5f,1.0f},{1.0f,0.5f,0.75f}
    };

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson19 l19 = new Lesson19();
        l19.run(fullscreen);
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
        if(!Keyboard.isKeyDown(Keyboard.KEY_F1)) {          // Is F1 Being Released?
            f1 = false;
        }
        if((Keyboard.isKeyDown(Keyboard.KEY_SPACE) && !sp) || (rainbow && (delay > 25))) {
            if(Keyboard.isKeyDown(Keyboard.KEY_SPACE)) {
                rainbow = false;            // If Spacebar Is Pressed Disable Rainbow Mode
            }
            sp = true;                      // Set Flag Telling Us Space Is Pressed
            delay = 0;                      // Reset The Rainbow Color Cycling Delay
            col++;                          // Change The Particle Color
            if(col > 11) {
                col = 0;                    // If Color Is Too High Reset It
            }
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_SPACE)) {
            sp = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_ADD) && (slowdown > 1.0f)) {
            slowdown -= 0.01f;              // Speed Up Particles
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_SUBTRACT) && (slowdown < 4.0f)) {
            slowdown += 0.01f;              // Slow Down Particles
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {
            zoom += 0.1f;                   // Zoom In
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {
            zoom -= 0.1f;                   // Zoom Out
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_RETURN) && !rp) {         // Return Key Pressed
            rp = true;                      // Set Flag Telling Us It's Pressed
            rainbow = !rainbow;             // Toggle Rainbow Mode On / Off
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_RETURN)) {
            rp = false;                     // If Return Is Released Clear Flag
        }

        delay++;                            // Increase Rainbow Mode Color Cycling Delay Counter
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
        particle = new Particle[MAX_PARTICLES];

        for(int i=0;i<MAX_PARTICLES;i++) {
            particle[i] = new Particle();
        }

        createWindow();
        IL.create();

        loadTextures();
        initGL();

    }
    private void loadTextures() {                                    // Load Bitmaps And Convert To Textures
        texture = loadTexture("Data/Particle.bmp");
    }
    private void initGL() {                                         // All Setup For OpenGL Goes Here
        GL11.glEnable(GL11.GL_TEXTURE_2D);                          // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH);                          // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);                  // Black Background
        GL11.glClearDepth(1.0f);                                    // Depth Buffer Setup
        // Really Nice Perspective Calculations
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);

        GL11.glMatrixMode(GL11.GL_PROJECTION);                      // Select The Projection Matrix
        GL11.glLoadIdentity();                                      // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                       // Select The Modelview Matrix

        GL11.glDisable(GL11.GL_DEPTH_TEST);
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE);           // Type Of Blending To Perform
        GL11.glEnable(GL11.GL_BLEND);                               // Enable Blending

        for (int i=0;i<MAX_PARTICLES;i++)                           // Initials All The Textures
        {
            particle[i].active = true;                              // Make All The Particles Active
            particle[i].life = 1.0f;                                // Give All The Particles Full Life
            particle[i].fade = ((float)(Math.random() * 100.0)) / 1000.0f + 0.003f;   // Random Fade Speed
            particle[i].r = colors[i * (12 / MAX_PARTICLES)][0];    // Select Red Rainbow Color
            particle[i].g = colors[i * (12 / MAX_PARTICLES)][1];    // Select Red Rainbow Color
            particle[i].b = colors[i * (12 / MAX_PARTICLES)][2];    // Select Red Rainbow Color
            particle[i].xi = ((float)((Math.random() * 50.0)) - 26.0f) * 10.0f;       // Random Speed On X Axis
            particle[i].yi = ((float)((Math.random() * 50.0)) - 25.0f) * 10.0f;       // Random Speed On Y Axis
            particle[i].zi = ((float)((Math.random() * 50.0)) - 25.0f) * 10.0f;       // Random Speed On Z Axis
            particle[i].xg = 0.0f;                                   // Set Horizontal Pull To Zero
            particle[i].yg = -0.8f;                                    // Set Vertical Pull Downward
            particle[i].zg = 0.0f;                                     // Set Pull On Z Axis To Zero
        }
    }

    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);     // Clear Screen And Depth Buffer
        GL11.glLoadIdentity();                                       // Reset The ModelView Matrix

        for(int i=0;i<MAX_PARTICLES;i++) {                      // Loop Through All The Particles
            if (particle[i].active) {                           // If The Particle Is Active
                float x = particle[i].x;                        // Grab Our Particle X Position
                float y = particle[i].y;                        // Grab Our Particle Y Position
                float z = particle[i].z + zoom;                 // Particle Z Pos + Zoom

                // Draw The Particle Using Our RGB Values, Fade The Particle Based On It's Life
                GL11.glColor4f(particle[i].r, particle[i].g, particle[i].b, particle[i].life);

                GL11.glBegin(GL11.GL_TRIANGLE_STRIP);                     // Build Quad From A Triangle Strip
                GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(x + 0.5f, y + 0.5f, z); // Top Right
                GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(x - 0.5f, y + 0.5f, z); // Top Left
                GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(x + 0.5f, y - 0.5f, z); // Bottom Right
                GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(x - 0.5f, y - 0.5f, z); // Bottom Left
                GL11.glEnd();                                        // Done Building Triangle Strip

                particle[i].x += particle[i].xi / (slowdown * 1000);// Move On The X Axis By X Speed
                particle[i].y += particle[i].yi / (slowdown * 1000);// Move On The Y Axis By Y Speed
                particle[i].z += particle[i].zi / (slowdown * 1000);// Move On The Z Axis By Z Speed

                particle[i].xi += particle[i].xg;           // Take Pull On X Axis Into Account
                particle[i].yi += particle[i].yg;           // Take Pull On Y Axis Into Account
                particle[i].zi += particle[i].zg;           // Take Pull On Z Axis Into Account
                particle[i].life -= particle[i].fade;       // Reduce Particles Life By 'Fade'

                if (particle[i].life < 0.0f) {                  // If Particle Is Burned Out
                    particle[i].life = 1.0f;                   // Give It New Life
                    particle[i].fade = ((float)(Math.random() * 100.0)) / 1000.0f + 0.003f;   // Random Fade Value
                    particle[i].x = 0.0f;                      // Center On X Axis
                    particle[i].y = 0.0f;                      // Center On Y Axis
                    particle[i].z = 0.0f;                      // Center On Z Axis
                    particle[i].xi = xspeed + ((float)(Math.random() * 60.0)) - 32.0f;  // X Axis Speed And Direction
                    particle[i].yi = yspeed + ((float)(Math.random() * 60.0)) - 30.0f;  // Y Axis Speed And Direction
                    particle[i].zi = ((float)(Math.random() * 60.0)) - 30.0f; // Z Axis Speed And Direction
                    particle[i].r = colors[col][0];            // Select Red From Color Table
                    particle[i].g = colors[col][1];            // Select Green From Color Table
                    particle[i].b = colors[col][2];            // Select Blue From Color Table
                }

                // If Number Pad 8 And Y Gravity Is Less Than 1.5 Increase Pull Upwards
                if (Keyboard.isKeyDown(Keyboard.KEY_NUMPAD8) && (particle[i].yg<1.5f)) {
                    particle[i].yg += 0.01f;
                }

                // If Number Pad 2 And Y Gravity Is Greater Than -1.5 Increase Pull Downwards
                if (Keyboard.isKeyDown(Keyboard.KEY_NUMPAD2) && (particle[i].yg>-1.5f)) {
                    particle[i].yg -= 0.01f;
                }

                // If Number Pad 6 And X Gravity Is Less Than 1.5 Increase Pull Right
                if (Keyboard.isKeyDown(Keyboard.KEY_NUMPAD6) && (particle[i].xg<1.5f)) {
                    particle[i].xg += 0.01f;
                }

                // If Number Pad 4 And X Gravity Is Greater Than -1.5 Increase Pull Left
                if (Keyboard.isKeyDown(Keyboard.KEY_NUMPAD4) && (particle[i].xg>-1.5f)) {
                    particle[i].xg -= 0.01f;
                }

                if (Keyboard.isKeyDown(Keyboard.KEY_TAB)) {                                       // Tab Key Causes A Burst
                    particle[i].x = 0.0f;                              // Center On X Axis
                    particle[i].y = 0.0f;                              // Center On Y Axis
                    particle[i].z = 0.0f;                              // Center On Z Axis
                    particle[i].xi = ((float)(Math.random() * 50.0) - 26.0f) * 10.0f;   // Random Speed On X Axis
                    particle[i].yi = ((float)(Math.random() * 50.0) - 25.0f) * 10.0f;   // Random Speed On Y Axis
                    particle[i].zi = ((float)(Math.random() * 50.0) - 25.0f) * 10.0f;   // Random Speed On Z Axis
                }
            }
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

class Particle {                         // Particles Structure
    public boolean active;               // Active (Yes/No)
    public float life;                   // Particle Life
    public float fade;                   // Fade Speed
    public float r;                      // Red Value
    public float g;                      // Green Value
    public float b;                      // Blue Value
    public float x;                      // X Position
    public float y;                      // Y Position
    public float z;                      // Z Position
    public float xi;                     // X Direction
    public float yi;                     // Y Direction
    public float zi;                     // Z Direction
    public float xg;                     // X Gravity
    public float yg;                     // Y Gravity
    public float zg;                     // Z Gravity
}

