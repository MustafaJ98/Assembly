.global _start
_start:
	LDR R0, =array // R0 = *ptr = & array [ 0 ];
	LDR R1, size 	
	SUB R1, R1,#1
	
	MOV R2, #0		//counter step
	MOV R3, #0		//counter i
	
loop_step:	CMP R2, R1  // step < size - 1
			BGE end
			
			MOV R3, #0
			SUB R4,R1, R2  //R4 =  size - step - 1
loop_i:		CMP R3, R4		//i < size - step - 1	
			BGE check_step
			
			// Sorting in ascending order.
		
			LDR R5, [R0, R3, LSL#2]	 // R5 = *(ptr + i)
			ADD R7, R3,#1  			 // R7 = i + 1 	 
			LDR R6, [R0, R7, LSL#2]  // R6 = *(ptr + i + 1 ) 
	
			CMP R5,R6		//(*(ptr + i) > *(ptr + i + 1 )
		
			STRGT R6, [R0, R3, LSL#2] //*(ptr + i) = *(ptr + i + 1 )
			STRGT R5, [R0, R7, LSL#2] //*(ptr + i + 1 ) = *(ptr + i)
			
			ADD R3, R3,#1
			B loop_i
			
check_step:	ADD R2,R2,#1
			B loop_step
			
end: b end

array: .word -1 , 23 , 0 , 12 , -7
size: .word 5