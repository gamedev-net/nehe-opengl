/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 9 : Moving Bitmaps In 3D Space
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
      boolean	twinkle;			// Twinkling Stars
      boolean	tp;					// 'T' Key Pressed?
      URL codeBase;
   
      final int num=50;				// Number Of Stars To Draw
      class stars				// Create A Structure For Star
      
      {
         int r=0, g=0, b=0;			// Stars Color
         float dist=0.0f,angle=0.0f;			// Stars Current Angle & Distance From Center
      }
      stars[] star=new stars[num];			// Need To Keep Track Of 'num' Stars
   
      float	zoom=-15.0f;		// Distance Away From Stars
      float tilt=90.0f;			// Tilt The View
      float	spin;				// Spin Stars
   
      int	loop;				// General Loop Variable
      int[]	texture=new int[1];			// Storage For One textures
   
   
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
            texLoader.readTexture(codeBase, "data/star.png");
         else
            texLoader.readTexture("data/star.png");
      
      
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
      // if we don't have a texture, crash out
         if(!LoadGLTextures())
         {
            System.out.println("Failed to load Textures,Bailing!");
            System.exit(-10);
         }
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glEnable(GL_TEXTURE_2D);							       // Enable Texture Mapping
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         gl.glBlendFunc(GL_SRC_ALPHA,GL_ONE);                   // Set The Blending Function For Translucency
         gl.glEnable(GL_BLEND);
      
         for (loop=0; loop<num; loop++)
         {
            star[loop] = new stars();
            star[loop].angle=0.0f;
            star[loop].dist=((float)(loop)/num)*5.0f;
            star[loop].r=(int)(256 * Math.random());
            star[loop].g=(int)(256 * Math.random());
            star[loop].b=(int)(256 * Math.random());
         }
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);			// Select Our Texture
      
         for (loop=0; loop<num; loop++)						// Loop Through All The Stars
         {
            gl.glLoadIdentity();								// Reset The View Before We Draw Each Star
            gl.glTranslatef(0.0f,0.0f,zoom);					// Zoom Into The Screen (Using The Value In 'zoom')
            gl.glRotatef(tilt,1.0f,0.0f,0.0f);					// Tilt The View (Using The Value In 'tilt')
            gl.glRotatef(star[loop].angle,0.0f,1.0f,0.0f);		// Rotate To The Current Stars Angle
            gl.glTranslatef(star[loop].dist,0.0f,0.0f);		// Move Forward On The X Plane
            gl.glRotatef(-star[loop].angle,0.0f,1.0f,0.0f);	// Cancel The Current Stars Angle
            gl.glRotatef(-tilt,1.0f,0.0f,0.0f);				// Cancel The Screen Tilt
         
            if (twinkle)
            {
               gl.glColor4ub((byte)star[(num-loop)-1].r,(byte)star[(num-loop)-1].g,(byte)star[(num-loop)-1].b,(byte)255);
               gl.glBegin(GL_QUADS);
               gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,-1.0f, 0.0f);
               gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,-1.0f, 0.0f);
               gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f, 1.0f, 0.0f);
               gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f, 1.0f, 0.0f);
               gl.glEnd();
            }
         
            gl.glRotatef(spin,0.0f,0.0f,1.0f);
            gl.glColor4ub((byte)star[loop].r,(byte)star[loop].g,(byte)star[loop].b,(byte)255);
            gl.glBegin(GL_QUADS);
            gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-1.0f,-1.0f, 0.0f);
            gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 1.0f,-1.0f, 0.0f);
            gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 1.0f, 1.0f, 0.0f);
            gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-1.0f, 1.0f, 0.0f);
            gl.glEnd();
         
            spin+=0.01f;
            star[loop].angle+=(float)(loop)/num;
            star[loop].dist-=0.01f;
            if (star[loop].dist<0.0f)
            {
               star[loop].dist+=5.0f;
               star[loop].r=(int)(256 * Math.random());
               star[loop].g=(int)(256 * Math.random());
               star[loop].b=(int)(256 * Math.random());
            }
         }
      }
   
   
     /** void display() Draw to the canvas. */
    // Purely a Java thing. Simple calls DrawGLScene once GL is initialized
      public void display()
      
      {
         glj.gljMakeCurrent();      //Ensure GL is initialised correctly
         for(int i=0;i<2;i++) // to get more performace.. damn slow event driven drawing
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