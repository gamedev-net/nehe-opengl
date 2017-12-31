! // This code was created by Jeff Molofee '99
! // If you've found this code useful, please let me know.
! // Visit me at www.demonews.com/hosted/nehe

!-------------------------------------------------------------------------------------
! I start to port it on DVF (Fortran) DJIP (jean-philippe.perois@Wanadoo.fr) (french)
!
! if you have any problem let me know
!
! *Djip*** it use the f90gl project (http://math.nist.gov/f90gl/)
! *Djip*** and is do with DVF / (CompactVisualFortan V6.1)
!-------------------------------------------------------------------------------------

! use dfwin                  // Header File For Windows
! use opengl_gl 		        // Header File For The OpenGL32 Library
! use opengl_glu		        // Header File For The GLu32 Library
! *Djip*** you have to use it in all routines....


! // #include <gl\glaux.h>	// Header File For The GLaux Library
! *Djip***  not use and d'ont existe in F90GL

Module VarGlob
    integer:: hRC           ! Permanent Rendering Context
    integer:: hDC           ! Private GDI Device Context
    logical:: keys(0:255)   ! Array Used For The Keyboard Routine

End Module VarGlob

subroutine InitGL( Width, Height)     ! This Will Be Called Right After The GL Window Is Created

  use opengl_gl
  use opengl_glu
 
  Implicit None

  Integer(GLSIZEI) :: Width, Height
  Real(GlDouble) :: Aspect
  Real(GlDouble) :: ZWidth, ZHeight
	call glClearColor(0.0_glclampf, 0.0_glclampf, 0.0_glclampf, 0.0_glclampf)	! This Will Clear The Background Color To Black
	call glClearDepth(1.0_glclampd) 			! Enables Clearing Of The Depth Buffer
	call glDepthFunc(GL_LESS);					! The Type Of Depth Test To Do
	call glEnable(GL_DEPTH_TEST)				! Enables Depth Testing
	call glShadeModel(GL_SMOOTH)				! Enables Smooth Color Shading

	call glMatrixMode(GL_PROJECTION)
	call glLoadIdentity()						! Reset The Projection Matrix

    ZWidth=Width
    ZHeight=Height
    Aspect=ZWidth/ZHeight
	call gluPerspective(45.0_GlDouble,Aspect,0.1_GlDouble,100.0_GlDouble)

	call glMatrixMode(GL_MODELVIEW)
End Subroutine InitGL

subroutine ReSizeGLScene( Width, Height)

  use opengl_gl
  use opengl_glu

  Implicit None

  Integer(GLSIZEI) :: Width, Height
  Real(GlDouble) :: Aspect
  Real(GlDouble) :: ZWidth, ZHeight

    if (Height==0) then; Height=1; endif         ! Prevent A Divide By Zero If The Window Is Too Small
	call glViewport(0, 0, Width, Height)		 ! Reset The Current Viewport And Perspective Transformation

	call glMatrixMode(GL_PROJECTION)
	call glLoadIdentity()

    ZWidth=Width
    ZHeight=Height
    Aspect=ZWidth/ZHeight
	call gluPerspective(45.0_GlDouble,Aspect,0.1_GlDouble,100.0_GlDouble)
	call glMatrixMode(GL_MODELVIEW)
End Subroutine ReSizeGLScene


Subroutine DrawGLScene()
  use opengl_gl
  use opengl_glu

  Implicit None

	call glClear(ior(GL_COLOR_BUFFER_BIT,GL_DEPTH_BUFFER_BIT)) ! Clear The Screen And The Depth Buffer
	call glLoadIdentity()									   ! Reset The View

	call glTranslatef(-1.5_glfloat,0.0_glfloat,-6.0_glfloat)

	call glBegin(GL_POLYGON)
		call glVertex3f( 0.0_glfloat, 1.0_glfloat, 0.0_glfloat)
		call glVertex3f(-1.0_glfloat,-1.0_glfloat, 0.0_glfloat)
		call glVertex3f( 1.0_glfloat,-1.0_glfloat, 0.0_glfloat)
	call glEnd()

	call glTranslatef(3.0_glfloat,0.0_glfloat,0.0_glfloat)

	call glBegin(GL_QUADS)
		call glVertex3f(-1.0_glfloat, 1.0_glfloat, 0.0_glfloat)
		call glVertex3f( 1.0_glfloat, 1.0_glfloat, 0.0_glfloat)
		call glVertex3f( 1.0_glfloat,-1.0_glfloat, 0.0_glfloat)
		call glVertex3f(-1.0_glfloat,-1.0_glfloat, 0.0_glfloat)
	call glEnd()
End Subroutine DrawGLScene


integer function WndProc( hwnd, message, wParam, lParam )
!DEC$ attributes stdcall :: WndProc

    use VarGlob
    use dfwin
    use opengl_gl
    use opengl_glu
    use opengl_w

    implicit none

    integer hwnd
    integer message
    integer wParam
    integer lParam
    integer(GLuint) PixelFormat
    type(t_RECT) Screen
    TYPE (T_DEVMODE), Pointer :: DevMode_Null       ! *djip*** pointer null for comback...

    integer ignor, nColors
    integer glnWidth, glnLength

    integer  ipfd
    parameter (ipfd=or(or(   PFD_DRAW_TO_WINDOW,  &  ! Format Must Support Window
                             PFD_SUPPORT_OPENGL), &  ! Format Must Support OpenGL 
			                 PFD_DOUBLEBUFFER))      ! Must Support Double Buffering
    type (t_PIXELFORMATDESCRIPTOR)::pfd = t_PIXELFORMATDESCRIPTOR( &
    	40,			        &	! Size Of This Pixel Format Descriptor
	    1,			        &   ! Version Number (?)
	    ipfd,               &
	    PFD_TYPE_RGBA,		&	! Must Support Double Buffering
	    16,			        &	! Select A 16Bit Color Depth
	    0, 0, 0, 0, 0, 0,	&	! color bits ignord (?)
	    0,			        &	! no alpha buffer
	    0,			        &	! Shift Bit Ignored (?)
	    0,			        &	! no accumulation buffer
	    0, 0, 0, 0, 		&	! Accumulation Bits Ignored (?)
	    32,			        &	! 16Bit Z-Buffer (Depth Buffer)  
	    0,			        &	! no stencil buffer
	    0,			        &	! no auxiliary buffer
	    PFD_MAIN_PLANE,		&	! Main Drawing Layer
	    0,			        &	! Reserved (?)
	    0, 0, 0 )			    ! Layer Masks Ignored (?)


    select case (message)				    ! Tells Windows We Want To Check The Message
        case (WM_CREATE)
            hDC = GetDC(hwnd);              ! Gets A Device Context For The Window
            PixelFormat = ChoosePixelFormat(hDC, pfd)		! Finds The Closest Match To The Pixel Format We Set Above

            if (PixelFormat .eq. 0) then
                ignor = MessageBox(0, 'Can''t Find A Suitable PixelFormat.'C, 'Error'C, ior(MB_OK,MB_ICONHAND))  ! MB_ICONERROR=MB_ICONHAND and MB_ICONERROR do not existe in module  "dfwin.mod"
	            call PostQuitMessage(0)     ! This Sends A 'Message' Telling The Program To Quit
                return                      ! Prevents The Rest Of The Code From Running
            endif

            if (SetPixelFormat(hDC, PixelFormat, pfd) .eq. 0) then
                ignor = MessageBox(0, "Can't Set The PixelFormat."C, "Error"C, ior(MB_OK,MB_ICONHAND))
 	            call PostQuitMessage(0)     ! This Sends A 'Message' Telling The Program To Quit
                return                      ! Prevents The Rest Of The Code From Running
            endif

	        hRC = wglCreateContext(hDC);
            if (hRC.eq. 0) then
                ignor = MessageBox(0, "Can't Create A GL Rendering Context."C, "Error"C, ior(MB_OK,MB_ICONHAND))
 	            call PostQuitMessage(0)     ! This Sends A 'Message' Telling The Program To Quit
                return                      ! Prevents The Rest Of The Code From Running
            endif
            if (wglMakeCurrent(hDC, hRC).eq. 0) then
                ignor = MessageBox(0, "Can't activate GLRC."C, "Error"C, ior(MB_OK,MB_ICONHAND))
 	            call PostQuitMessage(0)     ! This Sends A 'Message' Telling The Program To Quit
                return                      ! Prevents The Rest Of The Code From Running
            endif
	        ignor = GetClientRect(hWnd, Screen)
			Call InitGL(Screen.right, Screen.bottom)
	        return

        case (WM_DESTROY)
        case (WM_CLOSE)
	        ignor = ChangeDisplaySettings(DevMode_Null, 0)

	        ignor = wglMakeCurrent(hDC, NULL)
	        ignor = wglDeleteContext(hRC)
	        ignor = ReleaseDC(hWnd,hDC)

            call PostQuitMessage(0)     ! This Sends A 'Message' Telling The Program To Quit

            return

        case (WM_KEYDOWN)
			keys(wParam) = .TRUE.
            return

        case (WM_KEYUP)
			keys(wParam) = .FALSE.
            return

        case (WM_SIZE)
			call ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));
            return

        case default
            WndProc = DefWindowProc(hwnd, message, wParam, lParam)
            return
        end select
    return
end function WndProc

integer function WinMain( hInstance, hPrevInstance, lpCmdLine, nCmdShow )
!DEC$ IF DEFINED (_X86_)
!DEC$ attributes stdcall, alias: '_WinMain@16' :: WinMain
!DEC$ ELSE
!DEC$ attributes stdcall, alias: 'WinMain' :: WinMain
!DEC$ ENDIF

    use dfwin
    use VarGlob
    use opengl_w

    implicit none
    integer hInstance
    integer hPrevInstance
    integer lpCmdLine
    integer nCmdShow
    
    integer WndProc
    external WndProc
!DEC$ attributes stdcall :: WndProc

    integer ignor
    integer wsflag


    type (t_MSG) msg
    type (t_WNDCLASS) wc
    integer hwnd
    TYPE (T_DEVMODE) dmScreenSettings


    character szApp*20
    szApp = 'OpenGL WinClass'C             ! *DJIP*** C is use for C string..with DVF..


    if (hPrevInstance .eq. 0) then
	wc%style          = ior(CS_OWNDC,ior(CS_HREDRAW, CS_VREDRAW))
	wc%lpfnWndProc    = loc(WndProc)
	wc%cbClsExtra     = 0
	wc%cbWndExtra     = 0
	wc%hInstance      = hInstance
	wc%hIcon          = NULL
	wc%hCursor        = LoadCursor(NULL, IDC_ARROW)
	wc%hbrBackground  = NULL
	wc%lpszMenuName   = NULL
	wc%lpszClassName  = loc(szApp)
    if (RegisterClass(wc) .eq. 0) then
        ignor = MessageBox(0, 'Failed To Register The Window Class.'C, 'Error'C, ior(MB_OK,MB_ICONHAND));
        return
    endif

    end if

!        wsflag = or(or(or(WS_POPUP, WS_CLIPCHILDREN),WS_CLIPSIBLINGS),WS_TILEDWINDOW) ! *DJIP*** same with title.. and border (resizable).
        wsflag = or(or(WS_POPUP, WS_CLIPCHILDREN),WS_CLIPSIBLINGS)
    hwnd = CreateWindow(szApp,       &  ! create window
		"Jeff Molofee's GL Code Tutorial ... NeHe '99"C, &  ! Title Appearing At The Top Of The Window
                wsflag,               &
        CW_USEDEFAULT, CW_USEDEFAULT,        &			    ! The Position Of The Window On The Screen
        640, 480,           &								! The Width And Height Of The WIndow
        NULL,               &
        NULL,               &
        hInstance,          &
        NULL)

    if (hWnd .eq. 0) then
        ignor = MessageBox(0, 'Window Creation Error.'C, 'Error'C,  ior(MB_OK,MB_ICONHAND))
        return
    endif

	dmScreenSettings%dmSize				= sizeof(dmScreenSettings);
	dmScreenSettings%dmPelsWidth        = 640;								! Width
	dmScreenSettings%dmPelsHeight       = 480;								! Height
	dmScreenSettings%dmFields           = ior(DM_PELSWIDTH, DM_PELSHEIGHT)	! Color Depth
	ignor = ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN)			! Switch To Fullscreen Mode

    ignor = ShowWindow(hwnd, SW_SHOW)           ! show windows
    ignor = UpdateWindow(hwnd)

	ignor = SetFocus(hWnd);
	ignor = wglMakeCurrent(hDC,hRC);

    do while  (1)
		do while (PeekMessage(msg, NULL, 0, 0, PM_NOREMOVE))
			if (GetMessage(msg, NULL, 0, 0)) then
				ignor = TranslateMessage(msg)
				ignor = DispatchMessage(msg)
            else
                WinMain = .true.
				return
			endif
   		end do
		Call DrawGLScene();
		ignor = SwapBuffers(hDC);
		if (keys(VK_ESCAPE)) then ; ignor = SendMessage(hWnd,WM_CLOSE,0,0); endif
	end do
return
end function WinMain


! *DJIP***  this function do not exist in Fortan lets don it....
integer function LOWORD(lParam)
    integer lParam
    integer glnWidth

	glnWidth = and(lParam, #0000FFFF)  !  low word

    LOWORD=glnWidth

end function LOWORD

integer function HIWORD(lParam)
    integer lParam
    integer glnLength

	glnLength = ishft(lParam, -16)     !  high word

    HIWORD=glnLength

end function HIWORD
