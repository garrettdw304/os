; Called when an interrupt occurs
; R0 <- 0 if this interrupt was not from this driver's device, non-zero if this device handled the interrupt
; If 0 is to be returned, return it ASAP!
try_handle:

; Called once, when this driver is installed. Used by the driver to initialize its resources (init device and request workspace memory from kernel).
install:

; Called when the io scheduler begins servicing an io request related to this driver
; R0: the operation to be performed
; R1..2: The args passed in by the sys_call caller
begin_operation:
