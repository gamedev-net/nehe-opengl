; Attempt at NeHe's tutorial 16 : Fog.
;
; Author: Greg Helps [x86@ozducati.com]
; Date: July 10 2003
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
include .\gl.def
include .\glu.def
include .\winextra.def

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\opengl32.lib
includelib c:\masm32\lib\glu32.lib


; Missing from include files * * * * * * * * * * * * * * * * * * * * * 
DM_BITSPERPEL       = 00040000h
DM_PELSWIDTH        = 00080000h
DM_PELSHEIGHT       = 00100000h


; PROTOTYPES * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
WinMain         PROTO :HWND, :UINT, :WPARAM, :LPARAM
CreateGLWindow  PROTO :DWORD, :DWORD, :DWORD, :UINT, :BOOL
WndProc         PROTO :HWND, :UINT, :WPARAM, :LPARAM
KillGLWindow    PROTO
ReSizeGLScene   PROTO :GLsizei, :GLsizei
InitGL          PROTO
DrawGLScene     PROTO
LoadGLTextures  PROTO 


; STRUCTURES * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
; Define BMP structure
; I use this to reference width/height & data from the BMP file
BMPFILE STRUCT
    header BITMAPFILEHEADER <>
    info BITMAPINFOHEADER <>
    data DWORD ?
BMPFILE ENDS


; MACROS * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
; This macro is defined incorrectly in the includes. I fix him here
; rather than modify the include file.
; (GLenum pname, GLfloat param)
_glFogf MACRO pname,param
 gl_fpush param
 push pname
 call glFogf
ENDM

; fpc macro allows constants to be used with floating point operations.
; Authored by bitRAKE from Win32ASM board <http://board.win32asmcommunity.net>
; Great resource for assembler hackers
fpc MACRO val:REQ
    LOCAL w,x,y,z,zz,ww

    ;; split type and value, defaulting to REAL4
    z INSTR 1,<&val>,<! >
    IF z EQ 0
        y TEXTEQU <REAL4>
        x TEXTEQU <&val>
    ELSE
        y TEXTEQU @SubStr(<&val>,1,z-1) ;; Type
        x TEXTEQU @SubStr(<&val>,z+1,)  ;; Value
    ENDIF

    ;; replace . with _
    z INSTR 1,x,<!.>
    IF z EQ 0
        w TEXTEQU x
        x CATSTR x,<.0> ;; prevent error message
    ELSE
        w CATSTR @SubStr(%x,1,z-1),<_>,@SubStr(%x,z+1,)
    ENDIF

    ;; replace - with _
    zz INSTR 1,w,<!->
    IF zz EQ 0
        ww TEXTEQU w
    ELSE
        ww CATSTR @SubStr(%w,1,zz-1),<_>,@SubStr(%w,zz+1,)
    ENDIF

    ;; figure out global name for constant
    z SIZESTR y ;; use last char for size distiction
    ww CATSTR <__>,ww,<r>,@SubStr(%y,z,1)

    IF (OPATTR(ww)) EQ 0 ;; not defined
        CONST SEGMENT
            ww y x
        CONST ENDS
    ENDIF
    EXITM ww
ENDM


; INITIALISED DATA * * * * * * * * * * * * * * * * * * * * * * * * * * 
.data
LightAmbient                    GLfloat 0.5f,0.5f,0.5f,1.0f
LightDiffuse                    GLfloat 1.0f,1.0f,1.0f,1.0f
LightPosition                   GLfloat 0.0f,0.0f,2.0f,1.0f
fogcolor                        GLfloat 0.5f, 0.5f, 0.5f, 1.0f  ; Fog color
xrot                            GLfloat 0.0f    ; X Rotation
yrot                            GLfloat 0.0f    ; Y Rotation
xspeed                          GLfloat 0.0f    ; X Rotation speed
yspeed                          GLfloat 0.0f    ; Y Rotation speed
z                               REAL4   -5.0f   ; Depth into the screen
fogmode                         GLuint  GL_EXP, GL_EXP2, GL_LINEAR  ; Storage for three types of fog
fogfilter                       GLuint  0   ; Which fog to use
;
txt_Query_Fullscn               db      "Do you want to run in fullscreen?",0
txt_Title_Fullscn               db      "Graphics mode",0
txt_Window_Title                db      "NeHe's OpenGL Fog Tutorial",0
txt_OpenGL                      db      "OpenGL",0
txt_WC_Failed                   db      "Failed to registed window class",0
txt_GL_Context_Failed           db      "Failed to create a GL device context",0
txt_RC_Failed                   db      "Failed to create a GL rendering context",0
txt_PixelFormat_Failed          db      "Failed to find suitable PixelFormat",0
txt_ActivateRC_Failed           db      "Failed to activate GL rendering context",0
txt_GLInit_Failed               db      "Initialisation failed",0
txt_SetPixelFormat_Failed       db      "Failed to set PixelFormat",0
txt_WindowCreateError           db      "Window creation error",0
txt_Error                       db      "Error",0
;
txt_Crate_BMP                   db      "Crate.BMP",0


; UNINITIALISED DATA * * * * * * * * * * * * * * * * * * * * * * * * * 
.data?
hRC             HGLRC       ?   ;
hDC             HDC         ?   ; Open GL window structures
hWnd            HWND        ?   ;
hInstance       HINSTANCE   ?   ;

keys            db 256 dup (?)  ; keypress status
fullscreen      BOOL        ?   ; fullscreen toggle
active          BOOL        ?   ; window active toggle/status

texture         GLuint      3 dup (?)   ; GL Texture handle x 3
light           GLuint      ?   ; Lighting on/off
filter          GLuint      ?   ; Which filter to use
BMPTexture      DWORD       ?   ; Texture pointer

gp              BOOL        ?   ; G Pressed?
lp              BOOL        ?   ; L Pressed?
fp              BOOL        ?   ; F Pressed?

; BUGS BEGIN HERE * * * * * * * * * * * * * * * * * * * * * * * * * * 
.code

start:
invoke GetModuleHandle,0
mov hInstance, eax
invoke WinMain,hInstance,0,0,0
invoke ExitProcess, eax
;** END

; PROC WinMain * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
WinMain proc hInst:HWND, hPrevInst:UINT, CmdLine:WPARAM, CmdShow:LPARAM
    LOCAL msg:MSG, done:UINT

    ; Check if we should start in full screen
    invoke MessageBox,NULL,addr txt_Query_Fullscn,addr txt_Title_Fullscn,MB_YESNO or MB_ICONQUESTION

    .IF eax == IDNO
        mov fullscreen,FALSE
    .ELSE
        mov fullscreen,TRUE
    .ENDIF

    invoke CreateGLWindow,addr txt_Window_Title,640,480,16,fullscreen
    .IF !eax
        ret
    .ENDIF

    mov done,FALSE

    .WHILE !done
        invoke PeekMessage,addr msg,NULL,0,0,PM_REMOVE
        .IF eax
            .IF msg.message == WM_QUIT
                mov done,TRUE
            .ELSE
                invoke TranslateMessage,addr msg
                invoke DispatchMessage,addr msg
            .ENDIF
        .ELSE
            invoke DrawGLScene
            .IF ((active) && (!eax)) || (keys[VK_ESCAPE])
                mov done, 1
            .ELSE
                invoke SwapBuffers,hDC
            .ENDIF
            
            .IF keys[VK_F1]
                mov keys[VK_F1],FALSE
                invoke KillGLWindow
                xor fullscreen, 1
                invoke CreateGLWindow,addr txt_Window_Title,640,480,16,fullscreen
                .IF !eax
                    mov eax,FALSE
                .ENDIF
            .ENDIF
            .IF keys['L'] && !lp
                mov lp, TRUE
                xor light, 1
                .IF light == FALSE
                    invoke glDisable, GL_LIGHTING
                .ELSE
                    invoke glEnable, GL_LIGHTING
                .ENDIF
            .ENDIF
            .IF !keys['L']
                mov lp, FALSE
            .ENDIF
            
            .IF keys['F'] && !fp
                mov fp, TRUE
                inc filter
                .IF filter > 2
                    mov filter, 0
                .ENDIF
            .ENDIF
            .IF !keys['F']
                mov fp, FALSE
            .ENDIF
            
            .IF keys['G'] && !gp
                mov gp, TRUE
                inc fogfilter
                .IF fogfilter > 2
                    mov fogfilter, 0
                .ENDIF
                mov eax, fogfilter
                shl eax, 2  ; mul eax, sizeof(GLuint)
                invoke glFogi, GL_FOG_MODE, fogmode[eax]
            .ENDIF
            .IF !keys['G']
                mov gp, FALSE
            .ENDIF
            
            .IF keys[VK_PRIOR] == TRUE
                fld z
                fsub fpc(0.02)
                fstp z
            .ENDIF
            
            .IF keys[VK_NEXT] == TRUE
                fld z
                fadd fpc(0.02)
                fstp z
            .ENDIF
            
            .IF keys[VK_UP] == TRUE
                fld xspeed
                fsub fpc(0.01)
                fstp xspeed
            .ENDIF
            
            .IF keys[VK_DOWN] == TRUE
                fld xspeed
                fadd fpc(0.01)
                fstp xspeed
            .ENDIF
            
            .IF keys[VK_RIGHT] == TRUE
                fld yspeed
                fadd fpc(0.01)
                fstp yspeed
            .ENDIF
            
            .IF keys[VK_LEFT] == TRUE
                fld yspeed
                fsub fpc(0.01)
                fstp yspeed
            .ENDIF          
        .ENDIF
    .ENDW
    invoke KillGLWindow

    mov eax,msg.wParam
    ret
WinMain endp


; PROC InitGL * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
InitGL proc
    
    invoke LoadGLTextures   ; Load textures
    .IF (eax == NULL)       ; Exit if the textures failed to load
        ret
    .ENDIF
    
    invoke glEnable, GL_TEXTURE_2D                              ; Enable texture mapping
    invoke glShadeModel,GL_SMOOTH                               ; Enable smooth shading
    _glClearColor 0.5f, 0.5f, 0.5f, 1.0f                        ; Clear to the color of the fog
    _glClearDepth 1.0f                                          ; Depth buffer setup
    invoke glEnable, GL_DEPTH_TEST                              ; Enable depth testing
    invoke glDepthFunc, GL_LEQUAL                               ; Set type of depth test
    invoke glHint,GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST      ; Set nice perspective calculations
    
    invoke glLightfv,GL_LIGHT1, GL_AMBIENT, addr LightAmbient   ; Setup ambient light
    invoke glLightfv,GL_LIGHT1, GL_DIFFUSE, addr LightDiffuse   ; Setup diffuse light
    invoke glLightfv,GL_LIGHT1, GL_POSITION, addr LightPosition ; Position the light
    invoke glEnable,GL_LIGHT1                                   ; Enable light one
    
    mov eax, fogfilter
    shl eax, 2  ; mul eax, sizeof(GLuint)
    invoke glFogi, GL_FOG_MODE, fogmode[eax]    ; Fog mode
    invoke glFogfv, GL_FOG_COLOR, addr fogcolor ; Set fog color
    _glFogf GL_FOG_DENSITY, 0.35f               ; How dense will the fog be
    invoke glHint, GL_FOG_HINT, GL_DONT_CARE    ; Fog hint value
    _glFogf GL_FOG_START, 1.0f                  ; Fog start depth
    _glFogf GL_FOG_END, 5.0f                    ; Fog End depth
    invoke glEnable, GL_FOG                     ; Enable fog
    
    mov eax, 1          
    ret
InitGL endp


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
        
    .IF eax==INVALID_HANDLE_VALUE   ; get outta here if we failed to open the file
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
    .IF (eax != FileSize)   ; Free memory & exit if the readfile failed
        invoke GlobalFree, BMP
        xor eax, eax
        ret
    .ENDIF
    
    ; BMP file has the colours as BGR instead of RGB. Swap the R & B colours.
    mov ebx, BMP    ; Pointer to start of BMPFILE structure 
    mov eax, (BMPFILE PTR [ebx]).info.biWidth   ; eax = BMPwidth * BMPheight
    mul (BMPFILE PTR [ebx]).info.biHeight
    lea ebx, (BMPFILE PTR [ebx]).data           ; ebx = address of BMP data, ie: past the BMP header
    
    mov ecx, eax        ; Loop thru BMP data, swapping R & G colours
@@: mov al, [ebx]       ; al = Red value
    xchg al, [ebx+2]    ; Swap Green value with al, and al value with Green
    mov [ebx], al       ; Write back Green value
    add ebx, 3          ; Move to next block
    loop @B
    
    ; Return a handle to the BMP
    mov eax, BMP
    ret
LoadBMP endp


; PROC LoadGLTextures * * * * * * * * * * * * * * * * * * * * * * * * 
LoadGLTextures proc
    invoke LoadBMP, addr txt_Crate_BMP  ; Load the BMP from disk & return a pointer to a BMPFILE structure
    mov BMPTexture, eax
    .IF (eax == NULL)   ; Quit if file load failed
        ret
    .ENDIF

    invoke glGenTextures, 3, addr texture   ; Create three textures
    
    ; Create Nearest Filtered Texture
    invoke glBindTexture, GL_TEXTURE_2D, texture[0]
    mov eax, BMPTexture
    lea ebx, (BMPFILE PTR [eax]).data
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, (BMPFILE PTR [eax]).info.biWidth, (BMPFILE PTR [eax]).info.biHeight,\
        0, GL_RGB, GL_UNSIGNED_BYTE, ebx
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST
    
    ; Create Linear Filtered Texture
    invoke glBindTexture, GL_TEXTURE_2D, texture[1]
    mov eax, BMPTexture
    lea ebx, (BMPFILE PTR [eax]).data
    invoke glTexImage2D, GL_TEXTURE_2D, 0, 3, (BMPFILE PTR [eax]).info.biWidth, (BMPFILE PTR [eax]).info.biHeight,\
        0, GL_RGB, GL_UNSIGNED_BYTE, ebx
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR

    ; Create MipMapped Texture
    invoke glBindTexture, GL_TEXTURE_2D, texture[2]
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
    invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST
    mov eax, BMPTexture
    lea ebx, (BMPFILE PTR [eax]).data
    invoke gluBuild2DMipmaps, GL_TEXTURE_2D, 3, (BMPFILE PTR [eax]).info.biWidth, (BMPFILE PTR [eax]).info.biHeight,\
        GL_RGB, GL_UNSIGNED_BYTE, ebx

    
    .IF (BMPTexture != NULL)    ; Remember to free the memory for the BMPFILE allocated in LoadBMP
        invoke GlobalFree, BMPTexture
        mov eax, 1
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
    invoke glClear,GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
    invoke glLoadIdentity
    _glTranslatef 0.0f, 0.0f, z
    
    _glRotatef xrot, 1.0f, 0.0f, 0.0f
    _glRotatef yrot, 0.0f, 1.0f, 0.0f
    
    mov eax, filter
    invoke glBindTexture, GL_TEXTURE_2D, texture[eax]
    
    invoke glBegin, GL_QUADS
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
    _glVertex3f  1.0f,1.0f,-1.0f
    _glTexCoord2f 0.0f,1.0f
    _glVertex3f  1.0f,1.0f, 1.0f
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

    ; Rotation
    fld xrot    ; xrot += xspeed
    fadd xspeed
    fstp xrot
    
    fld yrot    ; yrot += yspeed
    fadd yspeed
    fstp yrot
    
    mov eax, 1
    ret
DrawGLScene endp

end start
 
