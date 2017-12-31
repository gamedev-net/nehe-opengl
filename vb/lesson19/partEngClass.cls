VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "partEngClass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'----------------------------------------------------------
'Entire code written by Edo Drenthen. Based on Jeff Molofee's NeHe lesson 19

Option Explicit

Const MAX_PARTICLES = 300                  'number of particles to be created
Const TEX_SIZE = 0.03                      'texture size

Private slowdown As Single                  'higher the value, the slower particle moves
Private zoom As Single                      'zoom variable
Private xspeed As Single                    'speed in x (right) direction
Private yspeed As Single                   'speed in y (left) direction

Private col As GLuint                       'current color selection

Private Type ParticleType                   'properties of one particle
    active As Boolean                       'is this particle visible (enabled) ?
    life As Single                          'time to live
    fade As Single                          'brightness of this particle
    r As Single                             'particle color
        g As Single
            b As Single
    x As Single                             'particle position
        y As Single
            z As Single
    xi As Single                            'particle direction vector
        yi As Single
            zi As Single
    xg As Single                            'particle gravity
        yg As Single
            zg As Single
End Type

Private particle(MAX_PARTICLES - 1) As ParticleType  'all particls
Private colors(11, 2) As GLfloat                     'rainbow colors
Private key As Integer                              ' sets key that is pressed during cycle
Private texture As GLuint                          'is there a texture loaded?
Private bmpimage() As GLubyte                       'array that texture is loaded in
Public Sub renderAll()

Dim x As GLfloat, y As GLfloat, z As GLfloat
Dim i As Integer

glClear (clrColorBufferBit Or clrDepthBufferBit)
For i = 0 To MAX_PARTICLES - 1                      'loop through all particles
    
    With particle(i)                                'saves a lot of writing
    
        'storing position
        x = .x
        y = .y
        z = .z + zoom
        
        'fade the particle according to its life
        
        
        'using a triangle strip to speed up calcs,
        'use .r,.g,.b instead of 1,1,1 to create colorful stars
        glColor4f .r, .g, .b, .life
        glBegin bmQuads 'this also works when no texture is loaded
            glTexCoord2f 0, 0: glVertex3f x - TEX_SIZE, y - TEX_SIZE, z
            glTexCoord2f 1, 0: glVertex3f x + TEX_SIZE, y - TEX_SIZE, z
            glTexCoord2f 1, 1: glVertex3f x + TEX_SIZE, y + TEX_SIZE, z
            glTexCoord2f 0, 1: glVertex3f x - TEX_SIZE, y + TEX_SIZE, z
        glEnd
        
        
        'now we can beginning moving particles for next loop
        .x = x + .xi / (slowdown * 1000)
        .y = y + .yi / (slowdown * 1000)
        .z = .z + .zi / (slowdown * 1000)
        
        'gravity is pulling incremental speed of particle down
        .xi = .xi + .xg
        .yi = .yi + .yg
        .zi = .zi + .zg
        
        'reducing particles' life
        .life = .life - .fade
        If .life < 0 Then                               'particle is burned out
            
            .life = 1                                  'regenerate
            .fade = (Rnd * 100) / 1000 + 0.003          'setting new life
            
            .x = 0
            .y = 0
            .z = 0
            
            .xi = xspeed + (Rnd * 60 - 32)              'setting new random speed
            .yi = yspeed + (Rnd * 60 - 32)
            .zi = (Rnd * 60 - 32)
            
            .r = colors(col, 0)         'setting new color
            .g = colors(col, 1)
            .b = colors(col, 2)
            
        End If
        'code for individual particle changes (gravity only) goes here, but I
        'didn't implemented that, because this particle is to slow as it is now
        
    End With
    
Next i
SwapBuffers ghDC

End Sub
Public Sub initialize()

setupStates

slowdown = 2                    'default values
zoom = -2

setColor 0, 1, 0.5, 0.5                 'setting rainbow colors
setColor 1, 1, 0.75, 0.5
setColor 2, 1, 1, 0.5
setColor 3, 0.75, 1, 0.5
setColor 4, 0.5, 1, 0.5
setColor 5, 0.5, 1, 0.75
setColor 6, 0.5, 1, 1
setColor 7, 0.5, 0.75, 1
setColor 8, 0.5, 1, 1
setColor 9, 0.75, 0.5, 1
setColor 10, 1, 0.5, 1
setColor 11, 1, 0.5, 0.75

initializeParticles                 'setting up for explosion


End Sub
Private Sub setupStates()

glClearColor 0, 0, 0, 1
glShadeModel smSmooth                   'enabling shading
glClearDepth 1
glBlendFunc sfSrcAlpha, dfOne           'setting up blending
glHint htPerspectiveCorrectionHint, hmNicest    'nice......
glEnable glcBlend

glEnable glcTexture2D                   'enabling texture mapping

End Sub
Private Sub setColor(index As Integer, r As GLfloat, g As GLfloat, b As GLfloat)

'this is just a usefull sub
colors(index, 0) = r
colors(index, 1) = g
colors(index, 2) = b

End Sub
Private Sub initializeParticles()

Randomize Timer
Dim i As Integer

For i = 0 To MAX_PARTICLES - 1

    particle(i).active = True              'set all particles to true
    particle(i).life = 1                   'give all particles full life
    particle(i).fade = (Rnd * 100) / 1000 + 0.003   'give random
    
    particle(i).r = colors(Int(i / (MAX_PARTICLES / 12)), 0)   'rainbow colors
    particle(i).g = colors(Int(i / (MAX_PARTICLES / 12)), 1)
    particle(i).b = colors(Int(i / (MAX_PARTICLES / 12)), 2)
    
    particle(i).xi = ((Rnd * 50) - 26) * 10 'random speed on x-axis
    particle(i).yi = ((Rnd * 50) - 26) * 10 'random speed on x-axis
    particle(i).zi = ((Rnd * 50) - 26) * 10 'random speed on x-axis
    
    particle(i).xg = 0                      'only y-gravity pulling particles down
    particle(i).yg = -0.8
    particle(i).zg = 0

Next i

End Sub
Public Sub setKey(keyc As Integer)

Dim i As Integer
'this sub sets a key that is pressed during one loop,
'only one key can be pressed during one loop !!!!!
'you might want to change this
key = keyc

Select Case key             'take action now if possible
Case vbKeyAdd
    If slowdown > 1 Then slowdown = slowdown - 0.1
Case vbKeySubtract
    If slowdown < 4 Then slowdown = slowdown + 0.1
Case vbKeyPageUp
    zoom = zoom + 1
Case vbKeyPageDown
    zoom = zoom - 1
Case vbKeySpace
    col = col + 1
    If col > 11 Then col = 0
Case vbKeyUp
    If yspeed < 200 Then yspeed = yspeed + 4
Case vbKeyDown
    If yspeed > -200 Then yspeed = yspeed - 4
Case vbKeyRight
    If xspeed < 200 Then xspeed = xspeed + 4
Case vbKeyLeft
    If xspeed > -200 Then xspeed = xspeed - 4
Case vbKeyTab                   'tab sets an explosion
    Const speed = 500
    For i = 0 To MAX_PARTICLES - 1
        With particle(i)
            .x = 0
            .y = 0
            .z = 0
            .xi = (Rnd * 50 - 25) * 10
            .zi = (Rnd * 50 - 25) * 10
            .yi = Sqr(speed ^ 2 - .xi ^ 2 - .zi ^ 2) * (Rnd * 2 - 1)
            .r = colors(Int(Rnd * 12), 0)
            .g = colors(Int(Rnd * 12), 1)
            .b = colors(Int(Rnd * 12), 2)
        End With
    Next i
End Select

End Sub
Public Sub loadTexture(pic As PictureBox)

Dim bmpHeight As GLfloat, bmpWidth As GLfloat
Dim i As Long, j As Long, k As Long
'this sub loads a texture from a picturebox

'first we are going to load all picture-data into an array
pic.ScaleMode = vbPixels                        'right scalemode
bmpHeight = pic.ScaleHeight
bmpWidth = pic.ScaleWidth

'checking for right sizes (square and perfect power of 2). If size is not
'a supported size, this if..then will make it the nearest possible size
If bmpHeight <> bmpWidth Or (Int(log2(bmpHeight)) - log2(bmpHeight)) <> 0 Then

    k = bmpHeight + bmpWidth
    For i = 4 To 8
        If k >= (2 ^ i) * 2 And k < (2 ^ (i + 1)) * 2 Then
            bmpHeight = 2 ^ i
            bmpWidth = 2 ^ i
            pic.ScaleHeight = 2 ^ i
            pic.ScaleWidth = 2 ^ i
            Exit For
        End If
    Next i
    
    If bmpHeight + bmpWidth > 2 ^ 8 * 2 Then        'checking for overflow
            bmpHeight = 2 ^ 8
            bmpWidth = 2 ^ 8
            pic.ScaleHeight = 2 ^ 8
            pic.ScaleWidth = 2 ^ 8
    ElseIf bmpHeight + bmpWidth < 2 ^ 4 * 2 Then
            bmpHeight = 2 ^ 4
            bmpWidth = 2 ^ 4
            pic.ScaleHeight = 2 ^ 4
            pic.ScaleWidth = 2 ^ 4
    End If
    
End If

ReDim bmpimage(bmpHeight * bmpWidth * 3 - 1)   'right array size

Dim x As Long                               'retrieving rgb-values from picturebox
x = 0
For i = 0 To bmpWidth - 1
    For j = 0 To bmpHeight - 1
        k = pic.Point(i, j)
        bmpimage(x) = (k And &HFF&)
        bmpimage(x + 1) = ((k And &HFF00&) / &H100&)
        bmpimage(x + 2) = ((k And &HFF0000) / &H10000)
        x = x + 3
    Next j
Next i

'storing texture and binding it
glGenTextures 1, texture                              'allocate and name texture
glBindTexture glTexture2D, texture      'select current texture

glPixelStorei pxsUnpackAlignment, 1
'select modulate to mix texture with color for shading
glTexEnvf tetTextureEnv, tenTextureEnvMode, tepModulate

'when texture is large, bilinear filter the first mipmap
glTexParameterf GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
glTexParameterf GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    
'when wrapping is enabled, send gl_repeat to texture-wrapping
glTexParameterf glTexture2D, tpnTextureWrapS, GL_CLAMP
glTexParameterf glTexture2D, tpnTextureWrapT, GL_CLAMP

'creating a texture
glTexImage2D glTexture2D, 0, 3, bmpWidth, bmpHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, bmpimage(0)

Erase bmpimage                          'cleaning up the mess


End Sub
Private Sub Class_Initialize()

texture = -1

End Sub
