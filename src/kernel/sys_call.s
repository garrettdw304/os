    .include SYS_CALL_S
SYS_CALL_S = 1

; This file is the interface between kernel and user space.
; No user space applications are technically allowed to directly call
; any kernel space functions other than ones in this file.

SYS_EXIT = 0
SYS_YIELD = 1
SYS_IOREQ = 2 ; R0..1 -> Struct to pass to driver's begin function
SYS_KALLOC = 3 ; R0..1 -> Number of bytes to allocate. R0..1 <- Address of allocated bytes
FIRST_INVALID_SYS_CALL = 4 ; TODO: Increment as more sys_calls are added

; Sys call jump table
sys_call_table_lsb:
    .byte <(switch_process-1) ; SYS_EXIT
    .byte <(switch_process-1) ; SYS_YIELD
    .byte <(request_io-1) ; SYS_IOREQ
    .byte <(kalloc-1) ; SYS_KALLOC
sys_call_table_msb:
    .byte >(switch_process-1) ; SYS_EXIT
    .byte >(switch_process-1) ; SYS_YIELD
    .byte >(request_io-1) ; SYS_IOREQ
    .byte >(kalloc-1) ; SYS_KALLOC

; TODO: Make sys_call take in a pointer to a struct of arguments

; ----------------------
; A -> operation. A SYS_# enum.
; VARIABLE PARAMS BASED ON THE OPERATION
; ----------------------
sys_call:
    php
    sei
    pha
    phy
    tay ; operation will be in y
    
    ; Check for any completed io requests so the process can be switched in and the device can service new requests
    jsr handle_completed_io_requests

    ; Compare operation and call appropriate subsystem (check least likely last) TODO: Might a jump table be better?
    cpy #FIRST_INVALID_SYS_CALL
    bcc valid$
    ; TODO its invalid
valid$
    ; Valid, look in jump table

    ply
    pla
    rti
; ----------------------

    .endif ; end include guard