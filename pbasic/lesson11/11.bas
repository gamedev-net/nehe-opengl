#Compile EXE
#DIM All

#Include "win32api.inc" ' Header File For Windows
#Include "gl/gl.inc"    ' Header File For The OpenGL32 Library
#Include "gl/glu.inc"   ' Header File For The GLu32 Library
#Include "gl/glaux.inc" ' Header File For The GLaux Library
#Include "gl/glwgl.inc" ' More crap
#Include "gl/pbgl.inc"  ' To make life easier

GLOBAL hRC AS LONG   ' Permanent Rendering Context
GLOBAL hDC AS LONG   ' Private GDI Device Context

GLOBAL keys() AS LONG  ' Array Used For The Keyboard Routine

GLOBAL points() AS SINGLE    ' The array for the points on the grid of our "wave"
GLOBAL wiggle_count AS LONG

GLOBAL xrot AS SINGLE      ' X Rotation
GLOBAL yrot AS SINGLE      ' Y Rotation
GLOBAL zrot AS SINGLE      ' Z Rotation

GLOBAL texture() AS DWORD  ' Storage for 1 texture

' Load Bitmaps And Convert To Textures
SUB LoadGLTextures
  ' Load Texture
  DIM texture1 AS AUX_RGBImageRec PTR

  texture1 = auxDIBImageLoad("Data/tim.bmp")
  IF texture1 = 0 THEN ExitProcess 1

  ' Create Texture
  glGenTextures 1, texture(0)
  glBindTexture %GL_TEXTURE_2D, texture(0)
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MAG_FILTER, %GL_LINEAR
  glTexParameteri %GL_TEXTURE_2D, %GL_TEXTURE_MIN_FILTER, %GL_LINEAR
  glTexImage2D %GL_TEXTURE_2D, 0, 3, @texture1.sizeX, @texture1.sizeY, 0, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@ndata
END SUB


' This Will Be Called Right After The GL Window Is Created
SUB InitGL(BYVAL lWidth AS LONG, BYVAL lHeight AS LONG)
  DIM float_x AS SINGLE, float_y AS SINGLE

  LoadGLTextures            ' Load The Texture(s)
  glEnable %GL_TEXTURE_2D   ' Enable Texture Mapping

  glClearColor 0.0, 0.0, 0.0, 0.0  ' This Will Clear The Background Color To Black
  glClearDepth 1.0                 ' Enables Clearing Of The Depth Buffer
  glDepthFunc %GL_LESS             ' The Type Of Depth Test To Do
  glEnable %GL_DEPTH_TEST          ' Enables Depth Testing
  glShadeModel %GL_SMOOTH          ' Enables Smooth Color Shading

  glMatrixMode %GL_PROJECTION
  glLoadIdentity                   ' Reset The Projection Matrix

  gluPerspective 45.0, lWidth/lHeight, 0.1, 100.0  ' Calculate The Aspect Ratio Of The Window

  glMatrixMode %GL_MODELVIEW

  FOR float_x = 0.0 TO 9.0 STEP 0.2
    FOR float_y = 0.0 TO 9-0 STEP 0.2
      points(Int(float_x*5), Int(float_y*5), 0) = float_x - 4.4
      points(Int(float_x*5), Int(float_y*5), 1) = float_y - 4.4
      points(Int(float_x*5), Int(float_y*5), 2) = sin(((float_x*5*8)/360) * 3.14159 * 2)
    NEXT float_y
  NEXT float_x
END SUB


SUB ReSizeGLScene(BYVAL lWidth AS LONG, BYVAL lHeight AS LONG)
  IF lHeight = 0 THEN     ' Prevent A Divide By Zero If The Window Is Too Small
    lHeight = 1
  END IF

  glViewport 0, 0, lWidth, lHeight    ' Reset The Current Viewport And Perspective Transformation

  glMatrixMode %GL_PROJECTION
  glLoadIdentity

  gluPerspective 45.0, lWidth/lHeight, 0.1, 100.0
  glMatrixMode %GL_MODELVIEW
END SUB


SUB DrawGLScene()
  DIM x AS LONG, y AS LONG
  DIM float_x AS SINGLE, float_y AS SINGLE, float_xb AS SINGLE, float_yb AS SINGLE

  glClear %GL_COLOR_BUFFER_BIT OR %GL_DEPTH_BUFFER_BIT
  glLoadIdentity
  glTranslatef 0.0, 0.0, -12.0

  glRotatef xrot, 1.0, 0.0, 0.0
  glRotatef yrot, 0.0, 1.0, 0.0  
  glRotatef zrot, 0.0, 0.0, 1.0

  glBindTexture %GL_TEXTURE_2D, texture(0)

  glPolygonMode %GL_BACK, %GL_FILL
  glPolygonMode %GL_FRONT, %GL_LINE

  glBegin %GL_QUADS

  FOR x = 0 TO 43
    FOR y = 0 TO 43
      float_x = x/44
      float_y = y/44
      float_xb = (x+1)/44
      float_yb = (y+1)/44

      glTexCoord2f float_x, float_y
      glVertex3f points(x,y,0), points(x,y,1), points(x,y,2)

      glTexCoord2f float_x, float_yb
      glVertex3f points(x,y+1,0), points(x,y+1,1), points(x,y+1,2)

      glTexCoord2f float_xb, float_yb
      glVertex3f points(x+1,y+1,0), points(x+1,y+1,1), points(x+1,y+1,2)

      glTexCoord2f float_xb, float_y
      glVertex3f points(x+1,y,0), points(x+1,y,1), points(x+1,y,2)
    NEXT y
  NEXT x

  glEnd

  IF wiggle_count = 2 THEN
    FOR y = 0 TO 44
      points(44,y,2) = points(0,y,2)
    NEXT y

    FOR x = 0 TO 43
      FOR y = 0 TO 44
        points(x,y,2) = points(x+1,y,2)
      NEXT y
    NEXT x

    wiggle_count = 0
  END IF

  INCR wiggle_count

  xrot = xrot + 0.3
  yrot = yrot + 0.2
  zrot = zrot + 0.4
END SUB


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
  Dim dmScreenSettings As DEVMODE

  DIM keys(255)
  DIM texture(0)
  DIM points(44, 44, 2)

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
    SwapBuffers hDC
    If keys(%VK_ESCAPE) Then SendMessage hWnd, %WM_CLOSE, 0, 0
  Loop
End Function


