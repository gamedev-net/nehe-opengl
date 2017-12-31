VERSION 5.00
Begin VB.Form frmmain 
   Caption         =   "Lesson 14 - Outlined Fonts"
   ClientHeight    =   5115
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6975
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   5115
   ScaleWidth      =   6975
   StartUpPosition =   3  'Windows Default
   Begin VB.PictureBox picMain 
      Height          =   4920
      Left            =   120
      ScaleHeight     =   324
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   447
      TabIndex        =   0
      Top             =   120
      Width           =   6765
   End
End
Attribute VB_Name = "frmmain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'Code by Edo
'----------------------------------------------------------
Const INDENT = 100              'resizing constants
Const OUTDENT = 200            'outdenting
Const BAR = 400                 'title bar height

Private opengl As New openGLcontrolClass           'handles initialization and terminating
Private Fontc  As New fontClass                 'handles drawing particles
Private quitflag As Boolean                         'needed for jumping out of rendering loop
Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)

If KeyCode = vbKeyEscape Then
    quitflag = True
    Form_Unload -1
End If

End Sub
Private Sub Form_Load()

Dim a As String
Me.Show: Me.Refresh

opengl.Initialize picMain.hDC, picMain.ScaleWidth, picMain.ScaleHeight 'this takes care of all initializing
Fontc.Initialize  'clearing and initializing all variables
Form_Resize

'start rendering particle engine
quitflag = False
Do Until quitflag = True
    DoEvents
    Fontc.renderAll
Loop


End Sub
Private Sub Form_Resize()

'when resizing: align all controls and call to glViewport
picMain.Left = INDENT       'align picturebox
picMain.Top = INDENT
picMain.Width = frmmain.Width - INDENT - OUTDENT
picMain.Height = frmmain.Height - 2 * INDENT - BAR

opengl.setupView picMain.ScaleWidth, picMain.ScaleHeight    'setting new viewport

End Sub
Private Sub Form_Unload(Cancel As Integer)

opengl.terminate            'cleaning up the mess
quitflag = True             'this here is needed to jump out of the rendering loop
Unload Me

End Sub
