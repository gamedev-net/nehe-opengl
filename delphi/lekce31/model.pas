unit model;

interface

uses GLaux, sysutils, windows, opengl;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  Vertex = record                                           // Struktura vertexu
    m_location: array [0..2] of GLfloat;                    // X, y, z souøadnice
    m_boneID: Char;                                         // Pro skeletální animaci
    end;

  Triangle = record                                         // Struktura trojúhelníku
    m_vertexIndices: array [0..2] of integer;               // Tøi indexy do pole vertexù
    m_s, m_t: array [0..2] of GLfloat;                      // Texturové koordináty
    m_vertexNormals: array [0..2,0..2] of GLfloat;          // Tøi normálové vektory
    end;

  Mesh = record                                             // Mesh modelu
    m_pTriangleIndices: array of integer;                   // Indexy do trojúhelníkù
    m_numTriangles: integer;                                // Poèet trojúhelníkù
    m_materialIndex: integer;                               // Index do materiálù
    end;

  Material = record                                         // Vlastnosti materiálù
    m_ambient, m_diffuse,                                   // Reakce materiálu na svìtlo
    m_specular, m_emissive: array [0..3] of GLfloat;
    m_shininess: GLfloat;                                   // Lesk materiálu
    m_texture: GLuint;                                      // Textura
    m_pTextureFilename: string;                             // Souborová cesta k textuøe
    end;

  TModel = class                                                                // Obecné úloištì dat (abstraktní tøída)
    protected
      m_numVertices: integer;                                                   // Poèet vertexù
      m_pVertices: array of Vertex;                                             // Dynamické pole vertexù
      m_numTriangles: integer;                                                  // Poèet trojúhelníkù
      m_pTriangles: array of Triangle;                                          // Dynamické pole trojúhelníkù
      m_numMeshes: integer;                                                     // Poèet meshù
      m_pMeshes: array of Mesh;                                                 // Dynamické pole meshù
      m_numMaterials: integer;                                                  // Poèet materiálù
      m_pMaterials: array of Material;                                          // Dynamické pole materiálù
    public
      constructor Create;                                                       // Konstruktor
      destructor Destroy; override;                                             // Destruktor
      function loadModelData(filename: string): boolean; virtual; abstract;     // Loading objektu ze souboru
      procedure reloadTexture;                                                  // Znovunahrání textur
      procedure Draw;                                                           // Vykreslení objektu
    end;

implementation

{ TModel }

constructor TModel.Create;                                                      // Konstruktor
begin
  m_numMeshes := 0;                                                             // Nulování struktur
  m_pMeshes := nil;
  m_numMaterials := 0;
  m_pMaterials := nil;
  m_numTriangles := 0;
  m_pTriangles := nil;
  m_numVertices := 0;
  m_pVertices := nil;
end;

destructor TModel.Destroy;                                                      // Destruktor
var
  i: integer;
begin
  for i := 0 to m_numMeshes - 1 do                                              // Uvolnìní všech struktur
    SetLength(m_pMeshes[i].m_pTriangleIndices,0);
  for i := 0 to m_numMaterials - 1 do
    m_pMaterials[i].m_pTextureFilename := '';
  m_numMeshes := 0;
  if m_pMeshes <> nil then
    begin
    SetLength(m_pMeshes,0);
    m_pMeshes := nil;
    end;
  m_numMaterials := 0;
  if m_pMaterials <> nil then
    begin
    SetLength(m_pMaterials,0);
    m_pMaterials := nil;
    end;
  m_numTriangles := 0;
  if m_pTriangles <> nil then
    begin
    SetLength(m_pTriangles,0);
    m_pTriangles := nil;
    end;
  m_numVertices := 0;
  if m_pVertices <> nil then
    begin
    SetLength(m_pVertices,0);
    m_pVertices := nil;
    end;
  inherited;
end;

procedure TModel.Draw;
var
  texEnabled: GLboolean;
  i, j, k: integer;
  materialIndex, triangleIndex, index: integer;
  pTri: ^Triangle;
begin
  texEnabled := glIsEnabled(GL_TEXTURE_2D);                                     // Uloí atribut
  for i := 0 to m_numMeshes - 1 do                                              // Meshe
    begin
    materialIndex := m_pMeshes[i].m_materialIndex;                              // Index
    if materialIndex >= 0 then                                                  // Obsahuje mesh index materiálu?
      begin                                                                     // Nastaví OpenGL
      glMaterialfv(GL_FRONT,GL_AMBIENT,@m_pMaterials[materialIndex].m_ambient);
      glMaterialfv(GL_FRONT,GL_DIFFUSE,@m_pMaterials[materialIndex].m_diffuse);
      glMaterialfv(GL_FRONT,GL_SPECULAR,@m_pMaterials[materialIndex].m_specular);
      glMaterialfv(GL_FRONT,GL_EMISSION,@m_pMaterials[materialIndex].m_emissive);
      glMaterialf(GL_FRONT,GL_SHININESS,m_pMaterials[materialIndex].m_shininess);
      if m_pMaterials[materialIndex].m_texture > 0 then                         // Obsahuje materiál texturu?
        begin
        glBindTexture(GL_TEXTURE_2D,m_pMaterials[materialIndex].m_texture);
        glEnable(GL_TEXTURE_2D);
        end
        else                                                                    // Bez textury
        glDisable(GL_TEXTURE_2D);
      end
      else                                                                      // Bez materiálu nemùe bıt ani textura
      glDisable(GL_TEXTURE_2D);
    glBegin(GL_TRIANGLES);                                                      // Zaèátek trojúhelníkù
      for j := 0 to m_pMeshes[i].m_numTriangles - 1 do                          // Trojúhelníky v meshi
        begin
        triangleIndex := m_pMeshes[i].m_pTriangleIndices[j];                    // Index
        pTri := @m_pTriangles[triangleIndex];                                   // Trojúhelník
        for k := 0 to 2 do                                                      // Vertexy v trojúhelníku
          begin
          index := pTri.m_vertexIndices[k];                                     // Index vertexu
          glNormal3fv(@pTri.m_vertexNormals[k]);                                // Normála
          glTexCoord2f(pTri.m_s[k],pTri.m_t[k]);                                // Texturovací souøadnice
          glVertex3fv(@m_pVertices[index].m_location);                          // Souøadnice vertexu
          end;
        end;
    glEnd;                                                                      // Konec kreslení
    end;
  if texEnabled then                                                            // Obnovení nastavení OpenGL
    glEnable(GL_TEXTURE_2D)
    else
    glDisable(GL_TEXTURE_2D);
end;

function LoadBMP(FileName: pchar):PTAUX_RGBImageRec;                            // Nahraje bitmapu
begin
  if Filename = '' then                                                         // Byla pøedána cesta k souboru?
    begin
    Result := nil;                                                              // Pokud ne, konec
    exit;
    end;
  if not FileExists(Filename) then                                              // Existuje soubor?
    begin
    Result := nil;                                                              // Pokud ne, konec
    exit;
    end;
  Result := auxDIBImageLoadA(FileName);                                         // Naète bitmapu a vrátí na ni ukazatel
end;

function LoadGLTextures(FileName: pchar): GLuint;                               // Loading bitmapy a konverze na texturu
var pImage: PTAUX_RGBImageRec;                                                  // Ukládá bitmapu
    texture: GLuint;
begin
  texture := 0;
  ZeroMemory(@pImage,sizeof(pImage));                                           // Vynuluje pamì
  pImage := LoadBMP(FileName);                                                  // Nahraje bitmapu
  if Assigned(FileName) then                                                    // Vše je bez problémù?
    begin
    glGenTextures(1,texture);                                                   // Generuje texturu
    glBindTexture(GL_TEXTURE_2D,texture);                                       // Typické vytváøení textury z bitmapy
    glTexImage2D(GL_TEXTURE_2D,0,3,pImage.sizeX,pImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,pImage.data);    // Vlastní vytváøení textury
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);             // Filtrování pøi zvìtšení
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);             // Filtrování pøi zmenšení
    end;
  Result := texture;                                                            // Vrací texturu
end;

procedure TModel.reloadTexture;                                                 // Nahrání textur
var
  i: integer;                                                                   // Cyklus
begin
  for i := 0 to m_numMaterials - 1 do                                           // Jednotlivé materiály
    if m_pMaterials[i].m_pTextureFilename <> '' then                            // Existuje øetìzec s cestou
      m_pMaterials[i].m_texture := LoadGLTextures(Pchar(m_pMaterials[i].m_pTextureFilename))  // Nahraje texturu
      else
      m_pMaterials[i].m_texture := 0;                                           // Nulou indikuje, e materiál nemá texturu
end;

end.
