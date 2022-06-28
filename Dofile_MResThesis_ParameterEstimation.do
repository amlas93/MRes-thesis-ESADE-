///////////////////////////////7/
// Project_Name: MRes Thesis   //
// Author: Salma Lemkhente     //
// Starting Date: May 15, 2022 //
/////////////////////////////////

clear all
set more off

// 0 - Setting up the data //
* Set up directory
cd "C:\Users\slemk\Desktop\MRes Thesis"

* Create logfile
log using logfile_MResthesis, replace

* Open Dataset
use "Dataset_MResThesis", clear

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

* Editing the data according to the paper - eliminating companies with "gross PPE less than $5m, any firm with missing gross PPE, negative or missing sales or missing assets" as well as companies from sectors of "Financial Services, Resources, Real Estate, Utilities"
drop if ppegt<5 | missing(ppegt)
drop if at==0 | missing(at)
drop if sale <=0 | missing(sale)
drop if sic >= 6000 & sic <= 6399
drop if sic >= 6700 & sic <= 6799
drop if sic >=4900 & sic <=4999
drop if sic >=1000 & sic <=1499

* Dealing with remaining missing values
misstable summarize act sale xrd xsga mkvalt pstk ppegt lt intan at ao
misstable nested act sale xrd xsga mkvalt pstk ppegt lt intan at ao

mvencode act sale xrd xsga mkvalt pstk ppegt lt intan at ao, mv(0) override

* Checking for inconsistencies
inspect xrd xsga pstk ao intan act at lt mkvalt
drop if ao<0 | pstk<0 | xsga<0 | xrd<0
winsor2 ppegt act ao,cuts (1 99) trim by(gvkey fyear)
tabulate fyear if (mkvalt + lt + pstk) < (ppegt+act+ao) & mkvalt>0 & lt>0 & pstk>0
count if (mkvalt + lt + pstk)-at<0
drop if (mkvalt + lt + pstk) < (ppegt+act+ao) & mkvalt>0 & lt>0 & pstk>0
replace xsga=xsga-xrd if xrd<xsga

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


// II - Prepping the data for estimation //

* Generate variables
gen xrd1 = l1.xrd
gen xrd2 = l2.xrd
gen xrd3 = l3.xrd
gen xrd4 = l4.xrd
gen xrd5 = l5.xrd
gen xrd6 = l6.xrd
gen xrd7 = l7.xrd
gen xrd8 = l8.xrd
gen xrd9 = l9.xrd
gen xrd10 = l10.xrd

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

* Checking for inconsistencies
mvencode xrd1 xrd2 xrd3 xrd4 xrd5 xrd6 xrd7 xrd8 xrd9 xrd10 xsga1 xsga2 xsga3 xsga4 xsga5 xsga6 xsga7 xsga8 xsga9 xsga10, mv(0) override
count if P_intan<0 & mkvalt>0 & lt>0 & pstk>0
tabulate fyear if P_intan<0

* Descriptive statistics of main variables (conditionned on positive Price Intangibles)
xtdescribe if P_intan>=0
xtsum gvkey fyear xrd xsga intan P_intan if P_intan>=0

* Saving data
save cleaned_data.dta, replace

// III - Estimation of Intangible Capital Parameters //

preserve
* Random sampling (20% in each Industry)
drop if Y<=0
set seed 1234
sample 20, by(Industry)
tab Industry

* Running the non-linear least squares regression equation (Pooled)

// Eventually, I will add the bootstrapping of std errors: vce(bootstrap, reps(1000))

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42)+log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1))

outreg2 using capital_parameters.doc, replace
estimates store _All

*Running the non-linear least squares regression equation (Industry: Consumer) and saving its results

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42) + log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if Industry == 1

outreg2 using capital_parameters.doc, append
estimates store _1

* Running the non-linear least squares regression equation (Industry: Manufacturing) and saving its results

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42) + log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if Industry == 2

outreg2 using capital_parameters.doc, append
estimates store _2

* Running the non-linear least squares regression equation (Industry: High Tech) and saving its results

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42) + log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if Industry == 3

outreg2 using capital_parameters.doc, append
estimates store _3

* Running the non-linear least squares regression equation (Industry: Health) and saving its results

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42) + log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if Industry == 4

outreg2 using capital_parameters.doc, append
estimates store _4

* Running the non-linear least squares regression equation (Industry: Other) and saving its results

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42) + log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if Industry == 5

outreg2 using capital_parameters.doc, append
estimates store _5

* Displaying all estimated parameters and compare results with followed article (Ewen's et al)

estimates table _1 _2 _3 _4 _5

coefplot _All || _1 || _2 || _3 || _4 || _5, drop(rho:_cons) bycoefs byopts(xrescale) xscale(log range(-0.8 1.5)) xline(0, lcolor (grey) lwidth(thin) lpatter(dash)) xlabel(0, add) mlabel format (%9.2f) mlabposition(12) mlabgap(*2) coeflabel(delta:_cons = "Depreciation rate of R&D capital" gamma:_cons = "Fraction of SG&A", wrap(20) labsize(medlarge) labcolor(black)) graphregion(fcolor(white)) title ("{bf:Parameter Estimates}") ciopts(recast(rcap))

coefplot _All || _1 || _2 || _3 || _4 || _5, drop(rho:_cons) bycoefs byopts(yrescale) yline(0, lcolor (black) lwidth(vthin)) ylabel(0, add) vertical mlabel format (%9.2f) mlabposition(12) mlabgap(*2) coeflabel(delta:_cons = "Depreciation rate of R&D capital" gamma:_cons = "Fraction of SG&A", wrap(20) labsize(medlarge) labcolor(black)) graphregion(fcolor(white)) title ("{bf:Parameter Estimates}") ciopts(recast(rcap))

* Saving all estimation results
save estimation_data.dta, replace

// IV - Constructing the adjusted asset book value //

* Open full compustat cleaned data
use "cleaned_data", clear
xtset gvkey fyear

* Compute each firm's intangible stocks using the industry parameters just estimated

estimates restore _1
gen Knowledge_Cap = xrd1*(1-_b[delta:_cons]) + xrd2 *(1-_b[delta:_cons])^2 + xrd3 * (1-_b[delta:_cons])^3 + xrd4 * (1-_b[delta:_cons])^4 + xrd5 * (1-_b[delta:_cons])^5+ xrd6 * (1-_b[delta:_cons])^6+ xrd7 * (1-_b[delta:_cons])^7+xrd8 * (1-_b[delta:_cons])^8+ xrd9 * (1-_b[delta:_cons])^9 + xrd10 * (1-_b[delta:_cons])^10

gen Organizational_Cap = (_b[gamma:_cons])*xsga1*(1-0.2)+(_b[gamma:_cons])*xsga2*(1-0.2)^2+(_b[gamma:_cons])*xsga3*(1-0.2)^3+(_b[gamma:_cons])*xsga4*(1-0.2)^4+(_b[gamma:_cons])*xsga5*(1-0.2)^5+(_b[gamma:_cons])*xsga6*(1-0.2)^6+(_b[gamma:_cons])*xsga7*(1-0.2)^7+(_b[gamma:_cons])*xsga8*(1-0.2)^8+(_b[gamma:_cons])*xsga9*(1-0.2)^9+(_b[gamma:_cons])*xsga10*(1-0.2)^10

estimates restore _2
replace Knowledge_Cap = xrd1*(1-_b[delta:_cons]) + xrd2 *(1-_b[delta:_cons])^2 + xrd3 * (1-_b[delta:_cons])^3 + xrd4 * (1-_b[delta:_cons])^4 + xrd5 * (1-_b[delta:_cons])^5+ xrd6 * (1-_b[delta:_cons])^6+ xrd7 * (1-_b[delta:_cons])^7+xrd8 * (1-_b[delta:_cons])^8+ xrd9 * (1-_b[delta:_cons])^9 + xrd10 * (1-_b[delta:_cons])^10  if Industry==2

replace Organizational_Cap = (_b[gamma:_cons])*xsga1*(1-0.2)+(_b[gamma:_cons])*xsga2*(1-0.2)^2+(_b[gamma:_cons])*xsga3*(1-0.2)^3+(_b[gamma:_cons])*xsga4*(1-0.2)^4+(_b[gamma:_cons])*xsga5*(1-0.2)^5+(_b[gamma:_cons])*xsga6*(1-0.2)^6+(_b[gamma:_cons])*xsga7*(1-0.2)^7+(_b[gamma:_cons])*xsga8*(1-0.2)^8+(_b[gamma:_cons])*xsga9*(1-0.2)^9+(_b[gamma:_cons])*xsga10*(1-0.2)^10 if Industry==2

estimates restore _3
replace Knowledge_Cap = xrd1*(1-_b[delta:_cons]) + xrd2 *(1-_b[delta:_cons])^2 + xrd3 * (1-_b[delta:_cons])^3 + xrd4 * (1-_b[delta:_cons])^4 + xrd5 * (1-_b[delta:_cons])^5+ xrd6 * (1-_b[delta:_cons])^6+ xrd7 * (1-_b[delta:_cons])^7+xrd8 * (1-_b[delta:_cons])^8+ xrd9 * (1-_b[delta:_cons])^9 + xrd10 * (1-_b[delta:_cons])^10  if Industry==3

replace Organizational_Cap = (_b[gamma:_cons])*xsga1*(1-0.2)+(_b[gamma:_cons])*xsga2*(1-0.2)^2+(_b[gamma:_cons])*xsga3*(1-0.2)^3+(_b[gamma:_cons])*xsga4*(1-0.2)^4+(_b[gamma:_cons])*xsga5*(1-0.2)^5+(_b[gamma:_cons])*xsga6*(1-0.2)^6+(_b[gamma:_cons])*xsga7*(1-0.2)^7+(_b[gamma:_cons])*xsga8*(1-0.2)^8+(_b[gamma:_cons])*xsga9*(1-0.2)^9+(_b[gamma:_cons])*xsga10*(1-0.2)^10 if Industry==3

estimates restore _4
replace Knowledge_Cap = xrd1*(1-_b[delta:_cons]) + xrd2 *(1-_b[delta:_cons])^2 + xrd3 * (1-_b[delta:_cons])^3 + xrd4 * (1-_b[delta:_cons])^4 + xrd5 * (1-_b[delta:_cons])^5+ xrd6 * (1-_b[delta:_cons])^6+ xrd7 * (1-_b[delta:_cons])^7+xrd8 * (1-_b[delta:_cons])^8+ xrd9 * (1-_b[delta:_cons])^9 + xrd10 * (1-_b[delta:_cons])^10  if Industry==4

replace Organizational_Cap = (_b[gamma:_cons])*xsga1*(1-0.2)+(_b[gamma:_cons])*xsga2*(1-0.2)^2+(_b[gamma:_cons])*xsga3*(1-0.2)^3+(_b[gamma:_cons])*xsga4*(1-0.2)^4+(_b[gamma:_cons])*xsga5*(1-0.2)^5+(_b[gamma:_cons])*xsga6*(1-0.2)^6+(_b[gamma:_cons])*xsga7*(1-0.2)^7+(_b[gamma:_cons])*xsga8*(1-0.2)^8+(_b[gamma:_cons])*xsga9*(1-0.2)^9+(_b[gamma:_cons])*xsga10*(1-0.2)^10 if Industry==4

estimates restore _5
replace Knowledge_Cap = xrd1*(1-_b[delta:_cons]) + xrd2 *(1-_b[delta:_cons])^2 + xrd3 * (1-_b[delta:_cons])^3 + xrd4 * (1-_b[delta:_cons])^4 + xrd5 * (1-_b[delta:_cons])^5+ xrd6 * (1-_b[delta:_cons])^6+ xrd7 * (1-_b[delta:_cons])^7+xrd8 * (1-_b[delta:_cons])^8+ xrd9 * (1-_b[delta:_cons])^9 + xrd10 * (1-_b[delta:_cons])^10  if Industry==5

replace Organizational_Cap = (_b[gamma:_cons])*xsga1*(1-0.2)+(_b[gamma:_cons])*xsga2*(1-0.2)^2+(_b[gamma:_cons])*xsga3*(1-0.2)^3+(_b[gamma:_cons])*xsga4*(1-0.2)^4+(_b[gamma:_cons])*xsga5*(1-0.2)^5+(_b[gamma:_cons])*xsga6*(1-0.2)^6+(_b[gamma:_cons])*xsga7*(1-0.2)^7+(_b[gamma:_cons])*xsga8*(1-0.2)^8+(_b[gamma:_cons])*xsga9*(1-0.2)^9+(_b[gamma:_cons])*xsga10*(1-0.2)^10 if Industry==5

gen intan_internal = Organizational_Cap + Knowledge_Cap
gen intan_total = intan_internal + intan

gen Adj_Bookvalue = at + intan_internal 
gen Bookvalue = at
gen Marketvalue = mkvalt + lt+ pstk

* Update cleaned_data
save "cleaned_data", replace

* Collapse intangible capital data yearly per industry
drop if Industry != 1
collapse (mean) intan_total intan intan_internal Organizational_Cap Knowledge_Cap at ppegt Adj_Bookvalue Bookvalue Marketvalue, by(fyear)
gen Industry=1
save collapse_1.dta, replace

use "cleaned_data", clear
drop if Industry != 2
collapse (mean) intan_total intan intan_internal Organizational_Cap Knowledge_Cap at ppegt Adj_Bookvalue Bookvalue Marketvalue, by(fyear)
gen Industry=2
save collapse_2.dta, replace

use "cleaned_data", clear
drop if Industry != 3
collapse (mean) intan_total intan intan_internal Organizational_Cap Knowledge_Cap at ppegt Adj_Bookvalue Bookvalue Marketvalue, by(fyear)
gen Industry=3
save collapse_3.dta, replace

use "cleaned_data", clear
drop if Industry != 4
collapse (mean) intan_total intan intan_internal Organizational_Cap Knowledge_Cap at ppegt Adj_Bookvalue Bookvalue Marketvalue, by(fyear)
gen Industry=4
save collapse_4.dta, replace

use "cleaned_data", clear
drop if Industry != 5
collapse (mean) intan_total intan intan_internal Organizational_Cap Knowledge_Cap at ppegt Adj_Bookvalue Bookvalue Marketvalue, by(fyear)
gen Industry=5
save collapse_5.dta, replace

append using "collapse_1" "collapse_2" "collapse_3" "collapse_4"
save collapse_all.dta, replace
summarize

* Graph out the intangible asset intensity (adjusted and non-adjusted)
sort fyear
gen Adj_intan_intensity = intan_total/(intan_total+ppegt)
by fyear: egen M_Adj_intan_intensity = mean(Adj_intan_intensity)
gen intan_intensity = intan/(intan+ppegt)
by fyear: egen M_intan_intensity = mean(intan_intensity)

line M_Adj_intan_intensity fyear || line M_intan_intensity fyear

gen Adj_intan_intensity_1 = Adj_intan_intensity if Industry==1
gen Adj_intan_intensity_2 = Adj_intan_intensity if Industry==2
gen Adj_intan_intensity_3 = Adj_intan_intensity if Industry==3
gen Adj_intan_intensity_4 = Adj_intan_intensity if Industry==4
gen Adj_intan_intensity_5 = Adj_intan_intensity if Industry==5

line Adj_intan_intensity_1 fyear || line Adj_intan_intensity_2 fyear || line Adj_intan_intensity_3 fyear || line Adj_intan_intensity_4 fyear || line Adj_intan_intensity_5 fyear

* Graph the proportion of internally generated intangibles
gen internal_intensity = intan_internal/intan_total
by fyear: egen M_internal_intensity = mean(internal_intensity)

gen internal_intensity_1 = internal_intensity if Industry==1
gen internal_intensity_2 = internal_intensity if Industry==2
gen internal_intensity_3 = internal_intensity if Industry==3
gen internal_intensity_4 = internal_intensity if Industry==4
gen internal_intensity_5 = internal_intensity if Industry==5

line M_internal_intensity fyear 

line internal_intensity_1 fyear || line internal_intensity_2 fyear || line internal_intensity_3 fyear || line internal_intensity_4 fyear || line internal_intensity_5 fyear

* Graph the proportion of internal intangible subcapital
gen knowledge_intensity = Knowledge_Cap/intan_total
by fyear: egen M_knowledge_intensity = mean(knowledge_intensity)
gen Organizational_intensity = Organizational_Cap/intan_total
by fyear: egen M_Organizational_intensity = mean(Organizational_intensity)

gen knowledge_intensity_1 = knowledge_intensity if Industry==1
gen knowledge_intensity_2 = knowledge_intensity if Industry==2
gen knowledge_intensity_3 = knowledge_intensity if Industry==3
gen knowledge_intensity_4 = knowledge_intensity if Industry==4
gen knowledge_intensity_5 = knowledge_intensity if Industry==5

gen Organizational_intensity_1 = Organizational_intensity if Industry==1
gen Organizational_intensity_2 = Organizational_intensity if Industry==2
gen Organizational_intensity_3 = Organizational_intensity if Industry==3
gen Organizational_intensity_4 = Organizational_intensity if Industry==4
gen Organizational_intensity_5 = Organizational_intensity if Industry==5

line M_knowledge_intensity fyear || line M_Organizational_intensity fyear

line knowledge_intensity_1 fyear || line knowledge_intensity_2 fyear || line knowledge_intensity_3 fyear || line knowledge_intensity_4 fyear || line knowledge_intensity_5 fyear

line Organizational_intensity_1 fyear || line Organizational_intensity_2 fyear || line Organizational_intensity_3 fyear || line Organizational_intensity_4 fyear || line Organizational_intensity_5 fyear

* Save the collapsed time series data file
save collapse_all.dta, replace

// V - Testing the overall performance of the intangible capitalization approach //
use "cleaned_data", clear
xtset gvkey fyear

* Compare how book value and adjusted book value of assets compare to total market value

replace Adj_Bookvalue = at + intan_total 
replace Bookvalue = at

xtreg Marketvalue Bookvalue
outreg2 validation_results.doc, replace
estimates store bookvalue

xtreg Marketvalue Adj_Bookvalue
outreg2 validation_results.doc, append
estimates store adjusted_bookvalue

xtreg Marketvalue Bookvalue if fyear>2010
outreg2 validation_results.doc, append
estimates store bookvalue_post2010

xtreg Marketvalue Adj_Bookvalue if fyear>2010
outreg2 validation_results.doc, append
estimates store adjusted_bookvalue_post2010

xtreg Marketvalue Bookvalue if fyear<2000
outreg2 validation_results.doc, append
estimates store bookvalue_pre2000

xtreg Marketvalue Adj_Bookvalue if fyear<2000
outreg2 validation_results.doc, append
estimates store adjusted_bookvalue_pre2000

coefplot bookvalue_post2010 adjusted_bookvalue_post2010 bookvalue_pre2000 adjusted_bookvalue_pre2000, drop(_cons) xline(1, lcolor (grey) lwidth(thin) lpatter(dash)) xlabel(0, add) mlabel format (%9.2f) mlabposition(12) mlabgap(*2) byopts(xrescale) xscale(log)

* Longitudinal analysis of tobin's q ratio (with and without intangible capital)

use collapse_all.dta, clear
gen tq = Marketvalue/Bookvalue
gen Adj_tq = Marketvalue/Adj_Bookvalue

by fyear: egen M_tq = mean(tq)
by fyear: egen M_Adj_tq = mean(Adj_tq)

line M_tq fyear || line M_Adj_tq fyear


// VI - Case of Internet companies //

* Creating a categorical variable for internet to identify internet companies (source:)
gen Internet = 1 if ticker == GOOG | AMZN | TCEHY | META | BABA | 3690.HK | JD | NOW | PYPL | PDD | BKNG | NF



// VII - Further robustness tests //

// Longitudinal analysis of the parameter estimates
use cleaned_data, clear

* Compare sample size beginning and end period
drop if Y<=0
by fyear, sort:summarize Y

* Run the estimation regression for beggining and end of period: before 1988 and in 2017

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42)+log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if fyear<1988, noconstant

estimates store prev_1988

count if fyear<1988

nl (lnY = {rho}*log((rho_dummy1+rho_dummy2+rho_dummy3+rho_dummy4+rho_dummy5+rho_dummy6+rho_dummy7+rho_dummy8+rho_dummy9+rho_dummy10+rho_dummy11+rho_dummy12+rho_dummy13+rho_dummy14+rho_dummy15+rho_dummy16+rho_dummy17+rho_dummy18+rho_dummy19+rho_dummy20+rho_dummy21+rho_dummy22+rho_dummy23+rho_dummy24+rho_dummy25+rho_dummy26+rho_dummy27+rho_dummy28+rho_dummy29+rho_dummy30+rho_dummy31+rho_dummy32+rho_dummy33+rho_dummy34+rho_dummy35+rho_dummy36+rho_dummy37+rho_dummy38+rho_dummy39+rho_dummy40+rho_dummy41+rho_dummy42)*42)+log(intan + xrd1*(1-{delta}) + xrd2 *(1-{delta})^2 + xrd3 * (1-{delta})^3 + xrd4 * (1-{delta})^4 + xrd5 * (1-{delta})^5+ xrd6 * (1-{delta})^6+ xrd7 * (1-{delta})^7+xrd8 * (1-{delta})^8+ xrd9 * (1-{delta})^9 + xrd10 * (1-{delta})^10 + ({gamma})*xsga1*(1-0.2)+({gamma})*xsga2*(1-0.2)^2+({gamma})*xsga3*(1-0.2)^3+({gamma})*xsga4*(1-0.2)^4+({gamma})*xsga5*(1-0.2)^5+({gamma})*xsga6*(1-0.2)^6+({gamma})*xsga7*(1-0.2)^7+({gamma})*xsga8*(1-0.2)^8+({gamma})*xsga9*(1-0.2)^9+({gamma})*xsga10*(1-0.2)^10 + 1)) if fyear==2017, noconstant

estimates store current_year

* Display the difference in magnitude (full sample, per industry)

estimates table current_year prev_1988

coefplot prev_1988 || current_year, drop(rho:_cons) bycoefs byopts(xrescale) xscale(log range(-0.8 1.5)) xline(0, lcolor (grey) lwidth(thin) lpatter(dash)) xlabel(0, add) mlabel format (%9.2f) mlabposition(12) mlabgap(*2) coeflabel(gamma:_cons = "Fraction of SG&A", wrap(20) labsize(medlarge) labcolor(black)) graphregion(fcolor(white)) title ("{bf:Fraction of SG&A before 1988 and now}") ciopts(recast(rcap))








