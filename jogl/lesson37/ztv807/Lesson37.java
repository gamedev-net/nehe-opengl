                  /*--.          .-"-.
                 /   o_O        / O o \
                 \_  (__\       \_ v _/
                 //   \\        //   \\
                ((     ))      ((     ))
 ¤¤¤¤¤¤¤¤¤¤¤¤¤¤--""---""--¤¤¤¤--""---""--¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
 ¤                 |||            |||                             ¤
 ¤                  |              |                              ¤
 ¤                                                                ¤
 ¤ Programmer:Abdul Bezrati                                       ¤
 ¤ Program   :Nehe's 37th lesson port to JOGL                     ¤
 ¤ Comments  :None                                                ¤
 ¤    _______                                                     ¤
 ¤  /` _____ `\;,    abezrati@hotmail.com                         ¤
 ¤ (__(^===^)__)';,                                 ___           ¤
 ¤   /  :::  \   ,;                               /^   ^\         ¤
 ¤  |   :::   | ,;'                              ( Ö   Ö )        ¤
 ¤¤¤'._______.'`¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤ --°oOo--(_)--oOo°--¤¤*/

import net.java.games.jogl.*;
import net.java.games.jogl.util.GLUT;
import java.util.StringTokenizer;
import java.awt.event.*;
import javax.swing.*;
import java.net.URL;
import java.awt.*;
import java.io.*;

public class Lesson37 implements KeyListener
{
  initRenderer      renderer;
  GLCanvas          canvas;
  Animator          loop;
  JFrame            frame;
  GLU               glu;
  GL                gl;

  boolean           outlineSmooth,                           // Flag To Anti-Alias The Lines ( NEW )
                    outlineDraw = true,                      // Flag To Draw The Outline ( NEW )
                    lightRotate = false,                     // Flag To See If We Rotate The Light ( NEW )
                    modelRotate = false,                     // Flag To Rotate The Model ( NEW )
                    keys[]      = new boolean[256],          // Array Used For The Keyboard Routine
                    light;                                   // Lighting ON/OFF
  // User Defined Variables
  float             outlineColor[] = { 0.0f, 0.0f, 0.0f },   // Color Of The Lines ( NEW )
                    outlineWidth   = 3f,                     // Width Of The Lines ( NEW )
                    modelAngle     = 0f;                     // Y-Axis Angle Of The Model ( NEW )

  POLYGON           polyData[];                              // Polygon Data ( NEW )
  VECTOR            lightAngle = new VECTOR();               // The Direction Of The Light ( NEW )

  int               shaderTexture[] = new int[1],            // Storage For One Texture ( NEW )
                    screenWidth,
                    screenHeight,
                    canvasHeight,
                    canvasWidth,
                    xLocation,
                    yLocation,
                    polyNum         = 0;                     // Number Of Polygons ( NEW )

  // User Defined Structures
  class MATRIX{ float Data[] = new float[16];}               // A Structure To Hold An OpenGL Matrix ( NEW )
                                                             // We Use [16] Due To OpenGL's Matrix Format ( NEW )
  class VECTOR{float X, Y, Z;}                               // A Structure To Hold A Single Vector ( NEW )
  class VERTEX{                                              // A Structure To Hold A Single Vertex ( NEW )
                VECTOR Nor = new VECTOR(),                   // Vertex Normal ( NEW )
                       Pos = new VECTOR();                   // Vertex Position ( NEW )
  }
  class POLYGON{                                             // A Structure To Hold A Single Polygon ( NEW )
     VERTEX Verts[] = new VERTEX[3];                         // Array Of 3 VERTEX Structures ( NEW )
     POLYGON(){
       for(int i =0; i<3; i++)
         Verts[i] = new VERTEX();
     }
  }

  // Math Functions
  float DotProduct(VECTOR V1, VECTOR V2){                       // Calculate The Angle Between The 2 Vectors ( NEW )
    return V1.X * V2.X + V1.Y * V2.Y + V1.Z * V2.Z;             // Return The Angle ( NEW )
  }

  float Magnitude(VECTOR V){                                    // Calculate The Length Of The Vector ( NEW )
    return (float)Math.sqrt(V.X * V.X + V.Y * V.Y + V.Z * V.Z); // Return The Length Of The Vector ( NEW )
  }

  void Normalize(VECTOR V){                                     // Creates A Vector With A Unit Length Of 1 ( NEW )

    float M = Magnitude (V);                                    // Calculate The Length Of The Vector  ( NEW )

    if(M != 0.0f){                                              // Make Sure We Don't Divide By 0  ( NEW )
      V.X /= M;                                                 // Normalize The 3 Components  ( NEW )
      V.Y /= M;
      V.Z /= M;
    }
  }

  void RotateVector(MATRIX M, VECTOR V, VECTOR D){              // Rotate A Vector Using The Supplied Matrix ( NEW )

    D.X = (M.Data[0] * V.X) + (M.Data[4] * V.Y) + (M.Data[8]  * V.Z);  // Rotate Around The X Axis ( NEW )
    D.Y = (M.Data[1] * V.X) + (M.Data[5] * V.Y) + (M.Data[9]  * V.Z);  // Rotate Around The Y Axis ( NEW )
    D.Z = (M.Data[2] * V.X) + (M.Data[6] * V.Y) + (M.Data[10] * V.Z);  // Rotate Around The Z Axis ( NEW )
  }

  public static void main(String []args) {
    Lesson37 demo = new Lesson37();
  }

  Lesson37(){
    int fullScreen = JOptionPane.showConfirmDialog(        null, "Would you like to run in fullscreen mode?",
                                                   "Fullscreen",  JOptionPane.YES_NO_OPTION);
    if(fullScreen!=0)
      JFrame.setDefaultLookAndFeelDecorated(true);

    frame          = new JFrame("NeHe's Cel-Shading Tutorial");
    screenWidth    = Toolkit.getDefaultToolkit().getScreenSize().width;
    screenHeight   = Toolkit.getDefaultToolkit().getScreenSize().height;

    switch(fullScreen){
      case 0:
        frame.setUndecorated(true);
      break;
      default:
        canvasWidth  = 640;
        canvasHeight = 480;
        xLocation    = (screenWidth  - canvasWidth )>>1;
        yLocation    = (screenHeight - canvasHeight)>>1;
        frame.setLocation(xLocation,yLocation);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setIconImage(new ImageIcon("Data/icon.png").getImage());
    }
    canvas  = GLDrawableFactory.getFactory().createGLCanvas(new GLCapabilities());
    canvas.setSize(new Dimension(canvasWidth,canvasHeight));
    canvas.addGLEventListener((renderer = new initRenderer()));
    canvas.requestFocus();
    canvas.addKeyListener(this);

    frame.addKeyListener(this);
    frame.addWindowListener(new shutDownWindow());
    frame.getContentPane().add(canvas,BorderLayout.CENTER);

    if(fullScreen==0){
      GraphicsEnvironment.getLocalGraphicsEnvironment().
      getDefaultScreenDevice().setFullScreenWindow(frame);
      GraphicsEnvironment.getLocalGraphicsEnvironment().
      getDefaultScreenDevice().setDisplayMode((new DisplayMode(640, 480, 32,
                                               DisplayMode.REFRESH_RATE_UNKNOWN)));
    }
    else
      frame.pack();
    frame.setVisible(true);
  }

  public class initRenderer
               implements GLEventListener
  {
    public void init(GLDrawable drawable){

      gl         = drawable.getGL();
      glu        = drawable.getGLU();
      int   i,                                                    // Looping Variable ( NEW )
            info;
      float shaderData[]  = new float[96];                        // Storate For The 96 Shader Values ( NEW )

      // Start Of User Initialization
      gl.glHint(gl.GL_PERSPECTIVE_CORRECTION_HINT, gl.GL_NICEST); // Realy Nice perspective calculations
      gl.glClearColor(0.7f, 0.7f, 0.7f, 0.0f);                    // Light Grey Background
      gl.glClearDepth(1.0f);                                      // Depth Buffer Setup

      gl.glEnable(gl.GL_DEPTH_TEST);                              // Enable Depth Testing
      gl.glDepthFunc(gl.GL_LESS);                                 // The Type Of Depth Test To Do

      gl.glShadeModel(gl.GL_SMOOTH);                              // Enables Smooth Color Shading ( NEW )
      gl.glDisable(gl.GL_LINE_SMOOTH);                            // Initially Disable Line Smoothing ( NEW )

      gl.glEnable(gl.GL_CULL_FACE);                               // Enable OpenGL Face Culling ( NEW )

      gl.glDisable(gl.GL_LIGHTING);                               // Disable OpenGL Lighting ( NEW )

      FileReader   shader;
      StringBuffer readShaderData = new StringBuffer();

      try{
        shader = new FileReader("Data\\shader.txt");              // Open The Shader File ( NEW )
        while ((info = shader.read()) != -1)
        readShaderData.append((char)info);
        shader.close();
      }
      catch(IOException e){
        System.out.println("Couldn't open shader.txt");
        System.exit(0);
      }

      StringTokenizer tokenizer = new StringTokenizer(readShaderData.toString());

      for(i = 0; i < 96; i+=3)                                      // Loop Though The 32 Greyscale Values ( NEW )
        shaderData[i  ] =
        shaderData[i+1] =
        shaderData[i+2] = Float.parseFloat(tokenizer.nextToken());  // Copy Over The Value ( NEW )

      gl.glGenTextures(1, shaderTexture);                           // Get A Free Texture ID ( NEW )
      gl.glBindTexture(gl.GL_TEXTURE_1D, shaderTexture[0]);         // Bind This Texture. From Now On It Will Be 1D ( NEW )

      // For Crying Out Loud Don't Let OpenGL Use Bi/Trilinear Filtering! ( NEW )
      gl.glTexParameteri(gl.GL_TEXTURE_1D,gl.GL_TEXTURE_MAG_FILTER,gl.GL_NEAREST);
      gl.glTexParameteri(gl.GL_TEXTURE_1D,gl.GL_TEXTURE_MIN_FILTER,gl.GL_NEAREST);

      gl.glTexImage1D(gl.GL_TEXTURE_1D, 0,gl.GL_RGB, 32, 0,gl.GL_RGB ,gl.GL_FLOAT, shaderData); // Upload ( NEW )

      lightAngle.X = 0.0f;                                          // Set The X Direction ( NEW )
      lightAngle.Y = 0.0f;                                          // Set The Y Direction ( NEW )
      lightAngle.Z = 1.0f;                                          // Set The Z Direction ( NEW )

      Normalize(lightAngle);                                        // Normalize The Light Direction ( NEW )
      ReadMesh ();                                                  // Return The Value Of ReadMesh ( NEW )

      loop = new Animator(drawable);
      loop.start();
    }

    public void display(GLDrawable drawable){
      // Clear Color Buffer, Depth Buffer
      gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT );
      int   i, j;                                                 // Looping Variables ( NEW )
      float TmpShade;                                             // Temporary Shader Value ( NEW )

      MATRIX TmpMatrix = new MATRIX();                            // Temporary MATRIX Structure ( NEW )
      VECTOR TmpVector = new VECTOR(),
             TmpNormal = new VECTOR();                            // Temporary VECTOR Structures ( NEW )

      gl.glLoadIdentity();                                        // Reset The Matrix

      if(outlineSmooth){                                          // Check To See If We Want Anti-Aliased Lines ( NEW )
        gl.glHint(gl.GL_LINE_SMOOTH_HINT,gl.GL_NICEST);           // Use The Good Calculations ( NEW )
        gl.glEnable(gl.GL_LINE_SMOOTH);                           // Enable Anti-Aliasing ( NEW )
      }
      else                                                        // We Don't Want Smooth Lines ( NEW )
        gl.glDisable(gl.GL_LINE_SMOOTH);                          // Disable Anti-Aliasing ( NEW )

      gl.glTranslatef (0.0f, 0.0f, -2.0f);                        // Move 2 Units Away From The Screen ( NEW )
      gl.glRotatef(modelAngle, 0.0f, 1.0f, 0.0f);                 // Rotate The Model On It's Y-Axis ( NEW )

      gl.glGetFloatv(gl.GL_MODELVIEW_MATRIX, TmpMatrix.Data);     // Get The Generated Matrix ( NEW )

      // Cel-Shading Code //
      gl.glEnable(gl.GL_TEXTURE_1D);                              // Enable 1D Texturing ( NEW )
      gl.glBindTexture(gl.GL_TEXTURE_1D, shaderTexture[0]);       // Bind Our Texture ( NEW )
      gl.glColor3f(1.0f, 1.0f, 1.0f);                             // Set The Color Of The Model ( NEW )

      gl.glBegin(gl.GL_TRIANGLES);                                // Tell OpenGL That We're Drawing Triangles

      for(i = 0; i < polyNum; i++)                                // Loop Through Each Polygon ( NEW )
        for(j = 0; j < 3; j++){                                   // Loop Through Each Vertex ( NEW )

          TmpNormal.X = polyData[i].Verts[j].Nor.X;               // Fill Up The TmpNormal Structure With
          TmpNormal.Y = polyData[i].Verts[j].Nor.Y;               // The Current Vertices' Normal Values ( NEW )
          TmpNormal.Z = polyData[i].Verts[j].Nor.Z;
          RotateVector (TmpMatrix, TmpNormal, TmpVector);         // Rotate This By The Matrix ( NEW )
          Normalize(TmpVector);                                   // Normalize The New Normal ( NEW )

          TmpShade = DotProduct(TmpVector, lightAngle);           // Calculate The Shade Value ( NEW )
          if(TmpShade < 0.0f)
            TmpShade = 0.0f;                                      // Clamp The Value to 0 If Negative ( NEW )

          gl.glTexCoord1f(TmpShade);                              // Set The Texture Co-ordinate As The Shade Value ( NEW )
          gl.glVertex3f(polyData[i].Verts[j].Pos.X,
                        polyData[i].Verts[j].Pos.Y,
                        polyData[i].Verts[j].Pos.Z);              // Send The Vertex Position ( NEW )
        }

      gl.glEnd ();                                                // Tell OpenGL To Finish Drawing
      gl.glDisable(gl.GL_TEXTURE_1D);                             // Disable 1D Textures ( NEW )

      // Outline Code //
      if(outlineDraw){                                            // Check To See If We Want To Draw The Outline ( NEW )
        gl.glEnable(gl.GL_BLEND);                                 // Enable Blending ( NEW )
        gl.glBlendFunc(gl.GL_SRC_ALPHA,gl.GL_ONE_MINUS_SRC_ALPHA);// Set The Blend Mode ( NEW )

        gl.glPolygonMode(gl.GL_BACK,gl.GL_LINE);                  // Draw Backfacing Polygons As Wireframes ( NEW )
        gl.glLineWidth(outlineWidth);                             // Set The Line Width ( NEW )
        gl.glCullFace(gl.GL_FRONT);                               // Don't Draw Any Front-Facing Polygons ( NEW )

        gl.glDepthFunc(gl.GL_LEQUAL);                             // Change The Depth Mode ( NEW )
        gl.glColor3fv(outlineColor);                              // Set The Outline Color ( NEW )

        gl.glBegin(gl.GL_TRIANGLES);                              // Tell OpenGL What We Want To Draw

        for(i = 0; i < polyNum; i++)                              // Loop Through Each Polygon ( NEW )
          for(j = 0; j < 3; j++)                                  // Loop Through Each Vertex ( NEW )
            gl.glVertex3f(polyData[i].Verts[j].Pos.X,
                          polyData[i].Verts[j].Pos.Y,
                          polyData[i].Verts[j].Pos.Z);            // Send The Vertex Position ( NEW )

        gl.glEnd();                                               // Tell OpenGL We've Finished
        gl.glDepthFunc(gl.GL_LESS);                               // Reset The Depth-Testing Mode ( NEW )
        gl.glCullFace(gl.GL_BACK);                                // Reset The Face To Be Culled ( NEW )
        gl.glPolygonMode(gl.GL_BACK,gl.GL_FILL);                  // Reset Back-Facing Polygon Drawing Mode ( NEW )
        gl.glDisable(gl.GL_BLEND);                                // Disable Blending ( NEW )
      }
      if(modelRotate)                                              // Check To See If Rotation Is Enabled ( NEW )
        modelAngle += .2f;                                      // Update Angle Based On The Clock
    }

    public void reshape(GLDrawable drawable,
                        int xstart,int ystart,
                        int width, int height){

      height = (height == 0) ? 1 : height;

      gl.glViewport(0,0,width,height);
      gl.glMatrixMode(gl.GL_PROJECTION);
      gl.glLoadIdentity();

      glu.gluPerspective(45,(float)width/height,1,1000);
      gl.glMatrixMode(gl.GL_MODELVIEW);
      gl.glLoadIdentity();
    }

    public void displayChanged(GLDrawable drawable,
                               boolean modeChanged,
                               boolean deviceChanged){}
  }

  void ReadMesh(){

    URL fileSource = null;
    try{
      fileSource = new URL("file", "localhost","Data\\model.txt");
    }
    catch(java.net.MalformedURLException e){
      System.out.println("Couldn't locate model, exiting");
      System.exit(0);
    }

    InputStream in = null;
    try {
      in = fileSource.openStream();
    }
    catch(IOException e){
      System.out.println("Couldn't load model, exiting");
      System.exit(0);
    }

    polyNum  = byteToInt(readNextFourBytes(in));
    polyData = new POLYGON[polyNum];

    for(int i=0; i<polyData.length;i++){
      polyData[i] = new POLYGON();
      for(int j =0; j<3; j++){
        polyData[i].Verts[j].Nor.X = byteToFloat(readNextFourBytes(in));
        polyData[i].Verts[j].Nor.Y = byteToFloat(readNextFourBytes(in));
        polyData[i].Verts[j].Nor.Z = byteToFloat(readNextFourBytes(in));

        polyData[i].Verts[j].Pos.X = byteToFloat(readNextFourBytes(in));
        polyData[i].Verts[j].Pos.Y = byteToFloat(readNextFourBytes(in));
        polyData[i].Verts[j].Pos.Z = byteToFloat(readNextFourBytes(in));
      }
    }
  }

  byte[] readNextFourBytes(InputStream in){
    byte[] bytes = new byte[4];

    try{
      for(int i = 0; i<4; i++)
        bytes[i] = (byte)in.read();
    }
    catch(Exception e){
      System.out.println("Error reading file, exiting");
      System.exit(0);
    }
    return bytes;
  }

  int byteToInt(byte[] array) {
    int value = 0;
    for(int i = 0; i < 4; i++) {
      int b = array[i];
      b &= 0xff;
      value |= (b << (i*8));
    }
   return value;
  }

  float byteToFloat(byte[] array){
    int value = 0;
    for(int i = 3; i >= 0; i--) {
      int b = array[i];
      b &= 0xff;
      value |= (b << (i * 8));
    }
    return Float.intBitsToFloat(value);
  }

  public void keyReleased(KeyEvent evt){

    keys[evt.getKeyCode()] = false;
  }

  public void keyPressed (KeyEvent evt){

    keys[evt.getKeyCode()] = true;

    if(keys[KeyEvent.VK_ESCAPE]){
      loop.stop();
      System.exit(0);
    }

    if(keys[KeyEvent.VK_SPACE])                         // Is the Space Bar Being Pressed? ( NEW )
      modelRotate = !modelRotate;                       // Toggle Model Rotation On/Off ( NEW )

    if(keys[KeyEvent.VK_1])                             // Is The Number 1 Being Pressed? ( NEW )
      outlineDraw = !outlineDraw;                       // Toggle Outline Drawing On/Off ( NEW )

    if(keys[KeyEvent.VK_2])                             // Is The Number 2 Being Pressed? ( NEW )
      outlineSmooth = !outlineSmooth;                   // Toggle Anti-Aliasing On/Off ( NEW )

    if(keys[KeyEvent.VK_UP])                            // Is The Up Arrow Being Pressed? ( NEW )
      outlineWidth++;                                   // Increase Line Width ( NEW )

    if(keys[KeyEvent.VK_DOWN])                          // Is The Down Arrow Being Pressed? ( NEW )
      outlineWidth--;                                   // Decrease Line Width ( NEW )
 }

  public void keyTyped   (KeyEvent evt){}
  public class shutDownWindow extends WindowAdapter {
    public void windowClosing(WindowEvent e) {
      loop.stop();
    }
  }
}
