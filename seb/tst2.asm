.equ RPC R3

.equ RDST RF
.equ RPLUS RE
.equ RMASK RD

.equ ADST 0x130
.equ APLUS 0x133
.equ AMASK 0x134

.org 0x0

start:
;init other pc
.db 0xf8
	lda R0
.db LO(main)
	plo RPC
	
	lda R0
.db HI(main)
	phi RPC
	
	sep RPC
	
.org 0x8
main:
;init dst
	lda RPC
.db LO(ADST)
	plo RDST
	
	lda RPC
.db HI(ADST)
	phi RDST
	
	lda RPC
.db 0x00
	str RDST
	
;init plus	
	lda RPC
.db LO(APLUS)
	plo RPLUS
	
	lda RPC
.db HI(APLUS)
	phi RPLUS
	
	lda RPC
.db 0x03
	str RPLUS

;init plus	
	lda RPC
.db LO(AMASK)
	plo RMASK
	
	lda RPC
.db HI(AMASK)
	phi RMASK
	
	lda RPC
.db 0x10
	str RMASK

	b loop
	
.org 0x28	
loop:
	
	sex RDST;20
	ldx;21
	
	sex RPLUS;22
	add;23
	str RDST;24

	sex RMASK;25
	and;26
	
	beq loop;27 28
	
	sex RDST ;29
	ldx;2a
	shr;2b
	shr;2b
	
	str RDST ;2c
	
	b loop ;2d 2e
	