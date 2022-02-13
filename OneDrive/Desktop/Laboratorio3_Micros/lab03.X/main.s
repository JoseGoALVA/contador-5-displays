PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT udata_bank0		;common memory
  CONT:		DS 1
  COUNT:	DS 8		; Contador
  
PSECT resVect, class=CODE, abs, delta=2
; ----------- VECTOR RESET ------------
ORG 00h
resVect:
    PAGESEL main
    GOTO main
    
PSECT code, delta=2, abs
; --------- CONFIGURACION -------------
ORG 100h
 
main:
    BANKSEL ANSEL
    CLRF    ANSEL			; I/O digitales
    CLRF    ANSELH
    BANKSEL TRISA
    BSF	    TRISA, 0
    BSF	    TRISA, 1
    BCF	    TRISD, 0
    BCF	    TRISD, 1
    BCF	    TRISD, 2
    BCF	    TRISD, 3
    BCF	    TRISE, 0
    CLRF    TRISC
    BANKSEL PORTA
    CLRF    CONT
    BANKSEL PORTC
    CLRF    PORTD
    CLRF    PORTE
    CLRF    PORTB
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII	
    MOVWF   PORTC
     ; Configuración de I/O
	    ; Guardamos caracter de CONT en ASCII
   
LOOP:	
    CALL    CHECKBOTON
    CALL    CHECKBOTON2
    CALL    LOOP_SEGUNDOS
    DECF    PORTD
    CALL    PRENDER_LED
    GOTO    LOOP

LOOP_SEGUNDOS:
    DECFSZ COUNT ,1 ;restamos 1 a 255
    GOTO LOOP_SEGUNDOS ; si es 0 regresar al loop
    RETURN
    
CONFIG_RELOJ:
    BANKSEL OSCCON	;--> CAMBIAMOS A BANKO 1 
    BCF	    OSCCON, 0   ; SCS -->,USAMOS RELOJ INTERNO
    BCF	    OSCCON, 6	
    BSF	    OSCCON, 5
    BSF	    OSCCON, 4	; IRFC <2:0> -> 011: 500kHZ
    RETURN 
    
CONFIG_TIMER0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 64
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   61
    MOVWF   TMR0	    ; 100ms retardo
    BCF	    T0IF
    return

RESET_TIMER0:
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   61
    MOVWF   TMR0	    ; 100ms retardo
    BCF	    T0IF
    return
     
CHECKBOTON:
    BTFSS PORTA, 0		; vemos si botón está presionado
    RETURN
      
ANTIREBOTES:
    BTFSC PORTA, 0		; vemos si botón ya no está presionado
    GOTO ANTIREBOTES
    
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC		; Guardamos caracter de CONT en ASCII
    INCF    CONT		; Incremento de contador
    BTFSC   CONT, 4			; Verificamos que el contador no sea mayor a 7
    CLRF    CONT		; Si es mayor a 7, reiniciamos contador
    RETURN	
    
CHECKBOTON2:
    BTFSS   PORTA, 1
    RETURN
    
ANTIREBOTES2:
    BTFSC PORTA, 1		; vemos si botón ya no está presionado
    GOTO ANTIREBOTES2
    
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII	
    MOVWF   PORTC		; Guardamos caracter de CONT en ASCII
    DECF    CONT		; decremento de contador
    BTFSC   CONT, 4		; Verificamos que el contador no sea mayor a 7
    CLRF    CONT		; Si es mayor a 7, reiniciamos contador
    RETURN
       
PRENDER_LED:
    MOVF    PORTC, W		; Movemos el valor literal a W
    XORWF   PORTD, 0		; Realizamos un xor de w con el valor derl puerto d
    BTFSS   STATUS, 2		; si son iguales Z = 1 y se salta la instruccion
    BCF	    PORTE, 0
    
    BTFSC   STATUS, 2		; si no son iguales Z = 0 y se salta la instruccion
    BSF	    PORTE, 0
    
    RETURN			; regresamos al loop
       
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