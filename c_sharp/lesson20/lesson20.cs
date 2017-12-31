/* 
 * NeHe Lesson 20 - Masking
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=20
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

namespace Lesson20
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson20.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 20 - C#";
			this.view = new Lesson20.LessonView();
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
		public bool masking = true;				// Masking On/Off
		public bool mp = false;					// M Pressed?
		public bool sp = false;					// Space Pressed?
		public bool scene = false;				// Which Scene To Draw
		public float roll = 0.0f;				// Rolling Texture
		
		public uint[] texture = new uint[5];	// Storage For Our Five Textures
		
		public bool finished;
        
		public LessonView() : base()
		{
			this.KeyDown += new KeyEventHandler(LessonView_KeyDown);
			this.KeyUp += new KeyEventHandler(LessonView_KeyUp);
			this.finished = false;
		}

		protected override void InitGLContext() 
		{
			LoadTextures();

			GL.glEnable(GL.GL_TEXTURE_2D);									// Enable Texture Mapping
			GL.glShadeModel(GL.GL_SMOOTH);									// Enable Smooth Shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);						// Black Background
			GL.glClearDepth(1.0f);											// Depth Buffer Setup
			GL.glEnable(GL.GL_DEPTH_TEST);									// Enables Depth Testing
		}

		protected bool LoadTextures()
		{
			Bitmap[] image = new Bitmap[5];
			string[] file = {@"Data\logo.bmp", @"Data\mask1.bmp", @"Data\image1.bmp", @"Data\mask2.bmp", @"Data\image2.bmp"};
			try
			{
				// If the files don't exist or can't be found, an ArgumentException is thrown instead of
				// just returning null
				for (int i=0; i < file.Length; i++)
					image[i] = new Bitmap(file[i]);
			} 
			catch (System.ArgumentException)
			{
				MessageBox.Show("Could not load data files.  Please make sure that Data is a subfolder from where the application is running.", "Error", MessageBoxButtons.OK);
				this.finished = true;
			}
			if (!this.finished)
			{
				GL.glGenTextures(image.Length, this.texture);
			
				for (int i=0; i < image.Length; i++)
				{
					image[i].RotateFlip(RotateFlipType.RotateNoneFlipY);
					System.Drawing.Imaging.BitmapData bitmapdata;
					Rectangle rect = new Rectangle(0, 0, image[i].Width, image[i].Height);

					bitmapdata = image[i].LockBits(rect, System.Drawing.Imaging.ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format24bppRgb);

					// Create Linear Filtered Texture
					GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[i]);
					GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
					GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
					GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, (int)GL.GL_RGB, image[i].Width, image[i].Height, 0, GL.GL_BGR_EXT, GL.GL_UNSIGNED_BYTE, bitmapdata.Scan0);

					image[i].UnlockBits(bitmapdata);
					image[i].Dispose();
				}
				return true;
			}
			return false;
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			GL.glLoadIdentity();
			
			GL.glTranslatef(0.0f, 0.0f, -2.0f);						// Move Into The Screen 5 Units

			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);			// Select Our Logo Texture
			GL.glBegin(GL.GL_QUADS);									// Start Drawing A Textured Quad
			GL.glTexCoord2f(0.0f, -this.roll+0.0f); GL.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
			GL.glTexCoord2f(3.0f, -this.roll+0.0f); GL.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
			GL.glTexCoord2f(3.0f, -this.roll+3.0f); GL.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
			GL.glTexCoord2f(0.0f, -this.roll+3.0f); GL.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
			GL.glEnd();											// Done Drawing The Quad

			GL.glEnable(GL.GL_BLEND);									// Enable Blending
			GL.glDisable(GL.GL_DEPTH_TEST);							// Disable Depth Testing

			if (this.masking)										// Is Masking Enabled?
				GL.glBlendFunc(GL.GL_DST_COLOR, GL.GL_ZERO);				// Blend Screen Color With Zero (Black)
			
			if (this.scene)											// Are We Drawing The Second Scene?
			{
				GL.glTranslatef(0.0f, 0.0f, -1.0f);					// Translate Into The Screen One Unit
				GL.glRotatef(this.roll*360, 0.0f, 0.0f, 1.0f);				// Rotate On The Z Axis 360 Degrees.
				if (this.masking)									// Is Masking On?
				{
					GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[3]);	// Select The Second Mask Texture
					GL.glBegin(GL.GL_QUADS);							// Start Drawing A Textured Quad
					GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
					GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
					GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
					GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
					GL.glEnd();									// Done Drawing The Quad
				}

				GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);					// Copy Image 2 Color To The Screen
				GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[4]);		// Select The Second Image Texture
				GL.glBegin(GL.GL_QUADS);								// Start Drawing A Textured Quad
				GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
				GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
				GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
				GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
				GL.glEnd();										// Done Drawing The Quad
			}
			else												// Otherwise
			{
				if (this.masking)									// Is Masking On?
				{
					GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[1]);	// Select The First Mask Texture
					GL.glBegin(GL.GL_QUADS);							// Start Drawing A Textured Quad
					GL.glTexCoord2f(this.roll+0.0f, 0.0f); GL.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
					GL.glTexCoord2f(this.roll+4.0f, 0.0f); GL.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
					GL.glTexCoord2f(this.roll+4.0f, 4.0f); GL.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
					GL.glTexCoord2f(this.roll+0.0f, 4.0f); GL.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
					GL.glEnd();									// Done Drawing The Quad
				}

				GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);					// Copy Image 1 Color To The Screen
				GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[2]);		// Select The First Image Texture
				GL.glBegin(GL.GL_QUADS);								// Start Drawing A Textured Quad
				GL.glTexCoord2f(roll+0.0f, 0.0f); GL.glVertex3f(-1.1f, -1.1f,  0.0f);	// Bottom Left
				GL.glTexCoord2f(roll+4.0f, 0.0f); GL.glVertex3f( 1.1f, -1.1f,  0.0f);	// Bottom Right
				GL.glTexCoord2f(roll+4.0f, 4.0f); GL.glVertex3f( 1.1f,  1.1f,  0.0f);	// Top Right
				GL.glTexCoord2f(roll+0.0f, 4.0f); GL.glVertex3f(-1.1f,  1.1f,  0.0f);	// Top Left
				GL.glEnd();										// Done Drawing The Quad
			}

			GL.glEnable(GL.GL_DEPTH_TEST);							// Enable Depth Testing
			GL.glDisable(GL.GL_BLEND);								// Disable Blending

			this.roll += 0.002f;										// Increase Our Texture Roll Variable
			if (this.roll > 1.0f)										// Is Roll Greater Than One
				this.roll -= 1.0f;										// Subtract 1 From Roll
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
			if (e.KeyCode == Keys.Escape)					// Finish the application if the escape key was pressed
				this.finished = true;
			else if (e.KeyCode == Keys.Space && !this.sp)	// Is Space Being Pressed?
			{
				this.sp = true;								// Tell Program Spacebar Is Being Held
				this.scene = !this.scene;					// Toggle From One Scene To The Other
			}
			else if (e.KeyCode == Keys.M && !this.mp)		// Is M Being Pressed?
			{
				this.mp = true;								// Tell Program M Is Being Held
				this.masking = !this.masking;				// Toggle Masking Mode OFF/ON
			}
		}

		private void LessonView_KeyUp(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.Space)
				this.sp = false;
			else if (e.KeyCode == Keys.M)
				this.mp = false;
		}
	}
}