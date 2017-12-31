package lesson11;

import net.java.games.jogl.GL;
import net.java.games.jogl.GLDrawable;
import net.java.games.jogl.GLEventListener;
import net.java.games.jogl.GLU;

import java.io.IOException;

class Renderer implements GLEventListener {
    float[][][] points = new float[45][45][3];    // The Array For The Points On The Grid Of Our "Wave"
    int wiggle_count = 0;		// Counter Used To Control How Fast Flag Waves
    float xrot;				// X Rotation ( NEW )
    float yrot;				// Y Rotation ( NEW )
    float zrot;				// Z Rotation ( NEW )
    float hold;
    int[] textures = new int[1]; //Storage for one texture ( NEW )

    private boolean loadGLTextures(GLDrawable gldrawable) {
        TextureReader.Texture texture = null;
        try {
            texture = TextureReader.readTexture("data/tim.png");
        } catch (IOException e) {
            return false;
        }

        GL gl = gldrawable.getGL();

        //Create Nearest Filtered Texture
        gl.glGenTextures(1, textures);
        gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]);

        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
        gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);

        gl.glTexImage2D(GL.GL_TEXTURE_2D,
                0,
                3,
                texture.getWidth(),
                texture.getHeight(),
                0,
                GL.GL_RGB,
                GL.GL_UNSIGNED_BYTE,
                texture.getPixels());
        return true;
    }

    public void init(GLDrawable glDrawable) {
        if (!loadGLTextures(glDrawable)) {
            System.out.println("Failed to load Textures,Bailing!");
            System.exit(0);
        }

        GL gl = glDrawable.getGL();
        gl.glEnable(GL.GL_TEXTURE_2D);						          // Enable Texture Mapping ( NEW )
        gl.glShadeModel(GL.GL_SMOOTH);                            //Enables Smooth Color Shading
        gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);               //This Will Clear The Background Color To Black
        gl.glClearDepth(1.0);                                  //Enables Clearing Of The Depth Buffer
        gl.glEnable(GL.GL_DEPTH_TEST);                            //Enables Depth Testing
        gl.glDepthFunc(GL.GL_LEQUAL);                             //The Type Of Depth Test To Do
        gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);  // Really Nice Perspective Calculations

        for (int x = 0; x < 45; x++) {
            for (int y = 0; y < 45; y++) {
                points[x][y][0] = ((x / 5.0f) - 4.5f);
                points[x][y][1] = ((y / 5.0f) - 4.5f);
                points[x][y][2] = (float) (Math.sin((((x / 5.0f) * 40.0f) / 360.0f) * 3.141592654 * 2.0f));
            }
        }
    }

    public void display(GLDrawable glDrawable) {
        GL gl = glDrawable.getGL();
        int x, y;
        float float_x, float_y, float_xb, float_yb;

        gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
        gl.glLoadIdentity();									// Reset The View

        gl.glTranslatef(0.0f, 0.0f, -12.0f);

        gl.glRotatef(xrot, 1.0f, 0.0f, 0.0f);
        gl.glRotatef(yrot, 0.0f, 1.0f, 0.0f);
        gl.glRotatef(zrot, 0.0f, 0.0f, 1.0f);

        gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]);

        gl.glBegin(GL.GL_QUADS);
        for (x = 0; x < 44; x++) {
            for (y = 0; y < 44; y++) {
                float_x = (float) (x) / 44.0f;
                float_y = (float) (y) / 44.0f;
                float_xb = (float) (x + 1) / 44.0f;
                float_yb = (float) (y + 1) / 44.0f;

                gl.glTexCoord2f(float_x, float_y);
                gl.glVertex3f(points[x][y][0], points[x][y][1], points[x][y][2]);

                gl.glTexCoord2f(float_x, float_yb);
                gl.glVertex3f(points[x][y + 1][0], points[x][y + 1][1], points[x][y + 1][2]);

                gl.glTexCoord2f(float_xb, float_yb);
                gl.glVertex3f(points[x + 1][y + 1][0], points[x + 1][y + 1][1], points[x + 1][y + 1][2]);

                gl.glTexCoord2f(float_xb, float_y);
                gl.glVertex3f(points[x + 1][y][0], points[x + 1][y][1], points[x + 1][y][2]);
            }
        }
        gl.glEnd();

        if (wiggle_count == 2) {
            for (y = 0; y < 45; y++) {
                hold = points[0][y][2];
                for (x = 0; x < 44; x++) {
                    points[x][y][2] = points[x + 1][y][2];
                }
                points[44][y][2] = hold;
            }
            wiggle_count = 0;
        }

        wiggle_count++;

        xrot += 0.3f;
        yrot += 0.2f;
        zrot += 0.4f;
    }

    public void reshape(GLDrawable glDrawable, int x, int y, int w, int h) {
        if (h == 0) h = 1;
        GL gl = glDrawable.getGL();
        GLU glu = glDrawable.getGLU();
        gl.glViewport(0, 0, w, h);                       // Reset The Current Viewport And Perspective Transformation
        gl.glMatrixMode(GL.GL_PROJECTION);                           // Select The Projection Matrix
        gl.glLoadIdentity();                                      // Reset The Projection Matrix
        glu.gluPerspective(45.0f, w / h, 0.1f, 100.0f);  // Calculate The Aspect Ratio Of The Window
        gl.glMatrixMode(GL.GL_MODELVIEW);                            // Select The Modelview Matrix
        gl.glLoadIdentity();                                      // Reset The ModalView Matrix
    }

    public void displayChanged(GLDrawable glDrawable, boolean b, boolean b1) {
    }
}
