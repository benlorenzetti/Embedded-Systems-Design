; catch-the-clown.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define	SW1_PORT	PORTB
#define	SW1_PIN		PB0

#define STATE_PERIOD	.64
#define	DEBOUNCE_TIME	.8

#define	chance_to_win	0x20
#define	outer_counter	0x21
#define	middle_counter	0x22
#define	timeout_counter	0x23

Reset_Vector
	ORG	0x00
	GOTO	Main

; Monitor_SW1_Function
;   returns 0x00 (true) if SW1 was active for debounce_time cycles, or
;   returns 0xFF (false) if a timeout occured first
;
Monitor_SW1_Function			; Initialize local scope variables
	CLRF	timeout_counter		; timeout_counter = 256; // (256==0)
Debounce_Loop
	;---Check for Timeout Event------------------------------------------;
	DECF	timeout_counter, F	; timeout_counter--;
	BTFSC	STATUS, Z		; if (timeout_counter == 0)
	RETLW	0xFF			;   return false;
	;---Monitor pushbutton input (inactive = 1, active = 0)--------------;
	BTFSC	SW1_PORT, SW1_PIN	; if (SW1 == 1)
	MOVLW	DEBOUNCE_TIME		;   debounce_counter = DEBOUNCE_TIME;
	;---Check for Successful Debounce Event------------------------------;
	DECFSZ	W, W			; if (--debounce_counter != 0)
	GOTO	Debounce_Loop		;   continue;
					; else
	RETLW	0x00			;   return true;

Main
Reset_State_Machine
	; Initialize state machine to clown state, with chance_to_win = true
	MOVLW	B'10000000'	; clown LED
	MOVWF	PORTD		; state = clown LED
	CLRF	chance_to_win	; chance_to_win = true; // true is 0
	CLRF	middle_counter	; middle_counter = 0;
	MOVLW	STATE_PERIOD	
	MOVWF	outer_counter	; outer_counter = STATE_PERIOD;
	MOVLW	DEBOUNCE_TIME	; debounce_counter = DEBOUNCE_TIME;
Forever_Loop
	CALL	Monitor_SW1_Function	; monitor SW1 with software debounce
	; Check for Win -----------------------------------------------------;
	XORWF	chance_to_win, W; hacky way to compute 
				; (debounce_counter && chance_to_win)
	BTFSC	STATUS, Z	; if ((above logic) == true)
	GOTO	Main		;   reset_state_machine(), continue;
				; else {
	XORWF	chance_to_win, W;   restore debounce_counter
	; Decrement middle and outer time scaling counters ------------------;
	DECFSZ	middle_counter, F	; if (--middle_counter != 0)
	GOTO	Forever_Loop		;   continue;
	DECFSZ	outer_counter, F	; if (--outer_counter != 0)
	GOTO	Forever_Loop		;   continue
	; Proceed to the next LED State
	RRF	PORTD, F
	BTFSC	STATUS, C	; if (led_state == 0x100)
	GOTO	Skip_Actions	; {
	RRF	PORTD, F	;    led_state = 0x080; // (the Clown LED)
	CLRF	chance_to_win	;    chance_to_win = true;
	BTFSC	W, 0		;    if (!debounce_counter)
	DECF	chance_to_win, F;      chance_to_win = false;
Skip_Actions			; }
	; Set outer/debounce counters for first iteration in the next state
	MOVLW	STATE_PERIOD
	MOVWF	outer_counter	; outer_counter = STATE_PERIOD;
	MOVLW	DEBOUNCE_TIME	; debounce_counter = DEBOUNCE_TIME;

	GOTO	Forever_Loop	; continue endlessly
;------------------------------ End of File ---------------------------------;
	END


