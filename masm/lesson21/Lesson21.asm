;-------------------------------------------------------------------------------------------;
;															  ;
;     MASM32 conversion of NeHe's OpenGL tutorial 21 by Christophe Jeannin (Chrishka)       ;
;                                                                                           ;
;-------------------------------------------------------------------------------------------;


include Lesson21.inc


.data

    hWnd        dd          NULL
    hDc         dd          NULL
    hRc         dd          NULL

    adjust      dd          3
    lives       dd          5
    level       dd          1
    level2      dd          1
    stage       dd          1

    steps       dd          6 dup(1,2,4,5,10,20)

    active      db          1
    anti        db          1

.data?

    hInst       dd          ?

    delay       dd          ?
    texture     dd          2 dup(?)
    base        dd          ?
    nseed       dd          ?

    vsprintf    dd          ?
    hDll        dd          ?

    player      object      <>
    enemy       object      <>
                object      <>
                object      <>
                object      <>
                object      <>
                object      <>
                object      <>
                object      <>
                object      <>
    hourglass   object      <>

    timer       _timer      <>

    ap          db          ?
    filled      db          ?
    gameover    db          ?
    fullscreen  db          ?
    keys        db          256 dup(?)
    vline       db          110 dup(?)  ;[11][10]
    hline       db          110 dup(?)  ;[10][11]

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
    szErr10     db          "Unable to load crtdll.dll",0
	
    szMsg1      db          "Would you like to run in fullscreen mode ?",0
    szMsg2      db          "GRID CRAZY",0
    szMsg3      db          "Level:%2i",0
    szMsg4      db          "Stage:%2i",0
    szMsg5      db          "GAME OVER",0
    szMsg6      db          "PRESS SPACE",0

    szTex1      db          "Font.bmp",0
    szTex2      db          "Image.bmp",0

    szSnd1      db          "Die.wav",0
    szSnd2      db          "Complete.wav",0
    szSnd3      db          "Freeze.wav",0
    szSnd4      db          "Hourglass.wav",0

    crt         db          "crtdll.dll",0
    vspr        db          "vsprintf",0

.code

Start:    

    invoke  GetModuleHandle,NULL
    mov     hInst,eax
    invoke  WinMain,eax,NULL,0
    invoke  ExitProcess,eax



TimerInit PROC

    ZeroMem timer,sizeof timer
    invoke  QueryPerformanceFrequency,addr timer.frequency
    .IF !eax
        mov     timer.performance_timer,0
        invoke  timeGetTime
        mov     timer.mm_timer_start,eax
        mov     timer.mm_timer_elapsed,eax
        mov     timer.resolution,3A83126Fh          ; 0.001f
        mov     dword ptr [timer.frequency],1000
        mov     dword ptr [timer.frequency+4],0
    .ELSE
        invoke  QueryPerformanceCounter,addr timer.performance_timer_start
        mov     timer.performance_timer,1
        fild    timer.frequency
        fdivr   fpc(1.0f)
        fstp    timer.resolution
        mov     eax,dword ptr [timer.performance_timer_start]
        mov     ecx,dword ptr [timer.performance_timer_start+4]
        mov     dword ptr [timer.performance_timer_elapsed],eax
        mov     dword ptr [timer.performance_timer_elapsed+4],ecx
    .ENDIF

TimerInit ENDP


TimerGetTime PROC
  LOCAL time:QWORD,tmp:DWORD

    .IF timer.performance_timer
        invoke  QueryPerformanceCounter,addr time
        fild    time
        fild    timer.performance_timer_start
        fsubp   st(1),st
        fmul    timer.resolution
        fmul    fpc(1000.0f)
        fstp    tmp
        mov     eax,tmp
        ret
    .ELSE
        invoke  timeGetTime
        mov     tmp,eax
        fild    tmp
        fild    timer.mm_timer_start
        fsubp   st(1),st
        fmul    timer.resolution
        fmul    fpc(1000.0f)
        fstp    tmp
        mov     eax,tmp
        ret
    .ENDIF

TimerGetTime ENDP


ResetObjects PROC
  LOCAL loop1:DWORD
  LOCAL lmt:DWORD

    mov     player.x,0
    mov     player.y,0
    mov     player.fx,0
    mov     player.fy,0

    mov     eax,level
    mul     stage
    mov     lmt,eax
    mov     loop1,0

    .WHILE loop1 < eax
        mov     eax,loop1
        imul    eax,eax,sizeof enemy
        mov     edi,eax
        invoke  nrandom,6
        add     eax,5
        mov     enemy[edi].x,eax
        invoke  nrandom,11
        mov     enemy[edi].y,eax
        mov     eax,enemy[edi].x
        imul    eax,eax,60
        mov     enemy[edi].fx,eax
        mov     eax,enemy[edi].y
        imul    eax,eax,40
        mov     enemy[edi].fy,eax
        mov     eax,lmt
        inc     loop1
    .ENDW

    ret

ResetObjects ENDP


LoadGLTexture PROC
  LOCAL info:BITMAP
  LOCAL hBmp1:DWORD
  LOCAL hBmp2:DWORD

    invoke  LoadImage,NULL,addr szTex1,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp1,eax
    invoke  LoadImage,NULL,addr szTex2,IMAGE_BITMAP,0,0,LR_LOADFROMFILE or LR_CREATEDIBSECTION
    .if !eax
        ret
    .endif
    mov     hBmp2,eax

    invoke  glGenTextures,2,addr texture
    invoke  glBindTexture,GL_TEXTURE_2D,texture[0*4]
    invoke  GetObject,hBmp1,sizeof info,addr info
    invoke  glTexImage2D,GL_TEXTURE_2D,0,3,info.bmWidth,info.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits
    invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
    invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR

    invoke  glBindTexture,GL_TEXTURE_2D,texture[1*4]
    invoke  GetObject,hBmp2,sizeof info,addr info
    invoke  glTexImage2D,GL_TEXTURE_2D,0,3,info.bmWidth,info.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,info.bmBits
    invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
    invoke  glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR

    invoke  DeleteObject,hBmp1
    invoke  DeleteObject,hBmp2

    mov     eax,1
    ret

LoadGLTexture ENDP


BuildFont PROC
  LOCAL loop1:DWORD
  LOCAL tmp:DWORD
  LOCAL _cx:REAL4
  LOCAL _cy:REAL4

    invoke  glGenLists,256
    mov     base,eax
    invoke  glBindTexture,GL_TEXTURE_2D,texture[0*4]
    mov     loop1,0

    .WHILE loop1 < 256
        xor     edx,edx
        mov     eax,loop1
        mov     ecx,16
        div     ecx
        mov     tmp,edx
        fild    tmp
        fdiv    fpc(16.0f)
        fstp    _cx
        mov     tmp,eax
        fild    tmp
        fdiv    fpc(16.0f)
        fstp    _cy
        mov     eax,base
        add     eax,loop1
        invoke  glNewList,eax,GL_COMPILE
            invoke  glBegin,GL_QUADS
                fld1
                fsub    _cy
                fsub    fpc(0.0625f)
                fstp    tmp
                invoke  glTexCoord2f,_cx,tmp
                invoke  glVertex2i,0,16
                fld     _cx
                fadd    fpc(0.0625f)
                mov     eax,tmp
                fstp    tmp
                invoke  glTexCoord2f,tmp,eax
                invoke  glVertex2i,16,16
                fld1
                fsub    _cy
                mov     eax,tmp
                fstp    tmp
                invoke  glTexCoord2f,eax,tmp
                invoke  glVertex2i,16,0
                invoke  glTexCoord2f,_cx,tmp
                invoke  glVertex2i,0,0
            invoke  glEnd
            invoke  glTranslatef,fpc(15.0f),0,0
        invoke  glEndList
        inc     loop1
    .ENDW

    ret

BuildFont ENDP


glPrint PROC C x:DWORD,y:DWORD,set:DWORD,fmt:DWORD,params:VARARG
  LOCAL text[256]:BYTE,tx:REAL4,ty:REAL4

    .IF fmt == NULL
        ret
    .ENDIF

    lea     ecx,params
    lea     eax,text
    push    ecx
    push    fmt
    push    eax
    call    vsprintf

    .IF set > 1
        mov     set,1
    .ENDIF

    invoke  glEnable,GL_TEXTURE_2D
    invoke  glLoadIdentity
    fild    x
    fstp    tx
    fild    y
    fstp    ty
    invoke  glTranslatef,tx,ty,0
    mov     eax,set
    imul    eax,eax,128
    mov     edx,base
    sub     edx,32
    add     edx,eax
    invoke  glListBase,edx

    .IF set == 0
        invoke  glScalef,fpc(1.5f),fpc(2.0f),fpc(1.0f)
    .ENDIF

    lea     ecx,text
    invoke  strlen,ecx
    lea     ecx,text
    invoke  glCallLists,eax,GL_UNSIGNED_BYTE,ecx
    invoke  glDisable,GL_TEXTURE_2D

    ret

glPrint ENDP


ResizeGLScene PROC w:DWORD,h:DWORD

    .IF h == 0
        mov     h,1
    .ENDIF
    invoke  glViewport,0,0,w,h
    invoke  glMatrixMode,GL_PROJECTION
    invoke  glLoadIdentity

    push    3FF00000h
    push    0
    push    0BFF00000h
    push    0
    push    0
    push    0
    sub     esp,8
    fild    h
    fstp    qword ptr [esp]
    sub     esp,8
    fild    w
    fstp    qword ptr [esp]
    push    0
    push    0
    call    glOrtho

    invoke  glMatrixMode,GL_MODELVIEW
    invoke  glLoadIdentity

    ret

ResizeGLScene ENDP


InitGL PROC

    invoke  LoadLibrary,addr crt
    .IF eax == NULL
        invoke  MessageBox,NULL,addr szErr10,addr szErr,MB_ICONERROR or MB_OK
        xor     eax,eax
        ret
    .ENDIF
    mov     hDll,eax
    invoke  GetProcAddress,eax,addr vspr
    .IF eax == NULL
        invoke  MessageBox,NULL,addr szErr10,addr szErr,MB_ICONERROR or MB_OK
        xor     eax,eax
        ret
    .ENDIF
    mov     vsprintf,eax

    invoke  LoadGLTexture
    .IF !eax
        ret
    .ENDIF

    invoke  BuildFont

    invoke  glShadeModel,GL_SMOOTH
    invoke  glClearColor,0,0,0,3F000000h
    invoke  glClearDepth,0,3FF00000h        ;1.0 double
    invoke  glHint,GL_LINE_SMOOTH_HINT,GL_NICEST
    invoke  glEnable,GL_BLEND
    invoke  glBlendFunc,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA

    invoke  GetTickCount
    mov     nseed,eax

    mov     eax,1
    ret

InitGL ENDP


DrawGLScene PROC
  LOCAL loop1:DWORD
  LOCAL loop2:DWORD
  LOCAL tmp:DWORD
  LOCAL tmp2:DWORD

    invoke  glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke  glBindTexture,GL_TEXTURE_2D,texture[0*4]
    invoke  glColor3f,3F800000h,3F000000h,3F800000h
    invoke  glPrint,207,24,0,addr szMsg2
    invoke  glColor3f,3F800000h,3F800000h,0
    invoke  glPrint,20,20,1,addr szMsg3,level2
    invoke  glPrint,20,40,1,addr szMsg4,stage

    .IF gameover
        invoke  nrandom,255
        mov     ecx,eax
        invoke  nrandom,255
        mov     edx,eax
        invoke  nrandom,255
        invoke  glColor3ub,eax,ecx,edx
        invoke  glPrint,472,20,1,addr szMsg5
        invoke  glPrint,472,40,1,addr szMsg6
    .ENDIF

    mov     eax,lives
    sub     eax,1
    .IF eax == 0FFFFFFFFh
    	jmp		@f
    .ENDIF
    mov     loop1,0

    .WHILE loop1 < eax
        invoke  glLoadIdentity
        fild    loop1
        fmul    fpc(40.0f)
        fadd    fpc(490.0f)
        fstp    tmp
        invoke  glTranslatef,tmp,42200000h,0
        fldz
        fsub    player.spin
        fstp    tmp
        invoke  glRotatef,tmp,0,0,3F800000h
        invoke  glColor3f,0,3F800000h,0

        invoke  glBegin,GL_LINES
            invoke  glVertex2i,-5,-5
            invoke  glVertex2i,5,5
            invoke  glVertex2i,5,-5
            invoke  glVertex2i,-5,5
        invoke  glEnd

        fldz
        fsub    player.spin
        fmul    fpc(0.5f)
        fstp    tmp
        invoke  glRotatef,tmp,0,0,3F800000h
        invoke  glColor3f,0,3F400000h,0

        invoke  glBegin,GL_LINES
            invoke  glVertex2i,-7,0
            invoke  glVertex2i,7,0
            invoke  glVertex2i,0,-7
            invoke  glVertex2i,0,7
        invoke  glEnd

        mov     eax,lives
        sub     eax,1
        inc     loop1
    .ENDW
@@:
    mov     filled,1
    invoke  glLineWidth,40000000h
    invoke  glDisable,GL_LINE_SMOOTH
    invoke  glLoadIdentity
    mov     loop1,0

    .WHILE loop1 < 11
        mov     loop2,0

        .WHILE loop2 < 11
            invoke  glColor3f,0,3F000000h,3F800000h
            mov     eax,loop1
            imul    eax,eax,11
            mov     ecx,loop2

            .IF hline[eax+ecx]
                invoke  glColor3f,3F800000h,3F800000h,3F800000h
            .ENDIF

            .IF loop1 < 10
                mov     eax,loop1
                imul    eax,eax,11
                mov     ecx,loop2

                .IF !hline[eax+ecx]
                    mov     filled,0
                .ENDIF

                invoke  glBegin,GL_LINES
                    mov     eax,60
                    mul     loop1
                    add     eax,20
                    mov     ecx,eax
                    mov     eax,loop2
                    imul    eax,eax,40
                    add     eax,70
                    mov     tmp,eax
                    invoke  glVertex2i,ecx,eax
                    mov     eax,loop1
                    imul    eax,eax,60
                    add     eax,80
                    invoke  glVertex2i,eax,tmp
                invoke  glEnd
            .ENDIF

            invoke  glColor3f,0,3F000000h,3F800000h
            mov     eax,loop1
            imul    eax,eax,10
            mov     ecx,loop2

            .IF vline[eax+ecx]
                invoke  glColor3f,3F800000h,3F800000h,3F800000h
            .ENDIF

            .IF loop2 < 10
                mov     eax,loop1
                imul    eax,eax,10
                mov     ecx,loop2

                .IF !vline[eax+ecx]
                    mov     filled,0
                .ENDIF

                invoke  glBegin,GL_LINES
                    mov     eax,loop1
                    imul    eax,eax,60
                    add     eax,20
                    mov     tmp,eax
                    mov     eax,loop2
                    imul    eax,eax,40
                    add     eax,70
                    invoke  glVertex2i,tmp,eax
                    mov     eax,loop2
                    imul    eax,eax,40
                    add     eax,110
                    invoke  glVertex2i,tmp,eax
                invoke  glEnd

            .ENDIF

            invoke  glEnable,GL_TEXTURE_2D
            invoke  glColor3f,3F800000h,3F800000h,3F800000h
            invoke  glBindTexture,GL_TEXTURE_2D,texture[1*4]

            .IF (loop1 < 10) && (loop2 < 10)
                mov     eax,loop1
                imul    eax,eax,11
                mov     ecx,eax
                add     ecx,loop2
                mov     eax,loop1
                imul    eax,eax,10
                mov     edx,eax
                add     eax,10
                add     edx,loop2
                add     eax,loop2

                .IF hline[ecx] && hline[ecx+1] && vline[edx] && vline[eax]
                    invoke  glBegin,GL_QUADS
                        fild    loop1
                        fdiv    fpc(10.0f)
                        fadd    fpc(0.1f)
                        fstp    tmp
                        fild    loop2
                        fdiv    fpc(10.0f)
                        fld1
                        fsubrp  st(1),st
                        fstp    tmp2
                        invoke  glTexCoord2f,tmp,tmp2
                        mov     eax,loop1
                        imul    eax,eax,60
                        add     eax,79
                        mov     ecx,eax
                        mov     eax,loop2
                        imul    eax,eax,40
                        add     eax,71
                        invoke  glVertex2i,ecx,eax
                        fild    loop1
                        fdiv    fpc(10.0f)
                        fstp    tmp
                        invoke  glTexCoord2f,tmp,tmp2
                        mov     eax,loop1
                        imul    eax,eax,60
                        add     eax,21
                        mov     ecx,eax
                        mov     eax,loop2
                        imul    eax,eax,40
                        add     eax,71
                        invoke  glVertex2i,ecx,eax
                        fild    loop2
                        fdiv    fpc(10.0f)
                        fstp    tmp2
                        fld1
                        fsub    tmp2
                        fsub    fpc(0.1f)
                        fstp    tmp2
                        invoke  glTexCoord2f,tmp,tmp2
                        mov     eax,loop1
                        imul    eax,eax,60
                        add     eax,21
                        mov     ecx,eax
                        mov     eax,loop2
                        imul    eax,eax,40
                        add     eax,109
                        invoke  glVertex2i,ecx,eax
                        fild    loop1
                        fdiv    fpc(10.0f)
                        fadd    fpc(0.1f)
                        fstp    tmp
                        invoke  glTexCoord2f,tmp,tmp2
                        mov     eax,loop1
                        imul    eax,eax,60
                        add     eax,79
                        mov     ecx,eax
                        mov     eax,loop2
                        imul    eax,eax,40
                        add     eax,109
                        invoke  glVertex2i,ecx,eax
                    invoke  glEnd
                .ENDIF

            .ENDIF

            invoke  glDisable,GL_TEXTURE_2D

            inc     loop2
        .ENDW

        inc     loop1
    .ENDW

    invoke  glLineWidth,3F800000h

    .IF anti
        invoke  glEnable,GL_LINE_SMOOTH
    .ENDIF

    .IF hourglass.fx == 1

        invoke  glLoadIdentity
        fild    hourglass.x
        fmul    fpc(60.0f)
        fadd    fpc(20.0f)
        fstp    tmp
        fild    hourglass.y
        fmul    fpc(40.0f)
        fadd    fpc(70.0f)
        fstp    tmp2
        invoke  glTranslatef,tmp,tmp2,0
        invoke  glRotatef,hourglass.spin,0,0,3F800000h
        invoke  nrandom,255
        mov     ecx,eax
        invoke  nrandom,255
        mov     edx,eax
        invoke  nrandom,255
        invoke  glColor3ub,eax,ecx,edx

        invoke  glBegin,GL_LINES
            invoke  glVertex2i,-5,-5
            invoke  glVertex2i,5,5
            invoke  glVertex2i,5,-5
            invoke  glVertex2i,-5,5
            invoke  glVertex2i,-5,5
            invoke  glVertex2i,5,5
            invoke  glVertex2i,-5,-5
            invoke  glVertex2i,5,-5
        invoke  glEnd

    .ENDIF

    invoke  glLoadIdentity
    fild    player.fx
    fadd    fpc(20.0f)
    fstp    tmp
    fild    player.fy
    fadd    fpc(70.0f)
    fstp    tmp2
    invoke  glTranslatef,tmp,tmp2,0
    invoke  glRotatef,player.spin,0,0,3F800000h
    invoke  glColor3f,0,3F800000h,0

    invoke  glBegin,GL_LINES
        invoke  glVertex2i,-5,-5
        invoke  glVertex2i,5,5
        invoke  glVertex2i,5,-5
        invoke  glVertex2i,-5,5
    invoke  glEnd

    fld     player.spin
    fmul    fpc(0.5f)
    fstp    tmp
    invoke  glRotatef,tmp,0,0,3F800000h
    invoke  glColor3f,0,3F400000h,0

    invoke  glBegin,GL_LINES
        invoke  glVertex2i,-7,0
        invoke  glVertex2i,7,0
        invoke  glVertex2i,0,-7
        invoke  glVertex2i,0,7
    invoke  glEnd

    mov     loop1,0
    mov     eax,stage
    xor     edx,edx
    mul     level

    .WHILE loop1 < eax
        invoke  glLoadIdentity
        mov     eax,loop1
        imul    eax,eax,sizeof enemy
        fild    enemy[eax].fx
        fadd    fpc(20.0f)
        fstp    tmp
        fild    enemy[eax].fy
        fadd    fpc(70.0f)
        fstp    tmp2
        invoke  glTranslatef,tmp,tmp2,0
        invoke  glColor3f,3F800000h,3F000000h,3F000000h

        invoke  glBegin,GL_LINES
            invoke  glVertex2i,0,-7
            invoke  glVertex2i,-7,0
            invoke  glVertex2i,-7,0
            invoke  glVertex2i,0,7
            invoke  glVertex2i,0,7
            invoke  glVertex2i,7,0
            invoke  glVertex2i,7,0
            invoke  glVertex2i,0,-7
        invoke  glEnd

        mov     eax,loop1
        imul    eax,eax,sizeof enemy
        invoke  glRotatef,enemy[eax].spin,0,0,3F800000h
        invoke  glColor3f,3F800000h,0,0

        invoke  glBegin,GL_LINES
            invoke  glVertex2i,-7,-7
            invoke  glVertex2i,7,7
            invoke  glVertex2i,-7,7
            invoke  glVertex2i,7,-7
        invoke  glEnd

        inc     loop1
        mov     eax,stage
        xor     edx,edx
        mul     level
    .ENDW

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
    invoke  UnregisterClass,addr szClass,hInst
    invoke  glDeleteLists,base,256
    .IF hDll != NULL
        invoke  FreeLibrary,hDll
    .ENDIF
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
    mov     edx,wrect.bottom
    mov     ecx,style
    sub     eax,wrect.left
    sub     edx,wrect.top
    or      ecx,WS_CLIPSIBLINGS or WS_CLIPCHILDREN
    invoke  CreateWindowEx,exstyle,addr szClass,titre,ecx,0,0,eax,edx,NULL,NULL,hInst,NULL
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
    mov     ecx,eax
    invoke  SetPixelFormat,hDc,ecx,addr pfd
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
        movzx   ecx,ax
        shr     eax,16
        invoke  ResizeGLScene,ecx,eax
        xor     eax,eax
        ret
    .endif
    invoke  DefWindowProc,hW,uMsg,wParam,lParam
    ret

WndProc ENDP


WinMain PROC hInstance:DWORD,lpCmdLine:DWORD,nCmdShow:DWORD
  LOCAL msg:MSG,done:DWORD,start:REAL4,tmp:DWORD
  LOCAL loop1:DWORD,loop2:DWORD

    mov     done,0

    invoke  MessageBox,NULL,addr szMsg1,addr szTitle,MB_YESNO or MB_ICONQUESTION
    .IF eax == IDYES
        mov     fullscreen,1
    .ELSE
        mov     fullscreen,0
    .ENDIF

    invoke  CreateGLWindow,addr szTitle,640,480,16
    .IF !eax
        xor     eax,eax
        ret
    .ENDIF

    invoke  ResetObjects
    invoke  TimerInit

    .WHILE !done
        invoke  PeekMessage,addr msg,NULL,0,0,PM_REMOVE
        .IF eax
            .IF msg.message == WM_QUIT
                mov     done,1
            .ELSE
                invoke  TranslateMessage,addr msg
                invoke  DispatchMessage,addr msg
            .ENDIF
        .ELSE
            invoke  TimerGetTime
            mov     start,eax
            invoke  DrawGLScene

            .IF (active && !eax) || keys[VK_ESCAPE]
                mov     done,1
            .ELSE
                invoke  SwapBuffers,hDc
            .ENDIF

@@:         mov     eax,adjust
            fld     steps[eax*4]
            fmul    fpc(2.0f)
            fadd    start
            fstp    tmp
            invoke  TimerGetTime
            fld     tmp
            mov     tmp,eax
            fld     tmp
            fcomip  st,st(1)
            fstp    tmp
            jc      @b

            .IF keys[VK_F1]
                    mov     keys[VK_F1],0
                    invoke  KillGLWindow
                    xor     fullscreen,1
                    invoke  CreateGLWindow,addr szTitle,640,480,16
                    .IF !eax
                        ret
                    .ENDIF
            .ENDIF

            .IF keys[VK_A] && !ap
                mov     ap,1
                xor     anti,1
            .ENDIF

            .IF !keys[VK_A]
                mov     ap,0
            .ENDIF

            .IF !gameover && active
                mov     loop1,0
                mov     eax,stage
                mul     level
                .WHILE loop1 < eax

                    mov     eax,loop1
                    imul    eax,eax,sizeof enemy
                    mov     esi,eax
                    mov     eax,enemy[esi].y
                    imul    eax,eax,40
                    mov     ecx,player.x
                    .IF (enemy[esi].x < ecx) && (enemy[esi].fy == eax)
                        inc     enemy[esi].x
                    .ENDIF

                    .IF (enemy[esi].x > ecx) && (enemy[esi].fy == eax)
                        dec     enemy[esi].x
                    .ENDIF

                    mov     eax,enemy[esi].x
                    imul    eax,eax,60
                    mov     ecx,player.y
                    .IF (enemy[esi].y < ecx) && (enemy[esi].fx == eax)
                        inc     enemy[esi].y
                    .ENDIF

                    .IF (enemy[esi].y > ecx) && (enemy[esi].fx == eax)
                        dec     enemy[esi].y
                    .ENDIF

                    mov     eax,3
                    sub     eax,level
                    .IF (delay > eax) && (hourglass.fx != 2)
                        mov     delay,0
                        mov     loop2,0
                        mov     eax,stage
                        xor     edx,edx
                        mul     level
                        .WHILE loop2 < eax

                            mov     eax,loop2
                            imul    eax,eax,sizeof enemy
                            mov     esi,eax
                            mov     eax,enemy[esi].x
                            imul    eax,eax,60
                            .IF enemy[esi].fx < eax
                                mov     ecx,adjust
                                mov     ecx,steps[ecx*4]
                                add     enemy[esi].fx,ecx
                                mov     tmp,ecx
                                fld     enemy[esi].spin
                                fiadd   tmp
                                fstp    enemy[esi].spin
                            .ENDIF

                            .IF enemy[esi].fx > eax
                                mov     ecx,adjust
                                mov     ecx,steps[ecx*4]
                                sub     enemy[esi].fx,ecx
                                mov     tmp,ecx
                                fld     enemy[esi].spin
                                fisub   tmp
                                fstp    enemy[esi].spin
                            .ENDIF

                            mov     eax,enemy[esi].y
                            imul    eax,eax,40
                            .IF enemy[esi].fy < eax
                                mov     ecx,adjust
                                mov     ecx,steps[ecx*4]
                                add     enemy[esi].fy,ecx
                                mov     tmp,ecx
                                fld     enemy[esi].spin
                                fiadd   tmp
                                fstp    enemy[esi].spin
                            .ENDIF

                            .IF enemy[esi].fy > eax
                                mov     ecx,adjust
                                mov     ecx,steps[ecx*4]
                                sub     enemy[esi].fy,ecx
                                mov     tmp,ecx
                                fld     enemy[esi].spin
                                fisub   tmp
                                fstp    enemy[esi].spin
                            .ENDIF

                            inc     loop2
                            mov     eax,stage
                            mul     level
                        .ENDW
                    .ENDIF

                    mov     eax,loop1
                    imul    eax,eax,sizeof enemy
                    mov     ecx,enemy[eax].fy
                    mov     eax,enemy[eax].fx
                    .IF (eax == player.fx) && (ecx == player.fy)
                        dec     lives
                        .IF lives == 0
                            mov     gameover,1
                        .ENDIF
                        invoke  ResetObjects
                        invoke  PlaySound,addr szSnd1,NULL,SND_SYNC
                    .ENDIF

                    inc     loop1
                    mov     eax,stage
                    mul     level
                .ENDW

                mov     eax,player.y
                imul    eax,eax,40
                mov     ecx,eax
                mov     eax,player.x
                imul    eax,eax,60
                .IF keys[VK_RIGHT] && (player.x < 10) && (player.fx == eax) && (player.fy == ecx)
                    mov     eax,player.x
                    imul    eax,eax,11
                    add     eax,player.y
                    mov     hline[eax],1
                    inc     player.x
                .ENDIF

                mov     eax,player.y
                imul    eax,eax,40
                mov     ecx,eax
                mov     eax,player.x
                imul    eax,eax,60
                .IF keys[VK_LEFT] && (player.x > 0) && (player.fx == eax) && (player.fy == ecx)
                    dec     player.x
                    mov     eax,player.x
                    imul    eax,eax,11
                    add     eax,player.y
                    mov     hline[eax],1
                .ENDIF

                mov     eax,player.y
                imul    eax,eax,40
                mov     ecx,eax
                mov     eax,player.x
                imul    eax,eax,60
                .IF keys[VK_DOWN] && (player.y < 10) && (player.fx == eax) && (player.fy == ecx)
                    mov     eax,player.x
                    imul    eax,eax,10
                    add     eax,player.y
                    mov     vline[eax],1
                    inc     player.y
                .ENDIF

                mov     eax,player.y
                imul    eax,eax,40
                mov     ecx,eax
                mov     eax,player.x
                imul    eax,eax,60
                .IF keys[VK_UP] && (player.y > 0) && (player.fx == eax) && (player.fy == ecx)
                    dec     player.y
                    mov     eax,player.x
                    imul    eax,eax,10
                    add     eax,player.y
                    mov     vline[eax],1
                .ENDIF

                mov     eax,player.x
                imul    eax,eax,60
                .IF player.fx < eax
                    mov     eax,adjust
                    mov     eax,steps[eax*4]
                    add     player.fx,eax
                .ENDIF

                mov     eax,player.x
                imul    eax,eax,60
                .IF player.fx > eax
                    mov     eax,adjust
                    mov     eax,steps[eax*4]
                    sub     player.fx,eax
                .ENDIF

                mov     eax,player.y
                imul    eax,eax,40
                .IF player.fy < eax
                    mov     eax,adjust
                    mov     eax,steps[eax*4]
                    add     player.fy,eax
                .ENDIF

                mov     eax,player.y
                imul    eax,eax,40
                .IF player.fy > eax
                    mov     eax,adjust
                    mov     eax,steps[eax*4]
                    sub     player.fy,eax
                .ENDIF

            .ELSE

                .IF keys[VK_SPACE]
                    mov     gameover,0
                    mov     filled,1
                    mov     level,1
                    mov     level2,1
                    mov     stage,0
                    mov     lives,5
                .ENDIF

            .ENDIF

            .IF filled
                invoke  PlaySound,addr szSnd2,NULL,SND_SYNC
                inc     stage
                .IF stage > 3
                    mov     stage,1
                    inc     level
                    inc     level2
                    .IF level > 3
                        mov     level,3
                        inc     lives
                        .IF lives > 5
                            mov     lives,5
                        .ENDIF
                    .ENDIF
                .ENDIF

                invoke  ResetObjects
                mov     loop1,0
                .WHILE loop1 < 11
                    mov     loop2,0
                    .WHILE loop2 < 11

                        .IF loop1 < 10
                            mov     eax,loop1
                            imul    eax,eax,11
                            add     eax,loop2
                            mov     hline[eax],0
                        .ENDIF

                        .IF loop2 < 10
                            mov     eax,loop1
                            imul    eax,eax,10
                            add     eax,loop2
                            mov     vline[eax],0
                        .ENDIF

                        inc     loop2
                    .ENDW

                    inc     loop1
                .ENDW

            .ENDIF

            mov     eax,hourglass.y
            imul    eax,eax,40
            mov     ecx,eax
            mov     eax,hourglass.x
            imul    eax,eax,60
            .IF (player.fx == eax) && (player.fy == ecx) && (hourglass.fx == 1)
                invoke  PlaySound,addr szSnd3,NULL,SND_ASYNC or SND_LOOP
                mov     hourglass.fx,2
                mov     hourglass.fy,0
            .ENDIF

            mov     eax,adjust
            mov     ecx,steps[eax*4]
            mov     tmp,ecx
            fild    tmp
            fmul    fpc(0.5f)
            fadd    player.spin
            fst     player.spin
            fld     fpc(360.0f)
            fcomip  st,st(1)
            setc    al
            .IF al
                fsub    fpc(360.0f)
                fstp    player.spin
            .ELSE
                fstp    tmp
            .ENDIF

            fldz
            mov     tmp,ecx
            fild    tmp
            fmul    fpc(0.25f)
            fld     hourglass.spin
            fsubrp  st(1),st
            fst     hourglass.spin
            fcomi   st,st(1)
            setc    al
            .IF al
                fadd    fpc(360.0f)
                fstp    hourglass.spin
                fstp    tmp
            .ELSE
                fstp    tmp
                fstp    tmp
            .ENDIF

            add     hourglass.fy,ecx
			xor		edx,edx
            mov     eax,6000
            div     level
            mov     tmp,eax
            .IF (hourglass.fx == 0) && (hourglass.fy > eax)
                invoke  PlaySound,addr szSnd4,NULL,SND_ASYNC
                invoke  nrandom,10
                inc     eax
                mov     hourglass.x,eax
                invoke  nrandom,11
                mov     hourglass.y,eax
                mov     hourglass.fx,1
                mov     hourglass.fy,0
            .ENDIF

            mov     eax,tmp
            .IF (hourglass.fx == 1) && (hourglass.fy > eax)
                mov     hourglass.fx,0
                mov     hourglass.fy,0
            .ENDIF

            mov     eax,level
            imul    eax,eax,500
            add     eax,500
            .IF (hourglass.fx == 2) && (hourglass.fy > eax)
                invoke  PlaySound,NULL,NULL,0
                mov     hourglass.fx,0
                mov     hourglass.fy,0
            .ENDIF

            inc     delay

        .ENDIF
    .ENDW

    invoke  KillGLWindow
    mov     eax,msg.wParam
    ret

WinMain ENDP


nrandom PROC _base:DWORD

;##########################################################################
;
;                     Park Miller random number algorithm.
;
;                      Written by Jaymeson Trudgen (NaN)
;                   Optimized by Rickey Bowers Jr. (bitRAKE)
;
;##########################################################################


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
    div _base

    mov eax,edx
    ret

nrandom ENDP


strlen PROC cstr:DWORD

    mov     ecx,cstr
    xor     eax,eax
    .WHILE byte ptr [ecx] != 0
        inc     ecx
        inc     eax
    .ENDW
    ret

strlen ENDP


END Start