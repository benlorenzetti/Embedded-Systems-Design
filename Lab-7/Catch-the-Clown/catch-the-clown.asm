; catch-the-clown.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define OUTER_SCALAR	.32
#define MIDDLE_SCALAR	.32
#define	DEBOUNCE_TIME	.8

#define	chance_to_win	0x20
#define	outer_counter	0x21
#define	middle_counter	0x22
#define	timeout_counter	0x23
#define steady_counter	0x24

Reset_Vector
	ORG	0
	GOTO	Main

; Monitor_SW1_Function-------------------------------------------------------;
Monitor_SW1_Function			; Initialize local scope variables
	CLRF	timeout_counter		; timeout_counter = 256; // (256==0)
Debounce_Loop
	;---Monitor pushbutton input-----------------------------------------;
	BTFSC	PORTB, RB0		; if (switch == 1)
	MOVLW	DEBOUNCE_TIME		;   steady_counter = DEBOUNCE_TIME;
	BTFSS	PORTB, RB0		; else // if (switch == 0)
	DECF	steady_counter, W	;   steady_counter--;	
	MOVWF	steady_counter
	;---Check for Successful Debounce Event------------------------------;
	BTFSC	STATUS, Z	; if (!steady_counter)
	RETLW	1		;    return 1; // for active
	;---Check for Timeout Event------------------------------------------;
	DECFSZ	timeout_counter	; if (--timeout_counter)
	GOTO	Debounce_Loop	;   continue;
				; else
	RETLW	0		;   return 0; // for inactive/timeout

Main
Initialize_IO
	BSF	STATUS, RP0	; switch from Bank 0 to Bank 1
	CLRF	TRISD		; configure port D to output for LEDs
	BSF	TRISB, RB0	; configure pushbutton on RB0 for input
	BANKSEL	ANSELH		; by default, RB0/AN12 is configured as analog
	BCF	ANSELH, ANS12	;   input. Reconfigure to digital.
	BANKSEL	0x00		; return to Bank 0

Initialize_Global_Variables
	MOVLW	0x10
	MOVWF	PORTD
	CLRF	PORTB
	CLRF	chance_to_win
	MOVLW	DEBOUNCE_TIME
	MOVFW	steady_counter

Forever_Loop
	MOVLW	OUTER_SCALAR		; else
	MOVWF	outer_counter		;   outer_counter = OUTER_SCALAR
Outer_Loop	; while (outer_counter)
	MOVLW	MIDDLE_SCALAR		; else
	MOVWF	middle_counter		;   middle_counter = MIDDLE_SCALAR
Middle_Loop	; while (middle_counter)
	; Monitor switch for active state (returns W=1 active; W=0 inactive)
	CALL	Monitor_SW1_Function
	; Check for Win -----------------------------------------------------;
	ANDWF	chance_to_win, W	; 
	BTFSS	STATUS, Z	 	; if (return_val && chance_to_win)
	GOTO	Middle_Loop	 	;   continue;
					; else
	DECFSZ	middle_counter, F	;   middle_counter--;
	GOTO	Middle_Loop
; End Middle_Loop Scope
	DECFSZ	outer_counter, F	; outer_counter--;
	GOTO	Outer_Loop		; 
; End Outer_Loop Scope
	; Advance to Next LED State
	BCF	STATUS, C
	RRF	PORTD, F		; led_state = led_state >> 1
	BTFSS	STATUS, C		; if (led_state)
	GOTO	Forever_Loop		;    continue;
					; if (!led_state) {
	RRF	PORTD, F		;    led_state = 128; // Clown state
	CLRF	chance_to_win		;    chance_to_win = false;
	MOVF	steady_counter, W	;    // to set the zero flag
	BTFSS	STATUS, Z		;    if (steady_counter != 0)
	INCF	chance_to_win, F	;       chance_to_win = true;
					; }
	GOTO	Forever_Loop
; End Forever_Loop Scope ----------------------------------------------------;
	END
