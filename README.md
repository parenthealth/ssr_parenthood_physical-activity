# The effect of parenthood on weekly physical activity in four OECD countries – A longitudinal analysis

## Abstract

This study investigates how parenthood affects weekly physical activity and explores how this effect varies by age of the child, parents’ gender, education, and the country context.
A substantial body of literature reports parenthood to decline weekly physical activity, though with considerable variation across studies. Although sociological scholarships have long emphasized the diversity of parenthood, few studies have specifically examined the dynamic nature and heterogeneity of its impact on physical activity. This study advances existing knowledge by addressing these gaps, comparing the effect of parenthood over time and across different social and national contexts. In addition, data and methodological limitations are addressed by analyzing parenthood from three years before to ten and more years after birth and by using difference-in-difference estimation.
The study harmonized household data for four countries (Australia, Germany, Switzerland, and the United States) from 2001 to 2019. Country-specific longitudinal group trend regression models were used to account for unobserved heterogeneity between parents and childless adults.
Entering parenthood significantly decreases the likelihood of weekly physical activity, especially among women. The effect declines as the child grows up but persists in all countries for several years. However, the size and duration of the effect vary by country, gender, and educational attainment.
Interventions to promote regular physical activity among parents need to consider the heterogeneity of parenthood including the age of the child, parental gender, and socioeconomic status, as well as the broader country context. More comparative panel studies are needed to better understand the effects of cultural and institutional differences.

----

The paper by Linden, P.; Reibling, N. & Kuhhirt, M. with the DOI: 10.1016/j.ssresearch.2025.103305 [here](https://www.sciencedirect.com/science/article/pii/S0049089X25001668). If you have any questions, please send an E-Mail to [Linden Research](mailto:research@linden-online.com).

----

### History

`2026-01-14`
:  Setup

---

### Directories

`\1_scripts`
:  scripts for replicating the analysis <br />
- `\cpf` : CPF data  <br />
- `\pa` : Physical activity data
	
`\2_rdta`
: folder for raw data

`\3_pdta`
: processed data

`\4_output`
: output (logs, tables & figures)

---

### Description

This repository contains the code for the analysis in the paper entitled "The effect of parenthood on weekly physical activity in four OECD countries – A longitudinal analysis" which is published under open access in [Social Sciences Research](https://www.sciencedirect.com/science/article/pii/S0049089X25001668).

The data for this analysis comes from harmonized data from four longitudinal household surveys: the Household, Income and Labour Dynamics [HILDA](https://melbourneinstitute.unimelb.edu.au/hilda) for Australia, the Panel Study of Income Dynamics [PSID](https://psidonline.isr.umich.edu/) for the U.S., the Swiss Household Panel [SHP](https://forscenter.ch/projekte/swiss-household-panel/?lang=de) for Switzerland and the Socio-Economic Panel [SOEP](https://www.diw.de/en/diw_01.c.615551.en/research_infrastructure__socio-economic_panel__soep.html) for Germany. Harmonization of covariates was achieved by adapting procedures from [Turek et al. 2021](https://academic.oup.com/esr/article/37/3/505/6168670). Please refer to the [CPF project](https://cpfdata.com/) for details. After harmonization and preparation of the data sets, we were able to analyze a sample of N=111,331 person-years over a time period from 1999-2019 (20 years).

---

### Replication instruction

All analysis were done in Stata 16 and under Windows 11. Please follow the steps listed below to reproduce findings:

1. Fork the repository / Sync fork if necessary
2. Open the file 00cr-cpf-master.do in 1_scripts\cpf to construct the CPF file for harmonized covariates over the four countries. Within the file note that you need to insert the raw data sets (see next step).
3. Since the data sets are not publicly accessible, we cannot provide data files within this repository. To access the data, you must register on the homepage of the data hosting institutions and/or complete a data use agreement. Please note also that the data used in this analysis refers to specific file versions:
	- HILDA: The Household, Income and Labour Dynamics in Australia (HILDA) Survey, GENERAL RELEASE 21 (Waves 1-21) DOI: 10.26193/KXNEBO.
	- PSID: Panel Study of Income Dynamics, Cross-year Individual Files 1968-2019.
	- SHP: Living in Switzerland Waves 1-21, DOI: 10.23662/FORS-DS-932-6.
	- SOEP: Socio-economic Panel (SOEP), Data of 1984-2019, (SOEP-Core, v36, EU Edition), DOI: 10.5684/soep.core.v36eu. <br />
	- Practical information on accessing the data and storing it on your personal storage device can be found in the Master-Do file under section #4.
4. After setting up the raw data, run the rest of the CPF master do-File. You should now have created a CPF dataset (CPF-pa.dta) with harmonized covariates within the folder 3_pdta\cpf\01cpf-out.
5. Run the file 00master-ph-exercise-com in 1_scripts\pa to construct and analyze the harmonized dataset. All log-files, tables and figures should then be available in the output folder.

Please mail to [Linden Research](mailto:research@linden-online.com) if anything is not working properly.

