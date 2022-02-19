; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: contador en el puerto A
; Hardware: LEDs en el puerto A
; 
; Creado: 26 ene, 2022
; Ultima modificacion: 26 ene, 2022
    
PROCESSOR 16F887
#include <xc.inc>
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC =    INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE =    OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE =   ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE =   OFF ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP =	    OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD =	    OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN =   OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO =    OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN =   OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP =	    ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  WRT =	    OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  CONFIG  BOR4V =   BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)

RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM


  
UP	EQU 0
DOWN	EQU 7
  
PSECT udata_bank0
  cont:		DS 2
  
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    CONT:		DS 1
    CONT_ASCII:		DS 1
    CONT_2:		DS 1
    CONTADOR_10S:	DS 1
    CONT_3:		DS 1
  
PSECT resVect, class=CODE, abs, delta=2
ORG 00h
       
resetVec:
    PAGESEL main
    GOTO main

;------------- CONFIGURACION ------------

 PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   RBIF
    CALL    INT_IOCB
    RESET_TMR0    100 ; 50ms
    CALL    CONTADOR
    
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
 
INT_IOCB:
    BANKSEL PORTA
    BTFSS   PORTB, UP
    INCF    PORTA
    BTFSS   PORTB, DOWN
    DECF    PORTA
    BCF	    RBIF
    
    RETURN 
    
    
PSECT code, delta=2, abs
ORG 100h    ; posición 100h para el codigo
 
main:
    CALL    CONFIG_IO
    CALL    CONFIG_RELOJ
    CALL    CONFIG_IOCRB
    CALL    CONFIG_INT_ENABLE
    CALL    CONFIG_TMR0
    BANKSEL PORTA

LOOP:
    GOTO LOOP 
    
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BCF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 128
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   100
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN
    
    
;------------- SUBRUTINAS ---------------
    
CONFIG_IOCRB:
    BANKSEL TRISA
    BSF	    IOCB, UP
    BSF	    IOCB, DOWN
    
    BANKSEL PORTA
    MOVF    PORTB, W
    BCF	    RBIF 
    RETURN
    
    
CONFIG_IO:
    BSF	    STATUS, 5
    BSF	    STATUS, 6
    CLRF    ANSEL
    CLRF    ANSELH
    
    BSF	    STATUS, 5
    BCF	    STATUS, 6
    BCF     TRISA,  0
    BCF     TRISA,  1
    BCF     TRISA,  2
    BCF     TRISA,  3
    BSF	    TRISB, UP
    BSF	    TRISB, DOWN
    CLRF    TRISC
    
    BCF	    OPTION_REG, 7
    BSF	    WPUB, UP
    BSF	    WPUB, DOWN
    
    BCF	    STATUS, 5
    BCF	    STATUS, 6
    CLRF    PORTA
    CLRF    PORTC
 
    BANKSEL TRISD
    CLRF    TRISD
    BANKSEL PORTD
    CLRF    PORTD
    MOVF    CONT_2, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII	
    MOVWF   PORTD

 
    RETURN 
    
CONFIG_RELOJ:
    BANKSEL	OSCCON
    BSF		IRCF2
    BSF		IRCF1
    BCF		IRCF0
    BSF		SCS	    ; 4Mhz
    RETURN

CONFIG_INT_ENABLE:
    BSF	    GIE	  ;INTCON
    BSF	    RBIE
    BCF	    RBIF
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    RETURN
    
CONTADOR:
    INCF    CONT
    MOVLW   50
    XORWF   CONT, W
    BTFSS   STATUS, 2
    RETURN

    CLRF    STATUS
    MOVF    CONT_2, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTD
    
    INCF    CONT_2
				; Guardamos caracter de CONT en ASCII
    CLRW
    MOVLW   11
    XORWF   CONT_2, W
    BTFSC   STATUS, 2
    CALL    CONTADOR2
    

    CLRF    CONT
    CLRF    STATUS
    RETURN 
   
CONTADOR2:
    RESET_TMR0 100
    CLRF    CONT_2
    MOVF    CONT_3, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC
    INCF    CONT_3
    BTFSC   CONT_3, 4		; Verificamos que el contador no sea menor a 0
    CLRF    CONT_3  
    MOVF    CONT_3
    GOTO    CONTADOR
    
ORG 200h    
TABLA:
    CLRF    PCLATH			; Limpiamos registro PCLATH
    BSF	    PCLATH, 1			; Posicionamos el PC en dirección 02xxh
    ANDLW   0x0f			; no saltar más del tamaño de la tabla
    ADDWF   PCL				; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   0b00000011		    	; ASCII char 0
    RETLW   0b10011111			; ASCII char 1
    RETLW   0b00100101			; ASCII char 2
    RETLW   0b00001101			; ASCII char 3
    RETLW   0b10011001			; ASCII char 4
    RETLW   0b01001001			; ASCII char 5
    RETLW   0b01000001			; ASCII char 6
    RETLW   0b00011111			; ASCII char 7
    RETLW   0b00000001			; ASCII char 8
    RETLW   0b00001001			; ascii char 9
    RETLW   0b00010001			; Hex char a
    RETLW   0b11000001			; Hex char b
    RETLW   0b11100101			; Hex char c
    RETLW   0b10000101			; Hex char d
    RETLW   0b11100001			; Hex char e
    RETLW   0b01110001			; Hex char f      
END
