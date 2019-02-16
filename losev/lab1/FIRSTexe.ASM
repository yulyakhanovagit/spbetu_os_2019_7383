;------------------------
AStack SEGMENT STACK
DW 12 DUP(?)
AStack ENDS

DATA SEGMENT
		; ДАННЫЕ

		PC_OTHER DB '  ', 0DH, 0AH, '$'
		PC_TYPE DB 'TYPE IBM PC: $'
		PC_PC DB 'PC.', 0DH, 0AH, '$'
		PC_XT DB 'PC/XT.', 0DH, 0AH, '$'
		PC_AT DB 'AT.', 0DH, 0AH, '$'
		PC_PS2M30 DB 'PS2 m.30.', 0DH, 0AH, '$'
		PC_PS2M60 DB 'PS2 m.50/60.', 0DH, 0AH, '$'
		PC_PS2M80 DB 'PS2 m.80.', 0DH, 0AH, '$'
		PC_CON DB 'PC CONVERTIBLE.', 0DH, 0AH, '$'
		PC_JR DB 'PC JR.', 0DH, 0AH, '$'

		DOS_VER	DB	'DOS VERSION: '
		DOS_F	DB	1 dup(?), '.'				; 1 цифра
		END_DOS_VER DB 2 dup(?), 0AH, 0DH, '$'	; до двух цифр
		OEM	DB	'OEM: ', 1 dup(?)				; всего 2 символа				
		OEMEND DB 1 dup(?), 0AH, 0DH,'$'		; для 1 байта
		USERN	DB	'USER NUMBER: ', 5 dup(?)	; всего 6 символов
		USRNEND DB 1 dup(?), '$'		; для 3 байт

DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack

; ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near 
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
NEXT:
		add AL,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
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
;-------------------------------
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
;--------------------------------------------------

BYTE_TO_DEC PROC near
		push CX
		push DX
		xor AH,AH
		xor DX,DX
		mov CX,10
loop_bd: div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_bd
		cmp AL,00h
		je end_l
		or AL,30h
		mov [SI],AL
end_l: 	pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP 


OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
		push ax
		mov ah, 09h
	    int 21h
	    pop ax
	    ret
OUTPUT_PROC ENDP


Main PROC FAR
	push DS
	sub AX,AX
	push AX
	mov AX,DATA
	mov DS,AX

	mov bx, 0f000h
		mov AL, bx[0fffeh] 			; получили тип pc
		
		lea		dx, PC_TYPE
		call	OUTPUT_PROC	
		
		lea	dx, PC_PC
		cmp AL, 0FFh
		je	output
	
		lea	dx, PC_XT		; здесь два варианта 
		cmp AL, 0FEh
		je	output
		cmp AL, 0FBh
		je	output
		
		lea	dx, PC_AT
		cmp AL, 0FCh
		je	output
	
		lea	dx, PC_PS2M30
		cmp AL, 0FAh
		je	output

		lea	dx, PC_PS2M60
		cmp AL, 0FCh
		je	output
	
		lea	dx, PC_PS2M80
		cmp AL, 0F8h
		je	output
	
		lea	dx, PC_JR
		cmp AL, 0FDh
		je	output

		lea	dx, PC_CON
		cmp AL, 0F9h
		je	output
		
		call BYTE_TO_HEX		; получили символьное представление кода типа pc
		LEA di, PC_OTHER
		mov [di], ax
		LEA DX, PC_OTHER
	
output:
		call	OUTPUT_PROC
	
		MOV	AH,30H				; выясняем версию DOS, OEM, номер пользователя 
		INT	21H
		
		LEA si, DOS_F; 	; BYTE_TO_DEC не залезет в байт, предшествующий началу
		call BYTE_TO_DEC		; строки DOS_F, потому что последняя версия DOS была 8
		
		mov al, ah				; номер модификации версии
		LEA si, END_DOS_VER
		call BYTE_TO_DEC
		LEA dx, DOS_VER;
		call	OUTPUT_PROC
		
		mov al, bh				; OEM
		call BYTE_TO_HEX
		LEA di,  OEMEND
		mov [di-1], ax
		LEA dx, OEM;
		call	OUTPUT_PROC
		
		mov ax, cx				; номер пользователя
		LEA di,  USRNEND
		call WRD_TO_HEX
		mov al, bl				
		call BYTE_TO_HEX
		mov [di-2], ax

		LEA dx, USERN	
		call	OUTPUT_PROC

	ret
Main ENDP

CODE ENDS

END Main