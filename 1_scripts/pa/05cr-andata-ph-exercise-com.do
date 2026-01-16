/*==============================================================================
File name:      05cr-andata-ph-exercise-com.do
Task:           Creates person-year data from 4 countries with all information
Project:      	Parenthood and physical activity 
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Loads basic hamonized person-year data
#2 Merges country-specific files
#3 Generates and recodes variables
	A: Harmonized physical activity measures, comparable over 5 countries
	B: Country-specific physical activity measures, not comparable
	C: Parenthood indicators
	D: Harmonized covariates
#4 Defines sample for analysis
#5 Inspect data
#6 Label & Save
#7 Cut section
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:
						
SHP: Both PA variables measure the same (except missings on days)

PSID: Birth year of first (adopted) child
other: First change in kids 0-1 in HH while kids in HH==0

Do this for 
(1) maximum time period for each country
(2) 2004- for all countries

bysort country female: sum agekid1 if syear==yrkid1, det 
Some cases with age at first birth > 45 (even for women)
But not excessive 
Excluded through age restriction on sample

Using only Number of Children in HH to define nonparents will lead to exclusion
of some nonparents

------------------------------------------------------------------------------*/

version 16.1  						// Stata version control
capture log close					// Closes log files

/*------------------------------------------------------------------------------
#1 Load basic harmonized person-year data
------------------------------------------------------------------------------*/

use "${wdir}\3_pdta\cpf\01cpf-out\CPF-pa.dta", clear

drop if (country==2 & wavey<1999) | (country==5 & wavey<1999)					// Drop all data prior 1999
drop if country==3 | country == 6												// Drop countries, who have no dependent variable
drop smoke* evsmoke* ncig*														// Drop not needed dependend variables
clonevar year = wavey

/*------------------------------------------------------------------------------
#2 Merge country-specific files & add dependent variables
------------------------------------------------------------------------------*/

*-------*
* HILDA *
*-------*

clonevar xwaveid = orgpid if country==1

sort xwaveid year
merge m:1 xwaveid year using "${pdta}/hilda-pa.dta"  ///
    , keep (1 3) keepusing(lspact lspact_cnef hh* tc*) nogen
    
	for any lspact lspact_cnef hh* tc*: rename X X_au

*------*
* PSID *
*------*

clonevar parpid = orgpid if country==2
sort parpid
merge m:1 parpid using "${pdta}/psid-kids.dta" ///
     , keep(1 3) keepusing(mn1brth yr1brth *kid*) nogen
	 
/*==============================================================================
***   Note:	Since variables in PSID are divided in information regarding head
			and spouse, we first have to build combined measures
==============================================================================*/

	for any panl patl panh path panm patm href mn1brth yr1brth nnatkid nadokid nokids: rename X X_us
	
*-----*
* SHP *
*-----*

clonevar idpers = orgpid if country==4

sort idpers year
merge m:1 idpers year using "${pdta}/shp-pa.dta"  ///
    , keep (1 3) keepusing(phact phact_days phact_cnef phact hh* ownkid) nogen
    
	for any phact phact_days phact_cnef hhkid hhmem0_1 hhmem2_4 ownkid: rename X X_ch

*------*
* SOEP *
*------*

clonevar persnr = orgpid if country==5
rename year syear

sort persnr syear
merge m:1 persnr syear using "${pdta}/soep-pa.dta"  ///
    , keep (1 3) keepusing(sport* hh*) nogen
    
	for any sport* hhkid hhmem0_1 hhmem2_4 region: rename X X_ge

sort persnr
merge m:1 persnr using "${rdta}/04_SOEP/soep.v36/raw/biobirth.dta"     ///
    , keep (1 3) keepusing (biovalid biokids sumkids                         ///
	                        kidpnr01 kidgeb01 kidsex01 kidmon01)             ///
				 nogen
              
rename persnr persnr_alt
rename kidpnr01 persnr
replace persnr=-persnr_alt if persnr<=0 | persnr==.
sort persnr

merge m:1 persnr using "${rdta}/04_SOEP/soep.v36/raw/ppfad.dta"    ///
    , keep (1 3) keepusing (sex gebjahr gebmonat) nogen nol
	
replace kidgeb01=gebjahr
replace kidmon01=gebmonat
replace kidsex01=sex    
drop sex gebjahr gebmonat
rename persnr kidpnr01
rename persnr_alt persnr

	for any biovalid biokids sumkids kidpnr01 kidgeb01 kidsex01 kidmon01: rename X X_ge 

/*------------------------------------------------------------------------------
#3 Generate and recode variables
------------------------------------------------------------------------------*/

*------------------------------------------------------------------------------*
* Part A: Harmonized physical activity maesures, comparable over 4 countries
*------------------------------------------------------------------------------*

* generate container for dummy no activity vs. at least 1/wk, comparable over 5 countries

gen phact_act=.   	

	lab def phact_act 0 "Not active weekly" 1 "Active at least weekly", replace
	lab val phact_act phact_act
	lab var phact_act "PA: Not active weekly/Active at least weekly (4 Ctry.)"

*-------*
* HILDA *
*-------*

recode lspact_au -8/-4=. 1/2=0 3/6=1, gen(phact_act_au)
	for any phact_act: replace X=X_au if country==1
		lab val phact_act_au phact_act
		lab var phact_act_au "PA: Not active weekly/Active at least weekly (AU)"

*------*
* PSID *
*------*

* Heavy (Days) - 2 Day, 3 Week, 5 Month, 6 Year, 7 Other

** active: days
	gen hphact_days_us=panh_us if path_us==2
	replace hphact_days_us=7 if hphact_days_us>7 & hphact_days_us<.
	
** active: weeks
	replace hphact_days_us=panh_us if path_us==3
	replace hphact_days_us=7 if hphact_days_us>7 & hphact_days_us<.
	
** active: months	
	replace hphact_days_us=panh_us/4 if path_us==5
	replace hphact_days_us=7 if hphact_days_us>7 & hphact_days_us<.
	
** active: years	
	replace hphact_days_us=panh_us/52 if path_us==6
	replace hphact_days_us=0 if panh_us==0

** gen dummy "Not active weekly/Active at least weekly"

gen phact_act_us=0 if country==2 & hphact_days_us<1
	
replace phact_act_us=1 if country==2 & hphact_days_us>=1 & hphact_days_us<.
	for any phact_act: replace X=X_us if country==2
		lab val phact_act_us phact_act
		lab var phact_act_us "PA: Not active weekly/Active at least weekly (US)"

*-----*
* SHP *
*-----*

recode phact_ch -3/-1=. 2=1 1=0, gen(phact_ch_aux)
gen phact_act_ch=(phact_ch_aux-1)*-1

replace phact_act_ch=. if phact_days_ch==-3 | phact_days_ch==-2 | phact_days_ch==-1 | phact_days_ch==.
replace phact_act_ch=0 if phact_ch==2 & phact_days_ch == -3
	for any phact_act: replace X=X_ch if country==4
		lab val phact_act_ch phact_act
		lab var phact_act_ch "PA: Not active weekly/Active at least weekly (CH)"
	
drop phact_ch_aux

*------*
* SOEP *
*------*

gen phact_ge=.
forval y = 1985(1)2019 {
    capture replace phact_ge=sport`y'_ge if syear==`y' & country==5
}

* different scale in several years (after 1984)

replace phact_ge=phact_ge-1 if phact_ge>1 & country==5 & (syear==1990 | syear==1995 | syear==1998 | ///
                                    syear==2003 | syear==2008 | syear==2013 | ///
                                    syear==2019)

replace phact_ge=. if syear==2018 & country==5 // only collected from refugee samples
	lab val phact_ge bhp_10_03                                    
                                    

recode phact_ge -5/-1=. 2/4=0, gen(phact_act_ge)
	for any phact_act: replace X=X_ge if country==5
		lab val phact_act_ge phact_act
		lab var phact_act_ge "PA: Not active weekly/Active at least weekly (GE)"

*------------------------------------------------------------------------------*
* Part B: Country-specific physical activity measures, not comparable
*------------------------------------------------------------------------------*

* generate container for country-specific physical activity

gen phact_ctr=.
	lab var phact_ctr "PA: Country-specific Exercise (4 Ctry.)"

*-------*
* HILDA *
*-------*

recode lspact_au -8/-4=. , gen(phact_ctr_au)
	replace phact_ctr_au = phact_ctr_au-1
	recode phact_ctr_au 0=5 1=4 2=3 3=2 4=1 5=0
	for any phact_ctr: replace X=X_au if country==1
		lab def phact_ctr_au 0 "Daily" 1 ">3x/week" 2 "3x/week" 3 "1 to 2x/week" 4 "<1x/week" 5 "Never",  replace
		lab val phact_ctr_au phact_ctr_au
		lab var phact_ctr_au "PA: Exercise (AU)"

*------*
* PSID *
*------*

gen phact_ctr_us=.
	replace phact_ctr_us = 0 if hphact_days_us == 7 & panh_us >0
	replace phact_ctr_us = 1 if hphact_days_us <7 & hphact_days >=6 & panh_us >0
	replace phact_ctr_us = 2 if hphact_days_us <6 & hphact_days >=5 & panh_us >0
	replace phact_ctr_us = 3 if hphact_days_us <5 & hphact_days >=4 & panh_us >0
	replace phact_ctr_us = 4 if hphact_days_us <4 & hphact_days >=3 & panh_us >0
	replace phact_ctr_us = 5 if hphact_days_us <3 & hphact_days >=2 & panh_us >0
	replace phact_ctr_us = 6 if hphact_days_us <2 & hphact_days >=1 & panh_us >0
	replace phact_ctr_us = 7 if panh_us == 0
	for any phact_ctr: replace X=X_us if country==2
		lab def phact_ctr_us 0 "7x/week" 1 "6x/week" 2 "5x/week" 3 "4x/week" 4 "3x/week" 5 "2x/week" 6 "1x/week" 7 "Never", replace
		lab val phact_ctr_us phact_ctr_us
		lab var phact_ctr_us "PA: Exercise (US)"

*-----*
* SHP *
*-----*

gen phact_ctr_ch=.
	replace phact_ctr_ch = 0 if phact_ch == 2
	replace phact_ctr_ch = phact_days_ch if phact_ch == 1
	recode phact_ctr_ch -3/-1=. 0=7 1=6 2=5 3=4 4=3 5=2 6=1 7=0
	for any phact_ctr: replace X=X_ch if country==4
		lab def phact_ctr_ch 0 "7x/week" 1 "6x/week" 2 "5x/week" 3 "4x/week" 4 "3x/week" 5 "2x/week" 6 "1x/week" 7 "Never", replace
		lab val phact_ctr_ch phact_ctr_ch																						
		lab var phact_ctr_ch "PA: Exercise (CH)"

*------*
* SOEP *
*------*

recode phact_ge -5/-1=. 1=0 2=1 3=2 4=3, gen(phact_ctr_ge)
	for any phact_ctr: replace X=X_ge if country==5
		lab def phact_ctr_ge 0 "Weekly" 1 "Monthly" 2 "Rare" 3 "Never", replace
		lab val phact_ctr_ge phact_ctr_ge
		lab var phact_ctr_ge "PA: Exercise (DE)"

*------------------------------------------------------------------------------*

* check for distributions of pa variable in all countries

log using "${text}/pa_av.log", replace

	foreach c in _au _us _ch _ge {
		foreach var in 	phact_act phact_ctr {        
			tab wavey `var'`c', row nofreq 
			}
	}        

	bysort country: tab wavey phact_act, m row nofreq
	bysort country: tab wavey phact_ctr, m row nofreq

	foreach c in _au _us _ch _ge {
		foreach var in phact_ctr {        
			tab phact_act`c' `var'`c', row nofreq 
			}
	}   

capture log close

*------------------------------------------------------------------------------*
* Part C: Parenthood variables
*------------------------------------------------------------------------------*

* year of first birth (US)

gen yrkid1=yr1brth_us if country==2
	replace yrkid1=. if yr1brth>9000

* change in child 0-1 years between wavey while # of all children was 0 in prev. wave

foreach v in hhmem0_1 hhkid {
    gen `v'=`v'_au if country==1
    replace `v'=`v'_ch if country==4
    replace `v'=`v'_ge if country==5
}

sort pid wavey
gen chkid=1 if pid==pid[_n-1] & syear==syear[_n-1]+1 & country!=2 ///
            & (country!=3 & hhmem0_1>=1 & hhmem0_1<. & hhmem0_1[_n-1]==0 & hhkid[_n-1]==0)
			
	bysort country female: ta wavey chkid

* year of first birth (all countries)

bysort pid: egen aux=min(syear) if chkid==1 & country!=2
bysort pid: egen aux2=max(aux) if country!=2
	replace yrkid1=aux2 if country!=2
	drop aux*
	lab var yrkid1 "Year of first birth (All countries)"
	bysort female: tab yrkid1 country if yrkid1==syear & syear>=1999 			// in US only half of births captures by this command

* age at first birth (all countries)

gen agekid1=yrkid1-yborn
	bysort country female: sum agekid1 if syear==yrkid1, det 
	lab var agekid1 "Age at first birth"

* time-sensitive parenthood variable - years before/after parenthood

gen parent_ba=syear-yrkid1
	lab var parent_ba "Time before/after first birth" 

bysort female: ta parent_ba country if yrkid1>1998

* time-varying parenthood indicator (0=no parent/1=parent from here on)

recode parent_ba -34/-1=0 0/85=1, gen(parent_t)
    
* time-constant parenthood indicator - ever parent (0=never/1=parenthood ever observed)

bysort pid: egen aux=max(hhkid)

gen parent_ev=0 if aux==0 & country!=2 | yr1brth_us==9999 & country==2
	replace parent_ev=1 if yrkid1<. & parent_ev==.
	lab var parent_ev "Time-constant parenthood indicator"

* labeling and missings

replace parent_t=0 if parent_ev==0
	lab var parent_t "Time-varying parenthood indicator"

* adjust years before/after parenthood for nonparents

sum age
	disp round(`r(mean)')

sum age if parent_ba == 0 & female==1, det      // mean age at first pregnancy women
	replace parent_ba = age - round(`r(mean)') if parent_ev==0 & female==1	

sum age if parent_ba == 0 & female==0, det      // mean age at first pregnancy men
	replace parent_ba = age - round(`r(mean)') if parent_ev==0 & female==0

* categorial time-sensitive parenthood variable = dynamic treatment variable

recode parent_ba      ///
      (-100/-3 = 0 "BY-3a+")   ///
      (-2/-1   = 1 "BY-1/2a")   ///	  
      (0/1     = 2 "BY+1a")   ///	  
      (2/3     = 3 "BY+2/3a")   ///	  	  
      (4/5     = 4 "BY+4/5a")   ///	  	  	  
      (6/9     = 5 "BY+6/9a")   ///	  	  	  	
      (10/90   = 6 "BY+10a+")   ///	  	  	  		  
    , gen(parent_tvc)
replace parent_tvc=0 if parent_ev==0
	lab var parent_tvc "Timepoints of dynamic treatment (Parenthood)"

*------------------------------------------------------------------------------*
* Part D: Harmonized covariates
*------------------------------------------------------------------------------*

*birth cohort(s)

* six cohorts

	recode yborn                    ///
		  (1935/1944 = 1 "1935-1944") ///
		  (1945/1954 = 2 "1945-1954") ///
		  (1955/1964 = 3 "1955-1964") ///
		  (1965/1974 = 4 "1965-1974") ///
		  (1975/1984 = 5 "1975-1984") ///
		  (1985/1997 = 6 "1985-1997") ///
		, gen(bcohort) 
	recode bcohort -1 1882/2007 = .	
		lab var bcohort "Birth cohort"
	
* four cohorts	
	
		recode yborn                   ///
		  (1948/1959 = 1 "1948-1959") ///
		  (1960/1969 = 2 "1960-1969") ///
		  (1970/1979 = 3 "1970-1979") ///
		  (1980/1991 = 4 "1980-1991") ///
		, gen(bcohort4) 
	recode bcohort4 -1 1882/2019 = .
		lab var bcohort4 "Birth cohort (test)"
	
* two cohorts
    
	recode yborn                   ///
		  (1970/1979 = 2 "1970-1979") ///
		  (1980/1991 = 3 "1980-1991") ///
		, gen(bcohort2) 
	recode bcohort2 -1 1882/2007 = .
		lab var bcohort2 "Birth cohort (dichotomous)"

* year dummies

tab wavey, gen(year)

* sex

recode female -3/-1=.
	clonevar sex = female
	recode sex (0=1) (1=2)
		lab def sex 1 "Male" 2 "Female", replace
		lab val sex sex
		lab var sex "Sex"   
	  
* education

rename edu3 edu3_orig
	recode edu3_orig            ///
		(-3 -2 -1 = .) ///
		, gen(edu3)
	
		lab def edu3 1 "Low" 2 "Middle" 2 "High", replace
		lab val edu3 edu3
		lab var edu3 "Education (3 levels)"
			
gen edu2 = edu3
	recode edu2 (2=1) (3=2)
		lab def edu2 1 "Low/Middle" 2 "High", replace
		lab val edu2 edu2
		lab var edu2 "Education (2 levels)"		
	
* family status (at birth)

recode marstat5				///
      (-8 -3 -2 -1 = .)	///
	  , gen(mar)
	 
	 lab def mar 1 "Living with partner" 2 "Single" 3 "Widowed" 4 "Divorced" 5 "Separated", replace
	 lab val mar mar
	 lab var mar "Marital status (5 levels)"
	 
bys pid (country): gen mar_chg = 0 if mar[_n] == mar[_n+1]
	bys pid (country): replace mar_chg = 1 if mar[_n] != [mar[_n+1]]
	
* dynamic of family status before/after birth
	
bys pid (country): gen mar_chg_ba = 1 if mar[_n] == mar[_n+1] & parent_t == 0
	bys pid (country): replace mar_chg_ba = 2 if mar[_n] != [mar[_n+1]] & parent_t == 0
	bys pid (country): replace mar_chg_ba = 3 if mar[_n] == [mar[_n+1]] & parent_t == 1
	bys pid (country): replace mar_chg_ba = 4 if mar[_n] != mar[_n+1] & parent_t == 1
	
	lab def mar_chg_ba 1 "Before birth, no change" 2 "Before birth, change" 3 "After birth, no change" 4 "After birth, change", replace
	lab val mar_chg_ba mar_chg_ba
	lab var mar_chg_ba "Marital status change before/after birth"

* partner status

clonevar relstat_b = mar														// this is NOT status at birth!!!
	recode relstat_b (1=2) (2 3 4 5 = 1)
		lab def relstat_b 1 "No Partner" 2 "Partner"
		lab val relstat_b relstat_b
		lab var relstat_b "Partner (No/Yes)"

	tab relstat_b, gen(relst)
	
* employment status

recode emplst5 (-3 -2 -1=.), gen(empl)
	lab val empl emplst5
	lab var empl "Employment status"
	
* employment level

recode fptime_h (-3 -2 -1=.), gen(fptime)
	lab val fptime fptime
	lab var fptime "Employment level (Full/Part-time)"	
	
* working hours

recode whweek (-3 -2 -1=.)
recode whmonth (-3 -2 -1=.)
recode whyear (-3 -2 -1=.)

	* binary indicator week

	gen whweek_d = .
		replace whweek_d = 0 if whweek == 0
		replace whweek_d = 1 if whweek >0 & whweek != .
		lab def whweek_d 0 "0 hrs" 1 ">0 hrs", replace
		lab val whweek_d whweek_d
		lab var whweek_d "Working hours weekly (binary)"

*------------------------------------------------------------------------------*

save "${pdta}/cpf-pa_prep.dta", replace

/*------------------------------------------------------------------------------
#4 Define samples for analysis
------------------------------------------------------------------------------*/

use "${pdta}/cpf-pa_prep.dta", clear

/*------------------------------------------------------------------------------

Sample A: 
	1. born 1970-1991
	2. observed before first pregnancy
	3. aged 18+ at obs.
    4. not recent samples (PSID, SOEP)
    5. truncate observation period before and after birth to -10 to 20
	
Sample B: no missings

Sample C: at least two pre-birth-year observations

Sample D: at least one pre-birth-year observation

------------------------------------------------------------------------------*/

* A: prep 1 - observed before first/second pregnancy

bysort pid: egen parent_tr=min(parent_ba) if parent_ev==1
	recode parent_tr -24/-1 = 1 0/90 = 0
	replace parent_tr=1 if parent_ev==0

* B: prep 2 - number of missing values in given year

egen miss=rowmiss(phact_act parent_t age sex edu2 relstat_b bcohort2)

* C: prep 3 - number of valid pre-pregnancy observations

bysort pid: egen abc=count(wavey) if parent_t==0 & miss==0 & age>=18
bysort pid: egen nobs=max(abc)
	drop abc

* D: generate variable that identifies Sample A

gen sampleA = bcohort2<.				/// born 1970-1991
			& age>17                   	/// aged 18+
            & (parent_ba>-11 & parent_ba<16 | parent_ev==0) ///
            & parent_tr==1              // obs. before 1st pregnancy				
	replace sampleA=0 if sampid_soep>11 & sampid_soep<. // no recent samples SOEP
	replace sampleA=0 if sampid_psid==2 | sampid_psid==3 | sampid_psid>4 & sampid_psid<. // no recent samples PSID     
        
* E: generate variable that identifies Sample B

gen sampleB = sampleA==1<.        /// 
            & miss==0              // no missing values          
		
* F: generate variable that identifies Sample C

gen sampleC = sampleB==1<.        /// 
            & nobs>1 & nobs<.     // at least two pre-pregnancy obs

* G: generate variable that identifies Sample D

gen sampleD = sampleB==1<.        /// 
            & nobs>0 & nobs<.     // at least one pre-pregnancy obs

* Inspect samples

log using "${text}/pa_sample.log", replace			

bysort female: ta parent_t country if sampleC==1, col

bysort female: ta parent_tvc country if sampleC==1
bysort female: ta parent_tvc country if sampleD==1
         
codebook pid if sampleC==1 & parent_t==1 & country==1 & female==1
codebook pid if sampleC==1 & parent_t==1 & country==1 & female==0          

codebook pid if sampleC==1 & parent_t==1 & country==2 & female==1
codebook pid if sampleC==1 & parent_t==1 & country==2 & female==0

codebook pid if sampleC==1 & parent_t==1 & country==4 & female==1
codebook pid if sampleC==1 & parent_t==1 & country==4 & female==0

codebook pid if sampleC==1 & parent_t==1 & country==5 & female==1
codebook pid if sampleC==1 & parent_t==1 & country==5 & female==0

codebook pid if sampleD==1 & parent_t==1 & country==1 & female==1
codebook pid if sampleD==1 & parent_t==1 & country==1 & female==0          

codebook pid if sampleD==1 & parent_t==1 & country==2 & female==1
codebook pid if sampleD==1 & parent_t==1 & country==2 & female==0

codebook pid if sampleD==1 & parent_t==1 & country==4 & female==1
codebook pid if sampleD==1 & parent_t==1 & country==4 & female==0

codebook pid if sampleD==1 & parent_t==1 & country==5 & female==1
codebook pid if sampleD==1 & parent_t==1 & country==5 & female==0

bysort country: tab wavey phact_act if sampleA==1, m row nofreq
bysort country: tab wavey phact_ctr if sampleA==1, m row nofreq

capture log close

/*------------------------------------------------------------------------------
#5 Inspect data
------------------------------------------------------------------------------*/				  

log using "${text}/pa_inspect.log", replace

* sort data
sort pid wavey

* inspect data
describe                       	// show all variables contained in data
notes                          	// show all notes contained in data
*codebook, problems              // potential problems in dataset
duplicates report pid wavey		// report duplicates
inspect                        	// distributions, #obs , missings

capture log close

/*------------------------------------------------------------------------------
#6 Label & Save
------------------------------------------------------------------------------*/

label data "CPF, andata, physical activity"

datasignature set, reset

save "${pdta}/andata-pa.dta", replace

*==============================================================================*
