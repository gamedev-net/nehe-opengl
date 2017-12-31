'Created by: X
'Copyright: Created by: X
'Original Author: mailto:joachim_rohde@freenet.de
'Converted from: http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=06
'Original C# source code: http://nehe.gamedev.net/data/lessons/c_sharp/lesson06.zip
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

        Public xrot As Single    '// X-axis rotation
        Public yrot As Single   '// Y-axis rotation
        Public zrot As Single   '// Z-axis rotation
        Public texture(1) As UInt32  '// texture

        Protected Overrides Sub InitGLContext()
            GL.glShadeModel(Convert.ToUInt32(GLFlags.GL_SMOOTH))              '// Enable Smooth Shading
            GL.glClearColor(0.0F, 0.0F, 0.0F, 0.5F)    '// Black Background
            GL.glClearDepth(1.0F)                     '// Depth Buffer Setup
            GL.glEnable(Convert.ToUInt32(GLFlags.GL_DEPTH_TEST))        '// Enables Depth Testing
            GL.glDepthFunc(Convert.ToUInt32(GLFlags.GL_LEQUAL))        '// The Type Of Depth Testing To Do
            GL.glHint(Convert.ToUInt32(GLFlags.GL_PERSPECTIVE_CORRECTION_HINT), Convert.ToUInt32(GLFlags.GL_NICEST))  '// Really Nice Perspective Calculations
            'rtri = 30.0f			'you can define the starting position
            'rquad = 60.0f		'you can define the starting position


            GL.glEnable(Convert.ToUInt32(GLFlags.GL_TEXTURE_2D))

            Dim Image As Bitmap = New Bitmap("..\water.bmp")
            Image.RotateFlip(RotateFlipType.RotateNoneFlipY)

            Dim bitmapdata As System.Drawing.Imaging.BitmapData
            Dim rect As Rectangle = New Rectangle(0, 0, Image.Width, Image.Height)

            bitmapdata = Image.LockBits(rect, System.Drawing.Imaging.ImageLockMode.ReadOnly, Drawing.Imaging.PixelFormat.Format24bppRgb)

            GL.glGenTextures(1, texture)
            GL.glBindTexture(Convert.ToUInt32(GLFlags.GL_TEXTURE_2D), texture(0))
            GL.glTexImage2D(Convert.ToUInt32(GLFlags.GL_TEXTURE_2D), 0, Convert.ToInt32(GLFlags.GL_RGB8), _
                            Image.Width, Image.Height, 0, Convert.ToUInt32(32992), _
                            Convert.ToUInt32(GLFlags.GL_UNSIGNED_BYTE), bitmapdata.Scan0)
            GL.glTexParameteri(Convert.ToUInt32(GLFlags.GL_TEXTURE_2D), Convert.ToUInt32(GLFlags.GL_TEXTURE_MIN_FILTER), Convert.ToUInt32(9729))   '// Linear Filtering
            GL.glTexParameteri(Convert.ToUInt32(GLFlags.GL_TEXTURE_2D), Convert.ToUInt32(GLFlags.GL_TEXTURE_MAG_FILTER), Convert.ToUInt32(9729))     '// Linear Filtering

            'NOTE: I am using CsGL 1.4.1.0
            'NOTE: GLFlags.GL_BGR_EXT is not present in the GlFlags enum. it's value is 32992. You can find this enum under CsGL.OpenGL.OpenGL.GL_GBR_EXT
            'NOTE: GLFlags.GL_LINEAR is not present in the GlFlags enum. it's value is 9729. You can find this enum under CsGL.OpenGL.OpenGL.GL_LINEAR


            Image.UnlockBits(bitmapdata)
            Image.Dispose()
        End Sub

        Public Overrides Sub glDraw()
            GL.glClear(Convert.ToUInt32(GLFlags.GL_COLOR_BUFFER_BIT Or GLFlags.GL_DEPTH_BUFFER_BIT)) '// Clear Screen and Depth Buffer
            GL.glMatrixMode(Convert.ToUInt32(GLFlags.GL_MODELVIEW))
            GL.glBindTexture(Convert.ToUInt32(GLFlags.GL_TEXTURE_2D), texture(0))      '// defines the texture
            GL.glLoadIdentity()           '// reset the current modelview matrix
            GL.glTranslatef(0.0F, 0.0F, -5.0F)      '// move 5 Units into the screen
            '//GL.glRotatef(rquad,1.0f,1.0f,1.0f)		the old possibility
            '//rquad -= -0.2f
            GL.glRotatef(xrot, 1.0F, 0.0F, 0.0F) '// rotate on the X-axis
            xrot += 0.3F       '// X-axis rotation
            GL.glRotatef(yrot, 0.0F, 1.0F, 0.0F) '// rotate on the Y-axis
            yrot += 0.2F       '// Y-axis rotation
            GL.glRotatef(zrot, 0.0F, 0.0F, 1.0F) '// rotate on the Z-axis
            zrot += 0.4F       '// Z-axis rotation

            GL.glBegin(Convert.ToUInt32(GLFlags.GL_QUADS))
            '// Front Face
            GL.glTexCoord2f(1.0F, 1.0F)  '// top right of texture
            GL.glVertex3f(1.0F, 1.0F, 1.0F) '// top right of quad
            GL.glTexCoord2f(0.0F, 1.0F)  '// top left of texture
            GL.glVertex3f(-1.0F, 1.0F, 1.0F) '// top left of quad
            GL.glTexCoord2f(0.0F, 0.0F)  '// bottom left of texture
            GL.glVertex3f(-1.0F, -1.0F, 1.0F) '// bottom left of quad
            GL.glTexCoord2f(1.0F, 0.0F)  '// bottom right of texture
            GL.glVertex3f(1.0F, -1.0F, 1.0F) '// bottom right of quad

            '// Back Face
            GL.glTexCoord2f(1.0F, 1.0F)  '// top right of texture
            GL.glVertex3f(-1.0F, 1.0F, -1.0F) '// top right of quad
            GL.glTexCoord2f(0.0F, 1.0F)  '// top left of texture
            GL.glVertex3f(1.0F, 1.0F, -1.0F) '// top left of quad
            GL.glTexCoord2f(0.0F, 0.0F)  '// bottom left of texture
            GL.glVertex3f(1.0F, -1.0F, -1.0F) '// bottom left of quad
            GL.glTexCoord2f(1.0F, 0.0F)  '// bottom right of texture
            GL.glVertex3f(-1.0F, -1.0F, -1.0F) '// bottom right of quad

            '// Top Face
            GL.glTexCoord2f(1.0F, 1.0F)  '// top right of texture
            GL.glVertex3f(1.0F, 1.0F, -1.0F) '// top right of quad
            GL.glTexCoord2f(0.0F, 1.0F)  '// top left of texture
            GL.glVertex3f(-1.0F, 1.0F, -1.0F) '// top left of quad
            GL.glTexCoord2f(0.0F, 0.0F)  '// bottom left of texture
            GL.glVertex3f(-1.0F, 1.0F, 1.0F) '// bottom left of quad
            GL.glTexCoord2f(1.0F, 0.0F)  '// bottom right of texture
            GL.glVertex3f(1.0F, 1.0F, 1.0F) '// bottom right of quad

            '// Bottom Face
            GL.glTexCoord2f(1.0F, 1.0F)  '// top right of texture
            GL.glVertex3f(1.0F, -1.0F, 1.0F) '// top right of quad
            GL.glTexCoord2f(0.0F, 1.0F)  '// top left of texture
            GL.glVertex3f(-1.0F, -1.0F, 1.0F) '// top left of quad
            GL.glTexCoord2f(0.0F, 0.0F)  '// bottom left of texture
            GL.glVertex3f(-1.0F, -1.0F, -1.0F) '// bottom left of quad
            GL.glTexCoord2f(1.0F, 0.0F)  '// bottom right of texture
            GL.glVertex3f(1.0F, -1.0F, -1.0F) '// bottom right of quad

            '// Right Face
            GL.glTexCoord2f(1.0F, 1.0F)  '// top right of texture
            GL.glVertex3f(1.0F, 1.0F, -1.0F) '// top right of quad
            GL.glTexCoord2f(0.0F, 1.0F)  '// top left of texture
            GL.glVertex3f(1.0F, 1.0F, 1.0F) '// top left of quad
            GL.glTexCoord2f(0.0F, 0.0F)  '// bottom left of texture
            GL.glVertex3f(1.0F, -1.0F, 1.0F) '// bottom left of quad
            GL.glTexCoord2f(1.0F, 0.0F)  '// bottom right of texture
            GL.glVertex3f(1.0F, -1.0F, -1.0F) '// bottom right of quad

            '// Left Face
            GL.glTexCoord2f(1.0F, 1.0F)  '// top right of texture
            GL.glVertex3f(-1.0F, 1.0F, 1.0F) '// top right of quad
            GL.glTexCoord2f(0.0F, 1.0F)  '// top left of texture
            GL.glVertex3f(-1.0F, 1.0F, -1.0F) '// top left of quad
            GL.glTexCoord2f(0.0F, 0.0F)  '// bottom left of texture
            GL.glVertex3f(-1.0F, -1.0F, -1.0F) '// bottom left of quad
            GL.glTexCoord2f(1.0F, 0.0F)  '// bottom right of texture
            GL.glVertex3f(-1.0F, -1.0F, 1.0F) '// bottom right of quad
            GL.glEnd()
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

    Private Sub Form1_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Me.Show()
        While Me.Created

            OpenGLControl1.glDraw()
            Me.Refresh()
            Application.DoEvents()
        End While
    End Sub
End Class

Public Class gg
    Inherits CSGL.OpenGL.OpenGL

End Class