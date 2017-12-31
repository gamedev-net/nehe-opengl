readme.txt (Lesson 23 for Game-Glut)
========================

This is the Game-Glut version for Nehe's lesson 23 on Sphere Environment Mapping.

It uses the base-code from  Milikas Anastasios(Milix)'s Game Glut port for lesson 18.

The new functions added are from GB Schmick (TipTup) 's original win32 version of the tutorial.

Strictly speaking, this code will only run on Windows platform is not portable to other systems as MessageBox() is used in ask_gamemode() function. (I think...)

You might also want to remove the following lines if you are not using VC++ 6.0. (ie Dev-C++, g++, gcc, etc)
Corresponding you have to add these libraries to your compiling procedure(or within your favorite IDE).
-> #pragma comment(lib, "glut32.lib")
-> #pragma comment(lib, "glu32.lib")
-> #pragma comment(lib, "opengl32.lib")
-> #pragma comment(lib, "glaux.lib")


The following two functions were not used in the program, but I left them in place for reference sake. 
- bool load_rgb_image(const char* file_name, int w, int h, RGBIMG* refimg);
- bool setup_textures();

Correspondingly. in the 'bool init(void);'  function. the lines using 'setup_textures()' were commented out. I don't know what does 'glPixelStorei(GL_UNPACK_ALIGNMENT, 1);' do. So if problems occur, you may want to comment it out.

That's all.
Happy GLing. :)