* =============================================================================
* 05_data_assembly.do
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: Import weekly virologic and weather exposure data; merge with
*          weekly strep count dataset; construct panel structure; normalize
*          SARS-CoV-2 and respiratory virus exposures to SD units
*
* Input:  collapsed_weekly_groupastrep.dta
*         Updated daily virologic and weather exposure file REVISED.dta
* Output: analysis_dataset.dta (panel-ready, with all exposures)
*
* Variable notes:
*   adj_sars_cases = test-adjusted SARS-CoV-2 case counts (Pandemic Period 1)
*                    see Fisman et al. Ann Intern Med 2021; Bosco et al. 2025
*   prop_sars2     = SARS-CoV-2 percent positivity (Pandemic Period 2)
*   prop_flua/b    = influenza A/B percent positivity (RVDSS)
*   prop_rsv       = RSV percent positivity (RVDSS)
*   prop_flu       = combined influenza percent positivity
* =============================================================================


* =============================================================================
* SECTION 1: AGGREGATE EXPOSURE DATA TO WEEKLY
* =============================================================================

* Daily exposure file contains virologic surveillance + weather variables
use "Updated daily virologic and weather exposure file REVISED.dta", clear

* Collapse daily to weekly means
collapse (mean) relhum temp precip abshum max_uvi ///
    prop_flub prop_flua prop_rsv prop_flu prop_sars2 adj_sars_cases, ///
    by(week year)

sort week year
save "Updated daily virologic and weather exposure file weekly.dta", replace
clear


* =============================================================================
* SECTION 2: MERGE WEEKLY STREP COUNTS WITH EXPOSURE DATA
* =============================================================================

use "collapsed_weekly_groupastrep.dta", clear
sort week year
merge week year using "Updated daily virologic and weather exposure file weekly.dta"
drop _merge
sort age2 gender2 week year


* =============================================================================
* SECTION 3: PANEL STRUCTURE
* =============================================================================

* Panel ID: age group nested within sex
* age2 = 1 (0-19), 2 (20-64), 3 (65+)
* gender2 = 1 (female), 2 (male)
* Panels 1-3: female age groups; Panels 4-6: male age groups

gen panel = age2 if gender2 == 1
replace panel = age2 + 3 if gender2 > 1

* Declare panel time series
xtset panel series_week


* =============================================================================
* SECTION 4: NORMALIZE SARS-CoV-2 EXPOSURE
* =============================================================================

* Two metrics used across the study period:
*   Period 1 (Mar 2020 - Aug 2022): test-adjusted case counts (adj_sars_cases)
*   Period 2 (Sep 2022 - Mar 2024): percent positivity (prop_sars2)
* Each normalized to its own study-period SD

* Period 1 SD (calculated over weeks when adj_sars_cases is non-missing)
egen sd_adj_sars  = sd(adj_sars_cases) if adj_sars_cases ~= .
* Period 2 SD
egen sd_prop_sars = sd(prop_sars2)     if prop_sars2 ~= .

* Construct unified normalized SARS-CoV-2 variable
* norm_sars = 0 pre-pandemic; Period 1 from test-adjusted cases; Period 2 from %pos
gen norm_sars = adj_sars_cases / sd_adj_sars if adj_sars_cases ~= .
replace norm_sars = prop_sars2 / sd_prop_sars if prop_sars2 ~= .


* =============================================================================
* SECTION 5: NORMALIZE OTHER RESPIRATORY VIRUS EXPOSURES
* =============================================================================

* Study-period SDs for each virus
egen sd_rsv  = sd(prop_rsv)
egen sd_flua = sd(prop_flua)
egen sd_flub = sd(prop_flub)
egen sd_flu  = sd(prop_flu)

* Normalized exposures (SD units; baseline RR=1.0 at zero viral activity)
gen norm_rsv  = prop_rsv  / sd_rsv
gen norm_flua = prop_flua / sd_flua
gen norm_flub = prop_flub / sd_flub
gen norm_flu  = prop_flu  / sd_flu


* =============================================================================
* SECTION 6: ADDITIONAL VARIABLES
* =============================================================================

* All-strep offset (add 0.5 to avoid log(0) in invasion propensity analyses)
gen week_all_strep_2 = week_all_strep + 0.5

* Pandemic period indicators
gen pandemic1 = 0
replace pandemic1 = 1 if date >= date("March 1, 2020",    "MD20Y")
gen pandemic2 = 0
replace pandemic2 = 1 if date >= date("September 1, 2022", "MD20Y")
replace pandemic1 = 0 if pandemic2 == 1   // mutually exclusive

* School closure indicator (Ontario, Dec 2020 - May 2021)
gen school_closed = 1 if date >= date("December 20, 2020", "MD20Y") ///
                       & date <= date("May 15, 2021",      "MD20Y")
replace school_closed = 0 if school_closed == .

* Flu B × SARS-CoV-2 interaction term
gen flub_sars = norm_flub * norm_sars

sort age2 gender2 week year
save "analysis_dataset.dta", replace
