;---------------
; Assembly Code
;---------------

;------------------------
.Include "M328Pdef.inc"
			.Cseg
			.Org 0x0000 		;Location for reset  
			Jmp Main  

			.ORG 0x0002 		;Location for external interrupt 0  
			Jmp externalISR0
;================================================================
main:
	  Ldi R20,HIGH(RAMEND)  
	  Out SPH,R20  
	  Ldi R20,LOW(RAMEND)  
	  Out SPL,R20 		;Set up the stack  

	  Ldi R20,0x03 		;Make INT0 falling edge triggered  
	  Sts EICRA,R20		;External Interrupt Control Register A

	  Ldi R20,0x01		;Enable INT0 - 0b00000001
	  Out EIMSK,R20		;External Interrupt MaSK
	  sei 				;Enable global interrupt  

	  LDI R26, 48		;setup value to add for ASCII (0-9)

	  Sbi PORTD,2 		;Activated pull-up 
	  LDI	R16, (1<<SPE)
	  OUT	SPCR, R16		  ;enable SPI as slave
      LDI   R16, 0xFF
      OUT   DDRD, R16         ;set port D o/p for data
	  CBI	DDRD, 2			  ;set pin D2 as input for interrupt
      SBI	DDRB, 0
      SBI   DDRB, 1			  ;set pin 0 and 1 of port B o/p for command
	  SBI	DDRC, 5			  ;set output for fan
      CBI   PORTB, 0          ;EN = 0
      RCALL delay_ms          ;wait for LCD power on
      ;-----------------------------------------------------
      RCALL LCD_init          ;subroutine to initialize LCD
	  LDI R18, 0x01
      ;----------------------------------------------------
      LDI   R16, 0xC0         ;cursor beginning of 2nd line
      RCALL command_wrt       ;send command code
      RCALL delay_ms
	  JMP dht_agn

;================================================================
dht_agn:
	  CALL delay_seconds
	  ;------------
	  ;start_signal
	  ;------------
	  SBI   DDRC, 1       ;pin PB0 as o/p
	  CBI   PORTC, 1      ;first, send low pulse
	  RCALL delay_20ms    ;for 20ms
	  SBI   PORTC, 1      ;then send high pulse
	  ;-----------------------------------------------------------------
	  ;response signal
	  ;---------------
	  CBI   DDRC, 1       ;pin PC1 as i/p
  w1: SBIC  PINC, 1
  	  RJMP  w1            ;wait for DHT11 low pulse
  w2: SBIS  PINC, 1
	  RJMP  w2            ;wait for DHT11 high pulse
  w3: SBIC  PINC, 1
	  RJMP  w3            ;wait for DHT11 low pulse
	  ;-----------------------------------------------------------------
	  RCALL DHT11_reading ;read humidity (1st byte of 40-bit data) (unused)
	  RCALL DHT11_reading
	  RCALL DHT11_reading ;read temp (3rd byte of 40-bit data)

	  MOV	R25, R19
	  CP    R25, R24		  ;check for byte 0x1E
	  BRGE	turn_on      	  ;turn on fan
	  RCALL	turn_off		  ;turn off fan

done: MOV	R19, R24
	  CALL	convert
	  LDI   R16, 0xC0         ;cursor beginning of 2nd line
	  RCALL command_wrt       ;send command code

	  RJMP dht_agn
;================================================================
turn_on:
  SBI PORTC, 5			;set bit 5, turn on fan
  RJMP done
turn_off:
  CBI PORTC, 5			;clear bit 5, turn off fan
  RET
;================================================================
LCD_init:
      LDI   R16, 0x33         ;init LCD for 4-bit data
      RCALL command_wrt       ;send to command register
      RCALL delay_ms
      LDI   R16, 0x32         ;init LCD for 4-bit data
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x28         ;LCD 2 lines, 5x7 matrix
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x0C         ;disp ON, cursor OFF
      RCALL command_wrt
      LDI   R16, 0x01         ;clear LCD
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x06         ;shift cursor right
      RCALL command_wrt
      RET  
;================================================================
command_wrt:
      MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      CBI   PORTB, 1          ;RS = 0 for command
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      RET
;================================================================
data_wrt:
      MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 1          ;RS = 1 for data
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;make wide EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      RET
;================================================================
DHT11_reading:
      LDI   R17, 8        ;set counter for receiving 8 bits
      CLR   R19           ;clear data register
      ;-------------------------------------------------------
w4:   SBIS  PINC, 1
      RJMP  w4            ;detect data bit (high pulse)
      RCALL delay_timer0  ;wait 50us & then check bit value
      ;-------------------------------------------------------
      SBIS  PINC, 1       ;if received bit=1, skip next inst
      RJMP  skp           ;else, received bit=0, jump to skp
      SEC                 ;set carry flag (C=1)
      ROL   R19           ;shift in 1 into LSB data register
      RJMP  w5            ;jump & wait for low pulse
skp:  LSL   R19           ;shift in 0 into LSB data register
      ;-------------------------------------------------------
w5:   SBIC  PINC, 1
      RJMP  w5            ;wait for DHT11 low pulse
      ;-------------------------------------------------------
      DEC   R17           ;decrement counter
      BRNE  w4            ;go back & detect next bit
      RET                 ;return to calling subroutine
;===============================================================
convert:
	  MOV R28, R19 ;move R19 value to R28
	  CPI R19, 228 ;check if value is equal or above 228
	  BRSH above ;branch to solution for a bug at value above 227
	  CPI R28, 100 ;check if value is in the hundreds
	  BRMI tens ;if not branch to tens
	  LDI R29, 100
	  CALL div ;get the hundreds digit via division
	  ADD R16, R26 ;ASCII conversion
	  CALL data_wrt ;print hundreds digit
	  RCALL delay_ms
	  CPI R28, 10
	  BRMI zero ;branch to solution for bug at 10x or 20x value
tens:
	  CPI R28, 10 ;check if value is in the hundreds
	  BRMI ones ;if not then branch to ones
	  LDI R29, 10
	  CALL div ;get the tens digit via division
	  ADD R16, R26 ;ASCII conversion
	  CALL data_wrt ;print tens digit
	  RCALL delay_ms
ones:
	  MOV R16, R28 ;prints the leftover value of division
	  ADD R16, R26 ;as the value for the ones digit
	  CALL data_wrt
	  RCALL delay_ms
	  RET
zero: ;solution for bug at 10x or 20x value
	  LDI R16, 48 ;prints the tens digit as zero
	  CALL data_wrt
	  RCALL delay_ms
      RJMP ones
above: ;solution for a bug at value above 227
	  LDI R16, 50 ;ignore the hundreds
	  CALL data_wrt ;and prints the hundreds digit as '2'
	  RCALL delay_ms
	  SUBI R28, 200 ;get the tens digit via subtraction
	  RJMP tens ;branch to print the tens digit
;===============================================================
div:
	  ;---------------------;numerator = value of R28
	  ;---------------------;denominator = R29
	  CLR R16 ;initialize quotient to 0
ldiv:   CP R28, R29 ;subtract (num - denom) &
	  BRMI donediv ;exit loop when -ve
	  INC R16 ;increment quotient by 1
	  SUB R28, R29 ;num = num - denom
	  RJMP ldiv ;loop & do another subtraction
donediv: RET

delay_short:
      NOP
      NOP
      RET
;------------------------
delay_us:
      LDI   R20, 90
l3:   RCALL delay_short
      DEC   R20
      BRNE  l3
      RET
;-----------------------
delay_ms:
      LDI   R21, 40
l4:   RCALL delay_us
      DEC   R21
      BRNE  l4
      RET
delay_20ms:             ;delay 20ms
      LDI   R21, 255
l32:  LDI   R22, 210
l42:  LDI   R23, 2
l52:  DEC   R23
      BRNE  l52
      DEC   R22
      BRNE  l42
      DEC   R21
      BRNE  l32
      RET
delay_timer0:             ;50 usec delay via Timer 0
      ;---------------------------------------------------------
      CLR   R20
      OUT   TCNT0, R20      ;initialize timer0 with count=0
      LDI   R20, 100
      OUT   OCR0A, R20      ;OCR0 = 100
      LDI   R20, 0b00001010
      OUT   TCCR0B, R20     ;timer0: CTC mode, prescaler 8
      ;---------------------------------------------------------
l22:   IN    R20, TIFR0      ;get TIFR0 byte & check
      SBRS  R20, OCF0A      ;if OCF0=1, skip next instruction
      RJMP  l22              ;else, loop back & check OCF0 flag
      ;---------------------------------------------------------
      CLR   R20
      OUT   TCCR0B, R20     ;stop timer0
      ;---------------------------------------------------------
      LDI   R20, (1<<OCF0A)
      OUT   TIFR0, R20      ;clear OCF0 flag
      RET
;================================================================
delay_seconds:        ;nested loop subroutine (max delay 3.11s)
    LDI   R20, 255    ;outer loop counter 
l5: LDI   R21, 255    ;mid loop counter
l6: LDI   R22, 20     ;inner loop counter to give 0.25s delay
l7: DEC   R22         ;decrement inner loop
    BRNE  l7          ;loop if not zero
    DEC   R21         ;decrement mid loop
    BRNE  l6          ;loop if not zero
    DEC   R20         ;decrement outer loop
    BRNE  l5          ;loop if not zero
    RET               ;return to caller
;================================================================
externalISR0:
	IN	R16, SPSR
    SBRS  R16, SPIF       ;wait for byte reception
    RJMP  externalISR0    ;to complete
	IN    R24, SPDR       ;i/p byte from data register
	Reti