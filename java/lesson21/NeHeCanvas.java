/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 21 : Lines, Antialiasing, Timing, Ortho View And Simple Sounds
Origional Visual C versions available at  : nehe.gamedev.net


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
   import java.applet.AudioClip;
   import java.applet.*;
   import java.net.MalformedURLException;




   class NeHeCanvas extends GLAnimCanvas implements KeyListener, MouseListener
   
   {   
     // holds information on which keys are held down.
      boolean[] keys=new boolean[256];
      URL codeBase;
      boolean[][]	vline=new boolean[11][11];										// Keeps Track Of Verticle Lines
      boolean[][]	hline=new boolean[11][11];										// Keeps Track Of Horizontal Lines
      boolean	ap;													// 'A' Key Pressed?
      boolean	filled;												// Done Filling In The Grid?
      boolean	gameover;											// Is The Game Over?
      boolean	anti=true;											// Antialiasing?
   
      int		loop1=0;												// Generic Loop1
      int		loop2=0;												// Generic Loop2
      int		delay;												// Enemy Delay
      int		adjust=3;											// Speed Adjustment For Really Slow Video Cards
      int		lives=5;											// Player Lives
      int		level=1;											// Internal Game Level
      int		level2=level;										// Displayed Game Level
      int		stage=1;											// Game Stage
      class	object												// Create A Structure For Our Player
      
      {
         int		fx, fy;											// Fine Movement Position
         int		x, y;											// Current Player Position
         float	spin;											// Spin Direction
      
      }
   
      object player=new object();										// Player Information
      object[] enemy=new object[9];									// Enemy Information
      object hourglass=new object();									// Hourglass Information
      AudioClip audioClip;
   
      public NeHeCanvas(int w, int h)
      
      {
         super(w, h);
      
         //Registers this canvas to process keyboard events, and Mouse events
         addKeyListener(this);
         addMouseListener(this);   
         setAnimateFps(60); // seemed to be essential in getting any performance 
         for(int i=0;i<9;i++)
            enemy[i]=new object();
      
      
      
      }
   
   	/*
      class timer			 											// Create A Structure For The Timer Information
      
      {
         __int64       frequency;									// Timer Frequency
         float         resolution;									// Timer Resolution
         long mm_timer_start;								// Multimedia Timer Start Value
         long mm_timer_elapsed;							// Multimedia Timer Elapsed Time
         bool			performance_timer;							// Using The Performance Timer?
         __int64       performance_timer_start;					// Performance Timer Start Value
         __int64       performance_timer_elapsed;					// Performance Timer Elapsed Time
      }
   	*/
      int		steps[]={ 1, 2, 4, 5, 10, 20 };					// Stepping Values For Slow Video Adjustment
   
      int	texture[]=new int[2];											// Font Texture Storage Space
      int	base;			
   
      public void TimerInit()
      {
      
      }
      float TimerGetTime() // return start time - current time
      {
         return 1.0f;
      }
   
      public void ResetObjects()										// Reset Player And Enemies
      
      {
         player.x=0;												// Reset Player X Position To Far Left Of The Screen
         player.y=0;												// Reset Player Y Position To The Top Of The Screen
         player.fx=0;											// Set Fine X Position To Match
         player.fy=0;											// Set Fine Y Position To Match
      
         for (loop1=0; loop1<(stage*level); loop1++)				// Loop Through All The Enemies
         {
            enemy[loop1]=new object();
            enemy[loop1].x=5+(int)(Math.random()*6);							// Select A Random X Position
            enemy[loop1].y=(int)Math.random()*11;							// Select A Random Y Position
            enemy[loop1].fx=enemy[loop1].x*60;					// Set Fine X To Match
            enemy[loop1].fy=enemy[loop1].y*40;					// Set Fine Y To Match
         }
      }
   
      public boolean LoadGLTextures()
      
      
      
      {
         String tileNames [] = {"data/font.png","data/Image.png"};
      
      
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
   
      void BuildFont()									// Build Our Font Display List
      
      {
         base=gl.glGenLists(256);									// Creating 256 Display Lists
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);				// Select Our Font Texture
         for (loop1=0; loop1<256; loop1++)						// Loop Through All 256 Lists
         {
            float cx=(float)(loop1%16)/16.0f;						// X Position Of Current Character
            float cy=(float)(loop1/16)/16.0f;						// Y Position Of Current Character
         
            gl.glNewList(base+loop1,GL_COMPILE);					// Start Building A List
            gl.glBegin(GL_QUADS);								// Use A Quad For Each Character
            gl.glTexCoord2f(cx,1.0f-cy-0.0625f);			// Texture Coord (Bottom Left)
            gl.glVertex2d(0,16);							// Vertex Coord (Bottom Left)
            gl.glTexCoord2f(cx+0.0625f,1.0f-cy-0.0625f);	// Texture Coord (Bottom Right)
            gl.glVertex2i(16,16);							// Vertex Coord (Bottom Right)
            gl.glTexCoord2f(cx+0.0625f,1.0f-cy);			// Texture Coord (Top Right)
            gl.glVertex2i(16,0);							// Vertex Coord (Top Right)
            gl.glTexCoord2f(cx,1.0f-cy);					// Texture Coord (Top Left)
            gl.glVertex2i(0,0);							// Vertex Coord (Top Left)
            gl.glEnd();										// Done Building Our Quad (Character)
            gl.glTranslated(15,0,0);							// Move To The Right Of The Character
            gl.glEndList();										// Done Building The Display List
         }														// Loop Until All 256 Are Built
      }
      void glPrint2(int x, int y, int set,String string)	// Where The Printing Happens
      
      
      {
         if (set>1)
         {
            set=1;
         }
         gl.glEnable(GL_TEXTURE_2D);
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
      void glPrint(int x, int y, int set, String message)	// Where The Printing Happens
      
      {
         if (set>1)												// Did User Choose An Invalid Character Set?
         {
            set=1;												// If So, Select Set 1 (Italic)
         }
         gl.glEnable(GL_TEXTURE_2D);								// Enable Texture Mapping
         gl.glLoadIdentity();										// Reset The Modelview Matrix
         gl.glTranslated(x,y,0);									// Position The Text (0,0 - Bottom Left)
         gl.glListBase(base-32+(128*set));							// Choose The Font Set (0 or 1)
      
         if (set==0)												// If Set 0 Is Being Used Enlarge Font
         {
            gl.glScalef(1.5f,2.0f,1.0f);							// Enlarge Font Width And Height
         }
      
         gl.glCallLists(message.length(),GL_UNSIGNED_BYTE,message.getBytes());		// Write The Text To The Screen
         gl.glDisable(GL_TEXTURE_2D);								// Disable Texture Mapping
      }
   
    /** void reshape(int width, int height) Called after the first paint command.  */
   
      public void reshape(int width, int height)
      {
         if(height==0)height=1;
         gl.glViewport(0, 0, width, height);                       // Reset The Current Viewport And Perspective Transformation
         gl.glMatrixMode(GL_PROJECTION);                           // Select The Projection Matrix
         gl.glLoadIdentity();                                      // Reset The Projection Matrix
         gl.glOrtho(0.0f,width,height,0.0f,-1.0f,1.0f);				// Create Ortho 640x480 View (0,0 At Top Left)
      
         //glu.gluPerspective(45.0f, width / height, 0.1f, 100.0f);  // Calculate The Aspect Ratio Of The Window
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
      
         BuildFont();
      
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         gl.glEnable(GL_BLEND);										// Enable Blending
         gl.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);		// Type Of Blending To Use
         gl.glEnable(GL_TEXTURE_2D);							// Enable 2D Texture Mapping
         ResetObjects();							// Reset Player / Enemy Positions
      
      }
   
   
   
   
      public void DrawGLScene()
      {
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
      
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);				// Select Our Font Texture
         gl.glColor3f(1.0f,0.5f,1.0f);								// Set Color To Purple
         glPrint(207,24,0,"GRID CRAZY");							// Write GRID CRAZY On The Screen
         gl.glColor3f(1.0f,1.0f,0.0f);								// Set Color To Yellow
         glPrint(20,20,1,"Level:"+level2);					// Write Actual Level Stats
         glPrint(20,40,1,"Stage:"+stage);						// Write Stage Stats
      
      
         if (gameover)											// Is The Game Over?
         {
            gl.glColor3ub((byte)(Math.random()*255),(byte)(Math.random()*255),(byte)(Math.random()*255));		// Pick A Random Color
            glPrint(472,20,1,"GAME OVER");						// Write GAME OVER To The Screen
            glPrint(456,40,1,"PRESS SPACE");					// Write PRESS SPACE To The Screen
         }
      
         for (loop1=0; loop1<lives-1; loop1++)					// Loop Through Lives Minus Current Life
         {
            gl.glLoadIdentity();									// Reset The View
            gl.glTranslatef(490+(loop1*40.0f),40.0f,0.0f);			// Move To The Right Of Our Title Text
            gl.glRotatef(-player.spin,0.0f,0.0f,1.0f);				// Rotate Counter Clockwise
            gl.glColor3f(0.0f,1.0f,0.0f);							// Set Player Color To Light Green
            gl.glBegin(GL_LINES);									// Start Drawing Our Player Using Lines
            gl.glVertex2d(-5,-5);								// Top Left Of Player
            gl.glVertex2d( 5, 5);								// Bottom Right Of Player
            gl.glVertex2d( 5,-5);								// Top Right Of Player
            gl.glVertex2d(-5, 5);								// Bottom Left Of Player
            gl.glEnd();											// Done Drawing The Player
            gl.glRotatef(-player.spin*0.5f,0.0f,0.0f,1.0f);		// Rotate Counter Clockwise
            gl.glColor3f(0.0f,0.75f,0.0f);							// Set Player Color To Dark Green
            gl.glBegin(GL_LINES);									// Start Drawing Our Player Using Lines
            gl.glVertex2d(-7, 0);								// Left Center Of Player
            gl.glVertex2d( 7, 0);								// Right Center Of Player
            gl.glVertex2d( 0,-7);								// Top Center Of Player
            gl.glVertex2d( 0, 7);								// Bottom Center Of Player
            gl.glEnd();											// Done Drawing The Player
         }
      
         filled=true;											// Set Filled To True Before Testing
         gl.glLineWidth(2.0f);										// Set Line Width For Cells To 2.0f
         gl.glDisable(GL_LINE_SMOOTH);								// Disable Antialiasing
         gl.glLoadIdentity();										// Reset The Current Modelview Matrix
         for (loop1=0; loop1<11; loop1++)						// Loop From Left To Right
         {
            for (loop2=0; loop2<11; loop2++)					// Loop From Top To Bottom
            {
            
               gl.glColor3f(0.0f,0.5f,1.0f);						// Set Line Color To Blue
               if (hline[loop1][loop2])						// Has The Horizontal Line Been Traced
               {
                  gl.glColor3f(1.0f,1.0f,1.0f);					// If So, Set Line Color To White
               }
            
               if (loop1<10)									// Dont Draw To Far Right
               {
                  if (!hline[loop1][loop2])					// If A Horizontal Line Isn't Filled
                  {
                     filled=false;							// filled Becomes False
                  }
                  gl.glBegin(GL_LINES);							// Start Drawing Horizontal Cell Borders
                  gl.glVertex2d(20+(loop1*60),70+(loop2*40));// Left Side Of Horizontal Line
                  gl.glVertex2d(80+(loop1*60),70+(loop2*40));// Right Side Of Horizontal Line
                  gl.glEnd();									// Done Drawing Horizontal Cell Borders
               }
            
               gl.glColor3f(0.0f,0.5f,1.0f);						// Set Line Color To Blue
               if (vline[loop1][loop2])						// Has The Horizontal Line Been Traced
               {
                  gl.glColor3f(1.0f,1.0f,1.0f);					// If So, Set Line Color To White
               }
               if (loop2<10)									// Dont Draw To Far Down
               {
                  if (!vline[loop1][loop2])					// If A Verticle Line Isn't Filled
                  {
                     filled=false;							// filled Becomes False
                  }
                  gl.glBegin(GL_LINES);							// Start Drawing Verticle Cell Borders
                  gl.glVertex2d(20+(loop1*60),70+(loop2*40));// Left Side Of Horizontal Line
                  gl.glVertex2d(20+(loop1*60),110+(loop2*40));// Right Side Of Horizontal Line
                  gl.glEnd();									// Done Drawing Verticle Cell Borders
               }
            
               gl.glEnable(GL_TEXTURE_2D);						// Enable Texture Mapping
               gl.glColor3f(1.0f,1.0f,1.0f);						// Bright White Color
               gl.glBindTexture(GL_TEXTURE_2D, texture[1]);		// Select The Tile Image
               if ((loop1<10) && (loop2<10))					// If In Bounds, Fill In Traced Boxes
               {
               // Are All Sides Of The Box Traced?
                  if (hline[loop1][loop2] && hline[loop1][loop2+1] && vline[loop1][loop2] && vline[loop1+1][loop2])
                  {
                     gl.glBegin(GL_QUADS);						// Draw A Textured Quad
                     gl.glTexCoord2f((float)(loop1/10.0f)+0.1f,1.0f-((float)(loop2/10.0f)));
                     gl.glVertex2d(20+(loop1*60)+59,(70+loop2*40+1));	// Top Right
                     gl.glTexCoord2f((float)(loop1/10.0f),1.0f-((float)(loop2/10.0f)));
                     gl.glVertex2d(20+(loop1*60)+1,(70+loop2*40+1));	// Top Left
                     gl.glTexCoord2f((float)(loop1/10.0f),1.0f-((float)(loop2/10.0f)+0.1f));
                     gl.glVertex2d(20+(loop1*60)+1,(70+loop2*40)+39);	// Bottom Left
                     gl.glTexCoord2f((float)(loop1/10.0f)+0.1f,1.0f-((float)(loop2/10.0f)+0.1f));
                     gl.glVertex2d(20+(loop1*60)+59,(70+loop2*40)+39);	// Bottom Right
                     gl.glEnd();								// Done Texturing The Box
                  }
               }
               gl.glDisable(GL_TEXTURE_2D);						// Disable Texture Mapping
            
            }
         }
         gl.glLineWidth(1.0f);										// Set The Line Width To 1.0f
      
         if (anti)												// Is Anti TRUE?
         {
            gl.glEnable(GL_LINE_SMOOTH);							// If So, Enable Antialiasing
         }
      
         if (hourglass.fx==1)									// If fx=1 Draw The Hourglass
         {
            gl.glLoadIdentity();									// Reset The Modelview Matrix
            gl.glTranslatef(20.0f+(hourglass.x*60),70.0f+(hourglass.y*40),0.0f);	// Move To The Fine Hourglass Position
            gl.glRotatef(hourglass.spin,0.0f,0.0f,1.0f);			// Rotate Clockwise
            gl.glColor3ub((byte)(Math.random()%255),(byte)(Math.random()%255),(byte)(Math.random()%255));		// Set Hourglass Color To Random Color
            gl.glBegin(GL_LINES);									// Start Drawing Our Hourglass Using Lines
            gl.glVertex2d(-5,-5);								// Top Left Of Hourglass
            gl.glVertex2d( 5, 5);								// Bottom Right Of Hourglass
            gl.glVertex2d( 5,-5);								// Top Right Of Hourglass
            gl.glVertex2d(-5, 5);								// Bottom Left Of Hourglass
            gl.glVertex2d(-5, 5);								// Bottom Left Of Hourglass
            gl.glVertex2d( 5, 5);								// Bottom Right Of Hourglass
            gl.glVertex2d(-5,-5);								// Top Left Of Hourglass
            gl.glVertex2d( 5,-5);								// Top Right Of Hourglass
            gl.glEnd();											// Done Drawing The Hourglass
         }
      
         gl.glLoadIdentity();										// Reset The Modelview Matrix
         gl.glTranslatef(player.fx+20.0f,player.fy+70.0f,0.0f);		// Move To The Fine Player Position
         gl.glRotatef(player.spin,0.0f,0.0f,1.0f);					// Rotate Clockwise
         gl.glColor3f(0.0f,1.0f,0.0f);								// Set Player Color To Light Green
         gl.glBegin(GL_LINES);										// Start Drawing Our Player Using Lines
         gl.glVertex2d(-5,-5);									// Top Left Of Player
         gl.glVertex2d( 5, 5);									// Bottom Right Of Player
         gl.glVertex2d( 5,-5);									// Top Right Of Player
         gl.glVertex2d(-5, 5);									// Bottom Left Of Player
         gl.glEnd();												// Done Drawing The Player
         gl.glRotatef(player.spin*0.5f,0.0f,0.0f,1.0f);				// Rotate Clockwise
         gl.glColor3f(0.0f,0.75f,0.0f);								// Set Player Color To Dark Green
         gl.glBegin(GL_LINES);										// Start Drawing Our Player Using Lines
         gl.glVertex2d(-7, 0);									// Left Center Of Player
         gl.glVertex2d( 7, 0);									// Right Center Of Player
         gl.glVertex2d( 0,-7);									// Top Center Of Player
         gl.glVertex2d( 0, 7);									// Bottom Center Of Player
         gl.glEnd();												// Done Drawing The Player
      
         for (loop1=0; loop1<(stage*level); loop1++)				// Loop To Draw Enemies
         {
            gl.glLoadIdentity();									// Reset The Modelview Matrix
            gl.glTranslatef(enemy[loop1].fx+20.0f,enemy[loop1].fy+70.0f,0.0f);
            gl.glColor3f(1.0f,0.5f,0.5f);							// Make Enemy Body Pink
            gl.glBegin(GL_LINES);									// Start Drawing Enemy
            gl.glVertex2d( 0,-7);								// Top Point Of Body
            gl.glVertex2d(-7, 0);								// Left Point Of Body
            gl.glVertex2d(-7, 0);								// Left Point Of Body
            gl.glVertex2d( 0, 7);								// Bottom Point Of Body
            gl.glVertex2d( 0, 7);								// Bottom Point Of Body
            gl.glVertex2d( 7, 0);								// Right Point Of Body
            gl.glVertex2d( 7, 0);								// Right Point Of Body
            gl.glVertex2d( 0,-7);								// Top Point Of Body
            gl.glEnd();											// Done Drawing Enemy Body
            gl.glRotatef(enemy[loop1].spin,0.0f,0.0f,1.0f);		// Rotate The Enemy Blade
            gl.glColor3f(1.0f,0.0f,0.0f);							// Make Enemy Blade Red
            gl.glBegin(GL_LINES);									// Start Drawing Enemy Blade
            gl.glVertex2d(-7,-7);								// Top Left Of Enemy
            gl.glVertex2d( 7, 7);								// Bottom Right Of Enemy
            gl.glVertex2d(-7, 7);								// Bottom Left Of Enemy
            gl.glVertex2d( 7,-7);								// Top Right Of Enemy
            gl.glEnd();											// Done Drawing Enemy Blade
         }
         if (keys['A'] && !ap)								// If 'A' Key Is Pressed And Not Held
         {
            ap=true;										// ap Becomes TRUE
            anti=!anti;										// Toggle Antialiasing
         }
         if (!keys['A'])										// If 'A' Key Has Been Released
         {
            ap=false;										// ap Becomes FALSE
         }
      
         if (!gameover )							// If Game Isn't Over And Programs Active Move Objects
         {
            for (loop1=0; loop1<(stage*level); loop1++)		// Loop Through The Different Stages
            {
               if ((enemy[loop1].x<player.x) && (enemy[loop1].fy==enemy[loop1].y*40))
               {
                  enemy[loop1].x++;						// Move The Enemy Right
               }
            
               if ((enemy[loop1].x>player.x) && (enemy[loop1].fy==enemy[loop1].y*40))
               {
                  enemy[loop1].x--;						// Move The Enemy Left
               }
            
               if ((enemy[loop1].y<player.y) && (enemy[loop1].fx==enemy[loop1].x*60))
               {
                  enemy[loop1].y++;						// Move The Enemy Down
               }
            
               if ((enemy[loop1].y>player.y) && (enemy[loop1].fx==enemy[loop1].x*60))
               {
                  enemy[loop1].y--;						// Move The Enemy Up
               }
            
               if (delay>(3-level) && (hourglass.fx!=2))	// If Our Delay Is Done And Player Doesn't Have Hourglass
               {
                  delay=0;								// Reset The Delay Counter Back To Zero
                  for (loop2=0; loop2<(stage*level); loop2++)	// Loop Through All The Enemies
                  {
                     if (enemy[loop2].fx<enemy[loop2].x*60)	// Is Fine Position On X Axis Lower Than Intended Position?
                     {
                        enemy[loop2].fx+=steps[adjust];	// If So, Increase Fine Position On X Axis
                        enemy[loop2].spin+=steps[adjust];	// Spin Enemy Clockwise
                     }
                     if (enemy[loop2].fx>enemy[loop2].x*60)	// Is Fine Position On X Axis Higher Than Intended Position?
                     {
                        enemy[loop2].fx-=steps[adjust];	// If So, Decrease Fine Position On X Axis
                        enemy[loop2].spin-=steps[adjust];	// Spin Enemy Counter Clockwise
                     }
                     if (enemy[loop2].fy<enemy[loop2].y*40)	// Is Fine Position On Y Axis Lower Than Intended Position?
                     {
                        enemy[loop2].fy+=steps[adjust];	// If So, Increase Fine Position On Y Axis
                        enemy[loop2].spin+=steps[adjust];	// Spin Enemy Clockwise
                     }
                     if (enemy[loop2].fy>enemy[loop2].y*40)	// Is Fine Position On Y Axis Higher Than Intended Position?
                     {
                        enemy[loop2].fy-=steps[adjust];	// If So, Decrease Fine Position On Y Axis
                        enemy[loop2].spin-=steps[adjust];	// Spin Enemy Counter Clockwise
                     }
                  }
               }
            
               // Are Any Of The Enemies On Top Of The Player?
               if ((enemy[loop1].fx==player.fx) && (enemy[loop1].fy==player.fy))
               {
                  lives--;								// If So, Player Loses A Life
               
                  if (lives==0)							// Are We Out Of Lives?
                  {
                     gameover=true;						// If So, gameover Becomes TRUE
                  }
                  PlaySound("Data/Die.wav",false);	// Play The Death Sound           //SOUND
                  ResetObjects();							// Reset Player / Enemy Positions
               
               }
            }
         
            if (keys[KeyEvent.VK_RIGHT] && (player.x<10) && (player.fx==player.x*60) && (player.fy==player.y*40))
            {
               hline[player.x][player.y]=true;				// Mark The Current Horizontal Border As Filled
               player.x++;									// Move The Player Right
            }
            if (keys[KeyEvent.VK_LEFT] && (player.x>0) && (player.fx==player.x*60) && (player.fy==player.y*40))
            {
               player.x--;									// Move The Player Left
               hline[player.x][player.y]=true;				// Mark The Current Horizontal Border As Filled
            }
            if (keys[KeyEvent.VK_DOWN] && (player.y<10) && (player.fx==player.x*60) && (player.fy==player.y*40))
            {
               vline[player.x][player.y]=true;				// Mark The Current Verticle Border As Filled
               player.y++;									// Move The Player Down
            }
            if (keys[KeyEvent.VK_UP] && (player.y>0) && (player.fx==player.x*60) && (player.fy==player.y*40))
            {
               player.y--;									// Move The Player Up
               vline[player.x][player.y]=true;				// Mark The Current Verticle Border As Filled
            }
         
            if (player.fx<player.x*60)						// Is Fine Position On X Axis Lower Than Intended Position?
            {
               player.fx+=steps[adjust];					// If So, Increase The Fine X Position
            }
            if (player.fx>player.x*60)						// Is Fine Position On X Axis Greater Than Intended Position?
            {
               player.fx-=steps[adjust];					// If So, Decrease The Fine X Position
            }
            if (player.fy<player.y*40)						// Is Fine Position On Y Axis Lower Than Intended Position?
            {
               player.fy+=steps[adjust];					// If So, Increase The Fine Y Position
            }
            if (player.fy>player.y*40)						// Is Fine Position On Y Axis Lower Than Intended Position?
            {
               player.fy-=steps[adjust];					// If So, Decrease The Fine Y Position
            }
         }
         else												// Otherwise
         {
            if (keys[' '])									// If Spacebar Is Being Pressed
            {
               gameover=false;								// gameover Becomes FALSE
               filled=true;								// filled Becomes TRUE
               level=1;									// Starting Level Is Set Back To One
               level2=1;									// Displayed Level Is Also Set To One
               stage=0;									// Game Stage Is Set To Zero
               lives=5;									// Lives Is Set To Five
            }
         }
      
         if (filled)											// Is The Grid Filled In?
         {
            PlaySound("Data/Complete.wav",false);	// If So, Play The Level Complete Sound          //SOUND
            stage++;										// Increase The Stage
            if (stage>3)									// Is The Stage Higher Than 3?
            {
               stage=1;									// If So, Set The Stage To One
               level++;									// Increase The Level
               level2++;									// Increase The Displayed Level
               if (level>3)								// Is The Level Greater Than 3?
               {
                  level=3;								// If So, Set The Level To 3
                  lives++;								// Give The Player A Free Life
                  if (lives>5)							// Does The Player Have More Than 5 Lives?
                  {
                     lives=5;							// If So, Set Lives To Five
                  }
               } 
            }
         
            ResetObjects();									// Reset Player / Enemy Positions
         
            for (loop1=0; loop1<11; loop1++)				// Loop Through The Grid X Coordinates
            {
               for (loop2=0; loop2<11; loop2++)			// Loop Through The Grid Y Coordinates
               {
                  if (loop1<10)							// If X Coordinate Is Less Than 10
                  {
                     hline[loop1][loop2]=false;			// Set The Current Horizontal Value To FALSE
                  }
                  if (loop2<10)							// If Y Coordinate Is Less Than 10
                  {
                     vline[loop1][loop2]=false;			// Set The Current Vertical Value To FALSE
                  }
               }
            }
         }
      
         // If The Player Hits The Hourglass While It's Being Displayed On The Screen
         if ((player.fx==hourglass.x*60) && (player.fy==hourglass.y*40) && (hourglass.fx==1))
         {
            // Play Freeze Enemy Sound
            PlaySound("Data/freeze.wav",true);                                //SOUND
            hourglass.fx=2;									// Set The hourglass fx Variable To Two
            hourglass.fy=0;									// Set The hourglass fy Variable To Zero
         }
      
         player.spin+=0.5f*steps[adjust];					// Spin The Player Clockwise
         if (player.spin>360.0f)								// Is The spin Value Greater Than 360?
         {
            player.spin-=360;								// If So, Subtract 360
         }
      
         hourglass.spin-=0.25f*steps[adjust];				// Spin The Hourglass Counter Clockwise
         if (hourglass.spin<0.0f)							// Is The spin Value Less Than 0?
         {
            hourglass.spin+=360.0f;							// If So, Add 360
         }
      
         hourglass.fy+=steps[adjust];						// Increase The hourglass fy Variable
         if ((hourglass.fx==0) && (hourglass.fy>6000/level))	// Is The hourglass fx Variable Equal To 0 And The fy
         {													// Variable Greater Than 6000 Divided By The Current Level?
            PlaySound("Data/hourglass.wav", false);	// If So, Play The Hourglass Appears Sound         //SOUND
            hourglass.x=(int)(Math.random()*10)+1;						// Give The Hourglass A Random X Value
            hourglass.y=(int)Math.random()*11;							// Give The Hourglass A Random Y Value
            hourglass.fx=1;									// Set hourglass fx Variable To One (Hourglass Stage)
            hourglass.fy=0;									// Set hourglass fy Variable To Zero (Counter)
         }
      
         if ((hourglass.fx==1) && (hourglass.fy>6000/level))	// Is The hourglass fx Variable Equal To 1 And The fy
         {													// Variable Greater Than 6000 Divided By The Current Level?
            hourglass.fx=0;									// If So, Set fx To Zero (Hourglass Will Vanish)
            hourglass.fy=0;									// Set fy to Zero (Counter Is Reset)
         }
      
         if ((hourglass.fx==2) && (hourglass.fy>500+(500*level)))	// Is The hourglass fx Variable Equal To 2 And The fy
         {													// Variable Greater Than 500 Plus 500 Times The Current Level?
            PlaySound("",false);						// If So, Kill The Freeze Sound                                //SOUND
            hourglass.fx=0;									// Set hourglass fx Variable To Zero
            hourglass.fy=0;									// Set hourglass fy Variable To Zero
         }
      
         delay++;
      
      }
   
      public void PlaySound(String wavFile,boolean loop)
      {
      // NOTE THIS IS A VERY DODGY WAY OF DOING THIS...
      // SHOULD USE a Media tracker or something.. but this was quick :) 
      
      
         if(audioClip!=null)
            audioClip.stop();
      
         if(wavFile.equals(""))
            return;  
      
         if(codeBase==null)
         {
            try {
            
               URL url = new URL("file:" + System.getProperty("user.dir") + "/"+wavFile);
               audioClip = Applet.newAudioClip(url);
               if(loop==true)
                  audioClip.loop();
               else
                  audioClip.play();
            } 
            
               catch (MalformedURLException e) {
               
                  System.err.println(e.getMessage());
               }
         
         }
      
      
      }
     /** void display() Draw to the canvas. */
    // Purely a Java thing. Simple calls DrawGLScene once GL is initialized
      public void display()
      
      {
      
      
         glj.gljMakeCurrent();      //Ensure GL is initialised correctly
         for(int i=0;i<2;i++) // to get more performace.. damn slow event driven drawing
            DrawGLScene();    // 2x speed... sortof... runs a little faster than NeHe VC version
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