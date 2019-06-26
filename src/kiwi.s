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

                INCLUDE "src/z80n.s"
                INCLUDE "src/gfx.s"
                INCLUDE "src/memory.s"

KiwiPal:        INCBIN  "data/kiwi.nip",6               ; 9 16-bit colours, followed by transparency index
KiwiGfx:        INCBIN  "data/kiwi.nim",4               ; 16-bit width, height followed by pixels

;;----------------------------------------------------------------------------------------------------------------------
;; Sprite classes

SpriteClasses:  db      1
KiwiSprite:
                dw      KiwiGfx                         ; SPRITES 0 (Idle), 1 (Walk1), 2 (Walk2)

;;----------------------------------------------------------------------------------------------------------------------
;; Sprites

Sprites:        db      1                               ; # of sprites

                dw      0                               ; Sprite type
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

                ; Initialise sprites
                ld      hl,SpriteClasses
                call    LoadSprites

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
