* MODEL FILE FOR "TRANSFCT" TRANSFORMER SYMBOL
*
* To change the parameters of the transformer, copy this 
* model file to another file and perform the following steps:
*
*		1)	Change the name of the subckt from "TRANSFCT" to
*			the same name as your file.
*		2)	Change the value of the primary inductance.
*		3)	Change the value of the secondary inductances.
*		4)	Change the coefficient of coupling.
*		5)	Change the values of the primary and secondary
*			DC resistance.
*
* These parameters are underlined.
*
*                 PRIMARY
*                 |   SECONDARY
*                / \ / | \
.SUBCKT TRANSFCT 1 2 3 4 5
*       ------
* 
LPRIM    6    2    120MH
*                  -----
*
RPS      1    6    5.0
*                  ---
*
LSEC1    7    4    10MH
*                  ----
*
RSS1     3    7    .001
*                  ----

LSEC2    4    8    10MH
*                  ----
*
RSS2     5    8    .001
*                  ----
*
KPS     LPRIM LSEC1 LSEC2  .999
*                          ----
.ENDS

