;;----------------------------------------------------------------------------------------------------------------------
;; Graphics library
;;----------------------------------------------------------------------------------------------------------------------

SPRITECLASS_Nim                 equ     0
SPRITECLASS_NumFrames           equ     2
SPRITECLASS_HeightFrame         equ     3

SPRITE_Class                    equ     0
SPRITE_Animation                equ     2
SPRITE_FrameNum                 equ     3
SPRITE_Mirror                   equ     4

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
;; Palette routines
;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------

PALETTESELECT_Sprite0           equ     %00000000
PALETTESELECT_Sprite1           equ     %00001000
PALETTESELECT_Layer20           equ     %00000000
PALETTESELECT_Layer21           equ     %00000100
PALETTESELECT_ULA0              equ     %00000000
PALETTESELECT_ULA1              equ     %00000010

PALETTEEDIT_ULA0                equ     %00000000
PALETTEEDIT_ULA1                equ     %01000000
PALETTEEDIT_Layer20             equ     %00010000
PALETTEEDIT_Layer21             equ     %01010000
PALETTEEDIT_Sprites0            equ     %00100000
PALETTEEDIT_Sprites1            equ     %01100000
PALETTEEDIT_Tilemap0            equ     %00110000
PALETTEEDIT_Tilemap1            equ     %01110000

LastPaletteSelect       db      %00000000

SelectPalette:
        ; Input:
        ;       A = palette (one of the PALETTESELECT_??? values)
        ; Output:
        ;       A = Contents of Next register $43 (ENHANCED ULA CONTROL REGISTER)

                push    de
                ld      d,a
                ld      a,(LastPaletteSelect)
                and     %11110001
                or      d
                nextreg $43,a
                ld      (LastPaletteSelect),a
                pop     de
                ret

LoadPalette:
        ; Input:
        ;       HL = start of NIP file after header
        ;       D = Palette selection (one of the PALETTEEDIT_??? values)
        ;       E = Start index
        ; Output:
        ;       HL = byte after palette in NIP file
        ;       A = transparent index
        ; Used:
        ;       BC, DE, A
        ;

                ; Set the palette to edit
                ld      a,(LastPaletteSelect)
                and     %10001111
                or      d
                nextreg $43,a
                ld      (LastPaletteSelect),a
                ld      a,e
                nextreg $40,a

                ld      b,(hl)          ; B = number of colours
                inc     hl

                ; Test for 9-bit or 8-bit palette loading
                bit     0,(hl)          ; Are we 9-bit?
                jr      z,.bits8

                ; 9-bit loading
                inc     hl
.l1             ld      a,(hl)
                nextreg $44,a
                inc     hl
                ld      a,(hl)
                nextreg $44,a
                inc     hl
                djnz    .l1
                jr      .end

                ; 8-bit loading
.bits8          inc     hl
.l2             ld      a,(hl)
                nextreg $41,a
                inc     hl
                djnz    .l2

.end            ld      a,(hl)
                inc     hl
                ret

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
;; Layer 2 Routines
;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------

InitL2:
                di
                nextreg $12,8           ; Set first page of L2 to page 16 (16-21)
                nextreg $13,11          ; Set first page of Shadow L2 to page 22 (22-27)

                ld      bc,0
                ld      de,$00c0
                xor     a
                call    L2_DrawRect

                ; Show the final image
                ld      bc,$123b
                ld      a,%00000010
                out     (c),a
                nextreg $50,$ff
                nextreg $51,$ff

                ei
                ret

L2_BASEPAGE     equ     16
L2_LASTPAGE     equ     L2_BASEPAGE+6
L2Page          db      0

CalcL2Address: 
                ; Input:
                ;       BC = XY
                ; Output:
                ;       HL = address in MMU0/1 and L2 area paged in (or YX in third)
                ; Uses:
                ;       A = Y coord in 3rd
                ;       BC = $123b
                ; Destroys:
                ;       A, BC
                ;

                ld      h,c                     ; H = Y coord
                ld      l,b                     ; L = X coord

                ; Bring in the correct L2 pages into MMU0/1
                ld      a,c
                and     $c0                     ; Mask off the page index (PP000000)
                swapnib                         ; 0000PP00
                srl     a                       ; 00000PP0
                add     a,L2_BASEPAGE           ; Add base page
                nextreg $50,a
                inc     a
                nextreg $51,a
                inc     a
                ld      (L2Page),a

                ld      a,h
                and     $3f
                ld      h,a                     ; HL = address

                ret

L2_DrawRect:
                ; Input:
                ;       BC = XY
                ;       DE = WH
                ;       A = palette index for fill
                ; Destroys:
                ;       A, BC, DE, HL
                ;

                push    af
                call    CalcL2Address           ; Page in correct L2 page and set HL to start address

                ld      c,d
                ld      b,0                     ; BC = # bytes
                ld      a,d                     ; A = width
                and     a                       ; Equal to 0?  (this means 256 really)
                jr      nz,.not256
                inc     b                       ; BC = 256 bytes
.not256         pop     af                      ; Restore colour
                ld      d,a                     ; D = colour

.line           
                call    memfill                 ; Fill in the bytes


                inc     h                       ; Go to next L2 line
                ld      a,h
                and     $c0                     ; Did we overrun?
                jr      z,.no_overrun           ; No, skip

                ld      a,(L2Page)              ; A = next L2 page
                cp      L2_LASTPAGE
                jr      z,.end

                nextreg $50,a
                inc     a
                nextreg $51,a
                inc     a
                ld      (L2Page),a
                ld      h,0                     ; Reset HL back to 0

.no_overrun     ld      a,d                     ; Restore fill value
                dec     e
                jr      nz,.line                ; More lines?  Then keep going?

.end            ret


;;----------------------------------------------------------------------------------------------------------------------
;; UpdateSprites
;; This will run through the sprite table and update state

UpdateSprites:
                ret