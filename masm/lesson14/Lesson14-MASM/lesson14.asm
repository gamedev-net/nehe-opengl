; Attempt at NeHe's tutorial 14 : Drawing outline fonts
;
; Author: Greg Helps [x86@ozducati.com]
; Date: July 3 2003
;
; With thanks to NeHe for the OpenGL tutorials <http://nehe.gamedev.net/>
; Inspiration for x86 Assembler from Nico <scalp@bigfoot.com>
; OpenGL x86 includes originally from hardcode <http://bizarrecreations.webjump.com>
; although the site is now offline. 
; I've included the OpenGL include files in the original archive as they are hard to find.
;
; Bugs are mine.
;
; I'm a beginner. If you've any comments / suggestions / questions - bring em on
.586
.model flat, stdcall
option casemap:none

; INCLUDES * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\masm32.inc
include c:\masm32\def\gl.def
include c:\masm32\def\glu.def
include c:\masm32\def\winextra.def

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\opengl32.lib
includelib c:\masm32\lib\glu32.lib

; Uses MS C runtime library for sprintf function. 
; Included with all MS windows systems (I think) from win95C onwards
includelib c:\masm32\lib\msvcrt.lib


; Missing from include files * * * * * * * * * * * * * * * * * * * * * 
DM_BITSPERPEL       = 00040000h
DM_PELSWIDTH        = 00080000h
DM_PELSHEIGHT       = 00100000h
ANTIALIASED_QUALITY = 4
WGL_FONT_POLYGONS 	= 1


; PROTOTYPES * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
WinMain 		PROTO :HWND, :UINT, :WPARAM, :LPARAM
CreateGLWindow 	PROTO :DWORD, :DWORD, :DWORD, :UINT, :BOOL
WndProc 		PROTO :HWND, :UINT, :WPARAM, :LPARAM
KillGLWindow 	PROTO
ReSizeGLScene 	PROTO :GLsizei, :GLsizei
InitGL 			PROTO
DrawGLScene 	PROTO
LoadGLTexture	PROTO
BuildFont		PROTO
KillFont		PROTO
glPrint			PROTO :DWORD

sprintf 		PROTO C :DWORD, :VARARG	; printf C function prototype from MS C runtime library
strlen			PROTO C :VARARG			; strlen C function prototype from MS C runtime library


; MACROS * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
; The following were missing from the hardcode include files
_glClearDepth MACRO t
    gl_dpush t
    mov eax, eax
    mov ebx, ebx
    call glClearDepth
ENDM

_gluPerspective MACRO a,b,c,d
    gl_dpush d
    gl_dpush c
    gl_dpush b
    gl_dpush a
    mov eax, eax
    mov ebx, ebx
    call gluPerspective
ENDM

_glClearColor MACRO a,b,c,d
    gl_fpush d
    gl_fpush c
    gl_fpush b
    gl_fpush a
    mov eax, eax
    mov ecx, ecx
    call glClearColor
ENDM

_glRasterPos2f MACRO a,b
	gl_fpush b
	gl_fpush a
	call glRasterPos2f
ENDM

; fpc macro allows constants to be used with floating point operations.
; Authored by bitRAKE from Win32ASM board <http://board.win32asmcommunity.net>
; Great resource for assembler hackers
fpc MACRO val:REQ
	LOCAL w,x,y,z,zz,ww

	;; split type and value, defaulting to REAL4
	z INSTR 1,<&val>,<! >
	IF z EQ 0
		y TEXTEQU <REAL4>
		x TEXTEQU <&val>
	ELSE
		y TEXTEQU @SubStr(<&val>,1,z-1)	;; Type
		x TEXTEQU @SubStr(<&val>,z+1,)	;; Value
	ENDIF

	;; replace . with _
	z INSTR 1,x,<!.>
	IF z EQ 0
		w TEXTEQU x
		x CATSTR x,<.0> ;; prevent error message
	ELSE
		w CATSTR @SubStr(%x,1,z-1),<_>,@SubStr(%x,z+1,)
	ENDIF

	;; replace - with _
	zz INSTR 1,w,<!->
	IF zz EQ 0
		ww TEXTEQU w
	ELSE
		ww CATSTR @SubStr(%w,1,zz-1),<_>,@SubStr(%w,zz+1,)
	ENDIF

	;; figure out global name for constant
	z SIZESTR y ;; use last char for size distiction
	ww CATSTR <__>,ww,<r>,@SubStr(%y,z,1)

	IF (OPATTR(ww)) EQ 0 ;; not defined
		CONST SEGMENT
			ww y x
		CONST ENDS
	ENDIF
	EXITM ww
ENDM


; INITIALISED DATA * * * * * * * * * * * * * * * * * * * * * * * * * * 
.data
txt_Query_Fullscn				db		"Do you want to run in fullscreen?",0
txt_Title_Fullscn				db		"Graphics mode",0
txt_Window_Title				db		"NeHe's Outline Font Tutorial",0
txt_OpenGL						db		"OpenGL",0
txt_WC_Failed					db		"Failed to registed window class",0
txt_GL_Context_Failed			db		"Failed to create a GL device context",0
txt_RC_Failed					db		"Failed to create a GL rendering context",0
txt_PixelFormat_Failed			db		"Failed to find suitable PixelFormat",0
txt_ActivateRC_Failed			db		"Failed to activate GL rendering context",0
txt_GLInit_Failed				db		"Initialisation failed",0
txt_SetPixelFormat_Failed		db		"Failed to set PixelFormat",0
txt_WindowCreateError			db		"Window creation error",0
txt_Error						db		"Error",0
;
txt_FontName					db		"Comic Sans MS",0
txt_Message						db		"NeHe - %3.2f",0


; UNINITIALISED DATA * * * * * * * * * * * * * * * * * * * * * * * * * 
.data?
; Define GMF array
GLYPHMETRICSFLOAT STRUCT
	gmfBlackBoxX FLOAT ?
	gmfBlackBoxY FLOAT ?
	x FLOAT ?
	y FLOAT ?
	gmfCellIncX FLOAT ?
	gmfCellIncY FLOAT ?
GLYPHMETRICSFLOAT ENDS
GMFSIZE EQU SIZEOF GLYPHMETRICSFLOAT

gmf	GLYPHMETRICSFLOAT 256 dup (<>)

rot				GLfloat		?	; holds rotational value of text
base			GLuint		?	; Font base

hRC				HGLRC     	?	;
hDC           	HDC       	?	; Open GL window structures
hWnd          	HWND      	?	;
hInstance     	HINSTANCE	?	;

keys          	db 256 dup (?)	; keypress status
fullscreen    	BOOL		?	; fullscreen toggle
active        	BOOL     	?	; window active toggle/status

txt_Buffer		byte 64 dup (?)	; A general text buffer for string manipulation


; BUGS BEGIN HERE * * * * * * * * * * * * * * * * * * * * * * * * * * 
.code

start:
invoke GetModuleHandle,0
mov hInstance, eax
invoke WinMain,hInstance,0,0,0
invoke ExitProcess, eax
;** END

; PROC WinMain * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
WinMain	proc hInst:HWND, hPrevInst:UINT, CmdLine:WPARAM, CmdShow:LPARAM
	LOCAL msg:MSG, done:UINT

	; Check	if we should start in full screen
	invoke MessageBox,NULL,addr	txt_Query_Fullscn,addr txt_Title_Fullscn,MB_YESNO or MB_ICONQUESTION

	.IF	eax	== IDNO
		mov	fullscreen,FALSE
	.ELSE
		mov	fullscreen,TRUE
	.ENDIF

	invoke CreateGLWindow,addr txt_Window_Title,640,480,16,fullscreen
	.IF	!eax
		ret
	.ENDIF

	mov	done,FALSE

	.WHILE !done
		invoke PeekMessage,addr	msg,NULL,0,0,PM_REMOVE
		.IF	eax
			.IF	msg.message	== WM_QUIT
				mov	done,TRUE
			.ELSE
				invoke TranslateMessage,addr msg
				invoke DispatchMessage,addr	msg
			.ENDIF
		.ELSE
			invoke DrawGLScene
			.IF ((active) && (!eax)) || (keys[VK_ESCAPE])
				mov done, 1
			.ELSE
				invoke SwapBuffers,hDC
			.ENDIF
	  		
			.IF	keys[VK_F1]
				mov	keys[VK_F1],FALSE
				invoke KillGLWindow
				xor	fullscreen,	1
				invoke CreateGLWindow,addr txt_Window_Title,640,480,16,fullscreen
				.IF	!eax
					mov	eax,FALSE
				.ENDIF
			.ENDIF
		.ENDIF
	.ENDW
	invoke KillGLWindow

	mov	eax,msg.wParam
	ret
WinMain	endp


; PROC InitGL * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
InitGL proc
  	invoke glShadeModel,GL_SMOOTH
  	_glClearColor 0.0f,0.0f,0.0f,0.5f
  	_glClearDepth 1.0f
  	invoke glEnable,GL_DEPTH_TEST
  	invoke glDepthFunc,GL_LEQUAL
 	invoke glHint,GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST
 	invoke glEnable, GL_LIGHT0
 	invoke glEnable, GL_LIGHTING
 	invoke glEnable, GL_COLOR_MATERIAL

	invoke BuildFont	; Create the outline fonts

	fld fpc(0.0)	; Good practice to initialise vars before use
	fstp rot		; although we'd get away without it

	mov eax, 1  		
  	ret
InitGL endp


; PROC CreateGLWindow * * * * * * * * * * * * * * * * * * * * * * * * 
CreateGLWindow proc WinTitle:DWORD, WinWidth:DWORD, WinHeight:DWORD, WinBits:UINT, WinFullscreen:BOOL
	LOCAL dwExStyle:DWORD, dwStyle:DWORD, PixelFormat:GLuint
	LOCAL WindowRect:RECT, dmScreenSettings:DEVMODE, wc:WNDCLASS, pfd:PIXELFORMATDESCRIPTOR

	mov WindowRect.left,0
	mov WindowRect.top,0
	push WinWidth
	pop WindowRect.right
	push WinHeight
	pop WindowRect.bottom

	push WinFullscreen
	pop fullscreen

	invoke GetModuleHandle,NULL
	mov hInstance,eax
	mov wc.style,CS_HREDRAW or CS_VREDRAW or CS_OWNDC
	mov wc.lpfnWndProc, offset WndProc
	mov wc.cbClsExtra,0
	mov wc.cbWndExtra,0
	push hInstance
	pop wc.hInstance
	mov wc.hbrBackground,NULL
	mov wc.lpszMenuName,NULL
	mov wc.lpszClassName,offset txt_OpenGL
	invoke LoadIcon,NULL,IDI_WINLOGO
	mov wc.hIcon,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov wc.hCursor,eax

	; Register the window class
	invoke RegisterClass,addr wc
	.IF !eax
		invoke MessageBox,NULL,addr txt_WC_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF

	; Set fullscreen, if appropriate
	.IF fullscreen
		ZeroMemory &dmScreenSettings,sizeof(dmScreenSettings)
		mov dmScreenSettings.dmSize,sizeof dmScreenSettings
		push WinWidth
		pop dmScreenSettings.dmPelsWidth
		push WinHeight
		pop dmScreenSettings.dmPelsHeight
		push WinBits
		pop dmScreenSettings.dmBitsPerPel
		mov dmScreenSettings.dmFields,DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT

		; Try to set selected mode
		invoke ChangeDisplaySettings,addr dmScreenSettings,CDS_FULLSCREEN
		.IF eax != DISP_CHANGE_SUCCESSFUL
			; Original code prompts user, and asks to set to window or exit. I'll just set to window mode
			mov fullscreen,FALSE
		.ENDIF
	.ENDIF

	; Check if we are (still?) in fullscreen
	.IF fullscreen
		mov dwExStyle, WS_EX_APPWINDOW
		mov dwStyle,WS_POPUP
		invoke ShowCursor,FALSE
	.ELSE
		mov dwExStyle,WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
		mov dwStyle, WS_OVERLAPPEDWINDOW 
	.ENDIF

	invoke AdjustWindowRectEx,addr WindowRect,dwStyle,FALSE,dwExStyle
	mov eax, WindowRect.left
	sub WindowRect.right,eax
	mov eax, WindowRect.top
	sub WindowRect.bottom, eax
	
	mov eax,dwStyle
	or eax,WS_CLIPSIBLINGS or WS_CLIPCHILDREN
	invoke CreateWindowEx,dwExStyle,addr txt_OpenGL,addr txt_Window_Title,eax,
		0,0,WindowRect.right,WindowRect.bottom,NULL,NULL,hInstance,NULL
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,txt_WindowCreateError,txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax, FALSE
		ret
	.ENDIF
	 mov hWnd,eax

	ZeroMemory &pfd,sizeof(PIXELFORMATDESCRIPTOR)
	mov pfd.nSize,sizeof(PIXELFORMATDESCRIPTOR)
	mov pfd.nVersion,1
	mov pfd.dwFlags,PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER 
	mov pfd.iPixelType,PFD_TYPE_RGBA
	mov pfd.cColorBits,16
	mov pfd.cDepthBits,16
	mov pfd.dwLayerMask,PFD_MAIN_PLANE

	; Try to get a device context
	invoke GetDC,hWnd
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,addr txt_GL_Context_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF
	mov hDC,eax

	; Select pixel format
	invoke ChoosePixelFormat,hDC,addr pfd
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,addr txt_PixelFormat_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF
	mov PixelFormat,eax

	; Set pixel format
	invoke SetPixelFormat,hDC,PixelFormat,addr pfd
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,addr txt_SetPixelFormat_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF

	; Get rendering context
	invoke wglCreateContext,hDC
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,addr txt_RC_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF
	mov hRC,eax

	; Activate rendering context
	invoke wglMakeCurrent,hDC,hRC
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,addr txt_ActivateRC_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF

	invoke ShowWindow,hWnd,SW_SHOW
	invoke SetForegroundWindow,hWnd
	invoke SetFocus,hWnd
	invoke ReSizeGLScene,WinWidth,WinHeight

	invoke InitGL
	.IF !eax
		invoke KillGLWindow
		invoke MessageBox,NULL,addr txt_GLInit_Failed,addr txt_Error,MB_OK or MB_ICONEXCLAMATION
		mov eax,FALSE
		ret
	.ENDIF
	
	mov eax,TRUE
	ret
CreateGLWindow endp


; PROC KillGLWindow * * * * * * * * * * * * * * * * * * * * * * * * * 
KillGLWindow proc
	.IF fullscreen
		invoke ChangeDisplaySettings,NULL,0
		invoke ShowCursor,TRUE
	.ENDIF
	
	.IF hRC
		invoke wglMakeCurrent,NULL,NULL
		invoke wglDeleteContext,hRC
		mov hRC,NULL
	.ENDIF
	
	.IF hDC
		invoke ReleaseDC,hWnd,hDC
		mov hDC,NULL
	.ENDIF
	
	.IF hWnd
		invoke DestroyWindow,hWnd
		mov hWnd,NULL
	.ENDIF
	
	invoke UnregisterClass,addr txt_OpenGL,hInstance
	mov hInstance,NULL
	
	ret
KillGLWindow endp


; PROC WndProc * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
WndProc proc hWind:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.IF uMsg == WM_ACTIVATE
    	mov eax,wParam
	    .IF !ah
    		mov active,TRUE
    	.ELSE
      		mov active,FALSE
    	.ENDIF
    	xor eax, eax
    	ret
	.ELSEIF uMsg==WM_SYSCOMMAND
  		.IF wParam == SC_SCREENSAVE or SC_MONITORPOWER
      		xor eax, eax
      		ret
    	.ENDIF
	.ELSEIF uMsg==WM_CLOSE
  		invoke PostQuitMessage,0
    	xor eax, eax
    	ret
  	.ELSEIF uMsg==WM_KEYDOWN
		mov eax,wParam
    	mov keys[eax],TRUE
    	xor eax, eax
    	ret
  	.ELSEIF uMsg==WM_KEYUP
		mov eax,wParam
    	mov keys[eax],FALSE
    	xor eax, eax
    	ret
  	.ELSEIF uMsg==WM_SIZE
    	mov eax,lParam
    	mov ebx,eax
		and eax,00000000000000001111111111111111b
    	shr ebx,16
    	invoke ReSizeGLScene,eax,ebx
    	xor eax, eax
    	ret
  	.ENDIF
  
  	invoke DefWindowProc,hWind,uMsg,wParam,lParam
  	ret
WndProc endp


; PROC ReSizeGLScene * * * * * * * * * * * * * * * * * * * * * * * * * 
ReSizeGLScene proc widthx:DWORD, heighty:DWORD
	LOCAL ratio:GLdouble
  
  	.IF heighty == 0
    	mov heighty, 1 ; prevent div by zero
  	.ENDIF
	invoke glViewport, 0, 0, widthx, heighty
  	invoke glMatrixMode, GL_PROJECTION
  	_glLoadIdentity  
		
  	fild widthx
  	fild heighty
  	fdivp st(1),st(0)
  	fstp ratio
  	_gluPerspective 45.0f, ratio, 0.1f,100.0f
  	invoke glMatrixMode, GL_MODELVIEW
  	_glLoadIdentity
  	ret
ReSizeGLScene endp


; PROC BuildFont * * * * * * * * * * * * * * * * * * * * * * * * * * * 
BuildFont proc
	LOCAL font:HFONT	; windows font ID

	invoke glGenLists, 256	; Create storage for 256 Characters
	mov base, eax
	
	invoke CreateFont, -12, 0, 0,0, FW_BOLD, FALSE, FALSE, FALSE, ANSI_CHARSET, 
		OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, FF_DONTCARE or DEFAULT_PITCH, addr txt_FontName
	mov font, eax
	
	invoke SelectObject, hDC, font
	invoke wglUseFontOutlines, hDC, 0, 255, base, fpc(0.0), fpc(0.2), WGL_FONT_POLYGONS, offset gmf

	mov eax, 1
	ret
BuildFont endp


; PROC KillFont * * * * * * * * * * * * * * * * * * * * * * * * * * * 
KillFont proc
	invoke glDeleteLists, base, 256
	mov eax, 1
	ret
KillFont endp


; PROC DrawGLScene * * * * * * * * * * * * * * * * * * * * * * * * * * 
DrawGLScene proc
	LOCAL c4:QWORD
	LOCAL c1:GLfloat, c2:GLfloat, c3:GLfloat

  	invoke glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
	invoke glLoadIdentity
	_glTranslatef 0.0f, 0.0f, -10.0f
	
	_glRotatef rot, 1.0f, 0.0f, 0.0f
	fld rot
	fmul fpc(1.5)
	fstp c2
	fld rot
	fmul fpc(1.4)
	fstp c3
	_glRotatef c2, 0.0f, 1.0f, 0.0f
	_glRotatef c3, 0.0f, 0.0f, 1.0f
	
	fld rot
	fdiv fpc(20.0)
	fcos
	fstp c1
	fld rot
	fdiv fpc(25.0)
	fsin
	fstp c2
	fld rot
	fdiv fpc(17.0)
	fcos
	fmul fpc(0.5)
	fsubr fpc(1.0)
	fstp c3
  	_glColor3f c1, c2, c3
  	
	; Add rot/50 to end of scrollymessage
	fld rot
	fdiv fpc(50.0)
	fstp c4

	; Format the string.
	; c4 is a QWORD. we can pass it to sprintf by passing it as two DWORDS. 
	; cast it with DWORD PTR and send HO dword and LO dword separately like thus:
	invoke sprintf, addr txt_Buffer, addr txt_Message, DWORD PTR [c4], DWORD PTR [c4+4]
  	invoke glPrint, addr txt_Buffer
  	
  	fld rot
  	fadd fpc(0.5)
  	fstp rot
  	
    mov eax, 1
    ret
DrawGLScene endp


; PROC glPrint * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
glPrint proc fmt:DWORD
	LOCAL textlen:REAL4
	LOCAL stringlen:UINT
	
	.IF (fmt == NULL)
		ret
	.ENDIF
	
	fild fpc(0.0)	; load zero to st0. this is the width of the outline text.

	invoke strlen, fmt
	mov stringlen, eax	; discover length of the fmt parameter

	mov ecx, 0			; Loop until we equal the length of the fmt parameter
@@:	xor ebx, ebx 		; mov ebx, 0

	mov eax, fmt		; st0 = st0 + gmf[fmt+ecx].gmfCellIncX;
	mov bl, [ecx+eax]	
	mov eax, GMFSIZE
	mul ebx
	fadd gmf[eax].gmfCellIncX
	
	inc ecx
	cmp ecx, stringlen
	jl @B
	
	fdiv fpc(2.0)		; divide st0 by two & change signs to negative
	fchs
	fstp textlen
	invoke glTranslatef, textlen, fpc(0.0), fpc(0.0)
	
	invoke glPushAttrib, GL_LIST_BIT
	invoke glListBase, base
	invoke glCallLists, stringlen, GL_UNSIGNED_BYTE, fmt
	invoke glPopAttrib

	ret
glPrint endp

end start
 
