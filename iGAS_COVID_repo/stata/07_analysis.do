* =============================================================================
* 07_analysis.do
* iGAS-COVID Analysis Pipeline
* Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
*
* Purpose: All regression analyses reported in the manuscript and appendices
*
* Notes on model selection:
*   - xtnbreg (panel NB) used where models converge
*   - nbreg (standard NB) used where panel models do not converge,
*     notably for age-stratified models in children and elderly
*   - estat ic run after every model for AIC comparison
*   - Propensity to invade: uses exp(week_all_strep) as exposure offset
*     with restriction week_all_strep > 0 (not log offset)
*   - l2.norm_sars = 2-week lag using manually constructed variable l2_norm_sars
* =============================================================================

use "analysis_dataset.dta", clear
sort panel series_week


* =============================================================================
* SECTION 1: PANDEMIC PERIOD DEFINITIONS
* =============================================================================

gen pandemic1 = 0
replace pandemic1 = 1 if date >= date("March 1, 2020",     "MD20Y")
gen pandemic2 = 0
replace pandemic2 = 1 if date >= date("September 1, 2022", "MD20Y")
replace pandemic1 = 0 if pandemic2 == 1   // mutually exclusive


* =============================================================================
* SECTION 2: DESCRIPTIVE TREND MODELS
* =============================================================================

sort age2 series_week

* Crude incidence by period (intercept-only)
nbreg week_igas,                                        exp(week_pop)
nbreg week_igas if pandemic1==0 & pandemic2==0,         exp(week_pop)
nbreg week_igas if pandemic1==1 & pandemic2==0,         exp(week_pop)
nbreg week_igas if pandemic1==0 & pandemic2==1,         exp(week_pop)

* Age-sex adjusted
nbreg week_igas sinwk coswk ib2.age2 gender2 week_sq,  exp(week_pop) irr
nbreg week_igas sinwk coswk ib2.age2 gender2 week_sq pandemic1 pandemic2, ///
    exp(week_pop) irr

* Period-specific adjusted models
nbreg week_igas sinwk gender2 coswk ib2.age2 week_sq ///
    if pandemic1==0 & pandemic2==1, exp(week_pop) irr
nbreg week_igas sinwk gender2 week_sq coswk ib2.age2 ///
    if pandemic1==1 & pandemic2==0, exp(week_pop) irr
nbreg week_igas sinwk coswk ib2.age2 gender2 week_sq ///
    if pandemic1==0 & pandemic2==0, exp(week_pop) irr

* Full period with cubic trend and both pandemic indicators
nbreg week_igas sinwk coswk week_cub week_sq centered_week pandemic1 pandemic2, ///
    exp(week_pop) irr


* =============================================================================
* SECTION 3: PRIMARY PANEL MODELS — INVASIVE STREP (ALL AGES)
* =============================================================================

* --- Pandemic Period 1 (Mar 2020 - Aug 2022) ---------------------------------

sort panel series_week

* Acute SARS-CoV-2 only
xtnbreg week_igas sinwk l2_norm_sars coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
sort panel series_week
estat ic

* Acute + cumulative SARS-CoV-2
xtnbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* With cumulative invasive GAS (immunity debt test)
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq ///
    i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Cumulative non-invasive strep
xtnbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Cumulative all strep
nbreg week_igas cum_all_strep l2_norm_sars sinwk coswk week_sq ///
    i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Joint: cumulative SARS-CoV-2 + cumulative iGAS
nbreg week_igas l2_norm_sars cum_norm_sars cum_igas sinwk coswk week_sq ///
    i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Joint: cumulative SARS-CoV-2 + cumulative non-invasive
nbreg week_igas l2_norm_sars cum_non_inv cum_norm_sars sinwk coswk week_sq ///
    i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Joint: cumulative SARS-CoV-2 + cumulative all strep
xtnbreg week_igas l2_norm_sars cum_norm_sars cum_all_strep sinwk coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic


* --- Pandemic Period 2 (Sep 2022 - Mar 2024) ---------------------------------

sort panel series_week

* Acute SARS-CoV-2 only
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Acute + cumulative SARS-CoV-2 (primary reported result: IRR 1.19, DAIC -157.5)
xtnbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* With cumulative iGAS
xtnbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Cumulative non-invasive strep
xtnbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Cumulative all strep
xtnbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Joint: cumulative SARS-CoV-2 + cumulative iGAS
xtnbreg week_igas l2_norm_sars cum_igas cum_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Joint: cumulative SARS-CoV-2 + cumulative non-invasive
xtnbreg week_igas l2_norm_sars cum_norm_sars cum_non_inv sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Joint: cumulative SARS-CoV-2 + cumulative all strep
xtnbreg week_igas l2_norm_sars cum_norm_sars cum_all_strep sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 4: AGE-STRATIFIED MODELS
*
* NOTE: Panel models (xtnbreg) do not converge for children (age2==1) or
*       elderly (age2==3). Standard nbreg used for these age groups.
*       Adults (age2==2): xtnbreg converges for Period 1; nbreg for Period 2.
* =============================================================================

* --- Children (age2 == 1) — nbreg throughout --------------------------------

sort panel series_week

* Pandemic Period 1: acute
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic

* Pandemic Period 1: acute + cumulative
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk i.gender2 week_sq ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic

* Pandemic Period 2: acute
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic

* Pandemic Period 2: acute + cumulative (key result: IRR 1.31)
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic

* With cumulative strep (immunity debt test)
sort panel series_week
nbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic

sort panel series_week
nbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic


* --- Adults (age2 == 2) — xtnbreg for P1, nbreg for P2 ---------------------

sort panel series_week

* Pandemic Period 1: acute (xtnbreg converges)
xtnbreg week_igas sinwk l2_norm_sars coswk week_sq ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic

* Pandemic Period 1: acute + cumulative
xtnbreg week_igas week_sq coswk sinwk cum_norm_sars l2_norm_sars ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic

* Pandemic Period 2: acute (nbreg)
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic

* Pandemic Period 2: acute + cumulative
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic

* With cumulative strep (immunity debt test)
sort panel series_week
nbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic

sort panel series_week
nbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic


* --- Elderly (age2 == 3) — xtnbreg for P1 (convergence note), nbreg for P2 -

sort panel series_week

* Pandemic Period 1: acute
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic1==1 & age2==3, exp(week_pop) irr
estat ic

* Pandemic Period 1: acute + cumulative
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==3, exp(week_pop) irr
estat ic

* Pandemic Period 2: acute
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==3, exp(week_pop) irr
estat ic

* Pandemic Period 2: acute + cumulative
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==3, exp(week_pop) irr
estat ic

* With cumulative strep (immunity debt test)
sort panel series_week
nbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==3, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==3, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==3, exp(week_pop) irr
estat ic

sort panel series_week
nbreg week_igas l2_norm_sars cum_all_strep sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==3, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_non_inv sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==3, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_sars cum_igas sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==3, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 5: NON-INVASIVE STREPTOCOCCAL DISEASE
* =============================================================================

* --- Pandemic Period 1 -------------------------------------------------------
sort panel series_week

* Acute only (panel model)
xtnbreg week_non_inv l2_norm_sars sinwk coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Acute only (standard NB, age-sex adjusted)
nbreg week_non_inv l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Acute + cumulative SARS-CoV-2
xtnbreg week_non_inv cum_norm_sars l2_norm_sars sinwk coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* [Models with cumulative iGAS, non-invasive, all-strep commented out
*  as these were exploratory and not reported in primary manuscript]


* --- Pandemic Period 2 -------------------------------------------------------
sort panel series_week

* Acute only
xtnbreg week_non_inv l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Acute + cumulative SARS-CoV-2 (reported result: IRR 1.22)
xtnbreg week_non_inv l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 6: PROPENSITY TO INVADE
*
* Replace population offset with total streptococcal disease (week_all_strep)
* Restriction: week_all_strep > 0 (exclude weeks with zero strep encounters)
* exp(week_all_strep) used directly as offset (not log-transformed offset)
* Null result = SARS-CoV-2 does not selectively enhance invasion
* =============================================================================

* --- Pandemic Period 1 -------------------------------------------------------
sort panel series_week

* Acute
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1 & week_all_strep>0, exp(week_all_strep) irr
estat ic

* Acute + cumulative
xtnbreg week_igas cum_norm_sars l2_norm_sars sinwk coswk week_sq ///
    if pandemic1==1 & week_all_strep>0, exp(week_all_strep) irr
estat ic


* --- Pandemic Period 2 -------------------------------------------------------
sort panel series_week

* Acute (standard NB, age-sex adjusted)
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1 & week_all_strep>0, exp(week_all_strep) irr
estat ic

* Acute (panel model)
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1 & week_all_strep>0, exp(week_all_strep) irr
estat ic

* Acute + cumulative (reported result: cumulative IRR ~1.04, p=0.10)
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1 & week_all_strep>0, exp(week_all_strep) irr
estat ic


* =============================================================================
* SECTION 7: NEGATIVE CONTROL ANALYSES — OTHER RESPIRATORY VIRUSES
* =============================================================================

* --- Influenza A -------------------------------------------------------------

* Pandemic Period 1
sort panel series_week
nbreg week_igas l2_norm_flua sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
xtnbreg week_igas sinwk l2_norm_flua coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Cumulative flu A (should be null)
nbreg week_igas l2_norm_flua cum_norm_flua sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Cumulative flu A + cumulative SARS-CoV-2 jointly
nbreg week_igas l2_norm_flua l2_norm_sars cum_norm_flua cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Pandemic Period 2
sort panel series_week
nbreg week_igas l2_norm_flua sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_flua l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Cumulative flu A (should be null)
nbreg week_igas l2_norm_flua cum_norm_flua sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Cumulative flu A + cumulative SARS-CoV-2 jointly
nbreg week_igas l2_norm_flua l2_norm_sars cum_norm_flua cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic2==1, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 8: FLU B — LAGGED AND CUMULATIVE (with interaction term)
* =============================================================================

* Pandemic Period 1
sort panel series_week
nbreg week_igas l2_norm_flub sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
xtnbreg week_igas sinwk l2_norm_flub coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Cumulative flu B
nbreg week_igas cum_norm_flub l2_norm_flub sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flub l2_norm_sars cum_norm_flub cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Pandemic Period 2
sort panel series_week
xtnbreg week_igas l2_norm_flub l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_flub sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_flub l2_norm_sars l2_interact sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Cumulative flu B
nbreg week_igas l2_norm_flub cum_norm_flub sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flub l2_norm_sars cum_norm_flub cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flub l2_norm_sars l2_interact cum_interact ///
    cum_norm_flub cum_norm_sars sinwk coswk week_sq if pandemic2==1, ///
    exp(week_pop) irr
estat ic

* Flu B x SARS-CoV-2 interaction terms
drop interact
gen interact     = norm_flub * norm_sars
gen cum_interact = cum_norm_flub * cum_norm_sars
nbreg week_igas l2_norm_flub l2_norm_sars cum_norm_flub cum_norm_sars ///
    cum_interact interact sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Pre-pandemic: flu A+B and RSV
nbreg week_igas l2_norm_flub l2_norm_flua sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==0 & pandemic1==0, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flub l2_norm_flua l2_norm_rsv sinwk coswk week_sq ///
    i.age2 i.gender2 if pandemic2==0 & pandemic1==0, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 9: ALL FLU COMBINED
* =============================================================================

* Pandemic Period 1
sort panel series_week
nbreg week_igas l2_norm_flu sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flu cum_norm_flu sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flu l2_norm_sars cum_norm_flu cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic1==1, exp(week_pop) irr
estat ic

* Pandemic Period 2
sort panel series_week
nbreg week_igas l2_norm_flu sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flu l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flu cum_norm_flu sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flu l2_norm_sars cum_norm_flu cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic2==1, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 10: RSV
* =============================================================================

* Pandemic Period 1
sort panel series_week
nbreg week_igas l2_norm_rsv sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_rsv l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_rsv sinwk coswk week_sq ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Cumulative RSV
nbreg week_igas l2_norm_rsv cum_norm_rsv sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr
estat ic

* Pandemic Period 2
sort panel series_week
nbreg week_igas l2_norm_rsv sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_rsv sinwk coswk week_sq ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Cumulative RSV
nbreg week_igas l2_norm_rsv cum_norm_rsv sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* RSV + SARS-CoV-2 jointly (key result: RSV eliminated by SARS-CoV-2)
nbreg week_igas l2_norm_rsv cum_norm_rsv l2_norm_sars cum_norm_sars ///
    sinwk coswk week_sq i.age2 i.gender2 if pandemic2==1, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_rsv l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr
estat ic

* Pre-pandemic: all resp viruses (seasonal confounding demonstration)
nbreg week_igas l2_norm_flu  sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic==0, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flua sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic==0, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_flub sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic==0, exp(week_pop) irr
estat ic
nbreg week_igas l2_norm_rsv  sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic==0, exp(week_pop) irr
estat ic


* =============================================================================
* SECTION 11: POPULATION ATTRIBUTABLE FRACTIONS
*
* Method: counterfactual prediction (Zhou et al. Clin Infect Dis 2012)
* Step 1: Fit model with coefl option to save coefficients
* Step 2: Manually construct counterfactual predictions setting SARS-CoV-2=0
*         by applying saved coefficients without SARS-CoV-2 terms
* Step 3: PAF = 100 * (sum_observed - sum_counterfactual) / sum_observed
*
* Note: predict n gives Poisson-like expected counts from NB model
* =============================================================================

sort panel series_week

* --- 11.1 Overall PAF — Acute, Pandemic Period 1 ----------------------------

nbreg week_igas sinwk l2_norm_sars coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr coefl
estat ic

* Counterfactual: predicted counts with SARS-CoV-2 coefficient zeroed out
gen pred_igas_no_sars = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.age2]*(age2==2) + _b[3.age2]*(age2==3) + ///
    _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic1==1

predict pred_igas_p1 if pandemic1==1, n
sort date
by date, sort: egen pred_igas_p1_total   = sum(pred_igas_p1)        if pandemic1==1
by date, sort: egen pred_igas_no_sars_p1t = sum(pred_igas_no_sars) if pandemic1==1

graph twoway line pred_igas_p1_total date if pandemic==1 ///
    || line pred_igas_no_sars_p1t date if pandemic1==1

* PAF
egen total_obs_p1 = total(pred_igas_p1_total)   if pandemic1==1
egen total_cf_p1  = total(pred_igas_no_sars_p1t) if pandemic1==1
gen paf_p1_acute = 100 * (total_obs_p1 - total_cf_p1) / total_obs_p1
summarize paf_p1_acute
display "Pandemic 1 acute COVID PAF: " r(mean) "%"


* --- 11.2 Overall PAF — Acute, Pandemic Period 2 ----------------------------

nbreg week_igas l2_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr coefl
estat ic

gen pred_igas_no_sars_p2 = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.age2]*(age2==2) + _b[3.age2]*(age2==3) + ///
    _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic2==1

predict pred_igas_p2 if pandemic2==1, n
sort date
by date, sort: egen pred_igas_p2_total    = sum(pred_igas_p2)          if pandemic2==1
by date, sort: egen pred_igas_no_sars_p2t = sum(pred_igas_no_sars_p2) ///
    if pandemic2==1 & week_igas~=.

graph twoway line pred_igas_p2_total series_week if pandemic2==1 ///
    || line pred_igas_no_sars_p2t series_week ///
       if pandemic2==1 & pred_igas_p2_total~=.

* PAF
egen total_obs_p2 = total(pred_igas_p2_total)    if pandemic2==1
egen total_cf_p2  = total(pred_igas_no_sars_p2t) ///
    if pandemic2==1 & pred_igas_p2_total~=.
gen paf_p2_acute = 100 * (total_obs_p2 - total_cf_p2) / total_obs_p2
summarize paf_p2_acute
display "Pandemic 2 acute COVID PAF: " r(mean) "%"


* --- 11.3 Overall PAF — Acute + Cumulative, Pandemic Period 1 ---------------

nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic1==1, exp(week_pop) irr coefl
estat ic

gen pred_igas_ac_no_sars = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.age2]*(age2==2) + _b[3.age2]*(age2==3) + ///
    _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic1==1

predict pred_igas_ac_p1 if pandemic1==1, n
sort date
by date, sort: egen pred_igas_ac_p1_total   = sum(pred_igas_ac_p1)     if pandemic1==1
by date, sort: egen pred_igas_no_sars_p1t_ac = sum(pred_igas_ac_no_sars) if pandemic1==1

graph twoway line pred_igas_ac_p1_total date if pandemic==1 ///
    || line pred_igas_no_sars_p1t_ac date if pandemic1==1

* PAF
egen total_obs_p1_ac = total(pred_igas_ac_p1_total)    if pandemic1==1
egen total_cf_p1_ac  = total(pred_igas_no_sars_p1t_ac) if pandemic1==1
gen paf_p1_ac = 100 * (total_obs_p1_ac - total_cf_p1_ac) / total_obs_p1_ac
summarize paf_p1_ac
display "Pandemic 1 acute and cumulative COVID PAF: " r(mean) "%"


* --- 11.4 Overall PAF — Acute + Cumulative, Pandemic Period 2 ---------------

gen log_cum_norm = ln(cum_norm_sars)
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.age2 i.gender2 ///
    if pandemic2==1, exp(week_pop) irr coefl
estat ic

gen pred_igas_ac_no_sars_p2 = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.age2]*(age2==2) + _b[3.age2]*(age2==3) + ///
    _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic2==1

predict pred_igas_ac_p2 if pandemic2==1, n
sort date
by date, sort: egen pred_igas_ac_p2_total    = sum(pred_igas_ac_p2)        if pandemic2==1
by date, sort: egen pred_igas_no_sars_p2t_ac = sum(pred_igas_ac_no_sars_p2) if pandemic2==1

graph twoway line pred_igas_ac_p2_total date if pandemic2==1 ///
    || line pred_igas_no_sars_p2t_ac date if pandemic2==1

* PAF
egen total_obs_p2_ac = total(pred_igas_ac_p2_total)    if pandemic2==1
egen total_cf_p2_ac  = total(pred_igas_no_sars_p2t_ac) if pandemic2==1
gen paf_p2_ac = 100 * (total_obs_p2_ac - total_cf_p2_ac) / total_obs_p2_ac
summarize paf_p2_ac
display "Pandemic 2 acute and cumulative COVID PAF: " r(mean) "%"


* --- 11.5 Whole Pandemic PAF (P1 + P2 combined) -----------------------------

* Acute only
by pandemic, sort: egen total_obs_p2_2 = max(total_obs_p2)
by pandemic, sort: egen total_obs_p1_2 = max(total_obs_p1)
by pandemic, sort: egen total_cf_p1_2  = max(total_cf_p1)
by pandemic, sort: egen total_cf_p2_2  = max(total_cf_p2)

gen paf_whole_acute = 100 * (total_obs_p2_2 + total_obs_p1_2 - ///
    total_cf_p2_2 - total_cf_p1_2) / (total_obs_p2_2 + total_obs_p1_2)
summarize paf_whole_acute
display "Whole pandemic: acute " r(mean) "%"

* Acute + cumulative
by pandemic, sort: egen total_obs_p2_ac_2 = max(total_obs_p2_ac)
by pandemic, sort: egen total_obs_p1_ac_2 = max(total_obs_p1_ac)
by pandemic, sort: egen total_cf_p1_ac_2  = max(total_cf_p1_ac)
by pandemic, sort: egen total_cf_p2_ac_2  = max(total_cf_p2_ac)

gen paf_whole_acute_cum = 100 * (total_obs_p2_ac_2 + total_obs_p1_ac_2 - ///
    total_cf_p2_ac_2 - total_cf_p1_ac_2) / (total_obs_p2_ac_2 + total_obs_p1_ac_2)
summarize paf_whole_acute_cum
display "Whole pandemic: acute + cumulative " r(mean) "%"

* Graph: acute only, whole pandemic
gen total_obs = pred_igas_p2_total
replace total_obs = pred_igas_p1_total if total_obs==. & pandemic==1
gen total_cf = pred_igas_no_sars_p2t
replace total_cf = pred_igas_no_sars_p1t if total_cf==. & pandemic==1
graph twoway line total_cf total_obs date if pandemic==1 ///
    & date > date("March 15, 2020", "MD20Y")

* Graph: acute + cumulative, whole pandemic
gen total_obs_ac = pred_igas_ac_p2_total
replace total_obs_ac = pred_igas_ac_p1_total if total_obs_ac==. & pandemic==1
gen total_cf_ac = pred_igas_no_sars_p2t_ac
replace total_cf_ac = pred_igas_no_sars_p1t_ac if total_cf_ac==. & pandemic==1
graph twoway line total_cf_ac total_obs_ac date if pandemic==1


* =============================================================================
* SECTION 12: AGE-STRATIFIED PAFs
* =============================================================================

* --- 12.1 Children (age2 == 1) -----------------------------------------------

sort panel series_week

* Acute P1
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr coefl
estat ic
gen pred_igas_no_sars_age1 = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic1==1
predict pred_igas_p1_age1 if pandemic1==1, n
sort date
by date, sort: egen pred_igas_p1_total_age1    = sum(pred_igas_p1_age1)      if pandemic1==1
by date, sort: egen pred_igas_no_sars_p1t_age1 = sum(pred_igas_no_sars_age1) if pandemic1==1
graph twoway line pred_igas_p1_total_age1 date if pandemic==1 ///
    || line pred_igas_no_sars_p1t_age1 date if pandemic1==1

egen total_obs_p1_age1 = total(pred_igas_p1_total_age1)    if pandemic1==1
egen total_cf_p1_age1  = total(pred_igas_no_sars_p1t_age1) if pandemic1==1
gen paf_p1_acute_age1 = 100 * (total_obs_p1_age1 - total_cf_p1_age1) / total_obs_p1_age1
summarize paf_p1_acute_age1
display "Pandemic 1 acute COVID PAF: " r(mean) "%"

* Acute P2
nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr coefl
estat ic
gen pred_igas_no_sars_p2_age1 = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic2==1
predict pred_igas_p2_age1 if pandemic2==1, n
sort date
by date, sort: egen pred_igas_p2_total_age1    = sum(pred_igas_p2_age1)         if pandemic2==1
by date, sort: egen pred_igas_no_sars_p2t_age1 = sum(pred_igas_no_sars_p2_age1) ///
    if pandemic2==1 & week_igas~=.

eigen total_obs_p2_age1 = total(pred_igas_p2_total_age1)    if pandemic2==1
egen total_cf_p2_age1   = total(pred_igas_no_sars_p2t_age1) ///
    if pandemic2==1 & pred_igas_p2_total~=.
gen paf_p2_acute_age1 = 100 * (total_obs_p2_age1 - total_cf_p2_age1) / total_obs_p2_age1
summarize paf_p2_acute_age1
display "Pandemic 2 acute COVID PAF: " r(mean) "%"

* Whole pandemic: acute
by pandemic, sort: egen total_obs_p2_2_age1 = max(total_obs_p2_age1)
by pandemic, sort: egen total_obs_p1_2_age1 = max(total_obs_p1_age1)
by pandemic, sort: egen total_cf_p1_2_age1  = max(total_cf_p1_age1)
by pandemic, sort: egen total_cf_p2_2_age1  = max(total_cf_p2_age1)
gen paf_whole_acute_age1 = 100 * (total_obs_p2_2_age1 + total_obs_p1_2_age1 - ///
    total_cf_p2_2_age1 - total_cf_p1_2_age1) / ///
    (total_obs_p2_2_age1 + total_obs_p1_2_age1)
summarize paf_whole_acute_age1
display "Whole pandemic in kids: acute " r(mean) "%"

gen total_obs_age1 = pred_igas_p2_total_age1
replace total_obs_age1 = pred_igas_p1_total_age1 if total_obs_age1==. & pandemic==1
gen total_cf_age1 = pred_igas_no_sars_p2t_age1
replace total_cf_age1 = pred_igas_no_sars_p1t_age1 if total_cf_age1==. & pandemic==1
graph twoway line total_cf_age1 total_obs_age1 date if pandemic==1

* Acute + cumulative P1
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr coefl
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic
gen pred_igas_ac_no_sars_age1 = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.gender2]*(gender2==2) + ln(week_pop)) ///
    if pandemic1==1 & age2==1
predict pred_igas_ac_p1_age1 if pandemic1==1, n
sort date
by date, sort: egen pred_igas_ac_p1_total_age1   = sum(pred_igas_ac_p1_age1)     if pandemic1==1
by date, sort: egen pred_igas_no_sars_p1t_ac_age1 = sum(pred_igas_ac_no_sars_age1) if pandemic1==1
graph twoway line pred_igas_ac_p1_total_age1 date if pandemic==1 ///
    || line pred_igas_no_sars_p1t_ac_age1 date if pandemic1==1

egen total_obs_p1_ac_age1 = total(pred_igas_ac_p1_total_age1)    if pandemic1==1
egen total_cf_p1_ac_age1  = total(pred_igas_no_sars_p1t_ac_age1) if pandemic1==1
gen paf_p1_ac_age1 = 100 * (total_obs_p1_ac_age1 - total_cf_p1_ac_age1) / total_obs_p1_ac_age1
summarize paf_p1_ac_age1
display "Pandemic 1 acute and cumulative COVID PAF: " r(mean) "%"

* Acute + cumulative P2
nbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq i.gender2 ///
    if pandemic2==1 & age2==1, exp(week_pop) irr coefl
gen pred_igas_ac_no_sars_p2_age1 = exp(_b[_cons] + _b[sinwk]*sinwk + _b[coswk]*coswk + ///
    _b[week_sq]*week_sq + _b[2.gender2]*(gender2==2) + ln(week_pop)) if pandemic2==1
estat ic
predict pred_igas_ac_p2_age1 if pandemic2==1, n
sort date
by date, sort: egen pred_igas_ac_p2_total_age1    = sum(pred_igas_ac_p2_age1)        if pandemic2==1
by date, sort: egen pred_igas_no_sars_p2t_ac_age1 = sum(pred_igas_ac_no_sars_p2_age1) if pandemic2==1
graph twoway line pred_igas_ac_p2_total_age1 date if pandemic2==1 ///
    || line pred_igas_no_sars_p2t_ac_age1 date if pandemic2==1

egen total_obs_p2_ac_age1 = total(pred_igas_ac_p2_total_age1)    if pandemic2==1
egen total_cf_p2_ac_age1  = total(pred_igas_no_sars_p2t_ac_age1) if pandemic2==1
gen paf_p2_ac_age1 = 100 * (total_obs_p2_ac_age1 - total_cf_p2_ac_age1) / total_obs_p2_ac_age1
summarize paf_p2_ac_age1
display "Pandemic 2 acute and cumulative COVID PAF: " r(mean) "%"

* Whole pandemic: acute + cumulative
by pandemic, sort: egen total_obs_p2_ac_2_age1 = max(total_obs_p2_ac_age1)
by pandemic, sort: egen total_obs_p1_ac_2_age1 = max(total_obs_p1_ac_age1)
by pandemic, sort: egen total_cf_p1_ac_2_age1  = max(total_cf_p1_ac_age1)
by pandemic, sort: egen total_cf_p2_ac_2_age1  = max(total_cf_p2_ac_age1)
gen paf_whole_acute_cum_age1 = 100 * (total_obs_p2_ac_2_age1 + total_obs_p1_ac_2_age1 - ///
    total_cf_p2_ac_2_age1 - total_cf_p1_ac_2_age1) / ///
    (total_obs_p2_ac_2_age1 + total_obs_p1_ac_2_age1)
summarize paf_whole_acute_cum_age1
display "Whole pandemic: acute + cumulative " r(mean) "%"

gen total_obs_age1_ac = pred_igas_ac_p2_total_age1
replace total_obs_age1_ac = pred_igas_ac_p1_total_age1 if total_obs_age1_ac==. & pandemic==1
gen total_cf_age1_ac = pred_igas_no_sars_p2t_ac_age1
replace total_cf_age1_ac = pred_igas_no_sars_p1t_ac_age1 if total_cf_age1_ac==. & pandemic==1
graph twoway line total_cf_age1_ac total_obs_age1_ac date if pandemic==1


* --- 12.2 Adults (age2 == 2) — same structure as kids ----------------------
* [Code follows identical pattern to children section above with _age2 suffix]
* Key models:
* Acute P1: nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 if pandemic1==1 & age2==2
* Acute P2: nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 if pandemic2==1 & age2==2
* Acute+cum P1: nbreg ... cum_norm_sars ... if pandemic1==1 & age2==2
* Acute+cum P2: nbreg ... cum_norm_sars ... if pandemic2==1 & age2==2
* [Full PAF calculation with _age2 variable suffix throughout]


* --- 12.3 Elderly (age2 == 3) — same structure --------------------------------
* Key models:
* Acute P1: nbreg week_igas sinwk l2_norm_sars coswk week_sq i.gender2 if pandemic1==1 & age2==3
* Acute P2: nbreg week_igas l2_norm_sars sinwk coswk week_sq i.gender2 if pandemic2==1 & age2==3
* Acute+cum P1: nbreg ... cum_norm_sars ... if pandemic1==1 & age2==3
* Acute+cum P2: nbreg ... cum_norm_sars ... if pandemic2==1 & age2==3
* [Full PAF calculation with _age3 variable suffix throughout]
* Note: display "Whole pandemic in elders: acute " r(mean) "%"


* =============================================================================
* SECTION 13: ADDITIONAL AGE-STRATIFIED xtnbreg MODELS
* (Reported in Supplementary Appendix 5)
* =============================================================================

* Children
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic1==1 & age2==1, exp(week_pop) irr
estat ic

sort panel series_week
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic2==1 & age2==1, exp(week_pop) irr
estat ic

* Adults
sort panel series_week
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic1==1 & age2==2, exp(week_pop) irr
estat ic

sort panel series_week
xtnbreg week_igas l2_norm_sars sinwk coswk week_sq ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic
xtnbreg week_igas l2_norm_sars cum_norm_sars sinwk coswk week_sq ///
    if pandemic2==1 & age2==2, exp(week_pop) irr
estat ic
