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

Global twinkle As Long
Global tp As Long

%num = 50

Type stars
   r As Long
   g As Long
   b As Long
   dist As Single
   angle As Single
End Type

Global star() As stars

Global zoom As Single
Global tilt As Single
Global spin As Single

Global nloop As Long
Global texture() As Long

Sub LoadGLTextures()
    ReDim texture(1) As Long
    Dim texture1 As AUX_RGBImageRec Ptr

    texture1 = auxDIBImageLoad("star.bmp")
    If texture1 = %NULL Then ExitProcess 1

    glGenTextures 1, texture(0)

    ' Create Linear Filtered Texture
    glBindTexture %GL_TEXTURE_2D, texture(0)
    glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MAG_FILTER,%GL_LINEAR
    glTexParameteri %GL_TEXTURE_2D,%GL_TEXTURE_MIN_FILTER,%GL_LINEAR
    glTexImage2D %GL_TEXTURE_2D, 0, 3, @texture1.sizeX, @texture1.sizeY, 0, %GL_RGB, %GL_UNSIGNED_BYTE, @texture1.@nData
End Sub

Sub InitGL(ByVal nWidth As Long, ByVal nHeight As Long)
   ReDim star(%num) As stars

   LoadGLTextures
   glEnable %GL_TEXTURE_2D

   glClearColor 0.0,0.0,0.0,0.0
   glClearDepth 1.0
   glShadeModel %GL_SMOOTH

   glMatrixMode %GL_PROJECTION
   glLoadIdentity

   gluPerspective 45.0,nWidth/nHeight,0.1,100.0

   glMatrixMode %GL_MODELVIEW
   glBlendFunc %GL_SRC_ALPHA,%GL_ONE
   glEnable %GL_BLEND

   For nloop = 0 To %num -1
       star(nloop).angle = 0.0
       star(nloop).dist = (nloop/%num)*5.0 ' Calculate Distance From The Center
       star(nloop).r = Rnd(0,255)          ' Give star[loop] A Random Red Intensity
       star(nloop).g = Rnd(0,255)          ' Give star[loop] A Random Green Intensity
       star(nloop).b = Rnd(0,255)          ' Give star[loop] A Random Blue Intensity
   Next nloop
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
   glBindTexture %GL_TEXTURE_2D, texture(0)

   For nloop = 0 To %num - 1
       glLoadIdentity
       glTranslatef 0.0,0.0,zoom
       glRotatef tilt,1.0,0.0,0.0

       glRotatef star(nloop).angle,0.0,1.0,0.0
       glTranslatef star(nloop).dist,0.0,0.0

       glRotatef -star(nloop).angle,0.0,1.0,0.0
       glRotatef -tilt,1.0,0.0,0.0

       If twinkle Then
           ' Assign A Color Using Bytes
          glColor4ub star((%num-nloop)-1).r,star((%num-nloop)-1).g,star((%num-nloop)-1).b,255
          glBegin %GL_QUADS
              glTexCoord2f 0.0, 0.0: glVertex3f -1.0,-1.0, 0.0
              glTexCoord2f 1.0, 0.0: glVertex3f  1.0,-1.0, 0.0
              glTexCoord2f 1.0, 1.0: glVertex3f  1.0, 1.0, 0.0
              glTexCoord2f 0.0, 1.0: glVertex3f -1.0, 1.0, 0.0
          glEnd
       End If

       glRotatef spin,0.0,0.0,1.0
       ' Assign A Color Using Bytes
       glColor4ub star(nloop).r,star(nloop).g,star(nloop).b,255
       glBegin %GL_QUADS
           glTexCoord2f 0.0, 0.0: glVertex3f -1.0,-1.0, 0.0
           glTexCoord2f 1.0, 0.0: glVertex3f  1.0,-1.0, 0.0
           glTexCoord2f 1.0, 1.0: glVertex3f  1.0, 1.0, 0.0
           glTexCoord2f 0.0, 1.0: glVertex3f -1.0, 1.0, 0.0
       glEnd

       spin = spin + 0.01
       star(nloop).angle = star(nloop).angle + (nloop/%num)
       star(nloop).dist = star(nloop).dist - 0.01

       If star(nloop).dist < 0.0 Then
          star(nloop).dist = star(nloop).dist + 5.0
          star(nloop).r = Rnd(0,255)
          star(nloop).g = Rnd(0,255)
          star(nloop).b = Rnd(0,255)
       End If
   Next
End Sub

Function WndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
   Local nScreen As RECT
   Local PixelFormat As Long
   Local pfd As PIXELFORMATDESCRIPTOR

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

    ReDim keys(256) As Long
    zoom = -15.0
    tilt = 90.0

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

        If keys(84) And IsFalse(tp) Then       ' T
           tp = %TRUE
           If twinkle = %TRUE Then twinkle = %FALSE Else twinkle = %TRUE
        End If

        If IsFalse(keys(84)) Then tp = %FALSE  'T
        If keys(%VK_UP) Then tilt = tilt - 0.5
        If keys(%VK_DOWN) Then tilt = tilt + 0.5
        If keys(%VK_PRIOR) Then zoom = zoom - 0.2
        If keys(%VK_NEXT) Then zoom = zoom + 0.2
    Wend

End Function




                                                                                                   