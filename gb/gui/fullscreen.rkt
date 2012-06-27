#lang racket/base
(require racket/class
         racket/contract
         racket/gui/base)

(define (make-fullscreen-canvas/ratio LABEL W H ON-PAINT ON-CHAR)
  (define-values (w h) (get-display-size #t))
  (define-values (x y) (get-display-left-top-inset #t))
  
  (define c-scale
    (min (/ w W)
         (/ h H)))
  (define cw (* W c-scale))
  (define ch (* H c-scale))
  (define hm (/ (- w cw) 2))
  (define vm (/ (- h ch) 2))
  
  (define frame 
    (new frame% 
         [label LABEL]
         [x 0] [y (* -1 y)]
         [width w] [height h]
         [style '(hide-menu-bar no-resize-border no-caption no-system-menu)]))
  
  (define vert-pane
    (new vertical-pane%
         [parent frame]
         [min-width w]
         [min-height h]))
  
  (define (make-vertical-border)
    (new canvas%
         [parent vert-pane]
         [min-width w]
         [min-height vm]
         [paint-callback
          (λ (c dc)
            (send dc set-background "black")
            (send dc clear))]))
  
  (define top-border (make-vertical-border))
  
  (define horiz-pane
    (new horizontal-pane%
         [parent vert-pane]
         [min-width w]
         [min-height ch]))
  
  (define (make-horizontal-border)
    (new canvas%
         [parent horiz-pane]
         [min-height ch]
         [min-width hm]
         [paint-callback
          (λ (c dc)
            (send dc set-background "black")
            (send dc clear))]))
  
  (define left-border (make-horizontal-border))
  (define this-canvas%
    (class canvas% 
      (define/override (on-paint)
        (ON-PAINT this))
      (define/override (on-char k)
        (ON-CHAR k))
      
      (super-new)))
  
  (define config
    (new gl-config%))
  (send config set-double-buffered #t)
  
  (define canvas
    (new this-canvas%
         [parent horiz-pane]
         [min-width cw]
         [min-height ch]
         [horiz-margin hm]
         [gl-config config]
         [style '(gl no-autoclear)]))
  (define right-border (make-horizontal-border))
  (define bot-border (make-vertical-border))
  
  (send frame show #t)
  ; XXX Figure out why this doesn't work, meaning why I have to click on the canvas
  ;     before keys will be picked up
  (send canvas focus)
    
  (values frame canvas))

(provide/contract
 [make-fullscreen-canvas/ratio
  (string? integer? integer? 
           ((is-a?/c canvas<%>) . -> . void)
           ((is-a?/c key-event%) . -> . void)
           . -> .
           (values (is-a?/c frame%)
                   (is-a?/c canvas<%>)))])