/*==============================================================================
File name:		06an-analysis-ph-exercise-com.do
Task:			Creates descriptive analyses of parenthood on physical activity
Project:		Parenthood and physical activity 
Author(s):		Linden & Kühhirt
Last update:  	2026-01-14
==============================================================================*/

/*------------------------------------------------------------------------------ 
Content:

#1 Sample descriptives
#2 Regression models for main analyses for pa variables over four countries
#3 Figures & Tables for time-varying-effects
#4 Regression models and figures for education-specific analyses

------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Notes:
------------------------------------------------------------------------------*/
clear all
version 16.1  						// Stata version control
capture log close					// Closes log files

/*------------------------------------------------------------------------------
#1 Sample descriptives
------------------------------------------------------------------------------*/

clear all
use "${pdta}/andata-pa.dta"

* run analysis only for sampleC (at least two pre-pregnancy observations)

drop if sampleC==0

xtset pid syear
sort country pid

* define globals

global av "phact_act"

*------------------------------------------------------------------------------*

* Table 1 - Person-years descriptives

	* N of observed women and men

	bys country sex: xtdescribe, pattern(1)

	* observational period

	tab syear country

	* observational years women and men

	tab sex country

	* transitions to motherhood/fatherhood

	tab sex country if parent_ba == 0 & parent_ev == 1
	
	* mean age at time of transition to parenthood

	gen transition_age = age if parent_ba == 0 & parent_ev == 1

	preserve
	collapse (mean) transition_age (sd) sd_transition_age=transition_age (count) n=transition_age, by(country sex)
	format transition_age sd_transition_age %9.2f
	list country sex transition_age sd_transition_age n, clean
	restore

* Appendix Table A1: Physical activity quotas over time

foreach c in _au _us _ch _ge {

	if "`c'"=="_au" {
		local cc = "AU"
	}

	if "`c'"=="_us" {
		local cc = "US"
	}
	
	if "`c'"=="_ch" {
		local cc = "CH"
	}

	if "`c'"=="_ge" {
		local cc = "DE"
	}
	
	tab $av`c' syear if sampleC==1 & sex==1 & parent_ev==1, col
	tab $av`c' syear if sampleC==1 & sex==2 & parent_ev==1, col
}

* Table 3 - Sample descriptives

	* Overall
	summtab2, vars(phact_act age edu2 relstat bcohort2 syear) type(2 1 2 2 2 2) ///
			by(country) mean median range total medfmt(2) mnfmt(2) catfmt(2) pmiss catmisstype("missperc") ///
			word wordname("${text}/table3.docx") ///
			title(Descriptive overview for the project: Parenthealth - Physical activity - Overall) replace
			
	* Summtab für Women
	summtab2 if sex == 2, vars(phact_act age edu2 relstat bcohort2 syear) type(2 1 2 2 2 2) ///
			by(country) mean median range total medfmt(2) mnfmt(2) catfmt(2) pmiss catmisstype("missperc") ///
			word wordname("${text}/table3.docx") ///
			title(Descriptive overview for the project: Parenthealth - Physical activity - Women) append		
    
	* Summtab für Men
	summtab2 if sex == 1, vars(phact_act age edu2 relstat bcohort2 syear) type(2 1 2 2 2 2) ///
			by(country) mean median range total medfmt(2) mnfmt(2) catfmt(2) pmiss catmisstype("missperc") ///
			word wordname("${text}/table3.docx") ///
			title(Descriptive overview for the project: Parenthealth - Physical activity - Men) append
		
/*------------------------------------------------------------------------------
#2 Regression models for main analyses for pa variables over four countries
------------------------------------------------------------------------------*/

* define globals

global av "phact_act"
global covars "age i.edu2 i.relstat_b i.syear i.bcohort2"

* generate containers for estimates, lower & higher CI boundaries
	 
foreach c in _au _us _ch _ge {
    
	if "`c'"=="_au" {
		local cc = "AU"
	}

	if "`c'"=="_us" {
		local cc = "US"
	}

	if "`c'"=="_ch" {
		local cc = "CH"
	}

	if "`c'"=="_ge" {
		local cc = "DE"
	}
	
		foreach s in 1 2 {
			for any estgd`s'`c' estdd`s'`c' estdt`s'`c' ///
					logd`s'`c' lodd`s'`c' lodt`s'`c'    ///
					higd`s'`c' hidd`s'`c' hidt`s'`c': gen X=.
					
		* estimate models:
					
		local m=1
		foreach x in parent_t i.parent_tvc {
			reg $av`c' `x' $covars if sex==`s' & sampleC==1, cluster(pid)
			est store MPOLS`m'`s'`c'

				forval n=1/6 {
					capture replace estgd`s'`c'=_b[`n'.parent_tvc] if _n==`n' & `m'==2
					capture replace logd`s'`c'=estgd`s'`c'-1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
					capture replace higd`s'`c'=estgd`s'`c'+1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
				}

			reg $av`c' `x' parent_ev $covars if sex==`s' & sampleC==1, cluster(pid)
			est store MDID`m'`s'`c'
		
				forval n=1/6 {
					capture replace estdd`s'`c'=_b[`n'.parent_tvc] if _n==`n' & `m'==2
					capture replace lodd`s'`c'=estdd`s'`c'-1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
					capture replace hidd`s'`c'=estdd`s'`c'+1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
				}

			reg $av`c' `x' i.parent_ev##c.$covars if sex==`s' & sampleC==1, cluster(pid)
			est store MDIT`m'`s'`c'
			
				forval n=1/6 {
					capture replace estdt`s'`c'=_b[`n'.parent_tvc] if _n==`n' & `m'==2
					capture replace lodt`s'`c'=estdt`s'`c'-1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
					capture replace hidt`s'`c'=estdt`s'`c'+1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
				}

		local m=`m'+1	  
		}
	}	
}

*------------------------------------------------------------------------------*

log using "${text}/pa_model.log", replace

* dif-tables for women

estout MDIT12_au MDIT12_us MDIT12_ch MDIT12_ge, ///
	keep(parent_t) ///
	cells(b(star fmt(3)) se(par)) ///
	mlabels("AU" "US" "CH" "GE") ///
	modelwidth(8) posthead("{bf:pa_dit_tv_fem}") ///
	stats(N N_clust, fmt(%9.0g) labels(Obs Obs_Cluster)) ///
	eq(1) legend label varlabels(_cons Constant) replace
	
estout MDIT22_au MDIT22_us MDIT22_ch MDIT22_ge, ///
	keep(*.parent_tvc) ///
	cells(b(star fmt(3)) se(par)) ///
	mlabels("AU" "US" "CH" "GE") ///
	modelwidth(8) posthead("{bf:pa_dit_ts_fem}") ///
	stats(N N_clust, fmt(%9.0g) labels(Obs Obs_Cluster)) ///
	eq(1) legend label varlabels(_cons Constant) replace

* dif-tables for men	
	
estout MDIT11_au MDIT11_us MDIT11_ch MDIT11_ge, ///
	keep(parent_t) ///
	cells(b(star fmt(3)) se(par)) ///
	mlabels("AU" "US" "CH" "GE") ///
	modelwidth(8) posthead("{bf:pa_dit_tv_mal}") ///
	stats(N N_clust, fmt(%9.0g) labels(Obs Obs_Cluster)) ///
	eq(1) legend label varlabels(_cons Constant) replace
	
estout MDIT21_au MDIT21_us MDIT21_ch MDIT21_ge, ///
	keep(*.parent_tvc) ///
	cells(b(star fmt(3)) se(par)) ///
	mlabels("AU" "US" "CH" "GE") ///
	modelwidth(8) posthead("{bf:pa_dit_ts_mal}") ///
	stats(N N_clust, fmt(%9.0g) labels(Obs Obs_Cluster)) ///
	eq(1) legend label varlabels(_cons Constant) replace

/*------------------------------------------------------------------------------
#3 Figures & Tables for time-varying-effects
------------------------------------------------------------------------------*/

* Figure 2: Difference in the proportion of weekly physical activity

gen model=_n if _n<7
label val model parent_tvc

foreach c in _au _us _ch _ge {	  
    
    if "`c'"=="_au" {
        local cc = "AU"
    }

    if "`c'"=="_us" {
        local cc = "US"
    }
    
    if "`c'"=="_ch" {
        local cc = "CH"
    }    
    
    if "`c'"=="_ge" {
        local cc = "DE"
    }    

	* GT models for both genders

	twoway (rspike lodt2`c' hidt2`c' model, color(black%30) lw(vvthick)) ///	   
		   (rspike lodt1`c' hidt1`c' model, color(black%30) lw(vvthick)) ///
		   (connected estdt2`c' model, ms(O) mc(black) lc(black) mfc(white) msize(large) lp(dash)) ///
		   (connected estdt1`c' model, ms(O) mc(black) lc(black) mfc(gray) msize(large) lp(dash))  ///
		 , legend(order(3 4) label(3 "Women") label(4 "Men") ring(0) bplace(11) fc(none)) ///
		   xtitle("Timepoints", size(4)) ytitle("Difference in the proportion of weekly physical activity", size(4)) ///
		   xlabel(1(1)6, val labsiz(3) angle(45) nogrid) ylabel(-.4(.2).2, labsiz(3) nogrid format(%2.1f)) ///
		   xline(2.5 3.5, lcolor(white) lw(vthin) lp(solid)) ///
		   xline(1(1)8, lcolor(white) lw(thin) lp(solid)) ///
		   xline(1.5 4.5 5.5 6.5 7.5, lcolor(white) lw(vthin) lp(solid)) ///
		   yline(-.4 -.3 -.2 -.1 .1 .2, lcolor(white) lw(thin) lp(solid)) ///
		   yline(0, lcolor(gs10) lw(thin)) ///
		   xline(1.5, lc(gs0) lw(thin)) ///
		   title("`cc'", size(4)) ///
		   plotregion(lcolor(gs0) fc(gs14) margin(medium) lw(medthick)) xsize(4) ysize(3.7) name(fig2_tr_gt`c', replace)
	graph export "${plot}/fig2_tr_gt`c'.emf", replace

}

* combined

	grc1leg2 ///
		fig2_tr_gt_au ///
		fig2_tr_gt_us ///
		fig2_tr_gt_ch ///
		fig2_tr_gt_ge, ///
			ytol xtob ytsize(3) xtsize(2.5) xsize(8) ysize(8) lrow(1) ring(12) iscale(0.6) row(2) graphon
	graph export "${plot}/fig2.emf", replace

* erase country graphs	

foreach c in _au _us _ch _ge {	
	
	erase "${plot}/fig2_tr_gt`c'.emf"

}

* clear graph window

graph drop *

*------------------------------------------------------------------------------*

* Regression tables - Appendix Table A2 & A3

rename syear syear_aux
egen syear= group(syear_aux)
labmask syear, values(syear_aux)
lab var syear "Wave"

* SSR tables for women
	
esttab  MPOLS22_au MPOLS22_us MPOLS22_ch MPOLS22_ge MDID22_au MDID22_us MDID22_ch MDID22_ge MDIT22_au MDIT22_us MDIT22_ch MDIT22_ge  ///
    using "${text}/tableA2_A3.rtf", replace ///
	title("Appendix - Table A2: Models for women") ///
	stats(N aic bic ll r2_a, fmt(%9.0g) labels("Observations" "AIC" "BIC" "Log-likelihood" "R2")) ///
    se star( * 0.10 ** 0.05 *** 0.01 ) b(3) ///
    mlabels("POLS: AU" "POLS: US" "POLS: CH" "POLS: DE" "POLS-GFE: AU" "POLS-GFE: US" "POLS-GFE: CH" "POLS-GFE: DE" "POLS-GT: AU" "POLS-GT: US" "POLS-GT: CH" "POLS-GT: DE") nonumbers ///
    eqlabels(none) label ///
	varlabels(	parent_tvc "Time before/since birth year (Ref.: BY-3a+)" ///
				edu2 "Education (Ref.: Low)" ///
				relstat_b "Partner (Ref.: No partner)" ///
				bcohort2 "Birth cohort (Ref.: 1970-1979)" ///
				parent_ev "Ever parent (GFE)" ///
				1.parent_ev "Ever parent (GT)" ///
				1.parent_ev#c.age "Ever parent X Age" ///
				_cons "Constant" ) ///
	drop(0.parent_tvc 1.edu2 1.relstat_b 2.bcohort2 0.parent_ev 0.parent_ev#c.age) ///
	order(parent_tvc *.parent_tvc edu2 2.edu2 age relstat_b 2.relstat_b bcohort2 3.bcohort2 syear 1999.syear 2000.syear *.syear parent_ev 1.parent_ev 1.parent_ev#c.age)

* SSR tables for men	
	
esttab MPOLS21_au MPOLS21_us MPOLS21_ch MPOLS21_ge MDID21_au MDID21_us MDID21_ch MDID21_ge MDIT21_au MDIT21_us MDIT21_ch MDIT21_ge ///
    using "${text}/tableA2_A3.rtf", append ///
	title("Appendix - Table A3: Models for men") ///
	stats(N aic bic ll r2_a, fmt(%9.0g) labels("Observations" "AIC" "BIC" "Log-likelihood" "R2")) ///
    se star( * 0.10 ** 0.05 *** 0.01 ) b(3) ///
    mlabels("POLS: AU" "POLS: US" "POLS: CH" "POLS: DE" "POLS-GFE: AU" "POLS-GFE: US" "POLS-GFE: CH" "POLS-GFE: DE" "POLS-GT: AU" "POLS-GT: US" "POLS-GT: CH" "POLS-GT: DE") nonumbers ///
    eqlabels(none) label ///
	varlabels(	parent_tvc "Time before/since birth year (Ref.: BY-3a+)" ///
				edu2 "Education (Ref.: Low)" ///
				relstat_b "Partner (Ref.: No partner)" ///
				bcohort2 "Birth cohort (Ref.: 1970-1979)" ///
				parent_ev "Ever parent (GFE)" ///
				1.parent_ev "Ever parent (GT)" ///
				1.parent_ev#c.age "Ever parent X Age" ///
				_cons "Constant" ) ///
	drop(0.parent_tvc 1.edu2 1.relstat_b 2.bcohort2 0.parent_ev 0.parent_ev#c.age) ///
	order(parent_tvc *.parent_tvc edu2 2.edu2 age relstat_b 2.relstat_b bcohort2 3.bcohort2 syear 1999.syear 2000.syear *.syear parent_ev 1.parent_ev 1.parent_ev#c.age)
	

/*------------------------------------------------------------------------------
#4 Regression models and figures for education-specific analyses
------------------------------------------------------------------------------*/

clear all
use "${pdta}/andata-pa.dta"

scalar starttime = c(current_time)	// Tracks running time

* run analysis only for sampleC (at least two pre-pregnancy observations)

drop if sampleC==0

xtset pid syear
sort country pid

* define globals

global av "phact_act"
global covars "age i.relstat_b i.syear i.bcohort2"

gen model=_n if _n<7
label val model parent_tvc
    
foreach c in _au _us _ch _ge {
		
		if "`c'"=="_au" {
			local cc = "AU"
		}

		if "`c'"=="_us" {
			local cc = "US"
		}
		
		if "`c'"=="_ch" {
			local cc = "CH"
		}    
		
		if "`c'"=="_ge" {
			local cc = "DE"
		}

		foreach s in 1 2 {
			forval e=1/2 {
				
				for any estgd`s'e`e'`c' estdd`s'e`e'`c' estdt`s'e`e'`c' ///
						logd`s'e`e'`c' lodd`s'e`e'`c' lodt`s'e`e'`c'    ///
						higd`s'e`e'`c' hidd`s'e`e'`c' hidt`s'e`e'`c': gen X=.

					local m=1
					foreach x in parent_t i.parent_tvc {
						reg $av`c' `x' $covars if sex==`s' & edu2==`e' & sampleC==1, cluster(pid)
						est store MPOLS`m'`s'e`e'`c'

						forval n=1/6 {
							capture replace estgd`s'e`e'`c'=_b[`n'.parent_tvc] if _n==`n' & `m'==2
							capture replace logd`s'e`e'`c'=estgd`s'e`e'`c'-1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
							capture replace higd`s'e`e'`c'=estgd`s'e`e'`c'+1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
						}

						reg $av`c' `x' parent_ev $covars if sex==`s' & edu2==`e' & sampleC==1, cluster(pid)
						est store MDID`m'`s'e`e'`c'
						
						forval n=1/6 {
							capture replace estdd`s'e`e'`c'=_b[`n'.parent_tvc] if _n==`n' & `m'==2
							capture replace lodd`s'e`e'`c'=estdd`s'e`e'`c'-1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
							capture replace hidd`s'e`e'`c'=estdd`s'e`e'`c'+1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
						}

						reg $av`c' `x' i.parent_ev##c.$covars if sex==`s' & edu2==`e' & sampleC==1, cluster(pid)
						est store MDIT`m'`s'e`e'`c'
						forval n=1/6 {
							capture replace estdt`s'e`e'`c'=_b[`n'.parent_tvc] if _n==`n' & `m'==2
							capture replace lodt`s'e`e'`c'=estdt`s'e`e'`c'-1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
							capture replace hidt`s'e`e'`c'=estdt`s'e`e'`c'+1.96*_se[`n'.parent_tvc] if _n==`n' & `m'==2
						}

					local m=`m'+1	  
					}
				}	
			}
		
		* Figure 3, Women
		
		twoway (rspike lodt2e1`c' hidt2e1`c' model, color(black%30) lw(vvthick)) ///	   
			   (rspike lodt2e2`c' hidt2e2`c' model, color(black%30) lw(vvthick)) ///
			   (connected estdt2e1`c' model, ms(O) mc(black) lc(black) mfc(gs6) msize(large) lp(dash))  ///
			   (connected estdt2e2`c' model, ms(O) mc(black) lc(black) mfc(white) msize(large) lp(dash))  ///
			 , legend(order(3 4) label(3 "Education: Primary/Secondary") label(4 "Education: Tertiary") ring(0) bplace(7)) ///
			   xtitle("Timepoints", size(4)) ytitle("Difference in the proportion of weekly physical activity", size(4)) ///
			   xlabel(1(1)6, val labsiz(3) angle(45) nogrid) ylabel(-.4(.2).2, labsiz(3) nogrid format(%2.1f)) ///
			   xline(1(1)6, lcolor(white) lw(thin) lp(solid)) ///
			   xline(1.5 2.5 3.5 4.5 5.5 6.5 7.5, lcolor(white) lw(vthin) lp(solid)) ///
			   yline(.2 .1 -.1 -.2 -.3 -.4, lcolor(white) lw(thin) lp(solid)) ///
			   yline(0, lcolor(gs10) lw(thin)) ///
			   xline(1.5, lc(gs0) lw(thin)) ///
			   title("Women, `cc'", size(4)) ///
			   plotregion(lcolor(gs0) fc(gs14) margin(medium) lw(medthick)) xsize(4) ysize(3.7) name(fig3_diff_edu2_dit_fem`c', replace)
		graph export "${plot}/fig3_diff_edu2_dit_fem`c'.emf", replace
		
		*  Figure 3, Men

		twoway (rspike lodt1e1`c' hidt1e1`c' model, color(black%30) lw(vvthick)) ///	   
			   (rspike lodt1e2`c' hidt1e2`c' model, color(black%30) lw(vvthick)) ///
			   (connected estdt1e1`c' model, ms(O) mc(black) lc(black) mfc(gs6) msize(large) lp(dash))  ///
			   (connected estdt1e2`c' model, ms(O) mc(black) lc(black) mfc(white) msize(large) lp(dash))  ///
			 , legend(order(3 4) label(3 "Education: Primary/Secondary") label(4 "Education: Tertiary") ring(0) bplace(7)) ///
			   xtitle("Timepoints", size(4)) ytitle("Difference in the proportion of weekly physical activity", size(4)) ///
			   xlabel(1(1)6, val labsiz(3) angle(45) nogrid) ylabel(-.4(.2).2, labsiz(3) nogrid format(%2.1f)) ///
			   xline(1(1)6, lcolor(white) lw(thin) lp(solid)) ///
			   xline(1.5 2.5 3.5 4.5 5.5 6.5 7.5, lcolor(white) lw(vthin) lp(solid)) ///
			   yline(.2 .1 -.1 -.2 -.3 -.4, lcolor(white) lw(thin) lp(solid)) ///
			   yline(0, lcolor(gs10) lw(thin)) ///
			   xline(1.5, lc(gs0) lw(thin)) ///
			   title("Men, `cc'", size(4)) ///
			   plotregion(lcolor(gs0) fc(gs14) margin(medium) lw(medthick)) xsize(4) ysize(3.7) name(fig3_diff_edu2_dit_mal`c', replace)
		graph export "${plot}/fig3_diff_edu2_dit_mal`c'.emf", replace

}
	
* combined

	grc1leg2 ///
		fig3_diff_edu2_dit_fem_au ///
		fig3_diff_edu2_dit_fem_us ///
		fig3_diff_edu2_dit_fem_ch ///
		fig3_diff_edu2_dit_fem_ge ///
		fig3_diff_edu2_dit_mal_au ///
		fig3_diff_edu2_dit_mal_us ///
		fig3_diff_edu2_dit_mal_ch ///
		fig3_diff_edu2_dit_mal_ge, ///
			ytol xtob ytsize(3) xtsize(2.5) xsize(8) ysize(4.3) lrow(1) ring(12) iscale(0.6) row(2) graphon
	graph export "${plot}/fig3.emf", replace	

* erase country graphs	

foreach c in _au _us _ch _ge {	

	erase "${plot}/fig3_diff_edu2_dit_fem`c'.emf"
	erase "${plot}/fig3_diff_edu2_dit_mal`c'.emf"
}

/*----------------------------------------------------------------------------*/

* * Regression tables - Appendix Table A4 & A5

rename syear syear_aux
egen syear= group(syear_aux)
labmask syear, values(syear_aux)
lab var syear "Wave"

* SSR tables for women
	
esttab MDIT22e1_au MDIT22e1_us MDIT22e1_ch MDIT22e1_ge MDIT22e2_au MDIT22e2_us MDIT22e2_ch MDIT22e2_ge ///
    using "${text}/tableA4_A5.rtf", replace ///
	title("Appendix - Table A4: Models for women, stratified by education") ///
	stats(N aic bic ll r2_a, fmt(%9.0g) labels("Observations" "AIC" "BIC" "Log-likelihood" "R2")) ///
    se star( * 0.10 ** 0.05 *** 0.01 ) b(3) ///
    mlabels("AU, Pri./Sec." "US, Pri./Sec." "CH, Pri./Sec." "DE, Pri./Sec." "AU, Tert." "US, Tert." "CH, Tert." "DE, Tert.") nonumbers ///
    eqlabels(none) label ///
	varlabels(	parent_tvc "Time before/since birth year (Ref.: BY-3a+)" ///
				relstat_b "Partner (Ref.: No partner)" ///
				bcohort2 "Birth cohort (Ref.: 1970-1979)" ///
				1.parent_ev "Ever parent" ///
				1.parent_ev#c.age "Ever parent X Age" ///
				_cons "Constant" ) ///
	drop(0.parent_tvc 1.relstat_b 2.bcohort2 0.parent_ev 0.parent_ev#c.age) ///
	order(parent_tvc *.parent_tvc age relstat_b 2.relstat_b bcohort2 3.bcohort2 syear 1999.syear 2000.syear *.syear	1.parent_ev 1.parent_ev#c.age)
	
* SSR tables for men	
	
esttab MDIT21e1_au MDIT21e1_us MDIT21e1_ch MDIT21e1_ge MDIT21e2_au MDIT21e2_us MDIT21e2_ch MDIT21e2_ge ///
    using "${text}/tableA4_A5.rtf", append ///
	title("Appendix - Table A5: Models for men, stratified by education") ///
	stats(N aic bic ll r2_a, fmt(%9.0g) labels("Observations" "AIC" "BIC" "Log-likelihood" "R2")) ///
    se star( * 0.10 ** 0.05 *** 0.01 ) b(3) ///
    mlabels("AU, Pri./Sec." "US, Pri./Sec." "CH, Pri./Sec." "DE, Pri./Sec." "AU, Tert." "US, Tert." "CH, Tert." "DE, Tert.") nonumbers ///
    eqlabels(none) label ///
	varlabels(	parent_tvc "Time before/since birth year (Ref.: BY-3a+)" ///
				relstat_b "Partner (Ref.: No partner)" ///
				bcohort2 "Birth cohort (Ref.: 1970-1979)" ///
				1.parent_ev "Ever parent" ///
				1.parent_ev#c.age "Ever parent X Age" ///
				_cons "Constant" ) ///
	drop(0.parent_tvc 1.relstat_b 2.bcohort2 0.parent_ev 0.parent_ev#c.age) ///
	order(parent_tvc *.parent_tvc age relstat_b 2.relstat_b bcohort2 3.bcohort2 syear 1999.syear 2000.syear *.syear 1.parent_ev 1.parent_ev#c.age)

/*----------------------------------------------------------------------------*/

graph drop *

*==============================================================================*
