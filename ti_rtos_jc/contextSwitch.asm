
    .cdecls C, NOLIST
    %{
        #include "sysCall.h"
        #include "rtos_init.h"
    %}

	.thumb

    .text


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
	push {lr}
	bl EnableSystick
	pop {lr}
	mov pc, lr
	;TODO: find out how to enable systick exceptions
	.endasmfunc
	;now we have to load our registers...

disableSysTick: .asmfunc
	movw r2, #0xE010
	movt r2, #0xE000
	ldr r3, [r2]
	orr r3, r3, #0x0
	str r3, [r2]
	bx lr
	.endasmfunc
enableSysTick: .asmfunc
	movw r2, #0xE010
	movt r2, #0xE000
	ldr r3, [r2]
	orr r3, r3, #0x3
	str r3, [r2]
	bx lr
	.endasmfunc
;used to create a new thread, called from user
	.export SpawnThread
SpawnThread: .asmfunc
	;turning off systick interrupt for this, because I don't want a systick to occur here...
	;would be bad...
	;TODO: disable all interrupts
	;need to disable the systick while thread creation is occuring
	push {lr}
	bl disableSysTick
	pop {lr}
	mov r1, r0
	mov r0, #1
	svc #1
	;returned from SVC, our stack is set up
	;we need to move our new stack value (stored in r4 - this was arbitrary)
	;	and branch to the function associated with this stack(in r1)
 	;TODO: the initial thread...needs to return to the right place
 	;we can do whatever we want with r4-r7, no C is using
 	;them yet since this is the first thing that happens
 	;in the new thread
 	mov sp, r4
	;this should alter where the other thread returns to
	str r6, [r5]
 	bl enableSysTick
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

	.export AlterOriginsReturn
	.thumbfunc AlterOriginsReturn
AlterOriginsReturn:	.asmfunc
	;this is only called when we make a new thread, we need the old thread to
	;operate normally
	add r2, r0, #0x34
	ldr r3, [r2]
	;fuck it, not working, we'll just load the lr
	;into the pc, grabbing both from memory
	;ldr r3, =threadReturn
	add r2, r2, #0x4
	str r3, [r2]
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
	bx lr
	.endasmfunc

;used to return to the application after SVC call
ReturnToApp: .asmfunc
	movw lr, #0xFFFD
	movt lr, #0xFFFF
	bx	lr
	.endasmfunc

	.export SysTickHandler
SysTickHandler: .asmfunc
	push {lr}
	bl SaveRegisters
	;logcontext switch will handle switching to
	;the next thread, also calls restore registers
	bl LogContextSwitch
	bl ContextSwitchEnd
	;r0 contains the pointer for SW register restore
	bl RestoreRegisters
	pop {lr}
	;returning back to process stack
	bx lr
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
	add r5, r0, #0x34
	ldr r6, [r5]
	;fuck it, not working, we'll just load the lr
	;into the pc, grabbing both from memory
	;ldr r3, =threadReturn
	add r5, r5, #0x4
	bl LogContextSwitch
	bl CreateThread
	;now we just need to store our new thread's stack in a special register
	;and call it a day
	;r4: contains the new SP
	mov r4, r0
	;r5 contains the memory location where the previous thread's stack pointer will
	;be restored
	;r6 contains the value that the previous thread's stack pointer should be
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

