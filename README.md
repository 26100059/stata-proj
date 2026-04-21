# Stata Project

# Cleaning Pipeline

## Per-year files (2015–2019)

- Imports raw CSV with auto-detected encoding  
- Renames variables to standardised names across all years (since each CSV had different original column names)  
- Drops columns not common to all 5 years:  
  - `region`  
  - `standarderror`  
  - `dystopiaresidual` (2015/16)  
  - `whiskerhigh`, `whiskerlow` (2017)  
  - confidence interval columns (2016)  
- Adds a `year` variable to each observation  
- Lowercases and strips whitespace from the `country` string  
- Coerces any string-type numeric columns to actual numerics, with non-convertible values forced to missing (`.`)  
- Saves each year as a clean `.dta` file  

---

## Master file

- Appends all 5 yearly files into one dataset  
- Drops exact duplicate rows (first pass)  
- Applies country name corrections — 9 specific remappings:  
  - e.g. `hong kong s.a.r., china` → `hong kong`  
  - `macedonia` → `north macedonia`  
  - `congo (brazzaville)` and `congo (kinshasa)` → `congo`  
- Re-lowercases and strips `country` after corrections  
- Drops duplicates again (second pass, catches any created by name merging)  
- Drops any rows with years outside 2015–2019  
- Sorts by `country` then `year`  

---

## Validation checks (reported, nothing dropped)

- Total row count  
- Missing value count per column  
- Summary statistics for all numeric columns  
- Negative value check per numeric column  
- Duplicate row report  
- Z-score outlier flag:  
  - Rows where any numeric column has `|z| > 3` are counted and reported, but intentionally not removed  


# World Happiness Report — Stata Project
### Does Wealth Drive Happiness? (2015–2019)

---

## Overview

This project analyses the **World Happiness Report** dataset (2015–2019) using Stata. The goal is to answer a research question through data cleaning, regression analysis, and visual storytelling. The full pipeline is split into two do-files:

| File | Purpose |
|------|---------|
| `clean_happiness.do` | Cleans 5 raw CSVs and builds a master dataset |
| `analysis_happiness.do` | Runs regressions, exports a table, and produces graphs |

---

## Research Question

> **Does GDP per capita drive national happiness, and does the effect hold after controlling for social and institutional factors?**

---

## Folder Structure

```
stata-proj/
├── 01 Data/
│   ├── Raw/          ← original CSVs from Kaggle (2015.csv … 2019.csv)
│   └── Cleaned/      ← output of clean_happiness.do
│       ├── 2015.dta
│       ├── 2016.dta
│       ├── 2017.dta
│       ├── 2018.dta
│       ├── 2019.dta
│       └── master_happiness.dta
├── 03 Output/        ← regression table (.rtf) and graphs (.png)
├── clean_happiness.do
└── analysis_happiness.do
```

---

## File 1 — `clean_happiness.do`

### What it does

Takes 5 raw CSVs from Kaggle and produces 5 clean `.dta` files plus one combined master file. Every step is explained below.

---

### Why 5 separate files?

The Kaggle dataset comes as one CSV per year, not one combined file. Each year also has **different column names** — for example, what is called `Family` in 2015/2016 is called `Social support` in 2018/2019, and 2017 uses dot-separated names like `Happiness.Score`. Cleaning them individually before combining ensures each year is handled correctly before anything is merged.

---

### Step-by-step breakdown

#### Section 1 — Helper program `clean_common`

A reusable program that runs the same post-rename logic on every year's data:

- **Adds a `year` variable** so that once all years are combined, every row knows which year it belongs to.
- **Lowercases and strips whitespace from `country`** — raw data has inconsistent capitalisation and occasional trailing spaces, which would cause the same country to appear as two different entries when merging.
- **Coerces numeric columns** using `destring ... force` — the Stata equivalent of pandas `pd.to_numeric(errors='coerce')`. Any value that cannot be converted becomes a missing value (`.`) rather than crashing the script.
- **Keeps only the 10 common columns** — `country`, `happiness_rank`, `happiness_score`, `gdp_per_capita`, `social_support`, `life_expectancy`, `freedom`, `generosity`, `corruption`, `year`. Columns unique to specific years (confidence intervals, whisker values, standard errors, region, dystopia residual) are dropped here.

`dystopia_residual` is intentionally excluded. It exists in 2015–2017 but is absent in 2018 and 2019. Keeping it would mean roughly 40% of the master dataset has a missing value for that column, making it unreliable for any analysis.

---

#### Section 2 — Per-year loading and renaming

Each year is imported with `import delimited`. An important detail: **Stata auto-transforms variable names on import** — all letters are lowercased and all spaces, dots, parentheses, and commas are removed. So `Economy (GDP per Capita)` becomes `economygdppercapita`, and `Happiness.Score` (2017) becomes `happinessscore`. The rename commands in the script use these auto-generated names, not the original CSV headers.

After renaming, year-specific columns that were not selected as common columns are explicitly dropped before `clean_common` is called. This is done with `drop` rather than `keep` because some of these columns vary by year and it is safer to remove the known extras than to accidentally drop something needed.

Each cleaned year is then saved as a `.dta` file.

---

#### Section 3 — Building the master file

All five yearly `.dta` files are stacked vertically using `append using`. The result is a long-format dataset where each row is a **country-year pair** — for example, Finland appears five times, once for each year.

After appending:

- **First duplicate drop** — removes any exact duplicate rows introduced during appending.
- **Country name corrections** — 9 known inconsistencies are fixed. For example, `hong kong s.a.r., china` becomes `hong kong`, and both `congo (brazzaville)` and `congo (kinshasa)` are standardised to `congo`. This is necessary because the same country is sometimes named differently across years, which would cause it to appear as multiple separate countries in any country-level analysis.
- **Second duplicate drop** — after name corrections, countries that were previously distinct strings may now match. A second pass catches any new duplicates created by the standardisation.
- **Year validation** — rows with year values outside 2015–2019 are removed. This is a safety check against any data entry anomalies.
- **Sort** — sorted by `country` then `year` for readability and reproducibility.

---

#### Section 4 — Validation report

A series of diagnostic checks printed to the Stata results window:

| Check | Purpose |
|-------|---------|
| Row count | Confirms expected number of observations (~750) |
| Missing values per column | Identifies any gaps before analysis |
| Summary statistics | Spot-checks ranges and means for plausibility |
| Negative value check | Flags impossible values (happiness scores, GDP, etc. cannot be negative) |
| Duplicate report | Confirms deduplication worked |
| Z-score outlier flag | Reports — but does **not** drop — observations where any numeric column has \|z\| > 3 |

Outliers are flagged but not removed. The decision to keep them follows the original Python script's commented-out line. Dropping outliers in happiness data would risk removing genuinely extreme-but-real countries (e.g. very low-scoring conflict states), which would bias the analysis.

---

## File 2 — `analysis_happiness.do`

### What it does

Loads the 2019 cross-section, runs four regression models, exports a formatted regression table, and produces five graphs.

---

### Why 2019 only for regressions?

The master file contains five years of data, but running regression on all five years at once creates a **repeated measures problem**: the same country appears five times, so observations are not independent of each other. Finland in 2015 and Finland in 2016 share the same underlying culture, institutions, and history — treating them as two independent data points inflates the effective sample size and makes standard errors unreliable.

Using only 2019 gives a **clean cross-section**: 156 countries, one observation each, fully independent. This is the standard approach for this type of analysis at this level. The multi-year master data is still used — but only for one purpose: the trend graph (Graph 4), where the goal is explicitly to show how the global average moved across years.

---

### Step-by-step breakdown

#### Section 1 — Inspect the data

`describe` and `summarize` are run first so the analyst can visually confirm variable types, value ranges, and missing counts before any modelling begins. Missing value counts are also printed per variable. This is standard practice — running a regression on a variable with unexpected missing values or wrong types produces silent errors that are hard to trace later.

---

#### Section 2 — Regression models

Four models are estimated, each building on the previous:

**Model 1 — Bivariate**
Only GDP per capita predicts happiness. This is the baseline — it answers "does the raw relationship exist?" before any controls are added. The R² of 0.630 means GDP alone explains 63% of cross-country variation in happiness.

**Model 2 — Full controls**
All six control variables are added. This is the core model. It answers the actual research question: does GDP still matter once everything else is held constant? It does (β = 0.775, p<0.01), but the coefficient is much smaller than in Model 1, which tells us some of GDP's apparent effect was actually due to correlated factors like social support and life expectancy.

**Model 3 — Interaction term**
The term `c.gdp_per_capita##c.freedom` creates three variables at once: GDP, freedom, and their product (GDP × freedom). The interaction tests whether the effect of GDP on happiness *depends on* the level of freedom. A positive, significant interaction coefficient (β = 1.828, p<0.05) means yes — wealthier countries get more happiness benefit from GDP when their citizens also feel free. The `c.` prefix is required in Stata to treat both variables as continuous in an interaction.

**Model 4 — Log-linear**
`ln(happiness_score)` is used as the outcome. This follows the instructor note about log-transforming the dependent variable. It changes the interpretation: coefficients now represent approximate percentage changes in happiness per unit increase in the predictor. This model serves as a robustness check — if the sign and significance of results hold under a different functional form, the findings are more credible.

---

#### Section 2b — Exporting the regression table

The `estout` package (`ssc install estout`) is used. The workflow is:

1. `eststo` stores each model's results in memory after re-running them quietly.
2. `esttab` pulls all four stored models and formats them into one side-by-side table.
3. The table is exported as `.rtf` (Rich Text Format), which opens and pastes cleanly in Microsoft Word without reformatting.

The table includes coefficients, standard errors, significance stars, R², adjusted R², and observation counts — everything needed for a results section.

---

#### Section 3 — Graphs

**Graph 1 — GDP vs Happiness scatter with linear fit (2019)**
The main X-Y relationship graph. Uses `twoway` with a `scatter` layer and an `lfit` (linear fit) layer overlaid. This directly visualises what Model 1 is estimating. Semi-transparent markers (`navy%60`) prevent overplotting where countries cluster.

**Graph 2 — Average happiness by freedom quartile (2019)**
`xtile` cuts the continuous freedom variable into four equal-sized groups. A `preserve / collapse / restore` block is used so the main dataset is not permanently aggregated — `collapse` reduces the dataset to group means, the graph is drawn, and `restore` brings back the full data. This shows freedom's independent relationship with happiness in a format that is easy to read without requiring the audience to interpret regression coefficients.

**Graph 3 — GDP vs Happiness split by corruption level (2019)**
The sample is split at the median corruption score using `summarize, detail` to extract the 50th percentile. Two scatter-plus-fit series are overlaid on the same plot using `if` conditions. This tests visually whether the GDP-happiness relationship differs between high- and low-corruption countries. The fact that the two fit lines are close together is itself a finding — consistent with corruption being only marginally significant in the regression.

**Graph 4 — Global average happiness trend 2015–2019 (master data)**
This is the only graph that uses the master file. Inside a `preserve / use / restore` block, the master data is loaded, collapsed to year-level means, and a connected line plot is drawn. Its purpose is to justify the 2019 focus: if the trend line were sharply rising or falling, 2019 would be an unusual year. The near-flat trend (~5.36–5.41) confirms it is representative.

**Graph 5 — Actual vs predicted happiness (Model 2, 2019)**
Model 2 is re-run quietly and `predict yhat` generates fitted values. These are plotted against actual values. The `function y=x` overlay draws the 45-degree line — the benchmark of perfect prediction. Points hugging this line indicate the model fits well and is not systematically over- or under-predicting for any range of happiness scores.

---

### Temporary variables

At the end of the script, `freedom_q`, `high_corruption`, `yhat`, and `ln_happiness` are dropped. These were created only for intermediate calculations and graphs. Leaving them in the dataset would clutter any downstream use of the data, so they are explicitly removed after serving their purpose.

---

## Dependencies

| Package | Install command | Used for |
|---------|----------------|---------|
| `estout` | `ssc install estout, replace` | Regression table export |
| `distinct` | `ssc install distinct, replace` | Unique country count in validation (optional — script falls back if absent) |

Both are one-time installs. They do not need to be reinstalled each time the scripts are run.

---

## Data Source

Kaggle — World Happiness Report (2015–2019)  
https://www.kaggle.com/datasets/unsdsn/world-happiness
