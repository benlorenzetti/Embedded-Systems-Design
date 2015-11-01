; pushbutton-test.asm
; Test active-low pushbutton on RB0 with active-high LED on RD0

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

Initialize_Data_and_IO
	CLRF	PORTB
	CLRF	PORTD
	BSF	STATUS, RP0	; Switch from Bank 0 to Bank 1
	BSF	PORTB, RB0	; configure RB0 as input
	BCF	PORTD, RD0	; configure RD0 as output
	BSF	STATUS, RP1	; Switch from Bank 1 to Bank 3
	BCF	ANSELH, ANS12	; by default RB0/AN12 is configured as analog
				;   input. Set to '0' to enable digital input
	BANKSEL	0x00		; Switch to Bank 0
Main_Loop
	MOVF	PORTB, W	; copy pushbutton input into W
	XORLW	1 << RB0	; invert active-low pushbutton for active-high
				;   output
	MOVWF	PORTD		; update LED display
	GOTO	Main_Loop
	END

