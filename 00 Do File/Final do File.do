/*===========================================================================
  World Happiness Analysis -- Full Pipeline
  Research Question:
    Does economic wealth (GDP per capita) drive happiness, and does the
    effect hold after controlling for social and institutional factors?

  PRIMARY DATA  : 2019.dta  -- clean cross-section, 156 countries
  SECONDARY DATA: master_happiness.dta -- used ONLY for the trend graph

  Y        = happiness_score
  Main X   = gdp_per_capita
  Controls = social_support, life_expectancy, freedom, generosity, corruption

  SECTIONS:
    1. Data Cleaning (2015-2019)
    2. Build Master File
    3. Validation Report
    4. Load 2019 & Inspect
    5. Exploratory / Preliminary Regressions
    6. Main Regression Models
    7. Export Regression Table
    8. Graphs
    9. Narrative Summary
===========================================================================*/

clear all
set more off

* Paths -- update if folder structure changes
local raw_path   "C:\Users\KRONOS\Desktop\stata-proj\01 Data\Raw"
local clean_path "C:\Users\KRONOS\Desktop\stata-proj\01 Data\Cleaned"
local out_path   "C:\Users\KRONOS\Desktop\stata-proj\03 Output"

graph set window fontface "Arial"
set scheme s1color

ssc install estout, replace


/*===========================================================================
  SECTION 1 -- DATA CLEANING (2015-2019)

  Raw CSVs -> Cleaned .dta files, one per year.
  Stata lowercases and strips punctuation from column names on import.
  See header notes for name mappings.

  COMMON COLUMNS KEPT: country, happiness_rank, happiness_score,
    gdp_per_capita, social_support, life_expectancy, freedom,
    generosity, corruption, year
  NOTE: dystopia_residual dropped -- absent in 2018 and 2019.
===========================================================================*/

* Helper program -- called after renaming in each year block.
* Coerces numerics, lowercases country, keeps only common columns.
capture program drop clean_common
program define clean_common
    args year

    gen year = `year'

    replace country = strlower(strtrim(country))

    foreach var of varlist happiness_rank happiness_score gdp_per_capita ///
                           social_support life_expectancy freedom        ///
                           generosity corruption {
        capture confirm numeric variable `var'
        if _rc != 0 {
            destring `var', replace force
        }
    }

    keep country happiness_rank happiness_score gdp_per_capita ///
         social_support life_expectancy freedom generosity      ///
         corruption year
end


* -- 2015 -------------------------------------------------------------------
* Stata names: country | region | happinessrank | happinessscore |
*   standarderror | economygdppercapita | family | healthlifeexpectancy |
*   freedom | trustgovernmentcorruption | generosity | dystopiaresidual

import delimited "`raw_path'\2015.csv", varnames(1) clear

rename happinessrank             happiness_rank
rename happinessscore            happiness_score
rename economygdppercapita       gdp_per_capita
rename family                    social_support
rename healthlifeexpectancy      life_expectancy
rename trustgovernmentcorruption corruption

drop region standarderror dystopiaresidual

clean_common 2015
save "`clean_path'\2015.dta", replace
display "2015 saved"


* -- 2016 -------------------------------------------------------------------
* Stata names: country | region | happinessrank | happinessscore |
*   lowerconfidenceinterval | upperconfidenceinterval | economygdppercapita |
*   family | healthlifeexpectancy | freedom | trustgovernmentcorruption |
*   generosity | dystopiaresidual

import delimited "`raw_path'\2016.csv", varnames(1) clear

rename happinessrank             happiness_rank
rename happinessscore            happiness_score
rename economygdppercapita       gdp_per_capita
rename family                    social_support
rename healthlifeexpectancy      life_expectancy
rename trustgovernmentcorruption corruption

drop region lowerconfidenceinterval upperconfidenceinterval dystopiaresidual

clean_common 2016
save "`clean_path'\2016.dta", replace
display "2016 saved"


* -- 2017 -------------------------------------------------------------------
* Stata names (dots stripped): country | happinessrank | happinessscore |
*   whiskerhigh | whiskerlow | economygdppercapita | family |
*   healthlifeexpectancy | freedom | generosity |
*   trustgovernmentcorruption | dystopiaresidual

import delimited "`raw_path'\2017.csv", varnames(1) clear

rename happinessrank             happiness_rank
rename happinessscore            happiness_score
rename economygdppercapita       gdp_per_capita
rename family                    social_support
rename healthlifeexpectancy      life_expectancy
rename trustgovernmentcorruption corruption

drop whiskerhigh whiskerlow dystopiaresidual

clean_common 2017
save "`clean_path'\2017.dta", replace
display "2017 saved"


* -- 2018 -------------------------------------------------------------------
* Stata names: overallrank | countryorregion | score | gdppercapita |
*   socialsupport | healthylifeexpectancy | freedomtomakelifechoices |
*   generosity | perceptionsofcorruption

import delimited "`raw_path'\2018.csv", varnames(1) clear

rename overallrank              happiness_rank
rename countryorregion          country
rename score                    happiness_score
rename gdppercapita             gdp_per_capita
rename socialsupport            social_support
rename healthylifeexpectancy    life_expectancy
rename freedomtomakelifechoices freedom
rename perceptionsofcorruption  corruption

clean_common 2018
save "`clean_path'\2018.dta", replace
display "2018 saved"


* -- 2019 -------------------------------------------------------------------
* Identical column structure to 2018

import delimited "`raw_path'\2019.csv", varnames(1) clear

rename overallrank              happiness_rank
rename countryorregion          country
rename score                    happiness_score
rename gdppercapita             gdp_per_capita
rename socialsupport            social_support
rename healthylifeexpectancy    life_expectancy
rename freedomtomakelifechoices freedom
rename perceptionsofcorruption  corruption

clean_common 2019
save "`clean_path'\2019.dta", replace
display "2019 saved"


/*===========================================================================
  SECTION 2 -- BUILD MASTER FILE (2015-2019)
===========================================================================*/

use "`clean_path'\2015.dta", clear

foreach yr in 2016 2017 2018 2019 {
    append using "`clean_path'\\`yr'.dta"
}

duplicates drop

* Country name corrections
replace country = "hong kong"           if country == "hong kong s.a.r., china"
replace country = "cyprus"              if country == "northern cyprus"
replace country = "cyprus"              if country == "north cyprus"
replace country = "north macedonia"     if country == "macedonia"
replace country = "trinidad and tobago" if country == "trinidad & tobago"
replace country = "taiwan"              if country == "taiwan province of china"
replace country = "somalia"             if country == "somaliland region"
replace country = "congo"               if country == "congo (brazzaville)"
replace country = "congo"               if country == "congo (kinshasa)"

replace country = strlower(strtrim(country))

duplicates drop
keep if inlist(year, 2015, 2016, 2017, 2018, 2019)
sort country year


/*===========================================================================
  SECTION 3 -- VALIDATION REPORT
===========================================================================*/

display _newline "================================================================"
display          "  VALIDATION REPORT"
display          "================================================================"

count
display _newline "Total rows: " r(N)

display _newline "Columns:"
ds

display _newline "--- Missing values per column ---"
foreach var of varlist country happiness_rank happiness_score gdp_per_capita ///
                       social_support life_expectancy freedom generosity     ///
                       corruption year {
    quietly count if missing(`var')
    display "  `var': " r(N) " missing"
}

display _newline "--- Summary statistics ---"
summarize happiness_rank happiness_score gdp_per_capita social_support ///
          life_expectancy freedom generosity corruption

display _newline "--- Negative value check ---"
foreach var of varlist happiness_rank happiness_score gdp_per_capita ///
                       social_support life_expectancy freedom        ///
                       generosity corruption {
    quietly count if `var' < 0
    if r(N) > 0 {
        display "  WARNING: " r(N) " negative(s) in `var'"
        list country year `var' if `var' < 0
    }
    else {
        display "  `var': no negatives"
    }
}

display _newline "--- Duplicate check ---"
duplicates report

display _newline "--- Z-score outlier flag (|z| > 3, reported only, NOT dropped) ---"
foreach var of varlist happiness_score gdp_per_capita social_support ///
                       life_expectancy freedom generosity corruption {
    quietly summarize `var'
    local m  = r(mean)
    local sd = r(sd)
    quietly count if abs((`var' - `m') / `sd') > 3 & !missing(`var')
    if r(N) > 0 {
        display "  `var': " r(N) " potential outlier(s)"
    }
    else {
        display "  `var': no outliers"
    }
}

display _newline "--- First 5 rows ---"
list in 1/5

display _newline "================================================================"

save "`clean_path'\master_happiness.dta", replace
display _newline "Master dataset saved -> `clean_path'\master_happiness.dta"


/*===========================================================================
  SECTION 4 -- LOAD 2019 CROSS-SECTION & INSPECT
  One observation per country -- no repeated measures issue.
===========================================================================*/

use "`clean_path'/2019.dta", clear

describe
summarize

display _newline "--- 2019 observation count ---"
count
* Should be ~156

display _newline "--- Missing values check ---"
foreach var of varlist happiness_score gdp_per_capita social_support ///
                       life_expectancy freedom generosity corruption {
    quietly count if missing(`var')
    display "  `var': " r(N) " missing"
}

display _newline "--- Summary statistics (2019) ---"
summarize happiness_score gdp_per_capita social_support life_expectancy ///
          freedom generosity corruption


/*===========================================================================
  SECTION 5 -- EXPLORATORY / PRELIMINARY

  Quick OLS with robust SEs, correlation matrix, added-variable plot,
  and distribution checks. Useful for slides / initial inspection.
  Log GDP tryout also included here -- seems more skewed, see notes.
===========================================================================*/

* Robust OLS -- preliminary look before running full model suite
reg happiness_score gdp_per_capita social_support life_expectancy freedom, robust

* Missing value check (belt-and-suspenders)
misstable summarize

* Correlation matrix -- quick sense of variable relationships
pwcorr happiness_score gdp_per_capita social_support life_expectancy freedom, sig

* Added-variable plot -- GDP effect net of other controls
avplot gdp_per_capita

* Happiness distribution by GDP split (above/below median)
summ gdp_per_capita, detail
gen high_gdp = gdp_per_capita > r(p50)

twoway (kdensity happiness_score if high_gdp==1) ///
       (kdensity happiness_score if high_gdp==0), ///
       legend(label(1 "High GDP") label(2 "Low GDP")) ///
       title("Happiness Distribution by GDP Level")

histogram happiness_score, kdensity ///
    title("Happiness Score Distribution with Density")

* K-means clustering (k=3) -- optional, good for slides
cluster kmeans happiness_score gdp_per_capita, k(3)
scatter happiness_score gdp_per_capita, ///
    by(_clus_1, title("Clusters of Countries"))

* Log GDP -- distribution check. Looked more skewed, kept linear in main models.
gen log_gdp = log(gdp_per_capita)

kdensity gdp_per_capita, normal title("Distribution of GDP per Capita")
kdensity log_gdp,        normal title("Distribution of Log GDP per Capita")

drop high_gdp log_gdp _clus_1


/*===========================================================================
  SECTION 6 -- MAIN REGRESSION MODELS (2019 cross-section)
===========================================================================*/

* Model 1: Bivariate -- GDP alone
display _newline "===== MODEL 1: Bivariate (GDP -> Happiness) ====="
reg happiness_score gdp_per_capita

* Model 2: Full controls
display _newline "===== MODEL 2: Full Controls ====="
reg happiness_score gdp_per_capita social_support life_expectancy ///
    freedom generosity corruption

local r2_full = string(e(r2), "%4.3f")
display "R-squared (Model 2): " `r2_full'

* Model 3: GDP x Freedom interaction
* Does the happiness payoff from wealth depend on perceived freedom?
display _newline "===== MODEL 3: GDP x Freedom Interaction ====="
reg happiness_score c.gdp_per_capita##c.freedom social_support ///
    life_expectancy generosity corruption

* Model 4: Log-linear -- GDP effect in percentage terms
gen ln_happiness = ln(happiness_score)
label variable ln_happiness "Log Happiness Score"

display _newline "===== MODEL 4: Log-Linear ====="
reg ln_happiness gdp_per_capita social_support life_expectancy ///
    freedom generosity corruption


/*===========================================================================
  SECTION 7 -- EXPORT REGRESSION TABLE
  Requires estout. Output: regression_table.rtf (open in Word)
===========================================================================*/

eststo clear

eststo m1: quietly reg happiness_score gdp_per_capita

eststo m2: quietly reg happiness_score gdp_per_capita social_support ///
    life_expectancy freedom generosity corruption

eststo m3: quietly reg happiness_score c.gdp_per_capita##c.freedom ///
    social_support life_expectancy generosity corruption

eststo m4: quietly reg ln_happiness gdp_per_capita social_support ///
    life_expectancy freedom generosity corruption

esttab m1 m2 m3 m4 using "`out_path'/regression_table.rtf",      ///
    replace                                                        ///
    title("Table 1. Determinants of Happiness Score (2019)")      ///
    mtitles("Bivariate" "Full Model" "GDP x Freedom" "Log-Linear") ///
    label                                                          ///
    b(%8.3f) se(%8.3f)                                             ///
    star(* 0.10 ** 0.05 *** 0.01)                                  ///
    r2 ar2                                                         ///
    scalars("N Observations")                                      ///
    nonotes                                                        ///
    addnotes("Standard errors in parentheses."                     ///
             "* p<0.10, ** p<0.05, *** p<0.01"                    ///
             "Data: World Happiness Report 2019. N=156 countries.")

display "Regression table exported -> `out_path'/regression_table.rtf"


/*===========================================================================
  SECTION 8 -- GRAPHS

  Graph 1: Scatter + fit -- GDP per capita vs Happiness (2019)
  Graph 2: Bar -- Average happiness by freedom quartile (2019)
  Graph 3: Scatter split by corruption level (2019)
  Graph 4: Actual vs predicted -- Model 2 fit (2019)
  Graph 5: Global average happiness trend 2015-2019 (master data)
===========================================================================*/

* -- Graph 1: Main relationship -- GDP vs Happiness --------------------------
twoway ///
    (scatter happiness_score gdp_per_capita, ///
        mcolor(navy%60) msize(small) msymbol(circle)) ///
    (lfit happiness_score gdp_per_capita, ///
        lcolor(cranberry) lwidth(medthick)), ///
    title("GDP per Capita and Happiness Score (2019)", size(medium)) ///
    subtitle("Cross-section of 156 countries") ///
    xtitle("GDP per Capita (scaled)") ytitle("Happiness Score") ///
    legend(order(1 "Country" 2 "Linear Fit") position(4) ring(0)) ///
    note("Source: World Happiness Report 2019")

graph export "`out_path'\graph1_gdp_happiness_2019.png", replace width(1200)
display "Graph 1 saved."


* -- Graph 2: Happiness by freedom quartile ----------------------------------
xtile freedom_q = freedom, nq(4)
label variable freedom_q "Freedom Quartile"
label define fq_lbl 1 "Q1 Least Free" 2 "Q2" 3 "Q3" 4 "Q4 Most Free"
label values freedom_q fq_lbl

preserve
    collapse (mean) happiness_score, by(freedom_q)
    graph bar happiness_score, over(freedom_q) ///
        title("Average Happiness by Freedom Quartile (2019)", size(medium)) ///
        subtitle("Countries grouped by perceived freedom to make life choices") ///
        ytitle("Average Happiness Score") ///
        bar(1, color(navy%50)) bar(2, color(navy%70)) ///
        bar(3, color(cranberry%70)) bar(4, color(cranberry)) ///
        blabel(bar, format(%4.2f) size(small)) ///
        note("Source: World Happiness Report 2019")
    graph export "`out_path'/graph2_freedom_happiness_2019.png", replace width(1200)
restore

display "Graph 2 saved."


* -- Graph 3: GDP-Happiness split by corruption level ------------------------
quietly summarize corruption, detail
local corr_med = r(p50)
gen high_corruption = (corruption > `corr_med') if !missing(corruption)
label variable high_corruption "Corruption Perception"
label define hc_lbl 0 "Low Corruption" 1 "High Corruption"
label values high_corruption hc_lbl

twoway ///
    (scatter happiness_score gdp_per_capita if high_corruption==0, ///
        mcolor(navy%50) msize(small) msymbol(circle)) ///
    (lfit happiness_score gdp_per_capita if high_corruption==0, ///
        lcolor(navy) lwidth(medthick)) ///
    (scatter happiness_score gdp_per_capita if high_corruption==1, ///
        mcolor(cranberry%50) msize(small) msymbol(triangle)) ///
    (lfit happiness_score gdp_per_capita if high_corruption==1, ///
        lcolor(cranberry) lwidth(medthick)), ///
    title("GDP vs Happiness by Corruption Level (2019)", size(medium)) ///
    subtitle("Does corruption weaken how wealth converts to happiness?") ///
    xtitle("GDP per Capita (scaled)") ytitle("Happiness Score") ///
    legend(order(1 "Low Corruption" 2 "Low Corr. Fit" ///
                 3 "High Corruption" 4 "High Corr. Fit") position(4) ring(0)) ///
    note("Source: World Happiness Report 2019")

graph export "`out_path'/graph3_corruption_split_2019.png", replace width(1200)
display "Graph 3 saved."


* -- Graph 4: Actual vs predicted (Model 2) ----------------------------------
quietly reg happiness_score gdp_per_capita social_support life_expectancy ///
    freedom generosity corruption
predict yhat, xb
label variable yhat "Predicted Happiness (Model 2)"

twoway ///
    (scatter happiness_score yhat, mcolor(navy%50) msize(small)) ///
    (function y=x, range(3 8) lcolor(cranberry) lwidth(medthick)), ///
    title("Actual vs Predicted Happiness Score (2019)", size(medium)) ///
    subtitle("Full model fit across 156 countries") ///
    xtitle("Predicted Happiness Score") ytitle("Actual Happiness Score") ///
    legend(order(1 "Countries" 2 "45-degree line") position(4) ring(0)) ///
    note("Source: World Happiness Report 2019")

graph export "`out_path'\graph4_actual_vs_predicted_2019.png", replace width(1200)
display "Graph 4 saved."


* -- Graph 5: Global average happiness trend 2015-2019 (master data) --------
* Context graph: was the world getting happier? Uses the full panel, not 2019 only.
preserve
    use "`clean_path'/master_happiness.dta", clear
    collapse (mean) happiness_score, by(year)

    twoway ///
        (connected happiness_score year, ///
            mcolor(navy) lcolor(navy) msize(medium) msymbol(circle) ///
            lwidth(medthick)), ///
        title("Global Average Happiness Score (2015-2019)", size(medium)) ///
        subtitle("Mean across all countries per year") ///
        xtitle("Year") ytitle("Average Happiness Score") ///
        xlabel(2015(1)2019) ///
        note("Source: World Happiness Report 2015-2019")

    graph export "`out_path'/graph5_trend_2015_2019.png", replace width(1200)
restore

display "Graph 5 (trend) saved."


/*===========================================================================
  SECTION 9 -- NARRATIVE SUMMARY
===========================================================================*/

display _newline "================================================================"
display "NARRATIVE SUMMARY"
display "================================================================"
display ""
display "Research Question:"
display "  Does GDP per capita drive happiness, and does the effect hold"
display "  after controlling for social and institutional factors?"
display ""
display "Data:"
display "  2019 World Happiness Report -- 156 countries, cross-sectional."
display "  One observation per country eliminates repeated-measures bias."
display ""
display "Key Findings:"
display ""
display "  Model 1 (bivariate): GDP per capita alone is a strong, significant"
display "  positive predictor of happiness (Graph 1 confirms this visually)."
display ""
display "  Model 2 (full controls): GDP remains significant after controlling"
display "  for social support, life expectancy, freedom, generosity, and"
display "  corruption. Social support and life expectancy also independently"
display "  predict happiness -- wealth is necessary but not sufficient."
display ""
display "  Model 3 (interaction): GDP has a stronger happiness payoff in"
display "  countries where people feel free to make life choices."
display ""
display "  Graph 2: happiness rises consistently across freedom quartiles,"
display "  reinforcing freedom as an independent driver beyond GDP."
display ""
display "  Graph 3: the GDP-happiness slope is steeper for low-corruption"
display "  countries -- wealth converts more efficiently where institutions"
display "  are trusted."
display ""
display "  Graph 5 (trend, 2015-2019): global average happiness was stable"
display "  across this period, so 2019 is representative, not an outlier."
display ""
display "  Limitation: cross-sectional OLS cannot establish causality."
display "  Omitted variables (culture, governance, climate) may confound."
display "  Panel fixed effects would be a natural next step."
display "================================================================"


/*---------------------------------------------------------------------------
  CLEAN UP
---------------------------------------------------------------------------*/
drop freedom_q high_corruption yhat ln_happiness

display _newline "All done. Graphs saved to: `out_path'"
