.global _start
_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.

.equ PIXEL_BUFFER, 0xc8000000
.equ CHAR_BUFFER, 0xc9000000

VGA_draw_point_ASM:
	PUSH {R3}
	LDR R3, =PIXEL_BUFFER

	ORR R3, R3, R0, LSL #1
	ORR R3, R3, R1, LSL #10

	STRH R2, [R3]
	POP {R3}
	BX LR

VGA_clear_pixelbuff_ASM:
		PUSH {R1 - R5, LR}
		MOV R2, #0	// set all pixel value to R1 = 0
		MOV R4, #0	// used to interate rows
		
loop_row:
		cmp R4, #320
		BGE loop_complete
		MOV R0, R4
		ADD R4, R4, #1
		
		MOV R5, #0	// used to interate columns
loop_column:
		cmp R5, #240
		
		BGE loop_row
		
		MOV R1, R5
		BL VGA_draw_point_ASM
		
		ADD R5, R5, #1
		B loop_column
	
loop_complete:
		POP {R1 - R5, LR}
		BX LR

VGA_write_char_ASM:
		// input Validation		
		CMP R0, #80			
		BXGE LR
		CMP R0, #0
		BXLT LR
		CMP R1, #60
		BXGE LR
		CMP R1, #0
		BXLT LR
	
		//valid input
		PUSH {R3}
		LDR R3, =CHAR_BUFFER
		ORR R3, R3, R0	
		ORR R3, R3, R1, LSL #7

		STRB R2, [R3]

		POP {R3}
		BX LR	

VGA_clear_charbuff_ASM:
	PUSH {R0-R2, LR}	
	MOV R2, #0
	MOV R0, #0
	
CHAR_LOOPX:
	MOV R1, #0
CHAR_LOOPY:
	BL VGA_write_char_ASM
	ADD R1, R1, #1
	CMP R1, #60
	BLT CHAR_LOOPY
	
	ADD R0, R0, #1
	CMP R0, #80
	BLT CHAR_LOOPX
	
	POP {R0-R2, LR}
	BX LR

@ TODO: insert PS/2 driver here.
.equ PS2_data_base, 0xFF200100
read_PS2_data_ASM:
	PUSH {R1, R2}
	LDR	R1, =PS2_data_base
	
	//extracted RVALID to R2
	LDR R2, [R1]
	LSR R2, R2, #15		
	AND R2, R2, #1
	
	// if RVALID is 1 write to address in R0
	CMP R2, #1
	BEQ VALID
	MOV R0, #0
	POP {R1, R2}
	BX LR
	
VALID:
	LDRB R2, [R1]
	STRB R2, [R0]
	MOV R0, #1
	POP {R1, R2}
	BX LR


write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}