; ------------------------------------------------------------------[08.05.2017]
; DivGMX Test By MVV <mvvproject@gmail.com>
; -----------------------------------------------------------------------------

	DEVICE	ZXSPECTRUM48

osd_buffer	equ #0c00	; OSD buffer start address
osd_buffer_size	equ 1024
stack_top	equ #0bfe


	org #0000
startprog:
	di
	ld sp,stack_top
	ld iy,list
	call cls		; очистка OSD буфера

	ld hl,menu
	call print_str		; печать в OSD буфер

q0

	ld bc,#0001		;#7ffd
	in a,(c)
	ld hl,#010c
	ld (iy+0),h		;y
	ld (iy+1),l		;x
	call print_hex

	ld bc,#0101		;#xxfe
	in a,(c)
	ld (iy+1),#14		;x
	call print_hex

	ld bc,#0e01		;pc
	in a,(c)
	ld (iy+1),#1a		;x
	call print_hex
	ld bc,#0f01		;pc
	in a,(c)
	call print_hex

	ld bc,#0d01
	in a,(c)
	ld (iy+1),#23		;x	
	bit 4,a			;ROM:Std/On
	ld hl,str_std
	jr z,q2
	ld hl,str_on
q2
	call print_str

	ld bc,#0d01
	in a,(c)
	ld (iy+1),#2b		;x	
	bit 5,a			;KBD:Std/USB
	ld hl,str_std
	jr z,q3
	ld hl,str_usb
q3
	call print_str

	ld bc,#0d01		;
	in a,(c)
	ld (iy+1),#33		;x
	bit 3,a			;BDI:0/1
	ld a,"0"
	jr z,q5
	inc a
q5
	call print_char

	ld bc,#0801		;#xxe3
	in a,(c)
	ld hl,#020c
	ld (iy+0),h		;y
	ld (iy+1),l		;x
	call print_hex

	ld bc,#0d01		;
	in a,(c)
	ld (iy+1),#14		;x
	bit 7,a			;AMAP:0/1
	ld a,"0"
	jr z,q1
	inc a
q1
	call print_char

	ld bc,#0d01
	in a,(c)
	ld (iy+1),#16		;x	
	bit 6,a			;DivMMC:on/off
	ld hl,str_off
	jr z,q4
	ld hl,str_on
q4
	call print_str

	ld bc,#0201		;#fadf
	in a,(c)
	ld (iy+1),39		;x
	call print_hex

	ld bc,#0301		;#fbdf
	in a,(c)
	ld (iy+1),47		;x
	call print_hex

	ld bc,#0401		;#ffdf
	in a,(c)
	ld (iy+1),55		;x
	call print_hex

	ld bc,#0501		;#xadf
	in a,(c)
	ld (iy+1),71		;x
	call print_hex

	ld bc,#0601		;#xbdf
	in a,(c)
	ld (iy+1),79		;x
	call print_hex

	ld bc,#0701		;#xfdf
	in a,(c)
	ld (iy+1),87		;x
	call print_hex



	ld bc,#0901		;#0f
	in a,(c)
	ld (iy+1),104		;x
	call print_hex

	ld bc,#0a01		;#1f
	in a,(c)
	ld (iy+1),110		;x
	call print_hex

	ld bc,#0b01		;#4f
	in a,(c)
	ld (iy+1),116		;x
	call print_hex

	ld bc,#0c01		;#5f
	in a,(c)
	ld (iy+1),125		;x
	call print_hex

	jp q0



; -----------------------------------------------------------------------------
; clear OSD buffer
; -----------------------------------------------------------------------------
cls
	ld hl,osd_buffer
	ld a,#10
cls1
	ld (hl)," "
	inc hl
	cp h
	jr nz,cls1
	ret

; -----------------------------------------------------------------------------
; print string i: hl - pointer to string zero-terminated
; -----------------------------------------------------------------------------
print_str
	ld a,(hl)
	cp 23
	jr z,print_pos_xy
	cp 24
	jr z,print_pos_x
	cp 25
	jr z,print_pos_y
	inc hl
	or a
	ret z
	call print_char
	jr print_str
print_pos_xy
	inc hl
	ld a,(hl)
	ld (iy+1),a		; x-coord
	inc hl
	ld a,(hl)
	ld (iy+0),a		; y-coord
	inc hl
	jr print_str
print_pos_x
	inc hl
	ld a,(hl)
	ld (iy+1),a		; x-coord
	inc hl
	jr print_str
print_pos_y
	inc hl
	ld a,(hl)
	ld (iy+0),a		; y-coord
	inc hl
	jr print_str

; -----------------------------------------------------------------------------
; print character i: a - ansi char
; -----------------------------------------------------------------------------
print_char
	push hl
	push bc
	cp 13
	jr z,pchar2

	ld h,high osd_buffer	; osd_buffer
	ld l,(iy+1)		; x
	ld b,(iy+0)		; y
	ld c,0
	rrc b
	rr c
	add hl,bc

	ld (hl),a
	ld a,(iy+1)		; x
	inc a
	cp 128
	jr c,pchar1
pchar2
	ld a,(iy+0)		; y
	inc a
	cp 8
	jr c,pchar0
	xor a
pchar0
	ld (iy+0),a
	xor a
pchar1
	ld (iy+1),a
	pop bc
	pop hl
	ret

; -----------------------------------------------------------------------------
; print hexadecimal i: a - 8 bit number
; -----------------------------------------------------------------------------
print_hex
	ld e,a
	and $f0
	rrca
	rrca
	rrca
	rrca
	call hex2
	ld a,e
	and $0f
hex2
	cp 10
	jr nc,hex1
	add 48
	jp print_char
hex1
	add 55
	jp print_char

; -----------------------------------------------------------------------------
; print decimal i: l,d,e - 24 bit number , e - low byte
; -----------------------------------------------------------------------------
print_dec
	ld ix,dectb_w
	ld b,8
	ld h,0
lp_pdw1
	ld c,"0"-1
lp_pdw2
	inc c
	ld a,e
	sub (ix+0)
	ld e,a
	ld a,d
	sbc (ix+1)
	ld d,a
	ld a,l
	sbc (ix+2)
	ld l,a
	jr nc,lp_pdw2
	ld a,e
	add (ix+0)
	ld e,a
	ld a,d
	adc (ix+1)
	ld d,a
	ld a,l
	adc (ix+2)
	ld l,a
	inc ix
	inc ix
	inc ix
	ld a,h
	or a
	jr nz,prd3
	ld a,c
	cp "0"
	ld a," "
	jr z,prd4
prd3
	ld a,c
	ld h,1
prd4
	call print_char
	djnz lp_pdw1
	ret
dectb_w
	db #80,#96,#98		; 10000000 decimal
	db #40,#42,#0f		; 1000000
	db #a0,#86,#01		; 100000
	db #10,#27,0		; 10000
	db #e8,#03,0		; 1000
	db 100,0,0		; 100
	db 10,0,0		; 10
	db 1,0,0		; 1



; -----------------------------------------------------------------------------
; управляющие коды
; 13 (0x0d)		- след строка
; 23 (0x17),x,y		- изменить позицию на координаты x,y
; 24 (0x18),x		- изменить позицию по x
; 25 (0x19),y		- изменить позицию по y
; 0			- конец строки

; x(0-127),y(0-7)

menu
	db 23,0,0
;	db "--------------------------------------------------------------------------------------------------------------------------------"

	db "Board:DivGMX(Ultimate) SoftCore:Basic(build 20170508 By MVV) "
	db "F1=OSD(nZ80@40MHz,RAM 4K,F5=Std/ROM,F6=ZC/DivMMC,F7=Std/USBKeyb)",13
	db "System[7FFD:00 xxFE:00 PC:0000 ROM:Std KBD:Std BDI:0]",13
	db "DivMMC[xxE3:00 AMAP:0 On ] Mouse0[FADF:00 FBDF:00 FFDF:00] "
	db "Mouse1[xADF:00 xBDF:00 xFFD:00] SounDrive[0F:00 1F:00 4F:00 5F/FB:00]",0
str_off
	db "Off",0
str_on
	db "On ",0
str_usb
	db "USB",0
str_std
	db "Std",0
list
	db 0,0,0,0,0,0,0,0,0

;	org #0c00
;	db "--------------------------------------------------------------------------------------------------------------------------------"
;	db "DivGMX[Rev.A Ultimate] SoftCore[Basic(build 20170112) By MVV] OSD[CPU:NZ80@28MHz RAM:4K F5=Std/ROM F6=ZC/DivMMC F7=Std/USBKeyb]                              "
;	db "System [7FFD:00 xxFE:00 1FFD:00]                                                                                                "
;	db "DivMMC [xxE3:00 xxE7:00 AMAP:0 ]-----------------------------------------------------------------------------------------------4"
;	db "Mouse0   [FADF:00 FBDF:00 FFDF:00]                                                                                              "
;	db "Mouse1   [0ADF:00 0BDF:00 0FFD:00]                                                                          -------------------6"
;	db "SounDrive[xx0F:00 xx1F:00 xx4F:00 xx5F:00 xxFB:00]-----------------------------------------------------------------------------3"
;	db "Addr:0000----------------------------------------------------------------------------------------------------------------------2"
;	db "6------------------------------------------------------------------------------------------------------------------------------1"
;	db "7------------------------------------------------------------------------------------------------------------------------------0"

; -----------------------------------------------------------------------------

	display "Code start: ",/a, startprog, " end: ",/a, $-1
	display "OSD buffer start: ",/a, osd_buffer, " end: ",/a, osd_buffer + osd_buffer_size - 1

	savebin "test.bin",startprog, 4096
