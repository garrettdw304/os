    .ifndef IO_SCHEDULER_S
IO_SCHEDULER_S = 1

; The io scheduler is in charge of keeping track of io requests,
; ensuring devices are not accessed by two processes at once,
; and invoking drivers to handle io requests that are currently being serviced.

    .include header.s
    .include pcb_table.s

; Checks for any complete io requests,
; returns the results of the requests to their associated processes
; and unblocks the processes.
; May begin new io requests if there are any queued up for devices who have just finished their requests.
check_complete_requests:

; Begins servicing the io request if the device is free,
; or adds the request to the device's queue if it is already servicing a request.
request_io:

    .endif ; end include guard