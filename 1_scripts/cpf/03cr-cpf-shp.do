/*==============================================================================
File:           05cr-cpf-shp-10ph-data.do
Task:           Creates shp extract to integrate in CPF file
Project:      	Parenthood & health behaviour
Author(s):      Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Info on how to get the data
#2 Append waves
#3 Generate vars and labels (Waves)
#4 Clean up and save (Waves)
#5 Append waves (CNEF)
#6 Generate vars and labels (CNEF)
#7 Clean up and save (CNEF)
#8 Combine wave data and cnef data
#9 Inspect data
#10 Label and save
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:


 
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
#1 Info on how to get and install the data (TO-DO):

	a) Download SHP Data folders (W1-W21, WA & CNEF) zipped files from:

	https://forscenter.ch/projects/swiss-household-panel/

	b) Place all folders as they are in 04_SHP\Data

------------------------------------------------------------------------------*/

version 16.1                            // Stata version control
capture log close                       // Closes log files
scalar starttime = c(current_time)      // Tracks running time

/*------------------------------------------------------------------------------
#2 Append waves
------------------------------------------------------------------------------*/

* generate strings of waves' numbers  

local waves `" "00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "' 
local n=10
local last=${shp_w}
while `n'<= `last' {
    local i="`n'"
    local waves = `" `waves'"' + `" "`i'" "' 
	local ++n
}
global waves= `"`waves'"'
di $waves

*
local waves2 `" "00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "' 
local n=10
local last=${shp_w}-2
while `n'<= `last' {
    local i="`n'"
    local waves2 = `" `waves2'"' + `" "`i'" "' 
	local ++n
}
global waves2= `"`waves2'"'
di $waves2

*
global years =   "99"  + `" `waves2'"' 
di $years
 
*
local n=1
local last=${shp_w}
while `n'<= `last' {
    local i="`n'"
    local wavesn = `" `wavesn'"' + `" "`i'" "' 
	local ++n
}
global wavesn= `"`wavesn'"'
di $wavesn

* get a wide file with all variables 

use "${shp_in}\SHP-Data-WA-STATA\shp_mp.dta", clear
	merge 1:1 idpers using "${shp_in}\SHP-Data-W1-W${shp_w}-STATA\W1_1999\shp99_p_user", nogen keep(1 3) 
	gen wave99=1999
		local m=2  // local macro for a loop
			foreach y in $waves2 {
				merge 1:1 idpers using "${shp_in}\SHP-Data-W1-W${shp_w}-STATA\W`m'_20`y'\shp`y'_p_user", nogen keep(1 3) 
				gen wave`y'=20`y'
				local m = `m' + 1
			}

* reduce variable continuum to needed variables

keep ///
idpers* wave* age* idhous* birthy isced* pdate*	///
ownkid* civsta* status* wstat* p*d29 p*w77 p*w39 p*w12 p*w13 p*w14 p*w05 x*w02

* rename vars with 'year' inside of the name
		
unab all: p*d29 p*w77 p*w39 p*w12 p*w13 p*w14 p*w05 x*w02
	
local allcount : word count `all'
disp `allcount'

 foreach i in p x {
    local n=1
    foreach y in $years {
		rename (`i'`y'*) (`i'_*_`n'), r
		local ++n 
		}
}

* renaming vars with year at the end

unab all:    ///
	idpers* wave* age* idhous* isced* pdate* ownkid*	///
	civsta* status* wstat*
local allcount : word count `all'
disp `allcount'

local x=0
foreach name in wave age idhous isced pdate ownkid ///
	civsta status wstat {
		rename `name'* `name'#, renumber dryrun  // Reports results 
		rename `name'* `name'_#, renumber r
		unab namess: `name'*
		local count : word count `namess'
		local x=`x'+`count'
}
	di "Renamed variables: " `x' "+ birthy & idpers"

* reshape

local vars1 	///
		age_ idhous_ isced_ pdate_ ownkid_	///
		civsta_ status_ wstat_
local vars2 	///
		p_d29_ p_w77_ p_w39_ p_w12_ p_w13_ p_w14_ p_w05_ x_w02_
		 
		* capture variable labels
		
			foreach n in `vars1' `vars2' {
				local `n'label: variable label `n'${shp_w}
			}

		* reshape
		
		reshape long  "`vars1'" "`vars2'" ///
			, i(idpers) j(wave $wavesn)

		* redefine labels
		
			foreach n in `vars1' `vars2' {
				label variable `n' "``n'label'"
			}

* order

order wave_*, first
drop wave_1-wave_19

* recode wave

local year=1999
local wavesn=`" ${wavesn} "'
foreach x in `wavesn' {
	recode wave  (`x'=`year')
	local ++year 
}

drop if pdate==. & age==.
	rename *_ *

order idpers wave idhous pdate birthy age, first
	disp "vars: " c(k) "   N: " _N

/*------------------------------------------------------------------------------
#3 Generate vars and labels (Waves)
------------------------------------------------------------------------------*/

* define common label

lab def yesno 0 "[0] No" 1 "[1] Yes" ///
        -1 "-1 MV general" -2 "-2 Item non-response" ///
        -3 "-3 Does not apply" -8 "-8 Question not asked in survey", replace

*-----------*
* Technical *
*-----------*

* personal identification number (pid)

rename idpers pid
	lab var pid "Unique identification number"

* household identification number (hid)

rename idhous hid
	lab var hid "Unique household identification number"
	
* interview year
	
rename wave intyear
	lab var intyear "Interview year"
	
* interview month  

gen intmonth=month(pdate)
	recode intmonth (.=-1)
		lab var intmonth "Interview month"
	
* wave identifier	
	
egen wave = group(intyear)
	lab var wave "Wave identifier"

* year identifier

gen wavey=intyear
	lab var wavey "Year identifier"

* repsondent status

recode status (0=1) (1=2) (2 4=3), gen(respstat)
	lab def respstat 	1 "Interviewed" 					///
						2 "Not interviewed (has values)" 	///
						3 "Not interviewed (no values)"
	lab val respstat respstat
	 lab var respstat "Respondent status"
	
* sort

sort pid wave	
	
*----------------------------------------*
* Sociodemographics & Family composition *
*----------------------------------------*

* age -> CNEF (see below) 

* Birth year

rename birthy yborn
	lab var yborn "Birth year" 
	
	* Correct age if values inconsistent with yborn (only if difference more than +/-1)
	
	gen temp_age_yborn=intyear-yborn if yborn>1000 & yborn<. 
	gen temp_age_err=age-temp_age_yborn if temp_age_yborn>0 & temp_age_yborn<120 & age>0 & age<120
	replace age=temp_age_yborn if (temp_age_err>1 | temp_age_err<-1) & temp_age_err!=.
	
	drop temp*		
		
* Gender -> CNEF (see below)

* education

	* education (3 levels)

	recode isced (-6 0 10 20=1) (31/33 41=2) (51/60=3) (-2=-2) (-1 -3 16=-1), gen(edu3)
		lab def edu3  1 "Low" 2 "Medium" 3 "High" // 2 incl Vocational
		lab val edu3 edu3
		lab var edu3 "Education: 3 levels"

	* education (4 levels)

	recode isced (-6 0 10=1) (20=2) (31/33 41=3) (51/60=4) (-2=-2) (-1 -3 16=-1), gen(edu4)

		lab def edu4  1 "[0-1] Primary" 2 "[2] Secondary lower" ///
					  3 "[3-4] Secondary upper" 4 "[5-8] Tertiary" 
		lab val edu4 edu4
		lab var edu4 "Education: 4 levels"
		
	* education (5 levels)

	recode isced (-6 0 10=1) (20=2) (31/33 41=3) (51=4) (52 60=5) (-2=-2) (-1 -3 16=-1), gen(edu5)

		lab def edu5  1 "[0-1] Primary" 2 "[2] Secondary lower" ///
					  3 "[3-4] Secondary upper" ///
					  4 "[5-6] Tertiary lower(bachelore)"  ///
					  5 "[7-8] Tertiary upper (master/doctoral)"
					  
		lab val edu5 edu5
		lab var edu5 "Education: 5 levels"

* primary martial status

recode civsta (2 6=1)(1 7=2)(5=3)(4=4)(3=5) (-8=-1)(-1=-3)(-2 -3=-2), gen(marstat5)
replace marstat5=1 if p_d29==1

	lab var marstat5 "Primary partnership status [5]"
	lab def marstat5				///
	1	"Married or Living with partner"	///
	2	"Single" 				///
	3	"Widowed" 				///
	4	"Divorced" 				///
	5	"Separated" 			///
	-1 "-1 MV general" -2 "-2 Item non-response" ///
	-3 "-3 Does not apply" -8 "-8 Question not asked in survey"
	lab val marstat5 marstat5

* children

clonevar kidsn_all=ownkid 
recode kidsn_all (0=0) (1/50=1), gen(kids_any)

	lab var kids_any  "Has any children"
	lab val kids_any   yesno
	lab var kidsn_all  "Number Of Children Ever Had"
	
* household size -> CNEF (see below)

* employment status

recode wstat (1=1)  (2 3=4) , gen(emplst5)
replace emplst5=3 if (p_w12==2 | p_w13==2 | p_w14==2) & age>=50
replace emplst5=3 if p_w12==3 | p_w13==3 | p_w14==3
replace emplst5=5 if p_w12==1 | p_w13==1 | p_w14==1
replace emplst5=2 if p_w05==1
replace emplst5=1 if x_w02>0 & x_w02<.

	lab def emplst5	///
			1 "Employed" 			/// including leaves
			2 "Unemployed (active)"	///
			3 "Retired, disabled"	///
			4 "Not active/home"		/// home-working separate?  
			5 "In education"		///
			-1 "MV"
	lab val emplst5 emplst5
	lab var emplst5 "Employment status [5]"

* working hours

recode p_w77 (-7 -5=-1), gen(whweek)
	lab var whweek "Work hours per week: worked"

gen whmonth=whweek*4.3
replace whmonth=whweek if whweek<0
	lab var whmonth "Work hours per month: worked"
	
* full/part time

recode p_w39 (1=2) (2=1) , gen(fptime_r)
replace fptime_r=3 if p_w39==-3 & (wstat==2 | wstat==3)

gen fptime_h=.
replace fptime_h=1 if whweek>=35 & whweek<.
replace fptime_h=2 if whweek<35 & whweek>0
replace fptime_h=3 if whweek==0
replace fptime_h=3 if emplst5>1 & emplst5<.
replace fptime_h=whweek if whweek<0 & fptime_h==.

	lab var fptime_r "Employment Level (self-report)"
	lab var fptime_h "Employment Level (based on hours)"
	
  	lab def fptime 1 "Full-time" 2 "Part-time/irregular" 3 "Not empl/other"
  	lab val fptime_r fptime
	lab val fptime_h fptime
	
/*------------------------------------------------------------------------------
#4 Clean up and save (Waves)
------------------------------------------------------------------------------*/

*keep

keep ///
	wave pid age* edu* intmonth intyear	///
	yborn kid* ///
	wavey	///
	marstat* whweek whmonth fptime_h fptime_r emplst5 ///
	respstat

* order

order ///
	pid intyear intmonth wave wavey respstat ///
	age yborn edu3 edu4 edu5 marstat5 whweek whmonth fptime_h fptime_r emplst5 ///
	kidsn_all kids_any

*save

save "${shp_out}\shp_waves.dta", replace

/*------------------------------------------------------------------------------
#5 Append waves (CNEF)
------------------------------------------------------------------------------*/
 
* correct var names

local wf 1999 // first wave
local wl `wf'+ ${shp_w}-1 // last wave
	while (`wf' <= `wl') {
		use "${shp_in_cnef}\shpequiv_`wf'.dta", clear
			rename *_`wf' *
			gen wave=`wf'
			save "${shp_out_work_cnef}\shpequiv_`wf'.dta", replace
		local `wf++'
}  

* append

local wf 1999 // first wave
local wl `wf'+ ${shp_w}-1 // last wave
	use "${shp_out_work_cnef}\shpequiv_`wf'.dta", clear
	while (`wf' < `wl') {
	  local `wf++'
	  display "Appending wave: "`wf'
			qui append using "${shp_out_work_cnef}\shpequiv_`wf'.dta"
	  display "No of vars after appned: " c(k) " N: " _N
	  display ""
	}
*	

save "${shp_out}\shp_cnef.dta", replace

* Delete temp files 

!del "${shp_out_work_cnef}\*.dta"

/*------------------------------------------------------------------------------
#6 Generate vars and labels (CNEF)
------------------------------------------------------------------------------*/

* define common label

lab def yesno 0 "[0] No" 1 "[1] Yes" ///
        -1 "-1 MV general" -2 "-2 Item non-response" ///
        -3 "-3 Does not apply" -8 "-8 Question not asked in survey", replace

*-----------*
* Technical *
*-----------*
	
* personal identification number (pid)

rename  x11101ll pid
	lab var pid "Unique identification number"
	
* interview year	
	
rename wave intyear
    lab var intyear "Interview year"

* wave identifier

egen wave = group(intyear)
	lab var wave "Wave identifier"

* year identifier

gen wavey=intyear
	lab var wavey "Year identifier"

* country identifier

gen country=4
	lab var country "Country"

* respondent status 

recode status (0 1=1) (2=2), gen(respstat)
	lab def respstat 	1 "Interviewed" 					///
						2 "Not interviewed (has values)" 	///
						3 "Not interviewed (no values)"
	lab val respstat respstat
	lab var respstat "Respondent status"
	
* 1st appearance in dataset	
	
bysort pid: egen wave1st = min(wave)
	label var wave1st "1st appearence in dataset"
	
* sample identifier

clonevar sampid_shp = x11104ll
	lab var sampid_shp "Sample identifier: SHP"

* sort

sort pid wave

*----------------------------------------*
* Sociodemographics & Family composition *
*----------------------------------------*

* age -> CNEF (see above)

* birth year -> CNEF (see above)
	
* Gender

recode d11102ll (1=0) (2=1), gen(female)
	lab def female 0 "Male" 1 "Female" 
	lab val female female 
	lab var female "Gender" 

* education	
	
	* educational years

	recode d11109 (-1=-3) (-2 -3=-2), gen(eduy)
		lab var eduy "Education: years"

* marital status -> CNEF (see above)

* children
 
clonevar kidsn_hh17=d11107 
	lab var kidsn_hh17   "Number of Children in HH aged 0-17"

* household size

clonevar nphh=d11106
	lab var nphh   "Number of People in HH"
	
* working hours per year

recode e11101 (-1=-3) (-2 -3=-2), gen(whyear)
	lab var whyear "Work hours per year: worked"
	
* full/part-time
	
recode e11103 (-1=-3) (-2 -3=-2), gen(fptime_h)
	
 	lab def fptime 1 "Full-time" 2 "Part-time/irregular" 3 "Not empl/other"
 	lab val fptime_h fptime
	lab var fptime_h "Employment Level (based on hours)"

/*------------------------------------------------------------------------------
#7 Clean up and save (CNEF)
------------------------------------------------------------------------------*/
* keep

keep ///
wave pid intyear country edu* ///
kid* female nphh whyear fptime_h ///
wave1st respstat sampid*

* save
	 
save "${shp_out}\shp_cnef.dta", replace

/*------------------------------------------------------------------------------
#8 Combine wave data and cnef data
------------------------------------------------------------------------------*/

use "${shp_out}\shp_cnef.dta", clear 
	disp "vars: " c(k) "   N: " _N

* add waves

merge 1:1 pid wave using "${shp_out}\shp_waves.dta" , ///
	keep(1 2 3) nogen 
	disp "vars: " c(k) "   N: " _N
	
* Fill MV based on whyear (imputed by CNEF)

replace whmonth=whyear/12 if (whmonth==.|whmonth<0) & whyear>0 & whyear<.
replace whweek=whyear/(12*4.3) if (whweek==.|whweek<0) & whyear>0 & whyear<. 	

* order

order ///
	pid intyear intmonth wave wavey country sampid_shp wave1st respstat ///
	age female yborn eduy edu3 edu4 edu5 marstat5 whweek whmonth fptime_h fptime_r emplst5 ///
	kidsn_all kids_any kidsn_hh17 nphh

/*------------------------------------------------------------------------------
#9 Inspect data
------------------------------------------------------------------------------*/				  

log using "${logs}/03shp_inspect$ps.log", replace

* sort data

sort pid wavey

* inspect data

describe                       	// show all variables contained in data
notes                          	// show all notes contained in data
codebook, problems             	// potential problems in dataset
duplicates report pid wavey		// report duplicates
inspect                        	// distributions, #obs , missings

capture log close
	
/*------------------------------------------------------------------------------
#10 Label & save
------------------------------------------------------------------------------*/

* sample selection

	* age
	
	keep if age>=18
	
	* MV in age and gender
	
	keep if female~=.
	keep if age~=.

* label data
 
label data "CPF_CH, parenthood"
    datasignature set, reset

* save

save "${shp_out}\shp$ps.dta" , replace
	erase "${shp_out}\shp_cnef.dta"
	erase "${shp_out}\shp_waves.dta"

*------------------------------------------------------------------------------*

* display running time

scalar endtime = c(current_time)

display ((round(clock(endtime, "hms") - clock(starttime, "hms"))) / 60000) " minutes"

*==============================================================================*


