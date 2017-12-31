unit TGALoader;

interface

uses opengl, windows;

type
  Texture = record                                  // Struktura textury
    imageData: PGLubyte;                            // Data
    bpp: GLuint;                                    // Barevná hloubka v bitech
    width: GLuint;                                  // Šíøka
    height: GLuint;                                 // Vıška
    texID: GLuint;                                  // ID textury
    typ: GLuint;                                    // Typ (GL_RGB, GL_RGBA)
    end;

  PTexture = ^Texture;                              // Ukazatel na strukturu textury

  TTGAHeader = record                               // Hlavièka TGA souboru
    Header: array [0..11] of GLubyte;               // Dvanáct bytù
    end;

  TTGA = record                                     // Struktura obrázku
    header: array [0..5] of GLubyte;                // Šest uiteènıch bytù z hlavièky
    bytesPerPixel: GLuint;                          // Barevná hloubka v bytech
    imageSize: GLuint;                              // Velikost pamìti pro obrázek
    typ: GLuint;                                    // Typ
    Heigh: GLuint;                                  // Vıška
    Width: GLuint;                                  // Šíøka
    Bpp: GLuint;                                    // Barevná hloubka v bitech
    end;

function LoadTGA(var texture: Texture; filename: string): boolean;

var
  tgaheader: TTGAHeader;                            // TGA hlavièka
  tga: TTGA;                                        // TGA obrázek
  uTGAcompare: array [0..11] of GLubyte = (0,0,2,0,0,0,0,0,0,0,0,0);  // TGA hlavièka nekomprimovaného obrázku
  cTGAcompare: array [0..11] of GLubyte = (0,0,10,0,0,0,0,0,0,0,0,0); // TGA hlavièka komprimovaného obrázku
  fTGA: file;                                       // Soubor

implementation

uses SysUtils;

function LoadUncompressedTGA(var texture: Texture; filename: string): boolean;  // Nahraje nekomprimovanı TGA
var
  precteno: integer;                                                            // Poèet pøeètenıch bytù
  i: integer;                                                                   // Cyklus
  B, R: PGLubyte;                                                               // Ukazatel na prohazované sloky barev
  temp: GLubyte;                                                                // Pomocná promìnná
begin
  BlockRead(fTGA,tga.header,sizeof(tga.header),precteno);                       // Šest uiteènıch bytù
  if precteno <> sizeof(tga.header) then
    begin
    MessageBox(0,'Could not read info header','ERROR',MB_OK);
    Result := false;
    end;
  texture.width := tga.header[1] * 256 + tga.header[0];                         // Šíøka
  texture.height := tga.header[3] * 256 + tga.header[2];                        // Vıška
  texture.bpp := tga.header[4];                                                 // Barevná hloubka v bitech
  tga.Width := texture.width;                                                   // Kopírování dat do struktury obrázku
  tga.Heigh := texture.height;
  tga.Bpp := texture.bpp;
  if (texture.width <= 0) or (texture.height <= 0) or                           // Platné hodnoty?
      ((texture.bpp <> 24) and (texture.bpp <> 32)) then
    begin
    MessageBox(0,'Invalid texture information','ERROR',MB_OK);
    Result := false;
    end;
  if texture.bpp = 24 then                                                      // 24 bitovı obrázek?
    texture.typ := GL_RGB
    else                                                                        // 32 bitovı obrázek
    texture.typ := GL_RGBA;
  tga.bytesPerPixel := texture.bpp div 8;                                       // BYTY na pixel
  tga.imageSize := tga.bytesPerPixel * tga.Width * tga.Heigh;                   // Velikost pamìti
  texture.imageData := AllocMem(tga.imageSize);                                 // Alokace pamìti pro data
  if texture.imageData = nil then                                               // Alokace neúspìšná
    begin
    MessageBox(0,'Could not allocate memory for image','ERROR',MB_OK);
    Result := false;
    end;
  BlockRead(fTGA,texture.imageData^,tga.imageSize,precteno);                    // Pokusí se nahrát data obrázku
  if precteno <> tga.imageSize then
    begin
    MessageBox(0,'Could not read image data','ERROR',MB_OK);
    FreeMem(texture.imageData);                                                 // Uvolnìní pamìti
    Result := false;
    end;
  for i := 0 to (tga.Width * tga.Heigh) - 1 do                                  // Pøevod BGR na RGB
    begin
    B := Pointer(Integer(texture.imageData) + i * tga.bytesPerPixel);           // Ukazatel na B
    R := Pointer(Integer(texture.imageData) + i * tga.bytesPerPixel+2);         // Ukazatel na R
    temp := B^;                                                                 // B uloíme do pomocné promìnné
    B^ := R^;                                                                   // R je na správném místì
    R^ := temp;                                                                 // B je na správném místì
    end;
  CloseFile(fTGA);                                                              // Zavøení souboru
  Result := true;                                                               // Úspìch
end;

function LoadCompressedTGA(var texture: Texture; filename: string): boolean;    // Nahraje komprimovanı obrázek
var
  precteno: integer;                                                            // Poèet pøeètenıch bytù
  pixelcount: GLuint;                                                           // Poèet pixelù
  currentpixel: GLuint;                                                         // Aktuální naèítanı pixel
  currentbyte: GLuint;                                                          // Aktuální naèítanı byte
  colorbuffer: PGLubyte;                                                        // Ukazatel na pole bytù
  chunkheader: GLubyte;                                                         // Byte hlavièky
  counter: integer;                                                             // Cyklus
  R, G, B, A: PGLubyte;                                                         // Ukazatel na sloky barev
  temp: PGLubyte;                                                               // Pomocná promìnná
begin
  BlockRead(fTGA,tga.header,sizeof(tga.header),precteno);                       // Šest uiteènıch bytù
  if precteno <> sizeof(tga.header) then
    begin
    MessageBox(0,'Could not read info header','ERROR',MB_OK);
    Result := false;
    end;
  texture.width := tga.header[1] * 256 + tga.header[0];                         // Šíøka
  texture.height := tga.header[3] * 256 + tga.header[2];                        // Vıška
  texture.bpp := tga.header[4];                                                 // Barevná hloubka v bitech
  tga.Width := texture.width;                                                   // Kopírování dat do struktury obrázku
  tga.Heigh := texture.height;
  tga.Bpp := texture.bpp;
  if (texture.width <= 0) or (texture.height <= 0) or                           // Platné hodnoty?
      ((texture.bpp <> 24) and (texture.bpp <> 32)) then
    begin
    MessageBox(0,'Invalid texture information','ERROR',MB_OK);
    Result := false;
    end;
  if texture.bpp = 24 then                                                      // 24 bitovı obrázek?
    texture.typ := GL_RGB
    else                                                                        // 32 bitovı obrázek
    texture.typ := GL_RGBA;
  tga.bytesPerPixel := texture.bpp div 8;                                       // BYTY na pixel
  tga.imageSize := tga.bytesPerPixel * tga.Width * tga.Heigh;                   // Velikost pamìti
  texture.imageData := AllocMem(tga.imageSize);                                 // Alokace pamìti pro data
  if texture.imageData = nil then                                               // Alokace neúspìšná
    begin
    MessageBox(0,'Could not allocate memory for image','ERROR',MB_OK);
    Result := false;
    end;
  pixelcount := tga.Width * tga.Heigh;                                          // Poèet pixelù
  currentpixel := 0;                                                            // Aktuální naèítanı pixel
  currentbyte := 0;                                                             // Aktuální naèítanı byte
  colorbuffer := AllocMem(tga.bytesPerPixel);                                   // Pamì pro jeden pixel
  if colorbuffer = nil then                                                     // Alokace neúspìšná
    begin
    MessageBox(0,'Could not allocate memory for color buffer','ERROR',MB_OK);
    FreeMem(texture.imageData);
    Result := false;
    end;
  repeat                                                                        // Prochází celı soubor
  chunkheader := 0;                                                             // Byte hlavièky
  BlockRead(fTGA,chunkheader,sizeof(GLubyte),precteno);                         // Naète byte hlavièky
  if precteno <> sizeof(GLubyte) then
    begin
    MessageBox(0,'Could not read RLE header','ERROR',MB_OK);
    FreeMem(texture.imageData);
    FreeMem(colorbuffer);
    Result := false;
    end;
  if chunkheader < 128 then                                                     // RAW èást obrázku
    begin
    Inc(chunkheader);                                                           // Poèet pixelù v sekci pøed vıskytem dalšího bytu hlavièky
    for counter := 0 to chunkheader - 1 do                                      // Jednotlivé pixely
      begin
      BlockRead(fTGA,colorbuffer^,tga.bytesPerPixel,precteno);                  // Naèítání po jednom pixelu
      if precteno <> tga.bytesPerPixel then
        begin
        MessageBox(0,'Could not read image data','ERROR',MB_OK);
        FreeMem(texture.imageData);
        FreeMem(colorbuffer);
        Result := false;
        end;
      R := Pointer(Integer(colorbuffer) + 2);                                   // Zápis do pamìti, prohodí R a B sloku barvy
      G := Pointer(Integer(colorbuffer) + 1);
      B := Pointer(Integer(colorbuffer) + 0);
      temp := Pointer(Integer(texture.imageData) + currentbyte);
      temp^ := R^;
      temp := Pointer(Integer(texture.imageData) + currentbyte + 1);
      temp^ := G^;
      temp := Pointer(Integer(texture.imageData) + currentbyte + 2);
      temp^ := B^;
      if tga.bytesPerPixel = 4 then                                             // 32 bitovı obrázek?
        begin
        A := Pointer(Integer(colorbuffer) + 3);                                 // Kopírování alfy
        temp := Pointer(Integer(texture.imageData) + currentbyte + 3);
        temp^ := A^;
        end;
      Inc(currentbyte,tga.bytesPerPixel);                                       // Aktualizuje byte
      Inc(currentpixel);                                                        // Pøesun na další pixel
      if currentpixel > pixelcount then                                         // Jsme za hranicí obrázku?
        begin
        MessageBox(0,'Too many pixels read','ERROR',MB_OK);
        FreeMem(texture.imageData);
        FreeMem(colorbuffer);
        Result := false;
        end;
      end;
    end
    else                                                                        // RLE èást obrázku
    begin
    Dec(chunkheader,127);                                                       // Poèet pixelù v sekci
    BlockRead(fTGA,colorbuffer^,tga.bytesPerPixel,precteno);                    // Naète jeden pixel
    if precteno <> tga.bytesPerPixel then
      begin
      MessageBox(0,'Could not read from file','ERROR',MB_OK);
      FreeMem(texture.imageData);
      FreeMem(colorbuffer);
      Result := false;
      end;
    for counter := 0 to chunkheader - 1 do                                      // Kopírování pixelu
      begin
      R := Pointer(Integer(colorbuffer) + 2);                                   // Zápis do pamìti, prohodí R a B sloku barvy
      G := Pointer(Integer(colorbuffer) + 1);
      B := Pointer(Integer(colorbuffer) + 0);
      temp := Pointer(Integer(texture.imageData) + currentbyte);
      temp^ := R^;
      temp := Pointer(Integer(texture.imageData) + currentbyte + 1);
      temp^ := G^;
      temp := Pointer(Integer(texture.imageData) + currentbyte + 2);
      temp^ := B^;
      if tga.bytesPerPixel = 4 then                                             // 32 bitovı obrázek?
        begin
        A := Pointer(Integer(colorbuffer) + 3);                                 // Kopírování alfy
        temp := Pointer(Integer(texture.imageData) + currentbyte + 3);
        temp^ := A^;
        end;
      Inc(currentbyte,tga.bytesPerPixel);                                       // Aktualizuje byte
      Inc(currentpixel);                                                        // Pøesun na další pixel
      if currentpixel > pixelcount then                                         // Jsme za hranicí obrázku?
        begin
        MessageBox(0,'Too many pixels read','ERROR',MB_OK);
        FreeMem(texture.imageData);
        FreeMem(colorbuffer);
        Result := false;
        end;
      end;
    end;
  until currentpixel = pixelcount;                                              // Pokraèuj dokud zbıvají pixely
  FreeMem(colorbuffer);                                                         // Uvolnìní dynamické pamìti
  CloseFile(fTGA);                                                              // Zavøení souboru
  Result := true;                                                               // Úspìch
end;

function LoadTGA(var texture: Texture; filename: string): boolean;              // Nahraje TGA soubor
var
  precteno: integer;                                                            // Poèet pøeètenıch bytù
begin
  AssignFile(fTGA,filename);                                                    // Pøiøazení souboru
  {$I-}
  Reset(fTGA,1);                                                                // Otevøe soubor
  {$I+}
  if IOResult <> 0 then                                                         // Nepodaøilo se ho otevøít?
    begin
    MessageBox(0,'Could not open texture file','ERROR',MB_OK);
    Result := false;
    exit;
    end;
  BlockRead(fTGA,tgaheader,sizeof(tgaheader),precteno);                         // Naète hlavièku souboru
  if precteno <> sizeof(tgaheader) then
    begin
    MessageBox(0,'Could not read file header','ERROR',MB_OK);
    CloseFile(fTGA);
    Result := false;
    exit;
    end;
  if CompareMem(@uTGAcompare,@tgaheader,sizeof(tgaheader)) then                 // Nekomprimovanı
    begin
    if not LoadUncompressedTGA(texture,filename) then
      begin
      CloseFile(fTGA);
      Result := false;
      exit;
      end;
    end
    else
    if CompareMem(@cTGAcompare,@tgaheader,sizeof(tgaheader)) then               // Komprimovanı
      begin
      if not LoadCompressedTGA(texture,filename) then
        begin
        CloseFile(fTGA);
        Result := false;
        exit;
        end;
      end
      else                                                                      // Ani jeden z nich
      begin
      MessageBox(0,'TGA file be type 2 or type 10','Invalid Image',MB_OK);
      CloseFile(fTGA);
      Result := false;
      exit;
      end;
  Result := true;                                                               // Vše v poøádku
end;

end.
