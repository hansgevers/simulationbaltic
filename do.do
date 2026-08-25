/*
Stata code supporting paper "Financial Sustainability of the Care for the Disabled: A Simulation of Benefits for Older People in the Baltic States up to 2050 with data from SHARE and Eurostat"
Author: Hans Gevers - Junior Research Fellow at the Estonian Business School
https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee
*/

clear all
log using output.smcl, replace name("SimulationBaltic")

asdoc, text(\par \qc Financial Sustainability of the Care for the Disabled: A Simulation of Benefits for Older People in the Baltic States up to 2050 with data from SHARE and Eurostat) fs(12)  save(report.doc) replace
asdoc, text(\par \qc Hans Gevers - Junior Research Fellow at the Estonian Business School https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee) fs(10)  save(report.doc) append

*>>>PREPROCESSING

foreach num of numlist 8(1)9{
	clear all
	cd "C:\users\hansg\Documents\bestanden\PhD ebs\JRF work Stata\SHARE data 7\sharew`num'_rel9-0-0_ALL_datasets_stata\"
	use "sharew`num'_rel9-0-0_gv_imputations.dta"
	keep if implicat==1
	merge 1:1 mergeid using "sharew`num'_rel9-0-0_gv_health.dta"
	isid mergeid
	drop _merge
	merge 1:1 mergeid using "sharew`num'_rel9-0-0_gv_weights.dta"
	isid mergeid
	drop _merge

	if `num'==8{
		gen Qyear=2020	
	}
	if `num'==9{
		gen Qyear=2022	
	}

	keep if country==57 | country==48 | country==35

	save "C:\users\hansg\Documents\bestanden\PhD ebs\JRF work Stata\SHARE data 7\W`num'_final.dta", replace
}

clear all
cd "C:\users\hansg\Documents\bestanden\PhD ebs\JRF work Stata\SHARE data 7\"
use "W8_final.dta"
merge 1:1 mergeid using "weightslong.dta", keep(match)
drop _merge
save "W8_final.dta", replace

clear all
cd "C:\users\hansg\Documents\bestanden\PhD ebs\JRF work Stata\SHARE data 7\"
use "W9_final.dta"
merge 1:1 mergeid using "weightslong.dta", keep(match)
drop _merge
save "W9_final.dta", replace

clear all
cd "C:\users\hansg\Documents\bestanden\PhD ebs\JRF work Stata\SHARE data 7\"
use "W8_final.dta"
append using "W9_final.dta"

save "dataset.dta", replace

clear all

use "dataset.dta"

*>>>PREPARATION

label define isc 0 "None" 1 "Primary education" 2 "Lower secondary education" 3 "Upper secondary education" 4 "Post-secondary non-tertiary education" 5 "Bachelor's or equivalent level" 6 "Master's or equivalent level/Doctoral or equivalent level"
label values isced isc
label variable isced "Education"

generate income = thinc-ypen3

egen id= group(mergeid)

drop if cjs==-99

generate educ=0
replace educ=1 if isced==3 | isced==4
replace educ=2 if isced>=5
label define educL 0 "Less than primary, primary and lower secondary education (ISCED levels 0-2)" 1 "Upper secondary and post-secondary non-tertiary education (ISCED levels 3 and 4)" 2 "Tertiary education (ISCED levels 5-8)"
label values educ educL

keep single ypen3 gender cjs age educ sphus country income gali id Qyear sphus

*>>>DESCRIPTIVES

tabulate country
hist ypen3

asdoc codebook single ypen3 gender cjs age educ sphus country income gali id Qyear, compact save(report.doc) append

asdoc codebook, save(report.doc) append

vioplot age, over(gender) over(country) scheme(s2color) ytitle("Number of respondents", margin(small)) ylabel(30(10)100,angle(0) labsize(small) grid) 
graph export sample.png, replace height(2400)
vioplot age if ypen3>0, over(gender) over(country) scheme(s2color) ytitle("Number of respondents", margin(small)) ylabel(30(10)100,angle(0) labsize(small) grid) 
graph export sampleDis.png, replace height(2400)

asdoc spearman single ypen3 gender cjs age educ sphus country income gali id Qyear sphus, save(report.doc) append

*>>>ANALYSIS

xtset id Qyear

*-------
*ESTONIA

*general model

xttobit ypen3 i.gender age i.gali i.educ income if country==35, ll(0) iterate(25) baselevels tobit

xttobit ypen3 i.gender age i.gali i.educ income if country==35, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(CoreEE) replace
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(CoreEE) replace

*for disability

generate ageD=0
replace ageD=1 if age>=55 & age<=64
replace ageD=2 if age>=65 & age<=74
replace ageD=3 if age>=75 & age<=84
replace ageD=4 if age>=85
label define ageDl 0 "Less than 55 years old" 1 "Between 55 and 64 years old" 2 "Between 65 and 74 years old" 3 "Between 75 and 84 years old" 4 "Older than 85 years"
label values ageD ageDl

xttobit ypen3 i.gender i.ageD i.gali i.educ income if country==35, ll(0) iterate(25) baselevels
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(DisabilityEE) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(DisabilityEE) append

*for education

generate ageE=0
replace ageE=1 if age>=55 & age<=64
replace ageE=2 if age>=65
label define agel 0 "Less than 55 years old" 1 "Between 55 and 64 years old" 2 "Older than 64 years"
label values ageE agel

xttobit ypen3 i.gender i.ageE i.gali i.educ income if country==35, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(EducationEE) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(EducationEE) append

*for income

xttobit ypen3 i.gender i.ageE i.gali i.educ income if country==35, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(IncomeEE) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(IncomeEE) append

*-------
*LITHUANIA

*general model

xttobit ypen3 i.gender age i.gali i.educ income if country==48, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(CoreLT) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(CoreLT) append

*for disability

xttobit ypen3 i.gender i.ageD i.gali i.educ income if country==48, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(DisabilityLT) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(DisabilityLT) append

*for education

xttobit ypen3 i.gender i.ageE i.gali i.educ income if country==48, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(EducationLT) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(EducationLT) append

*for income

xttobit ypen3 i.gender i.ageE i.gali i.educ income if country==48, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(IncomeLT) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(IncomeLT) append

*-------
*LATVIA

*general model

xttobit ypen3 i.gender age i.gali i.educ income if country==57, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(Core) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(Core) append

*for disability

xttobit ypen3 i.gender i.ageD i.gali i.educ income if country==57, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(DisabilityLV) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(DisabilityLV) append

*for education

xttobit ypen3 i.gender i.ageE i.gali i.educ income if country==57, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(EducationLV) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(EducationLV) append

*for income

xttobit ypen3 i.gender i.ageE i.gali i.educ income if country==57, ll(0) iterate(25) baselevels tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(IncomeLV) append
outreg2 using resultsNoStar.xls, excel dec(3) ctitle(IncomeLV) append

log close SimulationBaltic
translate output.smcl output.pdf