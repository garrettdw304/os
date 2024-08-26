    .ifndef IO_SCHEDULER_S
IO_SCHEDULER_S = 1

; The io scheduler is in charge of keeping track of io requests,
; ensuring devices are not accessed by two processes at once,
; and invoking drivers to handle io requests that are currently being serviced.

    .include header.s
    .include pcb_table.s

; TODO: Create driver tables

; Checks for any complete io requests,
; returns the results of the requests to their associated processes
; and unblocks the processes.
; May begin new io requests if there are any queued up for devices who have just finished their requests.
handle_completed_io_requests:
    rts
; TODO: Store the number of io requests that are being actively serviced so we dont have to check all 16 possible requests every time
;  (would it just be faster to check them all instead of checking this number? Maybe just make it a boolean, is there at least one...)

; Begins servicing the io request if the device is free,
; or adds the request to the device's queue if it is already servicing a request.
; R0..1 -> Args struct to pass to driver's begin function
request_io:
    rts

; Called when an interrupt occurs.
; Polls every installed driver to find the one that can handle the interrupt.
invoke_driver:
    rts

    .endif ; end include guard