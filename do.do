/*
Stata code supporting paper "Financial Sustainability of the Care for the Disabled: A Simulation of Benefits for Older People in the Baltic States up to 2036 with data from SHARE and Eurostat"
Author: Hans Gevers - Junior Research Fellow at the Estonian Business School
https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee
*/

clear all
log using output.smcl, replace name("SimulationBaltic")

asdoc, text(\par \qc Financial Sustainability of the Care for the Disabled: A Simulation of Benefits for Older People in the Baltic States up to 2036 with data from SHARE and Eurostat) fs(12)  save(report.doc) replace
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

generate income = thinc-ypen3

egen id= group(mergeid)

keep ypen3 gender age country income gali id Qyear

replace income=0 if income<0

drop if ypen3>7000

*additional age categorization to match Eurostat categories
generate ageD=0
replace ageD=1 if age>=55 & age<=64
replace ageD=2 if age>=65 & age<=74
replace ageD=3 if age>=75 & age<=84
replace ageD=4 if age>=85
label define ageDl 0 "Less than 55 years old" 1 "Between 55 and 64 years old" 2 "Between 65 and 74 years old" 3 "Between 75 and 84 years old" 4 "Older than 85 years"
label values ageD ageDl

generate ageE=0
replace ageE=1 if age>=55 & age<=64
replace ageE=2 if age>=65
label define agel 0 "Less than 55 years old" 1 "Between 55 and 64 years old" 2 "Older than 64 years"
label values ageE agel

*>>>DESCRIPTIVES

tabulate country

asdoc codebook ypen3 gender age country income gali id Qyear, compact save(report.doc) append

asdoc codebook, save(report.doc) append

hist ypen3 if ypen3>0, scheme(s2color) xlabel(0(1000)7000,angle(0) labsize(small) grid) ylabel(0.000(0.0002)0.001,angle(0) labsize(small) grid format(%9.0gc)) 
graph export benefits.png, replace height(2400)
vioplot age, over(gender) over(country) scheme(s2color) ytitle("Number of respondents", margin(small)) ylabel(30(10)100,angle(0) labsize(small) grid) 
graph export sample.png, replace height(2400)
vioplot age if ypen3>0, over(gender) over(country) scheme(s2color) ytitle("Number of respondents", margin(small)) ylabel(30(10)100,angle(0) labsize(small) grid) 
graph export sampleDis.png, replace height(2400)

asdoc spearman ypen3 gender age country income gali id Qyear, save(report.doc) append

foreach ageC in ageD ageE{	
	foreach num of numlist 35 48 57{
			foreach num2 of numlist 1 2{
				foreach num3 of numlist 0 1{
					asdoc, text(\par for `ageC': Country `num' , gender `num2' , limited `num3')
					asdoc tabstat income if country==`num' & gender==`num2' & gali==`num3', by(`ageC') stat(mean), save(report.doc) append
				}
			}		
	}
}

*>>>ANALYSIS

xtset id Qyear

*for disability
xttobit ypen3 i.gender i.ageD i.gali income i.country, ll(0) iterate(25) tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(DisabilityTobit) replace

xtpoisson ypen3 i.gender i.ageD i.gali income i.country if ypen3>0, re vce(robust)
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(DisabilityPoisson) append
outreg2 using resultsNoStar.xls, excel dec(10) ctitle(DisabilityPoisson) noaster nose replace

*for income
xttobit ypen3 i.gender i.ageE i.gali income i.country, ll(0) iterate(25) tobit
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(IncomeTobit) append

xtpoisson ypen3 i.gender i.ageE i.gali income i.country if ypen3>0, re vce(robust)
outreg2 using results.xls, excel dec(3) alpha(0.01, 0.05, 0.10) symbol(***, **, *) ctitle(IncomePoisson) append
outreg2 using resultsNoStar.xls, excel dec(10) ctitle(IncomePoisson) noaster nose append

log close SimulationBaltic
translate output.smcl output.pdf