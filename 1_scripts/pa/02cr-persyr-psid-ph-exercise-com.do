/*==============================================================================
File name:    	02cr-persyr-psid-ph-exercise-com.do
Task:         	Extracts parenthood variables from PSID
Project:      	Parenthood and physical activity
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14                         
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Extracts parenthood variables from PSID
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:

Birth order variable is missing for all children in family as soon as birth
order for one child is missing
------------------------------------------------------------------------------*/

version 16.1  						// Stata version control
capture log close					// Closes log files

/*------------------------------------------------------------------------------
#1 Extracts parenthood variables from PSID
------------------------------------------------------------------------------*/

use "${rdta}/02_PSID/PSIDtools_files/cah85_19.dta", clear

gen parpid=(CAH3*1000) + CAH4

sort parpid CAH15
bysort parpid: gen n=_n
bysort parpid: gen N=_N

ta CAH9 n if CAH11>0, col

* How many adults with adopted child?
gen adopt=1 if CAH2==2 & CAH11>0
bysort parpid: egen adoptex=max(adopt)
ta adoptex if n==1
ta adopt
* There are 1,933 adopted children and 1,611 adults with at least 1 adopted child

* Has neither adopted nor natural children
ta n if CAH11==999

* Number of adopted and natural children
gen natu=1 if CAH2==1 & CAH11>0
bysort parpid: egen nnatkid=count(natu) 
bysort parpid: egen nadokid=count(adopt)

bysort parpid: egen nokids=max(CAH11)
recode nokids 0=1 1/999=0

* Keep only the record for the first birth (or no birth)
keep if n==1

* sort data
sort parpid

rename (CAH15 CAH13) (yr1brth mn1brth)

* inspect data
describe                        // show all variables contained in data
notes                           // show all notes contained in data
codebook, problems              // potential problems in dataset
duplicates report parpid

*------------------------------------------------------------------------------*

label data "PSID, parenthood"

datasignature set, reset

save "${pdta}/psid-kids.dta", replace

*==============================================================================*
