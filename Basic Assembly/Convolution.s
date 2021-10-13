.global _start
_start:
	
_start: LDR R0, =fxMatrix /* Register R0 is a pointer to image matrix. */
LDR R1, =kxMatrix /* Register R1 is a pointer to kernel matrix. */
LDR R2, =gxMatrix /* Register R2 is a pointer to result vector. */
MOV R3, #0 /* x-counter */
MOV R4, #0 /* y-counter */
MOV R5, #0  // j-counter
MOV R6, #0  // i-counter

loop_y: LDR R9, ih
		CMP R4,R9
		BEQ end
		
		MOV R3, #0	
loop_x:	
		LDR R9, iw
		cmp R3, R9
		beq check_y
		
		MOV R10,#0  /* Register R10 is used to accumulate the product. */
		MOV R6, #0		
loop_i: 
		LDR r9, kw
		cmp R6, R9
		beq check_x
		MOV r5, #0
loop_j:
		LDR R9, kh
		cmp r5,r9
		Beq check_i
		
		// CODE PART
				//R11 is used as temp 1 
				ADD r11, r3, r5	//temp1 = x+j
				LDR R7, ksw
				SUB R11, R11, R7 // temp 1 = temp 1 - ksw
				
				//R12 is used as temp 2
				ADD R12, r4, r6 // temp 2 = y+i
				LDR R7, khw
				SUB R12, R12, R7 // temp 2 = temp2 - khw
				
				cmp R11,#0
				BLT skip
				cmp R12,#0
				BLT skip
				cmp R11,#9
				BGT skip
				cmp R12,#9
				BGT skip
			
				// R7 [KxMatrix + (kw*j)+i] to get memory location
				LDR R7, kw   //R7 = 5 
				MUL R7, R7,R6  //R7 = R7*R6 = 5*j
				ADD R7, R7, R5  //R7 = R7 + R5 = 5*j +i
				LDR R7, [R1, R7, LSL #2]
				
				// R8 fxMatrix[Temp1][Temp2] = 
				//[FxMatrix + temp1+iw*temp2] to get memory location
				LDR R8, iw
				MUL R8, R8, R12
				ADD R8, R8, R11
				LDR R8, [R0, R8, LSL #2]
				
				// R8 = kx[j][i] * fx [temp1][temp2]
				MUL R8, R7, R8
				//sum = sum + kx[j][i] * fx [temp1][temp2]
				ADD R10, R10, R8
				

skip: //do nothing
		
		ADD R5, R5, #1
		B loop_j
		
check_i:
		ADD r6,r6,#1
		B loop_i

check_x:
		//gx[x][y] = sum
		
		LDR R8, iw 
		MUL R8, R8,R4
		ADD R8, R8,R3
		STR R10, [R2, R8, LSL#2]
		
		ADD R3,R3,#1
		B loop_x
		
check_y:
		ADD R4, R4, #1
		B loop_y
		
		
end: B end



iw: .word 10 /* Image Width = 10 */
ih: .word 10 /*Image Height = 10 */
kw: .word 5 /* Kernel Width = 5 */
kh: .word 5 /* Kernel Height = 5 */
ksw: .word 2 // Kernel width Stride = (Kernel width-1)/2
khw: .word 2 // Kernel Height Stride = (Kernel Height-1)/2

/* Specify the elements of vector A. */
fxMatrix: .word 183 , 207 , 128 , 30 , 109 , 0 , 14 , 52 , 15 , 210, 228 , 76 , 48 , 82 , 179 , 194 , 22 , 168 , 58 , 116, 228 , 217 , 180 , 181 , 243 , 65 , 24 , 127 , 216 , 118, 64 , 210 , 138 , 104 , 80 , 137 , 212 , 196 , 150 , 139, 155 , 154 , 36 , 254 , 218 , 65 , 3 , 11 ,91,95,219 , 10 , 45 , 193 , 204 , 196 , 25 , 177 , 188 , 170, 189 , 241 , 102 , 237 , 251 , 223 , 10 , 24 , 171 , 71, 0 , 4 , 81 , 158 , 59 , 232 , 155 , 217 , 181 , 19, 25 , 12 , 80 , 244 , 227 , 101 , 250 , 103 , 68 , 46,136 , 152 , 144 , 2 , 97 , 250 , 47 , 58 , 214 , 51

/* Specify the elements kernel matrix */
kxMatrix: .word 1 , 1 , 0 , -1 , -1, 0 , 1 , 0 , -1 , 0, 0 , 0 , 1 , 0 , 0, 0 , -1 , 0 , 1 , 0, -1 , -1 , 0 , 1 , 1

gxMatrix: .space 400
.end