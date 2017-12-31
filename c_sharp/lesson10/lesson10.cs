/* 
 * NeHe Lesson 10 - Loading and Moving Through a 3D World
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=10
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
using System.IO;
using CsGL.OpenGL;

namespace Lesson10
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson10.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 10 - C#";
			this.view = new Lesson10.LessonView();
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

	public class Vertex
	{
		public float[] coords;				// Position (x, y, z), Texture (u, v)
		
		public Vertex()
		{
			this.coords = new float[5];
		}
	}

	public class Triangle
	{
		public Vertex[] vertex;

		public Triangle()
		{
			this.vertex = new Vertex[3];
			for (int i=0; i < 3; i++)
				this.vertex[i] = new Vertex();
		}
	}

	public class Sector
	{
		public Triangle[] triangle;

		public Sector()
		{
			this.triangle = null;
		}
	}
	
	public class LessonView : OpenGLControl
	{
		public bool	blend = false;				// Blending OFF/ON?
		public bool	fp = false;					// F Pressed?
		public bool	bp = false;					// B Pressed?
		
		public float heading = 0.0f;
		public float xpos = 0.0f;
		public float zpos = 0.0f;

		public float yrot = 0.0f;				// Y Rotation
		public float walkbias = 0;
		public float walkbiasangle = 0;
		public float lookupdown = 0.0f;
		public float z = 0.0f;					// Depth Into The Screen

		public int filter = 0;					// Which Filter To Use
		public uint[] texture = new uint[3];	// Texture array

		public Sector sector1 = new Sector();	// Our Model Goes Here:

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
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);						// Set The Blending Function For Translucency
			GL.glShadeModel(GL.GL_SMOOTH);									// Enable Smooth Shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
			GL.glClearDepth(1.0f);											// Depth Buffer Setup
			GL.glEnable(GL.GL_DEPTH_TEST);									// Enables Depth Testing
			GL.glDepthFunc(GL.GL_LESS);										// The Type Of Depth Testing To Do
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);		// Really Nice Perspective Calculations

			if (this.blend)													// If blending, turn it on and depth testing off
			{
				GL.glEnable(GL.GL_BLEND);
				GL.glDisable(GL.GL_DEPTH_TEST);
			}

			SetupWorld();
		}

		protected bool LoadTextures()
		{
			Bitmap image = null;
			string file = @"Data\Mud.bmp";
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

		public void SetupWorld()
		{
			string path = @"Data\World.txt";
			StreamReader filein = null;
			try
			{
				// If the file doesn't exist or can't be found, a FileNotFoundException is thrown instead of
				// just returning null, or if the directory as a whole isn't there, a DirectoryNotFound
				// exception will be thrown
				filein = new StreamReader(path, System.Text.Encoding.ASCII);
			}
			catch (System.IO.FileNotFoundException)
			{
				MessageBox.Show("Could not load " + path + ".  Please make sure that Data is a subfolder from where the application is running.", "Error", MessageBoxButtons.OK);
				this.finished = true;
			}
			catch (System.IO.DirectoryNotFoundException)
			{
				MessageBox.Show("Could not load " + path + ".  Please make sure that Data is a subfolder from where the application is running.", "Error", MessageBoxButtons.OK);
				this.finished = true;
			}

			if (filein != null)
			{
				string line = "";
				while (line.IndexOf("NUMPOLLIES") < 0)
					line = filein.ReadLine();
				string[] polystring = line.Split(' ');
				this.sector1.triangle = new Triangle[int.Parse(polystring[1])];
				for (int i=0; i < this.sector1.triangle.Length; i++)
				{
					this.sector1.triangle[i] = new Triangle();

					line = "";
					for (int v=0; v < 3; v++)
					{
						while (line.Trim().Length == 0 || line.IndexOf("//") >= 0)
							line = filein.ReadLine();
						string[] coords = line.Split(' ');
						int filled = 0;
						for (int j=0; j < coords.Length; j++)
						{
							if (coords[j].Trim().Length > 0)
							{
								sector1.triangle[i].vertex[v].coords[filled] = float.Parse(coords[j]);
								filled++;
							}
						}
						line = "";
					}
				}
				filein.Close();
			}
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			GL.glLoadIdentity();
			
			float x_m, y_m, z_m, u_m, v_m;
			
			GL.glRotatef(this.lookupdown, 1.0f, 0.0f, 0.0f);
			GL.glRotatef(360.0f - this.yrot, 0.0f, 1.0f, 0.0f);
	
			GL.glTranslatef(-this.xpos, -this.walkbias - 0.25f, -this.zpos);
			GL.glBindTexture(GL.GL_TEXTURE_2D, texture[filter]);
	
			// Process Each triangle
			GL.glBegin(GL.GL_TRIANGLES);
			GL.glNormal3f(0.0f, 0.0f, 1.0f);
			for (int i = 0; i < this.sector1.triangle.Length; i++)
			{
				x_m = this.sector1.triangle[i].vertex[0].coords[0];
				y_m = this.sector1.triangle[i].vertex[0].coords[1];
				z_m = this.sector1.triangle[i].vertex[0].coords[2];
				u_m = this.sector1.triangle[i].vertex[0].coords[3];
				v_m = this.sector1.triangle[i].vertex[0].coords[4];
				GL.glTexCoord2f(u_m, v_m); GL.glVertex3f(x_m, y_m, z_m);
			
				x_m = this.sector1.triangle[i].vertex[1].coords[0];
				y_m = this.sector1.triangle[i].vertex[1].coords[1];
				z_m = this.sector1.triangle[i].vertex[1].coords[2];
				u_m = this.sector1.triangle[i].vertex[1].coords[3];
				v_m = this.sector1.triangle[i].vertex[1].coords[4];
				GL.glTexCoord2f(u_m, v_m); GL.glVertex3f(x_m, y_m, z_m);
			
				x_m = this.sector1.triangle[i].vertex[2].coords[0];
				y_m = this.sector1.triangle[i].vertex[2].coords[1];
				z_m = this.sector1.triangle[i].vertex[2].coords[2];
				u_m = this.sector1.triangle[i].vertex[2].coords[3];
				v_m = this.sector1.triangle[i].vertex[2].coords[4];
				GL.glTexCoord2f(u_m, v_m); GL.glVertex3f(x_m, y_m, z_m);
			}
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
			else if (e.KeyCode == Keys.F && !this.fp)	// On the F key, cycle the texture filter (texture used)
			{
				this.fp = true;
				this.filter = (filter + 1) % 3;
			}
			else if (e.KeyCode == Keys.B && !this.bp)	// Blending code starts here
			{
				this.bp = true;
				this.blend = !this.blend;
				if (this.blend)
				{
					GL.glEnable(GL.GL_BLEND);			// Turn Blending On
					GL.glDisable(GL.GL_DEPTH_TEST);		// Turn Depth Testing Off
				}
				else
				{
					GL.glDisable(GL.GL_BLEND);			// Turn Blending Off
					GL.glEnable(GL.GL_DEPTH_TEST);		// Turn Depth Testing On
				}
			}											// Blending Code Ends Here
			else if (e.KeyCode == Keys.PageUp)			// On page up, move out
			{
				this.z -= 0.02f;
				this.lookupdown -= 1.0f;
			}
			else if (e.KeyCode == Keys.PageDown)		// On page down, move in
			{
				this.z += 0.02f;
				this.lookupdown += 1.0f;
			}
		}

		private void LessonView_KeyUp(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.F)				// Release the filter cycle key lock
				this.fp = false;
			else if (e.KeyCode == Keys.B)				// Release the blending toggle key lock
				this.bp = false;
		}

		protected override bool ProcessDialogKey(Keys keyData)
		{
			if (keyData == Keys.Up)
			{
				this.xpos -= (float)Math.Sin(this.heading * Math.PI / 180.0) * 0.05f;
				this.zpos -= (float)Math.Cos(this.heading * Math.PI / 180.0) * 0.05f;
				if (this.walkbiasangle >= 359.0f)
					this.walkbiasangle = 0.0f;
				else
					this.walkbiasangle += 10.0f;
				this.walkbias = (float)Math.Sin(this.walkbiasangle * Math.PI / 180.0) / 20.0f;
			}
			else if (keyData == Keys.Down)
			{
				this.xpos += (float)Math.Sin(this.heading * Math.PI / 180.0) * 0.05f;
				this.zpos += (float)Math.Cos(this.heading * Math.PI / 180.0) * 0.05f;
				if (this.walkbiasangle >= 359.0f)
					this.walkbiasangle = 0.0f;
				else
					this.walkbiasangle -= 10.0f;
				this.walkbias = (float)Math.Sin(this.walkbiasangle * Math.PI / 180.0) / 20.0f;
			}
			else if (keyData == Keys.Right)
			{
				this.heading -= 1.0f;
				this.yrot = this.heading;
			}
			else if (keyData == Keys.Left)
			{
				this.heading += 1.0f;
				this.yrot = this.heading;
			}

			return base.ProcessDialogKey (keyData);
		}
	}
}