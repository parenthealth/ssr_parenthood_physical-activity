/*==============================================================================
File:           04cr-cpf-soep.do
Task:           Creates soep extract to integrate in CPF file
Project:      	Parenthood & health behaviour
Author(s):      Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Info on how to get the data
#2 Extract vars from different datasets
#3 Merge single datasets
#4 Generate vars and labels
#5 Clean up
#6 Inspect data
#7 Label and save
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:


 
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
#1 Info on how to get and install the data (TO-DO):

	a) Download soep.v36 zipped files from:

	https://melbourneinstitute.unimelb.edu.au/hilda

	b) Place all raw datasets under soep.v36 in 05_SOEP\Data

------------------------------------------------------------------------------*/

version 16.1                            // Stata version control
capture log close                       // Closes log files
scalar starttime = c(current_time)      // Tracks running time

/*------------------------------------------------------------------------------
#2 Extract vars from different datasets
------------------------------------------------------------------------------*/

* ppath

use "${soep_in}\ppathl.dta", clear

	keep 	pid hid syear netto psample 	///
			piyear gebjahr					/// age
			sex
			
	sort  pid syear

	save "${soep_out_work}\gppathl_1.dta", replace
	
* hpath

use hid syear hnetto ///
	using "${soep_in}\hpathl.dta", clear
	
	sort  hid syear

	save "${soep_out_work}\ghpathl_1.dta", replace 	

* pgen

use "${soep_in}\pgen.dta", clear

	keep	pid hid syear					///
			pgisced11 pgisced97 pgcasmin  	/// Educ
			pgmonth 						/// Interview month
			pgfamstd						/// Marital status
			pgtatzeit						///	Working hours per week
			pgstib pglfs pgemplst			//	Employment status
			
	sort  pid syear

	save "${soep_out_work}\gpgen_1.dta", replace
	
* hgen

use "${soep_in}\hgen.dta", clear

	keep hid syear 							///
			hgnuts1_ew							/// Ost-West
			
	sort hid syear
	
	save "${soep_out_work}\ghgen_1.dta", replace

* pequiv

use "${soep_in}\pequiv.dta", clear

	keep	pid hid syear					///
			x11105							/// respondent status
			d11106 d11107					/// children & hh size
			d11109							/// double check education
			e11101							//	working hours per year
			
	sort  pid syear

	save "${soep_out_work}\gpequiv_1.dta", replace
	
* pl

use "${soep_in}\pl.dta", clear

	keep 	pid hid syear					///
			plb0022_h						//
			
	sort pid syear
	
	save "${soep_out_work}\gpl_1.dta", replace  

* biobirth

use "${soep_in}\biobirth.dta", clear

	keep 	hhnr persnr 					///
			sumkids							//
	rename persnr pid
	
	sort  pid

	save "${soep_out_work}\gbiobirth_1.dta", replace  

/*------------------------------------------------------------------------------
#3 Merge single datasets
------------------------------------------------------------------------------*/

use "${soep_out_work}\gppathl_1.dta", 

merge m:1 hid syear using "${soep_out_work}\ghpathl_1.dta" , keep(1 3) nogen

merge 1:1 pid syear using "${soep_out_work}\gpgen_1.dta" 	, keep(1 3) nogen

merge m:1 hid syear using "${soep_out_work}\ghgen_1.dta", keep(1 3) nogen

merge 1:1 pid syear using "${soep_out_work}\gpequiv_1.dta" , keep(1 3) nogen

merge 1:1 pid syear using "${soep_out_work}\gpl_1.dta" , keep(1 3) nogen	
	
merge m:1 pid  		using "${soep_out_work}\gbiobirth_1.dta" , keep(1 3) nogen	

* delete temp files

!del "${soep_out_work}\*.dta"

/*------------------------------------------------------------------------------
#4 Generate vars and labels
------------------------------------------------------------------------------*/

* define common label

lab def yesno 0 "[0] No" 1 "[1] Yes" ///
        -1 "-1 MV general" -2 "-2 Item non-response" ///
        -3 "-3 Does not apply" -8 "-8 Question not asked in survey", replace

*-----------*
* Technical *
*-----------*

* personal identification number (pid)	

lab var pid "Unique identification number"

* interview year

gen intyear=piyear
	replace intyear=syear if intyear<0
	   lab var intyear "Interview year"

* interview year
	
gen intmonth=pgmonth
	recode intmonth (-5=-1)	
    lab var intyear "Interview year"
	
* inerview month

lab var intmonth "Interview month"

* wave identifier

egen wave = group(syear)
	lab var wave "Wave identifier"
	
* year identifier	
	
gen wavey=syear
	lab var wavey "Year identifier"

* country identifier
	
gen country=5
	lab var country "Country"

* respondent status

recode x11105 (0=3), gen(respstat)
	lab def respstat 	1 "Interviewed" 					///
						2 "Not interviewed (has values)" 	///
						3 "Not interviewed (no values)"
	lab val respstat respstat
	lab var respstat "Respondent status"

* 1st appearance in dataset

bysort pid: egen wave1st = min(cond(respstat == 1, wave, .))
	label var wave1st "1st appearence in dataset"
	
* sample identifier

clonevar sampid_soep = psample
	lab val sampid_soep psample
	lab var sampid_soep "Sample identifier: SOEP"
	
* sort	
	
sort pid wave
	
*----------------------------------------*
* Sociodemographics & Family composition *
*----------------------------------------*

* age

gen age=piyear - gebjahr if gebjahr>100 & piyear>100
recode age (.=-1)
	lab var age "Age"

* birth year

clonevar yborn=gebjahr
	lab var yborn "Birth year"

* gender

recode sex (1=0) (2=1), gen(female)
	lab def female 0 "Male" 1 "Female" 
	lab val female female 
	lab var female "Gender"
	
* region (east-west)

recode hgnuts1_ew (21=0) (22=1), gen(region)
	lab def region 0 "Western Germany" 1 "Eastern Germany"
	lab val region region
	lab var region "Western-/Eastern Germany"
	
* education

	* education (3 levels)
	
	recode pgisced11 (0/2=1) (3 4=2) (5/8=3) , gen(edu3a)
	recode pgisced97 (0/2=1) (3 4=2) (5/6=3) , gen(edu3b)
	replace edu3b = 2 if intyear <2010 & pgisced97>=5 & pgcasmin==3 & d11109<12 & d11109>0
	gen edu3=edu3a
	replace edu3=edu3b if intyear <2010
	replace edu3=edu3b if intyear >=2010 & (edu3<0|edu3==.)

	drop edu3a edu3b
	
	lab def edu3  1 "[0-2] Low" 2 "[3-4] Medium" 3 "[5-8] High" // 2 incl Vocational
	lab val edu3 edu3
	lab var edu3 "Education: 3 levels"
	
	* education (4 levels)
	
	recode pgisced11 (0 1=1) (2=2) (3 4=3) (5/8=4) , gen(edu4a)
	recode pgisced97 (0 1=1) (2=2) (3 4=3) (5 6=4) , gen(edu4b)
	replace edu4b = 3 if intyear <2010 & pgisced97>=5 & pgcasmin==3 & d11109<12 & d11109>0
	gen edu4=edu4a
	replace edu4=edu4b if intyear <2010
	replace edu4=edu4b if intyear >=2010 & (edu4<0|edu4==.)

	drop edu4a edu4b
		
	lab def edu4  1 "[0-1] Primary" 2 "[2] Secondary lower" ///
				  3 "[3-4] Secondary upper" 4 "[5-8] Tertiary" 
	lab val edu4 edu4
	lab var edu4 "Education: 4 levels"
	
	* education (5 levels)
	
	recode pgisced11 (0 1=1) (2=2) (3 4=3) (5 6=4) (7 8=5) , gen(edu5a)
	recode pgisced97 (0 1=1) (2=2) (3 4=3) (5=4) (6=5) , gen(edu5b)
	replace edu5b = 3 if intyear <2010 & pgisced97>=5 & pgcasmin==3 & d11109<12 & d11109>0
	replace edu5b = 4  if intyear <2010 & pgisced97==6 & pgcasmin==8   
	replace edu5b = 5  if intyear <2010 & pgisced97==6 & pgcasmin==9   
	gen edu5=edu5a
	replace edu5=edu5b if intyear <2010
	replace edu5=edu5b if intyear >=2010 & (edu5<0|edu5==.)

	drop edu5a edu5b
		
	lab def edu5  1 "[0-1] Primary" 2 "[2] Secondary lower" ///
				  3 "[3-4] Secondary upper" ///
				  4 "[5-6] Tertiary lower(bachelore)"  ///
				  5 "[7-8] Tertiary upper (master/doctoral)"
				  
	lab val edu5 edu5
	lab var edu5 "Education: 5 levels"
	
	* educational years

	gen eduy=d11109		

	recode eduy (.=-1) (-2=-1)
	lab var eduy "Education: years"

* primary martial status

recode pgfamstd (1 7=1)(2 6 8=5)(3=2)(4=4)(5=3)	///
				(-1=-2) (-3=-1) (-5=-8), gen(marstat5)

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

clonevar kidsn_all= sumkids
clonevar kidsn_hh17= d11107

recode kidsn_all (1/50=1) (0=0), gen(kids_any)
 	
	lab var kids_any  "Has any children"
	lab val kids_any   yesno
	lab var kidsn_all  "Number Of Children Ever Had" 
 	lab var kidsn_hh17   "Number of Children in HH aged 0-17"
	
* household size

clonevar nphh= d11106
	lab var nphh   "Number of People in HH"
	
* employment status

	* create zeros (obs with any type of information)
	recode  plb0022_h (1/11=0) (-5/-1=-1), gen (emplst5)
	replace emplst5=0 if pgstib>=10 & pgstib<.
	replace emplst5=0 if pglfs>=1 & pglfs<.
	* create MV(-1) with no information 
	replace emplst5=-1 if   (plb0022_h<0 | plb0022_h==.) & (pgstib<=0 | pgstib==.) & (pglfs<0 | pglfs==.)

	* Categories 
	replace emplst5=4 if  plb0022_h==5 | plb0022_h==6| plb0022_h==7 | plb0022_h==9 | plb0022_h==11 
	replace emplst5=4 if  (pglfs>=1 & pglfs<=10)
	replace emplst5=4 if pgstib>=10 & pgstib<=13

	replace emplst5=3 if pgstib==13 | pglfs ==2 // Pensioner or NW-age 65 and older

	replace emplst5=5 if pgstib==11 | pglfs==3

	replace emplst5=2 if pgstib==12 | pglfs==6 

	replace emplst5=1 if (plb0022_h>=1 & plb0022_h<=4) | plb0022_h==8 | plb0022_h==10
	replace emplst5=1 if pglfs==11 | (pglfs==12 & pgstib!=13)

		lab def emplst5	///
				1 "Employed" 			/// including leaves
				2 "Unemployed (active)"	///
				3 "Retired, disabled"	///
				4 "Not active/home"		///   
				5 "In education"		///
				-1 "MV"
		lab val emplst5 emplst5
		lab var emplst5 "Employment status [5]"
	
* working hours

clonevar whweek=pgtatzeit 
clonevar whyear=e11101  

gen whmonth=whweek*4.3
replace whmonth=whweek if whweek <0
	lab var whweek "Work hours per week: worked"
	lab var whmonth "Work hours per month: worked"
	lab var whyear "Work hours per year: worked"
 
* Fill MV based on whyear (imputed by CNEF)

replace whmonth=whyear/12 if (whmonth==.|whmonth<0) & whyear>0 & whyear<.
replace whweek=whyear/(12*4.3) if (whweek==.|whweek<0) & whyear>0 & whyear<.

* full/part-time

recode plb0022_h (1=1) (2 4=2) (3 5/11=3) (-5 .=-1), gen(fptime_r)

gen fptime_h=.
replace fptime_h=1 if whweek>=35 & whweek<.
replace fptime_h=2 if whweek<35 & whweek>0
replace fptime_h=3 if whweek==0
replace fptime_h=3 if emplst5>1 & emplst5<.
replace fptime_h=whweek if whweek<0 & fptime_h==.
	lab def fptime_r 1 "Full-time" 2 "Part-time/irregular" 3 "Not empl/other"
	lab val fptime_r fptime_h fptime
	lab var fptime_r "Employment Level (self-report)"
	lab var fptime_h "Employment Level (based on hours)"

/*------------------------------------------------------------------------------
#5 Clean up and save
------------------------------------------------------------------------------*/	

* keep
	
keep	///
	pid intyear intmonth wave wavey country wave1st respstat sampid_soep ///
	age sex female yborn region eduy edu3 edu4 edu5 marstat5 ///
	kidsn_all kids_any kidsn_hh17 nphh whweek whmonth whyear emplst5 fptime_h fptime_r
	 
* order

order ///
	pid intyear intmonth wave wavey country wave1st respstat sampid_soep ///
	age female yborn region eduy edu3 edu4 edu5 marstat5 ///
	kidsn_all kids_any kidsn_hh17 nphh whweek whmonth whyear emplst5 fptime_h fptime_r
  
* sample selection
	
	* age
	
	keep if age>=18
	
	* MV in age and gender
	
	keep if female~=.
	keep if age~=.
	
/*------------------------------------------------------------------------------
#6 Inspect data
------------------------------------------------------------------------------*/				  

log using "${logs}/04soep_inspect$ps.log", replace

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
#7 Label & Save
------------------------------------------------------------------------------*/	

* label data
 
label data "CPF_DE, parenthood"
    datasignature set, reset
		
* save

save "${soep_out}\soep$ps.dta" , replace
		
*------------------------------------------------------------------------------*

* display running time

scalar endtime = c(current_time)

display ((round(clock(endtime, "hms") - clock(starttime, "hms"))) / 60000) " minutes"

*==============================================================================*
