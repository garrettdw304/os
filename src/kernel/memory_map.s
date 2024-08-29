    .ifndef MEMORY_MAP_S
; This file contains constants describing the memory map of the system.

; |-------------------------------------------------------------------------|
; DEVICE        RANGE               LENGTH      NOTE
; RAM           0000-7FFF           32768

; _ext. ports   8000-CFFF           20480       Extension ports

; _io           D000-DFFF           4096
; VIA           D000-D00F           16          Its gpio pin connections are defined in a seperate table in this file below
; PSC           D010-D010           1           Programmable Stack Controller
; Simple Timer  D011-D014           4
; UART 0        D015-D018           4           COM0; The UART used by default shell program
; UART 1        D019-D01C           4           COM1
; UART 2        D01D-D020           4           COM2
; UART 3        D021-D024           4           COM3

; ROM           E000-FFFF           8192
; |-------------------------------------------------------------------------|

RAM_BASE_REG =              0
RAM_LENGTH =                32768

VIA_IORB_REG =              $D000
VIA_IORA_REG =              $D001
VIA_DDRB_REG =              $D002
VIA_DDRA_REG =              $D003
VIA_T1CL_REG =              $D004
VIA_T1CH_REG =              $D005
VIA_T1LL_REG =              $D006
VIA_T1LH_REG =              $D007
VIA_T2CL_REG =              $D008
VIA_T2CH_REG =              $D009
VIA_SR_REG =                $D00A
VIA_ACR_REG =               $D00B
VIA_PCR_REG =               $D00C
VIA_IFR_REG =               $D00D
VIA_IER_REG =               $D00E
VIA_IORA_NOHS_REG =         $D00F
STK_PG_CTRL_REG =           $D010 ; stack page control register. Write to set the page for page 0x01 to remap to.
SIMPLE_TIMER_BASE_REG =     $D011 ; +0 -> INTERRUPTING, +1 -> MODE, +2 -> LO CYCLES, +3 -> HI CYCLES
ST_INTERRUPTING =           $D011
ST_MODE =                   $D012
ST_LO_CYCLES =              $D013
ST_HI_CYCLES =              $D014
UART0_BASE_ADDR =           $D015
UART0_RX =                  $D015
UART0_TX =                  $D015
UART0_STAT =                $D016
UART0_CTRL =                $D017
UART0_CMD =                 $D018
UART_RX =                   0
UART_TX =                   0
UART_STAT =                 1
UART_CTRL =                 2
UART_CMD =                  3

ROM_BASE_REG =              $E000
ROM_LENGTH =                8192

; |-------------------------------------------------------------------------|
; DEVICE        DEVICE PIN          VIA PIN         NOTE
; RTC           CE                  PORTA-0         PinMode is always OUTPUT
; *             SCLK                PORTA-1         PinMode is always OUTPUT
; *             DATA                PORTA-2         PinMode will be both (bidirectional data line)
; 
; GPIO Pins     GPIO-0..7           PORTB-0..7      Passes all 8 pins of port B to the outside of the computer for aftermarket use
; |-------------------------------------------------------------------------|

RTC_CE_PIN_FLAG =       0b00000001
RTC_SCLK_PIN_FLAG =     0b00000010
RTC_DATA_PIN_FLAG =     0b00000100

    .endif ; END INCLUDE GUARD