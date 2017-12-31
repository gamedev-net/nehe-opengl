/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 17 : 2D Texture Fonts
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
   
      int	base;				// Base Display List For The Font
      int[]	texture=new int[2];			// Storage For Our Font Texture
      int	loop;				// Generic Loop Variable
   
      float	cnt1;				// 1st Counter Used To Move Text & For Coloring
      float	cnt2;				// 2nd Counter Used To Move Text & For Coloring
   
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
         String tileNames [] = {"data/font.png","data/bumps.png"};
      
      
         gl.glGenTextures(2, texture);
      
         for (int i=0;i<2;i++){
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
      void BuildFont()								// Build Our Font Display List
      
      {
         float	cx;											// Holds Our X Character Coord
         float	cy;											// Holds Our Y Character Coord
      
         base=gl.glGenLists(256);								// Creating 256 Display Lists
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);			// Select Our Font Texture
         for (loop=0; loop<256; loop++)						// Loop Through All 256 Lists
         {
            cx=(float)(loop%16)/16.0f;						// X Position Of Current Character
            cy=(float)(loop/16)/16.0f;						// Y Position Of Current Character
         
            gl.glNewList(base+loop,GL_COMPILE);				// Start Building A List
            gl.glBegin(GL_QUADS);							// Use A Quad For Each Character
            gl.glTexCoord2f(cx,1-cy-0.0625f);			// Texture Coord (Bottom Left)
            gl.glVertex2i(0,0);						// Vertex Coord (Bottom Left)
            gl.glTexCoord2f(cx+0.0625f,1-cy-0.0625f);	// Texture Coord (Bottom Right)
            gl.glVertex2i(16,0);						// Vertex Coord (Bottom Right)
            gl.glTexCoord2f(cx+0.0625f,1-cy);			// Texture Coord (Top Right)
            gl.glVertex2i(16,16);						// Vertex Coord (Top Right)
            gl.glTexCoord2f(cx,1-cy);					// Texture Coord (Top Left)
            gl.glVertex2i(0,16);						// Vertex Coord (Top Left)
            gl.glEnd();									// Done Building Our Quad (Character)
            gl.glTranslated(10,0,0);						// Move To The Right Of The Character
            gl.glEndList();									// Done Building The Display List
         }													// Loop Until All 256 Are Built
      }
   
      void glPrint(int x, int y, String string, int set)	// Where The Printing Happens
      
      {
         if (set>1)
         {
            set=1;
         }
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);			// Select Our Font Texture
         gl.glDisable(GL_DEPTH_TEST);							// Disables Depth Testing
         gl.glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
         gl.glPushMatrix();										// Store The Projection Matrix
         gl.glLoadIdentity();									// Reset The Projection Matrix
         gl.glOrtho(0,640,0,480,-1,1);							// Set Up An Ortho Screen
         gl.glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
         gl.glPushMatrix();										// Store The Modelview Matrix
         gl.glLoadIdentity();									// Reset The Modelview Matrix
         gl.glTranslated(x,y,0);								// Position The Text (0,0 - Bottom Left)
         gl.glListBase(base-32+(128*set));						// Choose The Font Set (0 or 1)
         gl.glCallLists(string.length(),GL_BYTE,string.getBytes());			// Write The Text To The Screen
         gl.glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
         gl.glPopMatrix();										// Restore The Old Projection Matrix
         gl.glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
         gl.glPopMatrix();										// Restore The Old Projection Matrix
         gl.glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
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
         
            System.exit(-10);
         }
      
      
         float width = (float)getSize().width;
         float height = (float)getSize().height;
         BuildFont();
      
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Select The Type Of Blending
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         gl.glEnable(GL_TEXTURE_2D);							// Enable 2D Texture Mapping
      
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();                                         //Reset The View
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[1]);			// Select Our Second Texture
         gl.glTranslatef(0.0f,0.0f,-5.0f);						// Move Into The Screen 5 Units
         gl.glRotatef(45.0f,0.0f,0.0f,1.0f);					// Rotate On The Z Axis 45 Degrees (Clockwise)
         gl.glRotatef(cnt1*30.0f,1.0f,1.0f,0.0f);				// Rotate On The X & Y Axis By cnt1 (Left To Right)
         gl.glDisable(GL_BLEND);								// Disable Blending Before We Draw In 3D
         gl.glColor3f(1.0f,1.0f,1.0f);							// Bright White
         gl.glBegin(GL_QUADS);									// Draw Our First Texture Mapped Quad
         gl.glTexCoord2d(0.0f,0.0f);						// First Texture Coord
         gl.glVertex2f(-1.0f, 1.0f);						// First Vertex
         gl.glTexCoord2d(1.0f,0.0f);						// Second Texture Coord
         gl.glVertex2f( 1.0f, 1.0f);						// Second Vertex
         gl.glTexCoord2d(1.0f,1.0f);						// Third Texture Coord
         gl.glVertex2f( 1.0f,-1.0f);						// Third Vertex
         gl.glTexCoord2d(0.0f,1.0f);						// Fourth Texture Coord
         gl.glVertex2f(-1.0f,-1.0f);						// Fourth Vertex
         gl.glEnd();											// Done Drawing The First Quad
         gl.glRotatef(90.0f,1.0f,1.0f,0.0f);					// Rotate On The X & Y Axis By 90 Degrees (Left To Right)
         gl.glBegin(GL_QUADS);									// Draw Our Second Texture Mapped Quad
         gl.glTexCoord2d(0.0f,0.0f);						// First Texture Coord
         gl.glVertex2f(-1.0f, 1.0f);						// First Vertex
         gl.glTexCoord2d(1.0f,0.0f);						// Second Texture Coord
         gl.glVertex2f( 1.0f, 1.0f);						// Second Vertex
         gl.glTexCoord2d(1.0f,1.0f);						// Third Texture Coord
         gl.glVertex2f( 1.0f,-1.0f);						// Third Vertex
         gl.glTexCoord2d(0.0f,1.0f);						// Fourth Texture Coord
         gl.glVertex2f(-1.0f,-1.0f);						// Fourth Vertex
         gl.glEnd();											// Done Drawing Our Second Quad
         gl.glEnable(GL_BLEND);									// Enable Blending
      
         gl.glLoadIdentity();									// Reset The View
      // Pulsing Colors Based On Text Position
         gl.glColor3f(1.0f*(float)(Math.cos(cnt1)),1.0f*(float)(Math.sin(cnt2)),1.0f-0.5f*(float)(Math.cos(cnt1+cnt2)));
         glPrint( (int)((280+250*Math.cos(cnt1))),(int)(235+200*Math.sin(cnt2)),"NeHe",0);		// Print GL Text To The Screen
      
         gl.glColor3f(1.0f*(float)(Math.sin(cnt2)),1.0f-0.5f*(float)(Math.cos(cnt1+cnt2)),1.0f*(float)(Math.cos(cnt1)));
         glPrint( (int)((280+230*Math.cos(cnt2))),(int)(235+200*Math.sin(cnt1)),"OpenGL",1);	// Print GL Text To The Screen
      
         gl.glColor3f(0.0f,0.0f,1.0f);
         glPrint((int)(240+200*Math.cos((cnt2+cnt1)/5)),2,"Giuseppe D'Agata",0);
      
         gl.glColor3f(1.0f,1.0f,1.0f);
         glPrint((int)(242+200*Math.cos((cnt2+cnt1)/5)),2,"Giuseppe D'Agata",0);
      
         cnt1+=0.01f;										// Increase The First Counter
         cnt2+=0.0081f;										// Increase The Second Counter
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