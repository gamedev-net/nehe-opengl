.586p
.MODEL FLAT,STDCALL
option casemap:none
include \masm32\include\windows.inc
include \masm32\include\ogl\gl.def
include \masm32\include\ogl\glu.def
include \masm32\include\ogl\kernel32.inc
include \masm32\include\ogl\user32.inc
include \masm32\include\ogl\gdi32.inc
include \masm32\include\ogl\WinExtra\winextra.def
includelib \masm32\lib\opengl32.lib
includelib \masm32\lib\glu32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib

CreateGLWindow  PROTO :DWORD,:DWORD,:DWORD,:DWORD,:BYTE
WinMain         PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc         PROTO :DWORD,:DWORD,:DWORD,:DWORD
ReSizeGLScene   PROTO :DWORD,:DWORD
randlimit       PROTO :DWORD
randomize       PROTO
KillGLWindow    PROTO
InitGL          PROTO
DrawGLScene     PROTO
LoadGLTexture   PROTO

stars STRUCT
    r DWORD ?
    g DWORD ?
    b DWORD ?
    dist  GLfloat ?
    angle GLfloat ?
stars ENDS

include include.def             ;macro and constant definition
IDD_BITMAP      equ 100
num             equ 50
size_star       equ sizeof stars

.DATA
zoom            REAL4 -15.0f
tilt            GLfloat 90.0f
add_tilt        GLfloat 0.5f
add_spin        GLfloat 0.01
z_move          GLfloat 0.2f
fzero           GLfloat 0.0f
fcinq           GLfloat 5.0f
scalp           db "(scalp)",0
our_title       db "Moving bitmap in 3D space, (s)",0
ClassName       db "asmOpenGL",0
error_str       db "ERROR",0
not_full        db "The requested fullscreen mode is not supported by",13,10
                db "your video card. Use windowed mode instead ?",0
close           db "Program will now close",0
start_full      db "Would you like to run in fullscreen mode ?",0

.DATA?
hDC             HDC ?
hRC             HGLRC ?
hInstance       HANDLE ?
hWnd            dd ?
keys            db 256 dup (?)
active          db ?
fullscreen      db ?
twinkle         db ?
tp              db ?
texture         GLuint  ?
spin            GLfloat ?
star            stars num dup(<?>)
RandSeed        dd ?

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
        invoke PeekMessage, ADDR msg,0,0,0,PM_REMOVE
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
            .IF (keys['T'] && !tp)
                mov tp, 1
                .IF (twinkle)
                    mov twinkle, 0
                .ELSE
                    mov twinkle, 1
                .ENDIF
            .ENDIF
            .IF (!keys['T'])
                mov tp, 0
            .ENDIF
            .IF (keys[VK_UP])
                fld tilt
                fsub add_tilt
                fstp tilt
            .ENDIF
            .IF (keys[VK_DOWN])
                fld tilt
                fadd add_tilt
                fstp tilt
            .ENDIF
            .IF (keys[VK_PRIOR])
                fld zoom
                fsub z_move
                fstp zoom
            .ENDIF
            .IF (keys[VK_NEXT])
                fld zoom
                fadd z_move
                fstp zoom
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

InitGL proc
  LOCAL temp:DWORD
    invoke randomize
    invoke LoadGLTexture
    cmp eax, 0
    je end_init
    invoke glEnable, GL_TEXTURE_2D
    invoke glShadeModel, GL_SMOOTH
    _glClearColor 0.0f,0.0f,0.0f,0.5f
    _glClearDepth 1.0f
    invoke glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST
    invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE
    invoke glEnable, GL_BLEND
    xor ecx, ecx
    .while (ecx < num)
        fld fzero
        mov eax, ecx
        mov edx, size_star
        mul edx
        push eax
        fstp star[eax].angle                ;star[ecx*size_star]=0
        mov temp, ecx
        fild temp
        mov temp, num
        fild temp
        fdivp st(1), st(0)
        fmul fcinq
        pop edx
        fstp star[edx].dist                 ;star[ecx*size_star]=(ecx/num)*5
        invoke randlimit, 255
        mov star[edx].r, eax
        invoke randlimit, 255
        mov star[edx].g, eax
        invoke randlimit, 255
        mov star[edx].b, eax
        inc ecx
    .endw
    mov eax, 1
   end_init:
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
        xor eax, eax
        ret
    .ENDIF
    .IF (fullscreen)
        ZeroMemory &dmScreenSettings, sizeof(dmScreenSettings)
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
            invoke MessageBox, 0, ADDR not_full, ADDR scalp, MB_YESNO or MB_ICONEXCLAMATION
            .IF eax == IDYES
                mov fullscreen, 0
            .ELSE
                invoke MessageBox, 0, ADDR close, ADDR error_str, MB_OK or MB_ICONSTOP
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
    ZeroMemory &pfd, sizeof(PIXELFORMATDESCRIPTOR)
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
    invoke ChoosePixelFormat, hDC, ADDR pfd
    mov PixelFormat, eax
    invoke SetPixelFormat, hDC, PixelFormat, ADDR pfd
    invoke wglCreateContext, hDC
    mov hRC, eax
    invoke wglMakeCurrent, hDC, hRC
    invoke ShowWindow, hWnd, SW_SHOW
    invoke SetForegroundWindow, hWnd
    invoke SetFocus, hWnd
    invoke ReSizeGLScene, w, h
    invoke InitGL
    mov eax, 1
    ret
CreateGLWindow endp

ReSizeGLScene proc w:DWORD, h:DWORD             ;resize scene
  LOCAL ratio:GLdouble
    .IF h == 0
        mov h, 1                                ;prevent div by zero
    .ENDIF
    invoke glViewport, 0, 0, w, h               ;reset viewport
    invoke glMatrixMode, GL_PROJECTION          ;select projection matrix
    invoke glLoadIdentity                       ;reset it
    fild w
    fild h
    fdivp st(1), st(0)
    fstp ratio
    _gluPerspective 45.0f, ratio, 0.1f,100.0f
    invoke glMatrixMode, GL_MODELVIEW                   ;select modelview matrix
    invoke glLoadIdentity                               ;reset it
    ret
ReSizeGLScene endp

LoadGLTexture PROC
  LOCAL hBMP:DWORD, ImgInfo:BITMAP
    invoke glGenTextures, 1, ADDR texture
    invoke LoadImage, hInstance, IDD_BITMAP, IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION
    cmp eax, 0
    je end_load
    mov hBMP, eax
    invoke GetObject, hBMP, sizeof BITMAP, ADDR ImgInfo
    invoke glBindTexture, GL_TEXTURE_2D, texture
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, ImgInfo.bmWidth, ImgInfo.bmHeight,\
                         0, GL_BGR_EXT, GL_UNSIGNED_BYTE, ImgInfo.bmBits
    mov eax, 1
   end_load:
    ret
LoadGLTexture ENDP

KillGLWindow proc
    .IF (fullscreen)                                ;if fullscreen mode
        invoke ChangeDisplaySettings, 0, 0          ;get back to window
        invoke ShowCursor, 1                        ;and show mouse ptr
    .ENDIF
    .IF (hRC)
        invoke wglMakeCurrent, 0, 0
        invoke wglDeleteContext, hRC
        mov hRC, 0
    .ENDIF
    invoke ReleaseDC, hWnd, hDC
    invoke DestroyWindow, hWnd
    invoke UnregisterClass, ADDR ClassName, hInstance
    ret
KillGLWindow endp

randlimit proc limit:DWORD
  mov eax, limit
  push edx
  imul edx,RandSeed,08088405H
  inc edx
  mov RandSeed, edx
  mul edx
  mov eax, edx
  pop edx
  ret
randlimit endp

randomize proc
  invoke GetTickCount
  mov RandSeed, eax
  ret
randomize endp

DrawGLScene proc
  LOCAL temp:GLfloat, temp2:DWORD, count:DWORD
    invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke glBindTexture, GL_TEXTURE_2D, texture
    mov count, 0
    .while count<num
        invoke glLoadIdentity
        _glTranslatef 0.0f,0.0f,zoom
        _glRotatef tilt,1.0f,0.0f,0.0f
        mov eax, count
        mov edx, size_star
        mul edx
        push eax
        _glRotatef star[eax].angle, 0.0f,1.0f,0.0f
        pop eax
        push eax
        _glTranslatef star[eax].dist,0.0f,0.0f
        pop eax
        fld star[eax].angle
        fchs
        fstp temp
        _glRotatef temp,0.0f,1.0f,0.0f
        fld tilt
        fchs
        fstp temp
        _glRotatef temp,1.0f,0.0f,0.0f
        .if (twinkle)
            mov eax, num
            sub eax, count
            dec eax
            mov ecx, size_star
            mul ecx
            invoke glColor4ub, star[eax].r, star[eax].g, star[eax].b, 255
            invoke glBegin, GL_QUADS
               _glTexCoord2f 0.0f,0.0f
               _glVertex3f -1.0f,-1.0f,0.0f
               _glTexCoord2f 1.0f,0.0f
               _glVertex3f 1.0f,-1.0f,0.0f
               _glTexCoord2f 1.0f,1.0f
               _glVertex3f 1.0f,1.0f,0.0f
               _glTexCoord2f 0.0f,1.0f
               _glVertex3f -1.0f,1.0f,0.0f
            invoke glEnd
        .endif
        _glRotatef spin,0.0f,0.0f,1.0f
        mov eax, count
        mov edx, size_star
        mul edx
        push eax
        invoke glColor4ub, star[eax].r, star[eax].g, star[eax].b, 255
        invoke glBegin, GL_QUADS
           _glTexCoord2f 0.0f,0.0f
           _glVertex3f -1.0f,-1.0f,0.0f
           _glTexCoord2f 1.0f,0.0f
           _glVertex3f 1.0f,-1.0f,0.0f
           _glTexCoord2f 1.0f,1.0f
           _glVertex3f 1.0f,1.0f,0.0f
           _glTexCoord2f 0.0f,1.0f
           _glVertex3f -1.0f,1.0f,0.0f
        invoke glEnd
        fld spin
        fadd add_spin
        fstp spin
        fild count
        mov temp2, num
        fild temp2
        fdivp st(1), st(0)
        fstp temp
        pop eax
        fld star[eax].angle
        fadd temp
        fstp star[eax].angle
        fld star[eax].dist
        fsub add_spin
        fstp star[eax].dist
        mov ebx, star[eax].dist
        .IF ebx<0
            fld star[eax].dist
            fadd fcinq
            fstp star[eax].dist
            mov edx, eax
            invoke randlimit, 256
            mov star[edx].r, eax
            invoke randlimit, 256
            mov star[edx].g, eax
            invoke randlimit, 256
            mov star[edx].b, eax
        .ENDIF
        inc count
    .endw
    mov eax, 1
    ret
DrawGLScene endp

END start
