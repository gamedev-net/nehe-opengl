' ===========================================
' OpenGL Example for PB/DLL 6.0
'
' Sublevel6
'
' OpenGL Include Files Needed to Run
' http://ryme.future.easyspace.com/
' http://home.bip.net/dinky
' ===========================================

#Compile Exe
#Dim All

#Include "win32api.inc"  ' Header File For Windows
#Include "gl/gl.inc"     ' Header File For The OpenGL32 Library
#Include "gl/glu.inc"    ' Header File For The GLu32 Library
#Include "gl/glaux.inc"  ' Header File For The GLaux Library
#Include "gl/glwgl.inc"  ' Extra Header File For Windows
#Include "gl/pbgl.inc"

Type VERTEX
  ' 3D Coordinates
  x As Single
  y As Single
  z As Single
  ' Texture Coordinates
  u As Single
  v As Single
End Type

Global numtriangles As Long     ' Number Of Triangles In Sector
Global mytriangles() As VERTEX  ' Array Of Triangles


Global hRC As Long  ' Permanent Rendering Context
Global hDC As Long  ' Private GDI Device Context

$worldfile = "data\world.txt"

Global keys() As Byte
Global light As Long    ' Lighting ON/OFF
Global blend As Long    ' Blending ON/OFF
Global bp As Long       ' B Pressed?
Global lp As Long       ' L Pressed?
Global fp As Long       ' F Pressed?

Global xrot As Single   ' X Rotation
Global yrot As Single   ' Y Rotation
Global xspeed As Single ' X Rotation Speed
Global yspeed As Single ' Y Rotation Speed

Global walkbias As Single
Global walkbiasangle As Single

Global lookupdown As Single
'GLOBAL piover180 AS SINGLE  '= 0.0174532925

Global heading As Single
Global xpos As Single
Global zpos As Single

' Camera Location
Global camx As Single
Global camy As Single
Global camz As Single

Global therotate As Single

Global z As Single  ' Depth Into The Screen

Global LightAmbient() As Single   ' Ambient Light
Global LightDiffuse() As Single   ' Diffuse Light
Global LightPosition() As Single  ' Light Position

Global filter As Dword    ' Which Filter To Use
Global texture() As Dword ' Storage for 3 textures


' Converts Degrees To Radians. There Are 2 PI Radians In 360 Degrees.
Function rad(ByVal angle As Single) As Single
  Function = angle * 0.0174532925
End Function


Sub SetupWorld()
  Dim x As Single, y As Single, z As Single, u As Single, v As Single
  Dim i As Long
  Dim c As Long
  dim boom as long
  Dim vert As Long
  Dim oneline As String

  Open $worldfile For Input As #1

  Do Until Eof(1)
    Line Input #1, oneline
    If Left$(oneline, 11) = "NUMPOLLIES " Then
      numtriangles = Val(Mid$(oneline, 12))
      Exit Do
    End If
  Loop

  Dim mytriangles(numtriangles*3-1)

  For c = 0 To numtriangles - 1
    For vert = 0 To 2
      boom = 0
      Do
        Line Input #1, oneline
        oneline = Trim$(oneline)
        If oneline <> "" Then
          If Left$(oneline, 2) <> "//" Then
            mytriangles(c*3+vert).x = Val(oneline)
            i = Instr(oneline, " ")
            oneline = Trim$(Mid$(oneline, i))
            mytriangles(c*3+vert).y = Val(oneline)
            i = Instr(oneline, " ")
            oneline = Trim$(Mid$(oneline, i))
            mytriangles(c*3+vert).z = Val(oneline)
            i = Instr(oneline, " ")
            oneline = Trim$(Mid$(oneline, i))
            mytriangles(c*3+vert).u = Val(oneline)
            i = Instr(oneline, " ")
            oneline = Trim$(Mid$(oneline, i))
            mytriangles(c*3+vert).v = Val(oneline)
            boom = 1
          End If
        End If
      Loop Until boom = 1
    Next vert
  Next c
  Close #1
End Sub


' Load Bitmaps And Convert To Textures
Sub LoadGLTextures()
  ' Load Texture
  Dim texture1 As AUX_RGBImageRec Ptr
  Dim texture(2)

  texture1 = auxDIBImageLoad("Data/mud.bmp")
  If texture1 = 0 Then
    ExitProcess 1
  End If

  ' Create Nearest Filtered Texture
  glGenTextures 3, texture(0)
  glBindTexture %GL_TEXTURE_2D, texture(0)
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MAG_FILTER, %GL_NEAREST
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MIN_FILTER, %GL_NEAREST
  glTexImage2D %GL_TEXTURE_2D, 0, 3, @texture1.sizeX, @texture1.sizeY, 0, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@ndata

  ' Create Linear Filtered Texture
  glBindTexture %GL_TEXTURE_2D, texture(1)
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MAG_FILTER, %GL_LINEAR
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MIN_FILTER, %GL_LINEAR
  glTexImage2D %GL_TEXTURE_2D, 0, 3, @texture1.sizeX, @texture1.sizeY, 0, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@ndata

  ' Create MipMapped Texture
  glBindTexture %GL_TEXTURE_2D, texture(2)
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MAG_FILTER, %GL_LINEAR
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MIN_FILTER, %GL_LINEAR_MIPMAP_NEAREST
  gluBuild2DMipmaps %GL_TEXTURE_2D, 3, @texture1.sizeX, @texture1.sizeY, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@ndata
End Sub


' This Will Be Called Right After The GL Window Is Created
Sub InitGL(ByVal lWidth As Long, ByVal lHeight As Long)
  LoadGLTextures            ' Load The Texture(s)
  glEnable %GL_TEXTURE_2D   ' Enable Texture Mapping
  Dim LightAmbient(3)
  Dim LightDiffuse(3)
  Dim LightPosition(3)

  LightAmbient(0)  = 0.5 : LightAmbient(1)  = 0.5 : LightAmbient(2)  = 0.5 : LightAmbient(3)  = 1.0 ' Ambient Light
  LightDiffuse(0)  = 1.0 : LightDiffuse(1)  = 1.0 : LightDiffuse(2)  = 1.0 : LightDiffuse(3)  = 1.0 ' Diffuse Light
  LightPosition(0) = 0.0 : LightPosition(1) = 0.0 : LightPosition(2) = 2.0 : LightPosition(3) = 1.0 ' Light Position

  glBlendFunc %GL_SRC_ALPHA, %GL_ONE    ' Set The Blending Function For Translucency
  glClearColor 0.0, 0.0, 0.0, 0.0       ' This Will Clear The Background Color To Black
  glClearDepth 1.0                      ' Enables Clearing Of The Depth Buffer
  glDepthFunc %GL_LESS                  ' The Type Of Depth Test To Do
  glEnable %GL_DEPTH_TEST               ' Enables Depth Testing
  glShadeModel %GL_SMOOTH               ' Enables Smooth Color Shading

  glMatrixMode %GL_PROJECTION
  glLoadIdentity                        ' Reset The Projection Matrix

  gluPerspective 45.0, lWidth / lHeight, 0.1, 100.0  ' Calculate The Aspect Ratio Of The Window

  glMatrixMode %GL_MODELVIEW

  glLightfv %GL_LIGHT0, %GL_AMBIENT, LightAmbient(0)
  glLightfv %GL_LIGHT0, %GL_DIFFUSE, LightDiffuse(0)
  glLightfv %GL_LIGHT0, %GL_POSITION, LightPosition(0)
  glEnable %GL_LIGHT0
End Sub


Sub ReSizeGLScene(ByVal lWidth As Long, ByVal lHeight As Long)
  If lHeight = 0 Then ' Prevent A Divide By Zero If The Window Is Too Small
    lHeight = 1
  End If

  glViewport 0, 0, lWidth, lHeight  ' Reset The Current Viewport And Perspective Transformation

  glMatrixMode %GL_PROJECTION
  glLoadIdentity

  gluPerspective 45.0, lWidth / lHeight, 0.1, 100.0
  glMatrixMode %GL_MODELVIEW
End Sub


Sub DrawGLScene()
  Dim x_m As Single, y_m As Single, z_m As Single, u_m As Single, v_m As Single
  Dim xtrans As Single, ztrans As Single, ytrans As Single
  Dim sceneroty As Single
  Dim loop_m As Long

  xtrans = -xpos
  ztrans = -zpos
  ytrans = -walkbias - 0.25

  sceneroty = 360.0 - yrot

  glClear %GL_COLOR_BUFFER_BIT Or %GL_DEPTH_BUFFER_BIT  ' Clear The Screen And The Depth Buffer
  glLoadIdentity   ' Reset The View

  glRotatef lookupdown, 1.0, 0,0
  glRotatef sceneroty, 0, 1.0, 0

  glTranslatef xtrans, ytrans, ztrans
  glBindTexture %GL_TEXTURE_2D, texture(filter)

  ' Process Each Triangle
  For loop_m = 0 To numtriangles - 1 STEP 3
    glBegin %GL_TRIANGLES
      glNormal3f 0.0, 0.0, 1.0
      x_m = mytriangles(loop_m+0).x
      y_m = mytriangles(loop_m+0).y
      z_m = mytriangles(loop_m+0).z
      u_m = mytriangles(loop_m+0).u
      v_m = mytriangles(loop_m+0).v
      glTexCoord2f u_m,v_m : glVertex3f x_m,y_m,z_m

      x_m = mytriangles(loop_m+1).x
      y_m = mytriangles(loop_m+1).y
      z_m = mytriangles(loop_m+1).z
      u_m = mytriangles(loop_m+1).u
      v_m = mytriangles(loop_m+1).v
      glTexCoord2f u_m,v_m : glVertex3f x_m,y_m,z_m

      x_m = mytriangles(loop_m+2).x
      y_m = mytriangles(loop_m+2).y
      z_m = mytriangles(loop_m+2).z
      u_m = mytriangles(loop_m+2).u
      v_m = mytriangles(loop_m+2).v
      glTexCoord2f u_m,v_m : glVertex3f x_m,y_m,z_m
    glEnd
  Next loop_m
End Sub


Function WndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
  Dim Screen As RECT    ' Used Later On To Get The Size Of The Window
  Dim PixelFormat As Long
  Dim pfd As Static PIXELFORMATDESCRIPTOR

  Select Case uMsg    ' Tells Windows We Want To Check The Message
    Case %WM_CREATE
      pfd.nSize = Len(pfd)     ' Size Of This Pixel Format Descriptor
      pfd.nVersion = 1         ' Version Number (?)
      pfd.dwFlags = %PFD_DRAW_TO_WINDOW Or %PFD_SUPPORT_OPENGL Or %PFD_DOUBLEBUFFER Or %PFD_TYPE_RGBA
      pfd.iPixelType = %PFD_TYPE_RGBA
      pfd.cAlphaBits = 16      ' Select A 16Bit Color Depth
      pfd.cDepthBits = 16      ' 16Bit Z-Buffer (Depth Buffer)
      pfd.iLayerType = %PFD_MAIN_PLANE

      hDC = GetDC(hWnd)        ' Gets A Device Context For The Window
      PixelFormat = ChoosePixelFormat(hDC, pfd)   ' Finds The Closest Match To The Pixel Format We Set Above

      If PixelFormat = 0 Then
        MsgBox "Can't Find A Suitable PixelFormat.",,"Error"
        PostQuitMessage 0   ' This Sends A 'Message' Telling The Program To Quit
        Exit Function
      End If

      If SetPixelFormat(hDC, PixelFormat, pfd) = 0 Then
        MsgBox "Can't Set The PixelFormat.",,"Error"
        PostQuitMessage 0
        Exit Function
      End If

      hRC = wglCreateContext(hDC)
      If hRC = 0 Then
        MsgBox "Can't Create A GL Rendering Context.",,"Error"
        PostQuitMessage 0
        Exit Function
      End If

      If wglMakeCurrent(hDC, hRC) = 0 Then
        MsgBox "Can't activate GLRC.",,"Error"
        PostQuitMessage 0
        Exit Function
      End If

      GetClientRect hWnd, Screen
      InitGL Screen.nright, Screen.nbottom

    Case %WM_CLOSE, %WM_DESTROY
      pbglRestoreVideoMode

      wglMakeCurrent hDC, 0
      wglDeleteContext hRC
      ReleaseDC hWnd, hDC

      PostQuitMessage 0

    Case %WM_KEYDOWN
      keys(wParam) = 1

    Case %WM_KEYUP
      keys(wParam) = 0

    Case %WM_SIZE
      ReSizeGLScene LoWrd(lParam), HiWrd(lParam)

    Case Else
      Function = DefWindowProc(hWnd, uMsg, wParam, lParam)
      Exit Function

    End Select
    Function = 0
End Function


Function WinMain(ByVal hInstance As Long, ByVal hPrevInstance As Long, lpCmdLine As Asciiz Ptr, ByVal nCmdShow As Long) As Long
  Dim msg As tagMSG   ' Windows Message Structure
  Dim wc As WNDCLASS  ' Windows Class Structure Used To Set Up The Type Of Window
  Dim hWnd As Long    ' Storage For Window Handle
  Dim cname As Asciiz *20 ' Class name
  Dim keys(255)

  cname = "OpenGL WinClass"
  wc.style         = %CS_HREDRAW Or %CS_VREDRAW Or %CS_OWNDC
  wc.lpfnWndProc   = CodePtr(WndProc)
  wc.cbClsExtra    = 0
  wc.cbWndExtra    = 0
  wc.hInstance     = hInstance
  wc.hIcon         = 0
  wc.hCursor       = LoadCursor(0, ByVal %IDC_ARROW)
  wc.hbrBackground = 0
  wc.lpszMenuName  = 0
  wc.lpszClassName = VarPtr(cname)

  If RegisterClass(wc) = 0 Then
    MsgBox "Failed To Register The Window Class.",,"Error"
    Exit Function
  End If

  hWnd = CreateWindow(cname, "Jeff Molofee's GL Code Tutorial ... NeHe '99... ported by sublevel6 :P", _
                      %WS_POPUP Or %WS_CLIPCHILDREN Or %WS_CLIPSIBLINGS, 0, 0, 640, 480, 0, 0, hInstance, ByVal 0)

  If hWnd = 0 Then
    MsgBox "Window Creation Error.",,"Error"
    Exit Function
  End If

  pbglSetVideoMode 640, 480, 0  ' Switch To Fullscreen Mode

  ShowWindow hWnd, %SW_SHOW
  UpdateWindow hWnd
  SetFocus hWnd
  wglMakeCurrent hDC, hRC

  SetupWorld

  Do
    ' Process All Messages
    While PeekMessage(msg, 0, 0, 0, %PM_NOREMOVE) <> 0
      If GetMessage(msg, 0, 0, 0) Then
        TranslateMessage msg
        DispatchMessage msg
      Else
        Function = 1
        Exit Function
      End If
    WEND

    DrawGLScene
    ' Dinky's light fix ;)
    glLightfv %GL_LIGHT0, %GL_POSITION, LightPosition(0)

    SwapBuffers hDC
    If keys(%VK_ESCAPE) Then SendMessage hWnd, %WM_CLOSE, 0, 0

    If keys(Asc("B")) And (bp = 0) Then
      bp = 1
      blend = blend Xor 1
      If blend = 0 Then
        glDisable %GL_BLEND
        glEnable %GL_DEPTH_TEST
      Else
        glEnable %GL_BLEND
        glDisable %GL_DEPTH_TEST
      End If
    ElseIf keys(Asc("B")) = 0 THEN
      bp = 0
    End If

    If keys(Asc("F")) And (fp = 0) Then
      fp = 1
      Incr filter
      If filter > 2 Then filter = 0
    ElseIf keys(Asc("F")) = 0 THEN
      fp = 0
    End If

    If keys(Asc("L") And (lp=0)) Then
      lp = 1
      light = light Xor 1
      If light = 0 Then
        glDisable %GL_LIGHTING
      Else
        glEnable %GL_LIGHTING
      End If
    ElseIf keys(Asc("L")) = 0 THEN
      lp = 0
    End If

    If keys(%VK_PRIOR) Then
      z = z - 0.02
    End If

    If keys(%VK_NEXT) Then
      z = z + 0.02
    End If

    If keys(%VK_UP) Then
      xpos = xpos - Sin(heading*0.0174532925) * 0.05
      zpos = zpos - Cos(heading*0.0174532925) * 0.05
      If walkbiasangle >= 359.0 Then
        walkbiasangle = 0.0
      Else
       walkbiasangle = walkbiasangle + 10
      End If
      walkbias = Sin(walkbiasangle * 0.0174532925) / 20.0
    End If

    If keys(%VK_DOWN) Then
      xpos = xpos + Sin(heading*0.0174532925) * 0.05
      zpos = zpos + Cos(heading*0.0174532925) * 0.05
      If walkbiasangle <= 1.0 Then
        walkbiasangle = 359.0
      Else
       walkbiasangle = walkbiasangle - 10
      End If
      walkbias = Sin(walkbiasangle * 0.0174532925) / 20.0
    End If

    If keys(%VK_RIGHT) Then
      heading = heading - 1.0
      yrot = heading
    End If

    If keys(%VK_LEFT) Then
      heading = heading + 1.0
      yrot = heading
    End If

    If keys(%VK_PRIOR) Then
      lookupdown = lookupdown - 1.0
    End If

    If keys(%VK_NEXT) Then
      lookupdown = lookupdown + 1.0
    End If
  Loop
End Function

