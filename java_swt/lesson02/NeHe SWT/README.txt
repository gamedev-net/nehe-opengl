Oct. 11, 2003

Introduction
---------------------------
In order to run the SWT-OpenGL lessons, you will need the appropriate
Jar and DLL files. Once you have these files, you only need to place
them in the "NeHe SWT" directory. You'll then be able to use the lesson
batch files to run the programs. You will also need to be running under
JDK 1.3 or later, to use SWT or SWT-OpenGL. You can find the latest Java
at http://java.sun.com

Where to download the files
---------------------------
You'll be able to find the files needed to run these lessons at
http://www.eclipse.org

To download SWT go to:
http://download2.eclipse.org/downloads/drops/R-2.1.1-200306271545/index.php
or
downloads->Main Eclipse Download Servers->2.1.1 (or whatever is the latest release)
Go to the bottom of the page, where you will see the "SWT Binary and Source" section.
Download the Windows98/ME/2000/XP version.

To download SWT OpenGL Plugin:
http://dev.eclipse.org/viewcvs/index.cgi/%7Echeckout%7E/platform-swt-home/opengl/opengl.html
or
Projects->The Eclipse Project->Platform->SWT->
Development Resources->Experimental OpenGL Plugin->org.eclipse.swt.opengl
And download the swt-opengl-2.1-win32.zip file.

Installing the files
---------------------------
In the SWT zip file, you will find an swt.jar and swt DLL file. Place
those files in the "NeHe SWT" directory. In the SWT-OpenGL zip file,
you will also find similar files, an opengl.jar and gl-win32.dll.
Also place those in the "NeHe SWT" directory.

Running the lesson
---------------------------
Go to the "NeHe SWT" directory. And double click on the lesson.bat file
that you are interested on. i.e. if you had downloaded lesson 1. Then
there will be a Lesson1.bat in the "NeHe SWT" directory. Double clicking
on Lesson1.bat will run the program.

The batch files setup your classpath, so that java knows where to find
the Jar files it will need for these lessons. At the time of this 
writting, I used the following files to port the lessons to SWT-OpenGL:
openGL.jar from 4/24/03
gl-win32.dll from 4/24/03
swt.jar version 2.1.1
swt-win32-2135.dll