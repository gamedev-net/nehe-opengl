Attribute VB_Name = "modMain"
'------------------------------------------------------------------------------
'
' modMain.bas - Main module for application
'
' Written by Peter de Tagyos    ( pdetagyos@home.com )
'
' Translated from code found on NeHe's OpenGL website.
' ( http://nehe.gamedev.net )
'
'------------------------------------------------------------------------------

Option Explicit

'Global Variables -------------------------------------------------------------
'Display settings
Global giOldWidth As Integer
Global giOldHeight As Integer
Global giOldNumBits As Integer
Global giOldVRefresh As Integer

Global gbKeys(256) As Boolean       'Indicates which keys are currently pressed

Global gaTextures() As Long         'Array to hold textures
Global gaFogMode() As GLuint        'Modes that the fog can be in
Global gaFogColor() As GLfloat      'Color of the fog

Global giCurrFilter As Integer      'Currently selected filter
Global giCurrFogFilter As Integer   'Currently selected fog filter
Global gflXRot As GLfloat           'X rotation
Global gflYRot As GLfloat           'Y rotation
Global gflXSpeed As GLfloat         'X rotation speed
Global gflYSpeed As GLfloat         'Y rotation speed
Global gflZ As GLfloat              'Z position


'Global Routines --------------------------------------------------------------

Sub Main()
'Program Entry Point
Dim bFullscreen As Boolean
Dim bDone As Boolean
Dim frm As frmMain
Dim bLightSwitched As Boolean
Dim bFilterSwitched As Boolean
Dim bFogSwitched As Boolean
Dim bLightOn As Boolean

  bFullscreen = False
  bDone = False
  bLightSwitched = False
  bFilterSwitched = False
  bFogSwitched = False
  bLightOn = False
  giCurrFilter = 0
  gflZ = -5#          'Start the cube far enough away from the camera
  
  'Determine if the user wants to run fullscreen or not
  If (MsgBox("Would you like to run in Fullscreen Mode?", vbYesNo, _
    "Start Fullscreen?") = vbYes) Then
    bFullscreen = True
  End If

  'Save the current display settings so that we can restore them later
  SaveDisplaySettings

  'Create the main window and attach OpenGL to it
  Set frm = New frmMain
  If (CreateGLWindow(frm, 640, 480, 16, bFullscreen) = False) Then
    bDone = True
  End If
  
  'Keep looping until it is time to quit the application
  While Not bDone
    'Let Windows process events
    DoEvents
  
    'Check for a quit from DrawGLScene or the user
    If (DrawGLScene() = False) Or (gbKeys(vbKeyEscape)) Then
      'Quit the app
      bDone = True
    Else
      'We're not quitting, so update the screen and process events
      SwapBuffers frm.hDC
      
      'Let Windows process events
      DoEvents
      
      'Handle various keypresses
      'L - press
      If (gbKeys(vbKeyL) = True) And (bLightSwitched = False) Then
        'Toggle the light
        bLightOn = Not (bLightOn)
      
        'Change the OpenGL settings based on the new value
        If (bLightOn) Then
          glEnable glcLighting
        Else
          glDisable glcLighting
        End If
        
        'Indicate that we have toggled the light
        bLightSwitched = True
      End If
      
      'L - release
      If (gbKeys(vbKeyL) = False) Then
        'Clear the toggle flag
        bLightSwitched = False
      End If
      
      'F - pressed
      If (gbKeys(vbKeyF) = True) And (bFilterSwitched = False) Then
        'Toggle the filter
        giCurrFilter = giCurrFilter + 1
        'If we have passed the last filter, then go back to first one
        If giCurrFilter > 2 Then giCurrFilter = 0
        
        'Indicate that we have toggled the filter
        bFilterSwitched = True
      End If
      
      'F - released
      If (gbKeys(vbKeyF) = False) Then
        'Clear the toggle flag
        bFilterSwitched = False
      End If
      
      'G - pressed
      If (gbKeys(vbKeyG) = True) And (bFogSwitched = False) Then
        'Toggle the fog filter
        giCurrFogFilter = giCurrFogFilter + 1
        'If we have passed the last filter, then go back to first one
        If giCurrFogFilter > 2 Then giCurrFogFilter = 0
        
        'Set the new fog mode
        glFogi fogMode, gaFogMode(giCurrFogFilter)
        
        'Indicate that we have toggled the fog filter
        bFogSwitched = True
      End If
      
      'G - released
      If (gbKeys(vbKeyG) = False) Then
        'Clear the toggle flag
        bFogSwitched = False
      End If
      
      'PgUp - pressed
      If (gbKeys(vbKeyPageUp) = True) Then
        gflZ = gflZ - 0.02
      End If
      
      'PgDown - pressed
      If (gbKeys(vbKeyPageDown) = True) Then
        gflZ = gflZ + 0.02
      End If
      
      'Up - pressed
      If (gbKeys(vbKeyUp) = True) Then
        gflXSpeed = gflXSpeed - 0.01
      End If
      
      'Down - pressed
      If (gbKeys(vbKeyDown) = True) Then
        gflXSpeed = gflXSpeed + 0.01
      End If
      
      'Left - pressed
      If (gbKeys(vbKeyLeft) = True) Then
        gflYSpeed = gflYSpeed - 0.01
      End If
      
      'Right - pressed
      If (gbKeys(vbKeyRight) = True) Then
        gflYSpeed = gflYSpeed + 0.01
      End If
      
      'F1 - pressed
      If (gbKeys(vbKeyF1)) Then
        'User is pressing F1, so change modes
        gbKeys(vbKeyF1) = False         'reset key map
        
        'Destroy current window
        Unload frm      'This will implicitly call KillGLWindow()
        Set frm = Nothing
        
        'Swap Modes
        bFullscreen = Not bFullscreen
        
        'Create new window using new mode
        Set frm = New frmMain
        If (CreateGLWindow(frm, 640, 480, 16, bFullscreen) = False) Then
          bDone = True
        End If
      End If  'F1 Pressed
    End If  'Quit?
  Wend

  'Clean up and exit
  Unload frm            'This will implicitly call KillGLWindow()
  Set frm = Nothing

End Sub
