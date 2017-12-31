package lesson08;

import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;

class InputHandler extends KeyAdapter {
    private Renderer renderer;

    public InputHandler(Renderer renderer) {
        this.renderer = renderer;
    }

    public void keyPressed(KeyEvent e) {
        switch (e.getKeyCode()) {
            case KeyEvent.VK_ESCAPE:
                System.exit(0);
                //toggle lighting
            case KeyEvent.VK_L:
                renderer.setLightingEnabled(!renderer.isLightingEnabled());
                break;
            case KeyEvent.VK_F:
                renderer.switchFilter();
                break;
            case KeyEvent.VK_B:
                renderer.setBlendingEnabled(!renderer.isBlendingEnabled());
                break;
            case KeyEvent.VK_PAGE_UP:
                renderer.setZ(renderer.getZ() - 0.02f);
                break;
            case KeyEvent.VK_PAGE_DOWN:
                renderer.setZ(renderer.getZ() + 0.02f);
                break;
            case KeyEvent.VK_UP:
                renderer.setXspeed(renderer.getXspeed() - 0.01f);
                break;
            case KeyEvent.VK_DOWN:
                renderer.setXspeed(renderer.getXspeed() + 0.01f);
                break;
            case KeyEvent.VK_RIGHT:
                renderer.setYspeed(renderer.getYspeed() + 0.01f);
                break;
            case KeyEvent.VK_LEFT:
                renderer.setYspeed(renderer.getYspeed() - 0.01f);
                break;
        }
    }
}
