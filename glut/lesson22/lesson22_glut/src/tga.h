#ifndef _TGA_H
#define _TGA_H

// These defines are used to tell us about the type of TARGA file it is
#define TGA_RGB		 2		// This tells us it's a normal RGB (really BGR) file
#define TGA_A		 3		// This tells us it's a ALPHA file
#define TGA_RLE		10		// This tells us that the targa is Run-Length Encoded (RLE)

// This is our image structure for our targa data
struct tImageTGA
{
	int channels;			// The channels in the image (3 = RGB : 4 = RGBA)
	int sizeX;			// The width of the image in pixels
	int sizeY;			// The height of the image in pixels
	unsigned char *data;		// The image pixel data
};

/// functions prototypes
tImageTGA *LoadTGA(const char *filename);

void CreateTexture(GLuint textureArray[], char *strFileName, int textureID);

#endif
/* end of tga.h */

