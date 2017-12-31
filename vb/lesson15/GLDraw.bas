Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
   glClear clrColorBufferBit Or clrDepthBufferBit  ' Clear The Screen And The Depth Buffer
    glLoadIdentity                                  ' Reset The Current Modelview Matrix
    ' Position The Text
    glTranslatef 1.1 * Cos(rot / 16#), 0.8 * Sin(rot / 20#), -3#

    glRotatef rot, 1#, 0#, 0#                 ' Rotate On The X Axis
    glRotatef rot * 1.2, 0#, 1#, 0#           ' Rotate On The Y Axis
    glRotatef rot * 1.4, 0#, 0#, 1#           ' Rotate On The Z Axis

    glTranslatef -0.35, -0.35, 0.1         ' Center On X, Y, Z Axis
    glBindTexture GL_TEXTURE_2D, Texture(filter)           ' Select Our Texture
    glPrint "N"                       ' Draw A Skull And Crossbones Symbol
    rot = rot + 0.1                     ' Increase The Rotation Variable
'
'    glBegin GL_QUADS
'        ' Front Face
'        glNormal3f 0#, 0#, 1#                                    ' Normal Pointing Towards Viewer
'        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Left Of The Texture and Quad
'        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Right Of The Texture and Quad
'        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, 1#               ' Top Right Of The Texture and Quad
'        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, 1#              ' Top Left Of The Texture and Quad
'        ' Back Face
'        glNormal3f 0#, 0#, -1#                                   ' Normal Pointing Away From Viewer
'        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, -1#            ' Bottom Right Of The Texture and Quad
'        glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, -1#             ' Top Right Of The Texture and Quad
'        glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, -1#              ' Top Left Of The Texture and Quad
'        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, -1#             ' Bottom Left Of The Texture and Quad
'        ' Top Face
'        glNormal3f 0#, 1#, 0#                                    ' Normal Pointing Up
'        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#             ' Top Left Of The Texture and Quad
'        glTexCoord2f 0#, 0#: glVertex3f -1#, 1#, 1#              ' Bottom Left Of The Texture and Quad
'        glTexCoord2f 1#, 0#: glVertex3f 1#, 1#, 1#               ' Bottom Right Of The Texture and Quad
'        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#              ' Top Right Of The Texture and Quad
'        ' Bottom Face
'        glNormal3f 0#, -1#, 0#                                   ' Normal Pointing Down
'        glTexCoord2f 1#, 1#: glVertex3f -1#, -1#, -1#            ' Top Right Of The Texture and Quad
'        glTexCoord2f 0#, 1#: glVertex3f 1#, -1#, -1#             ' Top Left Of The Texture and Quad
'        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Left Of The Texture and Quad
'        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Right Of The Texture and Quad
'        ' Right face
'        glNormal3f 1#, 0#, 0#                                    ' Normal Pointing Right
'        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, -1#             ' Bottom Right Of The Texture and Quad
'        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#              ' Top Right Of The Texture and Quad
'        glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, 1#               ' Top Left Of The Texture and Quad
'        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Left Of The Texture and Quad
'        ' Left Face
'        glNormal3f -1#, 0#, 0#                                   ' Normal Pointing Left
'        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, -1#            ' Bottom Left Of The Texture and Quad
'        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Right Of The Texture and Quad
'        glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, 1#              ' Top Right Of The Texture and Quad
'        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#             ' Top Left Of The Texture and Quad
'    glEnd
'    xrot = xrot + xspeed                             ' X Axis Rotation
'    yrot = yrot + yspeed                             ' Y Axis Rotation
    DrawGLScene = True                                 ' Keep Going

End Function

