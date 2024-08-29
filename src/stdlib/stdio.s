    .ifndef STDIO_S
STDIO_S = 1

    .include header.s

CR = 13 ; carriage return
LF = 10 ; line feed, aka new line (\n)

    ; A <- gobbledygook
    .macro PRINTC, toPrint
        lda #\toPrint
        jsr printc
    .endm

    ; A <- gobbledygook
    ; R0..1 <- string
    .macro PRINT, string
        lda #<\string
        sta R0
        lda #>\string
        sta R1
        jsr print
    .endm

    ; takes an absolute address to a string, prints it and then prints a carriage return and line feed
    ; A <- gobbledygook
    ; R0..1 <- string
    .macro PRINT_LN, string
        PRINT \string
        PRINT_CRLF
    .endm

    ; A <- gobbledygook
    .macro PRINT_CRLF
        lda #CR
        jsr printc
        lda #LF
        jsr printc
    .endm

; A -> char to write
printc:
    sta UART0_TX
    jsr transmit_delay
    rts

; prints the value in the A register as a 2 digit hex value.
; A -> Value to print
print_hex:
    pha
    phx
    tax
    ; print the most significant digit
    txa
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    ; offset if digit is A-F
    cmp #':'
    bcc notAthroughF$
    clc
    adc #7 ; to get from : char to A char
notAthroughF$
    jsr printc
    ; print the least significant digit
    txa
    and #$0F
    clc
    adc #'0'
    ; offset if digit is A-F
    cmp #':'
    bcc notAthroughF2$
    clc
    adc #7 ; to get from : char to A char
notAthroughF2$
    jsr printc

    plx
    pla
    rts

; R0..1 -> string to write (null terminated, sub 256 len)
print:
    pha
    phy

    ldy #0
loop$
    lda (R0), Y
    beq return$
    jsr printc
    iny
    bra loop$

return$
    ply
    pla
    rts

; R0..1 -> string to write (null terminated, sub 256 len)
println:
    pha
    jsr print
    PRINT_CRLF
    pla
    rts

; A <- char received
readc:
    jsr wait_for_input
    lda UART0_RX
    rts

; Reads a line into the char buffer.
; R0..R1 -> char buffer
; R2 -> char buffer's length
readln:
    pha
    phy
    PUSHR R2
    ; len == 0?
    lda R2
    beq returnNoTerminatingChar$ ; there is no space in the buffer, return without appending string terminator.
    ; len == 1?
    dec R2 ; save 1 character for the string terminator
    beq return$ ; only 1 character fits in the buffer, use it for the string terminator
loop$
    jsr readc ; A <- character
    cmp #LF
    beq return$
    cmp #CR
    beq return$
    cmp #8 ; backspace
    beq backspace$
    sta (R0), Y
    jsr printc ; echo character
    iny
    cmp R2
    beq return$
    bra loop$
backspace$
    cpy #0
    beq loop$ ; dont go back if at beginning of buffer
    dey
    jsr printc ; print the backspace that we read in
    lda #32 ; space
    jsr printc ; clear the character that we backspaced
    lda #8 ; backspace
    jsr printc
    bra loop$
return$
    ; terminate string
    lda #0
    sta (R0), Y
returnNoTerminatingChar$
    ; goto next line
    PRINT_CRLF
    PULLR R2
    ply
    pla
    rts

wait_for_input:
    pha
loop$
    lda UART0_STAT
    and #%00001000
    cmp #%00001000
    bne loop$
    pla
    rts

; TODO: Dont forget to update the delay based on the baud of the uart used
; right now its:
;          baud   10 bits  HZ
; 1042 ~ 1/9600 * 10 * 1,000,000
;        dec   bne
; 5/itr= 2   + 3
; 1050 = 420 + 630
; 210  = 1050/5
transmit_delay:
    pha ; 3 cycles
    lda #210 ; 2
loop$
    dec ; 2 (420 total)
    bne loop$ ; 3 (630 total)
    pla ; 4
    rts ; 6

    .endif