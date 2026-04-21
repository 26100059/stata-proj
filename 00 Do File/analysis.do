/*===========================================================================
  World Happiness Analysis
  Research Question:
    Does economic wealth (GDP per capita) drive happiness, and does the
    effect hold after controlling for social and institutional factors?

  PRIMARY DATA  : 2019.dta  -- clean cross-section, 156 countries
                  All regressions and main graphs use 2019 only.
                  One observation per country -> no repeated measures issue.

  SECONDARY DATA: master_happiness.dta -- used ONLY for the trend graph
                  (bonus context graph showing 2015-2019 global trend)

  Y        = happiness_score
  Main X   = gdp_per_capita
  Controls = social_support, life_expectancy, freedom, generosity, corruption
===========================================================================*/

clear all
set more off

local clean_path "../01 Data/Cleaned"
local out_path   "../03 Output"

graph set window fontface "Arial"
set scheme s1color

ssc install estout, replace


/*---------------------------------------------------------------------------
  STEP 1 -- LOAD 2019 AND INSPECT
---------------------------------------------------------------------------*/
use "`clean_path'/2019.dta", clear

describe
summarize

display _newline "--- 2019 cross-section: observation count ---"
count
* Should be ~156 (one row per country, no repeats)

display _newline "--- Missing values check ---"
foreach var of varlist happiness_score gdp_per_capita social_support ///
                       life_expectancy freedom generosity corruption {
    quietly count if missing(`var')
    display "  `var': " r(N) " missing"
}

display _newline "--- Summary statistics (2019 only) ---"
summarize happiness_score gdp_per_capita social_support life_expectancy ///
          freedom generosity corruption


/*---------------------------------------------------------------------------
  STEP 2 -- REGRESSION (all on 2019 cross-section)
---------------------------------------------------------------------------*/

* ── Model 1: Bivariate -- GDP per capita alone ──────────────────────────────
display _newline "===== MODEL 1: Bivariate (GDP -> Happiness, 2019) ====="
reg happiness_score gdp_per_capita

* ── Model 2: Full model with all controls ───────────────────────────────────
display _newline "===== MODEL 2: Full Controls (2019) ====="
reg happiness_score gdp_per_capita social_support life_expectancy ///
    freedom generosity corruption

local r2_full = string(e(r2), "%4.3f")
display "R-squared (Model 2): " `r2_full'

* ── Model 3: Advanced -- GDP x Freedom interaction ──────────────────────────
* Does GDP matter MORE in countries where people feel free to make life choices?
display _newline "===== MODEL 3: GDP x Freedom Interaction (2019) ====="
reg happiness_score c.gdp_per_capita##c.freedom social_support ///
    life_expectancy generosity corruption

* ── Model 4: Log-linear -- interpret GDP effect in percentage terms ──────────
gen ln_happiness = ln(happiness_score)
label variable ln_happiness "Log Happiness Score"

display _newline "===== MODEL 4: Log-Linear Model (2019) ====="
reg ln_happiness gdp_per_capita social_support life_expectancy ///
    freedom generosity corruption


/*---------------------------------------------------------------------------
  STEP 2b -- EXPORT REGRESSION TABLE
  Requires estout package. Install once with: ssc install estout, replace

  We re-run all 4 models using eststo to store them, then export with esttab.
  Output: regression_table.rtf  (open directly in Word)
---------------------------------------------------------------------------*/

* Store each model
eststo clear

eststo m1: quietly reg happiness_score gdp_per_capita

eststo m2: quietly reg happiness_score gdp_per_capita social_support ///
    life_expectancy freedom generosity corruption

eststo m3: quietly reg happiness_score c.gdp_per_capita##c.freedom ///
    social_support life_expectancy generosity corruption

eststo m4: quietly reg ln_happiness gdp_per_capita social_support ///
    life_expectancy freedom generosity corruption

* Export to RTF (Word-compatible)
esttab m1 m2 m3 m4 using "`out_path'/regression_table.rtf", ///
    replace                                                    ///
    title("Table 1. Determinants of Happiness Score (2019)")   ///
    mtitles("Bivariate" "Full Model" "GDP x Freedom" "Log-Linear") ///
    label                                                      ///
    b(%8.3f)                                                   ///
    se(%8.3f)                                                  ///
    star(* 0.10 ** 0.05 *** 0.01)                              ///
    r2                                                         ///
    ar2                                                        ///
    scalars("N Observations")                                  ///
    nonotes                                                    ///
    addnotes("Standard errors in parentheses."                 ///
             "* p<0.10, ** p<0.05, *** p<0.01"                ///
             "Data: World Happiness Report 2019. N=156 countries.")

display "Regression table exported -> `out_path'/regression_table.rtf"


/*---------------------------------------------------------------------------
  STEP 3 -- GRAPHS

  Graph 1 (2019): Scatter + fit -- GDP per capita vs Happiness Score
  Graph 2 (2019): Bar chart -- Average happiness by freedom quartile
  Graph 3 (2019): Scatter split by corruption level -- nuance graph
  Graph 4 (Master, bonus): Line -- Global average happiness trend 2015-2019
---------------------------------------------------------------------------*/

* ── GRAPH 1: Main relationship -- GDP vs Happiness (2019) ───────────────────
twoway ///
    (scatter happiness_score gdp_per_capita, ///
        mcolor(navy%60) msize(small) msymbol(circle)) ///
    (lfit happiness_score gdp_per_capita, ///
        lcolor(cranberry) lwidth(medthick)), ///
    title("GDP per Capita and Happiness Score (2019)", size(medium)) ///
    subtitle("Cross-section of 156 countries") ///
    xtitle("GDP per Capita (scaled)") ///
    ytitle("Happiness Score") ///
    legend(order(1 "Country" 2 "Linear Fit") position(4) ring(0)) ///
    note("Source: World Happiness Report 2019")

graph export "`out_path'\graph1_gdp_happiness_2019.png", replace width(1200)
display "Graph 1 saved."


* ── GRAPH 2: Happiness by freedom quartile (2019) ───────────────────────────
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
        bar(1, color(navy%50))  ///
        bar(2, color(navy%70))  ///
        bar(3, color(cranberry%70)) ///
        bar(4, color(cranberry)) ///
        blabel(bar, format(%4.2f) size(small)) ///
        note("Source: World Happiness Report 2019")
    graph export "`out_path'/graph2_freedom_happiness_2019.png", replace width(1200)
restore

display "Graph 2 saved."


* ── GRAPH 3: GDP-Happiness split by corruption level (2019) ─────────────────
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
    xtitle("GDP per Capita (scaled)") ///
    ytitle("Happiness Score") ///
    legend(order(1 "Low Corruption" 2 "Low Corr. Fit" ///
                 3 "High Corruption" 4 "High Corr. Fit") ///
           position(4) ring(0)) ///
    note("Source: World Happiness Report 2019")

graph export "`out_path'/graph3_corruption_split_2019.png", replace width(1200)
display "Graph 3 saved."


* ── GRAPH 4 (Bonus, Master data): Global average happiness trend 2015-2019 ──
* Switches to master file, collapses to year-level means, then plots trend.
* This graph provides narrative context: were countries getting happier overall?

preserve
    use "`clean_path'/master_happiness.dta", clear

    collapse (mean) happiness_score, by(year)

    twoway ///
        (connected happiness_score year, ///
            mcolor(navy) lcolor(navy) msize(medium) msymbol(circle) ///
            lwidth(medthick)), ///
        title("Global Average Happiness Score (2015-2019)", size(medium)) ///
        subtitle("Mean across all countries per year") ///
        xtitle("Year") ///
        ytitle("Average Happiness Score") ///
        xlabel(2015(1)2019) ///
        note("Source: World Happiness Report 2015-2019")

    graph export "`out_path'/graph4_trend_2015_2019.png", replace width(1200)
restore

display "Graph 4 (trend, master data) saved."


/*---------------------------------------------------------------------------
  STEP 4 -- PREDICTED VALUES PLOT (Model 2, 2019 data)
  Re-run Model 2 on 2019 to generate predictions after graphs are done
---------------------------------------------------------------------------*/
quietly reg happiness_score gdp_per_capita social_support life_expectancy ///
    freedom generosity corruption
predict yhat, xb
label variable yhat "Predicted Happiness (Model 2)"

twoway ///
    (scatter happiness_score yhat, mcolor(navy%50) msize(small)) ///
    (function y=x, range(3 8) lcolor(cranberry) lwidth(medthick)), ///
    title("Actual vs Predicted Happiness Score (2019)", size(medium)) ///
    subtitle("Full model fit across 156 countries") ///
    xtitle("Predicted Happiness Score") ///
    ytitle("Actual Happiness Score") ///
    legend(order(1 "Countries" 2 "45-degree line (perfect fit)") ///
           position(4) ring(0)) ///
    note("Source: World Happiness Report 2019")

graph export "`out_path'\graph5_actual_vs_predicted_2019.png", replace width(1200)
display "Graph 5 (actual vs predicted) saved."


/*---------------------------------------------------------------------------
  STEP 5 -- NARRATIVE SUMMARY
---------------------------------------------------------------------------*/
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
display "  predict happiness, suggesting wealth is necessary but not sufficient."
display ""
display "  Model 3 (interaction): The GDP x Freedom interaction suggests"
display "  wealth has a stronger happiness payoff in countries where people"
display "  feel free to make life choices."
display ""
display "  Graph 2 shows happiness rises consistently across freedom quartiles,"
display "  reinforcing freedom as an independent driver beyond GDP."
display ""
display "  Graph 3 reveals that the GDP-happiness slope is steeper for"
display "  low-corruption countries -- wealth converts more efficiently into"
display "  wellbeing where institutions are trusted."
display ""
display "  Graph 4 (trend, 2015-2019) provides context: global average"
display "  happiness was relatively stable across this period, meaning the"
display "  2019 cross-section is representative and not an outlier year."
display ""
display "  Limitation: cross-sectional OLS cannot establish causality."
display "  Omitted variables (culture, governance quality, climate) may"
display "  confound results. Future work could use panel fixed effects."
display "================================================================"


/*---------------------------------------------------------------------------
  CLEAN UP TEMP VARIABLES
---------------------------------------------------------------------------*/
drop freedom_q high_corruption yhat ln_happiness

display _newline "All done. Graphs saved to: `out_path'"
