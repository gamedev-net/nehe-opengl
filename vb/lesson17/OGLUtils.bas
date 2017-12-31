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


Public base As GLuint         ' Base Display List For The Font Set
Public mloop As GLuint          ' Generic Loop Variable

Public cnt1 As GLfloat            ' 1st Counter Used To Move Text & For Coloring
Public cnt2 As GLfloat           ' 2nd Counter Used To Move Text & For Coloring


Public Texture(1) As GLuint                             ' Storage For two Textures





Private OldWidth As Long
Private OldHeight As Long
Private OldBits As Long
Private OldVertRefresh As Long
Private mPointerCount As Integer



Public Sub BuildFont()                  '
    Dim cx As Double                             ' Holds Our X Character Coord
    Dim cy As Double                             ' Holds Our Y Character Coord
    Dim i As Integer
    base = glGenLists(256)                         ' Creating 256 Display Lists
    glBindTexture glTexture2D, Texture(0)                ' Select Our Font Texture

    For i = 0 To 255                      ' Loop Through All 256 Lists
  
        cx = (i Mod 16) / 16#                   ' X Position Of Current Character
        ' note the integer divide below
        cy = (i \ 16) / 16#                ' Y Position Of Current Character

        glNewList base + i, lstCompile              ' Start Building A List

            glBegin bmQuads                   ' Use A Quad For Each Character

                glTexCoord2f cx, 1 - cy - 0.0625      ' Texture Coord (Bottom Left)
                glVertex2i 0, 0               ' Vertex Coord (Bottom Left)

                glTexCoord2f cx + 0.0625, 1 - cy - 0.0625 ' Texture Coord (Bottom Right)
                glVertex2i 16, 0             ' Vertex Coord (Bottom Right)

                glTexCoord2f cx + 0.0625, 1 - cy      ' Texture Coord (Top Right)
                glVertex2i 16, 16             ' Vertex Coord (Top Right)

                glTexCoord2f cx, 1 - cy           ' Texture Coord (Top Left)
                glVertex2i 0, 16              ' Vertex Coord (Top Left)
            glEnd                        ' Done Building Our Quad (Character)

            glTranslated 10, 0, 0                 ' Move To The Right Of The Character
        glEndList                            ' Done Building The Display List
    Next i                                   ' Loop Until All 256 Are Built

End Sub

Private Sub KillFont()                     ' Delete The Font
    glDeleteLists base, 256                ' Delete All 256 Characters
End Sub

Public Sub glPrint(x As GLint, y As GLint, s As String, sset As Integer)
' Where The Printing Happens
    If (sset > 1) Then                            ' Is set Greater Than One?
        sset = 1                            ' If So, Make Set Equal One
    End If
    glBindTexture GL_TEXTURE_2D, Texture(0)               ' Select Our Font Texture

    glDisable GL_DEPTH_TEST                        ' Disables Depth Testing

    glMatrixMode GL_PROJECTION                        ' Select The Projection Matrix
    glPushMatrix                             ' Store The Projection Matrix

    glLoadIdentity                           ' Reset The Projection Matrix
    glOrtho 0, 640, 0, 480, -1, 1                     ' Set Up An Ortho Screen

    glMatrixMode GL_MODELVIEW                     ' Select The Modelview Matrix
    glPushMatrix                             ' Store The Modelview Matrix
    glLoadIdentity                           ' Reset The Modelview Matrix

    glTranslated x, y, 0                          ' Position The Text (0,0 - Bottom Left)

    glListBase base - 32 + 128 * sset                ' Choose The Font Set (0 or 1)

    Dim b() As Byte
    Dim i As Integer
    Dim length As Double
    ReDim b(Len(s))             ' array of bytes to hold the string
    For i = 1 To Len(s)         ' for each character
        b(i - 1) = Asc(Mid$(s, i, 1)) ' convert from unicode to ascii
    Next
    b(Len(s)) = 0               ' null terminated
    glCallLists Len(s), GL_BYTE, b(0)            ' Write The Text To The Screen

    glMatrixMode GL_PROJECTION                        ' Select The Projection Matrix
    glPopMatrix                              ' Restore The Old Projection Matrix

    glMatrixMode GL_MODELVIEW                     ' Select The Modelview Matrix
    glPopMatrix                              ' Restore The Old Projection Matrix

    glEnable GL_DEPTH_TEST                        ' Enables Depth Testing

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
    
    Dim x As Long, y As Long
    Dim c As Long
    
    Dim yloc As Long
    For x = 0 To Width - 1
        For y = 0 To Height - 1
            c = pict.Point(x, y)                ' Returns in long format.
            yloc = Height - y - 1
            TextureImg(0, x, yloc) = c And 255
            TextureImg(1, x, yloc) = (c And 65280) \ 256
            TextureImg(2, x, yloc) = (c And 16711680) \ 65536
        Next y
    Next x
    
End Sub

Private Function LoadGLTextures() As Boolean
' Load Bitmaps And Convert To Textures
    Dim Status As Boolean
    Dim h1 As Long
    Dim w1 As Long
    Dim h2 As Long
    Dim w2 As Long
    Dim TextureImage1() As GLbyte
    Dim TextureImage2() As GLbyte
    Status = False                         ' Status Indicator

    If LoadBMP("Data\Font.BMP", TextureImage1(), h1, w1) Then
        If LoadBMP("Data\Bumps.BMP", TextureImage2(), h2, w2) Then
            ' Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
            Status = True                          ' Set The Status To TRUE
    
            glGenTextures 2, Texture(0)            ' Create The Textures
    
            ' Build All The Textures
            glBindTexture glTexture2D, Texture(0)
            glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
            glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR
            glTexImage2D glTexture2D, 0, 3, w1, h1, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage1(0, 0, 0)
    
            glBindTexture glTexture2D, Texture(1)
            glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
            glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR
            glTexImage2D glTexture2D, 0, 3, w2, h2, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage2(0, 0, 0)
        End If

    End If

    Erase TextureImage1   ' Free the texture image memory
    Erase TextureImage2   ' Free the texture image memory
    
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
    BuildFont
    glClearColor 0#, 0#, 0#, 0#                             ' Clear The Background Color To Black
    glClearDepth 1#                           ' Enables Clearing Of The Depth Buffer
    glDepthFunc cfLEqual                          ' The Type Of Depth Test To Do
    glBlendFunc sfSrcAlpha, dfOne                   ' Select The Type Of Blending
    glShadeModel smSmooth                         ' Enables Smooth Color Shading
    glEnable glcTexture2D                         ' Enable 2D Texture Mapping

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
    BuildFont

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
    If Not CreateGLWindow(frm, 640, 480, 16, fullscreen) Then
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

