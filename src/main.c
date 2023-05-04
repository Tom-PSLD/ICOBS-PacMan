// ##########################################################
// ##########################################################
// ##    __    ______   ______   .______        _______.   ##
// ##   |  |  /      | /  __  \  |   _  \      /       |   ##
// ##   |  | |  ,----'|  |  |  | |  |_)  |    |   (----`   ##
// ##   |  | |  |     |  |  |  | |   _  <      \   \       ##
// ##   |  | |  `----.|  `--'  | |  |_)  | .----)   |      ##
// ##   |__|  \______| \______/  |______/  |_______/       ##
// ##                                                      ##
// ##########################################################
// ##########################################################
//-----------------------------------------------------------
// main.c
// Author: Soriano Theo
// Update: 23-09-2020
//-----------------------------------------------------------

#include "system.h"

#define _BTNU_MODE  GPIOC.MODEbits.P0
#define BTNU        GPIOC.IDRbits.P0

#define _BTNL_MODE  GPIOC.MODEbits.P1
#define BTNL        GPIOC.IDRbits.P1

#define _BTNR_MODE  GPIOC.MODEbits.P2
#define BTNR        GPIOC.IDRbits.P2

#define _BTND_MODE  GPIOC.MODEbits.P3
#define BTND        GPIOC.IDRbits.P3

int TIMER_FLAG = 0;

static void timer_clock_cb(int code)
{
	TIMER_FLAG=1;
	((void)code);
}

int main(void)
{
	RSTCLK.GPIOAEN = 1;
	RSTCLK.GPIOBEN = 1;
	RSTCLK.GPIOCEN = 1;

	GPIOB.ODR = 0x0000;
	GPIOB.MODER = 0xFFFF;

	_BTNU_MODE = GPIO_MODE_INPUT;
	_BTNL_MODE = GPIO_MODE_INPUT;
	_BTNR_MODE = GPIO_MODE_INPUT;
	_BTND_MODE = GPIO_MODE_INPUT;

	// UART1 initialization
	UART1_Init(115200);
	UART1_Enable();
	IBEX_SET_INTERRUPT(IBEX_INT_UART1);

	IBEX_ENABLE_INTERRUPTS;

	myprintf("\n#####################\nDEMO\n#####################\n");

	set_timer_ms(1000, timer_clock_cb, 0);

	int8_t count = 0;
	int8_t last_count = -1;
	int8_t dx = 0;

	while(1) {
		do{
			if(BTNU){dx=1;}
			if(BTND){dx=-1;}
			if(BTNL){dx=0;}
			if(BTNR){
				count = 0;
				last_count = -1;
			}
		}while(!TIMER_FLAG);
		TIMER_FLAG = 0;
		last_count = count;
		count = count+dx;
		if(count!=last_count){
			myprintf("%d\n",count);
			GPIOB.ODR = count;
		}
	}
	return 0;
}

void Default_Handler(void){
	GPIOB.ODR = 0xFFFF;
}
