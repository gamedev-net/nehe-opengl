VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmmain 
   Caption         =   "lesson 19 - Particle Engine"
   ClientHeight    =   4995
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   7080
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   4995
   ScaleWidth      =   7080
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdExplosion 
      Caption         =   "Explosion"
      Height          =   255
      Left            =   4440
      TabIndex        =   16
      Top             =   600
      Width           =   1455
   End
   Begin VB.CommandButton cmdTexture 
      Caption         =   "Texture"
      Height          =   255
      Left            =   4440
      TabIndex        =   15
      TabStop         =   0   'False
      Top             =   360
      Width           =   1455
   End
   Begin VB.CommandButton cmdHelp 
      Caption         =   "Help"
      Height          =   255
      Left            =   4440
      TabIndex        =   14
      TabStop         =   0   'False
      Top             =   120
      Width           =   1455
   End
   Begin MSComDlg.CommonDialog cmd 
      Left            =   0
      Top             =   0
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin VB.Frame frameHelp 
      Height          =   3735
      Left            =   4440
      TabIndex        =   2
      Top             =   840
      Visible         =   0   'False
      Width           =   2535
      Begin VB.Label Label15 
         Caption         =   "Color Change : Space Bar"
         Height          =   255
         Left            =   120
         TabIndex        =   13
         Top             =   3000
         Width           =   1935
      End
      Begin VB.Label Label14 
         Caption         =   "- X-Speed : Left Arrow"
         Height          =   255
         Left            =   120
         TabIndex        =   12
         Top             =   2640
         Width           =   1695
      End
      Begin VB.Label Label13 
         Caption         =   "X-Speed : Right Arrow"
         Height          =   255
         Left            =   120
         TabIndex        =   11
         Top             =   2400
         Width           =   1815
      End
      Begin VB.Label Label12 
         Caption         =   "- Y-Speed : Down Arrow"
         Height          =   255
         Left            =   120
         TabIndex        =   10
         Top             =   2160
         Width           =   1815
      End
      Begin VB.Label Label11 
         Caption         =   "Y-Speed : Up Arrow"
         Height          =   255
         Left            =   120
         TabIndex        =   9
         Top             =   1920
         Width           =   1575
      End
      Begin VB.Label Label5 
         Caption         =   "Explosion : Tab"
         Height          =   255
         Left            =   120
         TabIndex        =   8
         Top             =   360
         Width           =   1815
      End
      Begin VB.Label Label6 
         Caption         =   "Speed Up : Numpad Add"
         Height          =   255
         Left            =   120
         TabIndex        =   7
         Top             =   720
         Width           =   1935
      End
      Begin VB.Label Label7 
         Caption         =   "Slow Down : Numpad Subtract"
         Height          =   255
         Left            =   120
         TabIndex        =   6
         Top             =   960
         Width           =   2295
      End
      Begin VB.Label Label8 
         Caption         =   "Zoom In: Page Up"
         Height          =   255
         Left            =   120
         TabIndex        =   5
         Top             =   1320
         Width           =   1575
      End
      Begin VB.Label Label9 
         Caption         =   "Zoom Out: Page Down"
         Height          =   255
         Left            =   120
         TabIndex        =   4
         Top             =   1560
         Width           =   1815
      End
      Begin VB.Label Label10 
         Caption         =   "Quit : Escape"
         Height          =   255
         Left            =   120
         TabIndex        =   3
         Top             =   3240
         Width           =   2175
      End
   End
   Begin VB.PictureBox picDummy 
      AutoRedraw      =   -1  'True
      AutoSize        =   -1  'True
      Height          =   435
      Left            =   0
      ScaleHeight     =   25
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   42
      TabIndex        =   1
      Top             =   480
      Visible         =   0   'False
      Width           =   690
   End
   Begin VB.PictureBox picMain 
      Height          =   4800
      Left            =   120
      ScaleHeight     =   316
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   279
      TabIndex        =   0
      Top             =   120
      Width           =   4245
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
'----------------------------------------------------------
Const INDENT = 100              'resizing constants
Const OUTDENT = 3000            'outdenting
Const BAR = 400                 'title bar height

Private opengl As New openGLcontrolClass           'handles initialization and terminating
Private parteng As New partEngClass                 'handles drawing particles
Private quitflag As Boolean                         'needed for jumping out of rendering loop
Private Sub cmdExplosion_Click()

parteng.setKey vbKeyTab         'setting key for explosion

End Sub
Private Sub cmdHelp_Click()

frameHelp.Visible = Not frameHelp.Visible

End Sub
Private Sub cmdTexture_Click()

cmd.Filter = "Texture Files (*.jpg *.bmp)|*.jpg;*.bmp"      'setting filter
cmd.ShowOpen
If cmd.FileName <> "" Then                      'only load valid files
    picDummy.Picture = LoadPicture(cmd.FileName)
    parteng.loadTexture picDummy
End If

End Sub
Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)

If KeyCode = vbKeyEscape Then
    quitflag = True
    End
Else
    parteng.setKey KeyCode                          'interact with partengClass
End If

End Sub
Private Sub Form_Load()

Me.Show: Me.Refresh

opengl.initialize picMain.hDC, picMain.ScaleWidth, picMain.ScaleHeight 'this takes care of all initializing
parteng.initialize  'clearing and initializing all variables

'ask for a jpg or bitmap
Call cmdTexture_Click

'start rendering particle engine
quitflag = False
Do Until quitflag = True
    DoEvents
    parteng.renderAll
Loop


End Sub
Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)

opengl.terminate            'cleaning up the mess
quitflag = True             'this here is needed to jump out of the rendering loop

'wait a while till loop has actually ended, maybe not necessary
wait 0.5
Unload Me

End Sub
Private Sub wait(sec As Single)

'this sub waits specified number of seconds
b! = Timer
Do
    DoEvents: DoEvents
Loop Until Timer > b! + sec

End Sub
Private Sub Form_Resize()

'when resizing: align all controls and call to glViewport

Dim a As Long
picMain.Left = INDENT       'align picturebox
picMain.Top = INDENT
picMain.Width = frmmain.Width - INDENT - OUTDENT
picMain.Height = frmmain.Height - 2 * INDENT - BAR

a = picMain.Left + picMain.Width + INDENT
cmdHelp.Left = a            'all align at the right side of the picturebox
cmdTexture.Left = a
cmdExplosion.Left = a
frameHelp.Left = a

cmdHelp.Top = INDENT
cmdTexture.Top = cmdHelp.Top + cmdHelp.Height
cmdExplosion.Top = cmdTexture.Top + cmdTexture.Height
frameHelp.Top = cmdExplosion.Top + cmdExplosion.Height

opengl.setupView picMain.ScaleWidth, picMain.ScaleHeight    'setting new viewport

End Sub
