* =============================================================================
* 03_deduplication
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: Append DAD and NACRS; retain first encounter per person across both databases
* =============================================================================

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


