
#Chris Casebeer
#6_15_2016
#SOF to POF at compile TCL script.


#Convert to POF from SOF using the quartus_cpf binary. 
#Option bits at 0x30_0000
#Page 0 SOF at 0x40_0000
#CFI 128Mb 1 bit passive serial flash and programming method. 

#The option bits are dictated by the parallel flash loader in the CPLD
#image used for booting the FPGA from flash. 

exec quartus_cpf -c pof_gen_CFI128_1bit_w_optionbits.cof
               