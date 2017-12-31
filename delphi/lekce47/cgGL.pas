(*
 *
 * Copyright (c) 2002, NVIDIA Corporation.
 *
 *
 *
 * NVIDIA Corporation("NVIDIA") supplies this software to you in consideration
 * of your agreement to the following terms, and your use, installation,
 * modification or redistribution of this NVIDIA software constitutes
 * acceptance of these terms.  If you do not agree with these terms, please do
 * not use, install, modify or redistribute this NVIDIA software.
 *
 *
 *
 * In consideration of your agreement to abide by the following terms, and
 * subject to these terms, NVIDIA grants you a personal, non-exclusive license,
 * under NVIDIAÒs copyrights in this original NVIDIA software (the "NVIDIA
 * Software"), to use, reproduce, modify and redistribute the NVIDIA
 * Software, with or without modifications, in source and/or binary forms;
 * provided that if you redistribute the NVIDIA Software, you must retain the
 * copyright notice of NVIDIA, this notice and the following text and
 * disclaimers in all such redistributions of the NVIDIA Software. Neither the
 * name, trademarks, service marks nor logos of NVIDIA Corporation may be used
 * to endorse or promote products derived from the NVIDIA Software without
 * specific prior written permission from NVIDIA.  Except as expressly stated
 * in this notice, no other rights or licenses express or implied, are granted
 * by NVIDIA herein, including but not limited to any patent rights that may be
 * infringed by your derivative works or by other works in which the NVIDIA
 * Software may be incorporated. No hardware is licensed hereunder.
 *
 *
 *
 * THE NVIDIA SOFTWARE IS BEING PROVIDED ON AN "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING
 * WITHOUT LIMITATION, WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT,
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR ITS USE AND OPERATION
 * EITHER ALONE OR IN COMBINATION WITH OTHER PRODUCTS.
 *
 *
 *
 * IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL,
 * EXEMPLARY, CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOST
 * PROFITS; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) OR ARISING IN ANY WAY OUT OF THE USE,
 * REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE NVIDIA SOFTWARE,
 * HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING
 * NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF NVIDIA HAS BEEN ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *)


unit cgGL;

interface

uses
  OpenGL{$IFNDEF COMPILER6_UP}, Windows{$ENDIF}, cg;

(*$HPPEMIT '#include "cgGL.h"' *)

const
  CgGLlibrary = 'cgGL.dll';

{$IFNDEF CG_DEPRECATED_API}

(*****************************************************************************)
(*** cgGL Type Definitions                                                 ***)
(*****************************************************************************)

type
  TCGGLenum = (CG_GL_MATRIX_IDENTITY,
                CG_GL_MATRIX_TRANSPOSE,
                CG_GL_MATRIX_INVERSE,
                CG_GL_MATRIX_INVERSE_TRANSPOSE,
                CG_GL_MODELVIEW_MATRIX,
                CG_GL_PROJECTION_MATRIX,
                CG_GL_TEXTURE_MATRIX,
                CG_GL_MODELVIEW_PROJECTION_MATRIX,
                CG_GL_VERTEX,
                CG_GL_FRAGMENT);
  CGGLenum = TCGGLenum;
  {$NODEFINE CGGLenum}
  {$NODEFINE TCGGLenum}
  {$HPPEMIT 'typedef CGGLenum TCGGLenum;'}


(******************************************************************************
 *** Profile Functions
 *****************************************************************************)

function cgGLIsProfileSupported(profile: TCGprofile): TCGbool; cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLIsProfileSupported}

procedure cgGLEnableProfile(profile: TCGprofile); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLEnableProfile}
procedure cgGLDisableProfile(profile: TCGprofile); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLDisableProfile}

function cgGLGetLatestProfile(profile_type: TCGGLenum): TCGprofile; cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetLatestProfile}
procedure cgGLSetOptimalOptions(profile: TCGprofile); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetOptimalOptions}

(******************************************************************************
 *** Program Managment Functions
 *****************************************************************************)

procedure cgGLLoadProgram(_program: PCGprogram); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLLoadProgram}
procedure cgGLBindProgram(_program: PCGprogram); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLBindProgram}

(******************************************************************************
 *** Parameter Managment Functions
 *****************************************************************************)

procedure cgGLSetParameter1f(param: PCGparameter; x: Single); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter1f}

procedure cgGLSetParameter2f(param: PCGparameter; x, y: Single); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter2f}

procedure cgGLSetParameter3f(param: PCGparameter; x, y, z: Single); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter3f}

procedure cgGLSetParameter4f(param: PCGparameter; x, y, z, w: Single); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter4f}

procedure cgGLSetParameter1fv(param: PCGparameter; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter1fv}

procedure cgGLSetParameter2fv(param: PCGparameter; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter2fv}

procedure cgGLSetParameter3fv(param: PCGparameter; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter3fv}

procedure cgGLSetParameter4fv(param: PCGparameter; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter4fv}

procedure cgGLSetParameter1d(param: PCGparameter; x: Double); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter1d}

procedure cgGLSetParameter2d(param: PCGparameter; x, y: Double); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter2d}

procedure cgGLSetParameter3d(param: PCGparameter; x, y, z: Double); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter3d}

procedure cgGLSetParameter4d(param: PCGparameter; x, y, z, w: Double); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter4d}

procedure cgGLSetParameter1dv(param: PCGparameter; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter1dv}

procedure cgGLSetParameter2dv(param: PCGparameter; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter2dv}

procedure cgGLSetParameter3dv(param: PCGparameter; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter3dv}

procedure cgGLSetParameter4dv(param: PCGparameter; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameter4dv}

procedure cgGLGetParameter1f(param: PCGparameter; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter1f}

procedure cgGLGetParameter2f(param: PCGparameter; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter2f}

procedure cgGLGetParameter3f(param: PCGparameter; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter3f}

procedure cgGLGetParameter4f(param: PCGparameter; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter4f}

procedure cgGLGetParameter1d(param: PCGparameter; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter1d}

procedure cgGLGetParameter2d(param: PCGparameter; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter2d}

procedure cgGLGetParameter3d(param: PCGparameter; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter3d}

procedure cgGLGetParameter4d(param: PCGparameter; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameter4d}

procedure cgGLSetParameterArray1f(param: PCGparameter;
    offset, nelements: Longint; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray1f}

procedure cgGLSetParameterArray2f(param: PCGparameter;
    offset, nelements: Longint; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray2f}

procedure cgGLSetParameterArray3f(param: PCGparameter;
    offset, nelements: Longint; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray3f}

procedure cgGLSetParameterArray4f(param: PCGparameter;
    offset, nelements: Longint; const v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray4f}

procedure cgGLSetParameterArray1d(param: PCGparameter;
    offset, nelements: Longint; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray1d}

procedure cgGLSetParameterArray2d(param: PCGparameter;
    offset, nelements: Longint; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray2d}

procedure cgGLSetParameterArray3d(param: PCGparameter;
    offset, nelements: Longint; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray3d}

procedure cgGLSetParameterArray4d(param: PCGparameter;
    offset, nelements: Longint; const v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterArray4d}

procedure cgGLGetParameterArray1f(param: PCGparameter;
    offset, nelements: Longint; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray1f}

procedure cgGLGetParameterArray2f(param: PCGparameter;
    offset, nelements: Longint; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray2f}

procedure cgGLGetParameterArray3f(param: PCGparameter;
    offset, nelements: Longint; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray3f}

procedure cgGLGetParameterArray4f(param: PCGparameter;
    offset, nelements: Longint; v: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray4f}

procedure cgGLGetParameterArray1d(param: PCGparameter;
    offset, nelements: Longint; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray1d}

procedure cgGLGetParameterArray2d(param: PCGparameter;
    offset, nelements: Longint; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray2d}

procedure cgGLGetParameterArray3d(param: PCGparameter;
    offset, nelements: Longint; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray3d}

procedure cgGLGetParameterArray4d(param: PCGparameter;
    offset, nelements: Longint; v: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetParameterArray4d}

procedure cgGLSetParameterPointer(param: PCGparameter; fsize: GLint;
    _type: TCGGLenum; stride: GLsizei; _pointer: Pointer); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetParameterPointer}

procedure cgGLEnableClientState(param: PCGparameter); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLEnableClientState}
procedure cgGLDisableClientState(param: PCGparameter); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLDisableClientState}

(******************************************************************************
 *** Matrix Parameter Managment Functions
 *****************************************************************************)

procedure cgGLSetMatrixParameterdr(param: PCGparameter; const matrix: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterdr}
procedure cgGLSetMatrixParameterfr(param: PCGparameter; const matrix: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterfr}
procedure cgGLSetMatrixParameterdc(param: PCGparameter; const matrix: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterdc}
procedure cgGLSetMatrixParameterfc(param: PCGparameter; const matrix: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterfc}

procedure cgGLGetMatrixParameterdr(param: PCGparameter; matrix: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterdr}
procedure cgGLGetMatrixParameterfr(param: PCGparameter; matrix: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterfr}
procedure cgGLGetMatrixParameterdc(param: PCGparameter; matrix: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterdc}
procedure cgGLGetMatrixParameterfc(param: PCGparameter; matrix: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterfc}

procedure cgGLSetStateMatrixParameter(param: PCGparameter;
    matrix: CGGLenum; transform: TCGGLenum); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetStateMatrixParameter}

procedure cgGLSetMatrixParameterArrayfc(param: PCGparameter;
    offset, nelements: Longint; const matrices: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterArrayfc}

procedure cgGLSetMatrixParameterArrayfr(param: PCGparameter;
    offset, nelements: Longint; const matrices: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterArrayfr}

procedure cgGLSetMatrixParameterArraydc(param: PCGparameter;
    offset, nelements: Longint; const matrices: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterArraydc}

procedure cgGLSetMatrixParameterArraydr(param: PCGparameter;
    offset, nelements: Longint; const matrices: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetMatrixParameterArraydr}

procedure cgGLGetMatrixParameterArrayfc(param: PCGparameter;
    offset, nelements: Longint; matrices: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterArrayfc}

procedure cgGLGetMatrixParameterArrayfr(param: PCGparameter;
    offset, nelements: Longint; matrices: PSingle); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterArrayfr}

procedure cgGLGetMatrixParameterArraydc(param: PCGparameter;
    offset, nelements: Longint; matrices: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterArraydc}

procedure cgGLGetMatrixParameterArraydr(param: PCGparameter;
    offset, nelements: Longint; matrices: PDouble); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetMatrixParameterArraydr}

(******************************************************************************
 *** Texture Parameter Managment Functions
 *****************************************************************************)

procedure cgGLSetTextureParameter(param: PCGparameter; texobj: GLuint); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLSetTextureParameter}
function cgGLGetTextureParameter(param: PCGparameter): GLuint; cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetTextureParameter}
procedure cgGLEnableTextureParameter(param: PCGparameter); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLEnableTextureParameter}
procedure cgGLDisableTextureParameter(param: PCGparameter); cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLDisableTextureParameter}
function cgGLGetTextureEnum(param: PCGparameter): GLenum; cdecl; external CgGLlibrary;
{$EXTERNALSYM cgGLGetTextureEnum}

{$ELSE}

{
#define cgGLLoadProgram cgGLDEPRECATEDAPI_LoadProgram
#define cgGLBindProgram cgGLDEPRECATEDAPI_BindProgram
#define cgGLEnableClientState cgGL_DEPRECATEDAPI_EnableClientState
#define cgGLDisableClientState cgGL_DEPRECATEDAPI_DisableClientState
}
{$Include cgGL_deprecated_api.inc}

{$ENDIF}


implementation

end.

