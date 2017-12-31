/*
	MilkshapeModel.cpp

		Loads and renders a Milkshape3D model. 

	Author:	Brett Porter
	Email: brettporter@yahoo.com
	Website: http://www.geocities.com/brettporter/
	Copyright (C)2000, Brett Porter. All Rights Reserved.

	This file may be used only as long as this copyright notice remains intact.
*/

#if defined(__APPLE__)
#include <string.h>
#include <OpenGL/gl.h>
#else
#include <windows.h>		// Header File For Windows
#include <gl\gl.h>			// Header File For The OpenGL32 Library
#endif

#include "MilkshapeModel.h"

#include <fstream.h>

#define SWAPEND16(x) ((((x) & 0xFF) << 8) | (((x) >> 8) & 0xFF))
#define SWAPEND32(x) ((((x) & 0xFF) << 24) | ((((x) >> 8) & 0xFF) << 16) | \
                      ((((x) >> 16) & 0xFF) << 8) | (((x) >> 24) & 0xFF))

float swapendf32( float floatValue )
{
   union mapUnion { unsigned char bytes[ 4 ]; float floatVal; } *mapping, newMapping;
   mapping = (union mapUnion *) &floatValue;
   newMapping.bytes[ 0 ] = mapping->bytes[ 3 ];
   newMapping.bytes[ 1 ] = mapping->bytes[ 2 ];
   newMapping.bytes[ 2 ] = mapping->bytes[ 1 ];
   newMapping.bytes[ 3 ] = mapping->bytes[ 0 ];
   return newMapping.floatVal;
}

MilkshapeModel::MilkshapeModel()
{
}

MilkshapeModel::~MilkshapeModel()
{
}

/* 
	MS3D STRUCTURES 
*/

// byte-align structures
#ifdef _MSC_VER
#	pragma pack( push, packing )
#	pragma pack( 1 )
#	define PACK_STRUCT
#elif defined( __GNUC__ )
#	define PACK_STRUCT	__attribute__((packed))
#else
#	error you must byte-align these structures with the appropriate compiler directives
#endif

typedef unsigned char byte;
typedef unsigned short word;

// File header
struct MS3DHeader
{
	char m_ID[10];
	int m_version;
} PACK_STRUCT;

// Vertex information
struct MS3DVertex
{
	byte m_flags;
	float m_vertex[3];
	char m_boneID;
	byte m_refCount;
} PACK_STRUCT;

// Triangle information
struct MS3DTriangle
{
	word m_flags;
	word m_vertexIndices[3];
	float m_vertexNormals[3][3];
	float m_s[3], m_t[3];
	byte m_smoothingGroup;
	byte m_groupIndex;
} PACK_STRUCT;

// Material information
struct MS3DMaterial
{
    char m_name[32];
    float m_ambient[4];
    float m_diffuse[4];
    float m_specular[4];
    float m_emissive[4];
    float m_shininess;	// 0.0f - 128.0f
    float m_transparency;	// 0.0f - 1.0f
    byte m_mode;	// 0, 1, 2 is unused now
    char m_texture[128];
    char m_alphamap[128];
} PACK_STRUCT;

//	Joint information
struct MS3DJoint
{
	byte m_flags;
	char m_name[32];
	char m_parentName[32];
	float m_rotation[3];
	float m_translation[3];
	word m_numRotationKeyframes;
	word m_numTranslationKeyframes;
} PACK_STRUCT;

// Keyframe data
struct MS3DKeyframe
{
	float m_time;
	float m_parameter[3];
} PACK_STRUCT;

// Default alignment
#ifdef _MSC_VER
#	pragma pack( pop, packing )
#endif

#undef PACK_STRUCT

bool MilkshapeModel::loadModelData( const char *filename )
{
	ifstream inputFile( filename, ios::in | ios::binary | ios::nocreate );
	if ( inputFile.fail())
		return false;	// "Couldn't open the model file."

	inputFile.seekg( 0, ios::end );
	long fileSize = inputFile.tellg();
	inputFile.seekg( 0, ios::beg );

	byte *pBuffer = new byte[fileSize];
	inputFile.read( pBuffer, fileSize );
	inputFile.close();

	const byte *pPtr = pBuffer;
	MS3DHeader *pHeader = ( MS3DHeader* )pPtr;
	pPtr += sizeof( MS3DHeader );

	if ( strncmp( pHeader->m_ID, "MS3D000000", 10 ) != 0 )
		return false; // "Not a valid Milkshape3D model file."

#if BYTE_ORDER == BIG_ENDIAN
   pHeader->m_version = SWAPEND32( pHeader->m_version );
#endif
	if ( pHeader->m_version < 3 || pHeader->m_version > 4 )
		return false; // "Unhandled file version. Only Milkshape3D Version 1.3 and 1.4 is supported." );

#if BYTE_ORDER == BIG_ENDIAN
   int nVertices = SWAPEND16( *(word *) pPtr );
#else
	int nVertices = *( word* )pPtr;
#endif
	m_numVertices = nVertices;
	m_pVertices = new Vertex[nVertices];
	pPtr += sizeof( word );

	int i;
	for ( i = 0; i < nVertices; i++ )
	{
		MS3DVertex *pVertex = ( MS3DVertex* )pPtr;
		m_pVertices[i].m_boneID = pVertex->m_boneID;
#if BYTE_ORDER == BIG_ENDIAN
      for( int loopvar = 0; loopvar < 3; loopvar++ )
         m_pVertices[ i ].m_location[ loopvar ] =
            swapendf32( pVertex->m_vertex[ loopvar ] );
#else
		memcpy( m_pVertices[i].m_location, pVertex->m_vertex, sizeof( float )*3 );
#endif
		pPtr += sizeof( MS3DVertex );
	}

#if BYTE_ORDER == BIG_ENDIAN
   int nTriangles = SWAPEND16( *(word *) pPtr );
#else
	int nTriangles = *( word* )pPtr;
#endif
	m_numTriangles = nTriangles;
	m_pTriangles = new Triangle[nTriangles];
	pPtr += sizeof( word );

	for ( i = 0; i < nTriangles; i++ )
	{
		MS3DTriangle *pTriangle = ( MS3DTriangle* )pPtr;
#if BYTE_ORDER == BIG_ENDIAN
      int vertexIndices[ 3 ] = { SWAPEND16( pTriangle->m_vertexIndices[ 0 ] ),
                                 SWAPEND16( pTriangle->m_vertexIndices[ 1 ] ),
                                 SWAPEND16( pTriangle->m_vertexIndices[ 2 ] ) };
		float t[ 3 ] = { 1.0f - swapendf32( pTriangle->m_t[ 0 ] ),
                       1.0f - swapendf32( pTriangle->m_t[ 1 ] ),
                       1.0f - swapendf32( pTriangle->m_t[ 2 ] ) };
      for( int loopvar1 = 0; loopvar1 < 3; loopvar1++ )
      {
         for( int loopvar2 = 0; loopvar2 < 3; loopvar2++ )
            m_pTriangles[ i ].m_vertexNormals[ loopvar1 ][ loopvar2 ] =
               swapendf32( pTriangle->m_vertexNormals[ loopvar1 ][ loopvar2 ] );
         m_pTriangles[ i ].m_s[ loopvar1 ] =
            swapendf32( pTriangle->m_s[ loopvar1 ] );
      }
#else
		int vertexIndices[3] = { pTriangle->m_vertexIndices[0], pTriangle->m_vertexIndices[1], pTriangle->m_vertexIndices[2] };
		float t[3] = { 1.0f-pTriangle->m_t[0], 1.0f-pTriangle->m_t[1], 1.0f-pTriangle->m_t[2] };
		memcpy( m_pTriangles[i].m_vertexNormals, pTriangle->m_vertexNormals, sizeof( float )*3*3 );
		memcpy( m_pTriangles[i].m_s, pTriangle->m_s, sizeof( float )*3 );
#endif
		memcpy( m_pTriangles[i].m_t, t, sizeof( float )*3 );
		memcpy( m_pTriangles[i].m_vertexIndices, vertexIndices, sizeof( int )*3 );
		pPtr += sizeof( MS3DTriangle );
	}

#if BYTE_ORDER == BIG_ENDIAN
   int nGroups = SWAPEND16( *(word *) pPtr );
#else
	int nGroups = *( word* )pPtr;
#endif
	m_numMeshes = nGroups;
	m_pMeshes = new Mesh[nGroups];
	pPtr += sizeof( word );
	for ( i = 0; i < nGroups; i++ )
	{
		pPtr += sizeof( byte );	// flags
		pPtr += 32;				// name

#if BYTE_ORDER == BIG_ENDIAN
      word nTriangles = SWAPEND16( *(word *) pPtr );
#else
		word nTriangles = *( word* )pPtr;
#endif
		pPtr += sizeof( word );
		int *pTriangleIndices = new int[nTriangles];
		for ( int j = 0; j < nTriangles; j++ )
		{
#if BYTE_ORDER == BIG_ENDIAN
         pTriangleIndices[ j ] = SWAPEND16( *(word *) pPtr );
#else
			pTriangleIndices[j] = *( word* )pPtr;
#endif
			pPtr += sizeof( word );
		}

		char materialIndex = *( char* )pPtr;
		pPtr += sizeof( char );

		m_pMeshes[i].m_materialIndex = materialIndex;
		m_pMeshes[i].m_numTriangles = nTriangles;
		m_pMeshes[i].m_pTriangleIndices = pTriangleIndices;
	}

#if BYTE_ORDER == BIG_ENDIAN
   int nMaterials = SWAPEND16( *(word *) pPtr );
#else
	int nMaterials = *( word* )pPtr;
#endif
	m_numMaterials = nMaterials;
	m_pMaterials = new Material[nMaterials];
	pPtr += sizeof( word );
	for ( i = 0; i < nMaterials; i++ )
	{
		MS3DMaterial *pMaterial = ( MS3DMaterial* )pPtr;
#if BYTE_ORDER == BIG_ENDIAN
      for( int loopvar = 0; loopvar < 4; loopvar++ )
      {
         m_pMaterials[ i ].m_ambient[ loopvar ] =
            swapendf32( pMaterial->m_ambient[ loopvar ] );
         m_pMaterials[ i ].m_diffuse[ loopvar ] =
            swapendf32( pMaterial->m_diffuse[ loopvar ] );
         m_pMaterials[ i ].m_specular[ loopvar ] =
            swapendf32( pMaterial->m_specular[ loopvar ] );
         m_pMaterials[ i ].m_emissive[ loopvar ] =
            swapendf32( pMaterial->m_emissive[ loopvar ] );
      }
		m_pMaterials[ i ].m_shininess = swapendf32( pMaterial->m_shininess );
#else
		memcpy( m_pMaterials[i].m_ambient, pMaterial->m_ambient, sizeof( float )*4 );
		memcpy( m_pMaterials[i].m_diffuse, pMaterial->m_diffuse, sizeof( float )*4 );
		memcpy( m_pMaterials[i].m_specular, pMaterial->m_specular, sizeof( float )*4 );
		memcpy( m_pMaterials[i].m_emissive, pMaterial->m_emissive, sizeof( float )*4 );
		m_pMaterials[i].m_shininess = pMaterial->m_shininess;
#endif
		m_pMaterials[i].m_pTextureFilename = new char[strlen( pMaterial->m_texture )+1];
		strcpy( m_pMaterials[i].m_pTextureFilename, pMaterial->m_texture );
		pPtr += sizeof( MS3DMaterial );
	}

	reloadTextures();

	delete[] pBuffer;

	return true;
}

