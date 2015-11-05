; catch-the-clown.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define OUTER_SCALAR	.32
#define MIDDLE_SCALAR	.32
#define	DEBOUNCE_TIME	.8

#define	state		0x20
#define	outer_counter	0x21
#define	middle_counter	0x22
#define timeout_counter	0x23	; non-static, timeout counter local to Monitor_SW1 ()
#define	ss_counter	0x24	; static, steady state counter local to Monitor_SW1 ()

Reset_Vector
	ORG	0
	GOTO	Main

; Monitor_SW1_Function-------------------------------------------------------;
Monitor_SW1_Function			; Initialize local scope variables
	CLRF	timeout_counter		; timeout_counter = 256; // (256==0)
Debounce_Loop
	;---Monitor pushbutton input-----------------------------------------;
	BTFSC	PORTB, RB0		; if (switch == 1)
	MOVLW	DEBOUNCE_TIME		;   ss_counter = DEBOUNCE_TIME;
	BTFSS	PORTB, RB0		; else // if (switch == 0)
	DECF	ss_counter, W		;   ss_counter--;	
	MOVWF	ss_counter
	;---Check for Successful Debounce Event------------------------------;
	ANDLW	0xFF		; Z = !ss_counter;
	BTFSC	STATUS, Z	; if (Z)
	RETLW	0		;    return 0;	// SW1 is active and steady
	;---Check for Timeout Event------------------------------------------;
	DECFSZ	timeout_counter	; if (--timeout_counter)
	GOTO	Debounce_Loop	;   continue;
				; else
	RETLW	1		;   return 1; // either SW1 is inactive, or
				;   // function timed out before proven steady

; uint8_t led_output Next_State_Transition (uint8_t state*, uint8_t active)
Next_State_Transition_Function
	MOVLW	0x01
	RETURN

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
	CLRF	state
	MOVLW	DEBOUNCE_TIME
	MOVFW	ss_counter

Forever_Loop

; for (outer_counter=OUTER_SCALAR; !outer_counter; outer_counter--)
Open_Outer_Loop
	MOVLW	OUTER_SCALAR	
	MOVWF	outer_counter	; outer_counter = OUTER_SCALAR
Outer_Loop

; for (middle_counter=MIDDLE_SCALAR; !middle_counter; middle_counter--)
Open_Middle_Loop
	MOVLW	MIDDLE_SCALAR
	MOVWF	middle_counter	; middle_counter = MIDDLE_SCALAR
Middle_Loop

Monitor_SW1
	CALL	Monitor_SW1_Function
Clown_Caught
	ADDWF	state, W		; Z = !(state + return_value)
	BTFSS	STATUS, Z	 	; if (!Z)
	GOTO	Middle_Loop	 	;   continue;

Close_Middle_Loop
	DECFSZ	middle_counter, F
	GOTO	Middle_Loop

Close_Outer_Loop
	DECFSZ	outer_counter, F
	GOTO	Outer_Loop

Next_State_Transition
	CALL	Next_State_Transition_Function

Update_LED_Display
	MOVWF	PORTD	; LED_Diplay = return_value;

	GOTO	Forever_Loop

	END
