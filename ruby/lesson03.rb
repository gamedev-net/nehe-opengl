# This code was created by Jeff Molofee '99 
# Conversion to Ruby by Manolo Padron Martinez (manolopm@cip.es)

require "opengl"
require "glut"


# A general OpenGL initialization function.  Sets all of the initial parameters

def InitGL(width, height) # We call this right after our OpenGL window 
                          # is created.

  GL.ClearColor(0.0, 0.0, 0.0, 0.0) # This Will Clear The Background 
                                    # Color To Black
  GL.ClearDepth(1.0)                # Enables Clearing Of The Depth Buffer
  GL.DepthFunc(GL::LESS)            # The Type Of Depth Test To Do
  GL.Enable(GL::DEPTH_TEST)         # Enables Depth Testing
  GL.ShadeModel(GL::SMOOTH)         # Enables Smooth Color Shading
  GL.MatrixMode(GL::PROJECTION)
  GL.LoadIdentity()                 # Reset The Projection Matrix
  GLU.Perspective(45.0,Float(width)/Float(height),0.1,100.0) # Calculate The Aspect Ratio 
                                               # Of The Window
  GL.MatrixMode(GL::MODELVIEW)
end

# The function called when our window is resized (which shouldn't happen, 
# because we're fullscreen) 
ReSizeGLScene = Proc.new {|width, height|
  if (height==0) # Prevent A Divide By Zero If The Window Is Too Small
    height=1
  end
  GL.Viewport(0,0,width,height) # Reset The Current Viewport And
                                # Perspective Transformation
  GL.MatrixMode(GL::PROJECTION)
  GL.LoadIdentity()
  GLU.Perspective(45.0,Float(width)/Float(height),0.1,100.0)
  GL.MatrixMode(GL::MODELVIEW)
}

# The main drawing function. 
DrawGLScene = Proc.new {
  GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT) # Clear The Screen And
                                          # The Depth Buffer
  GL.LoadIdentity()                       # Reset The View
  GL.Translate(-1.5, 0.0, -6.0)           # Move Left 1.5 Units And Into The 
                                          # Screen 6.0

  # draw a triangle (in smooth coloring mode)
  GL.Begin(GL::POLYGON)                   # start drawing a polygon
  GL.Color3f(  1.0, 0.0, 0.0)             # Set The Color To Red
  GL.Vertex3f( 0.0, 1.0, 0.0)             # Top
  GL.Color3f(  0.0, 1.0, 0.0)             # Set The Color To Green
  GL.Vertex3f( 1.0,-1.0, 0.0)             # Bottom Right
  GL.Color3f(  0.0, 0.0, 1.0)             # Set The Color To Blue
  GL.Vertex3f(-1.0,-1.0, 0.0)             # Bottom Left  
  GL.End()                                # we're done with the polygon 
                                          # (smooth color interpolation)    
  GL.Translate(3.0,0.0,0.0)               # Move Right 3 Units

  # draw a square (quadrilateral)
  GL.Color3f(0.5,0.5,1.0)                 # set color to a blue shade.
  GL.Begin(GL::QUADS)                     # start drawing a polygon (4 
                                          # sided)
  GL.Vertex3f(-1.0, 1.0, 0.0)             # Top Left
  GL.Vertex3f( 1.0, 1.0, 0.0)             # Top Right
  GL.Vertex3f( 1.0,-1.0, 0.0)             # Bottom Right
  GL.Vertex3f(-1.0,-1.0, 0.0)             # Bottom Left  
  GL.End();                               # done with the polygon

  # we need to swap the buffer to display our drawing.
  GLUT.SwapBuffers();
}



# The function called whenever a key is pressed.
keyPressed = Proc.new {|key, x, y| 

  # If escape is pressed, kill everything. 
  if (key == 27) 
    # shut down our window 
    GLUT.DestroyWindow($window)
    # exit the program...normal termination.
    exit(0)                   
  end
}


#Initialize GLUT state - glut will take any command line arguments that pertain
# to it or X Windows - look at its documentation at 
# http://reality.sgi.com/mjk/spec3/spec3.html 
GLUT.Init

#Select type of Display mode:   
# Double buffer 
# RGBA color
# Alpha components supported 
# Depth buffer 
GLUT.InitDisplayMode(GLUT::RGBA|GLUT::DOUBLE|GLUT::ALPHA|GLUT::DEPTH)

# get a 640x480 window
GLUT.InitWindowSize(640,480)

# the window starts at the upper left corner of the screen
GLUT.InitWindowPosition(0,0)

# Open a window
$window=GLUT.CreateWindow("Jeff Molofee's GL Code Tutorial ... NeHe '99")

# Register the function to do all our OpenGL drawing.
GLUT.DisplayFunc(DrawGLScene)

# Go fullscreen. This is as soon as possible.
GLUT.FullScreen()

# Even if there are no events, redraw our gl scene.
GLUT.IdleFunc(DrawGLScene)

# Register the function called when our window is resized.
GLUT.ReshapeFunc(ReSizeGLScene)

# Register the function called when the keyboard is pressed.
GLUT.KeyboardFunc(keyPressed)

# Initialize our window.
InitGL(640, 480)

# Start Event Processing Engine
GLUT.MainLoop()
