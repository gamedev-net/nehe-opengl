Attribute VB_Name = "modMain"
Option Explicit

'Global Variables -------------------------------------------------------------

Global gbKeys(256) As Boolean       'Indicates which keys are currently pressed


'Global Routines --------------------------------------------------------------

Sub Main()
'Program Entry Point
Dim bFullscreen As Boolean
Dim bDone As Boolean
Dim frm As frmMain

  bFullscreen = False
  bDone = False
  
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
      
      'Check to see if the user is pressing F1
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
