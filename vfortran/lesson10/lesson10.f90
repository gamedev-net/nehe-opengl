! //
! // This Code Was Created By Lionel Brits / Jeff Molofee '99
! //
! // Visit NeHe Productions At www.demonews.com/hosted/nehe
! //
!-------------------------------------------------------------------------------------
! I start to port it on DVF (Fortran) DJIP (jean-philippe.perois@Wanadoo.fr) (french)
!
! if you have any problem let me know
!
! *Djip*** it use the f90gl project (http://math.nist.gov/f90gl/)
! *Djip*** and is do with DVF / (CompactVisualFortan V6.1)
!-------------------------------------------------------------------------------------
! f90GLU.lib 
! use dfwin                  // Header File For Windows
! use opengl_gl 		        // Header File For The OpenGL32 Library
! use opengl_glu		        // Header File For The GLu32 Library
! *Djip*** you have to use it in all routines....


! // #include <gl\glaux.h>	// Header File For The GLaux Library
! *Djip***  d'ont existe in F90GL (see OpenGL_aux.f90 module)

Module VarGlob

  use dfwin
  use opengl_gl
  use opengl_glu
  Use OpenGL_AUX

    integer :: hRC                      ! Permanent Rendering Context
    integer :: hDC                      ! Private GDI Device Context

    logical :: keys(0:255)              ! Array Used For The Keyboard Routine
    Logical :: light			        ! Lighting ON/OFF
    Logical :: blend			        ! Blending OFF/ON?

    Logical :: lp			            ! L Pressed?
    Logical :: fp			            ! F Pressed?
    Logical :: bp			            ! B Pressed?

    Real(GLfloat)::	xrot	            ! X Rotation
!    Real(GLfloat)::	yrot	            ! Y Rotation
    Real(GLfloat)::	xspeed	            ! X Rotation Speed
!    Real(GLfloat)::	yspeed	            ! Y Rotation Speed

    Real(GLfloat)::	walkbias	        ! 
    Real(GLfloat)::	walkbiasangle	    ! 

    Real(GLfloat)::	lookupdown		    ! 

	REAL(4), PARAMETER :: PI=3.1415927             ! DPI=3.141592653589793238D0
! const float piover180 = 0.0174532925f;

	Real :: heading, xpos, zpos

    Real(GLfloat)::	camx=0, camy=0, camz=0		! Camera Location
    Real(GLfloat):: therotate

!    Real(GLfloat)::	z=0.0_glfloat	    ! Depth Into The Screen

    Real(GLfloat) :: LightAmbient(4)      = (/ 0.5_glfloat, 0.5_glfloat, 0.5_glfloat, 1.0_glfloat /)
    Real(GLfloat) :: LightDiffuse(4)      = (/ 1.0_glfloat, 1.0_glfloat, 1.0_glfloat, 1.0_glfloat /)
    Real(GLfloat) :: LightPosition(4)     = (/ 0.0_glfloat, 0.0_glfloat, 2.0_glfloat, 1.0_glfloat /)

    integer(GLuint)	:: filter			! Which Filter To Use
    integer(GLuint) :: texture(0:2)		! Storage for 3 textures

! // Our Model Goes Here:
! SECTOR sector1;
	Real(Glfloat), Allocatable :: Sector(:,:,:)   ! (dim= (5,3,n).... I Use Array not derived type...

End Module VarGlob

!// Converts Degrees To Radians. There Are 2 PI Radians In 360 Degrees.
!   I deside to use direct Radian (not degré)

subroutine readstr( file, str )

	integer :: file
	character(*) :: str

! 100	Format(A255)
100	Format(A<Len(str)>)

	read(file, 100) str
	do while ( (str(1:2).eq.'//') .or. ( Len_Trim(str).eq.0))
		read(file, 100) str
	enddo 

	return
end subroutine	


subroutine SetupWorld( )

	Use VarGlob
	
	integer :: file
	integer :: numtriangles
	integer :: loop, vert
	character(256) :: str
	Real(4) x,y,z,u,v

	file = 10
	Open( Unit=file, File='Data\World.txt', Status='OLD', Form='FORMATTED', ACCESS='SEQUENTIAL') 

	call readstr( file, str)
    read (str (11:20),*) numtriangles

	Allocate (sector(5,3,numtriangles))

	do loop = 1, numtriangles
		do vert = 1, 3
			call readstr( file, str)
			read(str,*) x,y,z,u,v
			sector(1,vert,loop) = x
			sector(2,vert,loop) = y
			sector(3,vert,loop) = z
			sector(4,vert,loop) = u
			sector(5,vert,loop) = v
		enddo
	enddo

	close (file)
	return
end subroutine	

! Load Bitmaps And Convert To Textures
subroutine LoadGLTextures()
	! Load Texture
    Use VarGlob

    integer(Glint) ignor

    type(AUX_RGBImageRec), pointer :: texture1
	texture1 => auxDIBImageLoad('Data/mud.bmp'C);
    if (.NOT.ASSOCIATED (texture1))  then 
		stop               ! Prevents The Rest Of The Code From Running
    endif

	! Create Nearest Filtered Texture
	call glGenTextures(3_glint, texture)
	call glBindTexture(GL_TEXTURE_2D, texture(0))
	call glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
	call glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
	call glTexImage2D(GL_TEXTURE_2D, 0, 3, texture1%sizeX, texture1%sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, texture1%datas)

	!Create Linear Filtered Texture
	call glBindTexture(GL_TEXTURE_2D, texture(1))
	call glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
	call glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)
	call glTexImage2D(GL_TEXTURE_2D, 0, 3, texture1%sizeX, texture1%sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, texture1%datas)

	! Create MipMapped Texture
	call glBindTexture(GL_TEXTURE_2D, texture(2))
	call glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
	call glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST)
	ignor = gluBuild2DMipmaps(GL_TEXTURE_2D, 3, texture1%sizeX, texture1%sizeY, GL_RGB, GL_UNSIGNED_BYTE, texture1%datas)

end subroutine LoadGLTextures

subroutine InitGL( Width, Height)     ! This Will Be Called Right After The GL Window Is Created

  Use VarGlob
  use opengl_gl
  use opengl_glu
 
  Implicit None

  Integer(GLSIZEI) :: Width, Height
  Real(GlDouble) :: Aspect
  Real(GlDouble) :: ZWidth, ZHeight

    filter = 0

	call LoadGLTextures()						! Load The Texture(s)
	call glEnable(GL_TEXTURE_2D)				! Enable Texture Mapping

	call glBlendFunc(GL_SRC_ALPHA,GL_ONE);		! Set The Blending Function For Translucency
	call glClearColor(0.0_glclampf, 0.0_glclampf, 0.0_glclampf, 0.0_glclampf)	! This Will Clear The Background Color To Black
	call glClearDepth(1.0_glclampd) 			! Enables Clearing Of The Depth Buffer
	call glDepthFunc(GL_LESS)					! The Type Of Depth Test To Do
	call glEnable(GL_DEPTH_TEST)				! Enables Depth Testing
	call glShadeModel(GL_SMOOTH)				! Enables Smooth Color Shading

	call glMatrixMode(GL_PROJECTION)
	call glLoadIdentity()						! Reset The Projection Matrix

    ZWidth=Width
    ZHeight=Height
    Aspect=ZWidth/ZHeight
	call gluPerspective(45.0_GlDouble,Aspect,0.1_GlDouble,100.0_GlDouble)

	call glMatrixMode(GL_MODELVIEW)

	call glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient)
	call glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse)
	call glLightfv(GL_LIGHT1, GL_POSITION,LightPosition)
	call glEnable(GL_LIGHT1)

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
  use VarGlob

  Implicit None
!{
	Real(GLfloat) :: x_m, y_m, z_m, u_m, v_m;
	Real(GLfloat) :: xtrans, ztrans, ytrans;
	Real(GLfloat) :: sceneroty;
	Integer :: numtriangles
	Integer :: loop

	xtrans = -xpos
	ztrans = -zpos
	ytrans = -walkbias-0.25

	sceneroty = - heading
	

	call glClear(ior(GL_COLOR_BUFFER_BIT,GL_DEPTH_BUFFER_BIT)) ! Clear The Screen And The Depth Buffer
	call glLoadIdentity()									   ! Reset The View

	call glRotatef(lookupdown*180/pi,1.0_glfloat,.0_glfloat,.0_glfloat)
	call glRotatef(sceneroty*180/pi,.0_glfloat,1.0_glfloat,.0_glfloat)
	
	call glTranslatef(xtrans, ytrans, ztrans);
	call glBindTexture(GL_TEXTURE_2D, texture(filter));

	
	numtriangles = Size(sector,3)           ! Fortran90 know all dimension of array!!!

	do loop = 1, numtriangles
		call glBegin(GL_TRIANGLES);
			call glNormal3f( 0.0_glfloat, 0.0_glfloat, 1.0_glfloat)		! ??? I don't know / is it true?

			call glTexCoord2fv(sector(4:5,1,loop)); call glVertex3fv(sector(1:3,1,loop))
			call glTexCoord2fv(sector(4:5,2,loop)); call glVertex3fv(sector(1:3,2,loop))
			call glTexCoord2fv(sector(4:5,3,loop)); call glVertex3fv(sector(1:3,3,loop))
		call glEnd()												! Done Drawing The Quad
	enddo

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
	    32,			        &	! Select A 32Bit Color Depth
	    0, 0, 0, 0, 0, 0,	&	! color bits ignord (?)
	    0,			        &	! no alpha buffer
	    0,			        &	! Shift Bit Ignored (?)
	    0,			        &	! no accumulation buffer
	    0, 0, 0, 0, 		&	! Accumulation Bits Ignored (?)
	    16,			        &	! 16Bit Z-Buffer (Depth Buffer)  
	    0,			        &	! no stencil buffer
	    0,			        &	! no auxiliary buffer
	    PFD_MAIN_PLANE,		&	! Main Drawing Layer
	    0,			        &	! Reserved (?)
	    0, 0, 0 )			    ! Layer Masks Ignored (?)

    TYPE (T_DEVMODE), Pointer :: DevMode_Null     ! *djip*** pointer null for comback...
    NULLIFY(DevMode_Null)


    select case (message)				    ! Tells Windows We Want To Check The Message
        case (WM_CREATE)
            hDC = GetDC(hwnd)              ! Gets A Device Context For The Window
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

	        hRC = wglCreateContext(hDC)
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
			call ReSizeGLScene(LOWORD(lParam),HIWORD(lParam))
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
        ignor = MessageBox(0, 'Failed To Register The Window Class.'C, 'Error'C, ior(MB_OK,MB_ICONHAND))
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

	dmScreenSettings%dmSize				= sizeof(dmScreenSettings)
	dmScreenSettings%dmPelsWidth        = 640								! Width
	dmScreenSettings%dmPelsHeight       = 480								! Height
	dmScreenSettings%dmFields           = ior(DM_PELSWIDTH, DM_PELSHEIGHT)	! Color Depth
	ignor = ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN)			! Switch To Fullscreen Mode

    ignor = ShowWindow(hwnd, SW_SHOW)           ! show windows
    ignor = UpdateWindow(hwnd)

	ignor = SetFocus(hWnd)
	ignor = wglMakeCurrent(hDC,hRC)

	call SetupWorld()

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
		Call DrawGLScene()
		ignor = SwapBuffers(hDC)
		if (keys(VK_ESCAPE)) then; ignor = SendMessage(hWnd,WM_CLOSE,0,0); endif
		if (keys(ICHAR('B')) .and. (.Not.(bp))) then
			bp= .TRUE. 
			blend = .Not.(blend)
			if (blend) then
				call glEnable(GL_BLEND);						! Turn Blending On
				call glDisable(GL_DEPTH_TEST);					! Turn Depth Testing Off
			 else
				call glDisable(GL_BLEND);						! Turn Blending Off
				call glEnable(GL_DEPTH_TEST);					! Turn Depth Testing On
            endif
        endif
		if (keys(ICHAR('L')) .and. (.Not.(lp))) then
			lp= .TRUE. 
			light= .Not.(light)
			if (light) then
				call glEnable(GL_LIGHTING)
			 else
				call glDisable(GL_LIGHTING)
            endif
        endif
		if (.Not.(keys(ICHAR('L')))) lp = .False. 
		if (keys(ICHAR('F')) .and. (.Not.(fp))) then
			fp= .TRUE. 
			filter=Mod(filter+1,3)
        endif
		if (.Not.(keys(ICHAR('F')))) fp = .False. 

		if (keys(VK_PRIOR))     lookupdown= lookupdown-1.745329251994329e-2
		if (keys(VK_NEXT))      lookupdown= lookupdown+1.745329251994329e-2
		if (keys(VK_RIGHT))     heading = heading - 1.745329251994329e-2
		if (keys(VK_LEFT))      heading = heading + 1.745329251994329e-2
		if (.Not.(keys(ICHAR('B')))) bp = .False. 
		if (keys(VK_UP))     then
			xpos=xpos-sin(heading)*0.05
			zpos=zpos-cos(heading)*0.05
			walkbiasangle= Modulo(walkbiasangle + 1.745329251994329e-1 ,2*pi)
			walkbias= sin(walkbiasangle) / 20.0
		endif
		if (keys(VK_DOWN))     then
			xpos=xpos+sin(heading)*0.05
			zpos=zpos+cos(heading)*0.05
			walkbiasangle= Modulo(walkbiasangle - 1.745329251994329e-1 ,2*pi)
			walkbias= sin(walkbiasangle) / 20.0
		endif
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
