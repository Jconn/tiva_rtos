#ifndef RTOS_INIT_H_
#define	RTOS_INIT_H_
#include <stdint.h>

void InitApplication(uint32_t *osStack, uint32_t * appStack, uint32_t *appStackEnd);
void SetProcessStack(uint32_t mainStackSize);
uint32_t * CreateThread();
void ContextSwitch(uint32_t * conRetAddr);
void OsReturn(void);
void RestoreRegisters(uint32_t *returnThread);
void ContextSwitchEnd();
#endif /*RTOS_INIT_H*/
