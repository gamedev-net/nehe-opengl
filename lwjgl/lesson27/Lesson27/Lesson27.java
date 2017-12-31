/*
 *      This Code Was Created By Jeff Molofee and GB Schmick 2000
 *      A HUGE Thanks To Fredric Echols For Cleaning Up
 *      And Optimizing The Base Code, Making It More Flexible!
 *      If You've Found This Code Useful, Please Let Me Know.
 *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
 */

import java.io.FileReader;
import java.io.StreamTokenizer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.glu.GLU;
import org.lwjgl.opengl.glu.Sphere;
import org.lwjgl.input.Keyboard;

/**
 * @author Mark Bernard
 * date:    7-Aug-2004
 *
 * Port of NeHe's Lesson 27 to LWJGL
 * Title: Shadows
 * Uses version 0.9alpha of LWJGL http://www.lwjgl.org/
 *
 * Be sure that the LWJGL libraries are in your classpath
 *
 * Ported directly from the C++ version
 *
 * 2004-10-08: Updated to version 0.92alpha of LWJGL.
 * 2004-12-19: Updated to version 0.94alpha of LWJGL.
 */
public class Lesson27 {
    private boolean done = false;
    private boolean fullscreen = false;
    private final String windowTitle = "NeHe's OpenGL Lesson 27 for LWJGL (Shadows)";
    private boolean f1 = false; // F1 key pressed
    private DisplayMode displayMode;

//    typedef float GLvector4f[4];                            // Typedef's For VMatMult Procedure
//    typedef float GLmatrix16f[16];                          // Typedef's For VMatMult Procedure

    GlObject obj;                                        // Object
    float xrot=0, xspeed=0;                           // X Rotation & X Speed
    float yrot=0, yspeed=0;                           // Y Rotation & Y Speed

    float lightPos[] = { 0.0f, 5.0f,-4.0f, 1.0f};           // Light Position
    float lightAmb[] = { 0.2f, 0.2f, 0.2f, 1.0f};           // Ambient Light Values
    float lightDif[] = { 0.6f, 0.6f, 0.6f, 1.0f};           // Diffuse Light Values
    float lightSpc[] = {-0.2f, -0.2f, -0.2f, 1.0f};         // Specular Light Values
    ByteBuffer byteBuffer;
    ByteBuffer floatBuffer;
    float matAmb[] = {0.4f, 0.4f, 0.4f, 1.0f};              // Material - Ambient Values
    float matDif[] = {0.2f, 0.6f, 0.9f, 1.0f};              // Material - Diffuse Values
    float matSpc[] = {0.0f, 0.0f, 0.0f, 1.0f};              // Material - Specular Values
    float matShn[] = {0.0f, 0.0f, 0.0f, 0.0f};                                // Material - Shininess

    float objPos[] = {-2.0f,-2.0f,-5.0f};                   // Object Position

//    GLUquadricObj   *q;                                     // Quadratic For Drawing A Sphere
    Sphere q;
    float spherePos[] = {-4.0f,-5.0f,-6.0f};

    public static void main(String args[]) {
        boolean fullscreen = false;
        if(args.length>0) {
            if(args[0].equalsIgnoreCase("fullscreen")) {
                fullscreen = true;
            }
        }

        Lesson27 l27 = new Lesson27();
        l27.run(fullscreen);
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

        // Spin Object
        if(Keyboard.isKeyDown(Keyboard.KEY_LEFT)) {
            yspeed -= 0.1f;                 // 'Arrow Left' Decrease yspeed
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_RIGHT)) {
            yspeed += 0.1f;                 // 'Arrow Right' Increase yspeed
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_UP)) {
            xspeed -= 0.1f;                 // 'Arrow Up' Decrease xspeed
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_DOWN)) {
            xspeed += 0.1f;                 // 'Arrow Down' Increase xspeed
        }

        // Adjust Light's Position
        if(Keyboard.isKeyDown(Keyboard.KEY_L)) {
            lightPos[0] += 0.05f;                // 'L' Moves Light Right
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_J)) {
            lightPos[0] -= 0.05f;                // 'J' Moves Light Left
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_I)) {
            lightPos[1] += 0.05f;                // 'I' Moves Light Up
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_K)) {
            lightPos[1] -= 0.05f;                // 'K' Moves Light Down
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_O)) {
            lightPos[2] += 0.05f;                // 'O' Moves Light Toward Viewer
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_U)) {
            lightPos[2] -= 0.05f;                // 'U' Moves Light Away From Viewer
        }

        // Adjust Object's Position
        if(Keyboard.isKeyDown(Keyboard.KEY_NUMPAD6)) {
            objPos[0] += 0.05f;           // 'Numpad6' Move Object Right
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_NUMPAD4)) {
            objPos[0] -= 0.05f;           // 'Numpad4' Move Object Left
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_NUMPAD8)) {
            objPos[1] += 0.05f;           // 'Numpad8' Move Object Up
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_NUMPAD5)) {
            objPos[1] -= 0.05f;           // 'Numpad5' Move Object Down
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_NUMPAD9)) {
            objPos[2] += 0.05f;           // 'Numpad9' Move Object Toward Viewer
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_NUMPAD7)) {
            objPos[2] -= 0.05f;           // 'Numpad7' Move Object Away From Viewer
        }

        // Adjust Ball's Position
        if(Keyboard.isKeyDown(Keyboard.KEY_D)) {
            spherePos[0] += 0.05f;               // 'D' Move Ball Right
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_A)) {
            spherePos[0] -= 0.05f;               // 'A' Move Ball Left
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_W)) {
            spherePos[1] += 0.05f;               // 'W' Move Ball Up
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_S)) {
            spherePos[1] -= 0.05f;               // 'S' Move Ball Down
        }

        if(Keyboard.isKeyDown(Keyboard.KEY_E)) {
            spherePos[2] += 0.05f;               // 'E' Move Ball Toward Viewer
        }
        if(Keyboard.isKeyDown(Keyboard.KEY_Q)) {
            spherePos[2] -= 0.05f;               // 'Q' Move Ball Away From Viewer
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
        initGLObjects();
        int width = 640;
        int height = 480;
        GL11.glShadeModel(GL11.GL_SMOOTH);                            // Enable Smooth Shading
        GL11.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);               // Black Background
        GL11.glClearDepth(1.0f);                                 // Depth Buffer Setup
        GL11.glClearStencil(0);                                  // Stencil Buffer Setup
        GL11.glEnable(GL11.GL_DEPTH_TEST);                            // Enables Depth Testing
        GL11.glDepthFunc(GL11.GL_LEQUAL);                             // The Type Of Depth Testing To Do
        GL11.glHint(GL11.GL_PERSPECTIVE_CORRECTION_HINT, GL11.GL_NICEST);  // Really Nice Perspective Calculations

        floatBuffer = ByteBuffer.allocateDirect(64);
        floatBuffer.order(ByteOrder.nativeOrder());
        byteBuffer = ByteBuffer.allocateDirect(16);
        byteBuffer.order(ByteOrder.nativeOrder());
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_POSITION, (FloatBuffer)byteBuffer.asFloatBuffer().put(lightPos).flip());        // Set Light1 Position
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_AMBIENT, (FloatBuffer)byteBuffer.asFloatBuffer().put(lightAmb).flip());         // Set Light1 Ambience
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_DIFFUSE, (FloatBuffer)byteBuffer.asFloatBuffer().put(lightDif).flip());         // Set Light1 Diffuse
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_SPECULAR, (FloatBuffer)byteBuffer.asFloatBuffer().put(lightSpc).flip());        // Set Light1 Specular
        GL11.glEnable(GL11.GL_LIGHT1);                                // Enable Light1
        GL11.glEnable(GL11.GL_LIGHTING);                              // Enable Lighting

        GL11.glMaterial(GL11.GL_FRONT, GL11.GL_AMBIENT, (FloatBuffer)byteBuffer.asFloatBuffer().put(matAmb).flip());         // Set Material Ambience
        GL11.glMaterial(GL11.GL_FRONT, GL11.GL_DIFFUSE, (FloatBuffer)byteBuffer.asFloatBuffer().put(matDif).flip());         // Set Material Diffuse
        GL11.glMaterial(GL11.GL_FRONT, GL11.GL_SPECULAR, (FloatBuffer)byteBuffer.asFloatBuffer().put(matSpc).flip());        // Set Material Specular
        GL11.glMaterial(GL11.GL_FRONT, GL11.GL_SHININESS, (FloatBuffer)byteBuffer.asFloatBuffer().put(matShn).flip());       // Set Material Shininess

        GL11.glCullFace(GL11.GL_BACK);                                // Set Culling Face To Back Face
        GL11.glEnable(GL11.GL_CULL_FACE);                             // Enable Culling
        GL11.glClearColor(0.1f, 1.0f, 0.5f, 1.0f);               // Set Clear Color (Greenish Color)

        q = new Sphere();                               // Initialize Quadratic
        q.setNormals(GL11.GL_SMOOTH);                   // Enable Smooth Normal Generation
        q.setTextureFlag(false);                        // Disable Auto Texture Coords

        GL11.glViewport(0,0,width,height);                           // Reset The Current Viewport

        GL11.glMatrixMode(GL11.GL_PROJECTION);                            // Select The Projection Matrix
        GL11.glLoadIdentity();                                       // Reset The Projection Matrix

        // Calculate The Aspect Ratio Of The Window
        GLU.gluPerspective(45.0f,
                (float) displayMode.getWidth() / (float) displayMode.getHeight(),
                0.1f,100.0f);

        GL11.glMatrixMode(GL11.GL_MODELVIEW);                             // Select The Modelview Matrix
        GL11.glLoadIdentity();                                       // Reset The Modelview Matrix
    }

    private void vMatMult(float M[], float v[]) {
        float res[] = new float[4];                                     // Hold Calculated Results
        res[0]=M[ 0]*v[0]+M[ 4]*v[1]+M[ 8]*v[2]+M[12]*v[3];
        res[1]=M[ 1]*v[0]+M[ 5]*v[1]+M[ 9]*v[2]+M[13]*v[3];
        res[2]=M[ 2]*v[0]+M[ 6]*v[1]+M[10]*v[2]+M[14]*v[3];
        res[3]=M[ 3]*v[0]+M[ 7]*v[1]+M[11]*v[2]+M[15]*v[3];
        v[0]=res[0];                                        // Results Are Stored Back In v[]
        v[1]=res[1];
        v[2]=res[2];
        v[3]=res[3];                                        // Homogenous Coordinate
    }

    private void initGLObjects() {                                     // Initialize Objects
        obj = new GlObject();

        readObject("Data/Object.txt", obj);          // Read Object2 Into obj

        setConnectivity(obj);                              // Set Face To Face Connectivity

        for (int i=0;i<obj.nPlanes;i++) {           // Loop Through All Object Planes
            calcPlane(obj, obj.planes[i]);               // Compute Plane Equations For All Faces
        }
    }

    private void drawGLRoom() {                                      // Draw The Room (Box)
        GL11.glBegin(GL11.GL_QUADS);                                  // Begin Drawing Quads
            // Floor
            GL11.glNormal3f(0.0f, 1.0f, 0.0f);                   // Normal Pointing Up
            GL11.glVertex3f(-10.0f,-10.0f,-20.0f);               // Back Left
            GL11.glVertex3f(-10.0f,-10.0f, 20.0f);               // Front Left
            GL11.glVertex3f( 10.0f,-10.0f, 20.0f);               // Front Right
            GL11.glVertex3f( 10.0f,-10.0f,-20.0f);               // Back Right
            // Ceiling
            GL11.glNormal3f(0.0f,-1.0f, 0.0f);                   // Normal Point Down
            GL11.glVertex3f(-10.0f, 10.0f, 20.0f);               // Front Left
            GL11.glVertex3f(-10.0f, 10.0f,-20.0f);               // Back Left
            GL11.glVertex3f( 10.0f, 10.0f,-20.0f);               // Back Right
            GL11.glVertex3f( 10.0f, 10.0f, 20.0f);               // Front Right
            // Front Wall
            GL11.glNormal3f(0.0f, 0.0f, 1.0f);                   // Normal Pointing Away From Viewer
            GL11.glVertex3f(-10.0f, 10.0f,-20.0f);               // Top Left
            GL11.glVertex3f(-10.0f,-10.0f,-20.0f);               // Bottom Left
            GL11.glVertex3f( 10.0f,-10.0f,-20.0f);               // Bottom Right
            GL11.glVertex3f( 10.0f, 10.0f,-20.0f);               // Top Right
            // Back Wall
            GL11.glNormal3f(0.0f, 0.0f,-1.0f);                   // Normal Pointing Towards Viewer
            GL11.glVertex3f( 10.0f, 10.0f, 20.0f);               // Top Right
            GL11.glVertex3f( 10.0f,-10.0f, 20.0f);               // Bottom Right
            GL11.glVertex3f(-10.0f,-10.0f, 20.0f);               // Bottom Left
            GL11.glVertex3f(-10.0f, 10.0f, 20.0f);               // Top Left
            // Left Wall
            GL11.glNormal3f(1.0f, 0.0f, 0.0f);                   // Normal Pointing Right
            GL11.glVertex3f(-10.0f, 10.0f, 20.0f);               // Top Front
            GL11.glVertex3f(-10.0f,-10.0f, 20.0f);               // Bottom Front
            GL11.glVertex3f(-10.0f,-10.0f,-20.0f);               // Bottom Back
            GL11.glVertex3f(-10.0f, 10.0f,-20.0f);               // Top Back
            // Right Wall
            GL11.glNormal3f(-1.0f, 0.0f, 0.0f);                  // Normal Pointing Left
            GL11.glVertex3f( 10.0f, 10.0f,-20.0f);               // Top Back
            GL11.glVertex3f( 10.0f,-10.0f,-20.0f);               // Bottom Back
            GL11.glVertex3f( 10.0f,-10.0f, 20.0f);               // Bottom Front
            GL11.glVertex3f( 10.0f, 10.0f, 20.0f);               // Top Front
        GL11.glEnd();                                            // Done Drawing Quads
    }

    private void render() {
        float Minv[] = new float[16];
        float wlp[] = new float[4];
        float lp[] = new float[4];

        // Clear Color Buffer, Depth Buffer, Stencil Buffer
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_DEPTH_BUFFER_BIT | GL11.GL_STENCIL_BUFFER_BIT);

        GL11.glLoadIdentity();                                   // Reset Modelview Matrix
        GL11.glTranslatef(0.0f, 0.0f, -20.0f);                   // Zoom Into Screen 20 Units
        GL11.glLight(GL11.GL_LIGHT1, GL11.GL_POSITION, (FloatBuffer)byteBuffer.asFloatBuffer().put(lightPos).flip());        // Position Light1
        GL11.glTranslatef(spherePos[0], spherePos[1], spherePos[2]); // Position The Sphere
        q.draw(1.5f, 32, 16);                         // Draw A Sphere

        // calculate light's position relative to local coordinate system
        // dunno if this is the best way to do it, but it actually works
        // if u find another aproach, let me know ;)

        // we build the inversed matrix by doing all the actions in reverse order
        // and with reverse parameters (notice -xrot, -yrot, -ObjPos[], etc.)
        GL11.glLoadIdentity();                                   // Reset Matrix
        GL11.glRotatef(-yrot, 0.0f, 1.0f, 0.0f);                 // Rotate By -yrot On Y Axis
        GL11.glRotatef(-xrot, 1.0f, 0.0f, 0.0f);                 // Rotate By -xrot On X Axis
        GL11.glGetFloat(GL11.GL_MODELVIEW_MATRIX,(FloatBuffer)floatBuffer.asFloatBuffer().put(Minv).flip());              // Retrieve ModelView Matrix (Stores In Minv)
        lp[0] = lightPos[0];                                // Store Light Position X In lp[0]
        lp[1] = lightPos[1];                                // Store Light Position Y In lp[1]
        lp[2] = lightPos[2];                                // Store Light Position Z In lp[2]
        lp[3] = lightPos[3];                                // Store Light Direction In lp[3]
        vMatMult(Minv, lp);                                 // We Store Rotated Light Vector In 'lp' Array
        GL11.glTranslatef(-objPos[0], -objPos[1], -objPos[2]);   // Move Negative On All Axis Based On ObjPos[] Values (X, Y, Z)
        GL11.glGetFloat(GL11.GL_MODELVIEW_MATRIX,(FloatBuffer)floatBuffer.asFloatBuffer().put(Minv).flip());              // Retrieve ModelView Matrix From Minv
        wlp[0] = 0.0f;                                      // World Local Coord X To 0
        wlp[1] = 0.0f;                                      // World Local Coord Y To 0
        wlp[2] = 0.0f;                                      // World Local Coord Z To 0
        wlp[3] = 1.0f;
        vMatMult(Minv, wlp);                                // We Store The Position Of The World Origin Relative To The
                                                            // Local Coord. System In 'wlp' Array
        lp[0] += wlp[0];                                    // Adding These Two Gives Us The
        lp[1] += wlp[1];                                    // Position Of The Light Relative To
        lp[2] += wlp[2];                                    // The Local Coordinate System

        GL11.glColor4f(0.7f, 0.4f, 0.0f, 1.0f);                  // Set Color To An Orange
        GL11.glLoadIdentity();                                   // Reset Modelview Matrix
        GL11.glTranslatef(0.0f, 0.0f, -20.0f);                   // Zoom Into The Screen 20 Units
        drawGLRoom();                                       // Draw The Room
        GL11.glTranslatef(objPos[0], objPos[1], objPos[2]);      // Position The Object
        GL11.glRotatef(xrot, 1.0f, 0.0f, 0.0f);                  // Spin It On The X Axis By xrot
        GL11.glRotatef(yrot, 0.0f, 1.0f, 0.0f);                  // Spin It On The Y Axis By yrot
        drawGLObject(obj);                                  // Procedure For Drawing The Loaded Object
        castShadow(obj, lp);                               // Procedure For Casting The Shadow Based On The Silhouette

        GL11.glColor4f(0.7f, 0.4f, 0.0f, 1.0f);                  // Set Color To Purplish Blue
        GL11.glDisable(GL11.GL_LIGHTING);                             // Disable Lighting
        GL11.glDepthMask(false);                              // Disable Depth Mask
        GL11.glTranslatef(lp[0], lp[1], lp[2]);                  // Translate To Light's Position
                                                            // Notice We're Still In Local Coordinate System
        q.draw(0.2f, 16, 8);                          // Draw A Little Yellow Sphere (Represents Light)
        GL11.glEnable(GL11.GL_LIGHTING);                              // Enable Lighting
        GL11.glDepthMask(true);                               // Enable Depth Mask

        xrot += xspeed;                                     // Increase xrot By xspeed
        yrot += yspeed;                                     // Increase yrot By yspeed

        GL11.glFlush();                                          // Flush The OpenGL Pipeline
    }

    private void cleanup() {
        Display.destroy();
    }

    private void readObject(String name, GlObject o) {
        try {
            StreamTokenizer in = new StreamTokenizer(new FileReader(name));
            in.nextToken();
            o.nPoints = (int)in.nval;
            for(int i=0;i<o.nPoints;i++) {
                in.nextToken();
                o.points[i].x = (float)in.nval;
                in.nextToken();
                o.points[i].y = (float)in.nval;
                in.nextToken();
                o.points[i].z = (float)in.nval;
            }
            in.nextToken();
            o.nPlanes = (int)in.nval;
            for(int i=0;i<o.nPlanes;i++) {
                in.nextToken();
                o.planes[i].p[0] = (int)in.nval;
                in.nextToken();
                o.planes[i].p[1] = (int)in.nval;
                in.nextToken();
                o.planes[i].p[2] = (int)in.nval;
                in.nextToken();
                o.planes[i].normals[0].x = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[0].y = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[0].z = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[1].x = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[1].y = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[1].z = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[2].x = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[2].y = (float)in.nval;
                in.nextToken();
                o.planes[i].normals[2].z = (float)in.nval;
            }
        }
        catch(Exception e) {
            e.printStackTrace();
        }
    }

//     connectivity procedure - based on Gamasutra's article
//     hard to explain here
    private void setConnectivity(GlObject o) {
        int p1i, p2i, p1j, p2j;
        int P1i, P2i, P1j, P2j;
        int i,j,ki,kj;

        for(i=0;i<o.nPlanes-1;i++) {
            for(j=i+1;j<o.nPlanes;j++) {
                for(ki=0;ki<3;ki++) {
                    if(o.planes[i].neigh[ki] != 0){
                        for(kj=0;kj<3;kj++){
                            p1i=ki;
                            p1j=kj;
                            p2i=(ki+1)%3;
                            p2j=(kj+1)%3;

                            p1i=o.planes[i].p[p1i];
                            p2i=o.planes[i].p[p2i];
                            p1j=o.planes[j].p[p1j];
                            p2j=o.planes[j].p[p2j];

                            P1i=((p1i+p2i)-Math.abs(p1i-p2i))/2;
                            P2i=((p1i+p2i)+Math.abs(p1i-p2i))/2;
                            P1j=((p1j+p2j)-Math.abs(p1j-p2j))/2;
                            P2j=((p1j+p2j)+Math.abs(p1j-p2j))/2;

                            if((P1i==P1j) && (P2i==P2j)){  //they are neighbours
                                o.planes[i].neigh[ki] = j+1;
                                o.planes[j].neigh[kj] = i+1;
                            }
                        }
                    }
                }
            }
        }
    }

//     function for computing a plane equation given 3 points
    private void calcPlane(GlObject o, Plane plane) {
        Point v[] = new Point[4];
        for(int i=0;i<4;i++) {
            v[i] = new Point();
        }

        for(int i=0;i<3;i++){
            v[i+1].x = o.points[plane.p[i]].x;
            v[i+1].y = o.points[plane.p[i]].y;
            v[i+1].z = o.points[plane.p[i]].z;
        }
        plane.planeEq.a = v[1].y*(v[2].z-v[3].z) + v[2].y*(v[3].z-v[1].z) + v[3].y*(v[1].z-v[2].z);
        plane.planeEq.b = v[1].z*(v[2].x-v[3].x) + v[2].z*(v[3].x-v[1].x) + v[3].z*(v[1].x-v[2].x);
        plane.planeEq.c = v[1].x*(v[2].y-v[3].y) + v[2].x*(v[3].y-v[1].y) + v[3].x*(v[1].y-v[2].y);
        plane.planeEq.d =-( v[1].x*(v[2].y*v[3].z - v[3].y*v[2].z) +
                          v[2].x*(v[3].y*v[1].z - v[1].y*v[3].z) +
                          v[3].x*(v[1].y*v[2].z - v[2].y*v[1].z) );
    }

//     procedure for drawing the object - very simple
    private void drawGLObject(GlObject o){
        GL11.glBegin(GL11.GL_TRIANGLES);
        for (int i=0; i<o.nPlanes; i++){
            for (int j=0; j<3; j++){
                GL11.glNormal3f(o.planes[i].normals[j].x,
                        o.planes[i].normals[j].y,
                        o.planes[i].normals[j].z);
                GL11.glVertex3f(o.points[o.planes[i].p[j]].x,
                        o.points[o.planes[i].p[j]].y,
                        o.points[o.planes[i].p[j]].z);
            }
        }
        GL11.glEnd();
    }

    private void castShadow(GlObject o, float lp[]){
        int i, j, k, jj;
        int p1, p2;
        Point v1 = new Point();
        Point v2 = new Point();
        float side;

        //set visual parameter
        for (i=0;i<o.nPlanes;i++){
            // chech to see if light is in front or behind the plane (face plane)
            side =  o.planes[i].planeEq.a*lp[0]+
                    o.planes[i].planeEq.b*lp[1]+
                    o.planes[i].planeEq.c*lp[2]+
                    o.planes[i].planeEq.d*lp[3];
            if (side >0) o.planes[i].visible = true;
                    else o.planes[i].visible = false;
        }

        GL11.glDisable(GL11.GL_LIGHTING);
        GL11.glDepthMask(false);
        GL11.glDepthFunc(GL11.GL_LEQUAL);

        GL11.glEnable(GL11.GL_STENCIL_TEST);
        GL11.glColorMask(false, false, false, false);
        GL11.glStencilFunc(GL11.GL_ALWAYS, 1, 0xffffffff);

        // first pass, stencil operation decreases stencil value
        GL11.glFrontFace(GL11.GL_CCW);
        GL11.glStencilOp(GL11.GL_KEEP, GL11.GL_KEEP, GL11.GL_INCR);
        for (i=0; i<o.nPlanes;i++){
            if (o.planes[i].visible)
                for (j=0;j<3;j++){
                    k = o.planes[i].neigh[j];
                    if ((k != 0) || (!o.planes[k-1].visible)){
                        // here we have an edge, we must draw a polygon
                        p1 = o.planes[i].p[j];
                        jj = (j+1)%3;
                        p2 = o.planes[i].p[jj];

                        //calculate the length of the vector
                        v1.x = (o.points[p1].x - lp[0])*100;
                        v1.y = (o.points[p1].y - lp[1])*100;
                        v1.z = (o.points[p1].z - lp[2])*100;

                        v2.x = (o.points[p2].x - lp[0])*100;
                        v2.y = (o.points[p2].y - lp[1])*100;
                        v2.z = (o.points[p2].z - lp[2])*100;

                        //draw the polygon
                        GL11.glBegin(GL11.GL_TRIANGLE_STRIP);
                            GL11.glVertex3f(o.points[p1].x,
                                        o.points[p1].y,
                                        o.points[p1].z);
                            GL11.glVertex3f(o.points[p1].x + v1.x,
                                        o.points[p1].y + v1.y,
                                        o.points[p1].z + v1.z);

                            GL11.glVertex3f(o.points[p2].x,
                                        o.points[p2].y,
                                        o.points[p2].z);
                            GL11.glVertex3f(o.points[p2].x + v2.x,
                                        o.points[p2].y + v2.y,
                                        o.points[p2].z + v2.z);
                        GL11.glEnd();
                    }
                }
        }

        // second pass, stencil operation increases stencil value
        GL11.glFrontFace(GL11.GL_CW);
        GL11.glStencilOp(GL11.GL_KEEP, GL11.GL_KEEP, GL11.GL_DECR);
        for (i=0; i<o.nPlanes;i++){
            if (o.planes[i].visible)
                for (j=0;j<3;j++){
                    k = o.planes[i].neigh[j];
                    if ((k != 0) || (!o.planes[k-1].visible)){
                        // here we have an edge, we must draw a polygon
                        p1 = o.planes[i].p[j];
                        jj = (j+1)%3;
                        p2 = o.planes[i].p[jj];

                        //calculate the length of the vector
                        v1.x = (o.points[p1].x - lp[0])*100;
                        v1.y = (o.points[p1].y - lp[1])*100;
                        v1.z = (o.points[p1].z - lp[2])*100;

                        v2.x = (o.points[p2].x - lp[0])*100;
                        v2.y = (o.points[p2].y - lp[1])*100;
                        v2.z = (o.points[p2].z - lp[2])*100;

                        //draw the polygon
                        GL11.glBegin(GL11.GL_TRIANGLE_STRIP);
                            GL11.glVertex3f(o.points[p1].x,
                                        o.points[p1].y,
                                        o.points[p1].z);
                            GL11.glVertex3f(o.points[p1].x + v1.x,
                                        o.points[p1].y + v1.y,
                                        o.points[p1].z + v1.z);

                            GL11.glVertex3f(o.points[p2].x,
                                        o.points[p2].y,
                                        o.points[p2].z);
                            GL11.glVertex3f(o.points[p2].x + v2.x,
                                        o.points[p2].y + v2.y,
                                        o.points[p2].z + v2.z);
                        GL11.glEnd();
                    }
                }
        }

        GL11.glFrontFace(GL11.GL_CCW);
        GL11.glColorMask(true, true, true, true);

        //draw a shadowing rectangle covering the entire screen
        GL11.glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
        GL11.glEnable(GL11.GL_BLEND);
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);
        GL11.glStencilFunc(GL11.GL_NOTEQUAL, 0, 0xffffffff);
        GL11.glStencilOp(GL11.GL_KEEP, GL11.GL_KEEP, GL11.GL_KEEP);
        GL11.glPushMatrix();
        GL11.glLoadIdentity();
        GL11.glBegin(GL11.GL_TRIANGLE_STRIP);
        GL11.glVertex3f(-0.1f, 0.1f,-0.10f);
        GL11.glVertex3f(-0.1f,-0.1f,-0.10f);
        GL11.glVertex3f( 0.1f, 0.1f,-0.10f);
        GL11.glVertex3f( 0.1f,-0.1f,-0.10f);
        GL11.glEnd();
        GL11.glPopMatrix();
        GL11.glDisable(GL11.GL_BLEND);

        GL11.glDepthFunc(GL11.GL_LEQUAL);
        GL11.glDepthMask(true);
        GL11.glEnable(GL11.GL_LIGHTING);
        GL11.glDisable(GL11.GL_STENCIL_TEST);
        GL11.glShadeModel(GL11.GL_SMOOTH);
    }
}

// vertex in 3d-coordinate system
class Point {
    float x, y, z;
}

// plane equation
class PlaneEq {
    float a, b, c, d;
}

// structure describing an object's face
class Plane {
    int p[];
    Point normals[];
    int neigh[];
    PlaneEq planeEq;
    boolean visible;

    public Plane() {
        p = new int[3];
        neigh = new int[3];
        normals = new Point[3];
        for(int i=0;i<3;i++) {
            normals[i] = new Point();
        }
        planeEq = new PlaneEq();
    }
}

// object structure
class GlObject {
    int nPlanes, nPoints;
    Point points[];
    Plane planes[];

    public GlObject() {
        points = new Point[100];
        planes = new Plane[200];
        for(int i=0;i<200;i++) {
            if(i<100) {
                points[i] = new Point();
            }
            planes[i] = new Plane();
        }
    }
}
