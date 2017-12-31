/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 18 : Quadratics
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
      boolean  sp;               // spacebar presses? ( new )
   
      int		part1;				// Start Of Disc ( NEW )
      int		part2;				// End Of Disc ( NEW )
      int		p1=0;				   // Increase 1 ( NEW )
      int		p2=1;				   // Increase 2 ( NEW )
   
      float	xrot;				      // X Rotation
      float	yrot;				      // Y Rotation
      float xspeed;				   // X Rotation Speed
      float yspeed;				   // Y Rotation Speed
      float	z=-5.0f;			      // Depth Into The Screen
   
      long quadratic;	         // Storage For Our Quadratic Objects ( NEW )
   
      float[] LightAmbient=		{ 0.5f, 0.5f, 0.5f, 1.0f };
      float[] LightDiffuse=		{ 1.0f, 1.0f, 1.0f, 1.0f };
      float[] LightPosition=	{ 0.0f, 0.0f, 2.0f, 1.0f };
   
      int	filter;				    // Which Filter To Use
      int[]	texture=new int[3];   // Storage For 3 Textures
      int object=0;               // which object to draw ( NEW ) 
   
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
            texLoader.readTexture(codeBase, "data/wall.png");
         else
            texLoader.readTexture("data/wall.png");
      
      
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
            System.exit(0);
         
         }
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
      
         gl.glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);		// Setup The Ambient Light
         gl.glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);		// Setup The Diffuse Light
         gl.glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);	// Position The Light
         gl.glEnable(GL_LIGHT1);								// Enable Light One
      
         quadratic=glu.gluNewQuadric();                      // Create A Pointer To The Quadric Object ( NEW )
         glu.gluQuadricNormals(quadratic, GLU_SMOOTH);       // Create Smooth Normals ( NEW )
         glu.gluQuadricTexture(quadratic, GL_TRUE);          // Create Texture Coords ( NEW 
      
      
      }
   
   
   
      private void glDrawCube() {
      
      
         gl.glBegin(GL_QUADS);
         //Front Face
         gl.glNormal3f(0.0f, 0.0f, 1.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);  //Bottom Left Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);  //Bottom Right Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);  //Top Right Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);  //Top Left Of The Texture and Quad
         //Back Face
         gl.glNormal3f(0.0f, 0.0f, -1.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);  //Bottom Right Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);  //Top Right Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);  //Top Left Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);  //Bottom Left Of The Texture and Quad
         //Top Face
         gl.glNormal3f(0.0f, 1.0f, 0.0f);
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);  //Top Left Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);  //Bottom Left Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);  //Bottom Right Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);  //Top Right Of The Texture and Quad
         //Bottom Face
         gl.glNormal3f(0.0f, -1.0f, 0.0f);
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);  //Top Right Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);  //Top Left Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);  //Bottom Left Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);  //Bottom Right Of The Texture and Quad
         //Right face
         gl.glNormal3f(1.0f, 0.0f, 0.0f);
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f, -1.0f);  //Bottom Right Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f, -1.0f);  //Top Right Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f( 1.0f,  1.0f,  1.0f);  //Top Left Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f( 1.0f, -1.0f,  1.0f);  //Bottom Left Of The Texture and Quad
         //Left Face
         gl.glNormal3f(-1.0f, 0.0f, 0.0f);
         gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f, -1.0f);  //Bottom Left Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f(-1.0f, -1.0f,  1.0f);  //Bottom Right Of The Texture and Quad
         gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f,  1.0f);  //Top Right Of The Texture and Quad
         gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f,  1.0f, -1.0f);  //Top Left Of The Texture and Quad
         gl.glEnd();
      }
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();                                         //Reset The View
         gl.glTranslatef(0.0f,0.0f,z);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[filter]);
      
         switch(object)
         {
            case 0:
               glDrawCube();
               break;
            case 1:
               gl.glTranslatef(0.0f,0.0f,-1.5f);					// Center The Cylinder
               glu.gluCylinder(quadratic,1.0f,1.0f,3.0f,32,32);	// A Cylinder With A Radius Of 0.5 And A Height Of 2
               break;
            case 2:
               glu.gluDisk(quadratic,0.5f,1.5f,32,32);				// Draw A Disc (CD Shape) With An Inner Radius Of 0.5, And An Outer Radius Of 2.  Plus A Lot Of Segments ;)
               break;
            case 3:
               glu.gluSphere(quadratic,1.3f,32,32);				// Draw A Sphere With A Radius Of 1 And 16 Longitude And 16 Latitude Segments
               break;
            case 4:
               gl.glTranslatef(0.0f,0.0f,-1.5f);					// Center The Cone
               glu.gluCylinder(quadratic,1.0f,0.0f,3.0f,32,32);	// A Cone With A Bottom Radius Of .5 And A Height Of 2
               break;
            case 5:
               part1+=p1;
               part2+=p2;
            
               if(part1>359)									// 360 Degrees
               {
                  p1=0;
                  part1=0;
                  p2=1;
                  part2=0;
               }
               if(part2>359)									// 360 Degrees
               {
                  p1=1;
                  p2=0;
               }
               glu.gluPartialDisk(quadratic,0.5f,1.5f,32,32,part1,part2-part1);	// A Disk Like The One Before
               break;
         };
      
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
         if (keys[' '] && !sp)
         {
            sp=true;
            object++;
            if(object>5)
               object=0;
         }
         if (!keys[' '])
         {
            sp=false;
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