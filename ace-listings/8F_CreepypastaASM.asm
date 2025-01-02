; MODULE ENTRY POINT/ WRA1:D901
; AFTER USING 8F
; This is just a routine which prepares the environment.
; It contains nothing more than 8-bit loads and stores.

ld hl,$d31d
ld (hl),$01      ; Set $D31D to $01 [1 item in your bag]
inc hl
ld (hl),$48      ; Set $D31E to $48 [Silph Scope]
inc hl
inc hl
ld (hl),$ff      ; Set $D320 to $FF [end of list]
ld hl,$d163
ld (hl),$01      ; Set $D163 to $01 [1 Pokemon in your party]
inc hl
ld (hl),$91      ; Set $D164 to $91 [Marowak]
inc hl
ld (hl),$ff      ; Set $D165 to $FF [End of list]
ld hl,$d16b
ld (hl),$91      ; Set $D16B to $91 [Marowak]
inc hl
ld (hl),$0
inc hl
ld (hl),$1       ; Set $D16C to $0001 [Current HP = 1]
inc hl
ld (hl),$1       ; Set $D16E to $01 [Level 1]
xor a
ldi (hl),a
ldi (hl),a
ldi (hl),a       ; Set $D16F-$D171 to $00 [No status ailments]
ld hl,$d173
ld (hl),$6a      ; Set $D173 to $6A [First move = Harden]
inc hl
ld (hl),$0       ; Set $D174 to $00 [End of list]
ld hl,$d18c
ld (hl),$1       ; Set $D18C to $01 [Level 1]
inc hl
ld (hl),$0
inc hl
ld (hl),$1       ; Set $D18D to $0001 [Max HP = 1]
inc hl
ld (hl),$0
inc hl
ld (hl),$5       ; Set $D18F to $0005 [Attack Stat = 5]
inc hl
ld (hl),$0
inc hl
ld (hl),$5       ; Set $D191 to $0005 [Defense Stat = 5]
inc hl
ld (hl),$0
inc hl
ld (hl),$5       ; Set $D193 to $0005 [Speed Stat = 5]
inc hl
ld (hl),$0
inc hl
ld (hl),$5       ; Set $D195 to $0005 [Special Stat = 5]
ld hl,$d355
ld (hl),$ff      ; Set $D355 to $FF [Very slow text speed]
ld hl,$d2b5
ld (hl),$7f
inc hl
ld (hl),$50      ; Set $D2B5 to {$7F, $50} [1st Pokemon's nickname is a blank space]
ld hl,$d36c
ld (hl),$03
inc hl
ld (hl),$db      ; Set $D36C to $03DB [Repoint current map's text table to $DB03]
inc hl
ld (hl),$01
inc hl
ld (hl),$db      ; Set $D36E to $01DB [Repoint current map's script to $DB01]
ld hl,$d52c
ld (hl),$22
inc hl
ld (hl),$22      ; Set $D52C to $2222 [Has no other purpose than glitching up the tiles after loading the save]
xor a
inc a
ld (d4e1),a      ; Set $D4E1 to $01 [Remove all the sprites except the first one]
ld (c110),a      ; Set $D4E2 to $01 [Set the first sprite's graphics to a picture of Red]
ld (c120),a      ; Set $D4E3 to $01 [Make the second sprite disappear]
ld (c130),a      ; Set $D4E3 to $01 [Make the third sprite disappear]
ld (c140),a      ; Set $D4E3 to $01 [Make the fourth sprite disappear]
ld (c150),a      ; Set $D4E3 to $01 [Make the fifth sprite disappear]
ld (d74b),a      ; Set $D74B to $01 [Make the game think that the player does not have the Pokedex]    
ld a,50
ld (d158),a      ; Set $D158 to $50 [Make the player's name blank]
ret

;-------------------------------------------------------------------------------

; MODULE ENTRY POINT/ WRA1:DB01
; AFTER LOADING THE SAVE/MAP SCRIPT
; This is where all that magic happens.

jr DB05_MapScriptMain

dw _DBA5_Tx_DoNotBe ; Text pointer for text ID $01 ["DO NOT BE AFRAID"]
dw _DBCF_Tx_ThereIs ; Text pointer for text ID $02 ["THERE IS NO ESCAPE"]

DB05_MapScriptMain:

ld hl,$d0c7
ld a,$3f
ldi (hl),a          ; Making sure that the ghost Missingno. will always load the move $3F (Hyper Beam)
xor a
ldi (hl),a
ldi (hl),a
ldi (hl),a

ld hl,$d52c     
ld a,$c0
ldi (hl),a
ld a,$45
ld (hl),a           ; This resets the glitched map so it works properly after the first event has passed

ld hl,$ffa3         ; Loads $FFA3 into HL (the event flag created just for this map's purposes)
push hl             ; Store it for later use
ld a,(hl)
cp a,$01            ; Check if the first event ('do not be afraid' dialog) is complete

jr nz,DB34_Skip1    ; Skip the event if it ISN'T already cleared

ld a,$40
ld ($ccd3),a
xor a
ld ($cd39),a
inc a
ld ($cd38),a
cpl
ld ($d730),a        ; Make the player go forward...

DB34_Skip1:

ld a,($d361)
sub a,$05           ; But if Player's Y coordinate is less than $05...
jr nc,DB42_Skip2
xor a
ld ($d730),a        ; Do not execute the scripted movement
ld ($cd38),a         

DB42_Skip2:

ld a,($d362)
cp a,$13            ; Check if Player's X coordinate is $13
jr nz,DB6C_Skip3    ; If it is not, skip this event
ld a,$02
ld ($ff00+8c),a
call $2920          ; Display the text ID #2 (THERE IS NO ESCAPE)
ld a,$ff
ld ($d127),a        ; Change the opponent's level to 255
ld ($d05c),a        ; Make the gym leader music play
ld ($cc47),a        ; Make the game crash after blacking out
xor a
ld ($d355),a        ; Set the text speed to super fast
ld a,$b8
ld ($d059),a        ; Set the ghost-form missingno as your opponent
ld b,$1c
ld hl,$7b6a
call $35d6          ; Delete the save file (indirect call to 1C:7B6A)

DB6C_Skip3:

pop hl
push hl             ; Restore the HL state from earlier (HL=$FFA3)
ld a,(hl)
and a               ; Check if the first event ('do not be afraid' dialog) is complete
jr nz,DB8E_Skip4    ; Skip this check if this event is already completed

inc (hl)            ; Set the event flag
ld b,$60

DB75_Delay:         ; This loop is used to make the sound disappear after loading the save
ld a,$ff
call $23b1          ; Mute the sound
halt                ; Wait one frame
dec b
jr nz, DB75_Delay   ; Repeat $60 times

ld hl,$c709
ld de,DB90_MapDataRLE
call $350c          ; Decompress the map data to $C709
ld a,$01
ld ($ff00+8c),a
call $2920          ; Display the text ID #1 (DO NOT BE AFRAID)

DB8E_Skip4:

pop hl
ret                 ; Return

DB90_MapDataRLE:
db 52,27            ; Byte $52 repeated $27 times
db 0e,08            ; Byte $0E repeated $08 times
db 52,08            ; Byte $52 repeated $08 times
db 0e,02            ; Byte $0E repeated $02 times
db 52,0e            ; Byte $52 repeated $0E times
db 0e,02            ; Byte $0E repeated $02 times
db 52,0e            ; Byte $52 repeated $0E times
db 0e,02            ; Byte $0E repeated $02 times
db 52,0e            ; Byte $52 repeated $0E times
db 0e,e0            ; Byte $0E repeated $E0 times
db ff

_DBA5_Tx_DoNotBe:
db 00,83,8e,7f,8d,8e,93,4f,81,84,7f,80,85,91,80,88,83,51
db 88,93,7f,96,8e,8d,93,7f,87,84,8b,8f,4f,98,8e,94,7f,80,93,7f,80,8b,8b,57
; DO NOT BE AFRAID :: IT WONT HELP YOU AT ALL

_DBCF_Tx_ThereIs:
db 00,93,87,84,91,84,7f,88,92,4f,8d,8e,7f,84,92,82,80,8f,84,51
db 92,80,98,7f,81,98,84,7f,93,8e,4f,98,8e,94,91,7f,92,80,95,84,7f,85,88,8b,84,57
; THERE IS NO ESCAPE :: SAY BYE TO YOUR SAVE FILE