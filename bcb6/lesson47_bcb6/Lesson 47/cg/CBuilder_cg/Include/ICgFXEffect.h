
#ifndef __ICGFX_EFFECT_BCB_H
#define __ICGFX_EFFECT_BCB_H

#ifdef CGFXDLL_EXPORTS
#define CGFXDLL_API __declspec(dllexport)
#else
#define CGFXDLL_API __declspec(dllimport)
#endif

#include <objbase.h>

#include "cgfx_stddefs.h"
#define CGFX_MAX_DIMENSIONS 4

//////////////////////////////////////////////////////////////////////////////
// Types /////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

typedef enum _CgFXPARAMETERTYPE
{
	CgFXPT_UNKNOWN			= 0,
	CgFXPT_BOOL,
	CgFXPT_INT,
    CgFXPT_FLOAT,
    CgFXPT_DWORD,
    CgFXPT_STRING,

    // Ref counted objects; Can be accessed as objects or as strings
    CgFXPT_TEXTURE,
    CgFXPT_CUBETEXTURE,
    CgFXPT_VOLUMETEXTURE,
    CgFXPT_VERTEXSHADER,
    CgFXPT_PIXELSHADER,

    // Complex type
    CgFXPT_STRUCT,
    
    // force 32-bit size enum
    CgFXPT_FORCE_DWORD      = 0x7fffffff

} CgFXPARAMETERTYPE;

typedef struct _CgFXEffect_DESC
{
	UINT Parameters;	// Number of parameters
	UINT Techniques;	// Number of techniques
	UINT Functions;		// Number of functions
} CgFXEFFECT_DESC;

typedef struct _CgFXPARAMETER_DESC
{
	LPCSTR Name;		// Parameter name.
	LPCSTR Index;		// Parameter index (cast to LPCSTR)

	// Usage
	LPCSTR Semantic;	// Semantic meaning

	// Type
	CgFXPARAMETERTYPE Type;	// Parameter type
	UINT Dimension[CGFX_MAX_DIMENSIONS];		// Elements in array
	UINT Bytes;				// Total size in bytes

	// Annotations
	UINT Annotations;		// Number of annotations.
} CgFXPARAMETER_DESC;

typedef struct _CgFXANNOTATION_DESC
{
    LPCSTR Name;                        // Annotation name
    LPCSTR Index;                       // Annotation index (cast to LPCSTR)
	LPCVOID Value;						// Annotation value (cast to LPCVOID)

    // Type
    CgFXPARAMETERTYPE Type;             // Annotation type
    UINT Dimension[CGFX_MAX_DIMENSIONS];                     // Elements in array
    UINT Bytes;                         // Total size in bytes

} CgFXANNOTATION_DESC;

typedef struct _CgFXTECHNIQUE_DESC
{
    LPCSTR Name;                        // Technique name
    LPCSTR Index;                       // Technique index (cast to LPCSTR)

    UINT Properties;                    // Number of properties
    UINT Passes;                        // Number of passes

} CgFXTECHNIQUE_DESC;

typedef struct _CgFXPASS_DESC
{
    LPCSTR Name;                        // Pass name
    LPCSTR Index;                       // Pass index (cast to LPCSTR)

} CgFXPASS_DESC;

typedef enum _CgFXMode
{
	CgFX_Unknown,
	CgFX_OpenGL,
	CgFX_Direct3D8,
	CgFX_Direct3D9
} CgFXMode;



//namespace ICgFXEffectDLL {

//////////////////////////////////////////////////////////////////////////////
// Base Effect ///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// base interface. extended by Effect and EffectCompiler.
//////////////////////////////////////////////////////////////////////////////
struct ICgFXBaseEffect// : public IUnknown
{
	//virtual HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void __RPC_FAR *__RPC_FAR *ppvObject) = 0;
       virtual HRESULT STDMETHODCALLTYPE QueryInterface( 
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void __RPC_FAR *__RPC_FAR *ppvObject) = 0;
	virtual HRESULT STDMETHODCALLTYPE AddRef(void) = 0;
	virtual HRESULT STDMETHODCALLTYPE Release(void) = 0;

    // Descriptions
	/* Return description of effect */
	virtual HRESULT STDMETHODCALLTYPE GetDesc(CgFXEFFECT_DESC* pDesc) = 0;
	/* Return description of the named/indexed parameter */
	virtual HRESULT STDMETHODCALLTYPE GetParameterDesc(LPCSTR pParameter, CgFXPARAMETER_DESC* pDesc) = 0;
	/* Return description of the named/indexed annotation */
	virtual HRESULT STDMETHODCALLTYPE GetAnnotationDesc(LPCSTR pParameter, LPCSTR pAnnotation, CgFXANNOTATION_DESC* pDesc) = 0;
	/* Return description of the named/indexed technique */
	virtual HRESULT STDMETHODCALLTYPE GetTechniqueDesc(LPCSTR pTechnique, CgFXTECHNIQUE_DESC* pDesc) = 0;
	/* Return description of pass for given technique */
	virtual HRESULT STDMETHODCALLTYPE GetPassDesc(LPCSTR pTechnique, LPCSTR pPass, CgFXPASS_DESC* pDesc) = 0;

	// Get/Set Parameter
	virtual HRESULT STDMETHODCALLTYPE SetValue(LPCSTR pName, LPCVOID pData, UINT Bytes) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetValue(LPCSTR pName, LPVOID pData, UINT Bytes) = 0;
	/*
	virtual HRESULT STDMETHODCALLTYPE SetValueTranspose(LPCSTR pName, LPCVOID pData, UINT Bytes) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetValueTranspose(LPCSTR pName, LPVOID pData, UINT Bytes) = 0;
	*/

	virtual HRESULT STDMETHODCALLTYPE STDMETHODCALLTYPE SetFloat(LPCSTR pName, FLOAT f) = 0;
	virtual HRESULT STDMETHODCALLTYPE STDMETHODCALLTYPE GetFloat(LPCSTR pName, FLOAT* f) = 0;
	virtual HRESULT STDMETHODCALLTYPE SetVector(LPCSTR pName, const float* pVector, UINT vecSize) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetVector(LPCSTR pName, float* pVector, UINT* vecSize) = 0;
	virtual HRESULT STDMETHODCALLTYPE SetMatrix(LPCSTR pName, const float* pMatrix, UINT nRows, UINT nCols) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetMatrix(LPCSTR pName, float* pMatrix, UINT* nRows, UINT* nCols) = 0;
	//virtual HRESULT STDMETHODCALLTYPE SetMatrixTranspose(LPCSTR pName, const float* pMatrix, UINT nRows, UINT nCols) = 0;
	//virtual HRESULT STDMETHODCALLTYPE GetMatrixTranspose(LPCSTR pName, float* pMatrix, UINT* nRows, UINT* nCols) = 0;
	
	virtual HRESULT STDMETHODCALLTYPE SetDword(LPCSTR pName, DWORD dw) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetDword(LPCSTR pName, DWORD* dw) = 0;

	virtual HRESULT STDMETHODCALLTYPE SetBoolValue(LPCSTR pName, bool bvalue) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetBoolValue(LPCSTR pName, bool* bvalue) = 0;

	
	virtual HRESULT STDMETHODCALLTYPE SetString(LPCSTR pName, LPCSTR pString) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetString(LPCSTR pName, LPCSTR* ppString) = 0;
	//virtual HRESULT STDMETHODCALLTYPE SetTexture1D(LPCSTR pName, DWORD textureHandle) = 0;
	//virtual HRESULT STDMETHODCALLTYPE GetTexture1D(LPCSTR pName, DWORD* textureHandle) = 0;
	virtual HRESULT STDMETHODCALLTYPE SetTexture(LPCSTR pName, DWORD textureHandle) =0;
	virtual HRESULT STDMETHODCALLTYPE GetTexture(LPCSTR pName, DWORD* textureHandle) = 0;
	/*
	virtual HRESULT STDMETHODCALLTYPE SetCubeTexture(LPCSTR pName, DWORD textureHandle) =0;
	virtual HRESULT STDMETHODCALLTYPE GetCubeTexture(LPCSTR pName, DWORD* textureHandle) = 0;
	virtual HRESULT STDMETHODCALLTYPE SetVolumeTexture(LPCSTR pName, DWORD textureHandle) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetVolumeTexture(LPCSTR pName, DWORD* textureHandle) = 0;
	*/

	virtual HRESULT STDMETHODCALLTYPE SetVertexShader(LPCSTR pName, DWORD vsHandle) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetVertexShader(LPCSTR pName, DWORD* vsHandle) = 0;

	virtual HRESULT STDMETHODCALLTYPE SetPixelShader(LPCSTR pName, DWORD psHandle) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetPixelShader(LPCSTR pName, DWORD* psHandle) = 0;
};

struct ICgFXEffect : public ICgFXBaseEffect
{
	// Set/get current technique:
	virtual HRESULT STDMETHODCALLTYPE SetTechnique(LPCSTR pTechnique) = 0;
	virtual HRESULT STDMETHODCALLTYPE GetTechnique(LPCSTR* ppTechnique) = 0;
	// Validate current technique:
	virtual HRESULT STDMETHODCALLTYPE Validate() = 0;
	// Returns the number of passes in pPasses:
	virtual HRESULT STDMETHODCALLTYPE Begin(UINT* pPasses, DWORD Flags) = 0;
	virtual HRESULT STDMETHODCALLTYPE Pass(UINT passNum) = 0;
	virtual HRESULT STDMETHODCALLTYPE End() = 0;

    virtual HRESULT STDMETHODCALLTYPE CloneEffect(ICgFXEffect** ppNewEffect) = 0;
	/*
	virtual HRESULT STDMETHODCALLTYPE FindNextValidTechnique(LPCSTR pTechnique, CgFXTECHNIQUE_DESC* pDesc) = 0;
	*/

	virtual HRESULT STDMETHODCALLTYPE GetDevice(LPVOID* ppDevice) = 0;
	virtual HRESULT STDMETHODCALLTYPE OnLostDevice() = 0;
	virtual HRESULT STDMETHODCALLTYPE OnResetDevice() = 0;

};

struct ICgFXEffectCompiler : public ICgFXBaseEffect
{
    // Compilation
    virtual HRESULT STDMETHODCALLTYPE CompileEffect(DWORD Flags, ICgFXEffect** ppEffect, const char** ppCompilationErrors) = 0;
};

#ifndef CGFXDLL_EXPORTS
#define CgFXCreateEffect CgFXCreateEffect_BCB
#define CgFXCreateEffectFromFileA CgFXCreateEffectFromFileA_BCB
#define CgFXCreateEffectCompiler CgFXCreateEffectCompiler_BCB
#define CgFXCreateEffectCompilerFromFileA CgFXCreateEffectCompilerFromFileA_BCB
#define CgFXSetDevice CgFXSetDevice_BCB
#define CgFXFreeDevice CgFXFreeDevice_BCB
#define CgFXGetErrors CgFXGetErrors_BCB
#define CgFXRelease CgFXRelease_BCB
#endif

extern "C" {

CGFXDLL_API HRESULT CgFXCreateEffect_BCB(
        LPCSTR               pSrcData,
        DWORD                Flags,
        ICgFXEffect**        ppEffect,
        const char**         ppCompilationErrors);

CGFXDLL_API HRESULT CgFXCreateEffectFromFileA_BCB(
        LPCSTR               pSrcFile,
        DWORD                Flags,
        ICgFXEffect**        ppEffect,
        const char**         ppCompilationErrors);

CGFXDLL_API HRESULT CgFXCreateEffectCompiler_BCB(
        LPCSTR                pSrcData,
        DWORD                 Flags,
        ICgFXEffectCompiler** ppEffectCompiler,
        const char**          ppCompilationErrors);

CGFXDLL_API HRESULT CgFXCreateEffectCompilerFromFileA_BCB(
        LPCSTR                pSrcFile,
        DWORD                 Flags,
        ICgFXEffectCompiler** ppEffectCompiler,
        const char**          ppCompilationErrors);

CGFXDLL_API HRESULT CgFXSetDevice_BCB(const char* pDeviceName,LPVOID pDevice);
CGFXDLL_API HRESULT CgFXFreeDevice_BCB(const char* pDeviceName, LPVOID pDevice);
CGFXDLL_API HRESULT CgFXGetErrors_BCB(const char** ppErrors);
CGFXDLL_API HRESULT CgFXRelease_BCB();

}

#endif
