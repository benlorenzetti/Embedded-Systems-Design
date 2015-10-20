; 8-Bit Linear Feedback Shift Register on PIC Development Board
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

;---------------LFSR Bit/Byte Sizes and Tap Locations---------------;
#define N1 8
#define M1 1
#define TAP_MASK1 0x00

;--------------------Allocate Static Variables----------------------;
cblock	0x20
	OUTER_DELAY
	MIDDLE_DELAY
	INNER_DELAY
	REMAINDER_DELAY
	BYTE_INDEX
	LFSR1: M1
endc

;-----------------------Organize Program Memory---------------------;
Reset_Vector:
	ORG 0
	GOTO Main

Interupt_Vector:
	ORG 4


#define OUTER_MAX_PLUS_1 65
#define MIDDLE_MAX_PLUS_1 126
#define INNER_MAX_PLUS_1 126
#define REMAINDER 1
;-------------------- void Pause_1_Second () -----------------------;
Pause_1_Second:
	MOVLW	OUTER_MAX_PLUS_1
	MOVWF	OUTER_DELAY
	MOVLW	REMAINDER
	MOVWF	REMAINDER_DELAY
Inner_Loop:
	DECFSZ	INNER_DELAY, f
	GOTO	Inner_Loop
	MOVLW	INNER_MAX_PLUS_1
	MOVWF	INNER_DELAY
Middle_Loop:
	DECFSZ	MIDDLE_DELAY, f
	GOTO	Inner_Loop
	MOVLW	MIDDLE_MAX_PLUS_1
	MOVWF	MIDDLE_DELAY
Outer_Loop:
	DECFSZ	OUTER_DELAY, f
	GOTO	Inner_Loop
Remainder_Loop:
	DECFSZ	REMAINDER_DELAY, f
	GOTO	Remainder_Loop
	RETURN

;-------------------------Begin Main Program------------------------;
Main:
	BANKSEL TRISD	; select Register Bank 1
	BCF	TRISD, 0	; make IO Pin RD0 an output
	BANKSEL PORTD		; back to Register Bank 0
Forever_Loop:
	BSF	PORTD, 0	; turn on LED RD0 (DS0)
	CALL	Pause_1_Second
	BCF	PORTD, 0	; turn off LED
	CALL	Pause_1_Second
	GOTO	Forever_Loop
	END
