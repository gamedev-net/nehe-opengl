/* Author: Victor Gonzalez Jr
 * Created on Oct 11, 2003
 */
package org.nehe.lesson2;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.*;
import org.eclipse.swt.widgets.*;

/** The Launcher class has the main method needed to start the lesson. */
public class Launcher
{
    /** The main method is the entry point for our Java application */
    public static void main(String[] args) {
        /* Create a display so that the UI functionality can be accessed */
        Display display = new Display();
        /* Create a standard shell (aka Window) */
        Shell shell = new Shell(display, SWT.SHELL_TRIM | SWT.NO_BACKGROUND);
        shell.setText("Your First Polygon");  // Set the window caption title
        shell.setLayout(new FillLayout()); // Set the layout style to Fill
        shell.setSize(640, 480);           // Set the window size to 640x480
        NeHeCanvas canvas = new NeHeCanvas(shell); // Create NeHeCanvas
        canvas.run();  // Start the rendering thread
        shell.open();  // Open the window
        while (!shell.isDisposed()) {       // Loop until shell is diposed/close
            if (!display.readAndDispatch()) // 
                display.sleep();
        }
    }
}