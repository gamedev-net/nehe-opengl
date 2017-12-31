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

include include.def
IDD_BITMAP      equ 100

.DATA
x_speed         GLfloat 1.4
y_speed         GLfloat 1.4
z               REAL4 -5.0
z_move          GLfloat 0.02
add_speed       GLfloat 0.01
LightAmbient    GLfloat 0.5,0.5,0.5,1.0
LightDiffuse    GLfloat 1.0,1.0,1.0,1.0
LightPosition   GLfloat 0.0,0.0,2.0,1.0
scalp           db "(scalp)",0
our_title       db "Blending, (s)",0
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
keys            db 256 dup (?)
active          db ?
fullscreen      db ?
light           db ?
blend           db ?
fp              db ?
lp              db ?
bpressed        db ?
hWnd            dd ?
filter          dd ?
texture         GLuint ?        ;this 3 lines are the same as texture[3] in C
texture1        GLuint ?        ;I do it this way cause it is easyier to access
texture2        GLuint ?        ;texture1 and texture2
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
            invoke DrawGLScene
            .IF ((active) && (!eax)) || (keys[VK_ESCAPE])
                mov done, 1
            .ELSE
                invoke SwapBuffers, hDC
            .ENDIF
            .IF (keys['L'] && !lp)
                mov lp, 1
                .IF (light)
                    mov light, 0
                .ELSE
                    mov light, 1
                .ENDIF
                .IF (!light)
                    invoke glDisable, GL_LIGHTING
                .ELSE
                    invoke glEnable, GL_LIGHTING
                .ENDIF
            .ENDIF
            .IF (!keys['L'])
                mov lp, 0
            .ENDIF
            .IF (keys['F'] && !lp)
                mov fp, 1
                inc filter
                .IF filter > 2
                    mov filter, 0
                .ENDIF
            .ENDIF
            .IF (!keys['F'])
                mov fp, 0
            .ENDIF
            .IF (keys[VK_PRIOR])
                fld z
                fsub z_move
                fstp z
            .ENDIF
            .IF (keys[VK_NEXT])
                fld z
                fadd z_move
                fstp z
            .ENDIF
            .IF (keys[VK_UP])
                fld x_speed
                fsub add_speed
                fstp x_speed
            .ENDIF
            .IF (keys[VK_DOWN])
                fld x_speed
                fadd add_speed
                fstp x_speed
            .ENDIF
            .IF (keys[VK_RIGHT])
                fld y_speed
                fadd add_speed
                fstp y_speed
            .ENDIF
            .IF (keys[VK_LEFT])
                fld y_speed
                fsub add_speed
                fstp y_speed
            .ENDIF
            .IF (keys['B'] && !bpressed)
                mov bpressed, 1
                .IF (blend)
                    mov blend, 0
                .ELSE
                    mov blend, 1
                .ENDIF
                .IF (blend)
                    invoke glEnable, GL_BLEND
                    invoke glDisable, GL_DEPTH_TEST
                .ELSE
                    invoke glDisable, GL_BLEND
                    invoke glEnable, GL_DEPTH_TEST
                .ENDIF
            .ENDIF
            .IF (!keys['B'])
                mov bpressed, 0
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
    invoke LoadGLTexture
    cmp eax, 0
    je end_init
    invoke glEnable, GL_TEXTURE_2D
    invoke glShadeModel, GL_SMOOTH
    _glClearDepth 1.0f
    _glColor4f 1.0f,1.0f,1.0f,0.5f
    invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE
    invoke glEnable, GL_DEPTH_TEST
    invoke glDepthFunc, GL_LEQUAL
    invoke glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST
    invoke glLightfv, GL_LIGHT1, GL_AMBIENT, ADDR LightAmbient
    invoke glLightfv, GL_LIGHT1, GL_DIFFUSE, ADDR LightDiffuse
    invoke glLightfv, GL_LIGHT1, GL_POSITION, ADDR LightPosition
    invoke glEnable, GL_LIGHT1
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
    _gluPerspective 45.0f, ratio, 0.1f,100.0f
    invoke glMatrixMode, GL_MODELVIEW                   ;select modelview matrix
    invoke glLoadIdentity                               ;reset it
    ret
ReSizeGLScene endp

LoadGLTexture PROC
  LOCAL hBMP:DWORD, ImgInfo:BITMAP
    invoke glGenTextures, 3, ADDR texture
    invoke LoadImage, hInstance, IDD_BITMAP, IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION
    cmp eax, 0
    je end_load
    mov hBMP, eax
    invoke GetObject, hBMP, sizeof BITMAP, ADDR ImgInfo

    invoke glBindTexture, GL_TEXTURE_2D, texture
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, ImgInfo.bmWidth, ImgInfo.bmHeight,\
                         0, GL_BGR_EXT, GL_UNSIGNED_BYTE, ImgInfo.bmBits

    invoke glBindTexture, GL_TEXTURE_2D, texture1
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, ImgInfo.bmWidth, ImgInfo.bmHeight,\
                         0, GL_BGR_EXT, GL_UNSIGNED_BYTE, ImgInfo.bmBits

    invoke glBindTexture, GL_TEXTURE_2D, texture2
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_NEAREST
    invoke gluBuild2DMipmaps, GL_TEXTURE_2D, 3, ImgInfo.bmWidth, ImgInfo.bmHeight,\
                              GL_BGR_EXT, GL_UNSIGNED_BYTE, ImgInfo.bmBits

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

DrawGLScene proc                                        ;drawing proc
    invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke glLoadIdentity                               ;reset modelview matrix
    _glTranslatef 0.0f, 0.0f, z
    _glRotatef xrot, 1.0f,0.0f,0.0f
    _glRotatef yrot, 0.0f,1.0f,0.0f

    mov eax, offset texture
    .IF filter == 1
        add eax, 4
    .ELSEIF filter == 2
        add eax, 8
    .ENDIF
    invoke glBindTexture, GL_TEXTURE_2D, DWORD PTR [eax]

    invoke glBegin, GL_QUADS
  ;front
    _glNormal3f 0.0f,0.0f,1.0f
    _glTexCoord2f 0.0f,0.0f
    _glVertex3f -1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f,0.0f
    _glVertex3f  1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f,1.0f
    _glVertex3f  1.0f, 1.0f, 1.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f -1.0f, 1.0f, 1.0f
  ;back
    _glNormal3f 0.0f,0.0f,-1.0f
    _glTexCoord2f 1.0f,0.0f
    _glVertex3f -1.0f,-1.0f,-1.0f
    _glTexCoord2f 1.0f,1.0f
    _glVertex3f -1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f  1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f,0.0f
    _glVertex3f  1.0f,-1.0f,-1.0f
  ;top
    _glNormal3f 0.0f,1.0f,0.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f -1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f,0.0f
    _glVertex3f -1.0f, 1.0f, 1.0f
    _glTexCoord2f 1.0f,0.0f
    _glVertex3f  1.0f, 1.0f, 1.0f
    _glTexCoord2f 1.0f,1.0f
    _glVertex3f  1.0f, 1.0f,-1.0f
  ;bottom
    _glNormal3f 0.0f,-1.0f,0.0f
    _glTexCoord2f 1.0f,1.0f
    _glVertex3f -1.0f,-1.0f,-1.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f  1.0f,-1.0f,-1.0f
    _glTexCoord2f 0.0f,0.0f
    _glVertex3f  1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f,0.0f
    _glVertex3f -1.0f,-1.0f, 1.0f
  ;right
    _glNormal3f 1.0f,0.0f,0.0f
    _glTexCoord2f 1.0f,0.0f
    _glVertex3f  1.0f,-1.0f,-1.0f
    _glTexCoord2f 1.0f,1.0f
    _glVertex3f  1.0f, 1.0f,-1.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f  1.0f, 1.0f, 1.0f
    _glTexCoord2f 0.0f,0.0f
    _glVertex3f  1.0f,-1.0f, 1.0f
  ;left
    _glNormal3f -1.0f,0.0f,0.0f
    _glTexCoord2f 0.0f,0.0f
    _glVertex3f -1.0f,-1.0f,-1.0f
    _glTexCoord2f 1.0f,0.0f
    _glVertex3f -1.0f,-1.0f, 1.0f
    _glTexCoord2f 1.0f,1.0f
    _glVertex3f -1.0f, 1.0f, 1.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f -1.0f, 1.0f,-1.0f
    invoke glEnd
    fld xrot
    fadd x_speed
    fstp xrot
    fld yrot
    fadd y_speed
    fstp yrot
    mov eax, 1
    ret
DrawGLScene endp

END start
