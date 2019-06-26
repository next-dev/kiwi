;;----------------------------------------------------------------------------------------------------------------------
;; Z80 and Next macros and registers
;;----------------------------------------------------------------------------------------------------------------------

;;----------------------------------------------------------------------------------------------------------------------
;; Pseudo-instructions

; Acts like: LD HL,(HL)
;
ldhl            macro
                ld      a,(hl)
                inc     hl
                ld      h,(hl)
                ld      l,a
                endm

bchilo          macro   hi, lo
                ld      bc,(hi * 16) + lo
                endm

dehilo          macro   hi, lo
                ld      de,(hi * 16) + lo
                endm

hlhilo          macro   hi, lo
                ld      hl,(hi * 16) + lo
                endm

;;----------------------------------------------------------------------------------------------------------------------
;; I/O Ports


; Communication and memory
IO_I2C_CLOCK    equ     $103b
IO_I2C_DATA     equ     $113b
IO_UART_TX      equ     $133b
IO_UART_RX      equ     $143b
IO_DMA          equ     $6b

; Paging
IO_PLUS3_PAGE   equ     $1ffd
IO_128K_PAGE    equ     $7ffd
IO_NEXT_PAGE    equ     $dffd

; Next registers
IO_REG_SELECT   equ     $243b
IO_REF_ACCESS   equ     $253b

; Graphics
IO_LAYER2       equ     $123b
IO_SPRITE       equ     $303b
IO_SPRITE_ATTR  equ     $57
IO_SPRITE_PATT  equ     $5b
IO_ULA          equ     $fe
IO_TIMEX        equ     $ff

; Audio
IO_AUDIO        equ     $bffd
IO_TURBO_SOUND  equ     $fffd
IO_SPECDRUM     equ     $df

; Input
IO_KEYBOARD     equ     $fe
IO_MOUSE_BTNS   equ     $fadf
IO_MOUSE_X      equ     $fbdf
IO_MOUSE_Y      equ     $ffdf
IO_JOY0         equ     $1f
IO_JOY1         equ     $37

;;----------------------------------------------------------------------------------------------------------------------
;; Next registers

NR_MACHINE_ID   equ     $00
NR_VERSION      equ     $01
NR_RESET        equ     $02
NR_MACHINE_TYPE equ     $03
NR_ROM_MAP      equ     $04
NR_PERIPH_1     equ     $05
NR_PERIPH_2     equ     $06
NR_CLOCK_SPEED  equ     $07
NR_PERIPH_3     equ     $08
NR_PERIPH_4     equ     $09
NR_VERSION_2    equ     $0e
NR_ANTI_BRICK   equ     $10
NR_VIDEO_TIME   equ     $11
NR_L2_PAGE      equ     $12
NR_L2S_PAGE     equ     $13
NR_TRANSP       equ     $14
NR_SPRITE_CTRL  equ     $15
NR_L2_X         equ     $16
NR_L2_Y         equ     $17
NR_CLIP_L2      equ     $18
NR_CLIP_SPRITES equ     $19
NR_CLIP_ULA     equ     $1a
NR_CLIP_TILEMAP equ     $1b
NR_CLIP_CTRL    equ     $1c
NR_RASTER_MSB   equ     $1e
NR_RASTER_LSB   equ     $1f
NR_RASTER_INTC  equ     $22
NR_RASTER_INTV  equ     $23
NR_KEYMAP_ADDRH equ     $2a
NR_KEYMAP_ADDRL equ     $2b
NR_KEYMAP_DATAH equ     $2c
NR_KEYMAP_DATAL equ     $2d
NR_TMAP_XMSB    equ     $2f
NR_TMAP_XLSB    equ     $30
NR_TMAP_Y       equ     $31
NR_ULA_X        equ     $32
NR_ULA_Y        equ     $33
NR_SPRITE_IDX   equ     $34
NR_SPRITE_0     equ     $35
NR_SPRITE_1     equ     $36
NR_SPRITE_2     equ     $37
NR_SPRITE_3     equ     $38
NR_SPRITE_4     equ     $39
NR_PALETTE_IDX  equ     $40
NR_PALETTE_VAL  equ     $41
NR_EULA_INKMASK equ     $42
NR_EULA_CTRL    equ     $43
NR_EULA_PAL     equ     $44
NR_TRANSPARENT  equ     $4a
NR_SPRITE_TRANS equ     $4b
NR_TMAP_TRANS   equ     $4c
NR_MMU0         equ     $50
NR_MMU1         equ     $51
NR_MMU2         equ     $52
NR_MMU3         equ     $53
NR_MMU4         equ     $54
NR_MMU5         equ     $55
NR_MMU6         equ     $56
NR_MMU7         equ     $57
NR_COPPER       equ     $60
NR_COPPER_CTRLL equ     $61
NR_COPPER_CTRLH equ     $62
NR_ULA_CTRL     equ     $68
NR_TMAP_CTRL    equ     $6b
NR_TMAP_DEFATTR equ     $6c
NR_TMAP_BASE    equ     $6f
NR_SPRITE_0_INC equ     $75
NR_SPRITE_1_INC equ     $76
NR_SPRITE_2_INC equ     $77
NR_SPRITE_3_INC equ     $78
NR_SPRITE_4_INC equ     $79
NR_LED          equ     $ff

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
