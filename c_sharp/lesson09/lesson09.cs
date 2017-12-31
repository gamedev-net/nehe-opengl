/* 
 * NeHe Lesson 09 - Moving bitmaps in 3D space
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=09
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

namespace Lesson09
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson09.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 09 - C#";
			this.view = new Lesson09.LessonView();
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

	// Start public class
	public class Star
	{
		public byte r, g, b;		// Star Color
		public float dist;			// Star Distance From Center
		public float angle;		// Star Current Angle

		public Star()
		{
			this.r = this.g = this.b = 0;
			this.dist = this.angle = 0.0f;
		}
	}
		
	public class LessonView : OpenGLControl
	{
		public bool twinkle = true;					// Twinkling Stars
		public bool tp = false;						// 'T' Key Pressed?

		public static int num = 50;					// Number Of Stars To Draw
		public Star[] star = null;					// Need To Keep Track Of 'num' Stars

		public float zoom = -15.0f;					// Distance Away From Stars
		public float tilt = 90.0f;					// Tilt The View
		public float spin = 0.0f;					// Spin Stars
		
		public Random rand = new Random();			// Random number generator

		public uint	loop = 0;						// General Loop Variable
		public uint[] texture = new uint[1];		// Storage For One Texture

		public bool finished;
        
		public LessonView() : base()
		{
			this.KeyDown += new KeyEventHandler(LessonView_KeyDown);
			this.KeyUp += new KeyEventHandler(LessonView_KeyUp);
			this.star = new Star[LessonView.num];
			for (int i=0; i < LessonView.num; i++)
				this.star[i] = new Star();
			this.finished = false;
		}

		protected override void InitGLContext() 
		{
			LoadTextures();

			GL.glEnable(GL.GL_TEXTURE_2D);									// Enable Texture Mapping
			GL.glShadeModel(GL.GL_SMOOTH);									// Enable Smooth Shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
			GL.glClearDepth(1.0f);											// Depth Buffer Setup
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);		// Really Nice Perspective Calculations
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);						// Set The Blending Function For Translucency
			GL.glEnable(GL.GL_BLEND);

			for (this.loop=0; this.loop < LessonView.num; this.loop++)
			{
				this.star[this.loop].angle = 0.0f;
				this.star[this.loop].dist = ((float)(this.loop) / LessonView.num) * 5.0f;
				this.star[this.loop].r = (byte)rand.Next(256);
				this.star[this.loop].g = (byte)rand.Next(256);
				this.star[this.loop].b = (byte)rand.Next(256);
			}
		}

		protected bool LoadTextures()
		{
			Bitmap image = null;
			string file = @"Data\Star.bmp";
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

				GL.glGenTextures(1, this.texture);
			
				// Create Linear Filtered Texture
				GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
				GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, (int)GL.GL_RGB, image.Width, image.Height, 0, GL.GL_BGR_EXT, GL.GL_UNSIGNED_BYTE, bitmapdata.Scan0);

				image.UnlockBits(bitmapdata);
				image.Dispose();
				return true;
			}
			return false;
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);

			for (this.loop=0; this.loop < LessonView.num; this.loop++)				// Loop Through All The Stars
			{
				GL.glLoadIdentity();											// Reset The View Before We Draw Each this.star
				GL.glTranslatef(0.0f, 0.0f, this.zoom);							// Zoom Into The Screen (Using The Value In 'zoom')
				GL.glRotatef(this.tilt, 1.0f, 0.0f, 0.0f);						// Tilt The View (Using The Value In 'tilt')
				GL.glRotatef(this.star[this.loop].angle, 0.0f, 1.0f, 0.0f);		// Rotate To The Current this.stars AnGL.gle
				GL.glTranslatef(this.star[this.loop].dist, 0.0f, 0.0f);			// Move Forward On The X Plane
				GL.glRotatef(-this.star[this.loop].angle, 0.0f, 1.0f, 0.0f);	// Cancel The Current this.stars AnGL.gle
				GL.glRotatef(-this.tilt, 1.0f, 0.0f, 0.0f);						// Cancel The Screen Tilt
		
				if (this.twinkle)
				{
					GL.glColor4ub(this.star[(LessonView.num-this.loop)-1].r, this.star[(LessonView.num-this.loop)-1].g, this.star[(LessonView.num-this.loop)-1].b, 255);
					GL.glBegin(GL.GL_QUADS);
					GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.0f,-1.0f, 0.0f);
					GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.0f,-1.0f, 0.0f);
					GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.0f, 1.0f, 0.0f);
					GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.0f, 1.0f, 0.0f);
					GL.glEnd();
				}

				GL.glRotatef(this.spin, 0.0f, 0.0f, 1.0f);
				GL.glColor4ub(this.star[this.loop].r, this.star[this.loop].g, this.star[this.loop].b, 255);
				GL.glBegin(GL.GL_QUADS);
				GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.0f,-1.0f, 0.0f);
				GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.0f,-1.0f, 0.0f);
				GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.0f, 1.0f, 0.0f);
				GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.0f, 1.0f, 0.0f);
				GL.glEnd();

				this.spin += 0.01f;
				this.star[this.loop].angle += (float)(this.loop) / LessonView.num;
				this.star[this.loop].dist -= 0.01f;
				if (this.star[this.loop].dist < 0.0f)
				{
					this.star[this.loop].dist += 5.0f;
					this.star[this.loop].r = (byte)rand.Next(256);
					this.star[this.loop].g = (byte)rand.Next(256);
					this.star[this.loop].b = (byte)rand.Next(256);
				}
			}
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
			else if (e.KeyCode == Keys.T && !this.tp)
			{
				this.tp = true;
				this.twinkle = !this.twinkle;
			}
			else if (e.KeyCode == Keys.PageUp)			// On page up, move out
				this.zoom -= 0.2f;
			else if (e.KeyCode == Keys.PageDown)		// On page down, move in
				this.zoom += 0.2f;
		}

		private void LessonView_KeyUp(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.T)					// Release the twinkle toggle key lock
				this.tp = false;
		}

		protected override bool ProcessDialogKey(Keys keyData)
		{
			if (keyData == Keys.Up)						// Tilt about the x axis
				this.tilt -= 0.5f;
			else if (keyData == Keys.Down)
				this.tilt += 0.5f;
			
			return base.ProcessDialogKey (keyData);
		}
	}
}