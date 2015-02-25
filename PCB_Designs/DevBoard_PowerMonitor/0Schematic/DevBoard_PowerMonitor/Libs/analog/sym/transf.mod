* MODEL FILE FOR "TRANSF" TRANSFORMER SYMBOL
*
* To change the parameters of the transformer, copy this 
* model file to another file and perform the following steps:
*
*		1)	Change the name of the subckt from "TRANSF" to
*			the same name as your file.
*		2)	Change the value of the primary inductance.
*		3)	Change the value of the secondary inductance.
*		4)	Change the coefficient of coupling.
*		5)	Change the values of the primary and secondary
*			DC resistance.
*
* These parameters are underlined.
*
.SUBCKT TRANSF 1 2 3 4
*       ------
* 
LPRIM    5    2    120MH
*                  -----
*
RPS      1    5    5.0
*                  ---
*
LSEC     6    4    20MH
*                  ----
*
RSS      3    6    .001
*                  ----
*
KPS      LPRIM LSEC  .999
*                    ----
.ENDS

