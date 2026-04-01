* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* PROGRAM:		Descriptive Stats
* PROGRAMMER:	Sofia Valdivia
* DATE:	08-01-2026
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Settings
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

	// Settings
	set more off
	clear all
	set more off
	set maxvar 8000
	set varabbrev off
	
	*ssc install blindschemes, replace all
	set scheme plotplain
	graph set window fontface "Palatino"
	set_defaults graphics
	colorpalette "#e0f3db" "#bae4bc" "#7bccc4" "#43a2ca" "#0868ac" "#065389" "#032E4C"

	grstyle init
	grstyle color background white
	grstyle color major_grid dimgray
	grstyle linewidth major_grid thin
	grstyle yesno draw_major_hgrid yes
	grstyle yesno grid_draw_min yes
	grstyle yesno grid_draw_max yes
	grstyle clockdir legend_position 6
	grstyle ring legend_position 0
	grstyle linestyle legend none
	grstyle set color YlGnBu, n(3)
	grstyle set linewidth 1.5pt: pbar
	grstyle set inten 75: bar

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* File Paths
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

	*** individual paths

	if "`c(username)'"=="sofiavaldivia"{
		cd "/Users/sofiavaldivia/Dropbox/Research Ideas/2_Households_Savings/"
		global figures "/Users/sofiavaldivia/Documents/GitHub/Household_Savings/Figures/" 
		global dbox "/Users/sofiavaldivia/Dropbox/Research Ideas/2_Households_Savings/"
		global git "/Users/sofiavaldivia/Documents/GitHub/Household_Savings"
	

	}
	
	
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Import all years
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	// Variables to keep across all years
	local vars_to_keep "burgst nohhold nomem jrbs jbrs bezig_01 bezig_02 bezig_03 bezig_04 bezig_05 bezig_06 bezig_07 bezig_08 bezig_09 bezig_10 bezig_11 bel_bezig bet ooitw jaarw maandw xmin1jn mlonp1 mlon1 hsol jawerk mawerk weeknr rwega zoek rawerk01 rawerk02 rawerk03 rawerk04 rawerk05 rawerk06 rawerk07 rawerk08 rawerk09 rawerk10 rawerk11 netloon perloon xminl2jn mloon mloonp loonm perloonm reis"
	
	// Initialize master dataset flag
	local first_file = 1
	
	// Loop through years 2010-2024
	forvalues year = 2010/2024 {
		
		// Construct file path based on year
		if `year' == 2010 {
			local file_path "Source/DHS/`year'/wrk`year'en_2.0.dta"
		}
		else if `year' >= 2011 & `year' <= 2014 {
			local file_path "Source/DHS/`year'/wrk`year'en_2.0.dta"
		}
		else if `year' >= 2015 & `year' <= 2018 {
			local file_path "Source/DHS/`year'/wrk`year'en_1.0.dta"
		}
		else if `year' == 2019 {
			local file_path "Source/DHS/`year'/wrk`year'en_1.2.dta"
		}
		else {
			local file_path "Source/DHS/`year'/wrk`year'en_1.0.dta"
		}
		
		// Check if file exists
		cap confirm file "`file_path'"
		if _rc == 0 {
			// Load the file
			use "`file_path'", clear
			
			// Convert all variable names to lowercase
			foreach var of varlist _all {
				local newname = lower("`var'")
				if "`var'" != "`newname'" {
					rename `var' `newname'
				}
			}
			
			// Keep only the variables we need (if they exist)
			foreach var of local vars_to_keep {
				cap confirm variable `var'
				if _rc != 0 {
					// Variable doesn't exist, create empty variable
					gen `var' = .
				}
			}
			keep `vars_to_keep'
			
			// Remove all value labels to avoid conflicts when combining years
			label drop _all
			foreach var of varlist _all {
				label values `var'
			}
			
			// Add year variable
			gen year = `year'
			
			// Save as temporary file or append to master
			if `first_file' == 1 {
				tempfile work_all
				save `work_all'
				local first_file = 0
				display "Loaded `year'"
			}
			else {
				append using `work_all'
				save `work_all', replace
				display "Loaded `year'"
			}
		}
		else {
			display "File not found for year `year': `file_path'"
		}
	}
	
	// Load the final combined dataset
	use `work_all', clear 

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Create main variables
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	// fix for jbrs
	replace jrbs = jbrs if year == 2023 | year == 2024
	drop jbrs
	
	// General married / single variables
	gen married = (burgst == 1 | burgst == 2)
	gen partner = (burgst == 1 | burgst == 2 | burgst == 4)
	gen single = (burgst == 6)
	replace single = 1 if (year == 2024 & burgst == 7)
	
	// Working status
	gen working = (bezig_01 == 1)
	replace working = 1 if bet == 1
	gen in_laborforce = (bezig_01 == 1 | bezig_02 == 1 | bezig_03 == 1)
		replace in_laborforce = 1 if working == 1
	gen looking_forjob = (zoek == 1 | zoek == 2)
	
	// Reservation wage
	gen rw_monthly1 = mlon1
	replace rw_monthly1 = mlon1 * 4 if mlonp1 == 1    // weekly → monthly
	replace rw_monthly1 = mlon1 * 1 if mlonp1 == 2    // 4 weeks ≈ month
	replace rw_monthly1 = mlon1 * 1 if mlonp1 == 3    // already monthly
	replace rw_monthly1 = mlon1 / 12 if mlonp1 == 4   // yearly → monthly
	
	gen rw_monthly2 = mloon
	replace rw_monthly2 = mloon * 4 if mloonp == 1
	replace rw_monthly2 = mloon * 1 if mloonp == 2
	replace rw_monthly2 = mloon * 1 if mloonp == 3
	replace rw_monthly2 = mloon / 12 if mloonp == 4
	// one outlier case that makes no sense
	replace rw_monthly2 = . if mloon == 999999997
	
	egen rw_monthly = rowtotal(rw_monthly1 rw_monthly2), missing
	
	// Indicator for year got married 
	gen married_after2018 = 1 if jrbs >= 2018 & !mi(jrbs)
	replace married_after2018 = 0 if jrbs < 2018 & !mi(jrbs)
	// Calculate unemployment spell from jawerk and mawerk
	
	save "Worked/DHS_Work.dta", replace
	
	// create marriage status
	bys nohhold: ereplace married = max(married)
	bys nohhold: ereplace single = max(single)
	
	collapse married working single rw_monthly hsol married_after2018, by(nohhold year)
	
	save "Worked/DHS_Work_uniquehh.dta", replace

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Graph 2: Average Monthly Reservation Wage by Marital Status and Year
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	// one response makes no sense
	// Prepare data for graph: filter and calculate averages
	
	// Filter data: remove missing values, remove outliers, and keep years <= 2021
	count if rw_monthly > 177770 & !mi(rw_monthly)
	drop if rw_monthly > 177770 & !mi(rw_monthly) // outliers
	*keep if !missing(rw_monthly) & !missing(married) & rw_monthly != 11111111.000 & rw_monthly <= 177770 //& year <= 2021
	
	// Create marital status label
	gen marital_label = "Not Married"
	replace marital_label = "Married" if married == 1
	
	gen single_label = "Not Single"
	replace single_label = "Single" if single == 1
	
	preserve
	unique nohhold if married == 1 & !mi(rw_monthly)
	local n_married: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(rw_monthly)
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single marital_label single_label)
	
	// Create the graph
	twoway (line avg_res_wage year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   text(3000 2011.2 "N Married: `n_married'" ///
			 2900 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage, replace)	
		   
		   
	*twoway (line avg_res_wage1 year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage1 year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage1, replace)
		   
	*twoway (line avg_res_wage2 year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage2 year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage2, replace)     
		   
	// Save the graph
	graph export "${figures}/res_wage_marital_status.pdf", replace
	restore
	
	// Res wage when looking for a job
	preserve
	keep if looking_forjob == 1 // see how it changes for people looking for jobs
	unique nohhold if married == 1 & !mi(rw_monthly)
	local n_married: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(rw_monthly)
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single marital_label single_label)
	
	// Create the graph
	twoway (line avg_res_wage year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   text(3000 2011.2 "N Married: `n_married'" ///
			 2900 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage, replace)	

	// Save the graph
	graph export "${figures}/res_wage_marital_status_lookingjob.pdf", replace
	
	restore
	
	
	// res wage when already working
	preserve
	keep if looking_forjob == 0 & working == 1 // see how it changes for people looking for jobs
	
	unique nohhold if married == 1 & !mi(rw_monthly)
	local n_married: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(rw_monthly)
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single marital_label single_label)
	
	// Create the graph
	twoway (line avg_res_wage year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   text(3450 2011.2 "N Married: `n_married'" ///
			 3300 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage, replace)	

	// Save the graph
	graph export "${figures}/res_wage_marital_status_work.pdf", replace
	
	restore
	
	
	// those in labor force
	preserve
	keep if in_laborforce == 1 // see how it changes for people looking for jobs
	
	unique nohhold if married == 1 & !mi(rw_monthly)
	local n_married: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(rw_monthly)
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single marital_label single_label)
	
	// Create the graph
	twoway (line avg_res_wage year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   text(3000 2011.2 "N Married: `n_married'" ///
			 2900 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage, replace)	

	// Save the graph
	graph export "${figures}/res_wage_marital_status_lfp.pdf", replace
	
	restore
	
	
	// commmute? -- looks like no difference
	preserve
	keep if working == 1
	unique nohhold if married == 1 & !mi(reis) 
	local n_married: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(reis) 
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_reis = reis, by(year married single marital_label single_label)
	
	// Create the graph
	twoway (line avg_reis year if married == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_reis year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Commute (Minutes)") yscale(titlegap(*5)) ///
		   title("Average Commute (Minutes) by Marital Status", size(medlarge) justification(center)) ///
		   text(30 2011.2 "N Married: `n_married'" ///
			 29 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage, replace)	

	// Save the graph
	graph export "${figures}/commute_marital_status_working.pdf", replace
	
	restore
	
	
	
	// exactly by property regime
	preserve
	unique nohhold if burgst == 1 & !mi(rw_monthly)
	local n_married_com: display %6.0fc `r(unique)'
	
	unique nohhold if burgst == 2 & !mi(rw_monthly)
	local n_married_sep: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(rw_monthly)
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single burgst marital_label single_label)
	
	// Create the graph
	twoway (line avg_res_wage year if burgst == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if burgst == 2, lwidth(0.8) lcolor("green")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Property regime", size(medlarge) justification(center)) ///
		   text(3500 2012 "N Com Property: `n_married_com'" ///
		   3400 2011.8 "N Sep Property: `n_married_sep'" ///
			 3300 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Community Property" 2 "Separate Property" 3 "Single") position(6) cols(2)) name(avg_res_wage, replace)	
		   
		   
	// Save the graph
	graph export "${figures}/res_wage_propertyregime.pdf", replace
	restore
	
	
	preserve
	unique nohhold if married == 1 & burgst == 1 & !mi(rw_monthly)
	local n_married: display %6.0fc `r(unique)'
	
	unique nohhold if single == 1 & !mi(rw_monthly)
	local n_single: display %6.0fc `r(unique)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single burgst marital_label single_label)
	
	// Create the graph
	twoway (line avg_res_wage year if married == 1 & burgst == 1, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   text(3000 2011.2 "N Married: `n_married'" ///
			 2900 2011.2 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married" 2 "Single") position(6) cols(2)) name(avg_res_wage, replace)	
		    
		   
	// Save the graph
	graph export "${figures}/res_wage_marital_status_commprop.pdf", replace
	restore
	
	
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Graph 3: Main Graph
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
preserve
	unique nohhold if !mi(rw_monthly) & married == 1 & married_after2014 == 1
	local n_married_after2014: display %6.0fc `r(unique)'
	
	unique nohhold if !mi(rw_monthly) & married == 1 & married_after2014 == 0
	local n_married_before2014: display %6.0fc `r(unique)'
	
	unique nohhold if !mi(rw_monthly) & single == 1 
	local n_single: display %6.0fc `r(N)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_res_wage = rw_monthly avg_res_wage1 = rw_monthly1 avg_res_wage2 = rw_monthly2, by(year married single marital_label single_label married_after2014)
	
	// Create the graph
	twoway (line avg_res_wage year if married == 1 & married_after2014 == 0, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_res_wage year if single == 1, lwidth(0.8) lcolor("#d62728")) ///
		   (line avg_res_wage year if married == 1 & married_after2014 == 1, lwidth(0.8) lcolor("green")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average Monthly Reservation Wage") yscale(titlegap(*5)) ///
		   title("Average Monthly Reservation Wage by Marital Status", size(medlarge) justification(center)) ///
		   text(3450 2012 "N Married After 2014: `n_married_after2014'" ///
			3350 2012 "N Married Before 2014: `n_married_before2014'" ///
			 3250 2012 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married before 2014" 2 "Single" 3 "Married after 2014") position(6) cols(3)) name(res_wage_2014, replace)	
		   // Save the graph
	graph export "${figures}/main_stats.pdf", replace
restore


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Outcome: N times applied for a job
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
preserve
	unique nohhold if !mi(hsol) & married == 1 & married_after2014 == 1
	local n_married_after2014: display %6.0fc `r(unique)'
	
	unique nohhold if !mi(hsol) & married == 1 & married_after2014 == 0
	local n_married_before2014: display %6.0fc `r(unique)'
	
	unique nohhold if !mi(hsol) & single == 1 
	local n_single: display %6.0fc `r(N)'
	
	// Collapse to get average reservation wage by year and marital status
	collapse (mean) avg_hsol = hsol, by(year married single marital_label single_label married_after2014)
	
	// Create the graph
	twoway (line avg_hsol year if married == 1 & married_after2014 == 0, lwidth(0.8) lcolor("#1f77b4")) ///
		   (line avg_hsol year if single == 1, lwidth(0.8) lcolor("#d62728")) ///
		   (line avg_hsol year if married == 1 & married_after2014 == 1, lwidth(0.8) lcolor("green")), ///
		   xlabel(2010(1)2024, angle(45) nogrid) ylabel(,nogrid) ///
		   xtitle("Year") ///
		   ytitle("Average N times applied for a job") yscale(titlegap(*5)) ///
		   title("Average N times applied for a job by Marital Status", size(medlarge) justification(center)) ///
		   text(8 2022 "N Married After 2014: `n_married_after2014'" ///
			7.5 2022 "N Married Before 2014: `n_married_before2014'" ///
			 7 2022 "N Single: `n_single'", ///
			 size(small) col(black*0.3)) ///
		   legend(order(1 "Married before 2014" 2 "Single" 3 "Married after 2014") position(6) cols(3)) name(res_wage_2014, replace)	
		   // Save the graph
	graph export "${figures}/main_stats_hsol.pdf", replace
restore

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Simple regression on job search
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
use "Worked/DHS_Work.dta", clear
keep if married ==  1
drop if rw_monthly > 177770 & !mi(rw_monthly) // outlier

* (1) Reservation wage — expect beta < 0 (less insurance → lower rw)
reg rw_monthly married_after2018 i.year, vce(cluster nohhold)

* (2) Job search intensity — expect beta > 0 (less insurance → apply more)
reg hsol married_after2018 i.year, vce(cluster nohhold)

* (3) Conditional on actively looking for a job
reg rw_monthly married_after2018 i.year if looking_forjob == 1, vce(cluster nohhold)
reg hsol married_after2018 i.year if looking_forjob == 1, vce(cluster nohhold)

////////////////////////////////////////
// Analysis for joint savings
///////////////////////////////////////////

//1. Identify by hhold and by savings if its individual or joint

// Variables to keep across all years
	local vars_to_keep "bz01 bet2 bet4 bet91 bet5 bet92 bet93 bet94 bet95 bet141 bet142 bet143 bet144 bet145 bet_posneg1 bet_posneg2 bet_posneg3 bet_posneg4 bet_posneg5 bz03 spa2 spa3 spa4 spa71 spa72 spa73 spa74 spa75 spa76 spa77 spa131 spa132 spa133 spa134 spa135 spa136 spa137 bz04 boe3 bz06 bri2 bri5 bri6"
	
	// Initialize master dataset flag
	local first_file = 1
	
	// Loop through years 2010-2024
	forvalues year = 2010/2024 {
		
		// Construct file path based on year
		if `year' == 2010 {
			local file_path "Source/DHS/`year'/agw`year'en_2.0.dta"
		}
		else if `year' >= 2011 & `year' <= 2014 {
			local file_path "Source/DHS/`year'/agw`year'en_2.0.dta"
		}
		else if `year' >= 2015 & `year' <= 2018 {
			local file_path "Source/DHS/`year'/agw`year'en_1.0.dta"
		}
		else if `year' == 2019 {
			local file_path "Source/DHS/`year'/agw`year'en_1.2.dta"
		}
		else {
			local file_path "Source/DHS/`year'/agw`year'en_1.0.dta"
		}
		
		// Check if file exists
		cap confirm file "`file_path'"
		if _rc == 0 {
			// Load the file
			use "`file_path'", clear
			
			// Convert all variable names to lowercase
			foreach var of varlist _all {
				local newname = lower("`var'")
				if "`var'" != "`newname'" {
					rename `var' `newname'
				}
			}
			
			// Keep only the variables we need (if they exist)
			foreach var of local vars_to_keep {
				cap confirm variable `var'
				if _rc != 0 {
					// Variable doesn't exist, create empty variable
					gen `var' = .
				}
			}
			keep `vars_to_keep'
			
			// Remove all value labels to avoid conflicts when combining years
			label drop _all
			foreach var of varlist _all {
				label values `var'
			}
			
			// Add year variable
			gen year = `year'
			
			// Save as temporary file or append to master
			if `first_file' == 1 {
				tempfile work_all
				save `work_all'
				local first_file = 0
				display "Loaded `year'"
			}
			else {
				append using `work_all'
				save `work_all', replace
				display "Loaded `year'"
			}
		}
		else {
			display "File not found for year `year': `file_path'"
		}
	}
	
	// Load the final combined dataset
	use `work_all', clear 

	
	
