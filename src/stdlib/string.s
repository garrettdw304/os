    .ifndef STRING_S
STRING_S = 1

    .include header.s

; This file handles dealing with strings that are 256 bytes (including null terminator) or less.
; Note: when you see a string being defined as 'null terminated, sub 256 len' that means that the string's buffer must not be more than 256 bytes (so that it includes the string terminator in the first 256 bytes).

; R0..1 -> string 1 pointer
; R2..3 -> string 2 pointer
; A <- 0: equal, non-zero: not equal
; Z <- 0: str1 != str2, 1: str1 == str2
strcmp:
    phy
    ldy #$FF ; load with 0 - 1 to counteract the first increment.
loop$
    iny
    lda (R0), Y
    bne notEndOfStr1$
    lda (R2), Y
    bra return$
notEndOfStr1$
    cmp (R2), Y
    beq loop$

return$
    ply
    cmp #0 ; ply has affected our Z bit, set it based on value of A again
    rts

; R0..1 -> string to be contained in string 2
; R2..3 -> string to contain string 1
; A <- 0: equal, non-zero: not equal
; Z <- 0: str1 != str2, 1: str1 == str2
starts_with:
    phy
    ldy #$FF
loop$
    iny
    lda (R2), Y
    bne notEndOfStr2$
    bra checkStr1$
notEndOfStr2$
    cmp (R0), Y
    beq loop$
checkStr1$
    lda (R0), Y
return$
    ply
    cmp #0
    rts

; Searches a null-terminated-sub-256-len string for the first index containing the character in A.
; R0..1 -> string to search in
; A -> the character to find
; A <- the first index containing the character to find, or gobbledygook if the value was not found.
; V <- 0: the character was found, 1: the character was not found
index_of:
    pha
    phy
    tay ; preserve the value that was in A while we push R2, then move the value into R2
    PUSHR R2
    sty R2

    ; set overflow and don't clear it unless we find the character that we are looking for.
    lda #$7F
    adc #1

    ldy #$FF
loop$
    iny
    lda (R0), Y
    beq return$
    cmp R2
    bne loop$
    clv
return$
    PULLR R2
    ply
    pla
    rts

; R0..1 -> string to get length of (string must be null terminated)
; R0 <- len of string
strlen:
    pha
    phy

    ldy #0
loop$
    lda (R0), Y
    beq break$
    iny
break$
    sty R0

    PULLR R2
    ply
    pla
    rts

; A -> character to be converted from a hex character into its numeric value
; A <- $FF if the character is not a hex character, else the numeric value of the hex character
hexCharToValue:
    cmp #':' ; char directly after 9
    bcc lessOrEqualTo9$
    cmp #'A'
    bcc notHexChar$
    cmp #'G'
    bcc itsAtoF$
    bra notHexChar$
itsAtoF$
    sec
    sbc #('A' - 10)
    rts
lessOrEqualTo9$
    cmp #'0'
    bcc notHexChar$
    sbc #'0'
    rts
notHexChar$
    lda #$FF
    rts
    .endif ; end include guard