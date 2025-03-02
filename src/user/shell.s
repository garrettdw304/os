    .ifndef SHELL_S
SHELL_S = 1
; This file contains code for the shell.

    .include header.s

create_process_cmd_str: .asciiz "create"
cls_cmd_str: .asciiz "cls"
print_pcbs_cmd_str: .asciiz "print"
shutdown_cmd_str: .asciiz "shutdown"
kill_cmd_str: .asciiz "kill "
help_cmd_str: .asciiz "help"

COMMAND_TABLE_LEN = 7
command_table_str_lo:
    .byte <(create_process_cmd_str)
    .byte <(cls_cmd_str)
    .byte <(print_pcbs_cmd_str)
    .byte <(shutdown_cmd_str)
    .byte <(kill_cmd_str)
    .byte <(help_cmd_str)
command_table_str_hi:
    .byte >(create_process_cmd_str)
    .byte >(cls_cmd_str)
    .byte >(print_pcbs_cmd_str)
    .byte >(shutdown_cmd_str)
    .byte >(kill_cmd_str)
    .byte >(help_cmd_str)
command_table_handler_lo:
    .byte <(create_process_ch-1)
    .byte <(cls_ch-1)
    .byte <(print_pcbs_ch-1)
    .byte <(shutdown_ch-1)
    .byte <(kill_ch-1)
    .byte <(help_ch-1)
command_table_handler_hi:
    .byte >(create_process_ch-1)
    .byte >(cls_ch-1)
    .byte >(print_pcbs_ch-1)
    .byte >(shutdown_ch-1)
    .byte >(kill_ch-1)
    .byte >(help_ch-1)

init_alt_buf_str:
    .byte $1B
    .asciiz "[?1049h"
unknown_command_str: .asciiz "Unknown command."
createProc_success_str: .asciiz "Created process successfully!"
createProc_fail_str: .asciiz "Failed to create process."
print_pcbs_space_str: .asciiz "        "
print_pcbs_header_str: .asciiz "ID         STATE      STKPG      SP"
shutdown_notification_str: .asciiz "System will now shutdown."
kill_fail_str: .asciiz "Process ID out of range (0-F)."
kill_success_str: .asciiz "Process killed."
help_str: .ascii "create. cls. print. shutdown. kill <pcb #>. help."

BUF_SIZE = 128

; The first register to be used to store a pointer to the input buffer
BUF_PTR_REG = $2

; Shell process entry point.
shell:
    ; init character buffer
    lda #<BUF_SIZE
    sta R0
    lda #>BUF_SIZE
    sta R1
    jsr kalloc ; TODO: Use user space heap
    ; move char buffer pointer into its permanent location
    lda R0
    sta BUF_PTR_REG
    lda R1
    sta BUF_PTR_REG+1
    ; software reset
    sta UART0_STAT ; value is dont cares
    ; init ctrl and cmd register
    lda #%00011110 ; 1 stop bit [1], 8 data bits [2], RCS = baud rate [1], 9600 baud rate [4]
    sta UART0_CTRL
    lda #%00001011 ; dont care [2], parity disabled [1], echo off [1], trans intr ctrl off req to send pin low [1], disable req interrupts [1], data terminal ready [1] (starts enabled interrupts)
    sta UART0_CMD
    PRINT init_alt_buf_str
loop$
    lda #'>'
    jsr printc
    jsr read_line
    jsr handle_command
    bra loop$

; Reads a line into the string buffer pointed to by BUF_PTR_REG..BUF_PTR_REG
; BUF_PTR_REG..BUF_PTR_REG -> string buffer
; A <- gobbledygook
; Y <- gobbledygook
read_line:
    ldy #0
loop$
    jsr readc ; A <- character
    cmp #LF
    beq return$
    cmp #CR
    beq return$
    cmp #8 ; backspace
    beq backspace$
    sta (BUF_PTR_REG), Y
    jsr printc ; echo character
    iny
    cpy #(BUF_SIZE-1) ; -1 for space for the string terminator
    bne loop$
    bra return$
backspace$
    cpy #0
    beq loop$ ; dont go back if at beginning of buffer
    dey
    jsr printc ; print the backspace that we read in
    lda #32 ; space
    jsr printc ; clear the character that we backspaced
    lda #8 ; backspace
    jsr printc
    bra loop$
return$
    ; goto next line
    PRINT_CRLF
    ; terminate string
    lda #0
    sta (BUF_PTR_REG), Y
    rts

; BUF_PTR_REG..BUF_PTR_REG+1 -> A pointer to a null-terminated-sub-256-len string that contains a potential command.
; R0..1 <- gobbledygook
; A <- gobbledygook
; Y <- gobbledygook
handle_command:
    ldy #$FF
loop$
    iny
    ; check to see if we are at the end of the command table
    cpy #COMMAND_TABLE_LEN
    beq unknownCommand$
    ; compare the command string with the input buffer
    lda command_table_str_lo, Y
    sta R0
    lda command_table_str_hi, Y
    sta R1
    jsr starts_with
    bne loop$
    ; call command handler
    jsr call_command_handler
    rts
unknownCommand$
    PRINT_LN unknown_command_str
    rts

; whenever the command handler returns, it does not return to this function
; but instead to the function that called call_command_handler
; Y -> command handler index
; A <- gobbledygook
call_command_handler:
    lda command_table_handler_hi, Y
    pha
    lda command_table_handler_lo, Y
    pha
    rts ; jumps to the address we just pushed.

; --------------------------------------------
; COMMAND HANDLERS
; --------------------------------------------
create_process_ch:
    pha
    PUSHR R2

    lda #<procEntry$
    sta R0
    lda #>procEntry$
    sta R1
    lda #0 ; initialize unblocked
    sta R2
    jsr create_process
    lda R0
    cmp #PCB_MAX_COUNT
    bcc success$

fail$
    lda #<createProc_fail_str
    sta R0
    lda #>createProc_fail_str
    bra return$

    ; print success message
success$
    lda #<createProc_success_str
    sta R0
    lda #>createProc_success_str

return$
    sta R1
    jsr print
    PRINT_CRLF
    PULLR R2
    pla
    rts
procEntry$
    bra procEntry$

cls_ch:
    bra start$
    
str$ ; Erase screen. Cursor to home (0,0).
    .byte $1B
    .ascii "[2J"
    .byte $1B
    .ascii "[H"
    .byte 0
start$
    pha
    lda #<str$
    sta R0
    lda #>str$
    sta R1
    jsr print
    pla
    rts

print_pcbs_ch:
    php
    sei ; dont wanna be interrupted while interacting with process stuff
    pha
    phy
    PUSHR R0
    PUSHR R1
    PUSHR R2
    PUSHR R3
    PUSHR R4
    PUSHR R5
    PUSHR R6
    PUSHR R7

    lda #<PCB_EXESTATE_TABLE
    sta R2
    lda #>PCB_EXESTATE_TABLE
    sta R3
    lda #<PCB_STACKPAGE_TABLE
    sta R4
    lda #>PCB_STACKPAGE_TABLE
    sta R5
    lda #<PCB_SP_TABLE
    sta R6
    lda #>PCB_SP_TABLE
    sta R7

    PRINT_LN print_pcbs_header_str

    ldy #0
loop$
    cpy #PCB_MAX_COUNT
    beq return$
    PRINTC '$'
    tya
    jsr print_hex
    PRINT print_pcbs_space_str
    PRINTC '$'
    lda (R2), Y
    jsr print_hex
    PRINT print_pcbs_space_str
    PRINTC '$'
    lda (R4), Y
    jsr print_hex
    PRINT print_pcbs_space_str
    PRINTC '$'
    lda (R6), Y
    jsr print_hex
    PRINT_CRLF
    iny
    bra loop$

return$
    PULLR R7
    PULLR R6
    PULLR R5
    PULLR R4
    PULLR R3
    PULLR R2
    PULLR R1
    PULLR R0
    ply
    pla
    rti

shutdown_ch:
    PRINT_LN shutdown_notification_str
    jsr stop_scheduling
    rts

kill_ch:
    pha
    phy

    ldy #5
    lda (R2), Y
    jsr hexCharToValue
    cmp #$FF
    bne valid$
    PRINT_LN kill_fail_str
    bra return$
valid$
    jsr kill
    PRINT_LN kill_success_str
return$
    ply
    pla
    rts

help_ch:
    PRINT_LN help_str
    rts

    .endif