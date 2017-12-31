unit Physics2;

interface

uses Physics;

type
  Spring = class                                                                // Tøída pružiny
    public
    mass1: Mass;                                                                // Èástice na prvním konci pružiny
    mass2: Mass;                                                                // Èástice na druhém konci pružiny
    springConstant: Double;                                                     // Konstanta tuhosti pružiny
    springLength: Double;                                                       // Délka, pøi které nepùsobí žádné síly
    frictionConstant: Double;                                                   // Konstanta vnitøního tøení
    constructor Create(mass1: Mass; mass2: Mass; springConstant, springLength, frictionConstant: Double); // Konstruktor
    procedure solve;                                                            // Aplikování sil na èástice
    end;

  RopeSimulation = class(Simulation)                                            // Tøída simulace lana
    springs: array of Spring;                                                   // Pružiny spojující èástice
    gravitation: Vector3D;                                                      // Gravitaèní zrychlení
    ropeConnectionPos: Vector3D;                                                // Bod v prostoru; pozice první èástice pro ovládání lanem
    ropeConnectionVel: Vector3D;                                                // Rychlost a smìr požadovaného pohybu
    groundRepulsionConstant: Double;                                            // Konstanta reprezentující, jak moc zemì odráží èástice
    groundFrictionConstant: Double;                                             // Konstanta reprezentující velikost tøení èástic se zemí (posouváme po zemi)
    groundAbsorptionConstant: Double;                                           // Konstanta reprezentující velikost absorbce tøení èástic se zemí (vertikální kolize)
    groundHeight: Double;                                                       // Pozice roviny zemì na ose y
    airFrictionConstant: Double;                                                // Konstanta odporu vzduchu na èástice
    constructor Create(numOfMasses: integer;                                    // Konstruktor tøídy // Poèet èástic
                        m,                                                      // Hmotnost každé èástice
                        springConstant,                                         // Tuhost pružiny
                        springLength,                                           // Délka pružiny v klidovém stavu
                        springFrictionConstant: Double;                         // Konstanta vnitøního tøení pružiny
                        gravitation: Vector3D;                                  // Gravitaèní zrychlení
                        airFrictionConstant,                                    // Odpor vzduchu
                        groundRepulsionConstant,                                // Odrážení èástic zemí
                        groundFrictionConstant,                                 // Tøení èástic se zemí
                        groundAbsorptionConstant,                               // Absorbce sil zemí
                        groundHeight: Double);                                  // Pozice zemì na ose y
    procedure solve; override;                                                  // Aplikování sil
    procedure simulate(dt: Double); override;                                   // Simulace lana
    procedure setRopeConnectionVel(ropeConnectionVel: Vector3D);                // Nastavení rychlosti první èástice
    procedure release; override;                                                // Uvolnìní prostøedkù
    end;

implementation

{ Spring }

constructor Spring.Create(mass1, mass2: Mass; springConstant, springLength,     // Konstruktor
  frictionConstant: Double);
begin
  Self.springConstant := springConstant;                                        // Nastavení èlenských promìnných
  Self.springLength := springLength;
  Self.frictionConstant := frictionConstant;
  Self.mass1 := mass1;
  Self.mass2 := mass2;
end;

procedure Spring.solve;                                                         // Aplikování sil na èástice
var
  springVector: Vector3D;
  r: Double;
  force: Vector3D;
begin
  springVector := Subtract(mass1.pos,mass2.pos);                                // Vektor mezi èásticemi
  r := Mag(springVector.x,springVector.y,springVector.z);                       // Vzdálenost èástic
  force := Vektor(0,0,0);                                                       // Pomocný vektor síly
  if r <> 0 then                                                                // Proti dìlení nulou
    force := Add(force,Multiply(Divide(springVector,r),(r - springLength) * (- springConstant))); // Výpoèet síly podle vzorce
  force := Add(force,Multiply(Invert(Subtract(mass1.vel,mass2.vel)),frictionConstant)); // Zmenšení síly o tøení
  mass1.applyForce(force);                                                      // Aplikování síly na èástici 1
  mass2.applyForce(Invert(force));                                              // Aplikování opaèné síly na èástici 2
end;

{ RopeSimulation }

constructor RopeSimulation.Create(numOfMasses: integer; m, springConstant,      // Konstruktor tøídy
  springLength, springFrictionConstant: Double; gravitation: Vector3D;
  airFrictionConstant, groundRepulsionConstant, groundFrictionConstant,
  groundAbsorptionConstant, groundHeight: Double);
var
  a: integer;
begin
  inherited Create(numOfMasses,m);                                              // Inicializace pøedka tøídy
  Self.gravitation := gravitation;
  Self.airFrictionConstant := airFrictionConstant;
  Self.groundFrictionConstant := groundFrictionConstant;
  Self.groundRepulsionConstant := groundRepulsionConstant;
  Self.groundAbsorptionConstant := groundAbsorptionConstant;
  Self.groundHeight := groundHeight;
  for a := 0 to numOfMasses - 1 do                                              // Nastavení poèáteèní pozice èástic
    begin
    masses[a].pos.x := a * springLength;                                        // Offsety jednotlivých èástic
    masses[a].pos.y := 0;                                                       // Rovnobìžnì se zemí
    masses[a].pos.z := 0;                                                       // Rovnobìžnì s obrazovkou
    end;
  SetLength(springs,numOfMasses);                                               // Alokace pamìti pro ukazatele na pružiny
  for a := 0 to numOfMasses - 2 do                                              // Vytvoøení jednotlivých pružin
    springs[a] := Spring.Create(masses[a],masses[a+1],springConstant,springLength,springFrictionConstant);  // Dvì èástice na pružinu
end;

procedure RopeSimulation.release;
var
  a: integer;
begin
  inherited;
  for a := 0 to numOfMasses - 1 do
    begin
    springs[a].Free;
    springs[a] := nil;
    end;
  SetLength(springs,0);
  springs := nil;
end;

procedure RopeSimulation.setRopeConnectionVel(ropeConnectionVel: Vector3D);     // Nastavení rychlosti první èástice
begin
  Self.ropeConnectionVel := ropeConnectionVel;                                  // Pøiøazení rychlostí
end;

procedure RopeSimulation.simulate(dt: Double);                                  // Simulace lana
begin
  inherited;                                                                    // Metoda pøedka
  ropeConnectionPos := Add(ropeConnectionPos,Multiply(ropeConnectionVel,dt));   // Zvìtšení pozice o rychlost
  if ropeConnectionPos.y < groundHeight then                                    // Dostala se èástice pod zem?
    begin
    ropeConnectionPos.y := groundHeight;                                        // Pøesunutí na úroveò zemì
    ropeConnectionVel.y := 0;                                                   // Nulování rychlosti na ose y
    end;
  masses[0].pos := ropeConnectionPos;                                           // Pozice první èástice
  masses[0].vel := ropeConnectionVel;                                           // Rychlost první èástice
end;

procedure RopeSimulation.solve;                                                 // Aplikování sil
var
  a: integer;
  v: Vector3D;
  force: Vector3D;
begin
  inherited;
  for a := 0 to numOfMasses - 2 do                                              // Prochází pružiny
    springs[a].solve;                                                           // Aplikování sil na pružinu
  for a := 0 to numOfMasses - 1 do                                              // Prochází èástice
    begin
    masses[a].applyForce(Multiply(gravitation,masses[a].m));                    // Gravitace
    masses[a].applyForce(Multiply(Invert(masses[a].vel),airFrictionConstant));  // Odpor vzduchu
    if masses[a].pos.y < groundHeight then                                      // Kolize se zemí
      begin
      v := masses[a].vel;                                                       // Grabování rychlosti
      v.y := 0;                                                                 // Vynechází rychlosti na ose y
      masses[a].applyForce(Multiply(Invert(v),groundFrictionConstant));         // Tøecí síla zemì
      v := masses[a].vel;                                                       // Grabování rychlosti
      v.x := 0;                                                                 // Zanedbání rychlosti na osách x a z
      v.z := 0;
      if v.y < 0 then                                                           // Pouze pøi kolizi smìrem k zemi
        masses[a].applyForce(Multiply(Invert(v),groundAbsorptionConstant));     //Absorbèní síla
      force := Multiply(Vektor(0,groundRepulsionConstant,0),(groundHeight - masses[a].pos.y));  // Síla odrazu
      masses[a].applyForce(force);                                              // Aplikování síly odrazu
      end;
    end;
end;

end.
