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

Private OldWidth As Long
Private OldHeight As Long
Private OldBits As Long
Private OldVertRefresh As Long
Public xrot As GLfloat                                  ' X Rotation ( NEW )
Public yrot As GLfloat                                  ' Y Rotation ( NEW )
Public zrot As GLfloat                                  ' Z Rotation ( NEW )

Public Texture(0) As GLuint                             ' Storage For One Texture ( NEW )
Private mPointerCount As Integer

Private Function LoadBMP(ByVal Filename As String, ByRef Texture() As GLuint, ByRef Height As Long, ByRef Width As Long) As Boolean
    Form1.Picture1.Picture = LoadPicture(Filename)  ' note the SacleMode of the picture control is set to 3 - Pixel
    CreateMapImage Form1.Picture1, Texture(), Height, Width ' Create a texture map array from the picture
    LoadBMP = True
End Function

Private Sub CreateMapImage(pict As PictureBox, ByRef TextureImg() As GLbyte, ByRef Height As Long, ByRef Width As Long)
    ' Create the array as needed for the image.
    pict.ScaleMode = 3                  ' Pixels
    Height = pict.ScaleHeight
    Width = pict.ScaleWidth
    
    ReDim TextureImg(2, Height - 1, Width - 1) ' size our texture array
    
    Dim X As Long
    Dim Y As Long
    Dim c As Long
    
    Dim yloc As Long
    For X = 0 To Width - 1                      ' loop through every pixel in the image
        For Y = 0 To Height - 1
            c = pict.Point(X, Y)                ' Returns in long format.
            yloc = Height - Y - 1               ' work out where we are in the Y
            TextureImg(0, X, yloc) = c And &HFF     ' get the lower 8 bits Red
            TextureImg(1, X, yloc) = (c \ 256) And &HFF   ' Get the middle 8 bits Green
            TextureImg(2, X, yloc) = (c \ 65536) And &HFF   'Get the top 8 bits Blue
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

    If LoadBMP("Data\NeHe.BMP", TextureImage(), h, w) Then
        ' Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
        Status = True                          ' Set The Status To TRUE

        glGenTextures 1, Texture(0)                 ' Create The Texture

        ' Typical Texture Generation Using Data From The Bitmap
        glBindTexture glTexture2D, Texture(0)

        ' Generate The Texture
        glTexImage2D glTexture2D, 0, 3, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage(0, 0, 0)
        glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR     ' Linear Filtering
        glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR     ' Linear Filtering
    End If

    Erase TextureImage   ' Free the texture image memory
    LoadGLTextures = Status
End Function



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

    glClearColor 0#, 0#, 0#, 0#         ' Black Background

    glClearDepth 1#                     ' Depth Buffer Setup
    glEnable glcDepthTest               ' Enables Depth Testing
    glDepthFunc cfLEqual                ' The Type Of Depth Test To Do

    glHint htPerspectiveCorrectionHint, hmNicest    ' Really Nice Perspective Calculations

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
    Dim I As Long
    Dim dm As DEVMODE
    I = 0
    Do  ' enumerate the display settings until we find the one we want
        ret = EnumDisplaySettings(0&, I, dm)
        If dm.dmPelsWidth = Width And _
            dm.dmPelsHeight = Height And _
            dm.dmBitsPerPel = Bits And _
            ((dm.dmDisplayFrequency = VertRefresh) Or (VertRefresh = -1)) Then Exit Do ' exit when we have a match
        I = I + 1
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

    CreateGLWindow = True                       ' Success

End Function

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    glClear clrColorBufferBit Or clrDepthBufferBit            ' Clear Screen And Depth Buffer
    glLoadIdentity                            ' Reset The Current Matrix
    glTranslatef 0#, 0#, -5#                          ' Move Into The Screen 5 Units
    glRotatef xrot, 1#, 0#, 0#                        ' Rotate On The X Axis
    glRotatef yrot, 0#, 1#, 0#                        ' Rotate On The Y Axis
    glRotatef zrot, 0#, 0#, 1#                        ' Rotate On The Z Axis

    glBindTexture GL_TEXTURE_2D, Texture(0)           ' Select Our Texture

    glBegin GL_QUADS
        ' Front Face
        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, 1#               ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, 1#              ' Top Left Of The Texture and Quad
        ' Back Face
        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, -1#            ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, -1#             ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, -1#              ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, -1#             ' Bottom Left Of The Texture and Quad
        ' Top Face
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#             ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f -1#, 1#, 1#              ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f 1#, 1#, 1#               ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#              ' Top Right Of The Texture and Quad
        ' Bottom Face
        glTexCoord2f 1#, 1#: glVertex3f -1#, -1#, -1#            ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f 1#, -1#, -1#             ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Right Of The Texture and Quad
        ' Right face
        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, -1#             ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#              ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, 1#               ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Left Of The Texture and Quad
        ' Left Face
        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, -1#            ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, 1#              ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#             ' Top Left Of The Texture and Quad
    glEnd

    xrot = xrot + 0.3                             ' X Axis Rotation
    yrot = yrot + 0.2                             ' Y Axis Rotation
    zrot = zrot + 0.4                             ' Z Axis Rotation
    DrawGLScene = True                                 ' Keep Going

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

