/* https://github.com/cirosantilli/x86-bare-metal-examples#protected-mode */

/* Push registers ax, bx, cx and dx. Lightweight `pusha`. */
.macro PUSH_ADX
    push %ax
    push %bx
    push %cx
    push %dx
.endm

/* Pop registers dx, cx, bx, ax. Inverse order from PUSH_ADX,
 * so this cancels that one.
 */
.macro POP_DAX
    pop %dx
    pop %cx
    pop %bx
    pop %ax
.endm

begin:
    .code16
    cli
    ljmp $0, $1f
    1:
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %bp
    mov %ax, %ss
    mov %bp, %sp
    mov %dl, initial_dl
    initial_dl: .byte 0

clear:
    PUSH_ADX
    mov $0x0600, %ax
    mov $0x7, %bh
    mov $0x0, %cx
    mov $0x184f, %dx
    int $0x10

    PUSH_ADX
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0, %dh
    mov $0, %dl
    int $0x10
    POP_DAX

    POP_DAX


    /* Must come before they are used. */
    .equ CODE_SEG, 8
    .equ DATA_SEG, gdt_data - gdt_start
    //.equ STACK_SEG, gdt_stack - gdt_start
    /* Tell the processor where our Global Descriptor Table is in memory. */
    lgdt gdt_descriptor
    /* Set PE (Protection Enable) bit in CR0 (Control Register 0),
     * effectively entering protected mode.
     */
    mov %cr0, %eax
    orl $0x1, %eax
    mov %eax, %cr0
    ljmp $CODE_SEG, $protected_mode

/* GDT */
gdt_start:
gdt_null:
    .long 0x0
    .long 0x0
gdt_code:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10011010
    .byte 0b11001111
    .byte 0x0
gdt_data:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10010000
    .byte 0b11001111
    .byte 0x0
/*gdt_stack:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10010110
    .byte 0b11001111
    .byte 0x0*/
gdt_end:
gdt_descriptor:
    .word gdt_end - gdt_start
    .long gdt_start


vga_current_line:
    .long 0

.code32
protected_mode:
    /* Setup the other segments.
     * Those movs are mandatory because they update the descriptor cache:
     * http://wiki.osdev.org/Descriptor_Cache
     */
    mov $DATA_SEG, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    //mov $STACK_SEG, %ax
    mov %ax, %ss
    /* TODO detect the last memory address available properly.
     * It depends on how much RAM we have.
     */
    mov $0X7000, %ebp
    mov %ebp, %esp

vga_print_string:
    pop %edx
    pop %ecx
    pop %ebx
    pop %eax    
    mov $message, %ecx
    mov vga_current_line, %eax
    mov $0, %edx
    /* Number of horizontal lines. */
    mov $25, %ebx
    div %ebx
    mov %edx, %eax
    /* 160 == 80 * 2 == line width * bytes per character on screen */
    mov $160, %edx
    mul %edx
    /* 0xb8000 == magic video memory address which shows on the screen. */
    lea 0xb8000(%eax), %edx
    /* White on black. */
    mov $0x0f, %ah
loop:
    mov (%ecx), %al
    cmp $0, %al
    je end
    mov %ax, (%edx)
    add $1, %ecx
    add $2, %edx
    jmp loop
end:
    incl vga_current_line
    pop %edx
    pop %ecx
    pop %ebx
    pop %eax   
    
    jmp .
message:
    .asciz "hello world" 
