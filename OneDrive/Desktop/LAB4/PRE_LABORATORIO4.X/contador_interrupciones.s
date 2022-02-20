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
    MOVLW   TMR_VAR	    ; movemos el valor de TMR_VAR a W
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM		    ; terminamos el macro


  
UP	EQU 0		    ; asignamos el bit 0 (numero de puerto) a la variable UP
DOWN	EQU 7		    ; asignamos el bit 7 (numero de puerto) a la variable DOWN 
  
PSECT udata_bank0
  cont:		DS 2
  
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    CONT:		DS 1	; contador para el primer display
    CONT_ASCII:		DS 1	; Contador para la tabla
    CONT_2:		DS 1	; contador para el segundo display
    CONT_3:		DS 1	; contador que chuquea el loop cada 60 segundos

  
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
    RESET_TMR0    100 ; 20ms
    CALL    CONTADOR
    
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
 
INT_IOCB:
    BANKSEL PORTA
    BTFSS   PORTB, UP	    ; llequemao el estado de puerto en  B
    INCF    PORTA
    BTFSS   PORTB, DOWN	    ; llequemao el estado de puerto en  B
    DECF    PORTA
    BCF	    RBIF	    ; Ponemos en cero RBIF
    
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
    MOVWF   TMR0	    ; 20ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN
    
    
;------------- SUBRUTINAS ---------------
    
CONFIG_IOCRB:
    BANKSEL TRISA
    BSF	    IOCB, UP	    ; Activamos la interrupcion en cambio del puerto b
    BSF	    IOCB, DOWN
    
    BANKSEL PORTA
    MOVF    PORTB, W
    BCF	    RBIF	    ; Activamos la bandera de interrupcion del puerto b
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
    BCF     TRISA,  2		; Asinagmos los puertos en A como salidas
    BCF     TRISA,  3
    BSF	    TRISB, UP		; Asinagmos los puertos en B como entradas
    BSF	    TRISB, DOWN
    CLRF    TRISC		; Asinagmos los puertos en C como salidas
    
    BCF	    OPTION_REG, 7
    BSF	    WPUB, UP		; Activamos el sistema pull up del puerto b
    BSF	    WPUB, DOWN		; Activamos el sistema pull down del puerto b
    
    BCF	    STATUS, 5
    BCF	    STATUS, 6
    CLRF    PORTA		; limpiamos el puerto A
    CLRF    PORTC		; limpiamos el puerto B
 
    BANKSEL TRISD
    CLRF    TRISD		; Asinagmos los puertos en d como salidas
    BANKSEL PORTD
    CLRF    PORTD
    MOVF    CONT_2, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII	
    MOVWF   PORTD		; Movemos el valor de CONT al puerto D

 
    RETURN 
    
CONFIG_RELOJ:
    BANKSEL	OSCCON
    BSF		IRCF2
    BSF		IRCF1
    BCF		IRCF0
    BSF		SCS		; configuramos el oscilador a 4Mhz
    RETURN

CONFIG_INT_ENABLE:
    BSF	    GIE			;INTCON
    BSF	    RBIE
    BCF	    RBIF
    BSF	    T0IE		; Habilitamos interrupcion TMR0
    BCF	    T0IF		; Limpiamos bandera de TMR0
    RETURN
    
CONTADOR:
    INCF    CONT		; incrementamos el contadro del primer display
    MOVLW   50			; Como queremos que cambia cada segundo pasamos el valor literal de 50 a w (1000ms/20ms = 50 repeticiones)
    XORWF   CONT, W		; Llequeamos si el valor de CONT es igual a 50
    BTFSS   STATUS, 2		; Llequeamos si la bandera de cero esta activada
    RETURN

    CLRF    STATUS
    MOVF    CONT_2, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTD		; movemos el valor al puerto D
    
    INCF    CONT_2		; Incrementamos el contador del segundo display
				
    CLRW			; limpiamos W
    MOVLW   11			; Pasamos el valor literal del hexadecimal A
    XORWF   CONT_2, W		; chequeamos si el valor literal y el valor en Cont_2 son iguales
    BTFSC   STATUS, 2		; chequeamos la bandera del cero
    CALL    CONTADOR2		; Llamamaos la sub rutina del segundo display
	
    CLRW			; Limpiamos el valor en w
    CLRF    STATUS		; Limpiamos las banderas de STATUS
    MOVLW   4			; Movemos el valor de cuatro para que cada 60 segundos se reinicie el contador
    XORWF   CONT_3, W		; chequeamos si el valor literal y el valor en Cont_2 son iguales
    BTFSC   STATUS, 2		; chequeamos la bandera del cero
    CALL    RESET_60SEGUNDOS	; llamamos a la subrutina del reset cada 60 segundos
    
    CLRF    CONT		; limpiamoz el contador principal
    CLRF    STATUS		; Limpiamos las banderas del Status
    RETURN 
   
CONTADOR2:
    RESET_TMR0 100		; reseteamos el TMR0
    CLRF    CONT_2		; limpiamos el contador del segundo display
    
    MOVF    CONT_3, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC		; Movemos el valor de la tabla a PORTC
    INCF    CONT_3		; Incrementamos nuestro tercer contador
    
    BTFSC   CONT_3, 4		; Verificamos que el contador no sea menor a 15
    CLRF    CONT_3		; limpiamos cont3
    MOVF    CONT_3		; movemos el cero a cont3
    GOTO    CONTADOR		; regresamos a la subrutina principal
    
RESET_60SEGUNDOS:
    RESET_TMR0 100
    CLRF    CONT_2		; Limpiamos el segundo contador
    CLRF    CONT_3		; Limpiamos el tercer contador
    CLRF    CONT		; Limpiamos el primer contador
    RETURN			; regresamos al "loop" prinicipal
    
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
