* =============================================================================
* 01_case_ascertainment_DAD
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: iGAS, non-invasive GAS, and all-strep case ascertainment from CIHI DAD (25 diagnosis fields)
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


