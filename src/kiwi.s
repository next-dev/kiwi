;;----------------------------------------------------------------------------------------------------------------------
;; Kiwi animation demo
;;----------------------------------------------------------------------------------------------------------------------

                DEVICE  ZXSPECTRUMNEXT
                CSPECTMAP "kiwi.map"

;;----------------------------------------------------------------------------------------------------------------------
;; Keyboard system

                INCLUDE "src/keyboard.s"

;;----------------------------------------------------------------------------------------------------------------------
;; Graphics system

                INCLUDE "src/gfx.s"
                INCLUDE "src/memory.s"

KiwiPal:        INCBIN  "data/kiwi.nip",6               ; 9 16-bit colours, followed by transparency index
KiwiGfx:        INCBIN  "data/kiwi.nim",4               ; 16-bit width, height followed by pixels

KiwiSprite:
                dw      KiwiGfx                         ; Graphics data
                db      4                               ; Number of frames
                db      24                              ; Height of each frame

                db      0                               ; Frame # of idle
                db      1,2,1,3                         ; Frames of walk cycle

Sprites:        db      1                               ; # of sprites

                dw      KiwiSprite                      ; Sprite type
                db      0, 0, 0                         ; Animation, Frame #, mirror X


;;----------------------------------------------------------------------------------------------------------------------
;; Main loop

Init:
                ; Initialise keyboard and interrupts
                call    InitKeys

                ; Initialise sprite and L2 palettes
                ld      hl,KiwiPal
                ld      d,PALETTEEDIT_Sprites0
                ld      e,0
                call    LoadPalette

                ld      hl,KiwiPal
                ld      d,PALETTEEDIT_Layer20
                ld      e,0
                call    LoadPalette

                ; Initialise L2
                call    InitL2

                ret

Start:
                call    Init



.loop:          ld      a,(KFlags)
                bit     0,a
                jr      nz,.no_keys

                ; Key has been pressed
                ld      a,(Key)
                cp      'O'
                call    z,GoLeft
                cp      'P'
                call    z,GoRight

                ; Consume key and loop
                ld      hl,KFlags
                res     0,(hl)                  ; Signal that we can fetch another key

                ;
.no_keys        ld      hl,KFlags
                bit     1,(hl)                  ; Did we start a new frame?
                jr      z,.loop                 ; No, keep looping

.animate        ld      ix,Sprites
                call    UpdateSprites
                jr      .loop


;;----------------------------------------------------------------------------------------------------------------------
;; Controls

GoLeft:         ret
GoRight:        ret

;;----------------------------------------------------------------------------------------------------------------------
;; NEX generation

                SAVENEX OPEN "kiwi.nex", Start, $c000
                SAVENEX CORE 2, 0, 0
                SAVENEX CFG 0, 0, 0, 0
                SAVENEX AUTO

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
