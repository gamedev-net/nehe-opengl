program lesson32a;

{   kód pro Delphi 7}

uses
  Windows,
  SysUtils,
  Messages,
  OpenGL,
  MMSystem,
  NeHeGL in 'NeHeGL.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';

type
  objects = record                                      // Struktura objektu
    rot: GLuint;                                        // Rotace (0 - ádná, 1 - po smìru hodinovıch ruèièek, 2 - proti smìru)
    hit: boolean;                                       // Byl objekt zasaen?
    frame: GLuint;                                      // Aktuální snímek exploze
    dir: GLuint;                                        // Smìr pohybu (0 - vlevo, 1 - vpravo, 2 - nahoru, 3 - dolù)
    texid: GLuint;                                      // Index do pole textur
    x: GLfloat;                                         // X pozice
    y: GLfloat;                                         // Y pozice
    spin: GLfloat;                                      // Smìr rotace na ose z
    distance: GLfloat;                                  // Hloubka ve scénì
    end;

  TextureImage = record                                 // Struktura textury
    imageData: ^GLubyte;                                // Ukazatel na data
    bpp: GLuint;                                        // Barevná hloubka
    width: GLuint;                                      // Šíøka
    height: GLuint;                                     // Vıška
    texID: GLuint;                                      // Èíslo textury
    end;

  dimensions = record                                   // Rozmìr objektu
    w: GLfloat;                                         // Šíøka
    h: GLfloat;                                         // Vıška
    end;

var
  g_window: PGL_Window;                                 // Okno
  g_keys: PKeys;                                        // Klávesy
  base: GLuint;                                         // Display listy fontu
  roll: GLfloat;                                        // Rolování mrakù
  level: GLint = 1;                                     // Aktuální level
  miss: GLint;                                          // Poèet nesestøelenıch objektù
  kills: GLint;                                         // Poèet sestøelenıch objektù v daném levelu
  score: GLint;                                         // Aktuální skóre
  game: boolean;                                        // Konec hry?
  textures: array [0..9] of TextureImage;               // Deset textur
  obj: array [0..29] of objects;                        // 30 Objektù
  // Velikost kadého objektu:          Modrá tváø,       kıbl,           terè,         Coca-cola,        Váza
  size: array [0..4] of dimensions = ((w: 1.0;h: 1.0),(w: 1.0;h: 1.0),(w: 1.0;h: 1.0),(w: 0.5;h: 1.0),(w: 0.75;h: 1.5));

function LoadTGA(var texture: TextureImage; filename: string): boolean;
var
  TGAheader: array [0..11] of byte;                                   // Nekomprimovaná TGA hlavièka  {0,0,2,0,0,0,0,0,0,0,0,0}
  TGAcompare: array [0..11] of byte;                                  // Pro porovnání TGA hlavièky
  Header: array [0..5] of byte;                                       // Prvních 6 uiteènıch bytù z hlavièky
  BytesPerPixel: GLuint;                                              // Poèet bytù na pixel pouitı v TGA souboru
  ImageSize: GLuint;                                                  // Ukládá velikost obrázku pøi alokování RAM
  temp: GLubyte;                                                      // Pomocná promìnná
  TypeMode: GLuint;                                                   // GL mód
  f: file;                                                            // Soubor TGA
  precteno: Gluint;                                                   // Poèet pøeètenıch bytù
  i: integer;                                                         // Cyklus
  B, R: PGLubyte;                                                     // Ukazatel na prohazované sloky barev
begin
  ZeroMemory(@TGAheader,sizeof(TGAheader));                           // Nulování prvkù pole
  TGAheader[2] := 2;                                                  // Tøetí prvek hlavièky je 2 - viz deklarace
  TypeMode := GL_RGBA;                                                // Implicitním GL módem je RGBA (32 BPP)
  if not FileExists(filename) then                                    // Existuje soubor?
    begin
    Result := false;                                                  // Konec funkce
    exit;
    end;
  AssignFile(f,filename);                                             // Pøiøazení souboru
  Reset(f,1);                                                         // Otevøe TGA soubor
  BlockRead(f,TGAcompare,Sizeof(TGAcompare),precteno);                // Naète hlavièku
  if (precteno <> Sizeof(TGAcompare)) or                              // Podaøilo se naèíst 12 bytù?
    (not CompareMem(@TGAcompare,@TGAHeader,sizeof(TGAheader))) then   // Mají potøebné hodnoty?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  BlockRead(f,Header,Sizeof(Header),precteno);                        // Pokud ano, naète dalších šest bytù
  if precteno <> sizeof(Header) then                                  // Podaøilo se naèíst 6 bytù?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  texture.width := Header[1] * 256 + Header[0];                       // Získá šíøku obrázku
  texture.height := Header[3] * 256 + Header[2];                      // Získá vıšku obrázku
  if (texture.width <= 0) or (texture.height <= 0)                    // Platná šíøka? Platná vıška?
    or ((Header[4] <> 24) and (Header[4] <> 32)) then                 // Platná barevná hloubka?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  texture.bpp := Header[4];                                           // Bity na pixel (24 nebo 32)
  BytesPerPixel := texture.bpp div 8;                                 // Byty na pixel
  ImageSize := texture.width * texture.height * BytesPerPixel;        // Velikost pamìti pro data obrázku
  texture.imageData := AllocMem(ImageSize);                           // Alokace pamìti pro data obrázku
  if texture.imageData = nil then                                     // Podaøilo se pamì alokovat?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  BlockRead(f,texture.imageData^,ImageSize,precteno);                 // Kopírování dat
  if precteno <> ImageSize then                                       // Podaøilo se kopírování dat?
    begin
    Result := false;                                                  // Konec funkce
    FreeMem(texture.imageData);                                       // Uvolní pamì
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  for i := 0 to (texture.width * texture.height) - 1 do               // Prochází data obrázku
    begin
    B := Pointer(Integer(texture.imageData) + i * BytesPerPixel);     // Ukazatel na B
    R := Pointer(Integer(texture.imageData) + i * BytesPerPixel+2);   // Ukazatel na R
    temp := B^;                                                       // B uloíme do pomocné promìnné
    B^ := R^;                                                         // R je na správném místì
    R^ := temp;                                                       // B je na správném místì
    end;
  CloseFile(f);                                                       // Zavøe soubor
  glGenTextures(1,texture.texID);                                     // Generuje texturu
  glBindTexture(GL_TEXTURE_2D,texture.texID);                         // Zvolí texturu
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);     // Lineární filtrování
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);     // Lineární filtrování
  if texture.bpp = 24 then TypeMode := GL_RGB;                        // Je obrázek 24 bitovı? Nastaví typ na GL_RGB
  glTexImage2D(GL_TEXTURE_2D,0,TypeMode,texture.width,texture.height,0,TypeMode,GL_UNSIGNED_BYTE,texture.imageData);  // Vytvoøí texturu
  FreeMem(texture.imageData);                                         // Uvolní pamì
  Result := true;
end;

procedure BuildFont;                                                  // Vytvoøení fontu
var
  cx, cy: GLfloat;                                                    // Koordináty x, y
  loop: integer;                                                      // Cyklus
begin
  base := glGenLists(95);                                             // 95 display listù
  glBindTexture(GL_TEXTURE_2D,textures[9].texID);                     // Vıbìr textury
  for loop := 0 to 94 do                                              // Vytváøí 95 display listù
    begin
    cx := (loop mod 16) / 16;                                         // X pozice aktuálního znaku
    cy := (loop div 16) / 8;                                          // Y pozice aktuálního znaku
    glNewList(base + loop,GL_COMPILE);                                // Vytvoøení display listu
      glBegin(GL_QUADS);                                              // Pro kadı znak jeden obdélník
        glTexCoord2f(cx,1-cy-0.120);glVertex2i(0,0);                  // Levı dolní
        glTexCoord2f(cx+0.0625,1-cy-0.120);glVertex2i(16,0);          // Pravı dolní
        glTexCoord2f(cx+0.0625,1-cy);glVertex2i(16,16);               // Pravı horní
        glTexCoord2f(cx,1-cy);glVertex2i(0,16);                       // Levı horní
      glEnd;                                                          // Konec znaku
      glTranslated(10,0,0);                                           // Pøesun na pravou stranu znaku
    glEndList;                                                        // Konec kreslení display listu
    end;
end;

procedure glPrint(x,y: GLint;text: string);
begin
  if text = '' then exit;                                             // Byl pøedán text?
  glBindTexture(GL_TEXTURE_2D,textures[9].texID);                     // Vıbìr textury
  glPushMatrix;                                                       // Uloí projekèní matici
  glLoadIdentity;                                                     // Reset matice
  glTranslated(x,y,0);                                                // Pozice textu (0,0 - levı dolní)
  glListBase(base-32);                                                // Poèátek
  glCallLists(length(text),GL_UNSIGNED_BYTE,Pchar(text));             // Vykreslení textu na obrazovku
  glPopMatrix;                                                        // Obnovení uloené projekèní matice
end;

procedure InitObject(num: integer);                                   // Inicializace objektu
var
  i,j: integer;                                                       // Cykly
  sorting: boolean;                                                   // Tøídìní
  tempobj: objects;                                                   // Pomocnı objekt
begin
  with obj[num] do
    begin
    rot := 1;                                                         // Rotace po smìru hodinovıch ruèièek
    frame := 0;                                                       // První snímek exploze
    hit := false;                                                     // Ještì nebyl zasaen
    texid := Random(5);                                               // Náhodnı index textury
    distance := - Random(4001) / 100;                                 // Náhodná hloubka
    y := -1.5 + (Random(451) / 100);                                  // Náhodná y pozice
    x := ((distance - 15) / 2) - (5 * level) - Random(5 * level);     // Náhodná x pozice zaloená na hloubce v obrazovce a s náhodnım zpodìním pøed vstupem na scénu
    dir := Random(2);                                                 // Náhodnı smìr pohybu
    if dir = 0 then                                                   // Pohybuje se doleva?
      begin
      rot := 2;                                                       // Rotace proti smìru hodinovıch ruèièek
      x := -x;                                                        // Vıchozí pozice vpravo
      end;
    if texid = 0 then                                                 // Modrá tváø
      y := -2.0;                                                      // Vdy tìsnì nad zemí
    if texid = 1 then                                                 // Kıbl
      begin
      dir := 3;                                                       // Padá dolù
      x := Random(Abs(Trunc(distance - 10))) + ((distance - 10) / 2);
      y := 4.5;                                                       // Tìsnì pod mraky
      end;
    if texid = 2 then                                                 // Terè
      begin
      dir := 2;                                                       // Vyletí vzhùru
      x := Random(Abs(Trunc(distance - 10))) + ((distance - 10) / 2);
      y := -3.0 - Random(5 * level);                                  // Pod zemí
      end;
    end;
  For j := level-1 downto 1 do begin                                  // Øazení objektù podle hloubky
    i := j;
    sorting := true;
    While (sorting) and (i > 0) do
      if (obj[i].distance < obj[i-1].distance) then begin
        tempobj := obj[i];
        obj[i] := obj[i-1];
        obj[i-1] := tempobj;
        Dec(i);
        end else sorting := false;
    end;

end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	        // Inicializace OpenGL
var
  loop: integer;                                                      // Cyklus
begin
  g_window := window;
  g_keys := key;
  Randomize;                                                          // Inicializace generátoru náhodnıch èísel
  LoadTGA(textures[0],'Data/BlueFace.tga');                           // Modrá tváø
  LoadTGA(textures[1],'Data/Bucket.tga');                             // Kbelík
  LoadTGA(textures[2],'Data/Target.tga');                             // Terè
  LoadTGA(textures[3],'Data/Coke.tga');                               // Coca-Cola
  LoadTGA(textures[4],'Data/Vase.tga');                               // Váza
  LoadTGA(textures[5],'Data/Explode.tga');                            // Exploze
  LoadTGA(textures[6],'Data/Ground.tga');                             // Zemì
  LoadTGA(textures[7],'Data/Sky.tga');                                // Obloha
  LoadTGA(textures[8],'Data/Crosshair.tga');                          // Kurzor
  LoadTGA(textures[9],'Data/Font.tga');                               // Font
  if not (Assigned(textures[0].imageData) and Assigned(textures[1].imageData) and
          Assigned(textures[2].imageData) and Assigned(textures[3].imageData) and
          Assigned(textures[4].imageData) and Assigned(textures[5].imageData) and
          Assigned(textures[6].imageData) and Assigned(textures[7].imageData) and
          Assigned(textures[8].imageData) and Assigned(textures[9].imageData)) then
    begin
    Result := false;                                                  // Inicializace se nezdaøila
    exit;
    end; 
  BuildFont;                                                          // Vytvoøí display listy fontu
  glClearColor(0.0, 0.0, 0.0, 0.0);	  	                              // Èerné pozadí
  glClearDepth(1.0);				                                          // Nastavení hloubkového bufferu
  glDepthFunc(GL_LEQUAL);				                                      // Typ hloubkového testování
  glEnable(GL_DEPTH_TEST);			                                      // Povolí hloubkové testování
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);                   // Nastavení alfa blendingu
  glEnable(GL_BLEND);                                                 // Zapne alfa blending
	//glAlphaFunc(GL_GREATER,0.1);                                      // Nastavení alfa testingu
	//glEnable(GL_ALPHA_TEST);                                          // Zapne alfa testing
	glEnable(GL_TEXTURE_2D);                                            // Zapne mapování textur
	glEnable(GL_CULL_FACE);                                             // Oøezávání zadních stran polygonù
  for loop := 0 to 29 do                                              // Prochází všechny objekty
    InitObject(loop);                                                 // Inicializace kadého z nich
  Result:=true;                                                       // Inicializace probìhla v poøádku
end;

procedure Deinitialize;                                               // Uvolnìní prostøedkù
var
  loop: integer;                                                      // Cyklus
begin
  for loop := 0 to 9 do
    glDeleteTextures(loop,@textures[loop].texid);                     // Smazání textur
  glDeleteLists(base,95);                                             // Smazání display listu
end;

procedure Explosion(num: integer);                                    // Animace exploze objektu
var
  ex, ey: GLfloat;                                                    // Subkoordináty v textuøe
begin
  ex := ((obj[num].frame div 4) mod 4) / 4;                           // Vıpoèet x snímku exploze (0.0f - 0.75f)
  ey := ((obj[num].frame div 4) div 4) / 4;                           // Vıpoèet y snímku exploze (0.0f - 0.75f)
  glBindTexture(GL_TEXTURE_2D,textures[5].texID);			                // Textura exploze
	glBegin(GL_QUADS);											                            // Kreslení obdélníkù
		glTexCoord2f(ex,1.0-ey); glVertex3f(-1.0,-1.0,0.0);               // Levı dolní
		glTexCoord2f(ex+0.25,1.0-ey); glVertex3f(1.0,-1.0,0.0);           // Pravı dolní
		glTexCoord2f(ex+0.25,1.0-(ey+0.25)); glVertex3f(1.0,1.0,0.0);     // Pravı horní
		glTexCoord2f(ex,1.0-(ey+0.25)); glVertex3f(-1.0,1.0,0.0);         // Levı horní
	glEnd;                                                              // Konec kreslení
  Inc(obj[num].frame);										                            // Zvıší snímek exploze
	if obj[num].frame > 63 then									                        // Poslední snímek?
		InitObject(num);										                              // Reinicializace objektu
end;

procedure Objekt(width, height: GLfloat; texid: GLuint);              // Vykreslí objekt
begin
  glBindTexture(GL_TEXTURE_2D,textures[texid].texID);		              // Zvolí správnou texturu
	glBegin(GL_QUADS);											                            // Kreslení obdélníkù
		glTexCoord2f(0.0,0.0); glVertex3f(-width,-height,0.0);            // Levı dolní
		glTexCoord2f(1.0,0.0); glVertex3f( width,-height,0.0);            // Pravı dolní
		glTexCoord2f(1.0,1.0); glVertex3f( width, height,0.0);            // Pravı horní
		glTexCoord2f(0.0,1.0); glVertex3f(-width, height,0.0);            // Levı horní
	glEnd;                                                              // Konec kreslení
end;

procedure DrawTargets;                                                // Vykreslí objekty
var
  loop: integer;                                                      // Cyklus
begin
  glLoadIdentity;											                                // Reset matice
	glTranslatef(0.0,0.0,-10.0);								                        // Posun do hloubky
	for loop := 0 to level - 1 do						                            // Prochází aktivní objekty
	  begin
		glLoadName(loop);										                              // Pøiøadí objektu jméno (pro detekci zásahù)
		glPushMatrix;											                                // Uloení matice
		glTranslatef(obj[loop].x,obj[loop].y,obj[loop].distance);		      // Umístìní objektu
		if obj[loop].hit then									                            // Byl objekt zasaen?
			Explosion(loop)									                                // Vykreslí snímek exploze
		  else                                                            // Objekt nebyl zasaen
		  begin
			glRotatef(obj[loop].spin,0.0,0.0,1.0);		                      // Natoèení na ose z
			Objekt(size[obj[loop].texid].w,size[obj[loop].texid].h,obj[loop].texid);	// Vykreslení
		  end;
		glPopMatrix;											                                // Obnoví matici
	  end;
end;

procedure Selection;                                                  // Detekce zasaení objektù
var
  buffer: array [0..511] of GLuint;                                   // Deklarace selection bufferu
  hits: GLint;                                                        // Poèet zasaenıch objektù
  viewport: array [0..3] of GLint;                                    // Velikost viewportu. [0] = x, [1] = y, [2] = vıška, [3] = šíøka
  choose, depth, loop: integer;                                       // Jméno objektu, hloubka, cyklus
begin
  if game then exit;                                                  // Konec hry? // Není dùvod testovat na zásah
  PlaySound('data/shot.wav',0,SND_ASYNC);                             // Pøehraje zvuk vıstøelu
  glGetIntegerv(GL_VIEWPORT,@viewport);                               // Nastaví pole podle velikosti a lokace scény relativnì k oknu
  glSelectBuffer(512,@buffer);                                        // Pøikáe OpenGL, aby pro selekci objektù pouilo pole buffer
  glRenderMode(GL_SELECT);                                            // Pøevedení OpenGL do selection módu
  glInitNames;                                                        // Inicializace name stacku
  glPushName(0);                                                      // Vloí 0 (nejménì jedna poloka) na stack
  glMatrixMode(GL_PROJECTION);                                        // Zvolí projekèní matici
  glPushMatrix;                                                       // Uloení projekèní matice
  glLoadIdentity;                                                     // Reset matice
  gluPickMatrix(mouse_x,viewport[3] - mouse_y,1.0,1.0,@viewport);     // Vytvoøení matice, která zvìtší malou èást obrazovky okolo kurzoru myši
  gluPerspective(45.0,(viewport[2] - viewport[0]) / (viewport[3] - viewport[1]),0.1,100.0); // Aplikování perspektivní matice
  glMatrixMode(GL_MODELVIEW);                                         // Modelview matice
  DrawTargets;                                                        // Renderuje objekty do selection bufferu
  glMatrixMode(GL_PROJECTION);                                        // Projekèní matice
  glPopMatrix;                                                        // Obnovení projekèní matice
  glMatrixMode(GL_MODELVIEW);                                         // Modelview matice
  hits := glRenderMode(GL_RENDER);                                    // Pøepnutí do renderovacího módu, uloení poètu objektù pod kurzorem
  if hits > 0 then                                                    // Bylo více ne nula zásahù?
    begin
    choose := buffer[3];                                              // Uloí jméno prvního objektu
    depth := buffer[1];                                               // Uloí jeho hloubku
    for loop := 1 to hits - 1 do                                      // Prochází všechny detekované zásahy
      if buffer[loop*4+1] < depth then                                // Je tento objekt blíe ne nìkterı z pøedchozích?
        begin
        choose := buffer[loop*4+3];						                        // Uloí jméno blišího objektu
				depth := buffer[loop*4+1];                                    // Uloí jeho hloubku
        end;
    if not obj[choose].hit then                                       // Nebyl ještì objekt zasaen?
      begin
      obj[choose].hit := true;                                        // Oznaèí ho jako zasaenı
      Inc(score);                                                     // Zvıší celkové skóre
      Inc(kills);                                                     // Zvıší poèet zásahù v levelu
      if kills > (level * 5) then                                     // Èas pro další level?
        begin
        miss := 0;                                                    // Nulování nezasaenıch objektù
        kills := 0;                                                   // Nulování zasaenıch objektù v tomto levelu
        Inc(level);                                                   // Posun na další level
        if level > 30 then level := 30;                               // Poslední level? // Nastavení levelu na poslední
        end;
      end;
    end;
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
var
  loop: integer;                                                      // Cyklus
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[Ord(' ')] and game then                           // Mezerník na konci hry?
    begin
    for loop := 0 to 29 do                                            // Prochází všechny objekty
      InitObject(loop);                                               // Jejich inicializace
    game := false;                                                    // Ještì není konec hry
    score := 0;                                                       // Nulové skóre
    level := 1;                                                       // První level
    kills := 0;                                                       // Nula zasaenıch objektù
    miss := 0;                                                        // Nula nezasaenıch objektù
    end;
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  roll := roll - milliseconds*0.00005;                                // Mraky plují a zemì se pohybuje
  for loop := 0 to level - 1 do                                       // Aktualizace všech viditelnıch objektù
    begin
    if obj[loop].rot = 1 then                                         // Rotace po smìru hodinovıch ruèièek?
			obj[loop].spin := obj[loop].spin - 0.2*(loop+milliseconds);
		if obj[loop].rot = 2 then                                         // Rotace proti smìru hodinovıch ruèièek?
			obj[loop].spin := obj[loop].spin + 0.2*(loop+milliseconds);
		if obj[loop].dir = 1 then                                         // Pohyb doprava?
			obj[loop].x := obj[loop].x + 0.012*milliseconds;
		if obj[loop].dir = 0 then                                         // Pohyb doleva?
			obj[loop].x := obj[loop].x - 0.012*milliseconds;
		if obj[loop].dir = 2 then                                         // Pohyb nahoru?
			obj[loop].y := obj[loop].y + 0.012*milliseconds;
		if obj[loop].dir = 3 then                                         // Pohyb dolù?
			obj[loop].y := obj[loop].y - 0.0025*milliseconds;
		// Objekt vyletìl vlevo ze scény, pohybuje se vlevo a ještì nebyl zasaen
		if ((obj[loop].x < (obj[loop].distance - 15.0) / 2.0) and (obj[loop].dir = 0) and (not obj[loop].hit)) then
		  begin
			Inc(miss);											                                // Zvıšení poètu nezasaenıch objektù
			obj[loop].hit := true;								                          // Odstranìní objektu (zajišuje animaci exploze a reinicializaci)
		  end;
		// Objekt vyletìl vpravo ze scény, pohybuje se vpravo a ještì nebyl zasaen
		if ((obj[loop].x > -(obj[loop].distance - 15.0) / 2.0) and (obj[loop].dir = 1) and (not obj[loop].hit)) then
		  begin
			Inc(miss);											                                // Zvıšení poètu nezasaenıch objektù
			obj[loop].hit := true;								                          // Odstranìní objektu (zajišuje animaci exploze a reinicializaci)
		  end;
		// Objekt narazil do zemì, pohybuje se dolù a ještì nebyl zasaen
		if ((obj[loop].y < -2.0) and (obj[loop].dir = 3) and (not obj[loop].hit)) then
		  begin
			Inc(miss);											                                // Zvıšení poètu nezasaenıch objektù
			obj[loop].hit := true;								                          // Odstranìní objektu (zajišuje animaci exploze a reinicializaci)
		  end;
    // Objekt je pod mraky a smìøuje vzhùru
		if ((obj[loop].y > 4.5) and (obj[loop].dir = 2)) then
			obj[loop].dir := 3;                                             // Zmìna smìru na pád
    end; 
end;

procedure Draw;                                                       // Vykreslení scény
var
  window: TRect;                                                      // Promìnná obdélníku
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smae obrazovku a hloubkovı buffer
  glLoadIdentity;	                                                    // Reset matice
  glPushMatrix;                                                       // Uloí matici
	glBindTexture(GL_TEXTURE_2D,textures[7].texID);                     // Textura mrakù
	glBegin(GL_QUADS);                                                  // Kreslení obdélníkù
		glTexCoord2f(1.0,roll/1.5+1.0); glVertex3f( 28.0,+7.0,-50.0);
		glTexCoord2f(0.0,roll/1.5+1.0); glVertex3f(-28.0,+7.0,-50.0);
		glTexCoord2f(0.0,roll/1.5+0.0); glVertex3f(-28.0,-3.0,-50.0);
		glTexCoord2f(1.0,roll/1.5+0.0); glVertex3f( 28.0,-3.0,-50.0);
		glTexCoord2f(1.5,roll+1.0); glVertex3f( 28.0,+7.0,-50.0);
		glTexCoord2f(0.5,roll+1.0); glVertex3f(-28.0,+7.0,-50.0);
		glTexCoord2f(0.5,roll+0.0); glVertex3f(-28.0,-3.0,-50.0);
		glTexCoord2f(1.5,roll+0.0); glVertex3f( 28.0,-3.0,-50.0);
		glTexCoord2f(1.0,roll/1.5+1.0); glVertex3f( 28.0,+7.0,0.0);
		glTexCoord2f(0.0,roll/1.5+1.0); glVertex3f(-28.0,+7.0,0.0);
		glTexCoord2f(0.0,roll/1.5+0.0); glVertex3f(-28.0,+7.0,-50.0);
		glTexCoord2f(1.0,roll/1.5+0.0); glVertex3f( 28.0,+7.0,-50.0);
		glTexCoord2f(1.5,roll+1.0); glVertex3f( 28.0,+7.0,0.0);
		glTexCoord2f(0.5,roll+1.0); glVertex3f(-28.0,+7.0,0.0);
		glTexCoord2f(0.5,roll+0.0); glVertex3f(-28.0,+7.0,-50.0);
		glTexCoord2f(1.5,roll+0.0); glVertex3f( 28.0,+7.0,-50.0);
	glEnd;                                                              // Konec kreslení
	glBindTexture(GL_TEXTURE_2D,textures[6].texID);			                // Textura zemì
	glBegin(GL_QUADS);											                            // Kreslení obdélníkù
		glTexCoord2f(7.0,4.0-roll); glVertex3f( 27.0,-3.0,-50.0);
		glTexCoord2f(0.0,4.0-roll); glVertex3f(-27.0,-3.0,-50.0);
		glTexCoord2f(0.0,0.0-roll); glVertex3f(-27.0,-3.0,0.0);
		glTexCoord2f(7.0,0.0-roll); glVertex3f( 27.0,-3.0,0.0);
	glEnd; 													                                    // Konec kreslení
	DrawTargets;												                                // Sestøelované objekty
  glPopMatrix;                                                        // Obnovení matice
	GetClientRect(g_window.hWnd,window);                                // Grabování rozmìrù okna
	glMatrixMode(GL_PROJECTION);                                        // Projekèní matice
	glPushMatrix;                                                       // Uloí projekèní matici
	glLoadIdentity;                                                     // Reset projekèní matice
	glOrtho(0,window.right,0,window.bottom,-1,1);                       // Nastavení pravoúhlé scény
	glMatrixMode(GL_MODELVIEW);                                         // Zvolí matici modelview
	glTranslated(mouse_x,window.bottom-mouse_y,0.0);                    // Posun na pozici kurzoru
	Objekt(16,16,8);                                                    // Vykreslí kurzor myši
	glPrint(240,450,'NeHe Productions');                                // Logo
	glPrint(10,10,Format('Level: %d',[level]));                         // Level
	glPrint(250,10,Format('Score: %d',[score]));                        // Skóre
	if miss > 9 then                                                    // Nestrefil hráè více ne devìt objektù?
	  begin
		miss := 9;                                                        // Limit je devìt
		game := true;                                                     // Konec hry
	  end;
	if game then                                                        // Konec hry?
		glPrint(490,10,'GAME OVER')                                       // Vypíše konec hry
	else
		glPrint(490,10,Format('Morale: %d/10',[10-miss]));                // Vypíše poèet objektù, které nemusí sestøelit
	glMatrixMode(GL_PROJECTION);                                        // Projekèní matice
	glPopMatrix;                                                        // Obnovení projekèní matice
	glMatrixMode(GL_MODELVIEW);                                         // Modelview matice
	glFlush;                                                            // Vyprázdní OpenGL renderovací pipeline
end;

function WindowProc(hWnd: HWND;                                       // Handle okna
                 uMsg: UINT;                                          // Zpráva pro okno
                 wParam: WPARAM;                                      // Doplòkové informace
                 lParam: LPARAM):                                     // Doplòkové informace
                                  LRESULT; stdcall;
var
  window: ^GL_Window;
  creation: ^CREATESTRUCT;
begin
  if uMsg = WM_SYSCOMMAND then                                        // Systémovı pøíkaz
      case wParam of                                                  // Typ systémového pøíkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                                // Pokus o zapnutí šetøièe obrazovky, Pokus o pøechod do úsporného reimu?
          begin
            Result := 0;                                              // Zabrání obojímu
            exit;
          end;
      end;
  window := Pointer(GetWindowLong(hWnd,GWL_USERDATA));
  case uMsg of                                                        // Vìtvení podle pøíchozí zprávy
    WM_CREATE:
      begin
      creation := Pointer(lParam);
      window := Pointer(creation.lpCreateParams);
      SetWindowLong(hWnd,GWL_USERDATA,Integer(window));
      Result := 0;
      end;
    WM_CLOSE:                                                         // Povel k ukonèení programu
      begin
      TerminateApplication(window^);                                  // Pošle zprávu o ukonèení
      Result := 0                                                     // Návrat do hlavního cyklu programu
      end;
    WM_SIZE:                                                          // Zmìna velikosti okna
      begin
      case wParam of
        SIZE_MINIMIZED:
          begin
          window.isVisible := false;
          Result := 0;
          end;
        SIZE_MAXIMIZED,
        SIZE_RESTORED:
          begin
          window.isVisible := true;
          ReshapeGL(LOWORD(lParam),HIWORD(lParam));                 // LoWord=Šíøka, HiWord=Vıška
          Result := 0;                                              // Návrat do hlavního cyklu programu
          end;
      end;
     // Result := 0;
      end;
    WM_KEYDOWN:                                                     // Stisk klávesy
      begin
      if (wParam >= 0) and (wParam <= 255) then
        begin
        window^.keys^.keyDown[wParam] := true;                      // Oznámí to programu
        Result := 0;
        end;
      //Result := 0;                                                // Návrat do hlavního cyklu programu
      end;
    WM_KEYUP:                                                       // Uvolnìní klávesy
      begin
      if (wParam >= 0) and (wParam <= 255) then
        begin
    	  window^.keys^.keyDown[wParam] := false;                     // Oznámí to programu
        Result := 0;                                                // Návrat do hlavního cyklu programu
        end;
      //exit;
      end;
    WM_TOGGLEFULLSCREEN:
      begin
      g_createFullScreen := not g_createFullScreen;
      PostMessage(hWnd,WM_QUIT,0,0);
      Result := 0;
      end;
    WM_LBUTTONDOWN:                                                 // Stisknutí levého tlaèítka myši
      begin
      mouse_x := LOWORD(lParam);
      mouse_y := HIWORD(lParam);
      Selection;
      Result := 0;
      end;
    WM_MOUSEMOVE:                                                   // Pohyb myši
      begin
      mouse_x := LOWORD(lParam);
      mouse_y := HIWORD(lParam);
      Result := 0;
      end;
    else
      // Pøedání ostatních zpráv systému
      begin
      	Result := DefWindowProc(hWnd,uMsg,wParam,lParam);
      end;
    end;
end;

function RegisterWindowClass(application: Application): boolean;
var
  windowClass: WNDCLASSEX;
begin
  ZeroMemory(@windowClass,Sizeof(windowClass));
  with windowClass do
    begin
    cbSize := Sizeof(windowClass);
    style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;                  // Pøekreslení pøi zmìnì velikosti a vlastní DC
    lpfnWndProc := @WindowProc;                                     // Definuje proceduru okna
    hInstance := application.hInstance;                             // Instance
    hbrBackground := COLOR_APPWORKSPACE;                            // Pozadí není nutné
    hCursor := LoadCursor(0,IDC_ARROW);                             // Standardní kurzor myši
    lpszClassName := PChar(application.className);                  // Jméno tøídy okna
    end;
  if RegisterClassEx(windowClass) = 0 then                          // Registruje tøídu okna
    begin
    MessageBox(HWND_DESKTOP,'RegisterClassEx Failed!','Error',MB_OK or MB_ICONEXCLAMATION);
    Result := false;                                                // Pøi chybì vrátí false
    exit;
    end;
  Result := true;
end;

function WinMain(hInstance: HINST;                                  // Instance
		 hPrevInstance: HINST;                                          // Pøedchozí instance
		 lpCmdLine: PChar;                                              // Parametry pøíkazové øádky
		 nCmdShow: integer):                                            // Stav zobrazení okna
                        integer; stdcall;
var
  app: Application;
  window: GL_Window;
  key: Keys;
  isMessagePumpActive: boolean;
  msg: TMsg;                                                        // Struktura zpráv systému
  tickCount: DWORD;
begin
  app.className := 'OpenGL';
  app.hInstance := hInstance;
  ZeroMemory(@window,Sizeof(window));
  with window do
    begin
    keys := @key;
    init.application := @app;
    init.title := 'NeHe''s Picking Tutorial';
    init.width := 640;
    init.height := 480;
    init.bitsPerPixel := 16;
    init.isFullScreen := true;
    end;
  ZeroMemory(@key,Sizeof(key));
  // Dotaz na uivatele pro fullscreen/okno
  if MessageBox(HWND_DESKTOP,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                MB_YESNO or MB_ICONQUESTION) = IDNO then
    window.init.isFullScreen := false;                                 // Bìh v oknì
  if not RegisterWindowClass(app) then
    begin
    MessageBox(HWND_DESKTOP,'Error Registering Window Class!','Error',MB_OK or MB_ICONEXCLAMATION);
    Result := -1;
    exit;
    end;
  g_isProgramLooping := true;
  g_createFullScreen := window.init.isFullScreen;
  while g_isProgramLooping do
    begin
    window.init.isFullScreen := g_createFullScreen;
    if CreateWindowGL(window) then
      begin
      if not Initialize(@window,@key) then
        TerminateApplication(window)
        else
        begin
        isMessagePumpActive := true;
        while isMessagePumpActive do
          if PeekMessage(msg,0,0,0,PM_REMOVE) then                  // Pøišla zpráva?
            if msg.message <> WM_QUIT then                          // Obdreli jsme zprávu pro ukonèení?
              DispatchMessage(msg)                                
              else
              isMessagePumpActive := false                          // Konec programu
            else
            if not window.isVisible then
              WaitMessage
              else
              begin
              tickCount := GetTickCount;
              Update(tickCount - window.lastTickCount);
              window.lastTickCount := tickCount;
              Draw;
              SwapBuffers(window.hDc);
              end;
        end;
      Deinitialize;
      DestroyWindowGL(window);
      end
      else
      begin
      MessageBox(HWND_DESKTOP,'Error Creating OpenGL Window','Error',MB_OK or MB_ICONEXCLAMATION);
      g_isProgramLooping := false;
      end;
    end;
  UnregisterClass(PChar(app.className),app.hInstance);
  Result := 0;
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );                  // Start programu
end.

