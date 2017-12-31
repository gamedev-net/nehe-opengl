/*	C# conversion of NeHe's lesson 3 by Joachim Rohde (aka Marilyn)
 *  This file compiles fine using SharpDevelop with CsGL
 *  (see Readme.txt for further informations)
 * */


using System;
using System.Drawing;
using System.Windows.Forms;
using CsGL.OpenGL;

namespace Lesson3
{
	public class OurView : OpenGLControl
	{
		public OurView(): base()
		{
			this.KeyDown += new KeyEventHandler(OurView_OnKeyDown);
		}
		
		protected void OurView_OnKeyDown(object Sender, KeyEventArgs kea)
		{
			//if escape was pressed exit the application
			if (kea.KeyCode == Keys.Escape) 
			{
				Application.Exit();
			}
		}
		

		public override void glDraw()
		{	
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
			GL.glLoadIdentity();							// Reset The Current Modelview Matrix

			GL.glTranslatef(-1.5f,0.0f,-6.0f);				// Left 1.5 Then Into Screen Six Units

			GL.glBegin(GL.GL_TRIANGLES);					// Begin Drawing Triangles
				GL.glColor3f(1.0f,0.0f,0.0f);				// Set The Color To Red
				GL.glVertex3f( 0.0f, 1.0f, 0.0f);			// Move Up One Unit From Center (Top Point)

				GL.glColor3f(0.0f,1.0f,0.0f);				// Set The Color To Green
				GL.glVertex3f(-1.0f,-1.0f, 0.0f);			// Left And Down One Unit (Bottom Left)
			
				GL.glColor3f(0.0f,0.0f,1.0f);				// Set The Color To Blue
				GL.glVertex3f( 1.0f,-1.0f, 0.0f);			// Right And Down One Unit (Bottom Right)
			GL.glEnd();										// Done Drawing A Triangle

			GL.glTranslatef(3.0f,0.0f,0.0f);				// From Right Point Move 3 Units Right
			
			GL.glColor3f(0.5f,0.5f,1.0f);					// Set The Color To Blue One Time Only
			GL.glBegin(GL.GL_QUADS);						// Start Drawing Quads
				GL.glVertex3f(-1.0f, 1.0f, 0.0f);			// Left And Up 1 Unit (Top Left)
				GL.glVertex3f( 1.0f, 1.0f, 0.0f);			// Right And Up 1 Unit (Top Right)
				GL.glVertex3f( 1.0f,-1.0f, 0.0f);			// Right And Down One Unit (Bottom Right)
				GL.glVertex3f(-1.0f,-1.0f, 0.0f);			// Left And Down One Unit (Bottom Left)
			GL.glEnd();										// Done Drawing A Quad
		}

		protected override void InitGLContext() 
		{
			GL.glShadeModel(GL.GL_SMOOTH);							// Enable Smooth Shading
			GL.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
			GL.glClearDepth(1.0f);									// Depth Buffer Setup
			GL.glEnable(GL.GL_DEPTH_TEST);							// Enables Depth Testing
			GL.glDepthFunc(GL.GL_LEQUAL);								// The Type Of Depth Testing To Do
			GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// Really Nice Perspective Calculations
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
	
	public class MainForm : System.Windows.Forms.Form	// Will show us the OpenGL window
	{
		private Lesson3.OurView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe's Lesson 3 in C# (by Joachim Rohde)";
			this.view = new Lesson3.OurView();			// view
			this.view.Parent = this;
			this.view.Dock = DockStyle.Fill; // Will fill whole form
		}

		static void Main() 
		{
			Application.Run(new MainForm());
		}
	}
}
