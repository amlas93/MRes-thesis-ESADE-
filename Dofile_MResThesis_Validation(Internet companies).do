clear all
set more off

// 0 - Setting up the data //
* Set up directory
cd "C:\Users\slemk\Desktop\MRes Thesis\New versions"

* Create logfile
log using logfile_MResthesis_internet, replace

* Open Dataset
use "Internet_sample_dataset", clear

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

* Exploring main inconsistencies
list gvkey if at==0 | missing(at) | at<0
list gvkey if sale<=0 | missing(sale)

* Checking for duplicated observations
duplicates report gvkey fyear
sort gvkey fyear
quietly by gvkey fyear: gen dup = cond(_N==1,0,_n)
bysort gvkey: tabulate dup
drop if dup>1

* Dropping the firms belonging to the excluded industries
drop if sic >= 6000 & sic <= 6399 | sic >= 6700 & sic <= 6799 | sic >=4900 & sic <=4999 | sic >=1000 & sic <=1499

* Applying the 5 fama-french industry classification

recode sic (2520/2589 2600/2699 2750/2769 2800/2829 2840/2899 3000/3099 3200/3569 3580/3621 3623/3629 3700/3709 3712/3713 3715 3717/3749 3752/3791 3793/3799 3860/3899 1200/1399 2900/2999 4900/4949 = 2) (3570/3579 3622 3660/3692 3694/3699 3810/3839 7370/7379 7391 8730/8734 4800/4899 = 3) (2830/2839 3693 3840/3859 = 4) (0100/0999 2000/2399 2700/2749 2770/2799 3100/3199 3940/3989 2500/2519 2590/2599 3630/3659 3710 3711 3714 3716 3750 3751 3792 3900/3939 3990/3999 5000/5999 7200/7299 7600/7699 8000/8099 4812 4813 4841 4832 4833 = 1), generate (Industry)
replace Industry = 5 if Industry==sic

label var Industry "Modified Fama-French Industry Code"

label define Industry 1 "Consumer Durables, NonDurables, Wholesale, Retail, and Some Services" 2 "Manufacturing, Energy, and Utilities" 3 "Business Equipment, Telephone, and Television Transmission" 4 "Healthcare, Medical Equipment, and Drugs" 5 "Other"

codebook Industry

* Setting up the data as panel
sort gvkey fyear
xtset gvkey fyear
xtdescribe

* Dealing with missing values
misstable summarize xrd xrdp xsga mkvalt lt pstk intan at
mvencode xrd  xrdp xsga mkvalt pstk lt intan, mv(0) override

* Adjusting variables
list gvkey if xrdp<0
replace xsga=xsga-xrd-xrdp if xrd<xsga

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

save "cleaned_data_internet", replace

* estimating sga parameter
gen xsga1 = l1.xsga
gen xsga2 = l2.xsga
gen xsga3 = l3.xsga
gen xsga4 = l4.xsga
gen xsga5 = l5.xsga
gen xsga6 = l6.xsga
gen xsga7 = l7.xsga
gen xsga8 = l8.xsga
gen xsga9 = l9.xsga
gen xsga10 = l10.xsga

gen P_intan = mkvalt + lt + pstk - (ppegt+act+ao)

gen Y = P_intan+1

tabulate fyear, generate(rho_dummy)

gen lnY = log(Y)

drop if Y<0
set seed 1234
sample 30

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42+rho_dummy43+rho_dummy44+rho_dummy45+rho_dummy46+rho_dummy47)*47)+log(intan + Knowledge_Cap + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1))

* Creating new organization capitalisation amount

use "cleaned_data_internet", replace

sort fyear gvkey

gen gamma_i = 0.4128601

gen Organizational_Cap_i = (gamma_i)*l1.xsga*(1-0.2)+(gamma_i)*l2.xsga*(1-0.2)^2+(gamma_i)*l3.xsga*(1-0.2)^3+(gamma_i)*l4.xsga*(1-0.2)^4+(gamma_i)*l5.xsga*(1-0.2)^5+(gamma_i)*l6.xsga*(1-0.2)^6+(gamma_i)*l7.xsga*(1-0.2)^7+(gamma_i)*l8.xsga*(1-0.2)^8+(gamma_i)*l9.xsga*(1-0.2)^9+(gamma_i)*l10.xsga*(1-0.2)^10


* Analysis
gen intan_internal = Organizational_Cap + Knowledge_Cap
gen Adj_Bookvalue = at + intan_internal
gen Bookvalue = at
gen Marketvalue = mkvalt + lt+ pstk

gen intan_internal_i = Organizational_Cap_i + Knowledge_Cap
gen Adj_Bookvalue_i = at + intan_internal_i

xtreg Marketvalue Bookvalue
outreg2 using results_internet.doc, replace

xtreg Marketvalue Adj_Bookvalue
outreg2 using results_internet.doc, append

xtreg Marketvalue Adj_Bookvalue_i
outreg2 using results_internet.doc, append

collapse (mean) Marketvalue Bookvalue Adj_Bookvalue Adj_Bookvalue_i, by(fyear)

* Additional Analysis

use "cleaned_data_internet", clear
gen defl_Adj_BV= l2.Adj_Bookvalue/sale

gen defl_BV = l2.Bookvalue/sale

gen defl_earnings = ebit/sale

xtreg defl_earnings defl_BV
outreg2 using rob_results.doc, replace

xtreg defl_earnings defl_Adj_BV
outreg2 using rob_results.doc, append

gen diff = Marketvalue-Bookvalue
gen Adj_diff = Marketvalue-Adj_Bookvalue

gen q = Marketvalue/Bookvalue
gen Adj_q = Marketvalue/Adj_Bookvalue

save "cleaned_data_internet", replace

collapse (mean) q Adj_q, by(fyear)

drop if Industry !=1
collapse (mean) diff Adj_diff, by(fyear)
gen Industry=1
save collapse_1_internet.dta, replace

use "cleaned_data_internet", clear
drop if Industry !=3
collapse (mean) diff Adj_diff, by(fyear)
gen Industry=3
save collapse_3_internet.dta, replace

use "cleaned_data_internet", clear
drop if Industry !=5
collapse (mean) diff Adj_diff, by(fyear)
gen Industry=5
save collapse_5_internet.dta, replace

append using "collapse_3_internet" "collapse_1_internet"

save collapse_all_internet.dta, replace


* export excel file


