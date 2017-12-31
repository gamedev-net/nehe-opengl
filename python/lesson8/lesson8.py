
"""

 This code was created by Jeff Molofee '99 (ported to Solaris/GLUT by Lakmal Gunasekara '99)

 If you've found this code useful, please let me know.

 Visit me at www.demonews.com/hosted/nehe
 (email Richard Campbell at ulmont@bellsouth.net)
 (email Lakmal Gunasekara at lakmal@gunasekara.de)

"""

"""
  Ported to Python by Ryan Showalter '04
  tankcoder@warpmail.net
  
  This is pretty much an exact port from the C code,
  please use this as refence and not as an example
  of how to program well (or at all) in OO.
"""

from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *
import time
import struct
import sys
from operator import *
from Image import *

# ascii codes for various special keys
ESCAPE = 27
PAGE_UP = 73
PAGE_DOWN = 81
UP_ARROW = 72
DOWN_ARROW = 80
LEFT_ARROW = 75
RIGHT_ARROW = 77

# The number of our GLUT window
window = None

# lighting on/off (1 = on, 0 = off) 
light = 0


xrot = 0   # x rotation
yrot = 0   # y rotation
xspeed = 0 # x rotation speed
yspeed = 0 # y rotation speed

z = -5.0  # depth into the screen.

# white ambient light at half intensity (rgba)
LightAmbient = [ 0.5, 0.5, 0.5, 1.0 ]

# super bright, full intensity diffuse light.
LightDiffuse = [ 1.0, 1.0, 1.0, 1.0 ]

# position of light (x, y, z, (position of light))
LightPosition = [ 0.0, 0.0, 2.0, 1.0 ]

filter = 0			# Which Filter To Use (nearest/linear/mipmapped)
texture = range(3)		# Storage for 3 textures.
blend = 0                  # Turn blending on/off

# Image type - contains height, width, and data 
class Image:
    sizeX = None
    sizeY = None
    data = None


def ImageLoad(filename, image):
    #PIL makes life easy...

    poo = open(filename)
	
    image.sizeX = poo.size[0]
    image.sizeY = poo.size[1]
    image.data = poo.tostring("raw", "RGBX", 0, -1)

# Load Bitmaps And Convert To Textures
def LoadGLTextures():
    # Load Texture
    image1 = Image()


    try:
    	ImageLoad("Data/lesson8/glass.bmp", image1)
    except:
    	print "Image Loading Failed, look into this"
        sys.exit()

    # Create Textures
    texture = glGenTextures(3)

    # texture 1 (poor quality scaling)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)  # cheap scaling when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)  # cheap scaling when image smalled than texture

    # 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image,
    # border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data)
    glBindTexture(GL_TEXTURE_2D, texture[0])   # 2d texture (x and y size)

    # texture 2 (linear scaling)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)  # scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)  # scale linearly when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data);
    glBindTexture(GL_TEXTURE_2D, texture[1])    # 2d texture (x and y size)

    # texture 3 (mipmapped scaling)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)  # scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST)  # scale linearly + mipmap when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data)

    # 2d texture, 3 colors, width, height, RGB in that order, byte data, and the data.
    gluBuild2DMipmaps(GL_TEXTURE_2D, 4, image1.sizeX, image1.sizeY, GL_RGBA, GL_UNSIGNED_BYTE, image1.data)
    glBindTexture(GL_TEXTURE_2D, texture[2])    # 2d texture (x and y size)
    

# A general OpenGL initialization function.  Sets all of the initial parameters.
def InitGL(Width, Height):	# We call this right after our OpenGL window is created.

    LoadGLTextures()                            # load the textures.
    glEnable(GL_TEXTURE_2D)                     # Enable texture mapping.
 
    glClearColor(0.0, 0.0, 0.0, 0.0)    	# This Will Clear The Background Color To Black
    glClearDepth(1.0)				# Enables Clearing Of The Depth Buffer
    glDepthFunc(GL_LESS)			# The Type Of Depth Test To Do
    glEnable(GL_DEPTH_TEST)			# Enables Depth Testing
    glShadeModel(GL_SMOOTH)			# Enables Smooth Color Shading

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()				# Reset The Projection Matrix

    gluPerspective(45.0,float(Width)/float(Height),0.1,100.0)	# Calculate The Aspect Ratio Of The Window

    glMatrixMode(GL_MODELVIEW)

    # set up light number 1.
    glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient)  # add lighting. (ambient)
    glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse)  # add lighting. (diffuse).
    glLightfv(GL_LIGHT1, GL_POSITION,LightPosition) # set light position.
    glEnable(GL_LIGHT1)                             # turn light 1 on.

    # setup blending
    glBlendFunc(GL_SRC_ALPHA,GL_ONE)			# Set The Blending Function For Translucency
    glColor4f(1.0, 1.0, 1.0, 0.5)

# The function called when our window is resized (which shouldn't happen, because we're fullscreen)
def ReSizeGLScene(Width, Height):

    if (Height==0):				# Prevent A Divide By Zero If The Window Is Too Small
	Height=1

    glViewport(0, 0, Width, Height)		# Reset The Current Viewport And Perspective Transformation

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    gluPerspective(45.0,float(Width)/float(Height),0.1,100.0)
    glMatrixMode(GL_MODELVIEW)


# The main drawing function.
def DrawGLScene():
    global xrot, yrot

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)		# Clear The Screen And The Depth Buffer
    glLoadIdentity()				# Reset The View

    glTranslatef(0.0,0.0,z)                     # move z units out from the screen.

    glRotatef(xrot,1.0,0.0,0.0)			# Rotate On The X Axis
    glRotatef(yrot,0.0,1.0,0.0)			# Rotate On The Y Axis

    glBindTexture(GL_TEXTURE_2D, texture[filter])   # choose the texture to use.

    glBegin(GL_QUADS)		                # begin drawing a cube

    # Front Face (note that the texture's corners have to match the quad's corners)
    glNormal3f( 0.0, 0.0, 1.0);                              # front face points out of the screen on z.
    
    glTexCoord2f(0.0, 0.0)
    glVertex3f(-1.0, -1.0,  1.0)	# Bottom Left Of The Texture and Quad
    
    glTexCoord2f(1.0, 0.0) 
    glVertex3f( 1.0, -1.0,  1.0)	# Bottom Right Of The Texture and Quad
    
    glTexCoord2f(1.0, 1.0) 
    glVertex3f( 1.0,  1.0,  1.0)	# Top Right Of The Texture and Quad
    
    glTexCoord2f(0.0, 1.0) 
    glVertex3f(-1.0,  1.0,  1.0)	# Top Left Of The Texture and Quad

    # Back Face
    glNormal3f( 0.0, 0.0,-1.0)                              # back face points into the screen on z.
    glTexCoord2f(1.0, 0.0) 
    glVertex3f(-1.0, -1.0, -1.0)	# Bottom Right Of The Texture and Quad
    
    glTexCoord2f(1.0, 1.0) 
    glVertex3f(-1.0,  1.0, -1.0)	# Top Right Of The Texture and Quad
    
    glTexCoord2f(0.0, 1.0) 
    glVertex3f( 1.0,  1.0, -1.0)	# Top Left Of The Texture and Quad
    
    glTexCoord2f(0.0, 0.0) 
    glVertex3f( 1.0, -1.0, -1.0)	# Bottom Left Of The Texture and Quad

    # Top Face
    glNormal3f( 0.0, 1.0, 0.0)                              # top face points up on y.
    
    glTexCoord2f(0.0, 1.0) 
    glVertex3f(-1.0,  1.0, -1.0)	# Top Left Of The Texture and Quad
    
    glTexCoord2f(0.0, 0.0) 
    glVertex3f(-1.0,  1.0,  1.0)	# Bottom Left Of The Texture and Quad
    
    glTexCoord2f(1.0, 0.0) 
    glVertex3f( 1.0,  1.0,  1.0)	# Bottom Right Of The Texture and Quad
    
    glTexCoord2f(1.0, 1.0) 
    glVertex3f( 1.0,  1.0, -1.0)	# Top Right Of The Texture and Quad

    # Bottom Face
    glNormal3f( 0.0, -1.0, 0.0)                             # bottom face points down on y.
    
    glTexCoord2f(1.0, 1.0) 
    glVertex3f(-1.0, -1.0, -1.0)	# Top Right Of The Texture and Quad
    
    glTexCoord2f(0.0, 1.0) 
    glVertex3f( 1.0, -1.0, -1.0)	# Top Left Of The Texture and Quad
    
    glTexCoord2f(0.0, 0.0) 
    glVertex3f( 1.0, -1.0,  1.0)	# Bottom Left Of The Texture and Quad
    
    glTexCoord2f(1.0, 0.0) 
    glVertex3f(-1.0, -1.0,  1.0)	# Bottom Right Of The Texture and Quad

    # Right face
    glNormal3f( 1.0, 0.0, 0.0)                              # right face points right on x.
    
    glTexCoord2f(1.0, 0.0) 
    glVertex3f( 1.0, -1.0, -1.0)	# Bottom Right Of The Texture and Quad
    
    glTexCoord2f(1.0, 1.0) 
    glVertex3f( 1.0,  1.0, -1.0)	# Top Right Of The Texture and Quad
    
    glTexCoord2f(0.0, 1.0) 
    glVertex3f( 1.0,  1.0,  1.0)	# Top Left Of The Texture and Quad
    
    glTexCoord2f(0.0, 0.0) 
    glVertex3f( 1.0, -1.0,  1.0)	# Bottom Left Of The Texture and Quad

    # Left Face
    glNormal3f(-1.0, 0.0, 0.0)                              # left face points left on x.
    
    glTexCoord2f(0.0, 0.0) 
    glVertex3f(-1.0, -1.0, -1.0)	# Bottom Left Of The Texture and Quad
    
    glTexCoord2f(1.0, 0.0) 
    glVertex3f(-1.0, -1.0,  1.0)	# Bottom Right Of The Texture and Quad
    
    glTexCoord2f(1.0, 1.0) 
    glVertex3f(-1.0,  1.0,  1.0)	# Top Right Of The Texture and Quad
    
    glTexCoord2f(0.0, 1.0) 
    glVertex3f(-1.0,  1.0, -1.0)	# Top Left Of The Texture and Quad

    glEnd()                                    # done with the polygon.

    xrot+=xspeed		               # X Axis Rotation
    yrot+=yspeed		               #  Y Axis Rotation

    # since this is double buffered, swap the buffers to display what just got drawn.
    glutSwapBuffers()


# The function called whenever a normal key is pressed. 
def keyPressed(key, x, y):
    global light, filter, blend
    
    key = ord(key)

    # avoid thrashing this procedure 
    time.sleep(0.01)

    if key == ESCAPE:
	# shut down our window 
	glutDestroyWindow(window)

	# exit the program...normal termination. 
	sys.exit()

    elif key == 108 or key == 76: # switch the lighting.
	print("L/l pressed; light is: %d\n"%(light))
	if light == 0:
		light = 1
	else:
		light = 0      # switch the current value of light, between 0 and 1.
		
	print("Light is now: %d\n"%(light))
	
	if not(light):
	    glDisable(GL_LIGHTING);
	else:
	    glEnable(GL_LIGHTING);

    elif key == 102 or key == 70: # switch the filter.
	print("F/f pressed; filter is: %d\n"%(filter))
	filter+=1
	if (filter>2):
	    filter=0
	    
	print("Filter is now: %d\n"%(filter))


    elif key == 130 or key == 98: # switch the blending.
	print("B/b pressed; blending is: %d\n"%(blend))
	if blend == 0:		# switch the current value of blend, between 0 and 1.
		blend = 1
	else:
		blend = 0
	 
	print("Blend is now: %d\n"%(blend))
	
	if not(blend):
	  glDisable(GL_BLEND)              # Turn Blending Off
	  glEnable(GL_DEPTH_TEST)          # Turn Depth Testing On
	else:
	  glEnable(GL_BLEND)		    # Turn Blending On
	  glDisable(GL_DEPTH_TEST)         # Turn Depth Testing Off

    else:
      print("Key %d pressed. No action there yet.\n"%(key))
      
      

# The function called whenever a normal key is pressed. 
def specialKeyPressed(key, x, y):
    global z, xspeed, yspeed

    # avoid thrashing this procedure 
    time.sleep(0.01)

    
    if key == GLUT_KEY_PAGE_UP: # move the cube into the distance.
	z-=0.02


    elif key == GLUT_KEY_PAGE_DOWN: # move the cube closer.
	z+=0.02


    elif key == GLUT_KEY_UP: # decrease x rotation speed;
	xspeed-=0.01


    elif key == GLUT_KEY_DOWN: # increase x rotation speed;
	xspeed+=0.01


    elif key == GLUT_KEY_LEFT: # decrease y rotation speed;
	yspeed-=0.01


    elif key == GLUT_KEY_RIGHT: # increase y rotation speed;
	yspeed+=0.01


def main():
    global window

    #   Initialize GLUT state - glut will take any command line arguments that pertain to it or
    #   X Windows - look at its documentation at http:reality.sgi.com/mjk/spec3/spec3.html 
    glutInit(sys.argv)

    # Select type of Display mode:
    # Double buffer
    # RGBA color
    # Depth buffer
    # Alpha blending 
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA)

    # get a 640 x 480 window 
    glutInitWindowSize(640, 480)

    # the window starts at the upper left corner of the screen 
    glutInitWindowPosition(0, 0)

    # Open a window 
    window = glutCreateWindow("Jeff Molofee's GL Code Tutorial ... NeHe '99")

    # Register the function to do all our OpenGL drawing. 
    glutDisplayFunc(DrawGLScene)

    # Go fullscreen.  This is as soon as possible. 
    glutFullScreen()

    # Even if there are no events, redraw our gl scene. 
    glutIdleFunc(DrawGLScene)

    # Register the function called when our window is resized. 
    glutReshapeFunc(ReSizeGLScene)

    # Register the function called when the keyboard is pressed. 
    glutKeyboardFunc(keyPressed)

    # Register the function called when special keys (arrows, page down, etc) are pressed.
    glutSpecialFunc(specialKeyPressed)

    # Initialize our window. 
    InitGL(640, 480)

    # Start Event Processing Engine 
    glutMainLoop()


main()

