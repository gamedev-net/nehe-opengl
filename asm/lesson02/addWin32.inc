;
; some additional definition to Borland's sample file, by FooLman/UnitedForce (c) 2000
;
IDI_WINLOGO = 32517
MB_ICONINFORMATION	equ <MB_ICONASTERISK>
MB_ICONSTOP		equ <MB_ICONHAND>

SC_SIZE         =0F000h
SC_MOVE         =0F010h
SC_MINIMIZE     =0F020h
SC_MAXIMIZE     =0F030h
SC_NEXTWINDOW   =0F040h
SC_PREVWINDOW   =0F050h
SC_CLOSE        =0F060h
SC_VSCROLL      =0F070h
SC_HSCROLL      =0F080h
SC_MOUSEMENU    =0F090h
SC_KEYMENU      =0F100h
SC_ARRANGE      =0F110h
SC_RESTORE      =0F120h
SC_TASKLIST     =0F130h
SC_SCREENSAVE   =0F140h
SC_HOTKEY       =0F150h
SC_DEFAULT      =0F160h
SC_MONITORPOWER =0F170h
SC_CONTEXTHELP  =0F180h
SC_SEPARATOR    =0F00Fh

WS_EX_DLGMODALFRAME     =00000001h
WS_EX_NOPARENTNOTIFY    =00000004h
WS_EX_TOPMOST           =00000008h
WS_EX_ACCEPTFILES       =00000010h
WS_EX_TRANSPARENT       =00000020h
WS_EX_MDICHILD          =00000040h
WS_EX_TOOLWINDOW        =00000080h
WS_EX_WINDOWEDGE        =00000100h
WS_EX_CLIENTEDGE        =00000200h
WS_EX_CONTEXTHELP       =00000400h

WS_EX_RIGHT             =00001000h
WS_EX_LEFT              =00000000h
WS_EX_RTLREADING        =00002000h
WS_EX_LTRREADING        =00000000h
WS_EX_LEFTSCROLLBAR     =00004000h
WS_EX_RIGHTSCROLLBAR    =00000000h

WS_EX_CONTROLPARENT     =00010000h
WS_EX_STATICEDGE        =00020000h
WS_EX_APPWINDOW         =00040000h

WS_EX_OVERLAPPEDWINDOW =(WS_EX_WINDOWEDGE or WS_EX_CLIENTEDGE)
WS_EX_PALETTEWINDOW    =(WS_EX_WINDOWEDGE or WS_EX_TOOLWINDOW or WS_EX_TOPMOST)

PFD_TYPE_RGBA			= 0
PFD_TYPE_COLORINDEX		= 1

PFD_MAIN_PLANE			= 0
PFD_OVERLAY_PLANE		= 1
PFD_UNDERLAY_PLANE		= (-1)

PFD_DOUBLEBUFFER		= 00000001h
PFD_STEREO			= 00000002h
PFD_DRAW_TO_WINDOW		= 00000004h
PFD_DRAW_TO_BITMAP		= 00000008h
PFD_SUPPORT_GDI			= 00000010h
PFD_SUPPORT_OPENGL		= 00000020h
PFD_GENERIC_FORMAT		= 00000040h
PFD_NEED_PALETTE		= 00000080h
PFD_NEED_SYSTEM_PALETTE		= 00000100h
PFD_SWAP_EXCHANGE		= 00000200h
PFD_SWAP_COPY			= 00000400h
PFD_SWAP_LAYER_BUFFERS		= 00000800h
PFD_GENERIC_ACCELERATED		= 00001000h
PFD_SUPPORT_DIRECTDRAW		= 00002000h

PFD_DEPTH_DONTCARE		= 20000000h
PFD_DOUBLEBUFFER_DONTCARE	= 40000000h
PFD_STEREO_DONTCARE		= 80000000h

DM_ORIENTATION      = 00000001h
DM_PAPERSIZE        = 00000002h
DM_PAPERLENGTH      = 00000004h
DM_PAPERWIDTH       = 00000008h
DM_SCALE            = 00000010h
DM_POSITION         = 00000020h
DM_NUP              = 00000040h
DM_COPIES           = 00000100h
DM_DEFAULTSOURCE    = 00000200h
DM_PRINTQUALITY     = 00000400h
DM_COLOR            = 00000800h
DM_DUPLEX           = 00001000h
DM_YRESOLUTION      = 00002000h
DM_TTOPTION         = 00004000h
DM_COLLATE          = 00008000h
DM_FORMNAME         = 00010000h
DM_LOGPIXELS        = 00020000h
DM_BITSPERPEL       = 00040000h
DM_PELSWIDTH        = 00080000h
DM_PELSHEIGHT       = 00100000h
DM_DISPLAYFLAGS     = 00200000h
DM_DISPLAYFREQUENCY = 00400000h
DM_ICMMETHOD        = 00800000h
DM_ICMINTENT        = 01000000h
DM_MEDIATYPE        = 02000000h
DM_DITHERTYPE       = 04000000h
DM_PANNINGWIDTH     = 08000000h
DM_PANNINGHEIGHT    = 10000000h
DMORIENT_PORTRAIT   = 1
DMORIENT_LANDSCAPE  = 2

CDS_UPDATEREGISTRY  = 00000001h
CDS_TEST            = 00000002h
CDS_FULLSCREEN      = 00000004h
CDS_GLOBAL          = 00000008h
CDS_SET_PRIMARY     = 00000010h
CDS_VIDEOPARAMETERS = 00000020h
CDS_RESET           = 40000000h
CDS_NORESET         = 10000000h

KF_EXTENDED         = 0100h
KF_DLGMODE          = 0800h
KF_MENUMODE         = 1000h
KF_ALTDOWN          = 2000h
KF_REPEAT           = 4000h
KF_UP               = 8000h

VK_LBUTTON        = 01h
VK_RBUTTON        = 02h
VK_CANCEL         = 03h
VK_MBUTTON        = 04h    ; NOT contiguous with L & RBUTTON 

VK_BACK           = 08h
VK_TAB            = 09h

VK_CLEAR          = 0Ch
VK_RETURN         = 0Dh

VK_SHIFT          = 10h
VK_CONTROL        = 11h
VK_MENU           = 12h
VK_PAUSE          = 13h
VK_CAPITAL        = 14h

VK_ESCAPE         = 1Bh

VK_SPACE          = 20h
VK_PRIOR          = 21h
VK_NEXT           = 22h
VK_END            = 23h
VK_HOME           = 24h
VK_LEFT           = 25h
VK_UP             = 26h
VK_RIGHT          = 27h
VK_DOWN           = 28h
VK_SELECT         = 29h
VK_PRINT          = 2Ah
VK_EXECUTE        = 2Bh
VK_SNAPSHOT       = 2Ch
VK_INSERT         = 2Dh
VK_DELETE         = 2Eh
VK_HELP           = 2Fh

; VK_0 thru VK_9 are the same as ASCII '0' thru '9' (0x30 - 0x39) 
; VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' (0x41 - 0x5A) 

VK_LWIN           = 5Bh
VK_RWIN           = 5Ch
VK_APPS           = 5Dh

VK_NUMPAD0        = 60h
VK_NUMPAD1        = 61h
VK_NUMPAD2        = 62h
VK_NUMPAD3        = 63h
VK_NUMPAD4        = 64h
VK_NUMPAD5        = 65h
VK_NUMPAD6        = 66h
VK_NUMPAD7        = 67h
VK_NUMPAD8        = 68h
VK_NUMPAD9        = 69h
VK_MULTIPLY       = 6Ah
VK_ADD            = 6Bh
VK_SEPARATOR      = 6Ch
VK_SUBTRACT       = 6Dh
VK_DECIMAL        = 6Eh
VK_DIVIDE         = 6Fh
VK_F1             = 70h
VK_F2             = 71h
VK_F3             = 72h
VK_F4             = 73h
VK_F5             = 74h
VK_F6             = 75h
VK_F7             = 76h
VK_F8             = 77h
VK_F9             = 78h
VK_F10            = 79h
VK_F11            = 7Ah
VK_F12            = 7Bh
VK_F13            = 7Ch
VK_F14            = 7Dh
VK_F15            = 7Eh
VK_F16            = 7Fh
VK_F17            = 80h
VK_F18            = 81h
VK_F19            = 82h
VK_F20            = 83h
VK_F21            = 84h
VK_F22            = 85h
VK_F23            = 86h
VK_F24            = 87h

VK_NUMLOCK        = 90h
VK_SCROLL         = 91h

; VK_L* & VK_R* - left and right Alt, Ctrl and Shift virtual keys.
; Used only as parameters to GetAsyncKeyState() and GetKeyState().
; No other API or message will distinguish left and right keys in this way.

VK_LSHIFT         =0A0h
VK_RSHIFT         =0A1h
VK_LCONTROL       =0A2h
VK_RCONTROL       =0A3h
VK_LMENU          =0A4h
VK_RMENU          =0A5h

VK_PROCESSKEY     =0E5h

VK_ATTN           =0F6h
VK_CRSEL          =0F7h
VK_EXSEL          =0F8h
VK_EREOF          =0F9h
VK_PLAY           =0FAh
VK_ZOOM           =0FBh
VK_NONAME         =0FCh
VK_PA1            =0FDh
VK_OEM_CLEAR      =0FEh


PIXELFORMATDESCRIPTOR struc
  nSize WORD ?
  nVersion WORD ?
  dwFlags DWORD ?
  iPixelType BYTE ?
  cColorBits BYTE ?
  cRedBits BYTE ?
  cRedShift BYTE ?
  cGreenBits BYTE ?
  cGreenShift BYTE ?
  cBlueBits BYTE ?
  cBlueShift BYTE ?
  cAlphaBits BYTE ?
  cAlphaShift BYTE ?
  cAccumBits BYTE ?
  cAccumRedBits BYTE ?
  cAccumGreenBits BYTE ?
  cAccumBlueBits BYTE ?
  cAccumAlphaBits BYTE ?
  cDepthBits  BYTE ?
  cStencilBits BYTE ?
  cAuxBUffers BYTE ?
  iLayerType BYTE ?
  bReserved BYTE ?
  dwLayerMask DWORD ?
  dwVisibleMask DWORD ?
  dwDamegeMask DWORD ? 
PIXELFORMATDESCRIPTOR ends
CCHDEVICENAME = 32
CCHFORMNAME = 32
DEVMODE struc
  dmDeviceName db CCHDEVICENAME dup (?)
  dmSpecVersion dw ?
  dmDriverVersion dw ?
  dmSize dw ?
  dmDriverExtra dw ? 	 
  dmFields dd ?
  dmPosition dd 2 dup (?)
  dmScale dw ?
  dmCopies dw ?
  dmDefaultSource dw ?
  dmPrintQuality dw ?
  dmColor dw ?
  dmDuplex dw ?
  dmYResolution dw ?
  dmTTOption dw ?
  dmCollate dw ?
  dmFormName db CCHFORMNAME dup (?)
  dmLogPixels dw ?
  dmBitsPerPel dd ?
  dmPelsWidth dd ?
  dmPelsHeight dd ?
  dmDisplayFlags dd ?
  dmDisplayFrequency dd ?
  dmICMMethod dd ?
  dmICMIntent dd ?
  dmMediaType dd ?
  dmDitherType dd ?
  dmReserved dd 2 dup (?)
DEVMODE ends  
