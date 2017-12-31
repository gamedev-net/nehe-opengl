/* Lesson 05 of NeHe Productions in C#
   created by Sabine Felsinger*/

using System;
using System.Windows.Forms;
using System.Drawing;
using CsGL.OpenGL;

namespace lesson05
{
	public class OurView : OpenGLControl
	{
		public float rtri;			// rtri is for rotating the pyramid
		public float rquad;			// rquad is for rotating the quad

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
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);	// Clear the Screen and the Depth Buffer
			GL.glMatrixMode(GL.GL_MODELVIEW);		// Modelview Matrix
			GL.glLoadIdentity();					// reset the current modelview matrix
			GL.glTranslatef(-1.5f,0.0f,-6.0f);		// move 1.5 Units left and 6 Units into the screen
			GL.glRotatef(rtri,0.0f,1.0f,0.0f);		// rotate the Pyramid on it's Y-axis
			rtri+=0.2f;								// rotation angle

			GL.glBegin(GL.GL_TRIANGLES);			// start drawing a triangle, always counterclockside (top-left-right)
			GL.glColor3f(1.0f,0.0f,0.0f);			// Red
			GL.glVertex3f(0.0f,1.0f,0.0f);			// Top of Triangle (Front)
			GL.glColor3f(0.0f,1.0f,0.0f);			// green
			GL.glVertex3f(-1.0f,-1.0f,1.0f);		// left of Triangle (front)
			GL.glColor3f(0.0f,0.0f,1.0f);			// blue
			GL.glVertex3f(1.0f,-1.0f,1.0f);			// right of triangle (front)

			GL.glColor3f(1.0f,0.0f,0.0f);			// red
			GL.glVertex3f(0.0f,1.0f,0.0f);			// top of triangle (right)
			GL.glColor3f(0.0f,0.0f,1.0f);			// blue
			GL.glVertex3f(1.0f,-1.0f,1.0f);			// left of triangle (right)
			GL.glColor3f(0.0f,1.0f,0.0f);			// green
			GL.glVertex3f(1.0f,-1.0f,-1.0f);		// right of triangel (right)

			GL.glColor3f(1.0f,0.0f,0.0f);			// red
			GL.glVertex3f(0.0f,1.0f,0.0f);			// top of triangle (back)
			GL.glColor3f(0.0f,1.0f,0.0f);			// green
			GL.glVertex3f(1.0f,-1.0f,-1.0f);		// left of triangle (back)
			GL.glColor3f(0.0f,0.0f,1.0f);			// blue
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);		// right of triangle (back)

			GL.glColor3f(1.0f,0.0f,0.0f);			// red
			GL.glVertex3f(0.0f,1.0f,0.0f);			// top of triangle (left)
			GL.glColor3f(0.0f,0.0f,1.0f);			// blue
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);		// left of triangle (left)
			GL.glColor3f(0.0f,1.0f,0.0f);			// green
			GL.glVertex3f(-1.0f,-1.0f,1.0f);		// right of triangle (left)
			GL.glEnd();

			GL.glLoadIdentity();					// reset the current modelview matrix
            GL.glTranslatef(1.5f,0.0f,-7.0f);		// move 1.5 Units right and 7 into the screen
			GL.glRotatef(rquad,1.0f,1.0f,1.0f);		// rotate the quad on the X,Y and Z-axis
			rquad-=0.15f;							// rotation angle

			GL.glBegin(GL.GL_QUADS);				// start drawing a quad
			GL.glColor3f(0.0f,1.0f,0.0f);			// green top
			GL.glVertex3f(1.0f,1.0f,-1.0f);			// top right (top)
            GL.glVertex3f(-1.0f,1.0f,-1.0f);		// top left (top)
			GL.glVertex3f(-1.0f,1.0f,1.0f);			// bottom left (top)
			GL.glVertex3f(1.0f,1.0f,1.0f);			// bottom right (top)

			GL.glColor3f(1.0f,0.5f,0.0f);			// orange
			GL.glVertex3f(1.0f,-1.0f,1.0f);			// top right (bottom)
			GL.glVertex3f(-1.0f,-1.0f,1.0f);		// top left (bottom)
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);		// bottom left (bottom)
			GL.glVertex3f(1.0f,-1.0f,-1.0f);		// bottom right (bottom)

			GL.glColor3f(1.0f,0.0f,0.0f);			// red
			GL.glVertex3f(1.0f,1.0f,1.0f);			// top right (front)
			GL.glVertex3f(-1.0f,1.0f,1.0f);			// top left (front)
			GL.glVertex3f(-1.0f,-1.0f,1.0f);		// bottom left (front)
			GL.glVertex3f(1.0f,-1.0f,1.0f);			// bottom right (front)

			GL.glColor3f(1.0f,1.0f,0.0f);				// yellow
			GL.glVertex3f(-1.0f,1.0f,-1.0f);		// top right (back)
			GL.glVertex3f(1.0f,1.0f,-1.0f);			// top left (back)
			GL.glVertex3f(1.0f,-1.0f,-1.0f);		// bottom left (back)
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);		// bottom right (back)
	
			GL.glColor3f(0.0f,0.0f,1.0f);			// blue
			GL.glVertex3f(-1.0f,1.0f,1.0f);			// top right (left)
			GL.glVertex3f(-1.0f,1.0f,-1.0f);		// top left (left)
			GL.glVertex3f(-1.0f,-1.0f,-1.0f);		// bottom left (left)
			GL.glVertex3f(-1.0f,-1.0f,1.0f);		// bottom right (left)

			GL.glColor3f(1.0f,0.0f,1.0f);			// violett
			GL.glVertex3f(1.0f,1.0f,-1.0f);			// top right (right)
			GL.glVertex3f(1.0f,1.0f,1.0f);			// top left (right)
			GL.glVertex3f(1.0f,-1.0f, 1.0f);		// bottom left (right)
			GL.glVertex3f(1.0f,-1.0f,-1.0f);		// bottom right (right)
			GL.glEnd();

		}

		protected override void InitGLContext() 
		{
			GL.glShadeModel(GL.GL_SMOOTH);								// enable smooth shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);					// black background
			GL.glClearDepth(1.0f);										// depth buffer setup
			GL.glEnable(GL.GL_DEPTH_TEST);								// enables depth testing
			GL.glDepthFunc(GL.GL_LEQUAL);								// type of depth test
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// nice perspective calculations
			//rtri = 30.0f;			define the rotation angle in the start position of the triangle
			//rquad = 30.0f;		define the rotation angle in the start position of the quad
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
		private lesson05.OurView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe lesson 05 in C# (by Sabine Felsinger)";
			this.view = new lesson05.OurView();			
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