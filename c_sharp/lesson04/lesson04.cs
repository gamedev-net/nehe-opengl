/* Lesson 04 of NeHe Productions in C#
   created by Sabine Felsinger*/

using System;
using System.Windows.Forms;
using System.Drawing;
using CsGL.OpenGL;

namespace lesson04
{
	public class OurView : OpenGLControl
	{
		public float rtri;			// rtri stands for rotating the triangle
		public float rquad;			// rquad stands for rotating the quad

		public bool finished;

		public OurView() : base()
		{
			this.KeyDown += new KeyEventHandler(OurView_OnKeyDown);
			finished = false;
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
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);		// Clear the Screen and the Depth Buffer
			GL.glMatrixMode(GL.GL_MODELVIEW);				// Modelview Matrix
			GL.glLoadIdentity();							// reset the current modelview matrix
			GL.glTranslatef(-1.5f,0.0f,-6.0f);				// move 1.5 Units left and 6 Units into the screen
			GL.glRotatef(rtri,0.0f,1.0f,0.0f);				// rotate the triangle on the Y-axis
			rtri += 0.2f;									// increase the rotation variable
			GL.glBegin(GL.GL_TRIANGLES);					// start drawing a triangle
			GL.glColor3f(1.0f,0.0f,0.0f);					// red
			GL.glVertex3f( 0.0f, 1.0f, 0.0f);				// top point of the triangle
			GL.glColor3f(0.0f,1.0f,0.0f);					// green
			GL.glVertex3f(-1.0f,-1.0f, 0.0f);				// left point of the triangle
			GL.glColor3f(0.0f,0.0f,1.0f);					// blue
			GL.glVertex3f( 1.0f,-1.0f, 0.0f);				// right point of the triangle
			GL.glEnd();										// done drawing the triangle

			GL.glLoadIdentity();							// reset the current modelview matrix
			GL.glTranslatef(1.5f,0.0f,-6.0f);				// move 1.5 Units right and 6 Units into the screen
			GL.glRotatef(rquad,1.0f,0.0f,0.0f);				// rotate the triangle on the X-axis
			rquad -= 0.15f;									// decrease the rotation variable 
			GL.glColor3f(0.5f,0.5f,1.0f);					// blue 
			GL.glBegin(GL.GL_QUADS);						// start drawing a quad
			GL.glVertex3f(-1.0f, 1.0f, 0.0f);				// top left of the quad
			GL.glVertex3f( 1.0f, 1.0f, 0.0f);				// top right of the quad
			GL.glVertex3f( 1.0f,-1.0f, 0.0f);				// bottom right of the quad
			GL.glVertex3f(-1.0f,-1.0f, 0.0f);				// bottom left of the quad
			GL.glEnd();										// done drawing the quad
		}
            
			protected override void InitGLContext() 
			{
				GL.glShadeModel(GL.GL_SMOOTH);								// enable smooth shading
				GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);					// black background
				GL.glClearDepth(1.0f);										// depth buffer setup
				GL.glEnable(GL.GL_DEPTH_TEST);								// enables depth testing
				GL.glDepthFunc(GL.GL_LEQUAL);								// type of depth testing
				GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// nice perspective calculations
				//rtri = 30.0f;			you can define the starting position
				//rquad = 60.0f;		you can define the starting position
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
		private lesson04.OurView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "nehe lesson 04 in C# (by Sabine Felsinger)";
			this.view = new lesson04.OurView();			
			this.view.Parent = this;
			this.view.Dock = DockStyle.Fill; // Will fill whole form
			this.Show();
		}

		static void Main() 
		{
			MainForm form = new MainForm();

			while ((!form.view.finished) && (!form.IsDisposed))		// refreshing the window, so it rotates
			{
				form.view.glDraw();
				form.Refresh();
				Application.DoEvents();
			}

			form.Dispose();
		}
	}
}