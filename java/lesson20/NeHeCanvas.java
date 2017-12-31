/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 20 : Masking
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
   
      boolean	masking=true;		// Masking On/Off
      boolean	mp;					// M Pressed?
      boolean	sp;					// Space Pressed?
      boolean	scene;				// Which Scene To Draw
   
      int[]	texture=new int[5];			// Storage For Our Five Textures
      int	loop;				// Generic Loop Variable
      float	roll;				// Rolling Texture
   
   
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
         String tileNames [] = 
         {"data/logo.png",
            "data/mask1.png",
            "data/image1.png",
            "data/mask2.png",
            "data/image2.png"
         };
      
      
         gl.glGenTextures(5, texture);
      
         for (int i=0;i<5;i++){
            PngTextureLoader texLoader = new PngTextureLoader(gl, glu);
         
            if(codeBase!=null)   
               texLoader.readTexture(codeBase, tileNames[i]);
            else
               texLoader.readTexture(tileNames[i]);
         
         
         
            if(!texLoader.isOk())
            {
               return false;
            }
                       //Create Nearest Filtered Texture
            gl.glBindTexture(GL_TEXTURE_2D, texture[i]);
         
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
         
         
         
         
         }
         return true;
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
            stop();
            cvsDispose();
            System.exit(-10);
         }
      
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         gl.glEnable(GL_TEXTURE_2D);
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();                                         //Reset The View
         gl.glTranslatef(0.0f,0.0f,-2.0f);						// Move Into The Screen 5 Units
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);			// Select Our Logo Texture
         gl.glBegin(GL_QUADS);									// Start Drawing A Textured Quad
         gl.glTexCoord2f(0.0f, -roll+0.0f); gl.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
         gl.glTexCoord2f(3.0f, -roll+0.0f); gl.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
         gl.glTexCoord2f(3.0f, -roll+3.0f); gl.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
         gl.glTexCoord2f(0.0f, -roll+3.0f); gl.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
         gl.glEnd();											// Done Drawing The Quad
      
         gl.glEnable(GL_BLEND);									// Enable Blending
         gl.glDisable(GL_DEPTH_TEST);							// Disable Depth Testing
      
         if (masking)										// Is Masking Enabled?
         {
            gl.glBlendFunc(GL_DST_COLOR,GL_ZERO);				// Blend Screen Color With Zero (Black)
         }
      
         if (scene)											// Are We Drawing The Second Scene?
         {
            gl.glTranslatef(0.0f,0.0f,-1.0f);					// Translate Into The Screen One Unit
            gl.glRotatef(roll*360,0.0f,0.0f,1.0f);				// Rotate On The Z Axis 360 Degrees.
            if (masking)									// Is Masking On?
            {
               gl.glBindTexture(GL_TEXTURE_2D, texture[3]);	// Select The Second Mask Texture
               gl.glBegin(GL_QUADS);							// Start Drawing A Textured Quad
               gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
               gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
               gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
               gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
               gl.glEnd();									// Done Drawing The Quad
            }
         
            gl.glBlendFunc(GL_ONE, GL_ONE);					// Copy Image 2 Color To The Screen
            gl.glBindTexture(GL_TEXTURE_2D, texture[4]);		// Select The Second Image Texture
            gl.glBegin(GL_QUADS);								// Start Drawing A Textured Quad
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
            gl.glEnd();										// Done Drawing The Quad
         }
         else												// Otherwise
         {
            if (masking)									// Is Masking On?
            {
               gl.glBindTexture(GL_TEXTURE_2D, texture[1]);	// Select The First Mask Texture
               gl.glBegin(GL_QUADS);							// Start Drawing A Textured Quad
               gl.glTexCoord2f(roll+0.0f, 0.0f); gl.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
               gl.glTexCoord2f(roll+4.0f, 0.0f); gl.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
               gl.glTexCoord2f(roll+4.0f, 4.0f); gl.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
               gl.glTexCoord2f(roll+0.0f, 4.0f); gl.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
               gl.glEnd();									// Done Drawing The Quad
            }
         
            gl.glBlendFunc(GL_ONE, GL_ONE);					// Copy Image 1 Color To The Screen
            gl.glBindTexture(GL_TEXTURE_2D, texture[2]);		// Select The First Image Texture
            gl.glBegin(GL_QUADS);								// Start Drawing A Textured Quad
            gl.glTexCoord2f(roll+0.0f, 0.0f); gl.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
            gl.glTexCoord2f(roll+4.0f, 0.0f); gl.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
            gl.glTexCoord2f(roll+4.0f, 4.0f); gl.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
            gl.glTexCoord2f(roll+0.0f, 4.0f); gl.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
            gl.glEnd();										// Done Drawing The Quad
         }
      
         gl.glEnable(GL_DEPTH_TEST);							// Enable Depth Testing
         gl.glDisable(GL_BLEND);								// Disable Blending
      
         roll+=0.002f;										// Increase Our Texture Roll Variable
         if (roll>1.0f)										// Is Roll Greater Than One
         {
            roll-=1.0f;										// Subtract 1 From Roll
         }
         if (keys[' '] && !sp)				// Is Space Being Pressed?
         {
            sp=true;				// Tell Program Spacebar Is Being Held
            scene=!scene;					// Toggle From One Scene To The Other
         }
         if (!keys[' '])						// Has Spacebar Been Released?
         {
            sp=false;			// Tell Program Spacebar Has Been Released
         }
      
         if (keys['M'] && !mp)				// Is M Being Pressed?
         {
            mp=true;			// Tell Program M Is Being Held
            masking=!masking;				// Toggle Masking Mode OFF/ON
         }
         if (!keys['M'])						// Has M Been Released?
         {
            mp=true;						// Tell Program That M Has Been Released
         }
      
      }
   
   
     /** void display() Draw to the canvas. */
    // Purely a Java thing. Simple calls DrawGLScene once GL is initialized
      public void display()
      
      {
         glj.gljMakeCurrent();      //Ensure GL is initialised correctly
         for(int i=0;i<3;i++) // to get more performace.. damn slow event driven drawing
            DrawGLScene();
         glj.gljSwap();             //Swap buffers
         glj.gljFree();             // release GL
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