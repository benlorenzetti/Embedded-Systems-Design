; debounce-time.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define DEBOUNCE_TIME	.1	; software debounce sampling period is
				; T = DEBOUNCE_TIME * 14 microseconds

#define rising_edge_counter	PORTD
#define	timeout_counter		0x20
#define	ss_counter		0x21	; steady state counter for debouncing

Reset_Vector
	ORG	0
	GOTO	Main

;------------------ uint8_t rising_edge Monitor_SW1 () ----------------------;
Monitor_SW1_Function
				; static uint8_t ss_counter;
	CLRF	timeout_counter	; uint8_t timeout_counter = 256;
Debounce_Loop
	;---------- Monitor Pushbutton Input --------------------------------;
	BTFSC	PORTB, RB0	; if (switch == 1)
	MOVLW	DEBOUNCE_TIME	;    ss_counter = DEBOUNCE_TIME;
	BTFSS	PORTB, RB0	; if (!switch) // SW1 is active low
	DECF	ss_counter, W	;    ss_counter--;
	MOVWF	ss_counter	
	;---------- Check for Timeout ---------------------------------------;
	DECF	timeout_counter, F	; debounce_counter--;
	BTFSC	STATUS, Z		; if (!debounce_counter)
	RETLW	0			;    return 0;
	;---------- Check if SW1 has been steady for debounce time ----------;
	ANDLW	0xFF		; Z = !ss_counter;
	BTFSC	STATUS, Z	; if (Z)
	RETLW	1		;    return 1;
				; else
	GOTO	Debounce_Loop	;    continue;

Main
Initialize_Variables
	CLRF	rising_edge_counter
	CLRF	timeout_counter
	MOVLW	DEBOUNCE_TIME
	MOVWF	ss_counter

Configure_IO
	BSF	STATUS, RP0	; switch from bank 0 to bank 1
	CLRF	TRISD		; configure PORTD for 8-LEDs output
	BSF	TRISB, RB0	; configure PORTB Pin 0 for pushbutton input
	BANKSEL	ANSELH		; by default, RB0/AN12 is configured as analog
	BCF	ANSELH, ANS12	;   input. Reconfigure to digital.
	BANKSEL	0x00		; return to bank 0

Forever_Loop
	CALL	Monitor_SW1_Function
	ADDWF	rising_edge_counter
	GOTO	Forever_Loop

	END


