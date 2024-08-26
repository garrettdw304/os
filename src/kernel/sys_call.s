    .include SYS_CALL_S
SYS_CALL_S = 1

; This file is the interface between kernel and user space.
; No user space applications are technically allowed to directly call
; any kernel space functions other than ones in this file.

SYS_EXIT = 0
SYS_YIELD = 1
SYS_IOREQ = 2 ; R0..1 -> Struct to pass to driver's begin function
SYS_KALLOC = 3 ; R0..1 -> Number of bytes to allocate. R0..1 <- Address of allocated bytes
; Allocates an RS-232 port
; R0 -> The RS-232 port to allocate, or $FF to select any available one.
; R1 -> 0 if the process should be blocked until the port can be allocated. Non-zero if it should not block.
; R0 <- The RS-232 port that was allocated, or $FF if the selected port (or none) could be allocated.
SYS_ALLOC_IO = 4
; Reads from a serial port until the buffer is full. The buffer is NOT terminated with a string terminator.
; This read request DOES NOT do special handling of the data
; (such as handling backspace or detecting the enter key or arrow keys).
; R0..1 -> The buffer to store into.
; R2 -> The size of the buffer.
SYS_READ = 7
; Reads from a serial port until the buffer is full or a carriage return followed by a new line is detected.
; This read request DOES do special handling of the data such as handling backspace, detecting the enter key
; and arrow keys and also echos received characters.
; R0..1 -> The buffer to store into.
; R2 -> The size of the buffer.
SYS_READ_LINE = 8
SYS_WRITE = 9
SYS_REG_DRIVER = 10
SYS_UNREG_DRIVER = 11
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