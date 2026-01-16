/*==============================================================================
File name:    	03cr-shp-ph-exercise-com.do
Task:         	Extracts physical activity and parenthood variables from SHP
Project:      	Parenthood and physical activity 
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Extract and combine physical activity info from annual person data
#2 Merge measure from SHP-CNEF for comparison
#3 Year of first birth
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:

The measure is consistent across waves (with categories yes/no)

Only the category "No" seems comparable to other countries.

>30% missing each year! --> check why!
------------------------------------------------------------------------------*/

version 16.1  						// Stata version control
capture log close					// Closes log files

/*------------------------------------------------------------------------------
#1 Extract and combine physical activity info from annual person data 
------------------------------------------------------------------------------*/

use "${rdta}/03_SHP/SHP-Data-W1-W21-STATA/W1_1999/shp99_p_user.dta", clear  // load first wave data
keep idpers p99a01 ownkid99 status99
rename p99a01 phact
rename ownkid99 ownkid
rename status99 status
gen year=1999

gen phact_days=.

local y = 2000
local c = 2
foreach w in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 {
    append using "${rdta}/03_SHP/SHP-Data-W1-W21-STATA/W`c'_`y'/shp`w'_p_user.dta"
    replace year=`y' if year==.
    replace phact=p`w'a01 if year==`y'
    replace phact_days=p`w'a04 if year==`y'
    replace ownkid=ownkid`w' if year==`y'
    replace status=status`w' if year==`y'
    keep idpers year phact phact_days ownkid status
    local y = `y' + 1
    local c = `c' + 1
}

/*------------------------------------------------------------------------------
#2 Merge measure from SHP-CNEF for comparison

Measure not available 2009, 2011/12, 2014/15, 2017/18 
------------------------------------------------------------------------------*/

gen phact_cnef=.
gen hhmem0_1=.
gen hhmem2_4=.
gen hhkid=.
rename idpers x11101ll
forval w=1999/2019 {
    sort x11101ll
    capture merge m:1 x11101ll using "${rdta}/03_SHP/SHP-Data-CNEF-STATA/shpequiv_`w'.dta" ///
        , keep (1 3) keepusing(m11104_`w') nogen
    capture replace phact_cnef=m11104_`w' if year==`w'
    capture drop m11104_`w' h11103_`w' h11104_`w'
}

forval w=1999/2019 {
    sort x11101ll
    merge m:1 x11101ll using "${rdta}/03_SHP/SHP-Data-CNEF-STATA/shpequiv_`w'.dta" ///
        , keep (1 3) keepusing(d11107_`w' h11103_`w' h11104_`w') nogen
    replace hhkid=d11107_`w' if year==`w'    
    replace hhmem0_1=h11103_`w' if year==`w'
    replace hhmem2_4=h11104_`w' if year==`w'
    drop d11107_`w' h11103_`w' h11104_`w'
}

rename x11101ll idpers
label val phact_cnef M11104
label val hhkid D11107
label val hhmem0_1 H11103
label val hhmem2_4 H11104

/*------------------------------------------------------------------------------
#3 Year of first birth
------------------------------------------------------------------------------*/

keep if status==0

* Check if all years are consecutive
sort idpers year
codebook idpers if idpers==idpers[_n-1] & year!=year[_n-1]+1, det

* Check if change in ownkid reflects birth or not
sort idpers year
bysort idpers: egen aux1=min(year) if ownkid>=1 & ownkid[_n-1]==0 & idpers==idpers[_n-1] & year==year[_n-1]+1
bysort idpers: egen aux1b=max(aux1)

bysort idpers: egen aux2=min(year) if hhmem0_1>=1 & hhmem0_1[_n-1]==0 & hhmem0_1<. & idpers==idpers[_n-1] & year==year[_n-1]+1
bysort idpers: egen aux2b=max(aux2)

bysort idpers: egen aux3=min(year) if hhmem0_1>=1 & hhmem0_1[_n-1]==0 & hhmem0_1<. & hhkid[_n-1]==0 & idpers==idpers[_n-1] & year==year[_n-1]+1
bysort idpers: egen aux3b=max(aux3)

bysort idpers: gen n=_n

ta aux2b aux1b if n==1, m  // agreement only starts 2012

* sort data
sort idpers year
order idpers year phact phact_days phact_cnef hh*

* inspect data
describe                        // show all variables contained in data
notes                           // show all notes contained in data
codebook, problems              // potential problems in dataset
duplicates report idpers year

*------------------------------------------------------------------------------*

label data "SHP v6097-7, 1999-2019, physical activity, parenthood"

datasignature set, reset

save "${pdta}/shp-pa", replace

*==============================================================================*
