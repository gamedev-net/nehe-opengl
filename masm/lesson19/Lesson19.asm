;-------------------------------------------------------------------------------------------;
; MASM32 conversion of Nehe's OpenGL tutorial 19 by Christophe Jeannin (Chrishka)           ;
;                                                                                           ;
; float and double parameters for GL functions are directly pushed as immediate.            ;
; I wrote a little program (Conv.exe) to know what value to push.                           ;
; doubles are pushed as 2 dwords, most significant dword first, then less significant one   ;
; but with stdcall arguments Right to Left you have to give invoke less significant dword   ;
; first, and then the most significant dword.                                               ;
;-------------------------------------------------------------------------------------------;


include Lesson19.inc

.data

    hWnd        dd          NULL
    hDc         dd          NULL
    hRc         dd          NULL
    zoom        REAL4       -40.0f

    active      db          1

    rainbow     db          1
	
    slowdown    REAL4       2.0f
	
    colors      REAL4       36 dup( 1.0f,0.5f,0.5f, 1.0f,0.75f,0.5f, 1.0f,1.0f,0.5f, 0.75f,1.0f,0.5f,
                                    0.5f,1.0f,0.5f, 0.5f,1.0f,0.75f, 0.5f,1.0f,1.0f, 0.5f,0.75f,1.0f,
                                    0.5f,0.5f,1.0f, 0.75f,0.5f,1.0f, 1.0f,0.5f,1.0f, 1.0f,0.5f,0.75f )

.data?

    hInst       dd          ?

    xspeed      REAL4       ?
    yspeed      REAL4       ?

    col         dd          ?
    delay       dd          ?

    texture     dd          ?

    nseed       dd          ?

    rp          db          ?
    space       db          ?

    fullscreen  db          ?

    keys        db          256 dup(?)
	
    particle    particles   MAX_PARTICLES dup(<>)

.const

    szClass     db          "NeHe's OpenGL",0

    szErr       db          "Error",0
    szTitle     db          "Lesson 19",0

    szErr1      db          "Failed to register the window class",0
    szErr2      db          "Requested fullscreen mode not supported",13,"Use windowed mode instead ?",0
    szErr3      db          "Window creation error",0
    szErr4      db          "Unable to get device context",0
    szErr5      db          "Can't find a suitable pixel format",0
    szErr6      db          "Unable to set the pixel format",0
    szErr7      db          "Unable to create a rendering context",0
    szErr8      db          "Unable to activate the rendering context",0
    szErr9      db          "Unable to initialize OpenGL",0
	
    szMsg1      db          "Would you like to run in fullscreen mode ?",0
	
    szTexture   db          "particle.bmp",0

.code

Start:
    invoke      GetModuleHandle,NULL
    mov         hInst,eax
    invoke      WinMain,eax,NULL,0
    invoke      ExitProcess,eax


LoadGLTexture PROC
  LOCAL info:BITMAP,hBmp:DWORD

    invoke  LoadImage,NULL,addr szTexture,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if eax
        mov     hBmp,eax
        invoke  glGenTextures,1,addr texture
        invoke  GetObject,hBmp,sizeof info,addr info

        invoke  glBindTexture,GL_TEXTURE_2D,texture
        invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
        invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR
        invoke  glTexImage2D,GL_TEXTURE_2D,0,3,info.bmWidth,info.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits

        invoke  DeleteObject,hBmp

        mov     eax,1
    .endif
    ret

LoadGLTexture ENDP

ResizeGLScene PROC w:DWORD,h:DWORD

    .if h == 0
        mov     h,1
    .endif
    invoke  glViewport,0,0,w,h
    invoke  glMatrixMode,GL_PROJECTION
    invoke  glLoadIdentity
    push    40690000h               ; 200.0
    push    0                       ; double
    push    3FB99999h               ; 0.1
    push    9999999Ah               ; double
    fild    w
    fidiv   h                       ; dividing w by h and
    sub     esp,8                   ; pushing it on the
    fstp    qword ptr [esp]         ; stack as a double
    push    40468000h               ; 45.0
    push    0                       ; double
    call    gluPerspective
    invoke  glMatrixMode,GL_MODELVIEW
    invoke  glLoadIdentity
    ret

ResizeGLScene ENDP

InitGL PROC
  LOCAL tmp:DWORD,colormul:REAL4

    invoke  LoadGLTexture
    .if !eax
        ret
    .endif

    invoke  glShadeModel,GL_SMOOTH
    invoke  glClearColor,0,0,0,0
    invoke  glClearDepth,0,3FF00000h        ;1.0 double
    invoke  glDisable,GL_DEPTH_TEST
    invoke  glEnable,GL_BLEND
    invoke  glBlendFunc,GL_SRC_ALPHA,GL_ONE
    invoke  glHint,GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST
    invoke  glHint,GL_POINT_SMOOTH_HINT,GL_NICEST
    invoke  glEnable,GL_TEXTURE_2D
    invoke  glBindTexture,GL_TEXTURE_2D,texture

    invoke  GetTickCount
    mov     nseed,eax
    xor     ebx,ebx
    xor     edi,edi

    .while ebx < MAX_PARTICLES
        mov     particle[edi].active,1
        mov     particle[edi].life,3F800000h

        invoke  nrandom,100
        mov     tmp,eax
        fild    tmp
        fdiv    fpc(1000.0f)
        fadd    fpc(0.003f)
        fstp    particle[edi].fade

        fld     fpc(12.0f)                  ; compute the color index
        mov     tmp,MAX_PARTICLES           ; ( loopcount*(12/MAX_PARTICLES) )
        fidiv   tmp                         ; with loopcount = ebx here
        fstp    colormul
        mov     tmp,ebx
        fild    tmp
        fmul    colormul
        fistp   tmp
        mov     ecx,tmp                     ; multiply the color index by 12 to point to the
        mov     eax,tmp                     ; right color, because each color is made of 3
        shl     ecx,3                       ; floats (r,g,b), and floats are 4 bytes so 3*4 = 12.
        shl     eax,2                       ; I'm using left shifts to multiply
        add     eax,ecx
        mov     ecx,colors[eax]
        mov     particle[edi].r,ecx
        mov     ecx,colors[eax+4]
        mov     particle[edi].g,ecx
        mov     ecx,colors[eax+8]
        mov     particle[edi].b,ecx

        invoke  nrandom,50                  ; randomize each color component
        mov     tmp,eax
        fild    tmp
        fsub    fpc(26.0f)
        fmul    fpc(10.0f)
        fstp    particle[edi].xi

        invoke  nrandom,50
        mov     tmp,eax
        fild    tmp
        fsub    fpc(25.0f)
        fmul    fpc(10.0f)
        fstp    particle[edi].yi

        invoke  nrandom,50
        mov     tmp,eax
        fild    tmp
        fsub    fpc(25.0f)
        fmul    fpc(10.0f)
        fstp    particle[edi].zi

        mov     particle[edi].xg,0
        mov     particle[edi].yg,0BF4CCCCDh             ; -0.8f
        mov     particle[edi].zg,0

        add     edi,sizeof particles
        inc     ebx
    .endw

    mov		eax,1
    ret

InitGL ENDP

DrawGLScene PROC
  LOCAL x:REAL4,y:REAL4,z:REAL4
  LOCAL tmp:DWORD

    invoke  glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke  glLoadIdentity

    xor     ebx,ebx
    xor     edi,edi

    .while ebx < MAX_PARTICLES
        .if particle[edi].active
            mov     eax,particle[edi].x
            mov     x,eax
            mov     eax,particle[edi].y
            mov     y,eax
            fld     particle[edi].z
            fadd    zoom
            fstp    z

            invoke  glColor4f,particle[edi].r,particle[edi].g,particle[edi].b,particle[edi].life
            invoke  glBegin,GL_TRIANGLE_STRIP
                invoke  glTexCoord2d,0,3FF00000h,0,3FF00000h
                push    z                                       ; since parameters are not very easy
                sub     esp,4                                   ; to compute, I don't use invoke here
                fld     y                                       ; to have better control over the stack
                fadd    fpc(0.5f)
                fstp    dword ptr [esp]
                sub     esp,4
                fld     x
                fadd    fpc(0.5f)
                fstp    dword ptr [esp]
                call    glVertex3f

                invoke  glTexCoord2d,0,0,0,3FF00000h
                push    z
                sub     esp,4
                fld     y
                fadd    fpc(0.5f)
                fstp    dword ptr [esp]
                sub     esp,4
                fld     x
                fsub    fpc(0.5f)
                fstp    dword ptr [esp]
                call    glVertex3f

                invoke  glTexCoord2d,0,3FF00000h,0,0
                push    z
                sub     esp,4
                fld     y
                fsub    fpc(0.5f)
                fstp    dword ptr [esp]
                sub     esp,4
                fld     x
                fadd    fpc(0.5f)
                fstp    dword ptr [esp]
                call    glVertex3f

                invoke  glTexCoord2d,0,0,0,0
                push    z
                sub     esp,4
                fld     y
                fsub    fpc(0.5f)
                fstp    dword ptr [esp]
                sub     esp,4
                fld     x
                fsub    fpc(0.5f)
                fstp    dword ptr [esp]
                call    glVertex3f
            invoke  glEnd

            fld     slowdown                        ; store slowdown*1000 in tmp so we don't
            fmul    fpc(1000.0f)                    ; have to compute it each time
            fstp    tmp

            fld     particle[edi].xi
            fdiv    tmp
            fadd    particle[edi].x
            fstp    particle[edi].x
            fld     particle[edi].yi
            fdiv    tmp
            fadd    particle[edi].y
            fstp    particle[edi].y
            fld     particle[edi].zi
            fdiv    tmp
            fadd    particle[edi].z
            fstp    particle[edi].z

            fld     particle[edi].xi
            fadd    particle[edi].xg
            fstp    particle[edi].xi
            fld     particle[edi].yi
            fadd    particle[edi].yg
            fstp    particle[edi].yi
            fld     particle[edi].zi
            fadd    particle[edi].zg
            fstp    particle[edi].zi

            fld     particle[edi].life
            fsub    particle[edi].fade
            fstp    particle[edi].life

            fldz
            fld     particle[edi].life
            fcomip  st,st(1)                            ; compare 0 and particle.life, set al
            setc    al                                  ; if life is less than 0
            ffree   st
            fincstp
            .if al                                      ; if particle.life < 0
                mov     particle[edi].life,3F800000h
                invoke  nrandom,100
                mov     tmp,eax
                fild    tmp
                fdiv    fpc(1000.0f)
                fadd    fpc(0.003f)
                fstp    particle[edi].fade
                mov     particle[edi].x,0
                mov     particle[edi].y,0
                mov     particle[edi].z,0
                invoke  nrandom,60
                mov     tmp,eax
                fild    tmp
                fsub    fpc(32.0f)
                fadd    xspeed
                fstp    particle[edi].xi
                invoke  nrandom,60
                mov     tmp,eax
                fild    tmp
                fsub    fpc(30.0f)
                fadd    yspeed
                fstp    particle[edi].yi
                invoke   nrandom,60
                mov     tmp,eax
                fild    tmp
                fsub    fpc(30.0f)
                fstp    particle[edi].zi

                mov     eax,col
                mov     ecx,col
                shl     eax,3
                shl     ecx,2
                add     eax,ecx
                mov     edx,colors[eax]
                mov     particle[edi].r,edx
                mov     edx,colors[eax+4]
                mov     particle[edi].g,edx
                mov     edx,colors[eax+8]
                mov     particle[edi].b,edx
            .endif

            fld     fpc(1.5f)
            fld     particle[edi].yg
            fcomip  st,st(1)
            setc    al
            ffree   st
            fincstp
            .if keys[VK_NUMPAD8] && al
                fld     particle[edi].yg
                fadd    fpc(0.01f)
                fstp    particle[edi].yg
            .endif

            fld		particle[edi].yg
            fld		fpc(-1.5f)
            fcomip	st,st(1)
            setc	al
            ffree	st
            fincstp
            .if keys[VK_NUMPAD2] && al
                fld     particle[edi].yg
                fsub    fpc(0.01f)
                fstp    particle[edi].yg
            .endif

            fld     fpc(1.5f)
            fld     particle[edi].xg
            fcomip  st,st(1)
            setc    al
            ffree   st
            fincstp
            .if keys[VK_NUMPAD6] && al
                fld		particle[edi].xg
                fadd	fpc(0.01f)
                fstp	particle[edi].xg
            .endif

            fld		particle[edi].xg
            fld		fpc(-1.5f)
            fcomip	st,st(1)
            setc	al
            ffree	st
            fincstp
            .if keys[VK_NUMPAD4] && al
                fld     particle[edi].xg
                fsub    fpc(0.01f)
                fstp    particle[edi].xg
            .endif

            .if keys[VK_TAB]
                mov     particle[edi].x,0
                mov     particle[edi].y,0
                mov     particle[edi].z,0
                invoke  nrandom,50
                mov     tmp,eax
                fild    tmp
                fsub    fpc(26.0f)
                fmul    fpc(10.0f)
                fstp    particle[edi].xi
                invoke  nrandom,50
                mov     tmp,eax
                fild    tmp
                fsub    fpc(25.0f)
                fmul    fpc(10.0f)
                fstp    particle[edi].yi
                invoke  nrandom,50
                mov     tmp,eax
                fild    tmp
                fsub    fpc(25.0f)
                fmul    fpc(10.0f)
                fstp    particle[edi].zi
            .endif

        .endif

        add     edi,sizeof particles
        inc     ebx
    .endw

    mov     eax,1
    ret

DrawGLScene ENDP

KillGLWindow PROC

    .if fullscreen
        invoke  ChangeDisplaySettings,NULL,0
        invoke  ShowCursor,TRUE
    .endif
    .if hRc
        invoke  wglMakeCurrent,NULL,NULL
        invoke  wglDeleteContext,hRc
        mov     hRc,NULL
    .endif
    .if hDc
        invoke  ReleaseDC,hWnd,hDc
        mov     hDc,NULL
    .endif
    .if hWnd
        invoke  DestroyWindow,hWnd
        mov     hWnd,NULL
    .endif
    invoke      UnregisterClass,addr szClass,hInst
    ret

KillGLWindow ENDP

CreateGLWindow PROC titre:DWORD,w:DWORD,h:DWORD,bpp:DWORD
  LOCAL wc:WNDCLASS,style:DWORD
  LOCAL exstyle:DWORD,wrect:RECT,dm:DEVMODE
  LOCAL pfd:PIXELFORMATDESCRIPTOR

    mov     wrect.left,0
    mov     eax,w
    mov     wrect.right,eax
    mov     wrect.top,0
    mov     eax,h
    mov     wrect.bottom,eax
    mov     wc.style,CS_HREDRAW or CS_VREDRAW or CS_OWNDC
    mov     wc.lpfnWndProc,WndProc
    mov     wc.cbClsExtra,0
    mov     wc.cbWndExtra,0
    mov     eax,hInst
    mov     wc.hInstance,eax
    invoke  LoadIcon,NULL,IDI_WINLOGO
    mov     wc.hIcon,eax
    invoke  LoadCursor,NULL,IDC_ARROW
    mov     wc.hCursor,eax
    mov     wc.hbrBackground,0
    mov     wc.lpszMenuName,NULL
    mov     wc.lpszClassName,offset szClass
    invoke  RegisterClass,addr wc
    .if !eax
        invoke  MessageBox,NULL,addr szErr1,addr szErr,MB_ICONERROR or MB_OK
        xor     eax,eax
        ret
    .endif
    .if fullscreen
        ZeroMem dm,sizeof dm
        mov     dm.dmSize,sizeof dm
        mov     eax,w
        mov     dm.dmPelsWidth,eax
        mov     eax,h
        mov     dm.dmPelsHeight,eax
        mov     eax,bpp
        mov     dm.dmBitsPerPel,eax
        mov     dm.dmFields,DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT
        invoke  ChangeDisplaySettings,addr dm,CDS_FULLSCREEN
        .if eax != DISP_CHANGE_SUCCESSFUL
            invoke  MessageBox,NULL,addr szErr2,addr szErr,MB_YESNO or MB_ICONQUESTION
            .if eax == IDYES
                mov     fullscreen,0
            .else
                xor     eax,eax
                ret
            .endif
        .endif
    .endif
    .if fullscreen
        mov     exstyle,WS_EX_APPWINDOW
        mov     style,WS_POPUP
        invoke  ShowCursor,FALSE
    .else
        mov     exstyle,WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
        mov style,WS_OVERLAPPEDWINDOW
    .endif
    invoke  AdjustWindowRectEx,addr wrect,style,FALSE,exstyle
    mov     eax,wrect.right
    mov     ebx,wrect.bottom
    mov     ecx,style
    sub     eax,wrect.left
    sub     ebx,wrect.top
    or      ecx,WS_CLIPSIBLINGS or WS_CLIPCHILDREN
    invoke  CreateWindowEx,exstyle,addr szClass,titre,ecx,0,0,eax,ebx,NULL,NULL,hInst,NULL
    .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr3,addr szErr,MB_ICONERROR or MB_OK
        xor     eax,eax
        ret
    .endif
    mov     hWnd,eax
    ZeroMem pfd,sizeof pfd
    mov     pfd.nSize,sizeof pfd
    mov     pfd.nVersion,1
    mov     pfd.dwFlags,PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
    mov     pfd.iPixelType,PFD_TYPE_RGBA
    mov     eax,bpp
    mov     pfd.cColorBits,al
    mov     pfd.cDepthBits,16
    mov     pfd.iLayerType,PFD_MAIN_PLANE
    invoke  GetDC,hWnd
    .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr4,addr szErr,MB_OK or MB_ICONERROR
        xor     eax,eax
        ret
    .endif
     mov     hDc,eax
     invoke  ChoosePixelFormat,hDc,addr pfd
     .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr5,addr szErr,MB_OK or MB_ICONERROR
        xor     eax,eax
        ret
    .endif
    mov     ebx,eax
    invoke  SetPixelFormat,hDc,ebx,addr pfd
    .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr6,addr szErr,MB_OK or MB_ICONERROR
        xor     eax,eax
        ret
    .endif
    invoke  wglCreateContext,hDc
    .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr7,addr szErr,MB_OK or MB_ICONERROR
        xor     eax,eax
        ret
    .endif
    mov     hRc,eax
    invoke  wglMakeCurrent,hDc,eax
    .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr8,addr szErr,MB_OK or MB_ICONERROR
        xor     eax,eax
        ret
    .endif
    invoke  ShowWindow,hWnd,SW_SHOW
    invoke  SetForegroundWindow,hWnd
    invoke  SetFocus,hWnd
    invoke  ResizeGLScene,w,h
    invoke  InitGL
    .if !eax
        invoke  KillGLWindow
        invoke  MessageBox,NULL,addr szErr9,addr szErr,MB_OK or MB_ICONERROR
        xor     eax,eax
        ret
    .endif
    mov     eax,1
    ret

CreateGLWindow ENDP

WndProc PROC hW:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

    .if uMsg == WM_ACTIVATE
        mov     eax,wParam
        shr     eax,16
        .if !ax
            mov     active,1
        .else
            mov     active,0
        .endif
            xor     eax,eax
            ret
    .elseif uMsg == WM_SYSCOMMAND
        .if (wParam == SC_SCREENSAVE) || (wParam == SC_MONITORPOWER)
            xor     eax,eax
            ret
        .endif
    .elseif uMsg == WM_CLOSE
        invoke  PostQuitMessage,0
        xor     eax,eax
        ret
    .elseif uMsg == WM_KEYDOWN
        mov     eax,wParam
        mov     keys[eax],1
        xor     eax,eax
        ret
    .elseif uMsg == WM_KEYUP
        mov     eax,wParam
        mov     keys[eax],0
        xor     eax,eax
        ret
    .elseif uMsg == WM_SIZE
        mov     eax,lParam
        movzx   ebx,ax
        shr     eax,16
        invoke  ResizeGLScene,ebx,eax
        xor     eax,eax
        ret
    .endif
    invoke  DefWindowProc,hW,uMsg,wParam,lParam
    ret

WndProc ENDP

WinMain PROC hInstance:DWORD,lpCmdLine:DWORD,nCmdShow:DWORD
  LOCAL msg:MSG,done:DWORD

    mov     done,0

    invoke  MessageBox,NULL,addr szMsg1,addr szTitle,MB_YESNO or MB_ICONQUESTION
    .if eax == IDYES
        mov     fullscreen,1
    .else
        mov     fullscreen,0
    .endif

    invoke  CreateGLWindow,addr szTitle,640,480,16
    .if !eax
        xor     eax,eax
        ret
    .endif

    .if fullscreen
        mov     slowdown,3F800000h
    .endif

    .while !done
        invoke  PeekMessage,addr msg,NULL,0,0,PM_REMOVE
        .if eax
            .if msg.message == WM_QUIT
                mov     done,1
            .else
                invoke  TranslateMessage,addr msg
                invoke  DispatchMessage,addr msg
            .endif
        .else
            .if active
                invoke  DrawGLScene
                .if !eax || keys[VK_ESCAPE]
                    mov     done,1
                .else
                    invoke  SwapBuffers,hDc

                    fld     slowdown
                    fld1
                    fcomip  st,st(1)
                    setc    al
                    ffree   st
                    fincstp
                    .if keys[VK_ADD] && al
                        fld     slowdown
                        fsub    fpc(0.01f)
                        fstp    slowdown
                    .endif

                    fld     fpc(4.0f)
                    fld     slowdown
                    fcomip  st,st(1)
                    setc    al
                    ffree   st
                    fincstp
                    .if keys[VK_SUBTRACT] && al
                        fld     slowdown
                        fadd    fpc(0.01f)
                        fstp    slowdown
                    .endif

                    .if keys[VK_PRIOR]
                        fld     zoom
                        fadd    fpc(0.1f)
                        fstp    zoom
                    .endif

                    .if keys[VK_NEXT]
                        fld     zoom
                        fsub    fpc(0.1f)
                        fstp    zoom
                    .endif

                    .if keys[VK_RETURN] && !rp
                        mov     rp,1
                        xor     rainbow,1
                    .endif
                    .if !keys[VK_RETURN]
                        mov     rp,0
                    .endif

                    .if (keys[VK_SPACE] && !space) || (rainbow && (delay > 25))
                        .if keys[VK_SPACE]
                            mov     rainbow,0
                        .endif
                        mov     space,1
                        mov     delay,0
                        inc     col
                        .if col > 11
                            mov     col,0
                        .endif
                    .endif
                    .if !keys[VK_SPACE]
                        mov     space,0
                    .endif

                    fld     fpc(200.0f)
                    fld     yspeed
                    fcomip  st,st(1)
                    setc    al
                    ffree   st
                    fincstp
                    .if keys[VK_UP] && al
                        fld     yspeed
                        fadd    fpc(1.0f)
                        fstp    yspeed
                    .endif

                    fld     yspeed
                    fld     fpc(-200.0f)
                    fcomip  st,st(1)
                    setc    al
                    ffree   st
                    fincstp
                    .if keys[VK_DOWN] && al
                        fld     yspeed
                        fsub    fpc(1.0f)
                        fstp    yspeed
                    .endif

                    fld     fpc(200.0f)
                    fld     xspeed
                    fcomip  st,st(1)
                    setc    al
                    ffree   st
                    fincstp
                    .if keys[VK_RIGHT]
                        fld     xspeed
                        fadd    fpc(1.0f)
                        fstp    xspeed
                    .endif

                    fld     xspeed
                    fld     fpc(-200.0f)
                    fcomip  st,st(1)
                    setc    al
                    ffree   st
                    fincstp
                    .if keys[VK_LEFT]
                        fld     xspeed
                        fsub    fpc(1.0f)
                        fstp    xspeed
                    .endif

                    inc     delay
 
                    .if keys[VK_F1]
                        mov     keys[VK_F1],0
                        invoke  KillGLWindow
                        xor     fullscreen,1
                        invoke  CreateGLWindow,addr szTitle,640,480,16
                        .if !eax
                            xor     eax,eax
                            ret
                        .endif
                    .endif

                .endif
            .endif
        .endif
    .endw

    invoke  KillGLWindow
    mov     eax,msg.wParam
    ret

WinMain ENDP

nrandom PROC base:DWORD

;  #########################################################################
;
;                     Park Miller random number algorithm.
;
;                      Written by Jaymeson Trudgen (NaN)
;                   Optimized by Rickey Bowers Jr. (bitRAKE)
;
;  #########################################################################


    mov eax,nseed

    xor edx,edx
    mov ecx,127773
    div ecx
    mov ecx,eax
    mov eax,16807
    mul edx
    mov edx,ecx
    mov ecx,eax
    mov eax,2836
    mul edx
    sub ecx,eax
    xor edx,edx
    mov eax,ecx
    mov nseed,ecx
    div base

    mov eax,edx
    ret

nrandom ENDP

END Start