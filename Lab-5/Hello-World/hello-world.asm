; Blink LED Connected to PORTD 0

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define DELAY1	0x20
#define DELAY2	0x21

Reset_Vector:
	ORG 0
	GOTO Main

Interupt_Vector:
	ORG 4

;-------------------Delay 2^16 Clock Cycles Function----------------;
Long_Delay:
	CLRF	DELAY1
	CLRF	DELAY2
Delay_Loop:
	DECFSZ	DELAY1, f
	GOTO	Delay_Loop
	DECFSZ	DELAY2, f
	GOTO	Delay_Loop
	RETURN

;-------------------------Begin Main Program------------------------;
Main:
	BANKSEL TRISD	; select Register Bank 1
	BCF	TRISD, 0	; make IO Pin RD0 an output
	BANKSEL PORTD		; back to Register Bank 0
Forever_Loop:
	BSF	PORTD, 0	; turn on LED RD0 (DS0)
	CALL	Long_Delay
	BCF	PORTD, 0	; turn off LED
	CALL	Long_Delay
	GOTO	Forever_Loop
	END
