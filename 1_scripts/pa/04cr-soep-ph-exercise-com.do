/*==============================================================================
File name:    	03cr-soep-ph-exercise-com.do
Task:         	Extracts physical activity variables from SOEP
Project:      	Parenthood and physical activity
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14                        
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Extracts physical activity info from annual person data ($p) and gap data ($pluecke)
#2 Combine in one data set (and delete auxiliary data)
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:

------------------------------------------------------------------------------*/

version 16.1  						// Stata version control
capture log close					// Closes log files

/*------------------------------------------------------------------------------
#1 Extract physical activity info from annual person data (and gap data)
------------------------------------------------------------------------------*/

local year = 1984
foreach wave in a b c d e f g h i j k l m n o p q r s t u v w x y z ba bb bc ///
                bd be bf bg bh bi bj {
      use "${rdta}/04_SOEP/soep.v36/raw/`wave'p.dta", clear
      capture append using "${rdta}/04_SOEP/soep.v36/raw/`wave'pluecke.dta", force
	  foreach sport in ap0202 bp0703 cp0903 ep0903 gp0413 ip0703 kp1203 ///
					   lp0613 mp0503 np0303 op0613 pp0303 rp0303 tp1414 ///
					   vp0303 xp0303 yp1815 zp0303 bbp0303 bdp1116      ///
					   bfp1103 bhp_10_03 bip_50_q106 bjp_06_16 {	
	  capture rename `sport' sport`year' 
	  }
	  
      capture keep persnr syear sport`year'
      save "${pdta}/soep-`year'sport.dta", replace
      local year = `year'+1
} 

/*------------------------------------------------------------------------------
#2 Combine in one data set (and delete auxiliary data)

Note: 	1984 not usable because of very different item.
		In other years, item switches between 4 and 5 categories repeatedly.
------------------------------------------------------------------------------*/

use "${pdta}/soep-1984sport.dta", clear
forval year=1985/2019 { 
	append using "${pdta}/soep-`year'sport.dta"
}

keep persnr syear sport*

* delete aux. data
forval year=1984/2019 {
	erase "${pdta}/soep-`year'sport.dta"
}

*check for and remove duplicates
sort persnr syear

duplicates report persnr syear

duplicates tag persnr syear, gen(isdup)

drop if isdup == 1
drop isdup

* merge number of children

rename persnr pid

merge 1:1 pid syear using "${rdta}/04_SOEP/soep.v36/pequiv.dta"   ///
    , keep (1 3) keepusing (m11104 d11107 h11103 h11104)                          ///
				 nogen

rename (pid m11104 d11107 h11103 h11104) (persnr sport_cnef hhkid hhmem0_1 hhmem2_4)

* sort data
sort persnr syear

* inspect data
describe                        // show all variables contained in data
notes                           // show all notes contained in data
codebook, problems              // potential problems in dataset
duplicates report persnr syear

*------------------------------------------------------------------------------*

label data "SOEP v36, 1984-2019, physical activity, parenthood"

datasignature set, reset

save "${pdta}/soep-pa.dta", replace

*==============================================================================*
