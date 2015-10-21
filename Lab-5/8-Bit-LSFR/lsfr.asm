; 8-Bit Linear Feedback Shift Register on PIC Development Board
; Ben Lorenzetti
; Embedded Systems Design, Fall 2015

#include <p16f887.inc>
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V

;-----------LFSR Bit/Byte Sizes, Tap Locations, and Initial Values------------;
#define LSFR_SIZE 1		; LSFR byte size
#define LSFR1_TAP_MASK	0xB8
#define LSFR1_BIT_SIZE	8
#define INITIAL_VALUE	1


;--------------------Allocate Static Variables----------------------;
	cblock	0x20
	OUTER_DELAY
	MIDDLE_DELAY
	INNER_DELAY
	REMAINDER_DELAY
	BYTE_INDEX
	PROP_SIGNAL
	COUNTER
	LOCAL_LSFR: LSFR_SIZE
	LSFR1: LSFR_SIZE
	endc

;-----------------------Organize Program Memory---------------------;
Reset_Vector:
	ORG 0
	GOTO Initialize

Interupt_Vector:
	ORG 4


#define OUTER_MAX_PLUS_1 65
#define MIDDLE_MAX_PLUS_1 126
#define INNER_MAX_PLUS_1 126
#define REMAINDER 1
;-------------------- void Pause_1_Second () -----------------------;
Pause_1_Second:
	MOVLW	OUTER_MAX_PLUS_1
	MOVWF	OUTER_DELAY
	MOVLW	REMAINDER
	MOVWF	REMAINDER_DELAY
Inner_Loop:
	DECFSZ	INNER_DELAY, f
	GOTO	Inner_Loop
	MOVLW	INNER_MAX_PLUS_1
	MOVWF	INNER_DELAY
Middle_Loop:
	DECFSZ	MIDDLE_DELAY, f
	GOTO	Inner_Loop
	MOVLW	MIDDLE_MAX_PLUS_1
	MOVWF	MIDDLE_DELAY
Outer_Loop:
	DECFSZ	OUTER_DELAY, f
	GOTO	Inner_Loop
Remainder_Loop:
	DECFSZ	REMAINDER_DELAY, f
	GOTO	Remainder_Loop
	RETURN
 
;------------Linear XOR Cascade Function----------------------------;
Linear_Function:
	CLRF	PROP_SIGNAL
Propagation_Loop:
	RRF	LOCAL_LSFR, 1	; shift LSFR right 1 bit
	MOVFW	STATUS		; get status register for its carry bit
	ANDLW	1		; keep only the carry bit
	ADDWF	PROP_SIGNAL, 1	; add carry bit to propagation signal
	DECFSZ	COUNTER, 1	; decrement counter and break if zero
	GOTO	Propagation_Loop
	RETURN


;-------------------Initialize Data Memory--------------------------;
Initialize:
	;---------- Initialize I/O
	BANKSEL TRISD		; select Register Bank 1
	CLRF	TRISD		; make Port D all output pins
	BANKSEL PORTD		; back to Register Bank 0
	;-----------Initialize LSFRs--------------------------------;
	MOVLW	INITIAL_VALUE
	MOVWF	LSFR1

;---------------Begin Main Program Loop-----------------------------;
Main:
	;-------------Update LED Display----------------------------;
	MOVFW	LSFR1
	MOVWF	PORTD
	;-----------Copy Parameters Prior to Function Call----------;
	MOVLW	LSFR1_TAP_MASK
	ANDWF	LSFR1, 0	; AND LSFR1 with its TAP_MASK and store in W
	MOVWF	LOCAL_LSFR	; make local copy for function
	MOVLW	LSFR1_BIT_SIZE
	MOVWF	COUNTER		; pass LSFR bit size by copy
	;-----------Call Linear XOR Function -----------------------;
	CALL	Linear_Function
	;----------Shift and Feedback the Register------------------;
	RRF	PROP_SIGNAL, 0	; move the return bit into STATUS, C
	RLF	LSFR1, 1	; shift LSFR with carry bit feeding in
	;---------------Delay and Repeat----------------------------;
	CALL	Pause_1_Second
	GOTO	Main

	END
