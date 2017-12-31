Attribute VB_Name = "GLDraw"
Option Explicit

Public Function DrawGLScene() As Boolean
' Here's Where We Do All The Drawing
    glClear clrColorBufferBit Or clrDepthBufferBit      ' Clear Screen And Depth Buffer
    glLoadIdentity                       ' Reset The Current Matrix

    Dim x_m As GLfloat
    Dim y_m As GLfloat
    Dim z_m As GLfloat
    Dim u_m As GLfloat
    Dim v_m As GLfloat                 ' Floating Point For Temp X, Y, Z, U And V Vertices
    Dim xtrans As GLfloat
    Dim ztrans As GLfloat
    Dim ytrans As GLfloat
    Dim sceneroty As GLfloat
    xtrans = -xpos                     ' Used For Player Translation On The X Axis
    ztrans = -zpos                     ' Used For Player Translation On The Z Axis
    ytrans = -walkbias - 0.25              ' Used For Bouncing Motion Up And Down
    sceneroty = 360# - yrot                ' 360 Degree Angle For Player Direction

    Dim numtriangles As Integer                       ' Integer To Hold The Number Of Triangles

    glRotatef lookupdown, 1#, 0#, 0#                 ' Rotate Up And Down To Look Up And Down
    glRotatef sceneroty, 0#, 1#, 0#                 ' Rotate Depending On Direction Player Is Facing
    
    glTranslatef xtrans, ytrans, ztrans               ' Translate The Scene Based On Player Position
    glBindTexture glTexture2D, Texture(mFilter)           ' Select A Texture Based On filter
    
    numtriangles = Sector1.numtriangles                ' Get The Number Of Triangles In Sector 1
    
    ' Process Each Triangle
    Dim loop_m As Integer
    For loop_m = 0 To numtriangles - 1       ' Loop Through All The Triangles
        glBegin bmTriangles                   ' Start Drawing Triangles
            glNormal3f 0#, 0#, 1#                 ' Normal Pointing Forward
            x_m = Sector1.triangle(loop_m).Vertex(0).x ' X Vertex Of 1st Point
            y_m = Sector1.triangle(loop_m).Vertex(0).y ' Y Vertex Of 1st Point
            z_m = Sector1.triangle(loop_m).Vertex(0).z ' Z Vertex Of 1st Point
            u_m = Sector1.triangle(loop_m).Vertex(0).u ' U Texture Coord Of 1st Point
            v_m = Sector1.triangle(loop_m).Vertex(0).v ' V Texture Coord Of 1st Point
            glTexCoord2f u_m, v_m: glVertex3f x_m, y_m, z_m ' Set The TexCoord And Vertice
            
            x_m = Sector1.triangle(loop_m).Vertex(1).x ' X Vertex Of 2nd Point
            y_m = Sector1.triangle(loop_m).Vertex(1).y ' Y Vertex Of 2nd Point
            z_m = Sector1.triangle(loop_m).Vertex(1).z ' Z Vertex Of 2nd Point
            u_m = Sector1.triangle(loop_m).Vertex(1).u ' U Texture Coord Of 2nd Point
            v_m = Sector1.triangle(loop_m).Vertex(1).v ' V Texture Coord Of 2nd Point
            glTexCoord2f u_m, v_m: glVertex3f x_m, y_m, z_m ' Set The TexCoord And Vertice
            
            x_m = Sector1.triangle(loop_m).Vertex(2).x ' X Vertex Of 3rd Point
            y_m = Sector1.triangle(loop_m).Vertex(2).y ' Y Vertex Of 3rd Point
            z_m = Sector1.triangle(loop_m).Vertex(2).z ' Z Vertex Of 3rd Point
            u_m = Sector1.triangle(loop_m).Vertex(2).u ' U Texture Coord Of 3rd Point
            v_m = Sector1.triangle(loop_m).Vertex(2).v ' V Texture Coord Of 3rd Point
            glTexCoord2f u_m, v_m: glVertex3f x_m, y_m, z_m ' Set The TexCoord And Vertice
        glEnd                        ' Done Drawing Triangles
    Next loop_m
    DrawGLScene = True                                 ' Keep Going

End Function

