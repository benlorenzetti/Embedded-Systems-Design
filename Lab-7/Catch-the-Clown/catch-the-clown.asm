; catch-the-clown.asm
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

#define	OUTER_MIN_PERIOD	.4
#define MIDDLE_SCALAR	.8
#define	DEBOUNCE_TIME	.8
#define	CLOWN_STATE	1 << 7
#define	OSC8_CHANNEL0_NOGO_ADON	0x41
#define	LEFTJUSTIFY_VSS_VDD	0x00

#define	led_state	PORTD
#define	period		0x20
#define	outer_counter	0x21
#define	middle_counter	0x22
#define timeout_counter	0x23	; timeout counter local to Monitor_SW1 ()
#define	ss_counter	0x24	; static, steady state time counter

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
	RETLW	0			;    return false;
	;---------- Check if SW1 has been steady for debounce time ----------;
	ANDLW	0xFF		; Z = !ss_counter;
	BTFSC	STATUS, Z	; if (!ss_counter)
	RETLW	0xFF		;    return true;
				; else
	GOTO	Debounce_Loop	;    continue;

Main
Initialize_IO
	BSF	STATUS, RP0	; switch from Bank 0 to Bank 1
	CLRF	TRISD		; configure port D to output for LEDs
	BSF	TRISB, RB0	; configure pushbutton on RB0 for input
	BSF	TRISA, RA0	; configure potentionmeter on RA0 for input
	BANKSEL	ANSEL		; go to bank 3
	BSF	ANSEL, 0
	BANKSEL	ANSELH		; by default, RB0/AN12 is configured as analog
	BCF	ANSELH, ANS12	;   input. Reconfigure to digital.
	BANKSEL	0x00		; return to Bank 0

Initialize_Analog_to_Digital_Converter
	BANKSEL	ADCON1
	MOVLW	LEFTJUSTIFY_VSS_VDD
	MOVWF	ADCON1		; left justify result,
		; use VSS and VDD for Vref- and Vref+
	BANKSEL	ADCON0	
	MOVLW	OSC8_CHANNEL0_NOGO_ADON
	MOVWF	ADCON0		; ADC clock rate = Fosc/8,
		; ADC input channel = 0, ADC on

ADC_Acquisition_Time
	CLRF	outer_counter
	CLRF	middle_counter
One_Off_Delay_Loop
	DECFSZ	middle_counter, F
	GOTO	One_Off_Delay_Loop
	DECFSZ	outer_counter, F
	GOTO	One_Off_Delay_Loop
	
Initialize_State_Machine
	MOVLW	CLOWN_STATE
	MOVWF	led_state
	MOVLW	DEBOUNCE_TIME
	MOVWF	ss_counter
State_Machine_Loop

Measure_Potentiometer
	BSF	ADCON0, GO	; start convertion
	BTFSC	ADCON0, GO	; is converstion done?
	GOTO	$-1		; go back to is conversion done?

Set_Period			; swap upper nibble of ADC result
	SWAPF	ADRESH, W	; into lower 4 bits of W
	ANDLW	0x0F		; keep only the lower 4 bits
	ADDLW	OUTER_MIN_PERIOD; 
	MOVWF	period	; period = (ADC_result >> 4) + MIN_PERIOD

; for (outer_counter=OUTER_SCALAR; !outer_counter; outer_counter--)
Open_Outer_Loop
	MOVF	period, W
	MOVWF	outer_counter	; outer_counter = OUTER_SCALAR
Outer_Loop

; for (middle_counter=MIDDLE_SCALAR; !middle_counter; middle_counter--)
Open_Middle_Loop
	MOVLW	MIDDLE_SCALAR
	MOVWF	middle_counter	; middle_counter = MIDDLE_SCALAR
Middle_Loop

Monitor_SW1
	CALL	Monitor_SW1_Function

Clown_Caught_Logic
	ADDLW	0		; Z = !return_value
	BTFSC	STATUS, Z	; if (!return_value) // timeout occured
	GOTO	Close_Middle_Loop;    continue;

	MOVF	led_state, W
	SUBLW	CLOWN_STATE	; Z = if (led_state == CLOWN_STATE)
	BTFSC	STATUS, Z	; if (Z)
	GOTO	Initialize_State_Machine; // you win!

Close_Middle_Loop
	DECFSZ	middle_counter, F
	GOTO	Middle_Loop

Close_Outer_Loop
	DECFSZ	outer_counter, F
	GOTO	Outer_Loop

Next_State_Transition
	BCF	STATUS, C
	RRF	led_state, F	; led_state = state >> 1;
	BTFSS	STATUS, C	; if (state)
	GOTO	State_Machine_Loop;  continue; // continue forever loop
				; else {
	RRF	led_state, F	;    led_state = 128;
	GOTO	State_Machine_Loop
				; continue; // continue forever loop

	END
