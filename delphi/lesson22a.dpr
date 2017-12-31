program lesson22a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL,sysutils,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type    // Definice rozšíøených možností OpenGL
  PFNGLMULTITEXCOORD1FARBPROC = procedure(target: GLenum; s,t : GLfloat); stdcall;
  PFNGLMULTITEXCOORD2FARBPROC = procedure(target: GLenum; s,t : GLfloat); stdcall;
  PFNGLMULTITEXCOORD3FARBPROC = procedure(target: GLenum; s,t : GLfloat); stdcall;
  PFNGLMULTITEXCOORD4FARBPROC = procedure(target: GLenum; s,t : GLfloat); stdcall;
  PFNGLACTIVETEXTUREARBPROC = procedure(target: GLenum); stdcall;
  PFNGLCLIENTACTIVETEXTUREARBPROC = procedure(target: GLenum); stdcall;

const
  MAX_EMBOSS = 0.008;               // Maximální posunutí efektem
  __ARB_ENABLE = true;              // Použito pro vyøazení multitexturingu
  MAX_EXTENSION_SPACE = 10240;      // Místo pro øetìzce s OpenGL rozšíøeními
  MAX_EXTENSION_LENGTH = 256;       // Maximum znakù v jednom øetìzci s rozšíøením
  EXT_INFO = false;                 // true, pokud chcete pøi startu vidìt podporovaná rozšíøení OpenGL
  GL_MAX_TEXTURE_UNITS_ARB = $84E2; // Konstanty rozšíøení, které budeme potøebovat
  GL_RGB8 = $8051;
  GL_RGBA8 = $8058;
  GL_TEXTURE0_ARB = $84C0;
  GL_COMBINE_EXT = $8570;
  GL_COMBINE_RGB_EXT = $8571;
  GL_TEXTURE1_ARB = $84C1;

var
  h_Rc: HGLRC;		                  // Trvalý Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  xrot: GLFloat;                    // X rotace
  yrot: GLFloat;                    // Y rotace
  xspeed: GLfloat;                  // Rychlost x rotace
  yspeed: GLfloat;                  // Rychlost y rotace
  z: GLfloat = -5.0;                // Hloubka v obrazovce
  filter: GLuint = 1;               // Jaký filtr použít
  texture: array [0..2] of GLuint;  // Místo pro tøi textury
  bump: array [0..2] of GLuint;     // Naše bumpmapy
  invbump: array [0..2] of GLuint;  // Invertované bumpmapy
  glLogo: GLuint;                   // Místo pro OpenGL Logo
  multiLogo: GLuint;                // Místo pro logo s multitexturingem
  LightAmbient: array [0..2] of GLfloat = ( 0.2, 0.2, 0.2);           // Barva ambientního svìtla je 20% bílá
  LightDiffuse: array [0..2] of GLfloat = ( 1.0, 1.0, 1.0);           // Difúzní svìtlo je bílé
  LightPosition: array [0..2] of GLfloat = ( 0.0, 0.0, 2.0);          // Pozice je nìkde uprostøed scény
  Gray: array [0..3] of GLfloat = ( 0.5, 0.5, 0.5, 1.0 );             // Barva okraje textury
  emboss: bool = false;                                               // Jenom Emboss, žádná základní textura
  bumps: bool = true;                                                 // Používat bumpmapping?
  Multitexturesupported: bool = false;                                // Indikátor podpory multitexturingu
  UseMultitexture: bool = true;                                       // Použit multitexturing?
  maxTexelUnits: GLint = 1;                                           // Poèet texturovacích jednotek - nejménì 1
  glMultiTexCoord1fARB: PFNGLMULTITEXCOORD1FARBPROC = nil;
  glMultiTexCoord2fARB: PFNGLMULTITEXCOORD2FARBPROC = nil;
  glMultiTexCoord3fARB: PFNGLMULTITEXCOORD3FARBPROC = nil;
  glMultiTexCoord4fARB: PFNGLMULTITEXCOORD4FARBPROC = nil;
  glActiveTextureARB: PFNGLACTIVETEXTUREARBPROC = nil;
  glClientActiveTextureARB: PFNGLCLIENTACTIVETEXTUREARBPROC = nil;
  data : Array [0..119] of GLfloat = (
		// Pøední stìna
		0.0, 0.0,		-1.0, -1.0, +1.0,
		1.0, 0.0,		+1.0, -1.0, +1.0,
		1.0, 1.0,		+1.0, +1.0, +1.0,
		0.0, 1.0,		-1.0, +1.0, +1.0,
		// Zadní stìna
		1.0, 0.0,		-1.0, -1.0, -1.0,
		1.0, 1.0,		-1.0, +1.0, -1.0,
		0.0, 1.0,		+1.0, +1.0, -1.0,
		0.0, 0.0,		+1.0, -1.0, -1.0,
		// Horní stìna
		0.0, 1.0,		-1.0, +1.0, -1.0,
		0.0, 0.0,		-1.0, +1.0, +1.0,
		1.0, 0.0,		+1.0, +1.0, +1.0,
		1.0, 1.0,		+1.0, +1.0, -1.0,
		// Dolní stìna
		1.0, 1.0,		-1.0, -1.0, -1.0,
		0.0, 1.0,		+1.0, -1.0, -1.0,
		0.0, 0.0,		+1.0, -1.0, +1.0,
		1.0, 0.0,		-1.0, -1.0, +1.0,
		// Pravá stìna
		1.0, 0.0,		+1.0, -1.0, -1.0,
		1.0, 1.0,		+1.0, +1.0, -1.0,
		0.0, 1.0,		+1.0, +1.0, +1.0,
		0.0, 0.0,		+1.0, -1.0, +1.0,
		// Levá stìna
		0.0, 0.0,		-1.0, -1.0, -1.0,
		1.0, 0.0,		-1.0, -1.0,  1.0,
		1.0, 1.0,		-1.0,  1.0,  1.0,
		0.0, 1.0,		-1.0,  1.0, -1.0);

function isInString(strings: pchar; searchstring: pchar): boolean;
begin
  if Pos(searchstring,strings) <> 0 then Result := true       // Hledání celého øetìzce jména rozšíøení
    else Result := false;                                     // Smùla, nic jsme nenašli!
end;

function initMultitexture: boolean;
var extensions: pchar;
begin
  extensions := glGetString(GL_EXTENSIONS);                                     // Získání øetìzce s rozšíøeními
  if EXT_INFO then MessageBox(h_Wnd,extensions,'OpenGL extensions',MB_OK or MB_ICONINFORMATION);
  if (isInString(extensions,'GL_ARB_multitexture')) and __ARB_ENABLE            // Je multitexturing podporován? a Pøíznak pro povolení multitexturingu
      and isInString(extensions,'GL_EXT_texture_env_combine') then              // Je podporováno texture-environment-combining?
    begin
    glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB,@maxTexelUnits);
    glMultiTexCoord1fARB := wglGetProcAddress('glMultiTexCoord1fARB');
    glMultiTexCoord2fARB := wglGetProcAddress('glMultiTexCoord2fARB');
    glMultiTexCoord3fARB := wglGetProcAddress('glMultiTexCoord3fARB');
    glMultiTexCoord4fARB := wglGetProcAddress('glMultiTexCoord4fARB');
    glActiveTextureARB := wglGetProcAddress('glActiveTextureARB');
    glClientActiveTextureARB := wglGetProcAddress('glClientActiveTextureARB');
    if EXT_INFO then MessageBox(h_Wnd,'The GL_ARB_multitexture extension will be used.','Feature supported!',MB_OK or MB_ICONINFORMATION);
    Result := true;
    exit;
    end;
  UseMultitexture := false;                                                     // Nemùžeme to používat, pokud to není podporováno!
  Result := false;
end;

procedure initLights;
begin
  glLightfv(GL_LIGHT1,GL_AMBIENT,@LightAmbient);          // Naètení informace o svìtlech do GL_LIGHT1
  glLightfv(GL_LIGHT1,GL_DIFFUSE,@LightDiffuse);
  glLightfv(GL_LIGHT1,GL_POSITION,@LightPosition);
  glEnable(GL_LIGHT1);
end;

function LoadBMP(FileName: pchar):PTAUX_RGBImageRec;        // Nahraje bitmapu
begin
  if Filename = '' then                                     // Byla pøedána cesta k souboru?
    begin
    Result := nil;                                          // Pokud ne, konec
    exit;
    end;
  if not FileExists(Filename) then                          // Existuje soubor?
    begin
    Result := nil;                                          // Pokud ne, konec
    exit;
    end;
  Result := auxDIBImageLoadA(FileName);                     // Naète bitmapu a vrátí na ni ukazatel
end;

function LoadGLTextures: Bool;                              // Loading bitmapy a konverze na texturu
type Tznak = array [0..255] of byte;                        // Typ pole znakù
var TextureImage: array [0..0] of PTAUX_RGBImageRec;        // Ukládá bitmapu
    Status: Bool;                                           // Indikuje chyby
    i: integer;                                             // Cyklus
    bumpmap, alpha, alpha1: ^Tznak;                         // Pomocné promìnné pro výpoèet bumpmapy a log
begin
  Status := false;
  ZeroMemory(@TextureImage,sizeof(TextureImage));           // Vynuluje pamì
  TextureImage[0] := LoadBMP('Data/Base.bmp');              // Nahraje bitmapu
  if Assigned(TextureImage[0]) then                         // Vše je bez problémù?
    begin
    Status := true;                                         // Vše je bez problémù
    glGenTextures(3,Texture[0]);                            // Generuje tøi textury
    // Vytvoøení nelineárnì filtrované textury
    glBindTexture(GL_TEXTURE_2D,texture[0]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);
    // Vytvoøení lineárnì filtrované textury
    glBindTexture(GL_TEXTURE_2D,texture[1]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);
    // Vytvoøení mipmapované textury
    glBindTexture(GL_TEXTURE_2D,texture[2]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);
    end
    else Status := false;
  TextureImage[0] := LoadBMP('Data/Bump.bmp');              // Loading bumpmap
  if Assigned(TextureImage[0]) then
    begin
    glPixelTransferf(GL_RED_SCALE,0.5);                     // Snížení intenzity RGB na 50% - polovièní intenzita
    glPixelTransferf(GL_GREEN_SCALE,0.5);
    glPixelTransferf(GL_BLUE_SCALE,0.5);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);        // Bez wrappingu (zalamování)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
    glTexParameterfv(GL_TEXTURE_2D,GL_TEXTURE_BORDER_COLOR,@gray);    // Barva okraje textury
    glGenTextures(3,bump[0]);                                         // Vytvoøí tøi textury
    // Vytvoøení nelineárnì filtrované textury
    glBindTexture(GL_TEXTURE_2D,bump[0]);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    // Vytvoøení lineárnì filtrované textury
    glBindTexture(GL_TEXTURE_2D,bump[1]);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    // Vytvoøení mipmapované textury
    glBindTexture(GL_TEXTURE_2D,bump[2]);
    gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    //**************************************************************************
    // Invertování bumpmapy
    // V Delphi to bohužel nejde tak jednoduše jako v C++. Pøekladaè ohlásí chybu.
    // Dle nápovìdy je toto správný opis konstrukce z C++. Doufám :-)))
    // U vytváøení textur nezapomeòte pøedat pomocnou promìnnou (bumpmap) místo
    // dat z TextureImage[0].data!!!!!!!
    //**************************************************************************
    GetMem(bumpmap,3*TextureImage[0].sizeX*TextureImage[0].sizeY);              // Alokace pamìti pro pomocnou promìnnou
    bumpmap := TextureImage[0].data;                                            // Pøedání dat do pomocné promìnné
    for i:= 0 to 3*TextureImage[0].sizeX*TextureImage[0].sizeY-1 do             // Vlastní invertování
      begin
      bumpmap[i] := 255 - bumpmap[i];
      end;
    glGenTextures(3,invbump[0]);                                                // Vytvoøí tøi textury
    // Vytvoøení nelineárnì filtrované textury
    glBindTexture(GL_TEXTURE_2D,invbump[0]);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,bumpmap);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    // Vytvoøení lineárnì filtrované textury
    glBindTexture(GL_TEXTURE_2D,invbump[1]);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,bumpmap);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    // Vytvoøení mipmapované textury
    glBindTexture(GL_TEXTURE_2D,invbump[2]);
    gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGB8,TextureImage[0].sizeX,TextureImage[0].sizeY,GL_RGB,GL_UNSIGNED_BYTE,bumpmap);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    glPixelTransferf(GL_RED_SCALE,1.0);                     // Vrácení intenzity RGB zpìt na 100%
    glPixelTransferf(GL_GREEN_SCALE,1.0);
    glPixelTransferf(GL_BLUE_SCALE,1.0);
    bumpmap := nil;
    FreeMem(bumpmap);                                       // Uvolnìní pamìti po pomocné promìnné
    end
    else Status := false;
  TextureImage[0] := LoadBMP('Data/OpenGL_ALPHA.bmp');      // Naète bitmapy log
  if Assigned(TextureImage[0]) then
    begin
    GetMem(alpha,4*TextureImage[0].sizeX*TextureImage[0].sizeY);                // Alokuje pamì pro RGBA8-Texturu
    //**************************************************************************
    // Alfa kanál loga OpenGL
    // V Delphi to bohužel nejde tak jednoduše jako v C++. Pøekladaè ohlásí chybu.
    // Dle nápovìdy je toto správný opis konstrukce z C++. Doufám :-)))
    //**************************************************************************
    GetMem(alpha1,sizeof(TextureImage[0].data));                                // Alokace pamìti pro pomocnou promìnnou
    alpha1 := TextureImage[0].data;                                             // Pøedání dat do pomocné promìnné
    for i:=0 to TextureImage[0].sizeX*TextureImage[0].sizeY-1 do
      alpha[4*i+3] := alpha1[i*3];                                              // Vezme pouze èervenou barvu jako alpha kanál
    alpha1 := nil;
    FreeMem(alpha1);                                                            // Uvolnìní pamìti po pomocné promìnné
    TextureImage[0] := LoadBMP('Data/OpenGL.bmp');
    if not Assigned(TextureImage[0]) then Status := false;
    GetMem(alpha1,sizeof(TextureImage[0].data));                                // Alokace pamìti pro pomocnou promìnnou
    alpha1 := TextureImage[0].data;                                             // Pøedání dat do pomocné promìnné
    for i:=0 to TextureImage[0].sizeX*TextureImage[0].sizeY-1 do
      begin
      alpha[4*i] := alpha1[i*3];                                                // R
      alpha[4*i+1] := alpha1[i*3+1];                                            // G
      alpha[4*i+2] := alpha1[i*3+2];                                            // B
      end;
    glGenTextures(1,glLogo);                                                    // Vytvoøí jednu texturu
    // Vytvoøí lineárnì filtrovanou RGBA8-Texturu
    glBindTexture(GL_TEXTURE_2D,glLogo);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGBA,GL_UNSIGNED_BYTE,alpha);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    alpha := nil;
    alpha1 := nil;
    FreeMem(alpha);                                                             // Uvolní alokovanou pamì
    FreeMem(alpha1);                                                            // Uvolnìní pamìti po pomocné promìnné
    end
    else Status := false;
  TextureImage[0] := LoadBMP('Data/multi_on_alpha.bmp');
  if Assigned(TextureImage[0]) then
    begin
    GetMem(alpha,4*TextureImage[0].sizeX*TextureImage[0].sizeY);                // Alokuje pamì pro RGBA8-Texturu
    //**************************************************************************
    // Alfa kanál loga multitexturingu
    // V Delphi to bohužel nejde tak jednoduše jako v C++. Pøekladaè ohlásí chybu.
    // Dle nápovìdy je toto správný opis konstrukce z C++. Doufám :-)))
    //**************************************************************************
    GetMem(alpha1,sizeof(TextureImage[0].data));                                // Alokace pamìti pro pomocnou promìnnou
    alpha1 := TextureImage[0].data;                                             // Pøedání dat do pomocné promìnné
    for i:=0 to TextureImage[0].sizeX*TextureImage[0].sizeY-1 do
      alpha[4*i+3] := alpha1[i*3];                                              // Vezme pouze èervenou barvu jako alpha kanál
    alpha1 := nil;
    FreeMem(alpha1);                                                            // Uvolnìní pamìti po pomocné promìnné
    TextureImage[0] := LoadBMP('Data/multi_on.bmp');
    if not Assigned(TextureImage[0]) then Status := false;
    GetMem(alpha1,sizeof(TextureImage[0].data));                                // Alokace pamìti pro pomocnou promìnnou
    alpha1 := TextureImage[0].data;                                             // Pøedání dat do pomocné promìnné
    for i:=0 to TextureImage[0].sizeX*TextureImage[0].sizeY-1 do
      begin
      alpha[4*i] := alpha1[i*3];                                                // R
      alpha[4*i+1] := alpha1[i*3+1];                                            // G
      alpha[4*i+2] := alpha1[i*3+2];                                            // B
      end;
    glGenTextures(1,multiLogo);                                                 // Vytvoøí jednu texturu
    // Vytvoøí lineárnì filtrovanou RGBA8-Texturu
    glBindTexture(GL_TEXTURE_2D,multiLogo);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGBA,GL_UNSIGNED_BYTE,alpha);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    alpha := nil;
    alpha1 := nil;
    FreeMem(alpha);                                                             // Uvolní alokovanou pamì
    FreeMem(alpha1);                                                            // Uvolnìní pamìti po pomocné promìnné
    end
    else Status := false;
  Result := Status;                                         // Oznámí pøípadné chyby
end;

procedure doCube;                                           // Kostka
var i: integer;
begin
  glBegin(GL_QUADS);
    // Pøední stìna
    glNormal3f( 0.0, 0.0, +1.0);
    for i := 0 to 3 do
      begin
      glTexCoord2f(data[5*i],data[5*i+1]);
      glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
      end;
    // Zadní stìna
    glNormal3f( 0.0, 0.0,-1.0);
    for i := 4 to 7 do
      begin
      glTexCoord2f(data[5*i],data[5*i+1]);
      glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
      end;
    // Horní stìna
    glNormal3f( 0.0, 1.0, 0.0);
    for i := 8 to 11 do
      begin
      glTexCoord2f(data[5*i],data[5*i+1]);
      glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
      end;
    // Spodní stìna
    glNormal3f( 0.0,-1.0, 0.0);
    for i := 12 to 15 do
      begin
      glTexCoord2f(data[5*i],data[5*i+1]);
      glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
      end;
    // Pravá stìna
    glNormal3f( 1.0, 0.0, 0.0);
    for i := 16 to 19 do
      begin
      glTexCoord2f(data[5*i],data[5*i+1]);
      glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
      end;
    // Levá stìna
    glNormal3f(-1.0, 0.0, 0.0);
    for i := 20 to 23 do
      begin
      glTexCoord2f(data[5*i],data[5*i+1]);
      glVertex3f(data[5*i+2],data[5*i+3],data[5*i+4]);
      end;
  glEnd();
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // Zmìna velikosti a inicializace OpenGL okna
begin
  if (Height=0) then		                                  // Zabezpeèení proti dìlení nulou
     Height:=1;                                           // Nastaví výšku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktuální nastavení
  glMatrixMode(GL_PROJECTION);                            // Zvolí projekèní matici
  glLoadIdentity();                                       // Reset matice
  gluPerspective(45.0,Width/Height,0.1,100.0);            // Výpoèet perspektivy
  glMatrixMode(GL_MODELVIEW);                             // Zvolí matici Modelview
  glLoadIdentity;                                         // Reset matice
end;

function InitGL:bool;	                              // Všechno nastavení OpenGL
begin
  Multitexturesupported := initMultitexture;        // Zjistí podporu multitexturingu
  if not LoadGLTextures then                        // Nahraje texturu
    begin
    Result := false;
    exit;
    end;
  glEnable(GL_TEXTURE_2D);                          // Zapne mapování textur
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glDepthFunc(GL_LEQUAL);				                    // Typ hloubkového testování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Nejlepší perspektivní korekce
  initLights;                                       // Inicializace svìtel
  Result:=true;                                     // Inicializace probìhla v poøádku
end;

procedure VMatMult(var M, v: array of GLfloat);
var res: array [0..2] of GLfloat;
begin
  res[0]:=M[ 0]*v[0]+M[ 1]*v[1]+M[ 2]*v[2]+M[ 3]*v[3];
  res[1]:=M[ 4]*v[0]+M[ 5]*v[1]+M[ 6]*v[2]+M[ 7]*v[3];
  res[2]:=M[ 8]*v[0]+M[ 9]*v[1]+M[10]*v[2]+M[11]*v[3];
  v[0]:=res[0];
  v[1]:=res[1];
  v[2]:=res[2];
  v[3]:=M[15];			                                // Homogenní souøadnice
end;

procedure SetUpBumps(var n, c, l, s, t: array of GLfloat);
var
  v: array [0..2] of GLfloat;                           // Vertex z aktuální pozice ke svìtlu
  lenQ: GLfloat;                                        // Použito pøi normalizaci
begin
  //****************************************************************************
  // Funkce nastaví posunutí textury
  // n : normála k ploše, musí mít délku 1
  // c : nìjaký bod na povrchu
  // l : pozice svìtla
  // s : smìr texturovacích souøadnic s (musí být normalizován!)
  // t : smìr texturovacích souøadnic t (musí být normalizován!)
  //****************************************************************************
  // Spoèítání v z aktuálního vertexu c ke svìtlu a jeho normalizace
  v[0]:=l[0]-c[0];
  v[1]:=l[1]-c[1];
  v[2]:=l[2]-c[2];
  lenQ:=sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
  v[0] := v[0] / lenQ;
  v[1] := v[1] / lenQ;
  v[2] := v[2] / lenQ;
  // Zohlednìní v tak, abychom dostali texturovací souøadnice
  c[0]:=(s[0]*v[0]+s[1]*v[1]+s[2]*v[2])*MAX_EMBOSS;
  c[1]:=(t[0]*v[0]+t[1]*v[1]+t[2]*v[2])*MAX_EMBOSS;
end;

procedure doLogo;			// MUSÍ SE ZAVOLAT AŽ NAKONEC!!! Zobrazí dvì loga
begin
  glDepthFunc(GL_ALWAYS);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING);
  glLoadIdentity();
  glBindTexture(GL_TEXTURE_2D,glLogo);
  glBegin(GL_QUADS);
    glTexCoord2f(0.0,0.0);	glVertex3f(0.23, -0.4,-1.0);
    glTexCoord2f(1.0,0.0);	glVertex3f(0.53, -0.4,-1.0);
    glTexCoord2f(1.0,1.0);	glVertex3f(0.53, -0.25,-1.0);
    glTexCoord2f(0.0,1.0);	glVertex3f(0.23, -0.25,-1.0);
  glEnd();
  if (useMultitexture) then
  begin
    glBindTexture(GL_TEXTURE_2D,multiLogo);
    glBegin(GL_QUADS);
      glTexCoord2f(0.0,0.0);	glVertex3f(-0.53, -0.4,-1.0);
      glTexCoord2f(1.0,0.0);	glVertex3f(-0.33, -0.4,-1.0);
      glTexCoord2f(1.0,1.0);	glVertex3f(-0.33, -0.3,-1.0);
      glTexCoord2f(0.0,1.0);	glVertex3f(-0.53, -0.3,-1.0);
    glEnd();
  end;
  glDepthFunc(GL_LEQUAL);
end;

function doMesh1TexelUnits : boolean;
var
  c : array [0..3] of GLfloat;					                // Aktuální vertex
  n : array [0..3] of GLfloat;					                // Normalizovaná normála daného povrchu
  s : array [0..3] of GLfloat;					                // Smìr texturovacích souøadnic s, normalizováno
  t : array [0..3] of GLfloat;					                // Smìr texturovacích souøadnic t, normalizováno
  l : array [0..3] of GLfloat;										      // Pozice svìtla, která bude transformována do prostoru objektu
  Minv : array [0..15] of GLfloat;									    // Pøevrácená modelview matice
  i : integer;
begin
  c[3] := 1.0;
  n[3] := 1.0;
  s[3] := 1.0;
  t[3] := 1.0;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);	// Smaže obrazovku a hloubkový buffer
  // Sestavení pøevrácené modelview matice; nahradí funkce Push a Pop jednou funkcí glLoadIdentity()
  // Jednoduché sestavení tím, že všechny transformace provedeme opaènì a v opaèném poøadí
  glLoadIdentity();
  glRotatef(-yrot,0.0,1.0,0.0);
  glRotatef(-xrot,1.0,0.0,0.0);
  glTranslatef(0.0,0.0,-z);
  glGetFloatv(GL_MODELVIEW_MATRIX,@Minv);
  glLoadIdentity();
  glTranslatef(0.0,0.0,z);
  glRotatef(xrot,1.0,0.0,0.0);
  glRotatef(yrot,0.0,1.0,0.0);
  // Transformace pozice svìtla do souøadnic objektu:
  l[0]:=LightPosition[0];
  l[1]:=LightPosition[1];
  l[2]:=LightPosition[2];
  l[3]:=1.0;                                            // Homogení souøadnice
  VMatMult(Minv,l);
  //****************************************************************************
  // První fáze:
  //   Použití bump textury
  //   Vypnutí blendingu
  //   Vypnutí svìtel
  //   Použití texturovacích souøadnic bez posunutí
  //   Vytvoøení geometrie
  //****************************************************************************
  glBindTexture(GL_TEXTURE_2D, bump[filter]);
  glDisable(GL_BLEND);
  glDisable(GL_LIGHTING);
  doCube();
  //****************************************************************************
  // Druhá fáze:
  //   Použití pøevrácené bumpmapy
  //   Povolení blendingu GL_ONE, GL_ONE
  //   Ponechá vypnutá svìtla
  //   Použití posunutých texturovacích souøadnic (Pøed každou stìnou krychle musíme zavolat funkci SetUpBumps())
  //   Vytvoøení geometrie
  //****************************************************************************
  glBindTexture(GL_TEXTURE_2D,invbump[filter]);
  glBlendFunc(GL_ONE,GL_ONE);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_BLEND);
  glBegin(GL_QUADS);
    // Pøední stìna
    n[0]:=0.0;		n[1]:=0.0;		n[2]:=1.0;
    s[0]:=1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 0 to 3 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Zadní stìna
    n[0]:=0.0;		n[1]:=0.0;		n[2]:=-1.0;
    s[0]:=-1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 4 to 7 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Horní stìna
    n[0]:=0.0;		n[1]:=1.0;		n[2]:=0.0;
    s[0]:=1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=0.0;		t[2]:=-1.0;
    for i := 8 to 11 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Spodní stìna
    n[0]:=0.0;		n[1]:=-1.0;		n[2]:=0.0;
    s[0]:=-1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=0.0;		t[2]:=-1.0;
    for i := 12 to 15 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Pravá stìna
    n[0]:=1.0;		n[1]:=0.0;		n[2]:=0.0;
    s[0]:=0.0;		s[1]:=0.0;		s[2]:=-1.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 16 to 19 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Levá stìna
    n[0]:=-1.0;		n[1]:=0.0;		n[2]:=0.0;
    s[0]:=0.0;		s[1]:=0.0;		s[2]:=1.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 20 to 23 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glTexCoord2f(data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
  glEnd();
  //****************************************************************************
  // Tøetí fáze:
  //   Použití základní barevné textury
  //   Povoluní blendingu GL_DST_COLOR, GL_SRC_COLOR
  //   Tuto blending rovnici násobit dvìma: (Cdst*Csrc)+(Csrc*Cdst) = 2(Csrc*Cdst)!
  //   Povolení svìtel, aby vytvoøily ambientní a rozptýlené svìtlo
  //   Vrácení GL_TEXTURE matice zpìt na "normální" texturovací souøadnice
  //   Vytvoøit geometrii
  //****************************************************************************
  if not(emboss) then
  begin
    glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glBindTexture(GL_TEXTURE_2D,texture[filter]);
    glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
    glEnable(GL_LIGHTING);
    doCube();
  end;
  xrot := xrot + xspeed;
  yrot := yrot + yspeed;
  if (xrot>360.0) then xrot := xrot - 360.0;
  if (xrot<0.0) then xrot := xrot + 360.0;
  if (yrot>360.0) then yrot := yrot - 360.0;
  if (yrot<0.0) then yrot := yrot + 360.0;
  doLogo();                                             // Nakonec loga
  result := true;
end;

function doMesh2TexelUnits : boolean;
var
  c : array [0..3] of GLfloat;                          // Aktuální vertex
  n : array [0..3] of GLfloat;                          // Normalizovaná normála povrchu
  s : array [0..3] of GLfloat;                          // Smìr texturovacích souøadnic s, normalizováno
  t : array [0..3] of GLfloat;                          // Smìr texturovacích souøadnic t, normalizováno
  l : array [0..3] of GLfloat;                          // Pozice svìtla k pøevedení na souøadnice objektu
  Minv : array [0..15] of GLfloat;                      // Pøevrácená modelview matice
  i : integer;
begin
  c[3] := 1.0;
  n[3] := 1.0;
  s[3] := 1.0;
  t[3] := 1.0;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);	// Smaže obrazovku a hloubkový buffer
  // Sestavení pøevrácené modelview matice, tohle nahradí funkce Push a Pop jednou funkcí glLoadIdentity()
  // Jednoduché sestavení tím, že všechny transformace provedeme opaènì a v opaèném poøadí
  glLoadIdentity();
  glRotatef(-yrot,0.0,1.0,0.0);
  glRotatef(-xrot,1.0,0.0,0.0);
  glTranslatef(0.0,0.0,-z);
  glGetFloatv(GL_MODELVIEW_MATRIX,@Minv);
  glLoadIdentity();
  glTranslatef(0.0,0.0,z);
  glRotatef(xrot,1.0,0.0,0.0);
  glRotatef(yrot,0.0,1.0,0.0);
  // Transformace pozice svìtla na souøadnice objektu:
  l[0]:=LightPosition[0];
  l[1]:=LightPosition[1];
  l[2]:=LightPosition[2];
  l[3]:=1.0;                                            // Homogení souøadnice
  VMatMult(Minv,l);
  //****************************************************************************
  // První fáze:
  //    Bez blendingu
  //    Bez svìtel
  //  Nastavení texture combineru 0 na
  //    Použití bumpmapy
  //    Použití neposunutých texturovacích souøadnic
  //    Nastaveví operace s texturou na GL_REPLACE, která pouze vykreslí texturu
  //  Nastavení texture combineru 1 na
  //    Posunuté texturovací souøadnice
  //    Nastavení operace s texturou na GL_ADD, což je multitexturovacím ekvivalentem k ONE, ONE blendingu
  //****************************************************************************
  // TEXTUROVACÍ JEDNOTKA #0:
  glActiveTextureARB(GL_TEXTURE0_ARB);
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, bump[filter]);
  glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT);
  glTexEnvf (GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_REPLACE);
  // TEXTUROVACÍ JEDNOTKA #1:
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, invbump[filter]);
  glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_EXT);
  glTexEnvf (GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_ADD);
  // Obecné pøepínaèe
  glDisable(GL_BLEND);
  glDisable(GL_LIGHTING);
  glBegin(GL_QUADS);
    // Pøední stìna
    n[0]:=0.0;		n[1]:=0.0;		n[2]:=1.0;
    s[0]:=1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 0 to 3 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glMultiTexCoord2fARB(GL_TEXTURE0_ARB, data[5*i], data[5*i+1]);
      glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Zadní stìna
    n[0]:=0.0;		n[1]:=0.0;		n[2]:=-1.0;
    s[0]:=-1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 4 to 7 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]);
      glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Horní stìna
    n[0]:=0.0;		n[1]:=1.0;		n[2]:=0.0;
    s[0]:=1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=0.0;		t[2]:=-1.0;
    for i := 8 to 11 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
      glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Dolní stìna
    n[0]:=0.0;		n[1]:=-1.0;		n[2]:=0.0;
    s[0]:=-1.0;		s[1]:=0.0;		s[2]:=0.0;
    t[0]:=0.0;		t[1]:=0.0;		t[2]:=-1.0;
    for i := 12 to 15 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
      glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Pravá stìna
    n[0]:=1.0;		n[1]:=0.0;		n[2]:=0.0;
    s[0]:=0.0;		s[1]:=0.0;		s[2]:=-1.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 16 to 19 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
      glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
    // Levá stìna
    n[0]:=-1.0;		n[1]:=0.0;		n[2]:=0.0;
    s[0]:=0.0;		s[1]:=0.0;		s[2]:=1.0;
    t[0]:=0.0;		t[1]:=1.0;		t[2]:=0.0;
    for i := 20 to 23 do
    begin
      c[0]:=data[5*i+2];
      c[1]:=data[5*i+3];
      c[2]:=data[5*i+4];
      SetUpBumps(n,c,l,s,t);
      glMultiTexCoord2fARB(GL_TEXTURE0_ARB,data[5*i]     , data[5*i+1]     );
      glMultiTexCoord2fARB(GL_TEXTURE1_ARB,data[5*i]+c[0], data[5*i+1]+c[1]);
      glVertex3f(data[5*i+2], data[5*i+3], data[5*i+4]);
    end;
  glEnd();
  //****************************************************************************
  // Druhá fáze:
  //   Použití základní textury
  //   Povolení osvìtlení
  //   Neposunuté texturovací souøadnice - vyresetovat GL_TEXTURE matice
  //   Nastavení texture environment na GL_MODULATE
  //****************************************************************************
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glDisable(GL_TEXTURE_2D);
  glActiveTextureARB(GL_TEXTURE0_ARB);
  if not(emboss) then
  begin
    glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glBindTexture(GL_TEXTURE_2D,texture[filter]);
    glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
    glEnable(GL_BLEND);
    glEnable(GL_LIGHTING);
    doCube();
  end;
  xrot := xrot + xspeed;
  yrot := yrot + yspeed;
  if (xrot>360.0) then xrot := xrot - 360.0;
  if (xrot<0.0) then xrot := xrot + 360.0;
  if (yrot>360.0) then yrot := yrot - 360.0;
  if (yrot<0.0) then yrot := yrot + 360.0;
  doLogo;                                               // Nakonec loga
  result := true;
end;

function doMeshNoBumps : boolean;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);	// Smaže obrazovku a hloubkový buffer
  glLoadIdentity();									                    // Reset matice
  glTranslatef(0.0,0.0,z);
  glRotatef(xrot,1.0,0.0,0.0);
  glRotatef(yrot,0.0,1.0,0.0);
  if (useMultitexture) then
  begin
    glActiveTextureARB(GL_TEXTURE1_ARB);
    glDisable(GL_TEXTURE_2D);
    glActiveTextureARB(GL_TEXTURE0_ARB);
  end;
  glDisable(GL_BLEND);
  glBindTexture(GL_TEXTURE_2D,texture[filter]);
  glBlendFunc(GL_DST_COLOR,GL_SRC_COLOR);
  glEnable(GL_LIGHTING);
  doCube();
  xrot := xrot + xspeed;
  yrot := yrot + yspeed;
  if (xrot>360.0) then xrot := xrot - 360.0;
  if (xrot<0.0) then xrot := xrot + 360.0;
  if (yrot>360.0) then yrot := yrot - 360.0;
  if (yrot<0.0) then yrot := yrot + 360.0;
  doLogo();                                             // Nakonec loga
  result := true;
end;

function DrawGLScene():bool;                            // Vykreslování
begin
  if (bumps) then
  begin
    if (useMultitexture and (maxTexelUnits>1)) then
      result := doMesh2TexelUnits
    else
      result := doMesh1TexelUnits;
  end
  else result := doMeshNoBumps;
end;


function WndProc(hWnd: HWND;                            // Handle okna
                 message: UINT;                         // Zpráva pro okno
                 wParam: WPARAM;                        // Doplòkové informace
                 lParam: LPARAM):                       // Doplòkové informace
                                  LRESULT; stdcall;
begin
  if message=WM_SYSCOMMAND then                         // Systémový pøíkaz
    begin
      case wParam of                                    // Typ systémového pøíkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                  // Pokus o zapnutí šetøièe obrazovky, Pokus o pøechod do úsporného režimu?
          begin
            result:=0;                                  // Zabrání obojímu
            exit;
          end;
      end;
    end;
  case message of                                       // Vìtvení podle pøíchozí zprávy
    WM_ACTIVATE:                                        // Zmìna aktivity okna
      begin
        if (Hiword(wParam)=0) then                      // Zkontroluje zda není minimalizované
          active:=true                                  // Program je aktivní
        else
          active:=false;                                // Program není aktivní
        Result:=0;                                      // Návrat do hlavního cyklu programu
      end;
    WM_CLOSE:                                           // Povel k ukonèení programu
      Begin
        PostQuitMessage(0);                             // Pošle zprávu o ukonèení
        result:=0                                       // Návrat do hlavního cyklu programu
      end;
    WM_KEYDOWN:                                         // Stisk klávesy
      begin
        keys[wParam] := TRUE;                           // Oznámí to programu
        result:=0;                                      // Návrat do hlavního cyklu programu
      end;
    WM_KEYUP:                                           // Uvolnìní klávesy
      begin
    	keys[wParam] := FALSE;                            // Oznámí to programu
        result:=0;                                      // Návrat do hlavního cyklu programu
      end;
    WM_SIZe:                                            // Zmìna velikosti okna
      begin
    	ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));     // LoWord=Šíøka, HiWord=Výška
        result:=0;                                      // Návrat do hlavního cyklu programu
      end
    else
      // Pøedání ostatních zpráv systému
      begin
      	Result := DefWindowProc(hWnd, message, wParam, lParam);
      end;
    end;
end;


procedure KillGLWindow;                                 // Zavírání okna
begin
  if FullScreen then                                    // Jsme ve fullscreenu?
    begin
      ChangeDisplaySettings(devmode(nil^),0);           // Pøepnutí do systému
      showcursor(true);                                 // Zobrazí kurzor myši
    end;
  if h_rc<> 0 then                                      // Máme rendering kontext?
    begin
      if (not wglMakeCurrent(h_Dc,0)) then              // Jsme schopni oddìlit kontexty?
        MessageBox(0,'Release of DC and RC failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      if (not wglDeleteContext(h_Rc)) then              // Jsme schopni smazat RC?
        begin
          MessageBox(0,'Release of Rendering Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
          h_Rc:=0;                                      // Nastaví hRC na 0
        end;
    end;
  if (h_Dc=1) and (releaseDC(h_Wnd,h_Dc)<>0) then       // Jsme schopni uvolnit DC
    begin
      MessageBox(0,'Release of Device Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Dc:=0;                                          // Nastaví hDC na 0
    end;
  if (h_Wnd<>0) and (not destroywindow(h_Wnd))then      // Jsme schopni odstranit okno?
    begin
      MessageBox(0,'Could not release hWnd.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Wnd:=0;                                         // Nastaví hWnd na 0
    end;
  if (not UnregisterClass('OpenGL',hInstance)) then     // Jsme schopni odregistrovat tøídu okna?
    begin
      MessageBox(0,'Could Not Unregister Class.','SHUTDOWN ERROR',MB_OK or MB_ICONINFORMATION);
    end;
end;


function CreateGlWindow(title:Pchar; width,height,bits:integer;FullScreenflag:bool):boolean stdcall;
var
  Pixelformat: GLuint;            // Ukládá formát pixelù
  wc:TWndclass;                   // Struktura Windows Class
  dwExStyle:dword;                // Rozšíøený styl okna
  dwStyle:dword;                  // Styl okna
  pfd: pixelformatdescriptor;     // Nastavení formátu pixelù
  dmScreenSettings: Devmode;      // Mód zaøízení
  h_Instance:hinst;               // Instance okna
  WindowRect: TRect;              // Obdélník okna
begin
  WindowRect.Left := 0;                               // Nastaví levý okraj na nulu
  WindowRect.Top := 0;                                // Nastaví horní okraj na nulu
  WindowRect.Right := width;                          // Nastaví pravý okraj na zadanou hodnotu
  WindowRect.Bottom := height;                        // Nastaví spodní okraj na zadanou hodnotu
  h_instance:=GetModuleHandle(nil);                   // Získá instanci okna
  FullScreen:=FullScreenflag;                         // Nastaví promìnnou fullscreen na správnou hodnotu
  with wc do
    begin
      style:=CS_HREDRAW or CS_VREDRAW or CS_OWNDC;    // Pøekreslení pøi zmìnì velikosti a vlastní DC
      lpfnWndProc:=@WndProc;                          // Definuje proceduru okna
      cbClsExtra:=0;                                  // Žádná extra data
      cbWndExtra:=0;                                  // Žádná extra data
      hInstance:=h_Instance;                          // Instance
      hIcon:=LoadIcon(0,IDI_WINLOGO);                 // Standardní ikona
      hCursor:=LoadCursor(0,IDC_ARROW);               // Standardní kurzor myši
      hbrBackground:=0;                               // Pozadí není nutné
      lpszMenuName:=nil;                              // Nechceme menu
      lpszClassName:='OpenGl';                        // Jméno tøídy okna
    end;
  if  RegisterClass(wc)=0 then                        // Registruje tøídu okna
    begin
      MessageBox(0,'Failed To Register The Window Class.','Error',MB_OK or MB_ICONERROR);
      Result:=false;                                  // Pøi chybì vrátí false
      exit;
    end;
  if FullScreen then                                  // Budeme ve fullscreenu?
    begin
      ZeroMemory( @dmScreenSettings, sizeof(dmScreenSettings) );  // Vynulování pamìti
      with dmScreensettings do
        begin
          dmSize := sizeof(dmScreenSettings);         // Velikost struktury Devmode
          dmPelsWidth  := width;	                    // Šíøka okna
	        dmPelsHeight := height;                     // Výška okna
          dmBitsPerPel := bits;                       // Barevná hloubka
          dmFields     := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
        end;
      // Pokusí se použít právì definované nastavení
      if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN))<>DISP_CHANGE_SUCCESSFUL THEN
        Begin
          // Nejde-li fullscreen, mùže uživatel spustit program v oknì nebo ho opustit
          if MessageBox(0,'This FullScreen Mode Is Not Supported. Use Windowed Mode Instead?'
                                             ,'NeHe GL',MB_YESNO or MB_ICONEXCLAMATION)= IDYES then
                FullScreen:=false                     // Bìh v oknì
          else
            begin
              // Zobrazí uživateli zprávu, že program bude ukonèen
              MessageBox(0,'Program Will Now Close.','Error',MB_OK or MB_ICONERROR);
              Result:=false;                          // Vrátí FALSE
              exit;
            end;
          end;
    end;
  if FullScreen then                                  // Jsme stále ve fullscreenu?
    begin
      dwExStyle:=WS_EX_APPWINDOW;                     // Rozšíøený styl okna
      dwStyle:=WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
      Showcursor(false);                              // Skryje kurzor
    end
  else
    begin
      dwExStyle:=WS_EX_APPWINDOW or WS_EX_WINDOWEDGE;   // Rozšíøený styl okna
      dwStyle:=WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
    end;
  AdjustWindowRectEx(WindowRect,dwStyle,false,dwExStyle); // Pøizpùsobení velikosti okna
  // Vytvoøení okna
  H_wnd:=CreateWindowEx(dwExStyle,                    // Rozšíøený styl
                               'OpenGl',              // Jméno tøídy
                               Title,                 // Titulek
                               dwStyle,               // Definovaný styl
                               0,0,                   // Pozice
                               WindowRect.Right-WindowRect.Left,  // Výpoèet šíøky
                               WindowRect.Bottom-WindowRect.Top,  // Výpoèet výšky
                               0,                     // Žádné rodièovské okno
                               0,                     // Bez menu
                               hinstance,             // Instance
                               nil);                  // Nepøedat nic do WM_CREATE
  if h_Wnd=0 then                                     // Pokud se okno nepodaøilo vytvoøit
    begin
      KillGlWindow();                                 // Zruší okno
      MessageBox(0,'Window creation error.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Vrátí chybu
      exit;
    end;
  with pfd do                                         // Oznámíme Windows jak chceme vše nastavit
    begin
      nSize:= SizeOf( PIXELFORMATDESCRIPTOR );        // Velikost struktury
      nVersion:= 1;                                   // Èíslo verze
      dwFlags:= PFD_DRAW_TO_WINDOW                    // Podpora okna
        or PFD_SUPPORT_OPENGL                         // Podpora OpenGL
        or PFD_DOUBLEBUFFER;                          // Podpora Double Bufferingu
      iPixelType:= PFD_TYPE_RGBA;                     // RGBA Format
      cColorBits:= bits;                              // Zvolí barevnou hloubku
      cRedBits:= 0;                                   // Bity barev ignorovány
      cRedShift:= 0;
      cGreenBits:= 0;
      cBlueBits:= 0;
      cBlueShift:= 0;
      cAlphaBits:= 0;                                 // Žádný alpha buffer
      cAlphaShift:= 0;                                // Ignorován Shift bit
      cAccumBits:= 0;                                 // Žádný akumulaèní buffer
      cAccumRedBits:= 0;                              // Akumulaèní bity ignorovány
      cAccumGreenBits:= 0;
      cAccumBlueBits:= 0;
      cAccumAlphaBits:= 0;
      cDepthBits:= 16;                                // 16-bitový hloubkový buffer (Z-Buffer)
      cStencilBits:= 0;                               // Žádný Stencil Buffer
      cAuxBuffers:= 0;                                // Žádný Auxiliary Buffer
      iLayerType:= PFD_MAIN_PLANE;                    // Hlavní vykreslovací vrstva
      bReserved:= 0;                                  // Rezervováno
      dwLayerMask:= 0;                                // Maska vrstvy ignorována
      dwVisibleMask:= 0;
      dwDamageMask:= 0;
    end;
  h_Dc := GetDC(h_Wnd);                               // Zkusí pøipojit kontext zaøízení
  if h_Dc=0 then                                      // Podaøilo se pøipojit kontext zaøízení?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t create a GL device context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  PixelFormat := ChoosePixelFormat(h_Dc, @pfd);       // Zkusí najít Pixel Format
  if (PixelFormat=0) then                             // Podaøilo se najít Pixel Format?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t Find A Suitable PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  if (not SetPixelFormat(h_Dc,PixelFormat,@pfd)) then  // Podaøilo se nastavit Pixel Format?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t set PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  h_Rc := wglCreateContext(h_Dc);                     // Podaøilo se vytvoøit Rendering Context?
  if (h_Rc=0) then
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t create a GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  if (not wglMakeCurrent(h_Dc, h_Rc)) then            // Podaøilo se aktivovat Rendering Context?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t activate the GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  ShowWindow(h_Wnd,SW_SHOW);                          // Zobrazení okna
  SetForegroundWindow(h_Wnd);                         // Do popøedí
  SetFOcus(h_Wnd);                                    // Zamìøí fokus
  ReSizeGLScene(width,height);                        // Nastavení perspektivy OpenGL scény
  if (not InitGl()) then                              // Inicializace okna
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'initialization failed.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  Result:=true;                                       // Vše probìhlo v poøádku
end;


function WinMain(hInstance: HINST;                    // Instance
		 hPrevInstance: HINST;                            // Pøedchozí instance
		 lpCmdLine: PChar;                                // Parametry pøíkazové øádky
		 nCmdShow: integer):                              // Stav zobrazení okna
                        integer; stdcall;
var
  msg: TMsg;                                          // Struktura zpráv systému
  done: Bool;                                         // Promìnná pro ukonèení programu

begin
  done:=false;
  // Dotaz na uživatele pro fullscreen/okno
  if MessageBox(0,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                             MB_YESNO or MB_ICONQUESTION)=IDNO then
    FullScreen:=false                                 // Bìh v oknì
  else
    FullScreen:=true;                                 // Fullscreen
  if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,FullScreen) then // Vytvoøení OpenGL okna
    begin
      Result := 0;                                    // Konec programu pøi chybì
      exit;
    end;
  while not done do                                   // Hlavní cyklus programu
    begin
      if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then  // Pøišla zpráva?
        begin
          if msg.message=WM_QUIT then                 // Obdrželi jsme zprávu pro ukonèení?
            done:=true                                // Konec programu
          else
            begin
	          TranslateMessage(msg);                    // Pøeloží zprávu
	          DispatchMessage(msg);                     // Odešle zprávu
	        end;
        end
      else      // Pokud nedošla žádná zpráva
        begin
          // Je program aktivní, ale nelze kreslit? Byl stisknut ESC?
          if (active and not(DrawGLScene()) or keys[VK_ESCAPE]) then
            done:=true                                // Ukonèíme program
          else                                        // Pøekreslení scény
            SwapBuffers(h_Dc);                        // Prohození bufferù (Double Buffering)
          if keys[VK_F1] then                         // Byla stisknuta klávesa F1?
            begin
            Keys[VK_F1] := false;                     // Oznaè ji jako nestisknutou
            KillGLWindow();                           // Zruší okno
            FullScreen := not FullScreen;             // Negace fullscreen
            // Znovuvytvoøení okna
            if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,fullscreen) then
              Result := 0;                            // Konec programu pokud nebylo vytvoøeno
            end;
          //E: pøepínání Emboss/bumpmapový mód
          //M: vypínání a zapínání multitexturingu
          //B: vypínání a zapínání bumpmappingu, pouze v emboss módu
          //F: pøepínání filtrù, GL_NEAREST není vhodný pro bumpmapping
          //KURSOROVÉ KLÁVESY: otáèení krychle
          if (keys[ord('E')]) then
            begin
              keys[ord('E')] := false;
              emboss := not(emboss);
            end;
          if (keys[ord('M')]) then
            begin
              keys[ord('M')] := false;
              useMultitexture := (not(useMultitexture) and multitextureSupported);
            end;
          if (keys[ord('B')]) then
            begin
              keys[ord('B')]:=false;
              bumps := not(bumps);
            end;
          if (keys[ord('F')]) then
            begin
              keys[ord('F')] := false;
              filter := filter +  1;
              filter := filter mod 3;
            end;
          if (keys[VK_PRIOR]) then
            begin
              z := z - 0.02;
            end;
          if (keys[VK_NEXT]) then
            begin
              z := z + 0.02;
            end;
          if (keys[VK_UP]) then
            begin
              xspeed := xspeed - 0.01;
            end;
          if (keys[VK_DOWN]) then
            begin
              xspeed := xspeed + 0.01;
            end;
          if (keys[VK_RIGHT]) then
            begin
              yspeed := yspeed + 0.01;
            end;
          if (keys[VK_LEFT]) then
            begin
              yspeed := yspeed - 0.01;
            end;
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

