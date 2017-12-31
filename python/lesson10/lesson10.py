#
# This code was created by Jeff Molofee '99 (ported to Linux/GLUT by
# Richard Campbell '00)
#
# If you've found this code useful, please let me know.
#
# Visit Jeff Molofee at www.demonews.com/hosted/nehe
# (email Richard Campbell at ulmont@bellsouth.net)
#

"""
  Ported to Python by Ryan Showalter '04
  tankcoder@warpmail.net
  
  This is pretty much an exact port from the C code,
  please use this as refence and not as an example
  of how to program well (or at all) in OO.
"""


from OpenGL.GLUT import *    	# Module For The GLUT Library
from OpenGL.GL import *		# Module For The OpenGL32 Library
from OpenGL.GLU import *	# Module For The GLu32 Library
import time     		# Module for sleeping.
from math import *    		# Module for trigonometric functions.
import sys			
import Image			#Image Loading

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

texture = range(3)       # storage for 3 textures;

light = 0           # lighting on/off
blend = 0        # blending on/off

xrot = 0            # x rotation
yrot = 0            # y rotation
xspeed = 0          # x rotation speed
yspeed = 0          # y rotation speed

walkbias = 0
walkbiasangle = 0

lookupdown = 0.0
piover180 = 0.0174532925

heading, xpos, zpos = (0.0, 0.0, 0.0)

camx, camy, camz = (0, 0, 0) # camera location.
therotate = 0

z=0.0                        # depth into the screen.

LightAmbient  = [0.5, 0.5, 0.5, 1.0]
LightDiffuse  = [1.0, 1.0, 1.0, 1.0]
LightPosition = [0.0, 0.0, 2.0, 1.0]

filter = 0       # texture filtering method to use (nearest, linear, linear + mipmaps)

class VERTEX:         # vertex coordinates - 3d and texture
    def __init__(self):
        self.x = 0
        self.y = 0
        self.z = 0
        self.u = 0
        self.v = 0


class TRIANGLE:          # triangle
	def __init__(self):
		self.vertex = [None]*3
		self.vertex[0] = VERTEX()
		self.vertex[1] = VERTEX()
		self.vertex[2] = VERTEX()

class SECTOR:         # sector of a 3d environment
    numtriangles = 0    # number of triangles in the sector
    triangle = []  # pointer to array of triangles.


sector1 = SECTOR()

# Image type - contains height, width, and data
class Imaged:
    sizeX = 0
    sizeY = 0
    data = None

# degrees to radians...2 PI radians = 360 degrees
def rad(angle):

    return angle * piover180


# helper for SetupWorld.  reads a file into a string until a nonblank, non-comment line
# is found ("/" at the start indicating a comment); assumes lines < 255 characters long.
def readstr(f):

    string = ''
    while 1:
	string = f.readline() # read the line
	#print string
        if((string[0] == '/') or (string[0] == '\n')):
        	continue
        else:
        	break
    return string


# loads the world from a text file.
def SetupWorld():

    filein = open("Data/lesson10/world.txt", "r")

    oneline = readstr(filein)
    oneline = oneline.strip().split()
    numtriangles = int(oneline[1])

    sector1.numtriangles = numtriangles
    sector1.triangle = [None]*numtriangles
    for x in range(len(sector1.triangle)):
    	sector1.triangle[x] = TRIANGLE()

    for loop in range(numtriangles):
	for vert in range(3):
	    oneline = readstr(filein)
	    x, y, z, u, v = map(float, oneline.strip().split())
	    sector1.triangle[loop].vertex[vert].x = float(x)
	    sector1.triangle[loop].vertex[vert].y = float(y)
	    sector1.triangle[loop].vertex[vert].z = float(z)
	    sector1.triangle[loop].vertex[vert].u = float(u)
	    sector1.triangle[loop].vertex[vert].v = float(v)
	    
	
    

    filein.close()


def ImageLoad(filename, image):
    #PIL makes life easy...

    poo = Image.open(filename)
	
    image.sizeX = poo.size[0]
    image.sizeY = poo.size[1]
    image.data = poo.tostring("raw", "RGBX", 0, -1)


# Load Bitmaps And Convert To Textures
def LoadGLTextures():
    global texture

    # Load Texture
    image1 = Imaged()


    try:
        ImageLoad("Data/lesson10/mud.bmp", image1)
    except:
        sys.exit()

    # Create Textures
    texture = glGenTextures(3)

    # texture 1 (poor quality scaling)
    glBindTexture(GL_TEXTURE_2D, texture[0])   # 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)  # cheap scaling when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)  # cheap scaling when image smalled than texture

    # 2d texture, level of detail 0 (normal), 3 components (red, green, blue), x size from image, y size from image,
    # border 0 (normal), rgb color data, unsigned byte data, and finally the data itself.
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data)
    

    # texture 2 (linear scaling)
    glBindTexture(GL_TEXTURE_2D, texture[1])    # 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)  # scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)  # scale linearly when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data);
    

    # texture 3 (mipmapped scaling)
    glBindTexture(GL_TEXTURE_2D, texture[2])    # 2d texture (x and y size)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)  # scale linearly when image bigger than texture
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST)  # scale linearly + mipmap when image smalled than texture
    glTexImage2D(GL_TEXTURE_2D, 0, 4, image1.sizeX, image1.sizeY, 0, GL_RGBA, GL_UNSIGNED_BYTE, image1.data)

    # 2d texture, 3 colors, width, height, RGB in that order, byte data, and the data.
    gluBuild2DMipmaps(GL_TEXTURE_2D, 4, image1.sizeX, image1.sizeY, GL_RGBA, GL_UNSIGNED_BYTE, image1.data)
    


# A general OpenGL initialization function.  Sets all of the initial parameters.
def InitGL(Width, Height):	# We call this right after our OpenGL window is created.

    LoadGLTextures()                           # load the textures.
    glEnable(GL_TEXTURE_2D)                    # Enable texture mapping.

    glBlendFunc(GL_SRC_ALPHA, GL_ONE)          # Set the blending function for translucency (note off at init time)
    glClearColor(0.0, 0.0, 0.0, 0.0)	# This Will Clear The Background Color To Black
    glClearDepth(1.0)				# Enables Clearing Of The Depth Buffer
    glDepthFunc(GL_LESS)                       # type of depth test to do.
    glEnable(GL_DEPTH_TEST)                    # enables depth testing.
    glShadeModel(GL_SMOOTH)			# Enables Smooth Color Shading

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()				# Reset The Projection Matrix

    gluPerspective(45.0,Width/Height,0.1,100.0)	# Calculate The Aspect Ratio Of The Window

    glMatrixMode(GL_MODELVIEW)

    # set up lights.
    glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient)
    glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse)
    glLightfv(GL_LIGHT1, GL_POSITION, LightPosition)
    glEnable(GL_LIGHT1)


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

    # calculate translations and rotations.
    xtrans = -xpos
    ztrans = -zpos
    ytrans = -walkbias-0.25
    sceneroty = 360.0 - yrot

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)		# Clear The Screen And The Depth Buffer
    glLoadIdentity()

    glRotatef(lookupdown, 1.0, 0, 0)
    glRotatef(sceneroty, 0, 1.0, 0)

    glTranslatef(xtrans, ytrans, ztrans)

    glBindTexture(GL_TEXTURE_2D, texture[filter])    # pick the texture.

    numtriangles = sector1.numtriangles

    for loop in range(numtriangles):        # loop through all the triangles
	glBegin(GL_TRIANGLES)
	glNormal3f( 0.0, 0.0, 1.0)

	x_m = sector1.triangle[loop].vertex[0].x
	y_m = sector1.triangle[loop].vertex[0].y
	z_m = sector1.triangle[loop].vertex[0].z
	u_m = sector1.triangle[loop].vertex[0].u
	v_m = sector1.triangle[loop].vertex[0].v
	#print x_m, y_m, z_m
	glTexCoord2f(u_m,v_m)
	glVertex3f(x_m,y_m,z_m)

	x_m = sector1.triangle[loop].vertex[1].x
	y_m = sector1.triangle[loop].vertex[1].y
	z_m = sector1.triangle[loop].vertex[1].z
	u_m = sector1.triangle[loop].vertex[1].u
	v_m = sector1.triangle[loop].vertex[1].v
	glTexCoord2f(u_m,v_m)
	glVertex3f(x_m,y_m,z_m)

	x_m = sector1.triangle[loop].vertex[2].x
	y_m = sector1.triangle[loop].vertex[2].y
	z_m = sector1.triangle[loop].vertex[2].z
	u_m = sector1.triangle[loop].vertex[2].u
	v_m = sector1.triangle[loop].vertex[2].v
	glTexCoord2f(u_m,v_m)
	glVertex3f(x_m,y_m,z_m)

	glEnd()
    

    # since this is double buffered, swap the buffers to display what just got drawn.
    glutSwapBuffers()



# The function called whenever a normal key is pressed.
def keyPressed(key, x, y):
    global blend, filter, light

    # avoid thrashing this procedure
    time.sleep(0.1)

    if ord(key) == ESCAPE: # kill everything.
	# exit the program...normal termination. 
	sys.exit()
	
    elif key == 'B' or key == 'b': # switch the blending
	print("B/b pressed; blending is: %d\n"%(blend))
	if blend:		# switch the current value of blend, between 0 and 1.
		blend = 0
	else:
		blend = 1    
		
	if (blend):
	    glEnable(GL_BLEND)
	    glDisable(GL_DEPTH_TEST)
	else:
	    glDisable(GL_BLEND)
	    glEnable(GL_DEPTH_TEST)
	
	print("Blending is now: %d\n"%(blend))

    elif key =='F' or key == 'f': # switch the filter
	print("F/f pressed; filter is: %d\n"%(filter))
	filter+=1                           # switch the current value of filter, between 0/1/2;
	if (filter > 2):
	    filter = 0
	
	print("Filter is now: %d\n"%(filter))

    elif key == 'L' or key == 'l': # switch the lighting
	print("L/l pressed; lighting is: %d\n"% (light))
	if light:		# switch the current value of light, between 0 and 1.
		light = 0
	else:
		light = 1
		
	if (light):
	    glEnable(GL_LIGHTING)
	else:
	    glDisable(GL_LIGHTING)
	
	print("Lighting is now: %d\n"%(light))

    else:
        print("Key %d pressed. No action there yet.\n"%(ord(key)))
    


# The function called whenever a normal key is pressed.
def specialKeyPressed(key, x, y):
    global lookupdown, walkbiasangle, walkbias, yrot, xpos, zpos, z

    # avoid thrashing this procedure
    #time.sleep(0.1)

    if key == GLUT_KEY_PAGE_UP: # tilt up
	z -= 0.2
	lookupdown -= 0.2

    elif key == GLUT_KEY_PAGE_DOWN: # tilt down
	z += 0.2
	lookupdown += 1.0

    elif key == GLUT_KEY_UP: # walk forward (bob head)
	xpos -= sin(yrot*piover180) * 0.05
	zpos -= cos(yrot*piover180) * 0.05
	if (walkbiasangle >= 359.0):
	    walkbiasangle = 0.0
	else:
	    walkbiasangle+= 10
	walkbias = sin(walkbiasangle * piover180)/20.0

    elif key ==GLUT_KEY_DOWN: # walk back (bob head)
	xpos += sin(yrot*piover180) * 0.05
	zpos += cos(yrot*piover180) * 0.05
	if (walkbiasangle <= 1.0):
	    walkbiasangle = 359.0
	else:
	    walkbiasangle-= 10
	walkbias = sin(walkbiasangle * piover180)/20.0


    elif key == GLUT_KEY_LEFT: # look left
	yrot += 1.5

    elif key == GLUT_KEY_RIGHT: # look right
	yrot -= 1.5

    else:
	print("Special key %d pressed. No action there yet.\n"%(key))
    


def main():
    global window
    
    SetupWorld()

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

