    .include SYS_CALL_S
SYS_CALL_S = 1

; This file is the interface between kernel and user space.
; No user space applications are technically allowed to directly call
; any kernel space functions other than ones in this file.

SYS_EXIT = 0
SYS_YIELD = 1
; R0..1 -> Number of bytes to allocate.
; R0..1 <- Address of allocated bytes, or 0 if the memory could not be allocated.
SYS_KALLOC = 2
; Allocates a serial port.
; R0 -> The device to allocate. See COM*.
; R1 -> 0 if the process should be blocked until the port can be allocated. Non-zero if it should not block.
; R0 <- The device that was allocated, or $FF if the selected device (or none) could be allocated.
SYS_SERIAL_OPEN = 3
; Reads from a serial port until the buffer is full. The buffer is NOT terminated with a string terminator.
; R0..1 -> The buffer to store into.
; R2 -> The size of the buffer.
SYS_SERIAL_READ = 4
SYS_SERIAL_WRITE = 5
; Closes a device.
SYS_SERIAL_CLOSE = 6
; Allocates the GPIO port. The process that owns the GPIO port is allowed to directly modify the port's registers (DDRB & IORB).
; R0 -> Zero if the process should block, non-zero if it should not.
; R0 <- Zero if the GPIO port could not be allocated, non-zero if it was.
SYS_GPIO_OPEN = 7
; Frees the GPIO port if this process owns it.
SYS_GPIO_CLOSE = 8
FIRST_INVALID_SYS_CALL = 9 ; TODO: Increment as more sys_calls are added

; Sys call jump table
sys_call_table_lo:
    .byte <(schedule_process-1)
    .byte <(schedule_process-1)
    .byte <(sys_kalloc_handler-1)
    .byte <(sys_serial_open_handler-1)
    .byte <(sys_serial_read_handler-1)
    .byte <(sys_serial_write_handler-1)
    .byte <(sys_serial_close_handler-1)
sys_call_table_hi:
    .byte >(schedule_process-1)
    .byte >(schedule_process-1)
    .byte >(sys_kalloc_handler-1)
    .byte >(sys_serial_open_handler-1)
    .byte >(sys_serial_read_handler-1)
    .byte >(sys_serial_write_handler-1)
    .byte >(sys_serial_close_handler-1)


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
    jsr handle_completed_io_requests

    ; Compare operation and call appropriate subsystem (check least likely last) TODO: Might a jump table be better?
    cpy #FIRST_INVALID_SYS_CALL
    bcc valid$
    ; Just crash the process (exit) if the sys_call is invalid
    lda #SYS_EXIT
    sta R0
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

sys_serial_open_handler:
    ; Try to allocate the device, if fail, block if specified to do so
    jsr request_serial_io
    rts

sys_serial_read_handler:
    rts

sys_serial_write_handler:
    rts

sys_serial_close_handler:
    rts

    .endif ; end include guard