TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG	100H
START: JMP BEGIN

;данные

off_mem_	db 'Segment address of the first byte of inaccessible memory:     ',0DH,0AH,'$'
Seg_adr_ 	db 'Segmental address of the environment passed to the program:          ',0DH,0AH,'$'
TAIL_ 		db 'Command-line tail:    ','$'
SREDA_ 		db 'The contents of the environment area in the symbolic form: ',0DH,0AH,'$'
PATH_ 		db 'Load module path: ',0DH,0AH,'$'
ENDL 		db 0DH,0AH,'$'
SPC         db '	    ','$'		



Write PROC near
	mov AH,09h
	int 21h
	ret
Write ENDP

Write_info PROC near
		
	mov ax,es:[2]
	mov di,offset off_mem_
	add di, 62
	call WRD_TO_HEX
	mov dx,offset off_mem_
	call Write
	
	mov ax,es:[2Ch]
	mov di,offset Seg_adr_
	add di, 65
	call WRD_TO_HEX
	mov dx,offset Seg_adr_
	call Write
	
	mov dx,offset TAIL_
	call Write
	mov cx,0
	mov cl,es:[80h]
	cmp cl,0
	je TAIL_END
	mov dx,81h
	mov bx,0
	mov ah,02h
	TAIL_loop:
		mov dl,es:[bx+81h]
		int 21h
		inc	bx
	loop TAIL_loop

	TAIL_END:
		mov dx,offset ENDL
		call Write
		ret
Write_info ENDP

Write_sreda_path PROC near
	mov DX, OFFSET SREDA_
	call Write
	mov dx,offset SPC
	call Write
	xor SI, SI
	mov BX, ES:[2Ch]
	mov ES, BX
	mov AH, 02h
	
	env_loop:
		mov DL, ES:[SI]
		int 21h
		inc SI
		cmp WORD PTR ES:[SI], 0000h
		je gotopath
		cmp BYTE PTR ES:[SI], 00h
		je linenew
		jmp env_loop
		
	linenew:
		mov dx,offset ENDL
		call Write
		mov dx,offset SPC
		call Write
		mov AH, 02h
		inc SI
		jmp env_loop
	
	gotopath:
		mov dx,offset ENDL
		call Write
		add SI, 4
		mov DX, OFFSET PATH_
		call Write
		mov dx,offset SPC
		call Write
		mov AH, 02h
		
		path_loop:
			mov DL, ES:[SI]
			int 21h
			inc SI
			cmp BYTE PTR ES:[SI], 00h
			jne path_loop
	ret
Write_sreda_path ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шестн. числа в AX 
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP

; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

BEGIN:
	call Write_info
	call Write_sreda_path
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START