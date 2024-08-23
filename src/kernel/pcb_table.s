    .ifndef PCB_TABLE_S
PCB_TABLE_S = 1

; This file contains code related to the pcb struct
; and the table that the kernel uses to store its pcbs.
; The pcb table is seperated from process_scheduler.s
; because it contains information related to other
; systems such as the io scheduler.

PCB_MAX_COUNT = $10 ; Max 16 pcbs. If this is adjusted, make sure that the _TABLE offsets are seperated enough.

; IO scheduler fields
; Defines which driver will handle the io request
PCB_IOCB_DEVICE_TABLE = $290
; Passed to the driver when the request begins to be serviced
PCB_IOCB_OPERATION_TABLE = $2A0
; The pointer to the struct of arguments passed when the io request was made.
; Passed to the driver when the request begins to be serviced
PCB_IOCB_ARGSLSB_TABLE = $2B0
PCB_IOCB_ARGSMSB_TABLE = $2C0

; Process scheduler fields
PCB_EXESTATE_TABLE = $2D0
PCB_STACKPAGE_TABLE = $2E0 ; as of right now pcb stackpages are not reallocated every time a new process is created, instead we init them to pages that our heap manager is not even set to manage. Though we will leave this in here to make it easier to add this feature in later.
PCB_SP_TABLE = $2F0

    .endif ; end include guard