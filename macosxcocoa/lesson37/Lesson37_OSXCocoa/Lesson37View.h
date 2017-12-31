/*
 * Original Windows comment:
 * "Sami Hamlaoui's Cel-Shading Code
 *     http://nehe.gamedev.net
 *               2001"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson37View.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

typedef struct tagMATRIX   // A Structure To Hold An OpenGL Matrix
{
   float Data[ 16 ];       // We Use [16] Due To OpenGL's Matrix Format
} MATRIX;

// This union is for dealing with endian issues in readMesh
union floatUnion
{
   NSSwappedFloat swap;
   float val;
};

typedef struct tagVECTOR   // A Structure To Hold A Single Vector
{
   union floatUnion X;     // The components of the vector
   union floatUnion Y;
   union floatUnion Z;
} VECTOR;

typedef struct tagVERTEX   // A Structure To Hold A Single Vertex
{
   VECTOR Nor;             // Vertex Normal
   VECTOR Pos;             // Vertex Position
} VERTEX;

typedef struct tagPOLYGON   // A Structure To Hold A Single Polygon
{
   VERTEX Verts[ 3 ];       // Array Of 3 VERTEX Structures
} POLYGON;

@interface Lesson37View : NSOpenGLView
{
   int colorBits, depthBits;
   BOOL runningFullScreen;
   NSDictionary *originalDisplayMode;
   BOOL outlineDraw;                   // Flag To Draw The Outline
   BOOL outlineSmooth;                 // Flag To Anti-Alias The Lines
   float outlineWidth;                 // Width Of The Lines

   VECTOR lightAngle;                  // The Direction Of The Light
   float modelAngle;                   // Y-Axis Angle Of The Model
   BOOL modelRotate;                   // Flag To Rotate The Model

   POLYGON *polyData;                  // Polygon Data
   int polyNum;                        // Number Of Polygons

   GLuint shaderTexture[ 1 ];          // Storage For One Texture
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) update:(long)milliseconds;
- (void) toggleModelRotate;
- (void) toggleOutlineDraw;
- (void) toggleOutlineSmooth;
- (void) increaseLineWidth;
- (void) decreaseLineWidth;
- (BOOL) isFullScreen;
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
