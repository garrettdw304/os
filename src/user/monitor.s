; implements features of a monitor

; Stores bytes into memory.
; R0..1 -> The address of the first byte to be replaced by the byte buffer.
; R2..3 -> The byte buffer that contains the bytes to store into memory.
; R4 -> The length of the byte buffer.
monitor_store:
    rts

; Loads bytes from memory and prints them.
; R0..1 -> The address of the first byte to be printed to stdio.
; R2 -> The number of bytes to be printed.
monitor_load:
    rts