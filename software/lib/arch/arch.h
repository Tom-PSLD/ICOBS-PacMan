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
// arch.h
// Author: Soriano Theo
// Update: 23-09-2021
//-----------------------------------------------------------
#ifndef __ARCH_H__
#define __ARCH_H__
// ----------------------------------------------------------------------------
// System clock frequency (in Hz)
#define SYSCLK                  50000000
// ======== REGISTERS =======
// AHB
#define GPIOA_BASE              0x11000000
#define GPIOB_BASE              0x11000400
#define GPIOC_BASE              0x11000800
#define RSTCLK_BASE             0x11011000
#define TIMER1_BASE             0x11018000
#define UART1_BASE              0x11020000
#define MY_PERIPH_BASE          0x11022000  
#define VGA_BASE                0x11024000
// ======== DEFINITIONS =======
#include "arch_gpio.h"
#include "arch_rstclk.h"
#include "arch_timer.h"
#include "arch_uart.h"
#include "arch_my_periph.h"
#include "arch_vga.h"
// ======== PERIPHERALS =======
// GPIO
#define GPIOA                   (*(GPIO_t*)GPIOA_BASE)
#define GPIOB                   (*(GPIO_t*)GPIOB_BASE)
#define GPIOC                   (*(GPIO_t*)GPIOC_BASE)
// Reset and clock control
#define RSTCLK                  (*(RSTCLK_t*)RSTCLK_BASE)
// TIMER
#define TIMER1                  (*(TIMER_t*)TIMER1_BASE)
// UART
#define UART1                   (*(UART_t*)UART1_BASE)
// VGA
#define VGA                     (*(VGA_t*)VGA_BASE)
// MY_PERIPH
#define MY_PERIPH               (*(MY_PERIPH_t*)MY_PERIPH_BASE)  
#endif