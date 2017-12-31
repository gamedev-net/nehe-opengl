; =============================================
; =             Jeff Molofee's (NeHe) OpenGL Examples             =
; =                           Tutorial 36 - Radial Blur                               =
; =                        by Jockel (rIo//SpinningKids)                         =
; =                MASM conversion by UFO-Pu55y//SND               =
; =============================================
	.586
	.model flat, stdcall
	option casemap:none
	
	include windows.inc
	include kernel32.inc
	includelib kernel32.lib
	include user32.inc
	includelib user32.lib
	include gdi32.inc
	includelib gdi32.lib

	include .\OpenGL\def\gl.def
	include .\OpenGL\def\glu.def
	include .\OpenGL\def\winextra.def
	include .\OpenGL\def\include.def
	includelib .\OpenGL\opengl32.lib
	includelib .\OpenGL\glu32.lib
	
	DlgProc					PROTO :HWND, :UINT, :WPARAM, :LPARAM
	GLTimer					PROTO	
	CreateGLWindow 			PROTO :DWORD
	InitGL					PROTO
	DrawGLScene				PROTO
	DrawBlur					PROTO :DWORD, :REAL4
	ProcessHelix				PROTO
	KillGLWindow				PROTO :DWORD

	FLOAT3D struct
		x					REAL4		?
		y					REAL4		?
		z					REAL4		?
	FLOAT3D ends
	
.data
; Window/GL-Stuff
	szWindowTitle				db			"Tutorial 36",0
	WindowWidth				dd			714
	WindowHeight				dd			474
	WindowWidthC			equ			714
	WindowHeightC			equ			474
	fovy						REAL8		45.0d
	zNear					REAL8		0.1d
	zFar						REAL8		2000.0d
; Blur
	global_ambient			REAL4		0.2f, 0.2f,  0.2f, 1.0f
	light0pos					REAL4		0.0f, 5.0f, 10.0f, 1.0f
	light0ambient				REAL4		0.2f, 0.2f,  0.2f, 1.0f
	light0diffuse				REAL4		0.3f, 0.3f,  0.3f, 1.0f
	light0specular				REAL4		0.8f, 0.8f,  0.8f, 1.0f
	lmodel_ambient			REAL4		0.2f, 0.2f,  0.2f, 1.0f
	glfMaterialColor			REAL4		0.4f, 0.2f, 0.8f, 1.0f
	specular					REAL4		1.0f, 1.0f, 1.0f, 1.0f
	BlurInc					REAL4		0.02f
	oRight					REAL8		640.0d
	oBottom					REAL8		480.0d
	oNear					REAL8		-1.0d
	oFar						REAL8		1.0d
; Helix
	twists					equ			5
	HelixDistance				REAL4		-50.0f
	eyey						REAL8		5.0d
	eyez						REAL8		50.0d
	upy						REAL8		1.0d
; float constants
	f0_0						REAL4		0.0f
	f0_2						REAL4		0.2f
	f0_5						REAL4		0.5f
	f1_0						REAL4		1.0f
	f1_5						REAL4		1.5f
	f2_0						REAL4		2.0f
	f3_0						REAL4		3.0f
	fPHI						REAL4		3.142f
	fPHIx2					REAL4		6.284f
	f20						REAL4		20.0f
	f180						REAL4		180.0f
	f480						REAL4		480.0f
	f640						REAL4		640.0f
; double constants
	d1_0					REAL8		1.0d

.data?
	hRC						HGLRC		?
	hDC						HDC			?
	hInstance					HINSTANCE	? 
; Blur
	BlurTexture				dd			?
	BlurData					dd			4000h dup (?) ; (128 * 128) * 4 bytes
; Helix
	vertex1					FLOAT3D		<?>
	vertex2					FLOAT3D		<?>
	vertex3					FLOAT3D		<?>
	vertex4					FLOAT3D		<?>
	normal					FLOAT3D		<?>
	angle					REAL4		?

.code
start:
	invoke GetModuleHandle,0
	mov hInstance, eax
	invoke DialogBoxParam, hInstance, 101, 0, ADDR DlgProc, 0
	invoke ExitProcess, eax

DlgProc	proc	hWnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if uMsg == WM_INITDIALOG
		invoke GetCurrentProcess
		invoke SetPriorityClass,eax,128
		invoke CreateGLWindow,hWnd
		invoke SetWindowText,hWnd,addr szWindowTitle
		invoke SetTimer,hWnd,777,12,ADDR GLTimer

	.elseif uMsg==WM_SYSCOMMAND
		.if wParam == SC_SCREENSAVE or SC_MONITORPOWER
			xor eax, eax
			ret
		.endif
	
	.elseif uMsg==WM_RBUTTONUP || uMsg==WM_LBUTTONUP
		invoke SendMessage,hWnd,WM_CLOSE,0,0
		
	.elseif uMsg==WM_CLOSE
		invoke KillTimer,hWnd,777
		invoke KillGLWindow, hWnd
		invoke EndDialog,hWnd,0
		xor eax, eax
		ret
		
	.endif

	xor	eax,eax
	ret
DlgProc	endp

CreateGLWindow proc hWnd:HWND
	LOCAL PixelFormat:GLuint, pfd:PIXELFORMATDESCRIPTOR, ratio:GLdouble

	ZeroMemory &pfd,sizeof(PIXELFORMATDESCRIPTOR)
	mov pfd.nSize,sizeof(PIXELFORMATDESCRIPTOR)
	mov pfd.nVersion,1
	mov pfd.dwFlags,PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER 
	mov pfd.iPixelType,PFD_TYPE_RGBA
	mov pfd.cColorBits,16
	mov pfd.cDepthBits,16
	mov pfd.dwLayerMask,PFD_MAIN_PLANE
	
	invoke GetDC,hWnd
	mov hDC,eax
	invoke ChoosePixelFormat,hDC,addr pfd
	mov PixelFormat,eax
	invoke SetPixelFormat,hDC,PixelFormat,addr pfd
	invoke wglCreateContext,hDC
	mov hRC,eax
	invoke wglMakeCurrent,hDC,hRC

	invoke glViewport, 0, 0, WindowWidth,WindowHeight
	invoke glMatrixMode, GL_PROJECTION
	invoke glLoadIdentity  
	fild WindowWidth
	fild WindowHeight
	fdivp st(1),st(0)
	fstp ratio
	fwait
	invoke gluPerspective,dword ptr fovy,dword ptr fovy+4,dword ptr ratio,dword ptr ratio+4, \
					dword ptr zNear,dword ptr zNear+4,dword ptr zFar,dword ptr zFar+4 ; 45.0d, ratio, 0.1d, 2000.0d
	invoke glMatrixMode, GL_MODELVIEW
	invoke glLoadIdentity
	
	invoke InitGL

	ret
	
CreateGLWindow endp

GLTimer proc

	invoke DrawGLScene
	invoke SwapBuffers,hDC

	ret
GLTimer EndP

InitGL proc

	invoke glGenTextures, 1, addr BlurTexture
	invoke glBindTexture, GL_TEXTURE_2D, BlurTexture
	invoke glTexImage2D, GL_TEXTURE_2D, 0, 4, 128, 128,0, GL_RGBA, GL_UNSIGNED_BYTE, addr BlurData
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR

	invoke glEnable, GL_TEXTURE_2D
	invoke glShadeModel,GL_SMOOTH 
	invoke glClearColor,f0_0,f0_0,f0_0,f0_5
	invoke glClearDepth,dword ptr d1_0,dword ptr d1_0+4
	invoke glEnable, GL_DEPTH_TEST 
	invoke glDepthFunc, GL_LESS
	invoke glHint,GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST

	invoke glLightModelfv,GL_LIGHT_MODEL_AMBIENT, addr lmodel_ambient
	invoke glLightModelfv,GL_LIGHT_MODEL_AMBIENT, addr global_ambient
	invoke glLightfv, GL_LIGHT0,GL_POSITION, addr light0pos
	invoke glLightfv, GL_LIGHT0,GL_AMBIENT, addr light0ambient
	invoke glLightfv, GL_LIGHT0,GL_DIFFUSE, addr light0diffuse
	invoke glLightfv, GL_LIGHT0,GL_SPECULAR, addr light0specular
	invoke glEnable,GL_LIGHTING
	invoke glEnable,GL_LIGHT0
	invoke glMateriali,GL_FRONT,GL_SHININESS,128

	mov eax, 1          
	ret
InitGL endp

DrawGLScene proc

	invoke glClearColor,f0_0,f0_0,f0_5,f0_5
	invoke glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
	invoke glLoadIdentity

	; RenderToTexture
	invoke glViewport,0,0,128,128
	invoke ProcessHelix
	invoke glBindTexture,GL_TEXTURE_2D,BlurTexture
	invoke glCopyTexImage2D,GL_TEXTURE_2D,0,GL_LUMINANCE,0,0,128,128,0
	invoke glClearColor,f0_0,f0_0,f0_5,f0_5
	invoke glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
	invoke glViewport,0,0,WindowWidth,WindowHeight

	; Draw
	invoke ProcessHelix
	invoke DrawBlur,25,BlurInc
	invoke glFlush
	
	; Rotate helix
	fld angle
	fadd f2_0
	fstp angle
	
	ret
DrawGLScene endp

DrawBlur proc times:DWORD, inc_:REAL4
	LOCAL num:DWORD
	LOCAL spost, _spost, alphainc, alpha:REAL4
	
	fldz
	fstp spost ; Starting Texture Coordinate Offset
	fld f0_2
	fstp alpha ; Starting Alpha Value
	fld alpha
	fidiv times ; Fade Speed For Alpha Blending
	fstp alphainc ; alphainc=0.2f / Times To Render Blur
	
	invoke glDisable,GL_TEXTURE_GEN_S ; Disable AutoTexture Coordinates
	invoke glDisable,GL_TEXTURE_GEN_T
	invoke glEnable,GL_TEXTURE_2D
	invoke glDisable,GL_DEPTH_TEST
	invoke glBlendFunc,GL_SRC_ALPHA,GL_ONE
	invoke glEnable,GL_BLEND
	invoke glBindTexture,GL_TEXTURE_2D,BlurTexture

	; Switch To Ortho View
	invoke glMatrixMode,GL_PROJECTION
	invoke glPushMatrix
	invoke glLoadIdentity
	invoke glOrtho,0,0,dword ptr oRight,dword ptr oRight+4,dword ptr oBottom,dword ptr oBottom+4, \
				0,0,dword ptr oNear,dword ptr oNear+4,dword ptr oFar,dword ptr oFar+4 ; 0,640,480,0,-1,1
	invoke glMatrixMode,GL_MODELVIEW
	invoke glPushMatrix
	invoke glLoadIdentity

	invoke glBegin,GL_QUADS
	xor eax,eax
	mov num,eax
	.while eax < times
		fld1
		fsub spost ; 1 - spost
		fstp _spost
		fwait
		invoke glColor4f,f1_0,f1_0,f1_0,alpha ; Set The Alpha Value (Starts At 0.2)
		invoke glTexCoord2f,spost,_spost	; Texture Coordinate	( 0, 1 )
		invoke glVertex2f,0,0				; First Vertex		( 0, 0 )
		invoke glTexCoord2f,spost,spost	; Texture Coordinate	( 0, 0 )
		invoke glVertex2f,0,f480			; Second Vertex	( 0, 480 )
		invoke glTexCoord2f,_spost,spost	; Texture Coordinate	( 1, 0 )
		invoke glVertex2f,f640,f480		; Third Vertex		( 640, 480 )
		invoke glTexCoord2f,_spost,_spost	; Texture Coordinate	( 1, 1 )
		invoke glVertex2f,f640,0			; Fourth Vertex		( 640,   0 )
		fld spost
		fadd inc_ ; Gradually Increase spost (Zooming Closer To Texture Center)
		fstp spost
		fld alpha
		fsub alphainc ; Gradually Decrease alpha (Gradually Fading Image Out)
		fstp alpha
		inc num
		mov eax,num
	.endw
	invoke glEnd
	
	; Return To Perspective View
	invoke glMatrixMode,GL_PROJECTION
	invoke glPopMatrix
	invoke glMatrixMode,GL_MODELVIEW
	invoke glPopMatrix
	
	invoke glEnable,GL_DEPTH_TEST
	invoke glDisable,GL_TEXTURE_2D
	invoke glDisable,GL_BLEND
	invoke glBindTexture,GL_TEXTURE_2D,0
	
	ret

DrawBlur endp

ProcessHelix proc
	LOCAL x_, y_, z_, phi, theta, v, u, r, angle_div, length_:REAL4
	LOCAL phi_int, theta_int:DWORD
	LOCAL v1:FLOAT3D
	LOCAL v2:FLOAT3D
	
	mov phi_int,0
	fld f1_5 ; Radius Of Twist
	fstp r
	fldz
	fstp phi
	fld angle
	fdiv f2_0
	fstp angle_div

	invoke glLoadIdentity
	invoke gluLookAt,0,0,dword ptr eyey,dword ptr eyey+4,dword ptr eyez,dword ptr eyez+4, \
				0,0,0,0,0,0,0,0,dword ptr upy,dword ptr upy+4,0,0 ; 0,5,50,0,0,0,0,1,0 -> Eye Position (0,5,50) Center Of Scene (0,0,0), Up On Y Axis
	invoke glPushMatrix
	invoke glTranslatef,0,0,HelixDistance ; Translate 50 Units Into The Screen
	invoke glRotatef,angle_div,f1_0,0,0 ; Rotate By angle/2 On The X-Axis
	fld angle
	fdiv f3_0
	fstp angle_div
	fwait
	invoke glRotatef,angle_div,0,f1_0,0 ; Rotate By angle/3 On The Y-Axis
	invoke glMaterialfv,GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE,addr glfMaterialColor
	invoke glMaterialfv,GL_FRONT_AND_BACK,GL_SPECULAR, addr specular
	invoke glBegin,GL_QUADS
	.while phi_int <= 360 ; 360 Degrees In Steps Of 20
		mov theta_int,0
		fldz
		fstp theta
		.while theta_int <= (360*twists) ; 360 Degrees * Number Of Twists In Steps Of 20
		; *** 1 ***
			fld phi ; Calculate Angles Of First Point
			fdiv f180
			fmul fPHI
			fstp v ; v=(phi/180.0f*3.142f)
			fld theta
			fdiv f180
			fmul fPHI
			fstp u ; u=(theta/180.0f*3.142f)

			fld v ; Calculate x Position (1st Point)
			fcos
			fadd f2_0
			fld u
			fcos
			fmul r
			fmul ST(0),ST(1) ; leaves 2.0f+cos(v) on fpu stack !
			fstp vertex1.x ; x=(cos(u)*(2.0f+cos(v) ))*r

			fld u ; Calculate y Position (1st Point)
			fsin
			fmul r
			fmul ; 2.0f+cos(v) is still on fpu stack !
			fstp vertex1.y  ; y=(sin(u)*(2.0f+cos(v) ))*r

			fld v ; Calculate z Position (1st Point)
			fsin
			fld u
			fsub fPHIx2
			fadd
			fmul r
			fstp vertex1.z ; z=(( u-(2.0f*3.142f)) + sin(v) ) * r
			
		; *** 2 ***
			fld phi
			fdiv f180
			fmul fPHI
			fstp v
			fld theta
			fadd f20
			fdiv f180
			fmul fPHI
			fstp u

			fld v
			fcos
			fadd f2_0
			fld u
			fcos
			fmul r
			fmul ST(0),ST(1)
			fstp vertex2.x

			fld u
			fsin
			fmul r
			fmul
			fstp vertex2.y

			fld v
			fsin
			fld u
			fsub fPHIx2
			fadd
			fmul r
			fstp vertex2.z

		; *** 3 ***
			fld phi
			fadd f20
			fdiv f180
			fmul fPHI
			fstp v
			fld theta
			fadd f20
			fdiv f180
			fmul fPHI
			fstp u

			fld v
			fcos
			fadd f2_0
			fld u
			fcos
			fmul r
			fmul ST(0),ST(1)
			fstp vertex3.x

			fld u
			fsin
			fmul r
			fmul
			fstp vertex3.y

			fld v
			fsin
			fld u
			fsub fPHIx2
			fadd
			fmul r
			fstp vertex3.z

		; *** 4 ***
			fld phi
			fadd f20
			fdiv f180
			fmul fPHI
			fstp v
			fld theta
			fdiv f180
			fmul fPHI
			fstp u

			fld v
			fcos
			fadd f2_0
			fld u
			fcos
			fmul r
			fmul ST(0),ST(1)
			fstp vertex4.x

			fld u
			fsin
			fmul r
			fmul
			fstp vertex4.y

			fld v
			fsin
			fld u
			fsub fPHIx2
			fadd
			fmul r
			fstp vertex4.z

		; Calculate Normals
			fld vertex1.x
			fsub vertex2.x
			fstp v1.x ; Vector 1.x=Vertex[0].x-Vertex[1].x
			fld vertex1.y
			fsub vertex2.y
			fstp v1.y ; Vector 1.y=Vertex[0].y-Vertex[1].y
			fld vertex1.z
			fsub vertex2.z
			fstp v1.z ; Vector 1.z=Vertex[0].y-Vertex[1].z

			fld vertex2.x
			fsub vertex3.x
			fstp v2.x ; Vector 2.x=Vertex[0].x-Vertex[1].x
			fld vertex2.y
			fsub vertex3.y
			fstp v2.y ; Vector 2.y=Vertex[0].y-Vertex[1].y
			fld vertex2.z
			fsub vertex3.z
			fstp v2.z ; Vector 2.z=Vertex[0].z-Vertex[1].z
			
			fld v1.z ; Compute The Cross Product To Give Us A Surface Normal
			fmul v2.y
			fstp normal.x
			fld v1.y
			fmul v2.z
			fsub normal.x
			fstp normal.x ; Cross Product For Y - Z
			
			fld v1.x
			fmul v2.z
			fstp normal.y
			fld v1.z
			fmul v2.x
			fsub normal.y
			fstp normal.y ; Cross Product For X - Z

			fld v1.y
			fmul v2.x
			fstp normal.z
			fld v1.x
			fmul v2.y
			fsub normal.z
			fstp normal.z ; Cross Product For X - Y
			
		; Normalize The Vectors
			fld normal.x ; Calculates The Length Of The Vector
			fmul normal.x
			fld normal.y
			fmul normal.y
			fld normal.z
			fmul normal.z
			fadd
			fadd
			fsqrt
			fstp length_
			fldz
			fld length_
			fcompp
			fstsw ax
			fwait
			.if ah==44h ; Prevents Divide By 0 Error By Providing
				fld1; An Acceptable Value For Vectors To Close To 0.
				fstp length_
			.endif
			fld normal.x
			fdiv length_
			fstp normal.x
			fld normal.y
			fdiv length_
			fstp normal.y
			fld normal.z
			fdiv length_
			fstp normal.z
			fwait
			
			invoke glNormal3f,normal.x,normal.y,normal.z
			invoke glVertex3f,vertex1.x,vertex1.y,vertex1.z
			invoke glVertex3f,vertex2.x,vertex2.y,vertex2.z
			invoke glVertex3f,vertex3.x,vertex3.y,vertex3.z
			invoke glVertex3f,vertex4.x,vertex4.y,vertex4.z
			fld theta
			fadd f20
			fstp theta
			add theta_int,20
		.endw
		fld phi
		fadd f20
		fstp phi
		add phi_int,20
	.endw
	invoke glEnd
	invoke glPopMatrix
	
	ret

ProcessHelix endp

KillGLWindow proc hWnd:DWORD

	.if hRC
		invoke wglMakeCurrent,NULL,NULL
		invoke wglDeleteContext,hRC
		mov hRC,NULL
	.endif
	.if hDC
		invoke ReleaseDC,hWnd,hDC
		mov hDC,NULL
	.endif
	.if hWnd
		invoke DestroyWindow,hWnd
		mov hWnd,NULL
	.endif
	mov hInstance,NULL
	
	ret
KillGLWindow endp

end start