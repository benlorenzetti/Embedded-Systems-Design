; debounce-tim.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define INNER_DELAY_TIME	.1
#define OUTER_DELAY_TIME	.1

;-----------------------Organize Program Memory------------------------------;
Reset_Vector
	ORG 0
	GOTO Main

Interupt_Vector
	ORG .4

;--------------------Allocate Static Variables----------------------;
	cblock	0x20
	active_state
	outer_delay_counter
	inner_delay_counter
	endc

;-------------------- Pause (INNER_DELAY * OUTER_DELAY)----------------------;
Pause
	MOVLW	OUTER_DELAY_TIME	; 
	MOVWF	outer_delay_counter	; initialize outer_delay_counter
	MOVLW	INNER_DELAY_TIME	;
	MOVWF	inner_delay_counter	; initialize inner_delay_counter
Inner_Loop
	DECFSZ	inner_delay_counter, f
	GOTO	Inner_Loop
	MOVLW	INNER_DELAY_TIME
	MOVWF	inner_delay_counter
Outer_Loop
	DECFSZ	outer_delay_counter, f
	GOTO	Inner_Loop
	RETURN

;------------------------------ Main () -------------------------------------;
Main
	;--------------- Initialize Variables and I/O -----------------------;
	BANKSEL	PORTD
	CLRF	PORTD		; port D serves as the bounce counter
	BANKSEL	TRISD
	CLRF	TRISD		; output bounce counter to LEDs
	BSF	TRISA, RA0	; use potentiometer for input
	BANKSEL	TRISB
	CLRF	TRISB
	DECF	TRISB
;	BSF	TRISB, RB0	; use pushbutton switch for input
	BANKSEL	PORTB
;	MOVF	PORTB, W	; copy initial pushbutton level into W
;	ANDLW	1 << RB0	; keep only the pushbutton pin
;	XORLW	0xFF		; invert initial level to get active level
;	MOVWF	active_state	; initialize active_level
	CLRF	active_state

First_Active_Event
	MOVF	PORTB, W	; move pushbutton input into W

	MOVWF	PORTD
	GOTO	First_Active_Event


	XORWF	active_state, W	; compare pushbutton level to active level
	ANDLW	1 << RB0	; keep only the pushbutton bit
	BTFSS	STATUS, Z	; break if (PORTB ^ active_state == 1)
	GOTO	First_Active_Event

Bounce_Counting_Loop
	INCF	PORTD, F	; increment the bounce counter
	BTFSC	STATUS, C	; check for overflow
	DECF	PORTD, F	; a hacky overflow fix...
	COMF	active_state	; next bounce will be the opposite state
	CALL	Pause		; vary the pause to test bouce damping rate

Bounce_Or_Reset_Events
	MOVF	PORTB, W	; load pushbutton input into W
	XORWF	active_state, W	; compare pushbutton to new active level
	ANDLW	1 << RB0	; keep only pushbutton bit
	BTFSS	STATUS, Z	; if (PORTB ^ active_state == 1), then a
	GOTO	Bounce_Counting_Loop	; bounce occurred and needs recorded
	MOVF	PORTA, W	; move potentiometer input to W
	ANDLW	1 << RA0	; keep only potentiometer pin
	BTFSC	STATUS, Z	; if (Vra0 == 0) then restart main program
	GOTO	Main
	GOTO	Bounce_Or_Reset_Events
;------------------------------ End of File ---------------------------------;
	END


