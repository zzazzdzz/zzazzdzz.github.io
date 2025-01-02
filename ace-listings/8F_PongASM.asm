                               ; MODULE ENTRY POINT/ WRA1:D901

jr   D920_EntryPoint           ; jump over subroutines below to D920, a real entry point
                               ; SUBROUTINE/ WRA1:D903
                               ; Increments the D register. Used in conditional jumps.
D903_IncrementD:
inc  d
ret  
                               ; SUBROUTINE/ WRA1:D905
                               ; Decrements the D register. Used in conditional jumps.
D905_DecrementD:
dec  d
ret  
                               ; SUBROUTINE/ WRA1:D907
                               ; Increments the value of address (hl) and sets zero flag after using. Used in conditional jumps.
D907_IncHLSetZero:
inc  (hl)                      
xor  a                         ; Since every a XOR a equals 0, this instruction will set the zero flag
ret  
                               ; SUBROUTINE/ WRA1:D907
                               ; Increments the value of address (HL) and sets zero flag after using. Used in conditional jumps.
D90A_DecHLSetZero:
dec  (hl)
xor  a                         ; Since every a XOR a equals 0, this instruction will set the zero flag
ret  
                               ; SUBROUTINE/ WRA1:D90D
                               ; Handles ball bounces off the walls and the pad. Plays a bounce sound using a native sound handling subroutine.
							   ; HL -> Ball direction byte address (always FFA0)
							   ;  C -> Direction byte (F0 if bouncing off the X axis, 0F if bouncing off the Y axis)
D90D_BallBounce:
ld   b,a                       ; Loads the A register to B, to restore it later
ld   a,c                       ; Loads the direction byte to A
xor  (hl)                      ; XORs the direction byte with the ball's current direction address
ld   (hl),a                    ; Loads the operation result to the ball's current direction byte
ld   a,$AF                     ; Load the sound identifier (AF == short beep)
call $23B1                     ; Play the sound (external subroutine)
ld   a,b                       ; Restore the A register back from B
ret  
                               ; JUMP DESTINATION/ WRA1:D918
							   ; Plays the 'game over' sound and restarts the game
D918_GameOver:
ld   a,$A6                     ; Load the sound identifier (A6 == error sound)
call $23B1                     ; Play the sound (external subroutine)
call $3748                     ; Wait for sound to be done playing (external subroutine)
                               ; Return instruction omitted on purpose - this will continue to run the code at D920, resetting the game in the process
							   
                               ; JUMP DESTINATION/ WRA1:D920
							   ; The program's entry point
D920_EntryPoint:
ld   d,$0E                     ; Set the pad's initial position to 15 (0x0E)
ld   hl,$FFA2                  ; Loads FFA2 (ball X location) address to HL
ld   (hl),d                    ; Sets the ball initial X location to 15 (0x0E)
inc  l                         ; HL=FFA3 (ball Y location)
ld   (hl),d                    ; Sets the ball initial Y location to 15 (0x0E)
ld   a,$FF                     ; Load the sound identifier (FF == mute music)
call $23B1                     ; Play the sound (here: mute the music)
dec  d                         ; Set the pad's position to 14 (0x0D)

                               ; JUMP DESTINATION/ WRA1:D92E
							   ; Does all the drawing and game calculations
D92E_DoGameTick:               
ld   bc,$0168                  ; Argument #1: Write 168 bytes...
ld   hl,$C3A0                  ; Argument #2: to location $C3A0 (screen I/O)...
ld   a,$10                     ; Argument #3: of value $10 (black tile)
push hl                        ; Saves HL for later use
call $36E0                     ; Set BC bytes of A starting from address HL (external subroutine) - clears the screen
pop  hl                        ; Restores HL for a while to clean up the stack
push de                        ; Saves DE (pad X location) for later use
push hl                        ; Saves HL (screen IO address) for later use
ld   hl,$C4E0                  ; Loads C4E0 to HL (screen IO 17th line)
ld   a,l                       
add  d                         
ld   l,a                       ; Adds pad X position to the lower byte of HL to calculate the pad's drawing location
xor  a                         ; Set A to 0 (white tile)
ldi  (hl),a
ldi  (hl),a
ldi  (hl),a
ldi  (hl),a                    ; Draw a 4-block-wide pad

                               ; SECTION/ WRA1:D948
							   ; Handles the collision detection with the walls and the pad

ld   hl,$FFA0                  ; Loads the ball direction byte address
ld   c,$0F                     ; Loads the invert byte 0F (bounce off X axis)
ld   a,($FF00+A2)              ; Loads the ball X coordinate
and  a
call z,D90D_BallBounce         ; If X=0, do the bounce off the X axis
cp   a,$13
call z,D90D_BallBounce         ; If X=$13 (DEC 19), do the bounce off the X axis
ld   c,$F0                     ; Loads the invert byte 0F (bounce off Y axis)
ld   a,($FF00+A3)              ; Loads the ball Y coordinate
and  a
call z,D90D_BallBounce         ; If Y=0, do the bounce off the Y axis
cp   a,$11
jp   z,D976_UpdateBallPosition ; If Y=$11 (DEC 17), the lower part of the screen, it's game over
cp   a,$0F                     ; Check if Y=$0F (DEC 15) - the vertical position of the pad
jr   nz,D976_Continue          ; If it isn't there's no need to check for collision with the pad
ld   e,d
ld   b,$04
ld   a,($FF00+A2)              ; Load the ball X location to register A
D96E_Loop1:
cp   e                         ; Check if the ball touches the pad
call z,D90D_BallBounce         ; Bounce if it does
inc  e
dec  b
jr   nz,D96E_Loop1             ; Check it for all 4 spots on the pad

                               ; JUMP DESTINATION/ WRA1:D976
							   ; Moves the ball on diagonals based on the direction byte
D976_UpdateBallPosition:
ld   a,(hl)                    ; Load the ball direction byte to register A
inc  l
inc  l                         ; HL=FFA2 (address of ball's X position)
ld   b,a                       ; Store a copy of the direction byte for later comparisons
and  a,$0F                     ; Check if the lower nibble of the direction byte is 0xF
call z,D907_IncHLSetZero       ; If it is, increment X position
call nz,D90A_DecHLSetZero      ; If it isn't, decrement X position
inc  l                         ; HL=FFA3 (address of ball's Y position)
ld   a,b
and  a,$F0                     ; Check if the upper nibble of the direction byte is 0xF
call z,D907_IncHLSetZero       ; If it is, increment Y position
call nz,D90A_DecHLSetZero      ; If it isn't, decrement Y position

                               ; SECTION/ WRA1:D98C
							   ; Calculates the drawing location (screen IO address) for the ball
							   
pop  hl                        ; Restore HL from all the way before (HL is now screen IO address)
ld   a,($FF00+A2)              ; Loads the ball X position
add  l                         
ld   l,a                       ; Adds it to HL to calculate the ball's X drawing location
ld   a,($FF00+A3)              ; Loads the ball Y position
ld   bc,$0014                  ; BC=0014: screen's width: adding it to HL will advance the drawing location 1 block downwards
and  a                         ; Check if A is equal to 0
jr   z,D99D_DrawBall           ; If it is, skip the loop, as the ball drawing position is already calculated

                               ; JUMP DESTINATION/ WRA1:D999
							   ; Part of the ball's drawing location calculation
D999_DrawBallLoop:
add  hl,bc                     ; Increase the Y drawing location by 1 block
dec  a                         ; Decrement the Y coordinate
jr   nz,D999_DrawBallLoop      ; Jump back if it is not equal to 0

                               ; JUMP DESTINATION/ WRA1:D99D
							   ; Draws the ball on the screen
D99D_DrawBall:
ld   (hl),a                    ; Yeah, that was very hard...

                               ; SECTION/ WRA1:D99E
							   ; Checks for key input, moves the pad accordingly
							   
pop  de                        ; Restore DE from all the way before (D contains now pad's X coordinate)
ld   a,d                       
cp   a,$10                     ; Check if the pad is on the screen's rightmost edge
jr   z,D9AB_SkipRightKey       ; If it is, skip this check so the pad does not go outside the screen bounds
ld   a,($FF00+F8)              ; Load key input address
and  a,$10                     ; Check for bit 4
call nz,D903_IncrementD        ; Increment the pad X location if it is set

                               ; JUMP DESTINATION/ WRA1:D9AB
							   ; Part of key input checking
D9AB_SkipRightKey:             
ld   a,d
and  a                         ; Check if the pad is on the screen's leftmost edge
jr   z,D9B6_DelayFrames        ; If it is, skip this check so the pad does not go outside the screen bounds
ld   a,($FF00+F8)               ; Load key input address
and  a,$20                     ; Check for bit 5
call nz,D905_DecrementD        ; Decrement the pad Y location if it is set

                               ; JUMP DESTINATION/ WRA1:D9B6
							   ; Renders the screen, delays 5 frames and returns back to the game tick procedure
D9B6_DelayFrames:
halt 
halt 
halt 
halt                           ; Delays 5 frames
halt                           ; Interrupts are enabled, so NOPs after HALTs are not necessary.
jp   D92E_DoGameTick           ; Long jump back to the game tick beginning