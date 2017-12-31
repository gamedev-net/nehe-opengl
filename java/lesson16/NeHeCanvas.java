/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 16 : Cool Looking Fog
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
      boolean	light;				// Lighting ON/OFF 
      boolean	lp;					// L Pressed? 
      boolean	fp;					// F Pressed? 
      boolean  gp;               // g pressed? ( new )
   
      float	xrot;				// X Rotation
      float	yrot;				// Y Rotation
      float xspeed;				// X Rotation Speed
      float yspeed;				// Y Rotation Speed
      float	z=-5.0f;			// Depth Into The Screen
      float[] LightAmbient=		{ 0.5f, 0.5f, 0.5f, 1.0f };
      float[] LightDiffuse=		{ 1.0f, 1.0f, 1.0f, 1.0f };
      float[] LightPosition=	{ 0.0f, 0.0f, 2.0f, 1.0f };
   
      int	filter;				// Which Filter To Use  ( new )
   
      int	fogMode[]= { GL_EXP, GL_EXP2, GL_LINEAR };	// Storage For Three Types Of Fog ( new )
      int	fogfilter = 0;								// Which Fog Mode To Use      ( new )
      float	fogColor[] = {0.5f,0.5f,0.5f,1.0f};		// Fog Color               ( new )
   
      int[]	texture=new int[3];			// Storage For 3 Textures
   
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
            texLoader.readTexture(codeBase, "data/crate.png");
         else
            texLoader.readTexture("data/crate.png");
      
      
         if(texLoader.isOk())
         {
            //Create Nearest Filtered Texture
            gl.glGenTextures(3, texture);
            gl.glBindTexture(GL_TEXTURE_2D, texture[0]);
         
            gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
         
            gl.glTexImage2D(GL_TEXTURE_2D,
                           0,
                           3,
                           texLoader.getImageWidth(),
                           texLoader.getImageHeight(),
                           0,
                           GL_RGB,
                           GL_UNSIGNED_BYTE,
                           texLoader.getTexture());
         
            //Create Linear Filtered Texture
            gl.glBindTexture(GL_TEXTURE_2D, texture[1]);
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
         
            //Create MipMapped Texture (Only with GL4Java 2.1.2.1 and later!)
            gl.glBindTexture(GL_TEXTURE_2D, texture[2]);
            gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
         
            glu.gluBuild2DMipmaps(GL_TEXTURE_2D,
                                 3,
                                 texLoader.getImageWidth(),
                                 texLoader.getImageHeight(),
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
         if(!LoadGLTextures()){
            System.exit(-10);
         
         }
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.5f,0.5f,0.5f,1.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         gl.glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);		// Setup The Ambient Light
         gl.glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);		// Setup The Diffuse Light
         gl.glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);	// Position The Light
         gl.glEnable(GL_LIGHT1);								// Enable Light One
         gl.glFogi(GL_FOG_MODE, fogMode[fogfilter]);			// Fog Mode
         gl.glFogfv(GL_FOG_COLOR, fogColor);					// Set Fog Color
         gl.glFogf(GL_FOG_DENSITY, 0.35f);						// How Dense Will The Fog Be
         gl.glHint(GL_FOG_HINT, GL_DONT_CARE);					// Fog Hint Value
         gl.glFogf(GL_FOG_START, 1.0f);							// Fog Start Depth
         gl.glFogf(GL_FOG_END, 5.0f);							// Fog End Depth
         gl.glEnable(GL_FOG);									// Enables GL_FOG
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();                                         //Reset The View
         gl.glTranslatef(0.0f,0.0f,z);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[filter]);
      
         gl.glBegin(GL_QUADS);
      // Front Face
         gl.glNormal3f( 0.0f, 0.0f, 1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
      // Back Face
         gl.glNormal3f( 0.0f, 0.0f,-1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
      // Top Face
         gl.glNormal3f( 0.0f, 1.0f, 0.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
      // Bottom Face
         gl.glNormal3f( 0.0f,-1.0f, 0.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
      // Right face
         gl.glNormal3f( 1.0f, 0.0f, 0.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);
      // Left Face
         gl.glNormal3f(-1.0f, 0.0f, 0.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);
         gl.glEnd();
      
         xrot+=xspeed;
         yrot+=yspeed;
      
      // process keys that are down ( kinda NON javaish, but i like it )
      
           //toggle lighting
         if( keys['L'] & !lp)
         {
            lp=true;
            light=!light;
            if(!light)gl.glDisable(GL_LIGHTING);
            if(light)gl.glEnable(GL_LIGHTING);
         }
         if(!keys['L'])
            lp=false;
      
      		// toggle filtering
         if (keys['F'] && !fp)
         {
            fp=true;
            filter+=1;
            if (filter>2)
            {
               filter=0;
            }
         }
         if (!keys['F'])
         {
            fp=false;
         }
         if (keys['G'] && !gp)
         {
            gp=true;
            fogfilter+=1;
            if (fogfilter>2)
            {
               fogfilter=0;
            }
            gl.glFogi(GL_FOG_MODE,fogMode[fogfilter]);
         }
         if (!keys['G'])
         {
            gp=false;
         }
      
      
      
         if (keys[KeyEvent.VK_PAGE_UP ])
         {
            z-=0.02f;
         }
         if (keys[KeyEvent.VK_PAGE_DOWN ])
         {
            z+=0.02f;
         }
         if (keys[KeyEvent.VK_UP])
         {
            xspeed-=0.01f;
         }
         if (keys[KeyEvent.VK_DOWN])
         {
            xspeed+=0.01f;
         }
         if (keys[KeyEvent.VK_RIGHT])
         {
            yspeed+=0.01f;
         }
         if (keys[KeyEvent.VK_LEFT])
         {
            yspeed-=0.01f;
         }
      }
   
   
     /** void display() Draw to the canvas. */
    // Purely a Java thing. Simple calls DrawGLScene once GL is initialized
      public void display()
      
      {
         glj.gljMakeCurrent();      //Ensure GL is initialised correctly
      
         for(int i=0;i<3;i++)
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