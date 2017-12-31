Attribute VB_Name = "modOpenGL"
'modOpenGL - Module containing OpenGL Helper functions

Option Explicit


'API Types --------------------------------------------------------------------
Private Type BITMAP           '14 bytes
  bmType As Long
  bmWidth As Long
  bmHeight As Long
  bmWidthBytes As Long
  bmPlanes As Long
  bmBitsPixel As Long
  bmBits As Long
End Type

Public Type BITMAPINFOHEADER  '40 bytes
  biSize As Long
  biWidth As Long
  biHeight As Long
  biPlanes As Integer
  biBitCount As Integer
  biCompression As Long
  biSizeImage As Long
  biXPelsPerMeter As Long
  biYPelsPerMeter As Long
  biClrUsed As Long
  biClrImportant As Long
End Type

Public Type RGBQUAD           '4 bytes
  rgbBlue As Byte
  rgbGreen As Byte
  rgbRed As Byte
  rgbReserved As Byte
End Type


'OpenGL Constants -------------------------------------------------------------
Public Const GL_BITMAP As Integer = &H1A00


'Private Constants ------------------------------------------------------------
Private Const TEXTURE_FILE As String = "Data\Glass.bmp"


'Global Variables -------------------------------------------------------------
Global giOldWidth As Integer
Global giOldHeight As Integer
Global giOldNumBits As Integer
Global giOldVRefresh As Integer

Global gaTextures() As Long     'Array to hold textures


'Local Variables --------------------------------------------------------------
Private hRC As Long       'Handle to the Rendering Context


'Global Routines --------------------------------------------------------------

Public Function CreateGLWindow(frm As Form, iWidth As Integer, _
  iHeight As Integer, iNumBits As Integer, bFullscreen As Boolean) As Boolean
'Attach OpenGL to the given window
Dim bRet As Boolean
Dim pfd As PIXELFORMATDESCRIPTOR
Dim lPixelFormat As Long
Dim lRet As Long

  'If user desires fullscreen mode, then change the display settings
  If (bFullscreen = True) Then
    bRet = SetFullscreenMode(iWidth, iHeight, iNumBits)
    If (bRet = False) Then
      'Could not set fullscreen mode
      MsgBox "Could not set fullscreen mode.  App will continue in windowed mode."
    End If
    
    'Remove all window decorations from the window
    frm.Caption = ""
    
    'Hide the mouse cursor for FS mode
    ShowCursor False
    
    'Maximize the window
    frm.WindowState = vbMaximized
  Else
    'Not fullscreen, so set the window up
    frm.Caption = "NeHe's Blending Tutorial"
  End If
  
  'Set up the Pixel Format that we wish to request
  pfd.nVersion = 1
  pfd.dwFlags = PFD_DRAW_TO_WINDOW Or PFD_SUPPORT_OPENGL Or PFD_DOUBLEBUFFER
  pfd.iLayerType = PFD_MAIN_PLANE
  pfd.iPixelType = PFD_TYPE_RGBA
  pfd.cColorBits = iNumBits
  pfd.cDepthBits = 16
  pfd.nSize = Len(pfd)
  
  'Request the desired pixel format
  lPixelFormat = ChoosePixelFormat(frm.hDC, pfd)
  If (lPixelFormat = 0) Then
    'Failed to get desired pixel format, so bail out
    MsgBox "Could not get desired Pixel Format"
    CreateGLWindow = False
    Exit Function
  End If
  
  'If we found a desirable pixel format, then set it
  lRet = SetPixelFormat(frm.hDC, lPixelFormat, pfd)
  If (lRet = 0) Then
    'Failed to set pixel format, so bail out
    MsgBox "Could not set desired Pixel Format"
    CreateGLWindow = False
    Exit Function
  End If
  
  'OK, now try to get a handle to the Rendering Context
  hRC = wglCreateContext(frm.hDC)
  If (hRC = 0) Then
    'Failed to create rendering context, so bail out
    MsgBox "Could not create the rendering context"
    CreateGLWindow = False
    Exit Function
  End If
  
  'Now that we have done all this, we need to activate the RC
  lRet = wglMakeCurrent(frm.hDC, hRC)
  If (lRet = 0) Then
    'Failed to activate the RC, so bail out
    MsgBox "Could not activate the RC"
    CreateGLWindow = False
    Exit Function
  End If
  
  'Finally, show the window and move it to the foreground
  frm.Show
  SetForegroundWindow frm.hWnd
  SetFocus frm.hWnd
  
  'Size the GL window appropriately
  frm.ScaleMode = 3        'ScaleMode = Pixel
  ReSizeGLScene frm.ScaleWidth, frm.ScaleHeight
  
  'And last but not least, we need to initialize OpenGL.
  bRet = InitGL()
  If (bRet = False) Then
    'Could not initialize OpenGL, so bail out
    MsgBox "Could not initialize OpenGL."
    CreateGLWindow = False
    Exit Function
  End If
  
  'Whew!  Return success
  CreateGLWindow = True
  
End Function


Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
Static xrot As GLfloat
Static yrot As GLfloat
Static zrot As GLfloat

  glClear clrColorBufferBit Or clrDepthBufferBit            ' Clear Screen And Depth Buffer
  glLoadIdentity                ' Reset The Current Matrix
  
  'Perform transformations on the cube since last time it was drawn
  glTranslatef 0#, 0#, gflZ     ' Position the cube WRT the current Z setting
  glRotatef xrot, 1#, 0#, 0#    ' Rotate On The X Axis
  glRotatef yrot, 0#, 1#, 0#    ' Rotate On The Y Axis

  'Set the texture to our current selection
  glBindTexture glTexture2D, gaTextures(giCurrFilter)           ' Select Our Texture

  glBegin GL_QUADS
    ' Front Face
    glNormal3f 0#, 0#, 1#                              'Set the surface normal
    glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, 1#       'Bottom Left Of The Texture and Quad
    glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, 1#        'Bottom Right Of The Texture and Quad
    glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, 1#         'Top Right Of The Texture and Quad
    glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, 1#        'Top Left Of The Texture and Quad
    ' Back Face
    glNormal3f 0#, 0#, -1#                             'Set the surface normal
    glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, -1#      'Bottom Right Of The Texture and Quad
    glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, -1#       'Top Right Of The Texture and Quad
    glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, -1#        'Top Left Of The Texture and Quad
    glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, -1#       'Bottom Left Of The Texture and Quad
    ' Top Face
    glNormal3f 0#, 1#, 0#                              'Set the surface normal
    glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#       'Top Left Of The Texture and Quad
    glTexCoord2f 0#, 0#: glVertex3f -1#, 1#, 1#        'Bottom Left Of The Texture and Quad
    glTexCoord2f 1#, 0#: glVertex3f 1#, 1#, 1#         'Bottom Right Of The Texture and Quad
    glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#        'Top Right Of The Texture and Quad
    ' Bottom Face
    glNormal3f 0#, -1#, 0#                             'Set the surface normal
    glTexCoord2f 1#, 1#: glVertex3f -1#, -1#, -1#      'Top Right Of The Texture and Quad
    glTexCoord2f 0#, 1#: glVertex3f 1#, -1#, -1#       'Top Left Of The Texture and Quad
    glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#        'Bottom Left Of The Texture and Quad
    glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#       'Bottom Right Of The Texture and Quad
    ' Right face
    glNormal3f 1#, 0#, 0#                              'Set the surface normal
    glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, -1#       'Bottom Right Of The Texture and Quad
    glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#        'Top Right Of The Texture and Quad
    glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, 1#         'Top Left Of The Texture and Quad
    glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#        'Bottom Left Of The Texture and Quad
    ' Left Face
    glNormal3f -1#, 0#, 0#                             'Set the surface normal
    glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, -1#      'Bottom Left Of The Texture and Quad
    glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#       'Bottom Right Of The Texture and Quad
    glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, 1#        'Top Right Of The Texture and Quad
    glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#       'Top Left Of The Texture and Quad
  glEnd

  'Update the rotation data for the next frame
  xrot = xrot + gflXSpeed   ' X Axis Rotation
  yrot = yrot + gflYSpeed   ' Y Axis Rotation
  
  DrawGLScene = True        ' Keep Going
  
End Function


Public Function InitGL() As Boolean
' All Setup For OpenGL Goes Here

  'Load the texture(s)
  If Not LoadGLTextures() Then
    InitGL = False
    Exit Function
  End If

  glEnable glcTexture2D               ' Enable Texture Mapping
  glShadeModel smSmooth               ' Enables Smooth Shading

  glClearColor 0#, 0#, 0#, 0.5        ' Black Background
  glClearDepth 1#                     ' Depth Buffer Setup
  
  glEnable glcDepthTest               ' Enables Depth Testing
  glDepthFunc cfLEqual                ' The Type Of Depth Test To Do
  glHint htPerspectiveCorrectionHint, hmNicest    ' Really Nice Perspective Calculations

  'Set the light settings
  Dim aflLightAmbient(4) As GLfloat
  Dim aflLightDiffuse(4) As GLfloat
  Dim aflLightPosition(4) As GLfloat
  
  'Ambient settings
  aflLightAmbient(0) = 0.5
  aflLightAmbient(1) = 0.5
  aflLightAmbient(2) = 0.5
  aflLightAmbient(3) = 1#
  'Diffuse settings
  aflLightDiffuse(0) = 1#
  aflLightDiffuse(1) = 1#
  aflLightDiffuse(2) = 1#
  aflLightDiffuse(3) = 1#
  'Position settings
  aflLightPosition(0) = 0#
  aflLightPosition(1) = 0#
  aflLightPosition(2) = 2#
  aflLightPosition(3) = 1#
  
  'Now set up the light in OpenGL
  glLightfv ltLight1, lpmAmbient, aflLightAmbient(0)
  glLightfv ltLight1, lpmDiffuse, aflLightDiffuse(0)
  glLightfv ltLight1, lpmPosition, aflLightPosition(0)

  'And enable the light
  glEnable glcLight1

  'Set up blending.   '(NEW)
  glColor4f 1#, 1#, 1#, 0.5       'Full color, 50% transparent
  glBlendFunc sfSrcAlpha, dfOne   'Set the blending function for translucency

  'Initialization Went OK
  InitGL = True
End Function

Public Sub KillGLWindow(frm As Form)
'Properly Kill The Window and unattach OpenGL
Dim lRet As Long

  'If we are in fullscreen display mode, then we need to restore the orignal mode
  If (frm.Caption = "") Then
    RestoreDisplayMode
    ShowCursor True
  End If

  'If we have a rendering context, then attempt to release it
  If hRC Then
    'Release the RC
    lRet = wglMakeCurrent(0, 0)
    If (lRet = 0) Then
      'Couldn't release the RC
      MsgBox "Release Of DC And RC Failed."
    End If

    'Free the RC
    lRet = wglDeleteContext(hRC)
    If (lRet = 0) Then
      MsgBox "Release Rendering Context Failed."
    End If
    
    'Clear the handle
    hRC = 0
  End If

End Sub

Public Function LoadGLTextures() As Boolean
'Load up desired bitmaps and convert them into textures
'that can be used by OpenGL

Dim sFile As String
Dim bmFile As BITMAPFILEHEADER
Dim bmInfo As BITMAPINFOHEADER
Dim bmRGB() As RGBQUAD
Dim iFile As Integer
Dim lImageSize As Long
Dim iPixelSize As Integer
Dim baImageData() As Byte

  On Error GoTo ERR_H

  'Set the filename
  sFile = App.Path & "\" & TEXTURE_FILE
  
  iFile = FreeFile
  
  Open sFile For Binary As iFile
  
  'Read in the headers
  Get #iFile, , bmFile
  Get #iFile, , bmInfo
  
  'Determine how many colors are used
  If (bmInfo.biBitCount < 24) Then
    'Less than 24 bits per pixel are used, so allocate space for the color table
    ReDim bmRGB(bmInfo.biClrUsed)
    
    'Read in the color table
    Get #iFile, , bmRGB
  End If
  
  'Determine how big the image is
  iPixelSize = bmInfo.biBitCount / 8
  
  lImageSize = bmInfo.biWidth * bmInfo.biHeight * iPixelSize
  
  ReDim baImageData(lImageSize)
  
  'Read in the image data
  Get #iFile, , baImageData
  
  Close #iFile
  
  'Allocate space for the texture "ptr" in the array
  ReDim gaTextures(3)
  
  'Allocate space for three textures in OpenGL
  glGenTextures 3, gaTextures(0)

  'Create the Nearest Filtered Texture
  glBindTexture glTexture2D, gaTextures(0)
  glTexParameteri glTexture2D, tpnTextureMagFilter, GL_NEAREST
  glTexParameteri glTexture2D, tpnTextureMinFilter, GL_NEAREST
  glTexImage2D glTexture2D, 0, 3, bmInfo.biWidth, bmInfo.biHeight, _
    0, tiBGRExt, GL_UNSIGNED_BYTE, baImageData(0)
  
  'Create the Linear Filtered Texture
  glBindTexture glTexture2D, gaTextures(1)
  glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
  glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR
  glTexImage2D glTexture2D, 0, 3, bmInfo.biWidth, bmInfo.biHeight, _
    0, tiBGRExt, GL_UNSIGNED_BYTE, baImageData(0)
  
  'Create the Mipmapped Texture
  glBindTexture glTexture2D, gaTextures(2)
  glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
  glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR_MIPMAP_NEAREST
  gluBuild2DMipmaps glTexture2D, 3, bmInfo.biWidth, bmInfo.biHeight, tiBGRExt, _
    GL_UNSIGNED_BYTE, ByVal VarPtr(baImageData(0))
  
  'Whew!  Return success if we got this far
  LoadGLTextures = True

EXIT_H:
  Erase baImageData   'since the textures are already created, free the bitmap data
  Exit Function
  
ERR_H:
  MsgBox Err.Description
  LoadGLTextures = False
  Resume EXIT_H
End Function

Public Sub ReSizeGLScene(ByVal Width As GLsizei, ByVal Height As GLsizei)
' Resize And Initialize The GL Window
  
  'Prevent a divide by zero error by making the height 1
  If Height = 0 Then
      Height = 1
  End If
  
  'Reset The Current Viewport
  glViewport 0, 0, Width, Height
  
  'Select The Projection Matrix and reset it
  glMatrixMode mmProjection
  glLoadIdentity

  'Calculate The Aspect Ratio Of The Window
  gluPerspective 45#, Width / Height, 0.1, 100#

  'Select The Modelview Matrix and reset it
  glMatrixMode mmModelView
  glLoadIdentity
End Sub

Private Sub RestoreDisplayMode()
'Restore the display mode the computer was in before the app started
Dim dmDisplaySettings As DEVMODE
Dim lRet As Long

  'Set up the Device Mode structure
  dmDisplaySettings.dmPelsWidth = giOldWidth
  dmDisplaySettings.dmPelsHeight = giOldHeight
  dmDisplaySettings.dmBitsPerPel = giOldNumBits
  dmDisplaySettings.dmDisplayFrequency = giOldVRefresh
  dmDisplaySettings.dmFields = DM_PELSWIDTH Or DM_PELSHEIGHT Or _
    DM_BITSPERPEL Or DM_DISPLAYFREQUENCY
  dmDisplaySettings.dmSize = Len(dmDisplaySettings)
  
  'Attempt to change the display mode back
  lRet = ChangeDisplaySettings(dmDisplaySettings, 0)
  If (lRet <> DISP_CHANGE_SUCCESSFUL) Then
    'If the restore fails, just bail
    MsgBox "Display restore failed."
  End If

End Sub

Public Sub SaveDisplaySettings()
'Save the current display settings so that they can be restored at a later time
Dim hRet As Long
Dim dm As DEVMODE

  'Grab a handle to an information context for the display device
  hRet = CreateIC("DISPLAY", "", "", dm)
  
  'Grab the current settings and store them
  giOldWidth = GetDeviceCaps(hRet, HORZRES)
  giOldHeight = GetDeviceCaps(hRet, VERTRES)
  giOldNumBits = GetDeviceCaps(hRet, BITSPIXEL)
  giOldVRefresh = GetDeviceCaps(hRet, VREFRESH)
  
  'Release the IC
  DeleteDC hRet

End Sub

Public Function SetFullscreenMode(iWidth As Integer, _
  iHeight As Integer, iNumBits As Integer) As Boolean
'Set the display mode to fullscreen with the given resolution
Dim bSuccess As Boolean
Dim dmDisplaySettings As DEVMODE
Dim lRet As Long

  bSuccess = False
  
  'Set up the Device Mode structure
  dmDisplaySettings.dmPelsWidth = iWidth
  dmDisplaySettings.dmPelsHeight = iHeight
  dmDisplaySettings.dmBitsPerPel = iNumBits
  dmDisplaySettings.dmFields = DM_PELSWIDTH Or DM_PELSHEIGHT Or DM_BITSPERPEL
  dmDisplaySettings.dmSize = Len(dmDisplaySettings)
  
  'Attempt to change to Fullscreen mode
  lRet = ChangeDisplaySettings(dmDisplaySettings, CDS_FULLSCREEN)
  If (lRet <> DISP_CHANGE_SUCCESSFUL) Then
    'We failed to change the mode
    bSuccess = False
  Else
    'Return success
    bSuccess = True
  End If
  
  SetFullscreenMode = bSuccess
End Function
