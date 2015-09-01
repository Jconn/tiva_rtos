# tiva_rtos
tiva tm4c123h6pmi rtos \n
This repo was a side project I did in the summer to try and get multi-threading working on TI's Tiva Launchpad.
All I did for new threads was split up the stack (I specified my stack as 16KB) into 1KB chunks 
and then assign one of these chunks to a thread.
I don't currently do error checking for stack overflows on each individual stack. 
I gave the OS a 4KB chunk of the stack to work with.
Currently the scheduler runs in a round-robin style. I have set the Systick to interrupt to 1ms. 

Launchpad used:
http://www.mouser.com/ProductDetail/Texas-Instruments/EK-TM4C123GXL/?qs=TB%2FQ0sBK%2FGefKGr%252bQsiJWQ%3D%3D&gclid=CjwKEAjwmZWvBRCCqrDK_8atgBUSJACnib3lXP8U7_iuU8LESYS-TvFogRx9cvmHv6Yitzi9jhBWGRoCVB7w_wcB&kpid=941848551
The microcontroller used is the tm4c123h6pmi, which contains a cortex-M4 processor.
tm4c123 datasheet:
http://users.ece.utexas.edu/~valvano/Volume1/tm4c123gh6pm.pdf


