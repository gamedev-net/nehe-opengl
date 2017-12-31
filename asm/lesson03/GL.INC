; GL header file by FooLman/United Force (c) 2000
;
; have fun with it!
;
; if you do not want your program to be 10000GBytes long comment out just the
; ones you really need!! 
; 

;extrn glAccum:PROC
;extrn glAlphaFunc:PROC
;extrn glAreTexturesResident:PROC
;extrn glArrayElement:PROC
extrn glBegin:PROC
;extrn glBindTexture:PROC
;extrn glBitmap:PROC
;extrn glBlendFunc:PROC
;extrn glCallList:PROC
;extrn glCallLists:PROC
extrn glClear:PROC
;extrn glClearAccum:PROC
extrn glClearColor:PROC
extrn glClearDepth:PROC
;extrn glClearIndex:PROC
;extrn glClearStencil:PROC 
;extrn glClipPlane:PROC 
;extrn glColor3b:PROC 
;extrn glColor3bv:PROC 
;extrn glColor3d:PROC 
;extrn glColor3dv:PROC 
extrn glColor3f:PROC 
;extrn glColor3fv:PROC 
;extrn glColor3i:PROC 
;extrn glColor3iv:PROC 
;extrn glColor3s:PROC 
;extrn glColor3sv:PROC 
;extrn glColor3ub:PROC 
;extrn glColor3ubv:PROC 
;extrn glColor3ui:PROC 
;extrn glColor3uiv:PROC 
;extrn glColor3us:PROC 
;extrn glColor3usv:PROC 
;extrn glColor4b:PROC 
;extrn glColor4bv:PROC 
;extrn glColor4d:PROC 
;extrn glColor4dv:PROC 
;extrn glColor4f:PROC 
;extrn glColor4fv:PROC 
;extrn glColor4i:PROC 
;extrn glColor4iv:PROC 
;extrn glColor4s:PROC 
;extrn glColor4sv:PROC 
;extrn glColor4ub:PROC 
;extrn glColor4ubv:PROC 
;extrn glColor4ui:PROC 
;extrn glColor4uiv:PROC 
;extrn glColor4us:PROC 
;extrn glColor4usv:PROC 
;extrn glColorMask:PROC 
;extrn glColorMaterial:PROC 
;extrn glColorPointer:PROC 
;extrn glCopyPixels:PROC 
;extrn glCopyTexImage1D:PROC 
;extrn glCopyTexImage2D:PROC 
;extrn glCopyTexSubImage1D:PROC 
;extrn glCopyTexSubImage2D:PROC 
;extrn glCullFace:PROC 
;extrn glDeleteLists:PROC 
;extrn glDeleteTextures:PROC 
extrn glDepthFunc:PROC 
;extrn glDepthMask:PROC 
;extrn glDepthRange:PROC 
;extrn glDisable:PROC 
;extrn glDisableClientState:PROC 
;extrn glDrawArrays:PROC 
;extrn glDrawBuffer:PROC 
;extrn glDrawElements:PROC 
;extrn glDrawPixels:PROC 
;extrn glEdgeFlag:PROC 
;extrn glEdgeFlagPointer:PROC 
;extrn glEdgeFlagv:PROC 
extrn glEnable:PROC 
;extrn glEnableClientState:PROC 
extrn glEnd:PROC 
;extrn glEndList:PROC 
;extrn glEvalCoord1d:PROC 
;extrn glEvalCoord1dv:PROC 
;extrn glEvalCoord1f:PROC 
;extrn glEvalCoord1fv:PROC 
;extrn glEvalCoord2d:PROC 
;extrn glEvalCoord2dv:PROC 
;extrn glEvalCoord2f:PROC 
;extrn glEvalCoord2fv:PROC 
;extrn glEvalMesh1:PROC 
;extrn glEvalMesh2:PROC 
;extrn glEvalPoint1:PROC 
;extrn glEvalPoint2:PROC 
;extrn glFeedbackBuffer:PROC 
extrn glFinish:PROC 
;extrn glFlush:PROC 
;extrn glFogf:PROC 
;extrn glFogfv:PROC 
;extrn glFogi:PROC 
;extrn glFogiv:PROC 
;extrn glFrontFace:PROC 
;extrn glFrustum:PROC 
;extrn glGenLists:PROC 
;extrn glGenTextures:PROC 
;extrn glGetBooleanv:PROC 
;extrn glGetClipPlane:PROC 
;extrn glGetDoublev:PROC 
;extrn glGetError:PROC 
;extrn glGetFloatv:PROC 
;extrn glGetIntegerv:PROC 
;extrn glGetLightfv:PROC 
;extrn glGetLightiv:PROC 
;extrn glGetMapdv:PROC 
;extrn glGetMapfv:PROC 
;extrn glGetMapiv:PROC 
;extrn glGetMaterialfv:PROC 
;extrn glGetMaterialiv:PROC 
;extrn glGetPixelMapfv:PROC 
;extrn glGetPixelMapuiv:PROC 
;extrn glGetPixelMapusv:PROC 
;extrn glGetPointerv:PROC 
;extrn glGetPolygonStipple:PROC 
;extrn glGetString:PROC 
;extrn glGetTexEnvfv:PROC 
;extrn glGetTexEnviv:PROC 
;extrn glGetTexGendv:PROC 
;extrn glGetTexGenfv:PROC 
;extrn glGetTexGeniv:PROC 
;extrn glGetTexImage:PROC 
;extrn glGetTexLevelParameterfv:PROC 
;extrn glGetTexLevelParameteriv:PROC 
;extrn glGetTexParameterfv:PROC 
;extrn glGetTexParameteriv:PROC 
extrn glHint:PROC 
;extrn glIndexMask:PROC 
;extrn glIndexPointer:PROC 
;extrn glIndexd:PROC 
;extrn glIndexdv:PROC 
;extrn glIndexf:PROC 
;extrn glIndexfv:PROC 
;extrn glIndexi:PROC 
;extrn glIndexiv:PROC 
;extrn glIndexs:PROC 
;extrn glIndexsv:PROC 
;extrn glIndexub:PROC 
;extrn glIndexubv:PROC 
;extrn glInitNames:PROC 
;extrn glInterleavedArrays:PROC 
;extrn glIsEnabled:PROC 
;extrn glIsList:PROC 
;extrn glIsTexture:PROC 
;extrn glLightModelf:PROC 
;extrn glLightModelfv:PROC 
;extrn glLightModeli:PROC 
;extrn glLightModeliv:PROC 
;extrn glLightf:PROC 
;extrn glLightfv:PROC 
;extrn glLighti:PROC 
;extrn glLightiv:PROC 
;extrn glLineStipple:PROC 
;extrn glLineWidth:PROC 
;extrn glListBase:PROC 
extrn glLoadIdentity:PROC 
;extrn glLoadMatrixd:PROC 
;extrn glLoadMatrixf:PROC 
;extrn glLoadName:PROC 
;extrn glLogicOp:PROC 
;extrn glMap1d:PROC 
;extrn glMap1f:PROC 
;extrn glMap2d:PROC 
;extrn glMap2f:PROC 
;extrn glMapGrid1d:PROC 
;extrn glMapGrid1f:PROC 
;extrn glMapGrid2d:PROC 
;extrn glMapGrid2f:PROC 
;extrn glMaterialf:PROC 
;extrn glMaterialfv:PROC 
;extrn glMateriali:PROC 
;extrn glMaterialiv:PROC 
extrn glMatrixMode:PROC 
;extrn glMultMatrixd:PROC 
;extrn glMultMatrixf:PROC 
;extrn glNewList:PROC 
;extrn glNormal3b:PROC 
;extrn glNormal3bv:PROC 
;extrn glNormal3d:PROC 
;extrn glNormal3dv:PROC 
;extrn glNormal3f:PROC 
;extrn glNormal3fv:PROC 
;extrn glNormal3i:PROC 
;extrn glNormal3iv:PROC 
;extrn glNormal3s:PROC 
;extrn glNormal3sv:PROC 
;extrn glNormalPointer:PROC 
;extrn glOrtho:PROC 
;extrn glPassThrough:PROC 
;extrn glPixelMapfv:PROC 
;extrn glPixelMapuiv:PROC 
;extrn glPixelMapusv:PROC 
;extrn glPixelStoref:PROC 
;extrn glPixelStorei:PROC 
;extrn glPixelTransferf:PROC 
;extrn glPixelTransferi:PROC 
;extrn glPixelZoom:PROC 
;extrn glPointSize:PROC 
;extrn glPolygonMode:PROC 
;extrn glPolygonOffset:PROC 
;extrn glPolygonStipple:PROC 
;extrn glPopAttrib:PROC 
;extrn glPopClientAttrib:PROC 
;extrn glPopMatrix:PROC 
;extrn glPopName:PROC 
;extrn glPrioritizeTextures:PROC 
;extrn glPushAttrib:PROC 
;extrn glPushClientAttrib:PROC 
;extrn glPushMatrix:PROC 
;extrn glPushName:PROC 
;extrn glRasterPos2d:PROC 
;extrn glRasterPos2dv:PROC 
;extrn glRasterPos2f:PROC 
;extrn glRasterPos2fv:PROC 
;extrn glRasterPos2i:PROC 
;extrn glRasterPos2iv:PROC 
;extrn glRasterPos2s:PROC 
;extrn glRasterPos2sv:PROC 
;extrn glRasterPos3d:PROC 
;extrn glRasterPos3dv:PROC 
;extrn glRasterPos3f:PROC 
;extrn glRasterPos3fv:PROC 
;extrn glRasterPos3i:PROC 
;extrn glRasterPos3iv:PROC 
;extrn glRasterPos3s:PROC 
;extrn glRasterPos3sv:PROC 
;extrn glRasterPos4d:PROC 
;extrn glRasterPos4dv:PROC 
;extrn glRasterPos4f:PROC 
;extrn glRasterPos4fv:PROC 
;extrn glRasterPos4i:PROC 
;extrn glRasterPos4iv:PROC 
;extrn glRasterPos4s:PROC 
;extrn glRasterPos4sv:PROC 
;extrn glReadBuffer:PROC 
;extrn glReadPixels:PROC 
;extrn glRectd:PROC 
;extrn glRectdv:PROC 
;extrn glRectf:PROC 
;extrn glRectfv:PROC 
;extrn glRecti:PROC 
;extrn glRectiv:PROC 
;extrn glRects:PROC 
;extrn glRectsv:PROC 
;extrn glRenderMode:PROC 
;extrn glRotated:PROC 
extrn glRotatef:PROC 
;extrn glScaled:PROC 
;extrn glScalef:PROC 
;extrn glScissor:PROC 
;extrn glSelectBuffer:PROC 
extrn glShadeModel:PROC 
;extrn glStencilFunc:PROC 
;extrn glStencilMask:PROC 
;extrn glStencilOp:PROC 
;extrn glTexCoord1d:PROC 
;extrn glTexCoord1dv:PROC 
;extrn glTexCoord1f:PROC 
;extrn glTexCoord1fv:PROC 
;extrn glTexCoord1i:PROC 
;extrn glTexCoord1iv:PROC 
;extrn glTexCoord1s:PROC 
;extrn glTexCoord1sv:PROC 
;extrn glTexCoord2d:PROC 
;extrn glTexCoord2dv:PROC 
;extrn glTexCoord2f:PROC 
;extrn glTexCoord2fv:PROC 
;extrn glTexCoord2i:PROC 
;extrn glTexCoord2iv:PROC 
;extrn glTexCoord2s:PROC 
;extrn glTexCoord2sv:PROC 
;extrn glTexCoord3d:PROC 
;extrn glTexCoord3dv:PROC 
;extrn glTexCoord3f:PROC 
;extrn glTexCoord3fv:PROC 
;extrn glTexCoord3i:PROC 
;extrn glTexCoord3iv:PROC 
;extrn glTexCoord3s:PROC 
;extrn glTexCoord3sv:PROC 
;extrn glTexCoord4d:PROC 
;extrn glTexCoord4dv:PROC 
;extrn glTexCoord4f:PROC 
;extrn glTexCoord4fv:PROC 
;extrn glTexCoord4i:PROC 
;extrn glTexCoord4iv:PROC 
;extrn glTexCoord4s:PROC 
;extrn glTexCoord4sv:PROC 
;extrn glTexCoordPointer:PROC 
;extrn glTexEnvf:PROC 
;extrn glTexEnvfv:PROC 
;extrn glTexEnvi:PROC 
;extrn glTexEnviv:PROC 
;extrn glTexGend:PROC 
;extrn glTexGendv:PROC 
;extrn glTexGenf:PROC 
;extrn glTexGenfv:PROC 
;extrn glTexGeni:PROC 
;extrn glTexGeniv:PROC 
;extrn glTexImage1D:PROC 
;extrn glTexImage2D:PROC 
;extrn glTexParameterf:PROC 
;extrn glTexParameterfv:PROC 
;extrn glTexParameteri:PROC 
;extrn glTexParameteriv:PROC 
;extrn glTexSubImage1D:PROC 
;extrn glTexSubImage2D:PROC 
;extrn glTranslated:PROC 
extrn glTranslatef:PROC 
;extrn glVertex2d:PROC 
;extrn glVertex2dv:PROC 
;extrn glVertex2f:PROC 
;extrn glVertex2fv:PROC 
;extrn glVertex2i:PROC 
;extrn glVertex2iv:PROC 
;extrn glVertex2s:PROC 
;extrn glVertex2sv:PROC 
;extrn glVertex3d:PROC 
;extrn glVertex3dv:PROC 
extrn glVertex3f:PROC 
;extrn glVertex3fv:PROC 
;extrn glVertex3i:PROC 
;extrn glVertex3iv:PROC 
;extrn glVertex3s:PROC 
;extrn glVertex3sv:PROC 
;extrn glVertex4d:PROC 
;extrn glVertex4dv:PROC 
;extrn glVertex4f:PROC 
;extrn glVertex4fv:PROC 
;extrn glVertex4i:PROC 
;extrn glVertex4iv:PROC 
;extrn glVertex4s:PROC 
;extrn glVertex4sv:PROC 
;extrn glVertexPointer:PROC 
extrn glViewport:PROC 


GL_CURRENT_BIT		= 00000001h
GL_POINT_BIT		= 00000002h
GL_LINE_BIT		= 00000004h
GL_POLYGON_BIT		= 00000008h
GL_POLYGON_STIPPLE_BIT  = 00000010h
GL_PIXEL_MODE_BIT       = 00000020h
GL_LIGHTING_BIT         = 00000040h
GL_FOG_BIT              = 00000080h
GL_DEPTH_BUFFER_BIT     = 00000100h
GL_ACCUM_BUFFER_BIT     = 00000200h
GL_STENCIL_BUFFER_BIT   = 00000400h
GL_VIEWPORT_BIT         = 00000800h
GL_TRANSFORM_BIT        = 00001000h
GL_ENABLE_BIT           = 00002000h
GL_COLOR_BUFFER_BIT     = 00004000h
GL_HINT_BIT             = 00008000h
GL_EVAL_BIT             = 00010000h
GL_LIST_BIT             = 00020000h
GL_TEXTURE_BIT          = 00040000h
GL_SCISSOR_BIT          = 00080000h
GL_ALL_ATTRIB_BITS      = 000fffffh

GL_CLIENT_PIXEL_STORE_BIT  = 00000001h
GL_CLIENT_VERTEX_ARRAY_BIT = 00000002h
GL_CLIENT_ALL_ATTRIB_BITS  =0FFFFFFFFh

GL_FALSE		= 0
GL_TRUE			= 1

GL_POINTS              = 0000h
GL_LINES               = 0001h
GL_LINE_LOOP           = 0002h
GL_LINE_STRIP          = 0003h
GL_TRIANGLES           = 0004h
GL_TRIANGLE_STRIP      = 0005h
GL_TRIANGLE_FAN        = 0006h
GL_QUADS               = 0007h
GL_QUAD_STRIP          = 0008h
GL_POLYGON             = 0009h

GL_ACCUM               = 0100h
GL_LOAD                = 0101h
GL_RETURN              = 0102h
GL_MULT                = 0103h
GL_ADD                 = 0104h

GL_NEVER               = 0200h
GL_LESS                = 0201h
GL_EQUAL               = 0202h
GL_LEQUAL              = 0203h
GL_GREATER             = 0204h
GL_NOTEQUAL            = 0205h
GL_GEQUAL              = 0206h
GL_ALWAYS              = 0207h

GL_ZERO                = 0
GL_ONE                 = 1
GL_SRC_COLOR           = 0300h
GL_ONE_MINUS_SRC_COLOR = 0301h
GL_SRC_ALPHA           = 0302h
GL_ONE_MINUS_SRC_ALPHA = 0303h
GL_DST_ALPHA           = 0304h
GL_ONE_MINUS_DST_ALPHA = 0305h

GL_DST_COLOR           = 0306h
GL_ONE_MINUS_DST_COLOR = 0307h
GL_SRC_ALPHA_SATURATE  = 0308h

GL_NONE                = 0
GL_FRONT_LEFT          = 0400h
GL_FRONT_RIGHT         = 0401h
GL_BACK_LEFT           = 0402h
GL_BACK_RIGHT          = 0403h
GL_FRONT               = 0404h
GL_BACK                = 0405h
GL_LEFT                = 0406h
GL_RIGHT               = 0407h
GL_FRONT_AND_BACK      = 0408h
GL_AUX0                = 0409h
GL_AUX1                = 040Ah
GL_AUX2                = 040Bh
GL_AUX3                = 040Ch

GL_NO_ERROR            = 0
GL_INVALID_ENUM        = 0500h
GL_INVALID_VALUE       = 0501h
GL_INVALID_OPERATION   = 0502h
GL_STACK_OVERFLOW      = 0503h
GL_STACK_UNDERFLOW     = 0504h
GL_OUT_OF_MEMORY       = 0505h

GL_2D                  = 0600h
GL_3D                  = 0601h
GL_3D_COLOR            = 0602h
GL_3D_COLOR_TEXTURE    = 0603h
GL_4D_COLOR_TEXTURE    = 0604h

GL_PASS_THROUGH_TOKEN  = 0700h
GL_POINT_TOKEN         = 0701h
GL_LINE_TOKEN          = 0702h
GL_POLYGON_TOKEN       = 0703h
GL_BITMAP_TOKEN        = 0704h
GL_DRAW_PIXEL_TOKEN    = 0705h
GL_COPY_PIXEL_TOKEN    = 0706h
GL_LINE_RESET_TOKEN    = 0707h

GL_EXP                 = 0800h
GL_EXP2                = 0801h

GL_CW                  = 0900h
GL_CCW                 = 0901h

GL_COEFF               = 0A00h
GL_ORDER               = 0A01h
GL_DOMAIN              = 0A02h

GL_PIXEL_MAP_I_TO_I    = 0C70h
GL_PIXEL_MAP_S_TO_S    = 0C71h
GL_PIXEL_MAP_I_TO_R    = 0C72h
GL_PIXEL_MAP_I_TO_G    = 0C73h
GL_PIXEL_MAP_I_TO_B    = 0C74h
GL_PIXEL_MAP_I_TO_A    = 0C75h
GL_PIXEL_MAP_R_TO_R    = 0C76h
GL_PIXEL_MAP_G_TO_G    = 0C77h
GL_PIXEL_MAP_B_TO_B    = 0C78h
GL_PIXEL_MAP_A_TO_A    = 0C79h

GL_VERTEX_ARRAY_POINTER        = 808Eh
GL_NORMAL_ARRAY_POINTER        = 808Fh
GL_COLOR_ARRAY_POINTER         = 8090h
GL_INDEX_ARRAY_POINTER         = 8091h
GL_TEXTURE_COORD_ARRAY_POINTER = 8092h
GL_EDGE_FLAG_ARRAY_POINTER     = 8093h

GL_CURRENT_COLOR                 =  0B00h
GL_CURRENT_INDEX                 =  0B01h
GL_CURRENT_NORMAL                =  0B02h
GL_CURRENT_TEXTURE_COORDS        =  0B03h
GL_CURRENT_RASTER_COLOR          =  0B04h
GL_CURRENT_RASTER_INDEX          =  0B05h
GL_CURRENT_RASTER_TEXTURE_COORDS =  0B06h
GL_CURRENT_RASTER_POSITION       =  0B07h
GL_CURRENT_RASTER_POSITION_VALID =  0B08h
GL_CURRENT_RASTER_DISTANCE       =  0B09h
GL_POINT_SMOOTH                  =  0B10h
GL_POINT_SIZE                    =  0B11h
GL_POINT_SIZE_RANGE              =  0B12h
GL_POINT_SIZE_GRANULARITY        =  0B13h
GL_LINE_SMOOTH                   =  0B20h
GL_LINE_WIDTH                    =  0B21h
GL_LINE_WIDTH_RANGE              =  0B22h
GL_LINE_WIDTH_GRANULARITY        =  0B23h
GL_LINE_STIPPLE                  =  0B24h
GL_LINE_STIPPLE_PATTERN          =  0B25h
GL_LINE_STIPPLE_REPEAT           =  0B26h
GL_LIST_MODE                     =  0B30h
GL_MAX_LIST_NESTING              =  0B31h
GL_LIST_BASE                     =  0B32h
GL_LIST_INDEX                    =  0B33h
GL_POLYGON_MODE                  =  0B40h
GL_POLYGON_SMOOTH                =  0B41h
GL_POLYGON_STIPPLE               =  0B42h
GL_EDGE_FLAG                     =  0B43h
GL_CULL_FACE                     =  0B44h
GL_CULL_FACE_MODE                =  0B45h
GL_FRONT_FACE                    =  0B46h
GL_LIGHTING                      =  0B50h
GL_LIGHT_MODEL_LOCAL_VIEWER      =  0B51h
GL_LIGHT_MODEL_TWO_SIDE          =  0B52h
GL_LIGHT_MODEL_AMBIENT           =  0B53h
GL_SHADE_MODEL                   =  0B54h
GL_COLOR_MATERIAL_FACE           =  0B55h
GL_COLOR_MATERIAL_PARAMETER      =  0B56h
GL_COLOR_MATERIAL                =  0B57h
GL_FOG                           =  0B60h
GL_FOG_INDEX                     =  0B61h
GL_FOG_DENSITY                   =  0B62h
GL_FOG_START                     =  0B63h
GL_FOG_END                       =  0B64h
GL_FOG_MODE                      =  0B65h
GL_FOG_COLOR                     =  0B66h
GL_DEPTH_RANGE                   =  0B70h
GL_DEPTH_TEST                    =  0B71h
GL_DEPTH_WRITEMASK               =  0B72h
GL_DEPTH_CLEAR_VALUE             =  0B73h
GL_DEPTH_FUNC                    =  0B74h
GL_ACCUM_CLEAR_VALUE             =  0B80h
GL_STENCIL_TEST                  =  0B90h
GL_STENCIL_CLEAR_VALUE           =  0B91h
GL_STENCIL_FUNC                  =  0B92h
GL_STENCIL_VALUE_MASK            =  0B93h
GL_STENCIL_FAIL                  =  0B94h
GL_STENCIL_PASS_DEPTH_FAIL       =  0B95h
GL_STENCIL_PASS_DEPTH_PASS       =  0B96h
GL_STENCIL_REF                   =  0B97h
GL_STENCIL_WRITEMASK             =  0B98h
GL_MATRIX_MODE                   =  0BA0h
GL_NORMALIZE                     =  0BA1h
GL_VIEWPORT                      =  0BA2h
GL_MODELVIEW_STACK_DEPTH         =  0BA3h
GL_PROJECTION_STACK_DEPTH        =  0BA4h
GL_TEXTURE_STACK_DEPTH           =  0BA5h
GL_MODELVIEW_MATRIX              =  0BA6h
GL_PROJECTION_MATRIX             =  0BA7h
GL_TEXTURE_MATRIX                =  0BA8h
GL_ATTRIB_STACK_DEPTH            =  0BB0h
GL_CLIENT_ATTRIB_STACK_DEPTH     =  0BB1h
GL_ALPHA_TEST                    =  0BC0h
GL_ALPHA_TEST_FUNC               =  0BC1h
GL_ALPHA_TEST_REF                =  0BC2h
GL_DITHER                        =  0BD0h
GL_BLEND_DST                     =  0BE0h
GL_BLEND_SRC                     =  0BE1h
GL_BLEND                         =  0BE2h
GL_LOGIC_OP_MODE                 =  0BF0h
GL_INDEX_LOGIC_OP                =  0BF1h
GL_LOGIC_OP                      =  GL_INDEX_LOGIC_OP
GL_COLOR_LOGIC_OP                =  0BF2h
GL_AUX_BUFFERS                   =  0C00h
GL_DRAW_BUFFER                   =  0C01h
GL_READ_BUFFER                   =  0C02h
GL_SCISSOR_BOX                   =  0C10h
GL_SCISSOR_TEST                  =  0C11h
GL_INDEX_CLEAR_VALUE             =  0C20h
GL_INDEX_WRITEMASK               =  0C21h
GL_COLOR_CLEAR_VALUE             =  0C22h
GL_COLOR_WRITEMASK               =  0C23h
GL_INDEX_MODE                    =  0C30h
GL_RGBA_MODE                     =  0C31h
GL_DOUBLEBUFFER                  =  0C32h
GL_STEREO                        =  0C33h
GL_RENDER_MODE                   =  0C40h
GL_PERSPECTIVE_CORRECTION_HINT   =  0C50h
GL_POINT_SMOOTH_HINT             =  0C51h
GL_LINE_SMOOTH_HINT              =  0C52h
GL_POLYGON_SMOOTH_HINT           =  0C53h
GL_FOG_HINT                      =  0C54h
GL_TEXTURE_GEN_S                 =  0C60h
GL_TEXTURE_GEN_T                 =  0C61h
GL_TEXTURE_GEN_R                 =  0C62h
GL_TEXTURE_GEN_Q                 =  0C63h
GL_PIXEL_MAP_I_TO_I_SIZE         =  0CB0h
GL_PIXEL_MAP_S_TO_S_SIZE         =  0CB1h
GL_PIXEL_MAP_I_TO_R_SIZE         =  0CB2h
GL_PIXEL_MAP_I_TO_G_SIZE         =  0CB3h
GL_PIXEL_MAP_I_TO_B_SIZE         =  0CB4h
GL_PIXEL_MAP_I_TO_A_SIZE         =  0CB5h
GL_PIXEL_MAP_R_TO_R_SIZE         =  0CB6h
GL_PIXEL_MAP_G_TO_G_SIZE         =  0CB7h
GL_PIXEL_MAP_B_TO_B_SIZE         =  0CB8h
GL_PIXEL_MAP_A_TO_A_SIZE         =  0CB9h
GL_UNPACK_SWAP_BYTES             =  0CF0h
GL_UNPACK_LSB_FIRST              =  0CF1h
GL_UNPACK_ROW_LENGTH             =  0CF2h
GL_UNPACK_SKIP_ROWS              =  0CF3h
GL_UNPACK_SKIP_PIXELS            =  0CF4h
GL_UNPACK_ALIGNMENT              =  0CF5h
GL_PACK_SWAP_BYTES               =  0D00h
GL_PACK_LSB_FIRST                =  0D01h
GL_PACK_ROW_LENGTH               =  0D02h
GL_PACK_SKIP_ROWS                =  0D03h
GL_PACK_SKIP_PIXELS              =  0D04h
GL_PACK_ALIGNMENT                =  0D05h
GL_MAP_COLOR                     =  0D10h
GL_MAP_STENCIL                   =  0D11h
GL_INDEX_SHIFT                   =  0D12h
GL_INDEX_OFFSET                  =  0D13h
GL_RED_SCALE                     =  0D14h
GL_RED_BIAS                      =  0D15h
GL_ZOOM_X                        =  0D16h
GL_ZOOM_Y                        =  0D17h
GL_GREEN_SCALE                   =  0D18h
GL_GREEN_BIAS                    =  0D19h
GL_BLUE_SCALE                    =  0D1Ah
GL_BLUE_BIAS                     =  0D1Bh
GL_ALPHA_SCALE                   =  0D1Ch
GL_ALPHA_BIAS                    =  0D1Dh
GL_DEPTH_SCALE                   =  0D1Eh
GL_DEPTH_BIAS                    =  0D1Fh
GL_MAX_EVAL_ORDER                =  0D30h
GL_MAX_LIGHTS                    =  0D31h
GL_MAX_CLIP_PLANES               =  0D32h
GL_MAX_TEXTURE_SIZE              =  0D33h
GL_MAX_PIXEL_MAP_TABLE           =  0D34h
GL_MAX_ATTRIB_STACK_DEPTH        =  0D35h
GL_MAX_MODELVIEW_STACK_DEPTH     =  0D36h
GL_MAX_NAME_STACK_DEPTH          =  0D37h
GL_MAX_PROJECTION_STACK_DEPTH    =  0D38h
GL_MAX_TEXTURE_STACK_DEPTH       =  0D39h
GL_MAX_VIEWPORT_DIMS             =  0D3Ah
GL_MAX_CLIENT_ATTRIB_STACK_DEPTH =  0D3Bh
GL_SUBPIXEL_BITS                 =  0D50h
GL_INDEX_BITS                    =  0D51h
GL_RED_BITS                      =  0D52h
GL_GREEN_BITS                    =  0D53h
GL_BLUE_BITS                     =  0D54h
GL_ALPHA_BITS                    =  0D55h
GL_DEPTH_BITS                    =  0D56h
GL_STENCIL_BITS                  =  0D57h
GL_ACCUM_RED_BITS                =  0D58h
GL_ACCUM_GREEN_BITS              =  0D59h
GL_ACCUM_BLUE_BITS               =  0D5Ah
GL_ACCUM_ALPHA_BITS              =  0D5Bh
GL_NAME_STACK_DEPTH              =  0D70h
GL_AUTO_NORMAL                   =  0D80h
GL_MAP1_COLOR_4                  =  0D90h
GL_MAP1_INDEX                    =  0D91h
GL_MAP1_NORMAL                   =  0D92h
GL_MAP1_TEXTURE_COORD_1          =  0D93h
GL_MAP1_TEXTURE_COORD_2          =  0D94h
GL_MAP1_TEXTURE_COORD_3          =  0D95h
GL_MAP1_TEXTURE_COORD_4          =  0D96h
GL_MAP1_VERTEX_3                 =  0D97h
GL_MAP1_VERTEX_4                 =  0D98h
GL_MAP2_COLOR_4                  =  0DB0h
GL_MAP2_INDEX                    =  0DB1h
GL_MAP2_NORMAL                   =  0DB2h
GL_MAP2_TEXTURE_COORD_1          =  0DB3h
GL_MAP2_TEXTURE_COORD_2          =  0DB4h
GL_MAP2_TEXTURE_COORD_3          =  0DB5h
GL_MAP2_TEXTURE_COORD_4          =  0DB6h
GL_MAP2_VERTEX_3                 =  0DB7h
GL_MAP2_VERTEX_4                 =  0DB8h
GL_MAP1_GRID_DOMAIN              =  0DD0h
GL_MAP1_GRID_SEGMENTS            =  0DD1h
GL_MAP2_GRID_DOMAIN              =  0DD2h
GL_MAP2_GRID_SEGMENTS            =  0DD3h
GL_TEXTURE_1D                    =  0DE0h
GL_TEXTURE_2D                    =  0DE1h
GL_FEEDBACK_BUFFER_POINTER       =  0DF0h
GL_FEEDBACK_BUFFER_SIZE          =  0DF1h
GL_FEEDBACK_BUFFER_TYPE          =  0DF2h
GL_SELECTION_BUFFER_POINTER      =  0DF3h
GL_SELECTION_BUFFER_SIZE         =  0DF4h
GL_POLYGON_OFFSET_UNITS          =  2A00h
GL_POLYGON_OFFSET_POINT          =  2A01h
GL_POLYGON_OFFSET_LINE           =  2A02h
GL_POLYGON_OFFSET_FILL           =  8037h
GL_POLYGON_OFFSET_FACTOR         =  8038h
GL_TEXTURE_BINDING_1D            =  8068h
GL_TEXTURE_BINDING_2D            =  8069h
GL_VERTEX_ARRAY                  =  8074h
GL_NORMAL_ARRAY                  =  8075h
GL_COLOR_ARRAY                   =  8076h
GL_INDEX_ARRAY                   =  8077h
GL_TEXTURE_COORD_ARRAY           =  8078h
GL_EDGE_FLAG_ARRAY               =  8079h
GL_VERTEX_ARRAY_SIZE             =  807Ah
GL_VERTEX_ARRAY_TYPE             =  807Bh
GL_VERTEX_ARRAY_STRIDE           =  807Ch
GL_NORMAL_ARRAY_TYPE             =  807Eh
GL_NORMAL_ARRAY_STRIDE           =  807Fh
GL_COLOR_ARRAY_SIZE              =  8081h
GL_COLOR_ARRAY_TYPE              =  8082h
GL_COLOR_ARRAY_STRIDE            =  8083h
GL_INDEX_ARRAY_TYPE              =  8085h
GL_INDEX_ARRAY_STRIDE            =  8086h
GL_TEXTURE_COORD_ARRAY_SIZE      =  8088h
GL_TEXTURE_COORD_ARRAY_TYPE      =  8089h
GL_TEXTURE_COORD_ARRAY_STRIDE    =  808Ah
GL_EDGE_FLAG_ARRAY_STRIDE        =  808Ch

GL_TEXTURE_WIDTH                 =  1000h
GL_TEXTURE_HEIGHT                =  1001h
GL_TEXTURE_INTERNAL_FORMAT       =  1003h
GL_TEXTURE_COMPONENTS            =  GL_TEXTURE_INTERNAL_FORMAT
GL_TEXTURE_BORDER_COLOR          =  1004h
GL_TEXTURE_BORDER                =  1005h
GL_TEXTURE_RED_SIZE              =  805Ch
GL_TEXTURE_GREEN_SIZE            =  805Dh
GL_TEXTURE_BLUE_SIZE             =  805Eh
GL_TEXTURE_ALPHA_SIZE            =  805Fh
GL_TEXTURE_LUMINANCE_SIZE        =  8060h
GL_TEXTURE_INTENSITY_SIZE        =  8061h
GL_TEXTURE_PRIORITY              =  8066h
GL_TEXTURE_RESIDENT              =  8067h

GL_DONT_CARE                     =  1100h
GL_FASTEST                       =  1101h
GL_NICEST                        =  1102h

GL_AMBIENT                       =  1200h
GL_DIFFUSE                       =  1201h
GL_SPECULAR                      =  1202h
GL_POSITION                      =  1203h
GL_SPOT_DIRECTION                =  1204h
GL_SPOT_EXPONENT                 =  1205h
GL_SPOT_CUTOFF                   =  1206h
GL_CONSTANT_ATTENUATION          =  1207h
GL_LINEAR_ATTENUATION            =  1208h
GL_QUADRATIC_ATTENUATION         =  1209h

GL_COMPILE                       =  1300h
GL_COMPILE_AND_EXECUTE           =  1301h

GL_BYTE                          =  1400h
GL_UNSIGNED_BYTE                 =  1401h
GL_SHORT                         =  1402h
GL_UNSIGNED_SHORT                =  1403h
GL_INT                           =  1404h
GL_UNSIGNED_INT                  =  1405h
GL_FLOAT                         =  1406h
GL_2_BYTES                       =  1407h
GL_3_BYTES                       =  1408h
GL_4_BYTES                       =  1409h
GL_DOUBLE                        =  140Ah
GL_DOUBLE_EXT                    =  140Ah

GL_CLEAR                         =  1500h
GL_AND                           =  1501h
GL_AND_REVERSE                   =  1502h
GL_COPY                          =  1503h
GL_AND_INVERTED                  =  1504h
GL_NOOP                          =  1505h
GL_XOR                           =  1506h
GL_OR                            =  1507h
GL_NOR                           =  1508h
GL_EQUIV                         =  1509h
GL_INVERT                        =  150Ah
GL_OR_REVERSE                    =  150Bh
GL_COPY_INVERTED                 =  150Ch
GL_OR_INVERTED                   =  150Dh
GL_NAND                          =  150Eh
GL_SET                           =  150Fh

GL_EMISSION                      =  1600h
GL_SHININESS                     =  1601h
GL_AMBIENT_AND_DIFFUSE           =  1602h
GL_COLOR_INDEXES                 =  1603h

GL_MODELVIEW                     =  1700h
GL_PROJECTION                    =  1701h
GL_TEXTURE                       =  1702h

GL_COLOR                         =  1800h
GL_DEPTH                         =  1801h
GL_STENCIL                       =  1802h

GL_COLOR_INDEX                   =  1900h
GL_STENCIL_INDEX                 =  1901h
GL_DEPTH_COMPONENT               =  1902h
GL_RED                           =  1903h
GL_GREEN                         =  1904h
GL_BLUE                          =  1905h
GL_ALPHA                         =  1906h
GL_RGB                           =  1907h
GL_RGBA                          =  1908h
GL_LUMINANCE                     =  1909h
GL_LUMINANCE_ALPHA               =  190Ah

GL_BITMAP                        =  1A00h

GL_POINT                         =  1B00h
GL_LINE                          =  1B01h
GL_FILL                          =  1B02h

GL_RENDER                        =  1C00h
GL_FEEDBACK                      =  1C01h
GL_SELECT                        =  1C02h

GL_FLAT                          =  1D00h
GL_SMOOTH                        =  1D01h

GL_KEEP                          =  1E00h
GL_REPLACE                       =  1E01h
GL_INCR                          =  1E02h
GL_DECR                          =  1E03h

GL_VENDOR                        =  1F00h
GL_RENDERER                      =  1F01h
GL_VERSION                       =  1F02h
GL_EXTENSIONS                    =  1F03h

GL_S                             =  2000h
GL_T                             =  2001h
GL_R                             =  2002h
GL_Q                             =  2003h

GL_MODULATE                      =  2100h
GL_DECAL                         =  2101h

GL_TEXTURE_ENV_MODE              =  2200h
GL_TEXTURE_ENV_COLOR             =  2201h

GL_TEXTURE_ENV                   =  2300h

GL_EYE_LINEAR                    =  2400h
GL_OBJECT_LINEAR                 =  2401h
GL_SPHERE_MAP                    =  2402h

GL_TEXTURE_GEN_MODE              =  2500h
GL_OBJECT_PLANE                  =  2501h
GL_EYE_PLANE                     =  2502h

GL_NEAREST                       =  2600h
GL_LINEAR                        =  2601h

GL_NEAREST_MIPMAP_NEAREST        =  2700h
GL_LINEAR_MIPMAP_NEAREST         =  2701h
GL_NEAREST_MIPMAP_LINEAR         =  2702h
GL_LINEAR_MIPMAP_LINEAR          =  2703h

GL_TEXTURE_MAG_FILTER            =  2800h
GL_TEXTURE_MIN_FILTER            =  2801h
GL_TEXTURE_WRAP_S                =  2802h
GL_TEXTURE_WRAP_T                =  2803h

GL_PROXY_TEXTURE_1D              =  8063h
GL_PROXY_TEXTURE_2D              =  8064h

GL_CLAMP                         =  2900h
GL_REPEAT                        =  2901h

GL_R3_G3_B2                      =  2A10h
GL_ALPHA4                        =  803Bh
GL_ALPHA8                        =  803Ch
GL_ALPHA12                       =  803Dh
GL_ALPHA16                       =  803Eh
GL_LUMINANCE4                    =  803Fh
GL_LUMINANCE8                    =  8040h
GL_LUMINANCE12                   =  8041h
GL_LUMINANCE16                   =  8042h
GL_LUMINANCE4_ALPHA4             =  8043h
GL_LUMINANCE6_ALPHA2             =  8044h
GL_LUMINANCE8_ALPHA8             =  8045h
GL_LUMINANCE12_ALPHA4            =  8046h
GL_LUMINANCE12_ALPHA12           =  8047h
GL_LUMINANCE16_ALPHA16           =  8048h
GL_INTENSITY                     =  8049h
GL_INTENSITY4                    =  804Ah
GL_INTENSITY8                    =  804Bh
GL_INTENSITY12                   =  804Ch
GL_INTENSITY16                   =  804Dh
GL_RGB4                          =  804Fh
GL_RGB5                          =  8050h
GL_RGB8                          =  8051h
GL_RGB10                         =  8052h
GL_RGB12                         =  8053h
GL_RGB16                         =  8054h
GL_RGBA2                         =  8055h
GL_RGBA4                         =  8056h
GL_RGB5_A1                       =  8057h
GL_RGBA8                         =  8058h
GL_RGB10_A2                      =  8059h
GL_RGBA12                        =  805Ah
GL_RGBA16                        =  805Bh

GL_V2F                           =  2A20h
GL_V3F                           =  2A21h
GL_C4UB_V2F                      =  2A22h
GL_C4UB_V3F                      =  2A23h
GL_C3F_V3F                       =  2A24h
GL_N3F_V3F                       =  2A25h
GL_C4F_N3F_V3F                   =  2A26h
GL_T2F_V3F                       =  2A27h
GL_T4F_V4F                       =  2A28h
GL_T2F_C4UB_V3F                  =  2A29h
GL_T2F_C3F_V3F                   =  2A2Ah
GL_T2F_N3F_V3F                   =  2A2Bh
GL_T2F_C4F_N3F_V3F               =  2A2Ch
GL_T4F_C4F_N3F_V4F               =  2A2Dh

GL_CLIP_PLANE0                   =  3000h
GL_CLIP_PLANE1                   =  3001h
GL_CLIP_PLANE2                   =  3002h
GL_CLIP_PLANE3                   =  3003h
GL_CLIP_PLANE4                   =  3004h
GL_CLIP_PLANE5                   =  3005h

GL_LIGHT0                        =  4000h
GL_LIGHT1                        =  4001h
GL_LIGHT2                        =  4002h
GL_LIGHT3                        =  4003h
GL_LIGHT4                        =  4004h
GL_LIGHT5                        =  4005h
GL_LIGHT6                        =  4006h
GL_LIGHT7                        =  4007h

GL_ABGR_EXT                      =  8000h

GL_UNSIGNED_BYTE_3_3_2_EXT       =  8032h
GL_UNSIGNED_SHORT_4_4_4_4_EXT    =  8033h
GL_UNSIGNED_SHORT_5_5_5_1_EXT    =  8034h
GL_UNSIGNED_INT_8_8_8_8_EXT      =  8035h
GL_UNSIGNED_INT_10_10_10_2_EXT   =  8036h

GL_VERTEX_ARRAY_EXT              =  8074h
GL_NORMAL_ARRAY_EXT              =  8075h
GL_COLOR_ARRAY_EXT               =  8076h
GL_INDEX_ARRAY_EXT               =  8077h
GL_TEXTURE_COORD_ARRAY_EXT       =  8078h
GL_EDGE_FLAG_ARRAY_EXT           =  8079h
GL_VERTEX_ARRAY_SIZE_EXT         =  807Ah
GL_VERTEX_ARRAY_TYPE_EXT         =  807Bh
GL_VERTEX_ARRAY_STRIDE_EXT       =  807Ch
GL_VERTEX_ARRAY_COUNT_EXT        =  807Dh
GL_NORMAL_ARRAY_TYPE_EXT         =  807Eh
GL_NORMAL_ARRAY_STRIDE_EXT       =  807Fh
GL_NORMAL_ARRAY_COUNT_EXT        =  8080h
GL_COLOR_ARRAY_SIZE_EXT          =  8081h
GL_COLOR_ARRAY_TYPE_EXT          =  8082h
GL_COLOR_ARRAY_STRIDE_EXT        =  8083h
GL_COLOR_ARRAY_COUNT_EXT         =  8084h
GL_INDEX_ARRAY_TYPE_EXT          =  8085h
GL_INDEX_ARRAY_STRIDE_EXT        =  8086h
GL_INDEX_ARRAY_COUNT_EXT         =  8087h
GL_TEXTURE_COORD_ARRAY_SIZE_EXT  =  8088h
GL_TEXTURE_COORD_ARRAY_TYPE_EXT  =  8089h
GL_TEXTURE_COORD_ARRAY_STRIDE_EXT=  808Ah
GL_TEXTURE_COORD_ARRAY_COUNT_EXT =  808Bh
GL_EDGE_FLAG_ARRAY_STRIDE_EXT    =  808Ch
GL_EDGE_FLAG_ARRAY_COUNT_EXT     =  808Dh
GL_VERTEX_ARRAY_POINTER_EXT      =  808Eh
GL_NORMAL_ARRAY_POINTER_EXT      =  808Fh
GL_COLOR_ARRAY_POINTER_EXT       =  8090h
GL_INDEX_ARRAY_POINTER_EXT       =  8091h
GL_TEXTURE_COORD_ARRAY_POINTER_EXT= 8092h
GL_EDGE_FLAG_ARRAY_POINTER_EXT   =  8093h

GL_TABLE_TOO_LARGE_EXT           =  8031h
GL_COLOR_TABLE_FORMAT_EXT        =  80D8h
GL_COLOR_TABLE_WIDTH_EXT         =  80D9h
GL_COLOR_TABLE_RED_SIZE_EXT      =  80DAh
GL_COLOR_TABLE_GREEN_SIZE_EXT    =  80DBh
GL_COLOR_TABLE_BLUE_SIZE_EXT     =  80DCh
GL_COLOR_TABLE_ALPHA_SIZE_EXT    =  80DDh
GL_COLOR_TABLE_LUMINANCE_SIZE_EXT=  80DEh
GL_COLOR_TABLE_INTENSITY_SIZE_EXT=  80DFh

GL_BGR_EXT                       =  80E0h
GL_BGRA_EXT                      =  80E1h

GL_COLOR_INDEX1_EXT              =  80E2h
GL_COLOR_INDEX2_EXT              =  80E3h
GL_COLOR_INDEX4_EXT              =  80E4h
GL_COLOR_INDEX8_EXT              =  80E5h
GL_COLOR_INDEX12_EXT             =  80E6h
GL_COLOR_INDEX16_EXT             =  80E7h

GL_ARRAY_ELEMENT_LOCK_FIRST_SGI  =  81A8h
GL_ARRAY_ELEMENT_LOCK_COUNT_SGI  =  81A9h

GL_CULL_VERTEX_SGI               =  81AAh
GL_CULL_VERTEX_EYE_POSITION_SGI  =  81ABh
GL_CULL_VERTEX_OBJECT_POSITION_SGI= 81ACh

GL_IUI_V2F_SGI                   =  81ADh
GL_IUI_V3F_SGI                   =  81AEh
GL_IUI_N3F_V2F_SGI               =  81AFh
GL_IUI_N3F_V3F_SGI               =  81B0h
GL_T2F_IUI_V2F_SGI               =  81B1h
GL_T2F_IUI_V3F_SGI               =  81B2h
GL_T2F_IUI_N3F_V2F_SGI           =  81B3h
GL_T2F_IUI_N3F_V3F_SGI           =  81B4h

GL_INDEX_TEST_SGI                =  81B5h
GL_INDEX_TEST_FUNC_SGI           =  81B6h
GL_INDEX_TEST_REF_SGI            =  81B7h

GL_INDEX_MATERIAL_SGI            =  81B8h
GL_INDEX_MATERIAL_PARAMETER_SGI  =  81B9h
GL_INDEX_MATERIAL_FACE_SGI       =  81BAh



