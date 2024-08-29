    .ifndef IO_SCHEDULER_S
IO_SCHEDULER_S = 1

; The io scheduler is in charge of keeping track of io requests,
; ensuring devices are not accessed by two processes at once,
; and invoking drivers to handle io requests that are currently being serviced.

    .include header.s
    .include pcb_table.s

COM0 = 0
COM1 = 1
COM2 = 2
COM3 = 3

; COM* in, device base addr out
com_base_addrs_lo:
    .byte <(UART0_BASE_ADDR)
com_base_addrs_hi:
    .byte >(UART0_BASE_ADDR)

; Checks for any complete io requests,
; returns the results of the requests to their associated processes
; and unblocks the processes.
; May begin new io requests if there are any queued up for devices who have just finished their requests.
handle_completed_io_requests:
    rts
; TODO: Store the number of io requests that are being actively serviced so we dont have to check all 16 possible requests every time
;  (would it just be faster to check them all instead of checking this number? Maybe just make it a boolean, is there at least one...)

; R0 -> The port to allocate (See COM*)
; R0 <- Zero if already allocated by another process, non-zero if this process owns this port.
allocate_serial_port:
    rts

    .endif ; end include guard