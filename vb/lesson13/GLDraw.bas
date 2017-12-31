Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    glClear clrColorBufferBit Or clrDepthBufferBit  ' Clear The Screen And The Depth Buffer
    glLoadIdentity                                  ' Reset The Current Modelview Matrix
    glTranslatef 0#, 0#, -1#                  ' Move One Unit Into The Screen

    ' Pulsing Colors Based On Text Position
    glColor3f 1# * Cos(cnt1), 1# * Sin(cnt2), 1# - 0.5 * Cos(cnt1 + cnt2)
    ' Position The Text On The Screen
    glRasterPos2f -0.45 + 0.05 * Cos(cnt1), 0.35 * Sin(cnt2)

    glPrint "Active OpenGL Text With NeHe - " & Format$(cnt1, "####0.##")  ' Print GL Text To The Screen

    cnt1 = cnt1 + 0.051                    ' Increase The First Counter
    cnt2 = cnt2 + 0.005                      ' Increase The Second Counter

    DrawGLScene = True                              ' Everything Went OK
End Function

