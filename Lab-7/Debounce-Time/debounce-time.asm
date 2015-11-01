; debounce-time.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

;-------------------- Declare Global Variables ------------------------------;
#define	active_state	0x20

Main
	;--------------- Initialize Variables -------------------------------;
	CLRF	PORTB		; clear input port, just for good measure
	CLRF	active_state	; initial active state for SW1 is active low
	CLRF	PORTD	; PORTD serves as counter for # of bounce events
	;--------------- Initialize I/O -------------------------------------;
	BSF	STATUS, RP0	; switch from Bank 0 to Bank 1
	CLRF	TRISD		; configure port D to output for LEDs
	BSF	TRISB, RB0	; configure pushbutton on RB0 for input
	BANKSEL	ANSELH		; by default, RB0/AN12 is configured as analog
	BCF	ANSELH, ANS12	;   input. Reconfigure to digital.
	BANKSEL	0x00		; return to Bank 0

Bounce_Event
	MOVF	PORTB, W	; store pushbutton input into W
	XORWF	active_state, W	; compare pushbutton to new active level
	ANDLW	1 << RB0	; keep only pushbutton bit
	BTFSS	STATUS, Z	; if (pushbutton != active_state),
	GOTO	Bounce_Event	;   then continue checking for bounce event
	INCF	PORTD, F	; else increment the bounce counter and
	COMF	active_state	;   invert the active state next event
	GOTO	Bounce_Event
;------------------------------ End of File ---------------------------------;
	END


