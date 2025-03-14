# ECE222-Digital-Computing-Lab

# Lab-1: Flashing LED

## Objective
- Assemble and download a simple assembly language program.
- Modify the C wrapper code to call the Lab-1 assembly code.
- Write RISC-V assembly instructions using various memory addressing modes.
- Test and debug the code on the RISC-V Development Board.
- Flash an LED at approximately 1 Hz (500ms ON, 500ms OFF).

## Background
- **Microprocessor:** The board uses the SiFive FE-310-G002.
- **Conditional Execution:** Instead of a Program Status Register (PSR), use conditional instructions like **BNEZ** (branch if not zero) and **BEQZ** (branch if zero).
- **Hardware Interfacing:**  
  - Turn off LEDs by writing `0x00FC0E3F` to the memory address `0x1001200C` (GPIO_OUTPUT_VAL).
  - Toggle bit 11 (LED bar's bit 1) at the same address to achieve the flashing effect.

## Pre-lab
- Review the RISC-V instruction set in Appendix D.
- Consider how to implement a delay in assembly (e.g., using a loop to count cycles).
- No pre-lab deliverables are required.

## In-lab Procedure
1. **Setup:**  
   - Create a new folder (e.g., `N:\ECE222\Lab_1`) and a project as done in Lab-0.
2. **Initialization:**  
   - Begin by turning off all eight LEDs.
3. **Implement LED Flashing:**  
   - Write about 5–8 lines of code to build the main loop that toggles bit 11.
   - Use an infinite loop to toggle the LED.
   - Insert a 500ms delay between toggles so the LED blinks visibly.
4. **Code Flow:**  
   - Start with the longer flowchart provided for clarity.
   - Once the longer version works, switch to the shorter flowchart for efficiency (this will reduce code size).
5. **Assembly & Debugging:**  
   - Assemble the code.
   - Download it to the board.
   - Debug if necessary.
6. **Execution:**  
   - Run the code by selecting “Run without debugging” from the drop-down menu.

## Delay Calculation Details
- **Clock Frequency:** 16 MHz.
- **Instruction Timing:**  
  - `ADDI`: 1 clock cycle.
  - `BNEZ`: 1 clock cycle.
- Use the above information to calculate the number of iterations needed in your delay loop to achieve a 500ms delay.

For further details on GPIO ports, refer to chapter 17 of the SiFive FE310-G002 Manual v1p5.



# Lab-2: Subroutines and Parameter Passing

## Objective
Implement a Morse code transmitter using subroutines. The LED will blink a five-character word in Morse code by turning on and off with precise timing.

## Overview
This lab emphasizes structured programming by breaking the task into small, reusable subroutines:
- **LED_ON**: Turns the LED (bit 11 at address `0x1001200C`) on.
- **LED_OFF**: Turns the LED off.
- **DELAY**: Pauses execution for a duration equal to the input parameter (in register `t0`) multiplied by 500ms.
- **CHAR2MORSE**: Converts an ASCII character to a Morse code pattern using a look-up table.

## Procedure
1. **Initialization**:  
   - Turn all LEDs off at the start.
   - Define a five-character word at the label `InputLUT`:
     - The first four characters are the initials of the lab partners (capital letters).
     - The fifth character is an additional, unique capital letter.

2. **Subroutine Implementation**:
   - **LED_OFF**:  
     - Write a subroutine that sets the correct bit of address `0x1001200C` to turn off the LED.
   - **LED_ON**:  
     - Write a subroutine that sets the same bit to turn on the LED.
   - **DELAY**:  
     - Implement a delay subroutine that uses the value in register `t0` to wait for `t0 * 500ms` before returning.
   - **CHAR2MORSE**:  
     - For each character in `InputLUT`:
       - Fetch the ASCII value.
       - Subtract `0x41` to obtain the index for the Morse look-up table.
       - Read the Morse pattern corresponding to the index.
       - For each bit (starting from the MSB):
         - If bit 31 is `1`, call `LED_ON`.
         - If bit 31 is `0`, call `LED_OFF`.
         - Call `DELAY` with a delay value of 1.
         - Continue until the entire Morse pattern is processed.
   - Insert an extra long delay (three dot-equivalent delays) before processing the next character.
   - After completing the whole word, add another four delay intervals and repeat the sequence.

## Deliverable
The final program continuously processes the five-character word, blinking the LED to represent Morse code, while making use of clearly defined subroutines for each operation.

## Notes
- All subroutines use parameter passing via registers.
- Follow the memory address specifications from Lab-1.
- Refer to the provided flowchart for the detailed sequence of operations.

