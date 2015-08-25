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
uint8_t currentThread;
uint8_t activeThreads;
void InitApplication(uint32_t *osStack, uint32_t * appStack, uint32_t *appStackEnd){
	int i;
	//main stack is set up, still using the main stack
	//now create data structure to handle all of our threads
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		ThreadList[i].stack = 0;
		ThreadList[i].priority = 0;
		ThreadList[i].stackEnd = 0;
	}
	activeThreads = 1;
	OsThread.priority = 0;
	OsThread.stack = osStack;
	//stack grows downwards....remember...
	OsThread.stackEnd = appStack + 1;
	currentThread = 0;
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
	++activeThreads;
	return ThreadList[i].stack;
}

//conRetAddr is the value that the addr to this thread should restoe regs through SW
void LogContextSwitch(uint32_t * conRetAddr){
	int i;
	//ze stack grows downwards!
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		if ((conRetAddr <= ThreadList[i].stack) &&
				(conRetAddr >= ThreadList[i].stackEnd)){
			ThreadList[i].stack = conRetAddr;
			return;
		}
	}
}

uint32_t* ContextSwitchEnd(){
	int i;
	int maxprio = 0;
	int retThread = 0;
	for(i = 0; i < MAXTHREADCOUNT; ++i){
		if(ThreadList[i].priority > maxprio && ThreadList[i].stack != 0){
			retThread = i;
		}
	}
	retThread = currentThread;
	currentThread = (currentThread +1) % activeThreads;
	return ThreadList[retThread].stack;
}

#define STCTRL 0xE000E010
#define STRELOAD 0xE000E014
#define STCURRENT 0xE000E018
void EnableSystick(void){


	uint32_t *regOps = (uint32_t *)STRELOAD;

	//let's configure the reload register to be
	//something such that we get a systick every 10 ms
	(*regOps) |= (0x10000);

	//need to write to the current count reg to clear it
	regOps = (uint32_t*)STCURRENT;
	(*regOps) |= (0x0);

	//this enables the Systick counter, as a multishot
	//using the sysclock
	regOps = (uint32_t*) STCTRL;
	(*regOps) |= 0x3;

}
