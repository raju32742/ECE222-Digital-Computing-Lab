// ---------------------------------------------------------------------------------
// Name: Lab_4.S
// Purpose: This code has 2 parts: the first part is to flash all 8 LED's on and
// off at a rate between 1 - 10Hz while the random number generator is called
// continuously. The random number generated will give a time delay of 5.0
// to 25.0 seconds with a resolution of 0.1s. Pressing pushbutton S1
// will create an interrupt in the microprocessor, forcing the interrupt service
// routine (ISR) to run. The ISR displays this random number on the 8 LED's (without
// a decimal). It delays for 1 second (count of 10), updating the count until it
// reaches zero. The program then exits the ISR and returns to the main program to
// flash all 8 LEDs again. The process repeats when the pushbutton S1 is pressed again.
// Author: Julius Olajos
// ---------------------------------------------------------------------------------

.section .text
.align 2
.globl _start

// Constants
GPIO_BASE = 0x10012000 // GPIO base address
GPIO_OUTPUT = 0x0C // GPIO output register offset
GPIO_OUTPUT_ENABLE = 0x08 // GPIO output enable register offset
GPIO_INPUT = 0x00 // GPIO input register offset
GPIO_INPUT_ENABLE = 0x04 // GPIO input enable register offset
GPIO_7SEGLED_PINS = 0x0000023F // Seven Segment LED Display Pins (7)
GPIO_LEDBAR_PINS = 0x00FC0C00 // LED Bar Pins (8)
GPIO_ALL_LED_PINS = 0x00FC0E3F // All LED Pins (15)
GPIO_FALL_INTERRUPT_ENABLE = 0x20 // Falling edge interrupt enable register offset
GPIO_FALL_INTERRUPT_PENDING = 0x24 // Falling edge interrupt pending register offset
GPIO_IO_FUNCTION_ENABLE = 0x028 // I/O function enable register offset
GPIO_IO_FUNCTION_SELECT = 0x02C // I/O function select register offset
GPIO_ON_MASK = 0xC004C00 // Mask to turn on all 8 LEDs for flashing
PLIC_BASE = 0x0C000000 // PLIC base address
PLIC_ENABLE = 0x2000 // PLIC interrupt enable register offset
PLIC_PRIORITY = 0x0004 // PLIC priority register offset
PLIC_THRESHOLD = 0x200000 // PLIC threshold register offset
PLIC_CLAIM = 0x200004 // PLIC claim/complete register offset
PLIC_INT_PEND = 0x1000 // PLIC interrupt pending register offset
S1_GPIO_PIN = 12 // S1 pushbutton pin number (active low)
S1_IRQ = 12 // IRQ number for GPIO pin 12
S1_PLIC_ID = 20 // PLIC interrupt source ID for GPIO pin 12
S1_PRIORITY = 7 // Interrupt priority for S1

// ---------------------------------------------------------------------------------
// This is the setup for the interrupt functionality of the RISC-V processor
// ---------------------------------------------------------------------------------

_start:
li t0, GPIO_BASE
// Pushbuttons SW(x) Register Address Mapping

.equ GPIO_SW_1, 0x00001000 // SW1 pushbutton (bit 12)

// Set up mtvec with the address of the interrupt vector (S1_interrupt)
la t0, S1_interrupt
csrw mtvec, t0

// Enable external machine interrupts in the mie register
li t0, (1 << 11) // Enable machine external interrupts (MEIE)
csrs mie, t0

// Enable global interrupts in the mstatus register
csrr t0, mstatus
li t1, (1 << 3) // Set MIE (Machine Interrupt Enable) bit mask in mstatus
or t0, t0, t1
csrw mstatus, t0

// Set up pushbutton S1 as input in the GPIO pins
li t1, GPIO_BASE + GPIO_INPUT_ENABLE // Load GPIO input enable register address
li t2, (1 << S1_GPIO_PIN) // Set bit 12 for S1 input
sw t2, 0(t1) // Enable S1 as input

// Set up the LED's in the GPIO pins as outputs
li t1, GPIO_BASE + GPIO_OUTPUT_ENABLE // Load GPIO output enable register address
li t2, GPIO_LEDBAR_PINS // Load LED bar pin mask
sw t2, 0(t1) // Enable LED outputs

// Configure the GPIO interrupt to trigger when S1 is pressed (falling edge)
li t1, GPIO_BASE + GPIO_FALL_INTERRUPT_ENABLE // Load falling edge interrupt register
li t2, (1 << S1_GPIO_PIN) // Set bit 12 for S1
sw t2, 0(t1) // Enable falling edge interrupt for S1

// Enable PLIC for S1 interrupt
li t1, PLIC_BASE + PLIC_ENABLE // Calculate address of PLIC interrupt enable register
li t2, (1 << 20) // Set bit 20 for PLIC Interrupt Source ID = 20 (GPIO pin 12)
sw t2, 0(t1)

// Set PLIC priority for S1 interrupt
li t1, PLIC_BASE
li t2, 4 * (S1_PLIC_ID) // Calculate address of Interrupt Priority Register
add t2, t2, t1
li t3, S1_PRIORITY // Set interrupt priority = 7
sw t3, 0(t2)

// Set PLIC threshold to 6 (allow all interrupts)
li t1, PLIC_BASE + PLIC_THRESHOLD // Calculate address of PLIC threshold register
li t2, 6 // Set threshold to 6, masks all interrupts of priority 6 or less
sw t2, 0(t1)

// ---------------------------------------------------------------------------------
// Main program loop for flashing LEDs at exactly 1 Hz
// ---------------------------------------------------------------------------------

// Initialize random number generator
li a7, 0xABCD // Seed value for RNG

main_program:
li t0, GPIO_BASE

// Turn on all LEDs
li t1, GPIO_BASE + GPIO_OUTPUT // Load GPIO output register address
li t2, GPIO_LEDBAR_PINS // Load LED bar pin mask
sw t2, 0(t1) // Turn on LEDs

// Delay for 500ms (ON time)
li a0, 5 // 5 units * 100ms = 500ms
jal DELAY // Call delay subroutine

// Turn off all LEDs
li t1, GPIO_BASE + GPIO_OUTPUT
li t2, 0 // Clear all bits
sw t2, 0(t1) // Turn off LEDs

// Delay for 500ms (OFF time)
li a0, 5 // 5 units * 100ms = 500ms
jal DELAY

// Generate random number
jal RandomNum
mv a4, a7 // Store random number in a4

j main_program // Repeat the main loop

// ---------------------------------------------------------------------------------
// Random Number generator Subroutine
// Register a7 holds the random number
// You can read this value anywhere in the code, but it can only be modified by this subroutine
RandomNum:
addi sp, sp, -16 // Allocate stack space
sw ra, 12(sp) // Save return address

li s4, 0x8000 // Load constant value to generate random number
and t1, a7, s4 // Mask bits of a7
li s4, 0x2000
and t3, a7, s4 // Mask another set of bits
slli t3, t3, 2 // Shift bits for random number
xor t3, t1, t3 // XOR to scramble bits
li s4, 0x1000
and t1, a7, t0
slli t1, t1, 3
xor t3, t3, t1
andi t1, a7, 0x0400 // Mask another part of a7
slli t1, t1, 5 // Shift bits for random number
xor t3, t3, t1 // XOR to scramble bits
srli t3, t3, 15 // Shift bits right
slli a7, a7, 1 // Shift bits left
or a7, a7, t3 // OR to set new value of a7 (random number)

lw ra, 12(sp) // Restore return address
addi sp, sp, 16 // Deallocate stack space
ret

// ---------------------------------------------------------------------------------
// Interrupt Service Routine (ISR) for S1 interrupt
S1_interrupt:
addi sp, sp, -16 // Allocate stack space
sw ra, 12(sp) // Save return address
sw t0, 8(sp) // Save register t0
sw t1, 4(sp) // Save register t1
sw t2, 0(sp) // Save register t2

// Acknowledge the interrupt in the PLIC (write the IRQ number to PLIC claim/complete register)
li t1, PLIC_BASE + PLIC_CLAIM // Get address of PLIC claim/complete register
lw t5, 0(t1) // Read the PLIC Interrupt ID

// Calculate the countdown time from the random number in a7
li t1, 200 // Range is 200 (250-50)
remu t0, a7, t1 // Get remainder 0-200
addi t0, t0, 50 // Add 50 to get range 50-250
mv a4, t0 // Store in a4

countdown_loop:
// Check if count <= 0
blez a4, end_countdown

// Display current count using DISPLAY_NUM
li t0, GPIO_BASE // Load GPIO base address
mv a0, a4 // Move current count to a0 for display
jal DISPLAY_NUM // Call display subroutine

// Delay for 1 second (10 units of 100ms)
li a0, 10 // 10 * 100ms = 1 second
jal DELAY

// Decrement count by 10 (1 second worth)
addi a4, a4, -10

j countdown_loop

end_countdown:
// Clear count
li a4, 0

// Display zero using DISPLAY_NUM
li t0, GPIO_BASE // Load GPIO base address
mv a0, zero // Display zero
jal DISPLAY_NUM

// Clear GPIO interrupt pending flag for S1
li t1, GPIO_BASE + GPIO_FALL_INTERRUPT_PENDING
li t2, (1 << S1_GPIO_PIN)
sw t2, 0(t1)

// Complete interrupt in PLIC
li t1, PLIC_BASE + PLIC_CLAIM
sw t5, 0(t1) // Writing the PLIC Interrupt ID

// Restore registers
lw ra, 12(sp)
lw t0, 8(sp)
lw t1, 4(sp)
lw t2, 0(sp)
addi sp, sp, 16

// Load main program address into mepc
la t0, main_program
csrw mepc, t0 // Write main_program address to mepc

mret

// ---------------------------------------------------------------------------------
// Display number subroutine
DISPLAY_NUM:
addi sp, sp, -16 // Allocate stack space
sw ra, 12(sp) // Save return address
sw s0, 8(sp) // Save s0
mv s0, a0 // Save the input value to s0
li t3, 0 // Initialize GPIO output to 0

// Handle lower 2 bits (bits 0-1 -> LED pins 10-11)
andi t4, s0, 0x03 // Extract bits 0-1
slli t4, t4, 10 // Shift to positions 10-11
or t3, t3, t4 // Add to output

// Handle upper 6 bits (bits 2-7 -> LED pins 18-23)
srli t4, s0, 2 // Get bits 2-7 by shifting right by 2
andi t4, t4, 0x3F // Mask to get 6 bits since 0x3F = 0011 1111
slli t4, t4, 18 // Shift to positions 18-23 of the bit field
or t3, t3, t4 // Add to output

// Write back to GPIO_OUTPUT register
sw t3, GPIO_OUTPUT(t0) // Update GPIO_OUTPUT with new LED states

lw s0, 8(sp) // Restore s0
lw ra, 12(sp) // Restore return address
addi sp, sp, 16 // Deallocate stack space
ret

// ---------------------------------------------------------------------------------
// Delay subroutine
// a0 is the argument, which specifies the number of 100ms units to delay
DELAY:
addi sp, sp, -16 // Allocate stack space
sw ra, 12(sp) // Save return address
sw t4, 8(sp) // Save t4

li t4, 800000 // Delay resolution for 100ms at 16MHz
mul t4, t4, a0 // Multiply by input parameter (number of units)

loop_delay:
addi t4, t4, -1 // Decrement t4
bnez t4, loop_delay // If not zero, continue looping

lw t4, 8(sp) // Restore t4
lw ra, 12(sp) // Restore return address
addi sp, sp, 16 // Deallocate stack space
ret
