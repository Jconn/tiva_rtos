/*
 * sysCall.h
 *
 *  Created on: Aug 19, 2015
 *      Author: John
 */

#ifndef SYSCALL_H_
#define SYSCALL_H_
#include <stdint.h>

void ThreadRequest(char * userStack);
void ProcessReturn(void);


#endif /* SYSCALL_H_ */
