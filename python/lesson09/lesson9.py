#
# This code was created by Jeff Molofee '99 (ported to Linux/GLUT by
# Richard Campbell '99)
#
# If you've found this code useful, please let me know.
#
# Visit me at www.demonews.com/hosted/nehe
# (email Richard Campbell at ulmont@bellsouth.net)
#

"""
  Ported to Python by Ryan Showalter '04
  tankcoder@warpmail.net
  
  This is pretty much an exact port from the C code,
  please use this as refence and not as an example
  of how to program well (or at all) in OO.
"""


from OpenGL.GL import * 	# GL funcs
from OpenGL.GLU import *	# GLU Stuff
from OpenGL.GLUT import *	# GLUT functions...
import time			# Needed for sleeping
import sys			# Exiting, etc
import random			# Random colors...
from Image import *		# Image Loader

# number of stars to have
STAR_NUM = 50

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

# twinkle on/off (1 = on, 0 = off)
twinkle = 0

class star:              # Star structure
    r, g, b = (0, 0, 0)          # stars' color
    dist = 0.0           # stars' distance from center
    angle = 0.0          # stars' current angle

stars = []
for x in range(STAR_NUM):
	stars.append(star())

zoom = -15.0             # viewing distance from stars.
tilt = 90.0              # tilt the view
spin = 0                 # spin twinkling stars

texture = range(1)       # storage for one texture;

# Image type - contains height, width, and data
class Image:
    sizeX = 0
    sizeY = 0
    data = None


def ImageLoad(filename, image):
    #PIL makes life easy...

    poo = open(filename)
	
    image.sizeX = poo.size[0]
    image.sizeY = poo.size[1]
    image.data = poo.tostring("raw", "RGBX", 0, -1)

# Load Bitmaps And Convert To Textures
def LoadGLTextures():
    global texture

    # Load Texture
    image1 = Image()


    #try:
    ImageLoad("Data/lesson9/Star.bmp", image1)
    #except:
    #	sys.exit()

    # Create Textures
    texture = glGenTextures(1)

    # linear filtered texture
    glBindTexture(GL_TEXTURE_2D, texture);   # 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); # scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); # scale linearly when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data);
    


# A general OpenGL initialization function.  Sets all of the initial parameters. 
def InitGL(Width, Height):			# We call this right after our OpenGL window is created.

    LoadGLTextures();                           # load the textures.
    glEnable(GL_TEXTURE_2D)                     # Enable texture mapping.

    glClearColor(0.0, 0.0, 0.0, 0.0)		# This Will Clear The Background Color To Black
    glClearDepth(1.0)				# Enables Clearing Of The Depth Buffer

    glShadeModel(GL_SMOOTH)			# Enables Smooth Color Shading

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()				# Reset The Projection Matrix

    gluPerspective(45.0,Width/Height,0.1,100.0)	# Calculate The Aspect Ratio Of The Window

    glMatrixMode(GL_MODELVIEW)

    # setup blending
    glBlendFunc(GL_SRC_ALPHA,GL_ONE)	        # Set The Blending Function For Translucency
    glEnable(GL_BLEND)                          # Enable Blending

    # set up the stars 
    for loop in range(STAR_NUM):
	stars[loop].angle = 0.0                # initially no rotation.

	stars[loop].dist = loop * 1.0 / STAR_NUM * 5.0 # calculate distance form the center
	stars[loop].r = random.randrange(1, 256, 1)            # random red intensity;
	stars[loop].g = random.randrange(1, 256, 1)            # random green intensity;
	stars[loop].b = random.randrange(1, 256, 1)            # random blue intensity;


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
    global spin

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)		# Clear The Screen And The Depth Buffer
    
    glBindTexture(GL_TEXTURE_2D, texture)     # pick the texture.

    for loop in range(STAR_NUM):        # loop through all the stars.
	glLoadIdentity()                        # reset the view before we draw each star.
	glTranslatef(0.0, 0.0, zoom)          # zoom into the screen.
	glRotatef(tilt, 1.0, 0.0, 0.0)       # tilt the view.

	glRotatef(stars[loop].angle, 0.0, 1.0, 0.0) # rotate to the current star's angle.
	glTranslatef(stars[loop].dist, 0.0, 0.0) # move forward on the X plane (the star's x plane).

	glRotatef(-stars[loop].angle, 0.0, 1.0, 0.0) # cancel the current star's angle.
	glRotatef(-tilt, 1.0, 0.0, 0.0)      # cancel the screen tilt.

	if (twinkle):                           # twinkling stars enabled ... draw an additional star.
	    # assign a color using bytes
	    glColor4ub(stars[STAR_NUM - loop-1].r, stars[STAR_NUM - loop-1].g, stars[STAR_NUM - loop-1].b, 255)

	    glBegin(GL_QUADS)                  # begin drawing the textured quad.
	    glTexCoord2f(0.0, 0.0) 
	    glVertex3f(-1.0, -1.0, 0.0)
	    glTexCoord2f(1.0, 0.0) 
	    glVertex3f( 1.0, -1.0, 0.0)
	    glTexCoord2f(1.0, 1.0) 
	    glVertex3f( 1.0,  1.0, 0.0)
	    glTexCoord2f(0.0, 1.0) 
	    glVertex3f(-1.0, 1.0, 0.0)
	    glEnd()                             # done drawing the textured quad.
	

	# main star
	glRotatef(spin, 0.0, 0.0, 1.0)       # rotate the star on the z axis.

        # Assign A Color Using Bytes
	glColor4ub(stars[loop].r,stars[loop].g,stars[loop].b,255)
	glBegin(GL_QUADS)			# Begin Drawing The Textured Quad
	glTexCoord2f(0.0, 0.0) 
	glVertex3f(-1.0,-1.0, 0.0)
	glTexCoord2f(1.0, 0.0) 
	glVertex3f( 1.0,-1.0, 0.0)
	glTexCoord2f(1.0, 1.0) 
	glVertex3f( 1.0, 1.0, 0.0)
	glTexCoord2f(0.0, 1.0) 
	glVertex3f(-1.0, 1.0, 0.0)
	glEnd()				# Done Drawing The Textured Quad

	spin +=0.01                           # used to spin the stars.
	stars[loop].angle += loop * 1.0 / STAR_NUM * 1.0    # change star angle.
	stars[loop].dist  -= 0.01              # bring back to center.

	if (stars[loop].dist<0.0):             # star hit the center
	    stars[loop].dist += 5.0            # move 5 units from the center.
	    stars[loop].r = random.randrange(1, 256, 1)        # new red color.
	    stars[loop].g = random.randrange(1, 256, 1)        # new green color.
	    stars[loop].b = random.randrange(1, 256, 1)        # new blue color.
	
    

    # since this is double buffered, swap the buffers to display what just got drawn.
    glutSwapBuffers()



# The function called whenever a normal key is pressed.
def keyPressed(key, x, y):

    global twinkle
    
    key = ord(key)
    # avoid thrashing this procedure
    time.sleep(0.1)

    if key == ESCAPE: # kill everything.
	# exit the program...normal termination.
	sys.exit()
	
    elif key == 116 or key == 84: # switch the twinkling.
	print("T/t pressed; twinkle is: %d\n"%(twinkle))
	if twinkle:		# switch the current value of twinkle, between 0 and 1.
		twinkle = 0
	else:
		twinkle = 1
		
	print("Twinkle is now: %d\n"%(twinkle))

    else:
      print("Key %d pressed. No action there yet.\n"%(key))
    


# The function called whenever a special key is pressed. 
def specialKeyPressed(key, x, y):

    global zoom, tilt
    # avoid thrashing this procedure
    time.sleep(0.1)

    if key == GLUT_KEY_PAGE_UP: # zoom out
	zoom -= 0.2


    elif key == GLUT_KEY_PAGE_DOWN: # zoom in
	zoom += 0.2

    elif key == GLUT_KEY_UP: # tilt up
	tilt -= 0.5

    elif key == GLUT_KEY_DOWN: # tilt down
	tilt += 0.5

    else:
	print ("Special key %d pressed. No action there yet.\n"%(key))
    


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
