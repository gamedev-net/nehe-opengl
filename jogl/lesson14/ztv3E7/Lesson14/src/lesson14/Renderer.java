package lesson14;

import net.java.games.jogl.GL;
import net.java.games.jogl.GLDrawable;
import net.java.games.jogl.GLEventListener;
import net.java.games.jogl.GLU;
import net.java.games.jogl.util.GLUT;

import java.text.NumberFormat;

class Renderer implements GLEventListener {
    private float rotation;				// Rotation
    private GLUT glut;
    private NumberFormat numberFormat;

    public Renderer() {
        numberFormat = NumberFormat.getNumberInstance();
        numberFormat.setMinimumFractionDigits(2);
        numberFormat.setMaximumFractionDigits(2);
    }

    void renderStrokeString(GL gl, int font, String string) {
        // Center Our Text On The Screen
        float width = glut.glutStrokeLength(font, string);
        gl.glTranslatef(-width / 2f, 0, 0);
        // Render The Text
        for (int i = 0; i < string.length(); i++) {
            char c = string.charAt(i);
            glut.glutStrokeCharacter(gl, font, c);
        }
    }

    public void init(GLDrawable glDrawable) {
        glut = new GLUT();

        GL gl = glDrawable.getGL();
        gl.glShadeModel(GL.GL_SMOOTH);							// Enable Smooth Shading
        gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
        gl.glClearDepth(1.0f);									// Depth Buffer Setup
        gl.glEnable(GL.GL_DEPTH_TEST);							// Enables Depth Testing
        gl.glDepthFunc(GL.GL_LEQUAL);								// The Type Of Depth Testing To Do
        gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);
        gl.glEnable(GL.GL_LIGHT0);								// Enable Default Light (Quick And Dirty)
        gl.glEnable(GL.GL_LIGHTING);								// Enable Lighting
        gl.glEnable(GL.GL_COLOR_MATERIAL);						// Enable Coloring Of Material
    }

    public void display(GLDrawable glDrawable) {
        GL gl = glDrawable.getGL();
        gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
        gl.glLoadIdentity();									// Reset The Current Modelview Matrix
        gl.glTranslatef(0.0f, 0.0f, -15.0f);						// Move One Unit Into The Screen
        gl.glRotatef(rotation, 1.0f, 0.0f, 0.0f);					// Rotate On The X Axis
        gl.glRotatef(rotation * 1.5f, 0.0f, 1.0f, 0.0f);				// Rotate On The Y Axis
        gl.glRotatef(rotation * 1.4f, 0.0f, 0.0f, 1.0f);				// Rotate On The Z Axis
        gl.glScalef(0.005f, 0.005f, 0.0f);
        // Pulsing Colors Based On The Rotation
        gl.glColor3f((float) (Math.cos(rotation / 20.0f)), (float) (Math.sin(rotation / 25.0f)), 1.0f - 0.5f * (float) (Math.cos(rotation / 17.0f)));
        renderStrokeString(gl, GLUT.STROKE_MONO_ROMAN, "NeHe - " + numberFormat.format((rotation / 50))); // Print GL Text To The Screen
        rotation += 0.5f;										// Increase The Rotation Variable
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
