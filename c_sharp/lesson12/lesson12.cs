/* 
 * NeHe Lesson 12 - Display Lists
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=12
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

namespace Lesson12
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson12.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 12 - C#";
			this.view = new Lesson12.LessonView();
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
		public uint box = 0;			// Storage For The Box Display List
		public uint top = 0;			// Storage For The Top Display List
		
		public float xrot = 0.0f;		// Rotates Cube On The X Axis
		public float yrot = 0.0f;		// Rotates Cube On The Y Axis

		public static float[][] boxcol = new float[5][] { 
			new float[3] {1.0f, 0.0f, 0.0f}, 
			new float[3] {1.0f, 0.5f, 0.0f},
			new float[3] {1.0f, 1.0f, 0.0f},
			new float[3] {0.0f, 1.0f, 0.0f},
			new float[3] {0.0f, 1.0f, 1.0f} };
		public static float[][] topcol = new float[5][] { 
			new float[3] {0.5f, 0.0f, 0.0f},
			new float[3] {0.5f, 0.25f, 0.0f},
			new float[3] {0.5f, 0.5f, 0.0f},
			new float[3] {0.0f, 0.5f, 0.0f},
			new float[3] {0.0f, 0.5f, 0.5f} };

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

			GL.glEnable(GL.GL_LIGHT0);										// Quick and dirty lighting
			GL.glEnable(GL.GL_LIGHTING);									// Enable lighting
			GL.glEnable(GL.GL_COLOR_MATERIAL);								// Enable material coloring

			BuildLists();
		}

		protected bool LoadTextures()
		{
			Bitmap image = null;
			string file = @"Data\Cube.bmp";
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

		public void BuildLists()
		{
			this.box = GL.glGenLists(2);						// Generate 2 Different Lists
			GL.glNewList(this.box, GL.GL_COMPILE);				// Start With The Box List
			GL.glBegin(GL.GL_QUADS);
			// Bottom Face
			GL.glNormal3f( 0.0f,-1.0f, 0.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f(-1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f( 1.0f, -1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f( 1.0f, -1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f(-1.0f, -1.0f,  1.0f);
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
			// Right face
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
			GL.glEndList();
			this.top = this.box + 1;							// Storage For "Top" Is "Box" Plus One
			GL.glNewList(this.top, GL.GL_COMPILE);				// Now The "Top" Display List
			GL.glBegin(GL.GL_QUADS);
			// Top Face
			GL.glNormal3f( 0.0f, 1.0f, 0.0f);
			GL.glTexCoord2f(0.0f, 1.0f); GL.glVertex3f(-1.0f,  1.0f, -1.0f);
			GL.glTexCoord2f(0.0f, 0.0f); GL.glVertex3f(-1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 0.0f); GL.glVertex3f( 1.0f,  1.0f,  1.0f);
			GL.glTexCoord2f(1.0f, 1.0f); GL.glVertex3f( 1.0f,  1.0f, -1.0f);
			GL.glEnd();
			GL.glEndList();
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);
			for (int yloop=1; yloop < 6; yloop++)
			{
				for (int xloop=0; xloop < yloop; xloop++)
				{
					GL.glLoadIdentity();							// Reset The View
					GL.glTranslatef(1.4f + ((float)xloop * 2.8f) - ((float)yloop * 1.4f), ((6.0f - (float)yloop) * 2.4f) - 7.0f, -20.0f);
					GL.glRotatef(45.0f - (2.0f * yloop) + this.xrot, 1.0f, 0.0f, 0.0f);
					GL.glRotatef(45.0f + this.yrot, 0.0f, 1.0f, 0.0f);
					GL.glColor3fv(LessonView.boxcol[yloop-1]);
					GL.glCallList(this.box);
					GL.glColor3fv(LessonView.topcol[yloop-1]);
					GL.glCallList(this.top);
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
		}

		protected override bool ProcessDialogKey(Keys keyData)
		{
			if (keyData == Keys.Up)						// Change rotation about the x axis
				this.xrot -= 4.2f;
			else if (keyData == Keys.Down)
				this.xrot += 4.2f;
			else if (keyData == Keys.Right)				// Change rotation about the y axis
				this.yrot += 4.2f;
			else if (keyData == Keys.Left)
				this.yrot -= 4.2f;
		
			return base.ProcessDialogKey (keyData);
		}
	}
}