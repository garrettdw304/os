    .ifndef SYS_CALL_S
SYS_CALL_S = 1

; This file is the interface between kernel and user space.
; No user space applications are technically allowed to directly call
; any kernel space functions other than sys_call.

SYS_EXIT = 0
SYS_YIELD = 1
; R0..1 -> Number of bytes to allocate.
; R0..1 <- Address of allocated bytes, or 0 if the memory could not be allocated.
SYS_KALLOC = 2
FIRST_INVALID_SYS_CALL = 3 ; TODO: Increment as more sys_calls are added

; Sys call jump table
sys_call_table_lo:
    .byte <(switch_process-1)
    .byte <(switch_process-1)
    .byte <(sys_kalloc_handler-1)
sys_call_table_hi:
    .byte >(switch_process-1)
    .byte >(switch_process-1)
    .byte >(sys_kalloc_handler-1)


; TODO: Make sys_call take in a pointer to a struct of arguments

; ----------------------
; A -> operation. A SYS_# enum.
; VARIABLE PARAMS BASED ON THE OPERATION
; Note: Remember, we dont want to modify any R registers because that is the
; params to the sys call that the user program passed us.
; ----------------------
sys_call:
    php
    sei
    pha
    phy
    tay ; operation will be in y
    
    ; Check for any completed io requests so the process can be switched in and the device can service new requests
    ; jsr handle_completed_io_requests

    ; Compare operation and call appropriate subsystem (check least likely last) TODO: Might a jump table be better?
    cpy #FIRST_INVALID_SYS_CALL
    bcc valid$
    ; Just crash the process (exit) if the sys_call is invalid
    ldy #SYS_EXIT
valid$
    ; Jump to appropriate handler using the jump table
    jsr jump$ ; store return address to stack
    bra leaveJmpTbl$ ; When we return, branch over the jump table code
jump$
    ; Store the jump address on stack
    lda sys_call_table_hi, Y
    pha
    lda sys_call_table_lo, Y
    pha
    rts ; Jump to pushed address
leaveJmpTbl$

    ply
    pla
    rti
; ----------------------

sys_kalloc_handler:
    jsr kalloc
    rts

    .endif ; end include guard