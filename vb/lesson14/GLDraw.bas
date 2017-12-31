Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    glClear clrColorBufferBit Or clrDepthBufferBit  ' Clear The Screen And The Depth Buffer
    glLoadIdentity                                  ' Reset The Current Modelview Matrix
    glTranslatef 0#, 0#, -10#                 ' Move Ten Units Into The Screen

    glRotatef rot, 1#, 0#, 0#                 ' Rotate On The X Axis
    glRotatef rot * 1.5, 0#, 1#, 0#           ' Rotate On The Y Axis
    glRotatef rot * 1.4, 0#, 0#, 1#           ' Rotate On The Z Axis

    ' Pulsing Colors Based On The Rotation
    glColor3f 1# * Cos(rot / 20#), 1# * Sin(rot / 25#), 1# - 0.5 * Cos(rot / 17#)

    glPrint "NeHe - " & Format$(rot / 50, "##0.00")          ' Print GL Text To The Screen

    rot = rot + 0.5                     ' Increase The Rotation Variable
    DrawGLScene = True                              ' Everything Went OK
End Function

