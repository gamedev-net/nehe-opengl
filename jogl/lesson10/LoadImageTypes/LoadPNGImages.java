/*
 * LoadPNGImages.java
 *
 * Created on December 19, 2003, 2:17 AM
 */

package LoadImageTypes;

import java.net.*;
import java.nio.*;
import java.io.*;
import java.awt.image.*;
import javax.imageio.*;
import net.java.games.jogl.util.*;  //required for BufferUtils

/**
 *
 * @author  ncb000gt
 */
public class LoadPNGImages 
{
    private int width;
    private int height;
    private ByteBuffer dest;
    
    /** Creates a new instance of LoadPNGImages */
    public LoadPNGImages() 
    {}
    
    public ByteBuffer getDest()
    {
        return dest;
    }
    
    public int getWidth()
    {
        return width;
    }
    
    public int getHeight()
    {
        return height;
    }
    
    public void getDataAsByteBuffer(URL url)
    {
      try
      {
        if (url == null)
        {
          throw new RuntimeException("Error reading resource " + url.getFile());
        }
        BufferedImage img = ImageIO.read(url);
        java.awt.geom.AffineTransform tx = java.awt.geom.AffineTransform.getScaleInstance(1, -1); 
        tx.translate(0, -img.getHeight(null)); 
        AffineTransformOp op = new AffineTransformOp(tx, AffineTransformOp.TYPE_NEAREST_NEIGHBOR); 
        img = op.filter(img, null);
        width = img.getWidth();
        height = img.getHeight();
        switch (img.getType())
        {
            case BufferedImage.TYPE_3BYTE_BGR:
            case BufferedImage.TYPE_CUSTOM:
                byte[] dataA = ((DataBufferByte)img.getRaster().getDataBuffer()).getData();
                dest = ByteBuffer.allocateDirect(dataA.length);
                dest.order(ByteOrder.nativeOrder());
                dest.put(dataA, 0, dataA.length);
                break;
            case BufferedImage.TYPE_INT_RGB:
                int[] dataB = ((DataBufferInt) img.getRaster().getDataBuffer()).getData();
                dest = ByteBuffer.allocateDirect(dataB.length * BufferUtils.SIZEOF_INT);
                dest.order(ByteOrder.nativeOrder());
                dest.asIntBuffer().put(dataB, 0, dataB.length);
                break;
            default:
                throw new RuntimeException("Unsupported image type " + img.getType());
        }
      }
      catch (IOException e)
      {
        throw new RuntimeException(e);
      }
    }
}
