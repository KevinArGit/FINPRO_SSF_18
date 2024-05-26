#line 1 "C:\\Users\\WINDOWS\\OneDrive\\Documents\\Arduino\\finpro_2\\finpro_2.S"
;------------------------
; Assembly Code
;------------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main
;===============================================================
main:
;-------------
.equ  SCK, 5
.equ  MOSI, 3
.equ  SS, 2
.equ  INT, 0
;--------------------------------------------------------------
    LDI   R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
    OUT   DDRB, R17       ;set MOSI, SCK, SS as o/p
    ;SBI   DDRC, 0         ;set pin C0 as interrupt o/p
    ;--------------------------------------------------------
    LDI   R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
    OUT   SPCR, R17       ;enable SPI as master, fsck=fosc/16
    ;--------------------------------------------------------
    LDI   R24, 0x00       ;initial value
    LDI   R25, 0x00       ;initial value
;===============================================================
;keypad
;---------------------------------------------------------------
    LDI   R21, 0xFF
    OUT   DDRB, R21
    LDI   R20, 0b11111000 ;low nibble port D i/p (column lines)
    OUT   DDRD, R20       ;high nibble port D o/p (row lines)
    ;-----------------------------------------------------------
gnd_rows:
    LDI   R20, 0x0F       ;send 0 to high nibble port D
    OUT   PORTD, R20      ;to ground all rows
    ;-----------------------------------------------------------
wait_release:
    NOP
    IN    R21, PIND       ;read key pins
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no keypress
    BRNE  wait_release    ;do again until keys released
    ;-----------------------------------------------------------
wait_keypress:
    NOP
    IN    R21, PIND       ;read key pins
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no keypress
    BREQ  wait_keypress   ;keypress? no, go back & check
    ;-----------------------------------------------------------
    RCALL my_delay        ;delay to cancel switch bounce
    ;-----------------------------------------------------------
    IN    R21, PIND       ;2nd check for keypress
    ANDI  R21, 0x07       ;which ensures that 1st keypress
    CPI   R21, 0x07       ;was not erroneous due to spike noise
    BREQ  wait_keypress 
    ;-----------------------------------------------------------
    LDI   R21, 0b01111111 ;ground row 1
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row1_col        ;row 1, find column
    ;-----------------------------------------------------------
    LDI   R21, 0b10111111 ;ground row 2
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row2_col        ;row 2, find column
    ;-----------------------------------------------------------
    LDI   R21, 0b11011111 ;ground row 3
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row3_col        ;row 3, find column
    ;-----------------------------------------------------------
    LDI   R21, 0b11101111 ;ground row 4
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row4_col        ;row 4, find column
;---------------------------------------------------------------
row1_col:
    LDI   R30, lo8(row1_digits)
    LDI   R31, hi8(row1_digits)
    RJMP  find
row2_col:
    LDI   R30, lo8(row2_digits)
    LDI   R31, hi8(row2_digits)
    RJMP  find
row3_col:
    LDI   R30, lo8(row3_digits)
    LDI   R31, hi8(row3_digits)
    RJMP  find
row4_col:
    LDI   R30, lo8(row4_digits)
    LDI   R31, hi8(row4_digits)
    RJMP  find
;---------------------------------------------------------------
find:
    LSR   R21           ;logical shift right
    BRCC  match
    LPM   R20, Z+
    RJMP  find
match:
    LPM   R20, Z

    CPI   R20, 10         ;if * pressed, clear register
    BREQ  clear
    CPI   R20, 15         ;if # pressed, send data
    BREQ  send

    LDI   R17, 10
    MUL   R25, R17
    MOV   R25, R20
    MOV   R24, R0
    ADD   R24, R20        ;multiply previous digit by 10 and add new digit
    CLR   R0
    CLR   R1
    RJMP  gnd_rows
send:
    ;SBI   PORTC, 0        ;enable interrupt
    CBI   PORTB, SS       ;enable slave device
    OUT   SPDR, R24       ;transmit byte to slave
    ;--------------------------------------------------------
loop: IN    R18, SPSR
    SBRS  R18, SPIF       ;wait for byte transmission
    RJMP  loop            ;to complete
    ;--------------------------------------------------------
    SBI   PORTB, SS       ;disable slave device
    ;CBI   PORTC, 0        ;clear interrupt
    RJMP  gnd_rows
clear:
    LDI   R21, 0x00       ;clear R21
    RJMP  gnd_rows
;---------------------------------------------------------------
row1_digits: .byte  1,2,3
row2_digits: .byte  4,5,6
row3_digits: .byte  7,8,9
row4_digits: .byte  10,0,15 ;* for clear, # for enter
;===============================================================
my_delay:
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 10
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET