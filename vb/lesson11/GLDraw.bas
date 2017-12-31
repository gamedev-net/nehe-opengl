Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    Dim x As Integer
    Dim y As Integer                       ' Loop Variables
    Dim float_x As Double
    Dim float_y As Double
    Dim float_xb As Double
    Dim float_yb As Double      ' Used To Break The Flag Into Tiny Quads

    glClear clrColorBufferBit Or clrDepthBufferBit  ' Clear The Screen And Depth Buffer
    glLoadIdentity                   ' Reset The Current Matrix

    glTranslatef 0#, 0#, -12#                 ' Translate 17 Units Into The Screen

    glRotatef xrot, 1#, 0#, 0#                ' Rotate On The X Axis
    glRotatef yrot, 0#, 1#, 0#                ' Rotate On The Y Axis
    glRotatef zrot, 0#, 0#, 1#                ' Rotate On The Z Axis

    glBindTexture glTexture2D, Texture(0)        ' Select Our Texture

    glBegin bmQuads                   ' Start Drawing Our Quads
    For x = 0 To 43              ' Loop Through The X Plane 0-44 (45 Points)
        For y = 0 To 43            ' Loop Through The Y Plane 0-44 (45 Points)

            float_x = CDbl(x) / 44#       ' Create A Floating Point X Value
            float_y = CDbl(y) / 44#       ' Create A Floating Point Y Value
            float_xb = CDbl(x + 1) / 44#      ' Create A Floating Point Y Value+0.0227f
            float_yb = CDbl(y + 1) / 44#      ' Create A Floating Point Y Value+0.0227f

            glTexCoord2f float_x, float_y     ' First Texture Coordinate (Bottom Left)
            glVertex3f points(x, y, 0), points(x, y, 1), points(x, y, 2)
            
            glTexCoord2f float_x, float_yb    ' Second Texture Coordinate (Top Left)
            glVertex3f points(x, y + 1, 0), points(x, y + 1, 1), points(x, y + 1, 2)
            
            glTexCoord2f float_xb, float_yb   ' Third Texture Coordinate (Top Right)
            glVertex3f points(x + 1, y + 1, 0), points(x + 1, y + 1, 1), points(x + 1, y + 1, 2)
            
            glTexCoord2f float_xb, float_y   ' Fourth Texture Coordinate (Bottom Right)
            glVertex3f points(x + 1, y, 0), points(x + 1, y, 1), points(x + 1, y, 2)
        Next y
    Next x
    glEnd                        ' Done Drawing Our Quads
    If wiggle_count = 2 Then                   ' Used To Slow Down The Wave (Every 2nd Frame Only)
        For y = 0 To 44           ' Loop Through The Y Plane
            hold = points(0, y, 2)       ' Store Current Value One Left Side Of Wave
            For x = 0 To 43        ' Loop Through The X Plane
                ' Current Wave Value Equals Value To The Right
                points(x, y, 2) = points(x + 1, y, 2)
            Next x
            points(44, y, 2) = hold      ' Last Value Becomes The Far Left Stored Value
        Next y
        wiggle_count = 0               ' Set Counter Back To Zero
    End If
    wiggle_count = wiggle_count + 1                    ' Increase The Counter
    xrot = xrot + 0.3                    ' Increase The X Rotation Variable
    yrot = yrot + 0.2                   ' Increase The Y Rotation Variable
    zrot = zrot + 0.4                     ' Increase The Z Rotation Variable

    DrawGLScene = True                        ' Jump Back


End Function

