; tricycle-lights.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define LEFT_LED		RD0
#define RIGHT_LED		RD7
#define LED_ON_PERIOD		.16
#define INNER_DELAY_TIME	.16
#define MIDDLE_DELAY_TIME	.32
#define	OSC8_CHANNEL0_NOGO_ADON	B'01000001
#define	LEFTJUSTIFY_VSS_VDD	B'00000000
#define RESULT_TRUNCATION_MASK	0xFC

;-----------------------Organize Program Memory---------------------;
Reset_Vector
	ORG 0
	GOTO Initialize

Interupt_Vector
	ORG .4

;--------------------Allocate Static Variables----------------------;
	cblock	0x20
	adc_result
	turn_signal
	delay_time
	outer_delay_counter
	middle_delay_counter
	inner_delay_counter
	endc

;----------Pause (INNER_DELAY * MIDDLE_DELAY * delay_time)----------;
Delay_Function
	MOVF	delay_time, 0		; copy delay_time to
	MOVWF	outer_delay_counter	;   outer_delay_loop
	MOVLW	INNER_DELAY_TIME	; initialize
	MOVWF	inner_delay_counter	;   inner_delay_counter
	MOVLW	MIDDLE_DELAY_TIME	; initialize
	MOVWF	middle_delay_counter	;   middle_delay_counter
Inner_Loop
	DECFSZ	inner_delay_counter, f
	GOTO	Inner_Loop
	MOVLW	INNER_DELAY_TIME
	MOVWF	inner_delay_counter
Middle_Loop
	DECFSZ	middle_delay_counter, f
	GOTO	Inner_Loop
	MOVLW	MIDDLE_DELAY_TIME
	MOVWF	middle_delay_counter
Outer_Loop
	DECFSZ	outer_delay_counter, f
	GOTO	Inner_Loop
	; return from delay function
	RETURN

;-------------------Initialize Data Memory--------------------------;
Initialize
	;------------- Initialize I/O ------------------------------;
	BANKSEL TRISD		; select Register Bank 1
	CLRF	TRISD		; set all LED pins to output
	BANKSEL PORTD		; back to Register Bank 0
	CLRF	PORTD		; set all LED pins to low
	BANKSEL	TRISA
	CLRF	TRISA		; clear TRISA
	BSF	TRISA, RA0	; set port A pin 0 to input
	;------------- Initialize ADC-------------------------------;
	BANKSEL	ADCON1
	MOVLW	LEFTJUSTIFY_VSS_VDD
	MOVWF	ADCON1		; left justify result,
		; use VSS and VDD for Vref- and Vref+
	BANKSEL	ADCON0	
	MOVLW	OSC8_CHANNEL0_NOGO_ADON
	MOVWF	ADCON0		; ADC clock rate = Fosc/8,
		; ADC input channel = 0, ADC on
	MOVLW	10		
	MOVWF	delay_time	; initialize delay_time
	CALL	Delay_Function	; Pause to allow ADC to settle
	;--------------- Go back to bank 0 -------------------------;
	BANKSEL	PORTD

;---------------Begin Main Program Loop-----------------------------;
Main
	;------------ Measure Potentiostat Input -------------------;
	BANKSEL	ADCON0
	BSF	ADCON0, GO	; start convertion
	BTFSC	ADCON0, GO	; is converstion done?
	GOTO	$-1		; go back to BTFSC instruction
	BANKSEL ADRESH
	MOVFW	ADRESH		; store ADC result in W
	ANDLW	RESULT_TRUNCATION_MASK	; adjust result resolution
	BANKSEL	PORTA		; go back to bank 0
	;------------ Ensure Pot Input is Valid --------------------;
	ADDLW	.0	; perform an arithmetic op on W to set Z flag
	BTFSC	STATUS, Z
	ADDLW	1	; if adc_result is zero, it would monkey with
		; the condition testing in the next step
		; so, if this is the case, set it equal to 1.
	MOVWF	adc_result
	;---- Test if adc_result == 10000000 (neutral position) ----;
	BSF	STATUS, C	; add 1 to adc_result during RLF
	RLF	adc_result, 1	; rotate 128 bit out of adc_result
	DECF	adc_result, 1	; set zero flag if neutral position
	; now Zero and Carry flags contain all needed information
	;---------- if (adc_result == NEUTRAL_POSITION) ------------;
	BTFSC	STATUS, Z	; 
	GOTO	Main		; continue
	;---------- Set turn_signal based on Carry Flag ------------;
	MOVLW	1 << LEFT_LED	; assume C == 0
	BTFSC	STATUS, C	; skip next instr. if C == 0
	MOVLW	1 << RIGHT_LED
	MOVWF	turn_signal	; load correct LED to blink on
	;---------- Set turn_signal_period based on Carry Flag -----;
	MOVFW	adc_result	; copy adc_result into W
	MOVWF	delay_time
		; turn_signal_period = adc_result
	BTFSC	STATUS, C	; skip next inst. if C == 0
	COMF	delay_time, 1
		; turn_signal_period = ~adc_result
	;---------- Blink the Turn Signal LED ----------------------;
	CALL	Delay_Function
	MOVF	turn_signal, 0	; copy turn_signal to W
	MOVWF	PORTD		; turn on appropriate LED
	MOVLW	LED_ON_PERIOD
	MOVWF	delay_time
	CALL	Delay_Function
	CLRF	PORTD		; turn off all LEDs
	CALL	Delay_Function
	;---------- End of Main Function Loop ----------------------;
	GOTO	Main
;-------------------------- End of File ----------------------------;
	END

