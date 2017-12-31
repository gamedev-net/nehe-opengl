' ===========================================
' OpenGL Example for PB/DLL 6.0
'
' Sublevel6
'
' OpenGL Include Files Needed to Run
' http://ryme.future.easyspace.com/
' http://home.bip.net/dinky
' ===========================================



$Compile Exe
$Dim All

$Include "win32api.inc"
$Include "gl/gl.inc"
$Include "gl/glu.inc"
$Include "gl/glaux.inc"
$Include "gl/glwgl.inc"

Global hRC As Long
Global hDC As Long

Global keys() As Long
Global light As Long
Global lp As Long
Global fp As Long
Global blend As Long
Global bp As Long

Global xrot As Single
Global yrot As Single
Global xspeed As Single
Global yspeed As Single

Global z As Single

Global LightAmbient() As Single

Global LightDiffuse() As Single

Global LightPosition() As Single

Global filter As Long
Global texture() As Long

Sub LoadGLTextures()
   Dim texture(2) As Long
   Dim texture1 As AUX_RGBImageRec Ptr

   texture1 = auxDIBImageLoad("glass.bmp")
   If texture1 = %NULL Then ExitProcess 1

   ' Create Nearest Filtered Texture
   glGenTextures 3, texture(0)
   glBindTexture %GL_TEXTURE_2D,texture(0)
   glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MAG_FILTER,%GL_NEAREST
   glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MIN_FILTER,%GL_NEAREST
   glTexImage2D %GL_TEXTURE_2D, 0, 3, @texture1.sizeX, @texture1.sizeY, 0, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@nData

   ' Create Linear Filtered Texture
   glBindTexture %GL_TEXTURE_2D, texture(1)
   glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MAG_FILTER,%GL_LINEAR
   glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MIN_FILTER,%GL_LINEAR
   glTexImage2D %GL_TEXTURE_2D, 0, 3, @texture1.sizeX, @texture1.sizeY, 0, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@nData

   ' Create MipMapped Texture
   glBindTexture %GL_TEXTURE_2D, texture(2)
   glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MAG_FILTER,%GL_LINEAR
   glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MIN_FILTER,%GL_LINEAR_MIPMAP_NEAREST

   gluBuild2DMipmaps %GL_TEXTURE_2D, 3, @texture1.sizeX, @texture1.sizeY, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@nData

End Sub

Sub InitGL(ByVal nWidth As Long, ByVal nHeight As Long)
   Dim LightAmbient(3) As Single
   Dim LightDiffuse(3) As Single
   Dim LightPosition(3) As Single

  LightAmbient(0) = 0.5 : LightAmbient(1) = 0.5 : LightAmbient(2) = 0.5 : LightAmbient(3) = 1.0
  LightDiffuse(0) = 1.0 : LightDiffuse(1) = 1.0 : LightDiffuse(2) = 1.0 : LightDiffuse(3) = 1.0
  LightPosition(0) = 0.0 : LightPosition(1) = 0.0 : LightPosition(2) = 2.0 : LightPosition(3) = 1.0

   LoadGLTextures
   glEnable %GL_TEXTURE_2D

   glClearColor 0.0,0.0,0.0,0.0
   glClearDepth 1.0
   glDepthFunc %GL_LESS
   glEnable %GL_DEPTH_TEST
   glShadeModel %GL_SMOOTH

   glMatrixMode %GL_PROJECTION
   glLoadIdentity

   gluPerspective 45.0,nWidth/nHeight,0.1,100.0

   glMatrixMode %GL_MODELVIEW

   glLightfv %GL_LIGHT1, %GL_AMBIENT, LightAmbient(0)
   glLightfv %GL_LIGHT1, %GL_DIFFUSE, LightDiffuse(0)
   glLightfv %GL_LIGHT1, %GL_POSITION, LightPosition(0)

   glEnable %GL_LIGHT1

   glColor4f 1.0,1.0,1.0,0.5
   glBlendFunc %GL_SRC_ALPHA,%GL_ONE
End Sub

Sub ReSizeGLScene(ByVal nWidth As Long, ByVal nHeight As Long)
   If nHeight = 0 Then nHeight = 1

   glViewport 0,0,nWidth,nHeight

   glMatrixMode %GL_PROJECTION
   glLoadIdentity

   gluPerspective 45.0,nWidth/nHeight,1.0,100.0
   glMatrixMode %GL_MODELVIEW
End Sub

Sub DrawGLScene()
   glClear %GL_COLOR_BUFFER_BIT Or %GL_DEPTH_BUFFER_BIT
   glLoadIdentity

   glTranslatef 0.0,0.0,z

   glRotatef xrot,1.0,0.0,0.0
   glRotatef yrot,0.0,1.0,0.0

   glBindTexture %GL_TEXTURE_2D, texture(filter)

   glBegin %GL_QUADS
        ' Front Face
        glNormal3f  0.0, 0.0, 1.0
        glTexCoord2f 0.0, 0.0: glVertex3f -1.0, -1.0,  1.0
        glTexCoord2f 1.0, 0.0: glVertex3f  1.0, -1.0,  1.0
        glTexCoord2f 1.0, 1.0: glVertex3f  1.0,  1.0,  1.0
        glTexCoord2f 0.0, 1.0: glVertex3f -1.0,  1.0,  1.0
        ' Back Face
        glNormal3f  0.0, 0.0,-1.0
        glTexCoord2f 1.0, 0.0: glVertex3f -1.0, -1.0, -1.0
        glTexCoord2f 1.0, 1.0: glVertex3f -1.0,  1.0, -1.0
        glTexCoord2f 0.0, 1.0: glVertex3f  1.0,  1.0, -1.0
        glTexCoord2f 0.0, 0.0: glVertex3f  1.0, -1.0, -1.0
        ' Top Face
        glNormal3f  0.0, 1.0, 0.0
        glTexCoord2f 0.0, 1.0: glVertex3f -1.0,  1.0, -1.0
        glTexCoord2f 0.0, 0.0: glVertex3f -1.0,  1.0,  1.0
        glTexCoord2f 1.0, 0.0: glVertex3f  1.0,  1.0,  1.0
        glTexCoord2f 1.0, 1.0: glVertex3f  1.0,  1.0, -1.0
        ' Bottom Face
        glNormal3f  0.0,-1.0, 0.0
        glTexCoord2f 1.0, 1.0: glVertex3f -1.0, -1.0, -1.0
        glTexCoord2f 0.0, 1.0: glVertex3f  1.0, -1.0, -1.0
        glTexCoord2f 0.0, 0.0: glVertex3f  1.0, -1.0,  1.0
        glTexCoord2f 1.0, 0.0: glVertex3f -1.0, -1.0,  1.0
        ' Right face
        glNormal3f  1.0, 0.0, 0.0
        glTexCoord2f 1.0, 0.0: glVertex3f  1.0, -1.0, -1.0
        glTexCoord2f 1.0, 1.0: glVertex3f  1.0,  1.0, -1.0
        glTexCoord2f 0.0, 1.0: glVertex3f  1.0,  1.0,  1.0
        glTexCoord2f 0.0, 0.0: glVertex3f  1.0, -1.0,  1.0
        ' Left Face
        glNormal3f -1.0, 0.0, 0.0
        glTexCoord2f 0.0, 0.0: glVertex3f -1.0, -1.0, -1.0
        glTexCoord2f 1.0, 0.0: glVertex3f -1.0, -1.0,  1.0
        glTexCoord2f 1.0, 1.0: glVertex3f -1.0,  1.0,  1.0
        glTexCoord2f 0.0, 1.0: glVertex3f -1.0,  1.0, -1.0
   glEnd

   xrot = xrot + xspeed
   yrot = yrot + yspeed
End Sub

Function WndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
   Local nScreen As RECT
   Local PixelFormat As Long
   Local pfd As PIXELFORMATDESCRIPTOR
   Dim keys(255) As Long

    pfd.nSize = Len(PIXELFORMATDESCRIPTOR)
    pfd.nVersion = 1
    pfd.dwFlags = %PFD_DRAW_TO_WINDOW Or %PFD_SUPPORT_OPENGL Or %PFD_DOUBLEBUFFER
    pfd.iPixelType = %PFD_TYPE_RGBA
    pfd.cColorBits = 16
    pfd.cRedBits = 0
    pfd.cRedShift = 0
    pfd.cGreenBits = 0
    pfd.cGreenShift = 0
    pfd.cBlueBits = 0
    pfd.cBlueShift = 0
    pfd.cAlphaBits = 0
    pfd.cAlphaShift = 0
    pfd.cAccumBits = 0
    pfd.cAccumRedBits = 0
    pfd.cAccumGreenBits = 0
    pfd.cAccumBlueBits = 0
    pfd.cAccumAlphaBits = 0
    pfd.cDepthBits = 16
    pfd.cStencilBits = 0
    pfd.cAuxBuffers = 0
    pfd.iLayerType = %PFD_MAIN_PLANE
    pfd.bReserved = 0
    pfd.dwLayerMask = 0
    pfd.dwVisibleMask = 0
    pfd.dwDamageMask = 0

    Select Case uMsg

        Case %WM_CREATE
            hDC = GetDC(hWnd)
            PixelFormat = ChoosePixelFormat(hDC, pfd)

            If IsFalse(PixelFormat) Then
                MsgBox "Can't Find A Suitable PixelFormat."
                PostQuitMessage 0
            End If

            If IsFalse(SetPixelFormat(hDC,PixelFormat,pfd)) Then
                MsgBox "Can't Set The PixelFormat."
                PostQuitMessage 0
            End If

            hRC = wglCreateContext(hDC)
            If IsFalse(hRC) Then
                MsgBox "Can't Create A GL Rendering Context."
                PostQuitMessage 0
            End If

            If IsFalse(wglMakeCurrent(hDC,hRC)) Then
                MsgBox "Can't activate GLRC."
                PostQuitMessage 0
            End If

            GetClientRect hWnd,nScreen
            InitGL nScreen.nRight,nScreen.nBottom

            Function = 0
            Exit Function

        Case %WM_DESTROY
            ChangeDisplaySettings ByVal %NULL,0

            wglMakeCurrent hDC,0
            wglDeleteContext hRC
            ReleaseDC hWNd,hDC

            PostQuitMessage 0

            Function = 0
            Exit Function

        Case %WM_CLOSE
            ChangeDisplaySettings ByVal %NULL,0

            wglMakeCurrent hDC,0
            wglDeleteContext hRC
            ReleaseDC hWNd,hDC

            PostQuitMessage 0

            Function = 0
            Exit Function

        Case %WM_KEYDOWN
            keys(wParam) = 1
            Function = 0
            Exit Function

        Case %WM_KEYUP
            keys(wParam) = 0
            Function = 0
            Exit Function

        Case %WM_SIZE
            ReSizeGLScene LoWrd(lParam),HiWrd(lParam)
            Function = 0
            Exit Function

    End Select

    Function = DefWindowProc(hWnd, uMsg, wParam, lParam)

End Function

Function WinMain(ByVal hInstance As Long, ByVal hPrevInstance As Long, lpCmdLine As Asciiz Ptr, ByVal nCmdShow As Long) Export As Long
    Local msg As tagMSG
    Local wc As WNDCLASS
    Local hWnd As Long
    Local szAppName As Asciiz * 20
    z = -5.0

    szAppName           = "OpenGL WinClass"
    wc.style            = %CS_HREDRAW Or %CS_VREDRAW Or %CS_OWNDC
    wc.lpfnWndProc      = CodePtr(WndProc)
    wc.cbClsExtra       = 0
    wc.cbWndExtra       = 0
    wc.hInstance        = hInstance
    wc.hIcon            = %NULL
    wc.hCursor          = LoadCursor(0,ByVal %IDC_ARROW)
    wc.hbrBackground    = %NULL
    wc.lpszMenuName     = %NULL
    wc.lpszClassName    = VarPtr(szAppName)

    If IsFalse(RegisterClass(wc)) Then
        MsgBox "Failed To Register The Window Class."
        Exit Function
    End If

    hWnd = CreateWindow(szAppName, _
                        "PB OpenGL Demo", _
                        %WS_POPUP Or %WS_CLIPCHILDREN Or %WS_CLIPSIBLINGS, _
                        0,0,640,480, _
                        %NULL,%NULL,hInstance,ByVal %NULL)


    If IsFalse(hWnd) Then
        MsgBox "Window Creation Error."
        Exit Function
    End If

    Local dmScreenSettings As DEVMODE
    dmScreenSettings.dmSize = SizeOf(dmScreenSettings)
    dmScreenSettings.dmPelsWidth = 640
    dmScreenSettings.dmPelsHeight = 480
    dmScreenSettings.dmFields = %DM_PELSWIDTH Or %DM_PELSHEIGHT
    ChangeDisplaySettings dmScreenSettings,%CDS_FULLSCREEN

    ShowWindow hWnd,%SW_SHOW
    UpdateWindow hWnd
    SetFocus hWnd
    wglMakeCurrent hDC,hRC

    While 1
        While IsTrue(PeekMessage(msg,%NULL,0,0,%PM_NOREMOVE))
            If GetMessage(msg,%NULL,0,0) Then
                TranslateMessage msg
                DispatchMessage msg
            Else
               Function = 1
               Exit Function
            End If
        Wend

        DrawGLScene
        SwapBuffers hDC
        If keys(%VK_ESCAPE) Then SendMessage hWnd,%WM_CLOSE,0,0

        If keys(76) And IsFalse(lp) Then    ' L
           lp = %TRUE
           If light = %TRUE Then light = %FALSE Else light = %TRUE

           If IsFalse(light) Then
              glDisable %GL_LIGHTING
           Else
              glEnable %GL_LIGHTING
           End If
        End If

        If IsFalse(keys(76)) Then lp = %FALSE

        If keys(70) And IsFalse(fp) Then    ' F
           fp = %TRUE
           filter = filter + 1
           If filter > 2 Then filter = 0
        End If

        If IsFalse(keys(70)) Then fp = %FALSE

        If keys(%VK_PRIOR) Then z = z - 0.02
        If keys(%VK_NEXT) Then z = z + 0.02
        If keys(%VK_UP) Then xspeed = xspeed - 0.01
        If keys(%VK_DOWN) Then xspeed = xspeed + 0.01
        If keys(%VK_RIGHT) Then yspeed = yspeed + 0.01
        If keys(%VK_LEFT) Then yspeed = yspeed - 0.01

        If keys(66) And IsFalse(bp) Then    ' B
           bp = %TRUE
           If blend = %TRUE Then blend = %FALSE Else blend = %TRUE
           If blend Then
              glEnable %GL_BLEND
              glDisable %GL_DEPTH_TEST
           Else
              glDisable %GL_BLEND
              glEnable %GL_DEPTH_TEST
           End If
        End If

        If IsFalse(keys(66)) Then bp = %FALSE
    Wend

End Function

                                                                                