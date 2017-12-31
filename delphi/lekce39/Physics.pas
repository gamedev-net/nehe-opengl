unit Physics;

interface

type
  Vector3D = record                                             // Vektor
    x, y, z: Double;
    end;

  Mass = class                                                  // Objekt
    public
      m: Double;                                                // Hmotnost
      pos: Vector3D;                                            // Pozice v prostoru
      vel: Vector3D;                                            // Rychlosti a smìr pohybu
      force: Vector3D;                                          // Síla pùsobící na objekt
      constructor Create(m: Double);                            // Konstruktor
      procedure applyForce(force: Vector3D);                    // Aplikace sil
      procedure init;                                           // Nulování sil
      procedure simulate(dt: Double);                           // Krok simulace
    end;

  Simulation = class                                            // Simulace
    public
      numOfMasses: integer;                                     // Poèet objektù v zásobníku
      masses: array of Mass;                                    // Objekty jsou uchovávány v jednorozmìrném poli ukazatelù na objekty
      constructor Create(numOfMasses: integer; m: Double);      // Konstruktor vytvoøí objekty s danou hmotností
      procedure Release; virtual;                               // Uvolní dynamickou pamì
      function getMass(index: integer): Mass;                   // Získání objektu s urèitım indexem
      procedure init; virtual;                                  // Tato metoda zavolá init() metodu kadého objektu
      procedure solve; virtual;
      procedure simulate(dt: Double); virtual;                  // Vıpoèet v závislosti na èase
      procedure operate(dt: Double); virtual;                   // Kompletní simulaèní metoda
    end;

  ConstantVelocity = class(Simulation)                          // Objekt s konstantní rychlostí
    public
      constructor Create;
    end;

  MotionUnderGravitation = class(Simulation)                    // Pohyb v gravitaci
    public
      gravitation: Vector3D;                                    // Gravitaèní zrychlení
      constructor Create(gravitation: Vector3D);
      procedure solve; override;                                // Aplikace gravitace
    end;

  MassConnectedWithSpring = class(Simulation)                   // Objekt spojenı pruinou s bodem
    public
      springConstant: Double;                                   // Èím vyšší bude tato konstanta, tím tuší bude pruina
      connectionPos: Vector3D;                                  // Bod ke kterému bude objekt pøipojen
      constructor Create(springConstant: Double);
      procedure solve; override;                                // Uití síly pruiny
    end;

// Funkce pro práci s vektory
function Vektor(x, y, z: Double): Vector3D;
function Add(v1, v2: Vector3D): Vector3D;
function Subtract(v1, v2: Vector3D): Vector3D;
function Multiply(v1: Vector3D; scale: Double): Vector3D;
function Divide(v1: Vector3D; scale: Double): Vector3D;
function Invert(v1: Vector3D): Vector3D;
function Mag(x, y, z: Double): Double;
function Uni(V1: Vector3D): Vector3D;

  

implementation

function Vektor(x, y, z: Double): Vector3D;                // Vrací vektor
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function Add(v1, v2: Vector3D): Vector3D;                   // Souèet
begin
  Result.x := v1.x + v2.x;
  Result.y := v1.y + v2.y;
  Result.z := v1.z + v2.z;
end;

function Subtract(v1, v2: Vector3D): Vector3D;              // Rozdíl
begin
  Result.x := v1.x - v2.x;
  Result.y := v1.y - v2.y;
  Result.z := v1.z - v2.z;
end;

function Multiply(v1: Vector3D; scale: Double): Vector3D;   // Násobení
begin
  Result.x := v1.x * scale;
  Result.y := v1.y * scale;
  Result.z := v1.z * scale;
end;

function Divide(v1: Vector3D; scale: Double): Vector3D;     // Podíl
begin
  Result.x := v1.x / scale;
  Result.y := v1.y / scale;
  Result.z := v1.z / scale;
end;

function Invert(v1: Vector3D): Vector3D;                    // Inverzní vektor
begin
  Result.x := -v1.x;
  Result.y := -v1.y;
  Result.z := -v1.z;
end;

function Mag(x, y, z: Double): Double;                      // Vrací velikost vektoru
begin
  Result := sqrt(sqr(x) + sqr(y) + sqr(z));
end;

function Uni(V1: Vector3D): Vector3D;                       // Vrací jednotkovı vektor
var
  length: Double;
begin
  length := Mag(V1.x,V1.y,V1.z);
  if length = 0 then
    begin
    Result.x := 0.0;
    Result.y := 0.0;
    Result.z := 0.0;
    end
    else
    begin
    Result.x := V1.x / length;
    Result.y := V1.y / length;
    Result.z := V1.z / length;
    end;
end;

{ Mass }

procedure Mass.applyForce(force: Vector3D);
begin
  Self.force := Add(Self.force,force);                                          // Vnìjší síla je pøiètena
end;

constructor Mass.Create(m: Double);                                             // Konstruktor
begin
  Self.m := m;
end;

procedure Mass.init;
begin
  force.x := 0;
  force.y := 0;
  force.z := 0;
end;

procedure Mass.simulate(dt: Double);
begin
  vel := Add(vel,Multiply(Divide(force,m),dt));                                 // Zmìna rychlosti je pøiètena k aktuální rychlosti
  pos := Add(pos,Multiply(vel,dt));                                             // Zmìna polohy je pøiètena k aktuální poloze
end;

{ Simulation }

constructor Simulation.Create(numOfMasses: integer; m: Double);                 // Konstruktor vytvoøí objekty s danou hmotností
var
  a: integer;
begin
  Self.numOfMasses := numOfMasses;                                              // Inicializace poètu
  SetLength(masses,numOfMasses);                                                // Alokace dynamické pamìti pro pole ukazatelù
  for a := 0 to numOfMasses - 1 do                                              // Projdeme všechny ukazatele na objekty
    masses[a] := Mass.Create(m);                                                // Vytvoøíme objekt a umístíme ho na místo v poli
end;

function Simulation.getMass(index: integer): Mass;                              // Získání objektu s urèitım indexem
begin
  if (index < 0) or (index >= numOfMasses) then                                 // Pokud index není v rozsahu pole
    Result := nil                                                               // Vrátí NULL
    else
    Result := masses[index];                                                    // Vrátí objekt s danım indexem
end;

procedure Simulation.init;                                                      // Tato metoda zavolá init() metodu kadého objektu
var
  a: integer;
begin
  for a := 0 to numOfMasses - 1 do                                              // Prochází objekty
    masses[a].init;                                                             // Zavolání init() daného objektu
end;

procedure Simulation.operate(dt: Double);                                       // Kompletní simulaèní metoda
begin
  init;                                                                         // Krok 1: vynulování sil
  solve;                                                                        // Krok 2: aplikace sil
  simulate(dt);                                                                 // Krok 3: vypoèítání polohy a rychlosti objektù v závislosti na èase
end;

procedure Simulation.Release;                                                   // Uvolní dynamickou pamì
var
  a: integer;
begin
  for a := 0 to numOfMasses - 1 do                                              // Smae všechny vytvoøené objekty
    begin
    masses[a].Free;                                                             // Uvolní dynamickou pamì objektù
    masses[a] := nil;                                                           // Nastaví ukazatele na NULL
    end;
  SetLength(masses,0);                                                          // Uvolní dynamickou pamì ukazatelù na objekty
  masses := nil;                                                                // Nastaví ukazatel na NULL
end;

procedure Simulation.simulate(dt: Double);                                      // Vıpoèet v závislosti na èase
var
  a: integer;
begin
  for a := 0 to numOfMasses - 1 do                                              // Projdeme všechny objekty
    masses[a].simulate(dt);                                                     // Vıpoèet nové polohy a rychlosti objektu
end;

procedure Simulation.solve;
begin
  // Bez implementace, protoe nechceme v základním zásobníku ádné síly
  // Ve vylepšenıch zásobnících, bude tato metoda nahrazena, aby na objekty pùsobila nìjaká síla
end;

{ ConstantVelocity }

constructor ConstantVelocity.Create;
begin
  inherited Create(1,1.0);                                                      // Konstruktor nejdøíve pouije konstruktor nadøazené tøídy, aby vytvoøil objekt o hmotnosti 1 kg
  masses[0].pos := Vektor(0.0,0.0,0.0);                                         // Nastavíme polohu objektu na poèátek
  masses[0].vel := Vektor(1.0,0.0,0.0);                                         // Nastavíme rychlost objektu na (1.0, 0.0, 0.0) m/s
end;

{ MotionUnderGravitation }

constructor MotionUnderGravitation.Create(gravitation: Vector3D);
begin
  inherited Create(1,1.0);                                                      // Konstruktor nejdøíve pouije konstruktor nadøazené tøídy, aby vytvoøil 1 objekt o hmotnosti 1kg
  Self.gravitation := gravitation;                                              // Nastavení gravitace
  masses[0].pos := Vektor(-10.0,0.0,0.0);                                       // Nastavení polohy objektu
  masses[0].vel := Vektor(10.0,15.0,0.0);                                       // Nastavení rychlosti objektu
end;

procedure MotionUnderGravitation.solve;                                         // Aplikace gravitace na všechny objekty, na které má pùsobit
var
  a: integer;
begin
  inherited;
  for a := 0 to numOfMasses - 1 do                                              // Pouijeme gravitaci na všechny objekty (zatím máme jenom jeden, ale to se mùe do budoucna zmìnit)
    masses[a].applyForce(Multiply(gravitation,masses[a].m));                    // Síla gravitace se spoèítá F = m * g
end;

{ MassConnectedWithSpring }

constructor MassConnectedWithSpring.Create(springConstant: Double);
begin
  inherited Create(1,1.0);                                                      // Konstruktor nejdøíve pouije konstruktor nadøazené tøídy, aby vytvoøil 1 objekt o hmotnosti 1kg
  Self.springConstant := springConstant;                                        // Nastavení tuhosti pruiny
  connectionPos := Vektor(0.0,-5.0,0.0);                                        // Nastavení pozice upevòovacího bodu
  masses[0].pos := Add(connectionPos,Vektor(10.0,0.0,0.0));                     // Nastavení pozice objektu na 10 metrù napravo od bodu, ke kterému je uchycen
  masses[0].vel := Vektor(0.0,0.0,0.0);                                         // Nastavení rychlosti objektu na nulu
end;

procedure MassConnectedWithSpring.solve;                                        // Uití síly pruiny
var
  a: integer;
  springVector: Vector3D;
begin
  inherited;
  for a := 0 to numOfMasses - 1 do                                              // Pouijeme sílu na všechny objekty (zatím máme jenom jeden, ale to se mùe do budoucna zmìnit)
    begin
    springVector := Subtract(masses[a].pos,connectionPos);                      // Nalezení vektoru od pozice objektu k úchytu
    masses[0].applyForce(Multiply(Invert(springVector),springConstant));        // Pouití síly podle uvedeného vzorce
    end;
end;

end.
