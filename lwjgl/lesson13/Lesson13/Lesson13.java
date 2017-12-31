/*
 *      This Code Was Created By Jeff Molofee 2000
 *      Modified by Shawn T. to handle (%3.2f, num) parameters.
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit My Site At nehe.gamedev.net
 */
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.IntBuffer;
import java.text.NumberFormat;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    26-May-2004
 *
 * Port of NeHe's Lesson 13 to LWJGL
 * Title: Bitmap fonts
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
 * 2004-12-19: Updated to version 0.94alpha of LWJGL
 */
public class Lesson13 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 13 for LWJGL (Bitmap Fonts)";
    private boolean f1 = false;
    private DisplayMode displayMode;

    private int texture;

    //build colours for font with alpha transparency
    private static final Color OPAQUE_WHITE = new Color(0xFFFFFFFF, true);
    private static final Color TRANSPARENT_BLACK = new Color(0x00000000, true);
    private NumberFormat numberFormat = NumberFormat.getInstance();

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

        Lesson13 l13 = new Lesson13();
        l13.run(fullscreen);
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

    private boolean render() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT);  // Clear Screen And Depth Buffer
        GL11.glLoadIdentity();                                              // Reset The Current Modelview Matrix

        // Position The Text On The Screen
        GL11.glTranslatef(-0.9f + 0.05f * ((float)Math.cos(cnt1)), 0.32f * ((float)Math.sin(cnt2)), -2.0f);                               // Move One Unit Into The Screen

        // Pulsing Colors Based On Text Position
        float red = 1.0f * ((float)Math.cos(cnt1));
        float green = 1.0f * ((float)Math.sin(cnt2));
        float blue = 1.0f - 0.5f * ((float)Math.cos(cnt1 + cnt2));
        GL11.glColor3f(red, green, blue);

        //format the floating point number to 2 decimal places
        numberFormat.setMaximumFractionDigits(2);
        numberFormat.setMinimumFractionDigits(2);

        glPrint("Active OpenGL Text With NeHe - " + numberFormat.format(cnt1));     // Print GL Text To The Screen
        cnt1 += 0.051f;                                                     // Increase The First Counter
        cnt2 += 0.005f;                                                     // Increase The Second Counter

        return true;
    }

    /* Some liberties had to be taken with this method.  I could not get the glCallLists() to work, so
     * it is done manually instead.
     */
    private void glPrint(String msg) {                                      // Custom GL "Print" Routine
        if(msg != null) {
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture);
            for(int i=0;i<msg.length();i++) {
                GL11.glCallList(base + msg.charAt(i));
                GL11.glTranslatef(0.05f, 0.0f, 0.0f);
            }
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
        buildFont();
    }
    private void initGL() {
        GL11.glShadeModel(GL11.GL_SMOOTH); // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        // Black Background
        GL11.glClearDepth(1.0); // Depth Buffer Setup
        GL11.glDepthFunc(GL11.GL_LEQUAL);
        GL11.glEnable(GL11.GL_DEPTH_TEST); // Enables Depth Testing
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);
        GL11.glEnable(GL11.GL_BLEND);
        GL11.glEnable(GL11.GL_TEXTURE_2D); // Enable Texture Mapping
        //GL11.glEnable(GL11.GL_CULL_FACE);
        // The Type Of Depth Testing To Do

        GL11.glMatrixMode(GL11.GL_PROJECTION);
        // Select The Projection Matrix
        GL11.glLoadIdentity(); // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);
        GL11.glMatrixMode(GL11.GL_MODELVIEW);
        // Select The Modelview Matrix

        // Really Nice Perspective Calculations
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);
    }
    private void cleanup() {
        Display.destroy();
    }

    /* The original tutorial number 13 used a windows specific extension to generate a bitmap
     * for the font.  I had to replace that with a custom bitmap generation that you see below.
     *
     */
    private void buildFont() {                          // Build Our Bitmap Font
        Font font;                                      // Font object

        /* Note that I have set the font to Courier New.  This font is not guraunteed to be on all
         * systems.  However it is very common so it is likely to be there.  You can replace this name
         * with any named font on your system or use the Java default names that are guraunteed to be there.
         * Also note that this will work well with monospace fonts, but does not look as good with
         * proportional fonts.
         */
        String fontName = "Courier New";                // Name of the font to use
        BufferedImage fontImage;                        // image for creating the bitmap
        int bitmapSize = 512;                           // set the size for the bitmap texture
        boolean sizeFound = false;
        boolean directionSet = false;
        int delta = 0;
        int fontSize = 24;

        /* To find out how much space a Font takes, you need to use a the FontMetrics class.
         * To get the FontMetrics, you need to get it from a Graphics context.  A Graphics context is
         * only available from a displayable surface, ie any class that subclasses Component or any Image.
         * First the font is set on a Graphics object.  Then get the FontMetrics and find out the width
         * and height of the widest character (W).  Then take the largest of the 2 values and find the
         * maximum size font that will fit in the size allocated.
         */
        while(!sizeFound) {
            font = new Font(fontName, Font.PLAIN, fontSize);  // Font Name
            // use BufferedImage.TYPE_4BYTE_ABGR to allow alpha blending
            fontImage = new BufferedImage(bitmapSize, bitmapSize, BufferedImage.TYPE_4BYTE_ABGR);
            Graphics2D g = (Graphics2D)fontImage.getGraphics();
            g.setFont(font);
            FontMetrics fm = g.getFontMetrics();
            int width = fm.stringWidth("W");
            int height = fm.getHeight();
            int lineWidth = (width > height) ? width * 16 : height * 16;
            if(!directionSet) {
                if(lineWidth > bitmapSize) {
                    delta = -2;
                }
                else {
                    delta = 2;
                }
                directionSet = true;
            }
            if(delta > 0) {
                if(lineWidth < bitmapSize) {
                    fontSize += delta;
                }
                else {
                    sizeFound = true;
                    fontSize -= delta;
                }
            }
            else if(delta < 0) {
                if(lineWidth > bitmapSize) {
                    fontSize += delta;
                }
                else {
                    sizeFound = true;
                    fontSize -= delta;
                }
            }
        }

        /* Now that a font size has been determined, create the final image, set the font and draw the
         * standard/extended ASCII character set for that font.
         */
        font = new Font(fontName, Font.BOLD, fontSize);  // Font Name
        // use BufferedImage.TYPE_4BYTE_ABGR to allow alpha blending
        fontImage = new BufferedImage(bitmapSize, bitmapSize, BufferedImage.TYPE_4BYTE_ABGR);
        Graphics2D g = (Graphics2D)fontImage.getGraphics();
        g.setFont(font);
        g.setColor(OPAQUE_WHITE);
        g.setBackground(TRANSPARENT_BLACK);
        FontMetrics fm = g.getFontMetrics();
        for(int i=0;i<256;i++) {
            int x = i % 16;
            int y = i / 16;
            char ch[] = {(char)i};
            String temp = new String(ch);
            g.drawString(temp, (x * 32) + 1, (y * 32) + fm.getAscent());
        }

        /* The following code is taken directly for the LWJGL example code.
         * It takes a Java Image and converts it into an OpenGL texture.
         * This is a very powerful feature as you can use this to generate textures on the fly out
         * of anything.
         */
        //      Flip Image
        AffineTransform tx = AffineTransform.getScaleInstance(1, -1);
        tx.translate(0, -fontImage.getHeight(null));
        AffineTransformOp op =
            new AffineTransformOp(tx, AffineTransformOp.TYPE_NEAREST_NEIGHBOR);
        fontImage = op.filter(fontImage, null);

        // Put Image In Memory
        ByteBuffer scratch =
            ByteBuffer.allocateDirect(
                4 * fontImage.getWidth() * fontImage.getHeight());

        byte data[] =
            (byte[])fontImage.getRaster().getDataElements(
                0,
                0,
                fontImage.getWidth(),
                fontImage.getHeight(),
                null);
        scratch.clear();
        scratch.put(data);
        scratch.rewind();

        // Create A IntBuffer For Image Address In Memory
        IntBuffer buf =
            ByteBuffer
                .allocateDirect(4)
                .order(ByteOrder.nativeOrder())
                .asIntBuffer();
        GL11.glGenTextures(buf); // Create Texture In OpenGL

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(0));
        // Typical Texture Generation Using Data From The Image

        // Linear Filtering
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR);
        // Linear Filtering
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        // Generate The Texture
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RGBA, fontImage.getWidth(), fontImage.getHeight(), 0, GL11.GL_RGBA, GL11.GL_UNSIGNED_BYTE, scratch);


        texture = buf.get(0);                           // Return Image Address In Memory

        base = GL11.glGenLists(256);                    // Storage For 256 Characters

        /* Generate the display lists.  One for each character in the standard/extended ASCII chart.
         */
        float textureDelta = 1.0f / 16.0f;
        for(int i=0;i<256;i++) {
            float u = ((float)(i % 16)) / 16.0f;
            float v = 1.f - (((float)(i / 16)) / 16.0f);
            GL11.glNewList(base + i, GL11.GL_COMPILE);
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture);
            GL11.glBegin(GL11.GL_QUADS);
                GL11.glTexCoord2f(u, v);
                GL11.glVertex3f(-0.0450f, 0.0450f, 0.0f);
                GL11.glTexCoord2f((u + textureDelta), v);
                GL11.glVertex3f(0.0450f, 0.0450f, 0.0f);
                GL11.glTexCoord2f((u + textureDelta), v - textureDelta);
                GL11.glVertex3f(0.0450f, -0.0450f, 0.0f);
                GL11.glTexCoord2f(u, v - textureDelta);
                GL11.glVertex3f(-0.0450f, -0.0450f, 0.0f);
            GL11.glEnd();
            GL11.glEndList();
        }
    }
}