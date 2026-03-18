* =============================================================================
* 04_collapse_and_zeroes.do
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: Collapse deduplicated strep records to weekly counts by age/sex;
*          generate complete date × age × sex scaffold with zeroes;
*          merge iGAS, non-invasive, and all-strep counts with population data
*
* Input:  all_strep_no_duplicates.dta
*         GTHA_plus_population_summary.csv
* Output: all_strep_counts_with_zeroes2.dta
* =============================================================================


* =============================================================================
* SECTION 1: CASE-ONLY DATASETS (for case-crossover studies, not used in
*             primary analysis but retained for reference)
* =============================================================================

use "all_strep_no_duplicates.dta", clear

* Invasive strep cases only
keep if igas == 1
keep mbun age_group gender_code date
save "igas_cases.dta", replace
clear

* Non-invasive strep cases only
* Defined as B950 + (cellulitis | otitis | pharyngitis | tracheitis), excluding iGAS
use "all_strep_no_duplicates.dta", clear
keep if (pharyngitis==1 | otitis==1 | cellulitis==1 | tracheitis==1) & igas==0
keep mbun age_group gender_code date
save "non_invasive_cases.dta", replace
clear

* All strep cases
use "all_strep_no_duplicates.dta", clear
keep mbun age_group gender_code date
save "all_strep_cases.dta", replace
clear


* =============================================================================
* SECTION 2: COLLAPSED COUNT DATASETS (without zeroes)
* =============================================================================

* Invasive GAS counts by date, age group, sex
use "all_strep_no_duplicates.dta", clear
keep if igas == 1
collapse (sum) igas, by(date age_group gender_code)
save "collapsed_igas_no_zeroes.dta", replace
clear

* Non-invasive strep counts
use "all_strep_no_duplicates.dta", clear
keep if (pharyngitis==1 | otitis==1 | cellulitis==1) & igas==0
gen non_invasive = 1
collapse (sum) non_invasive, by(date age_group gender_code)
save "collapsed_non_invasive_no_zeroes.dta", replace
clear

* All strep counts
use "all_strep_no_duplicates.dta", clear
collapse (sum) all_strep, by(date age_group gender_code)
save "collapsed_all_strep_no_zeroes.dta", replace
clear


* =============================================================================
* SECTION 3: GENERATE ZEROES SCAFFOLD
* Complete date × sex × age_group grid (January 1, 2011 through end of 2024)
* This ensures weeks with zero cases are represented in the time series
* =============================================================================

* Create daily date sequence
clear
set obs 1
gen date = date("January 1, 2011", "MD20Y")
format date %d
expand 6000
replace date = date[_n-1] + 1 if _n > 1
drop if year(date) > 2024

* Expand for 2 sexes
expand 2
sort date
gen gender_code = "F"
replace gender_code = "M" if date == date[_n-1]

* Expand for 3 age groups
expand 3
sort date gender_code
gen age_group = "0-19"
replace age_group = "20-64" if date == date[_n-1]
replace age_group = "65 +" if gender_code ~= gender_code[_n+1]
replace age_group = "0-19" if gender_code == "M" & age_group[_n-1] == "65 +" ///
    & date == date[_n-1]

ren gender_code gender
ren age_ age
gen year = year(date)
sort year age gender
save "zeroes.dta", replace
clear


* =============================================================================
* SECTION 4: MERGE CASE COUNTS WITH POPULATION DENOMINATORS
* =============================================================================

* Load population data from Statistics Canada
* (GTHA+ PHU-level annual estimates by age group and sex)
import delimited "GTHA_plus_population_summary.csv", clear
replace gender = "M" if gender == "Men+"
replace gender = "F" if gender == "Women+"
ren age_band age
replace age = "65 +" if age == "65+"
sort year age gender

* Merge with zeroes scaffold
merge year age gender using "zeroes.dta"
drop if _m == 1     // drop population records outside study period
drop _m
sort date age gender
save "zeroes.dta", replace
clear

* Merge iGAS counts into scaffold
use "collapsed_igas_no_zeroes.dta", clear
ren gender_ gender
ren age_ age
sort date age gender
merge date age gender using "zeroes.dta"
drop _m
sort date age gender
save "collapsed_igas_counts.dta", replace
clear

* Add non-invasive strep counts
use "collapsed_non_invasive_no_zeroes.dta", clear
ren age_g age
ren gender_c gender
sort date age gender
merge date age gender using "collapsed_igas_counts.dta"
drop _m
sort date age gender
save "collapsed_igas_non_invasive_counts.dta", replace
clear

* Add all-strep counts
use "collapsed_all_strep_no_zeroes.dta", clear
ren gender_ gender
ren age_ age
sort date age gender
merge date age gender using "collapsed_igas_non_invasive_counts.dta"
drop _m
sort date age gender


* =============================================================================
* SECTION 5: TIME VARIABLES
* =============================================================================

* Week of year
gen week  = week(date)
gen month = month(date)

* Sequential series week (week 1 = first week of 2011)
gen series_week = week + 52*(year - 2011)

* Centered time trend (centered at year 7 = 2018, week 1)
gen centered_week = series_week - 364
gen week_sq  = centered_week^2
gen week_cub = centered_week^3

* Pandemic indicator (onset: March 16, 2020)
gen pandemic = 0
replace pandemic = 1 if date > date("March 16, 2020", "MD20Y")

* COVID-19 wave indicators (based on epidemic wave dates in Ontario)
gen wave = 0
replace wave = 1 if date >= 21989   // Wave 1 start
replace wave = 2 if date >= 22164   // Wave 2 start
replace wave = 3 if date >= 22346   // Wave 3 start
replace wave = 4 if date >= 22465   // Wave 4 start
replace wave = 5 if date >= 22640   // Wave 5 start
replace wave = 6 if date >= 22724   // Wave 6 start
replace wave = round(wave)

* Fourier seasonal terms (annual periodicity, ω = 2π/52)
gen sinwk = sin(6.28 * week / 52)
gen coswk = cos(6.28 * week / 52)


* =============================================================================
* SECTION 6: POPULATION OFFSETS
* =============================================================================

gen day_pop  = pop / 365
gen week_pop = pop / 52
gen mo_pop   = pop / 12


* =============================================================================
* SECTION 7: ENCODE AGE AND SEX AS NUMERIC
* =============================================================================

encode age,    gen(age2)
encode gender, gen(gender2)


* =============================================================================
* SECTION 8: COLLAPSE TO WEEKLY COUNTS AND MERGE WITH EXPOSURE DATA
* =============================================================================

sort date
save "all_strep_counts_with_zeroes2.dta", replace
clear

* Collapse individual-level data to weekly panel (age × sex × week)
use "all_strep_counts_with_zeroes2.dta", clear
collapse (mean) week_igas week_non_inv week_all_strep pandemic population ///
    day_pop week_pop mo_pop sinwk coswk centered_week week_sq week_cub wave ///
    series_week date, by(age2 gender2 week year)
sort year week
save "collapsed_weekly_groupastrep.dta", replace
clear
