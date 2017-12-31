;-------------------------------------------------------------------------------------------;
; MASM32 conversion of NeHe's OpenGL tutorial 20 by Christophe Jeannin (Chrishka)           ;
;                                                                                           ;
; I converted "Image2.bmp" to 24 bits/pixel cause my way of loading bitmap doesn't handle   ;
; 8 bits/pixel bmp. I couldn't find a way to do it (I didn't try very hard, that's true)    ;
; If someone feels like showing me a way to do it, my address is :                          ;
; chris.j84@free.fr (you can use this address for comments, suggestions, corrections,       ;
; criticism, etc... too, fell free to mail me)                                              ;
;                                                                                           ;
; float and double parameters are directly pushed as immediate, it's better than macro in   ;
; some cases, cause it's avoiding some memory references, but fpu instructions don't accept ;
; immediate, so it's not always possible.                                                   ;
; I wrote a little program (Conv.exe) to have a fast way to find hex representation of      ;
; single and double precision floating point numbers.                                       ;
; doubles (coded on 8 bytes) are pushed as 2 dwords, most significant dword first, then     ;
; less significant one, but with stdcall arguments right to left you have to give invoke    ;
; less significant dword first, and then the most significant dword.                        ;
;-------------------------------------------------------------------------------------------;


include Lesson20.inc

.data

    hWnd        dd          NULL
    hDc         dd          NULL
    hRc         dd          NULL

    active      db          1

    masking     db          1

.data?

    hInst       dd          ?

    roll        REAL4       ?

    texture     dd          5 dup(?)

    mp          db          ?
    space       db          ?

    fullscreen  db          ?

    keys        db          256 dup(?)

    scene       db          ?

.const

    szClass     db          "NeHe's OpenGL",0

    szErr       db          "Error",0
    szTitle     db          "NeHe's masking tutorial",0

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
	
    szTexture1  db          "logo.bmp",0
    szTexture2  db          "mask1.bmp",0
    szTexture3  db          "image1.bmp",0
    szTexture4  db          "mask2.bmp",0
    szTexture5  db          "image2.bmp",0

.code

Start:

    invoke      GetModuleHandle,NULL
    mov         hInst,eax
    invoke      WinMain,eax,NULL,0
    invoke      ExitProcess,eax


LoadGLTexture PROC
  LOCAL info:BITMAP,hBmp1:DWORD
  LOCAL hBmp2:DWORD,hBmp3:DWORD
  LOCAL hBmp4:DWORD,hBmp5:DWORD

    invoke  LoadImage,NULL,addr szTexture1,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp1,eax
    invoke  LoadImage,NULL,addr szTexture2,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp2,eax
    invoke  LoadImage,NULL,addr szTexture3,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp3,eax
    invoke  LoadImage,NULL,addr szTexture4,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp4,eax
    invoke  LoadImage,NULL,addr szTexture5,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp5,eax

    invoke  glGenTextures,5,addr texture
    xor     ebx,ebx
    lea     edi,hBmp1

    .while ebx < 20
        invoke  glBindTexture,GL_TEXTURE_2D,texture[ebx]
        invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
        invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR
        invoke  GetObject,[edi],sizeof info,addr info
        invoke  glTexImage2D,GL_TEXTURE_2D,0,3,info.bmWidth,info.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits
        sub     edi,4
        add     ebx,4
    .endw

    invoke  DeleteObject,hBmp1
    invoke  DeleteObject,hBmp2
    invoke  DeleteObject,hBmp3
    invoke  DeleteObject,hBmp4
    invoke  DeleteObject,hBmp5

    mov     eax,1
    ret

LoadGLTexture ENDP


ResizeGLScene PROC w:DWORD,h:DWORD

    .if h == 0
        mov     h,1
    .endif
    invoke  glViewport,0,0,w,h
    invoke  glMatrixMode,GL_PROJECTION
    invoke  glLoadIdentity
    push    40590000h               ; 100.0
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

    invoke  LoadGLTexture
    .if !eax
        ret
    .endif

    invoke  glClearColor,0,0,0,0
    invoke  glClearDepth,0,3FF00000h        ;1.0 double
    invoke  glEnable,GL_DEPTH_TEST
    invoke  glShadeModel,GL_SMOOTH
    invoke  glEnable,GL_TEXTURE_2D
    mov     eax,1
    ret

InitGL ENDP


DrawGLScene PROC
  LOCAL tmp:REAL4

    invoke  glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke  glLoadIdentity
    invoke  glTranslatef,0,0,0C0000000h

    invoke  glBindTexture,GL_TEXTURE_2D,texture[0*4]
    invoke  glBegin,GL_QUADS
        fldz
        fsub    roll
        fstp    tmp
        invoke  glTexCoord2f,0,tmp
        invoke  glVertex3f,0BF8CCCCDh,0BF8CCCCDh,0
        invoke  glTexCoord2f,40400000h,tmp
        invoke  glVertex3f,3F8CCCCDh,0BF8CCCCDh,0
        fld     fpc(3.0f)
        fsub    roll
        fstp    tmp
        invoke  glTexCoord2f,40400000h,tmp
        invoke  glVertex3f,3F8CCCCDh,3F8CCCCDh,0
        invoke  glTexCoord2f,0,tmp
        invoke  glVertex3f,0BF8CCCCDh,3F8CCCCDh,0
    invoke  glEnd

    invoke  glEnable,GL_BLEND
    invoke  glDisable,GL_DEPTH_TEST

    .if masking
        invoke  glBlendFunc,GL_DST_COLOR,GL_ZERO
    .endif

    .if scene
        invoke  glTranslatef,0,0,0BF800000h
        push    3F800000h
        push    0
        push    0
        fld     roll
        fmul    fpc(360.0f)
        sub     esp,4
        fstp    dword ptr [esp]
        call    glRotatef

        .if masking
            invoke  glBindTexture,GL_TEXTURE_2D,texture[3*4]
            invoke  glBegin,GL_QUADS
                invoke  glTexCoord2f,0,0
                invoke  glVertex3f,0BF8CCCCDh,0BF8CCCCDh,0
                invoke  glTexCoord2f,3F800000h,0
                invoke  glVertex3f,3F8CCCCDh,0BF8CCCCDh,0
                invoke  glTexCoord2f,3F800000h,3F800000h
                invoke  glVertex3f,3F8CCCCDh,3F8CCCCDh,0
                invoke  glTexCoord2f,0,3F800000h
                invoke  glVertex3f,0BF8CCCCDh,3F8CCCCDh,0
            invoke  glEnd
        .endif

        invoke  glBlendFunc,GL_ONE,GL_ONE
        invoke  glBindTexture,GL_TEXTURE_2D,texture[4*4]
        invoke  glBegin,GL_QUADS
            invoke  glTexCoord2f,0,0
            invoke  glVertex3f,0BF8CCCCDh,0BF8CCCCDh,0
            invoke  glTexCoord2f,3F800000h,0
            invoke  glVertex3f,3F8CCCCDh,0BF8CCCCDh,0
            invoke  glTexCoord2f,3F800000h,3F800000h
            invoke  glVertex3f,3F8CCCCDh,3F8CCCCDh,0
            invoke  glTexCoord2f,0,3F800000h
            invoke  glVertex3f,0BF8CCCCDh,3F8CCCCDh,0
        invoke  glEnd
    .else
        .if masking
            invoke  glBindTexture,GL_TEXTURE_2D,texture[1*4]
            invoke  glBegin,GL_QUADS
                invoke  glTexCoord2f,roll,0
                invoke  glVertex3f,0BF8CCCCDh,0BF8CCCCDh,0
                fld     roll
                fadd    fpc(4.0f)
                fstp    tmp
                invoke  glTexCoord2f,tmp,0
                invoke  glVertex3f,3F8CCCCDh,0BF8CCCCDh,0
                invoke  glTexCoord2f,tmp,40800000h
                invoke  glVertex3f,3F8CCCCDh,3F8CCCCDh,0
                invoke  glTexCoord2f,roll,40800000h
                invoke  glVertex3f,0BF8CCCCDh,3F8CCCCDh,0
            invoke  glEnd
        .endif

        invoke  glBlendFunc,GL_ONE,GL_ONE
        invoke  glBindTexture,GL_TEXTURE_2D,texture[2*4]
        invoke  glBegin,GL_QUADS
            invoke  glTexCoord2f,roll,0
            invoke  glVertex3f,0BF8CCCCDh,0BF8CCCCDh,0
            fld     roll
            fadd    fpc(4.0f)
            fstp    tmp
            invoke  glTexCoord2f,tmp,0
            invoke  glVertex3f,3F8CCCCDh,0BF8CCCCDh,0
            invoke  glTexCoord2f,tmp,40800000h
            invoke  glVertex3f,3F8CCCCDh,3F8CCCCDh,0
            invoke  glTexCoord2f,roll,40800000h
            invoke  glVertex3f,0BF8CCCCDh,3F8CCCCDh,0
        invoke  glEnd
    .endif

    invoke  glEnable,GL_DEPTH_TEST
    invoke  glDisable,GL_BLEND

    fld     roll
    fadd    fpc(0.002f)
    fld1
    fcomip  st,st(1)                ; comparing (roll+0.002) with 1
    setc    al
    .if al                          ; if (roll+0.002) > 1
        fsub    fpc(1.0)            ; then substract 1 from it
    .endif
    fstp    roll

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
            invoke  DrawGLScene
            .if (active && !eax) || keys[VK_ESCAPE]
                mov     done,1
            .else
                invoke  SwapBuffers,hDc

                .if keys[VK_SPACE] && !space
                    mov     space,1
                    xor     scene,1
                .endif

                .if !keys[VK_SPACE]
                    mov     space,0
                .endif

                .if keys[VK_M] && !mp
                    mov     mp,1
                    xor     masking,1
                .endif

                .if !keys[VK_M]
                    mov     mp,0
                .endif

                .if keys[VK_F1]
                    mov     keys[VK_F1],0
                    invoke  KillGLWindow
                    xor     fullscreen,1
                    invoke  CreateGLWindow,addr szTitle,640,480,16
                    .if !eax
                        ret
                    .endif
                .endif

            .endif
        .endif
    .endw

    invoke  KillGLWindow
    mov     eax,msg.wParam
    ret

WinMain ENDP


END Start