; Assembly conversion of NeHe's openGL tutorial done by FooLman
; 
.386
.model flat,STDCALL
locals
include win32.inc
include addwin32.inc
include gl.inc
include glu.inc
L equ <LARGE>

extrn MessageBoxA:PROC
MessageBox equ <MessageBoxA>
extrn ChangeDisplaySettingsA:PROC
ChangeDisplaySettings equ <ChangeDisplaySettingsA>
extrn ShowCursor:PROC
extrn wglMakeCurrent:PROC
extrn wglDeleteContext:PROC
extrn ReleaseDC:PROC
extrn DestroyWindow:PROC
extrn LoadIconA:PROC
LoadIcon equ <LoadIconA>
extrn LoadCursorA:PROC
LoadCursor equ <LoadCursorA>
extrn GetModuleHandleA:PROC
GetModuleHandle equ <GetModuleHandleA>
extrn RegisterClassA:PROC
RegisterClass equ <RegisterClassA>
extrn CreateWindowExA:PROC
CreateWindowEx equ <CreateWindowExA>
extrn GetDC:PROC
extrn ChoosePixelFormat:PROC
extrn SetPixelFormat:PROC
extrn wglCreateContext:PROC
extrn ShowWindow:PROC
extrn SetForegroundWindow:PROC
extrn SetFocus:PROC
extrn DefWindowProcA:PROC
extrn PostQuitMessage:PROC
extrn TranslateMessage:PROC
extrn DispatchMessageA:PROC
DispatchMessage equ <DispatchMessageA>
extrn SwapBuffers:PROC
extrn PeekMessageA:PROC
PeekMessage equ <PeekMessageA>
DefWindowProc equ <DefWindowProcA>

; Numeric Data constants

_45d0	equ 40468000h ;45.0
_45d1   equ 0	
_01d0	equ 1069128089		 
_01d1   equ -1717986918 ;0.1
_100d0	equ 1079574528
_100d1  equ 0		;100.0
_1d0	equ 1072693248
_1d1	equ 0 		;1.0
_05	equ 1056964608  ; 0.5
_1	equ 1065353216  ; 1.0
_m1	equ -1082130432 ;-1.0
_3	equ 1077936128  ; 3.0
_m15	equ -1077936128 ;-1.5
_m6	equ -1061158912 ;-6.0
_15	equ 1069547520


_glVertex3f macro A1,A2,A3
push A3
push A2
push A1
call glVertex3f
endm

_glColor3f macro A1,A2,A3
push A3
push A2
push A1
call glColor3f
endm

_glRotatef macro A1,A2,A3,A4
push A4
push A3
push A2
push A1
call glRotatef
endm

_glTranslatef macro A1,A2,A3
push A3
push A2
push A1
call glTranslatef
endm
_glBegin macro A1
push A1
call glBegin
endm

.data
RCF	db 'Release Of DC And RC Failed.',0
RRC	db 'Release Rendering Context Failed.',0
RDC	db 'Release Device Context Failed.',0
CNR	db 'Could Not Release hWnd.',0
FTR	db 'Failed To Register The Window Class.',0
FSNS	db 'The Requested Fullscreen Mode Is Not Supported By',10,'Your Video Card. Use Windowed Mode Instead?',0
PWC	db 'Program Will Now Close.',0
CGLC	db 'Can''t Create a GL Device Context',0
CFPF	db 'Can''t Find A Suitable PixelFormat.',0
CSPF	db 'Can''t Set The PixelFormat',0
CCRC	db 'Can''t Create A GL Rendering Context.',0
CARC	db 'Can''t Activate The GL Rendering Context.',0
INF	db 'Initalization Failed.',0
RIF	db 'Would You Like To Run In FullScreen Mode?',0
WT	db 'NeHE''s Solid Object Tutorial',0
SFS	db 'Start FullScreen?',0
NGL	db 'NeHe GL',0
WCE	db 'Window Creation Error.',0
SDE	db 'SHUTDOWN '
ER 	db 'ERROR',0
ClassName db 'OpenGL',0;
trirot 	dd 0.2
qrot	dd -0.15
rtri dd 0.0
rquad dd 0.0
_aspd 	dq ?
active  db ?
fullscreen dw ?
hDC	dd ?
hRC	dd ?
hWnd	dd ?
PixelFormat dd ?
done db ?
keys db 256 dup (?)
wc WNDCLASS <?>
dmScreenSettings DEVMODE <?>
pfd PIXELFORMATDESCRIPTOR <?>
msg  MSGSTRUCT <?>
wTitle dd ?
width dd ?
height dd ?
bits dd ?
fullscreenflag dd ?
hInstance dd ?
.code

ReSizeGLScene proc  ; approved
	cmp [height],0
	jne @@1
	inc [height]
@@1:	
	push height
	push width
	push L 0
	push L 0
	call glViewport
	push L GL_PROJECTION
	call glMatrixMode
	call glLoadIdentity
	fild width
	fild height
	fdivp st(1),st
	fstp _aspd
	push _100d0
	push _100d1
	push _01d0
	push _01d1
	push dword ptr [_aspd+4]
	push dword ptr [_aspd]
	push _45d0
	push _45d1
	call gluPerspective
	push L GL_MODELVIEW
	call glMatrixMode
	call glLoadIdentity
	ret
ReSizeGLScene endp 
InitGL	proc 
	push L GL_SMOOTH
	call glShadeModel
	push _05
	push L 0
	push L 0
	push L 0
	call glClearColor
	push _1d0
	push _1d1
	call glClearDepth

	push GL_DEPTH_TEST
	call glEnable

	push GL_LEQUAL
	call glDepthFunc

	push GL_NICEST
	push GL_PERSPECTIVE_CORRECTION_HINT
	call glHint
	xor  eax,eax
	ret
InitGL	endp

DrawGLScene proc ;approved.
	push L (GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
	call glClear
	call glLoadIdentity
	_glTranslatef _m15,0,_m6
	_glRotatef rtri,0,_1,0
	_glBegin GL_TRIANGLES
					;FRONT
	_glColor3f   _1,  0,  0			
	_glVertex3f   0, _1,  0
	_glColor3f    0, _1,  0
	_glVertex3f _m1,_m1, _1
	_glColor3f    0,  0, _1
	_glVertex3f  _1,_m1, _1
					;RIGHT
	_glColor3f   _1,  0,  0
	_glVertex3f   0, _1,  0
	_glColor3f    0,  0, _1
	_glVertex3f  _1,_m1, _1
	_glColor3f    0, _1,  0
	_glVertex3f  _1,_m1,_m1
					;BACK

	_glColor3f   _1,  0,  0
	_glVertex3f   0, _1,  0
	_glColor3f    0, _1,  0
	_glVertex3f  _1,_m1,_m1
	_glColor3f    0,  0, _1
	_glVertex3f _m1,_m1,_m1
					;LEFT
	_glColor3f    0,  0, _1
	_glVertex3f _m1,_m1,_m1
	_glColor3f   _1,  0,  0
	_glVertex3f   0, _1,  0
	_glColor3f    0, _1,  0
	_glVertex3f _m1,_m1, _1
	
	call glEnd
	call glLoadIdentity
	_glTranslatef _15,0,_m6
	_glRotatef rquad,_1,_1,_1
	_glBegin GL_QUADS

	_glColor3f 0,_1,0
	_glVertex3f  _1, _1,_m1
	_glVertex3f _m1, _1,_m1
	_glVertex3f _m1, _1, _1
	_glVertex3f  _1, _1, _1

	_glColor3f _1,_05,0
	_glVertex3f  _1,_m1, _1
	_glVertex3f _m1,_m1, _1
	_glVertex3f _m1,_m1,_m1
	_glVertex3f  _1,_m1,_m1

	_glColor3f _1, 0, 0
	_glVertex3f  _1, _1, _1
	_glVertex3f _m1, _1, _1
	_glVertex3f _m1,_m1, _1
	_glVertex3f  _1,_m1, _1

	_glColor3f _1,_1,0
	_glVertex3f  _1,_m1,_m1
	_glVertex3f _m1,_m1,_m1
	_glVertex3f _m1, _1,_m1
	_glVertex3f  _1, _1,_m1

	_glColor3f 0,0,_1
	_glVertex3f _m1, _1, _1
	_glVertex3f _m1, _1,_m1
	_glVertex3f _m1,_m1,_m1
	_glVertex3f _m1,_m1, _1

	_glColor3f _1,0,_1
	_glVertex3f  _1, _1,_m1
	_glVertex3f  _1, _1, _1
	_glVertex3f  _1,_m1, _1
	_glVertex3f  _1,_m1,_m1
	call glEnd
	fld rtri
	fadd trirot
	fstp rtri
	fld rquad
	fadd qrot
	fstp rquad
	call glFinish
	xor eax,eax
	ret
DrawGLScene endp	

KillGLWindow proc
	mov ax,[fullscreen]
	or  ax,ax
	jz  @@1
	push 0
	push L 0
	call ChangeDisplaySettings
	push 1
	call ShowCursor
@@1:	
	mov eax, hRC
	or eax,eax
	jz @@2
	push L 0
	push L 0
	call wglMakeCurrent
	or eax,eax
	jnz @@3
	push MB_OK or MB_ICONINFORMATION
	push offset SDE
	push offset RCF
	push L 0
	call MessageBox
@@3:
	push hRC
	call wglDeleteContext
	or ax,ax
	jnz @@4
	push MB_OK or MB_ICONINFORMATION
	push offset SDE
	push offset RRC
	push L 0
	call MessageBox
@@4:	
	xor eax,eax
	mov [hRC],eax	
@@2:
	mov eax,[hDC]
	or eax,eax
	jz @@5
	push hDC
	push hWnd
	call ReleaseDC
	or eax,eax
	jnz @@5
	push MB_OK or MB_ICONINFORMATION
	push offset SDE
	push offset RDC
	push L 0
	call MessageBox
	xor eax,eax
	mov [hDC],eax
@@5:
	mov eax,hWnd
	or  eax,eax
	jz  @@6
	push hWnd
	call DestroyWindow
	or  eax,eax
	jnz  @@6
	push MB_OK or MB_ICONINFORMATION
	push offset SDE
	push offset CNR
	push L 0
	call MessageBox
	xor eax,eax
	mov [hWnd],eax
@@6:
	ret
KillGLWindow endp

CreateGLWindow	proc	
	mov eax,[fullscreenflag]
	mov [fullscreen],ax
	push L 0
	call GetModuleHandle
	mov hInstance,eax
	mov [wc.clsStyle], CS_HREDRAW or CS_VREDRAW or CS_OWNDC	
	mov [wc.clsLpfnWndProc], offset WndProc
	mov [wc.clsCbClsExtra],0
	mov [wc.clsCbWndExtra],0
	mov [wc.clsHInstance],eax
	push IDI_WINLOGO
	push L 0
	call LoadIcon
	mov [wc.clsHIcon],eax
	push IDC_ARROW
	push L 0
	call LoadCursor
	mov [wc.clsHCursor],eax
	mov [wc.clsHbrBackground],0
	mov [wc.clsLpszMenuName],0
	mov [wc.clsLpszClassName],offset ClassName
	push offset wc
	call RegisterClass
	or ax,ax
	jnz @@1
	push MB_OK or MB_ICONEXCLAMATION
	push offset ER
	push offset FTR
	push L 0
	call MessageBox
	mov ax,1
	ret
@@1: 
	mov ax,fullscreen
	or  ax,ax
	jz @@2
	mov ecx,size dmScreenSettings
	lea edi,dmScreenSettings
	xor ax,ax
    rep stosb
	mov ax,size dmScreenSettings
	mov [dmScreenSettings.dmSize],ax
	mov ebx,width
	mov [dmScreenSettings.dmPelsWidth],ebx
	mov ecx,height
	mov [dmScreenSettings.dmPelsHeight],ecx
	mov eax,bits
	mov [dmScreenSettings.dmBitsPerPel],eax
	mov [dmScreenSettings.dmFields],DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
	push L CDS_FULLSCREEN
	push offset dmScreenSettings
	call ChangeDisplaySettings
	or ax,ax
	jz @@2	
	push L MB_YESNO or MB_ICONEXCLAMATION
	push offset NGL
	push offset FSNS
	push L 0
	call MessageBox
	cmp ax,IDYES
	jne @@3
	xor ax,ax
	mov fullscreen,ax
	jmp @@2
@@3:
	push L MB_OK or MB_ICONSTOP
	push offset ER
	push offset PWC
	push L 0
	call MessageBox
	mov ax,1
	ret
@@2:
	mov ax,fullscreen
	or ax,ax
	jz  @@4
	push L 0 
	call ShowCursor
	mov eax,WS_EX_APPWINDOW
	mov ebx,WS_POPUP
	jmp @@5
@@4:
	mov eax,WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
	mov ebx,WS_OVERLAPPEDWINDOW
@@5:
	or ebx, WS_CLIPSIBLINGS or WS_CLIPCHILDREN
	push L 0
	push [hInstance]
	push L 0
	push L 0
	push height
	push width
	push L 0
	push L 0
	push ebx	
	push wTitle
	push offset ClassName
	push eax
	call CreateWindowEx
	or eax,eax
	jnz @@6
	call KillGLWindow
	push MB_OK or MB_ICONEXCLAMATION
	push offset ER
	push offset WCE
	push L 0
	call MessageBox
	mov ax, -1
	ret
@@6:
	mov [hWnd],eax
	mov ebx, size PIXELFORMATDESCRIPTOR
	mov ecx,ebx
	xor ax,ax
	mov edi,offset pfd
    rep stosb
	mov [pfd.nSize],bx
	mov [pfd.nVersion],1
	mov [pfd.dwFlags],PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
	mov [pfd.iPixelType],PFD_TYPE_RGBA
	mov eax,bits
	mov [pfd.cColorBits],al
	mov [pfd.cDepthBits],16
	mov [pfd.iLayerType],PFD_MAIN_PLANE
	push hWnd
	call GetDC
	or eax,eax
	jnz @@7
	call KillGLWindow
	push MB_OK or MB_ICONEXCLAMATION
	push offset ER
	push offset CGLC
	push L 0
	call MessageBox
	mov ax,-1
	ret
@@7:
	mov hDC,eax
	push offset pfd
	push eax
	call ChoosePixelFormat
	or eax,eax
	jnz @@8
	push MB_OK or MB_ICONEXCLAMATION
	push offset ER
	push offset CFPF
	push L 0
	call MessageBox
	mov ax,-1
	ret
@@8:
	mov PixelFormat,eax
	push offset pfd
	push eax
	push [hDC]
	call SetPixelFormat
	or eax,eax
	jnz @@9
	call KillGLWindow
	push MB_ICONEXCLAMATION or MB_OK
	push offset ER
	push offset CSPF
	push L 0
	call MessageBox
	mov ax,-1
	ret
@@9:
	push [hDC]
	call wglCreateContext
	or eax,eax
	jnz @@10
	call KillGLWindow
	push MB_OK or MB_ICONEXCLAMATION
	push offset ER
	push offset CCRC
	push L 0
	call MessageBox
	mov ax,-1
	ret
@@10:
	mov hRC,eax
	push eax
	push [hDC]
	call wglMakeCurrent
	or eax,eax
	jnz @@11
	call KillGLWindow
	push MB_ICONEXCLAMATION or MB_OK
	push offset ER
	push offset CARC
	push L 0
	call MessageBox
	mov eax,-1
	ret
@@11:
	
	push L SW_SHOW
	push [hWnd]
	call ShowWindow
	push [hWnd]
	call SetForegroundWindow
	push [hWnd]
	call SetFocus
	
	call ReSizeGLScene	


	call InitGL
	or eax,eax
	jz @@12

	call KillGLWindow
	push MB_ICONEXCLAMATION or MB_OK
	push offset ER
	push offset INF
	push L 0
	call MessageBox
	mov eax,-1
	ret
@@12:
	xor eax,eax
	ret
CreateGLWindow endp
WndProc proc uses ebx edi esi, hwnd : DWORD, wmsg : DWORD, wparam: DWORD, lparam:DWORD
	mov eax,[wmsg]
	cmp eax,WM_ACTIVATE
	je _wmactivate
	cmp eax,WM_SYSCOMMAND
	je _wmsyscommand
	cmp eax,WM_CLOSE
	je _wmclose
	cmp eax,WM_KEYDOWN
	je _wmkeydown
	cmp eax,WM_KEYUP
	je _wmkeyup
	cmp eax,WM_SIZE
	je _wmsize
@@3:
	push lparam
	push wparam
	push wmsg
	push hwnd
	call DefWindowProc
	ret
_wmactivate:	
	mov eax,[wparam]
	or ah,ah
	jz @@1
	mov ah,0
	mov active,ah
	xor eax,eax
	ret
@@1:
	mov ah,1
	mov active,ah
	xor eax,eax
	ret	
_wmsyscommand:
	mov ebx,wparam
	cmp ebx,SC_SCREENSAVE
	je @@2
	cmp ebx,SC_MONITORPOWER
	je @@2
	jmp @@3
@@2:	
	xor eax,eax
	ret 
_wmclose:
	push L 0
	call PostQuitMessage
	xor eax,eax
	ret
_wmkeydown:
	mov ebx,wparam
	mov byte ptr [keys+ebx],1
	xor eax,eax
	ret
_wmkeyup:
	mov ebx,wparam
	mov byte ptr [keys+ebx],0
	xor eax,eax
	ret
_wmsize:
	mov eax,lparam
	mov ebx,eax
	and eax,0ffffh
	shr ebx,16
	mov [width],eax
	mov [height],ebx
	call ReSizeGLScene
	xor eax,eax
	ret
WndProc endp
start:
	xor eax,eax
	mov [fullscreen],ax
	inc ax
	mov [active],al
	mov [done],al
	push MB_YESNO or MB_ICONQUESTION
	push offset SFS
	push offset RIF
	push L 0
	call MessageBox
	cmp eax,IDNO
	je @@1
	mov eax,1
	mov [fullscreen],ax
@@1:
	mov ax,[fullscreen]
	mov [fullscreenflag],eax
	mov eax,16
	mov bits,eax
	mov eax,480
	mov height,eax
	mov eax,640
	mov width,640
	lea eax,WT
	mov wTitle,eax
	call CreateGLWindow
	or eax,eax
	jz @@2a
	ret
@@2a:
@@2:
	mov al,done
	or al,al
	jz @@3
	push PM_REMOVE
	push L 0
	push L 0
	push L 0
	push offset msg
	call PeekMessage
	or eax,eax
	jz @@4			
	mov eax,[msg.msMESSAGE]
	cmp eax,WM_QUIT
	jne @@5
@@7:
	mov al,0
	mov done,al
	jmp @@2
@@5:	
	push offset msg
	call TranslateMessage
	push offset msg
	call DispatchMessage
	jmp @@2
@@4:
	mov al,[keys+27]
	or al,al
	jnz @@7
	mov al,active
	or al,al
	jz @@6
	call DrawGLScene
	or al,al
	jnz @@7 
@@6:
	push hDC
	call SwapBuffers
	jmp @@2
@@3:
	call KillGLWindow
	ret
ends

public WndProc
end start
