/*==============================================================================
File name:    	01cr-hilda-02ph-exercise-com.do
Task:         	Extracts physical activity and parenthood variables from HILDA
Project:      	Parenthood and physical activity 
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Extract physical activity info from annual person data and gap data
#2 Merge measure from HILDA-CNEF for comparison
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:
------------------------------------------------------------------------------*/

version 16.1  						// Stata version control
capture log close					// Closes log files

/*------------------------------------------------------------------------------
#1 Extract physical activity info from annual person data (and gap data)
------------------------------------------------------------------------------*/

use "${rdta}/01_HILDA/STATA 190c (Combined)/Combined_a190c.dta", clear  // load first wave data
keep xwaveid alspact atcr atcnr atcr04
rename alspact lspact
rename atcr tcr
rename atcnr tcnr
rename atcr04 tcr04 
gen year=2001

local y = 2002
foreach w in b c d e f g h i j k l m n o p q r s {
    append using "${rdta}/01_HILDA/STATA 190c (Combined)/Combined_`w'190c.dta"
    replace year=`y' if year==.
    replace lspact=`w'lspact if year==`y'
	replace tcr=`w'tcr if year==`y'
	replace tcnr=`w'tcnr if year==`y'
	replace tcr04 =`w'tcr04  if year==`y'
    keep xwaveid year lspact *lspact tcr *tcr tcnr *tcnr tcr04  *tcr04 
    local y = `y' + 1
}

/*------------------------------------------------------------------------------
#2 Merge measure from HILDA-CNEF for comparison
------------------------------------------------------------------------------*/

sort xwaveid year
merge 1:1 xwaveid year using "${rdta}/01_HILDA/STATA 190c (Other)/CNEF_Long_s190c.dta" ///
        , keep (1 3) keepusing(zzm11104 zzd11107 zzh11103 zzh11104) nogen

rename (zzm11104 zzd11107 zzh11103 zzh11104) (lspact_cnef hhkid hhmem0_1 hhmem2_4)

destring xwaveid , replace
recast float xwaveid
recast float year

* sort data
sort xwaveid year
order xwaveid year lspact lspact_cnef

* inspect data
describe                        // show all variables contained in data
notes                           // show all notes contained in data
codebook, problems              // potential problems in dataset
duplicates report xwaveid year

*------------------------------------------------------------------------------*

label data "HILDA 190c, 2001-2019, physical activity, parenthood"

datasignature set, reset

save "${pdta}/hilda-pa.dta", replace

*==============================================================================*
