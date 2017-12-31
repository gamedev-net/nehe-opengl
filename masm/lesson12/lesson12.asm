;i know i don't do so much comments... so for this
;tuts i tried to do some (not much). If you have
;any question, mail me ! (scalp@bigfoot.com).

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
KillGLWindow    PROTO
InitGL          PROTO
DrawGLScene     PROTO
LoadGLTexture   PROTO
BuildLists      PROTO

include include.def
IDD_BITMAP      equ 100

.DATA
scalp           db "(scalp)",0
our_title       db "Display List, converted in asm by (scalp)",0
ClassName       db "asmOpenGL",0
error_str       db "ERROR",0
not_full        db "The requested fullscreen mode is not supported by",13,10
                db "your video card. Use windowed mode instead ?",0
close           db "Program will now close",0
start_full      db "Would you like to run in fullscreen mode ?",0
boxcol          GLfloat 1.0f,0.0f,0.0f,1.0f,0.5f,0.0f,1.0f,1.0f,0.0f,0.0f,1.0f,0.0f,0.0f,1.0f,1.0f
topcol          GLfloat 0.5f,0.0f,0.0f,0.5f,0.25f,0.0f,0.5f,0.5f,0.0f,0.0f,0.5f,0.0f,0.0f,0.5f,0.5f
deux            GLfloat 2.0f
deux4           GLfloat 2.4f
deux8           GLfloat 2.8f
six             GLfloat 6.0f
sept            GLfloat 7.0f
moins20         REAL4 -20.0f
quarante5       GLfloat 45.0f
un              GLfloat 1.0f
un4             GLfloat 1.4f
zero2           GLfloat 0.2f

.data?
hDC             HDC ?
hRC             HGLRC ?
hInstance       HANDLE ?
keys            db 256 dup (?)
active          db ?
fullscreen      db ?
hWnd            dd ?
texture         GLuint  ?
box             GLuint  ?
top             GLuint  ?
xloop           GLuint  ?
yloop           GLuint  ?
xrot            GLfloat ?
yrot            GLfloat ?

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
            invoke DrawGLScene          ;here we do all the drawing
            .IF ((active) && (!eax)) || (keys[VK_ESCAPE])
                mov done, 1
            .ELSE
                invoke SwapBuffers, hDC
            .ENDIF
            .IF (keys[VK_F1])
                mov keys[VK_F1], 0      ;F1 pressed ?
                invoke KillGLWindow
                .IF (fullscreen)        ;fullscreen = not(fullscreen)
                    mov fullscreen, 0
                .ELSE
                    mov fullscreen, 1
                .ENDIF
                invoke CreateGLWindow, ADDR our_title, 640,480,16,fullscreen
                .IF (!eax)
                    ret
                .ENDIF
            .ENDIF
            .IF (keys[VK_LEFT])
                fld yrot
                fsub zero2
                fstp yrot
            .ENDIF
            .IF (keys[VK_RIGHT])
                fld yrot
                fadd zero2
                fstp yrot
            .ENDIF
            .IF (keys[VK_UP])
                fld xrot
                fsub zero2
                fstp xrot
            .ENDIF
            .IF (keys[VK_DOWN])
                fld xrot
                fadd zero2
                fstp xrot
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
    .ELSEIF uMsg == WM_SYSCOMMAND       ;to avoid scr from running
        .IF (wParam == SC_SCREENSAVE) || (wParam == SC_MONITORPOWER)
            xor eax, eax
            ret
        .ENDIF
    .ELSEIF uMsg == WM_KEYDOWN
        mov eax, wParam
        mov keys[eax], 1                ;update our key array
    .ELSEIF uMsg == WM_KEYUP
        mov eax, wParam
        mov keys[eax], 0                ;update our key array
    .ELSEIF uMsg == WM_SIZE
        mov eax, lParam
        mov ebx, eax
        and eax, 0ffffh                 ;eax=width=LOWORD
        shr ebx, 16                     ;ebx=height=HIWORD
        invoke ReSizeGLScene, eax, ebx  ;resize our window
    .ELSEIF uMsg == WM_CLOSE
        invoke PostQuitMessage, 0       ;quit...
        xor eax, eax
        ret
    .ENDIF
    invoke DefWindowProc, hWin, uMsg, wParam, lParam    ;gives other msg to windoze
    ret
WndProc endp

InitGL proc
  LOCAL loop_x:DWORD, loop_y:DWORD
    invoke LoadGLTexture                    ;load the bitmap
    cmp eax, 0                              ;works ?
    je end_init
    invoke BuildLists
    invoke glEnable, GL_TEXTURE_2D          ;enable texture mapping (the img is 2D)
    invoke glShadeModel, GL_SMOOTH          ;smooth shading
    _glClearColor 0.0f,0.0f,0.0f,0.5f       ;make a black backgroung
    _glClearDepth 1.0f
    invoke glEnable, GL_DEPTH_TEST          ;enable depth
    invoke glDepthFunc, GL_LEQUAL
    invoke glEnable, GL_LIGHT0              ;dirty lighting
    invoke glEnable, GL_LIGHTING            ;enable lighting
    invoke glEnable, GL_COLOR_MATERIAL      ;enable material coloring
    invoke glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST
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
    cmp eax, 0
    je end_create
    mov eax, 1
   end_create:
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
    _gluPerspective 45.0f, ratio, 0.1f,100.0f   ;calculate aspect ratio
    invoke glMatrixMode, GL_MODELVIEW           ;select modelview matrix
    invoke glLoadIdentity                       ;reset it
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
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, ImgInfo.bmWidth, ImgInfo.bmHeight,\
                         0, GL_BGR_EXT, GL_UNSIGNED_BYTE, ImgInfo.bmBits
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
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

DrawGLScene proc
  LOCAL temp1, temp2:GLfloat
    invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT          ;clear screen before drawing
    invoke glBindTexture, GL_TEXTURE_2D, texture
    mov yloop, 1
    .WHILE (yloop < 6)
        mov xloop, 0
        xor eax, eax
        .WHILE (eax < yloop)
            invoke glLoadIdentity
            fild yloop
            fmul un4
            fstp temp1
            fild xloop
            fmul deux8
            fadd un4
            fsub temp1
            fstp temp1          ;1.4f+(float(xloop)*2.8f)-(float(yloop)*1.4f)

            fld six
            fisub yloop
            fmul deux4
            fsub sept
            fstp temp2          ;((6.0f-float(yloop))*2.4f)-7.0f

            _glTranslatef temp1, temp2, moins20

            fild yloop
            fmul deux
            fchs
            fadd quarante5
            fadd xrot
            fstp temp1
            _glRotatef temp1, 1.0f, 0.0f, 0.0f
            fld yrot
            fadd quarante5
            fstp temp2
            _glRotatef temp2, 0.0f, 1.0f, 0.0f
            mov eax, yloop
            dec eax
            mov ebx, ((sizeof GLfloat)*3)
            mul ebx
            push eax
            add eax, offset boxcol
            invoke glColor3fv, eax
            invoke glCallList, box
            pop eax
            add eax, offset topcol
            invoke glColor3fv, eax
            invoke glCallList, top
            inc xloop
            mov eax, xloop
        .ENDW
        inc yloop
    .ENDW
    mov eax, 1
    ret
DrawGLScene endp

BuildLists PROC             ;build our cube display lists
    invoke glGenLists, 2    ;we want 2 lists
    mov box, eax            ;now box points to the first one
    invoke glNewList, box, GL_COMPILE   ;GL_COMPILE is important, see Nehe's tut for this
    invoke glBegin, GL_QUADS            ;start a new QUAD
    _glNormal3f 0.0f,-1.0f, 0.0f       ;bottom face
    _glTexCoord2f 1.0f, 1.0f
    _glVertex3f  -1.0f,-1.0f,-1.0f
    _glTexCoord2f 0.0f, 1.0f
    _glVertex3f   1.0f,-1.0f,-1.0f
    _glTexCoord2f 0.0f, 0.0f
    _glVertex3f   1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f, 0.0f
    _glVertex3f  -1.0f,-1.0f, 1.0f

    _glNormal3f 0.0f, 0.0f, 1.0f       ;front face
    _glTexCoord2f 0.0f, 0.0f
    _glVertex3f  -1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f, 0.0f
    _glVertex3f   1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f, 1.0f
    _glVertex3f   1.0f, 1.0f, 1.0f
    _glTexCoord2f 0.0f, 1.0f
    _glVertex3f  -1.0f, 1.0f, 1.0f

    _glNormal3f 0.0f, 0.0f,-1.0f       ;back face
    _glTexCoord2f 1.0f, 0.0f
    _glVertex3f  -1.0f,-1.0f,-1.0f
    _glTexCoord2f 1.0f, 1.0f
    _glVertex3f  -1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f, 1.0f
    _glVertex3f   1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f, 0.0f
    _glVertex3f   1.0f,-1.0f,-1.0f

    _glNormal3f 1.0f, 0.0f, 0.0f       ;right face
    _glTexCoord2f 1.0f, 0.0f
    _glVertex3f   1.0f,-1.0f,-1.0f
    _glTexCoord2f 1.0f, 1.0f
    _glVertex3f   1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f, 1.0f
    _glVertex3f   1.0f, 1.0f, 1.0f
    _glTexCoord2f 0.0f, 0.0f
    _glVertex3f   1.0f,-1.0f, 1.0f

    _glNormal3f -1.0f, 0.0f, 0.0f       ;left face
    _glTexCoord2f 0.0f, 0.0f
    _glVertex3f  -1.0f,-1.0f,-1.0f
    _glTexCoord2f 1.0f, 0.0f
    _glVertex3f  -1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f, 1.0f
    _glVertex3f  -1.0f, 1.0f, 1.0f
    _glTexCoord2f 0.0f, 1.0f
    _glVertex3f  -1.0f, 1.0f,-1.0f

    invoke glEnd
    invoke glEndList   ;it's ok for this list
    mov eax, box
    inc eax
    mov top, eax        ;storage for the top
    invoke glNewList, top, GL_COMPILE
    invoke glBegin, GL_QUADS
    _glNormal3f  0.0f, 1.0f, 0.0f
    _glTexCoord2f  0.0f, 1.0f
    _glVertex3f   -1.0f, 1.0f,-1.0f
    _glTexCoord2f  0.0f, 0.0f
    _glVertex3f   -1.0f, 1.0f, 1.0f
    _glTexCoord2f  1.0f, 0.0f
    _glVertex3f    1.0f, 1.0f, 1.0f
    _glTexCoord2f  1.0f, 1.0f
    _glVertex3f    1.0f, 1.0f,-1.0f
    invoke glEnd
    invoke glEndList
    ret
BuildLists ENDP

END start
