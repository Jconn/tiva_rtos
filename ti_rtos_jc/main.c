/*
 * main.c
 *
 *  Created on: Aug 17, 2015
 *      Author: John
 */
#include <stdint.h>
#include "rtos_init.h"
void set_SVC(char * stack);
void InitRtos(void);
void SysCallHandler(uint8_t sysNumber);
void TestFn(void);
void SpawnThread(void (*fnpointer)(void) );
int main(){
	InitRtos();
	SpawnThread(&TestFn);

	while(1);
	return 0;

}


void TestFn(void){
	while(1);

}
