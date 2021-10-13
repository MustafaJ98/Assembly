/* NOTE:
The compiler will produce breakpoints that can pause execution. This does not indicate an error has occurred. 
To get a smooth execution of the code, turn off the:
Device-specific warnings
Function clobbered callee-saved register warnings.
*/

.global _start
_start:

// Configure timer to 10 ms
LDR R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOV R1, #0b010	// set bits: mode = 1 (auto)
BL ARM_TIM_config_ASM

MOV R2, #0	// counter for 10 milliseconds
MOV R3, #0	// counter for 100 milliseconds
MOV R4, #0	// counter for seconds
MOV R5, #0	// counter for 10 seconds
MOV R6, #0	// counter for minutess
MOV R7, #0	// counter for 10 minutes


Loop:
	cmp R2, #10  // if 10ms counter >= 9, 100ms = 100ms + 1
	ADDGE R3,R3, #1
	MOVGE R2, #0		// 10ms count = 0
	
	cmp R3, #10  // if 100 ms counter >= 9, 1sec = 1sec + 1
	ADDGE R4,R4, #1
	MOVGE R3, #0			// ms count = 0
	
	
	cmp R4, #10  // if 1s count >= 10,  10s = 10s + 1
	ADDGE R5, R5, #1
	MOVGE R4, #0 // 1s count = 0
	
	cmp R5, #6  // if 10s count >= 6, min = min + 1
	ADDGE R6, R6, #1
	MOVGE R5, #0	// 10s count = 0
	
	cmp R6, #10  // if 1m count >= 10,  10m = 10min + 1
	ADDGE R7, R7, #1
	MOVGE R6, #0		// 1m count = 0
	
	MOV R0, #0b01 	//Write to HEX0
	MOV R1, R2		// Write counter value of R2 to HEX0
	BL HEX_write_ASM
	MOV R0, #0b10 	//Write to HEX1
	MOV R1, R3		// Write counter value of R2 to HEX0
	BL HEX_write_ASM
	MOV R0, #0b100 	//Write to HEX2
	MOV R1, R4		// Write counter value of R2 to HEX0
	BL HEX_write_ASM
	MOV R0, #0b1000 	//Write to HEX3
	MOV R1, R5		// Write counter value of R2 to HEX0
	BL HEX_write_ASM
	MOV R0, #0b10000 	//Write to HEX4
	MOV R1, R6		// Write counter value of R2 to HEX0
	BL HEX_write_ASM
	MOV R0, #0b100000 	//Write to HEX5
	MOV R1, R7		// Write counter value of R2 to HEX0
	BL HEX_write_ASM
	
WAIT:	
	// poll the push button
	BL read_PB_edgecp_ASM
	cmp R0, #0
	BLGT buttonControl
	// poll the timer
	BL ARM_TIM_read_INT_ASM // read timer status
	CMP R0, #0
	BEQ WAIT // wait for timer to expire
	
	BL ARM_TIM_clear_INT_ASM // reset timer flag bit
	ADD R2, R2, #1 // Increment 10 ms
	B Loop
	

buttonControl:
PUSH {R0,R1, LR}
// check if PB0 is pressed and released
MOV R0, #0b1	
BL PB_edgecp_is_pressed_ASM
CMP R0, #0
LDRGT R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOVGT R1, #0b011	// set bits: mode = 1 (auto)
BLGT ARM_TIM_config_ASM
BGT returnFromButtonControl

// check if PB1 is pressed and released
MOV R0, #0b10	
BL PB_edgecp_is_pressed_ASM
CMP R0, #0
LDRGT R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOVGT R1, #0b010	// set bits: mode = 1 (auto) enable = 0
BLGT ARM_TIM_config_ASM
BGT returnFromButtonControl

// check if PB2 is pressed and released
MOV R0, #0b100	
BL PB_edgecp_is_pressed_ASM
CMP R0, #0
LDRGT R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOVGT R1, #0b010	// set bits: mode = 1 (auto) enable = 0
BLGT ARM_TIM_config_ASM

MOVGT R2, #0	// counter for 10 milliseconds
MOVGT R3, #0	// counter for 100 milliseconds
MOVGT R4, #0	// counter for seconds
MOVGT R5, #0	// counter for 10 seconds
MOVGT R6, #0	// counter for minutess
MOVGT R7, #0	// counter for 10 minutes

MOVGT R0, #0b111111 	//Write to all HEX
MOVGT R1, #0		// Write counter value of 0 to HEX0
BLGT HEX_write_ASM
BGT returnFromButtonControl

returnFromButtonControl:
BL PB_clear_edgecp_ASM
POP {R0,R1, LR}
BX LR





/* TEST CODE PART 2

// Configure timer to 1 sec
LDR R0, =200000000 // timeout = 1/(200 MHz) x 200x10^6 = 1 sec
MOV R1, #0b011	// set bits: mode = 1 (auto), enable = 1
BL ARM_TIM_config_ASM
MOV R2, #0		// used as a counter to 15

Loop: 
	cmp R2, #15
	MOVGT R2, #0
	MOV R0, #0b1 	//Write to HEX0
	MOV R1, R2		// Write counter value of R2 to HEX0
	BL HEX_write_ASM

WAIT:
	BL ARM_TIM_read_INT_ASM // read timer status
	CMP R0, #0
	BEQ WAIT // wait for timer to expire
	
	BL ARM_TIM_clear_INT_ASM // reset timer flag bit
	ADD R2, R2, #1 // Increment HEX0 disp
	B Loop
*/



// ### Private Timer (ARM* A9* MPCore* Timers) drivers ####

.equ Timer_BASE, 0xFFFEC600

ARM_TIM_config_ASM:
PUSH {R2}
LDR R2, =Timer_BASE
STR R0, [R2]
STRH R1, [R2, #8]
POP {R2}
BX LR

ARM_TIM_read_INT_ASM:
PUSH {R2}
LDR R2, =Timer_BASE
LDR R0, [R2, #12]
POP {R2}
BX LR

ARM_TIM_clear_INT_ASM:
PUSH {R1-R2}
MOV R1, #0x00000001
LDR R2, =Timer_BASE
STR R1, [R2, #12]
POP {R1-R2}
BX LR

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
