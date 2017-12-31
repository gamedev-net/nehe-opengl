Attribute VB_Name = "GLDraw"
Option Explicit

Public vertexes(0 To 3, 0 To 2) As GLfloat
Public Blurtexture As GLint
Public angle As Double
Public Normal(0 To 2) As GLfloat
Public SceneWidth As GLint
Public SceneHeight As GLint

Public Sub CalcNormal(ByRef v() As GLfloat, ByRef out() As GLfloat)
    Dim v1(0 To 2) As Double
    Dim v2(0 To 2) As Double                                    ' Vector 1 (x,y,z) & Vector 2 (x,y,z)
    
    Dim x As Integer                                    ' Define X Coord
    x = 0
    Dim y As Integer                                    ' Define Y Coord
    y = 1
    Dim z As Integer                                    ' Define Z Coord
    z = 2

    ' Finds The Vector Between 2 Points By Subtracting
    ' The x,y,z Coordinates From One Point To Another.

    ' Calculate The Vector From Point 1 To Point 0
    v1(x) = v(0, x) - v(1, x)                                ' Vector 1.x=Vertex[0].x-Vertex[1].x
    v1(y) = v(0, y) - v(1, y)                                ' Vector 1.y=Vertex[0].y-Vertex[1].y
    v1(z) = v(0, z) - v(1, z)                                ' Vector 1.z=Vertex[0].y-Vertex[1].z
    ' Calculate The Vector From Point 2 To Point 1
    v2(x) = v(1, x) - v(2, x)                                ' Vector 2.x=Vertex[0].x-Vertex[1].x
    v2(y) = v(1, y) - v(2, y)                                ' Vector 2.y=Vertex[0].y-Vertex[1].y
    v2(z) = v(1, z) - v(2, z)                                ' Vector 2.z=Vertex[0].z-Vertex[1].z
    ' Compute The Cross Product To Give Us A Surface Normal
    out(x) = v1(y) * v2(z) - v1(z) * v2(y)                     ' Cross Product For Y - Z
    out(y) = v1(z) * v2(x) - v1(x) * v2(z)                     ' Cross Product For X - Z
    out(z) = v1(x) * v2(y) - v1(y) * v2(x)                     ' Cross Product For X - Y

    ReduceToUnit out                                          ' Normalize The Vectors
End Sub


Public Sub DrawBlur(times As Integer, inc As Double)
    Dim spost As Double
    spost = 0#                                          ' Starting Texture Coordinate Offset
    Dim alphainc As Double
    alphainc = 0.9 / times                              ' Fade Speed For Alpha Blending
    Dim alpha As Double
    alpha = 0.2                                         ' Starting Alpha Value
    Dim num As Integer
    
    ' Disable AutoTexture Coordinates
    glDisable GL_TEXTURE_GEN_S
    glDisable GL_TEXTURE_GEN_T

    glEnable GL_TEXTURE_2D                                    ' Enable 2D Texture Mapping
    glDisable GL_DEPTH_TEST                                   ' Disable Depth Testing
    glBlendFunc GL_SRC_ALPHA, GL_ONE                          ' Set Blending Mode
    glEnable GL_BLEND                                         ' Enable Blending
    glBindTexture GL_TEXTURE_2D, Blurtexture                  ' Bind To The Blur Texture
    ViewOrtho                                                 ' Switch To An Ortho View

    alphainc = alpha / times                                  ' alphainc=0.2f / Times To Render Blur

    glBegin GL_QUADS                                          ' Begin Drawing Quads
        For num = 0 To times - 1                              ' Number Of Times To Render Blur
        
            glColor4f 1#, 1#, 1#, alpha                       ' Set The Alpha Value (Starts At 0.2)
            glTexCoord2f 0 + spost, 1 - spost                 ' Texture Coordinate   ( 0, 1 )
            glVertex2f 0, 0                                   ' First Vertex     (   0,   0 )

            glTexCoord2f 0 + spost, 0 + spost                 ' Texture Coordinate   ( 0, 0 )
            glVertex2f 0, SceneHeight                         ' Second Vertex    (   0, 480 )

            glTexCoord2f 1 - spost, 0 + spost                 ' Texture Coordinate   ( 1, 0 )
            glVertex2f SceneWidth, SceneHeight                ' Third Vertex     ( 640, 480 )

            glTexCoord2f 1 - spost, 1 - spost                 ' Texture Coordinate   ( 1, 1 )
            glVertex2f SceneWidth, 0                          ' Fourth Vertex    ( 640,   0 )

            spost = spost + inc                               ' Gradually Increase spost (Zooming Closer To Texture Center)
            alpha = alpha - alphainc                          ' Gradually Decrease alpha (Gradually Fading Image Out)
        
        Next num
    glEnd                                                     ' Done Drawing Quads

    ViewPerspective                                           ' Switch To A Perspective View

    glEnable GL_DEPTH_TEST                                    ' Enable Depth Testing
    glDisable GL_TEXTURE_2D                                   ' Disable 2D Texture Mapping
    glDisable GL_BLEND                                        ' Disable Blending
    glBindTexture GL_TEXTURE_2D, 0                            ' Unbind The Blur Texture
End Sub

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    
    'Increase the rotation angle (sorry for this crappy solution)
    angle = angle + 2#
  
    glClearColor 0#, 0#, 0, 0.5                           ' Set The Clear Color To Black
    glClear GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT    ' Clear Screen And Depth Buffer
    
    glEnable GL_LIGHTING
    glEnable GL_LIGHT0
    glDisable GL_CULL_FACE
    glDisable GL_TEXTURE_2D
    glDisable GL_COLOR_MATERIAL
    glLoadIdentity                                         ' Reset The View
    
    RenderToTexture                                        ' Render To A Texture
    ProcessHelix                                           ' Draw Our Helix
    DrawBlur 20, 0.02                                      ' Draw The Blur Effect
    glFlush                                                ' Flush The GL Rendering Pipeline

    DrawGLScene = True
End Function

Public Function EmptyTexture() As GLint
    Dim txtnumber As GLint                                    ' Texture ID
    Dim data(0 To 127, 0 To 127) As GLuint                                          ' Stored Data

    glGenTextures 1, txtnumber                                ' Create 1 Texture
    glBindTexture GL_TEXTURE_2D, txtnumber                    ' Bind The Texture
    glTexImage2D GL_TEXTURE_2D, 0, 4, 128, 128, 0, _
        GL_RGBA, GL_UNSIGNED_BYTE, data(0, 0)                      ' Build Texture Using Information In data
    glTexParameteri GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    glTexParameteri GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR

    EmptyTexture = txtnumber                                  ' Return The Texture ID
End Function

Public Sub ProcessHelix()
    Dim x As Double                                  ' Helix x Coordinate
    Dim y As Double                                  ' Helix y Coordinate
    Dim z As Double                                  ' Helix z Coordinate
    Dim phi As Double                                ' Angle
    Dim theta As Double                              ' Angle
    Dim v As Double                                  ' Angles
    Dim u As Double
    Dim r As Double                                  ' Radius Of Twist
    Dim twists As Integer                            ' 5 Twists
    twists = 5

    Dim glfMaterialColor(0 To 3) As GLfloat           ' Set The Material Color
    glfMaterialColor(0) = 0.4
    glfMaterialColor(1) = 0.2
    glfMaterialColor(2) = 0.8
    glfMaterialColor(3) = 1#
    
    Dim specular(0 To 3) As GLfloat                   ' Sets Up Specular Lighting
    specular(0) = 1#
    specular(1) = 1#
    specular(2) = 1#
    specular(3) = 1#
    
    glLoadIdentity                                           ' Reset The Modelview Matrix
    gluLookAt 0, 5, 50, 0, 0, 0, 0, 1, 0                     ' Eye Position (0,5,50) Center Of Scene (0,0,0), Up On Y Axis

    glPushMatrix                                             ' Push The Modelview Matrix

    glTranslatef 0, 0, -50                                   ' Translate 50 Units Into The Screen
    glRotatef angle / 2#, 1, 0, 0                            ' Rotate By angle/2 On The X-Axis
    glRotatef angle / 3#, 0, 1, 0                            ' Rotate By angle/3 On The Y-Axis

    glMaterialfv GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, glfMaterialColor(0)
    glMaterialfv GL_FRONT_AND_BACK, GL_SPECULAR, specular(0)
    
    r = 1.5                                                  ' Radius

    glBegin GL_QUADS                                          ' Begin Drawing Quads
    
    phi = 0
    Do While (phi <= 360)
        theta = 0
        Do While (theta <= 360 * twists)
            v = phi / 180# * 3.142                         ' Calculate Angle Of First Point   (  0 )
            u = theta / 180# * 3.142                       ' Calculate Angle Of First Point   (  0 )

            x = Cos(u) * (2# + Cos(v)) * r              ' Calculate x Position (1st Point)
            y = Sin(u) * (2# + Cos(v)) * r              ' Calculate y Position (1st Point)
            z = ((u - (2# * 3.142)) + Sin(v)) * r       ' Calculate z Position (1st Point)

            vertexes(0, 0) = x                                ' Set x Value Of First Vertex
            vertexes(0, 1) = y                                ' Set y Value Of First Vertex
            vertexes(0, 2) = z                                ' Set z Value Of First Vertex

            v = (phi / 180# * 3.142)                         ' Calculate Angle Of Second Point  (  0 )
            u = ((theta + 20) / 180# * 3.142)                ' Calculate Angle Of Second Point  ( 20 )

            x = Cos(u) * (2# + Cos(v)) * r             ' Calculate x Position (2nd Point)
            y = Sin(u) * (2# + Cos(v)) * r             ' Calculate y Position (2nd Point)
            z = ((u - (2# * 3.142)) + Sin(v)) * r      ' Calculate z Position (2nd Point)

            vertexes(1, 0) = x                                ' Set x Value Of Second Vertex
            vertexes(1, 1) = y                                ' Set y Value Of Second Vertex
            vertexes(1, 2) = z                                ' Set z Value Of Second Vertex

            v = ((phi + 20) / 180# * 3.142)                  ' Calculate Angle Of Third Point   ( 20 )
            u = ((theta + 20) / 180# * 3.142)                ' Calculate Angle Of Third Point   ( 20 )

            x = Cos(u) * (2# + Cos(v)) * r             ' Calculate x Position (3rd Point)
            y = Sin(u) * (2# + Cos(v)) * r             ' Calculate y Position (3rd Point)
            z = ((u - (2# * 3.142)) + Sin(v)) * r      ' Calculate z Position (3rd Point)

            vertexes(2, 0) = x                                ' Set x Value Of Third Vertex
            vertexes(2, 1) = y                                ' Set y Value Of Third Vertex
            vertexes(2, 2) = z                                ' Set z Value Of Third Vertex

            v = ((phi + 20) / 180# * 3.142)                  ' Calculate Angle Of Fourth Point  ( 20 )
            u = ((theta) / 180# * 3.142)                     ' Calculate Angle Of Fourth Point  (  0 )

            x = Cos(u) * (2# + Cos(v)) * r             ' Calculate x Position (4th Point)
            y = Sin(u) * (2# + Cos(v)) * r             ' Calculate y Position (4th Point)
            z = ((u - (2# * 3.142)) + Sin(v)) * r      ' Calculate z Position (4th Point)

            vertexes(3, 0) = x                                ' Set x Value Of Fourth Vertex
            vertexes(3, 1) = y                                ' Set y Value Of Fourth Vertex
            vertexes(3, 2) = z                                ' Set z Value Of Fourth Vertex

            Call CalcNormal(vertexes(), Normal())                       ' Calculate The Quad Normal

            glNormal3f Normal(0), Normal(1), Normal(2)        ' Set The Normal

            ' Render The Quad
            glVertex3f vertexes(0, 0), vertexes(0, 1), vertexes(0, 2)
            glVertex3f vertexes(1, 0), vertexes(1, 1), vertexes(1, 2)
            glVertex3f vertexes(2, 0), vertexes(2, 1), vertexes(2, 2)
            glVertex3f vertexes(3, 0), vertexes(3, 1), vertexes(3, 2)
            theta = theta + 20
        Loop
        phi = phi + 20
    Loop    'Phi cycle
    glEnd                                                    ' Done Rendering Quads
    
    glPopMatrix                                              ' Pop The Matrix
End Sub

Public Sub ReduceToUnit(ByRef vector() As GLfloat)
    Dim length As Double                                               ' Holds Unit Length
    ' Calculates The Length Of The Vector
    length = Sqr((vector(0) * vector(0)) + (vector(1) * vector(1)) + (vector(2) * vector(2)))

    If (length = 0#) Then                                           ' Prevents Divide By 0 Error By Providing
        length = 1#                                           ' An Acceptable Value For Vectors To Close To 0.
    End If

    vector(0) = vector(0) / length                                      ' Dividing Each Element By
    vector(1) = vector(1) / length                                      ' Dividing Each Element By
    vector(2) = vector(2) / length                                      ' Dividing Each Element By
End Sub

Public Function RenderToTexture() As Boolean
    glViewport 0, 0, 128, 128                      'Set Our Viewport (Match Texture Size)

    ProcessHelix                                   'Render The Helix

    glBindTexture GL_TEXTURE_2D, Blurtexture       'Bind To The Blur Texture

    'Copy Our ViewPort To The Blur Texture (From 0,0 To 128,128... No Border)
    glCopyTexImage2D GL_TEXTURE_2D, 0, GL_LUMINANCE, 0, 0, 128, 128, 0

    glClearColor 0#, 0#, 0.5, 0.5                  'Set The Clear Color To Medium Blue
    glClear GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT       'Clear The Screen And Depth Buffer

    glViewport 0, 0, SceneWidth, SceneHeight                      'Set Viewport (0,0 to 640x480)
End Function


Public Sub ViewOrtho()
    glMatrixMode GL_PROJECTION                                ' Select Projection
    glPushMatrix                                              ' Push The Matrix
    glLoadIdentity                                            ' Reset The Matrix
    glOrtho 0, SceneWidth, SceneHeight, 0, -1, 1                             ' Select Ortho Mode (640x480)
    glMatrixMode GL_MODELVIEW                                 ' Select Modelview Matrix
    glPushMatrix                                              ' Push The Matrix
    glLoadIdentity                                            ' Reset The Matrix
End Sub


Public Sub ViewPerspective()
    glMatrixMode GL_PROJECTION                               ' Select Projection
    glPopMatrix                                              ' Pop The Matrix
    glMatrixMode GL_MODELVIEW                                ' Select Modelview
    glPopMatrix                                              ' Pop The Matrix
End Sub


