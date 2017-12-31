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
 * date:    18-Nov-2003
 *
 * Port of NeHe's Lesson 11 to LWJGL
 * Title: Flag Effect (Waving Texture)
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

public class Lesson11 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's Lesson 11 (Flag Effect (Waving Texture))";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private float points[][][] = new float[45][45][3];    // The Array For The Points On The Grid Of Our "Wave"
    private int wiggle_count = 0;       // Counter Used To Control How Fast Flag Waves

    private float xrot;             // X Rotation ( NEW )
    private float yrot;             // Y Rotation ( NEW )
    private float zrot;             // Z Rotation ( NEW )
    private float hold;             // Temporarily Holds A Floating Point Value

    private int texture[] = new int[1]; // Storage For 1 Textures

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson11 l11 = new Lesson11();
        l11.run(fullscreen);
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

    private void render() {
        int x, y;
        float float_x, float_y, float_xb, float_yb;

        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);  // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                  // Reset The View

        GL11.glTranslatef(0.0f,0.0f,-12.0f);

        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);
        GL11.glRotatef(zrot,0.0f,0.0f,1.0f);

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);

        GL11.glBegin(GL11.GL_QUADS);
        for( x = 0; x < 44; x++ ) {
            for( y = 0; y < 44; y++ ) {
                float_x = (float)(x)/44.0f;
                float_y = (float)(y)/44.0f;
                float_xb = (float)(x+1)/44.0f;
                float_yb = (float)(y+1)/44.0f;

                GL11.glTexCoord2f( float_x, float_y);
                GL11.glVertex3f( points[x][y][0], points[x][y][1], points[x][y][2] );

                GL11.glTexCoord2f( float_x, float_yb );
                GL11.glVertex3f( points[x][y+1][0], points[x][y+1][1], points[x][y+1][2] );

                GL11.glTexCoord2f( float_xb, float_yb );
                GL11.glVertex3f( points[x+1][y+1][0], points[x+1][y+1][1], points[x+1][y+1][2] );

                GL11.glTexCoord2f( float_xb, float_y );
                GL11.glVertex3f( points[x+1][y][0], points[x+1][y][1], points[x+1][y][2] );
            }
        }
        GL11.glEnd();

        if( wiggle_count == 2 ) {
            for( y = 0; y < 45; y++ ) {
                hold=points[0][y][2];
                for( x = 0; x < 44; x++) {
                    points[x][y][2] = points[x+1][y][2];
                }
                points[44][y][2]=hold;
            }
            wiggle_count = 0;
        }

        wiggle_count++;

        xrot+=0.3f;
        yrot+=0.2f;
        zrot+=0.4f;
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

        for(int x=0; x<45; x++) {
            for(int y=0; y<45; y++) {
                points[x][y][0]=(float)x/5.0f-4.5f;
                points[x][y][1]=(float)y/5.0f-4.5f;
                points[x][y][2]=(float)(Math.sin(((((double)x/5.0)*40.0)/360.0)*Math.PI*2.0));
            }
        }
    }

    private void loadTextures() {
        texture = loadTexture("Data/Tim.bmp");
    }
    private void initGL() {
        GL11.glEnable(GL11.GL_TEXTURE_2D);                                  // Enable Texture Mapping
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA,GL11.GL_ONE);                    // Set The Blending Function For Translucency
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);                          // This Will Clear The Background Color To Black
        GL11.glClearDepth(1.0);                                             // Enables Clearing Of The Depth Buffer
        GL11.glDepthFunc(GL11.GL_LESS);                                     // The Type Of Depth Test To Do
        GL11.glEnable(GL11.GL_DEPTH_TEST);                                  // Enables Depth Testing
        GL11.glShadeModel(GL11.GL_SMOOTH);                                  // Enables Smooth Color Shading
        GL11.glMatrixMode(GL11.GL_PROJECTION);                              // Select The Projection Matrix
        GL11.glLoadIdentity();                                              // Reset The Projection Matrix
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW);                               // Select The Modelview Matrix
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);   // Really Nice Perspective Calculations

        GL11.glPolygonMode( GL11.GL_BACK, GL11.GL_FILL );                   // Back Face Is Solid
        GL11.glPolygonMode( GL11.GL_FRONT, GL11.GL_LINE );                  // Front Face Is Made Of Lines
    }
    private void cleanup() {
        Display.destroy();
    }

    private final int[] loadTexture(String path) {
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
