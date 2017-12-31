/* 
 * NeHe Lesson 17 - 2D Texture Font
 * http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=17
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

namespace Lesson17
{
	public class MainForm : System.Windows.Forms.Form	
	{
		public Lesson17.LessonView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe Lesson 17 - C#";
			this.view = new Lesson17.LessonView();
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
		public uint baseList = 0;		// Base Display List For The Font
		
		public float cnt1 = 0.0f;		// 1st Counter Used To Move Text & For Coloring
		public float cnt2 = 0.0f;		// 2nd Counter Used To Move Text & For Coloring

		public uint[] texture = new uint[2];	// Texture array

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
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);						// Select The Type Of Blending
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);		// Really Nice Perspective Calculations

			BuildFont();
		}

		protected bool LoadTextures()
		{
			Bitmap[] image = {null, null};
			string[] file = {@"Data\Font.bmp", @"Data\Bumps.bmp"};
			try
			{
				// If the file doesn't exist or can't be found, an ArgumentException is thrown instead of
				// just returning null
				image[0] = new Bitmap(file[0]);
				image[1] = new Bitmap(file[1]);
			} 
			catch (System.ArgumentException)
			{
				MessageBox.Show("Could not load " + file[0] + " or " + file[1] + ".  Please make sure that Data is a subfolder from where the application is running.", "Error", MessageBoxButtons.OK);
				this.finished = true;
			}
			if (image != null)
			{
				GL.glGenTextures(2, this.texture);
			
				for (int i=0; i < 2; i++)
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

		public void BuildFont()									// Build Our Font Display List
		{
			float cx;											// Holds Our X Character Coord
			float cy;											// Holds Our Y Character Coord

			this.baseList = GL.glGenLists(256);					// Creating 256 Display Lists
			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[0]);	// Select Our Font Texture
			for (int loop=0; loop < 256; loop++)				// Loop Through All 256 Lists
			{
				cx = (float)(loop % 16) / 16.0f;				// X Position Of Current Character
				cy = (float)(loop / 16) / 16.0f;				// Y Position Of Current Character

				GL.glNewList((uint)(this.baseList+loop), GL.GL_COMPILE);// Start Building A List
				GL.glBegin(GL.GL_QUADS);						// Use A Quad For Each Character
				GL.glTexCoord2f(cx, 1 - cy - 0.0625f);			// Texture Coord (Bottom Left)
				GL.glVertex2i(0, 0);							// Vertex Coord (Bottom Left)
				GL.glTexCoord2f(cx + 0.0625f, 1 - cy - 0.0625f);// Texture Coord (Bottom Right)
				GL.glVertex2i(16, 0);							// Vertex Coord (Bottom Right)
				GL.glTexCoord2f(cx + 0.0625f, 1 - cy);			// Texture Coord (Top Right)
				GL.glVertex2i(16, 16);							// Vertex Coord (Top Right)
				GL.glTexCoord2f(cx, 1 - cy);					// Texture Coord (Top Left)
				GL.glVertex2i(0, 16);							// Vertex Coord (Top Left)
				GL.glEnd();										// Done Building Our Quad (Character)
				GL.glTranslated(10, 0, 0);						// Move To The Right Of The Character
				GL.glEndList();									// Done Building The Display List
			}													// Loop Until All 256 Are Built
		}

		public void KillFont()									// Delete The Font From Memory
		{
			GL.glDeleteLists(this.baseList, 256);				// Delete All 256 Display Lists
		}

		public void glPrint(int x, int y, string str, int charSet)	// Where The Printing Happens
		{
			if (charSet > 1)
				charSet = 1;
			GL.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);			// Select Our Font Texture
			GL.glDisable(GL.GL_DEPTH_TEST);							// Disables Depth Testing
			GL.glMatrixMode(GL.GL_PROJECTION);						// Select The Projection Matrix
			GL.glPushMatrix();										// Store The Projection Matrix
			GL.glLoadIdentity();									// Reset The Projection Matrix
			GL.glOrtho(0, 640, 0, 480, -1, 1);						// Set Up An Ortho Screen
			GL.glMatrixMode(GL.GL_MODELVIEW);						// Select The Modelview Matrix
			GL.glPushMatrix();										// Store The Modelview Matrix
			GL.glLoadIdentity();									// Reset The Modelview Matrix
			GL.glTranslated(x,y,0);									// Position The Text (0,0 - Bottom Left)
			GL.glListBase((uint)(this.baseList - 32 + (128 * charSet)));	// Choose The Font Set (0 or 1)
			// This is a really, really strange quirk of the CsGL library.  It seems that the glCallLists
			// function, when passed a string, is supposed to be in unicode format, which means that we have
			// to double the length for it to print the full string.  Strange, but it works.
			GL.glCallLists(str.Length * 2, GL.GL_UNSIGNED_BYTE, str);	// Write The Text To The Screen
			GL.glMatrixMode(GL.GL_PROJECTION);						// Select The Projection Matrix
			GL.glPopMatrix();										// Restore The Old Projection Matrix
			GL.glMatrixMode(GL.GL_MODELVIEW);						// Select The Modelview Matrix
			GL.glPopMatrix();										// Restore The Old Projection Matrix
			GL.glEnable(GL.GL_DEPTH_TEST);							// Enables Depth Testing
		}

		public override void glDraw()
		{
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			GL.glLoadIdentity();
			GL.glBindTexture(GL.GL_TEXTURE_2D, this.texture[1]);	// Select Our Second Texture
			GL.glTranslatef(0.0f, 0.0f, -5.0f);						// Move Into The Screen 5 Units
			GL.glRotatef(45.0f, 0.0f, 0.0f, 1.0f);					// Rotate On The Z Axis 45 Degrees (Clockwise)
			GL.glRotatef(this.cnt1 * 30.0f, 1.0f, 1.0f, 0.0f);		// Rotate On The X & Y Axis By cnt1 (Left To Right)
			GL.glDisable(GL.GL_BLEND);								// Disable Blending Before We Draw In 3D
			GL.glColor3f(1.0f, 1.0f, 1.0f);							// Bright White
			GL.glBegin(GL.GL_QUADS);								// Draw Our First Texture Mapped Quad
				GL.glTexCoord2d(0.0f, 0.0f);						// First Texture Coord
				GL.glVertex2f(-1.0f, 1.0f);							// First Vertex
				GL.glTexCoord2d(1.0f, 0.0f);						// Second Texture Coord
				GL.glVertex2f( 1.0f, 1.0f);							// Second Vertex
				GL.glTexCoord2d(1.0f, 1.0f);						// Third Texture Coord
				GL.glVertex2f( 1.0f, -1.0f);						// Third Vertex
				GL.glTexCoord2d(0.0f, 1.0f);						// Fourth Texture Coord
				GL.glVertex2f(-1.0f, -1.0f);						// Fourth Vertex
			GL.glEnd();												// Done Drawing The First Quad
			GL.glRotatef(90.0f, 1.0f, 1.0f, 0.0f);					// Rotate On The X & Y Axis By 90 Degrees (Left To Right)
			GL.glBegin(GL.GL_QUADS);									// Draw Our Second Texture Mapped Quad
				GL.glTexCoord2d(0.0f, 0.0f);						// First Texture Coord
				GL.glVertex2f(-1.0f, 1.0f);							// First Vertex
				GL.glTexCoord2d(1.0f, 0.0f);						// Second Texture Coord
				GL.glVertex2f( 1.0f, 1.0f);							// Second Vertex
				GL.glTexCoord2d(1.0f, 1.0f);						// Third Texture Coord
				GL.glVertex2f( 1.0f, -1.0f);						// Third Vertex
				GL.glTexCoord2d(0.0f, 1.0f);						// Fourth Texture Coord
				GL.glVertex2f(-1.0f, -1.0f);						// Fourth Vertex
			GL.glEnd();												// Done Drawing Our Second Quad
			GL.glEnable(GL.GL_BLEND);									// Enable Blending

			GL.glLoadIdentity();									// Reset The View
			// Pulsing Colors Based On Text Position
			GL.glColor3f(1.0f*(float)Math.Cos(this.cnt1), 1.0f*(float)Math.Sin(this.cnt2), 1.0f-0.5f*(float)Math.Cos(this.cnt1+this.cnt2));
			glPrint((int)(280+250*Math.Cos(this.cnt1)), (int)(235+200*Math.Sin(this.cnt2)), "NeHe", 0);		// Pr(int) GL.GL Text To The Screen

			GL.glColor3f(1.0f*(float)(Math.Sin(this.cnt2)), 1.0f-0.5f*(float)(Math.Cos(this.cnt1+this.cnt2)), 1.0f*(float)(Math.Cos(this.cnt1)));
			glPrint((int)(280+230*Math.Cos(this.cnt2)), (int)(235+200*Math.Sin(this.cnt1)), "OpenGL", 0);	// Pr(int) GL.GL Text To The Screen

			GL.glColor3f(0.0f, 0.0f, 1.0f);							// Set Color To Blue
			glPrint((int)(240+200*Math.Cos((this.cnt2+this.cnt1)/5)), 2, "Giuseppe D'Agata", 0);

			GL.glColor3f(1.0f, 1.0f, 1.0f);							// Set Color To White
			glPrint((int)(242+200*Math.Cos((this.cnt2+this.cnt1)/5)), 2, "Giuseppe D'Agata", 0);

			this.cnt1 += 0.01f;										// Increase The First Counter
			this.cnt2 += 0.0081f;										// Increase The Second Counter
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