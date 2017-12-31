/*
 * Options.java
 *
 * Date: 31 JAN 2003
 * Notes: This program was created as a way to implement an interface to let a user choose the settings for the game or OpenGL
 *					application being opened. The settings that are seen here were found in the NeHe basecode. If you want more things...
 *					ADD THEM! :) The original VC++ basecode can be found at http://nehe.gamedev.net...enjoy
 *	Anything else: This code can be used, changed, and distributed so long as there is a reference to me and/or GKE
 *
 *
 */

package OptionFrame;

import javax.swing.*;
import javax.swing.border.*;

import java.awt.*;
import java.awt.event.*;
/**
 *
 * @author  ncb000gt
 */
public class Options extends JFrame 
{
    //setting some predefined settings here
    private String pixels = "1024x768";
    private int width = 1024;
    private int height = 768;
    private boolean fullscreen = true;
    private boolean ok = false;
    private boolean cancel = false;
    private boolean bpp = true;	//32bpp
        
    /** Creates a new instance of Options */
    public Options() 
    {
	//new label and place an image in that label
	//JLabel splashLabel = new JLabel(new ImageIcon(getClass().getResource("resources/images/splash.jpg")));
	//new panels
	JPanel splashButtonPanel0 = new JPanel();
	JPanel splashButtonPanel1 = new JPanel();
	JPanel splashButtonPanel2 = new JPanel();

        //button groups
	ButtonGroup splashButtonGrp1 = new ButtonGroup();
	ButtonGroup splashButtonGrp2 = new ButtonGroup();
	//new buttons for future settings
	JCheckBox jCheckBoxFull = new JCheckBox("Fullscreen mode");
	JRadioButton jRadioButton640 = new JRadioButton("640x480 mode");
	JRadioButton jRadioButton800 = new JRadioButton("800x600 mode");
	JRadioButton jRadioButton1024 = new JRadioButton("1024x768 mode");
	JRadioButton jRadioButton1280 = new JRadioButton("1280x1024 mode");
	JRadioButton jRadioButton16bpp = new JRadioButton("16bpp");
	JRadioButton jRadioButton32bpp = new JRadioButton("32bpp");

	//these are push buttons because i called the other things buttons and i'm too lazy to fix them...that or too tired...:)
	JButton jButtonOk = new JButton("OK");
	JButton jButtonCancel = new JButton("Cancel");

        //create a name for all the buttons we created so we can do certain things if the names match on certain actions
	jCheckBoxFull.setName("Fullscreen");
	jRadioButton640.setName("640x480");
	jRadioButton800.setName("800x600");
	jRadioButton1024.setName("1024x768");
	jRadioButton1280.setName("1280x1024");
	jRadioButton16bpp.setName("16bpp");
	jRadioButton32bpp.setName("32bpp");
	jButtonOk.setName("OK");
	jButtonCancel.setName("Cancel");
	//make this undecorated, get rid of the crap!
	setUndecorated(true);

        //add buttons and the fullscreen box to the splash panel
	splashButtonPanel1.add(jRadioButton640);
	splashButtonPanel1.add(jRadioButton800);
	splashButtonPanel1.add(jRadioButton1024);
	splashButtonPanel1.add(jRadioButton1280);
	splashButtonPanel1.add(jCheckBoxFull);

	//add the bitsperpixel buttons to the correct panel...this currently isn't used but i have been told that you can set this
	//setting in GL so it's here
	splashButtonPanel2.add(jRadioButton16bpp);
	splashButtonPanel2.add(jRadioButton32bpp);

	//add the size buttons to the correct group to specify which one is true and which of the others aren't
	splashButtonGrp1.add(jRadioButton640);
	splashButtonGrp1.add(jRadioButton800);
	splashButtonGrp1.add(jRadioButton1024);
	splashButtonGrp1.add(jRadioButton1280);

	//make a new group for the bpp buttons
	splashButtonGrp2.add(jRadioButton16bpp);
	splashButtonGrp2.add(jRadioButton32bpp);

	//push buttons...are added to the panel
	splashButtonPanel0.add(jButtonOk);
	splashButtonPanel0.add(jButtonCancel);
	//predefined settings for the user
	jCheckBoxFull.setSelected(true);
	jRadioButton1024.setSelected(true);
	jRadioButton32bpp.setSelected(true);

        //create a new actionlistener through an embedded class
	ActionListener actionListener = new ActionListener()
	{
		//has something happened
		public void actionPerformed(ActionEvent ae)
		{
                    //get the source of the action
                    Object actionSource = ae.getSource();
                    //i'm not going through everything, it's self-explainatory if you follow the code...
                    //check the instanceof the object
                    if (actionSource instanceof JCheckBox)
                    {
			//see if the checkbox is selected and if the name matches...
			//strings, because they are objects, need to be checked with the object.equals(""); convention...
			if (((JCheckBox)actionSource).isSelected() && (((JCheckBox)actionSource).getName()).equals("Fullscreen"))
			{
                            System.out.println("Changed the value of: " + ((JCheckBox)actionSource).getName());
                            fullscreen = !fullscreen;
                        }
			else if ((((JCheckBox)actionSource).getName()).equals("Fullscreen"))
			{
                            System.out.println("Changed the value of: " + ((JCheckBox)actionSource).getName());
                            fullscreen = !fullscreen;	//this just makes it's value the opposite, much easier then figuring out if it is checked
																			//before or after you click on it...just a hassle to check that stuff...same thing above!
			}
                    }
                    else if (actionSource instanceof JRadioButton)
                    {
                        if (((JRadioButton)actionSource).isSelected())
                        {
                            //just setting variables...very procedural...but very simple
                            if ((((JRadioButton)actionSource).getName()).equals("640x480"))
                            {
                                System.out.println("Selected: " + ((JRadioButton)actionSource).getName());
                                pixels = "640x480";
                                width = 640;
                                height = 480;
                            }
                            else if ((((JRadioButton)actionSource).getName()).equals("800x600"))
                            {
				System.out.println("Selected: " + ((JRadioButton)actionSource).getName());
				pixels = "800x600";
                                width = 800;
                                height = 600;
                            }
                            else if ((((JRadioButton)actionSource).getName()).equals("1024x768"))
                            {
				System.out.println("Selected: " + ((JRadioButton)actionSource).getName());
				pixels = "1024x768";
                                width = 1024;
                                height = 768;
                            }
                            else if ((((JRadioButton)actionSource).getName()).equals("1280x1024"))
                            {
				System.out.println("Selected: " + ((JRadioButton)actionSource).getName());
				pixels = "1280x1024";
                                width = 1280;
                                height = 1024;
                            }
                            else if ((((JRadioButton)actionSource).getName()).equals("16bpp"))
                            {
				System.out.println("Selected: " + ((JRadioButton)actionSource).getName());
				bpp = false;
                            }
                            else if ((((JRadioButton)actionSource).getName()).equals("32bpp"))
                            {
				System.out.println("Selected: " + ((JRadioButton)actionSource).getName());
				bpp = true;
                            }
                        }
                    }
                    else if (actionSource instanceof JButton)
                    {
                        if (((JButton)actionSource).getName().equals("OK"))
                            ok = true;	//this is used in the RunGL class where it constantly checks to see if OK or cancel were clicked...
			else if (((JButton)actionSource).getName().equals("Cancel"))
                            cancel = true;
                    }
		}
            };

            //we need to listen to certain events on certain objects...this is how
            jCheckBoxFull.addActionListener(actionListener);
            jRadioButton640.addActionListener(actionListener);
            jRadioButton800.addActionListener(actionListener);
            jRadioButton1024.addActionListener(actionListener);
            jRadioButton1280.addActionListener(actionListener);
            jRadioButton16bpp.addActionListener(actionListener);
            jRadioButton32bpp.addActionListener(actionListener);
            jButtonOk.addActionListener(actionListener);
            jButtonCancel.addActionListener(actionListener);
            
            //arrange the stuff we want in a nice layout...
            //getContentPane().add(splashLabel, BorderLayout.NORTH);
            getContentPane().add(splashButtonPanel1, BorderLayout.CENTER);
            getContentPane().add(jCheckBoxFull, BorderLayout.WEST);
            getContentPane().add(splashButtonPanel2, BorderLayout.EAST);
            getContentPane().add(splashButtonPanel0, BorderLayout.SOUTH);
            pack();	//put everything into the frame so that the frame is filled
            //this next line sets the splash location...calculate the middle of the screen...you can test the math...it works...
            setLocation(((Toolkit.getDefaultToolkit().getScreenSize().width/2) - (getWidth()/2)) , ((Toolkit.getDefaultToolkit().getScreenSize().height/2) - (getHeight()/2)));
            //splashLabel.setBorder(BorderFactory.createLineBorder(new Color(75,75,75)));	//generate a line around the label holding the image
            setVisible(true);	//lets see it
    }
    
    	//get and set methods...
	public boolean getFullscreen()
	{
            return fullscreen;
	}

	public boolean getOK()
	{
            return ok;
	}

	public boolean getCancel()
	{
            return cancel;
	}

	public Dimension getPixels()
	{
            return new Dimension(width, height);
	}

	public boolean getBPP()
	{
            return bpp;
	}

	public void setOff()
	{
		setVisible(false);
	}
}