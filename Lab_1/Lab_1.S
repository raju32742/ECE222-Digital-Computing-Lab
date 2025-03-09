.section .text
.globl _start
.align  2

// -------------------------------------------------------------------------------------
// Name:        Lab_1.S
// Purpose:     This code will flash a single LED at an approximate 1 Hz frequency
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------
//
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
// Initialize the GPIO control registers and run the delay loop code
// -------------------------------------------------------------------------------------

_start:

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0                   //initliaze led states
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
  
    li t5, GPIO_LEDBAR_LED_1     // Load LED_1 Address into t5 (Bit 11)

loop:
    li t4, 0x3D0900            // the value of 4000000
	
    lw t3, GPIO_OUTPUT_VAL(t0)   // Read GPIO output values into t3
    xor t3, t5, t3               // XOR the GPIO output value (all zeroes to the LEDs). 
    sw t3, GPIO_OUTPUT_VAL(t0)   // Store this new value in GPIO output register

loop1:
    addi t4,t4, -1              //decrement counter by 1
    bnez t4, loop1              //continue counter decrement until 0
    j loop                       // Once counter reaches 0, go back to loop


    // counter value is initalized to 0x3d0900 because we have a clock frequency of 16MHz It takes 2 clock cycles to complete 1 flash on and 1 flash off. 
    //This means that the delay time it takes for 1 clock cycle (period) is 1/16,000,000 seconds. but since we want 500ms delay we need to divide 500ms by the period 
    //we just calculated, this gives us 8 million clock cycles in delay to achieve a 500mx flash delay for either on or off. to get the flash delay for both on and off, we
    //take into consideration that it takes 2 cycles for the full flash leaving us a final answer of 4 million clock cycles. This number 4 Million in hex in 0x3D0900 hence our counter\
    // initial value>



