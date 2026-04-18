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