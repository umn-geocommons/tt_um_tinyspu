# TinySPU Technical Docs

3.13.25

Logan Gall  
Eric Shook

## Hardware Structure

TinySPU is structured to function within the limitations of the TinyTapeout project spec. In general this means:

* ~50MHz Clock rate
* 8 bits of Input (designated to OpCode & QMux)
* 8 bits of Output (designated to M and N outputs)
* 8 bits of UIO (designated to ABCD inputs)

## How to test

The verilog code can be run in HDL software of preference, with the tt_um_tinyspu.v as the top-level module.

File main.v contains a testbench of all operations programmed for the TinySPU. This can be set as a simulation source.

File DemoBench.v contains a testbench showcasing complex operations that the TinySPU can perform. This can be set as a simulation source.

## Instruction Set

The instruction set is split into two sections:
* Operation Codes -- The operation selection for the chip, set as the high 4 bits of Input
* Q Mux Codes -- The data loading multiplexer code, set as the low 4 bits of Input

## TinySPU ISA OpCode  

### **Control SPU**
**0000 NOP (No Operation)**     
M \= Maintain value     
N \= Maintain value  

**0001 MinGate**    
M \= A if B \< D else C     
N \= min(B,D)  

**0010 EqGate**	    
M \= A if B == D else C     
N \= D  

**0011 ZeroMN**     
M \= 0      
N \= 0

### **Dual 4-bit Vector**
**0100 DistDir**    
M \= Manhattan Dist |(A-C)| \+ |(B-D)|  
N \= Direction (0=N 1=NE E SE S SW W NW)  

**0101 VectorBoxArea**      
M \= Area |(A-C)| \* |(B-D)|    
N \= Perimeter 2\*|(A-C)| \+ 2\*|(B-D)|  

**0110 BasicBuffer**    
\[A B\] \[C D\]     
M \= BufferedX  
N \= BufferedY  

**0111 AttrReclass**    
\[A\]\[B\]\[C\]\[D\]    
M \= 3 class    
N \= 2 class   

### **Dual 4-bit Raster Ops**
**1000 FocalMeanRow**   
\[A B C D\]     
M \= (A+B+C) / 3    
N \= (B+C+D) / 3

**1001 FocalSumRow**    
\[A B C D\]     
M \= (A+B+C)    
N \= (B+C+D)  

**1010 LocalDiv**   
\[A B\] \[C D\]     
M \= A/C    
N \= B/D

**1011 FocalMaxPoolRow**    
\[A B C D\]     
M \= max(A,B)   
N \= max(C,D)

**1100 NormDiffIndex**  
\[A B\] \[C D\]     
M \= (A-C) / (A+C)  
N \= (B-D) / (B+D)

**1101 LocalCodeOp**    
\[A\] \[B\] \[C\]   
M \=  (A op1 B)     
N \= ((A op1 B) op2 C)      
Code D (low op1, high op2): 00=&, 01=|, 10=+, 11=\*

### **Single 8-bit OUT (combine 4 high \+ 4 low bits \= 8 bit precision)**

**1110 MHDist8**    
M \= high bits for Manhattan Distance  
N \= low bits  

**1111 DotProduct**	    
M \= A\*B \+ {C,D} (high 4-bits)  
N \= low 4-bits for Sum Accumulate


## TinySPU ISA Q Mux
### **Control Input**

**0000 NoIO**   
A/B/C/D \= Maintain Value of all INP  

**0001 ZeroCD**     
C/D     \= 0

**0010 ZeroAB**     
A/B     \= 0  

**0011 (OPEN)**

### **UIO In (01xx)**

**0100 UIOACBD**    
A/B \= UIO High  
C/D \= UIO Low

**0101 UIOCD**  
C   \= UIO High  
D   \= UIO Low  

**0110 UIOAB**  
A   \= UIO High  
B   \= UIO Low  

**0111 UIOABCD**    
A/C \= UIO High  
B/D \= UIO Low

### **MN In (10xx)**

**1000 MNACBD**     
A/B \= M  
C/D \= N  

**1001 MNCD**   
C   \= M  
D   \= N  

**1010 MNAB**   
A   \= M  
B   \= N  

**1011 MNABCD**	    
A/C \= M  
B/D \= N

### **Open for future versions**
1100 (OPEN)  
1101 (OPEN)  
1110 (OPEN)  
1111 (OPEN)
