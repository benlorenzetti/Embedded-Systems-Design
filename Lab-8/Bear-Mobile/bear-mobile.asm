; bear-mobile.asm
; Embedded Systems Design Lab 8
; Ben Lorenzetti

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & BOR21V

#define	ADC_CONTROL1	0x00	; left justify ADC result into ADRESH, and
				; use Vss for Vref+ and Vdd for Vref-
#define	ADC_CONTROL0	0x41	; ADC clock rate = Fosc/8, input channel = 0,
				; and ADC = on.

#define	POST_SCALAR	.4	; Blink half period =
				;   ((1MHz/4) / Timer0 Prescalar) / PostScalar
#define	tout_counter	0x20	; uint8_t tout_counter;

Reset_Vector
	ORG	0x00
	Main

Interupt_Vector
	ORG	0x04
	DECFSZ	tout_counter, F	; if (--tout_counter)
	RETFIE			;   return;
				; else {
	MOVLW	POST_SCALAR	;   reset tout_counter...
	MOVWF	tout_counter	;     tout_counter = POST_SCALAR;
	MOVLW	0x01		;   load bit 0 mask into W
	XORWF	PORTD, F	;   invert bit 0 of PORTD
	RETFIE			;   return from interupt
				; }
	
Main
Initialize_Microcontroller
	BSF	STATUS, RP0	; goto Bank 1
	CLRF	TRISD		; config port D to output for LEDs
	BSF	TRISA, RB0	; config port A pin 0 to input for pot.
	MOVLW	ADC_CONTROL_1	; config ADC to left justify, Vss, and Vdd
	MOVWF	ADCON1
	BSF	STATUS, RP1	; goto Bank 3
	BSF	ANSEL, 0	; select portA pin0 as analog input
	BANKSEL	0x00		; return to Bank 0
	MOVLW	ADC_CONTROL_0	; config ADC clock rate, select channel 0
	MOVWF	ADCON0		;   and turn ADC on

Initialize_Data
	BCF	PORTD, 0	; initialize teddy bear eye closed
	
Forever_Loop			; for (;;) {
Measure_Potentiometer
	BSF	ADCON0, GO	; start analog-to-digital converison
	BTFSC	ADCON0, GO	; is successive approx complete?
	GOTO	$-1		; if no, check again

Update_Display
	BCF	ADRESH, 0	; clear bit 0 of ADC result (prec 256 -> 128)
	MOVLW	0x01		; load W with a bit 0 mask
	ANDWF	PORTD, W	; clear bits 7:1 of PORTD, keep bit 0
	ADDWF	ADRESH, W	; combine bits 7:1 of prior PORTD
	MOVWF	PORTD		;   with bit 0 or ADC result and update PORTD

	GOTO	Forever_Loop	; } // end of for loop
