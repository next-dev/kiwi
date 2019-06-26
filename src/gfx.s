;;----------------------------------------------------------------------------------------------------------------------
;; Graphics library
;;----------------------------------------------------------------------------------------------------------------------

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
                nextreg NR_EULA_CTRL,a
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
                nextreg NR_EULA_CTRL,a
                ld      (LastPaletteSelect),a
                ld      a,e
                nextreg NR_PALETTE_IDX,a

                ld      b,(hl)          ; B = number of colours
                inc     hl

                ; Test for 9-bit or 8-bit palette loading
                bit     0,(hl)          ; Are we 9-bit?
                jr      z,.bits8

                ; 9-bit loading
                inc     hl
.l1             ld      a,(hl)
                nextreg NR_EULA_PAL,a
                inc     hl
                ld      a,(hl)
                nextreg NR_EULA_PAL,a
                inc     hl
                djnz    .l1
                jr      .end

                ; 8-bit loading
.bits8          inc     hl
.l2             ld      a,(hl)
                nextreg NR_PALETTE_VAL,a
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
                nextreg NR_L2_PAGE,8    ; Set first page of L2 to page 16 (16-21)
                nextreg NR_L2S_PAGE,11  ; Set first page of Shadow L2 to page 22 (22-27)

                ld      bc,0
                ld      de,$00c0
                xor     a
                call    L2_DrawRect

                ; Show the final image
                ld      bc,IO_LAYER2
                ld      a,%00000010
                out     (c),a
                nextreg NR_MMU0,$ff
                nextreg NR_MMU1,$ff

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
                nextreg NR_MMU0,a
                inc     a
                nextreg NR_MMU1,a
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

                nextreg NR_MMU0,a
                inc     a
                nextreg NR_MMU1,a
                inc     a
                ld      (L2Page),a
                ld      h,0                     ; Reset HL back to 0

.no_overrun     ld      a,d                     ; Restore fill value
                dec     e
                jr      nz,.line                ; More lines?  Then keep going?

.end            ret


;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
;; SPRITE ROUTINES
;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------

;;----------------------------------------------------------------------------------------------------------------------
;; LoadSprites
;; Loads the sprite patterns for 16x24 sprites placed vertically in a nim

SpriteNum       db      0

LoadSprites:
        ; Input
        ;       HL = Sprite class table
        ;               Offset  Size    Description
        ;               0       1       Number of patters
        ;
                ld      b,(ix+0)                ; B = number of images
                xor     a
                ld      (SpriteNum),a           ; Sprite number

.sprite         push    bc

                push    hl
                ldhl                            ; HL = sprite data
                inc     hl
                inc     hl
                ld      e,(hl)                  ; C = height
                inc     hl
                inc     hl                      ; HL = pixel data

                ; Choose the sprite pattern index
.next           ld      a,(SpriteNum)
                ld      bc,IO_SPRITE
                out     (c),a
                inc     a
                ld      (SpriteNum),a

                ; Write the sprite pattern
                bchilo  $80,IO_SPRITE_PATT      ; B = number of bytes to upload, C = upload port
                otir                            ; Upload first 16 rows
                ld      b,$40                   ; Upload next 8 rows
                otir
                ld      b,$40
                xor     a
.l1             out     (c),a
                djnz    .l1                     ; Fill the rest of the sprite with transparent colour

                ld      a,e
                sub     24
                ld      e,a
                jr      nz,.next

                pop     hl                      ; Restore pointer to sprite table
                inc     hl
                inc     hl                      ; Next pointer
                pop     bc
                djnz    .sprite                 ; Next sprite graphic

                ret



;;----------------------------------------------------------------------------------------------------------------------
;; UpdateSprites
;; This will run through the sprite table and update state

UpdateSprites:
        ; Input:
        ;       IX = List of sprite data in the form of:
        ;               Offset  Size    Description
        ;               0       1       Number of sprites
        ;               1       5*N     Sprite info
        ;       Where sprite info is:
        ;               Offset  Size    Description
        ;               0       2       Address of sprite class data
        ;               2       1       Animation index
        ;               3       1       Frame # within animaton
        ;               4       1       Mirror in X direction
                ret