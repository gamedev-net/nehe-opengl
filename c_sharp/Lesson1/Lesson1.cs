/*	C# conversion of NeHe's lesson 1 by Joachim Rohde (aka Marilyn)
 *  This file compiles fine using SharpDevelop with CsGL
 *  (see Readme.txt for further informations)
 * */


using System;
using System.Drawing;
using System.Windows.Forms;
using CsGL.OpenGL;

namespace Lesson1
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
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);	
			GL.glLoadIdentity();					
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
		private Lesson1.OurView view;

		public MainForm()
		{
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(640, 480);
			this.Name = "MainForm";
			this.Text = "NeHe's Lesson 1 in C# (by Joachim Rohde)";
			this.view = new Lesson1.OurView();			// view
			this.view.Parent = this;
			this.view.Dock = DockStyle.Fill; // Will fill whole form
		}

		static void Main() 
		{
			Application.Run(new MainForm());
		}
	}
}
