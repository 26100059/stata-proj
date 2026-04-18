/*===========================================================================
  World Happiness Data Cleaning Script (2015-2019)
  Stata equivalent of Python cleaning pipeline

  Raw CSVs  -> C:\Users\KRONOS\Desktop\stata-proj\01 Data\Raw\
  Cleaned   -> C:\Users\KRONOS\Desktop\stata-proj\01 Data\Cleaned\

  COMMON COLUMNS KEPT (present in all 5 years):
    country, happiness_rank, happiness_score, gdp_per_capita,
    social_support, life_expectancy, freedom, generosity, corruption, year

  NOTE: dystopia_residual is dropped -- absent in 2018 and 2019.

  HOW STATA NAMES VARIABLES ON IMPORT (import delimited):
    - All letters lowercased
    - Spaces, dots, parentheses, commas all removed
    Examples:
      "Economy (GDP per Capita)"       -> economygdppercapita
      "Trust (Government Corruption)"  -> trustgovernmentcorruption
      "Happiness.Score"                -> happinessscore
      "Country or region"              -> countryorregion
      "Overall rank"                   -> overallrank
===========================================================================*/

clear all
set more off

* Edit these two locals if your folder structure changes
local raw_path   "C:\Users\KRONOS\Desktop\stata-proj\01 Data\Raw"
local clean_path "C:\Users\KRONOS\Desktop\stata-proj\01 Data\Cleaned"


/*---------------------------------------------------------------------------
  SECTION 1 -- HELPER PROGRAM
  Called after renaming in each year block.
  Coerces numerics, lowercases country, keeps only common columns.
---------------------------------------------------------------------------*/
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


/*---------------------------------------------------------------------------
  SECTION 2 -- PER-YEAR: LOAD -> RENAME -> CLEAN -> SAVE

  Stata-generated names after import delimited are listed in comments.
  If a rename fails, run:
      import delimited "...\YEAR.csv", varnames(1) clear
      describe
  and match what you see to the rename commands below.
---------------------------------------------------------------------------*/

* -- 2015 -------------------------------------------------------------------
* Raw:   Country | Region | Happiness Rank | Happiness Score |
*        Standard Error | Economy (GDP per Capita) | Family |
*        Health (Life Expectancy) | Freedom |
*        Trust (Government Corruption) | Generosity | Dystopia Residual
* Stata: country | region | happinessrank | happinessscore |
*        standarderror | economygdppercapita | family |
*        healthlifeexpectancy | freedom |
*        trustgovernmentcorruption | generosity | dystopiaresidual

import delimited "`raw_path'\2015.csv", varnames(1) clear

rename happinessrank             happiness_rank
rename happinessscore            happiness_score
rename economygdppercapita       gdp_per_capita
rename family                    social_support
rename healthlifeexpectancy      life_expectancy
rename trustgovernmentcorruption corruption
* freedom, generosity, country already have correct names

drop region standarderror dystopiaresidual

clean_common 2015
save "`clean_path'\2015.dta", replace
display "2015 saved"


* -- 2016 -------------------------------------------------------------------
* Raw:   Country | Region | Happiness Rank | Happiness Score |
*        Lower Confidence Interval | Upper Confidence Interval |
*        Economy (GDP per Capita) | Family | Health (Life Expectancy) |
*        Freedom | Trust (Government Corruption) | Generosity |
*        Dystopia Residual
* Stata: country | region | happinessrank | happinessscore |
*        lowerconfidenceinterval | upperconfidenceinterval |
*        economygdppercapita | family | healthlifeexpectancy |
*        freedom | trustgovernmentcorruption | generosity | dystopiaresidual

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
* Raw (dot-separated, quoted):
*        Country | Happiness.Rank | Happiness.Score | Whisker.high |
*        Whisker.low | Economy..GDP.per.Capita. | Family |
*        Health..Life.Expectancy. | Freedom | Generosity |
*        Trust..Government.Corruption. | Dystopia.Residual
* Stata strips all dots ->
*        country | happinessrank | happinessscore | whiskerhigh |
*        whiskerlow | economygdppercapita | family |
*        healthlifeexpectancy | freedom | generosity |
*        trustgovernmentcorruption | dystopiaresidual

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
* Raw:   Overall rank | Country or region | Score | GDP per capita |
*        Social support | Healthy life expectancy |
*        Freedom to make life choices | Generosity |
*        Perceptions of corruption
* Stata: overallrank | countryorregion | score | gdppercapita |
*        socialsupport | healthylifeexpectancy |
*        freedomtomakelifechoices | generosity | perceptionsofcorruption

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


/*---------------------------------------------------------------------------
  SECTION 3 -- BUILD MASTER FILE
---------------------------------------------------------------------------*/
use "`clean_path'\2015.dta", clear

foreach yr in 2016 2017 2018 2019 {
    append using "`clean_path'\\`yr'.dta"
}

duplicates drop

* Country name corrections (one replace per line -- avoids local quoting issues)
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


/*---------------------------------------------------------------------------
  SECTION 4 -- VALIDATION REPORT
---------------------------------------------------------------------------*/
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


/*---------------------------------------------------------------------------
  SECTION 5 -- SAVE MASTER
---------------------------------------------------------------------------*/
save "`clean_path'\master_happiness.dta", replace
display _newline "Master dataset saved -> `clean_path'\master_happiness.dta"
display "Done."
