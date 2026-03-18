* =============================================================================
* 02_case_ascertainment_NACRS
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: iGAS, non-invasive GAS, and all-strep case ascertainment from CIHI NACRS (10 diagnosis fields)
* =============================================================================

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


