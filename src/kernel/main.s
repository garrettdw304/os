    .org $E000 ; because our rom starts at address $E000
WHOLE_BUILD = 1 ; will tell .s files if they are allowed to include nmi, irq rst and .org directives (so that they can test themselves when not being used to compile the OS)

; TODO see .binary for alternate ways of including code (also see: .incbin, .incdir)
    .incdir ../stdlib
    .incdir ../user
    .include header.s
    .include io_scheduler.s
    .include memory_map.s
    .include heap_manager.s
    .include process_scheduler.s
    .include stdio.s
    .include monitor.s
    .include shell.s
    .include string.s
    .include sys_call.s

rst:
    ; pause interrupts
    sei

    ; initialize stack
    lda #1
    sta STK_PG_CTRL_REG
    ldx #$FF
    txs

    ; initialize the heap
    jsr init_heap

    ; TODO: initialize devices (VIA, UART)

    ; Begin scheduling and hand over the CPU to the first process
    jsr begin_scheduling
    
    ; TODO: shutdown sequence (maybe disable interrupts and start flashing an led? maybe pulse reset (cant just call reset routine, or other devices would not get the signal)? or just call stp?)
    lda #69
    stp
loop$
    stp
    bra loop$

irq:
    pha

    ; TODO: Handle all os managed interrupts then if none of those devices caused the interrupt, try running through the drivers.

    lda SIMPLE_TIMER_BASE_REG ; load interrupting reg
    cmp #0
    beq timeQNotOver$
    lda #SYS_YIELD
    jsr sys_call
timeQNotOver$

    pla
    rti

nmi:
    rti

    .org $fffa
    .word nmi	; Non-maskable interrupt vector
    .word rst	; Reset interrupt vector
    .word irq	; Interrupt request vector