Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    glClear clrColorBufferBit Or clrDepthBufferBit            ' Clear Screen And Depth Buffer
    glLoadIdentity                            ' Reset The Current Matrix
    glTranslatef 0#, 0#, z                              ' Translate Into/Out Of The Screen By z

    glRotatef xrot, 1#, 0#, 0#                        ' Rotate On The X Axis
    glRotatef yrot, 0#, 1#, 0#                        ' Rotate On The Y Axis

    glBindTexture glTexture2D, Texture(filter)            ' Select Our Texture

    glBegin GL_QUADS
        ' Front Face
        glNormal3f 0#, 0#, 1#                                    ' Normal Pointing Towards Viewer
        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, 1#               ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, 1#              ' Top Left Of The Texture and Quad
        ' Back Face
        glNormal3f 0#, 0#, -1#                                   ' Normal Pointing Away From Viewer
        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, -1#            ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, -1#             ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, -1#              ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, -1#             ' Bottom Left Of The Texture and Quad
        ' Top Face
        glNormal3f 0#, 1#, 0#                                    ' Normal Pointing Up
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#             ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f -1#, 1#, 1#              ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f 1#, 1#, 1#               ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#              ' Top Right Of The Texture and Quad
        ' Bottom Face
        glNormal3f 0#, -1#, 0#                                   ' Normal Pointing Down
        glTexCoord2f 1#, 1#: glVertex3f -1#, -1#, -1#            ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f 1#, -1#, -1#             ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Right Of The Texture and Quad
        ' Right face
        glNormal3f 1#, 0#, 0#                                    ' Normal Pointing Right
        glTexCoord2f 1#, 0#: glVertex3f 1#, -1#, -1#             ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f 1#, 1#, -1#              ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f 1#, 1#, 1#               ' Top Left Of The Texture and Quad
        glTexCoord2f 0#, 0#: glVertex3f 1#, -1#, 1#              ' Bottom Left Of The Texture and Quad
        ' Left Face
        glNormal3f -1#, 0#, 0#                                   ' Normal Pointing Left
        glTexCoord2f 0#, 0#: glVertex3f -1#, -1#, -1#            ' Bottom Left Of The Texture and Quad
        glTexCoord2f 1#, 0#: glVertex3f -1#, -1#, 1#             ' Bottom Right Of The Texture and Quad
        glTexCoord2f 1#, 1#: glVertex3f -1#, 1#, 1#              ' Top Right Of The Texture and Quad
        glTexCoord2f 0#, 1#: glVertex3f -1#, 1#, -1#             ' Top Left Of The Texture and Quad
    glEnd

    xrot = xrot + xspeed                             ' X Axis Rotation
    yrot = yrot + yspeed                             ' Y Axis Rotation
    DrawGLScene = True                                 ' Keep Going

End Function

