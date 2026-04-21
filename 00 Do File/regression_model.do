

use "../01 Data/2019.dta", clear

describe
summarize happiness_score gdp_per_capita social_support life_expectancy freedom

misstable summarize // Just in case for any missing values, there should not be any but for profesional standards we should do it 

reg happiness_score gdp_per_capita social_support life_expectancy freedom, robust

twoway (scatter happiness_score gdp_per_capita) ///
       (lfit happiness_score gdp_per_capita), ///
       title("Happiness vs GDP per Capita")
   
   // Main scatter plot between our two main variables, most relevant. Line of best fit added as well to see the trend
   
   avplot gdp_per_capita //Effect of GDP controlled for other variables 
   
   
   pwcorr happiness_score gdp_per_capita social_support life_expectancy freedom, sig //Correlation matrix for quick insight into our variables (could add this to the slides)
   
   
   // Some additional plots which we can choose from 
   
	summ gdp_per_capita, detail
gen high_gdp = gdp_per_capita > r(p50)

	twoway (kdensity happiness_score if high_gdp==1) ///
       (kdensity happiness_score if high_gdp==0), ///
       legend(label(1 "High GDP") label(2 "Low GDP")) ///
       title("Happiness Distribution by GDP Level")
	   
	   histogram happiness_score, kdensity ///
    title("Happiness Score Distribution with Density")
	
	cluster kmeans happiness_score gdp_per_capita, k(3)
	scatter happiness_score gdp_per_capita, ///
    by(_clus_1, title("Clusters of Countries"))
   
   
   //MISC: Log gdp tryout, it was recommended but it seems more skewed to me. 
   
   
   gen log_gdp = log(gdp_per_capita)
   
   
   kdensity gdp_per_capita, normal ///
    title("Distribution of GDP per Capita")
	
	kdensity log_gdp, normal ///
    title("Distribution of Log GDP per Capita")
