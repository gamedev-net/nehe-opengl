.586
.model flat,stdcall
option casemap:none


include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc
include \masm32\include\opengl32.inc
include \masm32\include\glu32.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\opengl32.lib
includelib \masm32\lib\glu32.lib


ResizeGLScene   PROTO :DWORD,:DWORD
InitGL          PROTO
DrawGLScene     PROTO
KillGLWindow    PROTO
CreateGLWindow  PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc         PROTO :DWORD,:DWORD,:DWORD,:DWORD
WinMain         PROTO :DWORD,:DWORD,:DWORD
LoadGLTexture   PROTO
glDrawCube      PROTO


DM_BITSPERPEL       equ     00040000h
DM_PELSWIDTH        equ     00080000h
DM_PELSHEIGHT       equ     00100000h
PFD_MAIN_PLANE      equ     00000000h
PFD_TYPE_RGBA       equ     00000000h
PFD_DOUBLEBUFFER    equ     00000001h
PFD_DRAW_TO_WINDOW  equ     00000004h
PFD_SUPPORT_OPENGL  equ     00000020h


fpc MACRO val:REQ       ; this is BitRAKE's fpc macro, thanks a lot to him
	LOCAL w,x,y,z,zz,ww

	;; split type and value, defaulting to REAL4
	z INSTR 1,<&val>,<! >
	IF z EQ 0
		y TEXTEQU <REAL4>
		x TEXTEQU <&val>
	ELSE
		y TEXTEQU @SubStr(<&val>,1,z-1)	;; Type
		x TEXTEQU @SubStr(<&val>,z+1,)	;; Value
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
		CONST$fpu SEGMENT
			ww y x
		CONST$fpu ENDS
	ENDIF
	EXITM ww
ENDM

ZeroMem MACRO dest,count
      mov        ecx,count
	lea        edi,dest
	shr        ecx,2
	xor        eax,eax
	rep        stosd
	mov        ecx,count
	and        ecx,3
	rep        stosb
ENDM