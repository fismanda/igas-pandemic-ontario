SARS-CoV-2 and the Late Pandemic Surge in Invasive Group A Streptococcal Disease
Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
Dalla Lana School of Public Health, University of Toronto

Preprint: medRxiv [DOI TBD]

Zenodo DOI: DOI: 10.5281/zenodo.19098309

Overview
This repository contains analytic code for a 13-year population-based time-series study examining the association between SARS-CoV-2 activity and invasive group A streptococcal (iGAS) disease in central Ontario, Canada (2011–2024).

Key findings:

34.3% of pandemic-era iGAS cases attributable to acute SARS-CoV-2 effects
Cumulative SARS-CoV-2 burden strongly associated with iGAS (IRR 1.19, 95% CI 1.15–1.24); model fit improved decisively with cumulative burden (ΔAIC = −157.5)
Cumulative streptococcal exposure showed no protective effect, directly refuting the immunity debt hypothesis
All associations specific to SARS-CoV-2; influenza null throughout; RSV association explained by confounding with SARS-CoV-2
Data Availability
Administrative health data (iGAS and streptococcal case counts) were accessed within the CIHI Secure Access Environment (SAE). These data cannot be publicly shared. Access requires execution of data protection agreements with the Canadian Institute for Health Information (CIHI): https://www.cihi.ca/en/data-and-reporting/access-data

Respiratory virus surveillance data (SARS-CoV-2, influenza A/B, RSV percent positivity) are publicly available from the Public Health Agency of Canada Respiratory Virus Detection Surveillance System (RVDSS):
https://www.canada.ca/en/public-health/services/surveillance/respiratory-virus-detections-canada.html

SARS-CoV-2 test-adjusted case counts (Pandemic Period 1) were derived using the methodology described in:

Fisman DN et al. Ann Intern Med 2021. doi:10.7326/M20-7003
Bosco S et al. BMC Infect Dis 2025. doi:10.1186/s12879-025-10968-6
Population denominators are publicly available from Statistics Canada Table 17-10-0009-01:
https://doi.org/10.25318/1710000901-eng

Repository Structure
├── stata/
│   ├── 01_case_ascertainment_DAD.do
│   ├── 02_case_ascertainment_NACRS.do
│   ├── 03_deduplication.do
│   ├── 04_collapse_and_zeroes.do
│   ├── 05_data_assembly.do
│   ├── 06_variable_construction.do
│   └── 07_analysis.do
├── R/
│   ├── figures.R
│   └── [additional figure scripts]
└── README.md
Analytic Pipeline
Code was executed in Stata 17 within the CIHI Secure Access Environment. File paths have been anonymized (original paths referenced a project-specific SAE drive). The pipeline proceeds as follows:

Stage 1: Case Ascertainment
01_case_ascertainment_DAD.do
Identifies iGAS, non-invasive GAS, and all-strep cases from the CIHI Discharge Abstract Database (DAD; 25 diagnosis fields). Defines iGAS as: (a) A40.0 (GAS sepsis) in any field, or (b) invasive syndrome code + B95.0 in any fields.

02_case_ascertainment_NACRS.do
Identical case definitions applied to the National Ambulatory Care Reporting System (NACRS; 10 diagnosis fields: main_problem + other_problem_1 through other_problem_9).

03_deduplication.do
Appends DAD and NACRS strep-positive files; retains the first encounter per person (by encrypted ID and date) across both databases, yielding one episode per person over the study period.

Stage 2: Data Preparation
04_collapse_and_zeroes.do
Collapses deduplicated records to weekly counts by age group (0–19, 20–64, ≥65 years) and sex; constructs a complete date × age × sex scaffold with zeroes; merges with Statistics Canada population denominators; generates time variables (series_week, centered_week, week_sq, week_cub), Fourier seasonal terms (sinwk, coswk), pandemic indicators, and wave variables.

05_data_assembly.do
Imports weekly virologic and weather exposure data; merges with weekly strep count dataset; constructs 6-panel xtset structure (3 age groups × 2 sexes); normalizes SARS-CoV-2 (Period 1: test-adjusted cases / SD; Period 2: percent positivity / SD), influenza A/B, RSV, and combined influenza exposures to standard deviation units.

06_variable_construction.do
Constructs: 2-week lagged acute SARS-CoV-2 exposure; cumulative SARS-CoV-2 burden (running sum from pandemic onset by panel); cumulative influenza, RSV, and streptococcal exposure variables; age-group indicator and interaction terms; lagged outcome variables for sensitivity analyses; school closure indicator.

Stage 3: Analysis
07_analysis.do
All regression analyses:

Descriptive crude incidence models (Section 1)
Primary panel negative binomial models — acute SARS-CoV-2 effects (Section 2)
Normalized virus models — period-specific (Section 3)
Cumulative SARS-CoV-2 models — exploratory (Section 4)
Age-stratified models (Section 5)
Negative control analyses — influenza and RSV (Section 6)
Non-invasive strep and invasion propensity analyses (Section 7)
Immunity debt hypothesis tests (Section 8)
Population attributable fraction estimation (Section 9)
Sensitivity analyses — alternative lags, log transformation, sex-stratified (Section 10)
Stage 4: Figures
R/figures.R
Figure generation in R. See script header for package dependencies and session information.

Key Variable Definitions
Variable	Definition
week_igas	Weekly iGAS case count (per age-sex stratum)
week_non_inv	Weekly non-invasive GAS case count
week_all_strep	Weekly all-strep case count
week_pop	Weekly population denominator (annual pop / 52)
norm_sars	Normalized SARS-CoV-2 exposure (SD units; P1: test-adjusted cases, P2: % positivity)
cum_norm_sars	Cumulative normalized SARS-CoV-2 burden (running sum from Mar 2020)
l2_norm_sars	2-week lagged normalized SARS-CoV-2
norm_flua/b	Normalized influenza A/B percent positivity
norm_rsv	Normalized RSV percent positivity
sinwk/coswk	Fourier seasonal terms (ω = 2π/52)
week_sq/cub	Quadratic/cubic secular time trend
pandemic1	Pandemic Period 1 indicator (Mar 2020 – Aug 2022)
pandemic2	Pandemic Period 2 indicator (Sep 2022 – Mar 2024)
panel	Panel ID (1–3: female age groups; 4–6: male age groups)
Software
Stata 17 (StataCorp, College Station TX) — case ascertainment, data management, regression analyses
R (version 4.x) — figures; packages listed in figure script headers
Ethics
Approved by the Research Ethics Board, University of Toronto (Protocol #41690). Study used pre-collected anonymized administrative data; informed consent waived.

Citation
If you use this code, please cite:

Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR. SARS-CoV-2 and the Late Pandemic Surge in Invasive Group A Streptococcal Disease: A 13-Year Population-Based Study. [Journal] [Year]. doi:[DOI]

Contact
David N. Fisman MD MPH FRCP(C)
Dalla Lana School of Public Health, University of Toronto
david.fisman@utoronto.ca
