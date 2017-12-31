; Attempt at NeHe's tutorial 17 : Font display lists.
;
; Author: Greg Helps [x86@ozducati.com]
; Date: July 30 2003
;
; With thanks to NeHe for the OpenGL tutorials <http://nehe.gamedev.net/>
; Inspiration for x86 Assembler from Nico <scalp@bigfoot.com>
; OpenGL x86 includes originally from hardcode <http://bizarrecreations.webjump.com>
; although the site is now offline.
; I've included the OpenGL includes needed to compile this program.
;
; Bugs are mine.
;
; I'm a beginner. If you've any comments / suggestions / questions - bring em on
;
; Please note: Assembled with MASM32V8 and windows.inc (Version 1.26e)
; Both available from <http://www.masmforum.com>
; 
.586
.model flat, stdcall
option casemap:none

; INCLUDES * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\masm32.inc
include .\gl.def
include .\glu.def
include .\winextra.def

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\opengl32.lib
includelib c:\masm32\lib\glu32.lib
includelib c:\masm32\lib\masm32.lib


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
BuildFont		PROTO
KillFont		PROTO
glPrint			PROTO :GLint, :GLint, :DWORD, :UINT
DrawGLScene 	PROTO
LoadGLTextures	PROTO 


; STRUCTURES * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
; Define BMP structure
; I use this to reference width/height & data section from BMP files
BMPFILE STRUCT
	header BITMAPFILEHEADER <>
	info BITMAPINFOHEADER <>
	data DWORD ?
BMPFILE ENDS


; INITIALISED DATA * * * * * * * * * * * * * * * * * * * * * * * * * * 
.data
gld_10_0						GLdouble	10.0f
r4_0_0							REAL4	0.0f
r4_0_01							REAL4	0.01f
r4_0_02							REAL4	0.02f
r4_0_0625						REAL4	0.0625f
r4_16_0							REAL4	16.0f
r4_1_0							REAL4	1.0f
r4_0_0081						REAL4	0.0081f
r4_235_0						REAL4	235.0f
r4_280_0						REAL4	280.0f
r4_30_0							REAL4	30.0f
r4_200_0						REAL4	200.0f
r4_250_0						REAL4	250.0f
r4_0_5							REAL4	0.5f
r4_230_0						REAL4	230.0f
r4_240_0						REAL4	240.0f
r4_m0_5							REAL4	-0.5f
r4_5_0							REAL4	2.0f
;
txt_Query_Fullscn				db		"Do you want to run in fullscreen?",0
txt_Title_Fullscn				db		"Graphics mode",0
txt_Window_Title				db		"NeHe's Font Display List Tutorial",0
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
txt_NeHe						db		"NeHe",0
txt_Giueseppe					db		"Giuseppe D'Agata",0
;
txt_Font_BMP					db		"Font.BMP",0
txt_Bumps_BMP					db		"Bumps.BMP",0


; UNINITIALISED DATA * * * * * * * * * * * * * * * * * * * * * * * * * 
.data?
hRC				HGLRC     	?	;
hDC           	HDC       	?	; Open GL window structures
hWnd          	HWND      	?	;
hInstance     	HINSTANCE	?	;
;
keys          	db 256 dup (?)	; keypress status
fullscreen    	BOOL		?	; fullscreen toggle
active        	BOOL     	?	; window active toggle/status
;
texture			GLuint 		2 dup (?)	; GL Texture handle x 2
BMPTexture		DWORD		2 dup (?)	; Texture pointer x 2
;
base			GLuint		?	; Base display list for the font
cnt1			GLfloat		?	; 1st temp used to move text & for colouring
cnt2			GLfloat		?	; you guessed it.. second temp


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
	
	invoke LoadGLTextures	; Load textures
	.IF (eax == NULL)		; Exit if the textures failed to load
		ret
	.ENDIF
	
	invoke BuildFont		; Build the font
	
	_glClearColor 0.0f, 0.0f, 0.0f, 0.0f						; Clear the background colour to black
	_glClearDepth 1.0f											; Depth buffer setup
	invoke glDepthFunc, GL_LEQUAL								; Set type of depth test
	invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE					; Select the type of blending
	invoke glShadeModel,GL_SMOOTH								; Enable smooth shading
	invoke glEnable, GL_TEXTURE_2D								; Enable texture mapping

	mov eax, 1  		
  	ret
InitGL endp


; PROC BuildFont * * * * * * * * * * * * * * * * * * * * * * * * * * *
BuildFont proc
	LOCAL charx:GLfloat, chary:GLfloat, temp:UINT, counter:UINT
	
	invoke glGenLists, 256		; Create 256 display lists
	mov base, eax
	
	invoke glBindTexture, GL_TEXTURE_2D, [texture]	; Select the font texture
	
	mov counter, 0

	.WHILE (counter < 256)
		mov eax, counter	; charx = (temp2 mod 16)/16		chary = 1 - int(temp2/16)/16 
		xor edx, edx
		mov ebx, 16
		div ebx
		
		mov temp, eax
		fild temp
		fdiv r4_16_0
		fsubr r4_1_0
		fstp chary
		
		mov temp, edx
		fild temp
		fdiv r4_16_0
		fstp charx
		
		mov eax, [counter]
		add eax, base
		invoke glNewList, eax, GL_COMPILE		; Start building a list
			
			invoke glBegin, GL_QUADS	; Use a quad for each character
				
				fld chary	; Texture coord, bottom left
				fsub r4_0_0625
				fstp chary
				invoke glTexCoord2f, charx, chary
				invoke glVertex2i, 0, 0
				
				fld charx	; Texture coord, bottom right
				fadd r4_0_0625
				fstp charx
				invoke glTexCoord2f, charx, chary
				invoke glVertex2i, 16, 0
				
				fld chary	; Texture coord, top right
				fadd r4_0_0625
				fstp chary
				invoke glTexCoord2f, charx, chary
				invoke glVertex2i, 16, 16
				
				fld charx	; Texture coord, top left
				fsub r4_0_0625
				fstp charx
				invoke glTexCoord2f, charx, chary
				invoke glVertex2i, 0, 16
			
			invoke glEnd	; Done building the quad
			
			invoke glTranslated, (DWORD PTR [gld_10_0]),(DWORD PTR [gld_10_0+4]), \
				(DWORD PTR [r4_0_0]),(DWORD PTR [r4_0_0]),  (DWORD PTR [r4_0_0]),(DWORD PTR [r4_0_0])
		
		invoke glEndList	; Done building the display list
		
		inc counter
	.ENDW
	ret
BuildFont endp


; PROC KillFont * * * * * * * * * * * * * * * * * * * * * * * * * * *
KillFont proc
	invoke glDeleteLists, base, 256
	ret
KillFont endp


; PROC glPrint * * * * * * * * * * * * * * * * * * * * * * * * * * * *
glPrint proc x:GLint, y:GLint, string:DWORD, set:UINT
	LOCAL gld_x:GLdouble, gld_y:GLdouble

	fild x		; Convert the GLuint's to GLdoubles for use with glTranslated
	fstp gld_x
	fild y		; Convert the GLuint's to GLdoubles for use with glTranslated
	fstp gld_y
	
	.IF (set > 1)
		mov set, 1
	.ENDIF

	invoke glBindTexture, GL_TEXTURE_2D, texture			; Select the font texture	
	invoke glDisable, GL_DEPTH_TEST							; Disable depth testing
	invoke glMatrixMode, GL_PROJECTION						; Select projection matrix
	invoke glPushMatrix										; Store the projection matrix
	invoke glLoadIdentity									; Reset projection matrix
	_glOrtho 0.0f, 640.0f, 0.0f, 480.0f, -1.0f, 1.0f		; Set up an Ortho screen
	invoke glMatrixMode, GL_MODELVIEW						; Select modelview matrix
	invoke glPushMatrix										; Store the modelview matrix
	invoke glLoadIdentity									; Reset the modelview matrix
	
	invoke glTranslated, (DWORD PTR [gld_x]),(DWORD PTR [gld_x+4]),   (DWORD PTR [gld_y]),(DWORD PTR [gld_y+4]), \
		(DWORD PTR [r4_0_0]),(DWORD PTR [r4_0_0])
		
	mov eax, 128											; Choose the font set
	mul set													; eax= (128*set)+base-32
	add eax, base
	sub eax, 32
	invoke glListBase, eax
		
	invoke StrLen, string
	invoke glCallLists, eax, GL_BYTE, string				; Write the text to the screen
	
	invoke glMatrixMode, GL_PROJECTION						; Select projection matrix
	invoke glPopMatrix										; Restore the old matrix
	invoke glMatrixMode, GL_MODELVIEW						; Select modelview matrix
	invoke glPopMatrix										; Restore the old matrix
	invoke glEnable, GL_DEPTH_TEST							; Enable depth testing
	
	ret
glPrint endp


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
	
	invoke KillFont
	
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


; PROC LoadBMP * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
; This procedure only works with 24-bit BMP files.
; But it is small and avoids the use of glaux.
; A check should probably be added here to make sure we're dealing with a 24bit BMP
LoadBMP proc FileName:DWORD
	LOCAL FileHandle:DWORD, FileSize:DWORD, BytesRead:DWORD, BMP:DWORD, ImageSize:DWORD

	; Open the file
	invoke CreateFile, FileName, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0
 	mov FileHandle, eax
 		
 	.IF eax==INVALID_HANDLE_VALUE	; get outta here if we failed to open the file
 		xor eax, eax
 		ret
 	.ENDIF
 		
 	; Determine size of the file
 	invoke GetFileSize, FileHandle, 0
 	mov FileSize, eax
 	
 	; Allocate space in memory for the file.
 	invoke GlobalAlloc, GPTR, FileSize
 	mov BMP, eax ; BMP = pointer to allocated space
 	
 	; Read the file into memory
 	invoke ReadFile, FileHandle, BMP, FileSize, addr BytesRead, 0
 	invoke CloseHandle, FileHandle
 	mov eax, BytesRead
 	.IF (eax != FileSize)	; Free memory & exit if the readfile failed
 		invoke GlobalFree, BMP
 		xor eax, eax
 		ret
 	.ENDIF
	
	; BMP file has the colours as BGR instead of RGB. Swap the R & B colours.
	mov ebx, BMP	; Pointer to start of BMPFILE structure 
	mov eax, (BMPFILE PTR [ebx]).info.biWidth	; eax = BMPwidth * BMPheight
	mul (BMPFILE PTR [ebx]).info.biHeight
	lea ebx, (BMPFILE PTR [ebx]).data			; ebx = address of BMP data, ie: past the BMP header
	
	mov ecx, eax		; Loop thru BMP data, swapping R & G colours
@@:	mov al, [ebx]		; al = Red value
	xchg al, [ebx+2]	; Swap Green value with al, and al value with Green
	mov [ebx], al		; Write back Green value
	add ebx, 3			; Move to next block
	loop @B
	
	; Return a handle to the BMP
	mov eax, BMP
	ret
LoadBMP endp


; PROC LoadGLTextures * * * * * * * * * * * * * * * * * * * * * * * * 
LoadGLTextures proc

	; Load the first texture, "Font.bmp"
	invoke LoadBMP, addr txt_Font_BMP
	mov BMPTexture, eax
	.IF (eax == NULL)	; Quit if file load failed
		ret
	.ENDIF
	
	; Load the second texture, "Bumps.bmp"
	invoke LoadBMP, addr txt_Bumps_BMP
	mov [BMPTexture+4], eax
	.IF (eax == NULL)	; Quit if file load failed
		ret
	.ENDIF

    invoke glGenTextures, 2, addr texture	; Create two textures handles
	
	; Build "Font" texture
    invoke glBindTexture, GL_TEXTURE_2D, texture[0]
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    mov eax, BMPTexture
	lea ebx, (BMPFILE PTR [eax]).data
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, (BMPFILE PTR [eax]).info.biWidth, (BMPFILE PTR [eax]).info.biHeight,\
		0, GL_RGB, GL_UNSIGNED_BYTE, ebx
    
    ; Build "Bumps" texture
    invoke glBindTexture, GL_TEXTURE_2D, texture[1]
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    mov eax, [BMPTexture+4]
	lea ebx, (BMPFILE PTR [eax]).data
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, (BMPFILE PTR [eax]).info.biWidth, (BMPFILE PTR [eax]).info.biHeight,\
		0, GL_RGB, GL_UNSIGNED_BYTE, ebx

	; Remember to free the memory for the BMPFILE allocated in LoadBMP
	; I assume that if we don't need to free it, then the load failed & I set exit flag accordingly.
	.IF (BMPTexture != NULL)	; 
		invoke GlobalFree, BMPTexture
		.IF ([BMPTexture+4] != NULL)
			invoke GlobalFree, [BMPTexture+4]
			mov eax, 1
		.ENDIF
	.ELSE
		xor eax, eax
	.ENDIF

    ret
LoadGLTextures endp 


; PROC ReSizeGLScene * * * * * * * * * * * * * * * * * * * * * * * * * 
ReSizeGLScene proc widthx:DWORD, heighty:DWORD
	LOCAL ratio:GLdouble
  
  	.IF heighty == 0
    	mov heighty, 1 ; prevent div by zero
  	.ENDIF
	invoke glViewport, 0, 0, widthx, heighty
  	invoke glMatrixMode, GL_PROJECTION
  	invoke glLoadIdentity  
		
  	fild widthx
  	fild heighty
  	fdivp st(1),st(0)
  	fstp ratio
  	_gluPerspective 45.0f, ratio, 0.1f, 100.0f
  	invoke glMatrixMode, GL_MODELVIEW
  	invoke glLoadIdentity
  	ret
ReSizeGLScene endp


; PROC DrawGLScene * * * * * * * * * * * * * * * * * * * * * * * * * * 
DrawGLScene proc
	LOCAL red:GLfloat, green:GLfloat, blue:GLfloat	; Used for float calculations with colours
	LOCAL x:UINT, y:UINT	; co-ordinates for printing text

  	invoke glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
	invoke glLoadIdentity
	
	invoke glBindTexture, GL_TEXTURE_2D, [texture+1]					; Select second texture
	_glTranslatef 0.0f, 0.0f, -5.0f										; Move into screen 5 units
	_glRotatef 45.0f, 0.0f, 0.0f, 1.0f									; Rotate on Z axis 45 degrees clockwise
				
	fld r4_30_0
	fmul cnt1
	fstp red															; naughty. red is a bad variable name here.
	_glRotatef red, 1.0f, 1.0f, 0.0f									; Rotate on X&Y axis by cnt1.
	
	invoke glDisable, GL_BLEND											; Disable blending
	_glColor3f 1.0f, 1.0f, 1.0f											; Bright white
	invoke glBegin, GL_QUADS
	_glTexCoord2f 0.0f, 0.0f
	_glVertex2f -1.0f, 1.0f
	_glTexCoord2f 1.0f, 0.0f
	_glVertex2f 1.0f, 1.0f
	_glTexCoord2f 1.0f, 1.0f
	_glVertex2f 1.0f, -1.0f
	_glTexCoord2f 0.0f, 1.0f
	_glVertex2f -1.0f, -1.0f
	invoke glEnd
	
	_glRotatef 90.0f, 1.0f, 1.0f, 0.0f
	invoke glBegin, GL_QUADS
	_glTexCoord2f 0.0f, 0.0f
	_glVertex2f -1.0f, 1.0f
	_glTexCoord2f 1.0f, 0.0f
	_glVertex2f 1.0f, 1.0f
	_glTexCoord2f 1.0f, 1.0f
	_glVertex2f 1.0f, -1.0f
	_glTexCoord2f 0.0f, 1.0f
	_glVertex2f -1.0f, -1.0f
	invoke glEnd
	
	invoke glEnable, GL_BLEND
	invoke glLoadIdentity
	
	fld cnt1
	fcos
	fstp red
	fld cnt2
	fsin
	fstp green
	fld cnt1
	fadd cnt2
	fcos
	fmul r4_0_5
	fsubr r4_1_0
	fstp blue
	_glColor3f red, green, blue
	
	fld cnt1
	fcos
	fmul r4_250_0
	fadd r4_280_0
	fistp x
	
	fld cnt2
	fsin
	fmul r4_200_0
	fadd r4_235_0
	fistp y
	
	invoke glPrint, x, y, addr txt_NeHe, 0		; Print NeHe on the screen
	
	fld cnt2
	fsin
	fstp red	; Calc red for OpenGL

	fld cnt1
	fadd cnt2
	fcos
	fmul r4_m0_5
	fsubr r4_1_0
	fstp green	; Calc green for OpenGL
	
	fld cnt1
	fcos
	fstp blue	; Calc blue for OpenGl
	invoke glColor3f, red, green, blue

	fld cnt2
	fcos
	fmul r4_230_0
	fadd r4_280_0
	fistp x		; X Coord for OpenGL
	
	fld cnt1
	fsin
	fmul r4_200_0
	fadd r4_235_0
	fistp y		; Y Coord for OpenGL

	invoke glPrint, x, y, addr txt_OpenGL, 1	; Print OpenGL on the screen
	
	invoke glColor3f, r4_0_0, r4_0_0, r4_1_0	; Set the colour to a dark blue
	fld cnt1
	fadd cnt2
	fdiv r4_5_0
	fcos
	fmul r4_200_0
	fadd r4_240_0
	fistp x
	invoke glPrint, x, 2, addr txt_Giueseppe, 0
	
	invoke glColor3f, r4_1_0, r4_1_0, r4_1_0	; Set the colour to a dark blue
	add x, 2
	invoke glPrint, x, 2, addr txt_Giueseppe, 0
	
	fld cnt1	; Increase cnt1
	fadd r4_0_01
	fstp cnt1
	
	fld cnt2	; Increase cnt2
	fadd r4_0_0081
	fstp cnt2
	
    mov eax, 1
    ret
DrawGLScene endp

end start