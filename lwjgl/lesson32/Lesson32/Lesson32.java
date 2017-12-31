/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.io.FileWriter;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.IntBuffer;

import java.util.*;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.Sys;
import org.lwjgl.openal.AL;
import org.lwjgl.openal.AL10;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.test.openal.WaveData;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;
import org.lwjgl.input.Mouse;

/**
 * @author Mark Bernard
 * date:    07-Sept-2004
 *
 * Port of NeHe's Lesson 32 to LWJGL
 * Title: Picking, Alpha Blending, Alpha Testing, Sorting
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 * 2004-12-19: Updated to version 0.94alpha of LWJGL and to use
 *             DevIL for image loading.
 */
public class Lesson32 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 32 for LWJGL (Picking, Alpha Blending, Alpha Testing, Sorting)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    private static final long timerResolution = Sys.getTimerResolution();

    //  User Defined Variables
    int base;                                               // Font Display List
    float roll;                                               // Rolling Clouds
    int level = 1;                                            // Current Level
    int miss;                                               // Missed Targets
    int kills;                                              // Level Kill Counter
    int score;                                              // Current Score
    boolean game;                                               // Game Over?
    int mouse_x;
    int mouse_y;
    long lastTime;
    long currentTime;
    int width = 640;
    int height = 480;

    IntBuffer shotBuffer = createIntBuffer(1);
    IntBuffer shotSource = createIntBuffer(1);

    int textures[];                                      // Storage For 10 Textures
    Timer timer;

    Objects object[];                                             // Storage For 30 Objects

//     Size Of Each Object: Blueface,     Bucket,      Target,       Coke,         Vase
    Dimensions size[];

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Objects.startLog();
        Lesson32 l32 = new Lesson32();
        l32.run(fullscreen);
        Objects.endLog();
    }
    public void run(boolean fullscreen) {
        this.fullscreen = fullscreen;
        try {
            init();

            while (!done) {
                render();
                currentTime = Sys.getTime();
//                mainloop((currentTime - lastTime) / timerResolution);
                mainloop(7);
                lastTime = currentTime;
                Display.update();
            }
            cleanup();
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(0);
        }
    }
    private void mainloop(long milliseconds) {
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

        if (Keyboard.isKeyDown(Keyboard.KEY_SPACE) && game) {   // Space Bar Being Pressed After Game Has Ended?
            initObjects();

            game = false;                                             // Set game (Game Over) To False
            score = 0;                                                // Set score To 0
            level = 1;                                                // Set level Back To 1
            kills = 0;                                                // Zero Player Kills
            miss = 0;                                                 // Set miss (Missed Shots) To 0
        }

        if(Mouse.isButtonDown(0)) {
            selection();
        }
        mouse_x = Mouse.getX();
        mouse_y = height - Mouse.getY();
        roll -= milliseconds * 0.00005f;                                // Roll The Clouds
        for (int i=0; i<level; i++) {                       // Loop Through The Objects
            if (object[i].rot == 1) {                               // If Rotation Is Clockwise
                object[i].spin -= 0.2f * ((float)(i + milliseconds)); // Spin Clockwise
            }
            if (object[i].rot == 2) {                               // If Rotation Is Counter Clockwise
                object[i].spin+=0.2f*((float)(i + milliseconds)); // Spin Counter Clockwise
            }
            if (object[i].dir == 1) {                               // If Direction Is Right
                object[i].x += 0.012f * ((float)milliseconds);         // Move Right
            }
            if (object[i].dir == 0) {                               // If Direction Is Left
                object[i].x -= 0.012f * ((float)milliseconds);         // Move Left
            }
            if (object[i].dir == 2) {                               // If Direction Is Up
                object[i].y += 0.012f * ((float)milliseconds);         // Move Up
            }
            if (object[i].dir == 3) {                               // If Direction Is Down
                object[i].y -= 0.0025f * ((float)milliseconds);        // Move Down
            }
            // If We Are To Far Left, Direction Is Left And The Object Was Not Hit
            if ((object[i].x < (object[i].distance - 15.0f) / 2.0f) && (object[i].dir == 0) && !object[i].hit) {
                miss += 1;                                            // Increase miss (Missed Object)
                object[i].hit = true;                              // Set hit To True To Manually Blow Up The Object
            }

            // If We Are To Far Right, Direction Is Left And The Object Was Not Hit
            if ((object[i].x > -(object[i].distance - 15.0f) / 2.0f) && (object[i].dir == 1) && !object[i].hit) {
                miss += 1;                                            // Increase miss (Missed Object)
                object[i].hit = true;                              // Set hit To True To Manually Blow Up The Object
            }

            // If We Are To Far Down, Direction Is Down And The Object Was Not Hit
            if ((object[i].y < -2.0f) && (object[i].dir == 3) && !object[i].hit) {
                miss += 1;                                            // Increase miss (Missed Object)
                object[i].hit = true;                              // Set hit To True To Manually Blow Up The Object
            }

            if ((object[i].y > 4.5f) && (object[i].dir == 2)) {    // If We Are To Far Up And The Direction Is Up
                object[i].dir = 3;                                 // Change The Direction To Down
            }
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
        game = false;
        textures = new int[10];                                      // Storage For 10 Textures

        object = new Objects[30];                                             // Storage For 30 Objects
        for(int i=0;i<30;i++) {
            object[i] = new Objects();
        }

        size = new Dimensions[5];
        size[0] = new Dimensions(1.0f, 1.0f);
        size[1] = new Dimensions(1.0f, 1.0f);
        size[2] = new Dimensions(1.0f, 1.0f);
        size[3] = new Dimensions(0.5f, 1.0f);
        size[4] = new Dimensions(0.75f, 1.5f);

        createWindow();
        IL.create();
        int width = displayMode.getWidth();
        int height = displayMode.getHeight();

        loadSounds();
        loadTextures();
        buildFont();

        initGL();
        lastTime = Sys.getTime();
    }

    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int screenWidth = 640;
        int screenHeight = 480;
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);                       // Black Background
        GL11.glClearDepth(1.0f);                                         // Depth Buffer Setup
        GL11.glDepthFunc(GL11.GL_LEQUAL);                                     // Type Of Depth Testing
        GL11.glEnable(GL11.GL_DEPTH_TEST);                                    // Enable Depth Testing
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);          // Enable Alpha Blending (disable alpha testing)
        GL11.glEnable(GL11.GL_BLEND);                                         // Enable Blending       (disable alpha testing)
//      GL11.glAlphaFunc(GL11.GL_GREATER,0.1f);                               // Set Alpha Testing     (disable blending)
//      GL11.glEnable(GL11.GL_ALPHA_TEST);                                    // Enable Alpha Testing  (disable blending)
        GL11.glEnable(GL11.GL_TEXTURE_2D);                                    // Enable Texture Mapping
        GL11.glEnable(GL11.GL_CULL_FACE);                                     // Remove Back Face

        initObjects();

        GL11.glViewport(0,0,width,height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,(float)screenWidth/(float)screenHeight,0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix
    }

    private void buildFont() {                                  // Build Our Font Display List
        float   cx;                                             // Holds Our X Character Coord
        float   cy;                                             // Holds Our Y Character Coord

        base = GL11.glGenLists(128);                            // Creating 256 Display Lists
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, textures[9]);     // Select Our Font Texture
        for (int i=0;i<127;i++) {                               // Loop Through All 256 Lists
            cx = ((float)(i % 16)) / 16.0f;                     // X Position Of Current Character
            cy = ((float)(i / 16)) / 8.0f;                     // Y Position Of Current Character

//            System.out.println("cx = " + cx + " cy = " + cy);
            GL11.glNewList(base + i, GL11.GL_COMPILE);          // Start Building A List
            GL11.glBegin(GL11.GL_QUADS);                        // Use A Quad For Each Character
            GL11.glTexCoord2f(cx, 1 - cy - 0.125f);            // Texture Coord (Bottom Left)
            GL11.glVertex2i(0, 0);                              // Vertex Coord (Bottom Left)
            GL11.glTexCoord2f(cx + 0.0625f, 1 - cy - 0.125f);  // Texture Coord (Bottom Right)
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

    private void initObjects() {
        for (int i=0; i<30; i++) {                           // Loop Through 30 Objects
            object[i].init(level);
        }
        Arrays.sort(object);

    }
    private void glPrint(int x, int y, String msg) {   // Where The Printing Happens
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, textures[9]);           // Select Our Font Texture
        GL11.glDisable(GL11.GL_DEPTH_TEST);                           // Disables Depth Testing
        GL11.glMatrixMode(GL11.GL_PROJECTION);                        // Select The Projection Matrix
        GL11.glPushMatrix();                                     // Store The Projection Matrix
        GL11.glLoadIdentity();                                   // Reset The Projection Matrix
        GL11.glOrtho(0, 640, 0, 480, -1, 1);                          // Set Up An Ortho Screen
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                         // Select The Modelview Matrix
        GL11.glPushMatrix();                                     // Store The Modelview Matrix
        GL11.glLoadIdentity();                                   // Reset The Modelview Matrix
        GL11.glTranslatef(x, y, 0);                                // Position The Text (0,0 - Bottom Left)
        int baseOffset = base - 32;                             // Choose The Font Set (0 or 1)
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

    private void selection() {                                            // This Is Where Selection Is Done
        int buffer[] = new int[512];                                        // Set Up A Selection Buffer
        int hits;                                               // The Number Of Objects That We Selected

        if (!game) {                                                   // Is Game Over?
//            playSound("data/shot.wav",NULL,SND_ASYNC);                  // Play Gun Shot Sound
            AL10.alSourcePlay(shotSource.get(0));

            // The Size Of The Viewport. [0] Is <x>, [1] Is <y>, [2] Is <length>, [3] Is <width>

            int viewport[] = new int[4];

            // This Sets The Array <viewport> To The Size And Location Of The Screen Relative To The Window
            IntBuffer temp = ByteBuffer.allocateDirect(64).order(ByteOrder.nativeOrder()).asIntBuffer();
            temp.order();
            GL11.glGetInteger(GL11.GL_VIEWPORT, temp);
            temp.get(viewport);
            temp = ByteBuffer.allocateDirect(2048).asIntBuffer();
            GL11.glSelectBuffer(temp);                                // Tell OpenGL To Use Our Array For Selection
            temp.get(buffer);

            // Puts OpenGL In Selection Mode. Nothing Will Be Drawn.  Object ID's and Extents Are Stored In The Buffer.
            GL11.glRenderMode(GL11.GL_SELECT);

            GL11.glInitNames();                                              // Initializes The Name Stack
            GL11.glPushName(0);                                              // Push 0 (At Least One Entry) Onto The Stack

            GL11.glMatrixMode(GL11.GL_PROJECTION);                                // Selects The Projection Matrix
            GL11.glPushMatrix();                                             // Push The Projection Matrix
            GL11.glLoadIdentity();                                           // Resets The Matrix

            // This Creates A Matrix That Will Zoom Up To A Small Portion Of The Screen, Where The Mouse Is.
            GLU.gluPickMatrix((float) mouse_x, (float) (viewport[3] - mouse_y), 1.0f, 1.0f, viewport);

            // Apply The Perspective Matrix
            GLU.gluPerspective(45.0f, (float) (viewport[2] - viewport[0]) / (float) (viewport[3] - viewport[1]), 0.1f, 100.0f);
            GL11.glMatrixMode(GL11.GL_MODELVIEW);                                 // Select The Modelview Matrix
            drawTargets();                                              // Render The Targets To The Selection Buffer
            GL11.glMatrixMode(GL11.GL_PROJECTION);                                // Select The Projection Matrix
            GL11.glPopMatrix();                                              // Pop The Projection Matrix
            GL11.glMatrixMode(GL11.GL_MODELVIEW);                                 // Select The Modelview Matrix
            hits = GL11.glRenderMode(GL11.GL_RENDER);                               // Switch To Render Mode, Find Out How Many
                                                                        // Objects Were Drawn Where The Mouse Was
            if(hits > 0) {                                               // If There Were More Than 0 Hits
                int choose = buffer[3];                                 // Make Our Selection The First Object
                int depth = buffer[1];                                  // Store How Far Away It Is

                for (int i = 1; i < hits; i++) {                // Loop Through All The Detected Hits
                    // If This Object Is Closer To Us Than The One We Have Selected
                    if (buffer[i * 4 + 1] < (int)depth) {
                        choose = buffer[i * 4 + 3];                      // Select The Closer Object
                        depth = buffer[i * 4 + 1];                       // Store How Far Away It Is
                    }
                }

                if (!object[choose].hit) {                               // If The Object Hasn't Already Been Hit
                    object[choose].hit = true;                            // Mark The Object As Being Hit
                    score += 1;                                           // Increase Score
                    kills += 1;                                           // Increase Level Kills
                    if (kills > level * 5) {                                 // New Level Yet?
                        miss = 0;                                         // Misses Reset Back To Zero
                        kills = 0;                                        // Reset Level Kills
                        level += 1;                                       // Increase Level
                        if (level > 30) {                                   // Higher Than 30?
                            level = 30;                                   // Set Level To 30 (Are You A God?)
                        }
                    }
                }
            }
        }
    }
    void drawObject(float width, float height, int texid) {             // Draw Object Using Requested Width, Height And Texture
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, textures[texid]);        // Select The Correct Texture
        GL11.glBegin(GL11.GL_QUADS);                                          // Start Drawing A Quad
            GL11.glTexCoord2f(0.0f,0.0f); GL11.glVertex3f(-width,-height,0.0f);   // Bottom Left
            GL11.glTexCoord2f(1.0f,0.0f); GL11.glVertex3f( width,-height,0.0f);   // Bottom Right
            GL11.glTexCoord2f(1.0f,1.0f); GL11.glVertex3f( width, height,0.0f);   // Top Right
            GL11.glTexCoord2f(0.0f,1.0f); GL11.glVertex3f(-width, height,0.0f);   // Top Left
        GL11.glEnd();                                                    // Done Drawing Quad
    }
    void explosion(int num) {                                        // Draws An Animated Explosion For Object "num"
        float ex = (float)((object[num].frame/4)%4)/4.0f;           // Calculate Explosion X Frame (0.0f - 0.75f)
        float ey = (float)((object[num].frame/4)/4)/4.0f;           // Calculate Explosion Y Frame (0.0f - 0.75f)

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, textures[5]);            // Select The Explosion Texture
        GL11.glBegin(GL11.GL_QUADS);                                          // Begin Drawing A Quad
        GL11.glTexCoord2f(ex      ,1.0f-(ey      )); GL11.glVertex3f(-1.0f,-1.0f,0.0f);   // Bottom Left
        GL11.glTexCoord2f(ex+0.25f,1.0f-(ey      )); GL11.glVertex3f( 1.0f,-1.0f,0.0f);   // Bottom Right
        GL11.glTexCoord2f(ex+0.25f,1.0f-(ey+0.25f)); GL11.glVertex3f( 1.0f, 1.0f,0.0f);   // Top Right
        GL11.glTexCoord2f(ex      ,1.0f-(ey+0.25f)); GL11.glVertex3f(-1.0f, 1.0f,0.0f);   // Top Left
        GL11.glEnd();                                                    // Done Drawing Quad

        object[num].frame += 1;                                       // Increase Current Explosion Frame
        if (object[num].frame > 63) {                                  // Have We Gone Through All 16 Frames?
            object[num].init(level);                                        // Init The Object (Assign New Values)
        }
    }

    void drawTargets() {                                         // Draws The Targets (Needs To Be Seperate)
        GL11.glLoadIdentity();                                           // Reset The Modelview Matrix
        GL11.glTranslatef(0.0f, 0.0f, -10.0f);                             // Move Into The Screen 20 Units
        for (int i=0; i<level; i++) {                       // Loop Through 9 Objects
            GL11.glLoadName(i);                                       // Assign Object A Name (ID)
            GL11.glPushMatrix();                                         // Push The Modelview Matrix
            GL11.glTranslatef(object[i].x, object[i].y, object[i].distance);      // Position The Object (x,y)
            if (object[i].hit) {                                  // If Object Has Been Hit
                explosion(i);                                    // Draw An Explosion
            }
            else {                                                  // Otherwise
                GL11.glRotatef(object[i].spin,0.0f,0.0f,1.0f);        // Rotate The Object
                drawObject(size[object[i].texid].w, size[object[i].texid].h, object[i].texid);   // Draw The Object
            }
            GL11.glPopMatrix();                                          // Pop The Modelview Matrix
        }
    }

    private void render() {
        GL11.glClear (GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);        // Clear Screen And Depth Buffer
        GL11.glLoadIdentity();                                           // Reset The Modelview Matrix

        GL11.glPushMatrix();                                             // Push The Modelview Matrix
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, textures[7]);            // Select The Sky Texture
        GL11.glBegin(GL11.GL_QUADS);                                          // Begin Drawing Quads
            GL11.glTexCoord2f(1.0f,roll/1.5f+1.0f); GL11.glVertex3f( 28.0f,+7.0f,-50.0f); // Top Right
            GL11.glTexCoord2f(0.0f,roll/1.5f+1.0f); GL11.glVertex3f(-28.0f,+7.0f,-50.0f); // Top Left
            GL11.glTexCoord2f(0.0f,roll/1.5f+0.0f); GL11.glVertex3f(-28.0f,-3.0f,-50.0f); // Bottom Left
            GL11.glTexCoord2f(1.0f,roll/1.5f+0.0f); GL11.glVertex3f( 28.0f,-3.0f,-50.0f); // Bottom Right

            GL11.glTexCoord2f(1.5f,roll+1.0f); GL11.glVertex3f( 28.0f,+7.0f,-50.0f);      // Top Right
            GL11.glTexCoord2f(0.5f,roll+1.0f); GL11.glVertex3f(-28.0f,+7.0f,-50.0f);      // Top Left
            GL11.glTexCoord2f(0.5f,roll+0.0f); GL11.glVertex3f(-28.0f,-3.0f,-50.0f);      // Bottom Left
            GL11.glTexCoord2f(1.5f,roll+0.0f); GL11.glVertex3f( 28.0f,-3.0f,-50.0f);      // Bottom Right

            GL11.glTexCoord2f(1.0f,roll/1.5f+1.0f); GL11.glVertex3f( 28.0f,+7.0f,0.0f);   // Top Right
            GL11.glTexCoord2f(0.0f,roll/1.5f+1.0f); GL11.glVertex3f(-28.0f,+7.0f,0.0f);   // Top Left
            GL11.glTexCoord2f(0.0f,roll/1.5f+0.0f); GL11.glVertex3f(-28.0f,+7.0f,-50.0f); // Bottom Left
            GL11.glTexCoord2f(1.0f,roll/1.5f+0.0f); GL11.glVertex3f( 28.0f,+7.0f,-50.0f); // Bottom Right

            GL11.glTexCoord2f(1.5f,roll+1.0f); GL11.glVertex3f( 28.0f,+7.0f,0.0f);        // Top Right
            GL11.glTexCoord2f(0.5f,roll+1.0f); GL11.glVertex3f(-28.0f,+7.0f,0.0f);        // Top Left
            GL11.glTexCoord2f(0.5f,roll+0.0f); GL11.glVertex3f(-28.0f,+7.0f,-50.0f);      // Bottom Left
            GL11.glTexCoord2f(1.5f,roll+0.0f); GL11.glVertex3f( 28.0f,+7.0f,-50.0f);      // Bottom Right
        GL11.glEnd();                                                    // Done Drawing Quads

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, textures[6]);            // Select The Ground Texture
        GL11.glBegin(GL11.GL_QUADS);                                          // Draw A Quad
            GL11.glTexCoord2f(7.0f,4.0f-roll); GL11.glVertex3f( 27.0f,-3.0f,-50.0f);  // Top Right
            GL11.glTexCoord2f(0.0f,4.0f-roll); GL11.glVertex3f(-27.0f,-3.0f,-50.0f);  // Top Left
            GL11.glTexCoord2f(0.0f,0.0f-roll); GL11.glVertex3f(-27.0f,-3.0f,0.0f);    // Bottom Left
            GL11.glTexCoord2f(7.0f,0.0f-roll); GL11.glVertex3f( 27.0f,-3.0f,0.0f);    // Bottom Right
            GL11.glEnd();                                                    // Done Drawing Quad

        drawTargets();                                              // Draw Our Targets
        GL11.glPopMatrix();                                              // Pop The Modelview Matrix

        // Crosshair (In Ortho View)
//        RECT window;                                                // Storage For Window Dimensions
//        GetClientRect (g_window->hWnd,&window);                     // Get Window Dimensions
        GL11.glMatrixMode(GL11.GL_PROJECTION);                                // Select The Projection Matrix
        GL11.glPushMatrix();                                             // Store The Projection Matrix
        GL11.glLoadIdentity();                                           // Reset The Projection Matrix
        GL11.glOrtho(0, width, 0, height, -1, 1);               // Set Up An Ortho Screen
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                                 // Select The Modelview Matrix
        GL11.glTranslatef((float)Mouse.getX(), (float)Mouse.getY(), 0.0f);           // Move To The Current Mouse Position
        drawObject(16, 16, 8);                                            // Draw The Crosshair

        // Game Stats / Title
        glPrint(240, 450, "NeHe Productions");                        // Print Title
        glPrint(10, 10, "Level: " + level);                           // Print Level
        glPrint(250, 10, "Score: " + score);                          // Print Score

        if (miss > 9) {                                                // Have We Missed 10 Objects?
            miss = 9;                                                 // Limit Misses To 10
            game = true;                                              // Game Over TRUE
        }

        if (game) {                                                  // Is Game Over?
            glPrint(490,10,"GAME OVER");                            // Game Over Message
        }
        else {
            glPrint(490,10,"Morale: " + (10 - miss) + "/10");                // Print Morale #/10
        }

        GL11.glMatrixMode(GL11.GL_PROJECTION);                                // Select The Projection Matrix
        GL11.glPopMatrix();                                              // Restore The Old Projection Matrix
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                                 // Select The Modelview Matrix

        GL11.glFlush();                                                  // Flush The GL Rendering Pipeline
    }

    private void cleanup() {
        Display.destroy();
    }

    private void loadSounds() throws Exception {
        // you must create OpenAl before you can do anything with it.
        AL.create();
        loadSound(shotBuffer, shotSource, "Data/Shot.wav");
    }
    // The code in loadSound is pretty much a copy of the code
    // from the test class org.lwjgl.test.openal.PlayTest.
    // WaveData can also be found in the test files as well.  It
    // is important to link in "lwjgl_test.jar" or the code will not compile.
    private void loadSound(IntBuffer buffer, IntBuffer source, String file) {
        WaveData temp;

        temp = WaveData.create(file);
        buffer.position(0).limit(1);
        AL10.alGenBuffers(buffer);
        source.position(0).limit(1);
        AL10.alGenSources(source);
        AL10.alBufferData(buffer.get(0), temp.format, temp.data, temp.samplerate);
        temp.dispose();
        AL10.alSourcei(source.get(0), AL10.AL_BUFFER, buffer.get(0));
    }
    private void loadTextures() {                                   // Load Bitmaps And Convert To Textures
        textures[0] = loadTexture("Data/BlueFace.tga");         // Load The BlueFace Texture
        textures[1] = loadTexture("Data/Bucket.tga");           // Load The Bucket Texture
        textures[2] = loadTexture("Data/Target.tga");           // Load The Target Texture
        textures[3] = loadTexture("Data/Coke.tga");             // Load The Coke Texture
        textures[4] = loadTexture("Data/Vase.tga");             // Load The Vase Texture
        textures[5] = loadTexture("Data/Explode.tga");          // Load The Explosion Texture
        textures[6] = loadTexture("Data/Ground.tga");           // Load The Ground Texture
        textures[7] = loadTexture("Data/Sky.tga");              // Load The Sky Texture
        textures[8] = loadTexture("Data/Crosshair.tga");        // Load The Crosshair Texture
        textures[9] = loadTexture("Data/Font.tga");               // Load The Crosshair Texture
    }

    private final int loadTexture(String path) {
        int ilType = 0;
        int glType = 0;

        IntBuffer image = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        IL.ilGenImages(1, image);
        IL.ilBindImage(image.get(0));
        IL.ilLoadImage(path);
        int bytesPerPixel = IL.ilGetInteger(IL.IL_IMAGE_BYTES_PER_PIXEL);
        ByteBuffer scratch = ByteBuffer.allocateDirect(IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * bytesPerPixel);
        if(bytesPerPixel == 3) {
            ilType = IL.IL_RGB;
            glType = GL11.GL_RGB;
        }
        else if(bytesPerPixel == 4) {
            ilType = IL.IL_RGBA;
            glType = GL11.GL_RGBA;
        }
        IL.ilCopyPixels(0, 0, 0, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 1, ilType, IL.IL_BYTE, scratch);
        
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
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, glType, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 0, glType, GL11.GL_UNSIGNED_BYTE, scratch);

        return buf.get(0); // Return Image Address In Memory
    }
    private IntBuffer createIntBuffer(int size) {
        ByteBuffer temp = ByteBuffer.allocateDirect(4 * size);
        temp.order(ByteOrder.nativeOrder());

        return temp.asIntBuffer();
    }
}
class Objects implements Comparable {
    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    static int idcount = 0;
    static FileWriter out = null;
    int id;
    int  rot;                                               // Rotation (0-None, 1-Clockwise, 2-Counter Clockwise)
    boolean hit;                                            // Object Hit?
    int  frame;                                             // Current Explosion Frame
    int  dir;                                               // Object Direction (0-Left, 1-Right, 2-Up, 3-Down)
    int  texid;                                             // Object Texture ID
    float x;                                                // Object X Position
    float y;                                                // Object Y Position
    float spin;                                             // Object Spin
    float distance;                                         // Object Distance

    public static void startLog() {
        try {
            out = new FileWriter("pick.log");
        }
        catch(Exception e) {
            e.printStackTrace();
        }
    }
    public static void endLog() {
        try {
            out.flush();
            out.close();
        }
        catch(Exception e) {
            e.printStackTrace();
        }
        out = null;
    }
    public Objects() {
        idcount++;
        id = idcount;
    }
    public void init(int level) {
        rot = 1;                                          // Clockwise Rotation
        frame = 0;                                        // Reset The Explosion Frame To Zero
        hit = false;                                      // Reset Object Has Been Hit Status To False
        texid = (int)(Math.random() * 5);                                 // Assign A New Texture
        distance = -(float)((Math.random() * 4001) / 100.0f);          // Random Distance
        y = -1.5f + (float)((Math.random() * 451) / 100.0f);             // Random Y Position
        // Random Starting X Position Based On Distance Of Object And Random Amount For A Delay (Positive Value)
        x = ((distance - 15.0f) / 2.0f) - (5 * level) - (float)(Math.random() * (5 * level));
        dir = (int)(Math.random() * 2);                                 // Pick A Random Direction

        if (dir == 0) {                                     // Is Random Direction Right
            rot = 2;                                      // Counter Clockwise Rotation
            x = -x;                           // Start On The Left Side (Negative Value)
        }

        if (texid == 0) {                                   // Blue Face
            y = -2.0f;                                    // Always Rolling On The Ground
        }

        if (texid == 1) {                                  // Bucket
            dir = 3;                                      // Falling Down
            x = (float)((Math.random() * (int)(distance - 10.0f)) + ((distance - 10.0f) / 2.0f));
            y = 4.5f;                                     // Random X, Start At Top Of The Screen
        }

        if (texid == 2) {                                  // Target
            dir = 2;                                      // Start Off Flying Up
            x = (float)((Math.random() * (int)(distance - 10.0f)) + ((distance - 10.0f) / 2.0f));
            y = -3.0f - (float)((Math.random() * ( 5 * level)));            // Random X, Start Under Ground + Random Value
        }
        if(out != null) {
            try {
                out.write("id=" + id + " x=" + x + " y=" + y + " spin=" + spin + " dis=" + distance + "\r\n");
            }
            catch(Exception e) {
                e.printStackTrace();
            }
        }
    }

    public int compareTo(Object obj) {       // Compare Function *** MSDN CODE MODIFIED FOR THIS TUT ***
        int result = 0;

        if(obj != null && obj instanceof Objects) {
            Objects that = (Objects)obj;
            if ( this.distance < that.distance) {                      // If First Structure distance Is Less Than The Second
                result = -1;                                                // Return -1
            }
            else if (this.distance > that.distance) {                 // If First Structure distance Is Greater Than The Second
                result = 1;                                                 // Return 1
            }
            else {                                                         // Otherwise (If The distance Is Equal)
                result = 0;                                                 // Return 0
            }
        }

        return result;
    }
}

class Dimensions {                                             // Object Dimensions
    float w;                                                  // Object Width
    float h;                                                  // Object Height

    public Dimensions(float w, float h) {
        this.w = w;
        this.h = h;
    }
}