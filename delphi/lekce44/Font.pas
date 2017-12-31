unit Font;

interface

uses OpenGL;

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external 'opengl32';
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';

type
  glFont = class
    public
      constructor Create;
      destructor Destroy; override;
      function GetListBase: GLuint;
      function GetTexture: GLuint;
      procedure SetWindowSize(width, height: GLint);
      procedure glPrintf(x, y: GLint; sada: GLint; text: string);
      procedure BuildFont(Scale: GLfloat = 1.0);
      procedure SetFontTexture(tex: GLuint);
    protected
      m_WindowWidth: GLdouble;
	    m_WindowHeight: GLdouble;
	    m_ListBase: GLuint;
	    m_FontTexture: GLuint;
    end;

implementation

{ glFont }

procedure glFont.BuildFont(Scale: GLfloat);                                     // Vytvoøí font
var
  cx, cy: GLfloat;
  loop: integer;
begin
  m_ListBase := glGenLists(256);                                                // Generování display listù
  if m_FontTexture <> 0 then
    begin
    glBindTexture(GL_TEXTURE_2D,m_FontTexture);                                 // Vybere texturu
    for loop := 0 to 255 do                                                     // 256 znakù
      begin
      cx := (loop mod 16) / 16.0;                                               // Pøíslušná èást textury
      cy := (loop div 16) / 16.0;
      glNewList(m_ListBase + loop,GL_COMPILE);                                  // Zaèátek tvorby display listu
        glBegin(GL_QUADS);
					glTexCoord2f(cx,1 - cy - 0.0625);
					glVertex2f(0,0);
					glTexCoord2f(cx + 0.0625,1 - cy - 0.0625);
					glVertex2f(16 * Scale,0);
					glTexCoord2f(cx + 0.0625,1 - cy);
					glVertex2f(16 * Scale,16 * Scale);
					glTexCoord2f(cx,1 - cy);
					glVertex2f(0,16 * Scale);
				glEnd;                                                                  
				glTranslated(10 * Scale,0,0);
      glEndList;                                                                // Konec display listu
      end;
    end;
end;

constructor glFont.Create;                                                      // Konstruktor
begin
  inherited;
  m_FontTexture := 0;
  m_ListBase := 0;
end;

destructor glFont.Destroy;                                                      // Destruktor
begin
  if m_FontTexture <> 0 then
    glDeleteTextures(1,@m_FontTexture);
  if m_ListBase <> 0 then
    glDeleteLists(m_ListBase,256);
  inherited;
end;

function glFont.GetListBase: GLuint;                                            // Vrací aktuální sadu znakù
begin
  Result := m_ListBase;
end;

function glFont.GetTexture: GLuint;                                             // Vrací aktuální texturu fontu
begin
  Result := m_FontTexture;
end;

procedure glFont.glPrintf(x, y, sada: GLint; text: string);                     // Výpis textu
begin
  if text = '' then exit;                                                       // Byl pøedán text?
  if sada > 1 then sada := 1;
  glEnable(GL_TEXTURE_2D);                                                      // Povolí textury
  glEnable(GL_BLEND);                                                           // Povolí blending
  glBlendFunc(GL_SRC_COLOR,GL_ONE_MINUS_SRC_COLOR);                             // Typ blendingu
  glBindTexture(GL_TEXTURE_2D,m_FontTexture);                                   // Výbìr textury
  glDisable(GL_DEPTH_TEST);                                                     // Vypne hloubkové testování
  glMatrixMode(GL_PROJECTION);                                                  // Vybere projekèní matici
  glPushMatrix;                                                                 // Uloží projekèní matici
  glLoadIdentity;                                                               // Reset matice
  glOrtho(0,m_WindowWidth,0,m_WindowHeight,-1,1);                               // Nastavení kolmé projekce
  glMatrixMode(GL_MODELVIEW);                                                   // Výbìr matice
  glPushMatrix;                                                                 // Uložení matice
  glLoadIdentity;                                                               // Reset matice
  glTranslated(x,y,0);                                                          // Pozice textu (0,0 - levá dolní)
  glListBase(m_ListBase-32+(128*sada));                                         // Zvolí znakovou sadu (0 nebo 1)
  glCallLists(length(text),GL_BYTE,Pchar(text));                                // Vykreslení textu na obrazovku
  glMatrixMode(GL_PROJECTION);                                                  // Výbìr projekèní matice
  glPopMatrix;                                                                  // Obnovení uložené projekèní matice
  glMatrixMode(GL_MODELVIEW);                                                   // Výbìr matice modelview
  glPopMatrix;                                                                  // Obnovení uložené modelview matice
  glEnable(GL_DEPTH_TEST);                                                      // Zapne hloubkové testování
  glDisable(GL_BLEND);                                                          // Vypne blending
  glDisable(GL_TEXTURE_2D);                                                     // Vypne textury
end;

procedure glFont.SetFontTexture(tex: GLuint);                                   // Nastaví texturu fontu
begin
  if tex <> 0 then
    m_FontTexture := tex;
end;

procedure glFont.SetWindowSize(width, height: GLint);                           // Velikost okna
begin
  m_WindowWidth := width;
  m_WindowHeight := height;
end;

end.
