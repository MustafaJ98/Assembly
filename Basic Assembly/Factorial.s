.global _start
_start:
	LDR R0, n  //R0 = n
	PUSH {R4 - LR}	//preserve registers
	BL FACT			//call R0 = fact(n)
	POP {R4 - LR}	//restore registers

end:	B end

FACT:   CMP R0, #1	  // if (n<=1) {
	    MOVLE R0, #1  // R0 = 1
	    BXLE LR		  // return }
					  // else
		MOV R1, R0	  // { R1 = n
		PUSH {R1, LR} //
	  	SUB R0,R0,#1  //	R0 = n-1
		BL FACT		  // R0 = fact(n-1)
		POP {R1,LR}
	  	MUL R0, R0, R1	//R4 = Mul = n*fact(n-1)
		BX LR
		
n: .word 4

.end