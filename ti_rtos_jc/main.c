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
void TestFn1(void);
void TestFn2(void);
void SpawnThread(void (*fnpointer)(void) );
/*
 * Initial test for rolling an rtos
 * onto the tiva tm4c123h6pmi MCU
 * Author: John Connolly
 *
 */
int main(){
	InitRtos();
	SpawnThread(&TestFn1);
//	SpawnThread(&TestFn2);
	while(1);
	return 0;

}


void TestFn1(void){
	while(1);

}

void TestFn2(void){
	while(1);
}
