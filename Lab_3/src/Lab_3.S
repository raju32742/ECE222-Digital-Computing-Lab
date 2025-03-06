.section .text
.align 2
.globl _start


// -------------------------------------------------------------------------------------
// Name:        Lab_3.S
// Purpose:     This code has 2 parts: the first part is to create a simple counter
//              subroutine that increments from 0x00 to 0xFF, wraps to 0 and continues
//              counting.  There is a 100ms delay between the display of the count. 
//		The second part is a reflex meter that will measure how fast
//              a user responds to an event accurate to a 10th of a millisecond.
//              Initially, all LED's are off and after a random amount of time
//              (between 2 and 10 seconds), one LED turns on (LED_6) and then the user
//		presses pushbutton S1.  The press of the button will be monitored by
//		using "polling".
//
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------


_start:

// -------------------------------------------------------------------------------------
// GPIO Control Registers Memory Mapping
 .equ GPIO_LEDBAR_LED_6,            0x400000
    .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
    .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
    .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
    .equ GPIO_INPUT_VAL,      0x00          // Address offset for reading GPIO inputs
    .equ GPIO_INPUT_EN,       0x04          // address offset for enabling GPIO inputs
    .equ GPIO_PUE,            0x10          // address offset for internal GPIO pull-up resistor

// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

    .equ GPIO_7SEGLED_PINS,   0x0000023F      // Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,    0x00FC0C00      // LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS,   0x00FC0E3F      // All LED Pins (15)
    .equ GPIO_LEDBAR_LED_1,   0x00000800      // LEDBAR LED1

// -------------------------------------------------------------------------------------
// Pushbuttons SW(x) Register Address Mapping

    .equ GPIO_SW_1,           0x00001000      // SW1 pushbutton (bit 12)
    .equ GPIO_SW_2,           0x00002000      // SW2 Pushbutton (bit 13)
    .equ GPIO_ALL_PBS,        0x00003000      // All Pushbutton Pins (bits 12, 13)

// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
    li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
    sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

// -------------------------------------------------------------------------------------

INITIAL:

// Initialize random number generator
 	li a7, 0xABCD                   // Initializes register a7 to a 16-bit non-zero value and NOTHING else can write to a7 !!!!



/*
//   --------------- Place your code here for the 00 - FF counter here ---------------
//part 1 start
COUNTER:


li t1, 0xFF //max counter value
li t0, 0x00 //initalize counter to 0

NOT0XFF:
    //DISPLAY
jal ra, DISPLAY_NUM //display current counter value

//DELAY
li a0, 0x3E8//0x3E8 //load delay
jal ra, DELAY



bge t0, t1, COUNTER // If counter >= 0xFF, reset to 0



//display
 addi t0, t0, 1 //increment counter
 jal ra, NOT0XFF //loop back

//part 1  end
*/

// -------------------------------------------------------------------------------------

loop:
//  Generate random number
        jal ra, RandomNum //generate random delay value

//  Once your number has been generated, it will be stored in register a7. Do not overwrite this!
//  You will now need to set up delays, subroutines to turn the LED ON and OFF, and for polling whether the Pushbutton S1 has been pressed.
//  Keep in mind that you will get a 32-bit number back from the random number generator.  You will need to display this 8 bits at a time,
//  starting with the lowest 8 bits.
//  You will probably want to rotate 8 bits at a time for display.

   li t1, 0x80        # Load x into t1 (modulus for random range)
    li t2, 0x276        # Load y into t2 (multiplier for scaling)
    li t3, 0x4E20        # Load z into t3  (linear shift)

    rem t4, a7, t1     # t4 = a7 % x (modulo operation) 
    mul t5, t4, t2     # t5 = (a7 % x) * y (Scale random value)
    add a0, t5, t3     # a0 = ((a7 % x) * y) + z (Add base delay)
 
    # a0 now contains the result

jal ra, DELAY //execute random delay

    li t3, GPIO_LEDBAR_LED_6 //load led 6
    sw t3, GPIO_OUTPUT_VAL(t0) //turn on led 6

li t4, 0x0 //initalize reaction time counter



polling:
    li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
    sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

    lw t1, GPIO_INPUT_VAL(t0) //read button state
    li t2, 0x1000 //mask for the 12th bit
    li a0, 0x1 //0.1 ms delay value
  jal ra, DELAY //execute delay
    addi t4, t4, 1 //increment counter

xori t1, t1, -1 //invert input bits bc button is active low
and t5, t2, t1 //mask to isolate and check the bits (AKA. check if the button has been pushed)


beqz t5, polling //if button not pressed continue polling

//reaction time counter is t4
li t1, 0x0 //initalize display counter

mv a3, t4 //save reaction time value for when we repeat the display again


DISPLAY:    

// Display the 32-bit number on the 8-LED Bar

// Register t1 holds the value of the number to be displayed
// Map each bit of the number to the corresponding LED Bar bit
// MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10
//


//mask is 0xFF
li t0, 0xFF //load mask

and t0, t0, t4 //mask current byte of reaction time

jal ra, DISPLAY_NUM //display
li a0, 0x4E20 //delay
jal ra, DELAY
srli t4, t4, 8 //shift to the next byte
li t5, 5 //number of times we will shift
addi t1, t1, 1 //increment counter
blt t1, t5, DISPLAY //continue if more bytes to display

j END //jump to end

DISPLAY_NUM: //subrountine to display a byte on leds
      addi sp, sp, -16  
      sw ra, 12(sp)
      sw t0, 8(sp)
      sw t4, 4(sp)
      sw t5, 0(sp)

slli t0, t0, 10 //shift value to allign bit with led position
li t5, 0x0 // led output mask

li t4, 0xC00 //maskk to isolate 10, 11
and t5, t0, t4 //store in t5

slli t0, t0, 6 //shift upper led bits
li t4,0xFC0000 //mask for upper led bits
and t0, t0, t4 //isolate upper led bits
or t5, t5, t0 //combine both isolated bits

    li t0, GPIO_BASE_CTRL_ADDR      
    sw t5, GPIO_OUTPUT_VAL(t0) //update led display

// Remember, the 8 LEDS are mapped to the GPIO as bits MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10

//   --------------- Place your code here for displaying the 8-bit values --------------- 
      lw t4, 4(sp)
      lw t5, 0(sp)
      lw t0, 8(sp)
      lw ra, 12(sp)
      addi sp, sp, 16
      ret




// Random Number generator
// Register a7 holds the random number.
// You can read this value anywhere in the code, but this register can only be written to by this subroutine
// Or Else!

RandomNum:
     addi sp, sp, -16
     sw ra, 12(sp)


     li s4, 0x8000		     // Load upper 20 bits
     and t1, a7, s4  		     // Mask to lower 16 bits
     li s4, 0x2000  		     // Load upper 20 bits
     and t3, a7, s4  		     // Mask to lower 16 bits


     slli t3, t3, 2
     xor t3, t1, t3
     li s4, 0x1000  		     // Load upper 20 bits
     and t1, a7, t0		     // Mask to lower 16 bits

     slli t1, t1, 3
     xor t3, t3, t1
     andi t1, a7, 0x0400
     slli t1, t1, 5
     xor t3, t3, t1
     srli t3, t3, 15
     slli a7, a7, 1
     or a7, a7, t3		     // Register a7 holds the random number

     lw ra, 12(sp)
     addi sp, sp, 16
     ret


DELAY:
     addi sp, sp, -16
     sw ra, 12(sp)
     sw a0, 8(sp)
     sw t4, 4(sp)



    loop0: //Outer loop for n = a0 iterations
        li t4, 0x320  // load 800 into t4, 800 is the number of cycles for 0.1ms 
        loop1: //decrementation of loop till counter (t4) reaches 0
        addi t4, t4, -1          //retrieves the value held in register t4 and decrements by 1, storing the new value in t4
        bnez t4, loop1
    addi  a0, a0, -1   //deincrement
    bnez a0, loop0


//   --------------- Place your code here for the various delays and timers --------------- 
     lw t4, 4(sp)
     lw a0, 8(sp)
     lw ra, 12(sp)
     addi sp, sp, 16
     ret


END:
li t1, 0x0 //clear counter
li a0 ,0xC350 //load delay value between restarting (5 seconds)
jal ra, DELAY //delay
mv t4, a3 //restore reaction time again to redisplay
j DISPLAY //display again



//LAB REPORT QUESTIONS

// ANSWER TO QUESTION 1: 
//We can calculate the maximum time per bit size by finding the maximum value each bit size can store, then multiplying by 0.1 ms.

//8 bits:
//Max value: (2^8)-1 = 255 
//Maximum time = 255 * 0.1ms = 25.5 ms

//16 bits:
//Max value: (2^16)-1 = 65,535
//Maximum time = 65,535 * 0.1ms = 6,553.5 ms

//24 bits:
//Max value: (2^24)-1 = 16,777,215
//Maximum time = 16,777,215 * 0.1ms = 1,677,721.5 ms

//32 bits:
//Max value: (2^32)-1 = 4,294,967,295 
//Maximum time = 255 * 0.1ms = 4,294,967,29.5 ms

// ANSWER TO QUESTION 2: 
//Based on online research and experiments conducted in lab, the average reaction time is approximately 300ms. We can conclude that the the 8-bit counter would be too fast and so the 16 bit counter will be more than adequaate to cover the average human reaction time and more.

//ANSWER TO QUESTION 3
//For a delay of 2 to 10 seconds ±5%, the allowed delay range would be:  1.9s <= t <= 10.5s
// the formula we used was ((a7 % 128) * 630) + 20,000
// a7 % 128 has a value in the range [0, 127], we then multiply by 630 to scale the number to be in the range of: [0, 80,010], lastly we add a 20,000 offset. which gives a range of  [20,000 , 100,010].
// converting 20,000 to seconds gives 2 seconds and 100,010 to seconds gives 10.001 seconds. These two numbers are well within the alowed range.