;;----------------------------------------------------------------------------------------------------------------------
;; Memory routines
;;----------------------------------------------------------------------------------------------------------------------

memcpy_dma:
                db      %11000011       ; R6: Reset
                db      %11000111       ; R6: Reset Port A timing
                db      %11001011       ; R6: Reset Port B timing

                ; Register 0 set up
                db      %01111101       ; R0: A -> B, transfer mode
mc_dma_src:     dw      0               ; Source address
mc_dma_len:     dw      0               ; Length

                ; Register 1 set up (Port A configuration)
                db      %01010100       ; R1: Port A config: increment, variable timing
                db      2               ; R1: Cycle length port A

                ; Register 2 set up (Port B configuration)
                db      %01010000       ; R2: Port B config: address fixed, variable timing
                db      2

                ; Register 4 set up (Operation mode)
                db      %10101101       ; R4: Continuous mode, set destination address
mc_dma_dest:    dw      0               ; Destination address

                ; Register 5 set up (Some control)
                db      %10000010       ; R5: Stop at end of block; read active low

                ; Register 6 (Commands)
                db      %11001111       ; R6: Load
                db      %10000111       ; R6: Enable DMA


memcpy_len      EQU     $-memcpy_dma

memcpy:
        ; Input:
        ;       HL = source address
        ;       DE = destination address
        ;       BC = number of bytes
        ;
                push    bc
                push    hl
                ld      (mc_dma_src),hl         ; Set up the source address
                ld      (mc_dma_len),bc         ; Set up the length
                ld      (mc_dma_dest),de        ; Set up the destination address

                ld      hl,memcpy_dma
                ld      b,memcpy_len
                ld      c,$6b
                otir                            ; Send DMA program
                pop     hl
                pop     bc
                ret

memfill:
        ; Input:
        ;       HL = source address
        ;       BC = number of bytes
        ;       A = value to fill
        ;
        ; This is equivalent to memcpy(HL,HL+1,BC-1), when we load (HL) with A.
        ;
                push    af
                push    de
                ld      (hl),a
                ld      d,h
                ld      e,l
                inc     de
                dec     bc
                call    memcpy
                inc     bc              ; Restore BC
                pop     de
                pop     af
                ret

;;----------------------------------------------------------------------------------------------------------------------

slow_memfill:
        ; Input:
        ;       HL = source address
        ;       BC = number of bytes
        ;       A = value to fill
        ;
        ; Doesn't use the memcpy(HL,HL+1,BC-1) trick.  This is required for filling memory in L2, since when
        ; you read, you're not reading from L2 but rather from the ROM.
        ;
                push    af
                push    bc
                push    de
                push    hl
                ld      d,a
.l1             ld      (hl),d
                inc     hl
                dec     bc
                ld      a,b
                or      c
                jr      nz,.l1
                pop     hl
                pop     de
                pop     bc
                pop     af
                ret

