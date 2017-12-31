'Created by: X
'Copyright: Created by: X
'Original Author: mailto:joachim_rohde@freenet.de
'Converted from: http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=02
'Original C# source code: http://nehe.gamedev.net/data/lessons/c_sharp/lesson02.zip
'Requires CsGL library: http://sourceforge.net/projects/csgl/
'This version uses CsGL library v1.4.1.0
'E-Mail: mailto:createdbyx@yahoo.com
'Web: http://www.createdbyx.com/
'Date: November 17, 2003
'=============================================

Public Class Form1
    Inherits System.Windows.Forms.Form

    Public Class OurView
        Inherits CsGL.OpenGL.OpenGLControl

        Protected Overrides Sub InitGLContext()
            GL.glShadeModel(Convert.ToUInt32(GLFlags.GL_SMOOTH))              '// Enable Smooth Shading
            GL.glClearColor(0.0F, 0.0F, 0.0F, 0.5F)    '// Black Background
            GL.glClearDepth(1.0F)                     '// Depth Buffer Setup
            GL.glEnable(Convert.ToUInt32(GLFlags.GL_DEPTH_TEST))        '// Enables Depth Testing
            GL.glDepthFunc(Convert.ToUInt32(GLFlags.GL_LEQUAL))        '// The Type Of Depth Testing To Do
            GL.glHint(Convert.ToUInt32(GLFlags.GL_PERSPECTIVE_CORRECTION_HINT), Convert.ToUInt32(GLFlags.GL_NICEST))  '// Really Nice Perspective Calculations
        End Sub

        Public Overrides Sub glDraw()
            GL.glClear(Convert.ToUInt32(GLFlags.GL_COLOR_BUFFER_BIT Or GLFlags.GL_DEPTH_BUFFER_BIT))
            GL.glLoadIdentity()
            GL.glTranslatef(-1.5F, 0.0F, -6.0F)   '// Move Left 1.5 Units And Into The Screen 6.0
            GL.glBegin(Convert.ToUInt32(GLFlags.GL_TRIANGLES))      '// Drawing Using Triangles
            GL.glVertex3f(0.0F, 1.0F, 0.0F)     '// Top
            GL.glVertex3f(-1.0F, -1.0F, 0.0F)   '// Bottom Left
            GL.glVertex3f(1.0F, -1.0F, 0.0F)    '// Bottom Right
            GL.glEnd()           '// Finished Drawing The Triangle

            GL.glTranslatef(3.0F, 0.0F, 0.0F)   '// Move Right 3 Units
            GL.glBegin(Convert.ToUInt32(GLFlags.GL_QUADS))       '// Draw A Quad
            GL.glVertex3f(-1.0F, 1.0F, 0.0F)    '// Top Left
            GL.glVertex3f(1.0F, 1.0F, 0.0F)     '// Top Right
            GL.glVertex3f(1.0F, -1.0F, 0.0F)    '// Bottom Right
            GL.glVertex3f(-1.0F, -1.0F, 0.0F)   '// Bottom Left
            GL.glEnd()         '// Done Drawing The Quad
        End Sub

        Protected Overrides Sub OnSizeChanged(ByVal e As System.EventArgs)
            MyBase.OnSizeChanged(e)
            Dim S As Size = Me.Size

            GL.glMatrixMode(Convert.ToUInt32(GLFlags.GL_PROJECTION))
            GL.glLoadIdentity()
            GL.gluPerspective(45.0, S.Width / S.Height, 0.1, 100.0)
            GL.glMatrixMode(Convert.ToUInt32(GLFlags.GL_MODELVIEW))
            GL.glLoadIdentity()
        End Sub
    End Class

#Region " Windows Form Designer generated code "

    Public Sub New()
        MyBase.New()

        'This call is required by the Windows Form Designer.
        InitializeComponent()

        'Add any initialization after the InitializeComponent() call

    End Sub

    'Form overrides dispose to clean up the component list.
    Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
        If disposing Then
            If Not (components Is Nothing) Then
                components.Dispose()
            End If
        End If
        MyBase.Dispose(disposing)
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    Friend WithEvents OpenGLControl1 As OurView
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.OpenGLControl1 = New OurView()
        Me.SuspendLayout()
        '
        'OpenGLControl1
        '
        Me.OpenGLControl1.Dock = System.Windows.Forms.DockStyle.Fill
        Me.OpenGLControl1.Name = "OpenGLControl1"
        Me.OpenGLControl1.Size = New System.Drawing.Size(292, 266)
        Me.OpenGLControl1.TabIndex = 0
        Me.OpenGLControl1.Text = "OpenGLControl1"
        '
        'Form1
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(292, 266)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.OpenGLControl1})
        Me.Name = "Form1"
        Me.Text = "Form1"
        Me.ResumeLayout(False)

    End Sub

#End Region

End Class


