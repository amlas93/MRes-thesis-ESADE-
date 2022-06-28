///////////////////////////////7/
// Project_Name: MRes Thesis   //
// Author: Salma Lemkhente     //
// Starting Date: May 15, 2022 //
/////////////////////////////////

clear all
set more off

// 0 - Setting up the data //
* Set up directory
cd "C:\Users\slemk\Desktop\MRes Thesis\New versions"

* Create logfile
log using logfile_MResthesis_full, replace

* Open Dataset
use "Full_sample_dataset", clear

// I - Cleaning the data //

* Exploring the data
describe
summarize 
sort fyear

* Converting from string to numerical when needed
destring GVKEY, replace
rename GVKEY gvkey
destring sic, replace

* Exploring missing values
mdesc
list gvkey if missing(sic)
replace sic=4412 if gvkey==335466
replace sic=67679 if gvkey==39750

* Dropping the firms belonging to the excluded industries
drop if sic >= 6000 & sic <= 6399 | sic >= 6700 & sic <= 6799 | sic >=4900 & sic <=4999 | sic >=1000 & sic <=1499

* Exploring main inconsistencies
drop if  missing(at) | at<0
drop if sale<=0 | missing(sale)

* Adjusting variables
gen mkvalt2 = prcc_f*csho if missing(mkvalt)
replace mkvalt2=0 if missing(mkvalt2)
replace mkvalt=0 if missing(mkvalt)
gen mkvalt3= mkvalt+mkvalt2
replace mkvalt=mkvalt3
summarize mkvalt mkvalt3
replace xsga=xsga-xrd-xrdp if xrd<xsga

* Checking for duplicated observations
duplicates report gvkey fyear
sort gvkey fyear
quietly by gvkey fyear: gen dup = cond(_N==1,0,_n)
bysort gvkey: tabulate dup
drop if dup>1

* Checking for inconsistencies
inspect xrd xsga pstk ao intan act at lt mkvalt
drop if ao<0 | pstk<0 | xsga<0 | xrd<0 | lt<0
winsor2 ppegt act ao,cuts (1 99) trim by(gvkey fyear)
tabulate fyear if (mkvalt + lt + pstk) < at
count if (mkvalt + lt + pstk)-at<0
drop if (mkvalt + lt + pstk) < (ppegt+act+ao) & mkvalt>0 & lt>0 & pstk>0

* Dealing with remaining missing values
misstable summarize xrd xsga mkvalt pstk ppegt lt intan at
misstable nested act sale xrd xsga mkvalt pstk ppegt lt intan at ao

mvencode act sale xrd xsga mkvalt pstk ppegt lt intan at ao, mv(0) override

* Creating a new categorical variable based on the paper's modified version of the 5-industry classification of Fama and French
recode sic (2520/2589 2600/2699 2750/2769 2800/2829 2840/2899 3000/3099 3200/3569 3580/3621 3623/3629 3700/3709 3712/3713 3715 3717/3749 3752/3791 3793/3799 3860/3899 1200/1399 2900/2999 4900/4949 = 2) (3570/3579 3622 3660/3692 3694/3699 3810/3839 7370/7379 7391 8730/8734 4800/4899 = 3) (2830/2839 3693 3840/3859 = 4) (0100/0999 2000/2399 2700/2749 2770/2799 3100/3199 3940/3989 2500/2519 2590/2599 3630/3659 3710 3711 3714 3716 3750 3751 3792 3900/3939 3990/3999 5000/5999 7200/7299 7600/7699 8000/8099 4812 4813 4841 4832 4833 = 1), generate (Industry)
replace Industry = 5 if Industry==sic
label var Industry "Modified Fama-French Industry Code"
label define Industry 1 "Consumer Durables, NonDurables, Wholesale, Retail, and Some Services" 2 "Manufacturing, Energy, and Utilities" 3 "Business Equipment, Telephone, and Television Transmission" 4 "Healthcare, Medical Equipment, and Drugs" 5 "Other"
codebook Industry

* Checking for duplicated observations
duplicates report gvkey fyear

* Setting up the data as panel
sort gvkey fyear
xtset gvkey fyear
xtdescribe

* Compute the internally generated capital (Knowledge and Organizational)

gen delta= 0.18537532
replace delta= 0.25812148  if Industry==2
replace delta= 0.45712276 if Industry==3
replace delta= 0.41600691 if Industry==4
replace delta= 0.49543143 if Industry==5

gen gamma=0.23268869 
replace gamma= 0.30025985 if Industry==2
replace gamma= 0.14802549 if Industry==3
replace gamma= 0.04927341  if Industry==4
replace gamma= 0.23691768   if Industry==5

gen Knowledge_Cap = l1.xrd*(1-delta) + l2.xrd *(1-delta)^2 + l3.xrd * (1-delta)^3 + l4.xrd * (1-delta)^4 + l5.xrd * (1-delta)^5+ l6.xrd * (1-delta)^6+ l7.xrd * (1-delta)^7+ l8.xrd * (1-delta)^8 + l9.xrd * (1-delta)^9 + l10.xrd * (1-delta)^10

gen Organizational_Cap = (gamma)*l1.xsga*(1-0.2)+(gamma)*l2.xsga*(1-0.2)^2+(gamma)*l3.xsga*(1-0.2)^3+(gamma)*l4.xsga*(1-0.2)^4+(gamma)*l5.xsga*(1-0.2)^5+(gamma)*l6.xsga*(1-0.2)^6+(gamma)*l7.xsga*(1-0.2)^7+(gamma)*l8.xsga*(1-0.2)^8+(gamma)*l9.xsga*(1-0.2)^9+(gamma)*l10.xsga*(1-0.2)^10

* Analysis
gen intan_internal = Organizational_Cap + Knowledge_Cap
gen Adj_Bookvalue = at + intan_internal
gen Bookvalue = at
gen Marketvalue = mkvalt + lt+ pstk

xtreg Marketvalue Bookvalue
outreg2 using validation.doc, replace

xtreg Marketvalue Adj_Bookvalue
outreg2 using validation.doc, append

xtreg Marketvalue Bookvalue if Industry==1
outreg2 using validation.doc, replace

xtreg Marketvalue Adj_Bookvalue if Industry==1
outreg2 using validation.doc, append

xtreg Marketvalue Bookvalue if Industry==2
outreg2 using validation.doc, append

xtreg Marketvalue Adj_Bookvalue if Industry==2
outreg2 using validation.doc, append

xtreg Marketvalue Bookvalue if Industry==3
outreg2 using validation.doc, append

xtreg Marketvalue Adj_Bookvalue if Industry==3
outreg2 using validation.doc, append

xtreg Marketvalue Bookvalue if Industry==4
outreg2 using validation.doc, replace

xtreg Marketvalue Adj_Bookvalue if Industry==4
outreg2 using validation.doc, append

xtreg Marketvalue Bookvalue if Industry==5
outreg2 using validation.doc, append

xtreg Marketvalue Adj_Bookvalue if Industry==5
outreg2 using validation.doc, append


gen q = Marketvalue/Bookvalue
gen Adj_q = Marketvalue/Adj_Bookvalue

save "cleaned_data_full", replace

*collapsing

collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)

drop if Industry !=1
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=1
save collapse_1_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=2
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=2
save collapse_2_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=3
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=3
save collapse_3_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=4
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=4
save collapse_4_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=5
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=5
save collapse_5_full.dta, replace

append using "collapse_4_full" "collapse_3_full" "collapse_2_full" "collapse_1_full"

save collapse_all_full.dta, replace

* excluding internet companies
use "cleaned_data_full", clear

drop if gvkey==2884 |gvkey==3382 |gvkey==16011 |gvkey==18750 |gvkey==18869 |gvkey==18872 |gvkey==19033 |gvkey==19295 |gvkey==20004|gvkey==20540 |gvkey==19033|gvkey==20699 |gvkey==21155 |gvkey==22164|gvkey==23071|gvkey==24234 |gvkey==26061|gvkey==26381|gvkey==27251|gvkey==29537|gvkey==30091|gvkey==32541|gvkey==32654|gvkey==32677 |gvkey==32935|gvkey==33175|gvkey==33186 |gvkey==33254|gvkey==33697|gvkey==33850|gvkey==33859|gvkey==34074|gvkey==34101|gvkey==34328|gvkey==34496|gvkey==35013|gvkey==35419|gvkey==35731|gvkey==35733|gvkey==36048 |gvkey==36616|gvkey==36691 |gvkey==37130 |gvkey==37148 |gvkey==37420|gvkey==37460|gvkey==38100|gvkey==38514|gvkey==38662|gvkey==38681|gvkey==39112|gvkey==39225|gvkey==39248|gvkey==62723|gvkey==64768|gvkey==66368|gvkey==119173|gvkey==122777|gvkey==137435|gvkey==137611|gvkey==144235|gvkey==149721|gvkey==164532|gvkey==170617|gvkey==175299|gvkey==177111|gvkey==177315|gvkey==178494|gvkey==184263|gvkey==185550|gvkey==186996|gvkey==187118|gvkey==187165|gvkey==187357|gvkey==187363|gvkey==188155|gvkey==196268|gvkey==238157|gvkey==321467

xtreg Marketvalue Bookvalue

xtreg Marketvalue Adj_Bookvalue

gen defl_Adj_BV= l2.Adj_Bookvalue/sale

gen defl_BV = l2.Bookvalue/sale

gen defl_earnings = ebit/sale

xtreg defl_earnings defl_BV
outreg2 using rob_results.doc, replace

xtreg defl_earnings defl_Adj_BV
outreg2 using rob_results.doc, append

save "cleaned_data_full", replace

*collapsing

collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)

drop if Industry !=1
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=1
save collapse_1_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=2
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=2
save collapse_2_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=3
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=3
save collapse_3_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=4
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=4
save collapse_4_full.dta, replace

use "cleaned_data_full", clear
drop if Industry !=5
collapse (mean) Marketvalue Adj_Bookvalue, by(fyear)
gen Industry=5
save collapse_5_full.dta, replace

append using "collapse_4_full" "collapse_3_full" "collapse_2_full" "collapse_1_full"

save collapse_all_full.dta, replace









