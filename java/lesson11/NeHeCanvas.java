/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 11 : Wave Effect
Origional Visual C versions available at  : http://nehe.gamedev.net
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
   
      float[][][] points=new float[45][45][3];    // The Array For The Points On The Grid Of Our "Wave"
      int wiggle_count = 0;		// Counter Used To Control How Fast Flag Waves
      float	xrot;				// X Rotation ( NEW )
      float	yrot;				// Y Rotation ( NEW )
      float	zrot;				// Z Rotation ( NEW )
      float hold;
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
            texLoader.readTexture(codeBase, "data/tim.png");
         else
            texLoader.readTexture("data/tim.png");
      
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
      
         for(int x=0; x<45; x++)
         {
            for(int y=0; y<45; y++)
            {
               points[x][y][0]=(float)((x/5.0f)-4.5f);
               points[x][y][1]=(float)((y/5.0f)-4.5f);
               points[x][y][2]=(float)(Math.sin((((x/5.0f)*40.0f)/360.0f)*3.141592654*2.0f));
            }
         }
      }
   
   
   
   
      public void DrawGLScene()
      {
         int x, y;
         float float_x, float_y, float_xb, float_yb;
      
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();									// Reset The View
      
         gl.glTranslatef(0.0f,0.0f,-12.0f);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);  
         gl.glRotatef(zrot,0.0f,0.0f,1.0f);
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);
      
         gl.glBegin(GL_QUADS);
         for( x = 0; x < 44; x++ )
         {
            for( y = 0; y < 44; y++ )
            {
               float_x = (float)(x)/44.0f;
               float_y = (float)(y)/44.0f;
               float_xb = (float)(x+1)/44.0f;
               float_yb = (float)(y+1)/44.0f;
            
               gl.glTexCoord2f( float_x, float_y);
               gl.glVertex3f( points[x][y][0], points[x][y][1], points[x][y][2] );
            
               gl.glTexCoord2f( float_x, float_yb );
               gl.glVertex3f( points[x][y+1][0], points[x][y+1][1], points[x][y+1][2] );
            
               gl.glTexCoord2f( float_xb, float_yb );
               gl.glVertex3f( points[x+1][y+1][0], points[x+1][y+1][1], points[x+1][y+1][2] );
            
               gl.glTexCoord2f( float_xb, float_y );
               gl.glVertex3f( points[x+1][y][0], points[x+1][y][1], points[x+1][y][2] );
            }
         }
         gl.glEnd();
      
         if( wiggle_count == 2 )
         {
            for( y = 0; y < 45; y++ )
            {
               hold=points[0][y][2];
               for( x = 0; x < 44; x++)
               {
                  points[x][y][2] = points[x+1][y][2];
               }
               points[44][y][2]=hold;
            }
            wiggle_count = 0;
         }
      
         wiggle_count++;
      
         xrot+=0.3f;
         yrot+=0.2f;
         zrot+=0.4f;
      
      }
   
   
     /** void display() Draw to the canvas. */
    // Purely a Java thing. Simple calls DrawGLScene once GL is initialized
      public void display()
      
      {
         for(int i=0;i<1;i++){
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