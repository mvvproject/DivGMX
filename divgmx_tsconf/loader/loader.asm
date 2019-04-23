 		DEVICE	ZXSPECTRUM48
; -----------------------------------------------------------------[06.05.2018]
; ReVerSE-U16 Loader (build 20180506) By MVV
; -----------------------------------------------------------------------------

system_port	equ #0001	; bit2 = 0:Loader ON, 1:Loader OFF; bit0 = 0:w25q64fv, 1:cd card
pr_param	equ #7f00
page3init	equ #7f04
cursor_pos	equ #7f05
block_16kB_cnt	equ #7f06
buffer		equ #8000
time_pos_y	equ #0a
time_pos_yx	equ #0a00
TOTAL_PAGE	equ 32

	org #0000
startprog:
	di
	ld sp,#7ffe
	xor a
	ld bc,system_port
	out (c),a
	out (#fe),a		; ���� �������
	call cls		; ������� ������
	ld hl,str1
	call print_str

; -----------------------------------------------------------------------------
; SD Loader
; -----------------------------------------------------------------------------
	ld sp,PWA
	ld bc,SYC
	ld a,DEFREQ
	out(c),a		;SET DEFREQ:%00000010-14MHz
	;PAGE3
	ld b,PW3/256
	in a,(c)		;READ PAGE3 //PW3:#13AF
	ld (page3init),a	;(page3init) <- SAVE orig PAGE3
	;PAGE2
	ld b,PW2/256
	in a,(c)		;READ PAGE2 //PW2:#12AF 
	ld e,PG0
	out (c),e		;SET PAGE2=0xF7
	ld (PGR),a		;(PGR) <- SAVE orig PAGE2
	;step_1: INIT SD CARD
	ld a,#00 		;STREAM: SD_INIT, HDD
	call FAT_DRV
	jr nz,ERR		;INIT - FAILED
	;step_2: find DIR entry
	ld hl,FES1
	ld a,#01 		;find DIR entry
	call FAT_DRV
	jr nz,ERR		;dir not found
	ld a,#02		;SET CURR DIR - ACTIVE
	call FAT_DRV
	;step_3: find File entry
	ld hl,FES2
	ld a,#01		;find File entry
	call FAT_DRV
	jr nz,ERR		;file not  found
	;step_4: download data
	ld a,#00		;#0 - start page 

	; Open 1st Page = ROM
	ld (block_16kB_cnt),a	;RESTORE block_16kB_cnt 
	ld c,a			;page Number
	ld de,#0000		;offset in PAGE: 
  	ld b,32			;1 block-512Byte/32bloks-16kB
	ld a,#03		;code 3: LOAD512(TSFAT.ASM) c
	call FAT_DRV		;return CDE - Address 

LOAD_16kb
	;Open 2snd Page = ROM 
	ld a,(block_16kB_cnt)	;��������� ������ �������� ������� � A
	inc a			;lock_16kB_cnt+1  ����������� �������� �� 1 
	ld (block_16kB_cnt),a	;��������� ����� ��������
	ld c,a			;page 
	ld de,#0000		;offset in Win3: 
	ld b,32			;1 block-512Byte // 32- 16kB
	;load data from opened file
	ld a,#03		;LOAD512(TSFAT.ASM) 
	call FAT_DRV		;������ ������ 16kB
	jr nz,RTC_INIT		;EOF -EXIT
	;CHECK CNT
	ld a,(block_16kB_cnt)	;��������� ������ �������� ������� � A
	sub TOTAL_PAGE		;��������� ��� ��� ��������� ���� ��� ���
	jr nz,LOAD_16kb		;���� �� �� �����, ���� ��� �� ������� �� 
	jr RTC_INIT
ERR
	ld sp,#7ffe
	ld hl,str_error
	call print_str

	ld a,%00000001
	ld bc,system_port
	out (c),a
; ID read
	ld hl,str8
	call print_str

	call spi_start
	ld d,%10101011	; command ID read
	call spi_w
	call spi_r
	call spi_r
	call spi_r
	call spi_r
	call print_hex
	call spi_end

	ld hl,str5
	call print_str

; 0CC000 evo.rom    512K
; -----------------------------------------------------------------------------
; SPI autoloader
; -----------------------------------------------------------------------------
	call spi_start
	ld d,%00000011	; command = read
	call spi_w

	ld d,#0c	; address = #0cc000
	call spi_w
	ld d,#c0
	call spi_w
	ld d,#00
	call spi_w

	xor a
spi_loader3
	ld bc,#13af
	out (c),a
	ld hl,#c000
	ld e,a
spi_loader2
	call spi_r
	ld (hl),a
	inc hl
	ld a,l
	or h
	jr nz,spi_loader2
	ld a,e
	call print_hex
	ld a,26
	ld (pr_param),a
	ld a,e
	inc a
	cp 32
	jr c,spi_loader3
	call spi_end

;----------------------------------------------
RTC_INIT
	ld sp,#7ffe

	ld a,(page3init)
	ld bc,#13af
	out (c),a
	
	xor a
	out (#fe),a

	ld hl,str3		;���������
	call print_str
	
	ld hl,str4
	call print_str
	call rtc_read

	ld hl,str_error		; ����������� ����������
	jr z,spi_loader4
	ld hl,str3		; ���������
spi_loader4
	call print_str

	call rtc_data
	call ddc_read

;	ld hl,str7
;	call print_str
;	call mac_read

	ld hl,str0		; any key
	call print_str

	call anykey
	call mc14818a_init	;������������� MC14818A
	
	ld a,%00000100
	ld bc,system_port
	out (c),a

	ld sp,#ffff
	jp #0000		; ������ �������

; �������� �������
anykey1
	ld hl,str0
	call print_str
	ld bc,system_port
anykey2
	in a,(c)		; ������ �������� ����������
	cp #ff
	jr nz,anykey2
anykey
	ld hl,time_pos_yx	; ���������� ������ ���� � �������
	ld (pr_param),hl
	call rtc_read		; ������ ���� � �������
	call rtc_data		; �����
	ld bc,system_port
	in a,(c)		; ������ �������� ����������
	cp #1b			; <S> ?
	jp z,rtc_setup
	cp #5a			; <ENTER> ?
	jr nz,anykey
	ret

; -----------------------------------------------------------------------------
; I2C DS1338 read
; -----------------------------------------------------------------------------
rtc_read
	ld bc,#3f00
	ld hl,buffer
	ld d,%11010001		; Device Address RTC DS1338 + read
	call i2c

	ld b,#3f
; ��������
; z=error, nz=ok
check_buffer
	ld hl,buffer
check_buffer1
	ld a,(hl)
	inc a
	ret nz
	ld (hl),a
	inc hl
	djnz check_buffer1
	ret
	
; -----------------------------------------------------------------------------
; ������������� MC14818A
; -----------------------------------------------------------------------------
mc14818a_init
	ld a,#80
	ld bc,#eff7
	out(c),a

; register b
	ld a,#0b
	ld b,#df
	out (c),a
	ld a,#82
	ld b,#bf
	out (c),a
; seconds
	ld a,#00
	ld b,#df
	out (c),a
	ld a,(buffer)		; 00h seconds
	and %01111111		; ������� ch ���
	ld b,#bf
	out (c),a
; minutes		
	ld a,#02
	ld b,#df
	out (c),a
	ld a,(buffer+1)		; 01h minutes
	ld b,#bf
	out (c),a
; hours		
	ld a,#04
	ld b,#df
	out (c),a
	ld a,(buffer+2)		; 02h hours
	and #3f
	ld b,#bf
	out (c),a
; day of the week		
	ld a,#06
	ld b,#df
	out (c),a
	ld a,(buffer+3)		; 03h day
	ld b,#bf
	out (c),a
; date of the month
	ld a,#07
	ld b,#df
	out (c),a
	ld a,(buffer+4)		; 04h date
	ld b,#bf
	out (c),a
; month
	ld a,#08
	ld b,#df
	out (c),a
	ld a,(buffer+5)		; 05h month
	ld b,#bf
	out (c),a
; year
	ld a,#09
	ld b,#df
	out (c),a
	ld a,(buffer+6)
	ld b,#bf
	out (c),a
; register b
	ld a,#0b
	ld b,#df
	out (c),a
	ld a,#02
	ld b,#bf
	out (c),a

	ld a,#00
	ld bc,#eff7
	out(c),a
	ret

; -----------------------------------------------------------------------------
; ����� ���� � �������
; -----------------------------------------------------------------------------
rtc_data
	; ����� ����
	ld a,(buffer+3)
	dec a
	and %00000111
	add a,a
	add a,a
	ld hl,day		; ���� ������
	ld e,a
	ld d,0
	add hl,de
	call print_str
	ld a,","
	call print_char
	ld a,(buffer+4)		; �����
	call print_hex
	ld a,"."
	call print_char
	ld a,(buffer+5)		; �����
	call print_hex
	ld a,"."
	call print_char
	ld a,#20
	call print_hex
	ld a,(buffer+6)		; ���
	call print_hex
	ld a," "
	call print_char
	; ����� �������
	ld a,(buffer+2)		; ���
	and %00111111
	call print_hex
	ld a,":"
	call print_char
	ld a,(buffer+1)		; ������
	call print_hex
	ld a,":"
	call print_char
	ld a,(buffer)		; �������
	and %01111111
	jp print_hex

; -----------------------------------------------------------------------------
; I2C DDC loader
; -----------------------------------------------------------------------------
ddc_read
	ld hl,str2
	call print_str
	ld bc,#0000		; B = ����� (0=256 ����), C = �����
	ld hl,buffer		; ����� ������ = #8000
	ld d,#a1		; Device Address = 0xA0 DDC + read
	call i2c

	ld b,#00
	call check_buffer
	
	ld hl,str_error	; ����������� ����������
	jr z,ddc_read3
	ld hl,str3		; ���������
ddc_read3
	call print_str

	ld hl,buffer+#48	; Detailed Timing Description # 2 or Monitor Descriptor
ddc_read1	
	ld bc,#0011		
	ld a,(hl)
	inc hl
	or (hl)
	jr z,ddc_descriptor	; Flag = 0000h when block used as descriptor
ddc_read2
	add hl,bc		; ��������� ����������
	bit 0,h
	ret nz			; �����, ���� ����� ��� ������ #8000-#80FF
	jr ddc_read1

ddc_descriptor
	inc hl
	inc hl
	ld c,#0f
	ld a,(hl)		; Data Type Tag
	cp #fc			; FCh: Monitor name?
	jr nz,ddc_read2
	inc hl
	inc hl
	ld b,12
ddc_print1	
	ld a,(hl)
	cp #0a
	ret z
	call print_char
	inc hl
	djnz ddc_print1
	ret

; -----------------------------------------------------------------------------	
; SPI 
; -----------------------------------------------------------------------------
; Ports:

; #02: Data Buffer (write/read)
;	bit 7-0	= Stores SPI read/write data

; #03: Command/Status Register (write)
;	bit 7-1	= Reserved
;	bit 0	= 1:END   	(Deselect device after transfer/or immediately if START = '0')
; #03: Command/Status Register (read):
; 	bit 7	= 1:BUSY	(Currently transmitting data)
;	bit 6-0	= Reserved

spi_end
	ld a,%00000001		; config = end
	out (#03),a
	ret
spi_start
	xor a
	out (#03),a
	ret
spi_w
	in a,(#03)
	rlca
	jr c,spi_w
	ld a,d
	out (#02),a
	ret
spi_r
	ld d,#ff
	call spi_w
spi_r1	
	in a,(#03)
	rlca
	jr c,spi_r1
	in a,(#02)
	ret

; -----------------------------------------------------------------------------	
; I2C 
; -----------------------------------------------------------------------------
; Ports:
; #8C: Data (write/read)
;	bit 7-0	= Stores I2C read/write data
; #8C: Address (write)
; 	bit 7-1	= Holds the first seven address bits of the I2C slave device
; 	bit 0	= I2C 1:read/0:write bit

; #9C: Command/Status Register (write)
;	bit 7-2	= Reserved
;	bit 1-0	= 00: IDLE; 01: START; 10: nSTART; 11: STOP
; #9C: Command/Status Register (read)
;	bit 7-2	= Reserved
;	bit 1 	= 1:ERROR 	(I2C transaction error)
;	bit 0 	= 1:BUSY 	(I2C bus busy)

; HL= ����� ������
; B = ����� (0=256 ����)
; C = �����
; D = Device Address (bit0: 0=WR, 1=RD)

i2c	
	ld a,%11111101		; start
	out (#9c),a
	ld a,d			; slave address w
	and %11111110
	out (#8c),a
	call i2c_ack
	bit 0,d
	jr nz,i2c_4		; �������
	ld a,%11111100		; idle
	out (#9c),a
	ld a,c			; word address
	out (#8c),a
	call i2c_ack
	jr i2c_2
i2c_4
	ld a,%11111110		; nstart
	out (#9c),a
	ld a,c			; word address
	out (#8c),a
	call i2c_ack
	ld a,%11111101		; start
	out (#9c),a
	ld a,d			; slave address r/w
	out (#8c),a
	call i2c_ack
	ld a,%11111100		; idle
	out (#9c),a
i2c_2
	ld a,b
	dec a
	jr nz,i2c_1
	ld a,%11111111		; stop
	out (#9c),a
i2c_1
	ld a,(hl)
	out (#8c),a
	call i2c_ack
	bit 0,d
	jr z,i2c_3		; ������? ��
	in a,(#8c)
	ld (hl),a
i2c_3	
	inc hl
	djnz i2c_2
	ret

; wait ack
i2c_ack
	in a,(#9c)
	rrca			; ack?
	jr c,i2c_ack
	rrca			; error?
	ret

; -----------------------------------------------------------------------------	
; clear screen
; -----------------------------------------------------------------------------	
cls
	xor a
	out (#fe),a
	ld hl,#5aff
cls1
	ld (hl),a
	or (hl)
	dec hl
	jr z,cls1
	ret

; -----------------------------------------------------------------------------	
; print string i: hl - pointer to string zero-terminated
; -----------------------------------------------------------------------------	
print_str
	ld a,(hl)
	cp 17
	jr z,print_color
	cp 23
	jr z,print_pos_xy
	cp 24
	jr z,print_pos_x
	cp 25
	jr z,print_pos_y
	or a
	ret z
	inc hl
	call print_char
	jr print_str
print_color
	inc hl
	ld a,(hl)
	ld (pr_param+2),a	; color
	inc hl
	jr print_str
print_pos_xy
	inc hl
	ld a,(hl)
	ld (pr_param),a		; x-coord
	inc hl
	ld a,(hl)
	ld (pr_param+1),a	; y-coord
	inc hl
	jr print_str
print_pos_x
	inc hl
	ld a,(hl)
	ld (pr_param),a		; x-coord
	inc hl
	jr print_str
print_pos_y
	inc hl
	ld a,(hl)
	ld (pr_param+1),a	; y-coord
	inc hl
	jr print_str

; -----------------------------------------------------------------------------	
; print character i: a - ansi char
; -----------------------------------------------------------------------------	
print_char
	push hl
	push de
	push bc
	cp 13
	jr z,pchar2
	sub 32
	ld c,a			; �������� ��������� � �
	ld hl,(pr_param)	; hl=yx
	;���������� -> scr adr
	;in: H - Y ����������, L - X ����������
	;out:hl - screen adress
	ld a,h
	and 7
	rrca
	rrca
	rrca
	or l
	ld l,a
	ld a,h
        and 24
	or 64
	ld d,a
	;scr adr -> attr adr
	;in: hl - screen adress
	;out:hl - attr adress
	rrca
	rrca
	rrca
	and 3
	or #58
	ld h,a
	ld a,(pr_param+2)	; ����
	ld (hl),a		; ������ �������� �������
	ld e,l
	ld l,c			; l= ������
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,font
	add hl,bc
	ld b,8
pchar3	ld a,(hl)
	ld (de),a
	inc d
	inc hl
	djnz pchar3
	ld a,(pr_param)		; x
	inc a
	cp 32
	jr c,pchar1
pchar2
	ld a,(pr_param+1)	; y
	inc a
	cp 24
	jr c,pchar0
	;����� ����� �� ���� ������
	call ssrl_up
	call asrl_up
	jr pchar00
pchar0
	ld (pr_param+1),a
pchar00
	xor a
pchar1
	ld (pr_param),a
	pop bc
	pop de
	pop hl
	ret

; -----------------------------------------------------------------------------	
; print hexadecimal i: a - 8 bit number
; -----------------------------------------------------------------------------	
print_hex
	ld b,a
	and $f0
	rrca
	rrca
	rrca
	rrca
	call hex2
	ld a,b
	and $0f
hex2
	cp 10
	jr nc,hex1
	add 48
	jp print_char
hex1
	add 55
	jp print_char

; print decimal i: l,d,e - 24 bit number , e - low byte
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
; ����� ����������� ����� �� ���� ������
; -----------------------------------------------------------------------------	
ssrl_up
        ld de,#4000     	; ������ �������� �������
lp_ssu1 
	push de           	; ��������� ����� ����� �� �����
        ld bc,#0020     	; � ����� - 32 �����
        ld a,e          	; � �������� de ��������� �����
        add a,c          	; ������� �����. � ��������
        ld l,a          	; hl ���������� �������� �����
        ld a,d          	; �����, ������� ���� � ����� 8.
        jr nc,go_ssup   	; ��� ����� � �������� e ������-
        add a,#08        	; ���� 32 � ������� � l. ���� ���-
go_ssup 
	ld h,a         		; ������ ������������, �� h=d+8
        ldir                 	; ������� ����� ����� (32 �����)
        pop de           	; ��������������� ����� ������ �����
        ld a,h          	; ���������: � �� ���� �� ��� �����-
        cp #58          	; �������? (��������� ��� 23 ����)
        jr nc,lp_ssu2   	; ���� ��, �� ������� �� �������
        inc d            	; ---------------------------------
        ld a,d          	; down_de
        and #07          	; ����������� ������������������
        jr nz,lp_ssu1   	; ������ ��� �������� �� �����
        ld a,e         		; ���� � �������� �������
        add a,#20        	; (��� �������� de)
        ld e,a          	;
        jr c,lp_ssu1    	; �� �����:  de - ����� �����
        ld a,d          	; �� ������: de - ����� ����� ����
        sub #08          	; ������������ �����������
        ld d,a          	;
        jr lp_ssu1      	; ---------------------------------
lp_ssu2 
	xor a            	; ������� ������������
lp_ssu3 
	ld (de),a       	; � � ��� ������� -
        inc e            	; ������� ����� ����� �����������
        jr nz,lp_ssu3   	; �����: 32 �����
        ld e,#e0        	; ������� � ���������
        inc d            	; (������) ����� �����������
        bit 3,d          	; ��������� ���� ��������� ���?
        jr z,lp_ssu2    	; ���� ���, �� ���������� ���������
        ret                  	; ����� �� ���������	

; -----------------------------------------------------------------------------	
; ����� ��������� �����
; -----------------------------------------------------------------------------	
asrl_up
        ld hl,#5820     	; ����� ������ ����� ���������
        ld de,#5800     	; ����� ������ ����� ���������
        ld bc,#02e0     	; ����������: 23 ����� �� 32 �����
        ldir                 	; �������� 23 ������ ����� �����
        xor a   		; ���� ��� ���������� ������ �����
lp_asup 
	ld (de),a       	; ������������� ����� �������
        inc e            	; ���� ��������� ��� ��������� �����
        jr nz,lp_asup   	; (e=0), �� ��������� ����
        ret                  	; ����� �� ���������

; -----------------------------------------------------------------------------	
; ������ ������ ��������
; -----------------------------------------------------------------------------
; e = y(0-23)		hl = �����
; d = x(0-31)
attr_addr
	ld a,e
        rrca
        rrca
        rrca
        ld l,a
        and 31
        or 88
        ld h,a
        ld a,l
        and 252
        or d
        ld l,a
	ret


; -----------------------------------------------------------------------------	
; RTC Setup
; -----------------------------------------------------------------------------
; a = �������		ix = �����
get_cursor
	ld de,cursor_pos_data
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,de
	push hl
	pop ix
	ret

; -----------------------------------------------------------------------------
; c = ����
; a = �������
print_cursor
	ld c,%01001111		; ���� �������
print_cursor1
	call get_cursor
	ld d,(hl)		; ���������� �
	inc hl
	ld b,(hl)		; ������ �������
	ld e,time_pos_y
	call attr_addr
print_cursor2	
	ld (hl),c
	inc hl
	djnz print_cursor2
	ret



; -----------------------------------------------------------------------------
rtc_setup
	ld hl,str6
	call print_str
	
	ld a,(buffer)
	and %01111111
	ld (buffer),a
	ld a,(buffer+2)
	and %00111111
	ld (buffer+2),a
	
	xor a
cursor1
	ld (cursor_pos),a	; ������ � ������
cursor2
	call print_cursor	; ���������� ������
key_press
	ld bc,system_port
	in a,(c)		; ������ �������� ����������
	cp #ff
	jr nz,key_press
key_press1
	ld bc,system_port
	in a,(c)		; ������ �������� ����������
	cp #5a			; <ENTER> ?
	jr z,key_enter
	cp #75			; <UP> ?
	jr z,key_up
	cp #72			; <DOWN> ?
	jr z,key_down
	cp #6b			; <LEFT> ?
	jr z,key_left
	cp #74			; <RIGHT> ?
	jr z,key_right
	cp #76			; <ESC>?
	jp z,anykey1
	jr key_press1

key_left
	ld a,(cursor_pos)
	or a			; ������ �������?
	jr z,key_press		; ��, �������� ��� ���������
	ld c,%00000111
	call print_cursor1	; ������ ������
	ld a,(cursor_pos)
	dec a
	jr cursor1

key_right
	ld a,(cursor_pos)
	cp 6			; ��������� �������?
	jr nc,key_press		; ��, �������� ��� ���������
	ld c,%00000111
	call print_cursor1	; ������ ������
	ld a,(cursor_pos)
	inc a
	jr cursor1

key_up
	ld d,(ix+4)
	ld e,(ix+5)
	ld a,(de)
	cp (ix+3)
	jr z,key_up2		; = max?
	add a,1			; �������������� ��������
key_up1
	daa
	ld (de),a
key_up2
	ld hl,time_pos_yx	; ���������� ������ ���� � �������
	ld (pr_param),hl
	call rtc_data		; �����
	ld a,(cursor_pos)
	jr cursor2

key_down
	ld d,(ix+4)
	ld e,(ix+5)
	ld a,(de)
	cp (ix+2)
	jr z,key_up2		; = min?
	sub 1			; �������������� ���������
	jr key_up1

key_enter
	ld hl,buffer
	set 7,(hl)
	ld hl,buffer
	ld bc,#0700
	ld d,%11010000		; Device Address RTC DS1338 + write
	call i2c

	ld hl,buffer
	res 7,(hl)
	ld bc,#0100
	ld d,%11010000		; Device Address RTC DS1338 + write
	call i2c
	jp anykey1



; ����������� ����
; 13 (0x0d)		- ���� ������
; 17 (0x11),color	- �������� ���� ����������� ��������
; 23 (0x17),x,y		- �������� ������� �� ���������� x,y
; 24 (0x18),x		- �������� ������� �� x
; 25 (0x19),y		- �������� ������� �� y
; 0			- ����� ������

str1	
	db 23,0,0,17,#47,"DivGMX Ultimate",17,7,13,13
	db "FPGA SoftCore - TSConf",13
	db "(build 20180506) By MVV",13,13

	db "Loading roms/zxevo.rom...",0
str8
	db "ASP configuration device ID 0x",0	; EPCS1	0x10 (1 Mb), EPCS4 0x12 (4 Mb), EPCS16 0x14 (16 Mb), EPCS64 0x16 (64 Mb)
str5
	db "Copying data from FLASH...",0
str3
	db 17,4," Done",17,7,13,0
str4
	db 23,0,9,"RTC data read...",0
;	    00000000001111111111222222222233
;	    01234567890123456789012345678901
str0
	db 23,0,22,"Press ENTER to continue         "
	db	   "S: RTC Setup  PrtScr: 49Hz/60Hz",0
str2
	db 13,13,"DDC data read...",0
str6
	db 23,0,22,"<>:Select Item   ENTER:Save&Exit"
	db "^",127,  ":Change Values   ESC:Abort   ",0
str_error
	db 17,2," Error",17,7,13,0
;str7
;	db 13,13,"MAC address ",0


; Fri,05.09.2014 23:53:29
; 0-7 1-31 1-12 0-99 0-23 0-59 0-59
cursor_pos_data
	db 0,3,#01,#07,#80,#03,#00,#00		; �, ������, min, max, ����� ����������
	db 4,2,#01,#31,#80,#04,#00,#00
	db 7,2,#01,#12,#80,#05,#00,#00
	db 10,4,#00,#99,#80,#06,#00,#00
	db 15,2,#00,#23,#80,#02,#00,#00
	db 18,2,#00,#59,#80,#01,#00,#00
	db 21,2,#00,#59,#80,#00,#00,#00

day
	db "Sun",0,"Mon",0,"Tue",0,"Wed",0,"Thu",0,"Fri",0,"Sat",0,"Err",0
FES1	
	db #10 		;flag (#00 - file, #10 - dir)
	db "ROMS"	;DIR name
	db #00
FES2
	db #00
	db "ZXEVO.ROM"    ;file name //
	db #00

	INCLUDE "TSFAT.ASM"
font	
	INCBIN "font.bin"


	savebin "loader.bin",startprog, 8192
	
	display "Size of ROM is: ",/a, $