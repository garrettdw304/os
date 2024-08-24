    .ifndef PROCESS_SCHEDULER_S
PROCESS_SCHEDULER_S = 1

    .include header.s
    .include pcb_table.s

; pcb
; {
;     byte id // the unique identifier for this pcb.
;     exe_state exeState // the execution state of the process. RUNNING, READY, BLOCKED, TERMINATED.
;     byte stackPage // the page to be given to the PSC (Programmable Stack Controller). Also used to free this processes stack (use free_memory(stackPage<<8) to free the memeory)
;     byte sp // should be loaded into SP register. Set when creating the pcb. Got when dispatching the pcb. Set when the process scheduler is scheduling a different pcb.
;    word heap // points to the memory allocated for this process's heap
; }

; context
; {
;     word pc (program counter, pushed via the call to the schedule_process function)
;     byte p (processor flags, pushed via pha, pulled via rti)
;     byte a
;     byte x
;     byte y
;     byte r0
;     ...
;     byte rf
; }

; READY implies that the pcb is not running but is ready to run.
EXESTATE_READY = 0 ; WARNING!!! If this is ever changed from 0, find #ZERO_ENUM_EXESTATE and add cmp stuff
; BLOCKED implies that the pcb is not running and is not ready to run. It is likely waiting on some kind of io.
EXESTATE_BLOCKED = 1
; RUNNING implies that this pcb is the currently running process's pcb.
EXESTATE_RUNNING = 2
; TERMINATING implies that the process will not receive any more CPU time.
; but cannot be used for a new process due to some resources not being freed yet
; (likely an io request is currently being serviced for this process).
EXESTATE_TERMINATING = 3
; TERMINATED implies that the pcb is not in use (its free) and can be used to store the pcb of a new process.
EXESTATE_TERMINATED = 4

; The absolute address of where the global context sp is stored. This is what stack pointer is loaded when there are no more processes to run and it is time for the system to go to where it was when begin_scheduling was called
GLOBAL_CONTEXT_SP = $200

TIME_QUANTUM = 5000 ; 1_000_000hz / 1_000ms = 1_000hz/ms -> 1_000 cycles = 1ms

; The index of the currently running process. RUNNING_PCB >= 0x10 -> no running process
RUNNING_PCB = $FF

; Switches the current process out for another ready process
; Y -> What to do with the current process (SYS_EXIT/SYS_YIELD)
switch_process:
    pha
    phx
    phy
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
    plx
    ply
    pla
    rts

; ----------------------
; used by the kernel when starting up the OS to switch in the first process while taking into account that there is not already one running.
; also initializes the PCB_TABLE to all terminated pcbs (except for the new one of course)
begin_scheduling:
    pha
    phx
    ; init all pcb exe states to EXESTATE_TERMINATED
    lda #EXESTATE_TERMINATED
    ldx #0
loop$
    sta PCB_EXESTATE_TABLE, X
    inx
    cpx #PCB_MAX_COUNT
    bcc loop$ ; branch if less than

    ; init all pcb stackpages
    lda #3 ; the first page that is allocated as a stack for the pcbs. Page 3 will be pcb0's stack, page 4 pcb1's etc.
    ldx #0
loop2$
    sta PCB_STACKPAGE_TABLE, X
    inc
    inx
    cpx #PCB_MAX_COUNT
    bcc loop2$

    ; store pcb index $PCB_MAX_COUNT so that when we call schedule_process (x is already $10 from the previous loop), it knows that we are just now scheduling the first process and to store the global context pointer
    stx RUNNING_PCB

    ; create the first process to schedule
    lda #<shell
    sta R0
    lda #>shell
    sta R1
    stz R2
    jsr create_process

    ; Set the timer to the time quantum and start it
    lda #<TIME_QUANTUM
    sta SIMPLE_TIMER_BASE_REG + 2 ; LO register
    lda #>TIME_QUANTUM
    sta SIMPLE_TIMER_BASE_REG + 3 ; HI register
    lda #2 ; free running mode
    sta SIMPLE_TIMER_BASE_REG + 1 ; start timer

    lda #SYS_YIELD
    jsr sys_call
    plx
    pla
    rts

; -----byte create_process(void* initialPC, bool setBlocked)---------
; Creates a pcb for a process and sets the process's program counter to initialPC.
; initialPC - The code for the process to begin executing when it is dispatched. Located in R0..1.
; setBlocked - 0 if the pcb should be initialized to the READY state. 1 if it should be initialized to the BLOCKED state. Located in R2.
; returns - the id of the pcb, PCB_MAX_COUNT if no pcbs were free causing the process to not be started. R0
create_process:
    php
    sei ; stop interrupts when editing the process lists
    pha
    phx
    PUSHR R2

    ; find valid pcb index
    ldx #0
loop$
    lda PCB_EXESTATE_TABLE, X
    cmp #EXESTATE_TERMINATED
    beq foundTerminated$
    ; not equal -> this pcb is not in the terminated state, continue loop if there are more pcbs
    inx
    cpx #PCB_MAX_COUNT
    bcc loop$ ; jump -> still more pcbs that may be in the TERMINATED state
    ; dont jump -> there is no pcb in the TERMINATED state...
    bra fail$
foundTerminated$
    
    ; store initial state into pcb->exeState
    lda R2
    sta PCB_EXESTATE_TABLE, X

    stx R2 ; prepare params
    jsr init_stack

    stx R0 ; store return value of new pcb's index (aka its "id")
    bra success$
fail$
    lda #PCB_MAX_COUNT
    sta R0
success$
    PULLR R2
    plx
    pla
    rti ; called using jsr but returns using rti to have the processor flags pulled in an atomic operation with the return
; ------------------------------------------

; Frees resources related to a pcb. Should not be called outside of this file (instead kill should be used).
; A -> the id of the pcb to free
free_pcb:
    php
    sei ; modifying pcbs should not be interrupted
    pha
    phy
    tay

    lda #EXESTATE_TERMINATED
    sta PCB_EXESTATE_TABLE, Y
    ; TODO: Free things such as allocated memory

    ply
    pla
    rti

; -----byte load_program(char* fileName)----------------------------
; Loads the program who's code and load info are contained in fileName.
; ------------------------------------------------------------------

; -----private void init_stack(void* initialPC, byte pcbIndex)------
; EXPECTS INTERRUPT ENABLE TO BE SET
; Initializes a processes stack to contain a valid context for when it is swapped in
; initialPC in R0..1
; pcbIndex in R2
init_stack:
    pha
    phx
    PUSHR R0
    PUSHR R1
    PUSHR R3
    PUSHR R4

    tsx ; preserve current stack pointer
    stx R3
    lda STK_PG_CTRL_REG ; preserve current stack page
    sta R4
    
    ; init new pcb's stack
    ldx R2
    lda PCB_STACKPAGE_TABLE, X
    sta STK_PG_CTRL_REG
    ldx #$FF
    txs

    ; Subtract 1 from initialPC to make it a valid return address
    sec
    lda R0
    sbc #1
    sta R0
    lda R1
    sbc #0 ; subtract carry
    sta R1

    ; push initial context
    ; push initialPC
    PUSHR R1
    PUSHR R0
    lda #0
    pha ; push p reg
    pha ; a
    pha ; x
    pha ; y
    pha ; R0
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha
    pha ; RF
    
    ; store sp into new pcb->sp
    tsx
    txa
    ldx R2 ; x <- pcb index
    sta PCB_SP_TABLE, X
    
    lda R4 ; restore current stack page
    sta STK_PG_CTRL_REG
    ldx R3 ; restore current stack pointer
    txs

    PULLR R4
    PULLR R3
    PULLR R1
    PULLR R0
    plx
    pla
    rts
; ------------------------------------------------------------------

; Stops scheduling processes and goes back to the global context
stop_scheduling:
    sei ; disable interrupts
    ; restore global context stack
    lda #1
    sta STK_PG_CTRL_REG
    ldx GLOBAL_CONTEXT_SP
    txs
    ; pop global context
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

; TODO: Convert/move to user space
; Kills a process.
; A -> The process id of the process to kill
kill:
    cmp RUNNING_PCB
    bne notMe$
    lda #SYS_EXIT
    jsr sys_call 
notMe$
    jsr free_pcb
    rts

    .endif ; end include guard