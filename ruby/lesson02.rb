# (c) 2004 Ben Goodspeed
# Lesson 2-Ruby, based on the tutorials at nehe.gamedev.net
#   based on Jeff Molofee (1999), Cora Hessey (2002)(perl port).
#
# Requires the ruby opengl bindings from: http://www2.giganet.net/~yoshi/
require "opengl"
require "glut"

# keycode we match against in the keyboard listener
ESCAPE = 27
$width , $height = 640, 480


initGL = Proc.new {
    # clear to black
    GL.ClearColor(0.0,0.0,0.0,0.0)

    GL.ClearDepth(1.0)
    GL.DepthFunc(GL::LESS);         

    # Enables depth testing with that type
    GL.Enable(GL::DEPTH_TEST);              
    
    # Enables smooth color shading
    GL.ShadeModel(GL::SMOOTH);      

    # Reset the projection matrix
    GL.MatrixMode(GL::PROJECTION);
    GL.LoadIdentity;

    # Calculate the aspect ratio of the Window
    GLU.Perspective(45.0, $width/$height, 0.1, 100.0);

    # Reset the modelview matrix
    GL.MatrixMode(GL::MODELVIEW);


}

display = Proc.new {
    # Clear the screen and the depth buffer
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT);  

    # Reset the view
    GL.LoadIdentity;

    # Move to the left 1.5 units and into the screen 6.0 units
    GL.Translate(-1.5, 0.0, -6.0); 
        
    # -- Draw a triangle --
    GL.Color(1.0,1.0,1.0)
    # Begin drawing a polygon
    GL.Begin(GL::POLYGON);
      GL.Vertex3f( 0.0, 1.0, 0.0);     # Top vertex
      GL.Vertex3f( 1.0, -1.0, 0.0);    # Bottom right vertex
      GL.Vertex3f(-1.0, -1.0, 0.0);    # Bottom left vertex
    # Done with the polygon
    GL.End;

    # Move 3 units to the right
    GL.Translate(3.0, 0.0, 0.0);

    # -- Draw a square (quadrilateral) --
    # Begin drawing a polygon (4 sided)
    GL.Begin(GL::QUADS);
      GL.Vertex3f(-1.0, 1.0, 0.0);       # Top Left vertex
      GL.Vertex3f( 1.0, 1.0, 0.0);       # Top Right vertex
      GL.Vertex3f( 1.0, -1.0, 0.0);      # Bottom Right vertex
      GL.Vertex3f(-1.0, -1.0, 0.0);      # Bottom Left  
    GL.End;                
    GL.Flush
    # Since this is double buffered, swap the buffers.
    # This will display what just got drawn.
    GLUT.SwapBuffers;
}

reshape = Proc.new { |w,h|
    h = 1 if h == 0
    $width, $height = w,h
    GL.Viewport(0, 0, $width, $height);              
    # Re-initialize the window (same lines from InitGL)
    GL.MatrixMode(GL::PROJECTION);
    GL.LoadIdentity;
    GLU.Perspective(45.0, $width/$height, 0.1, 100.0);
    GL.MatrixMode(GL::MODELVIEW);
}

keyboard = Proc.new { |key,x,y|
    case (key)
        when ESCAPE
        exit 0
        when 'f'[0]
        GLUT.ReshapeWindow(640,480)
    end
}




# Initialize glut & open a window
GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB | GLUT::DEPTH)
GLUT.InitWindowSize($width, $height)
GLUT.CreateWindow($0)

# initialize opengl
initGL.call

# add callback functions for some event listeners
GLUT.ReshapeFunc(reshape)
GLUT.DisplayFunc(display)
GLUT.KeyboardFunc(keyboard)
GLUT.FullScreen
# enter the main idle loop
GLUT.MainLoop()

