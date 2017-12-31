**********************************************************************************
*** This package contains NVIDIA Cg Toolkit 1.1 Release for Borland C++Builder ***
**********************************************************************************

Package compatible with Borland C++Builder 5 and 6.

Original files can de downloaded from:
  You can download NVIDIA Cg toolkit from: http://developer.nvidia.com/view.asp?IO=cg_toolkit

This package and additional Cg resources for Borland compilers can be downloaded from: 
  http://clootie.narod.ru/Projects/nvidia_cg.html

******************************************************************************* 

Directories contents:
1) LIB - NVIDIA Cg libraries for C++Builder 
2) DLL - cgD3D_ab.dll - selfmade DLL - contains DirectX8 management classes - used in now deprecated API.
3) Include - specially modified for C++Builder include files. You will need to overwite existing files in NVIDIA Cg toolkit include directory with these.

To compiler and run Cg enabled programs you should download and install NVIDIA Cg Toolkit.

******************************************************************************* 
!!! WARNING !!! 
Cg toolkit programming interface has been changed by NVIDIA since beta releases.
To successfully compile your programs developed against beta tookit you should define 
CG_DEPRECATED_API conditional define (in both Direct3D8 and OpenGL projects).

******************************************************************************* 
!!! NOTE !!! 
With this release you should not need to redistribute cg.exe command line compiler, 
as compiler now embedded in cg.dll library


Alexey Barkovoy,
25-Mar-2002
