/* 
 * NeHe Lesson 11 - Flag Efffect (Waving Texture)
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=11
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

namespace Lesson11
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson11.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 11 - C#";
			this.view = new Lesson11.LessonView();
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
		public float[][][] points;				// The Array For The Points On The Grid Of Our "Wave"
		public int wiggle_count = 0;			// Counter Used To Control How Fast Flag Waves

		public float xrot = 0.0f;				// X Rotation ( NEW )
		public float yrot = 0.0f;				// Y Rotation ( NEW )
		public float zrot = 0.0f;				// Z Rotation ( NEW )
		
		public uint[] texture = new uint[1];	// Texture array

		public bool finished;
        
		public LessonView() : base()
		{
			this.KeyDown += new KeyEventHandler(LessonView_KeyDown);
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

			GL.glPolygonMode(GL.GL_BACK, GL.GL_FILL);						// Back Face Is Solid
			GL.glPolygonMode(GL.GL_FRONT, GL.GL_LINE);						// Front Face Is Made Of Lines
			
			this.points = new float[45][][];
			for (int i=0; i < this.points.Length; i++)
			{
				this.points[i] = new float[45][];
				for (int j=0; j < this.points[i].Length; j++)
				{
					this.points[i][j] = new float[3];
					this.points[i][j][0] = (float)((i / 5.0f) - 4.5f);
					this.points[i][j][1] = (float)((j / 5.0f) - 4.5f);
					this.points[i][j][2] = (float)(Math.Sin((((i / 5.0f) * 40.0f) / 360.0f) * Math.PI * 2.0f));
				}
			}
		}

		protected bool LoadTextures()
		{
			Bitmap image = null;
			string file = @"Data\Tim.bmp";
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
			GL.glLoadIdentity();
			
			float float_x, float_y, float_xb, float_yb;

			GL.glTranslatef(0.0f, 0.0f, -12.0f);
	  
			GL.glRotatef(this.xrot, 1.0f, 0.0f, 0.0f);
			GL.glRotatef(this.yrot, 0.0f, 1.0f, 0.0f);  
			GL.glRotatef(this.zrot, 0.0f, 0.0f, 1.0f);

			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);

			GL.glBegin(GL.GL_QUADS);
			for (int i=0; i < 44; i++ )
			{
				for (int j=0; j < 44; j++ )
				{
					float_x = (float)i/44.0f;
					float_y = (float)j/44.0f;
					float_xb = (float)(i+1)/44.0f;
					float_yb = (float)(j+1)/44.0f;

					GL.glTexCoord2f(float_x, float_y);
					GL.glVertex3f(this.points[i][j][0], this.points[i][j][1], this.points[i][j][2]);

					GL.glTexCoord2f(float_x, float_yb);
					GL.glVertex3f(this.points[i][j+1][0], this.points[i][j+1][1], this.points[i][j+1][2]);

					GL.glTexCoord2f(float_xb, float_yb);
					GL.glVertex3f(this.points[i+1][j+1][0], this.points[i+1][j+1][1], this.points[i+1][j+1][2]);

					GL.glTexCoord2f(float_xb, float_y);
					GL.glVertex3f(this.points[i+1][j][0], this.points[i+1][j][1], this.points[i+1][j][2]);
				}
			}
			GL.glEnd();

			float hold = 0.0f;
			if (this.wiggle_count == 2)
			{
				for (int j=0; j < this.points[0].Length; j++ )
				{
					hold = this.points[0][j][2];
					for (int i=0; i < this.points.Length - 1; i++)
					{
						this.points[i][j][2] = this.points[i+1][j][2];
					}
					this.points[this.points.Length - 1][j][2] = hold;
				}
				this.wiggle_count = 0;
			}

			this.wiggle_count++;

			this.xrot += 0.3f;
			this.yrot += 0.2f;
			this.zrot += 0.4f;
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
		}
	}
}