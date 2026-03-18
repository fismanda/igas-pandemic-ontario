* =============================================================================
* 06_variable_construction.do
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: Construct lagged and cumulative exposure variables for all
*          respiratory viruses and streptococcal outcomes
*
* Input:  analysis_dataset.dta
* Output: analysis_dataset.dta (updated in place)
*
* NOTE: All lag and cumulative variables constructed manually using panel-safe
*       approaches (not Stata's L. operator) to ensure correct panel boundaries.
*       Combined influenza cumulative uses preserve/restore/tempfile approach
*       to avoid a between-panel variation bug.
* =============================================================================

use "analysis_dataset.dta", clear


* =============================================================================
* SECTION 1: SARS-CoV-2 LAGGED AND CUMULATIVE VARIABLES
* =============================================================================

* Cumulative SARS-CoV-2 burden (running sum from pandemic onset, by panel)
sort pandemic panel series_week
gen cum_norm_sars = norm_sars if panel ~= panel[_n-1] & pandemic == 1
replace cum_norm_sars = cum_norm_sars[_n-1] + norm_sars ///
    if cum_norm_sars == . & panel == panel[_n-1] & pandemic == 1

* 2-week lagged SARS-CoV-2 (manually constructed, panel-safe)
sort pandemic panel
gen l2_norm_sars = norm_sars[_n-2] if panel == panel[_n-2] & pandemic == 1


* =============================================================================
* SECTION 2: INFLUENZA A — LAGGED AND CUMULATIVE
* =============================================================================

sort pandemic panel series_week
gen cum_norm_flua = norm_flua if panel ~= panel[_n-1] & pandemic == 1
replace cum_norm_flua = cum_norm_flua[_n-1] + norm_flua ///
    if cum_norm_flua == . & panel == panel[_n-1] & pandemic == 1

* 2-week lag — pandemic and pre-pandemic periods
sort pandemic panel series_week
gen l2_norm_flua = norm_flua[_n-2] if panel == panel[_n-2] & pandemic == 1
replace l2_norm_flua = norm_flua[_n-2] if panel == panel[_n-2] & pandemic == 0


* =============================================================================
* SECTION 3: INFLUENZA B — LAGGED AND CUMULATIVE
* =============================================================================

sort pandemic panel series_week
gen cum_norm_flub = norm_flub if panel ~= panel[_n-1] & pandemic == 1
replace cum_norm_flub = cum_norm_flub[_n-1] + norm_flub ///
    if cum_norm_flub == . & panel == panel[_n-1] & pandemic == 1

sort pandemic panel
gen l2_norm_flub = norm_flub[_n-2] if panel == panel[_n-2] & pandemic == 1
sort pandemic panel series_week
replace l2_norm_flub = norm_flub[_n-2] if panel == panel[_n-2] & pandemic == 0


* =============================================================================
* SECTION 4: COMBINED INFLUENZA — CUMULATIVE (preserve/restore approach)
*
* NOTE: The standard panel-loop approach produced a between-panel variation bug
*       for combined influenza. Fix: reduce to one observation per date (since
*       norm_flu does not vary by panel), compute running sum, save as tempfile,
*       then merge back into full panel dataset.
* =============================================================================

drop _merge
preserve
    keep if pandemic == 1
    bysort date: keep if _n == 1          // one obs per date
    keep date norm_flu
    sort date
    gen cum_norm_flu = sum(norm_flu)      // running cumulative sum
    keep date cum_norm_flu
    tempfile cumflu
    save `cumflu'
restore
merge m:1 date using `cumflu'

* 2-week lag for combined flu — pandemic and pre-pandemic
sort pandemic panel series_week
gen l2_norm_flu = norm_flu[_n-2] if panel == panel[_n-2] & pandemic == 1
sort pandemic panel series_week
replace l2_norm_flu = norm_flu[_n-2] if panel == panel[_n-2] & pandemic == 0


* =============================================================================
* SECTION 5: RSV — LAGGED AND CUMULATIVE
* =============================================================================

sort pandemic panel series_week
gen cum_norm_rsv = norm_rsv if panel ~= panel[_n-1] & pandemic == 1
replace cum_norm_rsv = cum_norm_rsv[_n-1] + norm_rsv ///
    if cum_norm_rsv == . & panel == panel[_n-1] & pandemic == 1

sort pandemic panel series_week
gen l2_norm_rsv = norm_rsv[_n-2] if panel == panel[_n-2] & pandemic == 1
sort pandemic panel series_week
replace l2_norm_rsv = norm_rsv[_n-2] if panel == panel[_n-2] & pandemic == 0


* =============================================================================
* SECTION 6: CUMULATIVE STREPTOCOCCAL EXPOSURE (IMMUNITY DEBT TEST)
*
* Three formulations — used to test whether prior strep exposure is protective
* Immunity debt hypothesis predicts IRR < 1; observed: null or positive
* =============================================================================

sort pandemic panel series_week

* Cumulative invasive GAS
gen cum_igas = week_igas if panel ~= panel[_n-1] & pandemic == 1
replace cum_igas = cum_igas[_n-1] + week_igas ///
    if cum_igas == . & panel == panel[_n-1] & pandemic == 1

* Cumulative all strep
gen cum_all_strep = week_all_strep if panel ~= panel[_n-1] & pandemic == 1
replace cum_all_strep = cum_all_strep[_n-1] + week_all_strep ///
    if cum_all_strep == . & panel == panel[_n-1] & pandemic == 1

* Cumulative non-invasive strep
gen cum_non_inv = week_non_inv if panel ~= panel[_n-1] & pandemic == 1
replace cum_non_inv = cum_non_inv[_n-1] + week_non_inv ///
    if cum_non_inv == . & panel == panel[_n-1] & pandemic == 1


* =============================================================================
* SECTION 7: ADDITIONAL VARIABLES
* =============================================================================

* Scaled test-adjusted SARS-CoV-2 cases (per 1000 for numerical stability)
gen adj_sars1000 = adj_sars_cases / 1000

* Age-group indicator variables
gen kid        = 0
replace kid    = 1 if age2 == 1
gen middle_age = 0
replace middle_age = 1 if age2 == 2
gen old        = 0
replace old    = 1 if age2 == 3

* Age x SARS-CoV-2 interaction terms
gen interact_kid    = kid        * norm_sars
gen interact_middle = middle_age * norm_sars
gen interact_old    = old        * norm_sars

sort age2 gender2 series_week
save "analysis_dataset.dta", replace
