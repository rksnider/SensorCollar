Current verson: v1.0

No changes have been made to this board from when it was originally manufactured
Known issues: 
-The pin 1 designator on the TPS22912C switches is in the wrong spot.  This will cause issues in assembly.
-The power switch Sip32416 for FPGA_3p3V is hooked up wrong
-The power switches for the Microphones are hooked up incorrectly
-The 50MHz clock going to the FPGA from the CPLD needs to go to any one of the clk[0:11] pins on the FPGA to allow for use by the PLL
-The debug headder under U4 needs to be moved or it will be shorted to ground by the component placed nearby

The library in this project is the original library from when this board
was manufactured and does not include all of the features that the current
library has.  If you wish to use the parts from the current library, you will 
need to update all of the components by hand.