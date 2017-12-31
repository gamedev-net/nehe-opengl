/*

Author : Chris Veenboer
Date:  12/10/2002

Based on code from Josh Kirby who converted lessons 1-22.

Revised NeHe OpenGL tutorial Lesson 23 : Sphere Environment Mapping
Origional Visual C versions available at  : nehe.gamedev.net

Thanks go to Darren Hodges for the first port of the NeHe tutorials. I have totally
re-written these from next to scratch tho.

This set of ports makes use of the new Gl4Java 2.8.2 (which thankfully includes some Font support
and FULL OGL 1.3 spec)

It is also structures slightly different, in that this file is the only file that changes, the lesson.java
file is constant, making it much more easy to concentrate on the OpenGL specific code. All lesson.java does is create a class
that will display the NeheCanvas in either Applet form for use in a webpage or in a window.

Also this should mimic the order of the Nehe Html as much as possible, making reading the tutorial and writting
your own code as easy as possible

NOTE : this tutorial assumes you know Java basics. Once you've read these.. you'll see what Java is so much easier, if a little
slower :)

NOTE: for values of 'a little slower' equal to 'slower than slugs on valium'

*/

// Java  classes
   import java.awt.*;
   import java.awt.event.*;
   import java.net.URL;
   import java.util.*;



// GL4Java classes
   import gl4java.GLContext;
   import gl4java.awt.GLAnimCanvas;
   import gl4java.utils.textures.*;


   class NeHeCanvas extends GLAnimCanvas implements KeyListener, MouseListener

   {

      // applet related
      URL codeBase;

      // holds information on which keys are held down.
      boolean[] keys=new boolean[256];
      boolean sp;

      // settings such as light/filters/objects
      int filter = 0;
      int curObject = 0;

      float	xrot;				// X Rotation
      float	yrot;				// Y Rotation
      float	zrot;				// Z Rotation
      float xspeed;														// X Rotation Speed
      float yspeed;														// Y Rotation Speed
      float	z=-10.0f;													// Depth Into The Screen, if this is too low (say -5.0), the background will also move

      int	texture[]=new int[6];													// Storage For 6 Textures (Modified)

      float LightAmbient[]	= { 0.2f, 0.2f, 0.2f};						// Ambient Light is 20% white
      float LightDiffuse[]	= { 1.0f, 1.0f, 1.0f};						// Diffuse Light is white
      float LightPosition[] = { 0.0f, 0.0f, 2.0f};						// Position is somewhat in front of screen

      long quadratic;	         // Storage For Our Quadratic Objects

      public NeHeCanvas(int w, int h)

      {
         super(w, h);

         //Registers this canvas to process keyboard events, and Mouse events
         addKeyListener(this);
         addMouseListener(this);
         setAnimateFps(60); // seemed to be essential in getting any performance

      }

   /** void init() Called just AFTER the GL-Context is created. */

      public void init()

      {

         if(!LoadGLTextures())
         {
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
         initLights();										             // Initialize OpenGL Light

         quadratic=glu.gluNewQuadric();							// Create A Pointer To The Quadric Object (Return 0 If No Memory)
         glu.gluQuadricNormals(quadratic, GLU_SMOOTH);			// Create Smooth Normals
         glu.gluQuadricTexture(quadratic, GL_TRUE);				// Create Texture Coords

         gl.glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP); // Set The Texture Generation Mode For S To Sphere Mapping (NEW)
         gl.glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP); // Set The Texture Generation Mode For T To Sphere Mapping (NEW)

      }

      public void initLights() {


         gl.glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient);				// Load Light-Parameters Into GL_LIGHT1
         gl.glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse);
         gl.glLightfv( GL_LIGHT1, GL_POSITION, LightPosition);

         gl.glEnable(GL_LIGHT1);
      }

      public boolean LoadGLTextures()
      {
         // create two texture loader objects
         PngTextureLoader[] texLoader = new PngTextureLoader[2];
         texLoader[0] = new PngTextureLoader(gl, glu);
         texLoader[1] = new PngTextureLoader(gl, glu);
         if(codeBase!=null)      // Applet
         {
            texLoader[0].readTexture(codeBase, "Data/BG.png");
            texLoader[1].readTexture(codeBase, "Data/Reflect.png");
         }
         else // Local
         {
            texLoader[0].readTexture("Data/BG.png");
            texLoader[1].readTexture("Data/Reflect.png");
         }

         if(!texLoader[0].isOk() || !texLoader[1].isOk())
            return false;

         //Create Textures
         gl.glGenTextures(6, texture); // 6 textures

         for (int loop=0; loop<=1; loop++)
   		{
            // Create Nearest Filtered Texture
            gl.glBindTexture(GL_TEXTURE_2D, texture[loop]);// Gen Tex 0 and 1
            gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
            gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
            gl.glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,texLoader[loop].getImageWidth(),texLoader[loop].getImageHeight(),0,GL_RGB,GL_UNSIGNED_BYTE,texLoader[loop].getTexture());

	   		// Create Linear Filtered Texture
            gl.glBindTexture(GL_TEXTURE_2D, texture[loop+2]);// Gen Tex 2 and 3
            gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
            gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
            gl.glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,texLoader[loop].getImageWidth(),texLoader[loop].getImageHeight(),0,GL_RGB,GL_UNSIGNED_BYTE,texLoader[loop].getTexture());

   			// Create MipMapped Texture
            gl.glBindTexture(GL_TEXTURE_2D, texture[loop+4]);// Gen Tex 4 and 5
            gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
            gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
            gl.glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,texLoader[loop].getImageWidth(),texLoader[loop].getImageHeight(),0,GL_RGB,GL_UNSIGNED_BYTE,texLoader[loop].getTexture());

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


         gl.glEnable(GL_TEXTURE_GEN_S);							// Enable Texture Coord Generation For S (NEW)
         gl.glEnable(GL_TEXTURE_GEN_T);							// Enable Texture Coord Generation For T (NEW)

      	gl.glBindTexture(GL_TEXTURE_2D, texture[filter+(filter+1)]); // This Will Select The Sphere Map
      	gl.glPushMatrix();

         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);

      	switch(curObject)
      	{
      	case 0:
      		glDrawCube();
      		break;
      	case 1:
      		gl.glTranslatef(0.0f,0.0f,-1.5f);					// Center The Cylinder
      		glu.gluCylinder(quadratic,1.0f,1.0f,3.0f,32,32);	// A Cylinder With A Radius Of 0.5 And A Height Of 2
      		break;
      	case 2:
      		glu.gluSphere(quadratic,1.3f,32,32);				// Draw A Sphere With A Radius Of 1 And 16 Longitude And 16 Latitude Segments
      		break;
      	case 3:
      		gl.glTranslatef(0.0f,0.0f,-1.5f);					// Center The Cone
      		glu.gluCylinder(quadratic,1.0f,0.0f,3.0f,32,32);	// A Cone With A Bottom Radius Of .5 And A Height Of 2
      		break;
      	};

      	gl.glPopMatrix();
      	gl.glDisable(GL_TEXTURE_GEN_S);
      	gl.glDisable(GL_TEXTURE_GEN_T);


      	gl.glBindTexture(GL_TEXTURE_2D, texture[filter*2]);	// This Will Select The BG Maps...
      	gl.glPushMatrix();
      		gl.glTranslatef(0.0f, 0.0f, -24.0f);
      		gl.glBegin(GL_QUADS);
      			gl.glNormal3f( 0.0f, 0.0f, 1.0f);
      			gl.glTexCoord2f(0.0f, 0.0f); gl.glVertex3f(-13.3f, -10.0f,  10.0f);
      			gl.glTexCoord2f(1.0f, 0.0f); gl.glVertex3f( 13.3f, -10.0f,  10.0f);
      			gl.glTexCoord2f(1.0f, 1.0f); gl.glVertex3f( 13.3f,  10.0f,  10.0f);
      			gl.glTexCoord2f(0.0f, 1.0f); gl.glVertex3f(-13.3f,  10.0f,  10.0f);
      		gl.glEnd();
      	gl.glPopMatrix();


         if (keys['F'])
         {
            keys['F']=false;
            filter++;
            filter%=2;
         }
			if (keys[' '] && !sp)
			{
				sp=true;
				curObject++;
   			curObject%=4;
			}
			if (!keys[' '])
			{
				sp=false;
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


        	xrot+=xspeed;
      	yrot+=yspeed;

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