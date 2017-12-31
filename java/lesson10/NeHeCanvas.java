/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 10 : Moving through a world
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
   import java.net.*;
   import java.io.*;
   import java.util.StringTokenizer;



// GL4Java classes
   import gl4java.GLContext;
   import gl4java.awt.GLAnimCanvas;
   import gl4java.utils.textures.*;


   class NeHeCanvas extends GLAnimCanvas implements KeyListener, MouseListener
   
   {   
     // holds information on which keys are held down.
      boolean[] keys=new boolean[256];
      URL codeBase;
   
      boolean	blend;				// Blending ON/OFF
      boolean	bp;					// B Pressed?
      boolean	fp;					// F Pressed?
   
      final float piover180 = 0.0174532925f;
      float heading;
      float xpos;
      float zpos;
   
      float	yrot;				// Y Rotation
      float walkbias = 0;
      float walkbiasangle = 0;
      float lookupdown = 0.0f;
      float	z=0.0f;				// Depth Into The Screen
   
      int	filter;				// Which Filter To Use
      int[]	texture=new int[3];			// Storage For 3 Textures
   
   
      class VERTEX
      
      {
         float x, y, z;
         float u, v;
      } 
   
   
      class TRIANGLE
      
      {
         VERTEX[] vertex=new VERTEX[3];
         public TRIANGLE()
         {
            for(int i=0;i<3;i++)
               vertex[i]=new VERTEX();
         
         }
      } 
   
   
      class SECTOR
      
      {
         int numtriangles;
         TRIANGLE[] triangles;
         public SECTOR(int inTri)
         {
            numtriangles=inTri;
            triangles=new TRIANGLE[inTri];
            for(int i=0;i<inTri;i++)
               triangles[i] =new TRIANGLE();
         }
      } 
   
      SECTOR sector1;				// Our Model Goes Here:
   
   
      public NeHeCanvas(int w, int h)
      
      {
         super(w, h);
      
         //Registers this canvas to process keyboard events, and Mouse events
         addKeyListener(this);
         addMouseListener(this);   
         setAnimateFps(60); // seemed to be essential in getting any performance 
      
      }
      void SetupWorld() {
      
      
         float x, y, z, u, v;
         int numtriangles;
      
         try {
            String line;
         
            BufferedReader dis;
            //URL world = new URL(getCodeBase() + "data/world.txt");
         
         
               //URL world = new URL(codeBase + "data/world.txt");
            try{
               URL file = new URL(codeBase.toString()+"data/world.txt");
               URLConnection urlconnection = file.openConnection();
               urlconnection.connect();
            
               dis =  new BufferedReader(new InputStreamReader(urlconnection.getInputStream()));
            
            
               while ((line = dis.readLine()) != null) {
                  if (line.trim().length() == 0 || line.trim().startsWith("//"))
                     continue;
               
                  if (line.startsWith("NUMPOLLIES")) {
                     int numTriangles;
                  
                     numTriangles = Integer.parseInt(line.substring(line.indexOf("NUMPOLLIES") + "NUMPOLLIES".length() + 1));
                     sector1 = new SECTOR(numTriangles);
                  
                     break;
                  }
               }
            
               for (int i = 0; i < sector1.numtriangles; i++) {
                  for (int vert = 0; vert < 3; vert++) {
                  
                     while ((line = dis.readLine()) != null) {
                        if (line.trim().length() == 0 || line.trim().startsWith("//"))
                           continue;
                     
                        break;
                     }
                  
                     if (line != null) {
                        StringTokenizer st = new StringTokenizer(line, " ");
                     
                        sector1.triangles[i].vertex[vert].x = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangles[i].vertex[vert].y = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangles[i].vertex[vert].z = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangles[i].vertex[vert].u = Float.valueOf(st.nextToken()).floatValue();
                        sector1.triangles[i].vertex[vert].v = Float.valueOf(st.nextToken()).floatValue();                            
                     }                        
                  }
               }
            
               dis.close();
            }
               catch(Exception e)
               {}
         
         } 
         
         
         
         
            catch (Exception e) {
            
            
               System.out.println("IOException: " + e);
            }
      }
   
      public boolean LoadGLTextures()
      
      
      {
         PngTextureLoader texLoader = new PngTextureLoader(gl, glu);
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/mud.png");
         else
            texLoader.readTexture("data/mud.png");
      
         System.out.println("Loaded Textures");
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
         if(!LoadGLTextures())
         { 
            System.out.println("Failed to load Textures, Bailing!");
            System.exit(-10);
         }
         float width = (float)getSize().width;
         float height = (float)getSize().height;
      
         gl.glEnable(GL_TEXTURE_2D);							// Enable Texture Mapping
         gl.glBlendFunc(GL_SRC_ALPHA,GL_ONE);					// Set The Blending Function For Translucency
         gl.glShadeModel(GL_SMOOTH);                            //Enables Smooth Color Shading
         gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
         gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
         gl.glEnable(GL_DEPTH_TEST);                            //Enables Depth Testing
         gl.glDepthFunc(GL_LEQUAL);                             //The Type Of Depth Test To Do
         gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);  // Really Nice Perspective Calculations
         SetupWorld();
      }
   
   
   
   
      public void DrawGLScene()
      {
      
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);       //Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();   	                                     //Reset The View
      
         float x=0,y=0,z=0,u=0,v=0;
      
      
         float xtrans = -xpos;
         float ztrans = -zpos;
         float ytrans = -walkbias-0.25f;
         float sceneroty = 360.0f - yrot;
      
         gl.glRotatef(lookupdown,1.0f,0,0);
         gl.glRotatef(sceneroty,0,1.0f,0);
      
         gl.glTranslatef(xtrans, ytrans, ztrans);
         gl.glBindTexture(GL_TEXTURE_2D, texture[filter]);
      
            // Process Each Triangle
         for (int i = 0; i < sector1.numtriangles; i++) {
         
            gl.glBegin(GL_TRIANGLES);
            gl.glNormal3f( 0.0f, 0.0f, 1.0f);
            x = sector1.triangles[i].vertex[0].x;
            y = sector1.triangles[i].vertex[0].y;
            z = sector1.triangles[i].vertex[0].z;
            u = sector1.triangles[i].vertex[0].u;
            v = sector1.triangles[i].vertex[0].v;
            gl.glTexCoord2f(u,v); gl.glVertex3f(x,y,z);
         
            x = sector1.triangles[i].vertex[1].x;
            y = sector1.triangles[i].vertex[1].y;
            z = sector1.triangles[i].vertex[1].z;
            u = sector1.triangles[i].vertex[1].u;
            v = sector1.triangles[i].vertex[1].v;
            gl.glTexCoord2f(u,v); gl.glVertex3f(x,y,z);
         
            x = sector1.triangles[i].vertex[2].x;
            y = sector1.triangles[i].vertex[2].y;
            z = sector1.triangles[i].vertex[2].z;
            u = sector1.triangles[i].vertex[2].u;
            v = sector1.triangles[i].vertex[2].v;
            gl.glTexCoord2f(u,v); gl.glVertex3f(x,y,z);
            gl.glEnd();
         }
      
      
      
      
         if (keys['B'] && !bp)
         {
            bp=true;
            blend=!blend;
            if (!blend)
            {
               gl.glDisable(GL_BLEND);
               gl.glEnable(GL_DEPTH_TEST);
            }
            else
            {
               gl.glEnable(GL_BLEND);
               gl.glDisable(GL_DEPTH_TEST);
            }
         }
         if (!keys['B'])
         {
            bp=false;
         }
      
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
      
         if (keys[KeyEvent.VK_PAGE_UP])
         {
            z-=0.02f;
         }
      
         if (keys[KeyEvent.VK_PAGE_DOWN])
         {
            z+=0.02f;
         }
      
         if (keys[KeyEvent.VK_UP])
         {
         
         
            xpos -= (float)Math.sin(heading*piover180) * 0.05f;
            zpos -= (float)Math.cos(heading*piover180) * 0.05f;
            if (walkbiasangle >= 359.0f)
            {
               walkbiasangle = 0.0f;
            }
            else
            {
               walkbiasangle+= 10;
            }
            walkbias = (float)Math.sin(walkbiasangle * piover180)/20.0f;
         }
      
         if (keys[KeyEvent.VK_DOWN])
         {
            xpos += (float)Math.sin(heading*piover180) * 0.05f;
            zpos += (float)Math.cos(heading*piover180) * 0.05f;
            if (walkbiasangle <= 1.0f)
            {
               walkbiasangle = 359.0f;
            }
            else
            {
               walkbiasangle-= 10;
            }
            walkbias = (float)Math.sin(walkbiasangle * piover180)/20.0f;
         }
      
         if (keys[KeyEvent.VK_RIGHT])
         {
            heading -= 1.0f;
            yrot = heading;
         }
      
         if (keys[KeyEvent.VK_LEFT])
         {
            heading += 1.0f;	
            yrot = heading;
         }
      
         if (keys[KeyEvent.VK_PAGE_UP])
         {
            lookupdown-= 1.0f;
         }
      
         if (keys[KeyEvent.VK_PAGE_DOWN])
         {
            lookupdown+= 1.0f;
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