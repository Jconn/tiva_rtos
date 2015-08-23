
    .cdecls C, NOLIST
    %{
        #include "sysCall.h"
        #include "rtos_init.h"
    %}

	.thumb


    .text
	.align 4

mynewlabel	.equ 0xFFFFFFFD

    .align 2


 ;for a context switch, need to save current registers onto the OS stack, and then
 ;switch register, stack, etc.
 ;what is the OS stack?


;used to initialize the rtos, called from user
	.export InitRtos
InitRtos: .asmfunc
	mov r0, #2
	svc #2
	;we'll just use a dedicated register here...
	;TODO: we lose some bytes on the msp stack
	;	   here because we return from the exception with the psp
	;	   might want to recover these bytes
	mov sp, r4
	mov pc, lr
	.endasmfunc

;used to create a new thread, called from user
	.export SpawnThread
SpawnThread: .asmfunc
	mov r1, r0
	mov r0, #1
	svc #1
	;returned from SVC, our stack is set up
	;we need to move our new stack value (stored in r4 - this was arbitrary)
	;	and branch to the function associated with this stack(in r1)
 	mov sp, r4
	mov lr, r1
	bx lr
	.endasmfunc

;used to switch from app to OS. SW saving of registers
	.export SaveRegisters
SaveRegisters:	.asmfunc
	mrs r0, psp
	stmdb r0, {r4-r11}
	sub r0, r0, #0x20
	bx lr
	.endasmfunc

;used to return to the application after context switch. SW restoring of registers
	.export RestoreRegisters
RestoreRegisters: .asmfunc
	;sub r0, r0, #0x
	;TODO:ensure that we are
	;actually popping off the
	;right registers5
	ldm r0, {r4-r11}
	add r0,	r0,	#0x20
	msr	psp, r0
	.endasmfunc

;used to return to the application after SVC call
ReturnToApp: .asmfunc
	movw lr, #0xFFFD
	movt lr, #0xFFFF
	bx	lr
	.endasmfunc

;Exception Handler for svc command
	.export SVCallTopLevelHandler
	.thumbfunc SVCallTopLevelHandler
SVCallTopLevelHandler: .asmfunc
	;currently, there  is a top level assembly function because I might want to deal with
	;the lr later. What I didn't realize is that on an interrupt, the lr stores some information about
	;the application's save state, see http://infocenter.arm.com/help/topic/com.arm.doc.dui0553a/DUI0553A_cortex_m4_dgug.pdf
	;EXC_RETURN is pushed into the link register
	;EXC_RETURN[31:0] Description
	;0xFFFFFFF1 Return to Handler mode, exception return uses non-floating-point state
	;from the MSP and execution uses MSP after return.
	;0xFFFFFFF9 Return to Thread mode, exception return uses non-floating-point state from
	;MSP and execution uses MSP after return.
	;0xFFFFFFFD Return to Thread mode, exception return uses non-floating-point state from
	;the PSP and execution uses PSP after return.
	;0xFFFFFFE1 Return to Handler mode, exception return uses floating-point-state from
	;MSP and execution uses MSP after return.
	;0xFFFFFFE9 Return to Thread mode, exception return uses floating-point state from
	;MSP and execution uses MSP after return.
	;0xFFFFFFED Return to Thread mode, exception return uses floating-point state from PSP
	;and execution uses PSP after return


	;case 1: request to create a new stack
ThreadCreation:	cmp r0, #1
	bne SetOSStack
	;r0 contains the pointer to the function run by this thread
	bl SaveRegisters
	bl CreateThread
	;now we just need to store our new thread's stack in a special register
	;and call it a day
	;r4: contains the new SP
	mov r4, r0
	;now we can return to the user
	b ReturnToApp
	;case 2: initializing the rtos
SetOSStack:	cmp r0, #2
	bne Default
	mrs r1,msp
	;when we return, the exception handler loads the registers back
	;using the psp, so we can't change the psp yet, it still needs to find the registers!
	msr psp, r1
	;pass to the C function that inits data structures
	mov r0, r1
	sub r1, r0, #0x800
	sub r2, r1, #0x400
	mov r4, r1
	bl InitApplication
	;can't get lower16 and upper16 to work...
	b ReturnToApp
Default:
	b ReturnToApp
	; svc call that isn't supported
	.endasmfunc

	.export OsReturn
OsReturn:

