# /***********************************************
# *                                              *
# *    Jeff Molofee's Revised OpenGL Basecode    *
# *  Huge Thanks To Maxwell Sayles & Peter Puck  *
# *            http://nehe.gamedev.net           *
# *                     2001                     *
# *            Adapted to PyOpenGL GLUT          *
# *                                              *
# ***********************************************/
#
# NeHe Tutorial Lesson: 47 - CG Vertex Shader
#
# This code was created by Jeff Molofee 2003
# Ported to PyOpenGL 2.0 by Brian Leair 2004
#
# The port was based on the PyOpenGL tutorials and from 
# PyOpenGLContext (tests/glprint.py)
#
# If you've found this code useful, feel free to let me know 
# at (Brian Leair telcom_sage@yahoo.com).
#
# See original source and C based tutorial at http://nehe.gamedev.net
#
# Note:
# -----
# This code is not an ideal example of Pythonic coding or use of OO 
# techniques. It is a simple and direct exposition of how to use the 
# Open GL API in Python via the PyOpenGL package. It also uses GLUT, 
# a high quality platform independent library. Due to using these APIs, 
# this code is more like a C program using procedural programming.
#
# To run this example you will need:
# Python 	- www.python.org (v 2.3 as of 1/2004)
# PyOpenGL 	- pyopengl.sourceforge.net (v 2.0.1.07 as of 1/2004)
# Numeric Python	- (v.22 of "numpy" as of 1/2004) numpy.sourceforge.net
#
# A nvidia video card
# Nvidia CG runtime	- /www.nvidia.com/object/cg_toolkit_1_1.html
# PyCg 				- www.csit.fsu.edu/~mason/?section=projects:personal:pycg
# * I built PyCg-0.1.13.tar.gz from graphics.cs.lth.se/pyfx/download/
# and used swigwin-1.3.21 (+MSVC) from www.swig.org/download.html
#
#

import sys
from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *

from Lesson47 import *		# Draw (), Initialize () and all the real OpenGL work.


# *********************** Globals *********************** 
# Python 2.2 defines these directly
try:
	True
except NameError:
	True = 1==1
	False = 1==0


# Number of the glut window.
window = 0








# Reshape The Window When It's Moved Or Resized
def ReSizeGLScene(Width, Height):
	if Height == 0:						# Prevent A Divide By Zero If The Window Is Too Small 
		Height = 1

	glViewport(0, 0, Width, Height)		# Reset The Current Viewport And Perspective Transformation
	glMatrixMode(GL_PROJECTION)			# // Select The Projection Matrix
	glLoadIdentity()					# // Reset The Projection Matrix
	# // field of view, aspect ratio, near and far
	# This will squash and stretch our objects as the window is resized.
	# Note that the near clip plane is 1 (hither) and the far plane is 1000 (yon)
	gluPerspective(45.0, float(Width)/float(Height), 1, 100.0)

	glMatrixMode (GL_MODELVIEW);		# // Select The Modelview Matrix
	glLoadIdentity ();					# // Reset The Modelview Matrix
	return



def main():
	global window
	# pass arguments to init
	glutInit(sys.argv)

	# Select type of Display mode:   
	#  Double buffer 
	#  RGBA color
	# Alpha components supported 
	# Depth buffer
	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH)
	
	# get a 640 x 480 window 
	glutInitWindowSize(640, 480)
	
	# the window starts at the upper left corner of the screen 
	glutInitWindowPosition(0, 0)
	
	# Okay, like the C version we retain the window id to use when closing, but for those of you new
	# to Python, remember this assignment would make the variable local and not global
	# if it weren't for the global declaration at the start of main.
	window = glutCreateWindow("Lesson 47: NeHe & Owen Bourne's Cg Vertex Shader Tutorial");

   	# Register the drawing function with glut, BUT in Python land, at least using PyOpenGL, we need to
	# set the function pointer and invoke a function to actually register the callback, otherwise it
	# would be very much like the C version of the code.	
	glutDisplayFunc(Draw)
	
	# Uncomment this line to get full screen.
	#glutFullScreen()

	# When we are doing nothing, redraw the scene.
	glutIdleFunc(Draw)
	
	# Register the function called when our window is resized.
	glutReshapeFunc(ReSizeGLScene)
	
	# Register the function called when the keyboard is pressed.  
	glutKeyboardFunc(keyPressed)

	# GLUT When mouse buttons are clicked in window
	# glutMouseFunc (Upon_Click)

	# GLUT When the mouse mvoes
	# glutMotionFunc (Upon_Drag)

	# We've told Glut the type of window we want, and we've told glut about
	# various functions that we want invoked (idle, resizing, keyboard events).
	# Glut has done the hard work of building up thw windows DC context and 
	# tying in a rendering context, so we are ready to start making immediate mode
	# GL calls.
	# Call to perform inital GL setup (the clear colors, enabling modes
	InitGL (640, 480)

	# Start Event Processing Engine	
	glutMainLoop()

# Print message to console, and kick off the main to get it rolling.
if __name__ == "__main__":
	print "Hit ESC key to quit."
	main()
