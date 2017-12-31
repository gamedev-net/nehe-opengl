package lesson08;

public class Lesson08 {
    public static void main(String[] args) {
        final GLDisplay neheGLDisplay = new GLDisplay("Lesson 08: Blending");
        Renderer renderer = new Renderer();
        InputHandler inputHandler = new InputHandler(renderer);
        neheGLDisplay.addGLEventListener(renderer);
        neheGLDisplay.addKeyListener(inputHandler);
        neheGLDisplay.setAnimated(true);
        neheGLDisplay.setVisible(true);
    }
}
