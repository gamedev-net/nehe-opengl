package lesson14;

import lesson14.GLDisplay;
import lesson14.InputHandler;

public class Lesson14 {
    public static void main(String[] args) {
        final GLDisplay neheGLDisplay = new GLDisplay("Lesson 14: Outline fonts");
        Renderer renderer = new Renderer();
        InputHandler inputHandler = new InputHandler(renderer);
        neheGLDisplay.addGLEventListener(renderer);
        neheGLDisplay.addKeyListener(inputHandler);
        neheGLDisplay.setAnimated(true);
        neheGLDisplay.setVisible(true);
    }
}
