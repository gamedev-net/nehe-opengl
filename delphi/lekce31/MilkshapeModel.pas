unit MilkshapeModel;

interface

uses model, classes, sysutils, windows;

type
  {MS3D STRUKTURA}

  MS3DHeader = packed record                                          // Hlavièka souboru
    m_ID: array [0..9] of char;
    m_version: integer;
    end;

  MS3DVertex = packed record                                          // Informace o vertexu
    m_flags: byte;
    m_vertex: array [0..2] of single;
    m_boneID: char;
    m_refCount: byte;
    end;

  MS3DTriangle = packed record                                        // Informace o trojúhelníku
    m_flags: word;
    m_vertexIndices: array [0..2] of word;
    m_vertexNormals: array [0..2,0..2] of single;
    m_s, m_t: array [0..2] of single;
    m_smoothingGroup: byte;
    m_groupIndex: byte;
    end;

  MS3DMaterial = packed record                                        // Informace o materiálu
    m_name: array [0..31] of char;
    m_ambient: array [0..3] of single;
    m_diffuse: array [0..3] of single;
    m_specular: array [0..3] of single;
    m_emissive: array [0..3] of single;
    m_shininess: single;                                              // 0.0 - 128.0
    m_transparency: single;                                           // 0.0 - 1.0
    m_mode: byte;                                                     // 0, 1, 2
    m_texture: array [0..127] of char;
    m_alphamap: array [0..127] of char;
    end;

  MS3DJoint = packed record                                           // Joint informace
    m_flags: byte;
    m_name: array [0..31] of char;
    m_parentName: array [0..31] of char;
    m_rotation: array [0..2] of single;
    m_translation: array [0..2] of single;
    m_numRotationKeyframes: word;
    m_numTranslationKeyframes: word;
    end;

  MS3DKeyframe = packed record                                        // Keyframe informace
    m_time: single;
    m_parameter: array [0..2] of single;
    end;

  {Konec MS3D STRUKTURY}

  TMilkshapeModel = class(TModel)
    public
      constructor Create;                                             // Konstruktor
      destructor Destroy; override;                                   // Destruktor
      function loadModelData(filename: string): boolean; override;    // Loading objektu ze souboru
    end;

implementation

{ TMilkshapeModel }

constructor TMilkshapeModel.Create;
begin
end;

destructor TMilkshapeModel.Destroy;
begin
  inherited;
end;

function TMilkshapeModel.loadModelData(filename: string): boolean;
var
  inputFile: TFileStream;                                                       // Vstupní soubor
  buffer: ^byte;                                                                // Obraz souboru v pamìti
  pPtr: pointer;                                                                // Ukazatel do obraze souboru v pamìti
  size, precteno: integer;                                                      // Velikost souboru
  pHeader: MS3DHeader;                                                          // Hlavièka
  nVertices, nTriangles, nGroups, nMaterials: integer;                          // Poèty jednotlivıch struktur
  i, j: integer;                                                                // Cykly
  pVertex: MS3DVertex;                                                          // Vertexy
  pTriangle: MS3DTriangle;                                                      // Trojúhelníky
  vertexIndices: array [0..2] of integer;
  t: array [0..2] of single;
  materialIndex: char;                                                          // Index materiálu
  pMaterial: MS3DMaterial;                                                      // Materiál
begin
  try
  inputFile := TFileStream.Create(filename,fmOpenRead);                         // Otevøení souboru
  if not Assigned(inputFile) then                                               // Podaøilo se ho otevøít?
    begin
    Result := false;                                                            // Pokud ne, konec
    exit;
    end;
  size := inputFile.Seek(0,soFromEnd);                                          // Velikost souboru
  inputFile.Seek(0,soFromBeginning);
  buffer := AllocMem(size);                                                     // Alokace pamìti pro kopii souboru
  precteno := inputFile.Read(buffer^,size);                                     // Vytvoøení pamìové kopie souboru
  inputFile.Free;                                                               // Zavøení souboru
  if precteno <> size then                                                      // Naèetl se celı soubor?
    begin                                                                       // Pokud ne ...
    FreeMem(buffer,size);                                                       // Uvolnit alokovanou pamì
    Result := false;                                                            // Konec
    exit;
    end;
  pPtr := buffer;                                                               // Pomocnı ukazatel na kopii souboru
  pHeader := MS3DHeader(pPtr^);                                                 // Ukazatel na hlavièku
  pPtr := Pointer(Integer(pPtr) + Sizeof(MS3DHeader));                          // Posun za hlavièku
  if CompareStr(pHeader.m_ID,'MS3D000000') <> 0 then                            // Není Milkshape3D souborem
    begin
    FreeMem(buffer,size);                                                       // Uvolnit alokovanou pamì
    Result := false;                                                            // Konec
    exit;
    end;
  if (pHeader.m_version < 3) or (pHeader.m_version > 4) then                    // Špatná verze souboru, tøída podporuje pouze verze 1.3 a 1.4
    begin
    FreeMem(buffer,size);                                                       // Uvolnit alokovanou pamì
    Result := false;                                                            // Konec
    exit;
    end;
  nVertices := Word(pPtr^);                                                     // Poèet vertexù
  m_numVertices := nVertices;                                                   // Nastaví atribut tøídy
  SetLength(m_pVertices,nVertices);                                             // Alokace pamìti pro vertexy
  pPtr := Pointer(Integer(pPtr) + Sizeof(Word));                                // Posun za poèet vertexù
  for i := 0 to nVertices - 1 do                                                // Nahrává vertexy
    begin
    pVertex := MS3DVertex(pPtr^);                                               // Ukazatel na vertex
    m_pVertices[i].m_boneID := pVertex.m_boneID;                                // Naètení vertexu
    CopyMemory(@m_pVertices[i].m_location,@pVertex.m_vertex,Sizeof(single)*3);
    pPtr := Pointer(Integer(pPtr) + Sizeof(MS3DVertex));                        // Posun za tento vertex
    end;
  nTriangles := Word(pPtr^);                                                    // Poèet trojúhelníkù
  m_numTriangles := nTriangles;                                                 // Nastaví atribut tøídy
  SetLength(m_pTriangles,nTriangles);                                           // Alokace pamìti pro trojúhelníky
  pPtr := Pointer(Integer(pPtr) + Sizeof(Word));                                // Posun za poèet trojúhelníkù
  for i := 0 to nTriangles - 1 do                                               // Naèítá trojúhelníky
    begin
    pTriangle := MS3DTriangle(pPtr^);                                           // Ukazatel na trojúhelník
    vertexIndices[0] := pTriangle.m_vertexIndices[0];                           // Naètení trojúhelníku
    vertexIndices[1] := pTriangle.m_vertexIndices[1];
    vertexIndices[2] := pTriangle.m_vertexIndices[2];
    t[0] := 1.0 - pTriangle.m_t[0];
    t[1] := 1.0 - pTriangle.m_t[1];
    t[2] := 1.0 - pTriangle.m_t[2];
    CopyMemory(@m_pTriangles[i].m_vertexNormals,@pTriangle.m_vertexNormals,Sizeof(single)*3*3);
    CopyMemory(@m_pTriangles[i].m_s,@pTriangle.m_s,Sizeof(single)*3);
    CopyMemory(@m_pTriangles[i].m_t,@t,Sizeof(single)*3);
    CopyMemory(@m_pTriangles[i].m_vertexIndices,@vertexIndices,Sizeof(integer)*3);
    pPtr := Pointer(Integer(pPtr) + Sizeof(MS3DTriangle));                      // Posun za tento trojúhelník
    end;
  nGroups := Word(pPtr^);                                                       // Poèet meshù
  m_numMeshes := nGroups;                                                       // Nastaví atribut tøídy
  SetLength(m_pMeshes,nGroups);                                                 // Alokace pamìti pro meshe
  pPtr := Pointer(Integer(pPtr) + Sizeof(Word));                                // Posun za poèet meshù
  for i := 0 to nGroups - 1 do                                                  // Naèítá meshe
    begin
    pPtr := Pointer(Integer(pPtr) + Sizeof(byte));                              // Posun za flagy
    pPtr := Pointer(Integer(pPtr) + 32);                                        // Posun za jméno
    nTriangles := Word(pPtr^);                                                  // Poèet trojúhelníkù v meshi
    pPtr := Pointer(Integer(pPtr) + Sizeof(Word));                              // Posun za poèet trojúhelníkù
    SetLength(m_pMeshes[i].m_pTriangleIndices,nTriangles);                      // Alokace pamìti pro indexy trojúhelníkù
    for j := 0 to nTriangles - 1 do                                             // Naèítá indexy trojúhelníkù
      begin
      m_pMeshes[i].m_pTriangleIndices[j] := Word(pPtr^);                        // Pøiøadí index trojúhelníku
      pPtr := Pointer(Integer(pPtr) + Sizeof(Word));                            // Posun za index trojúhelníku
      end;
    materialIndex := Char(pPtr^);                                               // Naète index materiálu
    pPtr := Pointer(Integer(pPtr) + Sizeof(Char));                              // Posun za index materiálu
    m_pMeshes[i].m_materialIndex := Integer(materialIndex);                     // Index materiálu
    m_pMeshes[i].m_numTriangles := nTriangles;                                  // Poèet trojúhelníkù
    end;
  nMaterials := Word(pPtr^);                                                    // Poèet materiálù
  m_numMaterials := nMaterials;                                                 // Nastaví atribut tøídy
  SetLength(m_pMaterials,nMaterials);                                           // Alokace pamìti pro materiály
  pPtr := Pointer(Integer(pPtr) + Sizeof(Word));                                // Posun za poèet materiálù
  for i := 0 to nMaterials - 1 do                                               // Prochází materiály
    begin                                                                       
    pMaterial := MS3DMaterial(pPtr^);                                           // Ukazatel na materiál
    CopyMemory(@m_pMaterials[i].m_ambient,@pMaterial.m_ambient,Sizeof(single)*4); // Naète materiál
    CopyMemory(@m_pMaterials[i].m_diffuse,@pMaterial.m_diffuse,Sizeof(single)*4);
    CopyMemory(@m_pMaterials[i].m_specular,@pMaterial.m_specular,Sizeof(single)*4);
    CopyMemory(@m_pMaterials[i].m_emissive,@pMaterial.m_emissive,Sizeof(single)*4);
    m_pMaterials[i].m_shininess := pMaterial.m_shininess;
    m_pMaterials[i].m_pTextureFilename := pMaterial.m_texture;                  // Zkopírování jména souboru
    pPtr := Pointer(Integer(pPtr) + Sizeof(MS3DMaterial));                      // Posun za materiál
    end;
  reloadTexture;                                                                // Nahraje textury
  FreeMem(buffer,size);                                                         // Smae kopii souboru
  Result := true;                                                               // Model byl nahrán
  except                                                                        // Pøi kritické chybì ve funkci ...
  inputFile.Free;                                                               // Uvolnit alokovanou pamì
  FreeMem(buffer,size);                                                         // Uvolnit alokovanou pamì
  Result := false;
  end;
end;

end.
