Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
   glClear clrColorBufferBit Or clrDepthBufferBit  ' Clear The Screen And The Depth Buffer
    glLoadIdentity                                  ' Reset The Current Modelview Matrix
    glBindTexture glTexture2D, Texture(1)                ' Select Our Second Texture
    glTranslatef 0#, 0#, -5#                          ' Move Into The Screen 5 Units
    glRotatef 45#, 0#, 0#, 1#                         ' Rotate On The Z Axis 45 Degrees (Clockwise)

    glRotatef cnt1 * 30#, 1#, 1#, 0#                      ' Rotate On The X & Y Axis By cnt1 (Left To Right)

    glDisable glcBlend                             ' Disable Blending Before We Draw In 3D
    glColor3f 1#, 1#, 1#                          ' Bright White
    glBegin bmQuads                            ' Draw Our First Texture Mapped Quad
        glTexCoord2d 0#, 0#                       ' First Texture Coord
        glVertex2f -1#, 1#                        ' First Vertex
        glTexCoord2d 1#, 0#                       ' Second Texture Coord
        glVertex2f 1#, 1#                         ' Second Vertex
        glTexCoord2d 1#, 1#                       ' Third Texture Coord
        glVertex2f 1#, -1#                        ' Third Vertex
        glTexCoord2d 0#, 1#                       ' Fourth Texture Coord
        glVertex2f -1#, -1#                       ' Fourth Vertex
    glEnd                                           ' Done Drawing The First Quad

    glRotatef 90#, 1#, 1#, 0#                         ' Rotate On The X & Y Axis By 90 Degrees (Left To Right)
    glBegin bmQuads                           ' Draw Our Second Texture Mapped Quad
        glTexCoord2d 0#, 0#                       ' First Texture Coord
        glVertex2f -1#, 1#                        ' First Vertex
        glTexCoord2d 1#, 0#                       ' Second Texture Coord
        glVertex2f 1#, 1#                         ' Second Vertex
        glTexCoord2d 1#, 1#                       ' Third Texture Coord
        glVertex2f 1#, -1#                        ' Third Vertex
        glTexCoord2d 0#, 1#                       ' Fourth Texture Coord
        glVertex2f -1#, -1#                       ' Fourth Vertex
    glEnd                                ' Done Drawing Our Second Quad

  
    glEnable glcBlend                          ' Enable Blending
    glLoadIdentity                           ' Reset The View

    ' Pulsing Colors Based On Text Position
    glColor3f 1# * Cos(cnt1), 1# * Sin(cnt2), 1# - 0.5 * Cos(cnt1 + cnt2)

    glPrint Int(280 + 250 * Cos(cnt1)), Int(235 + 200 * Sin(cnt2)), "NeHe", 0 ' Print GL Text To The Screen

    glColor3f 1# * Sin(cnt2), 1# - 0.5 * Cos(cnt1 + cnt2), 1# * Cos(cnt1)
    glPrint Int(280 + 230 * Cos(cnt2)), Int(235 + 200 * Sin(cnt1)), "OpenGL", 1 ' Print GL Text To The Screen

    glColor3f 0#, 0#, 1#                            ' Set Color To Red
    glPrint Int(240 + 200 * Cos((cnt2 + cnt1) / 5)), 2, "Giuseppe D'Agata", 0 ' Draw Text To The Screen

    glColor3f 1#, 1#, 1#                            ' Set Color To White
    glPrint Int(242 + 200 * Cos((cnt2 + cnt1) / 5)), 2, "Giuseppe D'Agata", 0 ' Draw Offset Text To The Screen

    cnt1 = cnt1 + 0.01                              ' Increase The First Counter
    cnt2 = cnt2 + 0.0081                             ' Increase The Second Counter

    DrawGLScene = True                                 ' Keep Going

End Function

