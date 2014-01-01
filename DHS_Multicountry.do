/* Multicountry 1.00         Damian C Clarke                     vers:2012-09-05
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*/
clear all
version 11.2
cap log close
set more off
set mem 1200m
set maxvar 20000

*********************************************************************************
*** (1) Globals and locals (set clean to yes to remove new files)
*********************************************************************************
global DHSFolder "~/database/DHS/ImportData"
global DHSFolder_Data "~/database/DHS/DHS_Data"
local clean no

cd $DHSFolder

file open surveys using "DHS_Surveys_StataUse.txt", read
file read surveys line

*********************************************************************************
*** (2) Include new variables for cross country merging
*********************************************************************************
local i 0
while r(eof)==0 {
	foreach name in code country year {
		local `name' `line'
		file read surveys line
	}
	local survey `line'
	local code_test=substr("`survey'",1,2)
	file read surveys line
	local recodes `line'
	file read surveys line
	dis in yellow "`country'"
	dis in green "`code_test'"
	dis in green "`code'"
	if "`code_test'"=="`code'" {
		cap use $DHSFolder_Data/`country'/`year'/`survey'
		if `c(rc)'==0 {
			cap mkdir $DHSFolder_Data/`recodes'
			foreach num of numlist 1(1)7 {
				cap mkdir $DHSFolder_Data/`recodes'/p`num'
			}
			cap gen _cou = "`country'"
			cap gen _cou_code = "`code'"
			cap gen _year = "`year'"
			cap drop s* //Here I drop all country specific variables.
			if "`code'"=="AF"|"`code'"=="AL"|"`code'"=="AM"|"`code'"=="AO"|/*
			*/ "`code'"=="AZ"|"`code'"=="BD"|"`code'"=="BJ"|"`code'"=="BO"|/*
			*/ "`code'"=="BT"|"`code'"=="BR"|/*
			*/ "`code'"=="BF"|"`code'"=="BU"|"`code'"=="KH"|"`code'"=="CM" {
				save $DHSFolder_Data/`recodes'/p1/`survey', replace
			}
			else if "`code'"=="CF"|"`code'"=="CV"|"`code'"=="TD"|/*
			*/ "`code'"=="CO"|"`code'"=="KM"|"`code'"=="CG"|"`code'"=="CD"|/*
			*/ "`code'"=="CI"|"`code'"=="DR"|"`code'"=="EC"|"`code'"=="ES"|/*
			*/ "`code'"=="EG"|"`code'"=="ER"|"`code'"=="ET"|"`code'"=="GA" {
				save $DHSFolder_Data/`recodes'/p2/`survey', replace
			}
			else if "`code'"=="IA" {
				save $DHSFolder_Data/`recodes'/p3/`survey', replace
			}
			else if "`code'"=="GH"|"`code'"=="GU"|"`code'"=="GN"|/*
			*/ "`code'"=="GY"|"`code'"=="HT"|"`code'"=="HN"|"`code'"=="ID"|/*
			*/ "`code'"=="JO"|"`code'"=="KK"|"`code'"=="KE"|"`code'"=="KY"|/*
			*/ "`code'"=="LS"|"`code'"=="LB"|"`code'"=="MD"|"`code'"=="MW" {
				save $DHSFolder_Data/`recodes'/p4/`survey', replace
			}
			else if "`code'"=="MV"|"`code'"=="ML"|"`code'"=="MR"|/*
			*/ "`code'"=="MX"|"`code'"=="MB"|"`code'"=="MA"|"`code'"=="MZ"|/*
			*/ "`code'"=="NM"|"`code'"=="NP"|"`code'"=="NC"|"`code'"=="NI"|/*
			*/ "`code'"=="NG"|"`code'"=="OS"|"`code'"=="PK"|"`code'"=="PY" {
				save $DHSFolder_Data/`recodes'/p5/`survey', replace
			}
			else if "`code'"=="PE"|"`code'"=="PH"|"`code'"=="RW"|/*
			*/ "`code'"=="WS"|"`code'"=="ST"|"`code'"=="SN"|"`code'"=="SL"|/*
			*/ "`code'"=="ZA"|"`code'"=="LK"|"`code'"=="SD"|"`code'"=="SZ"|/*
			*/ "`code'"=="TZ"|"`code'"=="TH"|"`code'"=="TP"|"`code'"=="TG" {
				save $DHSFolder_Data/`recodes'/p6/`survey', replace
			}
			else {
				save $DHSFolder_Data/`recodes'/p7/`survey', replace
			}
			local ++i
		}
		else if `c(rc)'!=0 {
			dis in red "`country'"
			dis in red "`year'"
		}
	}
}
dis "`i'"
file close surveys

*********************************************************************************
*** (3) Merge files producing the World_ datasets
*********************************************************************************
/*Note that the else conditions can be removed if the computer or terminal you
are working on is quite powerful.  I tested this do file on a computer with 8gb
of virtual memory and 8 cores, and it ran fine by splitting the files into 7 
parts rather than as one file (see below). */

foreach surveytype in IR /*BR PR HR CR MR KR*/ {
	foreach num of numlist 1(1)7 {
		clear
		local i_`surveytype' 0
		local myfiles: dir "$DHSFolder_Data/`surveytype'/p`num'" files "*.dta"
		foreach survey of local myfiles {
			dis in yellow "`i_`surveytype''"
			append using "$DHSFolder_Data/`surveytype'/p`num'/`survey'", force
			local ++i_`surveytype'
		}
		save $DHSFolder_Data/World_`surveytype'_p`num', replace
	}
}

foreach surveytype in IR /*BR PR HR CR MR KR*/ {
	dis "`i_`surveytype''"
}

*********************************************************************************
*** (4) Cleaning up
*********************************************************************************
local clean no
if "`clean'"=="yes" {
	foreach surveytype in AH BR CR HH HR IQ IR KR ML MR OD PQ PR SQ VA VR WI WS XP XR HW {
		foreach num of numlist 1(1)7 {
			cap local myfiles: dir "$DHSFolder_Data/`surveytype'/p`num'" files "*.dta"
			foreach survey of local myfiles {
				rm "$DHSFolder_Data/`surveytype'/p`num'/`survey'"				
			}
			rmdir "$DHSFolder_Data/`surveytype'/p`num'"
		}
		rmdir "$DHSFolder_Data/`surveytype'"
	}
}
else if "`clean'"!="yes" {
	dis "You have not removed files made by this program."  
	dis "If you wish to do so, change the local `clean' to yes."
}
