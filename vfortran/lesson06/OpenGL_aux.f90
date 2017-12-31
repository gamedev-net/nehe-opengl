! module aux...
! *DJIP***  I nead it because it is not part of the f90GL project...

Module OpenGL_AUX_T
!
! ** RGB Image Structure
!
type  AUX_RGBImageRec
    integer*4 :: sizeX,  sizeY 
    integer*1, pointer :: datas(:)
end type  AUX_RGBImageRec

end Module OpenGL_AUX_T

Module OpenGL_AUX

!DEC$ objcomment lib:"glaux.lib"

    use dfwin
    Use OpenGL_AUX_T
    Use OpenGL_GL

private  fauxRGBImageLoad
interface
! integer(4) function fauxRGBImageLoad (dummy0)
integer*4 function fauxRGBImageLoad (dummy0)
!DEC$ ATTRIBUTES DEFAULT :: auxRGBImageLoad
! Returns pointer to AUX_RGBImageRec
!DEC$IF DEFINED(_X86_)
!DEC$ ATTRIBUTES STDCALL, REFERENCE, ALIAS : '_auxRGBImageLoadA@4' :: fauxRGBImageLoad
!DEC$ELSE
!DEC$ ATTRIBUTES STDCALL, REFERENCE, ALIAS :  'auxRGBImageLoad'  :: fauxRGBImageLoad
!DEC$ENDIF
character*(*) dummy0
!DEC$ ATTRIBUTES REFERENCE :: dummy0
end function fauxRGBImageLoad
end interface

private  fauxDIBImageLoad
interface
integer(4) function fauxDIBImageLoad (dummy0)
! function fauxDIBImageLoad (dummy0)
!DEC$ ATTRIBUTES DEFAULT :: auxDIBImageLoad
! Returns pointer to AUX_RGBImageRec
! Use OpenGL_GL
! type (glcptr) :: fauxDIBImageLoad
!DEC$IF DEFINED(_X86_)
!DEC$ ATTRIBUTES STDCALL, REFERENCE, ALIAS : '_auxDIBImageLoadA@4' :: fauxDIBImageLoad
!DEC$ELSE
!DEC$ ATTRIBUTES STDCALL, REFERENCE, ALIAS :  'auxDIBImageLoad'  :: fauxDIBImageLoad
!DEC$ENDIF
character*(*) dummy0
!DEC$ ATTRIBUTES REFERENCE :: dummy0
end function fauxDIBImageLoad
end interface


CONTAINS 

function auxRGBImageLoad ( dummy0)
    character*(*) dummy0
    type(AUX_RGBImageRec), pointer :: auxRGBImageLoad
    integer(1),target :: int1(*)
    integer(4) int4
    integer(4) tab
    integer(4) sizeX, sizeY
    integer(4) i,j,k

    POINTER (p1, int4)
    POINTER (p2, int1)

    p1 = fauxRGBImageLoad (dummy0)

    if (p1 == 0) then
        Nullify(auxRGBImageLoad)
        return
    endif

    ALLOCATE(auxRGBImageLoad)  

    auxRGBImageLoad%sizeX = int4
    sizeX = int4
    p1 = p1 + SIZEOF(int4)
    auxRGBImageLoad%sizeY = int4
    sizeY = int4
    p1 = p1  + SIZEOF(int4)
    p2 = int4

     auxRGBImageLoad%datas => int1(1:3*sizeY*sizeX)


end function auxRGBImageLoad

function auxDIBImageLoad ( dummy0)
    character*(*) dummy0
    character*(20) text
    type(AUX_RGBImageRec), pointer :: auxDIBImageLoad
    integer(1),Target :: int1(*)
    integer(4) int4
!    type (glcptr) tab
    integer*4 tab
    integer(4) sizeX, sizeY
    integer(4) i,j,k

    POINTER (p1, int4)
    POINTER (p2, int1)


!    if (tab .eq. glnullptr) then
!        ignor = MessageBox(0, 'impossible de charger l''image.'C, 'Error'C, ior(MB_OK,MB_ICONHAND))  ! MB_ICONERROR=MB_ICONHAND and MB_ICONERROR do not existe in module  "dfwin.mod"
!        call PostQuitMessage(0)     ! This Sends A 'Message' Telling The Program To Quit
!        return                      ! Prevents The Rest Of The Code From Running
!    endif

    p1 = fauxDIBImageLoad (dummy0)

!    p1 = LOC(tab)
!    write(text,*) p1
!    ignor = MessageBox(0, 'impossible '//text//' 'C, 'Error'C, ior(MB_OK,MB_ICONHAND))  ! MB_ICONERROR=MB_ICONHAND and MB_ICONERROR do not existe in module  "dfwin.mod"

    if (p1 == 0) then
        Nullify(auxDIBImageLoad)
        return
    endif

    ALLOCATE(auxDIBImageLoad)

    auxDIBImageLoad%sizeX = int4
    sizeX = int4
    p1 = p1 + SIZEOF(int4)
    auxDIBImageLoad%sizeY = int4
    sizeY = int4
    p1 = p1  + SIZEOF(int4)
    p2 = int4

    auxDIBImageLoad%datas => int1(1:3*sizeY*sizeX)
!    ALLOCATE(auxDIBImageLoad%datas(3*sizeY*sizeX))  
!    do i=1,3*sizeX*sizeY
!        auxDIBImageLoad%datas(i)=int1
!        p2=p2+SIZEOF(int1)
!    enddo

end function auxDIBImageLoad



End Module OpenGL_AUX


