 TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG	100H
START: JMP BEGIN

Av_mem_	    db 'Amount of available memory:               ',0DH,0AH,'$'
Ex_mem_ 	db 'Extended memory size:           ',0DH,0AH,'$'
Ch_MCB_ 	db 'Chain of MCB:    ',0DH,0AH,'$'
Ch_MCB_STR 	db 'Adress  Type MCB  Address PSP    Size    SC/SD',0DH,0AH,'$'
ENDL 		db 0DH,0AH,'$'
SPC         db '                                         $'	
sz          db 0


Write PROC near
	mov ah,09h
	int 21h
	ret
Write ENDP

Avail_mem PROC
	mov ax,0
	mov ah,4Ah
	mov bx,0FFFFh 
	int 21h
	mov ax,10h 
	mul bx 
	mov si,offset Av_mem_+33
	call BYTE_TO_DEC
	mov dx, offset Av_mem_
	call Write
		mov ah,4ah
		mov bx,offset sz
		int 21h
	ret
Avail_mem ENDP

Extended_mem PROC near
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov bh,al
	
	mov ax,bx
	mov dx,0
	mov si,offset Ex_mem_+25
	call BYTE_TO_DEC
	mov dx,offset Ex_mem_
	call Write
	
	ret
Extended_mem ENDP

Chain_MCB PROC near
	mov dx,offset Ch_MCB_
	call Write
	mov dx,offset Ch_MCB_STR
	call Write
		push es
	mov ah,52h
	int 21h
	mov bx,es:[bx-2]
	mov es,bx
	Str_Chain:
		mov ax,es
		mov di,offset SPC+4
		call WRD_TO_HEX
		xor ah,ah
		mov al,es:[00h]
		mov di,offset SPC+13
		call WRD_TO_HEX
		mov ax,es:[01h]
		mov di,offset SPC+24
		call WRD_TO_HEX
		mov ax,es:[03h]
		mov si,offset SPC+36
		mov dx, 0
		mov bx, 10h
		mul bx
		call BYTE_TO_DEC
		mov dx,offset SPC
		call Write
		mov cx,8
		mov bx,8
		mov ah,02h
		Str_Chain2:
			mov dl,es:[bx]
			add bx,1
			int 21h
		loop Str_Chain2
		mov dx,offset ENDL
		call Write
		mov ax,es
		add ax,1
		add ax,es:[03h]
		mov bl,es:[00h]
		mov es,ax
		
		push bx
		mov bx,offset SPC+42
		mov [bx+19],ax
		mov [bx+21],ax
		mov [bx+23],ax
		pop bx

		cmp bl,4Dh
		je Str_Chain
	pop es
	ret
Chain_MCB ENDP
	
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

; перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	;xor AH,AH
	;xor DX,DX
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
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

BEGIN:
	call Avail_mem
	call Extended_mem
	call Chain_MCB
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START