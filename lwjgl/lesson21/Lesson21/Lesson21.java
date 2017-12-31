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
import java.text.NumberFormat;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.Sys;
import org.lwjgl.openal.AL;
import org.lwjgl.openal.AL10;
import org.lwjgl.opengl.GL11;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;
import org.lwjgl.test.openal.WaveData;

/**
 * @author Mark Bernard
 * date:    26-Jun-2004
 *
 * Port of NeHe's Lesson 21 to LWJGL
 * Title: Lines, Antialiasing, Timing, Ortho View And Simple Sounds
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * Sound here is done with OpenAL.  I have left he original PlaySound calls to provide a comparison.
 * I have also use utility files from the LWJGL test code.  You need to link in lwjgl_test.jar along with
 * lwjgl.jar for the sounds to work.
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL and to use
 *             DevIL for image loading.
 */
public class Lesson21 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 21 for LWJGL (Lines, Antialiasing, Timing, Ortho View And Simple Sounds)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    private boolean vline[][];                                      // Keeps Track Of Verticle Lines
    private boolean hline[][];                                      // Keeps Track Of Horizontal Lines
    private boolean ap;                                             // 'A' Key Pressed?
    private boolean filled;                                         // Done Filling In The Grid?
    private boolean gameover;                                       // Is The Game Over?
    private boolean anti = true;                                    // Antialiasing?

    private int loop1;                                              // Generic Loop1
    private int j;                                                  // Generic Loop2
    private int delay;                                              // Enemy Delay
    private int adjust = 0;                                         // Speed Adjustment For Really Slow Video Cards
    private int lives = 5;                                          // Player Lives
    private int level = 1;                                          // Internal Game Level
    private int level2 = level;                                     // Displayed Game Level
    private int stage = 1;                                          // Game Stage
    private NumberFormat numberFormat = NumberFormat.getInstance();

    private GameObject player;                                      // Player Information
    private GameObject enemy[];                                     // Enemy Information
    private GameObject hourglass;                                   // Hourglass Information

    private Timer timer;
    private float start;

    int steps[]={ 1, 2, 4, 5, 10, 20 };                             // Stepping Values For Slow Video Adjustment

    int texture[];                                                  // Font Texture Storage Space
    int base;                                                       // Base Display List For The Font
    IntBuffer completeBuffer = createIntBuffer(1);
    IntBuffer completeSource = createIntBuffer(1);
    IntBuffer dieBuffer = createIntBuffer(1);
    IntBuffer dieSource = createIntBuffer(1);
    IntBuffer freezeBuffer = createIntBuffer(1);
    IntBuffer freezeSource = createIntBuffer(1);
    IntBuffer hourglassWavBuffer = createIntBuffer(1);
    IntBuffer hourglassWavSource = createIntBuffer(1);

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson21 l21 = new Lesson21();
        l21.run(fullscreen);
    }
    public void run(boolean fullscreen) {
        this.fullscreen = fullscreen;
        try {
            init();
            while (!done) {
                start = timerGetTime();
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

        while(timerGetTime() < start + ((float)steps[adjust]) * 2.0f);

        if (Keyboard.isKeyDown(Keyboard.KEY_A) && !ap) {    // If 'A' Key Is Pressed And Not Held
            ap = true;                                      // ap Becomes true
            anti = !anti;                                   // Toggle Antialiasing
        }
        if (!Keyboard.isKeyDown(Keyboard.KEY_A)) {          // If 'A' Key Has Been Released
            ap = false;                                     // ap Becomes false
        }

        if (!gameover) {                                    // If Game Isn't Over And Programs Active Move Objects
            for (int i=0; i<(stage*level); i++) {           // Loop Through The Different Stages
                if ((enemy[i].x < player.x) && (enemy[i].fy == enemy[i].y * 40)) {
                    enemy[i].x++;                           // Move The Enemy Right
                }

                if ((enemy[i].x > player.x) && (enemy[i].fy == enemy[i].y * 40)) {
                    enemy[i].x--;                           // Move The Enemy Left
                }

                if ((enemy[i].y < player.y) && (enemy[i].fx == enemy[i].x * 60)) {
                    enemy[i].y++;                           // Move The Enemy Down
                }

                if ((enemy[i].y > player.y) && (enemy[i].fx == enemy[i].x * 60)) {
                    enemy[i].y--;                           // Move The Enemy Up
                }

                if (delay > (3 - level) && (hourglass.fx != 2)) {   // If Our Delay Is Done And Player Doesn't Have Hourglass
                    delay = 0;                                      // Reset The Delay Counter Back To Zero
                    for (int j=0; j<(stage*level); j++) {           // Loop Through All The Enemies
                        if (enemy[j].fx < enemy[j].x * 60) {        // Is Fine Position On X Axis Lower Than Intended Position?
                            enemy[j].fx += steps[adjust];           // If So, Increase Fine Position On X Axis
                            enemy[j].spin += steps[adjust];         // Spin Enemy Clockwise
                        }
                        if (enemy[j].fx > enemy[j].x * 60) {        // Is Fine Position On X Axis Higher Than Intended Position?
                            enemy[j].fx -= steps[adjust];           // If So, Decrease Fine Position On X Axis
                            enemy[j].spin-=steps[adjust];           // Spin Enemy Counter Clockwise
                        }
                        if (enemy[j].fy < enemy[j].y * 40) {        // Is Fine Position On Y Axis Lower Than Intended Position?
                            enemy[j].fy+=steps[adjust];             // If So, Increase Fine Position On Y Axis
                            enemy[j].spin+=steps[adjust];           // Spin Enemy Clockwise
                        }
                        if (enemy[j].fy > enemy[j].y * 40) {        // Is Fine Position On Y Axis Higher Than Intended Position?
                            enemy[j].fy -= steps[adjust];           // If So, Decrease Fine Position On Y Axis
                            enemy[j].spin -= steps[adjust];         // Spin Enemy Counter Clockwise
                        }
                    }
                }

                // Are Any Of The Enemies On Top Of The Player?
                if ((enemy[i].fx == player.fx) && (enemy[i].fy == player.fy)) {
                    lives--;                                        // If So, Player Loses A Life

                    if (lives == 0) {                               // Are We Out Of Lives?
                        gameover = true;                            // If So, gameover Becomes true
                    }

                    resetObjects();                                 // Reset Player / Enemy Positions
//                    PlaySound("Data/Die.wav", null, SND_SYNC);      // Play The Death Sound
                    AL10.alSourcePlay(dieSource.get(0));
                }
            }

            if(Keyboard.isKeyDown(Keyboard.KEY_RIGHT) && (player.x < 10) && (player.fx == player.x * 60) && (player.fy == player.y * 40)) {
                hline[player.x][player.y] = true;                   // Mark The Current Horizontal Border As Filled
                player.x++;                                         // Move The Player Right
            }
            if(Keyboard.isKeyDown(Keyboard.KEY_LEFT) && (player.x > 0) && (player.fx == player.x * 60) && (player.fy == player.y * 40)) {
                player.x--;                                         // Move The Player Left
                hline[player.x][player.y] = true;                   // Mark The Current Horizontal Border As Filled
            }
            if(Keyboard.isKeyDown(Keyboard.KEY_DOWN) && (player.y < 10) && (player.fx == player.x * 60) && (player.fy == player.y * 40)) {
                vline[player.x][player.y] = true;                   // Mark The Current Verticle Border As Filled
                player.y++;                                         // Move The Player Down
            }
            if (Keyboard.isKeyDown(Keyboard.KEY_UP) && (player.y > 0) && (player.fx == player.x * 60) && (player.fy == player.y * 40)) {
                player.y--;                                         // Move The Player Up
                vline[player.x][player.y] = true;                   // Mark The Current Verticle Border As Filled
            }

            if (player.fx < player.x * 60) {                // Is Fine Position On X Axis Lower Than Intended Position?
                player.fx += steps[adjust];                 // If So, Increase The Fine X Position
            }
            if (player.fx > player.x * 60) {                // Is Fine Position On X Axis Greater Than Intended Position?
                player.fx -= steps[adjust];                 // If So, Decrease The Fine X Position
            }
            if (player.fy < player.y * 40) {                // Is Fine Position On Y Axis Lower Than Intended Position?
                player.fy += steps[adjust];                 // If So, Increase The Fine Y Position
            }
            if (player.fy > player.y * 40) {                // Is Fine Position On Y Axis Lower Than Intended Position?
                player.fy -= steps[adjust];                 // If So, Decrease The Fine Y Position
            }
        }
        else {                                              // Otherwise
            if (Keyboard.isKeyDown(Keyboard.KEY_SPACE)) {   // If Spacebar Is Being Pressed
                gameover = false;                           // gameover Becomes false
                filled = true;                              // filled Becomes true
                level = 1;                                  // Starting Level Is Set Back To One
                level2 = 1;                                 // Displayed Level Is Also Set To One
                stage = 0;                                  // Game Stage Is Set To Zero
                lives = 5;                                  // Lives Is Set To Five
            }
        }

        if (filled) {                                       // Is The Grid Filled In?
//            PlaySound("Data/Complete.wav", NULL, SND_SYNC); // If So, Play The Level Complete Sound
            AL10.alSourcePlay(completeSource.get(0));
            stage++;                                        // Increase The Stage
            if (stage > 3) {                                // Is The Stage Higher Than 3?
                stage = 1;                                  // If So, Set The Stage To One
                level++;                                    // Increase The Level
                level2++;                                   // Increase The Displayed Level
                if (level > 3) {                            // Is The Level Greater Than 3?
                    level = 3;                              // If So, Set The Level To 3
                    lives++;                                // Give The Player A Free Life
                    if (lives > 5) {                        // Does The Player Have More Than 5 Lives?
                        lives = 5;                          // If So, Set Lives To Five
                    }
                }
            }

            resetObjects();                                 // Reset Player / Enemy Positions

            for (int i=0; i<11; i++) {                      // Loop Through The Grid X Coordinates
                for (int j=0; j<11; j++) {                  // Loop Through The Grid Y Coordinates
                    if (i < 10) {                           // If X Coordinate Is Less Than 10
                        hline[i][j] = false;                // Set The Current Horizontal Value To false
                    }
                    if (j < 10) {                           // If Y Coordinate Is Less Than 10
                        vline[i][j] = false;                // Set The Current Vertical Value To false
                    }
                }
            }
        }

        // If The Player Hits The Hourglass While It's Being Displayed On The Screen
        if ((player.fx == hourglass.x * 60) && (player.fy == hourglass.y * 40) && (hourglass.fx == 1)) {
            // Play Freeze Enemy Sound
//            PlaySound("Data/freeze.wav", NULL, SND_ASYNC | SND_LOOP);
            AL10.alSourcePlay(freezeSource.get(0));
            hourglass.fx = 2;                               // Set The hourglass fx Variable To Two
            hourglass.fy = 0;                               // Set The hourglass fy Variable To Zero
        }

        player.spin += 0.5f * steps[adjust];                // Spin The Player Clockwise
        if (player.spin > 360.0f) {                         // Is The spin Value Greater Than 360?
            player.spin -= 360;                             // If So, Subtract 360
        }

        hourglass.spin -= 0.25f * steps[adjust];            // Spin The Hourglass Counter Clockwise
        if (hourglass.spin < 0.0f) {                        // Is The spin Value Less Than 0?
            hourglass.spin += 360.0f;                       // If So, Add 360
        }

        hourglass.fy += steps[adjust];                      // Increase The hourglass fy Variable
        if ((hourglass.fx == 0) && (hourglass.fy > 6000 / level)) { // Is The hourglass fx Variable Equal To 0 And The fy
        // Variable Greater Than 6000 Divided By The Current Level?
//            PlaySound("Data/hourglass.wav", NULL, SND_ASYNC);   // If So, Play The Hourglass Appears Sound
            AL10.alSourcePlay(hourglassWavSource.get(0));
            hourglass.x = (int)(Math.random() * 10.0 + 1.0);// Give The Hourglass A Random X Value
            hourglass.y = (int)(Math.random() * 11.0);      // Give The Hourglass A Random Y Value
            hourglass.fx = 1;                               // Set hourglass fx Variable To One (Hourglass Stage)
            hourglass.fy = 0;                               // Set hourglass fy Variable To Zero (Counter)
        }

        if ((hourglass.fx == 1) && (hourglass.fy > 6000 / level)) { // Is The hourglass fx Variable Equal To 1 And The fy
        // Variable Greater Than 6000 Divided By The Current Level?
            hourglass.fx = 0;                               // If So, Set fx To Zero (Hourglass Will Vanish)
            hourglass.fy = 0;                               // Set fy to Zero (Counter Is Reset)
        }

        if ((hourglass.fx == 2) && (hourglass.fy > 500 + (500 * level))) { // Is The hourglass fx Variable Equal To 2 And The fy
        // Variable Greater Than 500 Plus 500 Times The Current Level?
//            PlaySound(NULL, NULL, 0);                       // If So, Kill The Freeze Sound
            hourglass.fx = 0;                               // Set hourglass fx Variable To Zero
            hourglass.fy = 0;                               // Set hourglass fy Variable To Zero
        }

        delay++;                                            // Increase The Enemy Delay Counter
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
        enemy = new GameObject[9];
        for(int i=0;i<9;i++) {
            enemy[i] = new GameObject();
        }

        player = new GameObject();                                      // Player Information
        hourglass = new GameObject();                                   // Hourglass Information
        timer = new Timer();

        vline = new boolean[11][11];                                    // Keeps Track Of Verticle Lines
        hline = new boolean[11][11];                                    // Keeps Track Of Horizontal Lines

        for(int i=0;i<11;i++) {
            for(int j=0;j<11;j++) {
                vline[i][j] = false;
                hline[j][i] = false;
            }
        }

        createWindow();
        IL.create();

        loadTextures();
        initGL();
        buildFont();
        resetObjects();
        timerInit();
        loadSounds();

    }
    private void loadSounds() throws Exception {
        // you must create OpenAl before you can do anything with it.
        AL.create();
        loadSound(completeBuffer, completeSource, "Data/Complete.wav");
        loadSound(dieBuffer, dieSource, "Data/Die.wav");
        loadSound(freezeBuffer, freezeSource, "Data/Freeze.wav");
        loadSound(hourglassWavBuffer, hourglassWavSource, "Data/Hourglass.wav");
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
        texture = new int[2];
        texture[0] = loadTexture("Data/Font.bmp");
        texture[1] = loadTexture("Data/Image.bmp");
    }
    private void initGL() {                                         // All Setup For OpenGL Goes Here
        GL11.glShadeModel(GL11.GL_SMOOTH);                          // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);                  // Black Background
        GL11.glClearDepth(1.0f);                                    // Depth Buffer Setup
        GL11.glHint(GL11.GL_LINE_SMOOTH_HINT, GL11.GL_NICEST);      // Set Line Antialiasing
        GL11.glEnable(GL11.GL_BLEND);                               // Enable Blending
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);      // Type Of Blending To Use

        // This line was in the original source.  I removed it because
        // it causes problems with other resolutions in fullscreen.
        //GL11.glViewport(0,0,640,480);                               // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                      // Select The Projection Matrix
        GL11.glLoadIdentity();                                      // Reset The Projection Matrix

        GL11.glOrtho(0.0f,640,480,0.0f,-1.0f,1.0f);                 // Create Ortho 640x480 View (0,0 At Top Left)

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                       // Select The Modelview Matrix
        GL11.glLoadIdentity();                                      // Reset The Modelview Matrix
    }

    private void buildFont() {                                      // Build Our Font Display List
        base = GL11.glGenLists(256);                                // Creating 256 Display Lists
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);         // Select Our Font Texture
        for (int i=0; i<256; i++) {                                 // Loop Through All 256 Lists
            float cx = (float)(i % 16) / 16.0f;                     // X Position Of Current Character
            float cy = (float)(i / 16) / 16.0f;                     // Y Position Of Current Character

            GL11.glNewList(base+i,GL11.GL_COMPILE);                 // Start Building A List
                GL11.glBegin(GL11.GL_QUADS);                        // Use A Quad For Each Character
                    GL11.glTexCoord2f(cx,1.0f-cy-0.0625f);          // Texture Coord (Bottom Left)
                    GL11.glVertex2i(0,16);                          // Vertex Coord (Bottom Left)
                    GL11.glTexCoord2f(cx+0.0625f,1.0f-cy-0.0625f);  // Texture Coord (Bottom Right)
                    GL11.glVertex2i(16,16);                         // Vertex Coord (Bottom Right)
                    GL11.glTexCoord2f(cx+0.0625f,1.0f-cy);          // Texture Coord (Top Right)
                    GL11.glVertex2i(16,0);                          // Vertex Coord (Top Right)
                    GL11.glTexCoord2f(cx,1.0f-cy);                  // Texture Coord (Top Left)
                    GL11.glVertex2i(0,0);                           // Vertex Coord (Top Left)
                GL11.glEnd();                                       // Done Building Our Quad (Character)
                GL11.glTranslatef(15.0f,0,0);                       // Move To The Right Of The Character
            GL11.glEndList();                                       // Done Building The Display List
        }                                                           // Loop Until All 256 Are Built
    }

    private void timerInit() {
        timer.performance_timer = true;
        timer.resolution = Sys.getTimerResolution();
        timer.performance_timer_start = Sys.getTime();
        timer.performance_timer_elapsed = timer.performance_timer_start;
    }

    private float timerGetTime() {
        return ((float)((Sys.getTime() - timer.performance_timer_start) * timer.resolution)) * 1000.0f;
    }

    private void resetObjects() {                               // Reset Player And Enemies
        player.x = 0;                                           // Reset Player X Position To Far Left Of The Screen
        player.y = 0;                                           // Reset Player Y Position To The Top Of The Screen
        player.fx = 0;                                          // Set Fine X Position To Match
        player.fy = 0;                                          // Set Fine Y Position To Match

        for (int i=0; i<(stage * level); i++) {                 // Loop Through All The Enemies
            enemy[i].x = 5 + (int)(Math.random() * 6.0);        // Select A Random X Position
            enemy[i].y = (int)(Math.random() * 11.0);           // Select A Random Y Position
            enemy[i].fx = enemy[i].x * 60;                      // Set Fine X To Match
            enemy[i].fy = enemy[i].y * 40;                      // Set Fine Y To Match
        }
    }

    /* Some liberties had to be taken with this method.  I could not get the glCallLists() to work, so
     * it is done manually instead.
     */
    private void glPrint(int x, int y, int set, String msg) {       // Custom GL "Print" Routine
        int offset = base - 32 + (128 * set);

        GL11.glEnable(GL11.GL_TEXTURE_2D);                          // Enable Texture Mapping
        GL11.glLoadIdentity();                                      // Reset The Modelview Matrix
        GL11.glTranslatef(x, y, 0);                                 // Position The Text (0,0 - Bottom Left)
        if (set == 0) {                                             // If Set 0 Is Being Used Enlarge Font
            GL11.glScalef(1.5f,2.0f,1.0f);                          // Enlarge Font Width And Height
        }
        if(msg != null) {
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);
            for(int i=0;i<msg.length();i++) {
                GL11.glCallList(offset + msg.charAt(i));
                GL11.glTranslatef(0.05f, 0.0f, 0.0f);
            }
        }
        GL11.glDisable(GL11.GL_TEXTURE_2D);                         // Disable Texture Mapping
    }

    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);  // Clear Screen And Depth Buffer
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);                 // Select Our Font Texture
        GL11.glColor3f(1.0f, 0.5f, 1.0f);                                   // Set Color To Purple
        glPrint(207, 24, 0, "GRID CRAZY");                                  // Write GRID CRAZY On The Screen
        GL11.glColor3f(1.0f, 1.0f, 0.0f);                                   // Set Color To Yellow
        numberFormat.setMinimumIntegerDigits(2);
        numberFormat.setMaximumIntegerDigits(2);
        glPrint(20, 20, 1, "Level:" + numberFormat.format(level2));         // Write Actual Level Stats
        glPrint(20, 40, 1, "Stage:" + numberFormat.format(stage));          // Write Stage Stats

        if(gameover) {                                                      // Is The Game Over?
            GL11.glColor3ub((byte)(Math.random() * 255.0), (byte)(Math.random() * 255.0), (byte)(Math.random() * 255.0));       // Pick A Random Color
            glPrint(472, 20, 1, "GAME OVER");                               // Write GAME OVER To The Screen
            glPrint(456, 40, 1, "PRESS SPACE");                             // Write PRESS SPACE To The Screen
        }

        //draw lives in upper right corner
        for(int i=0; i<lives - 1; i++) {                            // Loop Through Lives Minus Current Life
            GL11.glLoadIdentity();                                  // Reset The View
            float x = 490.0f + (((float)i) * 40.0f);
            GL11.glTranslatef(x, 40.0f, 0.0f);                      // Move To The Right Of Our Title Text
            GL11.glRotatef(-player.spin, 0.0f, 0.0f, 1.0f);         // Rotate Counter Clockwise
            GL11.glColor3f(0.0f, 1.0f, 0.0f);                       // Set Player Color To Light Green
            GL11.glBegin(GL11.GL_LINES);                            // Start Drawing Our Player Using Lines
                GL11.glVertex2i(-5, -5);                            // Top Left Of Player
                GL11.glVertex2i( 5,  5);                            // Bottom Right Of Player
                GL11.glVertex2i( 5, -5);                            // Top Right Of Player
                GL11.glVertex2i(-5,  5);                            // Bottom Left Of Player
            GL11.glEnd();                                           // Done Drawing The Player
            GL11.glRotatef(-player.spin * 0.5f, 0.0f, 0.0f, 1.0f);  // Rotate Counter Clockwise
            GL11.glColor3f(0.0f, 0.75f, 0.0f);                      // Set Player Color To Dark Green
            GL11.glBegin(GL11.GL_LINES);                            // Start Drawing Our Player Using Lines
                GL11.glVertex2i(-7,  0);                            // Left Center Of Player
                GL11.glVertex2i( 7,  0);                            // Right Center Of Player
                GL11.glVertex2i( 0, -7);                            // Top Center Of Player
                GL11.glVertex2i( 0,  7);                            // Bottom Center Of Player
            GL11.glEnd();                                           // Done Drawing The Player

        }

        filled = true;                                              // Set Filled To True Before Testing
        GL11.glLineWidth(2.0f);                                     // Set Line Width For Cells To 2.0f
        GL11.glDisable(GL11.GL_LINE_SMOOTH);                        // Disable Antialiasing
        GL11.glLoadIdentity();                                      // Reset The Current Modelview Matrix
        for(int i=0; i<11; i++) {                                   // Loop From Left To Right
            for(int j=0; j<11; j++) {                               // Loop From Top To Bottom
                GL11.glColor3f(0.0f, 0.5f, 1.0f);                   // Set Line Color To Blue
                if(hline[i][j]) {                                   // Has The Horizontal Line Been Traced
                    GL11.glColor3f(1.0f, 1.0f, 1.0f);               // If So, Set Line Color To White
                }

                if(i < 10) {                                        // Dont Draw To Far Right
                    if(!hline[i][j]) {                              // If A Horizontal Line Isn't Filled
                        filled = false;                             // filled Becomes False
                    }
                    GL11.glBegin(GL11.GL_LINES);                    // Start Drawing Horizontal Cell Borders
                    int x1 = 20 + (i * 60);
                    int x2 = 80 + (i * 60);
                    int y1 = 70 + (j * 40);
                    int y2 = 70 + (j * 40);
                        GL11.glVertex2i(x1, y1);                    // Left Side Of Horizontal Line
                        GL11.glVertex2i(x2, y2);                    // Right Side Of Horizontal Line
                    GL11.glEnd();                                   // Done Drawing Horizontal Cell Borders
                }

                GL11.glColor3f(0.0f, 0.5f, 1.0f);                   // Set Line Color To Blue
                if(vline[i][j]) {                                   // Has The Horizontal Line Been Traced
                    GL11.glColor3f(1.0f, 1.0f, 1.0f);               // If So, Set Line Color To White
                }
                if(j<10) {                                          // Dont Draw To Far Down
                    if(!vline[i][j]) {                              // If A Verticle Line Isn't Filled
                        filled = false;                             // filled Becomes False
                    }
                    GL11.glBegin(GL11.GL_LINES);                    // Start Drawing Verticle Cell Borders
                    int x1 = 20 + (i * 60);
                    int x2 = 20 + (i * 60);
                    int y1 = 70 + (j * 40);
                    int y2 = 110 + (j * 40);
                        GL11.glVertex2i(x1, y1);                    // Left Side Of Vertical Line
                        GL11.glVertex2i(x2, y2);                    // Right Side Of Vertical Line
                    GL11.glEnd();                                   // Done Drawing Verticle Cell Borders
                }

                GL11.glEnable(GL11.GL_TEXTURE_2D);                  // Enable Texture Mapping
                GL11.glColor3f(1.0f, 1.0f, 1.0f);                   // Bright White Color
                GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[1]); // Select The Tile Image
                if((i < 10) && (j < 10)) {                          // If In Bounds, Fill In Traced Boxes
                    // Are All Sides Of The Box Traced?
                    if(hline[i][j] && hline[i][j+1] && vline[i][j] && vline[i+1][j]) {
                        GL11.glBegin(GL11.GL_QUADS);                // Draw A Textured Quad
                            GL11.glTexCoord2f((((float)i) / 10.0f) + 0.1f, 1.0f - ((float)j) / 10.0f);
                            GL11.glVertex2i(20 + (i * 60) + 59, (70 + j * 40 + 1));   // Top Right
                            GL11.glTexCoord2f((((float)i) / 10.0f), 1.0f - (((float)j) / 10.0f));
                            GL11.glVertex2i(20 + (i * 60) + 1, (70 + j * 40 + 1));    // Top Left
                            GL11.glTexCoord2f((((float)i) / 10.0f), 1.0f - (((float)j) / 10.0f) + 0.1f);
                            GL11.glVertex2i(20 + (i * 60) + 1, (70 + j * 40) + 39);   // Bottom Left
                            GL11.glTexCoord2f((((float)i) / 10.0f) + 0.1f, 1.0f - (((float)j) / 10.0f) + 0.1f);
                            GL11.glVertex2i(20+(i*60)+59,(70+j*40)+39);  // Bottom Right
                        GL11.glEnd();                               // Done Texturing The Box
                    }
                }
                GL11.glDisable(GL11.GL_TEXTURE_2D);                 // Disable Texture Mapping
            }
        }
        GL11.glLineWidth(1.0f);                                     // Set The Line Width To 1.0f

        if(anti) {                                                  // Is Anti true?
            GL11.glEnable(GL11.GL_LINE_SMOOTH);                     // If So, Enable Antialiasing
        }

        if(hourglass.fx == 1) {                                     // If fx=1 Draw The Hourglass
            GL11.glLoadIdentity();                                  // Reset The Modelview Matrix
            GL11.glTranslatef(20.0f + (hourglass.x * 60), 70.0f + (hourglass.y * 40), 0.0f);   // Move To The Fine Hourglass Position
            GL11.glRotatef(hourglass.spin, 0.0f, 0.0f, 1.0f);       // Rotate Clockwise
            GL11.glColor3ub((byte)(Math.random() * 255.0), (byte)(Math.random() * 255.0), (byte)(Math.random() * 255.0));       // Set Hourglass Color To Random Color
            GL11.glBegin(GL11.GL_LINES);                            // Start Drawing Our Hourglass Using Lines
                GL11.glVertex2i(-5, -5);                            // Top Left Of Hourglass
                GL11.glVertex2i( 5,  5);                            // Bottom Right Of Hourglass
                GL11.glVertex2i( 5, -5);                            // Top Right Of Hourglass
                GL11.glVertex2i(-5,  5);                            // Bottom Left Of Hourglass
                GL11.glVertex2i(-5,  5);                            // Bottom Left Of Hourglass
                GL11.glVertex2i( 5,  5);                            // Bottom Right Of Hourglass
                GL11.glVertex2i(-5, -5);                            // Top Left Of Hourglass
                GL11.glVertex2i( 5, -5);                            // Top Right Of Hourglass
            GL11.glEnd();                                           // Done Drawing The Hourglass
        }

        GL11.glLoadIdentity();                                      // Reset The Modelview Matrix
        GL11.glTranslatef(player.fx + 20.0f, player.fy + 70.0f, 0.0f);     // Move To The Fine Player Position
        GL11.glRotatef(player.spin, 0.0f, 0.0f, 1.0f);              // Rotate Clockwise
        GL11.glColor3f(0.0f, 1.0f, 0.0f);                           // Set Player Color To Light Green
        GL11.glBegin(GL11.GL_LINES);                                // Start Drawing Our Player Using Lines
            GL11.glVertex2i(-5, -5);                                // Top Left Of Player
            GL11.glVertex2i( 5,  5);                                // Bottom Right Of Player
            GL11.glVertex2i( 5, -5);                                // Top Right Of Player
            GL11.glVertex2i(-5,  5);                                // Bottom Left Of Player
        GL11.glEnd();                                               // Done Drawing The Player
        GL11.glRotatef(player.spin * 0.5f, 0.0f, 0.0f, 1.0f);       // Rotate Clockwise
        GL11.glColor3f(0.0f, 0.75f, 0.0f);                          // Set Player Color To Dark Green
        GL11.glBegin(GL11.GL_LINES);                                // Start Drawing Our Player Using Lines
            GL11.glVertex2i(-7,  0);                                // Left Center Of Player
            GL11.glVertex2i( 7,  0);                                // Right Center Of Player
            GL11.glVertex2i( 0, -7);                                // Top Center Of Player
            GL11.glVertex2i( 0,  7);                                // Bottom Center Of Player
        GL11.glEnd();                                               // Done Drawing The Player

        for(int i=0; i<(stage * level); i++) {                      // Loop To Draw Enemies
            GL11.glLoadIdentity();                                  // Reset The Modelview Matrix
            GL11.glTranslatef(enemy[i].fx + 20.0f, enemy[i].fy + 70.0f, 0.0f);
            GL11.glColor3f(1.0f, 0.5f, 0.5f);                       // Make Enemy Body Pink
            GL11.glBegin(GL11.GL_LINES);                            // Start Drawing Enemy
                GL11.glVertex2i( 0, -7);                            // Top Point Of Body
                GL11.glVertex2i(-7,  0);                            // Left Point Of Body
                GL11.glVertex2i(-7,  0);                            // Left Point Of Body
                GL11.glVertex2i( 0,  7);                            // Bottom Point Of Body
                GL11.glVertex2i( 0,  7);                            // Bottom Point Of Body
                GL11.glVertex2i( 7,  0);                            // Right Point Of Body
                GL11.glVertex2i( 7,  0);                            // Right Point Of Body
                GL11.glVertex2i( 0, -7);                            // Top Point Of Body
            GL11.glEnd();                                           // Done Drawing Enemy Body
            GL11.glRotatef(enemy[i].spin, 0.0f, 0.0f, 1.0f);        // Rotate The Enemy Blade
            GL11.glColor3f(1.0f, 0.0f, 0.0f);                       // Make Enemy Blade Red
            GL11.glBegin(GL11.GL_LINES);                            // Start Drawing Enemy Blade
                GL11.glVertex2i(-7, -7);                            // Top Left Of Enemy
                GL11.glVertex2i( 7,  7);                            // Bottom Right Of Enemy
                GL11.glVertex2i(-7,  7);                            // Bottom Left Of Enemy
                GL11.glVertex2i( 7, -7);                            // Top Right Of Enemy
            GL11.glEnd();                                           // Done Drawing Enemy Blade
        }
    }

    private void cleanup() {
        Display.destroy();
    }

    /**
     * Texture loading directly from LWJGL examples
     */
    private final int loadTexture(String path) {
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

    private IntBuffer createIntBuffer(int size) {
      ByteBuffer temp = ByteBuffer.allocateDirect(4 * size);
      temp.order(ByteOrder.nativeOrder());

      return temp.asIntBuffer();
    }

}

class GameObject {                                             // Create A Structure For Our Player
    public int fx, fy;                                         // Fine Movement Position
    public int x, y;                                           // Current Player Position
    public float spin;                                         // Spin Direction
}

class Timer {                                             // Create A Structure For The Timer Information
  public long frequency;                                  // Timer Frequency
  public float resolution;                                // Timer Resolution
  public long mm_timer_start;                             // Multimedia Timer Start Value
  public long mm_timer_elapsed;                           // Multimedia Timer Elapsed Time
  public boolean performance_timer;                       // Using The Performance Timer?
  public long performance_timer_start;                    // Performance Timer Start Value
  public long performance_timer_elapsed;                  // Performance Timer Elapsed Time
}

