/* 
 * NeHe Lesson 18 - Quadratics
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=18
 * 
 * Ported to C# by Brian Holley, February, 2004
 * http://tachyon.unl.edu
 * 
 * Uses the CsGL library from http://csgl.sourceforge.net
 * Some CsGL setup and image code from NeHe Lesson 06 C# port by Sabine Felsinger
 */

using System;
using System.Drawing;
using System.Windows.Forms;
using CsGL.OpenGL;

namespace Lesson18
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson18.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 18 - C#";
			this.view = new Lesson18.LessonView();
			this.view.Parent = this;
			this.view.Dock = DockStyle.Fill;
			this.Show();
		}

		static void Main() 
		{
			MainForm form = new MainForm();

			while ((!form.view.finished) && (!form.IsDisposed))
			{
				form.view.glDraw();
				form.Refresh();
				Application.DoEvents();
			}

			form.Dispose();
		}
	}
	
	public class LessonView : OpenGLControl
	{
		public bool	light = true;				// Lighting ON/OFF
		public bool	lp = false;					// L Pressed?
		public bool	fp = false;					// F Pressed?
		public bool sp = false;                 // Spacebar Pressed? ( NEW )

		public int part1 = 0;					// Start Of Disc ( NEW )
		public int part2 = 0;					// End Of Disc ( NEW )
		public int p1 = 0;						// Increase 1 ( NEW )
		public int p2 = 1;						// Increase 2 ( NEW )

		public float xrot = 0.0f;				// X-axis rotation
		public float yrot = 0.0f;				// Y-axis rotation
		public float zrot = 0.0f;
		public float xspeed = 0.0f;				// X Rotation Speed
		public float yspeed = 0.0f;				// Y Rotation Speed
		public float z = -5.0f;					// Depth Into The Screen

		public GLUquadric quadratic;			// Storage For Our Quadratic Objects ( NEW )
		
		// Lighting components for the cube
		public float[] LightAmbient =  {0.5f, 0.5f, 0.5f, 1.0f};
		public float[] LightDiffuse =  {1.0f, 1.0f, 1.0f, 1.0f};
		public float[] LightPosition = {0.0f, 0.0f, 2.0f, 1.0f};

		public int filter = 0;					// Which Filter To Use
		public uint[] texture = new uint[3];	// Texture array
		public uint obj = 0;					// Which Object To Draw (NEW)

		public bool finished;
        
		public LessonView() : base()
		{
			this.KeyDown += new KeyEventHandler(LessonView_KeyDown);
			this.KeyUp += new KeyEventHandler(LessonView_KeyUp);
			this.Disposed += new EventHandler(LessonView_Disposed);
			this.finished = false;
		}

		protected override void InitGLContext() 
		{
			LoadTextures();

			GL.glEnable(GL.GL_TEXTURE_2D);									// Enable Texture Mapping
			GL.glShadeModel(GL.GL_SMOOTH);									// Enable Smooth Shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
			GL.glClearDepth(1.0f);											// Depth Buffer Setup
			GL.glEnable(GL.GL_DEPTH_TEST);									// Enables Depth Testing
			GL.glDepthFunc(GL.GL_LEQUAL);									// The Type Of Depth Testing To Do
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);		// Really Nice Perspective Calculations

			GL.glLightfv(GL.GL_LIGHT1, GL.GL_AMBIENT,  this.LightAmbient);	// Setup The Ambient Light
			GL.glLightfv(GL.GL_LIGHT1, GL.GL_DIFFUSE,  this.LightDiffuse);	// Setup The Diffuse Light
			GL.glLightfv(GL.GL_LIGHT1, GL.GL_POSITION, this.LightPosition);	// Position The Light
			GL.glEnable(GL.GL_LIGHT1);										// Enable Light One

			this.quadratic = GL.gluNewQuadric();							// Create A Pointer To The Quadric Object (Return 0 If No Memory) (NEW)
			GL.gluQuadricNormals(this.quadratic, GL.GLU_SMOOTH);			// Create Smooth Normals (NEW)
			GL.gluQuadricTexture(this.quadratic, (byte)GL.GL_TRUE);			// Create Texture Coords (NEW)

			if (this.light)													// If lighting, enable it to start
				GL.glEnable(GL.GL_LIGHTING);
		}

		protected bool LoadTextures()
		{
			Bitmap image = null;
			string file = @"Data\Wall.bmp";
			try
			{
				// If the file doesn't exist or can't be found, an ArgumentException is thrown instead of
				// just returning null
				image = new Bitmap(file);
			} 
			catch (System.ArgumentException)
			{
				MessageBox.Show("Could not load " + file + ".  Please make sure that Data is a subfolder from where the application is running.", "Error", MessageBoxButtons.OK);
				this.finished = true;
			}
			if (image != null)
			{
				image.RotateFlip(RotateFlipType.RotateNoneFlipY);
				System.Drawing.Imaging.BitmapData bitmapdata;
				Rectangle rect = new Rectangle(0, 0, image.Width, image.Height);

				bitmapdata = image.LockBits(rect, System.Drawing.Imaging.ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format24bppRgb);

				GL.glGenTextures(3, this.texture);
			
				// Create Nearest Filtered Texture
				GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
				GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, (int)GL.GL_RGB, image.Width, image.Height, 0, GL.GL_BGR_EXT, GL.GL_UNSIGNED_BYTE, bitmapdata.Scan0);

				// Create Linear Filtered Texture
				GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[1]);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
				GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, (int)GL.GL_RGB, image.Width, image.Height, 0, GL.GL_BGR_EXT, GL.GL_UNSIGNED_BYTE, bitmapdata.Scan0);

				// Create MipMapped Texture
				GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[2]);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR_MIPMAP_NEAREST);
				GL.gluBuild2DMipmaps(GL.GL_TEXTURE_2D, (int)GL.GL_RGB, image.Width, image.Height, GL.GL_BGR_EXT, GL.GL_UNSIGNED_BYTE, bitmapdata.Scan0);

				image.UnlockBits(bitmapdata);
				image.Dispose();
				return true;
			}
			return false;
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			GL.glLoadIdentity();
			GL.glTranslatef(0.0f, 0.0f, this.z);

			GL.glRotatef(this.xrot, 1.0f, 0.0f, 0.0f);
			GL.glRotatef(this.yrot, 0.0f, 1.0f, 0.0f);

			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[filter]);

			switch (this.obj)
			{
				case 0:
					glDrawCube();
					break;
				case 1:
					GL.glTranslatef(0.0f, 0.0f, -1.5f);					// Center The Cylinder
					GL.gluCylinder(this.quadratic, 1.0f, 1.0f, 3.0f, 32, 32);	// A Cylinder With A Radius Of 0.5 And A Height Of 2
					break;
				case 2:
					GL.gluDisk(this.quadratic, 0.5f, 1.5f, 32, 32);				// Draw A Disc (CD Shape) With An Inner Radius Of 0.5, And An Outer Radius Of 2.  Plus A Lot Of Segments ;)
					break;
				case 3:
					GL.gluSphere(this.quadratic, 1.3f, 32, 32);					// Draw A Sphere With A Radius Of 1 And 16 Longitude And 16 Latitude Segments
					break;
				case 4:
					GL.glTranslatef(0.0f, 0.0f, -1.5f);							// Center The Cone
					GL.gluCylinder(this.quadratic, 1.0f, 0.0f, 3.0f, 32, 32);	// A Cone With A Bottom Radius Of .5 And A Height Of 2
					break;
				case 5:
					this.part1 += this.p1;
					this.part2 += this.p2;

					if (this.part1 > 359)									// 360 Degrees
					{
						this.p1 = 0;
						this.p2 = 1;
						this.part1 = this.part2 = 0;
					}
					if (this.part2 > 359)									// 360 Degrees
					{
						this.p1 = 1;
						this.p2 = 0;
					}
					GL.gluPartialDisk(this.quadratic, 0.5f, 1.5f, 32, 32, this.part1, this.part2 - this.part1);	// A Disk Like The One Before
					break;
			};

			this.xrot += this.xspeed;
			this.yrot += this.yspeed;
		}

		public void glDrawCube()
		{
			GL.glBegin(GL.GL_QUADS);
			// Front Face
			GL.glNormal3f( 0.0f, 0.0f, 1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.0f, -1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.0f, -1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.0f,  1.0f,  1.0f);
			// Back Face
			GL.glNormal3f( 0.0f, 0.0f,-1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f(-1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f(-1.0f,  1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f( 1.0f,  1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f( 1.0f, -1.0f, -1.0f);
			// Top Face
			GL.glNormal3f( 0.0f, 1.0f, 0.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.0f,  1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.0f,  1.0f, -1.0f);
			// Bottom Face
			GL.glNormal3f( 0.0f,-1.0f, 0.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f(-1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f( 1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f( 1.0f, -1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f(-1.0f, -1.0f,  1.0f);
			// Right Face
			GL.glNormal3f( 1.0f, 0.0f, 0.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.0f,  1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f( 1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f( 1.0f, -1.0f,  1.0f);
			// Left Face
			GL.glNormal3f(-1.0f, 0.0f, 0.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f(-1.0f, -1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f(-1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.0f,  1.0f, -1.0f);
			GL.glEnd();
		}

		protected override void OnSizeChanged(EventArgs e)
		{
			base.OnSizeChanged(e);
			Size s = Size;

			if (s.Height == 0)
				s.Height = 1;

			GL.glViewport(0, 0, s.Width, s.Height);

			GL.glMatrixMode(GL.GL_PROJECTION);
			GL.glLoadIdentity();
			GL.gluPerspective(45.0f, (double)s.Width /(double) s.Height, 0.1f, 100.0f);	
			GL.glMatrixMode(GL.GL_MODELVIEW);
			GL.glLoadIdentity();
		}

		protected void LessonView_KeyDown(object Sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.Escape)				// Finish the application if the escape key was pressed
				this.finished = true;
			else if (e.KeyCode == Keys.L && !this.lp)	// On the L key, flip the lighting mode
			{
				this.lp = true;
				this.light = !this.light;
				if (this.light)
					GL.glEnable(GL.GL_LIGHTING);
				else
					GL.glDisable(GL.GL_LIGHTING);
			}
			else if (e.KeyCode == Keys.F && !this.fp)	// On the F key, cycle the texture filter (texture used)
			{
				this.fp = true;
				this.filter = (filter + 1) % 3;
			}
			else if (e.KeyCode == Keys.Space && !this.sp)
			{
				this.sp = true;
				this.obj = (this.obj + 1) % 6;
			}
			else if (e.KeyCode == Keys.PageUp)			// On page up, move out
				this.z -= 0.02f;
			else if (e.KeyCode == Keys.PageDown)		// On page down, move in
				this.z += 0.02f;
		}

		private void LessonView_KeyUp(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.L)					// Release the lighting toggle key lock
				this.lp = false;
			else if (e.KeyCode == Keys.F)				// Release the filter cycle key lock
				this.fp = false;
			else if (e.KeyCode == Keys.Space)
				this.sp = false;
		}

		protected override bool ProcessDialogKey(Keys keyData)
		{
			if (keyData == Keys.Up)					// Change rotation about the x axis
				this.xspeed -= 0.01f;
			else if (keyData == Keys.Down)
				this.xspeed += 0.01f;
			else if (keyData == Keys.Right)			// Change rotation about the y axis
				this.yspeed += 0.01f;
			else if (keyData == Keys.Left)
				this.yspeed -= 0.01f;
		
			return base.ProcessDialogKey (keyData);
		}

		private void LessonView_Disposed(object sender, EventArgs e)
		{
			GL.gluDeleteQuadric(this.quadratic);	// Delete The Quadratic To Free System Resources
		}
	}
}