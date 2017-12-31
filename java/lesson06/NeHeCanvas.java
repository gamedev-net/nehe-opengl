/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 6 : Texture Mapping
Origional Visual C versions available at  : nehe.gamedev.net
Previous Java port at Hoglims site (linked to from Nehe's)


Thanks go to Darren Hodges for the first port of the NeHe tutorials.

This set of ports makes use of the new Gl4Java 2.8.2 (which thankfully includes Font support)

It is also structures slightly different, in that this file is the only file that changes, the lesson.java
file is constant, making it much more easy to concentrate on the OpenGL specific code. All lesson.java does is create a class
that will display the NeheCanvas in either Applet form for use in a webpage or in a window.

Also this should mimic the order of the Nehe Html as much as possible, making reading the tutorial and writting 
your own code as easy as possible

NOTE : this tutorial assumes you know Java basics. Once you've read these.. you'll see what Java is so much easier, if a little
slower :)

*/

// Java  classes
   import java.awt.*;
   import java.awt.event.*;
   import java.net.URL;



// GL4Java classes
   import gl4java.GLContext;
   import gl4java.awt.GLAnimCanvas;
   import gl4java.utils.textures.*;


   class NeHeCanvas extends GLAnimCanvas implements KeyListener, MouseListener
   
   {   
     // holds information on which keys are held down.
      boolean[] keys=new boolean[256];
      URL codeBase;
      float	xrot;				// X Rotation ( NEW )
      float	yrot;				// Y Rotation ( NEW )
      float	zrot;				// Z Rotation ( NEW )
      int[] texture = new int[1]; //Storage for one texture ( NEW )
   
      public NeHeCanvas(int w, int h)
      
      {
         super(w, h);
      
         //Registers this canvas to process keyboard events, and Mouse events
         addKeyListener(this);
         addMouseListener(this);   
         setAnimateFps(60); // seemed to be essential in getting any performance 
      
      }
      public boolean LoadGLTextures()
      {
         PngTextureLoader texLoader = new PngTextureLoader(gl, glu);
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/nehe.png");
         else
            texLoader.readTexture("data/nehe.png");
      
         if(texLoader.isOk())
         {
            //Create Texture
            gl.glGenTextures(1, texture);
            gl.glBindTexture(GL_TEXTURE_2D, texture[0]);
         
            gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
         
            gl.glTexImage2D(GL_TEXTURE_2D,
                           0,
                           3,
                           texLoader.getImageWidth(),
                           texLoader.getImageHeight(),
                           0,
                           GL_RGB,
                           GL_UNSIGNED_BYTE,
                           texLoader.getTexture());
            return true;
         }
         return false;
      }
   
   
   
    /** void reshape(int width, int height) Called after the first paint command.  */
   
      public void reshape(int width, int height)
      {
         if(height==0)height=1;
         gl.glViewport(0, 0, width, height);                       // Reset The Current Viewport And Perspective Transformation
         gl.glMatrixMode(GL_PROJECTION);                           // Select The Projection Matrix
         gl.glLoadIdentity();                                      // Reset The Projection Matrix
         glu.gluPerspective(45.0f, width / height, 0.1f, 100.0f);  // Calculate The Aspect Ratio Of The Window
         gl.glMatrixMode(GL_MODELVIEW);                            // Select The Modelview Matrix
         gl.glLoadIdentity();                                      // Reset The ModalView Matrix
      
      }
   
   
   /** void preInit() Called just BEFORE the GL-Context is created. */
   
      public void preInit()
      { doubleBuffer = true; stereoView = false; // buffering but not stereoview
      }
   
   /** void init() Called just AFTER the GL-Context is created. */
   
      public void init()
      
      {
         if(!LoadGLTextures())
         {
            System.out.println("Failed to load Textures,Bailing!");

         	System.exit(0);
         }
      
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glEnable(GL_TEXTURE_2D);						          // Enable Texture Mapping ( NEW )
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();									// Reset The View
         gl.glTranslatef(0.0f,0.0f,-7.0f);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);
         gl.glRotatef(zrot,0.0f,0.0f,1.0f);
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);
      
         gl.glBegin(GL_QUADS);
      // Front Face
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
      // Back Face
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
      // Top Face
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
      // Bottom Face
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
      // Right face
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
      // Left Face
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
         gl.glEnd();
      
         xrot+=0.3f;
         yrot+=0.2f;
         zrot+=0.4f;
      }
   
   
     /** void display() Draw to the canvas. */
    // Purely a Java thing. Simple calls DrawGLScene once GL is initialized
      public void display()
      
      {
         for(int i=0;i<3;i++){
            glj.gljMakeCurrent();      //Ensure GL is initialised correctly
            DrawGLScene();
            glj.gljSwap();             //Swap buffers
            glj.gljFree();             // release GL
         }
      }
   
   
   // Key Listener events
      public void keyTyped(KeyEvent e){
      }
   
      public void keyPressed(KeyEvent e){
         switch(e.getKeyCode())
         {
            //Kill app
            case KeyEvent.VK_ESCAPE:
               {
                  System.exit(0);
                  break;
               }
            default :
               if(e.getKeyCode()<250) // only interested in first 250 key codes, are there more?
                  keys[e.getKeyCode()]=true;	
               break;
         }
      }
   
      public void keyReleased(KeyEvent e){
         if(e.getKeyCode()<250)  // only interested in first 250 key codes, are there more?
            keys[e.getKeyCode()]=false;
      }
   
   // mouse listener events
   
      public void mouseEntered( MouseEvent evt )
      
      {
         Component comp = evt.getComponent();
         if( comp.equals(this ) )
         {
            requestFocus();
         }
      }
   
   
      public void mouseExited( MouseEvent evt ){ 
      }
   
      public void mousePressed( MouseEvent evt ){ 
      }
   
      public void mouseReleased( MouseEvent evt ){ 
      }
   
      public void mouseClicked( MouseEvent evt )
      { 
         Component comp = evt.getComponent();
         if( comp.equals(this ) )
         {
            requestFocus();
         }
      }
   
   }