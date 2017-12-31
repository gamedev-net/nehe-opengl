Attribute VB_Name = "modMain"
Option Explicit

'/*
' *      This Code Was Created By Jeff Molofee and GB Schmick 2000
' *      A HUGE Thanks To Fredric Echols For Cleaning Up
' *      And Optimizing The Base Code, Making It More Flexible!
' *      If You've Found This Code Useful, Please Let Me Know.
' *      Visit Our Sites At www.tiptup.com and nehe.gamedev.net
' */
'
' VB Win32 port by Chris Gilbert (AKA The Gilb) 2k1
'

Dim hDC As Long
Dim hRC As Long
Dim hWnd As Long

Dim keys(256) As Boolean
Dim active As Boolean
Dim fullscreen As Boolean
Dim light As Boolean
Dim lp As Boolean
Dim fp As Boolean
Dim sp As Boolean

Dim part1 As Integer
Dim part2 As Integer
Dim p1 As Integer
Dim p2 As Integer

Dim xrot As GLfloat
Dim yrot As GLfloat
Dim xspeed As GLfloat
Dim yspeed As GLfloat
Dim z As GLfloat

Dim quadratic As GLUquadricObj

Dim LightAmbient(3) As GLfloat
Dim LightDiffuse(3) As GLfloat
Dim LightPosition(3) As GLfloat

Dim filter As GLuint
Dim texture(3) As GLuint
Dim object As GLuint


Private Function LoadBMP(Filename As String) As Byte()
    Dim bmFile As BITMAPFILEHEADER
    Dim bmInfo As BITMAPINFOHEADER
    Dim bmRGB() As RGBQUAD
    Dim ff As Integer
    Dim lImageSize As Long
    Dim iPixelSize As Integer
    Dim baImageData() As Byte
  
    ' Find a free file for opening
    ff = FreeFile()
  
    ' Open the file
    Open Filename For Binary As ff
        'Read in the headers
        Get ff, , bmFile
        Get ff, , bmInfo
  
        'Determine how many colors are used
        If (bmInfo.biBitCount < 24) Then
            'Less than 24 bits per pixel are used, so read in the color table
            ReDim bmRGB(bmInfo.biClrUsed)
    
            Get ff, , bmRGB
        End If
  
        'Determine how big the image is
        iPixelSize = bmInfo.biBitCount / 8
  
        'Resize array to fit image data size
        lImageSize = bmInfo.biWidth * bmInfo.biHeight * iPixelSize
        ReDim baImageData(lImageSize)
  
        'Read in the image data
        Get ff, , baImageData
    Close ff
    
    LoadBMP = baImageData(): Exit Function
End Function

Private Sub LoadGLTextures()
    Dim bmpdata() As Byte
    Dim width As GLsizei, height As GLsizei
    
    bmpdata = LoadBMP(App.Path & "\Data\Wall.bmp")
    
    '
    ' !!! WARNING !!!
    '
    ' These values are hard-coded, but only because I couldn't find a gracious way
    ' of returning the width and height of the bitmap from the LoadBMP function
    ' whilst still keeping NeHe compliant :) When loading your own bitmaps you can find
    ' their width and height in the LoadBMP function as bmInfo.biWidth / biHeight
    '
    width = 64
    height = 64
    
    glGenTextures 3, texture(0)
    
    glBindTexture glTexture2D, texture(0)
    glTexParameteri glTexture2D, tpnTextureMagFilter, GL_NEAREST
    glTexParameteri glTexture2D, tpnTextureMinFilter, GL_NEAREST
    glTexImage2D glTexture2D, 0, 3, width, height, 0, tiBGRExt, GL_UNSIGNED_BYTE, bmpdata(0)

    glBindTexture glTexture2D, texture(1)
    glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
    glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR
    glTexImage2D glTexture2D, 0, 3, width, height, 0, tiBGRExt, GL_UNSIGNED_BYTE, bmpdata(0)

    glBindTexture glTexture2D, texture(2)
    glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
    glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR_MIPMAP_NEAREST
    gluBuild2DMipmaps glTexture2D, 3, width, height, tiBGRExt, GL_UNSIGNED_BYTE, VarPtr(bmpdata(0))

    Erase bmpdata
End Sub

Public Sub ReSizeGLScene(width As Integer, height As Integer)
    If height = 0 Then height = 1
    
    glViewport 0, 0, width, height
    
    glMatrixMode mmProjection
    glLoadIdentity
    
    gluPerspective 45#, CDbl(width) / CDbl(height), 0.1, 100#
    
    glMatrixMode mmModelView
    glLoadIdentity
End Sub

Public Function InitGL() As Integer
    Call LoadGLTextures

    glEnable glcTexture2D
    glShadeModel smSmooth
    glClearColor 0, 0, 0, 0.5
    glClearDepth 1
    glEnable glcDepthTest
    glDepthFunc cfLEqual
    glHint htPerspectiveCorrectionHint, hmNicest
    
    LightAmbient(0) = 0.5: LightAmbient(1) = 0.5: LightAmbient(2) = 0.5: LightAmbient(3) = 1
    LightDiffuse(0) = 1: LightDiffuse(1) = 1: LightDiffuse(2) = 1: LightDiffuse(3) = 1
    LightPosition(0) = 0: LightPosition(1) = 0: LightPosition(2) = 2: LightPosition(3) = 1

    glLightfv ltLight1, lpmAmbient, LightAmbient(0)
    glLightfv ltLight1, lpmDiffuse, LightDiffuse(0)
    glLightfv ltLight1, lpmPosition, LightPosition(0)
    glEnable glcLight1
    
    quadratic = gluNewQuadric()
    gluQuadricNormals quadratic, qnSmooth
    gluQuadricTexture quadratic, GL_TRUE
    
    InitGL = True: Exit Function
End Function

Public Sub DrawCube()
    glBegin bmQuads
        ' Front Face
        glNormal3f 0, 0, 1
        glTexCoord2f 0, 0: glVertex3f -1, -1, 1
        glTexCoord2f 1, 0: glVertex3f 1, -1, 1
        glTexCoord2f 1, 1: glVertex3f 1, 1, 1
        glTexCoord2f 0, 1: glVertex3f -1, 1, 1
        ' Back Face
        glNormal3f 0, 0, -1
        glTexCoord2f 1, 0: glVertex3f -1, -1, -1
        glTexCoord2f 1, 1: glVertex3f -1, 1, -1
        glTexCoord2f 0, 1: glVertex3f 1, 1, -1
        glTexCoord2f 0, 0: glVertex3f 1, -1, -1
        ' Top Face
        glNormal3f 0, 1, 0
        glTexCoord2f 0, 1: glVertex3f -1, 1, -1
        glTexCoord2f 0, 0: glVertex3f -1, 1, 1
        glTexCoord2f 1, 0: glVertex3f 1, 1, 1
        glTexCoord2f 1, 1: glVertex3f 1, 1, -1
        ' Bottom Face
        glNormal3f 0, -1, 0
        glTexCoord2f 1, 1: glVertex3f -1, -1, -1
        glTexCoord2f 0, 1: glVertex3f 1, -1, -1
        glTexCoord2f 0, 0: glVertex3f 1, -1, 1
        glTexCoord2f 1, 0: glVertex3f -1, -1, 1
        ' Right Face
        glNormal3f 1, 0, 0
        glTexCoord2f 1, 0: glVertex3f 1, -1, -1
        glTexCoord2f 1, 1: glVertex3f 1, 1, -1
        glTexCoord2f 0, 1: glVertex3f 1, 1, 1
        glTexCoord2f 0, 0: glVertex3f 1, -1, 1
        ' Left Face
        glNormal3f -1, 0, 0
        glTexCoord2f 0, 0: glVertex3f -1, -1, -1
        glTexCoord2f 1, 0: glVertex3f -1, -1, 1
        glTexCoord2f 1, 1: glVertex3f -1, 1, 1
        glTexCoord2f 0, 1: glVertex3f -1, 1, -1
    glEnd
End Sub

Public Function DrawGLScene() As Integer
    glClear clrColorBufferBit Or clrDepthBufferBit
    glLoadIdentity
    glTranslatef 0, 0, z

    glRotatef xrot, 1, 0, 0
    glRotatef yrot, 0, 1, 0

    glBindTexture glTexture2D, texture(filter)

    Select Case object
        Case 0:
            Call DrawCube
        Case 1:
            glTranslatef 0, 0, -1.5
            gluCylinder quadratic, 1, 1, 3, 32, 32
        Case 2:
            gluDisk quadratic, 0.5, 1.5, 32, 32
        Case 3:
            gluSphere quadratic, 1.3, 32, 32
        Case 4:
            glTranslatef 0, 0, -1.5
            gluCylinder quadratic, 1, 0, 3, 32, 32
        Case 5:
            part1 = part1 + p1
            part2 = part2 + p2
   
            If part1 > 359 Then
                p1 = 0
                part1 = 0
                p2 = 1
                part2 = 0
            End If
            If part2 > 359 Then
                p1 = 1
                p2 = 0
            End If
            gluPartialDisk quadratic, 0.5, 1.5, 32, 32, part1, part2 - part1
    End Select

    xrot = xrot + xspeed
    yrot = yrot + yspeed
    
    DrawGLScene = True
End Function

Public Sub KillGLWindow()
    If fullscreen Then
        ChangeDisplaySettings 0, 0
        ShowCursor True
    End If

    If hRC <> 0 Then
        If Not wglMakeCurrent(0, 0) <> 0 Then
            MsgBox "Release Of DC And RC Failed!"
        End If
        
        If Not wglDeleteContext(hRC) <> 0 Then
            MsgBox "Release Rendering Context Failed!"
        End If
        
        hRC = 0
    End If
    
    ReleaseDC hWnd, hDC
    DestroyWindow hWnd
    
    If Not UnregisterClass("OPENGL", App.hInstance) <> 0 Then
        MsgBox "Could Not Unregister Class!"
    End If
End Sub

Public Function CreateGLWindow(Title As String, width As Integer, height As Integer, BPP As Integer, fullscreenflag As Boolean) As Boolean
    Dim PixelFormat As Long
    Dim wc As WNDCLASSEX
    Dim dwStyle As Long, dwExStyle As Long
    Dim pfd As PIXELFORMATDESCRIPTOR
    Dim WindowRect As RECT
    
    fullscreen = fullscreenflag
    
    With WindowRect
        .Top = 0
        .Left = 0
        .Bottom = height
        .Right = width
    End With
    
    With wc
        .cbSize = Len(wc)
        .style = CS_HREDRAW Or CS_VREDRAW Or CS_OWNDC
        .lpfnWndProc = getAddress(AddressOf WndProc)
        .hInstance = App.hInstance
        .hbrBackground = COLOR_APPWORKSPACE
        .hCursor = LoadCursor(0, IDC_ARROW)
        .lpszClassName = "OPENGL"
        .hIcon = LoadIcon(0, IDI_WINLOGO)
    End With
    
    If RegisterClassEx(wc) = 0 Then
        MsgBox "RegisterClassEx Failed!"
        CreateGLWindow = False: Exit Function
    End If
    
    If fullscreen Then
        Dim dmScreenSettings As DEVMODE
        
        With dmScreenSettings
            .dmSize = Len(dmScreenSettings)
            .dmPelsWidth = width
            .dmPelsHeight = height
            .dmBitsPerPel = BPP
            .dmFields = DM_BITSPERPEL Or DM_PELSWIDTH Or DM_PELSHEIGHT
        End With
        
        If (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL) Then
            If (MsgBox("The Requested Mode Is Not Supported By" & vbCr & "Your Video Card. Use Windowed Mode Instead?", vbYesNo + vbExclamation, "NeHe GL") = vbYes) Then
                fullscreen = False
            Else
                MsgBox "Program Will Now Close.", vbCritical, "ERROR"
                CreateGLWindow = False: Exit Function
            End If
        End If
    End If
    
    If fullscreen Then
        dwExStyle = WS_EX_APPWINDOW
        dwStyle = WS_POPUP
        ShowCursor False
    Else
        dwExStyle = WS_EX_APPWINDOW Or WS_EX_WINDOWEDGE
        dwStyle = WS_OVERLAPPEDWINDOW
    End If
    
    AdjustWindowRectEx WindowRect, dwStyle, CLng(False), dwExStyle
    
    hWnd = CreateWindowEx(dwExStyle, _
                    "OPENGL", _
                    Title, _
                    dwStyle Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN, _
                    GetSystemMetrics(SM_CXSCREEN) / 2 - width / 2, _
                    GetSystemMetrics(SM_CYSCREEN) / 2 - height / 2, _
                    width, _
                    height, _
                    HWND_DESKTOP, _
                    0, _
                    App.hInstance, _
                    Nothing)
                    
    If Not hWnd <> 0 Then
        MsgBox "CreateWindowEx Failed!"
        CreateGLWindow = False: Exit Function
    End If
    
    With pfd
        .nSize = Len(pfd)
        .nVersion = 1
        .dwflags = PFD_DRAW_TO_WINDOW Or PFD_SUPPORT_OPENGL Or PFD_DOUBLEBUFFER
        .iPixelType = PFD_TYPE_RGBA
        .cColorBits = BPP
        .cRedBits = 0: .cRedShift = 0: .cGreenBits = 0: .cGreenShift = 0: .cBlueBits = 0: .cBlueShift = 0
        .cAlphaBits = 0
        .cAlphaShift = 0
        .cAccumBits = 0
        .cAccumRedBits = 0: .cAccumGreenBits = 0: .cAccumBlueBits = 0: .cAccumAlphaBits = 0
        .cDepthBits = 16
        .cStencilBits = 0
        .cAuxBuffers = 0
        .iLayerType = PFD_MAIN_PLANE
        .bReserved = 0
        .dwLayerMask = 0: .dwVisibleMask = 0: .dwDamageMask = 0
    End With
    
    hDC = GetDC(hWnd)
    If Not hDC <> 0 Then
        MsgBox "GetDC Failed! : HDC = " & hDC
        KillGLWindow
        CreateGLWindow = False: Exit Function
    End If
    
    PixelFormat = ChoosePixelFormat(hDC, pfd)
    If Not PixelFormat <> 0 Then
        MsgBox "ChoosePixelFormat Failed!"
        KillGLWindow
        CreateGLWindow = False: Exit Function
    End If
    
    If Not SetPixelFormat(hDC, PixelFormat, pfd) <> 0 Then
        MsgBox "SetPixelFormat Failed!"
        KillGLWindow
        CreateGLWindow = False: Exit Function
    End If
    
    hRC = wglCreateContext(hDC)
    If Not hRC <> 0 Then
        MsgBox "wglCreateContext Failed!"
        KillGLWindow
        CreateGLWindow = False: Exit Function
    End If
    
    If Not wglMakeCurrent(hDC, hRC) <> 0 Then
        MsgBox "wglMakeCurrent Failed!"
        KillGLWindow
        CreateGLWindow = False: Exit Function
    End If

    ShowWindow hWnd, SW_SHOW
    UpdateWindow hWnd
    
    SetWindowPos hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE Or SWP_NOSIZE
    SetFocus hWnd
    
    ReSizeGLScene width, height
    InitGL
    
    CreateGLWindow = True
End Function

Public Function WndProc(ByVal lhWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
    Select Case wMsg
        Case WM_ACTIVATE:
            If HIWORD(wParam) <> 0 Then
                active = True
            Else
                active = False
            End If
            
            WndProc = 0: Exit Function
            
        Case WM_SYSCOMMAND:
            Select Case wParam
                Case SC_SCREENSAVE
                Case SC_MONITORPOWER
                
                WndProc = 0: Exit Function
            End Select
    
        Case WM_CLOSE:
            PostQuitMessage 0
            WndProc = 0: Exit Function
            
        Case WM_KEYDOWN:
            keys(wParam) = True
            WndProc = 0: Exit Function
        
        Case WM_KEYUP:
            keys(wParam) = False
            WndProc = 0: Exit Function
            
        Case WM_SIZE:
            ReSizeGLScene LOWORD(lParam), HIWORD(lParam)
            WndProc = 0: Exit Function
    End Select
    
    WndProc = DefWindowProc(lhWnd, wMsg, wParam, lParam)
End Function

Sub Main()
    Dim mymsg As MSG
    Dim done As Boolean
    
    done = False
    active = True
    fullscreen = True
    p1 = 0
    p2 = 1
    z = -5
    object = 0
    
    If MsgBox("Would You Like To Run In Fullscreen Mode?", vbYesNo, "Start Fullscreen?") = vbNo Then
        fullscreen = False
    End If

    If Not CreateGLWindow("NeHe & TipTup's Quadratics Tutorial", 640, 480, 16, fullscreen) Then
        Exit Sub
    End If

    Do While Not done
        If PeekMessage(mymsg, 0&, 0, 0, PM_REMOVE) Then
            If mymsg.message = WM_QUIT Then
                done = True
            Else
                TranslateMessage mymsg
                DispatchMessage mymsg
            End If
        Else
            If (active And (Not DrawGLScene)) Or keys(VK_ESCAPE) Then
                done = True
            Else
                SwapBuffers hDC
                If keys(vbKeyL) And (Not lp) Then
                    lp = True
                    light = Not light
                    If Not light Then
                        glDisable glcLighting
                    Else
                        glEnable glcLighting
                    End If
                End If
                If Not keys(vbKeyL) Then
                    lp = False
                End If
                If keys(vbKeyF) And (Not fp) Then
                    fp = True
                    filter = filter + 1
                    If filter > 2 Then
                        filter = 0
                    End If
                End If
                If Not keys(vbKeyF) Then
                    fp = False
                End If
                If keys(vbKeySpace) And (Not sp) Then
                    sp = True
                    object = object + 1
                    If object > 5 Then object = 0
                End If
                If Not keys(vbKeySpace) Then
                    sp = False
                End If
                If keys(VK_PRIOR) Then
                    z = z - 0.02
                End If
                If keys(VK_NEXT) Then
                    z = z + 0.02
                End If
                If keys(VK_UP) Then
                    xspeed = xspeed - 0.01
                End If
                If keys(VK_DOWN) Then
                    xspeed = xspeed + 0.01
                End If
                If keys(VK_RIGHT) Then
                    yspeed = yspeed + 0.01
                End If
                If keys(VK_LEFT) Then
                    yspeed = yspeed - 0.01
                End If

                If keys(VK_F1) Then
                    keys(VK_F1) = False
                    Call KillGLWindow
                    fullscreen = Not fullscreen
                    If Not CreateGLWindow("NeHe & TipTup's Quadratics Tutorial", 640, 480, 16, fullscreen) Then
                        Exit Sub
                    End If
                End If
            End If
        End If
    Loop
    
    Call KillGLWindow
End Sub

'
' HELPER FUNCTIONS
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Function getAddress(lpadr As Long) As Long
    getAddress = lpadr
End Function

Public Function HIWORD(val As Long) As Integer
    HIWORD = val \ &H10000 And &HFFFF&
End Function

Public Function LOWORD(val As Long) As Integer
    LOWORD = val And &HFFFF&
End Function
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' END HELPER FUNCTIONS
'
