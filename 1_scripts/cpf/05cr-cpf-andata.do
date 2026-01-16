/*==============================================================================
File:         	05cr-cpf-andata$ps.doa.do
Task:         	Creates & labels the harmonized dataset
Project:      	Parenthood & health behaviour
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Append all surveys
#2 Labels
#3 Inspect data
#4 Save
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:

------------------------------------------------------------------------------*/

version 16.1  						// Stata version control
capture log close					// Closes log files
scalar starttime = c(current_time)	// Tracks running time

/*------------------------------------------------------------------------------
#1 Append all surveys
------------------------------------------------------------------------------*/

clear
local data= "$surveys"	// hilda psid shp soep
	foreach data in `data' {
		append	using "${`data'_out}\\`data'$ps.dta"	 
	}

* keep

isvar  	///		
	pid wave wavey intyear intmonth country respstat sampid* wave1st href ///
	age region yborn female eduy edu3 edu4 edu5 ///
	marstat5 nphh whweek whmonth whyear emplst5 fptime_h fptime_r ///
	kidsn_hh17 kidsn_hh15 kidsn_all kids_any nkids_dv ///
	panl-ndrinkhmd
		
keep `r(varlist)'		

* add pid-prefix for the country		

rename pid orgpid

	tostring orgpid, gen(pid_temp)
	generate str pid = ""

	tokenize "10 20 30 40 50 60" 
		foreach c of num 1/6	{
			replace pid="`1'"+pid_temp if country==`c'
		macro shift 1  
		}
	destring pid, replace
	format pid  %14.0g

drop pid_temp

* order

order country orgpid pid wave wavey intyear intmonth respstat ///
		female age yborn edu* marstat5 whweek whmonth whyear emplst5 fptime_h fptime_r ///
		kidsn_hh17 kidsn_all kids_any nphh ///
		sampid*	
		
/*------------------------------------------------------------------------------
#2 Labels
------------------------------------------------------------------------------*/

* label vars

lab var country "Country"
lab var orgpid "Personal id from original dataset"
lab var pid "CPF personal id number"
lab var wave "Wave nr"
lab var wavey "Wave - main year of data collection"

lab var intyear "Year of interview"
lab var intmonth "Month of interview"
lab var female "Gender (female)"
lab var age "Age"
lab var yborn "Birth year"
lab var edu3 "Education: 3 levels"
lab var edu4 "Education: 4 levels"
lab var edu5 "Education: 5 levels"
lab var eduy "Education: years"
lab var marstat5 "Primary partnership status"
lab var whweek "Working hours: Week"
lab var whmonth "Working hours: Month"
lab var whyear "Working hours: Year"
lab var emplst5 "Employment status [5]"
lab var fptime_h "Employment Level (based on hours)"
lab var fptime_r "Employment Level (self-report)"

lab var kidsn_hh17 "Number Of Children in HH aged 0-17"
lab var kidsn_all "Number Of Children Ever Had"
lab var kids_any "Has own children"

lab var nphh "Number of People in HH"

* def value labels 

lab def yesno 		0 "[0] No" 1 "[1] Yes" ///
					-1 "[-1] MV gen" -2 "[-2] Item nresp" ///
					-3 "[-3] Not apply" -8 "[-8] Not asked ", replace
	
lab def country 	1 "[1] Australia" 2 "[2] USA" 3 "[3] Russia" ///
					4 "[4] Switzerland" 5 "[5] Germany" 6 "[6] UK" , replace

lab def respstat 	1 "Interviewed" 					///
					2 "Not interviewed (has values)" 	///
					3 "Not interviewed (no values)", replace
					
lab def female 		0 "Male" 1 "Female" , replace

lab def edu3  		1 "[0-2] Low" 2 "[3-4] Medium" 3 "[5-8] High"  , replace
lab def edu4  		1 "[0-1] Primary" 2 "[2] Secondary lower" ///
					3 "[3-4] Secondary upper" 4 "[5-8] Tertiary" , replace
lab def edu5  		1 "[0-1] Primary" 2 "[2] Secondary lower" ///
					3 "[3-4] Secondary upper" ///
					4 "[5-6] Tertiary lower(bachelor)"  ///
					5 "[7-8] Tertiary upper (master/doctoral)", replace
lab def marstat5				///
					1	"Married or Living with partner"	///
					2	"Single" 				///
					3	"Widowed" 				///
					4	"Divorced" 				///
					5	"Separated" 			///
					-1 "[-1] MV gen" -2 "[-2] Item nresp" ///
					-3 "[-3] Not apply" -8 "[-8] Not asked "	, replace
					
lab def emplst5	///
					1 "Employed" 			///
					2 "Unemployed (active)"	///
					3 "Retired, disabled"	///
					4 "Not active/home"		///  
					5 "In education"		///
					-1 "MV"					///
					-2 "Item nresp"			///
					-3 "Not apply"			///
					, replace
					
lab def fptime ///
					1 "Full-time" 			///
					2 "Part-time/irregular" ///
					3 "Not empl/other" 		///
					-1 "MV"					///
					-2 "Item nresp"			///
					-3 "Not apply"			///
					, replace
					
lab def wh ///
					-1 "MV"					///
					-2 "Item nresp"			///
					-3 "Not apply"			///
					, replace					
		
* apply value labels
		
lab val country country

lab val female yesno
lab val edu3
lab val edu4
lab val edu5 edu5
lab val marstat5 marstat5
lab val emplst5 emplst5
lab val fptime_h fptime_r fptime
lab val whweek whmonth whyear wh

lab val kids_any yesno

/*------------------------------------------------------------------------------
#3 Inspect data
------------------------------------------------------------------------------*/				  

log using "${logs}/05cpf_inspect$ps.log", replace

* sort data

sort pid wavey

* inspect data

describe                       	// show all variables contained in data
notes                          	// show all notes contained in data
*codebook, problems             	// potential problems in dataset
duplicates report pid wavey		// report duplicates
inspect                        	// distributions, #obs , missings

capture log close

/*------------------------------------------------------------------------------
#4 Save
------------------------------------------------------------------------------*/

* label data

label data "CPF (physical activity, parenthood)"
	datasignature set, reset

save "${Gcpf_out}\CPF-pa.dta", replace

*------------------------------------------------------------------------------*

* display running time

scalar endtime = c(current_time)

display ((round(clock(endtime, "hms") - clock(starttime, "hms"))) / 60000) " minutes"

*==============================================================================*
