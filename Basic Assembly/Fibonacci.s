.global _start
_start:
	LDR R0, n
	MOV R1, #0
	MOV R2, #0
	PUSH {R4 - LR}
	BL FIB
	POP {R4 - LR}
	
end: b end	
	
FIB:
	 cmp r0, #3		  //compare n with 3
	 MOVLT R0, #1	       	  //(if n<3) fib(n)=1	
	 BXLT LR		  // return
	 			//ELSE
	 MOV R1, R0		 //r1 = n
	 SUB R0, R1, #1		 //R0 = (n-1)
	 PUSH {R1, LR}		 // Preserve R1, LR
	 BL FIB			 //R0 = fib (n-1)
	 MOV r2,r0		 //R2 = fib (n-1)
	 POP {R1,LR}		 // Restore R1, LR
	 SUB R0, R1, #2		 // R0 = n-2
	 PUSH {R2,LR}		 // Preserve R2, LR
	 BL FIB			 // R0 = fib(n-2)
	 POP {R2,LR}		 // restore R2, LR
	 ADD R0, R0, R2		//R0 = fib(n-1)+fib(n-2)
	 
	 BX LR  //return

n: .word 5