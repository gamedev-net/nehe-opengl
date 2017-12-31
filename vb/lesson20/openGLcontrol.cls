VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "openGLcontrolClass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'----------------------------------------------------------

'this module initialises and terminates OGL context's & handles
Option Explicit

Const P_VIEWANGLE = 45
Const P_NEARPLANE = 0.1
Const P_FARPLANE = 200


Private result As Long              'a dummy variable to assign to all long-functions
Public Sub initialize(h As Long, pw As Long, ph As Long)

'h = output-control's hdc
'pw = width of output control
'ph = height of output control
ghDC = h

setupOGL            'takes care of pixelformats, palette isn't handled in this project
setupView pw, ph    'setting up view

End Sub
Private Sub setupOGL()

Dim pfd As PIXELFORMATDESCRIPTOR
Dim dummy As Long

pfd.nSize = Len(pfd)
pfd.nVersion = 1
pfd.dwFlags = PFD_DRAW_TO_WINDOW Or PFD_SUPPORT_OPENGL Or PFD_DOUBLEBUFFER
pfd.iPixelType = PFD_TYPE_RGBA
pfd.cColorBits = 24
pfd.cDepthBits = 16
pfd.iLayerType = PFD_MAIN_PLANE

result = glGetError()                    'create a dummy call to opengl
If result <> GL_INVALID_OPERATION Then showMsg "setupOGL: invalid initialisation-error"

'Now we can investigate a pixel format index
result = ChoosePixelFormat(ghDC, pfd)    'find the closest match

If result = 0 Then                       'no match found
    showMsg "setupOGL: Format is set to zero when initialising"
    Exit Sub
End If
dummy = SetPixelFormat(ghDC, result, pfd)    'setting pixel format to the one with
ghRC = wglCreateContext(ghDC)                'creating a rendering context
wglMakeCurrent ghDC, ghRC                    'selecting context, making it current
                                                          
End Sub
Public Sub setupView(ByVal pw As Long, ByVal ph As Long)

Dim a As Double

glMatrixMode mmProjection     'change to modelling view
glLoadIdentity                'load the new identity matrix

'We now must specify the projection matrix' entries. We are doing this with
'gluPerspective, in which you can specify far and near clipping, view angle
'and aspect ratio
a = CDbl(pw) / CDbl(ph)

gluPerspective P_VIEWANGLE, a, P_NEARPLANE, P_FARPLANE             'setting matrix entries
glViewport 0, 0, pw, ph                  'defining viewport

glMatrixMode mmModelView                'new matrix
glLoadIdentity

End Sub
Public Sub terminate()

'when app is unloading, this need to be done first
wglMakeCurrent vbNull, vbNull             'deselect the RC
result = wglDeleteContext(ghRC)           'and deleting the RC

End Sub
