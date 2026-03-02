#ifndef ARCH_VGA_H_
#define ARCH_VGA_H_

typedef struct {
    volatile unsigned int background_color; 
    volatile unsigned int X1_pos;          
    volatile unsigned int Y1_pos;           
    volatile unsigned int X2_pos;           
    volatile unsigned int Y2_pos;           
    volatile unsigned int X3_pos;           
    volatile unsigned int Y3_pos; 
    volatile unsigned int X4_pos;          
    volatile unsigned int Y4_pos;
    volatile unsigned int X5_pos;
    volatile unsigned int Y5_pos;
    volatile unsigned int X6_pos;
    volatile unsigned int Y6_pos;


} VGA_t;

#endif
