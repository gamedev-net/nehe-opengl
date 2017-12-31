import sys
from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *
from Cg import *


# *********************** Globals *********************** 
# Python 2.2 defines these directly
try:
	True
except NameError:
	True = 1==1
	False = 1==0

TWO_PI	= 2.0*3.1415926535			# 2 * PI
SIZE	= 64						# // Defines The Size Of The X/Z Axis Of The Mesh

# Some api in the chain is translating the keystrokes to this octal string
# so instead of saying: ESCAPE = 27, we use the following.
ESCAPE = '\033'

g_cg_enable = True 					# // Toggle Cg Program On / Off
g_mesh = None						# Our Static triangle Mesh
g_wave_movement = 0.0;				# // Our Variable To Move The Waves Across The Mesh

g_modelViewMatrix = None
g_position = None
g_color = None
g_wave = None
g_cgVertexProfile = None
g_cgProgram = None
g_cgContext = None


# // Any GL Init Code & User Initialiazation Goes Here
def InitGL(Width, Height):				# We call this right after our OpenGL window is created.
	global g_mesh
	global g_modelViewMatrix, g_position, g_color, g_wave
	global g_cgVertexProfile, g_cgProgram, g_cgContext

	glClearColor(0.0, 0.0, 0.0, 0.5)	# This Will Clear The Background Color To Black
	glClearDepth(1.0)					# Enables Clearing Of The Depth Buffer
	glDepthFunc(GL_LEQUAL)				# The Type Of Depth Test To Do
	glEnable(GL_DEPTH_TEST)				# Enables Depth Testing
	glShadeModel (GL_SMOOTH)			# // Select Smooth Shading
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Really Nice Perspective Calculations


	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);	# // Draw Our Mesh In Wireframe Mode
	# // Create Our Mesh
	g_mesh = Numeric.zeros ((SIZE, SIZE, 3), 'f')
	for x in xrange (SIZE):
		for z in xrange (SIZE):
			g_mesh[x][z][0] = float ((SIZE / 2) - x);		# // We Want To Center Our Mesh Around The Origin
			g_mesh[x][z][1] = 0.0;							# // Set The Y Values For All Points To 0
			g_mesh[x][z][2] = float ((SIZE / 2) - z);		# // We Want To Center Our Mesh Around The Origin

	# // Setup Cg
	g_cgContext = cgCreateContext ()

	# // Validate Our Context Generation Was Successful
	if (g_cgContext == None):
		raise "Failed To Create Cg Context"
		return False;										# // We Cannot Continue

	g_cgVertexProfile = cgGLGetLatestProfile(CG_GL_VERTEX);	# // Get The Latest GL Vertex Profile
	# // Validate Our Profile Determination Was Successful
	if (g_cgVertexProfile == CG_PROFILE_UNKNOWN):
		raise "Invalid profile type"
		return False;										# // We Cannot Continue

	cgGLSetOptimalOptions(g_cgVertexProfile);					# // Set The Current Profile

	# // Load And Compile The Vertex Shader From File
	g_cgProgram = cgCreateProgramFromFile(g_cgContext, CG_SOURCE, 
		"CG/Wave.cg", g_cgVertexProfile, "main", None);
	# // Validate Success
	if (g_cgProgram == None):
		# // We Need To Determine What Went Wrong
		Error = cgGetError();

		# // Show A Message Box Explaining What Went Wrong
		raise cgGetErrorString(Error)
		return False;										# // We Cannot Continue

	# // Load The Program
	cgGLLoadProgram(g_cgProgram);

	# // Get Handles To Each Of Our Parameters So That
	# // We Can Change Them At Will Within Our Code
	g_position		= cgGetNamedParameter(g_cgProgram, "IN.position");
	g_color			= cgGetNamedParameter(g_cgProgram, "IN.color");
	g_wave			= cgGetNamedParameter(g_cgProgram, "IN.wave");
	g_modelViewMatrix	= cgGetNamedParameter(g_cgProgram, "ModelViewProj");

	return True									# // Initialization Went OK


# The function called whenever a key is pressed. Note the use of Python tuples to pass in: (key, x, y)  
def keyPressed(*args):
	global g_cg_enable
	# If escape is pressed, kill everything.
	key = args [0]
	if key == ESCAPE:
		Deinitialize ()
		sys.exit ()

	if key == ' ':
		g_cg_enable = not g_cg_enable

	return


def Draw ():
	global g_wave_movement
	global g_modelViewMatrix, g_position, g_color, g_wave
	global g_cgVertexProfile, g_cgProgram
	global g_cg_enable

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);				# // Clear Screen And Depth Buffer
	glLoadIdentity();												# // Reset The Current Modelview Matrix


	# // Position The Camera To Look At Our Mesh From A Distance
	gluLookAt(0.0, 25.0, -45.0, 0.0, 0.0, 0.0, 0, 1, 0);

	# // Set The Modelview Matrix Of Our Shader To Our OpenGL Modelview Matrix
	cgGLSetStateMatrixParameter (g_modelViewMatrix, CG_GL_MODELVIEW_PROJECTION_MATRIX, CG_GL_MATRIX_IDENTITY);

	if g_cg_enable == True:
		cgGLEnableProfile (g_cgVertexProfile);				# // Enable Our Vertex Shader Profile
		# // Bind Our Vertex Program To The Current State
		cgGLBindProgram (g_cgProgram);
		# // Set The Drawing Color To Light Green (Can Be Changed By Shader, Etc...)
		cgGLSetParameter4f (g_color, 0.5, 1.0, 0.5, 1.0);


	# // Start Drawing Our Mesh
	for x in xrange (SIZE - 1):
		# // Draw A Triangle Strip For Each Column Of Our Mesh
		glBegin(GL_TRIANGLE_STRIP);
		for z in xrange (SIZE - 1):
			# // Set The Wave Parameter Of Our Shader To The Incremented Wave Value From Our Main Program
			cgGLSetParameter3f (g_wave, g_wave_movement, 1.0, 1.0);
			glVertex3f(g_mesh[x][z][0], g_mesh[x][z][1], g_mesh[x][z][2]);		# // Draw Vertex
			glVertex3f(g_mesh[x+1][z][0], g_mesh[x+1][z][1], g_mesh[x+1][z][2]);	# // Draw Vertex
			g_wave_movement += 0.00002;									# // Increment Our Wave Movement
			if (g_wave_movement > TWO_PI):									# // Prevent Crashing
				g_wave_movement = 0.0;
		glEnd()

	if g_cg_enable:
		cgGLDisableProfile (g_cgVertexProfile);							# // Disable Our Vertex Profile

	glFlush ();													# // Flush The GL Rendering Pipeline
	glutSwapBuffers ()
	return


# // Any User DeInitialization Goes Here
def Deinitialize ():
	global g_cgVertexProfile, g_cgProgram, g_cgContext

	# // Destroy Our Cg Context And All Programs Contained Within It
	cgDestroyContext(g_cgContext);
	return

