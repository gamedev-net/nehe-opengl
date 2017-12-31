VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "fontClass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'Code by Edo
'----------------------------------------------------------
Option Explicit

Private base As GLuint              'the base of our display lists
Private cnt1 As GLfloat              '1st counter for coloring and rotating text
Private cnt2 As GLfloat              '2nd counter for coloring and rotating text
Public Sub Initialize()

glShadeModel smSmooth           'smooth shading
glClearColor 0, 0, 0, 1
glClearDepth 1
glEnable glcDepthTest
glDepthFunc cfLEqual            'setting depth function
glHint htPerspectiveCorrectionHint, hmNicest

buildFont

End Sub
Private Sub buildFont()

'this sub builds up our font
Dim font As Long

base = glGenLists(96)
font = CreateFont(-24, 0, 0, 0, FW_BOLD, False, False, False, ANSI_CHARSET, _
                OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, _
                FF_DONTCARE Or DEFAULT_PITCH, "Courier New")
'Parameter explanation:
'-24        -> height of font, negative for finding CHARACTER-based font
'0          -> width of font, by setting this to 0 windows will use default width
'0          -> angle of escapement (this will rotate the font)
'0          -> angle of orientation
'FW_BOLD    -> range from 0-1000, the higher the value, the thicker the font
'false      -> italic
'false      -> underline
'false      -> strikeout
'ANSI_CHARSET           -> Greek, russian, chinese, default, symbol or ansi character set
'OUT_TT_PRECIS          -> if more charsets are available, use truetype
'CLIP_DEFAULT_PRECIS    -> what kind of clipping when fonts is out of clipping range
'ANTIALIASED_QUALITY    -> Default, proof, draft, nonantia., antia. output quality
'FF_DONTCARE or DEFAULT_PITCH   -> default, fixed, variable pitch, decorative, roman, swiss, dontcare, modern and script family
'"Courier New"                -> the selected font

SelectObject ghDC, font         'select the font you specified

wglUseFontBitmaps ghDC, 32, 96, base
'Parameter explanation:
'ghdc   -> select current dc
'32      -> starting character
'96    -> number of display lists to be build
'base   -> starting display list

End Sub
Private Sub killFont()

'deletes all display lists, windows may do this for you
glDeleteLists base, 96

End Sub
Private Sub glPrint(fmt As String)
'this is the handy sub that uses the outline font to print text to screen

On Error GoTo einde             'debug, checking for errors

Dim i As Integer
Dim strlen As Integer           'lenght of the string
Dim text(0 To 256 - 1) As Byte  'this is where we store out text in bytes

strlen = Len(fmt)               'the length of our message
If strlen > 256 Then Exit Sub   'cannot store in text array
If strlen = 0 Then Exit Sub     'nothing to print

For i = 0 To strlen - 1         'looping through each char and storing it in text
    text(i) = CByte(Asc(Mid(fmt, i + 1, 1)))
Next i

'now for the actual drawing on the screen
glPushAttrib amListBit
    glListBase base - 32
    glCallLists strlen, GL_UNSIGNED_BYTE, text(0)
glPopAttrib
Exit Sub

einde:
showMsg "hier in de glPrint sub ontstaat een error"
End Sub
Public Sub renderAll()

glClear (clrColorBufferBit Or clrDepthBufferBit)
glPushMatrix

    glTranslatef 0, 0, -1
    
    'Pulsing colors based on text position
    glColor3f Cos(cnt1), Sin(cnt2), 1 - 0.5 * Cos(cnt1 + cnt2)
    
    'Position the text on the screen
    glRasterPos2f -0.5 + 0.05 * Cos(cnt1), 0.35 * Sin(cnt2)
    glPrint "Active Opengl Text With NeHe"
    
    'Now only one thing left: increasing variables cnt1/2
    cnt1 = cnt1 + 0.051
    cnt2 = cnt2 + 0.005
    If cnt1 > 360 Then cnt1 = 0         'preventing overflow
    If cnt2 > 360 Then cnt2 = 0
    
glPopMatrix
SwapBuffers ghDC

End Sub
Private Sub Class_Terminate()

killFont

End Sub
