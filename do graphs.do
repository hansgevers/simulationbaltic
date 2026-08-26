/*
Stata code supporting paper "Financial Sustainability of the Care for the Disabled: A Simulation of Benefits for Older People in the Baltic States up to 2036 with data from SHARE and Eurostat"
Author: Hans Gevers - Junior Research Fellow at the Estonian Business School
https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee
*/

clear all

cd "C:\Users\hansg\Documents\bestanden\PhD ebs\JRF work Stata\SHARE data 7"

import excel "Forecast.xlsx", sheet("Eurostat data forecast") firstrow
encode Age, generate(AgeC)
encode Gender, generate(GenderC)
encode Country, generate(CountryC)

global var1 Estonia Latvia Lithuania
global var2 Females Males
foreach nr of numlist 1(1)3 {
	foreach nr2 of numlist 1(1)2 {
		local v1: word `nr' of $var1
		local v2: word `nr2' of $var2
		
		graph twoway connected Amount Year if CountryC==`nr' & GenderC==`nr2' & AgeC==1 || connected Amount Year if CountryC==`nr' & GenderC==`nr2' & AgeC==2 || connected Amount Year if CountryC==`nr' & GenderC==`nr2' & AgeC==3 || connected Amount Year if CountryC==`nr' & GenderC==`nr2' & AgeC==4 || connected Amount Year if CountryC==`nr' & GenderC==`nr2' & AgeC==5, scheme(s2color) ytitle("Amount in euros", margin(small)) ylabel(, angle(0) labsize(small) grid format(%12.0fc)) legend(lastlabel(1 "45-54") lastlabel(2 "55-64") lastlabel(3 "65-74") lastlabel(4 "75-84") lastlabel(5 "85+"))
		graph export `v1'_`v2'.svg, replace height(2400)
	}
}
