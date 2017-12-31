/*
 * File gotten from Abdul Bezrati's (abezrati@hotmail.com) NeHe OpenGL port to JoGL.
 * This program takes a bmp file and converts it to an array of bytes which can then
 * be loaded as a texture. I have changed things as wanted, but essentially things
 * stayed the same. Thanks to Abdul for this file. Saved me a lot of work! :)
 */

package LoadImageTypes;

import java.io.*;
import java.io.File;
import java.awt.Image;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.net.URL;

public class LoadBMPImages
{
  private byte[] data;
  private int width;
  private int height;
  
  public LoadBMPImages()
  {
    destroy();
  }
  
  public byte[] getData()
  {
      return data;
  }
  
  public int getWidth()
  {
      return width;
  }
  
  public int getHeight()
  {
      return height;
  }

  public void generateTextureInfo(InputStream textureName, String filename, boolean AlphaChannel)
  {
    Image textureFile = null;
    int[] pixels;

    if(!(filename.endsWith("bmp")))
    {
      try{ textureFile = java.awt.Toolkit.getDefaultToolkit().getImage(filename); }
      catch(NullPointerException e){ System.out.println(e); }

      while(width <= 0 || height <= 0)
      {
        width      = textureFile.getWidth(null);
        height     = textureFile.getHeight(null);
      }

      pixels = new int[width*height];

      try{
        new java.awt.image.PixelGrabber(textureFile,
                                        0,
                                        0,
                                        width,
                                        height,
                                        pixels,
                                        0,
                                        width).grabPixels();
        textureFile = null;
      }
      catch (InterruptedException e) {}
    }
    else
    { pixels = loadBitmapPixels(textureName); }

    if(!AlphaChannel){
        data = new byte[pixels.length*3];
        for(int y = height -1, pointer = 0; y>=0; y--)
        for(int x = 0; x<width; x++,pointer+=3)
        {
          data[pointer+0] = (byte)((pixels[y*width + x] >> 16) & 0xFF);
          data[pointer+1] = (byte)((pixels[y*width + x] >>  8) & 0xFF);
          data[pointer+2] = (byte) (pixels[y*width + x]        & 0xFF);
        }
    }
    else{
        data = new byte[pixels.length*4];
        for(int y = height -1, pointer = 0; y>=0; y--)
        for(int x = 0; x<width; x++,pointer+=4)
        {
          data[pointer+3] = (byte)((pixels[y*width + x] >> 24) & 0xFF);
          data[pointer+0] = (byte)((pixels[y*width + x] >> 16) & 0xFF);
          data[pointer+1] = (byte)((pixels[y*width + x] >>  8) & 0xFF);
          data[pointer+2] = (byte)( pixels[y*width + x]        & 0xFF);
        }
    }
    pixels = null;
  }
  
  public int[] loadBitmapPixels(InputStream in)
  {
    try
    {
      BufferedInputStream input = new BufferedInputStream(in);

      int bitmapFileHeaderLength = 14;
      int bitmapInfoHeaderLength = 40;

      byte[] bitmapFileHeader = new byte[bitmapFileHeaderLength];
      byte[] bitmapInfoHeader = new byte[bitmapInfoHeaderLength];

      input.read(bitmapFileHeader, 0, bitmapFileHeaderLength);
      input.read(bitmapInfoHeader, 0, bitmapInfoHeaderLength);

      int nSize             = bytesToInt(bitmapFileHeader, 2);
      int nWidth            = bytesToInt(bitmapInfoHeader, 4);
      int nHeight           = bytesToInt(bitmapInfoHeader, 8);
      int nBiSize           = bytesToInt(bitmapInfoHeader, 0);
      int nPlanes           = bytesToShort(bitmapInfoHeader, 12);
      int nBitCount         = bytesToShort(bitmapInfoHeader, 14);
      int nSizeImage        = bytesToInt(bitmapInfoHeader, 20);
      int nCompression      = bytesToInt(bitmapInfoHeader, 16);
      int nColoursUsed      = bytesToInt(bitmapInfoHeader, 32);
      int nXPixelsMeter     = bytesToInt(bitmapInfoHeader, 24);
      int nYPixelsMeter     = bytesToInt(bitmapInfoHeader, 28);
      int nImportantColours = bytesToInt(bitmapInfoHeader, 36);

      if(nBitCount==24)
      {
        int npad = ((npad= (nSizeImage / nHeight)  - nWidth * 3)==4 || npad<0)? 0:npad;
        int nindex = 0;
        int[] ndata = new int [nHeight * nWidth];
        byte[] brgb = new byte[( nWidth + npad) * 3 * nHeight];

        input.read (brgb, 0, (nWidth + npad) * 3 * nHeight);
        
        for(int j = 0; j < nHeight; j++)
        {
          for(int i = 0; i < nWidth; i++)
          {
            ndata[nWidth * (nHeight - j - 1) + i] = (      255      & 0xff) << 24|
                                                    (brgb[nindex+2] & 0xff) << 16|
                                                    (brgb[nindex+1] & 0xff) <<  8|
                                                    (brgb[nindex]   & 0xff);
            nindex += 3;
          }
          nindex += npad;
        }
        
        brgb  = null;
        input.close();
        width  = nWidth;
        height = nHeight;
        return ndata;
      }
      else
      {
        if(nBitCount == 8)
        {
          int nNumColors = (nColoursUsed > 0) ? nColoursUsed:(1&0xff)<<nBitCount;

          if(nSizeImage == 0)
          {
            nSizeImage = ((((nWidth*nBitCount)+31) & ~31 ) >> 3);
            nSizeImage *= nHeight;
          }

          int[] npalette = new int[nNumColors];
          byte[] bpalette = new byte[nNumColors*4];
          input.read (bpalette, 0, nNumColors*4);
          int nindex8 = 0;
          

          for(int n = 0; n < nNumColors; n++)
          {
            npalette[n] = (       255          & 0xff) << 24|
                        (bpalette[nindex8+2] & 0xff) << 16|
                        (bpalette[nindex8+1] & 0xff) <<  8|
                        (bpalette[nindex8+0] & 0xff);

            nindex8 += 4;
          }

          int npad8    = (nSizeImage / nHeight) - nWidth;
          int[] ndata8 = new int[nWidth*nHeight];
          byte[] bdata  = new byte[(nWidth+npad8)*nHeight];

          input.read(bdata, 0, (nWidth+npad8)*nHeight);
          nindex8 = 0;

          for(int j8 = 0; j8 < nHeight; j8++)
          {
            for(int i8 = 0; i8 < nWidth; i8++)
            {
              ndata8[nWidth*(nHeight-j8-1)+i8] = npalette[((int)bdata[nindex8]&0xff)];
              nindex8++;
            }
            nindex8 += npad8;
          }
          
          input.close();
          width  = nWidth;
          height = nHeight;
          return ndata8;
        }
        else
          System.out.println ("Not a 24-bit or 8-bit Windows Bitmap, aborting...");
        input.close();
      }
    }
    catch (Exception e)
    {
      System.out.println("Caught exception in loadbitmap!");
    }
    return null;
  }

  public int[] loadBitmapPixels(URL file)
  {
    try
    {
      FileInputStream input = new FileInputStream(file.getFile());

      int bitmapFileHeaderLength = 14;
      int bitmapInfoHeaderLength = 40;

      byte[] bitmapFileHeader = new byte[bitmapFileHeaderLength];
      byte[] bitmapInfoHeader = new byte[bitmapInfoHeaderLength];

      input.read(bitmapFileHeader, 0, bitmapFileHeaderLength);
      input.read(bitmapInfoHeader, 0, bitmapInfoHeaderLength);

      int nSize             = bytesToInt(bitmapFileHeader, 2);
      int nWidth            = bytesToInt(bitmapInfoHeader, 4);
      int nHeight           = bytesToInt(bitmapInfoHeader, 8);
      int nBiSize           = bytesToInt(bitmapInfoHeader, 0);
      int nPlanes           = bytesToShort(bitmapInfoHeader, 12);
      int nBitCount         = bytesToShort(bitmapInfoHeader, 14);
      int nSizeImage        = bytesToInt(bitmapInfoHeader, 20);
      int nCompression      = bytesToInt(bitmapInfoHeader, 16);
      int nColoursUsed      = bytesToInt(bitmapInfoHeader, 32);
      int nXPixelsMeter     = bytesToInt(bitmapInfoHeader, 24);
      int nYPixelsMeter     = bytesToInt(bitmapInfoHeader, 28);
      int nImportantColours = bytesToInt(bitmapInfoHeader, 36);

      if(nBitCount==24)
      {
        int npad = ((npad= (nSizeImage / nHeight)  - nWidth * 3)==4 || npad<0)? 0:npad;
        int nindex = 0;
        int[] ndata = new int [nHeight * nWidth];
        byte[] brgb = new byte[( nWidth + npad) * 3 * nHeight];

        input.read (brgb, 0, (nWidth + npad) * 3 * nHeight);
        
        for(int j = 0; j < nHeight; j++)
        {
          for(int i = 0; i < nWidth; i++)
          {
            ndata[nWidth * (nHeight - j - 1) + i] = (      255      & 0xff) << 24|
                                                    (brgb[nindex+2] & 0xff) << 16|
                                                    (brgb[nindex+1] & 0xff) <<  8|
                                                    (brgb[nindex]   & 0xff);
            nindex += 3;
          }
          nindex += npad;
        }
        
        brgb  = null;
        input.close();
        width  = nWidth;
        height = nHeight;
        return ndata;
      }
      else
      {
        if(nBitCount == 8)
        {
          int nNumColors = (nColoursUsed > 0) ? nColoursUsed:(1&0xff)<<nBitCount;

          if(nSizeImage == 0)
          {
            nSizeImage = ((((nWidth*nBitCount)+31) & ~31 ) >> 3);
            nSizeImage *= nHeight;
          }

          int[] npalette = new int[nNumColors];
          byte[] bpalette = new byte[nNumColors*4];
          input.read (bpalette, 0, nNumColors*4);
          int nindex8 = 0;
          

          for(int n = 0; n < nNumColors; n++)
          {
            npalette[n] = (       255          & 0xff) << 24|
                        (bpalette[nindex8+2] & 0xff) << 16|
                        (bpalette[nindex8+1] & 0xff) <<  8|
                        (bpalette[nindex8+0] & 0xff);

            nindex8 += 4;
          }

          int npad8    = (nSizeImage / nHeight) - nWidth;
          int[] ndata8 = new int[nWidth*nHeight];
          byte[] bdata  = new byte[(nWidth+npad8)*nHeight];

          input.read(bdata, 0, (nWidth+npad8)*nHeight);
          nindex8 = 0;

          for(int j8 = 0; j8 < nHeight; j8++)
          {
            for(int i8 = 0; i8 < nWidth; i8++)
            {
              ndata8[nWidth*(nHeight-j8-1)+i8] = npalette[((int)bdata[nindex8]&0xff)];
              nindex8++;
            }
            nindex8 += npad8;
          }
          
          input.close();
          width  = nWidth;
          height = nHeight;
          return ndata8;
        }
        else
          System.out.println ("Not a 24-bit or 8-bit Windows Bitmap, aborting...");
        input.close();
      }
    }
    catch (Exception e)
    {
      System.out.println("Caught exception in loadbitmap!");
    }
    return null;
  }

  public int bytesToInt(byte[] bytes,int index)
  {
    return  (bytes[index+3]&0xff) << 24 |
            (bytes[index+2]&0xff) << 16 |
            (bytes[index+1]&0xff) <<  8 |
             bytes[index+0]&0xff;
  }

  public short bytesToShort(byte[] bytes,int index)
  {
     return (short)((bytes[index+1]&0xff)<<8 | (bytes[index+0]&0xff));
  }

  void destroy()
  {
    data = null;
    width = -1;
    height = -1;
  }
}
