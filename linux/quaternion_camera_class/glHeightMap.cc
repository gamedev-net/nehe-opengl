//////////////////////////////////////////////////////////////////////
//
// glHeightMap.cpp: implementation of the glHeightMap class.
//
//////////////////////////////////////////////////////////////////////

#include "glHeightMap.h"
#include <stdio.h>
#include <stdlib.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////
glHeightMap::glHeightMap()
{
    m_Texture = 0;
    m_Left = -(MAP_SIZE / 2);
    m_Right = MAP_SIZE / 2;
    m_Front = MAP_SIZE / 2;
    m_Back = -(MAP_SIZE / 2);
    m_HeightOffset = 128.0;
    m_ScaleValue = 12.0f;
}
glHeightMap::~glHeightMap()
{
}

bool glHeightMap::LoadRawFile(const char *strName, int nSize)
{
    FILE *pFile = NULL;
    // Open The File In Read / Binary Mode.
    pFile = fopen( strName, "rb" );
    // Check To See If We Found The File And Could Open It
    if ( pFile == NULL )	
    {
	// Display Error Message And Stop The Function
	return(false);
    }
    fread( m_HeightMap, 1, nSize, pFile );

    //After We Read The Data, It's A Good Idea To Check If Everything Read Fine
    int result = ferror( pFile );
    // Check If We Received An Error
    if (result)
    {
	return(false);
    }
    // Close The File.
    fclose(pFile);
	
    return(true);
}

GLfloat glHeightMap::GetHeight(GLfloat X, GLfloat Y)
{
    int x = int(X + (MAP_SIZE / 2)) % MAP_SIZE; // Error Check Our x Value
    int y = int(Y + (MAP_SIZE / 2)) % MAP_SIZE; // Error Check Our y Value
    if(!m_HeightMap) return 0; // Make Sure Our Data Is Valid
    if(x >= 0 && x <= MAP_SIZE && y >= 0 && y <= MAP_SIZE)
    {
	return m_HeightMap[x + (y << 10)];
    }
    else
    {
	return(0.0f);
    }
}

bool glHeightMap::SetVertexColor(GLfloat x, GLfloat y)
{
    if(!m_HeightMap) return(false); // Make Sure Our Height Data Is Valid
    GLfloat fColor = GLfloat((GetHeight(x, y ) / 256.0f) + 0.15);
    // Assign This Blue Shade To The Current Vertex
    glColor4f(fColor, fColor, fColor, 1.0f);
    return(true);
}

void glHeightMap::DrawHeightMap(void)
{
    GLfloat X = 0, Y = 0; // Create Some Variables To Walk The Array With.
    GLfloat Heights[4];
    GLfloat Color[4];
	
    if(!m_HeightMap) return; // Make Sure Our Height Data Is Valid

    if(m_Texture)
    {
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, m_Texture);
    }

    glBegin(GL_QUADS);
    for ( X = m_Left; X < m_Right; X += GLfloat(STEP_SIZE) )
    {
	for ( Y = m_Back; Y < m_Front; Y += GLfloat(STEP_SIZE) )
	{
	    Heights[0] = GetHeight(X, Y);
	    Heights[1] = GetHeight(X, Y + STEP_SIZE);
	    Heights[2] = GetHeight(X + STEP_SIZE, Y + STEP_SIZE);
	    Heights[3] = GetHeight(X + STEP_SIZE, Y);
	    // Set the vertex color
	    GetVertexColor(X, Y, Color);
	    glColor4fv(Color);
		
	    if(m_Texture) { glTexCoord2f(0.0f, 0.0f); }
	    // Get The (X, Y, Z) Value For The Bottom Left Vertex
	    glVertex3f( GLfloat(X),
			Heights[0] - m_HeightOffset,
			GLfloat(Y));
			
	    // Set the vertex color
	    GetVertexColor(X, Y + STEP_SIZE, Color);
	    glColor4fv(Color);
		
	    if(m_Texture) { glTexCoord2f(0.0f, 1.0f); }
	    // The (X, Y, Z) Value For The Top Left Vertex
	    glVertex3f( GLfloat(X),
			Heights[1] - m_HeightOffset,
			GLfloat(Y + STEP_SIZE));
			
	    // Set the vertex color
	    GetVertexColor(X + STEP_SIZE, Y + STEP_SIZE, Color);
	    glColor4fv(Color);
	    if(m_Texture) {	glTexCoord2f(1.0f, 1.0f); }
	    // Get The (X, Y, Z) Value For The Top Right Vertex
	    glVertex3f( GLfloat(X + STEP_SIZE), 
			Heights[2] - m_HeightOffset,
			GLfloat(Y + STEP_SIZE));

	    // Set the vertex color
	    GetVertexColor(X + STEP_SIZE, Y, Color);
	    glColor4fv(Color);
	    if(m_Texture) {	glTexCoord2f(1.0f, 0.0f); }
	    // Get The (X, Y, Z) Value For The Bottom Right Vertex
	    glVertex3f( GLfloat(X + STEP_SIZE), 
			Heights[3] - m_HeightOffset,
			GLfloat(Y));
	}
    }

    glEnd();
    if(m_Texture != 0)
    {
	glDisable(GL_TEXTURE_2D);
    }
}

void glHeightMap::GetVertexColor(GLfloat x, GLfloat y, GLfloat *col)
{
    if(!col) return;
	
    GLfloat fColor = GLfloat((GetHeight(x, y ) / 256.0f) + 0.20);
    // Assign This Blue Shade To The Current Vertex
    col[0] = fColor;
    col[1] = fColor;
    col[2] = fColor;
    col[3] = 1.0f;
}

/* Image type - contains height, width, and data */
typedef struct {
    unsigned long sizeX;
    unsigned long sizeY;
    char *data;
} RGBImageRec;

/*
 * getint and getshort are help functions to load the bitmap byte by byte on 
 * SPARC platform (actually, just makes the thing work on platforms of either
 * endianness, not just Intel's little endian)
 */
static unsigned int getint(FILE *fp)
{
  int c, c1, c2, c3;

  // get 4 bytes
  c = getc(fp);  
  c1 = getc(fp);  
  c2 = getc(fp);  
  c3 = getc(fp);
  
  return ((unsigned int) c) +   
    (((unsigned int) c1) << 8) + 
    (((unsigned int) c2) << 16) +
    (((unsigned int) c3) << 24);
}

static unsigned int getshort(FILE *fp)
{
  int c, c1;
  
  //get 2 bytes
  c = getc(fp);  
  c1 = getc(fp);

  return ((unsigned int) c) + (((unsigned int) c1) << 8);
}

// quick and dirty bitmap loader...for 24 bit bitmaps with 1 plane only.  
// See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info.
// (from NeHe's lesson10 Linux port by Richard Campbell)
int RGBImageLoad(const char *filename, RGBImageRec *image) 
{
    FILE *file;
    unsigned long size;                 // size of the image in bytes.
    unsigned long i;                    // standard counter.
    unsigned short int planes;          // number of planes in image (must be 1) 
    unsigned short int bpp;             // number of bits per pixel (must be 24)    
    char temp;                          // used to convert bgr to rgb color.

    // make sure the file is there.
    if ((file = fopen(filename, "rb"))==NULL) {
      printf("File Not Found : %s\n",filename);
      return 0;
    }
    
    // seek through the bmp header, up to the width/height:
    fseek(file, 18, SEEK_CUR);

    // No 100% errorchecking anymore!!!
    // read the width
    image->sizeX = getint (file);
    printf("Width of %s: %lu\n", filename, image->sizeX);
    
    // read the height 
    image->sizeY = getint (file);
    printf("Height of %s: %lu\n", filename, image->sizeY);
    
    // calculate the size (assuming 24 bits or 3 bytes per pixel).
    size = image->sizeX * image->sizeY * 3;

    // read the planes
    planes = getshort(file);
    if (planes != 1) {
        printf("Planes from %s is not 1: %u\n", filename, planes);
        return 0;
    }

    // read the bpp
    bpp = getshort(file);
    if (bpp != 24) {
      printf("Bpp from %s is not 24: %u\n", filename, bpp);
      return 0;
    }
        
    // seek past the rest of the bitmap header.
    fseek(file, 24, SEEK_CUR);

    // read the data. 
    image->data = (char *) malloc(size);
    if (image->data == NULL) {
        printf("Error allocating memory for color-corrected image data");
        return 0;       
    }

    if ((i = fread(image->data, size, 1, file)) != 1) {
        printf("Error reading image data from %s.\n", filename);
        return 0;
    }

    for (i=0;i<size;i+=3) { // reverse all of the colors. (bgr -> rgb)
        temp = image->data[i];
        image->data[i] = image->data[i+2];
        image->data[i+2] = temp;
    }

    // we're done.
    return 1;
}


bool glHeightMap::LoadTexture(const char *Filename)
{
    int success = 0;
    // File Handle
    FILE *File=NULL;
    RGBImageRec *TextureImage;

    // Make Sure A Filename Was Given
    if (!Filename)
    {
	// If Not Return NULL
	return(false);
    }
    // Check To See If The File Exists
    File=fopen(Filename,"r");
    // Does The File Exist?
    if (File)
    {
	// Close The Handle
	fclose(File);
	// Create Storage Space For The Texture
	TextureImage = (RGBImageRec *) malloc(sizeof(RGBImageRec));
	// Set The Pointer To NULL
	TextureImage->data = NULL;

	// Load The Bitmap And Return A Pointer
	success = RGBImageLoad(Filename, &TextureImage[0]);
	if (success == 0)
	{
	    if (TextureImage->data != NULL)
		free(TextureImage->data);
	    free(TextureImage);
	    return false;
	}
    }
    else
    {
	return(false);
    }
    if (TextureImage->data != NULL)
    {
	// Create The Texture
	glGenTextures(1, &m_Texture);
	// Typical Texture Generation Using Data From The Bitmap
	glBindTexture(GL_TEXTURE_2D, m_Texture);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, 
		     TextureImage->sizeX, TextureImage->sizeY,
		     0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage->data);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    }
    else
    {
	free(TextureImage);
	return(false);
    }
    // If Texture Image Exists
    if (TextureImage->data)
    {
	// Free The Texture Image Memory
	free(TextureImage->data);
	// Free The Image Structure
	free(TextureImage);
    }
    else
    {
	return(false);
    }
    return(true);
}
