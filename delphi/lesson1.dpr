program lesson1;

{   This Code Was Created By Jeff Molofee 2000
    A HUGE Thanks To Fredric Echols For Cleaning Up
    And Optimizing This Code, Making It More Flexible!
    If You've Found This Code Useful, Please Let Me Know.
    Visit My Site At nehe.gamedev.net

    Conversion of the basecode to Delphi By Peter De Jaegher(Perry.dj@glo.be)
    Thanks To Marc Aarts for his Input

    Conversion To Delphi by Marc Aarts (marca@stack.nl)}

uses
  Windows,
  Messages,
  OpenGL,
  GLaux;        //Glaux unit

{ The 'glAux' unit can be found at

     http:=//www.delphi-jedi.org/DelphiGraphics/OpenGL/GLAux.zip

    The glaux translation was done by Manuel Parma and is hosted at the
    Delphi-Jedi Project web site in the graphics section. You may also
    be interested in the OpenGL headers available there, since they are
    more complete than the version that shipped with Delphi 4 and 5.
    The OpenGL headers there support the full 1.1 spec and supports dynamic
    linking to the opengl32.dll so you can detect whether or not it's
    available in the first place. If you DO use that version of the OpenGL
    header, you can remove the two texture procedures declared below since
    they are present in that translation.

    Please note: the glAux unit will REQUIRE the glaux.dll library to be
    present when you run this program. You can install it from the GLAux.zip
    mentioned above into your Windows SYSTEM directory (SYSTEM32 for you
    NT users). Or, simply keep a copy of it in the same directory as your
    application.

    If any of this is confusing or you need help, feel free to e-mail me
    at marca@stack.nl. Do NOT e-mail Jeff regarding Delphi translation
    issues since he is not responsible for the translation I've done here.}



var
  h_Rc: HGLRC;		            // Permanent Rendering Context
  h_Dc: HDC;                        // Private GDI Device Context
  h_Wnd:HWND;                       // Holds Our Window Handle
  keys: array [0..255] of BOOL;	    // Array Used For The Keyboard Routine
  Active:bool;                      // Window Active Flag
  FullScreen:bool;                  // Fullscreen Flag


procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); //Resize And Initialze The GL Window
var
  fWidth, fHeight: GLfloat;
begin
  if (Height=0) then		     // Prevent A Divide By Zero If The Window Is Too Small
     Height:=1;                      // By Making The Height One
  glViewport(0, 0, Width, Height);   // Reset The Current Viewport And Perspective Transformation
  glMatrixMode(GL_PROJECTION);       // Select The Projection Matrix
  glLoadIdentity();                  // Reset The Projection Matrix
  fWidth := width;
  fHeight := height;
  gluPerspective(45.0,fWidth/fHeight,0.1,100.0);// Calculate The Aspect Ratio Of The Window
  glMatrixMode(GL_MODELVIEW);        // Select The Modelview Matrix
  glLoadIdentity                     //Reset The Modelview Matrix
end;


function InitGL:bool;	// All Setup For OpenGL Goes Here
begin
  glShadeModel(GL_SMOOTH);			   // Enables Smooth Color Shading
  glClearColor(0.0, 0.35, 0.45, 0.5);		   // Black Background; Red, Green, Blue and ALFA parameters; the values go from 0.0 to 1.0; I changed it a little
  glClearDepth(1.0);				   // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);			   // Enables Depth Testing
  glDepthFunc(GL_LESS);				   // The Type Of Depth Test To Do
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);//Realy Nice perspective calculations
  initGL:=true;                                    // Everything went fine
end;


function DrawGLScene():bool;    // Here's Where We Do All The Drawing!!! Right after glLoadIdentity and before DrawGLScene:=true
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
  glLoadIdentity();	        // Reset The View
  DrawGLScene:=true;            // Everything Went OK
end;


function WndProc(hWnd: HWND;         //Handle For The Window
                 message: UINT;      //Message For This Window
                 wParam: WPARAM;     //Additional Message Information
                 lParam: LPARAM):    //Additional Message Information
                                  LRESULT; stdcall;
begin
  // The WM_SYSCOMMAND Message Is Not In The Case-Loop, Because If It Is, Other Messages
  // Won't Be Handled Anymore(If You Know The Reason, Please Let Me Know...)
  if message=WM_SYSCOMMAND then    //Intercept System Commands
    begin
      case wParam of                         //Check System Calls
        SC_SCREENSAVE,SC_MONITORPOWER:       //Screensaver Trying To Start, Monitor Trying To Enter Powersave?
          begin
            result:=0;                       //Prevent This From Happening
            exit;                            //Exit
          end;
      end;
    end;
  case message of // Tells Windows We Want To Check The Message
    WM_ACTIVATE:
      begin
        if (Hiword(wParam)=0) then  //Check Minimization State
          active:=true              //Program Is Active
        else
          active:=false;            //Program Is No Longer Active
        Result:=0;                  //Return To The Message Loop
      end;
    WM_CLOSE:                       //Did We Get A Close Message
      Begin
        PostQuitMessage(0);         //Send A Quit Message
        result:=0                   //Return To The Message Loop
      end;
    WM_KEYDOWN:                     //Is A Key Being Held Down?
      begin
        keys[wParam] := TRUE;       //If So, Mark It As True
        result:=0;                  //Return To The Message Loop
      end;
    WM_KEYUP:                       //Is A Key Being Released?
      begin
    	keys[wParam] := FALSE;      //If So, Mark It As False
        result:=0;                  //Return To The Message Loop
      end;
    WM_SIZe:                        //Resize The GL Window
      begin
    	ReSizeGLScene(LOWORD(lParam),HIWORD(lParam)); //Loword=Width, Highword=Height
        result:=0;                  //Return To The Message Loop
      end
    else
      //Pass All Unhandled Messages To DefWinProc
      begin
      	Result := DefWindowProc(hWnd, message, wParam, lParam);
      end;
    end;
end;


procedure KillGLWindow; //Properly Kill The Window
begin
  if FullScreen then   //Are We In Fullscreen Mode?
    begin
      ChangeDisplaySettings(devmode(nil^),0); //Switch Back To The Desktop
      showcursor(true);  //Show The Mouse Pointer
    end;
  if h_rc<> 0 then       //Is There A Rendering Context?
    begin
      if (not wglMakeCurrent(h_Dc,0)) then   //Are We Able To Release Dc and Rc contexts?
        MessageBox(0,'Release of DC and RC failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      if (not wglDeleteContext(h_Rc)) then   //Are We Able To Delete The Rc?
        begin
          MessageBox(0,'Release of Rendering Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
          h_Rc:=0;                           //Set Rc To Null
        end;
    end;
  if (h_Dc=1) and (releaseDC(h_Wnd,h_Dc)<>0) then   //Are We Able To Release The Dc?
    begin
      MessageBox(0,'Release of Device Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Dc:=0;                           //Set Dc To Null
    end;
  if (h_Wnd<>0) and (not destroywindow(h_Wnd))then   //Are We Able To Destroy The Window?
    begin
      MessageBox(0,'Could not release hWnd.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Wnd:=0;                          //Set hWnd To Null
    end;
  ///////////////////////        nelson    added section 1  ///////////////////////////////
  if (not UnregisterClass('OpenGL',hInstance)) then   // Are We Able To Unregister Class
    begin
      MessageBox(0,'Could Not Unregister Class.','SHUTDOWN ERROR',MB_OK or MB_ICONINFORMATION);
      hInstance:=NULL;				     // Set hInstance To NULL
    end;
 ///////////////////////         nelson    ...section 1 up to here  ///////////////////////

end;


function CreateGlWindow(title:Pchar; width,height,bits:integer;FullScreenflag:bool):boolean stdcall;
var
  Pixelformat: GLuint;           //Holds The Result After Searching For A Match
  wc:TWndclass;                  //Windows Class Structure
  dwExStyle:dword;               //Extended Window Style
  dwStyle:dword;                 //Window Style
  pfd: pixelformatdescriptor;    //Tells Windows How We Want Things To Be
  dmScreenSettings: Devmode;     //Device Mode
  h_Instance:hinst;              // Holds The Instance Of The Application
begin
  h_instance:=GetModuleHandle(nil); //Grab An Instance For Our Window
  FullScreen:=FullScreenflag;       //Set The Global Fullscreen Flag
  with wc do
    begin
      style:=CS_HREDRAW or CS_VREDRAW or CS_OWNDC;   //Redraw On Size -- Own DC For Window
      lpfnWndProc:=@WndProc;                         //WndProc Handles The Messages
      cbClsExtra:=0;                                 //No Extra Window Data
      cbWndExtra:=0;                                 //No Extra Window Data
      hInstance:=h_Instance;                         //Set The Instance
      hIcon:=LoadIcon(0,IDI_WINLOGO);                //Load The Default Icon
      hCursor:=LoadCursor(0,IDC_ARROW);              //Load The Arrow Pointer
      hbrBackground:=0;                              //No BackGround Required For OpenGL
      lpszMenuName:=nil;                             //We Don't Want A Menu
      lpszClassName:='OpenGl';                       //Set The CLass Name
    end;
  if  RegisterClass(wc)=0 then                       //Attempt To Register The Window Class
    begin
      MessageBox(0,'Failed To Register The Window Class.','Error',MB_OK or MB_ICONERROR);
      CreateGLwindow:=false;                         //Return False
      exit;                                          //Exit
    end;
  if FullScreen then                                 //Attempt Fullscreen Mode
    begin
      ZeroMemory( @dmScreenSettings, sizeof(dmScreenSettings) );  //Makes Sure Memory's Available
      with dmScreensettings do
        begin
          dmSize := sizeof(dmScreenSettings);         //Size Of The Devmode Structure
          dmPelsWidth  := width;	              //Selected Screen Width
	  dmPelsHeight := height;                     //Selected Screen Height
          dmBitsPerPel := bits;                       //Selected Bits Per Pixel
          dmFields     := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
        end;
      //Try To Set The Selected Mode And Get Results. CDS_FullScreen Gets Rid Of The Start Bar
      if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN))<>DISP_CHANGE_SUCCESSFUL THEN
        Begin
          if MessageBox(0,'This FullScreen Mode Is Not Supported. Use Windowed Mode Instead?'
                                             ,'NeHe GL',MB_YESNO or MB_ICONEXCLAMATION)= IDYES then
                FullScreen:=false   //Select The Windowed Mode
          else
            begin
              //Popup A Message Box Letting The User Know The Program Is Closing
              MessageBox(0,'Program Will Now Close.','Error',MB_OK or MB_ICONERROR);
              CreateGLWindow:=false;    //Return False
            end;
          end;
    end;
  if FullScreen then  //Check If We're Still In Fullscreen Mode
    begin
      dwExStyle:=WS_EX_APPWINDOW;  //Extended Window Style
      dwStyle:=WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; //Window Style
      Showcursor(false);           //Hide Mouse Pointer
    end
  else
    begin
      dwExStyle:=WS_EX_APPWINDOW or WS_EX_WINDOWEDGE;   //Extended Window Style
      dwStyle:=WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; //Windows Style
    end;
  //Create The Window
  H_wnd:=CreateWindowEx(dwExStyle,                   //Extende Style For The Window
                               'OpenGl',             //Class Name
                               Title,                //Window Title
                               dwStyle,              //Window Style
                               0,0,                  //Window Position
                               width,height,         //Selected Width and Height
                               0,                    //No Parent Window
                               0,                    //No Menu
                               hinstance,            //Instance
                               nil);                 //Don't Pass Anything To WM_CREATE
  if h_Wnd=0 then              //If The Window Creation Failed
    begin
      KillGlWindow();          //Reset The Display
      MessageBox(0,'Window creation error.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;   //Return False
      exit;
    end;
  with pfd do    //Tells Windows How We Want Things To Be
    begin
      nSize:= SizeOf( PIXELFORMATDESCRIPTOR ); // Size Of This Pixel Format Descriptor
      nVersion:= 1;                            // Version Number (?)
      dwFlags:= PFD_DRAW_TO_WINDOW             // Format Must Support Window
        or PFD_SUPPORT_OPENGL                  // Format Must Support OpenGL
        or PFD_DOUBLEBUFFER;                   // Must Support Double Buffering
      iPixelType:= PFD_TYPE_RGBA;              // Request An RGBA Format
      cColorBits:= bits;                       // Select Our Color Depth
      cRedBits:= 0;                            // Color Bits Ignored
      cRedShift:= 0;
      cGreenBits:= 0;
      cBlueBits:= 0;
      cBlueShift:= 0;
      cAlphaBits:= 0;                          // No Alpha Buffer
      cAlphaShift:= 0;                         // Shift Bit Ignored
      cAccumBits:= 0;                          // No Accumulation Buffer
      cAccumRedBits:= 0;                       // Accumulation Bits Ignored
      cAccumGreenBits:= 0;
      cAccumBlueBits:= 0;
      cAccumAlphaBits:= 0;
      cDepthBits:= 16;                         // 16Bit Z-Buffer (Depth Buffer)
      cStencilBits:= 0;                        // No Stencil Buffer
      cAuxBuffers:= 0;                         // No Auxiliary Buffer
      iLayerType:= PFD_MAIN_PLANE;             // Main Drawing Layer
      bReserved:= 0;                           // Reserved
      dwLayerMask:= 0;                         // Layer Masks Ignored
      dwVisibleMask:= 0;
      dwDamageMask:= 0;
    end;
  h_Dc := GetDC(h_Wnd);                        // Try Getting A Device Context
  if h_Dc=0 then                               // Did We Get Device Context For The Window?
    begin
      KillGLWindow();                          //Reset The Display
      MessageBox(0,'Cant''t create a GL device context.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;                   //Return False
      exit;
    end;
  PixelFormat := ChoosePixelFormat(h_Dc, @pfd);// Finds The Closest Match To The Pixel Format We Set Above
  if (PixelFormat=0) then                      //Did We Find A Matching Pixelformat?
    begin
      KillGLWindow();                          //Reset The Display
      MessageBox(0,'Cant''t Find A Suitable PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;                   //Return False
      exit;
    end;
  if (not SetPixelFormat(h_Dc,PixelFormat,@pfd)) then  //Are We Able To Set The Pixelformat?
    begin
      KillGLWindow();                          //Reset The Display
      MessageBox(0,'Cant''t set PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;                   //Return False
      exit;
    end;
  h_Rc := wglCreateContext(h_Dc);              //Are We Able To Get A Rendering Context?
  if (h_Rc=0) then
    begin
      KillGLWindow();                          //Reset The Display
      MessageBox(0,'Cant''t create a GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;                   //Return False
      exit;
    end;
  if (not wglMakeCurrent(h_Dc, h_Rc)) then     //Are We Able To Activate The Rendering Context?
    begin
      KillGLWindow();                          //Reset The Display
      MessageBox(0,'Cant''t activate the GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;                   //Return False
      exit;
    end;
  ShowWindow(h_Wnd,SW_SHOW);       //Show The Window
  SetForegroundWindow(h_Wnd);      //Slightly Higher Priority
  SetFOcus(h_Wnd);                 //Set Keyboard Focus To The Window
  ReSizeGLScene(width,height);     //Set Up Our Perspective Gl Screen
  if (not InitGl()) then           //Can we Initialize The Newley Created GL Window
    begin
      KillGLWindow();              //Reset The Display
      MessageBox(0,'initialization failed.','Error',MB_OK or MB_ICONEXCLAMATION);
      CreateGLWindow:=false;       //Return False
      exit;
    end;

  CreateGLWindow:=true;            //Succes
end;


function WinMain(hInstance: HINST;          //Instance
		 hPrevInstance: HINST;      //Previous Instance
		 lpCmdLine: PChar;          //Command Line Parameters
		 nCmdShow: integer):        //Window Show State
                                    integer; stdcall;
var
  msg: TMsg;      // Windows Message Structure
  done: Bool;     // Variable To Exit The Loop

begin
  done:=false;
  //Ask The User Which Screenmode They Prefer
  if MessageBox(0,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                             MB_YESNO or MB_ICONQUESTION)=IDNO then
    FullScreen:=false      //Windowed Mode
  else
    FullScreen:=true;      //Fullscreen Mode
  if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,FullScreen) then //Could We Create The OpenGl Window?
    begin
      Result := 0;    //Quit If The Window Wasn't Created
      exit;
    end;
  while not done do   //Loop That Keeps The Program Running
    begin
      if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then  //Is There A Message Running
        begin
          if msg.message=WM_QUIT then                 //Have We Received A Quit Message?
            done:=true                                //If So, Done=True
          else
            begin
	      TranslateMessage(msg);                  //Translate The Message
	      DispatchMessage(msg);                   //Dispatch The Message
	    end;
        end
      else
        begin
          //Draw The GL Scene. Watch For ESC Key Aned Quit Messages from DrawGLScene()
          if (active and not(DrawGLScene()) or keys[VK_ESCAPE]) then
            done:=true                      //ESC PRessed Or DrawGLScene Signalle A Quit
          else
            SwapBuffers(h_Dc);              //Not Time TO Quit Yet, Update The Screen

/////////////////////////         nelson added section 2 starting here    /////////////////
          if keys[VK_F1] then               // if F1 being pressed?
           begin
            Keys[VK_F1] := false;           // if so make the key FALSE
            KillGLWindow();                 // Kill our current window
            FullScreen := not FullScreen;   // Toggle Fullscreen / Windowed mode
            // Recreate our OpenGL Window
               if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,fullscreen) then
                 Result := 0;                   // Quit if window was not created
           end;
////////////////////////         section 2 ends here   ///////////////////////////////////           
        end;
    end;                                    // while loop
  killGLwindow();                           //Shutdown
  result:=msg.wParam;
end;

// this part is like the main() in c++
begin
  active:=true;                             //The Active Variable Is Set To True By Default
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   //This Starts the program
end.

