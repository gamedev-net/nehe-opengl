package lesson08;

import net.java.games.jogl.GLCanvas;
import net.java.games.jogl.GLCapabilities;
import net.java.games.jogl.GLDrawableFactory;
import net.java.games.jogl.GLEventListener;

import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyListener;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.util.TimerTask;

class GLDisplay {
    private static final int DEFAULT_WIDTH = 640;
    private static final int DEFAULT_HEIGHT = 480;
    private static final int DEFAULT_ANIMATION_DELAY = 1000 / 60;

    private JFrame frame;
    private GLCanvas glCanvas;
    private java.util.Timer animationTimer;
    private TimerTask animationTimerTask = new AnimatorTimerTask();
    private boolean initialized = false;

    public GLDisplay(String title) {
        this(title, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }

    public GLDisplay(String title, int width, int height) {
        glCanvas = GLDrawableFactory.getFactory().createGLCanvas(new GLCapabilities());
        glCanvas.setSize(width, height);
        glCanvas.setIgnoreRepaint(true);

        frame = new JFrame(title);
        frame.getContentPane().setLayout(new BorderLayout());
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        setAnimated(false);
    }

    public void addGLEventListener(GLEventListener glEventListener) {
        glCanvas.addGLEventListener(glEventListener);
    }

    public void removeGLEventListener(GLEventListener glEventListener) {
        glCanvas.removeGLEventListener(glEventListener);
    }

    private void setupFrame() {
        frame.getContentPane().add(glCanvas);
        frame.pack();
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        frame.setLocation(
                (screenSize.width - frame.getWidth()) / 2,
                (screenSize.height - frame.getHeight()) / 2
        );
    }

    public synchronized void setVisible(boolean visible) {
        if (visible && !initialized) {
            setupFrame();
            initialized = true;
        }
        frame.setVisible(visible);
    }

    public synchronized boolean isVisible() {
        return frame.isVisible();
    }

    public void setAnimated(boolean animated) {
        setAnimated(animated, DEFAULT_ANIMATION_DELAY);
    }

    public void setAnimated(boolean animated, int delay) {
        if (animated) {
            animationTimer = new java.util.Timer();
            animationTimer.scheduleAtFixedRate(animationTimerTask, 0, delay);
        } else {
            if (animationTimer != null)
                animationTimer.cancel();
        }
    }

    public void addKeyListener(KeyListener l) {
        glCanvas.addKeyListener(l);
    }

    public void addMouseListener(MouseListener l) {
        glCanvas.addMouseListener(l);
    }

    public void addMouseMotionListener(MouseMotionListener l) {
        glCanvas.addMouseMotionListener(l);
    }

    public void removeKeyListener(KeyListener l) {
        glCanvas.removeKeyListener(l);
    }

    public void removeMouseListener(MouseListener l) {
        glCanvas.removeMouseListener(l);
    }

    public void removeMouseMotionListener(MouseMotionListener l) {
        glCanvas.removeMouseMotionListener(l);
    }

    private class AnimatorTimerTask extends TimerTask {
        public void run() {
            glCanvas.display();
        }
    }
}
