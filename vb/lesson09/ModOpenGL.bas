Attribute VB_Name = "modOpenGL"
'------------------------------------------------------------------------------
'
' modOpenGL.bas - Module containing OpenGL-related functions
'
' Written by Peter de Tagyos    ( pdetagyos@home.com )
'
' Translated from the code found on NeHe's OpenGL website.
' ( http://nehe.gamedev.net )
'
'------------------------------------------------------------------------------

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


'User-Defined Types -----------------------------------------------------------
Private Type typStar          'Holds the data describing a single star
  iR As Integer
  iG As Integer
  iB As Integer
  flDist As GLfloat
  flAngle As GLfloat
End Type


'OpenGL Constants -------------------------------------------------------------
Public Const GL_BITMAP As Integer = &H1A00


'Private Constants ------------------------------------------------------------
Private Const TEXTURE_FILE As String = "Data\Star.bmp"    'Bitmap filename
Private Const NUM_TEXTURES As Integer = 1                 'Number of textures used
Private Const NUM_STARS As Integer = 50                   'Number of stars to draw


'Global Variables -------------------------------------------------------------
Global giOldWidth As Integer
Global giOldHeight As Integer
Global giOldNumBits As Integer
Global giOldVRefresh As Integer

Global gaTextures() As Long     'Array to hold textures
Global gaStars() As typStar     'Array to hold stars

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
    frm.Caption = "NeHe's Animated Blended Textures Tutorial"
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
'Here's Where We Do All The Drawing
Dim iLoop As Integer

  glClear clrColorBufferBit Or clrDepthBufferBit    'Clear Screen And Depth Buffer
  glBindTexture glTexture2D, gaTextures(0)          'Select the texture
  
  'Loop through all the stars, drawing each in turn
  For iLoop = 0 To (NUM_STARS - 1)
    'Reset the view before we draw each star
    glLoadIdentity
    
    'Move the to position that we want to place the star
    glTranslatef 0#, 0#, gflZ                       'Zoom into the screen (using current Z)
    glRotatef gflTilt, 1#, 0#, 0#                   'Tilt the camera (using current tilt)
    glRotatef gaStars(iLoop).flAngle, 0#, 1#, 0#    'Tilt the camera specifically for this star
    glTranslatef gaStars(iLoop).flDist, 0#, 0#      'Move forward on the X plane for this star
    
    'Now cancel the rotations, so that the bitmap will face forward
    glRotatef -(gaStars(iLoop).flAngle), 0#, 1#, 0#   'Cancel the star tilt
    glRotatef -(gflTilt), 1#, 0#, 0#                  'Cancel the tilt
    
    'Perform special steps if Twinkle is toggled
    If (gbTwinkleOn) Then
      'Set the color for this star's twinkle
      glColor4ub gaStars(NUM_STARS - iLoop - 1).iR, _
        gaStars(NUM_STARS - iLoop - 1).iG, _
        gaStars(NUM_STARS - iLoop - 1).iB, _
        255
      'Draw the twinkle
      glBegin bmQuads
        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, 0#
        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, 0#
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, 0#
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, 0#
      glEnd
    End If
        
    glRotatef gflX, 0#, 0#, 1#          'Rotate the camera
    
    'Set the color for this star
    glColor4ub gaStars(iLoop).iR, _
      gaStars(iLoop).iG, _
      gaStars(iLoop).iB, _
      255
    
    'Draw the star
    glBegin bmQuads
      glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, 0#
      glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, 0#
      glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, 0#
      glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, 0#
    glEnd
    
    'Change settings for the next frame
    gflX = gflX + 0.01        'X spin
    gaStars(iLoop).flAngle = gaStars(iLoop).flAngle + CSng(iLoop) / CSng(NUM_STARS)  'Change Angle
    gaStars(iLoop).flDist = gaStars(iLoop).flDist - 0.01    'Move away from camera a bit
    If (gaStars(iLoop).flDist < 0#) Then
      '"Jumble" the star
      gaStars(iLoop).flDist = gaStars(iLoop).flDist + 5#    'Move towards the camera
      gaStars(iLoop).iR = Int(Rnd * 256)
      gaStars(iLoop).iG = Int(Rnd * 256)
      gaStars(iLoop).iB = Int(Rnd * 256)
    End If
  Next      'Star
  
  DrawGLScene = True        'Return success
  
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
  
  glHint htPerspectiveCorrectionHint, hmNicest    ' Really Nice Perspective Calculations

  glBlendFunc sfSrcAlpha, dfOne       'Set up blending
  glEnable glcBlend                   'And turn it on

  'Allocate memory for the stars array
  ReDim gaStars(NUM_STARS)

  'Set up the stars array with random settings for each star
  Dim iLoop As Integer
  For iLoop = 0 To (NUM_STARS - 1)
    gaStars(iLoop).flAngle = 0#
    gaStars(iLoop).flDist = (CSng(iLoop) / CSng(NUM_STARS)) * 5#
    gaStars(iLoop).iR = Int(Rnd * 256)
    gaStars(iLoop).iG = Int(Rnd * 256)
    gaStars(iLoop).iB = Int(Rnd * 256)
  Next    'Star
  
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
  ReDim gaTextures(NUM_TEXTURES)
  
  'Allocate space for three textures in OpenGL
  glGenTextures NUM_TEXTURES, gaTextures(0)

  'Create the Linear Filtered Texture
  glBindTexture glTexture2D, gaTextures(0)
  glTexParameteri glTexture2D, tpnTextureMagFilter, GL_LINEAR
  glTexParameteri glTexture2D, tpnTextureMinFilter, GL_LINEAR
  glTexImage2D glTexture2D, 0, 3, bmInfo.biWidth, bmInfo.biHeight, _
    0, tiBGRExt, GL_UNSIGNED_BYTE, baImageData(0)
  
  'Return success
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
