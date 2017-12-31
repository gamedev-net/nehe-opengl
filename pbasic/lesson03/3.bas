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

Sub InitGL(ByVal nWidth As Long, ByVal nHeight As Long)
   glClearColor 0.0,0.0,0.0,0.0
   glClearDepth 1.0
   glDepthFunc %GL_LESS
   glEnable %GL_DEPTH_TEST
   glShadeModel %GL_SMOOTH

   glMatrixMode %GL_PROJECTION
   glLoadIdentity

   gluPerspective 45.0,nWidth/nHeight,0.1,100.0

   glMatrixMode %GL_MODELVIEW
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

   glTranslatef -1.5,0.0,-6.0

   glBegin %GL_POLYGON
        glColor3f 1.0,0.0,0.0              ' Set The Color To Red
        glVertex3f  0.0, 1.0, 0.0          ' Top

        glColor3f 0.0,1.0,0.0              ' Set The Color To Green
        glVertex3f  1.0,-1.0, 0.0          ' Bottom Right

        glColor3f 0.0,0.0,1.0              ' Set The Color To Blue
        glVertex3f -1.0,-1.0, 0.0          ' Bottom Left
   glEnd

   glTranslatef 3.0,0.0,0.0

   glColor3f 0.5,0.5,1.0                   ' // Set The Color To Blue One Time Only
   glBegin %GL_QUADS
        glVertex3f -1.0, 1.0, 0.0          ' Top Left
        glVertex3f  1.0, 1.0, 0.0          ' Top Right
        glVertex3f  1.0,-1.0, 0.0          ' Bottom Right
        glVertex3f -1.0,-1.0, 0.0          ' Bottom Left
   glEnd
End Sub

Function WndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
   Local nScreen As RECT
   Local PixelFormat As Long
   Local pfd As PIXELFORMATDESCRIPTOR
   Dim keys(256) As Long

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
    Wend

End Function




                                                                                              