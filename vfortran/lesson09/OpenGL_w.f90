! module w...
! *DJIP***  I ned it because it is not part of the f90GL project...

Module OpenGL_W
!DEC$ objcomment lib:"opengl32.lib"
!DEC$ objcomment lib:"glaux.lib"
!DEC$ objcomment lib:"glu32.lib"
interface !lib=opengl32.lib
integer function wglCreateContext (hDC)
!DEC$ ATTRIBUTES DEFAULT :: fwglCreateContext
!DEC$ IF DEFINED(_X86_)
!DEC$ ATTRIBUTES STDCALL, ALIAS : '_wglCreateContext@4' :: wglCreateContext 
!DEC$ ELSE
!DEC$ ATTRIBUTES STDCALL, ALIAS :  'wglCreateContext'  :: wglCreateContext 
!DEC$ ENDIF
integer hDC
end function wglCreateContext 
end interface

interface !lib=opengl32.lib
logical(4) function wglMakeCurrent (hDC, hGLRC)
!DEC$ ATTRIBUTES DEFAULT :: wglMakeCurrent
!DEC$ IF DEFINED(_X86_)
!DEC$ ATTRIBUTES STDCALL, ALIAS : '_wglMakeCurrent@8' :: wglMakeCurrent 
!DEC$ ELSE
!DEC$ ATTRIBUTES STDCALL, ALIAS :  'wglMakeCurrent'   :: wglMakeCurrent 
!DEC$ ENDIF
integer hGLRC               
integer hDC
end function wglMakeCurrent 
end interface

interface !lib=opengl32.lib
integer function wglDeleteContext (hDC)
!DEC$ ATTRIBUTES DEFAULT :: fwglDeleteContext
!DEC$ IF DEFINED(_X86_)
!DEC$ ATTRIBUTES STDCALL, ALIAS : '_wglDeleteContext@4' :: wglDeleteContext 
!DEC$ ELSE
!DEC$ ATTRIBUTES STDCALL, ALIAS :  'wglDeleteContext'  :: wglDeleteContext 
!DEC$ ENDIF
integer hDC
end function wglDeleteContext 
end interface

End Module OpenGL_W

