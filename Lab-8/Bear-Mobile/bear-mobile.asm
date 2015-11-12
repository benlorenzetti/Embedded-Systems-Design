; bear-mobile.asm
; Embedded Systems Design Lab 8
; Ben Lorenzetti
; /opt/microchip/mplabx/v3.10/mpasmx/mpasmx -p16f887 catch-the-clown.asm
#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define	ADC_CONTROL1	0x00	; left justify ADC result into ADRESH, and
				; use Vss for Vref+ and Vdd for Vref-
#define	ADC_CONTROL0	0x41	; ADC clock rate = Fosc/8, input channel = 0,
				; and ADC = on.
#define OPTIONS_LITERAL	(0<<T0CS) | (0<<PSA) | (1<<PS2) | (1<<PS1) | (1<<PS0)
			; Clk = Fosc/4, prescale assignment bit 0, prescalar 256
#define TIMER0_SCALAR	.128
#define	POST_SCALAR	.32	; Blink half period = (1 MHz / 4) /
; Blink 1/2period = 0.25 MHz /(Prescalar * (256 -Timer0_Scalar) *Post_scalar)
#define	tout_counter	0x20	; uint8_t tout_counter;
#define	save_w		0x21
#define	save_status	0x22

Reset_Vector
	ORG	0x00
	GOTO	Main

Interupt_Vector
	ORG	0x04
	MOVWF	save_w		; save W register
	MOVF	STATUS, W	
	MOVWF	save_status	; save STATUS register
	BCF	INTCON, T0IF	; reset timer0 interupt flag
	MOVLW	TIMER0_SCALAR	; reset timer0
	MOVWF	TMR0		;   with predetermined counter
	DECFSZ	tout_counter, F	; if (!(--tout_counter))
	GOTO	Return_from_Interupt
	MOVLW	POST_SCALAR	;   reset tout_counter...
	MOVWF	tout_counter	;     tout_counter = POST_SCALAR;
	MOVLW	0x01		;   load bit 0 mask into W
	XORWF	PORTD, F	;   invert bit 0 of PORTD
Return_from_Interupt
	MOVF	save_status, W	; restore Status register
	MOVWF	STATUS
	SWAPF	save_w, f	; restore W without changing Z
	SWAPF	save_w, w
	RETFIE			;   return from interupt
				; }
	
Main
Initialize_Microcontroller
	BSF	STATUS, RP0	; goto Bank 1
	CLRF	TRISD		; config port D to output for LEDs
	BSF	TRISA, RB0	; config port A pin 0 to input for pot.
	MOVLW	ADC_CONTROL1	; config ADC to left justify, Vss, and Vdd
	MOVWF	ADCON1
	BSF	STATUS, RP1	; goto Bank 3
	BSF	ANSEL, 0	; select portA pin0 as analog input
	MOVLW	OPTIONS_LITERAL	; timer0 clk, prescalar, &prescalar assignment
	MOVWF	OPTION_REG	; configure timer 0
	BANKSEL	0x00		; return to Bank 0
	MOVLW	ADC_CONTROL0	; config ADC clock rate, select channel 0
	MOVWF	ADCON0		;   and turn ADC on
	BCF	INTCON, PEIE	; disable peripheral interupts
	BSF	INTCON, T0IE	; enable timer0 interupt
	BSF	INTCON, GIE	; set global enable interupt flag

Initialize_Data
	BCF	PORTD, 0	; initialize teddy bear eye closed
	MOVLW	POST_SCALAR	; initialize tout_counter to
	MOVWF	tout_counter	; tout_counter = POST_SCALAR;
	
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

	END
