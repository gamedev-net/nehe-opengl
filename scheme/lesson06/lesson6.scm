(require
 (lib "gl.ss" "sgl")
 (lib "gl-vectors.ss" "sgl"))


;; Structure to hold a loaded texture image
(define-struct texture (width height data))

;; Load a texture (DrScheme specific)
 (define load-texture
    (lambda (file)
      (let* (
             (bmp  (make-object bitmap% file 'unknown #f))
             (dc (instantiate bitmap-dc% (bmp)))
             (width (send bmp get-width))
             (height (send bmp get-height))
             (pixels (* width height))
             (vec (make-vector (* pixels 3)))
             (data (make-string (* pixels 4)))
             (i 0)
             )
        (send dc get-argb-pixels 0 0 width height data)
        (letrec
            ([loop
              (lambda ()
                (if (< i pixels)
                    (begin
                      (vector-set! vec (* i  3)
                                   (char->integer (string-ref data (+ (* i 4) 1))))
                      (vector-set! vec (+ (* i 3) 1)
                                   (char->integer (string-ref data (+ (* i 4) 2))))
                      (vector-set! vec (+ (* i 3) 2)
                                   (char->integer (string-ref data (+ (* i 4) 3))))
                      (set! i (+ i 1))
                      (loop))))])
          (loop))
        (make-texture width height (vector->gl-ubyte-vector vec)))))

;; This function returns a counter that increments
;; each time it is called. It takes three
;; arguments.  The first is the initial value of
;; the counter, the second is the step, the third
;; is the minimum value, and the last is the
;; maximum value.  If it reaches it's maximum value
;; it wraps around to it's minimum and vice-versa.
;; There is no error checking, so be careful.
(define (counter-generator init step min max)
  (letrec ((value init)
           (loop
            (lambda ()
              (if (or
                   (> value max)
                   (< value min))
                  (begin
                    (cond ((> value max)
                           (set! value (+ min (- value max))))
                          ((< value min)
                           (set! value (+ max (+ value min)))))
                    (loop))
                  value))))
    (lambda ()
      (set! value (+ value step))
      (loop))))

(define xrot (counter-generator 0 0.2 0 360))
(define yrot (counter-generator 0 0.3 0 360))
(define zrot (counter-generator 0 0.4 0 360))

;; A vector to hold texture numbers
(define *texture* (vector->gl-uint-vector (make-vector 1)))

;; Our initialization function
(define gl-init
  (lambda ()
    (let ((texture (load-texture "NeHe.bmp")))
      (glGenTextures 1 *texture*)
      (glBindTexture GL_TEXTURE_2D (gl-uint-vector-ref *texture* 0))
      (glTexImage2D GL_TEXTURE_2D 0 3 (texture-width texture) (texture-height texture)
                    0 GL_RGB GL_UNSIGNED_BYTE (texture-data texture))
      (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR)
      (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER GL_LINEAR))

      (glEnable GL_TEXTURE_2D)
      (glShadeModel GL_SMOOTH)
      (glClearColor 0.0 0.0 0.0 0.5)
      (glClearDepth 1.0)
      (glEnable GL_DEPTH_TEST)
      (glDepthFunc GL_LEQUAL)
      (glHint GL_PERSPECTIVE_CORRECTION_HINT GL_NICEST)))

;; Our main function that does the drawing
(define (gl-draw)
  (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))

  (glLoadIdentity)
  (glTranslatef 0 0 -5)
  (glRotatef (xrot) 1 0 0)
  (glRotatef (yrot) 0 1 0)
  (glRotatef (zrot) 0 0 1)
  (glBindTexture GL_TEXTURE_2D (gl-uint-vector-ref *texture* 0))

  (glBegin GL_QUADS)
  ; front
  (glTexCoord2f 0 0)
  (glVertex3f -1 -1 1)
  (glTexCoord2f 0 1)
  (glVertex3f 1 -1 1)
  (glTexCoord2f 1 1)
  (glVertex3f 1 1 1)
  (glTexCoord2f 1 0)
  (glVertex3f -1 1 1)
  ; back
  (glTexCoord2f 1 0)
  (glVertex3f -1 -1 -1)
  (glTexCoord2f 1 1)
  (glVertex3f 1 -1 -1)
  (glTexCoord2f 0 1)
  (glVertex3f 1 1 -1)
  (glTexCoord2f 0 0)
  (glVertex3f -1 1 -1)
  ; top
  (glTexCoord2f 0 1)
  (glVertex3f -1 1 -1)
  (glTexCoord2f 0 0)
  (glVertex3f 1 1 -1)
  (glTexCoord2f 1 0)
  (glVertex3f 1 1 1)
  (glTexCoord2f 1 1)
  (glVertex3f -1 1 1)
  ; bottom
   (glTexCoord2f 1 1)
  (glVertex3f -1 -1 -1)
  (glTexCoord2f 0 1)
  (glVertex3f -1 -1 1)
  (glTexCoord2f 0 0)
  (glVertex3f 1 -1 1)
  (glTexCoord2f 1 0)
  (glVertex3f 1 -1 -1)
  ; right
  (glTexCoord2f 1 0)
  (glVertex3f 1 -1 -1)
  (glTexCoord2f 1 1)
  (glVertex3f 1 -1 1)
  (glTexCoord2f 0 1)
  (glVertex3f 1 1 1)
  (glTexCoord2f 0 0)
  (glVertex3f 1 1 -1)
  ;left
   (glTexCoord2f 0 0)
  (glVertex3f -1 -1 -1)
  (glTexCoord2f 1 0)
  (glVertex3f -1 1 -1)
  (glTexCoord2f 1 1)
  (glVertex3f -1 1 1)
  (glTexCoord2f 0 1)
  (glVertex3f -1 -1 1)

  (glEnd)
  (glFlush))

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
  (gluPerspective 45.0 (/ width height) 0.1 100)

  (glMatrixMode GL_MODELVIEW)
  (glLoadIdentity))

; The key handeling function
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

;; Make a 640 x 480 frame
(define frame
  (instantiate frame% ()
    (label "NeHe's OpenGL Tutorial #6 - ported by BBurns")
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
