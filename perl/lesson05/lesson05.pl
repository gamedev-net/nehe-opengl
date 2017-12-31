#! /usr/bin/perl -w
#
# This code was created by Jeff Molofee '99 
# Ported to Perl by Cora Hussey '02
#
# If this was helpful, let me know.
# Visit me at www.cs.ucla.edu/~chussey
#
# Requires OpenGL module in addition to OpenGL
#   (visit www.cpan.org or "perl -MCPAN -e 'install OpenGL'")
#

use OpenGL qw(:all);    # Use the OpenGL module
use strict;             # Use strict typechecking

# ASCII constant for the escape key
use constant ESCAPE => 27;

# Global variable for our window
my $window;

# Rotation variables for triangle and quad
my $rtri  = 0.0;
my $rquad = 0.0;

# A general GL initialization function 
# Called right after our OpenGL window is created
# Sets all of the initial parameters
sub InitGL {              

    # Shift the width and height off of @_, in that order
    my ($width, $height) = @_;

    # Set the background "clearing color" to black
    glClearColor(0.0, 0.0, 0.0, 0.0);

    # Enables clearing of the Depth buffer 
    glClearDepth(1.0);                    

    # The type of depth test to do
    glDepthFunc(GL_LESS);         

    # Enables depth testing with that type
    glEnable(GL_DEPTH_TEST);              
    
    # Enables smooth color shading
    glShadeModel(GL_SMOOTH);      

    # Reset the projection matrix
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;

    # Calculate the aspect ratio of the Window
    gluPerspective(45.0, $width/$height, 0.1, 100.0);

    # Reset the modelview matrix
    glMatrixMode(GL_MODELVIEW);
}


# The function called when our window is resized 
# This shouldn't happen, because we're fullscreen
sub ReSizeGLScene {

    # Shift width and height off of @_, in that order
    my ($width, $height) = @_;

    # Prevent divide by zero error if window is too small
    if ($height == 0) { $height = 1; }

    # Reset the current viewport and perspective transformation
    glViewport(0, 0, $width, $height);              

    # Re-initialize the window (same lines from InitGL)
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(45.0, $width/$height, 0.1, 100.0);
    glMatrixMode(GL_MODELVIEW);
}

# The main drawing function.
sub DrawGLScene {

    # Clear the screen and the depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  

    # Reset the view
    glLoadIdentity;

    # Move to the left 1.5 units and into the screen 6.0 units
    glTranslatef(-1.5, 0.0, -6.0); 
    
    # Rotate the triangle on the y axis 
    # Order is (degrees, x, y, z), set to 1.0 your rotation axis
    glRotatef($rtri, 0.0, 1.0, 0.0); 
    
    # -- Draw a pyramid (in smooth coloring mode) --

    # Begin drawing a polygon
    # Note that each face (of 4) must be shaded
    glBegin(GL_POLYGON);

    # Front face of pyramid
    glColor3f(1.0, 0.0, 0.0);       # Set the color to red
    glVertex3f(0.0, 1.0, 0.0);      # Top of triangle (front of pyramid)
    glColor3f(0.0, 1.0, 0.0);       # Set the color to green
    glVertex3f(-1.0, -1.0, 1.0);    # Left of triangle (front of pyramid)
    glColor3f(0.0, 0.0, 1.0);       # Set the color to blue
    glVertex3f(1.0, -1.0, 1.0);     # Right of traingle (front of pyramid)    

    # Right face of pyramid
    glColor3f(1.0, 0.0, 0.0);       # Red color
    glVertex3f(0.0, 1.0, 0.0);      # Top of triangle (right of pyramid)
    glColor3f(0.0, 0.0, 1.0);       # Blue color
    glVertex3f(1.0, -1.0, 1.0);     # Left of triangle (right of pyramid)
    glColor3f(0.0, 1.0, 0.0);       # Green color
    glVertex3f(1.0, -1.0, -1.0);    # Right of triangle (right of pyramid)

    # Back face of pyramid
    glColor3f(1.0, 0.0, 0.0);       # Red color
    glVertex3f(0.0, 1.0, 0.0);      # Top of triangle (back of pyramid)
    glColor3f(0.0, 1.0, 0.0);       # Green color
    glVertex3f(1.0, -1.0, -1.0);    # Left of triangle (back of pyramid)
    glColor3f(0.0, 0.0, 1.0);       # Blue color
    glVertex3f(-1.0, -1.0, -1.0);   # Right of triangle (back of pyramid)

    # Left face of pyramid.
    glColor3f(1.0, 0.0, 0.0);       # Red color
    glVertex3f(0.0, 1.0, 0.0);      # Top of triangle (left of pyramid)
    glColor3f(0.0, 0.0, 1.0);       # Blue color
    glVertex3f(-1.0, -1.0, -1.0);   # Left of triangle (left of pyramid)
    glColor3f(0.0, 1.0, 0.0);       # Green color
    glVertex3f(-1.0, -1.0, 1.0);    # Right of triangle (left of pyramid)

    # Done with the polygon
    glEnd;

    # Reset the screen
    glLoadIdentity;

    # Move to the right 1.5 units and into the screen 6.0 units
    glTranslatef(1.5, 0.0, -6.0); 

    # Rotate the quad on the x y and z axis
    glRotatef($rquad, 1.0, 1.0, 1.0);
        
    # -- Draw a cube (6 quadrilaterals) --

    # Set color to a blue color
    glColor3f(0.5, 0.5, 1.0);

    # Begin drawing the cube
    glBegin(GL_QUADS);

    # Top face of cube
    glColor3f(0.0, 1.0, 0.0);       # Set the color to Blue
    glVertex3f(1.0, 1.0, -1.0);     # Top right vertex (Top of cube)
    glVertex3f(-1.0, 1.0, -1.0);    # Top left vertex (Top of cube)
    glVertex3f(-1.0, 1.0, 1.0);     # Bottom left vertex (Top of cube)
    glVertex3f(1.0, 1.0, 1.0);      # Bottom right vertex (Top of cube)

    # Bottom face of cube
    glColor3f(1.0, 0.5, 0.0);       # Set the color to Orange
    glVertex3f(1.0, -1.0, 1.0);     # Top right vertex (Bottom of cube)
    glVertex3f(-1.0, -1.0, 1.0);    # Top left vertex (Bottom of cube)
    glVertex3f(-1.0, -1.0, -1.0);   # Bottom left vertex (Bottom of cube)
    glVertex3f( 1.0, -1.0, -1.0);   # Bottom right vertex (Bottom of cube)

    # Front of cube
    glColor3f(1.0, 0.0, 0.0);       # Set the color to Red
    glVertex3f(1.0, 1.0, 1.0);      # Top right vertex (Front)
    glVertex3f(-1.0, 1.0, 1.0);     # Top left vertex (Front)
    glVertex3f(-1.0, -1.0, 1.0);    # Bottom left vertex (Front)
    glVertex3f(1.0, -1.0, 1.0);     # Bottom right vertex (Front)

    # Back of cube.
    glColor3f(1.0, 1.0, 0.0);       # Set the color to Yellow
    glVertex3f(1.0, -1.0, -1.0);    # Top right vertex (Back)
    glVertex3f(-1.0, -1.0, -1.0);   # Top left vertex (Back)
    glVertex3f(-1.0, 1.0, -1.0);    # Bottom left vertex (Back)
    glVertex3f(1.0, 1.0, -1.0);     # Bottom right vertex (Back)

    # Left of cube
    glColor3f(0.0, 0.0, 1.0);       # Blue
    glVertex3f(-1.0, 1.0, 1.0);     # Top right vertex (Left)
    glVertex3f(-1.0, 1.0, -1.0);    # Top left vertex (Left)
    glVertex3f(-1.0, -1.0, -1.0);   # Bottom left vertex (Left)
    glVertex3f(-1.0, -1.0, 1.0);    # Bottom vertex (Left)

    # Right of cube
    glColor3f(1.0, 0.0, 1.0);       # Violet
    glVertex3f(1.0, 1.0, -1.0);     # Top right vertex (Right)
    glVertex3f(1.0, 1.0, 1.0);      # Top left vertex (Right)
    glVertex3f(1.0, -1.0, 1.0);     # Bottom left vertex (Right)
    glVertex3f(1.0, -1.0, -1.0);    # Bottom right vertex (Right)

    # End drawing the cube
    glEnd;                

    # Increase rotation angle for triangle, decrease for quad
    $rtri  = $rtri  + 15.0; 
    $rquad = $rquad - 15.0; 

    # Since this is double buffered, swap the buffers.
    # This will display what just got drawn.
    glutSwapBuffers;
}

# The function called whenever a key is pressed. 
sub keyPressed {

    # Shift the unsigned char key, and the x,y placement off @_, in
    # that order.
    my ($key, $x, $y) = @_;
    
    # Avoid thrashing this procedure
    # Note standard Perl does not support usleep
    # For finer resolution sleep than seconds, try:
    #    'select undef, undef, undef, 0.1;'
    # to sleep for (at least) 0.1 seconds
    sleep(100);

    # If f key pressed, undo fullscreen and resize to 640x480
    if ($key == ord('f')) {

        # Use reshape window, which undoes fullscreen
        glutReshapeWindow(640, 480);
    }

    # If escape is pressed, kill everything.
    if ($key == ESCAPE) 
    { 
        # Shut down our window 
        glutDestroyWindow($window); 
        
        # Exit the program...normal termination.
        exit(0);                   
    }
}

# --- Main program ---

# Initialize GLUT state
glutInit;  

# Select type of Display mode:   
# Double buffer 
# RGB color (Also try GLUT_RGBA)
# Alpha components removed (try GLUT_ALPHA) 
# Depth buffer */  
glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);  

# Get a 640 x 480 window
glutInitWindowSize(640, 480);  

# The window starts at the upper left corner of the screen
glutInitWindowPosition(0, 0);  

# Open the window  
$window = glutCreateWindow("Jeff Molofee's GL Code Tutorial ... NeHe '99");  

# Register the function to do all our OpenGL drawing.
glutDisplayFunc(\&DrawGLScene);  

# Go fullscreen.  This is as soon as possible. 
glutFullScreen;

# Even if there are no events, redraw our gl scene.
glutIdleFunc(\&DrawGLScene);

# Register the function called when our window is resized. 
glutReshapeFunc(\&ReSizeGLScene);

# Register the function called when the keyboard is pressed.
glutKeyboardFunc(\&keyPressed);

# Initialize our window.
InitGL(640, 480);
  
# Start Event Processing Engine
glutMainLoop;  

return 1;


