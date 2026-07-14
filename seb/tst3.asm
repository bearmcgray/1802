
.equ RDST RF
.equ RPLUS RE
.equ RMASK RD

.equ ADST 0x130
.equ APLUS 0x133
.equ AMASK 0x134

.org 0x0

start:
	
	lda R0
.db LO(APLUS)
	plo RPLUS
	
	lda R0
.db HI(APLUS)
	phi RPLUS
	
	lda R0
.db 0x01
	str RPLUS
	
loop:
	sex RPLUS
	add
	b loop ;2d 2e
	