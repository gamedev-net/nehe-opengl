/*

Author : Jeff Kirby (Reflex)
Date:  21/12/2001

Revised NeHe OpenGL tutorial Lesson 22 : Bump Mapping, MultiTexturing & Extensions
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
   
      final float MAX_EMBOSS= 0.008f;
      final int MAX_EXTENSION_SPACE = 10240;									// Characters for Extension-Strings
      final int MAX_EXTENSION_LENGTH = 256;									// Maximum Of Characters In One Extension-String
   
   
      boolean multitextureSupported=false;									// Flag Indicating Whether Multitexturing Is Supported
      boolean useMultitexture=true;											// Use It If It Is Supported?
      int[] maxTexelUnits=new int[2];												// Number Of Texel-Pipelines. This Is At Least 1.
   
   
     // holds information on which keys are held down.
      boolean[] keys=new boolean[256];
      URL codeBase;
   
      boolean	emboss=false;												// Emboss Only, No Basetexture?
      boolean  bumps=true;													// Do Bumpmapping?
   
   
      float	xrot;				// X Rotation 
      float	yrot;				// Y Rotation 
      float	zrot;				// Z Rotation 
      float xspeed;														// X Rotation Speed   ( new )
      float yspeed;														// Y Rotation Speed   ( new )
      float	z=-5.0f;													// Depth Into The Screen (new )
   
      int	filter=1;													// Which Filter To Use
      int	texture[]=new int[3];													// Storage For 3 Textures
      int  bump[]=new int[3];													// Our Bumpmappings
      int  invbump[]=new int[3];													// Inverted Bumpmaps
      int[]	glLogo=new int[1];														// Handle For OpenGL-Logo
      int[]  multiLogo=new int[1];													// Handle For Multitexture-Enabled-Logo
   
      float LightAmbient[]	= { 0.2f, 0.2f, 0.2f};						// Ambient Light is 20% white
      float LightDiffuse[]	= { 1.0f, 1.0f, 1.0f};						// Diffuse Light is white
      float LightPosition[] = { 0.0f, 0.0f, 2.0f};						// Position is somewhat in front of screen
   
      float Gray[]= {0.5f,0.5f,0.5f,1.0f};
   
   // Data Contains The Faces For The Cube In Format 2xTexCoord, 3xVertex;
   // Note That The Tesselation Of The Cube Is Only Absolute Minimum.
      float data[]= {
      // FRONT FACE
         0.0f, 0.0f,		-1.0f, -1.0f, +1.0f,
         1.0f, 0.0f,		+1.0f, -1.0f, +1.0f,
         1.0f, 1.0f,		+1.0f, +1.0f, +1.0f,
         0.0f, 1.0f,		-1.0f, +1.0f, +1.0f,
         // BACK FACE
         1.0f, 0.0f,		-1.0f, -1.0f, -1.0f,
         1.0f, 1.0f,		-1.0f, +1.0f, -1.0f,
         0.0f, 1.0f,		+1.0f, +1.0f, -1.0f,
         0.0f, 0.0f,		+1.0f, -1.0f, -1.0f,
         // Top Face
         0.0f, 1.0f,		-1.0f, +1.0f, -1.0f,
         0.0f, 0.0f,		-1.0f, +1.0f, +1.0f,
         1.0f, 0.0f,		+1.0f, +1.0f, +1.0f,
         1.0f, 1.0f,		+1.0f, +1.0f, -1.0f,
         // Bottom Face
         1.0f, 1.0f,		-1.0f, -1.0f, -1.0f,
         0.0f, 1.0f,		+1.0f, -1.0f, -1.0f,
         0.0f, 0.0f,		+1.0f, -1.0f, +1.0f,
         1.0f, 0.0f,		-1.0f, -1.0f, +1.0f,
         // Right Face
         1.0f, 0.0f,		+1.0f, -1.0f, -1.0f,
         1.0f, 1.0f,		+1.0f, +1.0f, -1.0f,
         0.0f, 1.0f,		+1.0f, +1.0f, +1.0f,
         0.0f, 0.0f,		+1.0f, -1.0f, +1.0f,
         // Left Face
         0.0f, 0.0f,		-1.0f, -1.0f, -1.0f,
         1.0f, 0.0f,		-1.0f, -1.0f,  1.0f,
         1.0f, 1.0f,		-1.0f,  1.0f,  1.0f,
         0.0f, 1.0f,		-1.0f,  1.0f, -1.0f
      };
      public NeHeCanvas(int w, int h)
      
      {
         super(w, h);
      
         //Registers this canvas to process keyboard events, and Mouse events
         addKeyListener(this);
         addMouseListener(this);   
         setAnimateFps(60); // seemed to be essential in getting any performance 
      
      }
   
   	// Always Check For Extension-Availability During Run-Time!
   
   // isMultitextureSupported() Checks At Run-Time If Multitexturing Is Supported
   
      boolean initMultitexture() {
         boolean arbExt=false,envExt=false;
      
      		// run throught the list of extension and see if the ones we want are available
         StringTokenizer tok = new StringTokenizer(gl.glGetString(GL_EXTENSIONS));
         String token;
      
         while(tok.hasMoreTokens())
         {
            token=tok.nextToken();
            System.out.println(token);
            if(token.compareTo("GL_ARB_multitexture")==0)
               arbExt=true;
            //else
               //if(token.compareTo("GL_EXT_texture_env_combine")==0)
                  //envExt=true;
         
         }
         gl.glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB,maxTexelUnits);
      
      
         if(arbExt /*&& envExt*/ )
         {
            gl.glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB,maxTexelUnits);
            System.out.println("MaxTexelUnits : "+maxTexelUnits[0]);
            System.out.println("Required Extension found (GL_ARB_multitexture)");
            return true;
         }
      
         useMultitexture=false;											// We Can't Use It If It Isn't Supported!
         return false;
      }
      public void initLights() {
      
      
         gl.glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient);				// Load Light-Parameters Into GL_LIGHT1
         gl.glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse);	
         gl.glLightfv( GL_LIGHT1, GL_POSITION, LightPosition);
      
         gl.glEnable(GL_LIGHT1);	
      }
      public boolean LoadGLTextures()
      {
         PngTextureLoader texLoader = new PngTextureLoader(gl, glu);
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/base.png");
         else
            texLoader.readTexture("data/base.png");
      
         if(!texLoader.isOk())
         {
            return false;
         }
            //Create Texture
         gl.glGenTextures(3, texture);
      
         // Create Nearest Filtered Texture
         gl.glBindTexture(GL_TEXTURE_2D, texture[0]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
         gl.glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,texLoader.getImageWidth(),texLoader.getImageHeight(),0,GL_RGB,GL_UNSIGNED_BYTE,texLoader.getTexture());
      
      // Create Linear Filtered Texture
         gl.glBindTexture(GL_TEXTURE_2D, texture[1]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGB, GL_UNSIGNED_BYTE, texLoader.getTexture());
      
      // Create MipMapped Texture
         gl.glBindTexture(GL_TEXTURE_2D, texture[2]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
         glu.gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), GL_RGB, GL_UNSIGNED_BYTE, texLoader.getTexture());
      
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/bump.png");
         else
            texLoader.readTexture("data/bump.png");
      
         if(!texLoader.isOk())
         {
            return false;
         }
      
      
         gl.glPixelTransferf(GL_RED_SCALE,0.5f);						// Scale RGB By 50%, So That We Have Only			
         gl.glPixelTransferf(GL_GREEN_SCALE,0.5f);						// Half Intenstity
         gl.glPixelTransferf(GL_BLUE_SCALE,0.5f);
      
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);	// No Wrapping, Please!
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
         gl.glTexParameterfv(GL_TEXTURE_2D,GL_TEXTURE_BORDER_COLOR,Gray);
      
         gl.glGenTextures(3, bump);										// Create Three Textures
      
      // Create Nearest Filtered Texture
         gl.glBindTexture(GL_TEXTURE_2D, bump[0]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGB, GL_UNSIGNED_BYTE, texLoader.getTexture());
      
      // Create Linear Filtered Texture
         gl.glBindTexture(GL_TEXTURE_2D, bump[1]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGB, GL_UNSIGNED_BYTE, texLoader.getTexture());
      
      // Create MipMapped Texture
         gl.glBindTexture(GL_TEXTURE_2D, bump[2]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
         glu.gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageWidth(), GL_RGB, GL_UNSIGNED_BYTE, texLoader.getTexture());
      
         byte[] invTexture = texLoader.getTexture();
      
         for (int i=0; i<3*texLoader.getImageWidth()*texLoader.getImageWidth(); i++)		// Invert The Bumpmap
            invTexture[i]= (byte)(255-invTexture[i]);
      
         gl.glGenTextures(3, invbump);								// Create Three Textures
      
      // Create Nearest Filtered Texture
         gl.glBindTexture(GL_TEXTURE_2D, invbump[0]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGB, GL_UNSIGNED_BYTE, invTexture);
      
      // Create Linear Filtered Texture
         gl.glBindTexture(GL_TEXTURE_2D, invbump[1]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGB, GL_UNSIGNED_BYTE, invTexture);
      
      // Create MipMapped Texture
         gl.glBindTexture(GL_TEXTURE_2D, invbump[2]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
         glu.gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB8, texLoader.getImageWidth(), texLoader.getImageHeight(), GL_RGB, GL_UNSIGNED_BYTE, invTexture);
      
         gl.glPixelTransferf(GL_RED_SCALE,1.0f);				// Scale RGB Back To 100% Again		
         gl.glPixelTransferf(GL_GREEN_SCALE,1.0f);			
         gl.glPixelTransferf(GL_BLUE_SCALE,1.0f);
      
      
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/OpenGL_ALPHA.png");
         else
            texLoader.readTexture("data/OpenGL_ALPHA.png");
      
         if(!texLoader.isOk())
         {
            return false;
         }
      
         byte[] alpha=new byte[4*texLoader.getImageWidth()*texLoader.getImageHeight()];		// Create Memory For RGBA8-Texture
         for (int a=0; a<texLoader.getImageWidth()*texLoader.getImageHeight(); a++)
            alpha[4*a+3]=texLoader.getTexture()[a*3];					// Pick Only Red Value As Alpha!
      
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/OpenGL.png");
         else
            texLoader.readTexture("data/OpenGL.png");
      
         if(!texLoader.isOk())
         {
            return false;
         }
      
         for (int a=0; a<texLoader.getImageWidth()*texLoader.getImageHeight(); a++) {		
            alpha[4*a]=texLoader.getTexture()[a*3];					// R
            alpha[4*a+1]=texLoader.getTexture()[a*3+1];				// G
            alpha[4*a+2]=texLoader.getTexture()[a*3+2];				// B
         }
      
         gl.glGenTextures(1, glLogo);							// Create One Textures
      
      // Create Linear Filtered RGBA8-Texture
         gl.glBindTexture(GL_TEXTURE_2D, glLogo[0]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGBA, GL_UNSIGNED_BYTE, alpha);
      
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/multi_on_alpha.png");
         else
            texLoader.readTexture("data/multi_on_alpha.png");
      
         if(!texLoader.isOk())
         {
            return false;
         }
      
         alpha=new byte[4*texLoader.getImageWidth()*texLoader.getImageHeight()];		// Create Memory For RGBA8-Texture
         for (int a=0; a<texLoader.getImageWidth()*texLoader.getImageHeight(); a++)
            alpha[4*a+3]=texLoader.getTexture()[a*3];					// Pick Only Red Value As Alpha!
      
         if(codeBase!=null)   
            texLoader.readTexture(codeBase, "data/multi_on.png");
         else
            texLoader.readTexture("data/multi_on.png");
      
         if(!texLoader.isOk())
         {
            return false;
         }
      
         for (int a=0; a<texLoader.getImageWidth()*texLoader.getImageHeight(); a++) {		
            alpha[4*a]=texLoader.getTexture()[a*3];					// R
            alpha[4*a+1]=texLoader.getTexture()[a*3+1];				// G
            alpha[4*a+2]=texLoader.getTexture()[a*3+2];				// B
         }
      
         gl.glGenTextures(1, multiLogo);							// Create One Textures
      
      // Create Linear Filtered RGBA8-Texture
         gl.glBindTexture(GL_TEXTURE_2D,  multiLogo[0]);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
         gl.glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
         gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,texLoader.getImageWidth(), texLoader.getImageHeight(), 0, GL_RGBA, GL_UNSIGNED_BYTE, alpha);
      
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
   
      void doCube () {
      
         int i;
         gl.glBegin(GL_QUADS);
      // Front Face
         gl.glNormal3f( 0.0f, 0.0f, +1.0f);
         for (i=0; i<4; i++) {
            gl.glTexCoord2f(data[5*i],data[5*i+1]);
            gl.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
         }
      // Back Face
         gl.glNormal3f( 0.0f, 0.0f,-1.0f);
         for (i=4; i<8; i++) {
            gl.glTexCoord2f(data[5*i],data[5*i+1]);
            gl.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
         }
      // Top Face
         gl.glNormal3f( 0.0f, 1.0f, 0.0f);
         for (i=8; i<12; i++) {
            gl.glTexCoord2f(data[5*i],data[5*i+1]);
            gl.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
         }
      // Bottom Face
         gl.glNormal3f( 0.0f,-1.0f, 0.0f);
         for (i=12; i<16; i++) {
            gl.glTexCoord2f(data[5*i],data[5*i+1]);
            gl.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
         }
      // Right face
         gl.glNormal3f( 1.0f, 0.0f, 0.0f);
         for (i=16; i<20; i++) {
            gl.glTexCoord2f(data[5*i],data[5*i+1]);
            gl.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
         }
      // Left Face
         gl.glNormal3f(-1.0f, 0.0f, 0.0f);
         for (i=20; i<24; i++) {
            gl.glTexCoord2f(data[5*i],data[5*i+1]);
            gl.glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
         }
         gl.glEnd();	
      }
   /** void preInit() Called just BEFORE the GL-Context is created. */
   
      public void preInit()
      { doubleBuffer = true; stereoView = false; // buffering but not stereoview
      }
   
   /** void init() Called just AFTER the GL-Context is created. */
   
      public void init()
      
      {
      
         multitextureSupported=initMultitexture();
      
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
         initLights();										// Initialize OpenGL Light	
      
      }
   
   // Calculates v=vM, M Is 4x4 In Column-Major, v Is 4dim. Row (i.e. "Transposed")
   
      void VMatMult(float[] M, float[] v) {
      
         float[] res=new float[3];
         res[0]=M[ 0]*v[0]+M[ 1]*v[1]+M[ 2]*v[2]+M[ 3]*v[3];
         res[1]=M[ 4]*v[0]+M[ 5]*v[1]+M[ 6]*v[2]+M[ 7]*v[3];
         res[2]=M[ 8]*v[0]+M[ 9]*v[1]+M[10]*v[2]+M[11]*v[3];;	
         v[0]=res[0];
         v[1]=res[1];
         v[2]=res[2];
         v[3]=M[15];											// Homogenous Coordinate
      }
   
      void SetUpBumps(float[] n, float[] c, float[] l, float[] s, float[] t) {
      
         float[] v=new float[3];							// Vertex From Current Position To Light	
         float lenQ;							// Used To Normalize		
      
      // Calculate v From Current Vector c To Lightposition And Normalize v	
         v[0]=l[0]-c[0];		
         v[1]=l[1]-c[1];		
         v[2]=l[2]-c[2];		
         lenQ=(float) Math.sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
         v[0]/=lenQ;		v[1]/=lenQ;		v[2]/=lenQ;
      // Project v Such That We Get Two Values Along Each Texture-Coordinat Axis.
         c[0]=(s[0]*v[0]+s[1]*v[1]+s[2]*v[2])*MAX_EMBOSS;
         c[1]=(t[0]*v[0]+t[1]*v[1]+t[2]*v[2])*MAX_EMBOSS;	
      }
   
      void doLogo() {			// MUST CALL THIS LAST!!!, Billboards The Two Logos.
      
         gl.glDepthFunc(GL_ALWAYS);		
         gl.glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
         gl.glEnable(GL_BLEND);
         gl.glDisable(GL_LIGHTING);
         gl.glLoadIdentity();	
         gl.glBindTexture(GL_TEXTURE_2D,glLogo[0]);
         gl.glBegin(GL_QUADS);
         gl.glTexCoord2f(0.0f,0.0f);	gl.glVertex3f(0.13f, -0.4f,-1.0f);
         gl.glTexCoord2f(1.0f,0.0f);	gl.glVertex3f(0.43f, -0.4f,-1.0f);
         gl.glTexCoord2f(1.0f,1.0f);	gl.glVertex3f(0.43f, -0.25f,-1.0f);
         gl.glTexCoord2f(0.0f,1.0f);	gl.glVertex3f(0.13f, -0.25f,-1.0f);
         gl.glEnd();		
         if (useMultitexture) {
            gl.glBindTexture(GL_TEXTURE_2D,multiLogo[0]);
            gl.glBegin(GL_QUADS);
            gl.glTexCoord2f(0.0f,0.0f);	gl.glVertex3f(-0.33f, -0.4f,-1.0f);
            gl.glTexCoord2f(1.0f,0.0f);	gl.glVertex3f(-0.13f, -0.4f,-1.0f);
            gl.glTexCoord2f(1.0f,1.0f);	gl.glVertex3f(-0.13f, -0.3f,-1.0f);
            gl.glTexCoord2f(0.0f,1.0f);	gl.glVertex3f(-0.33f, -0.3f,-1.0f);
            gl.glEnd();		
         }
         gl.glDepthFunc(GL_LEQUAL);
      }
   
      boolean doMesh1TexelUnits() {
      
      
         float c[]={0.0f,0.0f,0.0f,1.0f};					// Holds Current Vertex
         float n[]={0.0f,0.0f,0.0f,1.0f};					// Normalized Normal Of Current Surface		
         float s[]={0.0f,0.0f,0.0f,1.0f};					// s-Texture Coordinate Direction, Normalized
         float t[]={0.0f,0.0f,0.0f,1.0f};					// t-Texture Coordinate Direction, Normalized
         float[] l=new float[4];										// Holds Our Lightposition To Be Transformed Into Object Space
         float[] Minv=new float[16];									// Holds The Inverted Modelview Matrix To Do So.
         int i;								
      
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
      
      // Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With One glLoadIdentity();
      // Simply Build It By Doing All Transformations Negated And In Reverse Order.
         gl.glLoadIdentity();								
         gl.glRotatef(-yrot,0.0f,1.0f,0.0f);
         gl.glRotatef(-xrot,1.0f,0.0f,0.0f);
         gl.glTranslatef(0.0f,0.0f,-z);
         gl.glGetFloatv(GL_MODELVIEW_MATRIX,Minv);
         gl.glLoadIdentity();
         gl.glTranslatef(0.0f,0.0f,z);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);	
      
      // Transform The Lightposition Into Object Coordinates:
         l[0]=LightPosition[0];
         l[1]=LightPosition[1];
         l[2]=LightPosition[2];
         l[3]=1.0f;											// Homogenous Coordinate
         VMatMult(Minv,l);
      
      /*	PASS#1: Use Texture "Bump"
      	No Blend
      	No Lighting
      	No Offset Texture-Coordinates */
         gl.glBindTexture(GL_TEXTURE_2D, bump[filter]);
         gl.glDisable(GL_BLEND);
         gl.glDisable(GL_LIGHTING);
         doCube();
      
      /* PASS#2:	Use Texture "Invbump"
      	Blend GL_ONE To GL_ONE
      	No Lighting
      	Offset Texture Coordinates 
      	*/
         gl.glBindTexture(GL_TEXTURE_2D,invbump[filter]);
         gl.glBlendFunc(GL_ONE,GL_ONE);
         gl.glDepthFunc(GL_LEQUAL);
         gl.glEnable(GL_BLEND);	
      
         gl.glBegin(GL_QUADS);	
      // Front Face	
         n[0]=0.0f;		n[1]=0.0f;		n[2]=1.0f;			
         s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=0; i<4; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Back Face	
         n[0]=0.0f;		n[1]=0.0f;		n[2]=-1.0f;	
         s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=4; i<8; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Top Face	
         n[0]=0.0f;		n[1]=1.0f;		n[2]=0.0f;		
         s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
         for (i=8; i<12; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Bottom Face
         n[0]=0.0f;		n[1]=-1.0f;		n[2]=0.0f;		
         s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
         for (i=12; i<16; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Right Face	
         n[0]=1.0f;		n[1]=0.0f;		n[2]=0.0f;		
         s[0]=0.0f;		s[1]=0.0f;		s[2]=-1.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=16; i<20; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Left Face
         n[0]=-1.0f;		n[1]=0.0f;		n[2]=0.0f;		
         s[0]=0.0f;		s[1]=0.0f;		s[2]=1.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=20; i<24; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }		
         gl.glEnd();
      
      	/* PASS#3:	Use Texture "Base"
      	Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
      	Lighting Enabled
      	No Offset Texture-Coordinates
      	*/
         if (!emboss) {
            gl.glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
            gl.glBindTexture(GL_TEXTURE_2D,texture[filter]);
            gl.glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);	
            gl.glEnable(GL_LIGHTING);
            doCube();
         }
      
         xrot+=xspeed;
         yrot+=yspeed;
         if (xrot>360.0f) xrot-=360.0f;
         if (xrot<0.0f) xrot+=360.0f;
         if (yrot>360.0f) yrot-=360.0f;
         if (yrot<0.0f) yrot+=360.0f;
      
      /*	LAST PASS:	Do The Logos! */
         doLogo();
      
         return true;
      }
      boolean doMesh2TexelUnits() {
      
      
         float c[]={0.0f,0.0f,0.0f,1.0f};					// holds current vertex
         float n[]={0.0f,0.0f,0.0f,1.0f};					// normalized normal of current surface		
         float s[]={0.0f,0.0f,0.0f,1.0f};					// s-texture coordinate direction, normalized
         float t[]={0.0f,0.0f,0.0f,1.0f};					// t-texture coordinate direction, normalized
         float[] l=new float[4];										// holds our lightposition to be transformed into object space
         float[] Minv=new float[16];									// holds the inverted modelview matrix to do so.
         int i;								
      
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
      
      // Build Inverse Modelview Matrix First. This Substitutes One Push/Pop With One glLoadIdentity();
      // Simply Build It By Doing All Transformations Negated And In Reverse Order.
         gl.glLoadIdentity();								
         gl.glRotatef(-yrot,0.0f,1.0f,0.0f);
         gl.glRotatef(-xrot,1.0f,0.0f,0.0f);
         gl.glTranslatef(0.0f,0.0f,-z);
         gl.glGetFloatv(GL_MODELVIEW_MATRIX,Minv);
         gl.glLoadIdentity();
         gl.glTranslatef(0.0f,0.0f,z);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);	
      
      // Transform The Lightposition Into Object Coordinates:
         l[0]=LightPosition[0];
         l[1]=LightPosition[1];
         l[2]=LightPosition[2];
         l[3]=1.0f;											// Homogenous Coordinate
         VMatMult(Minv,l);
      
      /*	PASS#1: Texel-Unit 0:	Use Texture "Bump"
      					No Blend
      					No Lighting
      					No Offset Texture-Coordinates 
      					Texture-Operation "Replace"
      	Texel-Unit 1:	Use Texture "Invbump"
      					No Lighting
      					Offset Texture Coordinates 
      					Texture-Operation "Replace"
      */
      // TEXTURE-UNIT #0		
         gl.glActiveTextureARB(GL_TEXTURE0_ARB);
         gl.glEnable(GL_TEXTURE_2D);
         gl.glBindTexture(GL_TEXTURE_2D, bump[filter]);
         gl.glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT);
         gl.glTexEnvf (GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_REPLACE);	
      // TEXTURE-UNIT #1:
         gl.glActiveTextureARB(GL_TEXTURE1_ARB);
         gl.glEnable(GL_TEXTURE_2D);
         gl.glBindTexture(GL_TEXTURE_2D, invbump[filter]);
         gl.glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT);
         gl.glTexEnvf (GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_ADD);
      // General Switches:
         gl.glDisable(GL_BLEND);
         gl.glDisable(GL_LIGHTING);	
         gl.glBegin(GL_QUADS);	
      // Front Face	
         n[0]=0.0f;		n[1]=0.0f;		n[2]=1.0f;			
         s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=0; i<4; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]); 
            gl.glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Back Face	
         n[0]=0.0f;		n[1]=0.0f;		n[2]=-1.0f;	
         s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=4; i<8; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]); 
            gl.glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Top Face	
         n[0]=0.0f;		n[1]=1.0f;		n[2]=0.0f;		
         s[0]=1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
         for (i=8; i<12; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
            gl.glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Bottom Face
         n[0]=0.0f;		n[1]=-1.0f;		n[2]=0.0f;		
         s[0]=-1.0f;		s[1]=0.0f;		s[2]=0.0f;
         t[0]=0.0f;		t[1]=0.0f;		t[2]=-1.0f;
         for (i=12; i<16; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
            gl.glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Right Face	
         n[0]=1.0f;		n[1]=0.0f;		n[2]=0.0f;		
         s[0]=0.0f;		s[1]=0.0f;		s[2]=-1.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=16; i<20; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
            gl.glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }
      // Left Face
         n[0]=-1.0f;		n[1]=0.0f;		n[2]=0.0f;		
         s[0]=0.0f;		s[1]=0.0f;		s[2]=1.0f;
         t[0]=0.0f;		t[1]=1.0f;		t[2]=0.0f;
         for (i=20; i<24; i++) {	
            c[0]=data[5*i+2];		
            c[1]=data[5*i+3];
            c[2]=data[5*i+4];
            SetUpBumps(n,c,l,s,t);
            gl.glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     ); 
            gl.glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]); 
            gl.glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
         }		
         gl.glEnd();
      
      /* PASS#2	Use Texture "Base"
      	Blend GL_DST_COLOR To GL_SRC_COLOR (Multiplies By 2)
      	Lighting Enabled
      	No Offset Texture-Coordinates
      	*/	
         gl.glActiveTextureARB(GL_TEXTURE1_ARB);		
         gl.glDisable(GL_TEXTURE_2D);
         gl.glActiveTextureARB(GL_TEXTURE0_ARB);			
         if (!emboss) {						
            gl.glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
            gl.glBindTexture(GL_TEXTURE_2D,texture[filter]);
            gl.glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
            gl.glEnable(GL_BLEND);
            gl.glEnable(GL_LIGHTING);
            doCube();
         }
      
         xrot+=xspeed;
         yrot+=yspeed;
         if (xrot>360.0f) xrot-=360.0f;
         if (xrot<0.0f) xrot+=360.0f;
         if (yrot>360.0f) yrot-=360.0f;
         if (yrot<0.0f) yrot+=360.0f;
      
      /* LAST PASS:	Do The Logos! */	
         doLogo();
      
         return true;										// Keep Going
      }
   
      boolean doMeshNoBumps() {
      
      
         gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
         gl.glLoadIdentity();									// Reset The View
         gl.glTranslatef(0.0f,0.0f,z);
      
         gl.glRotatef(xrot,1.0f,0.0f,0.0f);
         gl.glRotatef(yrot,0.0f,1.0f,0.0f);	
         if (useMultitexture) {
            gl.glActiveTextureARB(GL_TEXTURE1_ARB);		
            gl.glDisable(GL_TEXTURE_2D);
            gl.glActiveTextureARB(GL_TEXTURE0_ARB);
         }
         gl.glDisable(GL_BLEND);
         gl.glBindTexture(GL_TEXTURE_2D,texture[filter]);	
         gl.glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
         gl.glEnable(GL_LIGHTING);
         doCube();
      
         xrot+=xspeed;
         yrot+=yspeed;
         if (xrot>360.0f) xrot-=360.0f;
         if (xrot<0.0f) xrot+=360.0f;
         if (yrot>360.0f) yrot-=360.0f;
         if (yrot<0.0f) yrot+=360.0f;
      
      /* LAST PASS:	Do The Logos! */	
         doLogo();
      
         return true;										// Keep Going
      }
      public void DrawGLScene()
      {
         if (bumps) {
            if (useMultitexture && maxTexelUnits[0]>1)
               doMesh2TexelUnits();	
            else 
               doMesh1TexelUnits();	
         }
         else 
            doMeshNoBumps();
      
         if (keys['E'])
         {
            keys['E']=false;
            emboss=!emboss;
         }				
         if (keys['M'])
         {
            keys['M']=false;
            useMultitexture=((!useMultitexture) && multitextureSupported);
         }				
         if (keys['B'])
         {
            keys['B']=false;
            bumps=!bumps;
         }				
         if (keys['F'])
         {
            keys['F']=false;
            filter++;
            filter%=3;
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