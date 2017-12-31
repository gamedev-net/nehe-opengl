/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 5 : Solid Shapes
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



// GL4Java classes
   import gl4java.GLContext;
   import gl4java.awt.GLAnimCanvas;


   class NeHeCanvas extends GLAnimCanvas implements KeyListener, MouseListener
   
   {   
     // holds information on which keys are held down.
      boolean[] keys=new boolean[256];
      float rtri,rquad;
      public NeHeCanvas(int w, int h)
      
      {
         super(w, h);
      
         //Registers this canvas to process keyboard events, and Mouse events
         addKeyListener(this);
         addMouseListener(this);   
         setAnimateFps(60); // seemed to be essential in getting any performance 
      
      }
   
    /** void reshape(int width, int height) Called after the first paint command.  */
   
      public void reshape(int width, int height)
      {
         System.out.println("Width : "+width+" Height: "+height);
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
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();                                         //Reset The View
         gl.glTranslatef(-1.5f,0.0f,-8.0f);						// Move Left 1.5 Units And Into The Screen 6.0
         gl.glRotatef(rtri,0.0f,1.0f,0.0f);						// Rotate The Triangle On The Y axis ( NEW )
         gl.glBegin(GL_TRIANGLES);								// Start Drawing A Triangle
         gl.glColor3f(1.0f,0.0f,0.0f);						// Red
         gl.glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Front)
         gl.glColor3f(0.0f,1.0f,0.0f);						// Green
         gl.glVertex3f(-1.0f,-1.0f, 1.0f);					// Left Of Triangle (Front)
         gl.glColor3f(0.0f,0.0f,1.0f);						// Blue
         gl.glVertex3f( 1.0f,-1.0f, 1.0f);					// Right Of Triangle (Front)
         gl.glColor3f(1.0f,0.0f,0.0f);						// Red
         gl.glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Right)
         gl.glColor3f(0.0f,0.0f,1.0f);						// Blue
         gl.glVertex3f( 1.0f,-1.0f, 1.0f);					// Left Of Triangle (Right)
         gl.glColor3f(0.0f,1.0f,0.0f);						// Green
         gl.glVertex3f( 1.0f,-1.0f, -1.0f);					// Right Of Triangle (Right)
         gl.glColor3f(1.0f,0.0f,0.0f);						// Red
         gl.glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Back)
         gl.glColor3f(0.0f,1.0f,0.0f);						// Green
         gl.glVertex3f( 1.0f,-1.0f, -1.0f);					// Left Of Triangle (Back)
         gl.glColor3f(0.0f,0.0f,1.0f);						// Blue
         gl.glVertex3f(-1.0f,-1.0f, -1.0f);					// Right Of Triangle (Back)
         gl.glColor3f(1.0f,0.0f,0.0f);						// Red
         gl.glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Left)
         gl.glColor3f(0.0f,0.0f,1.0f);						// Blue
         gl.glVertex3f(-1.0f,-1.0f,-1.0f);					// Left Of Triangle (Left)
         gl.glColor3f(0.0f,1.0f,0.0f);						// Green
         gl.glVertex3f(-1.0f,-1.0f, 1.0f);					// Right Of Triangle (Left)
         gl.glEnd();											// Done Drawing The Pyramid
      
         gl.glLoadIdentity();									// Reset The Current Modelview Matrix
         gl.glTranslatef(1.5f,0.0f,-9.0f);						// Move Right 1.5 Units And Into The Screen 7.0
         gl.glRotatef(rquad,1.0f,1.0f,1.0f);					// Rotate The Quad On The X axis ( NEW )
         gl.glBegin(GL_QUADS);									// Draw A Quad
         gl.glColor3f(0.0f,1.0f,0.0f);						// Set The Color To Blue
         gl.glVertex3f( 1.0f, 1.0f,-1.0f);					// Top Right Of The Quad (Top)
         gl.glVertex3f(-1.0f, 1.0f,-1.0f);					// Top Left Of The Quad (Top)
         gl.glVertex3f(-1.0f, 1.0f, 1.0f);					// Bottom Left Of The Quad (Top)
         gl.glVertex3f( 1.0f, 1.0f, 1.0f);					// Bottom Right Of The Quad (Top)
         gl.glColor3f(1.0f,0.5f,0.0f);						// Set The Color To Orange
         gl.glVertex3f( 1.0f,-1.0f, 1.0f);					// Top Right Of The Quad (Bottom)
         gl.glVertex3f(-1.0f,-1.0f, 1.0f);					// Top Left Of The Quad (Bottom)
         gl.glVertex3f(-1.0f,-1.0f,-1.0f);					// Bottom Left Of The Quad (Bottom)
         gl.glVertex3f( 1.0f,-1.0f,-1.0f);					// Bottom Right Of The Quad (Bottom)
         gl.glColor3f(1.0f,0.0f,0.0f);						// Set The Color To Red
         gl.glVertex3f( 1.0f, 1.0f, 1.0f);					// Top Right Of The Quad (Front)
         gl.glVertex3f(-1.0f, 1.0f, 1.0f);					// Top Left Of The Quad (Front)
         gl.glVertex3f(-1.0f,-1.0f, 1.0f);					// Bottom Left Of The Quad (Front)
         gl.glVertex3f( 1.0f,-1.0f, 1.0f);					// Bottom Right Of The Quad (Front)
         gl.glColor3f(1.0f,1.0f,0.0f);						// Set The Color To Yellow
         gl.glVertex3f( 1.0f,-1.0f,-1.0f);					// Top Right Of The Quad (Back)
         gl.glVertex3f(-1.0f,-1.0f,-1.0f);					// Top Left Of The Quad (Back)
         gl.glVertex3f(-1.0f, 1.0f,-1.0f);					// Bottom Left Of The Quad (Back)
         gl.glVertex3f( 1.0f, 1.0f,-1.0f);					// Bottom Right Of The Quad (Back)
         gl.glColor3f(0.0f,0.0f,1.0f);						// Set The Color To Blue
         gl.glVertex3f(-1.0f, 1.0f, 1.0f);					// Top Right Of The Quad (Left)
         gl.glVertex3f(-1.0f, 1.0f,-1.0f);					// Top Left Of The Quad (Left)
         gl.glVertex3f(-1.0f,-1.0f,-1.0f);					// Bottom Left Of The Quad (Left)
         gl.glVertex3f(-1.0f,-1.0f, 1.0f);					// Bottom Right Of The Quad (Left)
         gl.glColor3f(1.0f,0.0f,1.0f);						// Set The Color To Violet
         gl.glVertex3f( 1.0f, 1.0f,-1.0f);					// Top Right Of The Quad (Right)
         gl.glVertex3f( 1.0f, 1.0f, 1.0f);					// Top Left Of The Quad (Right)
         gl.glVertex3f( 1.0f,-1.0f, 1.0f);					// Bottom Left Of The Quad (Right)
         gl.glVertex3f( 1.0f,-1.0f,-1.0f);					// Bottom Right Of The Quad (Right)
         gl.glEnd();											// Done Drawing The Quad
      
         rtri+=0.2f;											// Increase The Rotation Variable For The Triangle ( NEW )
         rquad-=0.15f;										// Decrease The Rotation Variable For The Quad ( NEW )										// Decrease The Rotation Variable For The Quad ( NEW )											// Done Drawing The Quad
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