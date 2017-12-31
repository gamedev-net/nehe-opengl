;written by (scalp), modified by Andras Kobor

.586p
.MODEL FLAT,STDCALL
option casemap:none
include	\masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \masm32\include\opengl32.inc
include \masm32\include\glu32.inc
include \masm32\include\masm32.inc
include \masm32\include\fpu.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\opengl32.lib
includelib \masm32\lib\glu32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\fpu.lib

PFD_MAIN_PLANE		equ	0
PFD_TYPE_COLORINDEX	equ	1
PFD_TYPE_RGBA		equ	0
PFD_DOUBLEBUFFER	equ	1
PFD_DRAW_TO_WINDOW	equ	4
PFD_SUPPORT_OPENGL	equ	020h
DM_BITSPERPEL           equ     00040000h
DM_PELSWIDTH            equ     00080000h
DM_PELSHEIGHT           equ     00100000h


CreateGLWindow  PROTO :DWORD,:DWORD,:DWORD,:DWORD,:BYTE
WinMain         PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc         PROTO :DWORD,:DWORD,:DWORD,:DWORD
ReSizeGLScene   PROTO :DWORD,:DWORD
KillGLWindow    PROTO
InitGL          PROTO
DrawGLScene     PROTO
glPrint         PROTO :DWORD


.DATA

our_title       db "Masm32 conversion of Nehe's tuts ",0
ClassName       db "asmOpenGL",0
error           db "ERROR",0
noDC_RC         db "Release of DC and RC failed.",0
RCrelease       db "Release rendering context failed.",0
DCrelease       db "Release device context failed.",0
hWndRelease     db "Could not release hWnd.",0
register_error  db "Failed to register the window class.",0
not_full        db "The requested fullscreen mode is not supported by",13,10
                db "your video card. Use windowed mode instead ?",0
create_device   db "Can't create a GL device context.",0
create_pixel    db "Can't find a suitable pixelformat.",0
close           db "Program will now close",0
create_error    db "Window creation error.",0
pixel_error     db "Can't set the pixelformat.",0
rend_error      db "Can't create a GL rendering context.",0
act_error       db "Can't activate the GL rendering context.",0
init_error      db "Initialization Failed.",0
start_full      db "Would you like to run in fullscreen mode ?",0
class_error     db "Could not unregister class.",0

Value1Dbl	dq	1.0
Value45Dbl	dq	45.0
Value01Dbl	dq	0.1
Value100Dbl	dq	100.0

base            dd      0
font            dd      0 
oldfont         dd      0 
fontfamily      db      "Courier New",0 
mytext          db      "Active OpenGL Text With NeHe - ",0
F00             dd      0.0
Fm10            dd     -1.0  
Fm05            dd     -0.5
F10             dd      1.0
F0051           dd      0.051
F0005           dd      0.005 
F005            dd      0.05
Fm045           dd     -0.45 
F035            dd      0.35 
cnt1            dd      0.0
cnt2            dd      0.0
cnt12           dd      0.0

.DATA?
hDC         HDC ?
hInstance   HANDLE ?
keys        db 256 dup (?)
active      db ?
fullscreen  db ?
hWnd        dd ?
hRC         dd ? 
buffer1     db 10 dup (?) 
buffer2     db 50 dup (?)
  

.CODE
start:
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke WinMain, eax, 0, 0, 0
    invoke ExitProcess, eax

WinMain proc hInst:HWND, hPrevInst:UINT, CmdLine:WPARAM, CmdShow:LPARAM
  LOCAL msg:MSG, done:DWORD
    invoke MessageBox, 0, ADDR start_full, ADDR our_title, MB_YESNO or MB_ICONQUESTION
    .IF eax == IDNO
        mov fullscreen, 0
    .ELSE
        mov fullscreen, 1
    .ENDIF
    invoke CreateGLWindow, ADDR our_title, 640, 480, 16, fullscreen
    .IF (!eax)
        ret
    .ENDIF
    mov done, 0
    .while (!done)
        invoke PeekMessage, ADDR msg,NULL,0,0,PM_REMOVE
        .IF (eax)
            .IF msg.message == WM_QUIT
                mov done, 1
            .ELSE
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
            .ENDIF
        .ELSE
            invoke DrawGLScene
            .IF ((active) && (!eax)) || (keys[VK_ESCAPE])
                mov done, 1
            .ELSE
                invoke SwapBuffers, hDC
            .ENDIF
            .IF (keys[VK_F1])
                mov keys[VK_F1], 0
                invoke KillGLWindow
                .IF (fullscreen)
                    mov fullscreen, 0
                .ELSE
                    mov fullscreen, 1
                .ENDIF
                invoke CreateGLWindow, ADDR our_title, 640,480,16,fullscreen
                .IF (!eax)
                    ret
                .ENDIF
            .ENDIF
        .ENDIF
    .endw
    invoke KillGLWindow
    mov eax, msg.wParam
    ret
WinMain endp

WndProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .IF uMsg == WM_ACTIVATE
        mov eax, wParam
        .IF (!ah)
            mov active, 1
        .ELSE
            mov active, 0
        .ENDIF
    .ELSEIF uMsg == WM_SYSCOMMAND
        .IF (wParam == SC_SCREENSAVE) || (wParam == SC_MONITORPOWER)
            xor eax, eax
            ret
        .ENDIF
    .ELSEIF uMsg == WM_KEYDOWN
        mov eax, wParam
        mov keys[eax], 1
    .ELSEIF uMsg == WM_KEYUP
        mov eax, wParam
        mov keys[eax], 0
    .ELSEIF uMsg == WM_SIZE
        mov eax, lParam
        mov ebx, eax
        and eax, 0ffffh         ;eax=width=LOWORD
        shr ebx, 16             ;ebx=height=HIWORD
        invoke ReSizeGLScene, eax, ebx
    .ELSEIF uMsg == WM_CLOSE
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .ENDIF
    invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret
WndProc endp

InitGL proc         ;opengl setup (like color, etc...)
    invoke glShadeModel, GL_SMOOTH              ;enable smooth shading
    invoke glClearDepth,DWORD PTR Value1Dbl,DWORD PTR Value1Dbl+4       ;depth buffer setup
    invoke glEnable, GL_DEPTH_TEST              ;enable depth testing
    invoke glDepthFunc, GL_LEQUAL               ;type of depth test
  ;set really nice perspective calculations
    invoke glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST
    invoke glGenLists, 96
    mov base, eax 
    invoke CreateFont, -24, 0, 0, 0, FW_BOLD, 0, 0, 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, FF_DONTCARE, addr fontfamily 
    mov font, eax
    invoke SelectObject, hDC, font
    mov oldfont, eax
    invoke wglUseFontBitmaps, hDC, 32, 96, base
    invoke SelectObject, hDC, oldfont
    invoke DeleteObject, font 
    mov eax, 1
    ret
InitGL endp

CreateGLWindow proc letitle:DWORD,w:DWORD,h:DWORD,bits:DWORD,flag:BYTE
  LOCAL PixelFormat:DWORD, wc:WNDCLASS
  LOCAL dwExStyle:DWORD, dwStyle:DWORD
  LOCAL rect:RECT, dmScreenSettings:DEVMODE
  LOCAL pfd:PIXELFORMATDESCRIPTOR
    mov rect.left, 0
    push w
    pop rect.right
    mov rect.top, 0
    push h
    pop rect.bottom
    mov al, flag
    mov fullscreen, al
    mov wc.style, CS_HREDRAW or CS_VREDRAW or CS_OWNDC
    mov wc.lpfnWndProc, offset WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    push hInstance
    pop wc.hInstance
    mov wc.hIcon, 0
    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, offset ClassName
    mov wc.hbrBackground, 0
    invoke RegisterClass, ADDR wc
    .IF (!eax)
        invoke MessageBox, 0, ADDR register_error, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    .IF (fullscreen)
        invoke RtlZeroMemory, ADDR dmScreenSettings, sizeof dmScreenSettings 
        mov dmScreenSettings.dmSize, sizeof dmScreenSettings
        push w
        pop dmScreenSettings.dmPelsWidth
        push h
        pop dmScreenSettings.dmPelsHeight
        push bits
        pop dmScreenSettings.dmBitsPerPel
        mov dmScreenSettings.dmFields, DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT
        invoke ChangeDisplaySettings, ADDR dmScreenSettings, CDS_FULLSCREEN
        .IF eax != DISP_CHANGE_SUCCESSFUL
            invoke MessageBox, 0, ADDR not_full, ADDR error, MB_YESNO or MB_ICONEXCLAMATION
            .IF eax == IDYES
                mov fullscreen, 0
            .ELSE
                invoke MessageBox, 0, ADDR close, ADDR error, MB_OK or MB_ICONSTOP
                xor eax, eax
                ret
            .ENDIF
        .ENDIF
    .ENDIF
    .IF (fullscreen)
        mov dwExStyle, WS_EX_APPWINDOW
        mov dwStyle, WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN
        invoke ShowCursor, 0
    .ELSE
        mov dwExStyle, WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
        mov dwStyle, WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN
    .ENDIF
    invoke AdjustWindowRectEx, ADDR rect, dwStyle, 0, dwExStyle
    mov eax, rect.left
    sub rect.right, eax
    mov eax, rect.top
    sub rect.bottom, eax
    invoke CreateWindowEx, dwExStyle, ADDR ClassName, ADDR our_title, \
                           dwStyle,0,0, rect.right, rect.bottom, 0, 0, hInstance, 0
    mov hWnd, eax
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR create_error, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    invoke RtlZeroMemory,  ADDR pfd, sizeof pfd  
    mov pfd.nSize, sizeof PIXELFORMATDESCRIPTOR
    mov pfd.nVersion, 1
    mov pfd.dwFlags, PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
    mov pfd.iPixelType, PFD_TYPE_RGBA
    mov eax, bits
    mov pfd.cColorBits, al
    mov pfd.cDepthBits, 16
    mov pfd.dwLayerMask, PFD_MAIN_PLANE
    invoke GetDC, hWnd
    mov hDC, eax
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR create_device, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    invoke ChoosePixelFormat, hDC, ADDR pfd
    mov PixelFormat, eax
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR create_pixel, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    invoke SetPixelFormat, hDC, PixelFormat, ADDR pfd
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR pixel_error, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    invoke wglCreateContext, hDC
    mov hRC, eax
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR rend_error, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    invoke wglMakeCurrent, hDC, hRC
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR act_error, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    invoke ShowWindow, hWnd, SW_SHOW
    invoke SetForegroundWindow, hWnd
    invoke SetFocus, hWnd
    invoke ReSizeGLScene, w, h
    invoke InitGL
    .IF (!eax)
        invoke KillGLWindow
        invoke MessageBox, 0, ADDR init_error, ADDR error, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        ret
    .ENDIF
    mov eax, 1
    ret
CreateGLWindow endp

DrawGLScene proc                                        ;drawing proc
 LOCAL c1:REAL4, c2:REAL4, c12:REAL4
 ;clear screen and depth buffer
    invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke glLoadIdentity                               ;reset modelview matrix
    invoke glTranslatef, F00, F00, Fm10
    fld cnt1
    fld cnt2
    fadd
    fcos
    fmul Fm05
    fadd F10
    fstp c12  
    fld cnt1
    fcos 
    fstp c1
    fld cnt2
    fsin 
    fstp c2
    invoke glColor3f, c1, c2, c12
    fld c1
    fmul F005
    fadd Fm045
    fstp c1
    fld c2
    fmul F035
    fstp c2
    invoke glRasterPos2f, c1, c2
    fld cnt1
    invoke FpuFLtoA, 0, 2, ADDR buffer1, SRC1_FPU or SRC2_DIMM 
    invoke RtlZeroMemory,  ADDR buffer2, 50   
    invoke szCatStr, addr buffer2, addr mytext
    invoke szCatStr, addr buffer2, addr buffer1
    invoke glPrint, addr buffer2 
    fld cnt1
    fadd  F0051
    fstp cnt1
    fld cnt2
    fadd  F0005
    fstp cnt2  
    mov eax, 1
    ret
DrawGLScene endp

ReSizeGLScene proc w:DWORD, h:DWORD             ;resize scene
  LOCAL ratio:QWORD
    .IF h == 0
        mov h, 1                                ;prevent div by zero
    .ENDIF
    invoke glViewport, 0, 0, w, h               ;reset viewport
    invoke glMatrixMode, GL_PROJECTION          ;select projection matrix
    invoke glLoadIdentity                       ;reset it
    fild w
    fild h
    fdivp st(1), st ;width/height
    fstp ratio
    invoke gluPerspective,DWORD PTR Value45Dbl,DWORD PTR Value45Dbl+4,DWORD PTR ratio,DWORD PTR ratio+4,DWORD PTR Value01Dbl,DWORD PTR Value01Dbl+4,DWORD PTR Value100Dbl,DWORD PTR Value100Dbl+4  
    invoke glMatrixMode, GL_MODELVIEW                   ;select modelview matrix
    invoke glLoadIdentity                               ;reset it
    ret
ReSizeGLScene endp

KillGLWindow proc
;here we do a lot of tests, but at least, you have to do
;wglMakeCurrent, wglDeleteContext and ReleaseDC.
    .IF (fullscreen)                                ;if fullscreen mode
        invoke ChangeDisplaySettings, 0, 0          ;get back to window
        invoke ShowCursor, 1                        ;and show mouse ptr
    .ENDIF
  ;do a lot of error checking before closing
    .IF (hRC)
        invoke wglMakeCurrent, 0, 0
        .IF (!eax)
            invoke MessageBox, 0, ADDR noDC_RC, ADDR error, MB_OK or MB_ICONINFORMATION
        .ENDIF
        invoke wglDeleteContext, hRC
        .IF (!eax)
            invoke MessageBox, 0, ADDR RCrelease, ADDR error, MB_OK or MB_ICONINFORMATION
        .ENDIF
        mov hRC, 0
    .ENDIF
    invoke ReleaseDC, hWnd, hDC
    .IF (hDC && (!eax))
        invoke MessageBox, 0, ADDR DCrelease, ADDR error, MB_OK or MB_ICONINFORMATION
        mov hDC, 0
    .ENDIF
    invoke DestroyWindow, hWnd
    .IF (hWnd && (!eax))
        invoke MessageBox, 0, ADDR hWndRelease, ADDR error, MB_OK or MB_ICONINFORMATION
        mov hWnd, 0
    .ENDIF
    invoke UnregisterClass, ADDR ClassName, hInstance
    .IF (!eax)
        invoke MessageBox, 0, ADDR class_error, ADDR error, MB_OK or MB_ICONINFORMATION
    .ENDIF
    invoke glDeleteLists, base, 96
    ret
KillGLWindow endp

glPrint proc thetext:DWORD 
    invoke glPushAttrib, GL_LIST_BIT 
    mov eax , base
    sub eax, 32
    invoke glListBase, eax
    invoke StrLen, thetext
    invoke glCallLists, eax, GL_UNSIGNED_BYTE, thetext
    invoke glPopAttrib
    ret
glPrint endp

END start
