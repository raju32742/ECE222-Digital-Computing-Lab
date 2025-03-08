// Lab_0.S
// ---------------------------------------

    .align 4
    .globl _start


_start:
    // Store 0x12345678 into memory address 0x80000000 in little-endian format
    lui     t0, 0x12345        // Load upper half of t0 with 0x12345000
    addi    t0, t0, 0x678      // Add lower half to t0 to get 0x12345678
    li      t1, 0x80000000     // Load upper half of t1 with 0x80000000
    sw      t0, 0(t1)          // Store word t0 at address pointed to by t1

    // Import values to registers - the values could be addresses or data
    li      t0, 0x123          // Load 0x123 into t0
    li      t1, 0x456          // Load 0x456 into t1
    li      t2, 0x789          // Load 0x789 into t2
    li      t3, 0xabc          // Load 0xabc into t3
    li      t4, 0xdef          // Load 0xdef into t4
    li      t5, 0x0            // Load 0x0 into t5

    // Swapping the values in t0 and t1 (t5 is used as temporary buffer)
    mv      t5, t0             // t5 <- t0 (content of t0 is stored in t5)
    mv      t0, t1             // t0 <- t1 (content of t1 is stored in t0)
    mv      t1, t5             // t1 <- t5 (content of t5 is stored in t1)

    // Adding five values together t5 <- t0 + t1 + t2 + t3 + t4
    add     t5, t0, t1         // t5 <- t0 + t1
    add     t5, t5, t2         // t5 <- t5 + t2
    add     t5, t5, t3         // t5 <- t5 + t3
    add     t5, t5, t4         // t5 <- t5 + t4

LOOP:
    j       LOOP               // Branch back to this line - an infinite loop

