/*==============================================================================
File:         	00master-ph-exercise-com.do
Task:         	Sets up and executes analyses
Project:      	Parenthood and physical activity 
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
Run time:		Approximately 10 Min.
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Installs ado files used in the analysis
#2 Stata Settings
#3 Defines globals
#4 Specifies order and task of code files and runs them
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:

------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
#1 Install ado files                                                         
------------------------------------------------------------------------------*/

*ssc install blindschemes, replace // Color scheme for plots
*ssc install estout, replace       // Formatting and exporting tables
*ssc install coefplot, replace     // Formatting and exporting output as plot

/*------------------------------------------------------------------------------
#2 Stata settings
------------------------------------------------------------------------------*/

version 16.1         				// Stata version control
clear all             				// Clear memory
macro drop _all       				// Delete all macros
set linesize 82       				// Result window has room for 82 chars in one line
set more off, perm    				// Prevents pause in results window
set scheme plotplain  				// Sets color scheme for graphs
set maxvar 32767      				// Size of data matrix

/*------------------------------------------------------------------------------
#3 Define globals 
------------------------------------------------------------------------------*/

* project stamp
global ps "exercise-com"

* working directory 

* -> Retrieve c(username) by typing disp "`c(username)'" in command line

if "`c(username)'" == "[YOUR USER NAME]" {
	global wdir "[PATH WHERE REPO IS SAVED]"
}


if "`c(username)'" == "[YOUR USER NAME]" {
	global wdir "[PATH WHERE REPO IS SAVED]\2_rdta"
}

/*------------------------------------------------------------------------------
#4 Create working directories & define globals (physical activity data)
------------------------------------------------------------------------------*/

* create pa folder name

global pa 	"pa"
global pa_fold  $pa

* create pa folder

foreach pa of global pa_fold {
	capture mkdir "${wdir}\3_pdta\\`pa'"
}

* subdirectories

global pdta  "$wdir/3_pdta/pa"      		// processed data
global code  "$wdir/1_scripts/pa"       	// code files
global cbook "$wdir/4_output/var"       	// codebooks
global plot  "$wdir/4_output/fig"       	// figures
global text  "$wdir/4_output/tab"       	// logfiles + tables

/*------------------------------------------------------------------------------
#5 Specify name, task and sequence of code files to run
------------------------------------------------------------------------------*/

/// ------ Project-Do-Files *

do "$code/01cr-hilda-ph-exercise-com.do"    		// Extracts physical activity variables from HILDA
do "$code/02cr-persyr-psid-ph-exercise-com.do"   	// Extracts parenthood variables from PSID
do "$code/03cr-shp-ph-exercise-com.do"    			// Extracts physical activity variables from SHP
do "$code/04cr-soep-ph-exercise-com.do"    			// Extracts physical activity variables from SOEP
do "$code/05cr-andata-ph-exercise-com.do"    		// Combines single country data sets
do "$code/06an-analysis-ph-exercise-com.do"			// Descriptive & regression analysis

/*----------------------------------------------------------------------------*/

*==============================================================================*
