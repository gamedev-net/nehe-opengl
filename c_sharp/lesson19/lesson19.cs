/* 
 * NeHe Lesson 19 - Particle Engine using Triangle Strips
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=19
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

namespace Lesson19
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson19.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 19 - C#";
			this.view = new Lesson19.LessonView();
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
		public static int MaxParticles = 500;	// Number of particles to create
		public bool	rainbow = true;				// Rainbow Mode?
		public bool	sp = false;					// Spacebar Pressed?
		public bool	rp = false;					// Enter Key Pressed?

		public float slowdown = 2.0f;			// Slow Down Particles
		public float xspeed = 0.0f;				// Base X Speed (To Allow Keyboard Direction Of Tail)
		public float yspeed = 0.0f;				// Base Y Speed (To Allow Keyboard Direction Of Tail)
		public float zoom = -40.0f;				// Used To Zoom Out

		public uint col = 0;					// Current Color Selection
		public uint delay = 0;					// Rainbow Effect Delay
		public Random rand = null;				// Random number generator
		
		public uint[] texture = new uint[3];	// Texture array

		public class Particle					// Create A Structure For Particle
		{
			public bool	active;					// Active (Yes/No)
			public float life;					// Particle Life
			public float fade;					// Fade Speed
			public float r, g, b;				// Color
			public float x, y, z;				// Position
			public float xi, yi, zi;			// Direction
			public float xg, yg, zg;			// Gravity
		}
		
		Particle[] particle = null;				// Particle Array (Room For Particle Info)

		public static float[][] colors = new float[12][] {	// Rainbow Of Colors
			new float[3] {1.0f,0.5f,0.5f}, new float[3] {1.0f,0.75f,0.5f}, 
			new float[3] {1.0f,1.0f,0.5f}, new float[3] {0.75f,1.0f,0.5f},
			new float[3] {0.5f,1.0f,0.5f}, new float[3] {0.5f,1.0f,0.75f}, 
			new float[3] {0.5f,1.0f,1.0f}, new float[3] {0.5f,0.75f,1.0f},
			new float[3] {0.5f,0.5f,1.0f}, new float[3] {0.75f,0.5f,1.0f}, 
			new float[3] {1.0f,0.5f,1.0f}, new float[3] {1.0f,0.5f,0.75f} };

		public bool finished;
        
		public LessonView() : base()
		{
			this.KeyDown += new KeyEventHandler(LessonView_KeyDown);
			this.KeyUp += new KeyEventHandler(LessonView_KeyUp);
			this.finished = false;

			this.particle = new Particle[LessonView.MaxParticles];
			for (int i=0; i < LessonView.MaxParticles; i++)
				this.particle[i] = new Particle();
		}

		protected override void InitGLContext() 
		{
			LoadTextures();

			GL.glEnable(GL.GL_TEXTURE_2D);									// Enable Texture Mapping
			GL.glShadeModel(GL.GL_SMOOTH);									// Enable Smooth Shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
			GL.glClearDepth(1.0f);											// Depth Buffer Setup
			GL.glDisable(GL.GL_DEPTH_TEST);									// Enables Depth Testing
			GL.glEnable(GL.GL_BLEND);										// Enable Blending
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);						// Type Of Blending To Perform
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);		// Really Nice Perspective Calculations

			GL.glHint(GL.GL_POINT_SMOOTH_HINT, GL.GL_NICEST);				// Really Nice Point Smoothing

			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);			// Select Our Texture

			this.rand = new Random();
			for (int loop=0; loop < LessonView.MaxParticles; loop++)		// Initials All The Textures
			{
				this.particle[loop].active = true;								// Make All The Particles Active
				this.particle[loop].life = 1.0f;								// Give All The this.particles Full Life
				this.particle[loop].fade = (float)(this.rand.Next(100))/1000.0f+0.003f;	// Random Fade Speed
				this.particle[loop].r = LessonView.colors[loop*(12/LessonView.MaxParticles)][0];	// Select Red Rainbow Color
				this.particle[loop].g = LessonView.colors[loop*(12/LessonView.MaxParticles)][1];	// Select Red Rainbow Color
				this.particle[loop].b = LessonView.colors[loop*(12/LessonView.MaxParticles)][2];	// Select Red Rainbow Color
				this.particle[loop].xi = (float)((this.rand.Next(50))-26.0f)*10.0f;	// Random Speed On X Axis
				this.particle[loop].yi = (float)((this.rand.Next(50))-25.0f)*10.0f;	// Random Speed On Y Axis
				this.particle[loop].zi = (float)((this.rand.Next(50))-25.0f)*10.0f;	// Random Speed On Z Axis
				this.particle[loop].xg = 0.0f;									// Set Horizontal Pull To Zero
				this.particle[loop].yg = -0.8f;									// Set Vertical Pull Downward
				this.particle[loop].zg = 0.0f;									// Set Pull On Z Axis To Zero
			}
		}

		protected bool LoadTextures()
		{
			Bitmap image = null;
			string file = @"Data\Particle.bmp";
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
			
			for (int loop=0; loop < LessonView.MaxParticles; loop++)	// Loop Through All The Particles
			{
				if (this.particle[loop].active)							// If The Particle Is Active
				{
					float x = this.particle[loop].x;					// Grab Our Particle X Position
					float y = this.particle[loop].y;					// Grab Our Particle Y Position
					float z = this.particle[loop].z+zoom;				// Particle Z Pos + Zoom

					// Draw The Particle Using Our RGB Values, Fade The Particle Based On It's Life
					GL.glColor4f(this.particle[loop].r, this.particle[loop].g, this.particle[loop].b, this.particle[loop].life);

					GL.glBegin(GL.GL_TRIANGLE_STRIP);						// Build Quad From A TrianGL.gle Strip
						GL.glTexCoord2d(1, 1); GL.glVertex3f(x+0.5f, y+0.5f, z); // Top Right
						GL.glTexCoord2d(0, 1); GL.glVertex3f(x-0.5f, y+0.5f, z); // Top Left
						GL.glTexCoord2d(1, 0); GL.glVertex3f(x+0.5f, y-0.5f, z); // Bottom Right
						GL.glTexCoord2d(0, 0); GL.glVertex3f(x-0.5f, y-0.5f, z); // Bottom Left
					GL.glEnd();										// Done Building TrianGL.gle Strip

					this.particle[loop].x += this.particle[loop].xi/(slowdown*1000);// Move On The X Axis By X Speed
					this.particle[loop].y += this.particle[loop].yi/(slowdown*1000);// Move On The Y Axis By Y Speed
					this.particle[loop].z += this.particle[loop].zi/(slowdown*1000);// Move On The Z Axis By Z Speed

					this.particle[loop].xi += this.particle[loop].xg;			// Take Pull On X Axis Into Account
					this.particle[loop].yi += this.particle[loop].yg;			// Take Pull On Y Axis Into Account
					this.particle[loop].zi += this.particle[loop].zg;			// Take Pull On Z Axis Into Account
					this.particle[loop].life -= this.particle[loop].fade;		// Reduce Particles Life By 'Fade'

					if (this.particle[loop].life < 0.0f)					// If Particle Is Burned Out
					{
						this.particle[loop].life = 1.0f;					// Give It New Life
						this.particle[loop].fade = (float)(this.rand.Next(100))/1000.0f+0.003f;	// Random Fade Value
						this.particle[loop].x = 0.0f;						// Center On X Axis
						this.particle[loop].y = 0.0f;						// Center On Y Axis
						this.particle[loop].z = 0.0f;						// Center On Z Axis
						this.particle[loop].xi = this.xspeed+(float)(this.rand.Next(60)-32.0f);	// X Axis Speed And Direction
						this.particle[loop].yi = this.yspeed+(float)(this.rand.Next(60)-30.0f);	// Y Axis Speed And Direction
						this.particle[loop].zi = (float)(this.rand.Next(60)-30.0f);	// Z Axis Speed And Direction
						this.particle[loop].r = LessonView.colors[this.col][0];			// Select Red From Color Table
						this.particle[loop].g = LessonView.colors[this.col][1];			// Select Green From Color Table
						this.particle[loop].b = LessonView.colors[this.col][2];			// Select Blue From Color Table
					}
				}
			}

			if (this.rainbow && (this.delay > 25))
			{
				this.delay = 0;						// Reset The Rainbow Color Cycling Delay
				this.col = (this.col + 1) % 12;		// Change The Particle Color
			}

			delay++;							// Increase Rainbow Mode Color Cycling Delay Counter
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
			else if (e.KeyCode == Keys.Add && (this.slowdown > 1.0f))
				this.slowdown -= 0.01f;		// Speed Up Particles
			else if (e.KeyCode == Keys.Subtract && (this.slowdown < 4.0f))
				this.slowdown+=0.01f;	// Slow Down Particles
			else if (e.KeyCode == Keys.PageUp)
				this.zoom += 0.1f;		// Zoom In
			else if (e.KeyCode == Keys.PageDown)
				this.zoom -= 0.1f;		// Zoom Out
			else if (e.KeyCode == Keys.Return && !this.rp)	// Return Key Pressed
			{
				this.rp = true;								// Set Flag Telling Us It's Pressed
				this.rainbow = !this.rainbow;				// Toggle Rainbow Mode On / Off
			}	
			else if (e.KeyCode == Keys.Space && !this.sp)	// Space Or Rainbow Mode
			{
				this.rainbow = false;			// If Spacebar Is Pressed Disable Rainbow Mode
				this.sp = true;						// Set Flag Telling Us Space Is Pressed
				this.delay = 0;						// Reset The Rainbow Color Cycling Delay
				this.col = (this.col + 1) % 12;		// Change The Particle Color
			}
			else
			{
				for (int loop=0; loop < LessonView.MaxParticles; loop++)
				{
					// If Number Pad 8 And Y Gravity Is Less Than 1.5 Increase Pull Upwards
					if (e.KeyCode == Keys.NumPad8 && (this.particle[loop].yg < 1.5f))
						this.particle[loop].yg += 0.01f;
						// If Number Pad 2 And Y Gravity Is Greater Than -1.5 Increase Pull Downwards
					else if (e.KeyCode == Keys.NumPad2 && (this.particle[loop].yg > -1.5f))
						this.particle[loop].yg -= 0.01f;
						// If Number Pad 6 And X Gravity Is Less Than 1.5 Increase Pull Right
					else if (e.KeyCode == Keys.NumPad6 && (this.particle[loop].xg < 1.5f))
						this.particle[loop].xg += 0.01f;
						// If Number Pad 4 And X Gravity Is Greater Than -1.5 Increase Pull Left
					else if (e.KeyCode == Keys.NumPad4 && (this.particle[loop].xg > -1.5f))
						this.particle[loop].xg -= 0.01f;
					else if (e.KeyCode == Keys.Tab)										// Tab Key Causes A Burst
					{
						this.particle[loop].x = 0.0f;								// Center On X Axis
						this.particle[loop].y = 0.0f;								// Center On Y Axis
						this.particle[loop].z = 0.0f;								// Center On Z Axis
						this.particle[loop].xi = (float)(this.rand.Next(50)-26.0f)*10.0f;	// Random Speed On X Axis
						this.particle[loop].yi = (float)(this.rand.Next(50)-25.0f)*10.0f;	// Random Speed On Y Axis
						this.particle[loop].zi = (float)(this.rand.Next(50)-25.0f)*10.0f;	// Random Speed On Z Axis
					}
				}
			}
		}

		private void LessonView_KeyUp(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.Space)			// Release the space key lock
				this.sp = false;
			else if (e.KeyCode == Keys.Return)		// Release the return key lock
				this.rp = false;
		}

		protected override bool ProcessDialogKey(Keys keyData)
		{
			if (keyData == Keys.Up && this.yspeed < 200)						// Change rotation about the x axis
				this.yspeed += 1.0f;
			else if (keyData == Keys.Down && this.yspeed > -200)
				this.yspeed -= 1.0f;
			else if (keyData == Keys.Right && this.xspeed < 200)				// Change rotation about the y axis
				this.xspeed += 1.0f;
			else if (keyData == Keys.Left && this.xspeed > -200)
				this.xspeed -= 1.0f;
		
			return base.ProcessDialogKey (keyData);
		}
	}
}