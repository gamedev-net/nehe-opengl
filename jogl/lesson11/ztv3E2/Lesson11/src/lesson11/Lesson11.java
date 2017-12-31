package lesson11;

public class Lesson11 {
    public static void main(String[] args) {
        final GLDisplay neheGLDisplay = new GLDisplay("Lesson 11: Flag effect");
        Renderer renderer = new Renderer();
        InputHandler inputHandler = new InputHandler(renderer);
        neheGLDisplay.addGLEventListener(renderer);
        neheGLDisplay.addKeyListener(inputHandler);
        neheGLDisplay.setAnimated(true);
        neheGLDisplay.setVisible(true);
    }
}
