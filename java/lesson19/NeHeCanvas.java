/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 19 : Particles with Triangle strips
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
      final int MAX_PARTICLES= 1000;
      boolean[] keys=new boolean[256];
      URL codeBase;
   
      boolean	rainbow=true;				// Rainbow Mode?
      boolean	sp;							// Spacebar Pressed?
      boolean	rp;							// Enter Key Pressed?
   
      float	slowdown=2.0f;				// Slow Down Particles
      float	xspeed;						// Base X Speed (To Allow Keyboard Direction Of Tail)
      float	yspeed;						// Base Y Speed (To Allow Keyboard Direction Of Tail)
      float	zoom=-40.0f;				// Used To Zoom Out
   
      int	loop;						// Misc Loop Variable
      int	col;						// Current Color Selection
      int	delay;						// Rainbow Effect Delay
      int[]	texture=new int[1];					// Storage For Our Particle Texture
      class particles
      {
         boolean	active;					// Active (Yes/No)
         float	life;					// Particle Life
         float	fade;					// Fade Speed
         float	r;						// Red Value
         float	g;						// Green Value
         float	b;						// Blue Value
         float	x;						// X Position
         float	y;						// Y Position
         float	z;						// Z Position
         float	xi;						// X Direction
         float	yi;						// Y Direction
         float	zi;						// Z Direction
         float	xg;						// X Gravity
         float	yg;						// Y Gravity
         float	zg;						// Z Gravity
      }
   
      particles[] particle=new particles[1000];
   
      float colors[][]=
      {
         {1.0f,0.5f,0.5f},{1.0f,0.75f,0.5f},{1.0f,1.0f,0.5f},{0.75f,1.0f,0.5f},
         {0.5f,1.0f,0.5f},{0.5f,1.0f,0.75f},{0.5f,1.0f,1.0f},{0.5f,0.75f,1.0f},
         {0.5f,0.5f,1.0f},{0.75f,0.5f,1.0f},{1.0f,0.5f,1.0f},{1.0f,0.5f,0.75f}
      };
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
            texLoader.readTexture(codeBase, "data/particle.png");
         else
            texLoader.readTexture("data/particle.png");
      
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
            stop();
            cvsDispose();
            System.exit(-10);
         }
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glDisable(GL_DEPTH_TEST);                           //Disables Depth Testing
         gl.glEnable(GL_BLEND);
         gl.glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Type Of Blending To Perform
         //gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         gl.glHint(GL_POINT_SMOOTH_HINT,GL_NICEST);				// Really Nice Point Smoothing
         gl.glEnable(GL_TEXTURE_2D);	
         gl.glBindTexture(GL_TEXTURE_2D,texture[0]);			// Select Our Texture
      
         for (loop=0;loop<1000;loop++)				// Initials All The Textures
         {
            particle[loop]=new particles();
            particle[loop].active=true;								// Make All The Particles Active
            particle[loop].life=1.0f;								// Give All The Particles Full Life
            particle[loop].fade=(float)(100 * Math.random())/1000.0f+0.003f;	// Random Fade Speed
            particle[loop].r=colors[loop*(12/MAX_PARTICLES)][0];	// Select Red Rainbow Color
            particle[loop].g=colors[loop*(12/MAX_PARTICLES)][1];	// Select Red Rainbow Color
            particle[loop].b=colors[loop*(12/MAX_PARTICLES)][2];	// Select Red Rainbow Color
            particle[loop].xi=(float)((50 * Math.random())-26.0f)*10.0f;		// Random Speed On X Axis
            particle[loop].yi=(float)((50 * Math.random())-25.0f)*10.0f;		// Random Speed On Y Axis
            particle[loop].zi=(float)((50 * Math.random())-25.0f)*10.0f;		// Random Speed On Z Axis
            particle[loop].xg=0.0f;									// Set Horizontal Pull To Zero
            particle[loop].yg=-0.8f;								// Set Vertical Pull Downward
            particle[loop].zg=0.0f;									// Set Pull On Z Axis To Zero
         }
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();                                         //Reset The View
         for (loop=0;loop<MAX_PARTICLES;loop++)					// Loop Through All The Particles
         {
            if (particle[loop].active)							// If The Particle Is Active
            {
               float x=particle[loop].x;						// Grab Our Particle X Position
               float y=particle[loop].y;						// Grab Our Particle Y Position
               float z=particle[loop].z+zoom;					// Particle Z Pos + Zoom
            
            // Draw The Particle Using Our RGB Values, Fade The Particle Based On It's Life
               gl.glColor4f(particle[loop].r,particle[loop].g,particle[loop].b,particle[loop].life);
            
               gl.glBegin(GL_TRIANGLE_STRIP);						// Build Quad From A Triangle Strip
               gl.glTexCoord2d(1,1); gl.glVertex3f(x+0.5f,y+0.5f,z); // Top Right
               gl.glTexCoord2d(0,1); gl.glVertex3f(x-0.5f,y+0.5f,z); // Top Left
               gl.glTexCoord2d(1,0); gl.glVertex3f(x+0.5f,y-0.5f,z); // Bottom Right
               gl.glTexCoord2d(0,0); gl.glVertex3f(x-0.5f,y-0.5f,z); // Bottom Left
               gl.glEnd();										// Done Building Triangle Strip
            
               particle[loop].x+=particle[loop].xi/(slowdown*1000);// Move On The X Axis By X Speed
               particle[loop].y+=particle[loop].yi/(slowdown*1000);// Move On The Y Axis By Y Speed
               particle[loop].z+=particle[loop].zi/(slowdown*1000);// Move On The Z Axis By Z Speed
            
               particle[loop].xi+=particle[loop].xg;			// Take Pull On X Axis Into Account
               particle[loop].yi+=particle[loop].yg;			// Take Pull On Y Axis Into Account
               particle[loop].zi+=particle[loop].zg;			// Take Pull On Z Axis Into Account
               particle[loop].life-=particle[loop].fade;		// Reduce Particles Life By 'Fade'
            
               if (particle[loop].life<0.0f)					// If Particle Is Burned Out
               {
                  particle[loop].life=1.0f;					// Give It New Life
                  particle[loop].fade=(float)(100 * Math.random())/1000.0f+0.003f;	// Random Fade Value
                  particle[loop].x=0.0f;						// Center On X Axis
                  particle[loop].y=0.0f;						// Center On Y Axis
                  particle[loop].z=0.0f;						// Center On Z Axis
                  particle[loop].xi=xspeed+(float)((60 * Math.random())-32.0f);	// X Axis Speed And Direction
                  particle[loop].yi=yspeed+(float)((60 * Math.random())-30.0f);	// Y Axis Speed And Direction
                  particle[loop].zi=(float)((60 * Math.random())-30.0f);	// Z Axis Speed And Direction
                  particle[loop].r=colors[col][0];			// Select Red From Color Table
                  particle[loop].g=colors[col][1];			// Select Green From Color Table
                  particle[loop].b=colors[col][2];			// Select Blue From Color Table
               }
            
            // If Number Pad 8 And Y Gravity Is Less Than 1.5 Increase Pull Upwards
               if (keys[KeyEvent.VK_UP] && (particle[loop].yg<1.5f)) particle[loop].yg+=0.01f;
            
            // If Number Pad 2 And Y Gravity Is Greater Than -1.5 Increase Pull Downwards
               if (keys[KeyEvent.VK_DOWN] && (particle[loop].yg>-1.5f)) particle[loop].yg-=0.01f;
            
            // If Number Pad 6 And X Gravity Is Less Than 1.5 Increase Pull Right
               if (keys[KeyEvent.VK_RIGHT] && (particle[loop].xg<1.5f)) particle[loop].xg+=0.01f;
            
            // If Number Pad 4 And X Gravity Is Greater Than -1.5 Increase Pull Left
               if (keys[KeyEvent.VK_LEFT] && (particle[loop].xg>-1.5f)) particle[loop].xg-=0.01f;
            
               if (keys[KeyEvent.VK_TAB])										// Tab Key Causes A Burst
               {
                  particle[loop].x=0.0f;								// Center On X Axis
                  particle[loop].y=0.0f;								// Center On Y Axis
                  particle[loop].z=0.0f;								// Center On Z Axis
                  particle[loop].xi=(float)((50 * Math.random())-26.0f)*10.0f;	// Random Speed On X Axis
                  particle[loop].yi=(float)((50 * Math.random())-25.0f)*10.0f;	// Random Speed On Y Axis
                  particle[loop].zi=(float)((50 * Math.random())-25.0f)*10.0f;	// Random Speed On Z Axis
               }
            
            }
         
         }
         if (keys[KeyEvent.VK_ADD] && (slowdown>1.0f)) slowdown-=0.01f;		// Speed Up Particles
         if (keys[KeyEvent.VK_SUBTRACT] && (slowdown<4.0f)) slowdown+=0.01f;	// Slow Down Particles
      
         if (keys[KeyEvent.VK_PAGE_UP])	zoom+=0.1f;		// Zoom In
         if (keys[KeyEvent.VK_PAGE_DOWN])	zoom-=0.1f;		// Zoom Out
      
         if (keys[KeyEvent.VK_ENTER] && !rp)			// Return Key Pressed
         {
            rp=true;						// Set Flag Telling Us It's Pressed
            rainbow=!rainbow;				// Toggle Rainbow Mode On / Off
         }
         if (!keys[KeyEvent.VK_ENTER]) rp=false;		// If Return Is Released Clear Flag
      
         if ((keys[' '] && !sp) || (rainbow && (delay>25)))	// Space Or Rainbow Mode
         {
            if (keys[' '])	rainbow=false;	// If Spacebar Is Pressed Disable Rainbow Mode
            sp=true;						// Set Flag Telling Us Space Is Pressed
            delay=0;						// Reset The Rainbow Color Cycling Delay
            col++;							// Change The Particle Color
            if (col>11)	col=0;				// If Color Is To High Reset It
         }
         if (!keys[' '])	sp=false;			// If Spacebar Is Released Clear Flag
      
            // If Up Arrow And Y Speed Is Less Than 200 Increase Upward Speed
         if (keys[KeyEvent.VK_UP] && (yspeed<200)) yspeed+=1.0f;
      
            // If Down Arrow And Y Speed Is Greater Than -200 Increase Downward Speed
         if (keys[KeyEvent.VK_DOWN] && (yspeed>-200)) yspeed-=1.0f;
      
            // If Right Arrow And X Speed Is Less Than 200 Increase Speed To The Right
         if (keys[KeyEvent.VK_RIGHT] && (xspeed<200)) xspeed+=1.0f;
      
            // If Left Arrow And X Speed Is Greater Than -200 Increase Speed To The Left
         if (keys[KeyEvent.VK_LEFT] && (xspeed>-200)) xspeed-=1.0f;
      
         delay++;							// Increase Rainbow Mode Color Cycling Delay Counter	
      
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