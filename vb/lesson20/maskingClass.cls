VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "maskingClass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'To run this app, goto Project --> References...--> Browse :
'C:\win..\system\vbogl.tlb
'----------------------------------------------------------

Option Explicit

Private masking As Boolean                  'is masking on ?
Private roll As GLfloat                     'rolling texture
Private scene As Boolean                    'what scene do we want to draw ?

Private texture(1 To 5) As GLuint           'texture handle array
Private numtextures As Integer              'number of texture succesfully loaded
Private bmpimage() As GLubyte                   'empty pixel array
Public Sub initialize()

setupStates                               'enabling all states
masking = True                            'always set masking to true
roll = 0                                    'not rolled yet
scene = True                                'display scene 1 first
numtextures = 0                             'must be set to 0

'loading all 5 masks and pictures, in this order:
'logo,mask1,image1,mask2,image2
With frmMain                   'setting picture in dummy picturebox in formmain
    .labelProgress.Caption = "Loading...1/5": .Refresh     'showing loading progress
    .picdummy.Picture = LoadPicture(App.Path & "\logo.jpg")
    loadTexture .picdummy
    
    .labelProgress.Caption = "Loading...2/5": .Refresh
    .picdummy.Picture = LoadPicture(App.Path & "\mask1.jpg")
    loadTexture .picdummy
    
    .labelProgress.Caption = "Loading...3/5": .Refresh
    .picdummy.Picture = LoadPicture(App.Path & "\image1.jpg")
    loadTexture .picdummy
    
    .labelProgress.Caption = "Loading...4/5": .Refresh
    .picdummy.Picture = LoadPicture(App.Path & "\mask2.jpg")
    loadTexture .picdummy
    
    .labelProgress.Caption = "Loading...5/5": .Refresh
    .picdummy.Picture = LoadPicture(App.Path & "\image2.jpg")
    loadTexture .picdummy

    
    End With

End Sub
Private Sub setupStates()

'setting up all starting opengl-states
glClearColor 0, 0, 0, 1                 'black background color
glClearDepth 1
glEnable glcDepthTest
glShadeModel smSmooth                   'enabling shading
glEnable glcTexture2D                   'enabling texture mapping
        
End Sub
Public Sub renderAll()

'now for the fun stuff. All our drawing commands go in here
glClear (clrColorBufferBit Or clrDepthBufferBit)
glPushMatrix

    glTranslatef 0, 0, -3               'this is the z where we draw our textures
    glBindTexture glTexture2D, texture(1)
    
    glBegin bmQuads                 'start drawing a textured quad
        glTexCoord2f 3, -roll + 0: glVertex3f -1.1, -1.1, 0 'bottom right
        glTexCoord2f 3, -roll + 3: glVertex3f 1.1, -1.1, 0  'top right
        glTexCoord2f 0, -roll + 3: glVertex3f 1.1, 1.1, 0 'top left
        glTexCoord2f 0, -roll + 0: glVertex3f -1.1, 1.1, 0 'bottom left
    
    glEnd
   
    glEnable glcBlend               'when blending mode is on, depth testing MUST be disabled
    glDisable glcDepthTest
    
    If masking = True Then glBlendFunc sfDstColor, dfZero      'blend screen color with zero (black)
    If scene = True Then
        
        glRotatef roll * 360, 0, 0, 1
        If masking = True Then
            
            glBindTexture glTexture2D, texture(4)
            glBegin bmQuads
                glTexCoord2f 0, 0: glVertex3f -1.1, -1.1, 0 'bottom left
                glTexCoord2f 1, 0: glVertex3f 1.1, -1.1, 0  'bottom right
                glTexCoord2f 1, 1: glVertex3f 1.1, 1.1, 0   'top right
                glTexCoord2f 0, 1: glVertex3f -1.1, 1.1, 0  'top left
            glEnd
            
            glBlendFunc sfOne, dfOne
            glBindTexture glTexture2D, texture(5)
            glBegin bmQuads
                glTexCoord2f 0, 0: glVertex3f -1.1, -1.1, 0 'bottom left
                glTexCoord2f 1, 0: glVertex3f 1.1, -1.1, 0  'bottom right
                glTexCoord2f 1, 1: glVertex3f 1.1, 1.1, 0   'top right
                glTexCoord2f 0, 1: glVertex3f -1.1, 1.1, 0  'top left
            glEnd

        End If
        
    Else            'draw the first scene
        
        If masking = True Then
            
            glBindTexture glTexture2D, texture(2)
            glBegin bmQuads
                glTexCoord2f roll + 4, 0: glVertex3f -1.1, -1.1, 0 'bottom left
                glTexCoord2f roll + 4, 4: glVertex3f 1.1, -1.1, 0 'bottom right
                glTexCoord2f roll + 0, 4: glVertex3f 1.1, 1.1, 0 'top right
                glTexCoord2f roll + 0, 0: glVertex3f -1.1, 1.1, 0 'top left
            glEnd
        
            glBlendFunc sfOne, dfOne
            glBindTexture glTexture2D, texture(3)
            glBegin bmQuads
                glTexCoord2f roll + 4, 0: glVertex3f -1.1, -1.1, 0 'bottom left
                glTexCoord2f roll + 4, 4: glVertex3f 1.1, -1.1, 0 'bottom right
                glTexCoord2f roll + 0, 4: glVertex3f 1.1, 1.1, 0 'top right
                glTexCoord2f roll + 0, 0: glVertex3f -1.1, 1.1, 0 'top left
            glEnd
            
        End If
        
    End If
    
    glEnable glcDepthTest
    glDisable glcBlend
    roll = roll + 0.02
    If roll > 1 Then roll = 0

glPopMatrix
SwapBuffers ghDC

End Sub
Public Sub loadTexture(pic As PictureBox)

'this sub loads a texture out of a picturebox into the texture memory
Dim bmpHeight As GLfloat, bmpWidth As GLfloat
Dim i As Long, j As Long, k As Long

'first we are going to load all picture-data into an array
bmpHeight = pic.ScaleHeight                     'setting width and height
bmpWidth = pic.ScaleWidth

'an array with 1 dimension loads quicker than one with 3 dimensions.
'you might want to change to 3 dimensions for simplicity
ReDim bmpimage(bmpHeight * bmpWidth * 3 - 1)   'right array size

'no picture-boundry test is needed here, so we can begin loading our texture
Dim X As Long                               'retrieving rgb-values from picturebox
X = 0
For i = 0 To bmpWidth - 1
    For j = 0 To bmpHeight - 1
        k = pic.Point(i, j)                 'extracting rgb - value out of picbox
        
        bmpimage(X) = (k And &HFF&)
        bmpimage(X + 1) = ((k And &HFF00&) / &H100&)
        bmpimage(X + 2) = ((k And &HFF0000) / &H10000)
        X = X + 3
    Next j
Next i

'storing texture and binding it
numtextures = numtextures + 1                         'increasing number of textures
If numtextures > 5 Then Exit Sub                      'texture-overflow
glGenTextures 1, texture(numtextures)                 'generating a texture
glBindTexture glTexture2D, texture(numtextures)      'select current texture

glPixelStorei pxsUnpackAlignment, 1
'select modulate to mix texture with color for shading
glTexEnvf tetTextureEnv, tenTextureEnvMode, tepModulate

'when texture is large, bilinear filter the first mipmap
glTexParameterf GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
glTexParameterf GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    
'when wrapping is enabled, send gl_repeat to texture-wrapping
'in this application gl_clamp doesn't work, so don't change following 2 lines
glTexParameterf glTexture2D, tpnTextureWrapS, GL_REPEAT
glTexParameterf glTexture2D, tpnTextureWrapT, GL_REPEAT

'creating a texture
glTexImage2D glTexture2D, 0, 3, bmpWidth, bmpHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, bmpimage(0)

Erase bmpimage                          'cleaning up the mess

End Sub
Public Sub changeScene()

scene = Not scene                   'changing rendering scene

End Sub
