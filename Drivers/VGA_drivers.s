.global _start
_start:
        bl      draw_test_screen
end:
        b       end

@ TODO: Insert VGA driver functions here.

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

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071