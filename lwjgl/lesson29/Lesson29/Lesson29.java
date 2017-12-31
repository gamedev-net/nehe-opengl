/////////////////////////////////////////////////////////////////
//                                                             //
//  The OpenGL Basecode Used In This Project Was Created By    //
//  Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code  //
//  Useful, Please Let Me Know.                                //
//                                                             //
//  Original Code & Tutorial Text By Andreas Löffler           //
//  Excellent Job Andreas!                                     //
//                                                             //
//  Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )  //
//  Proper Image Structure, Better Blitter Code, Misc Fixes    //
//  Thanks Rob!                                                //
//                                                             //
//  0% CPU Usage While Minimized Thanks To Jim Strong          //
//  ( jim@scn.net ).  Thanks Jim!                              //
//                                                             //
//  Visit Me At nehe.gamedev.net                               //
//                                                             //
/////////////////////////////////////////////////////////////////

import java.io.FileInputStream;
import java.nio.ByteBuffer;
import java.nio.IntBuffer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    24-Aug-2004
 *
 * Port of NeHe's Lesson 29 to LWJGL
 * Title: Blitter Function, RAW Texture Loading
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL.
 */
public class Lesson29 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 29 for LWJGL (Blitter Function, RAW Texture Loading)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    float xrot;                                               // X Rotation
    float yrot;                                               // Y Rotation
    float zrot;                                               // Z Rotation

    int texture[];                                         // Storage For 1 Texture

    TextureImage t1;                                             // Pointer To The Texture Image Data Type
    TextureImage t2;                                             // Pointer To The Texture Image Data Type

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson29 l29 = new Lesson29();
        l29.run(fullscreen);
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

        initGL();
    }


    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int width = 640;
        int height = 480;
        texture = new int[1];
        t1 = readTextureData("Data/Monitor.raw");              // Fill The Image Structure With Data

        t2 = readTextureData("Data/GL.raw");                   // Fill The Image Structure With Data

        // Image To Blend In, Original Image, Src Start X & Y, Src Width & Height, Dst Location X & Y, Blend Flag, Alpha Value
        blit(t2,t1,127,127,128,128,64,64,true,127);                    // Call The Blitter Routine

        buildTexture (t1);                                          // Load The Texture Map Into Texture Memory

        t1 = null;                                    // Clean Up Image Memory Because Texture Is
        t2 = null;                                    // In GL Texture Memory Now

        GL11.glEnable(GL11.GL_TEXTURE_2D);                                    // Enable Texture Mapping

        GL11.glShadeModel(GL11.GL_SMOOTH);                                    // Enables Smooth Color Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);                       // This Will Clear The Background Color To Black
        GL11.glClearDepth(1.0);                                          // Enables Clearing Of The Depth Buffer
        GL11.glEnable(GL11.GL_DEPTH_TEST);                                    // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LESS);                                       // The Type Of Depth Test To Do

        GL11.glViewport(0,0,width,height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,(float)width/(float)height,0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix
    }
    //Since Java does not have pointers, this method had to be almost completely re-written
    private void blit(TextureImage src, TextureImage dst, int src_xstart, int src_ystart, int src_width, int src_height,
            int dst_xstart, int dst_ystart, boolean blend, int alpha) {
     // Clamp Alpha If Value Is Out Of Range
     if( alpha > 255 ) {
         alpha = 255;
     }
     if( alpha < 0 ) {
         alpha = 0;
     }

     //values for the location in the destination image
     int x = dst_xstart * src.format;
     int y = dst_ystart;
     for(int j=src_ystart;j<(src_ystart + src_height);j++) {
         x = dst_xstart * src.format;
         for(int i=src_xstart * src.format;i<(src_xstart * src.format) + (src_width * src.format);i++) {
             int src_pos = i + (j * 256 * src.format);
             int dst_pos = x + (y * 256 * src.format);
             if(blend) {
                 // to make the calculations work correctly the data had to be changed to an
                 // unsigned state.  By converting to an int and masking out everything
                 // except the bottom 8 bits, the bit pattern is preserved and the sign is dropped.
                 // ie. -1(11111111) becomes 255(00000000 00000000 00000000 11111111)
                 int source = ((int)src.data[src_pos]) & 0x000000ff;
                 int dest = ((int)dst.data[dst_pos]) & 0x000000ff;
                 dst.data[dst_pos] = (byte)( ((source * alpha) + (dest * (255 - alpha))) >> 8 );
             }
             else {
                 dst.data[dst_pos] = src.data[src_pos];
             }
             x++;
         }
         y++;
     }
 }

    private void render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);     // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                       // Reset The View
        GL11.glTranslatef(0.0f,0.0f,-5.0f);

        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);
        GL11.glRotatef(zrot,0.0f,0.0f,1.0f);

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);

        GL11.glBegin(GL11.GL_QUADS);
            // Front Face
        GL11.glNormal3f( 0.0f, 0.0f, 1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
            // Back Face
        GL11.glNormal3f( 0.0f, 0.0f,-1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
            // Top Face
        GL11.glNormal3f( 0.0f, 1.0f, 0.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f( 1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f(-1.0f,  1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f(-1.0f,  1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f( 1.0f,  1.0f,  1.0f);
            // Bottom Face
        GL11.glNormal3f( 0.0f,-1.0f, 0.0f);
        GL11.glTexCoord2f(0.0f, 0.0f); GL11.glVertex3f( 1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 0.0f); GL11.glVertex3f(-1.0f, -1.0f,  1.0f);
        GL11.glTexCoord2f(1.0f, 1.0f); GL11.glVertex3f(-1.0f, -1.0f, -1.0f);
        GL11.glTexCoord2f(0.0f, 1.0f); GL11.glVertex3f( 1.0f, -1.0f, -1.0f);
            // Right Face
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

        xrot+=0.3f;
        yrot+=0.2f;
        zrot+=0.4f;
    }

    private void cleanup() {
        Display.destroy();
    }

    private void buildTexture (TextureImage tex) {
        IntBuffer temp = ByteBuffer.allocateDirect(4).asIntBuffer();
        ByteBuffer data = ByteBuffer.allocateDirect(tex.data.length);
        data.put(tex.data);
        data.rewind();
        GL11.glGenTextures(temp);
        temp.get(texture);
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture[0]);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR);
        GLU.gluBuild2DMipmaps(GL11.GL_TEXTURE_2D, GL11.GL_RGB, tex.width, tex.height, GL11.GL_RGBA, GL11.GL_UNSIGNED_BYTE, data);
    }

    //  Read A .RAW File In To The Allocated Image Buffer Using Data In The Image Structure Header.
    //  Flip The Image Top To Bottom.  Returns 0 For Failure Of Read, Or Number Of Bytes Read.
    private TextureImage readTextureData(String filename) {
        TextureImage result = new TextureImage(256, 256, 4);
        byte temp[] = new byte[256 * 256 * 3];
        int stride = 256 * 4;
        int imageStride = 256 * 3;
        int copyOffset = (stride * 256) - stride;

        try {
            FileInputStream in = new FileInputStream(filename);
            in.read(temp);
            for(int i = 0; i<temp.length;i+=3) {
                result.data[copyOffset] = temp[i];
                result.data[copyOffset + 1] = temp[i + 1];
                result.data[copyOffset + 2] = temp[i + 2];
                result.data[copyOffset + 3] = (byte)255;
                copyOffset += 4;
                if(copyOffset % stride == 0) {
                    copyOffset -= (stride * 2);
                }
            }
        }
        catch(Exception e) {
            e.printStackTrace();
        }
        return result;
    }
}
class TextureImage {
    int width;                                                  // Width Of Image In Pixels
    int height;                                                 // Height Of Image In Pixels
    int format;                                                 // Number Of Bytes Per Pixel
    byte data[];                                                // Texture Data

    public TextureImage() {}
    public TextureImage(int width, int height, int format) {
        this.width = width;
        this.height = height;
        this.format = format;
        data = new byte[width * height * format];
    }
}
