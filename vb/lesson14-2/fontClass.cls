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
Private rot As Integer              'when rot is declared as glfloat app crashes. Mail me if you find out why, I desperately need to know
Private gmf(0 To 256 - 1) As GLYPHMETRICSFLOAT  'this will hold all info on our chars
Public Sub Initialize()

glShadeModel smSmooth           'smooth shading
glClearColor 0, 0, 0, 1
glClearDepth 1
glEnable glcDepthTest
glDepthFunc cfLEqual            'setting depth function
glHint htPerspectiveCorrectionHint, hmNicest
glEnable glcLight0
glEnable glcLighting
glEnable glcColorMaterial       'we need this because we are drawing 3D objects to screen
                                'glColor* will not cause the text color to change
buildFont

End Sub
Private Sub buildFont()

'this sub builds up our font
Dim font As Long

base = glGenLists(256)
font = CreateFont(-12, 0, 0, 0, FW_BOLD, False, False, False, ANSI_CHARSET, _
                OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, _
                FF_DONTCARE Or DEFAULT_PITCH, "Comic Sans MS")
'Parameter explanation:
'-12        -> height of font, negative for finding CHARACTER-based font
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
'"Comic Sans MS"                -> the selected font

SelectObject ghDC, font         'select the font you specified

wglUseFontOutlines ghDC, 0, 255, base, 0, 0.2, WGL_FONT_POLYGONS, gmf(0)
'Parameter explanation:
'ghdc   -> select current dc
'0      -> starting character
'255    -> number of display lists to be build
'base   -> starting display list
'0      -> deviation (closer to 0 will create smoother font)
'0.2    -> font thickness (in z-axis)
'WGL_FONT_POLYGONS  -> will create solid font, wgl_font_lines will create wireframe font
'gmf(0) -> pointer to display list data

End Sub
Private Sub killFont()

'deletes all display lists, windows may do this for you
glDeleteLists base, 256

End Sub
Private Sub glPrint(fmt As String)
'this is the handy sub that uses the outline font to print text to screen

On Error GoTo einde             'debug, checking for errors

Dim i As Integer
Dim strlen As Integer           'lenght of the string
Dim length As GLfloat           'width of the whole string in opengl
Dim text(0 To 256 - 1) As Byte  'this is where we store out text in bytes

strlen = Len(fmt)               'the length of our message
If strlen > 256 Then Exit Sub   'cannot store in text array
If strlen = 0 Then Exit Sub     'nothing to print

For i = 0 To strlen - 1         'looping through each char and storing it in text
    text(i) = CByte(Asc(Mid(fmt, i + 1, 1)))
Next i

length = 0                      'setting text-length to 0
For i = 0 To strlen - 1         'now we are going to compute the actual (opengl) length of our text
    length = length + gmf(text(i)).gmfCellIncX
Next i
glTranslatef -length / 2, 0, 0  'translating to the left of the screen for drawing begin

'now for the actual drawing on the screen
glPushAttrib amListBit
    glListBase base
    glCallLists strlen, GL_UNSIGNED_BYTE, text(0)
glPopAttrib
Exit Sub

einde:
showMsg "hier in de glPrint sub ontstaat een error"
End Sub
Public Sub renderAll()

glClear (clrColorBufferBit Or clrDepthBufferBit)
glPushMatrix

    glTranslatef 0, 0, -7                       'changed from value in tutorial (-10)
    glRotatef rot, 1, 0, 0
    glRotatef CSng(rot * 1.5), 0, 1, 0
    glRotatef CSng(rot * 1.4), 0, 0, 1
    
    'this will cause the color to be pulsing
    glColor3f Cos(rot / 20), Sin(rot / 25), 1 - 0.5 * Cos(rot / 17)
    glPrint "Nehe - " & CStr(rot)
    rot = rot + 1                           'does anybody know why rot=rot+0.5 doesn't work here ?
    If rot > 720 Then rot = rot Mod 720     'protecting from overflow
    
glPopMatrix
SwapBuffers ghDC

End Sub
Private Sub Class_Terminate()

killFont

End Sub
