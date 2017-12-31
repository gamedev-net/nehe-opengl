NeHe's OpenGL lessons - C# port readme

This application has been converted from the Visual C++ version by NeHe (Jeff Molofee) using
the C# with OpenGL library CsGL (http://csgl.sourceforge.net).
While it's not a perfect conversion, it's pretty dang close.

This application was compiled with Visual Studio .NET 2003, although it will compile easily
with earlier Visual Studio .NET versions and theoretically any C# compiler.

To run this application, there are two requirements.

1) Copy the two CsGL link libraries (csgl.dll and csgl.native.dll) to your 
%systemroot%\system32 folder (probably c:\windows\system32 or c:\winnt\system32).  This
is required for C# to be able to find the libraries to run the application.

2) The Data directory must be a subfolder of the directory containing the executable.  That
means that if you run the unzipped executable you will be fine, but if you compile and run, 
you need to copy the Data folder where the executable builds to.

If you have any questions or comments about this code, feel free to email me at
comp_brain@hotmail.com or visit my website at http://tachyon.unl.edu.  Thanks!

-Brian Holley
