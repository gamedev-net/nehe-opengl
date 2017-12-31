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

Private hrc As Long
Private fullscreen As Boolean

Public base As GLuint         ' Base Display List For The Font Set
Public rot As GLfloat             ' Used To Rotate The Text      ( ADD )
Public gmf(256) As GLYPHMETRICSFLOAT   ' Storage For Information About Our Font



Private OldWidth As Long
Private OldHeight As Long
Private OldBits As Long
Private OldVertRefresh As Long

Private mPointerCount As Integer

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

Public Sub BuildFont(frm As Form)                    ' Build Our Bitmap Font
    Dim hfont As Long                       ' Windows Font ID

    base = glGenLists(256)                   ' Storage For 256 Characters
    hfont = CreateFont(-12, 0, 0, 0, FW_BOLD, False, False, False, _
            ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, _
            FF_DONTCARE Or DEFAULT_PITCH, "Comic Sans MS")
            

    SelectObject frm.hDC, hfont                ' Selects The Font We Created ( NEW )

    wglUseFontOutlines frm.hDC, 0, 255, base, 0#, 0.2, WGL_FONT_POLYGONS, gmf(0)

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
    glShadeModel smSmooth               ' Enables Smooth Shading

    glClearColor 0#, 0#, 0#, 0#         ' Black Background

    glClearDepth 1#                     ' Depth Buffer Setup
    glEnable glcDepthTest               ' Enables Depth Testing
    glDepthFunc cfLEqual                ' The Type Of Depth Test To Do

    glHint htPerspectiveCorrectionHint, hmNicest    ' Really Nice Perspective Calculations

    glEnable glcLight0                     ' Enable Default Light (Quick And Dirty)   ( NEW )
    glEnable glcLighting                   ' Enable Lighting              ( NEW )
    glEnable glcColorMaterial              ' Enable Coloring Of Material          ( NEW )


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

    KillFont                     ' Destroy The Font

    ' Note
    ' The form owns the device context (hDC) window handle (hWnd) and class (RTThundermain)
    ' so we do not have to do all the extra work

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

    pfd.cAccumAlphaBits = 0
    pfd.cAccumBits = 0
    pfd.cAccumBlueBits = 0
    pfd.cAccumGreenBits = 0
    pfd.cAccumRedBits = 0
    pfd.cAlphaBits = 0
    pfd.cAlphaShift = 0
    pfd.cAuxBuffers = 0
    pfd.cBlueBits = 0
    pfd.cBlueShift = 0
    pfd.cColorBits = Bits
    pfd.cDepthBits = 16
    pfd.cGreenBits = 0
    pfd.cGreenShift = 0
    pfd.cRedBits = 0
    pfd.cRedShift = 0
    pfd.cStencilBits = 0
    pfd.dwDamageMask = 0
    pfd.dwflags = PFD_DRAW_TO_WINDOW Or PFD_SUPPORT_OPENGL Or PFD_DOUBLEBUFFER
    pfd.dwLayerMask = 0
    pfd.dwVisibleMask = 0
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
            DoEvents
        End If

        If Keys(vbKeyF1) Then                   ' Is F1 Being Pressed?
            Keys(vbKeyF1) = False               ' If So Make Key FALSE
            Unload frm                          ' Kill Our Current Window
            Set frm = New Form1                 ' create a new one
            fullscreen = Not fullscreen         ' Toggle Fullscreen / Windowed Mode
            ' Recreate Our OpenGL Window
            If Not CreateGLWindow(frm, 640, 480, 16, fullscreen) Then
                Unload frm                      ' Quit If Window Was Not Created
            End If
        End If
        Done = frm.Visible = False              ' if the form is not visible then we are done
    Loop
    ' Shutdown
    Set frm = Nothing
    End
End Sub




