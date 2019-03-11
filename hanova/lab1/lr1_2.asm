STACK SEGMENT STACK
	DW 0100H DUP(?)
STACK ENDS

DATA SEGMENT
; ДАННЫЕ
OS db 'Type OS: $'
OS_VERS db 'Version OS:   .  ',0DH,0AH,'$'
OS_OEM db 'OEM:    ',0DH,0AH,'$'
SER_NUM db 'Serial number: ','$'
STRING db '    $'
ENDSTR db 0DH,0AH,'$'

PC db 'PC',0DH,0AH,'$'
PCXT db 'PC/XT',0DH,0AH,'$'
_AT db 'AT',0DH,0AH,'$'
PS2_30 db 'PS2 model 30',0DH,0AH,'$'
PS2_80 db 'PS2 model 80',0DH,0AH,'$'
PCjr db 'PCjr',0DH,0AH,'$'
PC_Cnv db 'PC Convertible',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:STACK
Write PROC near
	mov AH,09h
	int 21h
	ret
Write ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

System PROC near
	mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh
	ret
System ENDP

Write_system PROC near
	mov dx, OFFSET OS
	call Write
	call System

	cmp al,0FFh
	je PC_mtk
	cmp al,0FEh
	je PCXT_mtk
	cmp al,0FBh
	je PCXT_mtk
	cmp al,0FCh
	je AT_mtk
	cmp al,0FAh
	je PS2_30_mtk
	cmp al,0F8h
	je PS2_80_mtk
	cmp al,0FDh
	je PCjr_mtk
	cmp al,0F9h
	je PC_Cnv_mtk

	PC_mtk:
		mov dx, OFFSET PC
		jmp to_write
	PCXT_mtk:
		mov dx, OFFSET PCXT
		jmp to_write
	AT_mtk:
		mov dx, OFFSET _AT
		jmp to_write
	PS2_30_mtk:
		mov dx, OFFSET PS2_30
		jmp to_write
	PS2_80_mtk:
		mov dx, OFFSET PS2_80
		jmp to_write
	PCjr_mtk:
		mov dx, OFFSET PCjr
		jmp to_write
	PC_Cnv_mtk:
		mov dx, OFFSET PC_Cnv
		

	to_write:
	call Write
	ret
Write_system ENDP

Ver_OS PROC near
	mov ax,0
	mov ah,30h
	int 21h

	mov si,offset OS_VERS
	add si,12
	push ax
	call BYTE_TO_DEC

	pop ax
	mov al,ah
	add si,3
	call BYTE_TO_DEC

	mov dx,offset OS_VERS
	call Write
	ret
Ver_OS ENDP

Write_oem PROC near
	mov ax,0
	mov ah,30h
	int 21h

	mov si,offset OS_OEM
	add si,7
	mov al,bh
	call BYTE_TO_DEC

	mov dx,offset OS_OEM
	call Write
	ret
Write_oem ENDP

Num_of_serial PROC near

	mov dx,offset SER_NUM
	call Write
	mov  al,bl
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl,bh
	int 21h
	mov di,offset STRING
	add di,3
	mov ax,cx
	call WRD_TO_HEX
	mov dx,offset STRING
	call Write

	mov dx,offset ENDSTR
	call Write

	ret
Num_of_serial ENDP

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
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

BEGIN:
	mov ax,DATA
	mov ds,ax
	call Write_system
	call Ver_OS
	call Num_of_serial
	call Write_oem
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
 END BEGIN