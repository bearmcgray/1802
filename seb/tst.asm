
.equ TMP RF

.org 0x0

;main begins here
start:
	;glo R0
	lda R0 ; 0
.db 0x30 ;1
	plo TMP  ;2
	lda R0 ;3
.db 0x01 ;4
	phi TMP ;5
	lda R0 ;6
.db 0x01 ;7
	sex TMP   ;     8       haha
	str TMP  ; 9
	b loop ;a b
	
.org 0x10	
loop:
	add ;10
	b loop;loop there ;11 12
	