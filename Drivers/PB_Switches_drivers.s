/* NOTE:
The compiler will produce breakpoints that can pause execution. This does not indicate an error has occurred. 
To get a smooth execution of the code, turn off the:
Device-specific warnings
*/

.global _start
_start:

// MAIN PROGRAM
MOV R0, #0b110000
BL HEX_flood_ASM		// turn on HEX 4 and 5

main_loop:

BL read_slider_switches_ASM	// R0 = slider Switches
BL write_LEDs_ASM			// write R0 to lEDs
AND R4, R0, #0b1111			// store last 4 slider switches in R4

CMP R0, #0b100000000		// check if Slider sw 9 is asserted
MOVGE R0, #0b1111
BLGE HEX_clear_ASM			// Reset all Hex displays
BLGE PB_clear_edgecp_ASM	// Reset push buttons
BGE main_loop				// skip loop iteration

BL read_PB_edgecp_ASM
cmp R0, #0
BEQ main_loop

MOV R1, R4
BL HEX_write_ASM

BL PB_clear_edgecp_ASM
b main_loop

end: b end

/* USED TO TEST FOR SLIDER AND LED

loop: 
BL read_slider_switches_ASM
BL write_LEDs_ASM

b loop
*/


// #### Sider Switches Driver #####

.equ SW_MEMORY, 0xFF200040

read_slider_switches_ASM:  //// returns the state of slider switches in R0
	PUSH {r1}
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
	POP {R1}
    BX  LR

// #### LEDs Driver ####

.equ LED_MEMORY, 0xFF200000
write_LEDs_ASM:
	PUSH {r1}
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    POP {r1}
	BX  LR
	
// #### Drivers for 7 segment display ####
	
.equ HEX0_3_BASE, 0xFF200020
.equ HEX4_5_BASE, 0xFF200030

HEX_clear_ASM:
			PUSH {R2-R7, LR}
			LDR		R2, =HEX0_3_BASE
			LDR 	R3, =HEX4_5_BASE
			MOV 	R4, #6	//loop counter
			MOV 	R5, #1	//bit identifier
			MOV		R7, #0x00
			B		loop_bits

HEX_flood_ASM:
			PUSH {R2-R7, LR}
			LDR		R2, =HEX0_3_BASE
			LDR 	R3, =HEX4_5_BASE
			MOV 	R4, #6	//loop counter
			MOV 	R5, #1	//bit identifier
			MOV		R7, #0x7F
			B		loop_bits

HEX_write_ASM:
			PUSH {R2-R7, LR}
			LDR		R7, =Value
			LDR		R7, [R7, R1, lsl #2]
			LDR		R2, =HEX0_3_BASE
			LDR 	R3, =HEX4_5_BASE
			MOV 	R4, #6	//loop counter
			MOV 	R5, #1	//bit identifier	
			B		loop_bits

// Following subroutines are used by all function
// to write to display
loop_bits:	TST 	R0, R5
			BLNE	find_disp
			LSL 	R5, R5, #1
			SUBS	R4, R4, #1
			BEQ		return
			B		loop_bits

return: POP {R2-R7, LR}
		BX LR

find_disp:	CMP		R5, #0x1	// HEX0
			BEQ		HEX0		//write to HEX0
			
			CMP		R5, #0x2	 // HEX1
			BEQ		HEX1
			
			CMP		R5, #0x4	 // HEX2
			BEQ		HEX2
			
			CMP		R5, #0x8	 // HEX3
			BEQ		HEX3
			
			CMP		R5, #0x10 	 // HEX4
			BEQ		HEX4
			
			CMP		R5, #0x20 	 // HEX5
			BEQ		HEX5

//Write content of R2 to Display
HEX0:		STRB	R7, [R2]	// write content of R2 to HEX0
			BX		LR
			
HEX1:		STRB	R7, [R2, #1] // write content of R7 to HEX1
			BX		LR
			
HEX2:		STRB	R7, [R2, #2] // write content of R7 to HEX2
			BX		LR
			
HEX3:		STRB	R7, [R2, #3] // write content of R7 to HEX3
			BX		LR
			
HEX4:		STRB	R7, [R3]  	 // write content of R7 to HEX4
			BX		LR
			
HEX5:		STRB	R7, [R3, #1] // write content of R7 to HEX5
			BX		LR

Value: .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D,0x7D,0x07,0x7F,0x67,0x77,0x7F,0x39,0x3F,0x79,0x71

// #### Drivers for Push Buttonns ####

.equ Pushbutton_Base, 0xFF200050

read_PB_data_ASM:
		PUSH {R1}
		LDR  R1, =Pushbutton_Base // R1 points to KEY data register
        LDR  R0, [R1]       // R0 holds the value of KEY data register
        POP  {R1}
		BX   LR

PB_data_is_pressed_ASM:
		PUSH {R1,R2}
 		LDR  R1, =Pushbutton_Base   // R1 is a pointer to KEY data register
        LDR  R2, [R1]         // R2 holds the value of KEY data register
        AND  R0, R0, R2       // bitwise-and on key value and parameter 
		POP  {R1,R2}
        BX   LR
		
read_PB_edgecp_ASM: 
	    PUSH {R1}
		LDR  R1,=Pushbutton_Base // R1 points to KEY data register
        LDR  R0, [R1, #12] // R0 holds the value of KEY edgecapture register
        POP  {R1}
		BX   LR

PB_edgecp_is_pressed_ASM:
		PUSH {R1,R2}
 		LDR  R1, =Pushbutton_Base // R1 is a pointer to KEY data register
        LDR  R2, [R1, #12]  // R2 holds the value of KEY edgecapture register
        AND  R0, R0, R2    // bitwise-and on key value and parameter 
		POP  {R1,R2}
        BX   LR

PB_clear_edgecp_ASM:
	    PUSH {R1}
		LDR  R1,=Pushbutton_Base // R1 points to KEY data register
        LDR  R0, [R1, #12] // R0 holds the value of KEY edgecapture register
        STR  R0, [R1, #12]
	    POP  {R1}
		BX   LR

enable_PB_INT_ASM:
			PUSH {R1}
            LDR     R1, =Pushbutton_Base     // R1 points to KEY data register
            STR     R0, [R1, #8]        // place R2 in KEY interrupt register
            POP {R1}
			BX      LR
			
disable_PB_INT_ASM:
			PUSH {R1}
            LDR     R1, =Pushbutton_Base       // R1 points to KEY data register
            STR     R0, [R1, #8]        // place R2 in KEY interrupt register
            POP {R1}
			BX      LR			