Attribute VB_Name = "OGLUtils"
Option Explicit

' a couple of declares to work around some deficiencies of the type library
Private Declare Function EnumDisplaySettings Lib "user32" Alias "EnumDisplaySettingsA" (ByVal lpszDeviceName As Long, ByVal iModeNum As Long, lpDevMode As Any) As Boolean
Private Declare Function ChangeDisplaySettings Lib "user32" Alias "ChangeDisplaySettingsA" (lpDevMode As Any, ByVal dwflags As Long) As Long
Private Declare Function CreateIC Lib "gdi32" Alias "CreateICA" (ByVal lpDriverName As String, ByVal lpDeviceName As String, ByVal lpOutput As String, ByVal lpInitData As Long) As Long

Private Const CCDEVICENAME = 32
Private Const CCFORMNAME = 32
Private Const DM_BITSPERPEL = &H40000
Private Const DM_PELSWIDTH = &H80000
Private Const DM_PELSHEIGHT = &H100000

Private Type DEVMODE
    dmDeviceName        As String * CCDEVICENAME
    dmSpecVersion       As Integer
    dmDriverVersion     As Integer
    dmSize              As Integer
    dmDriverExtra       As Integer
    dmFields            As Long
    dmOrientation       As Integer
    dmPaperSize         As Integer
    dmPaperLength       As Integer
    dmPaperWidth        As Integer
    dmScale             As Integer
    dmCopies            As Integer
    dmDefaultSource     As Integer
    dmPrintQuality      As Integer
    dmColor             As Integer
    dmDuplex            As Integer
    dmYResolution       As Integer
    dmTTOption          As Integer
    dmCollate           As Integer
    dmFormName          As String * CCFORMNAME
    dmUnusedPadding     As Integer
    dmBitsPerPel        As Integer
    dmPelsWidth         As Long
    dmPelsHeight        As Long
    dmDisplayFlags      As Long
    dmDisplayFrequency  As Long
End Type

Public Keys(255) As Boolean             ' used to keep track of key_downs
Public Active As Boolean

Private hrc As Long
Private fullscreen As Boolean

Public xrot As GLfloat                                  ' X Rotation ( NEW )
Public yrot As GLfloat                                  ' Y Rotation ( NEW )
Public xspeed As GLfloat                                ' X Rotation Speed
Public yspeed As GLfloat                                ' Y Rotation Speed

Public z As GLfloat                                     ' Depth Into The Screen (we need to initialize this
                                                        ' as we can't declare and assign an initivalue like C
                                                        ' initial value -0.5#

Public base As GLuint         ' Base Display List For The Font Set
Public rot As GLfloat             ' Used To Rotate The Text      ( ADD )
Public gmf(256) As GLYPHMETRICSFLOAT   ' Storage For Information About Our Font


Public light As Boolean                                 ' Lighting ON / OFF
Public lp As Boolean                                    ' L Pressed?
Public fp As Boolean                                    ' F Pressed?

Public LightAmbient(3) As GLfloat                       ' Ambient Light Values ( NEW )
                                                        '   = { 0.5f, 0.5f, 0.5f, 1.0f };
Public LightDiffuse(3) As GLfloat                       ' Diffuse Light Values ( NEW )
                                                        '   = { 1.0f, 1.0f, 1.0f, 1.0f };
Public LightPosition(3) As GLfloat                      ' Light Position ( NEW )
                                                        '   = { 0.0f, 0.0f, 2.0f, 1.0f };

Public filter As GLuint                                 ' Which Filter To Use
Public Texture(3) As GLuint                             ' Storage For Three Textures





Private OldWidth As Long
Private OldHeight As Long
Private OldBits As Long
Private OldVertRefresh As Long
Private mPointerCount As Integer

Private Sub SetupLightingArrays()
    LightAmbient(0) = 0.5
    LightAmbient(1) = 0.5
    LightAmbient(2) = 0.5
    LightAmbient(3) = 1#

    LightDiffuse(0) = 1#
    LightDiffuse(1) = 1#
    LightDiffuse(2) = 1#
    LightDiffuse(3) = 1#
    
    LightPosition(0) = 0#
    LightPosition(1) = 0#
    LightPosition(2) = 2#
    LightPosition(3) = 1#
End Sub

Public Sub BuildFont(frm As Form)                    ' Build Our Bitmap Font
    Dim hfont As Long                       ' Windows Font ID

    base = glGenLists(256)                   ' Storage For 256 Characters
    hfont = CreateFont(-12, 0, 0, 0, FW_BOLD, False, False, False, _
            SYMBOL_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, _
            FF_DONTCARE Or DEFAULT_PITCH, "WIngdings")
            

    SelectObject frm.hDC, hfont                ' Selects The Font We Created ( NEW )

    wglUseFontOutlines frm.hDC, 0, 255, base, 0.1, 0.2, WGL_FONT_POLYGONS, gmf(0)

End Sub

Private Sub KillFont()                     ' Delete The Font
    glDeleteLists base, 256                ' Delete All 256 Characters
End Sub

Public Sub glPrint(ByVal s As String)                ' Custom GL "Print" Routine
    ' we are just going to provide a simple print routine just like normal basic
    Dim b() As Byte
    Dim i As Integer
    Dim length As Double
    If Len(s) > 0 Then              ' only if the pass a string
        ReDim b(Len(s))             ' array of bytes to hold the string
        For i = 1 To Len(s)         ' for each character
            b(i - 1) = Asc(Mid$(s, i, 1)) ' convert from unicode to ascii
            length = length + gmf(b(i)).gmfCellIncX      ' Increase Length By Each Characters Width
        Next
        b(Len(s)) = 0               ' null terminated
        glTranslatef -length / 2, 0#, 0#          ' Center Our Text On The Screen


        glPushAttrib amListBit               ' Pushes The Display List Bits     ( NEW )
        glListBase base                  ' Sets The Base Character to 32    ( NEW )
    
        glCallLists Len(s), GL_UNSIGNED_BYTE, b(0)   ' Draws The Display List Text  ( NEW )
        glPopAttrib                      ' Pops The Display List Bits   ( NEW )
    End If
End Sub

Private Sub HidePointer()
    ' hide the cursor (mouse pointer)
    mPointerCount = ShowCursor(False) + 1
    Do While ShowCursor(False) >= -1
    Loop
    Do While ShowCursor(True) <= -1
    Loop
    ShowCursor False
End Sub

Private Sub ShowPointer()
    ' show the cursor (mouse pointer)
    Do While ShowCursor(False) >= mPointerCount
    Loop
    Do While ShowCursor(True) <= mPointerCount
    Loop
End Sub

Private Function LoadBMP(ByVal Filename As String, ByRef Texture() As GLuint, ByRef Height As Long, ByRef Width As Long) As Boolean

    Dim intFileHandle As Integer
    Dim bitmapheight As Long
    Dim bitmapwidth As Long

    ' Open a file.
    ' The file should be BMP with pictures 64x64,128x128,256x256 .....
  
    If Filename = "" Then
        End
    End If
    If UCase(Right(Filename, 3)) = "BMP" Then
        Form1.Picture1.Picture = LoadPicture(Filename)
        CreateTextureMapFromImage Form1.Picture1, Texture(), Height, Width
    ElseIf UCase(Right(Filename, 3)) = "MOT" Then
        intFileHandle = FreeFile
        Open Filename For Binary Access Read Lock Read Write As intFileHandle
        Get #intFileHandle, , Width
        Get #intFileHandle, , Height
        ReDim bitmapImage(2, Height - 1, Width - 1)
        Get #intFileHandle, , Texture
        Close intFileHandle
    End If
    LoadBMP = True
End Function

Private Sub CreateTextureMapFromImage(pict As PictureBox, ByRef TextureImg() As GLbyte, ByRef Height As Long, ByRef Width As Long)
    ' Create the array as needed for the image.
    pict.ScaleMode = 3                  ' Pixels
    Height = pict.ScaleHeight
    Width = pict.ScaleWidth
    
    ReDim TextureImg(2, Height - 1, Width - 1)
    
    ' Fill the array with the bitmap data...  This could take
    ' a while...
    
    Dim X As Long, Y As Long
    Dim c As Long
    
    Dim yloc As Long
    For X = 0 To Width - 1
        For Y = 0 To Height - 1
            c = pict.Point(X, Y)                ' Returns in long format.
            yloc = Height - Y - 1
            TextureImg(0, X, yloc) = c And 255
            TextureImg(1, X, yloc) = (c And 65280) \ 256
            TextureImg(2, X, yloc) = (c And 16711680) \ 65536
        Next Y
    Next X
    
End Sub

Private Function LoadGLTextures() As Boolean
' Load Bitmaps And Convert To Textures
    Dim Status As Boolean
    Dim h As Long
    Dim w As Long
    Dim TextureImage() As GLbyte
    Status = False                         ' Status Indicator

    If LoadBMP("Data\Lights.BMP", TextureImage(), h, w) Then
        ' Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
        Status = True                          ' Set The Status To TRUE

        glGenTextures 3, Texture(0)            ' Create The Textures

        ' Create Nearest Filtered Texture
        glBindTexture glTexture2D, Texture(0)
        glTexParameteri glTexture2D, tpnTextureMagFilter, GL_NEAREST '( NEW )
        glTexParameteri glTexture2D, tpnTextureMinFilter, GL_NEAREST '( NEW )
        glTexImage2D glTexture2D, 0, 3, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage(0, 0, 0)


        ' Create Linear Filtered Texture
        glBindTexture glTexture2D, Texture(1)
        glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR     ' Linear Filtering
        glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR     ' Linear Filtering
        glTexImage2D glTexture2D, 0, 3, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage(0, 0, 0)
    
        ' Create MipMapped Texture
        glBindTexture glTexture2D, Texture(2)
        glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
        glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR_MIPMAP_NEAREST '( NEW )
        gluBuild2DMipmaps glTexture2D, 3, w, h, GL_RGB, GL_UNSIGNED_BYTE, VarPtr(TextureImage(0, 0, 0))  ' ( NEW )
        ' Texturing Contour Anchored To The Object
        glTexGeni tcS, tgTextureGenMode, tgmObjectLinear
        ' Texturing Contour Anchored To The Object
        glTexGeni tcT, tgTextureGenMode, tgmObjectLinear
        glEnable glcTextureGenS          ' Auto Texture Generation
        glEnable glcTextureGenT          ' Auto Texture Generation

    End If

    Erase TextureImage   ' Free the texture image memory
    LoadGLTextures = Status
End Function

Public Sub ReSizeGLScene(ByVal Width As GLsizei, ByVal Height As GLsizei)
' Resize And Initialize The GL Window
    If Height = 0 Then              ' Prevent A Divide By Zero By
        Height = 1                  ' Making Height Equal One
    End If
    glViewport 0, 0, Width, Height  ' Reset The Current Viewport
    glMatrixMode mmProjection       ' Select The Projection Matrix
    glLoadIdentity                  ' Reset The Projection Matrix

    ' Calculate The Aspect Ratio Of The Window
    gluPerspective 45#, Width / Height, 0.1, 100#

    glMatrixMode mmModelView        ' Select The Modelview Matrix
    glLoadIdentity                  ' Reset The Modelview Matrix
End Sub

Public Function InitGL() As Boolean
' All Setup For OpenGL Goes Here
    If Not LoadGLTextures Then          ' Jump To Texture Loading Routine ( NEW )
        InitGL = False                  ' If Texture Didn't Load Return FALSE ( NEW )
        Exit Function
    End If

    glEnable glcTexture2D               ' Enable Texture Mapping ( NEW )
    glShadeModel smSmooth               ' Enables Smooth Shading

    glClearColor 0#, 0#, 0#, 0.5        ' Black Background

    glClearDepth 1#                     ' Depth Buffer Setup
    glEnable glcDepthTest               ' Enables Depth Testing
    glDepthFunc cfLEqual                ' The Type Of Depth Test To Do

    glHint htPerspectiveCorrectionHint, hmNicest    ' Really Nice Perspective Calculations

    glLightfv ltLight1, lpmAmbient, LightAmbient(0)             ' Setup The Ambient Light
    glLightfv ltLight1, lpmDiffuse, LightDiffuse(0)             ' Setup The Diffuse Light
    glLightfv ltLight1, lpmPosition, LightPosition(0)           ' Position The Light
    glEnable glcLight0                                          ' Enable Light One

    InitGL = True                       ' Initialization Went OK
End Function


Public Sub KillGLWindow()
' Properly Kill The Window
    If fullscreen Then                              ' Are We In Fullscreen Mode?
        ResetDisplayMode                            ' If So Switch Back To The Desktop
        ShowPointer                                 ' Show Mouse Pointer
    End If

    If hrc Then                                     ' Do We Have A Rendering Context?
        If wglMakeCurrent(0, 0) = 0 Then             ' Are We Able To Release The DC And RC Contexts?
            MsgBox "Release Of DC And RC Failed.", vbInformation, "SHUTDOWN ERROR"
        End If

        If wglDeleteContext(hrc) = 0 Then           ' Are We Able To Delete The RC?
            MsgBox "Release Rendering Context Failed.", vbInformation, "SHUTDOWN ERROR"
        End If
        hrc = 0                                     ' Set RC To NULL
    End If

    ' Note
    ' The form owns the device context (hDC) window handle (hWnd) and class (RTThundermain)
    ' so we do not have to do all the extra work
    KillFont                     ' Destroy The Font

End Sub

Private Sub SaveCurrentScreen()
    ' Save the current screen resolution, bits, and Vertical refresh
    Dim ret As Long
    ret = CreateIC("DISPLAY", "", "", 0&)
    OldWidth = GetDeviceCaps(ret, HORZRES)
    OldHeight = GetDeviceCaps(ret, VERTRES)
    OldBits = GetDeviceCaps(ret, BITSPIXEL)
    OldVertRefresh = GetDeviceCaps(ret, VREFRESH)
    ret = DeleteDC(ret)
End Sub

Private Function FindDEVMODE(ByVal Width As Integer, ByVal Height As Integer, ByVal Bits As Integer, Optional ByVal VertRefresh As Long = -1) As DEVMODE
    ' locate a DEVMOVE that matches the passed parameters
    Dim ret As Boolean
    Dim i As Long
    Dim dm As DEVMODE
    i = 0
    Do  ' enumerate the display settings until we find the one we want
        ret = EnumDisplaySettings(0&, i, dm)
        If dm.dmPelsWidth = Width And _
            dm.dmPelsHeight = Height And _
            dm.dmBitsPerPel = Bits And _
            ((dm.dmDisplayFrequency = VertRefresh) Or (VertRefresh = -1)) Then Exit Do ' exit when we have a match
        i = i + 1
    Loop Until (ret = False)
    FindDEVMODE = dm
End Function

Private Sub ResetDisplayMode()
    Dim dm As DEVMODE             ' Device Mode
    
    dm = FindDEVMODE(OldWidth, OldHeight, OldBits, OldVertRefresh)
    dm.dmFields = DM_BITSPERPEL Or DM_PELSWIDTH Or DM_PELSHEIGHT
    If OldVertRefresh <> -1 Then
        dm.dmFields = dm.dmFields Or DM_DISPLAYFREQUENCY
    End If
    ' Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
    If (ChangeDisplaySettings(dm, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL) Then
    
        ' If The Mode Fails, Offer Two Options.  Quit Or Run In A Window.
        MsgBox "The Requested Mode Is Not Supported By Your Video Card", , "NeHe GL"
    End If

End Sub

Private Sub SetDisplayMode(ByVal Width As Integer, ByVal Height As Integer, ByVal Bits As Integer, ByRef fullscreen As Boolean, Optional VertRefresh As Long = -1)
    Dim dmScreenSettings As DEVMODE             ' Device Mode
    Dim p As Long
    SaveCurrentScreen                           ' save the current screen attributes so we can go back later
    
    dmScreenSettings = FindDEVMODE(Width, Height, Bits, VertRefresh)
    dmScreenSettings.dmBitsPerPel = Bits
    dmScreenSettings.dmPelsWidth = Width
    dmScreenSettings.dmPelsHeight = Height
    dmScreenSettings.dmFields = DM_BITSPERPEL Or DM_PELSWIDTH Or DM_PELSHEIGHT
    If VertRefresh <> -1 Then
        dmScreenSettings.dmDisplayFrequency = VertRefresh
        dmScreenSettings.dmFields = dmScreenSettings.dmFields Or DM_DISPLAYFREQUENCY
    End If
    ' Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
    If (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL) Then
    
        ' If The Mode Fails, Offer Two Options.  Quit Or Run In A Window.
        If (MsgBox("The Requested Mode Is Not Supported By" & vbCr & "Your Video Card. Use Windowed Mode Instead?", vbYesNo + vbExclamation, "NeHe GL") = vbYes) Then
            fullscreen = False                  ' Select Windowed Mode (Fullscreen=FALSE)
        Else
            ' Pop Up A Message Box Letting User Know The Program Is Closing.
            MsgBox "Program Will Now Close.", vbCritical, "ERROR"
            End                   ' Exit And Return FALSE
        End If
    End If
End Sub

Public Function CreateGLWindow(frm As Form, Width As Integer, Height As Integer, Bits As Integer, fullscreenflag As Boolean) As Boolean
    Dim PixelFormat As GLuint                       ' Holds The Results After Searching For A Match
    Dim pfd As PIXELFORMATDESCRIPTOR                ' pfd Tells Windows How We Want Things To Be


    fullscreen = fullscreenflag                     ' Set The Global Fullscreen Flag


    If (fullscreen) Then                            ' Attempt Fullscreen Mode?
        SetDisplayMode Width, Height, Bits, fullscreen
    End If
    
    If fullscreen Then
        HidePointer                                 ' Hide Mouse Pointer
        frm.WindowState = vbMaximized
    End If

    pfd.cColorBits = Bits
    pfd.cDepthBits = 16
    pfd.dwflags = PFD_DRAW_TO_WINDOW Or PFD_SUPPORT_OPENGL Or PFD_DOUBLEBUFFER Or PFD_TYPE_RGBA
    pfd.iLayerType = PFD_MAIN_PLANE
    pfd.iPixelType = PFD_TYPE_RGBA
    pfd.nSize = Len(pfd)
    pfd.nVersion = 1
    
    PixelFormat = ChoosePixelFormat(frm.hDC, pfd)
    If PixelFormat = 0 Then                     ' Did Windows Find A Matching Pixel Format?
        KillGLWindow                            ' Reset The Display
        MsgBox "Can't Find A Suitable PixelFormat.", vbExclamation, "ERROR"
        CreateGLWindow = False                  ' Return FALSE
    End If

    If SetPixelFormat(frm.hDC, PixelFormat, pfd) = 0 Then ' Are We Able To Set The Pixel Format?
        KillGLWindow                            ' Reset The Display
        MsgBox "Can't Set The PixelFormat.", vbExclamation, "ERROR"
        CreateGLWindow = False                           ' Return FALSE
    End If
    
    hrc = wglCreateContext(frm.hDC)
    If (hrc = 0) Then                           ' Are We Able To Get A Rendering Context?
        KillGLWindow                            ' Reset The Display
        MsgBox "Can't Create A GL Rendering Context.", vbExclamation, "ERROR"
        CreateGLWindow = False                  ' Return FALSE
    End If

    If wglMakeCurrent(frm.hDC, hrc) = 0 Then    ' Try To Activate The Rendering Context
        KillGLWindow                            ' Reset The Display
        MsgBox "Can't Activate The GL Rendering Context.", vbExclamation, "ERROR"
        CreateGLWindow = False                  ' Return FALSE
    End If
    frm.Show                                    ' Show The Window
    SetForegroundWindow frm.hWnd                ' Slightly Higher Priority
    frm.SetFocus                                ' Sets Keyboard Focus To The Window
    ReSizeGLScene frm.ScaleWidth, frm.ScaleHeight ' Set Up Our Perspective GL Screen

    If Not InitGL() Then                        ' Initialize Our Newly Created GL Window
        KillGLWindow                            ' Reset The Display
        MsgBox "Initialization Failed.", vbExclamation, "ERROR"
        CreateGLWindow = False                   ' Return FALSE
    End If
    BuildFont frm

    CreateGLWindow = True                       ' Success

End Function

Sub Main()
    Dim Done As Boolean
    Dim frm As Form
    Done = False
    SetupLightingArrays
    ' Ask The User Which Screen Mode They Prefer
    fullscreen = MsgBox("Would You Like To Run In Fullscreen Mode?", vbYesNo + vbQuestion, "Start FullScreen?") = vbYes
    
    ' Create Our OpenGL Window
    Set frm = New Form1
    If Not CreateGLWindow(frm, 800, 600, 16, fullscreen) Then
        Done = True                             ' Quit If Window Was Not Created
    End If

    Do While Not Done
        ' Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
        If (Not DrawGLScene Or Keys(vbKeyEscape)) Then  ' Updating View Only If Active
            Unload frm                          ' ESC or DrawGLScene Signalled A Quit
        Else                                    ' Not Time To Quit, Update Screen
            SwapBuffers (frm.hDC)               ' Swap Buffers (Double Buffering)
            If Keys(vbKeyL) And Not lp Then    ' L Key Being Pressed Not Held?
                lp = True                           ' lp Becomes TRUE
                light = Not light                   ' Toggle Light TRUE/FALSE
                If Not light Then                   ' If Not Light
                    glDisable glcLighting               ' Disable Lighting
                Else                                ' Otherwise
                    glEnable glcLighting                ' Enable Lighting
                End If
            End If
            If Not Keys(vbKeyL) Then                    ' Has L Key Been Released?
                lp = False                              ' If So, lp Becomes FALSE
            End If
            If Keys(vbKeyF) And Not fp Then                ' Is F Key Being Pressed?
                fp = True                               ' fp Becomes TRUE
                filter = filter + 1                     ' filter Value Increases By One
                If (filter > 2) Then                    ' Is Value Greater Than 2?
                    filter = 0                          ' If So, Set filter To 0
                End If
            End If
            If Not Keys(vbKeyF) Then                    ' Has F Key Been Released?
                fp = False                              ' If So, fp Becomes FALSE
            End If
                If Keys(vbKeyPageUp) Then               ' Is Page Up Being Pressed?
                    z = z - 0.02                        ' If So, Move Into The Screen
                End If
                If Keys(vbKeyPageDown) Then             ' Is Page Down Being Pressed?
                    z = z + 0.02                        ' If So, Move Towards The Viewer
                End If
                If Keys(vbKeyUp) Then                   ' Is Up Arrow Being Pressed?
                    xspeed = xspeed - 0.01              ' If So, Decrease xspeed
                End If
                If Keys(vbKeyDown) Then                 ' Is Down Arrow Being Pressed?
                    xspeed = xspeed + 0.01              ' If So, Increase xspeed
                End If
                If Keys(vbKeyRight) Then                ' Is Right Arrow Being Pressed?
                    yspeed = yspeed + 0.01              ' If So, Increase yspeed
                End If
                If Keys(vbKeyLeft) Then                 ' Is Left Arrow Being Pressed?
                    yspeed = yspeed - 0.01              ' If So, Decrease yspeed
                End If
            DoEvents
        End If

        If Keys(vbKeyF1) Then                   ' Is F1 Being Pressed?
            Keys(vbKeyF1) = False               ' If So Make Key FALSE
            Unload frm                          ' Kill Our Current Window
            Set frm = New Form1                 ' create a new one
            fullscreen = Not fullscreen         ' Toggle Fullscreen / Windowed Mode
            ' Recreate Our OpenGL Window
            If Not CreateGLWindow(frm, 800, 600, 16, fullscreen) Then
                Unload frm                      ' Quit If Window Was Not Created
            End If
        End If
        Done = frm.Visible = False              ' if the form is not visible then we are done
    Loop
    ' Shutdown
    Set frm = Nothing
    End
End Sub

