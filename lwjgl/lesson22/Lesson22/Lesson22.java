/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.awt.*;
import java.awt.event.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.IntBuffer;
import java.nio.FloatBuffer;
import javax.swing.*;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.ARBMultitexture;
import org.lwjgl.opengl.EXTTextureEnvCombine;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.devil.IL;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    26-Jun-2004
 *
 * Port of NeHe's Lesson 22 to LWJGL
 * Title: Bump-Mapping, Multi-Texturing & Extensions
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
public class Lesson22 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 22 for LWJGL (Bump-Mapping, Multi-Texturing & Extensions)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

    float MAX_EMBOSS = 0.008f;              // Maximum Emboss-Translate. Increase To Get Higher Immersion
                                        // At A Cost Of Lower Quality (More Artifacts Will Occur!)
    boolean ARB_ENABLE = true;                                           // Used To Disable ARB Extensions Entirely

    boolean EXT_INFO = false;                                                 // Do You Want To See Your Extensions At Start-Up?
    // not required with Java String class.
//    final int MAX_EXTENSION_SPACE = 10240;                                   // Characters for Extension-Strings
//    final int MAX_EXTENSION_LENGTH = 256;                                    // Maximum Of Characters In One Extension-String
    boolean multitextureSupported = true;                                   // Flag Indicating Whether Multitexturing Is Supported
    boolean useMultitexture = false;                                          // Use It If It Is Supported?

    // for the way LWJGL gets this information, we need an array of length 16
    // then the number retreived is stored inposition '0'
    int maxTexelUnits[] = new int[16];                                              // Number Of Texel-Pipelines. This Is At Least 1.

    boolean emboss = false;                                               // Emboss Only, No Basetexture?
    boolean bumps = false;                                                 // Do Bumpmapping?

    boolean eKey = false;
    boolean mKey = false;
    boolean bKey = false;
    boolean fKey = false;

    float xrot;                                                       // X Rotation
    float yrot;                                                       // Y Rotation
    float xspeed;                                                     // X Rotation Speed
    float yspeed;                                                     // Y Rotation Speed
    float z = -5.0f;                                                    // Depth Into The Screen

    int filter = 1;                                                   // Which Filter To Use
    int texture[];                                                 // Storage For 3 Textures
    int bump[];                                                    // Our Bumpmappings
    int invbump[];                                                 // Inverted Bumpmaps
    int glLogo;                                                     // Handle For OpenGL-Logo
    int multiLogo;                                                  // Handle For Multitexture-Enabled-Logo

    float lightAmbient[]  = { 0.2f, 0.2f, 0.2f, 1.0f};                      // Ambient Light is 20% white
    float lightDiffuse[]  = { 1.0f, 1.0f, 1.0f, 1.0f};                      // Diffuse Light is white
    float lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f};                      // Position is somewhat in front of screen

    float gray[]= {0.5f,0.5f,0.5f,1.0f};

//     Data Contains The Faces For The Cube In Format 2xTexCoord, 3xVertex;
//     Note That The Tesselation Of The Cube Is Only Absolute Minimum.
    float data[]= {
            // FRONT FACE
            0.0f, 0.0f,     -1.0f, -1.0f, +1.0f,
            1.0f, 0.0f,     +1.0f, -1.0f, +1.0f,
            1.0f, 1.0f,     +1.0f, +1.0f, +1.0f,
            0.0f, 1.0f,     -1.0f, +1.0f, +1.0f,
            // BACK FACE
            1.0f, 0.0f,     -1.0f, -1.0f, -1.0f,
            1.0f, 1.0f,     -1.0f, +1.0f, -1.0f,
            0.0f, 1.0f,     +1.0f, +1.0f, -1.0f,
            0.0f, 0.0f,     +1.0f, -1.0f, -1.0f,
            // Top Face
            0.0f, 1.0f,     -1.0f, +1.0f, -1.0f,
            0.0f, 0.0f,     -1.0f, +1.0f, +1.0f,
            1.0f, 0.0f,     +1.0f, +1.0f, +1.0f,
            1.0f, 1.0f,     +1.0f, +1.0f, -1.0f,
            // Bottom Face
            1.0f, 1.0f,     -1.0f, -1.0f, -1.0f,
            0.0f, 1.0f,     +1.0f, -1.0f, -1.0f,
            0.0f, 0.0f,     +1.0f, -1.0f, +1.0f,
            1.0f, 0.0f,     -1.0f, -1.0f, +1.0f,
            // Right Face
            1.0f, 0.0f,     +1.0f, -1.0f, -1.0f,
            1.0f, 1.0f,     +1.0f, +1.0f, -1.0f,
            0.0f, 1.0f,     +1.0f, +1.0f, +1.0f,
            0.0f, 0.0f,     +1.0f, -1.0f, +1.0f,
            // Left Face
            0.0f, 0.0f,     -1.0f, -1.0f, -1.0f,
            1.0f, 0.0f,     -1.0f, -1.0f,  1.0f,
            1.0f, 1.0f,     -1.0f,  1.0f,  1.0f,
            0.0f, 1.0f,     -1.0f,  1.0f, -1.0f
    };

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson22 l22 = new Lesson22();
        l22.run(fullscreen);
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

        if(Keyboard.isKeyDown(Keyboard.KEY_E) && !eKey) {
            eKey = true;
            emboss = !emboss;
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_E)) {
            eKey = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_M) && !mKey) {
            mKey = true;
            useMultitexture = ((!useMultitexture) && multitextureSupported);
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_M)) {
            mKey = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_B) && !bKey) {
            bKey = true;
            bumps = !bumps;
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_B)) {
            bKey = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_F) && !fKey) {
            fKey = true;
            filter++;
            filter %= 3;
        }
        if(!Keyboard.isKeyDown(Keyboard.KEY_F)) {
            fKey = false;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_PRIOR)) {
            z -= 0.02f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_NEXT)) {
            z+=0.02f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_UP)) {
            xspeed -= 0.01f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            xspeed += 0.01f;
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {
            yspeed += 0.01f;
        }
        if (Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {
            yspeed -= 0.01f;
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
        initMultitexture();
    }

//  isMultitextureSupported() Checks At Run-Time If Multitexturing Is Supported
    private boolean initMultitexture() {
        boolean result = false;
        String extensions;
        extensions = GL11.glGetString(GL11.GL_EXTENSIONS);            // Fetch Extension String
        extensions = extensions.replaceAll(" ", "\n");

        if(EXT_INFO) {
            MessageBox.showMessage(extensions, "supported GL extensions");
        }

        if ((extensions.indexOf("GL_ARB_multitexture") != -1) &&                // Is Multitexturing Supported?
                ARB_ENABLE &&                                                 // Override-Flag
                extensions.indexOf("GL_EXT_texture_env_combine") != -1) {       // Is texture_env_combining Supported?
            ByteBuffer temp = ByteBuffer.allocateDirect(64);
            temp.order(ByteOrder.nativeOrder());

            GL11.glGetInteger(ARBMultitexture.GL_MAX_TEXTURE_UNITS_ARB, (IntBuffer)temp.asIntBuffer().put(maxTexelUnits).flip());
            temp.asIntBuffer().get(maxTexelUnits);
//            for(int i=0;i<16;i++) {
//                System.out.println("" + maxTexelUnits[i]);
//            }
//            System.exit(0);
            if(EXT_INFO) {
                MessageBox.showMessage("The GL_ARB_multitexture extension will be used.", "Feature supported!");
            }

            result = true;
            useMultitexture = true;
        }

        return result;
    }

    private void initLights() {
        ByteBuffer temp = ByteBuffer.allocateDirect(16);
        temp.order(ByteOrder.nativeOrder());

        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_AMBIENT, (FloatBuffer)temp.asFloatBuffer().put(lightAmbient).flip());              // Setup The Ambient Light
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_DIFFUSE, (FloatBuffer)temp.asFloatBuffer().put(lightDiffuse).flip());              // Setup The Diffuse Light
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_POSITION,(FloatBuffer)temp.asFloatBuffer().put(lightPosition).flip());         // Position The Light

        GL11.glEnable(GL11.GL_LIGHT1);                          // Enable Light One
    }

    private void initGL() {                                         // All Setup For OpenGL Goes Here
        int width = 640;
        int height = 480;
        GL11.glEnable(GL11.GL_TEXTURE_2D);                            // Enable Texture Mapping
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);               // Black Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL);                             // The Type Of Depth Testing To Do
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);  // Really Nice Perspective Calculations

        GL11.glViewport(0,0,width,height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix

        initLights();
    }

    private void render() {
        if(bumps) {
            if (useMultitexture && maxTexelUnits[0]>1) {
                doMesh2TexelUnits();
            }
            else {
                doMesh1TexelUnits();
            }
        }
        else {
            doMeshNoBumps();
        }
    }
    private void doCube() {
        GL11.glBegin(GL11.GL_QUADS);
            // Front Face
            GL11.glNormal3f( 0.0f, 0.0f, +1.0f);
            for(int i=0; i<4; i++) {
                GL11.glTexCoord2f(data[5*i],data[5*i+1]);
                GL11.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
            }
            // Back Face
            GL11.glNormal3f( 0.0f, 0.0f,-1.0f);
            for(int i=4; i<8; i++) {
                GL11.glTexCoord2f(data[5*i],data[5*i+1]);
                GL11.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
            }
            // Top Face
            GL11.glNormal3f( 0.0f, 1.0f, 0.0f);
            for(int i=8; i<12; i++) {
                GL11.glTexCoord2f(data[5*i],data[5*i+1]);
                GL11.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
            }
            // Bottom Face
            GL11.glNormal3f( 0.0f,-1.0f, 0.0f);
            for(int i=12; i<16; i++) {
                GL11.glTexCoord2f(data[5*i],data[5*i+1]);
                GL11.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
            }
            // Right face
            GL11.glNormal3f( 1.0f, 0.0f, 0.0f);
            for(int i=16; i<20; i++) {
                GL11.glTexCoord2f(data[5*i],data[5*i+1]);
                GL11.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
            }
            // Left Face
            GL11.glNormal3f(-1.0f, 0.0f, 0.0f);
            for(int i=20; i<24; i++) {
                GL11.glTexCoord2f(data[5*i],data[5*i+1]);
                GL11.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
            }
        GL11.glEnd();
    }
    //  Calculates v=vM, M Is 4x4 In Column-Major, v Is 4dim. Row (i.e. "Transposed")
    private void VMatMult(float M[], float v[]) {
        float res[] = new float[3];
        res[0]=M[ 0]*v[0]+M[ 1]*v[1]+M[ 2]*v[2]+M[ 3]*v[3];
        res[1]=M[ 4]*v[0]+M[ 5]*v[1]+M[ 6]*v[2]+M[ 7]*v[3];
        res[2]=M[ 8]*v[0]+M[ 9]*v[1]+M[10]*v[2]+M[11]*v[3];;
        v[0]=res[0];
        v[1]=res[1];
        v[2]=res[2];
        v[3]=M[15];                                            // Homogenous Coordinate
    }

    /*  Okay, Here Comes The Important Stuff:

        On http://www.nvidia.com/marketing/Developer/DevRel.nsf/TechnicalDemosFrame?OpenPage
        You Can Find A Demo Called GL_BUMP That Is A Little Bit More Complicated.
        GL_BUMP:   Copyright Diego Tártara, 1999.
                 -  diego_tartara@ciudad.com.ar  -

        The Idea Behind GL_BUMP Is, That You Compute The Texture-Coordinate Offset As Follows:
            0) All Coordinates Either In Object Or In World Space.
            1) Calculate Vertex v From Actual Position (The Vertex You're At) To The Lightposition
            2) Normalize v
            3) Project This v Into Tangent Space.
                Tangent Space Is The Plane "Touching" The Object In Our Current Position On It.
                Typically, If You're Working With Flat Surfaces, This Is The Surface Itself.
            4) Offset s,t-Texture-Coordinates By The Projected v's x And y-Component.

        * This Would Be Called Once Per Vertex In Our Geometry, If Done Correctly.
        * This Might Lead To Incoherencies In Our Texture Coordinates, But Is Ok As Long As You Did Not
        * Wrap The Bumpmap.

        Basically, We Do It The Same Way With Some Exceptions:
            ad 0) We'll Work In Object Space All Time. This Has The Advantage That We'll Only
                  Have To Transform The Lightposition From Frame To Frame. This Position Obviously
                  Has To Be Transformed Using The Inversion Of The Modelview Matrix. This Is, However,
                  A Considerable Drawback, If You Don't Know How Your Modelview Matrix Was Built, Since
                  Inverting A Matrix Is Costly And Complicated.
            ad 1) Do It Exactly That Way.
            ad 2) Do It Exactly That Way.
            ad 3) To Project The Lightvector Into Tangent Space, We'll Support The Setup-Routine
                  With Two Directions: One Of Increasing s-Texture-Coordinate Axis, The Other In
                  Increasing t-Texture-Coordinate Axis. The Projection Simply Is (Assumed Both
                  texCoord Vectors And The Lightvector Are Normalized) The Dotproduct Between The
                  Respective texCoord Vector And The Lightvector.
            ad 4) The Offset Is Computed By Taking The Result Of Step 3 And Multiplying The Two
                  Numbers With MAX_EMBOSS, A Constant That Specifies How Much Quality We're Willing To
                  Trade For Stronger Bump-Effects. Just Temper A Little Bit With MAX_EMBOSS!

        WHY THIS IS COOL:
            * Have A Look!
            * Very Cheap To Implement (About One Squareroot And A Couple Of MULs)!
            * Can Even Be Further Optimized!
            * SetUpBump Doesn't Disturb glBegin()/glEnd()
            * THIS DOES ALWAYS WORK - Not Only With XY-Tangent Spaces!!

        DRAWBACKS:
            * Must Know "Structure" Of Modelview-Matrix Or Invert It. Possible To Do The Whole Thing
            * In World Space, But This Involves One Transformation For Each Vertex!
    */

    private void setUpBumps(float n[], float c[], float l[], float s[], float t[]) {
        float v[] = new float[3];                           // Vertex From Current Position To Light
        float lenQ;                           // Used To Normalize

        // Calculate v From Current Vector c To Lightposition And Normalize v
        v[0]=l[0]-c[0];
        v[1]=l[1]-c[1];
        v[2]=l[2]-c[2];
        lenQ=(float) Math.sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
        v[0]/=lenQ;     v[1]/=lenQ;     v[2]/=lenQ;
        // Project v Such That We Get Two Values Along Each Texture-Coordinat Axis.
        c[0]=(s[0]*v[0]+s[1]*v[1]+s[2]*v[2])*MAX_EMBOSS;
        c[1]=(t[0]*v[0]+t[1]*v[1]+t[2]*v[2])*MAX_EMBOSS;
    }

    private void doLogo() {         // MUST CALL THIS LAST!!!, Billboards The Two Logos.
        GL11.glDepthFunc(GL11.GL_ALWAYS);
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);
        GL11.glEnable(GL11.GL_BLEND);
        GL11.glDisable(GL11.GL_LIGHTING);
        GL11.glLoadIdentity();
        GL11.glBindTexture(GL11.GL_TEXTURE_2D,glLogo);
        GL11.glBegin(GL11.GL_QUADS);
            GL11.glTexCoord2f(0.0f,0.0f);    GL11.glVertex3f(0.23f, -0.4f,-1.0f);
            GL11.glTexCoord2f(1.0f,0.0f);    GL11.glVertex3f(0.53f, -0.4f,-1.0f);
            GL11.glTexCoord2f(1.0f,1.0f);    GL11.glVertex3f(0.53f, -0.25f,-1.0f);
            GL11.glTexCoord2f(0.0f,1.0f);    GL11.glVertex3f(0.23f, -0.25f,-1.0f);
        GL11.glEnd();
        if (useMultitexture) {
            GL11.glBindTexture(GL11.GL_TEXTURE_2D,multiLogo);
            GL11.glBegin(GL11.GL_QUADS);
                GL11.glTexCoord2f(0.0f,0.0f);    GL11.glVertex3f(-0.53f, -0.4f,-1.0f);
                GL11.glTexCoord2f(1.0f,0.0f);    GL11.glVertex3f(-0.33f, -0.4f,-1.0f);
                GL11.glTexCoord2f(1.0f,1.0f);    GL11.glVertex3f(-0.33f, -0.3f,-1.0f);
                GL11.glTexCoord2f(0.0f,1.0f);    GL11.glVertex3f(-0.53f, -0.3f,-1.0f);
            GL11.glEnd();
        }
        GL11.glDepthFunc(GL11.GL_LEQUAL);
    }

    private void doMesh1TexelUnits() {

        float c[]={0.0f,0.0f,0.0f,1.0f};                 // Holds Current Vertex
        float n[]={0.0f,0.0f,0.0f,1.0f};                 // Normalized Normal Of Current Surface
        float s[]={0.0f,0.0f,0.0f,1.0f};                 // s-Texture Coordinate Direction, Normalized
        float t[]={0.0f,0.0f,0.0f,1.0f};                 // t-Texture Coordinate Direction, Normalized
        float l[] = new float[4];                                       // Holds Our Lightposition To Be Transformed Into Object Space
        float Minv[] = new float[16];                                   // Holds The Inverted Modelview Matrix To Do So.
        int i;

        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer

        // Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With One glLoadIdentity();
        // Simply Build It By Doing All Transformations Negated And In Reverse Order.
        GL11.glLoadIdentity();
        GL11.glRotatef(-yrot,0.0f,1.0f,0.0f);
        GL11.glRotatef(-xrot,1.0f,0.0f,0.0f);
        GL11.glTranslatef(0.0f,0.0f,-z);

        ByteBuffer temp = ByteBuffer.allocateDirect(64);
        temp.order(ByteOrder.nativeOrder());
        GL11.glGetFloat(GL11.GL_MODELVIEW_MATRIX, (FloatBuffer)temp.asFloatBuffer());
        temp.asFloatBuffer().get(Minv);

        GL11.glLoadIdentity();
        GL11.glTranslatef(0.0f,0.0f,z);

        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);

        // Transform The Lightposition Into Object Coordinates:
        l[0]=lightPosition[0];
        l[1]=lightPosition[1];
        l[2]=lightPosition[2];
        l[3]=1.0f;                                          // Homogenous Coordinate
        VMatMult(Minv,l);

    /*  PASS#1: Use Texture "Bump"
                No Blend
                No Lighting
                No Offset Texture-Coordinates */
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, bump[filter]);
        GL11.glDisable(GL11.GL_BLEND);
        GL11.glDisable(GL11.GL_LIGHTING);
        doCube();

    /* PASS#2:  Use Texture "Invbump"
                Blend GL_ONE To GL_ONE
                No Lighting
                Offset Texture Coordinates
                */
        GL11.glBindTexture(GL11.GL_TEXTURE_2D,invbump[filter]);
        GL11.glBlendFunc(GL11.GL_ONE,GL11.GL_ONE);
        GL11.glDepthFunc(GL11.GL_LEQUAL);
        GL11.glEnable(GL11.GL_BLEND);

        GL11.glBegin(GL11.GL_QUADS);
            // Front Face
            n[0]=0.0f;      n[1]=0.0f;      n[2]=1.0f;
            s[0]=1.0f;      s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=0; i<4; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                GL11.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Back Face
            n[0]=0.0f;      n[1]=0.0f;      n[2]=-1.0f;
            s[0]=-1.0f;     s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=4; i<8; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                GL11.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Top Face
            n[0]=0.0f;      n[1]=1.0f;      n[2]=0.0f;
            s[0]=1.0f;      s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=0.0f;      t[2]=-1.0f;
            for (i=8; i<12; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                GL11.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Bottom Face
            n[0]=0.0f;      n[1]=-1.0f;     n[2]=0.0f;
            s[0]=-1.0f;     s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=0.0f;      t[2]=-1.0f;
            for (i=12; i<16; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                GL11.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Right Face
            n[0]=1.0f;      n[1]=0.0f;      n[2]=0.0f;
            s[0]=0.0f;      s[1]=0.0f;      s[2]=-1.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=16; i<20; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                GL11.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Left Face
            n[0]=-1.0f;     n[1]=0.0f;      n[2]=0.0f;
            s[0]=0.0f;      s[1]=0.0f;      s[2]=1.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=20; i<24; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                GL11.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
        GL11.glEnd();

    /* PASS#3:  Use Texture "Base"
                Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
                Lighting Enabled
                No Offset Texture-Coordinates
                */
        if (!emboss) {
            GL11.glTexEnvf (GL11.GL_TEXTURE_ENV, GL11.GL_TEXTURE_ENV_MODE, GL11.GL_MODULATE);
            GL11.glBindTexture(GL11.GL_TEXTURE_2D,texture[filter]);
            GL11.glBlendFunc(GL11.GL_DST_COLOR,GL11.GL_SRC_COLOR);
            GL11.glEnable(GL11.GL_LIGHTING);
            doCube();
        }

        xrot+=xspeed;
        yrot+=yspeed;
        if (xrot>360.0f) xrot-=360.0f;
        if (xrot<0.0f) xrot+=360.0f;
        if (yrot>360.0f) yrot-=360.0f;
        if (yrot<0.0f) yrot+=360.0f;

    /*  LAST PASS:  Do The Logos! */
        doLogo();
    }

    private void doMesh2TexelUnits() {

        float c[]={0.0f,0.0f,0.0f,1.0f};                 // holds current vertex
        float n[]={0.0f,0.0f,0.0f,1.0f};                 // normalized normal of current surface
        float s[]={0.0f,0.0f,0.0f,1.0f};                 // s-texture coordinate direction, normalized
        float t[]={0.0f,0.0f,0.0f,1.0f};                 // t-texture coordinate direction, normalized
        float l[] = new float[4];                                       // holds our lightposition to be transformed into object space
        float Minv[] = new float[16];                                   // holds the inverted modelview matrix to do so.
        int i;

        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer

        // Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With One glLoadIdentity();
        // Simply Build It By Doing All Transformations Negated And In Reverse Order.
        GL11.glLoadIdentity();
        GL11.glRotatef(-yrot,0.0f,1.0f,0.0f);
        GL11.glRotatef(-xrot,1.0f,0.0f,0.0f);
        GL11.glTranslatef(0.0f,0.0f,-z);

        ByteBuffer temp = ByteBuffer.allocateDirect(64);
        temp.order(ByteOrder.nativeOrder());
        GL11.glGetFloat(GL11.GL_MODELVIEW_MATRIX, (FloatBuffer)temp.asFloatBuffer().put(Minv).flip());

        GL11.glLoadIdentity();
        GL11.glTranslatef(0.0f,0.0f,z);

        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);

        // Transform The Lightposition Into Object Coordinates:
        l[0]=lightPosition[0];
        l[1]=lightPosition[1];
        l[2]=lightPosition[2];
        l[3]=1.0f;                                          // Homogenous Coordinate
        VMatMult(Minv,l);

    /*  PASS#1: Texel-Unit 0:   Use Texture "Bump"
                                No Blend
                                No Lighting
                                No Offset Texture-Coordinates
                                Texture-Operation "Replace"
                Texel-Unit 1:   Use Texture "Invbump"
                                No Lighting
                                Offset Texture Coordinates
                                Texture-Operation "Replace"
    */
        // TEXTURE-UNIT #0
        ARBMultitexture.glActiveTextureARB(ARBMultitexture.GL_TEXTURE0_ARB);
        GL11.glEnable(GL11.GL_TEXTURE_2D);
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, bump[filter]);
        GL11.glTexEnvf (GL11.GL_TEXTURE_ENV, GL11.GL_TEXTURE_ENV_MODE, EXTTextureEnvCombine.GL_COMBINE_EXT);
        GL11.glTexEnvf (GL11.GL_TEXTURE_ENV, EXTTextureEnvCombine.GL_COMBINE_RGB_EXT, GL11.GL_REPLACE);
        // TEXTURE-UNIT #1:
        ARBMultitexture.glActiveTextureARB(ARBMultitexture.GL_TEXTURE1_ARB);
        GL11.glEnable(GL11.GL_TEXTURE_2D);
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, invbump[filter]);
        GL11.glTexEnvf (GL11.GL_TEXTURE_ENV, GL11.GL_TEXTURE_ENV_MODE, EXTTextureEnvCombine.GL_COMBINE_EXT);
        GL11.glTexEnvf (GL11.GL_TEXTURE_ENV, EXTTextureEnvCombine.GL_COMBINE_RGB_EXT, GL11.GL_ADD);
        // General Switches:
        GL11.glDisable(GL11.GL_BLEND);
        GL11.glDisable(GL11.GL_LIGHTING);
        GL11.glBegin(GL11.GL_QUADS);
            // Front Face
            n[0]=0.0f;      n[1]=0.0f;      n[2]=1.0f;
            s[0]=1.0f;      s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=0; i<4; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Back Face
            n[0]=0.0f;      n[1]=0.0f;      n[2]=-1.0f;
            s[0]=-1.0f;     s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=4; i<8; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Top Face
            n[0]=0.0f;      n[1]=1.0f;      n[2]=0.0f;
            s[0]=1.0f;      s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=0.0f;      t[2]=-1.0f;
            for (i=8; i<12; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Bottom Face
            n[0]=0.0f;      n[1]=-1.0f;     n[2]=0.0f;
            s[0]=-1.0f;     s[1]=0.0f;      s[2]=0.0f;
            t[0]=0.0f;      t[1]=0.0f;      t[2]=-1.0f;
            for (i=12; i<16; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Right Face
            n[0]=1.0f;      n[1]=0.0f;      n[2]=0.0f;
            s[0]=0.0f;      s[1]=0.0f;      s[2]=-1.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=16; i<20; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
            // Left Face
            n[0]=-1.0f;     n[1]=0.0f;      n[2]=0.0f;
            s[0]=0.0f;      s[1]=0.0f;      s[2]=1.0f;
            t[0]=0.0f;      t[1]=1.0f;      t[2]=0.0f;
            for (i=20; i<24; i++) {
                c[0]=data[5*i+2];
                c[1]=data[5*i+3];
                c[2]=data[5*i+4];
                setUpBumps(n,c,l,s,t);
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
                ARBMultitexture.glMultiTexCoord2fARB(ARBMultitexture.GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
                GL11.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
            }
        GL11.glEnd();

    /* PASS#2   Use Texture "Base"
                Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
                Lighting Enabled
                No Offset Texture-Coordinates
                */
        ARBMultitexture.glActiveTextureARB(ARBMultitexture.GL_TEXTURE1_ARB);
        GL11.glDisable(GL11.GL_TEXTURE_2D);
        ARBMultitexture.glActiveTextureARB(ARBMultitexture.GL_TEXTURE0_ARB);
        if (!emboss) {
            GL11.glTexEnvf (GL11.GL_TEXTURE_ENV, GL11.GL_TEXTURE_ENV_MODE, GL11.GL_MODULATE);
            GL11.glBindTexture(GL11.GL_TEXTURE_2D,texture[filter]);
            GL11.glBlendFunc(GL11.GL_DST_COLOR,GL11.GL_SRC_COLOR);
            GL11.glEnable(GL11.GL_BLEND);
            GL11.glEnable(GL11.GL_LIGHTING);
            doCube();
        }

        xrot+=xspeed;
        yrot+=yspeed;
        if (xrot>360.0f) xrot-=360.0f;
        if (xrot<0.0f) xrot+=360.0f;
        if (yrot>360.0f) yrot-=360.0f;
        if (yrot<0.0f) yrot+=360.0f;

    /* LAST PASS:   Do The Logos! */
        doLogo();
    }
    private void doMeshNoBumps() {

        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
        GL11.glLoadIdentity();                                   // Reset The View
        GL11.glTranslatef(0.0f,0.0f,z);

        GL11.glRotatef(xrot,1.0f,0.0f,0.0f);
        GL11.glRotatef(yrot,0.0f,1.0f,0.0f);
        if (useMultitexture) {
            ARBMultitexture.glActiveTextureARB(ARBMultitexture.GL_TEXTURE1_ARB);
            GL11.glDisable(GL11.GL_TEXTURE_2D);
            ARBMultitexture.glActiveTextureARB(ARBMultitexture.GL_TEXTURE0_ARB);
        }
        GL11.glDisable(GL11.GL_BLEND);
        GL11.glBindTexture(GL11.GL_TEXTURE_2D,texture[filter]);
        GL11.glBlendFunc(GL11.GL_DST_COLOR, GL11.GL_SRC_COLOR);
        GL11.glEnable(GL11.GL_LIGHTING);
        doCube();

        xrot+=xspeed;
        yrot+=yspeed;
        if (xrot>360.0f) {
            xrot-=360.0f;
        }
        if (xrot<0.0f) {
            xrot+=360.0f;
        }
        if (yrot>360.0f) {
            yrot-=360.0f;
        }
        if (yrot<0.0f) {
            yrot+=360.0f;
        }

    /* LAST PASS:   Do The Logos! */
        doLogo();
    }

    private void cleanup() {
        Display.destroy();
    }

    private void loadTextures() {                                   // Load Bitmaps And Convert To Textures
        texture = loadMipMappedTexture("Data/Base.bmp");
        bump = loadBumpMappedTexture("Data/Bump.bmp");
        invbump = loadInverseBumpMappedTexture("Data/Bump.bmp");
        glLogo = loadAlphaTexture("Data/OpenGL_ALPHA.bmp", "Data/OpenGL.bmp");
        multiLogo = loadAlphaTexture("Data/Multi_On_Alpha.bmp", "Data/Multi_On.bmp");
    }

    /**
     * Texture loading directly from LWJGL examples
     */
    private final int loadAlphaTexture(String pathAlpha, String path) {
        IntBuffer image = ByteBuffer.allocateDirect(8).order(ByteOrder.nativeOrder()).asIntBuffer();
        IL.ilGenImages(2, image);
        IL.ilBindImage(image.get(0));
        IL.ilLoadImage(pathAlpha);
        IL.ilConvertImage(IL.IL_RGB, IL.IL_BYTE);

        ByteBuffer temp = IL.ilGetData();
        byte data[] = new byte[IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * 3];
        temp.get(data);
        byte alpha[] = new byte[4 * IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT)];
        for (int i=0; i<IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT); i++) {
            alpha[4*i+3]=data[i*3];                  // Pick Only Red Value As Alpha!
        }

        IL.ilBindImage(image.get(1));
        IL.ilLoadImage(pathAlpha);
        IL.ilConvertImage(IL.IL_RGB, IL.IL_BYTE);

        temp = IL.ilGetData();
        data = new byte[IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * 3];
        temp.get(data);
        for (int i=0; i<IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT); i++) {
            alpha[4*i]=data[i*3];                    // R
            alpha[4*i+1]=data[i*3+1];                // G
            alpha[4*i+2]=data[i*3+2];                // B
        }

        // Put Image In Memory
        ByteBuffer scratch = ByteBuffer.allocateDirect(4 * IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT));

        scratch.clear();
        scratch.put(alpha);
        scratch.rewind();

        // Create A IntBuffer For Image Address In Memory
        IntBuffer buf = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        GL11.glGenTextures(buf); // Create Texture In OpenGL

        GL11.glBindTexture(GL11.GL_TEXTURE_2D, buf.get(0));
        // Typical Texture Generation Using Data From The Image

        // Linear Filtering
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        // Linear Filtering
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR);
        // Generate The Texture
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RGBA8, IL.ilGetInteger(IL.IL_IMAGE_WIDTH),
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 0, GL11.GL_RGBA, GL11.GL_UNSIGNED_BYTE, scratch);

        return buf.get(0); // Return Image Address In Memory
    }
    /**
     * Texture loading directly from LWJGL examples
     */
    private int[] loadMipMappedTexture(String path) {
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
        GLU.gluBuild2DMipmaps(GL11.GL_TEXTURE_2D, GL11.GL_RGB, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

      return new int[]{ buf.get(0), buf.get(1), buf.get(2) };     // Return Image Addresses In Memory
    }
    /**
     * Texture loading directly from LWJGL examples
     */
    private int[] loadBumpMappedTexture(String path) {
        IntBuffer image = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        IL.ilGenImages(1, image);
        IL.ilBindImage(image.get(0));
        IL.ilLoadImage(path);
        IL.ilConvertImage(IL.IL_RGB, IL.IL_BYTE);
        ByteBuffer scratch = ByteBuffer.allocateDirect(IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * 3);
        IL.ilCopyPixels(0, 0, 0, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 1, IL.IL_RGB, IL.IL_BYTE, scratch);

        GL11.glPixelTransferf(GL11.GL_RED_SCALE, 0.5f);                        // Scale RGB By 50%, So That We Have Only
        GL11.glPixelTransferf(GL11.GL_GREEN_SCALE, 0.5f);                      // Half Intenstity
        GL11.glPixelTransferf(GL11.GL_BLUE_SCALE, 0.5f);

        ByteBuffer temp = ByteBuffer.allocateDirect(16);
        temp.order(ByteOrder.nativeOrder());

        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_S, GL11.GL_CLAMP);  // No Wrapping, Please!
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_T, GL11.GL_CLAMP);
        GL11.glTexParameter(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_BORDER_COLOR, (FloatBuffer)temp.asFloatBuffer().put(gray).flip());

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
        GLU.gluBuild2DMipmaps(GL11.GL_TEXTURE_2D, GL11.GL_RGB, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

        GL11.glPixelTransferf(GL11.GL_RED_SCALE, 1.0f);                // Scale RGB Back To 100% Again
        GL11.glPixelTransferf(GL11.GL_GREEN_SCALE, 1.0f);
        GL11.glPixelTransferf(GL11.GL_BLUE_SCALE, 1.0f);

        return new int[]{ buf.get(0), buf.get(1), buf.get(2) };     // Return Image Addresses In Memory
    }
    /**
     * Texture loading directly from LWJGL examples
     */
    private int[] loadInverseBumpMappedTexture(String path) {
        IntBuffer image = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asIntBuffer();
        IL.ilGenImages(1, image);
        IL.ilBindImage(image.get(0));
        IL.ilLoadImage(path);
        IL.ilConvertImage(IL.IL_RGB, IL.IL_BYTE);
        ByteBuffer scratch = ByteBuffer.allocateDirect(IL.ilGetInteger(IL.IL_IMAGE_WIDTH) * IL.ilGetInteger(IL.IL_IMAGE_HEIGHT) * 3);
        IL.ilCopyPixels(0, 0, 0, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), 1, IL.IL_RGB, IL.IL_BYTE, scratch);

        GL11.glPixelTransferf(GL11.GL_RED_SCALE, 0.5f);                        // Scale RGB By 50%, So That We Have Only
        GL11.glPixelTransferf(GL11.GL_GREEN_SCALE, 0.5f);                      // Half Intenstity
        GL11.glPixelTransferf(GL11.GL_BLUE_SCALE, 0.5f);

        ByteBuffer temp = ByteBuffer.allocateDirect(16);
        temp.order(ByteOrder.nativeOrder());

        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_S, GL11.GL_CLAMP);  // No Wrapping, Please!
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_T, GL11.GL_CLAMP);
        GL11.glTexParameter(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_BORDER_COLOR, (FloatBuffer)temp.asFloatBuffer().put(gray).flip());

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
        GLU.gluBuild2DMipmaps(GL11.GL_TEXTURE_2D, GL11.GL_RGB, IL.ilGetInteger(IL.IL_IMAGE_WIDTH), 
                IL.ilGetInteger(IL.IL_IMAGE_HEIGHT), GL11.GL_RGB, GL11.GL_UNSIGNED_BYTE, scratch);

        GL11.glPixelTransferf(GL11.GL_RED_SCALE, 1.0f);                // Scale RGB Back To 100% Again
        GL11.glPixelTransferf(GL11.GL_GREEN_SCALE, 1.0f);
        GL11.glPixelTransferf(GL11.GL_BLUE_SCALE, 1.0f);

        return new int[]{ buf.get(0), buf.get(1), buf.get(2) };     // Return Image Addresses In Memory
    }
}

class MessageBox extends JDialog implements ActionListener {
    private static MessageBox instance = null;

    private JPanel mainPanel = new JPanel(new BorderLayout());
    private JTextArea msg = new JTextArea();
    private JScrollPane msgPane = new JScrollPane(msg, ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED, ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);
    private JPanel buttonPanel = new JPanel(new FlowLayout());
    private JButton ok = new JButton("OK");

    private MessageBox(String title) {
        super(new JDialog(), title, true);
        setSize(400, 300);
        getContentPane().add(mainPanel, BorderLayout.CENTER);
        mainPanel.add(msgPane, BorderLayout.CENTER);
        mainPanel.add(buttonPanel, BorderLayout.SOUTH);
        buttonPanel.add(ok);
        ok.addActionListener(this);
    }
    public static void showMessage(String message, String title) {
        instance = new MessageBox(title);
        instance.msg.setText(message);
        instance.ok.requestFocus(true);
        instance.show();
        instance = null;
    }

    public void actionPerformed(ActionEvent e) {
        if(e.getSource().equals(ok)) {
            instance.hide();
        }
    }
}