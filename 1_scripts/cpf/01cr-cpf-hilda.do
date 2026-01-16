/*==============================================================================
File:           01cr-cpf-hilda.do
Task:           Creates hilda extract to integrate in CPF file
Project:      	Parenthood & health behaviour
Author(s):      Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Info on how to get the data
#2 Rename files to fit in one dataset
#3 Append waves
#4 Generate vars and labels (Waves)
#5 Clean up and save (Waves)
#6 Generate vars and labels (CNEF)
#7 Clean up and save (CNEF)
#8 Combine original data and cnef data
#9 Clean up
#10 Inspect data
#11 Label and save
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:


 
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
#1 Info on how to get and install the data (TO-DO):

	a) Download "STATA 190c Combined & Other" zipped files from:

	https://melbourneinstitute.unimelb.edu.au/hilda

	b) Place both folders ("Combined" & "Other) as they are in 01_HILDA\Data

------------------------------------------------------------------------------*/

version 16.1                            // Stata version control
capture log close                       // Closes log files

/*------------------------------------------------------------------------------
#2 Rename files to fit in one dataset
------------------------------------------------------------------------------*/

* delete wave identifier in var names (letters) & add variable wave to each file

local waves = substr(c(alpha), 1, (${hilda_w} *2)-1)   // letters identifying waves 

local year=2001

foreach w in `waves' {
	 use "${hilda_in}\STATA ${hilda_w}0c (Combined)\Combined_`w'${hilda_w}0c.dta", clear
		 gen wave=`year'
		 rename `w'* *
		 sort xwaveid
		 order xwaveid wave, first
	 save "${hilda_out_work}\hilda`year'.dta", replace
	 local ++year
}

/*------------------------------------------------------------------------------
#3 Append waves
------------------------------------------------------------------------------*/

use "${hilda_out_work}\hilda2001.dta", clear 

local last = 20${hilda_w}

foreach w of numlist  2002/`last' {
	  display "Appending wave: "`w'
		 qui append using "${hilda_out_work}\hilda`w'.dta"
		 display "After append of wave `w' - Vars:" c(k) " N: " _N
		 display ""
}

sort xwaveid wave

* delete temp files

!del "${hilda_out_work}\*.dta"

/*------------------------------------------------------------------------------
#4 Generate vars and labels (Waves)
------------------------------------------------------------------------------*/

* define common label

lab def yesno 0 "[0] No" 1 "[1] Yes" ///
        -1 "-1 MV general" -2 "-2 Item non-response" ///
        -3 "-3 Does not apply" -8 "-8 Question not asked in survey", replace

*-----------*
* Technical *
*-----------*

* personal identification number (pid)

rename xwaveid pid
	lab var pid "Unique identification number"

	* to fill MV:
	
	bysort pid: egen wave1st = min(cond(hgint == 1, wave, .))

* interview year

gen intyear=substr(hhhqivw, -4, 4)
	destring intyear, replace force
    replace intyear=-1 if intyear==-4
        lab var intyear "Interview year"
		
* interview month       
        
gen intmonth=substr(hhhqivw, -7, 2)
	destring intmonth, replace force
	replace intmonth=-1 if intmonth==-4
        lab var intmonth "Interview month"

* year identifier       
        
rename wave wavey
	lab var wavey "Year identifier"
	
* wave identifier	

egen wave = group(wavey)
	lab var wave "Year identifier"

* country identifier

gen country=1
	lab var country "Country"

* respondent status

recode hgint (0=3), gen(respstat)
        lab def respstat 1 "Interviewed" ///
						 2 "Not interviewed (has values)" ///
                         3 "Not interviewed (no values)"
        lab val respstat respstat
        lab var respstat "Respondent status"
        
* 1st appearance in dataset

label var wave1st "1st appearence in dataset"

* sort

sort pid wave

*----------------------------------------*
* Sociodemographics & Family composition *
*----------------------------------------*

* age

rename hhiage age
	lab var age "Age"

* birth year

gen yborn=hgyob
	lab var yborn "Birth year"

        
* Gender -> CNEF (see below)

* education
 
	* education (3 levels)

	recode edhigh1 (9 =1) (8 5=2) (1/4=3) (-10=-3) (10 =-1), gen(edu3)

	replace edu3=2 if edhigh1==9 & edhists==1
		lab def edu3  1 "[0-2] Low" 2 "[3-4] Medium" 3 "[5-8] High" // 2 incl Vocational
		lab val edu3 edu3
		lab var edu3 "Education: 3 levels"
			
	* education (4 levels)

	recode edu3 (2=3) (3=4), gen(edu4)
		replace edu4=2 if edhigh1==9 & edhists>1 & edhists<=5
		replace edu4=3 if edhigh1==9 & edhists==1

		lab def edu4  1 "[0-1] Primary" 2 "[2] Secondary lower" ///
					  3 "[3-4] Secondary upper" 4 "[5-8]Tertiary" 
		lab val edu4 edu4
		lab var edu4 "Education: 4 levels"

	* education (5 levels)

	recode edhigh1 (9 =1) (8 5=3) (4 3=4) (2 1=5) (-10=-3) (10 =-1), gen(edu5)
		replace edu5=2 if edhigh1==9 & edhists>1 & edhists<=5
		replace edu5=3 if edhigh1==9 & edhists==1

			lab def edu5  1 "[0-1] Primary" 2 "[2] Secondary lower" ///
									  3 "[3-4] Secondary upper" 4 "[5-6] Tertiary lower(bachelore)"  ///
									  5 "[7-8] Tertiary upper (master/doctoral)"
			lab val edu5 edu5
			lab var edu5 "Education: 5 levels"

			* Fill MV based on other waves 

			qui sum wave
			local max= r(max)
			forvalues  n= 1/`max'  {
			foreach e in 3 4 5 			{
			bysort pid (wave): replace edu`e'=edu`e'[_n+1] if age>24 & edu`e'[_n+1]>0 & edu`e'[_n+1]<. & edu`e'<0  		
			}
			}

	* educational years

	gen eduy=.
		replace eduy=18.5       if edhigh1==1
		replace eduy=16         if edhigh1==2
		replace eduy=15         if edhigh1==3
		replace eduy=13         if edhigh1==4
		replace eduy=12         if edhigh1==5
		replace eduy=12         if edhigh1==8
		replace eduy=0 if edhigh1==9 & edagels==1
		replace eduy=11  if edhigh1==9 & edagels==2 & edhists==1
		replace eduy=10  if edhigh1==9 & edagels==2 & edhists==2
		replace eduy=9  if edhigh1==9 & edagels==2 & edhists==3
		replace eduy=8  if edhigh1==9 & edagels==2 & edhists==4
		replace eduy=7  if edhigh1==9 & edagels==2 & edhists==5
		replace eduy=6  if edhigh1==9 & edagels==2 & edhists==6
		replace eduy=6  if edhigh1==9 & edagels==2 & edhists==7
		replace eduy=4  if edhigh1==9 & edagels==2 & edhists==8  
		replace eduy=11  if edhigh1==9 & edagels>2 & edhists==2
		replace eduy=10  if edhigh1==9 & edagels>2 & edhists==3
		replace eduy=9  if edhigh1==9 & edagels>2 & edhists==4
		replace eduy=8  if edhigh1==9 & edagels>2 & edhists==5
		replace eduy=7  if edhigh1==9 & edagels>2 & edhists==6
		replace eduy=6  if edhigh1==9 & edagels>2 & edhists==7
		replace eduy=4  if edhigh1==9 & edagels>2 & edhists==8
			
		* fill MV based on edu
		
		replace eduy=6 if eduy==. & edu5==1
			lab var eduy "Education: years"

* primary martial status

recode mrcurr (1 2=1) (6=2)(5=3)(4=4)(3=5) (-10=-3) (-4 -3=-1), gen(marstat5)
        lab var marstat5 "Primary partnership status [5]"
        lab def marstat5                                ///
        1       "Married or Living with partner"        ///
        2       "Single"                                ///
        3       "Widowed"                               ///
        4       "Divorced"                              ///
        5       "Separated"                     ///
        -1 "-1 MV general" -2 "-2 Item non-response" ///
        -3 "-3 Does not apply" -8 "-8 Question not asked in survey"
        lab val marstat5 marstat5
        
* children

gen kidsn_all=tchad

	recode kidsn_all (-10=-3) (-4 -3=-1)
	recode kidsn_all (1/max=1) (0=0), gen(kids_any)
	egen kidsn_hh17= anycount(hgage1-hgage20), values(0/17)
	
	lab var kids_any  "Has any children"
	lab val kids_any   yesno
	lab var kidsn_all  "Number Of Children Ever Had " 
	lab var kidsn_hh17   "Number of Children in HH aged 0-17"

* household size -> CNEF (See below)

* employment status

recode esbrd (1=1) (2=2) (3=4) (-10=-3), gen(emplst5)
replace emplst5=3 if (nlmact==1 | rtcomp==1 | rtcompn==1) 	/// self-rep retired completely 
					& hgage>=50 							/// age 45+
					& esbrd==3 								//  not active 
replace emplst5=3 if (nlmact==4 & helth==1 & (helthwk==1 | helthwk==3)) // disab
	egen temp=anymatch( ///
		edcq100 edcq110 edcq120 edcq200 edcq211 edcq221 edcq310 ///
		edcq311 edcq312 edcq400 edcq411 edcq413 edcq421 edcq500 ///
		edcq511 edcq514 edcq521 edcq524 edcq600 edcq611) 		///
		,v(1)
replace emplst5=5 if nlmact==3 & temp==1
	drop temp
replace emplst5=5 if emplst5==4 & edagels==2
replace emplst5=2 if esbrd==2
replace emplst5=1 if esbrd==1

	lab def emplst5	///
			1 "Employed" 			/// including leaves
			2 "Unemployed (active)"	///
			3 "Retired, disabled"	///
			4 "Not active/home"		/// home-working separate?  
			5 "In education"		///
			-1 "MV"
	lab val emplst5 emplst5
	lab var emplst5 "Employment status [5]"

* working hours per week

recode jbhruc (-10 -1=-3) (-6 -4 -3=-1), gen(whweek)
gen whmonth=whweek*4.3
replace whmonth=whweek if whweek<0

lab var whweek "Work hours per week: worked"
lab var whmonth "Work hours per month: worked"
	
* full/part time

recode esdtl (3/7=3)(-10=-3), gen(fptime_r)

gen fptime_h=.
replace fptime_h=1 if whweek>=35 & whweek<.
replace fptime_h=2 if whweek<35 & whweek>0
replace fptime_h=3 if whweek==0
replace fptime_h=3 if emplst5>1 & emplst5<.
 
	lab var fptime_r "Employment Level (self-report)"
	lab var fptime_h "Employment Level (based on hours)"
	
	lab def fptime 1 "Full-time" 2 "Part-time/irregular" 3 "Not empl/other"
	lab val fptime_r  fptime_h fptime
         
/*------------------------------------------------------------------------------
#5 Clean up and save (Waves)
------------------------------------------------------------------------------*/

* keep

keep    ///
	wave wavey wave1st pid yborn intyear intmonth country age respstat ///
	edu*    ///     
	marstat* kids* whweek whmonth fptime_r fptime_h emplst5

* order

order pid wave intyear age wavey

* save 
         
save "${hilda_out}\hilda_waves.dta", replace

/*------------------------------------------------------------------------------
#6 Generate vars and labels (CNEF)
------------------------------------------------------------------------------*/

* open merged dataset

local w=word("`c(alpha)'", ${hilda_w})  // convert wave's number to letter 
use "${hilda_in}\STATA ${hilda_w}0c (Other)\CNEF_Long_`w'${hilda_w}0c.dta", clear

* delete prefix of variables    

rename zz* *

* define common label

lab def yesno 0 "[0] No" 1 "[1] Yes" ///
        -1 "-1 MV general" -2 "-2 Item non-response" ///
        -3 "-3 Does not apply" -8 "-8 Question not asked in survey", replace

*-----------*
* Technical *
*-----------*

* create personal identification number (pid)

rename xwaveid pid

* interview year

rename year intyear
	lab var intyear "Interview year"
	
* wave identifier	
	
egen wave = group(intyear)
	lab var wave "Wave identifier"
	
* sample identifier

clonevar sampid_hilda = x11106ll
	lab val sampid_hilda sampid_hilda
	lab var sampid_hilda "Sample identifier: HILDA"	
	
* sort

sort pid wave

*----------------------------------------*
* Sociodemographics & Family composition *
*----------------------------------------*

* age -> Wave data (see above)

* Birth year -> Wave data (see above)
        
* Gender

recode d11102ll (1=0) (2=1), gen(female)

	lab def female 0 "Male" 1 "Female" 
        lab val female female
        lab var female "Gender"

* education -> Wave data (see above)

* formal marital status -> Wave data (see above)
        
* children

clonevar kidsn_hh18=d11107 
	lab var kidsn_hh "Number of Children in HH 0-18"

* household size

clonevar nphh=d11106
    lab var nphh "Number of People in HH"
	
* working hours per year

recode e11101 (-1=-3) (-3=-1), gen(whyear)
	lab var whyear "Work hours per year: worked"
	
* full/part time

recode e11103 (-1=-3) (-3=-1), gen(fptime_h)
	lab def fptime 1 "Full-time" 2 "Part-time/irregular" 3 "Not empl/other"
	lab val fptime_h fptime
	lab var fptime_h "Employment Level (based on hours)"
	
/*------------------------------------------------------------------------------
#7 Clean up and save (CNEF)
------------------------------------------------------------------------------*/

* keep

keep    ///
	wave pid intyear ///
	kids* female nphh whyear fptime_h                                   

sort pid wave

order pid wave intyear female

save "${hilda_out}\hilda_cnef.dta", replace

/*------------------------------------------------------------------------------
#8 Combine original data and cnef data
------------------------------------------------------------------------------*/

use "${hilda_out}\hilda_cnef.dta", clear
	disp "vars: " c(k) "   N: " _N

* add waves

merge 1:1 pid wave using "${hilda_out}\hilda_waves.dta" , ///
	keep(1 2 3) nogen
	disp "vars: " c(k) "   N: " _N
	
/*------------------------------------------------------------------------------
#9 Clean up
------------------------------------------------------------------------------*/	

* order

order pid intyear intmonth wave wavey country wave1st respstat ///
age female yborn edu3 edu4 edu5 marstat5 ///
kidsn_all kids_any kidsn_hh17 nphh emplst5 whweek whmonth whyear fptime_r fptime_h

* destring pid

destring pid, replace

* Fill MV based on whyear (imputed by CNEF)

	replace whmonth=whyear/12 if (whmonth==.|whmonth<0) & whyear>0 & whyear<.
	replace whweek=whyear/(12*4.3) if (whweek==.|whweek<0) & whyear>0 & whyear<.

* sample selection

	* age
	
	keep if age>=18
	
	* MV in age and gender
	
	keep if female~=.
	keep if age~=.
	
/*------------------------------------------------------------------------------
#10 Inspect data
------------------------------------------------------------------------------*/				  

log using "${logs}/01hilda_inspect$ps.log", replace

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
#11 Label & save
------------------------------------------------------------------------------*/	

* label data
 
label data "CPF_AU, parenthood"
    datasignature set, reset
	
* save

save "${hilda_out}\hilda$ps.dta" , replace
	erase "${hilda_out}\hilda_cnef.dta"
	erase "${hilda_out}\hilda_waves.dta"

*==============================================================================*
