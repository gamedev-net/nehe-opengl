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

Global gbKeys(256) As Boolean       'Indicates which keys are currently pressed

Global gbTwinkleOn As Boolean       'Should the stars twinkle?
Global gflX As GLfloat              'Current X position of stars
Global gflTilt As GLfloat           'Current "tilt" of the camera
Global gflZ As GLfloat              'Current Z position of camera


'Global Routines --------------------------------------------------------------

Sub Main()
'Program Entry Point
Dim bFullscreen As Boolean
Dim bDone As Boolean
Dim frm As frmMain
Dim bTwinkleSwitched As Boolean

  bFullscreen = False
  bDone = False
  bTwinkleSwitched = False
  gflTilt = 90#
  gflX = 0#
  gflZ = -15#               'Start pretty far away from the stars
  
  'Enable random number generator
  Randomize
  
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
      'T - pressed
      If (gbKeys(vbKeyT) = True) And (bTwinkleSwitched = False) Then
        'Toggle the twinkle
        gbTwinkleOn = Not gbTwinkleOn
        
        'Indicate that we have toggled the twinkle
        bTwinkleSwitched = True
      End If
      
      'T - released
      If (gbKeys(vbKeyT) = False) Then
        'Clear the toggle flag
        bTwinkleSwitched = False
      End If
      
      'Up - pressed
      If (gbKeys(vbKeyUp) = True) Then
        'Decrease the tilt
        gflTilt = gflTilt - 0.5
      End If
      
      'Down - pressed
      If (gbKeys(vbKeyDown) = True) Then
        'Increase the tilt
        gflTilt = gflTilt + 0.5
      End If
      
      'PgUp - pressed
      If (gbKeys(vbKeyPageUp) = True) Then
        'Move the camera away from the stars
        gflZ = gflZ - 0.2
      End If
      
      'PgDown - pressed
      If (gbKeys(vbKeyPageDown) = True) Then
        'Move the camera towards the stars
        gflZ = gflZ + 0.2
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
