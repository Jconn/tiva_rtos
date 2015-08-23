/*
 * rtos_init.c
 *
 *  Created on: Aug 19, 2015
 *      Author: John
 */

#include "rtos_init.h"
#include <stdint.h>
#define MAXTHREADCOUNT 10
typedef struct ThreadControlBlock{
	uint32_t *stackEnd;
	uint32_t *stack;
	uint8_t priority;
}TCB;

TCB OsThread;
TCB ThreadList [MAXTHREADCOUNT];
uint32_t *nextStack;
void InitApplication(uint32_t *osStack, uint32_t * appStack, uint32_t *appStackEnd){
	int i;
	//main stack is set up, still using the main stack
	//now create data structure to handle all of our threads
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		ThreadList[i].stack = 0;
		ThreadList[i].priority = 0;
		ThreadList[i].stackEnd = 0;
	}
	OsThread.priority = 0;
	OsThread.stack = osStack;
	//stack grows downwards....remember...
	OsThread.stackEnd = appStack + 1;

	ThreadList[0].priority = 0;
	ThreadList[0].stack = appStack;
	//can use stackEnd as the pId of the thread
	ThreadList[0].stackEnd = appStackEnd;
	nextStack = appStackEnd-1;
	//call os return to change the from msp to psp
	//now call assembly function, push all the registers onto the stack
}
uint32_t * CreateThread(){
	int i;
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		if(ThreadList[i].stack == 0)
			break;
	}
	ThreadList[i].stack = nextStack;
	ThreadList[i].stackEnd = nextStack - 0x400;
	ThreadList[i].priority = 0;
	nextStack = ThreadList[i].stackEnd -1;
	return ThreadList[i].stack;
}

//conRetAddr is the value that the addr to this thread should restoe regs through SW
void ContextSwitch(uint32_t * conRetAddr){
	int i;
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		if ((conRetAddr >= ThreadList[i].stack) &&
				(conRetAddr <= ThreadList[i].stackEnd)){
			ThreadList[i].stack = conRetAddr;
		}
	}
}

void ContextSwitchEnd(){
	int i;
	int maxprio = 0;
	int retThread = 0;
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		if(ThreadList[i].priority > maxprio && ThreadList[i].stack != 0){
			retThread = i;
		}
	}
	RestoreRegisters(ThreadList[retThread].stack);
}

