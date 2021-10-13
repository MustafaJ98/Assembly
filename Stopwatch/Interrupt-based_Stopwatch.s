/* NOTE:
The compiler will produce breakpoints that can pause execution. This does not indicate an error has occurred. 
To get a smooth execution of the code, turn off the:
Device-specific warnings
Function clobbered callee-saved register warnings.
*/

.section .vectors, "ax"
B _start
B SERVICE_UND // undefined instruction vector
B SERVICE_SVC // software interrupt vector
B SERVICE_ABT_INST // aborted prefetch vector
B SERVICE_ABT_DATA // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ // IRQ interrupt vector
B SERVICE_FIQ // FIQ interrupt vector

PB_int_flag: .word 0x0
tim_int_flag: .word 0x0
.text
.global _start
_start:
/* Set up stack pointers for IRQ and SVC processor modes */
MOV R1, #0b11010010 // interrupts masked, MODE = IRQ
MSR CPSR_c, R1 // change to IRQ mode
LDR SP, =0xFFFFFFFF - 3 // set IRQ stack to A9 onchipmemory

/* Change to SVC (supervisor) mode with interrupts disabled */
MOV R1, #0b11010011 // interrupts masked, MODE = SVC
MSR CPSR, R1 // change to supervisor mode
LDR SP, =0x3FFFFFFF - 3 // set SVC stack to top of DDR3 memory

BL CONFIG_GIC // configure the ARM GIC

//enable interrupt for Pushbutton Keys
MOV R0, #0xF // set interrupt mask bits
BL enable_PB_INT_ASM

//enable interrupt for ARM A9 private timer
LDR R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOV R1, #0b110	// set bits: interupt = 1, mode = 1 (auto)
BL ARM_TIM_config_ASM

// enable IRQ interrupts in the processor
MOV R0, #0b01010011 // IRQ unmasked, MODE = SVC
MSR CPSR_c, R0

IDLE:
MOV R2, #0	// counter for 10 milliseconds
MOV R3, #0	// counter for 100 milliseconds
MOV R4, #0	// counter for seconds
MOV R5, #0	// counter for 10 seconds
MOV R6, #0	// counter for minutess
MOV R7, #0	// counter for 10 minutes

Loop:
	cmp R2, #10  // if ms count >= 100 sec = sec + 1
	ADDGE R3,R3, #1
	MOVGE R2, #0			// ms count = 0
	
	cmp R3, #10  // if ms count >= 100 sec = sec + 1
	ADDGE R4,R4, #1
	MOVGE R3, #0			// ms count = 0
	
	
	cmp R4, #10  // if s count >= 60 min = min + 1
	ADDGE R5, R5, #1
	MOVGE R4, #0		// s count = 0
	
	cmp R5, #6  // if s count >= 60 min = min + 1
	ADDGE R6, R6, #1
	MOVGE R5, #0		// s count = 0
	
	cmp R6, #10  // if s count >= 60 min = min + 1
	ADDGE R7, R7, #1
	MOVGE R6, #0		// s count = 0
	
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
	// check Memory for push button
	LDR R1,=PB_int_flag
	LDR R0, [R1]
	cmp R0, #0
	BLGT buttonControl
	// poll the timer
	LDR R1,=tim_int_flag
	LDR R0, [R1]
	CMP R0, #0
	BEQ WAIT // wait for timer to expire
	
	MOV R0, #0
	STR R0, [R1]
	ADD R2, R2, #1 // Increment 10 ms
	B Loop

B IDLE // This is where you write your objective task

buttonControl:
PUSH {R0,R1, LR}
// check if PB0 is pressed and released
CMP R0, #1
LDREQ R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOVEQ R1, #0b111	// set bits: mode = 1 (auto) enable = 1
BLEQ ARM_TIM_config_ASM
BEQ returnFromButtonControl

// check if PB1 is pressed and released
CMP R0, #2
LDREQ R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOVEQ R1, #0b110	// set bits: mode = 1 (auto) enable = 0
BLEQ ARM_TIM_config_ASM
BEQ returnFromButtonControl

CMP R0, #4
MOVEQ R2, #0	// counter for 10 milliseconds
MOVEQ R3, #0	// counter for 100 milliseconds
MOVEQ R4, #0	// counter for seconds
MOVEQ R5, #0	// counter for 10 seconds
MOVEQ R6, #0	// counter for minutess
MOVEQ R7, #0	// counter for 10 minutes

MOVEQ R0, #0b111111 	//Write to all HEX
MOVEQ R1, #0		// Write counter value of R2 to HEX0
BLEQ HEX_write_ASM
LDREQ R0, =2000000 // timeout = 1/(200 MHz) x 2x10^6 = 10 msec
MOVEQ R1, #0b110	// set bits: mode = 1 (auto) enable = 0
BLEQ ARM_TIM_config_ASM
BEQ returnFromButtonControl

returnFromButtonControl:
LDR R1,=PB_int_flag
MOV R0, #0
STR R0, [R1]
POP {R0,R1, LR}
BX LR


/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
LDR R4, =0xFFFEC100
LDR R5, [R4, #0x0C] // read from ICCIAR
/* To Do: Check which interrupt has occurred (check interrupt IDs)
Then call the corresponding ISR
If the ID is not recognized, branch to UNEXPECTED
See the assembly example provided in the De1-SoC Computer_Manual
on page 46 */
Pushbutton_check:
CMP R5, #73
BLEQ KEY_ISR
BEQ EXIT_IRQ
TIMER_check:
CMP R5, #29
BLEQ ARM_TIM_ISR
BEQ EXIT_IRQ

UNEXPECTED: B UNEXPECTED // if not recognized, stop here

EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
STR R5, [R4, #0x10] // write to ICCEOIR
POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
B SERVICE_FIQ

CONFIG_GIC:
PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
by passing their IDs to R0 and repeating the next 3 lines */
MOV R0, #73 // KEY port (Interrupt ID = 73)
MOV R1, #1 // this field is a bit-mask; bit 0 targets cpu0
BL CONFIG_INTERRUPT
MOV R0, #29 // Timer port (Interrupt ID = 29)
MOV R1, #1 // this field is a bit-mask; bit 0 targets cpu0
BL CONFIG_INTERRUPT
/* configure the GIC CPU Interface */
LDR R0, =0xFFFEC100 // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
LDR R1, =0xFFFF // enable interrupts of all priorities levels
STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
MOV R1, #1
STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
LDR R0, =0xFFFED000
STR R1, [R0]
POP {PC}
/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default
(reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
LSR R4, R0, #3 // calculate reg_offset
BIC R4, R4, #3 // R4 = reg_offset
LDR R2, =0xFFFED100
ADD R4, R2, R4 // R4 = address of ICDISER
AND R2, R0, #0x1F // N mod 32
MOV R5, #1 // enable
LSL R2, R5, R2 // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
LDR R3, [R4] // read current register value
ORR R3, R3, R2 // set the enable bit
STR R3, [R4] // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
BIC R4, R0, #3 // R4 = reg_offset
LDR R2, =0xFFFED800
ADD R4, R2, R4 // R4 = word address of ICDIPTR
AND R2, R0, #0x3 // N mod 4
ADD R4, R2, R4 // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
STRB R1, [R4]
POP {R4-R5, PC}

KEY_ISR:
PUSH {R0,R1,LR}			
BL read_PB_edgecp_ASM		// R0 = Push button Keys
LDR R1, =PB_int_flag		// R1 = pointer to PB flag
STR R0, [R1]				// Save R0 to PB flag

BL PB_clear_edgecp_ASM
POP {R0,R1,LR}
BX LR

ARM_TIM_ISR:
PUSH {R1, R2, LR}
LDR R1, =tim_int_flag		//pointer to memory  tim flag
MOV R2, #1				
STR R2, [R1]				// set tim flga = 1
BL ARM_TIM_clear_INT_ASM	// clear TIM 
POP {R1, R2, LR}
BX LR



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
        STR  R0, [R1, #12]	// writing clears edgecp
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
	
