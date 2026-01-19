/*==============================================================================
File:         	00cr-cpf-master.do
Task:         	Master do-file for creating a dataset with harmonized variables
				from HILDA, PSID, SHP, SOEP
Project:      	Parenthood & health behaviour
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
Run time:		Approximately 20 min.
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Install needed ado files
#2 Stata Settings
#3 Create working directories & define globals (raw data)
#4 !!! IMPORTANT !!! Insert raw data
#5 Create working directories & define globals (cpf data)
#6 Run country specific do-files, append & label dataset
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes: 

IMPORTANT - RUN DO-FILE TILL STEP #4, THEN INSERT RAW DATA, THEN PROCEED WITH STEP #5

------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
#1 Install needed ado files                                                         
------------------------------------------------------------------------------*/

* blindschemes (additional blind & colorblind optimized schemes for plots)

cap which blindschmes
	if _rc ssc install blindschemes, replace

* estout (formatting and exporting tables)

cap which blindschmes
	if _rc ssc install estout, replace

* coefplot (formatting and exporting output as plots)

cap which blindschmes
	if _rc ssc install coefplot, replace

* isvar, iscogen & psditools (needed to create harmonized file)

foreach ado in isvar iscogen psidtools  {
	cap which `ado'
	if _rc ssc install `ado', replace
}

* renvars (renames variables in varlist instead of single rename)

cap which renvars
	if _rc net install http://www.stata-journal.com/software/sj5-4/dm88_1

	
* svmat (creates matrix from variables)

cap which svmat2
	if _rc	net install  http://www.stata.com/stb/stb56/dm79

/*------------------------------------------------------------------------------
#2 Stata settings
------------------------------------------------------------------------------*/

version 16.1          				// Stata version control
clear all             				// clear memory
macro drop _all       				// delete all macros
set linesize 82       				// result window has room for 82 chars in one line
set more off, perm    				// prevents pause in results window
set scheme plotplain  				// sets color scheme for graphs
set maxvar 32767      				// size of data matrix
scalar starttime = c(current_time)	// Tracks running time

/*------------------------------------------------------------------------------
#3 Create working directories & define globals (raw data)
------------------------------------------------------------------------------*/

* project stamp

global ps "-cpf-data"

* working directory 

* -> Retrieve c(username) by typing disp "`c(username)'" in command line
* -> Set global wdir as path, where repo is saved

if "`c(username)'" == "[YOUR USER NAME]" {
	global wdir "[PATH WHERE REPO IS SAVED]"
}

* create survey-specific folder names for raw data

global hilda 	"01_HILDA"
global psid 	"02_PSID"
global shp		"03_SHP"
global soep		"04_SOEP"
global surv_fold  $hilda $psid $shp $soep

* create survey-specific folders for raw data

foreach surv of global surv_fold {
	capture mkdir "${wdir}\2_rdta\\`surv'"
}

* create survey-specific subfolders for raw data

*HILDA*

	* create folder names

	global Fhilda_combined "STATA 190c (Combined)"
	global Fhilda_other "STATA 190c (Other)"
	
	* create path globals
	
	global Ghilda_combined "${wdir}\2_rdta\01_HILDA\\${Fhilda_combined}"
	global Ghilda_other "${wdir}\2_rdta\01_HILDA\\${Fhilda_other}"
	
	* create folders

	capture mkdir "${Ghilda_combined}"
	capture mkdir "${Ghilda_other}"
	
*PSID*

	* create folder names

	global Fpsid_cross "Cross-year Individual 1968-2019"
	global Fpsid_family "Family and Ind Files (zip)"
	global Fpsid_tools "PSIDtools_files"
	
	* create path globals
	
	global Gpsid_cross "${wdir}\2_rdta\02_PSID\\${Fpsid_cross}"
	global Gpsid_family "${wdir}\2_rdta\02_PSID\\${Fpsid_family}"
	global Gpsid_tools "${wdir}\2_rdta\02_PSID\\${Fpsid_tools}"
	
	* create folders

	capture mkdir "${Gpsid_cross}"
	capture mkdir "${Gpsid_cross}\pack"
	capture mkdir "${Gpsid_family}"
	capture mkdir "${Gpsid_tools}"

********************************************************************************
disp "!!! STOP HERE AND INSERT RAW DATA FILES !!!"
********************************************************************************

/*------------------------------------------------------------------------------
#4 !!! IMPORTANT !!! Insert raw data
------------------------------------------------------------------------------*/

/*
To run the do-files from here properly, you need to insert the raw datasets 
BEFORE continuing with #5. Insert the raw data as follows:

*HILDA* 
	
	Apply for the data via the National Centre for Longitudinal 
	Data Dataverse (Australian Government Department of Social Services): 
	
	https://dataverse.ada.edu.au/dataverse/ncld. 
	
	Unpack downloaded files, 
	such as STATA 190c (1-Combined Data Files) and STATA 190c 
	(2-Other Data Files), to subfolders indicated as “Combined” and “Other” 
	in the “Data” folder. The final structure should look as follows:
	
	2_rdta\01_HILDA\STATA 190c (Combined)\[the data] &
	2_rdta\01_HILDA\STATA 190c (Other)\[the data]

*PSID*
	
	The logic behind PSID differs from other datasets and is much more complex
	(see Survey-specific details for PSID). To organise the data, we use the 
	psidtools ado (Kohler, 2015), which can be downloaded using:
	
	ssc install psidtools

	Data are available via the official website for registered users: 
	
	https://simba.isr.umich.edu/Zips/ZipMain.aspx
	
		1. Download all Family Files (one per wave, e.g. fam2019er.zip) 
		and place them in into Family and Ind Files (zip). Do not unpack.
		2. Download Cross-year Individual: 1968-2019 zipped file and place it 
		in Family and Ind Files (zip). Do not unpack.
		3. Leave all files in the Family and Ind Files (zip) folder unpacked but
		additionally unpack the Cross-year Individual: 1968-2019 zipped file 
		(ind2019er.zip) to Data/Cross-year/Individual 1968-2019/pack. 
		It should contain a txt file with vales named, e.g. IND2019ER.txt 
		(which is defined in as global psid_ind_er 
		“${psid_in}\pack\IND${psid_w}ER.txt” based on the latest PSID year 
		indicated in 2 as global psid_w).
	
*SHP*
	
Data are available via FORSbase for registered users: 
https://forscenter.ch/projects/swiss-household-panel/data. 
Unpack all folders from Data_STATA.zip into the main Data folder. 
It should then contain several folders with different types of datasets. 
The main source of the individual- and household-level data are files in 
SHP-Data-W1-W21-STATA folder (e.g. shp99_p_user.dta). Additionally, 
CPF refers to other folders, including SHP-Data-CNEF-STATA and SHP-Data-WA-STATA.	
	
*SOEP*
	
Data are available via the Research Data Center SOEP after granting access: 
www.diw.de/en/diw_02.c.242211.en/criteria_fdz_soep.html
Data should be unpacked into Data keeping additionally the wave-specific 
subfolder (e.g. soep.v35), which contains then all the SOEP files.	

*/

/*------------------------------------------------------------------------------
#5 Create working directories & define globals (cpf data)
------------------------------------------------------------------------------*/

* create cpf folder name

global cpf 	"cpf"
global cpf_fold  $cpf

* create cpf folder

foreach cpf of global cpf_fold {
	capture mkdir "${wdir}\3_pdta\\`cpf'"
}

* create cpf output folder names

global Fcpf_out "01cpf-out" 	// 	name processed data folder
global Flog 	"02cpf-log"	//	name log folder
	
* create cpf output folder paths
 
global Gcpf_out 	"${wdir}\3_pdta\cpf\\${Fcpf_out}"  	// create processed data folder	
global Gcpf_log 	"${wdir}\3_pdta\cpf\\${Flog}" 		// name log folder
	
* create cpf output folders

capture mkdir   "${Gcpf_out}"	
capture mkdir   "${Gcpf_log}"

* create survey-specific subfolder names for cpf

global hilda_cpf 	"01_HILDA_cpf"
global psid_cpf 	"02_PSID_cpf"
global shp_cpf		"03_SHP_cpf"
global soep_cpf		"04_SOEP_cpf"
global surv_fold_cpf  $hilda_cpf $psid_cpf $shp_cpf $soep_cpf

* create survey specific subfolder for cpf temp data

foreach surv of global surv_fold_cpf {
	capture mkdir "${Gcpf_out}\\`surv'"
	capture mkdir "${Gcpf_out}\\`surv'\temp"  	//working files
}

capture mkdir "${Gcpf_out}\03_SHP_cpf\temp\CNEF"

* define global working macros

	* global for path to syntax files

	global cpf_in 	"${wdir}\1_scripts\cpf\"
	global logs		"${wdir}\3_pdta\cpf\02cpf-log"
	
	* globals identifying last wave in surveys

	global surveys "hilda psid shp soep"
	global hilda_w 		"19"		// version of HILDA, number of waves
	global psid_w		"2019"		// latest year of PSID
	global shp_w 		"21"		// number of waves  
	global soep_w 		"36"		// version and number of waves  
	
* define survey specific input and output macros

	* input folders
	
		* HILDA
		
		global hilda_in 		"${wdir}\2_rdta\\${hilda}"

		* PSID
		
		global psid_in 			"${wdir}\2_rdta\\\${psid}\Cross-year Individual 1968-${psid_w}" 	 
		global psid_downl   	"${wdir}\2_rdta\\\${psid}\Family and Ind Files (zip)"
		global psidtools_in		"${wdir}\2_rdta\\\${psid}\PSIDtools_files"
		global psid_org 		"${psid_in}\psid_crossy_ind.dta"
		global psid_syntax 		"${wdir}\\${psid}\"											// PSID syntax
		global psid_ind_er_name	"IND${psid_w}ER.txt" 										// PSID "Cross-year Individual 1968-XXXX" file
		global psid_ind_er 		"${psid_in}\pack\\${psid_ind_er_name}" 				// PSID "Cross-year Individual 1968-XXXX" file
			
		* SHP
		
		global shp_in 			"${wdir}\2_rdta\\\${shp}" 		 
		global shp_in_cnef 		"${shp_in}\SHP-Data-CNEF-STATA" 		

		* SOEP
		
		global soep_in 			"${wdir}\2_rdta\\${soep}\soep.v${soep_w}" 	 

	* output folders
	
		* for CPF-country data
		
		foreach surv in hilda psid shp soep {
			global `surv'_out "${Gcpf_out}\\${`surv'}_cpf"		 
			global `surv'_out_work "${`surv'_out}\temp"
		}
	
		* additional for SHP-CNEF
		
		global shp_out_work_cnef "${shp_out_work}\CNEF"

/*------------------------------------------------------------------------------
#6 Run country specific do-files, append & label dataset
------------------------------------------------------------------------------*/

/// ------ Project-Do-Files *

do "$cpf_in/01cr-cpf-hilda.do"   // Creates hilda extract to integrate in CPF file
do "$cpf_in/02cr-cpf-psid.do"    // Creates psid extract to integrate in CPF file
do "$cpf_in/03cr-cpf-shp.do"   	// Creates shp extract to integrate in CPF file
do "$cpf_in/04cr-cpf-soep.do"   // Creates soep extract to integrate in CPF file
do "$cpf_in/05cr-cpf-andata.do"	// Appends all countries and labels data

*==============================================================================*

* display running time

scalar endtime = c(current_time)

display ((round(clock(endtime, "hms") - clock(starttime, "hms"))) / 60000) " minutes"

*==============================================================================*
