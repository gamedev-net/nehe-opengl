;; PLT Scheme version of NeHe's tutorial #2
;;
;; Written and tested with WinXP Pro + DrScheme 205 + sgl 
;; if you test this under any *nix (including FreeBSD or
;; any other non-linix *nix) please write me at bcj1980 at
;; sbcglobal dot net and tell me about the results.
;;
;; Disclaimer: 
;; I am not only a non "guru" programmer, I'm
;; new to scheme, OpenGL, and MrEd.  Thankfully, I have
;; many years experience with 3d algorithims, so it comes
;; fairly easily to me, but don't be intimitaded by my 
;; coding style.  This tutorial was ported under the 
;; assumption that you know C, and are following along
;; with NeHe's commented code and not just relying on
;; mine.  Also, I don't attempt to explain the majority 
;; of the scheme-centric code and I assume you are
;; fairly comfortable with scheme by now if you are
;; trying out OpenGL bindings.  Also, I explicitly 
;; disclaim any responsibility for firey explosions/
;; monitor death/melting video cards, or anything else 
;; unpleaseant that may happen to you, your hardware,
;; or your software as a result of you using my code. 

(require (lib "gl.ss" "sgl")
         (lib "gl-vectors.ss" "sgl")
         (lib "math.ss" "mzlib"))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper functions

;; This is a kludge for lack of GLU support in SGL.
;; I choose to keep the name in case SGL gets GLU
;; support later.  You probably shouldn't try to 
;; understand this yet unless you're masochistic or
;; want an explosive brain hemorrhage. There is no
;; error checking, so be careful.

(define (gluPerspective fovy aspect znear zfar)
  (let ((f (/ 1 (tan (/ (* fovy (/ pi 180)) 2))))
        (g (- znear zfar)))
    (glMultMatrixd
     (vector->gl-double-vector 
      (vector
       (/ f aspect) 0 0 0
       0 f 0 0
       0 0 (/ (+ znear zfar) g) -1
       0 0 (/ (* 2 znear zfar) g) 0)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Our main function that does the drawing


(define (gl-draw)
  (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))
  
  ;;----------------------------------------------;;
  ;; Now comes the fun part: Drawing!!!!
  
  (glLoadIdentity)
  (glTranslatef -1.5 0 -6)
  
  (glBegin GL_TRIANGLES)
  
  (glVertex3f 0 1 0)
  (glVertex3f -1 -1 0)
  (glVertex3f 1 -1 0)
     
  (glEnd)
  
  (glTranslatef 3 0 0)
   
  (glBegin GL_QUADS)
  
  (glVertex3f -1 1 0)
  (glVertex3f 1 1 0)
  (glVertex3f 1 -1 0)
  (glVertex3f -1 -1 0)
  
  (glEnd)
  
  (glFlush))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Drawing, resizing, key handling 
;; and initilization functions


;; This function calls gl-init once and then sets itself to call gl-draw
(define (gl-thunk)
  (if (send glcontext ok?)
      (begin
        (send glcanvas with-gl-context gl-init)
        (send glcanvas with-gl-context gl-draw)
        (send glcanvas swap-gl-buffers)
        (set! gl-thunk 
              (lambda ()
                (send glcanvas with-gl-context gl-draw)
                (send glcanvas swap-gl-buffers))))
      (begin 
        (display "Error: OpenGL context failed to initialize")
        (newline)
        (exit))))


;; A function that recorrects for a new aspect ratio when the window is resized
(define (gl-resize width height)
  (glViewport 0 0 width height)
  
  (glMatrixMode GL_PROJECTION)
  (glLoadIdentity)
  (gluPerspective 45 (/ width height) 0.1 100)
  
  (glMatrixMode GL_MODELVIEW)
  (glLoadIdentity))


;; A function to initialize the OpenGL state
(define (gl-init)
  (glShadeModel GL_SMOOTH)
  (glClearColor 0 0 0 0.5)
  (glClearDepth 1)
  (glEnable GL_DEPTH_TEST)
  (glDepthFunc GL_LEQUAL)
  (glHint GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST))

;; The key handeling function
(define (gl-handlekey key)
  (let ((k (send key get-key-code)))
        (cond ((eq? k 'escape) (exit))
              ((eq? k 'f1) 
               ;This is FAT kludge if ever there was one.
               ;MrEd strangly dosn't seem to include a function
               ;to determine whether a frame is maximized or not,
               ;so we have to manually check
               (let ((x (send frame get-width))
                     (y (send frame get-height)))
                 (send frame maximize #t)
                 (if (and (= (send frame get-width) x)
                          (= (send frame get-height) y))
                     (send frame maximize #f)))))))
                          

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Windowing setup

;; Make a 640 × 480 frame
(define frame 
  (instantiate frame% () 
    (label "NeHe's OpenGL Tutorial #2 - ported by Bandit Cat") 
    (width 640) 
    (height 480)))

(define glcanvas%
  (class canvas%
    (override on-paint on-size on-superwindow-show on-char)
    (define (on-paint) (gl-thunk))
    
    (define (on-size w h)
      (send this with-gl-context 
            (lambda () 
              (gl-resize w h))))
    
    (define (on-superwindow-show shown)
      (if shown
          (void)
          (set! gl-loop (lambda () #t))))
    
    (define (on-char key) (gl-handlekey key))
    
    (super-instantiate ())))


;; These commands name the canvas and context for ease of use
(define glcanvas (instantiate glcanvas% (frame)))
(define glcontext (send (send glcanvas get-dc) get-gl-context))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The loop

;; This is the loop that does the majority of the drawing
(define (gl-loop) 
  (if (send glcanvas is-shown?)
      (begin
        (yield)
        (gl-thunk)
        (gl-loop))))

;; Show the frame
(send frame show #t) 

;; Wait for the ok sign and then enter the loop.
(letrec ((wait (lambda () (if (send glcontext ok?) (void) (wait))))) (wait)) 
(gl-loop)