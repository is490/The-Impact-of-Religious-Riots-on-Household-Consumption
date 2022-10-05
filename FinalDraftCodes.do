***The other rounds (43rd, 50th and 55th) are similarly coded****
***The State and State Region data in round 50th and 55th are matched to the State and State Region codes of Round 38 to maintain uniformity*** 
***Renaming variables***
rename B3_1_q7 religion
rename B3_1_q11 pce
rename Wgt_Combined multiplier

***dropping the irrelevant data variables from the raw data file: Round 38***
drop B3_1_q1 B3_1_q2 B3_1_q3 B3_1_q4 B3_1_q9 B3_1_q10 B3_1_q12 B3_1_q13 B3_1_q14 B3_1_q15 B3_1_q16 B10_q1 B10_q2 B10_q3 B10_q4 B10_q5
B10_q6 B10_q7 B10_q8 B10_q9 B10_q11 Last_rec_indicator Wgt_SubSample Record_No Upadate_Code CDI Sector villageno SubRound Hhold_no Sample Stratum SubSample samplevillage informantcode Informant_Type_Code Survey_Code Substn_Code Income_account Expenditure_account niccode ncocode householdtypecode HH_Type socialgroupcode Posted_Stratum_Code pcew

***Create per-capita expenditure that is apppropriately weighted for each HH***
gen pcew=pce*multiplier
save "D:\Thesis\38\NSS38_hhdata.dta", replace
***Generate Average per-capita expenditure at the region level by religion (Muslims & Hindus) for each round***
***First, for Muslim HHs***
keep if religion=="2"
collapse(sum) pcew multiplier, by (stateregion)
gen mpce=pcew/(multiplier)
rename multiplier multm
sort stateregion
save "D:\Thesis\38\NSS38_Mdata.dta", replace

***Generate Average per-capita expenditure at the region level by religion (Muslims & Hindus) for each round***
***First, for Hindu HHs***
use "D:\Thesis\38\NSS38_hhdata.dta", replace
keep if religion == "1"
collapse(sum) pcew multiplier, by (stateregion)
gen hpce=pcew/(multiplier)
rename multiplier multh
sort stateregion
save "D:\Thesis\38\NSS38_Hdata.dta", replace
merge stateregion using "D:\Thesis\38\NSS38_Mdata.dta", unique
drop _merge
sort stateregion
gen logwtmpcH=ln(hpce)
gen logwtmpcM=ln(mpce)
gen MHexp=mpce/hpce
gen logMH= ln(MHexp)
save "D:\Thesis\38\HMdata.dta", replace

***Generate regional level controls: Population, Muslim %, Religious Polarization***
use "D:\Thesis\38\NSS38_hhdata.dta", replace
collapse(sum) pcew multiplier, by(stateregion)
gen avpce=pcew/multiplier
gen logavpce= ln(avpce)
gen mult=multiplier/10000
total mult
*** we get the total of 'mult' all over india as 13110.41***
gen regnpop=(mult/1311041)*100  
gen logpop=ln(regnpop)
drop mult pcew
sort stateregion
save "D:\Thesis\38\controls.dta", replace
merge stateregion using "D:\Thesis\38\HMdata.dta",unique
drop _merge
gen muslimpercent=(100*multm)/multiplier
gen s1=multh/(multh+multm)
gen s2=multm/(multh+multm)
gen rpol=4*((s1^2)*(1-s1)+(s2^2)*(1-s2))
drop multiplier
save "D:\Thesis\38\HMdata.dta", replace

***Generate Gini coefficients for Hindu HHs and Muslim HHs at the regional level***
***Generate religion dummies and then add up for each region***

use "D:\Thesis\38\NSS38_hhdata.dta", clear
quietly tabulate religion, gen (relig_dum)
collapse (sum)  relig_dum2 relig_dum3, by (stateregion)
save "D:\Thesis\38\HMReligionDummy.dta", replace

use "D:\Thesis\38\NSS38_hhdata.dta", clear
sort stateregion
merge stateregion using "D:\Thesis\38\HMReligionDummy.dta", uniqusing
drop _merge
sort stateregion
    ****drop regions with no Hindus******
drop if  relig_dum2==0
    ****drop regions with no Muslims******
drop if  relig_dum3==0
save "D:\Thesis\38\GiniReligionDummy_HM.dta", replace

drop if pce == .
gen gini_srH = .    
gen gini_srM = . 
egen subgroup = group(stateregion)
gen mult_rounded=round( mult)
replace mult_rounded=0 if multiplier<0  
                        
levels subgroup, local(levels) 
foreach i of local levels { 
      ineqdeco pce [fw=mult_rounded] if [subgroup == `i' & religion == "1"]
      replace gini_srH = $S_gini if [subgroup == `i'& religion == "1"]
} 

levels subgroup, local(levels) 
foreach i of local levels { 
      ineqdeco pce [fw=mult_rounded] if [subgroup == `i' & religion == "2"]
      replace gini_srM = $S_gini if [subgroup == `i' & religion == "2"]
} 


keep stateregion gini_srH gini_srM
collapse (mean) gini_srH  gini_srM, by (stateregion)
save "D:\Thesis\38\sr_HM_Gini.dta", replace

***Urbanization variable***
use "D:\Thesis\38\NSS38_hhdata.dta",replace
destring Sector, gen (sec)
gen urb=(sec==2)
gen urb_w=urb*multiplier
collapse(sum) urb_w multiplier, by (stateregion)
gen urban=urb_w/(multiplier)
rename urban hh_urban
sort stateregion
save "D:\Thesis\38\UrbanControl.dta",replace

***Merging datasets***
use "D:\Thesis\38\NSS38_hhdata.dta",clear
sort stateregion
merge stateregion using "D:\Thesis\38\HMdata.dta"
drop _merge

sort stateregion
merge stateregion using "D:\Thesis\38\sr_HM_Gini.dta"
drop _merge

sort stateregion
merge stateregion using "D:\Thesis\38\UrbanControl.dta"
drop _merge

***Merging riots dataset***
***generate numeric type of stateregion as sr to match with the using data with numeric varaible types***
destring stateregion, gen(sr)
sort sr
merge m:1 sr using "D:\Thesis\38\Riots_38.dta",force
drop _merge

***dropping states not used in the analysis***
drop if State == "03"
drop if State == "07"
drop if State == "08"
drop if State == "13"
drop if State == "14"
drop if State == "15"
drop if State == "19"
drop if State == "21"
drop if State == "24"
drop if State == "25"
drop if State == "26"
drop if State == "27"
drop if State == "28"
drop if State == "29"
drop if State == "30"
drop if State == "31"
drop if State == "32"

*Merging IV dataset***
sort sr
merge m:1 sr using "D:\Thesis\38\IV_festivals_38.dta",force
drop _merge

sort sr
save "D:\Thesis\38\NSS38_MasterFile.dta",replace

***Merging for the final data set***sort stateregion

merge stateregion using "D:\Thesis\43\sr_HM_Gini.dta"
drop _merge

sort stateregion
merge stateregion using "D:\Thesis\43\UrbanControl.dta"
drop _merge
destring stateregion, gen(sr)
sort sr
merge m:1 sr using "D:\Thesis\43\Riots_43.dta", force
drop _merge
sort sr
merge m:1 sr using "D:\Thesis\43\IV_festivals_43.dta",force
drop _merge

sort sr
save using "....\MainData.dta"

*Exporting Tables*
**Table 1: Summary Statistics of Consumption***
estpost summarize avpce pcew hpce mpce MHexp gini_srH gini_srM
esttab using summarystatpce.rtf, cell("count mean sd min max") title(Table 1: Summary Statistics of Consumption) addnote("Source: National Sample Survey, 38th, 43rd, 50th and 55th rounds") nonumbers

**Table 2: Summary Statistics for Riots***
estpost summarize allkilled allinjured allcasualties alloutbreaks
esttab using summarystatriots.rtf, cell("count mean sd max min") title(Table 2: Summary Statistics of Riots) nonumbers addnote("Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996-2000 by Mitra and Ray (2014)")


***set fixed effects variable for region and time***
xtset sr round

***OLS regression with fixed effects model***
***Table 3: The Effect of Riots on Log of Hindu Per Capita Expenditure***
xtreg logwtmpcH allcasualties allkilled alloutbreak,fe robust
eststo h1
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcH allkilled allcasualties alloutbreak logpop rpol,fe robust
eststo h2
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcH allkilled allcasualties alloutbreak logpop rpol hh_urban,fe robust
eststo h3
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcH allkilled allcasualties alloutbreak logpop rpol gini_srH gini_srM hh_urban,fe robust
eststo h4
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
esttab h1 h2 h3 h4 using table3.rtf, replace label se star(* 0.10 ** 0.05 *** 0.01) s(fixedr fixedy r2 N, label("State Region Fixed Effects" "Time Fixed Effects" "R-Square" "Observations")) title("Table 4: The Effect of Riots on Log of Hindu Per Capita Expenditure") note("Source — Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996-2000 by Mitra and Ray (2014) and National Sample Survey 38th, 43rd, 50th and 55th rounds." "The dependent variable in this table is the log of per capita expenditures in Hindu households.") nonumbers

***Table 4: The Effect of Riots on Log of Muslim Per Capita Expenditure***
xtreg logwtmpcM allcasualties allkilled alloutbreak,fe robust
eststo m1
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcM allkilled allcasualties alloutbreak logpop rpol,fe robust
eststo m2
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcM allkilled allcasualties alloutbreak logpop rpol hh_urban,fe robust
eststo m3
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcM allkilled allcasualties alloutbreak logpop rpol gini_srH gini_srM hh_urban,fe robust
eststo m4
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
esttab m1 m2 m3 m4 using table4.rtf, replace label se star(* 0.10 ** 0.05 *** 0.01) s(fixedr fixedy r2 N, label("State Region Fixed Effects" "Time Fixed Effects" "R-Square" "Observations")) title("Table 5: The Effect of Riots on Log of Muslim Per Capita Expenditure") note("Source — Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996 to 2000 by Mitra and Ray (2014) and National Sample Survey 38th, 43rd, 50th and 55th rounds." "The dependent variable in this table is the log of per capita expenditures in Muslim households") nonumbers

***Table 5: The Effect of Riots on Log of Average Per Capita Expenditure***
xtreg logavpce allcasualties allkilled alloutbreak,fe robust
eststo a1
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logavpce allkilled allcasualties alloutbreak logpop rpol,fe robust
eststo a2
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logavpce allkilled allcasualties alloutbreak logpop rpol hh_urban,fe robust
eststo a3
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logavpce allkilled allcasualties alloutbreak logpop rpol gini_srH gini_srM hh_urban,fe robust
eststo a4
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
esttab a1 a2 a3 a4 using table5.rtf, replace label se star(* 0.10 ** 0.05 *** 0.01) s(fixedr fixedy r2 N, label("State Region Fixed Effects" "Time Fixed Effects" "R-Square" "Observations")) title("Table 6: The Effect of Riots on Log of Average Per Capita Expenditure") note("Source — Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996 to 2000 by Mitra and Ray (2014) and National Sample Survey 38th, 43rd, 50th and 55th rounds." "The dependent variable in this table is the log of average per capita expenditures in households") nonumbers


***Using IV***
***Checking the relevancy of IV, festivals, with first stage regression on conflict variables***
**Table 6: First Stage IV Regression of festivals on Riot variables**
xtreg allcasualties festival,fe robust
eststo f1
estadd local dc "No", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg allkilled festival,fe robust
eststo f2
estadd local dc "No", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg alloutbreak festival,fe robust
eststo f3
estadd local dc "No", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg allcasualties festival logpop rpol hh_urban,fe robust
eststo f4
estadd local dc "Yes", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg allkilled festival logpop rpol hh_urban,fe robust
eststo f5
estadd local dc "Yes", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg alloutbreak festival logpop rpol hh_urban,fe robust
eststo f6
estadd local dc "Yes", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
esttab f1 f2 f3 f4 f5 f6 using table6.rtf, replace label se star(* 0.10 ** 0.05 *** 0.01) s(dc fixedr fixedy r2 N, label("Demographic Controls" "State Region Fixed Effects" "Time Fixed Effects" "R-Square" "Observations")) title("Table 7: First Stage IV Regression of festivals on Riot variables") note("Source — Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996 to 2000 by Mitra and Ray (2014). The dataset for binary Instrument Variable festival was created manually for 14 States and their corresponding State Regions.") nonumbers drop(logpop rpol hh_urban)

***Second stage of IV regression***
**Table 7: Reduced form and IV regressions using festival as instrument variable for allcasualties**
xtivreg logwtmpcH (allcasualties = festival), fe
eststo i1
estadd local dc "No", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtivreg logwtmpcM (allcasualties = festival), fe
eststo i2
estadd local dc "No", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtivreg logavpce (allcasualties = festival), fe
eststo i3
estadd local dc "No", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtivreg logwtmpcH rpol logpop hh_urban (allcasualties = festival), fe
eststo i4
estadd local dc "Yes", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtivreg logwtmpcM rpol logpop hh_urban (allcasualties = festival), fe
eststo i5
estadd local dc "Yes", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtivreg logavpce rpol logpop hh_urban (allcasualties = festival), fe
eststo i6
estadd local dc "Yes", replace
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
esttab i1 i2 i3 i4 i5 i6 using table7.rtf, replace label se star(* 0.10 ** 0.05 *** 0.01) s(dc fixedr fixedy N, label("Demographic Controls" "State Region Fixed Effects" "Time Fixed Effects" "Observations")) title("Table 8: Reduced form and IV regressions using festival as instrument variable for allcasualties") note("Source — Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996 to 2000 by Mitra and Ray (2014). The dataset for binary Instrument Variable festival was created manually for 14 States and their corresponding State Regions.") nonumbers drop(logpop rpol hh_urban)



***Robustness Checks***
**using a different explanatory variable**
*we use variable "conflict" as an explanatory variable where, conflict = allcasualties + allotbreaks*
***OLS regression with fixed effects model***
***Table 8: Robustness Check***

xtreg logwtmpcH conflict logpop rpol hh_urban,fe robust
eststo r1
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logwtmpcM conflict logpop rpol hh_urban,fe robust
eststo r2
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
xtreg logavpce conflict logpop rpol hh_urban,fe robust
eststo r3
estadd local fixedr "Yes", replace
estadd local fixedy "Yes", replace
esttab r1 r2 r3 using table8.rtf, replace label se star(* 0.10 ** 0.05 *** 0.01) s(fixedr fixedy r2 N, label("State Region Fixed Effects" "Time Fixed Effects" "R-Square" "Observations")) title("Table 9: Robustness Check") note("Source — Varshney-Wilkinson data set on Religious Riots (1950-95) extended from 19996-2000 by Mitra and Ray (2014) and National Sample Survey 38th, 43rd, 50th and 55th rounds." "The dependent variables in this table is the log of per capita expenditure in Hindu households and the log of per capita expenditure in Muslim households" "***Significant at the 1 percent level. **Significant at the 5 percent level. *Significant at the 10 percent level.") nonumbers

***Graphs***

graph bar  hpce mpce , over( statename, label(angle(55)))
graph bar (max) allkilled (max) allcasualties , over( statename, label(angle(55)) )
graph bar  (max) logwtmpcH (max) logwtmpcM (max) logavpce , over( statename, label(angle(55)))







