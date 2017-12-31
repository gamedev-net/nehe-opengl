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
ReadALine       PROTO :DWORD,:DWORD
atodw           PROTO :DWORD
atof            PROTO :DWORD
KillGLWindow    PROTO
InitGL          PROTO
DrawGLScene     PROTO
LoadGLTexture   PROTO
SetupWorld      PROTO

VERTEX STRUCT
    x REAL4 ?
    y REAL4 ?
    z REAL4 ?
    u REAL4 ?
    v REAL4 ?
VERTEX ENDS

TRIANGLE STRUCT             ;just to know the size of TRIANGLE struct.
    vertex0 VERTEX <?>
    vertex1 VERTEX <?>
    vertex2 VERTEX <?>
TRIANGLE ENDS

include include.def             ;macros and constants definition
IDD_BITMAP      equ 100

.DATA
piover180       GLfloat 0.0174532925f
zero25          GLfloat 0.25f
zero02          GLfloat 0.02f
zero05          GLfloat 0.05f
vingt           GLfloat 20.0f
un              GLfloat 1.0f
trois6          GLfloat 360.0f
worldfile       db "world.txt",0
scalp           db "(scalp)",0
our_title       db "Moving in a 3D world, by (scalp)",0
ClassName       db "asmOpenGL",0
error_str       db "ERROR",0
not_found       db "The file 'world.txt' should be in the current directory",0
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
blend           db ?
bpressed        db ?
fpressed        db ?
filter          GLuint  ?
texture         GLuint  ?
texture1        GLuint  ?
texture2        GLuint  ?
heading         GLfloat ?
xpos            GLfloat ?
zpos            GLfloat ?
yrot            GLfloat ?
numtriangles    dd ?
pTriangle       dd ?
buffer          db 265 dup(?)
walkbias        GLfloat ?
walkbiasangle   GLfloat ?
lookupdown      GLfloat ?
z               GLfloat ?

.CODE
start:
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke WinMain, eax, 0, 0, 0
    invoke ExitProcess, eax

WinMain proc hInst:HWND, hPrevInst:UINT, CmdLine:WPARAM, CmdShow:LPARAM
  LOCAL msg:MSG, done:DWORD, temp:GLfloat
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
            .IF (keys['F'] && !fpressed)
                mov fpressed, 1
                inc filter
                .IF filter > 2
                    mov filter, 0
                .ENDIF
            .ENDIF
            .IF (!keys['F'])
                mov fpressed, 0
            .ENDIF
            .IF (keys['B'] && !bpressed)
                mov bpressed, 1
                .IF (blend)
                    mov blend, 0
                .ELSE
                    mov blend, 1
                .ENDIF
                .IF (!blend)
                    invoke glDisable, GL_BLEND
                    invoke glEnable, GL_DEPTH_TEST
                .ELSE
                    invoke glEnable, GL_BLEND
                    invoke glDisable, GL_DEPTH_TEST
                .ENDIF
            .ENDIF
            .IF (!keys['B'])
                mov bpressed, 0
            .ENDIF
            .IF (keys[VK_RIGHT])
                fld heading
                fsub un
                fst heading
                fstp yrot
            .ENDIF
            .IF (keys[VK_LEFT])
                fld heading
                fadd un
                fst heading
                fstp yrot
            .ENDIF
            .IF (keys[VK_PRIOR])
                fld z
                fsub zero02
                fstp z
                fld lookupdown
                fsub un
                fstp lookupdown
            .ENDIF
            .IF (keys[VK_NEXT])
                fld z
                fadd zero02
                fstp z
                fld lookupdown
                fadd un
                fstp lookupdown
            .ENDIF
            .IF (keys[VK_UP])
                fld heading
                fmul piover180
                fsin
                fmul zero05
                fchs
                fadd xpos
                fstp xpos

                fld heading
                fmul piover180
                fcos
                fmul zero05
                fchs
                fadd zpos
                fstp zpos

                .IF walkbiasangle >= 359
                    mov walkbiasangle, 0
                .ELSE
                    add walkbiasangle, 10
                .ENDIF
                fild walkbiasangle
                fmul piover180
                fsin
                fld vingt
                fdivp st(1), st(0)
                fstp walkbias
            .ENDIF
            .IF (keys[VK_DOWN])
                fld heading
                fmul piover180
                fsin
                fmul zero05
                fadd xpos
                fstp xpos

                fld heading
                fmul piover180
                fcos
                fmul zero05
                fadd zpos
                fstp zpos

                .IF walkbiasangle <= 1
                    mov walkbiasangle, 359
                .ELSE
                    sub walkbiasangle, 10
                .ENDIF
                fild walkbiasangle
                fmul piover180
                fsin
                fld vingt
                fdivp st(1), st(0)
                fstp walkbias
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
    invoke GlobalFree, pTriangle
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
    invoke LoadGLTexture
    cmp eax, 0
    je end_init
    invoke glEnable, GL_TEXTURE_2D
    invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE
    _glClearColor 0.0f,0.0f,0.0f,0.0f
    _glClearDepth 1.0f
    invoke glDepthFunc, GL_LESS
    invoke glEnable, GL_DEPTH_TEST
    invoke glShadeModel, GL_SMOOTH
    invoke glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST
    invoke SetupWorld
    cmp eax, 0
    je end_init
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
        inc h                                   ;prevent div by zero
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

DrawGLScene proc
  LOCAL x_m, y_m, z_m, u_m, v_m:GLfloat, count2:DWORD
  LOCAL xtrans:GLfloat, ytrans:GLfloat, ztrans:GLfloat
  LOCAL sceneroty:GLfloat, count:DWORD
    push esi
    invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke glLoadIdentity
    fld xpos
    fchs
    fstp xtrans
    fld walkbias
    fchs
    fsub zero25
    fstp ytrans
    fld zpos
    fchs
    fstp ztrans
    fld yrot
    fchs
    fadd trois6
    fstp sceneroty
    _glRotatef lookupdown,1.0f,0.0f,0.0f
    _glRotatef sceneroty,0.0f,1.0f,0.0f
    _glTranslatef xtrans,ytrans,ztrans
    mov eax, offset texture
    .IF filter == 1
        add eax, 4
    .ELSEIF filter == 2
        add eax, 8
    .ENDIF
    invoke glBindTexture, GL_TEXTURE_2D,DWORD PTR [eax]
    mov count, 0
    xor eax, eax
    mov esi, pTriangle
    .while eax < numtriangles
        push esi
        invoke glBegin, GL_TRIANGLES
        _glNormal3f 0.0f, 0.0f, 1.0f
        pop esi
        mov count2, 0
        .while count2 < 3
            fld GLfloat PTR [esi]
            fstp x_m
            add esi, sizeof GLfloat
            fld GLfloat PTR [esi]
            fstp y_m
            add esi, sizeof GLfloat
            fld GLfloat PTR [esi]
            fstp z_m
            add esi, sizeof GLfloat
            fld GLfloat PTR [esi]
            fstp u_m
            add esi, sizeof GLfloat
            fld GLfloat PTR [esi]
            fstp v_m
            add esi, sizeof GLfloat
            push esi
            _glTexCoord2f u_m, v_m
            _glVertex3f x_m, y_m,z_m
            pop esi
            inc count2
        .endw
        push esi
        invoke glEnd
        pop esi
        inc count
        mov eax, count
    .endw
    pop esi
    mov eax, 1
    ret
DrawGLScene endp

SetupWorld proc
  LOCAL FileHdl:DWORD, file_size:DWORD, pMemory:DWORD, count:DWORD
  LOCAL bytes_read:DWORD, pointer:DWORD, count2:DWORD, vert:DWORD
    push edi
    push esi
    invoke CreateFile, ADDR worldfile, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0
    .IF (eax == INVALID_HANDLE_VALUE)
        invoke MessageBox, 0, ADDR not_found, ADDR error_str, MB_OK or MB_ICONEXCLAMATION
        xor eax, eax
        pop esi
        pop edi
        ret
    .ENDIF
    mov FileHdl, eax
    invoke GetFileSize, eax, 0
    inc eax
    mov file_size, eax
    invoke GlobalAlloc, GPTR, file_size
    mov pMemory, eax
    dec file_size
    invoke ReadFile, FileHdl, pMemory, file_size, ADDR bytes_read, 0
    invoke CloseHandle, FileHdl
    push pMemory
    pop pointer
    xor eax, eax
    .while eax == 0
        invoke ReadALine, pointer, ADDR buffer
        add pointer, ecx
    .endw
    mov eax, offset buffer
    .IF (BYTE PTR [eax] == 'N')&&(BYTE PTR [eax+1] == 'U')&&(BYTE PTR [eax+2] == 'M')
        add eax, 11
    .ENDIF
    invoke atodw, eax
    mov numtriangles, eax
    mov ebx, sizeof TRIANGLE
    mul ebx
    invoke GlobalAlloc, GPTR, eax
    mov pTriangle, eax
    mov count, 0
    mov esi, eax
    xor eax, eax
    .while (eax < numtriangles)
        mov vert, 0
        .while (vert < 3)
            mov count2, 0
            xor eax, eax
            .while eax == 0
                invoke ReadALine, pointer, ADDR buffer
                add pointer, ecx
            .endw
            mov edi, offset buffer
            .while (count2 < 5)
                .while (BYTE PTR [edi] == ' ')
                    inc edi
                .endw
                invoke atof, edi
                fstp (GLfloat PTR [esi])
                add edi, eax
                add esi, sizeof GLfloat
                inc count2
            .endw
            inc vert
        .endw
        inc count
        mov eax, count
    .endw
    invoke GlobalFree, pMemory
    mov eax, 1
   end_setup:
    pop esi
    pop edi
    ret
SetupWorld endp

ReadALine proc pSource:DWORD, pDest:DWORD               ;eax = nb of significant bytes (0 = nothing)
  LOCAL cpy:BYTE                                        ;ecx = nb of bytes read (should be add to pointer)
    push esi
    push edi
    mov esi, 40000
    mov cpy, 1
    mov eax, pSource
    mov edx, pDest
    xor ecx, ecx
    .WHILE (BYTE PTR [eax+ecx] != 13)
        .IF (BYTE PTR [eax+ecx] == '/')
            mov cpy, 0
            .IF esi == 40000
                mov esi, ecx
            .ENDIF
        .ENDIF
        .IF (cpy)
            mov bl, BYTE PTR [eax+ecx]
            mov BYTE PTR [edx+ecx], bl
        .ENDIF
        inc ecx
    .ENDW
    mov BYTE PTR [edx+ecx], 0
    mov eax, ecx
    inc ecx
    inc ecx
    .IF esi == 0
        xor eax, eax
    .ENDIF
    pop edi
    pop esi
    ret
ReadALine endp

atodw proc ptrString:DWORD
  ;----------------------------------------
  ; Convert decimal string into dword value
  ; return value in eax
  ; by Tim Roberts (modified by me)
  ;----------------------------------------
    xor eax, eax
    mov esi, ptrString
    xor ecx, ecx
    xor edx, edx
    mov al, BYTE PTR [esi]
    inc esi
    .if al == '-'
        mov edx, -1
	  mov al, BYTE PTR [esi]
	  inc esi
    .endif
    .while al != 0
	  sub al, '0'	; convert to bcd
	  lea ecx, [ecx+ecx*4]	; ecx = ecx * 5
	  lea ecx, [eax+ecx*2]	; ecx = eax + old ecx * 10
	  mov al, BYTE PTR [esi]
	  inc esi
    .endw
    lea eax, [ecx+edx]	; move to eax and negate
    xor eax, edx
    ret
atodw endp

atof proc ptrString:DWORD
  ;----------------------------------------
  ;convert a string containing a float to
  ;a simple precision float number returned
  ;in st(0), number of bytes read + 1
  ;returned in eax, made by (scalp)
  ;----------------------------------------
  LOCAL sign:BYTE, entiere:DWORD, decimal:DWORD, precision:DWORD, temp:REAL4
    push esi
    push edi
    xor eax, eax
    mov esi, ptrString
    mov al, BYTE PTR [esi]
    cmp al, 0
    je fini0
    mov sign, 0
    .IF al == '+'
        inc esi
    .ELSEIF al == '-'
        mov sign, 1
        inc esi
    .ENDIF
    xor ecx, ecx
    mov al, BYTE PTR [esi]
    .while al != '.'
	  sub al, '0'
	  lea ecx, [ecx+ecx*4]
	  lea ecx, [eax+ecx*2]
	  inc esi
	  mov al, BYTE PTR [esi]
    .endw
    mov entiere, ecx
    xor ecx, ecx
    mov ebx, 1
    inc esi
    mov al, BYTE PTR [esi]
    .while ((al != ' ')&&(al != 0))
	  sub al, '0'
	  lea ecx, [ecx+ecx*4]
	  lea ecx, [eax+ecx*2]
	  inc esi
        imul ebx, 10
	  mov al, BYTE PTR [esi]
    .endw
    sub esi, ptrString
    mov eax, esi
    mov decimal, ecx
    mov precision, ebx
    fild decimal
    fild precision
    fdivp st(1), st(0)
    fstp temp
    fild entiere
    fadd temp
    .IF (sign == 1)
        fchs
    .ENDIF
    jmp fini
  fini0:
    xor eax, eax
  fini:
    pop edi
    pop esi
    ret
atof endp

END start
