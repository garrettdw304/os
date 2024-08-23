    .ifndef HEAP_MANAGER_S
HEAP_MANAGER_S = 1

    .include header.s

; mcb
; {
;     word size // the number of usable bytes in this block (not including the bytes of this struct)
;     word next // a pointer to the first byte of the next mcb struct
;     word prev // a pointer to the first byte of the previous mcb struct
;     byte allocated // 0 if this block is free, otherwise allocated
; }

HEAP_START = $1300 ; space for zero page, kernel stack (page 1), kernel pcb tables (page 2) and 16 pages for pcb stackpages.
HEAP_END = $7FFF ; the last address managed by the heap manager
HEAP_SIZE = HEAP_END - HEAP_START + 1 ; num of bytes managed by the heap (27904)

MCB_SIZE = 7 ; size, next, prev, allocated
MCB_SIZE_OFFSET = 0
MCB_NEXT_OFFSET = 2
MCB_PREV_OFFSET = 4
MCB_ALLOCATED_OFFSET = 6

; -----init_heap()-------------------------------------------------
; Initializes the first mcb of the heap.
init_heap:
    pha

    ; Store the size of the first mcb
    lda #<HEAP_SIZE
    sta HEAP_START + MCB_SIZE_OFFSET
    lda #>HEAP_SIZE
    sta HEAP_START + MCB_SIZE_OFFSET + 1
    ; store next
    stz HEAP_START + MCB_NEXT_OFFSET
    stz HEAP_START + MCB_NEXT_OFFSET + 1
    ; store prev
    stz HEAP_START + MCB_PREV_OFFSET
    stz HEAP_START + MCB_PREV_OFFSET + 1
    ; store allocated
    stz HEAP_START + MCB_ALLOCATED_OFFSET

    pla
    rts
; -----------------------------------------------------------------

; -----word kalloc_mem(word size)-----------------------------
; size - The number of bytes to allocate. Stored in R0..1.
; Returns the address of the first allocated byte or 0 if no space could be allocated
; returned in R0..R1
kalloc_mem:
    ; dont want to be interrupted while modifying the heap.
    php
    sei
    pha
    phx
    phy
    ; push R2..3 for current ('cur') mcb
    PUSHR R2
    PUSHR R3
    ; push R4..5 for a 16-bit scratch register
    PUSHR R4
    PUSHR R5

    ; load the first mcb ptr into R2..3
    LOADR R2, #<HEAP_START
    LOADR R3, #>HEAP_START
    ; start the loop, dont load next mcb ptr on the first interation
    bra notNull$
; ----- LOOP -----
    ; while (cur != NULL)
while$
    ; cur = cur->next
    ldy #MCB_NEXT_OFFSET
    lda (R2), Y
    tax ; x holds R2's future value
    iny
    lda (R2), Y ; a holds R3's future value
    stx R2
    sta R3
    ; cur != NULL
    lda #0
    cmp R2
    bne notNull$
    cmp R3
    beq fail$
notNull$
    ; cur->allocated == false
    ldy #MCB_ALLOCATED_OFFSET
    lda (R2), Y ; load cur->allocated
    cmp #0
    bne while$ ; next interation because this block is allocated
    ; cur->size >= size
    ; check most significant bytes first
    ldy #MCB_SIZE_OFFSET+1
    lda (R2), Y ; cur->size
    cmp R1 ; size
    bcc while$ ; cur->size < size
    bne break$ ; if lhs.hi >= rhs.hi && lhs.hi != rhs.hi -> lhs > rhs
    ; they are equal. now check the least significant bytes
    lda (R2) ; cur->size
    cmp R0 ; size
    bcc while$ ; cur->size < size

    bra break$
break$
; ----- END LOOP -----
    ; cur->allocated = true
    ldy #MCB_ALLOCATED_OFFSET
    lda #1
    sta (R2), Y
    ; Check if we need to split this block using: cur->size >= size + sizeof(mcb))
    ; R4..5 = size(R0..1) + MCB_SIZE(7)
    clc
    lda R0
    adc #MCB_SIZE
    sta R4
    lda R1
    adc #0 ; add Carry to >size
    sta R5
    ;  (R2..3)        R4..5
    ; cur->size >= size + sizeof(mcb))
    ldy #1
    lda (R2), Y
    cmp R4, Y
    bcc skipSplit$ ; if lhs.hi < rhs.hi -> lhs < rhs
    bne doSplit$ ; if lhs.hi >= rhs.hi && lhs.hi != rhs.hi -> lhs > rhs
    ; they are equal. now check the least significant bytes
    lda (R2)
    cmp R4
    bcc skipSplit$
doSplit$
    jsr split_mcb
skipSplit$
    ; add MCB_SIZE to cur and return it as the address of the first byte of usable memory
    LOADR R0, R2
    LOADR R1, R3
    clc
    lda R0
    adc #MCB_SIZE
    sta R0
    lda R1
    adc #0 ; add Carry
    sta R1
    bra success$
fail$
    ; return null
    stz R0
    stz R1

success$
    PULLR R5
    PULLR R4
    PULLR R3
    PULLR R2
    ply
    plx
    pla
    rti ; pull processor flags register while returning
; -----END kalloc_mem-----------------------------------------

; -----split_mcb---------------------------------------------------
; params:
; R0..1: the size that mcb should be. NewMcb->size will be mcb->size - size - MCB_SIZE.
; R2..3: mcb*. A pointer to the mcb that we want to split.
; returns:
; R0..1: a pointer to mcb->next. Not expected to be needed by the caller,
;        I just dont want to preserve these registers because size is not needed by kalloc_mem() after a call to this function.
; R4..5: a pointer to newMcb.
; #NOTE: Does not preserve A, X or Y registers. Mainly for use in kalloc_mem().
split_mcb:
    ; Split the unrequested bytes off of the end of cur
    ;      (R4..5)= R0..1(16) + R2..3(16) + 8-bitConst
    ; mcb* newMcb = (mcb*)(size + cur + MCB_SIZE); // newMcb = (R4..5)
    ; handle size + cur first
    clc
    lda R0
    adc R2
    sta R4
    lda R1
    adc R3
    sta R5
    ; add MCB_SIZE
    clc
    lda R4
    adc #MCB_SIZE
    sta R4
    lda R5
    adc #0 ; add Carry
    sta R5
    ; now (R4..5) is newMcb
    ; newMcb->size = cur->size - size
    sec
    ldy #MCB_SIZE_OFFSET
    lda (R2), Y
    sbc R0
    sta (R4), Y
    iny
    lda (R2), Y
    sbc R1
    sta (R4), Y
    ; newMcb->size -= sizeof(mcb)
    sec
    ldy #MCB_SIZE_OFFSET
    lda (R4), Y
    sbc #MCB_SIZE
    sta (R4), Y
    iny
    lda (R4), Y
    sbc #0 ; subtract the carry
    sta (R4), Y
    ; cur->size = size
    lda R0
    ldy #MCB_SIZE_OFFSET
    sta (R2), Y
    lda R1
    iny
    sta (R2), Y
    ; now size(R0..R1) is no longer needed.
    ; newMcb->next = cur->next
    ldy #MCB_NEXT_OFFSET
    lda (R2), Y
    sta (R4), Y
    iny
    lda (R2), Y
    sta (R4), Y
    ; is cur->next null?
    ldy #MCB_NEXT_OFFSET
    lda (R2), Y
    bne nextNotNull$
    iny
    lda (R2), Y
    beq nextIsNull$
nextNotNull$
    ; move cur->next into R0..1 so that we can indaddr into it
    ldy #MCB_NEXT_OFFSET
    lda (R2), Y
    sta R0
    iny
    lda (R2), Y
    sta R1
    ; cur->next->prev = newMcb
    ldy #MCB_PREV_OFFSET
    lda R4
    sta (R0), Y
    iny
    lda R5
    sta (R0), Y
nextIsNull$
    ; cur->next = newMcb
    ldy #MCB_NEXT_OFFSET
    lda R4
    sta (R2), Y
    iny
    lda R5
    sta (R2), Y
    ; newMcb->allocated = false
    ldy #MCB_ALLOCATED_OFFSET
    lda #0
    sta (R4), Y
    ; newMcb->prev = cur
    ldy #MCB_PREV_OFFSET
    lda R2
    sta (R4), Y
    iny
    lda R3
    sta (R4), Y

    rts
; -----End split_mcb-----------------------------------------------

    .endif ; end include guard