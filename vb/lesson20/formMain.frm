VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmMain 
   Caption         =   "Lesson 20 - Masking"
   ClientHeight    =   4830
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   8025
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   4830
   ScaleWidth      =   8025
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton commandScene 
      Caption         =   "Scene"
      Height          =   375
      Left            =   6480
      TabIndex        =   2
      Top             =   120
      Width           =   855
   End
   Begin MSComDlg.CommonDialog cmd 
      Left            =   0
      Top             =   0
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin VB.PictureBox picdummy 
      AutoRedraw      =   -1  'True
      AutoSize        =   -1  'True
      FillStyle       =   0  'Solid
      Height          =   375
      Left            =   0
      ScaleHeight     =   21
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   61
      TabIndex        =   1
      Top             =   480
      Visible         =   0   'False
      Width           =   975
   End
   Begin VB.PictureBox picMain 
      Height          =   4575
      Left            =   120
      ScaleHeight     =   301
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   413
      TabIndex        =   0
      Top             =   120
      Width           =   6255
   End
   Begin VB.Label labelProgress 
      Height          =   255
      Left            =   6480
      TabIndex        =   3
      Top             =   600
      Width           =   1455
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'To run this app, dblClick Project --> References...--> Browse :
'C:\win..\system\vbogl.tlb
'remember: picmain.scalemode MUST be vbPixels, also picdummy.scalemode.
'picdummy.autoredraw must be true, picmain.autoredraw must be false
'----------------------------------------------------------
Option Explicit

Const INDENT = 100      'constants for resizing
Const OUTDENT = 1500
Const BAR = 400         'height of title bar

Private opengl As New openGLcontrolClass
Private masking As New maskingClass
Private quitflag As Boolean             'tells us when to quit this app
Private Sub commandScene_Click()

masking.changeScene                     'changing the scene

End Sub
Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)

If KeyCode = vbKeyEscape Then
    quitflag = True
    Form_Unload -1
End If

End Sub
Private Sub Form_Load()

Me.Show: Me.Refresh             'this line must be here for correct drawing the first frame

opengl.initialize picMain.hDC, picMain.ScaleWidth, picMain.ScaleHeight
masking.initialize              'initializing everything

quitflag = False
Do Until quitflag = True
    DoEvents                    'such as keyboard input and resizing
    masking.renderAll
Loop

End Sub
Private Sub Form_Resize()

'when resizing: all controls must be re-placed, glViewport must be called to
picMain.Left = INDENT           're-placing picturebox
picMain.Top = INDENT
picMain.Width = frmMain.Width - OUTDENT - INDENT
picMain.Height = frmMain.Height - 2 * INDENT - BAR

commandScene.Left = picMain.Left + picMain.Width + INDENT   'place on the right side of picturebox
commandScene.Top = INDENT

labelProgress.Left = picMain.Left + picMain.Width + INDENT   'place on the right side of picturebox
labelProgress.Top = commandScene.Top + commandScene.Height + INDENT

opengl.setupView picMain.ScaleWidth, picMain.ScaleHeight     'resetting viewport

End Sub
Private Sub Form_Unload(Cancel As Integer)

opengl.terminate           'terminates and deselects and destroys all hdc,rdc etc.
quitflag = True             'for jumping out of rendering loop
Unload Me                   'unload...

End Sub
