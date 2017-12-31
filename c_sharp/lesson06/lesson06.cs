/* Lesson 06 of NeHe Productions in C#
   created by Sabine Felsinger*/

using System;
using System.Drawing;
using System.Windows.Forms;
using CsGL.OpenGL;

namespace lesson06
{
	public class OurView : OpenGLControl
	{
		public float xrot;		// X-axis rotation
		public float yrot;		// Y-axis rotation
		public float zrot;		// Z-axis rotation

		// public float rquad;  (that's the old possibility)

		public bool finished;
        
		public uint[] texture;		// texture

		public OurView() : base()
		{
			this.KeyDown += new KeyEventHandler(OurView_OnKeyDown);
			finished = false;
			texture = new uint[1];		// storage for texture
		}

		protected void OurView_OnKeyDown(object Sender, KeyEventArgs kea)
		{
			//if escape was pressed exit the application
			if (kea.KeyCode == Keys.Escape) 
			{
				finished = true;
			}
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);	// Clear Screen and Depth Buffer
			GL.glMatrixMode(GL.GL_MODELVIEW);
			GL.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);					// defines the texture
			GL.glLoadIdentity();											// reset the current modelview matrix
			GL.glTranslatef(0.0f,0.0f,-5.0f);								// move 5 Units into the screen
			//GL.glRotatef(rquad,1.0f,1.0f,1.0f);		the old possibility
			//rquad -= -0.2f;
			GL.glRotatef(xrot,1.0f,0.0f,0.0f);			// rotate on the X-axis
			xrot+=0.3f;									// X-axis rotation
			GL.glRotatef(yrot,0.0f,1.0f,0.0f);			// rotate on the Y-axis
			yrot+=0.2f;									// Y-axis rotation
			GL.glRotatef(zrot,0.0f,0.0f,1.0f);			// rotate on the Z-axis
			zrot+=0.4f;									// Z-axis rotation

			GL.glBegin(GL.GL_QUADS);
			// Front Face
			GL.glTexCoord2f(1.0f,1.0f);			// top right of texture
			GL.glVertex3f(1.0f,1.0f,1.0f);		// top right of quad
			GL.glTexCoord2f(0.0f,1.0f);			// top left of texture
			GL.glVertex3f(-1.0f,1.0f,1.0f);		// top left of quad
			GL.glTexCoord2f(0.0f,0.0f);			// bottom left of texture
			GL.glVertex3f(-1.0f,-1.0f,1.0f);	// bottom left of quad
			GL.glTexCoord2f(1.0f,0.0f);			// bottom right of texture
			GL.glVertex3f(1.0f,-1.0f,1.0f);		// bottom right of quad

			// Back Face
			GL.glTexCoord2f(1.0f,1.0f);			// top right of texture
			GL.glVertex3f(-1.0f,1.0f,-1.0f);	// top right of quad
			GL.glTexCoord2f(0.0f,1.0f);			// top left of texture
			GL.glVertex3f(1.0f,1.0f,-1.0f);		// top left of quad
			GL.glTexCoord2f(0.0f,0.0f);			// bottom left of texture
			GL.glVertex3f(1.0f,-1.0f,-1.0f);	// bottom left of quad
			GL.glTexCoord2f(1.0f,0.0f);			// bottom right of texture
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);	// bottom right of quad

			// Top Face
			GL.glTexCoord2f(1.0f,1.0f);			// top right of texture
			GL.glVertex3f(1.0f,1.0f,-1.0f);		// top right of quad
			GL.glTexCoord2f(0.0f,1.0f);			// top left of texture
			GL.glVertex3f(-1.0f,1.0f,-1.0f);	// top left of quad
			GL.glTexCoord2f(0.0f,0.0f);			// bottom left of texture
			GL.glVertex3f(-1.0f,1.0f,1.0f);		// bottom left of quad
			GL.glTexCoord2f(1.0f,0.0f);			// bottom right of texture
			GL.glVertex3f(1.0f,1.0f,1.0f);		// bottom right of quad

			// Bottom Face
			GL.glTexCoord2f(1.0f,1.0f);			// top right of texture
			GL.glVertex3f(1.0f,-1.0f,1.0f);		// top right of quad
			GL.glTexCoord2f(0.0f,1.0f);			// top left of texture
			GL.glVertex3f(-1.0f,-1.0f,1.0f);	// top left of quad
			GL.glTexCoord2f(0.0f,0.0f);			// bottom left of texture
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);	// bottom left of quad
			GL.glTexCoord2f(1.0f,0.0f);			// bottom right of texture
			GL.glVertex3f(1.0f,-1.0f,-1.0f);	// bottom right of quad

			// Right Face
			GL.glTexCoord2f(1.0f,1.0f);			// top right of texture
			GL.glVertex3f(1.0f,1.0f,-1.0f);		// top right of quad
			GL.glTexCoord2f(0.0f,1.0f);			// top left of texture
			GL.glVertex3f(1.0f,1.0f,1.0f);		// top left of quad
			GL.glTexCoord2f(0.0f,0.0f);			// bottom left of texture
			GL.glVertex3f(1.0f,-1.0f,1.0f);		// bottom left of quad
			GL.glTexCoord2f(1.0f,0.0f);			// bottom right of texture
			GL.glVertex3f(1.0f,-1.0f,-1.0f);	// bottom right of quad

			// Left Face
			GL.glTexCoord2f(1.0f,1.0f);			// top right of texture
			GL.glVertex3f(-1.0f,1.0f,1.0f);		// top right of quad
			GL.glTexCoord2f(0.0f,1.0f);			// top left of texture
			GL.glVertex3f(-1.0f,1.0f,-1.0f);	// top left of quad
			GL.glTexCoord2f(0.0f,0.0f);			// bottom left of texture
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);	// bottom left of quad
			GL.glTexCoord2f(1.0f,0.0f);			// bottom right of texture
			GL.glVertex3f(-1.0f,-1.0f,1.0f);	// bottom right of quad
			GL.glEnd();
		}

		protected override void InitGLContext() 
		{
			GL.glShadeModel(GL.GL_SMOOTH);								// enable smooth shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);					// black background
			GL.glClearDepth(1.0f);										// depth buffer setup
			GL.glEnable(GL.GL_DEPTH_TEST);								// enables depth testing
			GL.glDepthFunc(GL.GL_LEQUAL);								// type of depth testing
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// nice perspective calculations
			// rquad = 150.0f;		defines the rotation angle in the start position of the quad

			GL.glEnable(GL.GL_TEXTURE_2D);

			Bitmap image = new Bitmap("water.bmp");
			image.RotateFlip(RotateFlipType.RotateNoneFlipY);
			System.Drawing.Imaging.BitmapData bitmapdata;
			Rectangle rect = new Rectangle(0, 0, image.Width, image.Height);

			bitmapdata = image.LockBits(rect, System.Drawing.Imaging.ImageLockMode.ReadOnly, 
				System.Drawing.Imaging.PixelFormat.Format24bppRgb);

			GL.glGenTextures(1, texture);
			GL.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);
			GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, (int)GL.GL_RGB8, image.Width, image.Height,
				0, GL.GL_BGR_EXT, GL.GL_UNSIGNED_BYTE, bitmapdata.Scan0);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);		// Linear Filtering
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);		// Linear Filtering

			image.UnlockBits(bitmapdata);
			image.Dispose();
		}

		protected override void OnSizeChanged(EventArgs e)
		{
			base.OnSizeChanged(e);
			Size s = Size;

			GL.glMatrixMode(GL.GL_PROJECTION);
			GL.glLoadIdentity();
			GL.gluPerspective(45.0f, (double)s.Width /(double) s.Height, 0.1f, 100.0f);	
			GL.glMatrixMode(GL.GL_MODELVIEW);
			GL.glLoadIdentity();
		}
	}
	
	public class MainForm : System.Windows.Forms.Form	
	{
		public lesson06.OurView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "nehe lesson 06 in C# (by Sabine Felsinger)";
			this.view = new lesson06.OurView();			
			this.view.Parent = this;
			this.view.Dock = DockStyle.Fill; // Will fill whole form
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
}