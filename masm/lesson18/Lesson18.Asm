;-------------------------------------------------------------------------------------------;
; MASM32 conversion of Nehe's OpenGL tutorial 18 by Christophe Jeannin (Chrishka)           ;
; I'm sorry about the poor indentation in MASM32 QEDITOR, I wrote this with RadASM,         ;
; I've tried to fix that, but it still could be a bit messy                                 ;
; float and double parameters for GL functions are directly pushed as immediate.            ;
; I wrote a little program (Conv.exe) to know what value to push.                           ;
; doubles are pushed as 2 dwords, most significant dword first, then less significant one   ;
; but with stdcall arguments Right to Left you have to give invoke less significant dword   ;
; first, and then the most significant dword.                                               ;
; ------------------------------------------------------------------------------------------;


include Lesson18.inc

.data

    hWnd        dd      NULL
    hDc         dd      NULL
    hRc         dd      NULL
    z           REAL4   -5.0f

    Ambient     REAL4   0.5f
                REAL4   0.5f
                REAL4   0.5f
                REAL4   1.0f

    Diffuse     REAL4   1.0f
                REAL4   1.0f
                REAL4   1.0f
                REAL4   1.0f

    Position    REAL4   0.0f
                REAL4   0.0f
                REAL4   2.0f
                REAL4   1.0f

    filter      dd      0

    p1          dd      0
    p2          dd      1

    object      dd      0

    active      db      1

    light       db      0

.data?

    hInst       dd      ?

    xrot        REAL4   ?
    yrot        REAL4   ?
    xspeed      REAL4   ?
    yspeed      REAL4   ?

    part1       dd      ?
    part2       dd      ?

    texture     dd      3 dup(?)

    quadratic   dd      ?

    lp          db      ?
    fp          db      ?
    space       db      ?

    fullscreen  db      ?

    keys        db      256 dup(?)

.const

    szClass     db      "OpenGL",0

    szErr       db      "Error",0
    szTitle     db      "Lesson 18",0

    szErr1      db      "Failed to register the window class",0
    szErr2      db      "Requested fullscreen mode not supported",13,"Use windowed mode instead ?",0
    szErr3      db      "Window creation error",0
    szErr4      db      "Unable to get device context",0
    szErr5      db      "Can't find a suitable pixel format",0
    szErr6      db      "Unable to set the pixel format",0
    szErr7      db      "Unable to create a rendering context",0
    szErr8      db      "Unable to activate the rendering context",0
    szErr9      db      "Unable to initialize OpenGL",0

    szMsg1      db      "Run in fullscreen ?",0
	
    szTexture   db      "Wall.bmp",0

.code

Start:

	invoke	GetModuleHandle,NULL
	mov		hInst,eax
	invoke	WinMain,eax,NULL,0
	invoke	ExitProcess,eax


glDrawCube PROC

	invoke	glBegin,GL_QUADS
		invoke	glNormal3f,0,0,3F800000h
		invoke	glTexCoord2f,0,0
		invoke	glVertex3f,0BF800000h,0BF800000h,3F800000h
		invoke	glTexCoord2f,3F800000h,0
		invoke	glVertex3f,3F800000h,0BF800000h,3F800000h
		invoke	glTexCoord2f,3F800000h,3F800000h
		invoke	glVertex3f,3F800000h,3F800000h,3F800000h
		invoke	glTexCoord2f,0,3F800000h
		invoke	glVertex3f,0BF800000h,3F800000h,3F800000h

		invoke	glNormal3f,0,0,0BF800000h
		invoke	glTexCoord2f,3F800000h,0
		invoke	glVertex3f,0BF800000h,0BF800000h,0BF800000h
		invoke	glTexCoord2f,3F800000h,3F800000h
		invoke	glVertex3f,0BF800000h,3F800000h,0BF800000h
		invoke	glTexCoord2f,0,3F800000h
		invoke	glVertex3f,3F800000h,3F800000h,0BF800000h
		invoke	glTexCoord2f,0,0
		invoke	glVertex3f,3F800000h,0BF800000h,0BF800000h

		invoke	glNormal3f,0,3F800000h,0
		invoke	glTexCoord2f,0,3F800000h
		invoke	glVertex3f,0BF800000h,3F800000h,0BF800000h
		invoke	glTexCoord2f,0,0
		invoke	glVertex3f,0BF800000h,3F800000h,3F800000h
		invoke	glTexCoord2f,3F800000h,0
		invoke	glVertex3f,3F800000h,3F800000h,3F800000h
		invoke	glTexCoord2f,3F800000h,3F800000h
		invoke	glVertex3f,3F800000h,3F800000h,0BF800000h

		invoke	glNormal3f,0,0BF800000h,0
		invoke	glTexCoord2f,3F800000h,3F800000h
		invoke	glVertex3f,0BF800000h,0BF800000h,0BF800000h
		invoke	glTexCoord2f,0,3F800000h
		invoke	glVertex3f,3F800000h,0BF800000h,0BF800000h
		invoke	glTexCoord2f,0,0
		invoke	glVertex3f,3F800000h,0BF800000h,3F800000h
		invoke	glTexCoord2f,3F800000h,0
		invoke	glVertex3f,0BF800000h,0BF800000h,3F800000h

		invoke	glNormal3f,3F800000h,0,0
		invoke	glTexCoord2f,3F800000h,0
		invoke	glVertex3f,3F800000h,0BF800000h,0BF800000h
		invoke	glTexCoord2f,3F800000h,3F800000h
		invoke	glVertex3f,3F800000h,3F800000h,0BF800000h
		invoke	glTexCoord2f,0,3F800000h
		invoke	glVertex3f,3F800000h,3F800000h,3F800000h
		invoke	glTexCoord2f,0,0
		invoke	glVertex3f,3F800000h,0BF800000h,3F800000h

		invoke	glNormal3f,0BF800000h,0,0
		invoke	glTexCoord2f,0,0
		invoke	glVertex3f,0BF800000h,0BF800000h,0BF800000h
		invoke	glTexCoord2f,3F800000h,0
		invoke	glVertex3f,0BF800000h,0BF800000h,3F800000h
		invoke	glTexCoord2f,3F800000h,3F800000h
		invoke	glVertex3f,0BF800000h,3F800000h,3F800000h
		invoke	glTexCoord2f,0,3F800000h
		invoke	glVertex3f,0BF800000h,3F800000h,0BF800000h
	invoke	glEnd
	ret

glDrawCube ENDP

LoadGLTexture PROC
  LOCAL info:BITMAP,hBmp:DWORD

	invoke	LoadImage,NULL,addr szTexture,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
	.if eax
		mov		hBmp,eax
		invoke	glGenTextures,3,addr texture
		invoke	GetObject,hBmp,sizeof info,addr info

		invoke	glBindTexture,GL_TEXTURE_2D,texture[0*4]
		invoke	glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST
    	      invoke	glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST
		invoke	glTexImage2D,GL_TEXTURE_2D,0,3,info.bmWidth,info.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits

		invoke	glBindTexture,GL_TEXTURE_2D,texture[1*4]
		invoke	glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
        	invoke	glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR
        	invoke	glTexImage2D,GL_TEXTURE_2D,0,3,info.bmWidth,info.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits

        	invoke	glBindTexture,GL_TEXTURE_2D,texture[2*4]
        	invoke	glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST
        	invoke	glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR
        	invoke	gluBuild2DMipmaps,GL_TEXTURE_2D,3,info.bmWidth,info.bmHeight,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits

            invoke      DeleteObject,hBmp

        	mov		eax,1
        	ret
	.endif
	ret

LoadGLTexture ENDP

ResizeGLScene PROC w:DWORD,h:DWORD

	.if h == 0
		mov		h,1
	.endif
	invoke  glViewport,0,0,w,h
	invoke  glMatrixMode,GL_PROJECTION
	invoke  glLoadIdentity
	push	40590000h		; 100.0
	push	0			; double
	push	3FB99999h		; 0.1
	push	9999999Ah		; double
	fild	dword ptr w
	fidiv	dword ptr h
	sub	esp,8
	fstp	qword ptr [esp]
	push	40468000h		; 45.0
	push	0			; double
	call	gluPerspective
	invoke  glMatrixMode,GL_MODELVIEW
	invoke  glLoadIdentity
	ret

ResizeGLScene ENDP

InitGL PROC

	invoke	LoadGLTexture
	.if !eax
		ret
	.endif
	invoke	glEnable,GL_TEXTURE_2D
	invoke	glShadeModel,GL_SMOOTH
	invoke	glClearColor,0,0,0,0
	invoke	glClearDepth,0,3FF00000h    ;1.0 double
	invoke	glEnable,GL_DEPTH_TEST
	invoke	glDepthFunc,GL_LEQUAL
	invoke	glHint,GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST
	invoke	glLightfv,GL_LIGHT1,GL_AMBIENT,addr Ambient
	invoke	glLightfv,GL_LIGHT1,GL_DIFFUSE,addr Diffuse
	invoke	glLightfv,GL_LIGHT1,GL_POSITION,addr Position
	invoke	glEnable,GL_LIGHT1
	invoke	gluNewQuadric
	mov		quadratic,eax
	invoke	gluQuadricNormals,eax,GLU_SMOOTH
	invoke	gluQuadricTexture,quadratic,GL_TRUE
	mov		eax,quadratic
	ret

InitGL ENDP

DrawGLScene PROC
  LOCAL d1:REAL8,d2:REAL8,tmp:DWORD

	invoke	glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
	invoke	glLoadIdentity
	invoke	glTranslatef,0,0,z
	invoke	glRotatef,xrot,3F800000h,0,0						; 1.0f,0.0f,0.0f
	invoke	glRotatef,yrot,0,3F800000h,0						; 0.0f,1.0f,0.0f
	mov		eax,filter
	invoke	glBindTexture,GL_TEXTURE_2D,texture[eax*4]
	.if object == 0
		invoke	glDrawCube
	.elseif object == 1
		invoke	glTranslatef,0,0,0BFC00000h						      ; 0.0f,0.0f,-1.5f
		invoke	gluCylinder,quadratic,0,3FF00000h,0,3FF00000h,0,40080000h,32,32	; 1.0,1.0,3.0
	.elseif object == 2
		invoke	gluDisk,quadratic,0,3FE00000h,0,3FF80000h,32,32
	.elseif object == 3
		invoke	gluSphere,quadratic,0CCCCCCCDh,3FF4CCCCh,32,32
	.elseif object == 4
		invoke	glTranslatef,0,0,0BFC00000h
		invoke	gluCylinder,quadratic,0,3FF00000h,0,0,0,40080000h,32,32
	.elseif object == 5
		mov		eax,p1
		mov		edx,p2
		add		part1,eax
		add		part2,edx
		.if part1 > 359
			mov		p1,0
			mov		part1,0
			mov		p2,1
			mov		part2,0
		.endif
		.if part2 > 359
			mov		p1,1
			mov		p2,0
		.endif
		fild	      part1
		fstp	      d1
		mov		eax,part2
		sub		eax,part1
		mov		tmp,eax
		fild	      tmp
		fstp	      d2
		invoke	gluPartialDisk,quadratic,0,3FE00000h,0,3FF80000h,32,32,dword ptr d1,dword ptr d1+4,dword ptr d2,dword ptr d2+4
	.endif
	fld	xrot
	fadd	xspeed
	fstp	xrot
	fld	yrot
	fadd	yspeed
	fstp	yrot
	mov		eax,1
	ret

DrawGLScene ENDP

KillGLWindow PROC

	invoke	gluDeleteQuadric,quadratic
	.if fullscreen
		invoke	ChangeDisplaySettings,NULL,0
		invoke	ShowCursor,TRUE
	.endif
	.if hRc
		invoke	wglMakeCurrent,NULL,NULL
		invoke	wglDeleteContext,hRc
		mov		hRc,NULL
	.endif
	.if hDc
		invoke	ReleaseDC,hWnd,hDc
		mov		hDc,NULL
	.endif
	.if hWnd
		invoke	DestroyWindow,hWnd
		mov		hWnd,NULL
	.endif
	invoke	UnregisterClass,addr szClass,hInst
	ret

KillGLWindow ENDP

CreateGLWindow PROC titre:DWORD,w:DWORD,h:DWORD,bpp:DWORD
  LOCAL wc:WNDCLASS,style:DWORD
  LOCAL exstyle:DWORD,wrect:RECT,dm:DEVMODE
  LOCAL pfd:PIXELFORMATDESCRIPTOR

	mov		wrect.left,0
	mov		eax,w
	mov		wrect.right,eax
	mov		wrect.top,0
	mov		eax,h
	mov		wrect.bottom,eax
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_OWNDC
	mov		wc.lpfnWndProc,WndProc
	mov		wc.cbClsExtra,0
	mov		wc.cbWndExtra,0
	mov		eax,hInst
	mov		wc.hInstance,eax
	invoke	LoadIcon,NULL,IDI_WINLOGO
	mov		wc.hIcon,eax
	invoke	LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	mov		wc.hbrBackground,0
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szClass
	invoke	RegisterClass,addr wc
	.if !eax
		invoke	MessageBox,NULL,addr szErr1,addr szErr,MB_ICONERROR or MB_OK
		xor		eax,eax
		ret
	.endif
	.if fullscreen
		ZeroMem	dm,sizeof dm
		mov		dm.dmSize,sizeof dm
		mov		eax,w
		mov		dm.dmPelsWidth,eax
		mov		eax,h
		mov		dm.dmPelsHeight,eax
		mov		eax,bpp
		mov		dm.dmBitsPerPel,eax
		mov		dm.dmFields,DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT
		invoke	ChangeDisplaySettings,addr dm,CDS_FULLSCREEN
		.if eax != DISP_CHANGE_SUCCESSFUL
			invoke	MessageBox,NULL,addr szErr2,addr szErr,MB_YESNO or MB_ICONQUESTION
			.if eax == IDYES
				mov		fullscreen,0
			.else
				xor		eax,eax
				ret
			.endif
		.endif
	.endif
	.if fullscreen
		mov		exstyle,WS_EX_APPWINDOW
		mov		style,WS_POPUP
		invoke	ShowCursor,FALSE
	.else
		mov		exstyle,WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
		mov		style,WS_OVERLAPPEDWINDOW
	.endif
	invoke	AdjustWindowRectEx,addr wrect,style,FALSE,exstyle
	mov		eax,wrect.right
	mov		ebx,wrect.bottom
	mov		ecx,style
	sub		eax,wrect.left
	sub		ebx,wrect.top
	or		ecx,WS_CLIPSIBLINGS or WS_CLIPCHILDREN
	invoke	CreateWindowEx,exstyle,addr szClass,titre,ecx,0,0,eax,ebx,NULL,NULL,hInst,NULL
	.if !eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr3,addr szErr,MB_ICONERROR or MB_OK
		xor		eax,eax
		ret
	.endif
	mov		hWnd,eax
	ZeroMem	pfd,sizeof pfd
	mov		pfd.nSize,sizeof pfd
	mov		pfd.nVersion,1
	mov		pfd.dwFlags,PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
	mov		pfd.iPixelType,PFD_TYPE_RGBA
	mov		eax,bpp
	mov		pfd.cColorBits,al
	mov		pfd.cDepthBits,16
	mov		pfd.iLayerType,PFD_MAIN_PLANE
	invoke	GetDC,hWnd
	.if	!eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr4,addr szErr,MB_OK or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	mov		hDc,eax
	invoke	ChoosePixelFormat,hDc,addr pfd
	.if	!eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr5,addr szErr,MB_OK or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	lea		ebx,pfd
	push	ebx
	push	eax
	push	hDc
	call	SetPixelFormat
	.if !eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr6,addr szErr,MB_OK or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	invoke	wglCreateContext,hDc
	.if !eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr7,addr szErr,MB_OK or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	mov		hRc,eax
	invoke	wglMakeCurrent,hDc,eax
	.if !eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr8,addr szErr,MB_OK or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	invoke	ShowWindow,hWnd,SW_SHOW
	invoke	SetForegroundWindow,hWnd
	invoke	SetFocus,hWnd
	invoke	ResizeGLScene,w,h
	invoke	InitGL
	.if !eax
		invoke	KillGLWindow
		invoke	MessageBox,NULL,addr szErr9,addr szErr,MB_OK or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	mov		eax,1
	ret

CreateGLWindow ENDP

WndProc	PROC hW:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

	.if uMsg == WM_ACTIVATE
		mov		eax,wParam
		shr		eax,16
		.if !ax
			mov		active,1
		.else
			mov		active,0
		.endif
		xor		eax,eax
		ret
	.elseif uMsg == WM_SYSCOMMAND
		.if (wParam == SC_SCREENSAVE) || (wParam == SC_MONITORPOWER)
			xor		eax,eax
			ret
		.endif
	.elseif uMsg == WM_CLOSE
		invoke	PostQuitMessage,0
		xor		eax,eax
		ret
	.elseif uMsg == WM_KEYDOWN
		mov		eax,wParam
		mov		keys[eax],1
		xor		eax,eax
		ret
	.elseif uMsg == WM_KEYUP
		mov		eax,wParam
		mov		keys[eax],0
		xor		eax,eax
		ret
	.elseif uMsg == WM_SIZE
		mov		eax,lParam
		movzx	ebx,ax
		shr		eax,16
		invoke	ResizeGLScene,ebx,eax
		xor		eax,eax
		ret
	.endif
	invoke	DefWindowProc,hW,uMsg,wParam,lParam
	ret

WndProc ENDP

WinMain PROC hInstance:DWORD,lpCmdLine:DWORD,nCmdShow:DWORD
  LOCAL msg:MSG,done:DWORD

	mov		done,0
	invoke	MessageBox,NULL,addr szMsg1,addr szTitle,MB_YESNO or MB_ICONQUESTION
	.if eax == IDYES
		mov		fullscreen,1
	.else
		mov		fullscreen,0
	.endif
	invoke		CreateGLWindow,addr szTitle,640,480,16
	.if !eax
		xor	eax,eax
		ret
	.endif
	.while !done
		invoke	PeekMessage,addr msg,NULL,0,0,PM_REMOVE
		.if eax
			.if	msg.message == WM_QUIT
				mov		done,1
			.else
				invoke	TranslateMessage,addr msg
				invoke	DispatchMessage,addr msg
			.endif
		.else
			.if active
				.if keys[VK_ESCAPE]
					mov		done,1
				.else
					invoke	DrawGLScene
					invoke	SwapBuffers,hDc
					.if keys[VK_L] && !lp
						mov		lp,1
						xor		light,1
						.if !light
							invoke	glDisable,GL_LIGHTING
						.else
							invoke	glEnable,GL_LIGHTING
						.endif
					.endif
					.if !keys[VK_L]
						mov		lp,0
					.endif
					.if keys[VK_F] && !fp
						mov		fp,1
						inc		filter
						.if filter > 2
							mov		filter,0
						.endif
					.endif
					.if !keys[VK_F]
						mov		fp,0
					.endif
					.if keys[VK_SPACE] && !space
						mov		space,1
						inc		object
						.if object > 5
							mov		object,0
						.endif
					.endif
					.if !keys[VK_SPACE]
						mov		space,0
					.endif
					.if keys[VK_PRIOR]
						fld	z
						fsub	fpc(0.02f)
						fstp	z
					.endif
					.if keys[VK_NEXT]
						fld	z
						fadd	fpc(0.02f)
						fstp	z
					.endif
					.if keys[VK_UP]
						fld	xspeed
						fsub	fpc(0.01f)
						fstp	xspeed
					.endif
					.if keys[VK_DOWN]
						fld	xspeed
						fadd	fpc(0.01f)
						fstp	xspeed
					.endif
					.if keys[VK_LEFT]
						fld	yspeed
						fsub	fpc(0.01f)
						fstp	yspeed
					.endif
					.if keys[VK_RIGHT]
						fld	yspeed
						fadd	fpc(0.01f)
						fstp	yspeed
					.endif
					.if keys[VK_F1]
						mov		keys[VK_F1],0
						invoke	KillGLWindow
						xor		fullscreen,1
						invoke	CreateGLWindow,addr szTitle,640,480,16
						.if !eax
							xor	eax,eax
							ret
						.endif
					.endif
				.endif
			.endif
		.endif
	.endw
	invoke	KillGLWindow
	mov		eax,msg.wParam
	ret

WinMain ENDP

END Start