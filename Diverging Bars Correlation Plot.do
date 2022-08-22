* Diverging bars correlation plot
	
		* Before we start off, lets install the following packages (One time)
		* ssc install schemepack, replace
		* ssc install colrspace, replace
		* ssc install palettes, replace
		* ssc install labutil, replace

	
		* Load sample Dataset
		sysuse auto, clear	
				
		* Only change names of variable in local var_corr. 
		* The code will hopefully do the rest of the work without any hitch
		local var_corr price mpg trunk weight length turn foreign
		local countn : word count `var_corr'
		
********************************************************************************
* Hopefully wont require any changing unless you want different color palette
* or want to change the width of the bar using lwidth() (currently width = 3)
		
		* Use correlation command
		quietly correlate `var_corr'
		matrix C = r(C)
		local rnames : rownames C
		
		* Now to generate a dataset from the Correlation Matrix
		clear
			
		* This will not have the diagonal of matrix (correlation of 1) 
		local tot_rows : display `countn' * `countn'
		set obs `tot_rows'
		
		generate corrname1 = ""
		generate corrname2 = ""
		generate y = .
		generate x = .
		generate corr = .
		generate abs_corr = .
		
		local row = 1
		local y = 1
		local rowname = 2
			
		foreach name of local var_corr {
			forvalues i = `rowname'/`countn' { 
				local a : word `i' of `var_corr'
				replace corrname1 = "`name'" in `row'
				replace corrname2 = "`a'" in `row'
				replace y = `y' in `row'
				replace x = `i' in `row'
				replace corr = round(C[`i',`y'], .01) in `row'
				replace abs_corr = abs(C[`i',`y']) in `row'
				
				local ++row
				
			}
			
			local rowname = `rowname' + 1
			local y = `y' + 1
		
		}
			
		drop if missing(corrname1)
		replace abs_corr = 0.1 if abs_corr < 0.1 & abs_corr > 0.04
		
		* Generating a variable that will contain color codes
		* colorpalette HCL pinkgreen, n(20) nograph intensity(0.75) //Not Color Blind Friendly
		colorpalette CET CBD1, n(20) nograph //Color Blind Friendly option
		generate colorname = ""
		local col = 1
		forvalues colrange = -1(0.1)0.9 {
			replace colorname = "`r(p`col')'" if corr >= `colrange' & corr < `=`colrange' + 0.1'
			replace colorname = "`r(p20)'" if corr == 1
			local ++col
		}	
		
		* Grouped correlation of variables
		generate group_corr = corrname1 + " - " + corrname2
		compress
		
		
		* Sort the plot
		sort corr, stable
		generate rank_corr = _n
		labmask rank_corr, values(group_corr)
		
		
		* Plotting
		* Run the commands ahead in one go if you have reached this point in breaks
		* Saving the plotting code in a local 
		forvalues i = 1/`=_N' {
		
			local barlist "`barlist' (scatteri `=rank_corr[`i']' 0 `=rank_corr[`i']' `=corr[`i']' , recast(line) lcolor("`=colorname[`i']'") lwidth(*6))"
		
		}
		
		* Saving labels for Y-Axis in a local
		levelsof rank_corr, local(yl)
		foreach l of local yl {
		
			local ylab "`ylab' `l'  `" "`:lab (rank_corr) `l''" "'"	
			
		}	
		
		twoway `barlist', legend(off) scheme(white_tableau) ylabel(`ylab', labsize(2.5)) ///
				xlab(, labsize(2.5)) ///
				ytitle("Pairs") xtitle("Correlation Coeff.") ///
				title("Correlation Coefficient (Diverging Bar Plot)", size(3) pos(11))