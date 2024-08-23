    .include SYS_CALL_S
SYS_CALL_S = 1

; This file is the interface between kernel and user space.
; No user space applications are technically allowed to directly call
; any kernel space functions other than ones in this file.

SYS_EXIT = 0
SYS_YIELD = 1

; TODO: Make sys_call take in a pointer to a struct of arguments

; TODO: Move the process scheduling part of sys_call into a new function
; that will be in process_scheduler.s.
; ----------------------
; A -> operation. A SYS_# enum.
; ----------------------
sys_call:
    php
    sei
    ; Push the current context onto the stack.
    pha
    phx
    phy
    tay ; operation will be in y
    PUSHR R0
    PUSHR R1
    PUSHR R2
    PUSHR R3
    PUSHR R4
    PUSHR R5
    PUSHR R6
    PUSHR R7
    PUSHR R8
    PUSHR R9
    PUSHR RA
    PUSHR RB
    PUSHR RC
    PUSHR RD
    PUSHR RE
    PUSHR RF
    
    ; check if this is global context, if so, preserve global context stack pointer. if not, continue as normal.
    lda RUNNING_PCB
    cmp #PCB_MAX_COUNT
    bcc notGlobal$ ; branch if less than
    tsx ; store the global context's stack pointer
    stx GLOBAL_CONTEXT_SP
    bra selNextProc$
notGlobal$

    ; Store sp into RUNNING->sp
    tsx
    txa
    ldx RUNNING_PCB ; x will contain our pcb index for indexing into the pcb tables
    sta PCB_SP_TABLE, X

    ; set RUNNING->exeState accordingly
    cpy #SYS_YIELD
    beq yielding$
    ; if we make it here, either op was SYS_EXIT or it was invalid so lets exit.
    ; TODO: Probably utilize free_pcb
    lda #EXESTATE_TERMINATED
    sta PCB_EXESTATE_TABLE, X
    bra selNextProc$
yielding$
    lda #EXESTATE_READY
    sta PCB_EXESTATE_TABLE, X
    bra selNextProc$
selNextProc$
    ; select next process to run
    inx
    cpx #PCB_MAX_COUNT
    bcc noWrap$
    ldx #0
noWrap$
    stx R0 ; R0 is now the stopping point for the loop
    stz R1 ; R1 is now a flag. 0 -> all pcbs are terminated, 1 -> there are still blocked pcbs to wait on
loop$
    lda PCB_EXESTATE_TABLE, X
    ; cmp #EXESTATE_RUNNING no need to compare with 0 after loading (#ZERO_ENUM_EXESTATE)
    beq foundReady$
    ; not equal -> this pcb is not in the ready state, continue loop if there are more pcbs
    ; if this pcb is blocked, set blockedExists flag so that we know there is atleast a blocked pcb (if there is not and there is no ready pcb's either, that implies that there are no pcbs and so we can go back to global context)
    cmp #EXESTATE_TERMINATED
    bne terminated$
    ; if its not terminated, mark our flag in R1 indicateding that there are blocked pcbs to wait on if there are no pcbs ready to take the cpu yet
    lda #1
    sta R1
terminated$
    inx
    cpx #PCB_MAX_COUNT
    bcc noWrap2$
    ldx #0
noWrap2$
    cpx R0
    bne loop$ ; not equal -> there is still more pcbs that haven't been checked. equal -> there is no pcb in the READY state...
    ; check to see if there are any pcbs that are blocked, if so, wait on them. If not, go back to global context.
    lda R1
    bne wait$
    jmp stop_scheduling ; go back to global context because there are no processes to schedule
wait$
    ; wait for an interrupt, which may cause a process's io to finish and unblock it
    cli
    wai
    sei
    bra loop$
foundReady$

    ; store new pcb index into RUNNING_PCB
    txa
    sta RUNNING_PCB

    ; set new pcb->exeState to running state
    lda #EXESTATE_RUNNING
    sta PCB_EXESTATE_TABLE, X

    ; set stack page to RUNNING->stackPage
    lda PCB_STACKPAGE_TABLE, X
    sta STK_PG_CTRL_REG

    ; load RUNNING->sp into sp
    lda PCB_SP_TABLE, X
    tax
    txs

    sta SIMPLE_TIMER_BASE_REG ; storing into simple timer's interrupt register causes it to reset its time to inital cycles
    lda SIMPLE_TIMER_BASE_REG ; loading from it will clear its interrupt (so we dont leave this context switch just to perform another one)

    ; pop new pcb's context
    PULLR RF
    PULLR RE
    PULLR RD
    PULLR RC
    PULLR RB
    PULLR RA
    PULLR R9
    PULLR R8
    PULLR R7
    PULLR R6
    PULLR R5
    PULLR R4
    PULLR R3
    PULLR R2
    PULLR R1
    PULLR R0
    ply
    plx
    pla
    rti
; ----------------------

    .endif ; end include guard