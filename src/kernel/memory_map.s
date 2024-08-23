    .ifndef MEMORY_MAP_S
; This file contains constants describing the memory map of the system.

; |-------------------------------------------------------------------------|
; DEVICE        RANGE               LENGTH      NOTE
; RAM           0000-7FFF           32768
;
; _ext. ports   8000-CFFF           20480       Extension ports
;
; _io           D000-DFFF           4096
; PSC           D000-D000           1           Programmable Stack Controller
; Simple Timer  D001-D004           4
; UART 0        D005-D008           4           The UART used by the shell program

; ROM           E000-FFFF           8192
; |-------------------------------------------------------------------------|

RAM_BASE_REG =              0
RAM_LENGTH =                32768

STK_PG_CTRL_REG =           $D000 ; stack page control register. Write to set the page for page 0x01 to remap to.
SIMPLE_TIMER_BASE_REG =     $D001 ; +0 -> INTERRUPTING, +1 -> MODE, +2 -> LO CYCLES, +3 -> HI CYCLES
ST_INTERRUPTING =           $D001
ST_MODE =                   $D002
ST_LO_CYCLES =              $D003
ST_HI_CYCLES =              $D004
UART_RX =                   $D005
UART_TX =                   $D005
UART_STAT =                 $D006
UART_CTRL =                 $D007
UART_CMD =                  $D008

ROM_BASE_REG =              $E000
ROM_LENGTH =                8192

    .endif ; END INCLUDE GUARD