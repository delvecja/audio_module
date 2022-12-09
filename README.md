# Audio Module for the DE2-115 FPGA.

## Organization

### audio_module.v

The top level module is stored in the audio_module.v file. In this file you will find the finite state machine that controls the entire module and initializes the Audio Chip on the DE2-115. This is also where you will find instantiations of the other modules that are needed for communicating with the Wolfson WM8731. 

### AudioDAC.v and AudioADC.v

In these files you will find the finite state machines for sending and recieving 32 bit words to and from the Audio Chip.

### HighPassFilter.v, LowPassFilter.v, and EchoFilter.v

In these files you will find the functions for filtering out certain frequencies and echoing from the signal. The Highpass and Lowpass filters work fairyl well, but the Echo filter does not work as it is supposed to.

### seven_segment.v

A simple module for encoding a 4 bit number into a 7 bit signal for the Seven Segment Displays to use. This was used for outputing debugging signals.

### Audio_CLK

The Audio Clock imported module for the DE2-115 board.

### Debouncer.v

A debouncer module that was somewhat problematic. This debouncer was sourced from Dr. Jamieson's Canvas page.

### I2C.v and Audio_Chip_Init.v

These are the modules for sending bits using the I2C protocol and initilizing the Audio Chip with user settings and the Audio Clock signal. These modules were sourced from a similar project found on github by Austyn Larkin. The github repo for his project can be found [here.](https://github.com/Reenforcements/VerilogDE2115AudioFilters)

## Sources

[I2C and Audio Chip Initialization modules](https://github.com/Reenforcements/VerilogDE2115AudioFilters)
[Wolfson WM8731 Datasheet](http://cdn.sparkfun.com/datasheets/Dev/Arduino/Shields/WolfsonWM8731.pdf)
[DE2-115 User Manual](http://www.terasic.com.tw/attachment/archive/502/DE2_115_User_manual.pdf)
