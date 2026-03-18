* =============================================================================
* PSEUDOCODE: SARS-CoV-2 and the Late Pandemic Surge in Invasive Group A
* Streptococcal Disease: A 13-Year Population-Based Study
*
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* NOTE: This pseudocode describes the analytic approach. Actual code was
* executed within the CIHI Secure Access Environment (SAE) and cannot be
* shared with individual-level data. Respiratory virus surveillance data
* are publicly available from PHAC (see Data Availability statement).
*
* Software: Stata 17 (StataCorp, College Station TX)
* Analysis period: March 29, 2011 – March 28, 2024 (676 weeks)
* Study region: Greater Toronto-Hamilton Area Plus (GTHA+), Ontario, Canada
* =============================================================================


* =============================================================================
* SECTION 1: DATA ASSEMBLY
* =============================================================================

* --- 1.1 iGAS Case Ascertainment (DAD) ---------------------------------------
*
* Source: CIHI Discharge Abstract Database (DAD)
* Import raw data and clean diagnosis fields (trim, uppercase)

import delimited "dad_full.csv", clear

* Clean all diagnosis fields
foreach v of varlist diag_code_1-diag_code_25 {
    replace `v' = trim(upper(`v'))
}

* Step 1: Flag B95.0 (GAS modifier) across all 25 fields
* foreach loop works cleanly for single-code flags
gen byte b950_any = 0
foreach v of varlist diag_code_1-diag_code_25 {
    replace b950_any = 1 if `v' == "B950"
}

* Step 2: Flag invasive syndromes across all 25 fields
* NOTE: foreach loop with multiple OR conditions did not execute correctly
* in the SAE environment; brute-force replace used instead (25 lines per field)
* Invasive syndrome codes: A400, G002, M722, M726, J390, J391, J392,
*                          J860, J869, M000, M002, I330, A481
gen byte invasive_any = 0
replace invasive_any = 1 if (diag_code_1=="A400" | diag_code_1=="G002" | ///
    diag_code_1=="M722" | diag_code_1=="M726" | diag_code_1=="J860" | ///
    diag_code_1=="J869" | diag_code_1=="M000" | diag_code_1=="M002" | ///
    diag_code_1=="I330")
* [Repeated for diag_code_2 through diag_code_25 — identical logic]

* Step 3: Flag A40.0 (GAS sepsis — always iGAS by definition)
* foreach loop works for this single-code flag
gen byte igas = 0
foreach v of varlist diag_code_1-diag_code_25 {
    replace igas = 1 if `v' == "A400"
}

* Step 4: Extend iGAS definition to invasive syndrome + B95.0
replace igas = 1 if igas == 0 & (invasive_any == 1 & b950_any == 1)


* --- 1.2 Non-Invasive Streptococcal Disease (DAD) ----------------------------
*
* Requirement: B95.0 in any field (confirms GAS etiology)
* Exclusion: records meeting iGAS criteria excluded at end
*
* NOTE: All non-invasive syndrome flags use brute-force replace across
* all 25 fields (same pattern as invasive_any above)

* Pharyngitis (J02.x, J03.x)
gen byte pharyngitis = 0
replace pharyngitis = 1 if inlist(diag_code_1, "J02","J020","J021","J022", ///
    "J028","J029","J030","J03090","J03091")
* [Repeated for diag_code_2 through diag_code_25]
replace pharyngitis = 0 if igas == 1   // exclude iGAS records

* Tracheitis/Laryngitis (J39.0, J39.1, J39.2)
gen byte tracheitis = 0
replace tracheitis = 1 if inlist(diag_code_1, "J390","J391","J392")
* [Repeated for diag_code_2 through diag_code_25]

* Otitis media (H65, H66, H67)
gen byte otitis = 0
replace otitis = 1 if inlist(diag_code_1, "H65","H650","H660","H662", ///
    "H669","H671","H672","H673")
* [Repeated for diag_code_2 through diag_code_25]
replace otitis = 0 if igas == 1

* Cellulitis (L03.x)
gen byte cellulitis = 0
replace cellulitis = 1 if inlist(diag_code_1, "L030","L031","L032","L033", ///
    "L034","L035","L036","L038","L039")
* [Repeated for diag_code_2 through diag_code_25]

* Combined pharyngitis/otitis variable
gen phar_otit = 1 if pharyng + otitis > 0
replace phar_otit = 0 if phar_otit == .

* Non-invasive strep flag (any of the above + B95.0, excluding iGAS)
gen non_invasive = 0
replace non_invasive = 1 if (pharyngitis==1 | tracheitis==1 | ///
    otitis==1 | cellulitis==1) & b950_any==1 & igas==0


* --- 1.3 All Streptococcal Disease (DAD) ------------------------------------
*
* Definition: any record with B95.0 in any field, OR any iGAS record
* The second condition captures A40.0 cases that lack B95.0 coding
* Used as denominator in invasion propensity analyses (Section 8)

gen all_strep = 0
replace all_strep = 1 if b950_any == 1
replace all_strep = 1 if b950_any == 0 & igas == 1

* Tag data source and save strep-only file
gen source = "DAD"
keep if all_strep == 1
save "dad_all_strep.dta", replace
clear


* --- 1.4 iGAS Case Ascertainment (NACRS) -------------------------------------
*
* Source: CIHI National Ambulatory Care Reporting System (NACRS)
* 10 diagnosis fields: main_problem + other_problem_1 through other_problem_9
* NOTE: Field names differ from DAD (main_problem/other_problem_N vs diag_code_N)

import delimited "nacrs_full.csv", clear

* Clean diagnosis fields
foreach v of varlist main_problem other_problem_1-other_problem_9 {
    replace `v' = trim(upper(`v'))
}

* Flag B95.0 — foreach loop works for single-code flag
gen byte b950_any = 0
foreach v of varlist main_problem other_problem_1-other_problem_9 {
    replace b950_any = 1 if `v' == "B950"
}

* Flag invasive syndromes — brute force (nested loop with local macro did not work)
gen byte invasive_any = 0
replace invasive_any = 1 if (main_problem=="A400" | main_problem=="G002" | ///
    main_problem=="M722" | main_problem=="M726" | main_problem=="J860" | ///
    main_problem=="J869" | main_problem=="M000" | main_problem=="M002" | ///
    main_problem=="I330")
replace invasive_any = 1 if (other_problem_1=="A400" | other_problem_1=="G002" | ///
    other_problem_1=="M722" | other_problem_1=="M726" | other_problem_1=="J860" | ///
    other_problem_1=="J869" | other_problem_1=="M000" | other_problem_1=="M002" | ///
    other_problem_1=="I330")
* [Repeated for other_problem_2 through other_problem_9 — identical logic]

* Flag A40.0 (GAS sepsis) — foreach loop works for single-code flag
gen byte igas = 0
foreach v of varlist main_problem other_problem_1-other_problem_9 {
    replace igas = 1 if `v' == "A400"
}
replace igas = 1 if igas == 0 & (invasive_any == 1 & b950_any == 1)

* Non-invasive syndromes — brute force across main_problem + other_problem_1-9

* Pharyngitis (J02.x, J03.x)
gen byte pharyngitis = 0
replace pharyngitis = 1 if inlist(main_problem,"J02","J020","J021","J022", ///
    "J028","J029","J030","J03090","J03091")
replace pharyngitis = 1 if inlist(other_problem_1,"J02","J020","J021","J022", ///
    "J028","J029","J030","J03090","J03091")
* [Repeated for other_problem_2 through other_problem_9]
replace pharyngitis = 0 if igas == 1

* Otitis media (H65, H66, H67)
gen byte otitis = 0
replace otitis = 1 if inlist(main_problem,"H65","H650","H660","H662", ///
    "H669","H671","H672","H673")
replace otitis = 1 if inlist(other_problem_1,"H65","H650","H660","H662", ///
    "H669","H671","H672","H673")
* [Repeated for other_problem_2 through other_problem_9]
replace otitis = 0 if igas == 1

* Cellulitis (L03.x)
gen byte cellulitis = 0
replace cellulitis = 1 if inlist(main_problem,"L030","L031","L032","L033", ///
    "L034","L035","L036","L038","L039")
replace cellulitis = 1 if inlist(other_problem_1,"L030","L031","L032","L033", ///
    "L034","L035","L036","L038","L039")
* [Repeated for other_problem_2 through other_problem_9]

* Tracheitis/Laryngitis (J39.0-J39.2)
gen byte tracheitis = 0
replace tracheitis = 1 if inlist(main_problem,"J390","J391","J392")
replace tracheitis = 1 if inlist(other_problem_1,"J390","J391","J392")
* [Repeated for other_problem_2 through other_problem_9]
replace tracheitis = 0 if igas == 1

* All strep, phar_otit, date, source flag
gen all_strep = 0
replace all_strep = 1 if b950_any == 1
replace all_strep = 1 if b950_any == 0 & igas == 1

gen phar_otit = 1 if pharyng + otitis > 0
replace phar_otit = 0 if phar_otit == .

gen date = date(date_of, "20YMD")
format date %d

gen source = "NACRS"
drop submitting
keep if all_strep == 1
save "nacrs_all_strep.dta", replace
clear


* --- 1.5 Cross-Database Deduplication ----------------------------------------
*
* Append DAD and NACRS into single master dataset
* Retain only the FIRST encounter per person (by encrypted ID and date)
* Yields one episode per person across the entire study period
* Episode date = date of first recorded healthcare contact with strep diagnosis

* Combine both databases
use "nacrs_all_strep.dta"
append using "dad_all_strep.dta"
save "all_strep.dta", replace

* Sort by encrypted person ID (mbun) and encounter date
* Flag first encounter per person
gen byte first = 0
by mbun date, sort: replace first = 1 if _n == 1

* Flag duplicate encounters (same person, >1 record — for accounting)
by mbun date, sort: gen dup = 1 if mbun == mbun[_n-1]

* Identify people appearing in BOTH DAD and NACRS (for accounting only)
* e.g. ED visit (NACRS) followed by hospital admission (DAD) for same episode
gen both = 0
by mbun date, sort: replace both = 1 if mbun == mbun[_n-1] & source ~= source[_n-1]
by mbun date, sort: egen both2 = max(both)

* Retain only first encounter per person
keep if first == 1
save "all_strep_no_duplicates.dta", replace


* --- 1.5 Cross-Database Deduplication ----------------------------------------
*
* Problem: same patient may appear in both DAD (admission) and NACRS (ED visit)
* Solution: link records by encrypted unique identifier, retain first encounter

* Sort combined DAD+NACRS file by person ID and encounter date
sort encrypted_id encounter_date

* Keep only the first encounter per person across the entire study period
* This yields one episode per person; episode date = first healthcare contact
by encrypted_id: keep if _n == 1


* --- 1.6 Aggregate to Weekly Time Series -------------------------------------
*
* Aggregate individual-level records to weekly counts
* Stratify by: age group (0-19, 20-64, ≥65) and sex (male, female)
* Yields 6 age-sex panels × 676 weeks

* Create week variable (surveillance weeks run Sunday-Saturday)
generate week = wofd(encounter_date)

* Create age groups
generate age_group = 1 if age < 20        // 0-19 years
replace  age_group = 2 if age >= 20 & age < 65  // 20-64 years
replace  age_group = 3 if age >= 65       // ≥65 years

* Collapse to weekly counts per stratum
collapse (sum) week_igas week_non_inv week_all_strep, ///
    by(week age_group sex)


* =============================================================================
* SECTION 2: POPULATION DENOMINATORS
* =============================================================================

* Annual population estimates from Statistics Canada (Table 17-10-0009-01)
* Stratified by age group and sex for each PHU in GTHA+
* Aggregated across all 14 PHUs to GTHA+ totals
* Annual counts interpolated to weekly estimates (divide by 52)

* For regression offset: log(weekly_population)
generate ln_week_pop = log(week_pop)

* For incidence rate models: use annualized population as exposure
* (offset = log(week_pop) where week_pop = annual_pop / 52)


* =============================================================================
* SECTION 3: RESPIRATORY VIRUS EXPOSURE VARIABLES
* =============================================================================

* --- 3.1 SARS-CoV-2, Pandemic Period 1 (Mar 2020 – Aug 2022) ----------------
*
* Source: Ontario Case and Contact Management System (CCM)
* Method: test-adjusted case counts using age-sex standardization
*   (see Fisman et al. Ann Intern Med 2021; Bosco et al. BMC Infect Dis 2025)
* Adjustment accounts for differential testing rates by age and sex

* Standardized weekly SARS-CoV-2 exposure (Period 1)
generate sars2_p1 = test_adjusted_cases_p1 / sd_sars2_p1


* --- 3.2 SARS-CoV-2, Pandemic Period 2 (Sep 2022 – Mar 2024) ----------------
*
* Source: Public Health Agency of Canada, Respiratory Virus Detection
*         Surveillance System (RVDSS) – percent positivity
* Normalized by study-period standard deviation

generate sars2_p2 = pct_positive_sars2 / sd_sars2_p2


* --- 3.3 Influenza A, Influenza B, RSV (full study period) ------------------
*
* Source: RVDSS percent positivity data (2011-2024)
* Normalized by study-period standard deviation for each virus

generate flu_a_std  = flu_a_pct_pos  / sd_flu_a
generate flu_b_std  = flu_b_pct_pos  / sd_flu_b
generate rsv_std    = rsv_pct_pos    / sd_rsv
generate flu_ab_std = flu_ab_pct_pos / sd_flu_ab   // combined for pandemic period

* NOTE: All viral exposures normalized to SD units to allow comparison across
* pathogens and across periods with different surveillance metrics.
* Baseline RR=1.0 corresponds to zero viral circulation.


* --- 3.4 Acute Exposure with 2-Week Lag --------------------------------------
*
* Based on expected interval between respiratory viral infection and
* secondary bacterial disease onset (refs 18-21 in manuscript)

tsset panel_id week
generate sars2_lag2    = L2.sars2_combined   // 2-week lag
generate flu_a_lag2    = L2.flu_a_std
generate flu_b_lag2    = L2.flu_b_std
generate rsv_lag2      = L2.rsv_std
generate flu_ab_lag2   = L2.flu_ab_std


* --- 3.5 Cumulative SARS-CoV-2 Burden ----------------------------------------
*
* Running sum of standardized weekly SARS-CoV-2 exposure from March 2020
* Operationalizes hypothesis of progressive immune dysfunction from
* repeated/cumulative population-level COVID-19 exposure

generate sars2_cumulative = 0
replace  sars2_cumulative = sum(sars2_combined) if week >= pandemic_start_week

* Also construct cumulative streptococcal exposure (for immunity debt test)
generate strep_cum_invasive   = sum(week_igas)     if week >= pandemic_start_week
generate strep_cum_noninv     = sum(week_non_inv)  if week >= pandemic_start_week
generate strep_cum_total      = sum(week_all_strep) if week >= pandemic_start_week

* Normalize cumulative variables by their standard deviations
foreach var of varlist sars2_cumulative strep_cum_* {
    summarize `var'
    replace `var' = `var' / r(sd)
}


* =============================================================================
* SECTION 4: SEASONAL ADJUSTMENT (FOURIER TERMS)
* =============================================================================

* Fourier harmonic terms for annual seasonality (ω = 2π/52)
* These capture predictable seasonal oscillations in iGAS incidence
* Critical: without these, respiratory virus effects are confounded by
*           shared winter seasonality (demonstrated in pre-pandemic analyses)

local pi = 3.14159265358979
generate sin1 = sin(2 * `pi' * week_of_year / 52)
generate cos1 = cos(2 * `pi' * week_of_year / 52)
generate sin2 = sin(4 * `pi' * week_of_year / 52)
generate cos2 = cos(4 * `pi' * week_of_year / 52)

* Also include quadratic secular time trend
generate time_linear    = week - first_week
generate time_quadratic = time_linear^2


* =============================================================================
* SECTION 5: PRIMARY ANALYSES – PANEL NEGATIVE BINOMIAL REGRESSION
* =============================================================================

* Panel structure: 6 age-sex strata (3 age groups × 2 sexes)
* Command: xtnbreg (Stata panel negative binomial)
* Offset: log(weekly population)
* Fixed effects for age-sex panels

xtset panel_id week


* --- 5.1 Pre-Pandemic Baseline (March 2011 – February 2020) -----------------
*
* Establishes expected iGAS patterns before SARS-CoV-2
* Used to characterize pre-pandemic seasonality and secular trends

xtnbreg week_igas ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    i.age_group i.sex ///
    , exposure(week_pop) fe


* --- 5.2 Pandemic Period 1 – Acute SARS-CoV-2 Effects -----------------------
*
* Primary analysis: acute SARS-CoV-2 exposure at 2-week lag

xtnbreg week_igas ///
    sars2_lag2 ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    i.age_group i.sex ///
    , exposure(week_pop) fe


* --- 5.3 Pandemic Period 2 – Acute Effects -----------------------------------

* [Same specification as 5.2, restricted to Period 2 data]


* --- 5.4 Pandemic Period 2 – Cumulative Effects (Exploratory) ---------------
*
* Model 1: Cumulative only
xtnbreg week_igas ///
    sars2_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    i.age_group i.sex ///
    , exposure(week_pop) fe

* Model 2: Acute + Cumulative (joint model)
xtnbreg week_igas ///
    sars2_lag2 sars2_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    i.age_group i.sex ///
    , exposure(week_pop) fe

* Compare model fit using AIC
* ΔAIC = AIC(acute only) – AIC(acute + cumulative)
* Negative ΔAIC indicates improved fit with cumulative burden


* --- 5.5 Age-Stratified Models -----------------------------------------------
*
* Run separately for each age group (0-19, 20-64, ≥65)
* Standard nbreg (not panel) with sex as covariate

foreach age in 1 2 3 {

    * Acute only
    nbreg week_igas ///
        sars2_lag2 ///
        sin1 cos1 sin2 cos2 ///
        time_linear time_quadratic ///
        i.sex ///
        if age_group == `age' ///
        , exposure(week_pop)

    * Acute + cumulative
    nbreg week_igas ///
        sars2_lag2 sars2_cumulative ///
        sin1 cos1 sin2 cos2 ///
        time_linear time_quadratic ///
        i.sex ///
        if age_group == `age' ///
        , exposure(week_pop)
}


* =============================================================================
* SECTION 6: POPULATION ATTRIBUTABLE FRACTION (PAF) ESTIMATION
* =============================================================================

* Method: counterfactual prediction (Zhou et al. Clin Infect Dis 2012)
*
* Step 1: Generate predicted counts using observed SARS-CoV-2 exposure
predict predicted_observed, n

* Step 2: Generate counterfactual predictions with SARS-CoV-2 set to zero
*         (all other model parameters held constant)
*         For acute model: set sars2_lag2 = 0
*         For joint model: set both sars2_lag2 = 0 AND sars2_cumulative = 0

generate sars2_lag2_zero    = 0
generate sars2_cumul_zero   = 0

* Temporarily replace exposure variable and predict
* [In practice: use lincom/margins or manual coefficient application]
predict predicted_counterfactual, n  // using zeroed exposure

* Step 3: Calculate PAF
* PAF = (sum(observed) - sum(counterfactual)) / sum(observed) × 100

summarize predicted_observed if pandemic_period == 1
local sum_obs = r(sum)
summarize predicted_counterfactual if pandemic_period == 1
local sum_cf = r(sum)
local paf = (`sum_obs' - `sum_cf') / `sum_obs' * 100

* Note: PAFs calculated separately for:
*   - Pandemic Period 1 (Mar 2020 – Aug 2022)
*   - Pandemic Period 2 (Sep 2022 – Mar 2024)
*   - Whole pandemic (concatenated)
*   - By age group (0-19, 20-64, ≥65)


* =============================================================================
* SECTION 7: NEGATIVE CONTROL ANALYSES
* =============================================================================

* Purpose: assess SARS-CoV-2 specificity; confirm model does not
*          spuriously detect associations with other respiratory viruses
*
* Key finding: without Fourier adjustment, ALL viruses show apparent
* associations with iGAS (shared winter seasonality). After adjustment,
* only SARS-CoV-2 associations persist.


* --- 7.1 Pre-Pandemic: Demonstrate Seasonal Confounding ---------------------

* Without seasonal adjustment (spurious associations expected)
foreach virus in flu_a flu_b rsv flu_combined {
    nbreg week_igas `virus'_lag2 ///
        time_linear time_quadratic ///
        i.age_group i.sex ///
        if prepandemic == 1 ///
        , exposure(week_pop)
}

* With seasonal adjustment (associations should become null)
foreach virus in flu_a flu_b rsv flu_combined {
    nbreg week_igas `virus'_lag2 ///
        sin1 cos1 sin2 cos2 ///
        time_linear time_quadratic ///
        i.age_group i.sex ///
        if prepandemic == 1 ///
        , exposure(week_pop)
}


* --- 7.2 Pandemic Period 1: Influenza and RSV --------------------------------

* Acute influenza (combined A+B) – should be null
xtnbreg week_igas ///
    flu_ab_lag2 ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , exposure(week_pop) fe

* Cumulative influenza – should be null
xtnbreg week_igas ///
    flu_ab_lag2 flu_ab_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , exposure(week_pop) fe

* [Same for RSV]


* --- 7.3 Pandemic Period 2: Head-to-Head Models ------------------------------

* RSV alone (may appear significant due to SARS-CoV-2 confounding)
xtnbreg week_igas ///
    rsv_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , exposure(week_pop) fe

* RSV + SARS-CoV-2 jointly (RSV effect should be eliminated)
xtnbreg week_igas ///
    rsv_cumulative sars2_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , exposure(week_pop) fe

* SARS-CoV-2 + Period 2 linear time trend (robustness to secular trends)
xtnbreg week_igas ///
    sars2_lag2 sars2_cumulative ///
    time_p2_linear ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , exposure(week_pop) fe


* =============================================================================
* SECTION 8: NON-INVASIVE STREPTOCOCCAL DISEASE AND INVASION PROPENSITY
* =============================================================================

* --- 8.1 SARS-CoV-2 Association with Non-Invasive Strep ---------------------
*
* Replace outcome with non-invasive streptococcal incidence
* Keep population as offset
* If effect sizes similar to iGAS → broad susceptibility increase

xtnbreg week_non_inv ///
    sars2_lag2 sars2_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , exposure(week_pop) fe


* --- 8.2 Invasion Propensity Analysis ----------------------------------------
*
* Replace POPULATION offset with TOTAL STREPTOCOCCAL DISEASE offset
* Estimates iGAS risk per streptococcal infection
* If null → SARS-CoV-2 increases susceptibility broadly (not invasion specifically)
* If significant → SARS-CoV-2 specifically promotes invasion

generate ln_all_strep_offset = log(week_all_strep + 0.5)  // add 0.5 to avoid log(0)

xtnbreg week_igas ///
    sars2_lag2 sars2_cumulative ///
    sin1 cos1 sin2 cos2 ///
    time_linear time_quadratic ///
    , offset(ln_all_strep_offset) fe


* =============================================================================
* SECTION 9: IMMUNITY DEBT HYPOTHESIS TEST
* =============================================================================

* The immunity debt hypothesis predicts: IRR < 1.0 for cumulative strep exposure
* (more past exposure → more immunity → lower current risk)
*
* Test: include cumulative streptococcal exposure alongside cumulative SARS-CoV-2
* If immunity debt is operating: strep_cum coefficient should be < 1 (protective)
* If not: strep_cum coefficient should be null or positive


* --- 9.1 Full Population (Pandemic Period 2) ---------------------------------

* Three formulations of cumulative streptococcal exposure:
foreach strep_var in strep_cum_invasive strep_cum_noninv strep_cum_total {

    xtnbreg week_igas ///
        sars2_lag2 sars2_cumulative `strep_var' ///
        sin1 cos1 sin2 cos2 ///
        time_linear time_quadratic ///
        , exposure(week_pop) fe

    * Expected under immunity debt: coef on `strep_var' < 0 (IRR < 1)
    * Observed: IRR ≈ 1.0 (null) or > 1.0 (opposite direction)
}


* --- 9.2 Age-Stratified Immunity Debt Tests ----------------------------------

foreach age in 1 2 3 {
    nbreg week_igas ///
        sars2_lag2 sars2_cumulative strep_cum_total ///
        sin1 cos1 sin2 cos2 ///
        time_linear time_quadratic ///
        i.sex ///
        if age_group == `age' & pandemic2 == 1 ///
        , exposure(week_pop)
}


* =============================================================================
* SECTION 10: SENSITIVITY ANALYSES
* =============================================================================

* --- 10.1 Alternative Lag Structures ----------------------------------------
* Test 1-week and 3-week lags for acute SARS-CoV-2 effects
* (primary analysis uses 2-week lag)

foreach lag in 1 3 {
    generate sars2_lag`lag' = L`lag'.sars2_combined
    * [Run same model as Section 5.2 with sars2_lag`lag']
}


* --- 10.2 Log Transformation of Cumulative Burden ---------------------------
* Test whether log(cumulative burden) performs similarly to linear form
* (cumulative burden ranges from 0 to ~350 in original scale, 0 to ~6 in log)

generate sars2_cum_log = log(sars2_cumulative + 1)
* [Run same model as Section 5.4 with log-transformed cumulative variable]


* --- 10.3 Sex-Stratified Models ----------------------------------------------
* Run primary models separately for males and females

foreach sex in 1 2 {
    xtnbreg week_igas ///
        sars2_lag2 sars2_cumulative ///
        sin1 cos1 sin2 cos2 ///
        time_linear time_quadratic ///
        i.age_group ///
        if sex_var == `sex' ///
        , exposure(week_pop) fe
}


* --- 10.4 Crude Incidence Rates by Age Group and Period ---------------------
* Intercept-only negative binomial models
* Yields annualized crude rates per 100,000 with 95% CIs

foreach age in 1 2 3 {
    foreach period in prepandemic pandemic1 pandemic2 fullseries {

        nbreg week_igas ///
            if age_group == `age' & study_period == "`period'" ///
            , exposure(week_pop)
        * _cons gives annualized incidence rate per person
        * Multiply by 100,000 for rate per 100,000

        * Same for non-invasive strep:
        nbreg week_non_inv ///
            if age_group == `age' & study_period == "`period'" ///
            , exposure(week_pop)
    }
}


* =============================================================================
* END OF PSEUDOCODE
* =============================================================================
*
* Data availability:
*   - iGAS/streptococcal case data: CIHI Secure Access Environment
*     (data sharing agreements required; not publicly available)
*   - SARS-CoV-2 test-adjusted estimates: derived from Ontario CCM/OLIS
*     (see Fisman et al. 2021, Bosco et al. 2025 for methodology)
*   - Respiratory virus surveillance (RVDSS): publicly available at
*     https://www.canada.ca/en/public-health/services/surveillance/
*     respiratory-virus-detections-canada.html
*   - Population denominators: Statistics Canada Table 17-10-0009-01
*     https://doi.org/10.25318/1710000901-eng
*
* Zenodo DOI: [INSERT ZENODO DOI]
* =============================================================================
