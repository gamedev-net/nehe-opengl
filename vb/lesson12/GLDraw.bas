Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    glClear clrColorBufferBit Or clrDepthBufferBit            ' Clear Screen And Depth Buffer

    glBindTexture GL_TEXTURE_2D, Texture(0)           ' Select Our Texture
    For yloop = 1 To 5             ' Loop Through The Y Plane

        For xloop = 0 To yloop - 1    ' Loop Through The X Plane

  
            glLoadIdentity           ' Reset The View

            ' Position The Cubes On The Screen
            glTranslatef 1.4 + (CDbl(xloop) * 2.8) - (CDbl(yloop) * 1.4), ((6# - CDbl(yloop)) * 2.4) - 7#, -20#

            glRotatef 45# - (2# * yloop) + xrot, 1#, 0#, 0#   ' Tilt The Cubes Up And Down
            glRotatef 45# + yrot, 0#, 1#, 0#              ' Spin Cubes Left And Right

            glColor3fv boxcol(0, yloop - 1)    ' Select A Box Color

            glCallList box            ' Draw The Box

            glColor3fv topcol(0, yloop - 1)    ' Select The Top Color

            glCallList top            ' Draw The Top
        Next xloop
    Next yloop
    DrawGLScene = True                                 ' Keep Going

End Function

