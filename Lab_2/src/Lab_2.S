.section .text
.align 2
.globl _start

// -------------------------------------------------------------------------------------
// Name:        Lab_2.S
// Purpose:     This code will convert a string of ASCII chracters into Morse code
//              and flash a single LED (Led Bar LED_7) in Morse code with a time base
//		of approximately 500ms.
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------


_start:

// -------------------------------------------------------------------------------------
// GPIO Control Registers Memory Mapping

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
    .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
    .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR

// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

    .equ GPIO_7SEGLED_PINS, 0x0000023F      // Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x00FC0C00      // LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x00FC0E3F      // All LED Pins (15)
    .equ GPIO_LEDBAR_LED_1, 0x00000800      // LEDBAR LED1
// -------------------------------------------------------------------------------------
// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0x00
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.


// Reset s1 to the starting address of the input string
ResetLUT:
    la s1, InputLUT           // assign s1 to the address at label LUT (our input word)

// Start processing each character byte by byte
NextChar:
    lbu a0, 0(s1)             //read the character at the address s1 (s1 is the address of the letter)
    addi s1, s1, 1            // point to next value for number of delays, jump by 1 byte
    snez a1, a0               // If we read character 0 (null at end of the string) then reset to the start of lookup table
    bnez a1, ProcessChar      // If we have a character process it

    //once all characters are read, put a 6 dot delay
    li a2, 16
    jal ra, DELAY
    j ResetLUT //after 6 dot delay, reset and restart

//jumps to char2morse subroutine
ProcessChar:
    jal ra, CHAR2MORSE        // convert ASCII to Morse pattern in a1

// Turn the LED On
LED_ON:
    addi sp, sp, -16 //make space in the stack (decrease stack pointer by 16 bytes)
    sw ra, 12(sp) //store current return address in the stack
    sw t4, 8(sp) //store current t4 value in stack
    sw t3, 4(sp) //store current t3 value in stack

    lw t3, GPIO_OUTPUT_VAL(t0) // read GPIO output value into t3
    li t4, 0x00800000 //bit 23 to 1 (for LED 7)
    or t3, t3, t4 // set bit 23 to 1 (led 7)
    sw t3, GPIO_OUTPUT_VAL(t0)  // Store new value in GPIO output register

    lw t3, 4(sp) //restore t3 from stack
    lw ra, 12(sp) //restore return address from stack
    lw t4, 8(sp) //restore t4 from stack
    addi sp, sp, 16 // increase stack pointer by 16 bytes
    ret

// Turn the LED Off
LED_OFF:
    addi sp, sp, -16 
    sw ra, 12(sp)
    sw t4, 8(sp)
    sw t3, 4(sp)

    lw t3, GPIO_OUTPUT_VAL(t0) // read GPIO output value into t3
    li t4, 0xFF7FFFFF //bit 23 to 0 (for LED 7)
    and t3, t3, t4  // set bit 23 to 0 (led 7)
    sw t3, GPIO_OUTPUT_VAL(t0)   // Store new value in GPIO output register

    lw t3, 4(sp)
    lw ra, 12(sp)
    lw t4, 8(sp)
    addi sp, sp, 16
    ret

//  Delay Routines
DELAY:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t4, 4(sp)

    mv t5, a2 //to copy value of a2 (multiplier) into t5
    

    loop1:
        li t4, 0x3D0900 //roughly 500ms countdown

    loop2:
        addi t4, t4, -1 // decrement 1 from 500ms countdown
        bnez t4, loop2 // if t4 is not 0 (still more time remaining), loop again (keep decrementing)
    
    addi t5, t5, -1 //decrement one from multiplier countdown
    bnez t5, loop1 //if not zero (multiples still remanin), loop entire process again

    lw ra, 12(sp)
    lw t4, 4(sp)
    addi sp, sp, 16
    ret


CHAR2MORSE:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t4, 4(sp)
    sw t3, 8(sp)

    la s2, MorseLUT //loads address of morse table to s2

    addi a0, a0, -0x41 //subtract 41 from asci value to find index (A would be index 0)
    
    slli a0, a0, 1 //multiplies a0 by 2 (each index represents 2 bytes entry and each morse value is 16bit)
    add t1, s2, a0 //adds index found from input to base address of morse table to create address of next morse letter
    lhu a3, 0(t1) //loading what value is at that index of morse table to a3

    leftshift:
        li t3, 0x80000000 //32 bit where MSB is 1
        and t4, a3, t3 //check if MSB of morse value is 0 (haven't reached start of relevant bits yet)
        bnez t4, morse_read //t4 is zero when the MSB is not 1, if it is one, begin reading relevant bits
        slli a3, a3, 1 //if MSB is still 0, shift a3 by 1
        j leftshift

    morse_read:
        and t4, a3, t3 //check if current MSB is 1
        bnez t4, turn_on //if it is 1, begin turn on process
        j turn_off //otherwise, begin turn off process

        turn_on:
            jal ra, LED_ON //link return address, jump to LED_ON
            j delay_branch 

        turn_off:
            jal ra, LED_OFF //link return address, jump to LED_OFF

        delay_branch:
        li a2, 1 //set a2 to 1 for 1 dot delay
        jal ra, DELAY //link return address, jump to DELAY
        slli a3, a3, 1 //shift morse value left (discards MSB we dealt with so we can go to next value)
        bnez a3, morse_read //if a3 is zero, that means all 1s were read and morse is printed for that character
        
    li a2, 3 //set a2 to 3 for 3 dot delay between
    jal ra, LED_OFF //turn the led off, current character is done
    jal ra, DELAY //call 3 dot delay between characters

    lw t3, 8(sp)
    lw t4, 4(sp)
    lw ra, 12(sp)	
    addi sp, sp, 16	
    j NextChar //jump to nextchar	
    ret

// Data used in the program

.align 2

// Character input string

InputLUT:
    .asciz "RA" //initals + A (Ben Sadeh Sarala Edirisinghe A)


// Morse Code Look Up Table

.align 2
MorseLUT:
    .half 0x17, 0x1D5, 0x75D, 0x75   // A, B, C, D
    .half 0x1, 0x15D, 0x1DD, 0x55    // E, F, G, H
    .half 0x5, 0x1777, 0x1D7, 0x175  // I, J, K, L
    .half 0x77, 0x1D, 0x777, 0x5DD   // M, N, O, P
    .half 0x1DD7, 0x5D, 0x15, 0x7    // Q, R, S, T
    .half 0x57, 0x157, 0x177, 0x757  // U, V, W, X
    .half 0x1D77, 0x775              // Y, Z

End:
  .end

  // using t3 and t4