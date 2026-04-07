[org 0x0100]
jmp start



;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
; Play Sound Functions
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

old_pit_control: db 0
playSound:
    push bp
    mov bp, sp

    pusha

	in al, 43h            ; Save the previous control word
	mov [old_pit_control], al
    ; Set the frequency to 440 Hz for the PC speaker
    mov ax, 0x34DC      ; PIT base frequency
    mov dx, 0x12	; 0x1234DC -> 1193180
    mov cx, [bp + 4]         ; Desired tone frequency (A4 note)
    div cx               ; AX now contains divisor for 440 Hz
    mov bx, ax           ; Store divisor in BX for PIT

    ; Program the PIT for square wave generation on channel 2
    mov al, 0B6h         ; Set up control word: binary counter, mode 3, channel 2
    out 43h, al          ; Send control word to PIT command port
    mov al, bl           ; Send low byte of divisor
    out 42h, al
    mov al, bh           ; Send high byte of divisor
    out 42h, al

    ; Enable the speaker
    in al, 61h           ; Read current state of port 61h
    or al, 3             ; Set bits 0 and 1 to enable speaker and sound from PIT
    out 61h, al

    ; Delay to play the sound for a short time
    mov cx, 5000h       ; CX is used as a delay counter
delay_loop:
    loop delay_loop      ; Busy-wait loop for timing

    ; Disable the speaker
    in al, 61h           ; Read current state of port 61h
    and al, 0FCh         ; Clear bits 0 and 1 to turn off the speaker
    out 61h, al

mov al, [old_pit_control] ; Restore the original PIT control word
out 43h, al



    popa
    pop bp
    ret 2

playJumpSound:
push cx

mov cx, 200
.loop:
push cx
call playSound
add cx, 50
cmp cx, 600
jle .loop
pop cx
ret

delay2:
pusha
  mov cx, 0xFFFF
   l1z: loop l1z
l2z:loop l2z
l7z:loop l7z
l10z: loop l10z

l8z: loop l8z
popa
ret


gameOverSound:

mov cx, 2
outerloop:
; C3 (130.81 Hz ≈ 131 Hz)
mov ax, 131         
push ax
call playSound
call delay2
; C5 (523.25 Hz ≈ 523 Hz) High C
mov ax, 523         
push ax
call playSound
call delay2
; G5 (783.99 Hz ≈ 784 Hz) High G
mov ax, 784         
push ax
call playSound
call delay2
; E5 (659.25 Hz ≈ 660 Hz) High E
mov ax, 660         
push ax
call playSound
call delay2
; C5 (523.25 Hz ≈ 523 Hz) High C
mov ax, 523         
push ax
call playSound
call delay2
; G5 (783.99 Hz ≈ 784 Hz) High G
mov ax, 784         
push ax
call playSound
call delay2
; E5 (659.25 Hz ≈ 660 Hz) High E
mov ax, 660         
push ax
call playSound
; E5 (659.25 Hz ≈ 660 Hz) High E
mov ax, 660         
push ax
call playSound
; E5 (659.25 Hz ≈ 660 Hz) High E
mov ax, 660         
push ax
call playSound
; E5 (659.25 Hz ≈ 660 Hz) High E
mov ax, 660         
push ax
call playSound
call delay2
loop outerloop
; E4 (329.63 Hz ≈ 330 Hz)
mov ax, 330         
push ax
call playSound
call delay2
; F4 (349.23 Hz ≈ 350 Hz)
mov ax, 350         
push ax
call playSound
call delay2
; F#4 (369.99 Hz ≈ 370 Hz) F Sharp
mov ax, 370         
push ax
call playSound
call delay2
; F4 (349.23 Hz ≈ 350 Hz)
mov ax, 350         
push ax
call playSound
call delay2
; F#4 (369.99 Hz ≈ 370 Hz) F Sharp
mov ax, 370         
push ax
call playSound
call delay2
; G4 (392.00 Hz) G
mov ax, 392         
push ax
call playSound
call delay2
; G4 (392.00 Hz) G
mov ax, 392         
push ax
call playSound
call delay2
; A4 (440.00 Hz) A
mov ax, 440         
push ax
call playSound
call delay2
; B4 (493.88 Hz ≈ 494 Hz) B
mov ax, 494         
push ax
call playSound
call delay2
; C5 (523.25 Hz ≈ 523 Hz) C
mov ax, 523         
push ax
call playSound
call delay2
; E4 (329.63 Hz ≈ 330 Hz)
mov ax, 330         
push ax
call playSound
mov ax, 330         
push ax
call playSound
mov ax, 330         
push ax
call playSound

ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
; Timer
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
tickcount: dw 120
timerflag: dw 0
ticker: dw 0
gamelose: dw 0

printtime:

pusha
push es

mov ax, 0xb800
mov es, ax
mov ax, [tickcount]
mov bx, 10
mov cx, 0

tloop1:
mov dx, 0
div bx
add dl, 0x30
push dx
inc cx
cmp ax, 0
jnz tloop1

mov di, 300

mov word [es:di] , 0x720
mov word [es:di+2] , 0x720
mov word [es:di+4] , 0x720

tloop2:
pop dx
mov dh, 0x04
mov [es:di]. dx
add di,2
loop tloop2

pop es
popa
ret

timerr:
cmp word [timerflag] , 0
jz skiptimer

cmp word [ticker] , 18
jnz usualprint

mov word [ticker] , 0
sub word [tickcount] , 1

cmp word [tickcount] , 0
jg usualprint

mov word [gamelose] , 1
mov al, 0x20
out 0x20, al

pop ax
pop ax
pop ax
jmp endthegame

usualprint:
call printtime

skiptimer:
add word [ticker] , 1
mov al, 0x20
out 0x20, al

iret



;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
; Menu 1  (Welcome Menu)
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------



msg1: db 'Welcome to Maze Runner | Choose Maze generation Algorithm'
len1: dw 57
msg2: db 'Binary Tree Algorithm'
len2: dw 21
msg3: db 'Recursive Backtracking Algorithm'
len3: dw 32
msg4: db "Prim's Algorithm"
len4: dw 16
msg5: db "Settings"
len5: dw 8
msg6: db "EXIT"
len6: dw 4
currSelect: dw 1

menu1:
cld
pusha
push di
push es

mov ax, 0xb800
mov es, ax
mov di, 694

; Message 1
mov ax, [len1]
shr ax, 1
sub di, ax

mov si, msg1
mov cx, [len1]
mov ah, 0x03

cld
lp1:
lodsb
stosw
loop lp1

; Message 2
mov di, 1670
mov ax, [len2]
shr ax, 1
sub di, ax
mov cx, [len2]

mov si, msg2
cmp word [currSelect], 1 ; highlight word.
je curr2
mov ah, 0x07
jmp lp2

curr2:
mov ah, 0x97

lp2:
lodsb
stosw
loop lp2

; Message 3
mov di, 1986
mov ax, [len3]
shr ax, 1
sub di, ax

mov si, msg3
mov cx, [len3]
cmp word [currSelect], 2 ; highlight word.
je curr3
mov ah, 0x07
jmp lp3

curr3:
mov ah, 0x97

lp3:
lodsb
stosw
loop lp3

; Message 4
mov di, 2312
mov ax, [len4]
shr ax, 1
sub di, ax

mov si, msg4
mov cx, [len4]
cmp word [currSelect], 3  ; highlight word.
je curr4
mov ah, 0x07
jmp lp4

curr4:
mov ah, 0x97

lp4:
lodsb
stosw
loop lp4

; Message 5
mov di, 2638
mov ax, [len5]
shr ax, 1
sub di, ax

mov si, msg5
mov cx, [len5]
cmp word [currSelect], 4  ; highlight word.
je curr5
mov ah, 0x07
jmp lp5

curr5:
mov ah, 0x97

lp5:
lodsb
stosw
loop lp5

; Message 6
mov di, 2958
mov ax, [len6]
shr ax, 1
sub di, ax

mov si, msg6
mov cx, [len6]
cmp word [currSelect], 5	; logic for printing (w/ or without selection)
je curr6
mov ah, 0x04
jmp lp6

curr6:
mov ah, 0x94


lp6:
lodsb
stosw
loop lp6

pop es
pop di
popa

ret


;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
menuInputs:
pusha
push di
push es

lp7:
mov ah, 0	;service 0
int 0x16	; BIOS service
call playJumpSound
cmp ax, 0x1C0D	; Enter key
je enterKey
cmp ax, 0x4800	; up arrow key
jne downArrow

;UpARROW key logic
cmp word [currSelect], 1
jne skip1
mov word [currSelect], 5
call menu1
jmp lp7
skip1:
sub word [currSelect], 1
call menu1
jmp lp7

downArrow:
;DownARROW key logic
cmp ax, 0x5000
jne lp7
cmp word [currSelect], 5
jne skip2
mov word[currSelect], 1
call menu1
jmp lp7
skip2:
add word [currSelect], 1
call menu1
jmp lp7

enterKey:

pop es
pop di
popa

ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
; Menu 2  (Settings)
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------


ms1: db 'Select Maze color and Maze size'
ln1: dw 31
ms2: db 'RED'
ln2: dw 3
ms3: db 'GREEN'
ln3: dw 5
ms4: db " WHITE "
ln4: dw 7
ms5: db "17 X 17"
ln5: dw 7
ms6: db "BACK"
ln6: dw 4
currSelect2: dw 1
Size: dw 25
Color: dw 0x03DB


menu2:

cld
pusha
push di
push es

mov ax, 0xb800
mov es, ax
mov di, 701

; Message 1
mov ax, [ln1]
shr ax, 1
sub di, ax

mov si, ms1
mov cx, [ln1]
mov ah, 0x03

cld
lop1:
lodsb
stosw
loop lop1

; Message 2
mov di, 1673
mov ax, [ln2]
shr ax, 1
sub di, ax
mov cx, [ln2]

mov si, ms2	
cmp word [currSelect2], 1 ; highlight word.
je cur2
mov ah, 0x07
jmp lop2

cur2:
mov ah, 0x97

lop2:
lodsb
stosw
loop lop2

; Message 3
mov di, 1992
mov ax, [ln3]
shr ax, 1
sub di, ax

mov si, ms3
mov cx, [ln3]
cmp word [currSelect2], 2 ; highlight word.
je cur3
mov ah, 0x07
jmp lop3

cur3:
mov ah, 0x97

lop3:
lodsb
stosw
loop lop3

; Message 4
mov di, 2311
mov ax, [ln4]
shr ax, 1
sub di, ax

mov si, ms4
mov cx, [ln4]
cmp word [currSelect2], 3  ; highlight word.
je cur4
mov ah, 0x07
jmp lop4

cur4:
mov ah, 0x97


lop4:
lodsb
stosw
loop lop4

; Message 5
mov di, 2631
mov ax, [ln5]
shr ax, 1
sub di, ax

mov si, ms5
mov cx, [ln5]
cmp word [currSelect2], 4  ; highlight word.
je cur5
mov ah, 0x07
jmp lop5

cur5:
mov ah, 0x97


lop5:
lodsb
stosw
loop lop5

; Message 6
mov di, 2952
mov ax, [ln6]
shr ax, 1
sub di, ax

mov si, ms6
mov cx, [ln6]
cmp word [currSelect2], 5	; logic for printing w/ or without selection
je cur6
mov ah, 0x04
jmp lop6

cur6:
mov ah, 0x94


lop6:
lodsb
stosw
loop lop6


pop es
pop di
popa

ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
; Menu Inputs 2 ( settings inputs)
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
menuInputs2:

pusha

lop7:
mov ah, 0	;service 0
int 0x16	; BIOS service
call playJumpSound
cmp ax, 0x1C0D	; Enter key
je enterK
cmp ax, 0x4800	; up arrow key
jne downArr

; Up arrow key logic
cmp word [currSelect2], 1
jne skp1
mov word [currSelect2], 5
call menu2
jmp lop7
skp1:
sub word [currSelect2], 1
call menu2
jmp lop7

downArr:
;DownARROW key logic
cmp ax, 0x5000
jne lop7
cmp word [currSelect2], 5
jne skp2
mov word[currSelect2], 1
call menu2
jmp lop7
skp2:
add word [currSelect2], 1
call menu2
jmp lop7
enterK:
cmp word [currSelect2], 1
je red
cmp word [currSelect2], 2
je green
cmp word [currSelect2], 3
je bigS
cmp word[currSelect2], 4
je smallS
cmp word[currSelect2], 5
jne skipMainJump
jmp start
skipMainJump

red:
mov word[Color], 0x04DB
jmp lop7
green:
mov word[Color], 0x02DB
jmp lop7
bigS:
mov word[Color], 0x07DB
jmp lop7
smallS:
mov word[Size], 17
jmp lop7

popa

ret


;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
delay:
pusha
push di
push es

mov cx, 0xFA00
l10: loop l10



pop es
pop di
popa

ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
clrscreen:
pusha
push di
push es

mov ax, 0xb800
mov es, ax
xor di, di
mov ax, 0x0720
mov cx, 2000
rep stosw

pop es
pop di
popa

ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

seed: dw 0

randomGen:
push bp
mov bp, sp
push bx
push cx
push dx
push es

;XOR Shift Random no. Generator

mov ax, [seed]    
mov cx, 7	; Shift amount for 1st operation
mov dx, ax	; value to be shifted

lA:
shl dx, 1
loop lA
xor ax, dx

mov cx, 9	; Shift amount for 2nd operation
mov dx, ax	; value to be shifted
lB:
shr dx, 1
loop lB
xor ax, dx

mov cx, 8	; Shift amount for 3rd operation
mov dx, ax	; value to be shifted
lC:
shl dx, 1
loop lC
xor ax, dx

; ax has random value

mov [seed], ax 	; update seed
mov ah, 0		; reduce the value.
div byte [bp + 4]	; compress into the range. 
mov al, ah		; store in al.

pop es
pop dx
pop cx
pop bx

pop bp

ret 2   	 
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
squareGen:
push bp
mov bp, sp
pusha
push di
push es

mov ax, 0xb800
mov es, ax
sub word[bp + 4], 1

; -- code for moving di to top left of square ---
mov di, 1998	; middle pixel
mov ax, [bp + 4]
shr ax, 1	; n/2
mov cx, ax

l1:
sub di, 4   ; 4 because double pixel
loop l1
mov cx, ax
l2:
sub di, 160
loop l2

mov si, di
add si, 160

;  ---------

mov ax, [Color]		; hex value for full block

; print square --------
mov cx, [bp + 4]
shl cx, 1
rep stosw
mov cx, [bp + 4]


l3:
mov [es:di], ax
mov [es:di + 2], ax
add di, 160
loop l3

mov [es:di + 2], ax
mov cx, [bp + 4]
shl cx, 1
std
rep stosw
mov cx, [bp + 4]
cld

l4:
mov [es:di], ax
mov [es:di + 2], ax
sub di, 160
loop l4

mov word[es:si], 0x0720
mov word[es:si+2], 0x0720

pop es
pop di
popa
pop bp

ret 2

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
binaryMazeGen:
push bp
mov bp, sp
push bx
push cx
push dx

; -- code for moving di to top left of square ---
mov di, 1998	; middle pixel
mov ax, [bp + 4]
shr ax, 1	; n/2
mov cx, ax

l5:
sub di, 4   ; cuz of double pixel 
loop l5
mov cx, ax
l6:
sub di, 160
loop l6

add di, 164
;  ---------

mov ax, 0xb800
mov es, ax

mov bx, [bp + 4]	
shr bx, 1 	; divide by two because of grid.

mov dx, bx 	; dx is outer loop counter


l8:

mov si, di		; store starting index
mov cx, bx

l7:
mov ax, 2	; random no. range (0-1)
push ax		
Call randomGen	; AL has random value

Call delay
cmp al, 0
jz south

; Print on east
add di, 4
mov ax, [Color]
mov [es:di], ax
mov [es:di + 2], ax
sub di, 4
jmp loopEnd

south:
; Print on south
add di, 160
mov ax, [Color]
mov [es:di], ax
mov [es:di + 2], ax
	
sub di, 160

loopEnd:
add di, 8

loop l7

mov di, si	; restore the starting index

add di, 320	; go 2 blocks south

dec dx
jnz l8


pop dx
pop cx
pop bx

pop bp

ret 2

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	;RECURSIVE MAZE GENERATION ALGORITHM
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
left_var: db 0
right_var: db 0
bottom_var: db 0
top_var: db 0
direction: db 0, 0, 0, 0  ; (left right top bottom)
startIndex: dw 0
endIndex: dw 0
rand: dw 0

; Monster Locations 
monsterLocations: times 80 dw 0
;collectables Locations
;collectablesLocations: times 10 dw 0

RecursiveMazeGen:
push bp
mov bp, sp
pusha


; -- code for moving di to top left of square ---
mov di, 1998	; middle pixel
mov ax, [bp + 4]
shr ax, 1	; n*2
mov cx, ax

lx5:
sub di, 4   ; cuz of double pixel 
loop lx5
mov cx, ax
lx6:
sub di, 160
loop lx6

push di

mov di , 1998
mov cx, ax
ler:
add di, 4   ; cuz of double pixel 
loop ler
mov cx, ax
ler2:
add di, 160
loop ler2

mov [endIndex] , di

pop di

;----------------setting border locations

mov ax, di
mov bl, 160
div bl

add ah, 4
mov [left_var], ah

mov ax, [bp + 4]
shl ax, 2
mov bl, [left_var]
add bl, al
sub bl, 8
mov [right_var], bl

mov ax, di
add ax, 160
add ax, 4
mov [top_var], ax

mov al, [bp + 4]
mov bl, 160
mul bl
mov bx, di
add bx, ax
sub bx, 320
mov ax, [bp + 4]
shl ax, 2
add bx, ax
sub bx, 4
mov [bottom_var], bx

;----------------------

; fill the square with blocks

mov ax, 0xb800
mov es, ax

mov bx, [bp + 4]	
mov dx, bx 	; dx is outer loop counter

mov [startIndex], di

lx8:
mov cx, bx
mov si, di
lx7:
mov ax, [Color]
mov [es:di], ax
mov [es:di+2], ax

add di, 4
loop lx7

mov di, si	; restore the starting index
add di, 160	
dec dx
jnz lx8

; -------/////Real Stuff\\\\\---------------

mov di, [startIndex]
add di, 164

mov ax, 0x48DB

; print first block
mov [es:di], ax
mov [es:di + 2], ax

xor si, si
top:

; generate random number
Generate:
mov ax, 4	; random no. range (0-3)
push ax		
Call randomGen	; AL has random value
add al, 1	; range (1-4)
cmp al, 2
jle skp
add al, 1	; random numbers {2,4,1,5} {left, right, top, bottom}
skp:



cmp al, [direction]
jne Selected
mov al, 1
cmp al, [direction + 2]
jne Selected
mov al, 4
cmp al, [direction + 1]
jne Selected
mov al, 5
cmp al, [direction + 3]
jne Selected
jmp backTrack		; if all random numbers are equal to direction flags -> backTrack

Selected:		


mov dl, al
mov [rand], al



cmp dl, 2
jne skipLeft
jmp moveLeft
skipLeft:
cmp dl, 1
je moveTop
cmp dl, 5
je moveBottom
cmp dl, 4
jne skipright
jmp moveRight
skipright:

moveTop:
mov dx, [Color]
cmp [es:di-320], dx
; inc if no movement
je checked1
mov byte [direction + 2], 1
jmp top
checked1:
mov dx, 0x00DB
cmp [es:di-320], dx
; inc if no movement
jne checked2
mov byte [direction + 2], 1
jmp top
checked2:
;border check
mov ax, di
sub ax, 160
cmp ax, [top_var]
; inc if no movement
jge checked3
mov byte [direction + 2], 1
jmp top
checked3:

; Monster Spawn Location (------------)

cmp si, 160
je skipSpawn
cmp [monsterLocations + si], di
je skipSpawn
mov [monsterLocations + si], di
add si, 2
skipSpawn:

sub di, 160
mov ax, 0x48DB
mov [es:di], ax
mov [es:di + 2], ax
sub di, 160
mov [es:di], ax
mov [es:di + 2], ax


jmp endMove

moveBottom:
mov dx, [Color]
cmp [es:di+320], dx
; inc if no movement
je checked4
mov byte [direction + 3], 5
jmp top
checked4:
mov dx, 0x00DB
cmp [es:di+320], dx
; inc if no movement
jne checked5
mov byte [direction + 3], 5
jmp top
checked5:
;border check
mov ax, di
add ax, 160
cmp ax, [bottom_var]
; inc if no movement
jl checked6
mov byte [direction + 3], 5
jmp top
checked6:

; Monster Spawn Location (And Collectables)

cmp si, 160
je skipSpawn2
cmp [monsterLocations + si], di
je skipSpawn2
mov [monsterLocations + si], di
add si, 2
skipSpawn2:

add di, 160
mov ax, 0x48DB
mov [es:di], ax
mov [es:di + 2], ax
add di, 160
mov [es:di], ax
mov [es:di + 2], ax
mov cx, 20
jmp endMove

moveLeft:
mov dx, [Color]
cmp [es:di-8], dx
; inc if no movement
je checked7
mov byte [direction], 2
jmp top
checked7:
mov dx, 0x00DB
cmp [es:di-8], dx
; inc if no movement
jne checked8
mov byte [direction], 2
jmp top
checked8:
;border check 
mov ax, di
sub ax, 4
mov bl , 160
div bl
cmp ah, [left_var]
; inc if no movement
jge checked9
mov byte [direction], 2
jmp top
checked9:

sub di, 4
mov ax, 0x48DB
mov [es:di], ax
mov [es:di + 2], ax
sub di, 4
mov [es:di], ax
mov [es:di + 2], ax
mov cx, 20
jmp endMove

moveRight:
mov dx, [Color]
cmp [es:di+8], dx
; inc if no movement
je checked10
mov byte [direction + 1], 4
jmp top
checked10:
mov dx, 0x00DB
cmp [es:di+8], dx
; inc if no movement
jne checked11
mov byte [direction + 1], 4
jmp top
checked11:
;border check
mov ax, di
add ax, 4
mov bl , 160
div bl
cmp ah, [right_var]
; inc if no movement
jl checked12
mov byte [direction + 1], 4
jmp top
checked12:



add di, 4
mov ax, 0x48DB
mov [es:di], ax
mov [es:di + 2], ax
add di, 4
mov [es:di], ax
mov [es:di + 2], ax
mov cx, 20

endMove:
mov byte[direction], 0	; clr flags if movement occured. 
mov byte[direction + 1], 0
mov byte[direction + 2], 0
mov byte[direction + 3], 0
call delay
; Convert random value to opposite and push to stack.
mov bx, 6
sub bx, [rand]
push bx		; stack push

jmp top

backTrack:
call delay




mov ax, 0x00DB

cmp sp, 0xFFE8
jne skipendGen
jmp endGen
skipendGen:


pop bx	


cmp bx, 2
je LeftR
cmp bx, 1
je TopR
cmp bx, 5
je BottomR
cmp bx, 4
je RightR

TopR:
mov [es:di], ax
mov [es:di + 2], ax
sub di, 160
mov [es:di], ax
mov [es:di + 2], ax
sub di, 160
jmp gotop

BottomR:
mov [es:di], ax
mov [es:di + 2], ax
add di, 160
mov [es:di], ax
mov [es:di + 2], ax
add di, 160
jmp gotop

LeftR:
mov [es:di], ax
mov [es:di + 2], ax
sub di, 4
mov [es:di], ax
mov [es:di + 2], ax
sub di, 4
jmp gotop

RightR:
mov [es:di], ax
mov [es:di + 2], ax
mov [es:di + 4], ax
mov [es:di + 6], ax
add di, 8

gotop:
mov byte[direction], 0	; clr flags after reversing
mov byte[direction + 1], 0
mov byte[direction + 2], 0
mov byte[direction + 3], 0
jmp top

endGen:


mov di, [startIndex]
add di, 160
mov word [es:di], 0x00DB	
mov word [es:di+2], 0X00DB

add di, 4
mov ax, 0x00DB

; finish first block
mov [es:di], ax
mov [es:di + 2], ax

mov di, [endIndex]
sub di, 160
mov word [es:di], 0x00DB	
mov word [es:di+2], 0X0249

sub di, 4
mov ax, 0x00DB

mov [es:di], ax
mov [es:di + 2], ax


popa

pop bp

ret 2


;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	;Player stuff
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
score: dw 0
scmsg: db 'SCORE:'
gameend: dw 0
gameover: db 'GAME OVER'
menudirect: db 'Press Enter to proceed'
gamewon: db 'CONGRATULATIONS! YOU BEAT THE MAZE'
gamelost: db 'BETTER LUCK NEXT TIME!'
spidermode: db 'Space->Spider'
secondsleft: db 'Seconds:'

Playerspawn:

mov ax, 0xb800
mov es, ax
mov di , 2000

mov ah, 0x0E
mov al , 2

mov di, [startIndex]
mov [es:di] , ax
ret

printScore:
push bp
mov bp,sp
pusha

mov ax, 0xb800
mov es, ax
mov di , [bp + 4]    ;1100
mov ah, 0x02
mov cx, 6
mov si, scmsg

cld

pv1:

lodsb
stosw

loop pv1

mov di, [bp + 6]  ;1114
mov word [es:di] , 0x720
mov word [es:di+2] , 0x720
mov word [es:di+4] , 0x720

mov ax, 0xb800
mov es, ax
mov ax, [score]
mov bx, 10
mov cx, 0

nextdigit:
mov dx, 0
div bx
add dl, 0x30
push dx
inc cx
cmp ax, 0
jnz nextdigit

mov di, [bp + 6]     ;1114

nextpos:
pop dx
mov dh, 0x02
mov [es:di] , dx
add di, 2
loop nextpos

popa
pop bp
ret 4

ScoreUpdate:

cmp bx, 0x0401
jnz nxt2
sub word [score], 10

nxt2:
cmp bx, 0x0501
jnz nxt3
sub word [score], 20


nxt3:
cmp bh, 0x09
jnz exitt
add word [score], 15

exitt:

cmp bx, 0x0249
jne nxtcheck

finishgame:
mov word [gameend] , 1

nxtcheck:
cmp word [score] , 0
jge backto

mov word [score] , 0

backto:

ret 

upmove2:

mov word [es:di] , 0x720
sub di, 160
mov word [es:di] , 0x0E02
ret

downmove2:

mov word [es:di] , 0x720
add di, 160
mov word [es:di] , 0x0E02
ret

leftmove2:

mov word [es:di] , 0x720
sub di, 2
mov word [es:di] , 0x0E02
ret

rightmove2:

mov word [es:di] , 0x720
add di, 2
mov word [es:di] , 0x0E02
ret

printtiming:
pusha

mov ax, 0xb800
mov es, ax
mov di , 140
mov ah, 0x04
mov cx, 8
mov si, secondsleft

cld

pstv1:

lodsb
stosw

loop pstv1

popa
ret

printspider:

pusha

mov ax, 0xb800
mov es, ax
mov di , 320
mov ah, 0x03
mov cx, 13
mov si, spidermode

cld

psv1:

lodsb
stosw

loop psv1

popa
ret

drawrect:

pusha

mov di, 172

mov ax, 0xb800
mov es , ax
mov ax, 0x0D2A

mov cx, 65

lp1a:
mov [es:di] , ax
add di, 2
loop lp1a

mov cx, 20
lp2a:
mov [es:di] , ax
add di, 160
loop lp2a

mov cx, 65
lp3a:
mov [es:di] , ax
sub di, 2
loop lp3a

mov cx, 20
lp4a:
mov [es:di] , ax
sub di, 160
loop lp4a

popa
ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	;START EXECUTION
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

oldisr: dd 0

start:

push ax
push es
xor ax, ax
mov es, ax
mov ax , [es:8*4]
mov [oldisr] ,ax
mov ax , [es:8*4 + 2]
mov [oldisr + 2] ,ax
pop es
pop ax


mov sp, 0xFFFE
call clrscreen
call menu1
call menuInputs
call clrscreen

mov ah, 2Ch         ;"Get System Time"
int 21h     
 
; After the interrupt, DL = hundredths of a second

mov [seed], dl		; seed
mov ax, 2	; random no. range (0-1)
push ax
Call randomGen	; AL has rand

cmp word [currSelect], 1
je algo1
cmp word [currSelect], 2
je algo2
cmp word [currSelect], 3
je algo3
cmp word [currSelect], 4
je algo4
cmp word [currSelect], 5
jne skipterminate
jmp terminate
skipterminate:

algo1:			; Algorithm 1 (binary tree)

mov ax, [Size]	; maze dimension |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
push ax
call squareGen	; generate a nxn square. 


mov ax, [Size]
push ax
call binaryMazeGen	; generate maze using binary algorithm.
jmp playGame

algo2:
mov ax, [Size]	; maze dimension
push ax
call RecursiveMazeGen	; generate a nxn square. 

jmp playGame

algo3:
mov ax, [Size]	; maze dimension
push ax
call squareGen	; generate a nxn square.

jmp playGame


algo4:

call menu2	; Settings menu
call menuInputs2

playGame:

push es
cli
xor ax, ax
mov es, ax
mov word [es:8*4] , timerr
mov [es:8*4+2] , cs
sti
pop es


; rest of game functionality

xor si, si
mov dx, 3
mov ah , 0x04

printMonster:

mov di, [monsterLocations + si]
mov word[es:di], 0x09E3
add si, 4
mov di, [monsterLocations + si]
mov al , 01
mov word[es:di], ax
add si, 4
sub dx, 1
cmp dx, 0
je setter

mov ah, 0x04
continuee:

cmp si, 160
jne printMonster
jmp onwith

setter:
mov ah, 0x05
mov dx, 3
jmp continuee

onwith:
xor si, si
mov word [es:si] , 0x720

call Playerspawn

mov word [timerflag] , 1

gameloop:
cmp word [gameend] , 1
je endthegame


mov ax, 1114
push ax
mov ax, 1100
push ax
call printScore
call printspider
call printtiming

cmp word [gamelose], 1
je endthegame

mov ah, 0
int 0x16

cmp al , 119   ;w
je upmove

cmp al , 97  ;a
je leftmove

cmp al, 100
je rightmove  ;d

cmp al , 115
je downmove   ;s

cmp al, 27    ;esc
jnz gameloop

jmp endthegame

upmove:

mov bx, [es:di - 160]
cmp bx , [Color]
je gameloop

call upmove2
call ScoreUpdate

jmp gameloop

downmove:
mov bx, [es:di + 160]
cmp bx , [Color]
je gameloop

call downmove2
call ScoreUpdate

jmp gameloop

leftmove:
mov bx, [es:di - 2]
cmp bx , [Color]
je gameloop

call leftmove2
call ScoreUpdate

jmp gameloop

rightmove:
mov bx, [es:di + 2]
cmp bx , [Color]
je gameloop

call rightmove2
call ScoreUpdate

jmp gameloop

endthegame:
mov word [timerflag] , 0
mov word [tickcount] , 120
mov word [ticker] , 0
mov word [gameend] , 0   ;if he plays again so resetting

push es
push ax
push bx

cli
xor ax, ax
mov es, ax
mov ax, [oldisr]
mov bx, [oldisr + 2]
mov word [es:8*4] , ax
mov [es:8*4 + 2], bx
sti

pop bx
pop ax
pop es

cmp al, 27
jne wrappup

mov word [score] , 0
jmp beginner

wrappup:

call clrscreen
call drawrect

cmp word [gamelose] , 1
jnz winningwala

mov word [gamelose] , 0

push es
pusha
mov ah, 0x13
mov al, 0
mov bh, 0
mov bl, 0x84
mov dx, 0x0B1D
mov cx, 22
push cs
pop es
mov bp, gamelost
int 0x10
popa
pop es

jmp forboth

winningwala:
push es
pusha

mov ah, 0x13
mov al, 0
mov bh, 0
mov bl, 0x97
mov dx, 0x0B17
mov cx, 34
push cs
pop es
mov bp, gamewon
int 0x10

popa
pop es

forboth:


push es
pusha
mov ah, 0x13
mov al, 0
mov bh, 0
mov bl, 0x04
mov dx, 0x0D1D
mov cx, 22
push cs
pop es
mov bp, menudirect
int 0x10

popa
pop es

mov ax, 1364
push ax
mov ax, 1350
push ax
call printScore
mov word [score] , 0

restarting:
mov ah, 0
int 0x16

cmp ax, 0x1C0D
jne restarting

beginner:

call clrscreen
jmp start


;nomatch:

;mainLOOP:




;mov ah, 0
;int 0x16	; BIOS service

call playJumpSound
	

;jmp terminate

;jmp mainLOOP





terminate:
mov ax, 0x4c00
int 0x21
