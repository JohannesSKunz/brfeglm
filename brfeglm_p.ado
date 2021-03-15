*! version 1.0.0  15mar2021
/* predict for brfeglm*/
/* adapted from probit_p */
program define brfeglm_p, sort
	version 6, missing

	syntax [anything] [if] [in] [, SCores * ]
	if `"`scores'"' != "" {
		GenScores `0'
		exit
	}

		/* Step 1:
			place command-unique options in local myopts
			Note that standard options are
			LR:
				Index XB Cooksd Hat 
				REsiduals RSTAndard RSTUdent
				STDF STDP STDR noOFFset
			SE:
				Index XB STDP noOFFset
		*/
		

	//scalar ttt = filewrite("margtest.txt","0contents: `0'",1)
		
		
	//AB: removed deviance rules asif ;type options
	local xopts 
	local oopts Pr xbu d1(string) d2(string)
	if `"`e(prefix)'`e(opt)'"' != "" {
		local oopts `oopts' xb index stdp
	}
	local myopts `xopts' `oopts'

		/* Step 2:
			call _propts, exit if done, 
			else collect what was returned.
		*/
	_pred_se "`myopts'" `0'
	if `s(done)' { exit }
	local vtyp  `s(typ)'  //AB: double, float etc
	local varn `s(varn)'
	local 0 `"`s(rest)'"'

		/* Step 3:
			Parse your syntax.
		*/
	syntax [if] [in] [, `myopts' ]
	if `:length local index' {
		local xb xb
	}
	opts_exclusive "`asif' `rules' `nooffset'"
	
	

	if "`e(prefix)'" != "" {
		_prefix_nonoption after `e(prefix)' estimation,		///
	}

		/* Step 4:
			Concatenate switch options together
		*/
	local type "`xb'`xbu'`pr'`stdp'"
		/* Step 5:
			quickly process default case if you can 
			Do not forget -nooffset- option.
		*/
	if "`type'"=="" | "`type'"=="pr" {
// 		if `"`d2'"' != "" & `"`d1'"' == "" {
// 			di as err "option d2() requires option d1()"
// 			exit 198
// 		}
		if "`type'"=="" {
			di in smcl in gr ///
			"(option {bf:pr} assumed; Pr(`e(depvar)'))"
		}
		/* for pr and d1 & d2, we also need to know the full estimation 
		subsample
		*/
		tempvar smpl
		qui gen byte `smpl' = e(sample)
		
		tempname xb
		qui _predict double `xb' if `smpl', `offset' xb
		//AB-----
		// Always use e() as saved FEs may be old estimation
		tempname mfe newid feest
		mat `mfe' = e(b_fe)
		qui egen `newid' = group(`e(identifier)') if `smpl'
		qui bysort `newid': gen `feest' = `mfe'[`newid',1]
		qui replace `xb' = `xb'+ `feest'   // Estimates of FEs mean zero, basic xb has overall mean
		//AB^^^^^
		
		// Remove perfect prediction rules handling
		//_pred_rules `xb' `if' `in', `rules' `asif'


	if `"`d2'"' != "" {
		//AB-----
		if  "`e(model)'" == "probit" {
			qui gen `vtyp' `varn' = -`xb'*normalden(`xb') `if' `in'
		} 
		else if  "`e(model)'" == "logit" {
			qui gen `vtyp' `varn' = 1/(1+exp(-`xb')) `if' `in'
			qui replace `varn' = `varn'*(1-`varn')*(1-2*`varn')	
		}
		else if  "`e(model)'" == "cloglog" { 
			qui gen `vtyp' `varn' = 1 - exp( -exp(`xb') ) `if' `in'
			qui replace `varn' = ((1-`varn')*exp(`xb'))*(1-exp(`xb'))
		}
		else {
			di as err "model must either be probit, logit, or cloglog"
			exit 198
		}
		label var `varn' "d2 Pr(`e(depvar)') / d xb d xb"
		//AB^^^^^
	}
	else if `"`d1'"' != "" {
		//AB-----
		if  "`e(model)'" == "probit" {
			qui gen `vtyp' `varn' = normalden(`xb') `if' `in'
		} 
		else if  "`e(model)'" == "logit" {
			qui gen `vtyp' `varn' = 1/(1+exp(-`xb')) `if' `in'
			qui replace `varn' = `varn'*(1-`varn')	
		}
		else if  "`e(model)'" == "cloglog" { 
			qui gen `vtyp' `varn' = 1 - exp( -exp(`xb') ) `if' `in'
			qui replace `varn' = (1-`varn')*exp(`xb')
		}
		else {
			di as err "model must either be probit, logit, or cloglog"
			exit 198
		}
		label var `varn' "d Pr(`e(depvar)') / d xb"
		//AB^^^^^
	}
	else {
		//AB-----
		if  "`e(model)'" == "probit" {
			qui gen `vtyp' `varn' = normal(`xb') `if' `in'
		} 
		else if  "`e(model)'" == "logit" {
			qui gen `vtyp' `varn' = 1/(1+exp(-`xb')) `if' `in'
		}
		else if  "`e(model)'" == "cloglog" { 
			qui gen `vtyp' `varn' = 1 - exp( -exp(`xb') ) `if' `in'
		}
		else {
			di as err "model must either be probit, logit, or cloglog"
			exit 198
		}
		//AB^^^^^
		
		label var `varn' "Pr(`e(depvar)')"
	}

		exit
	}


		/* Step 6:
			mark sample (this is not e(sample)).
		*/


		/* Step 7:
			handle options that take argument one at a time.
			Comment if restricted to e(sample).
			Be careful in coding that number of missing values
			created is shown.
			Do all intermediate calculations in double.
		*/


		/* Step 8:
			handle switch options that can be used in-sample or 
			out-of-sample one at a time.
			Be careful in coding that number of missing values
			created is shown.
			Do all intermediate calculations in double.
		*/
	if "`type'"=="xb" {
		quietly _predict `vtyp' `varn' `if' `in', `offset' xb
				// Remove perfect prediction rules handling
		//_pred_rules `varn' `if' `in', `rules' `asif'
		qui _pred_missings `varn'
		label var `varn' "Linear prediction (exc. FEs)"
		exit
	}
	
		if "`type'"=="xbu" {
		/* for xbu, we also need to know the full estimation 
		subsample
		*/
		tempvar smpl
		qui gen byte `smpl' = e(sample)
		quietly _predict `vtyp' `varn' if `smpl', `offset' xb
		// Remove perfect prediction rules handling
		//_pred_rules `varn' `if' `in', `rules' `asif'
		//AB-----
		// Always use e() as saved FEs may be old estimation
		tempname mfe newid feest
		mat `mfe' = e(b_fe)
		qui egen `newid' = group(`e(identifier)') if `smpl'
		qui bysort `newid': gen `feest' = `mfe'[`newid',1]
		qui replace `varn' = `varn' + `feest'   // Estimates of FEs mean zero, basic xb has overall mean
		//AB^^^^^
		qui _pred_missings `varn'
		label var `varn' "Linear prediction (inc. FEs)"
		exit
	}

	if "`type'"=="stdp" {
		opts_exclusive "stdp `rules'"
		quietly _predict `vtyp' `varn' `if' `in', `offset' stdp
				// Remove perfect prediction rules handling
		//_pred_rules `varn' `if' `in', `asif'
		_pred_missings `varn'
		label var `varn' "S.E. of the prediction (exc. FEs)"
		exit
	}

		/* Step 9:
			handle switch options that can be used in-sample only.
			Same comments as for step 8.
		*/
	marksample touse

		/* 
			For the remaining cases, we need the model 
			variables
		*/
	
	GetRhs rhs

		/*
			below we distinguish carefully between e(sample) 
			and `touse' because e(sample) may be a superset 
			of `touse'
		*/
	tempvar keep
	qui gen byte `keep' = e(sample)
	unopvarlist `rhs'
	local uorhs `"`r(varlist)'"'
	sort `keep' `uorhs'
	qui replace `touse'=0 if !`keep'


		/*
			remaining types require we know the weights, 
			if any.
		*/
		
	if `"`e(wtype)'"' != "" {
		if `"`e(wtype)'"' != "fweight" {
			di in red `"not possible with `e(wtype)'s"'
			exit 135
		}
		tempvar w
		qui {
			gen double `w' `e(wexp)'
			compress `w'
		}
		local lab "weighted "
	}
	else	local w 1

		/*
			remaining types require we know 
				p = probability of success
				m = # in covariate pattern
				y = # of successes within covariate pattern
		*/

		//AB deleted all remaining types
		

	error 198
end

program define GetRhs /* name */ 
	args where
	tempname b 
	mat `b' = get(_b)
	local rhs : colnames `b'
	mat drop `b'
	local n : word count `rhs'
	tokenize `rhs'
	if "``n''"=="_cons" {
		local `n'
	}
	c_local `where' "`*'"
end

program GenScores, rclass
	version 9, missing
	syntax [anything] [if] [in] [, * ]
	_score_spec `anything', `options'
	local varn `s(varlist)'
	local vtyp `s(typlist)'
	
	/* for scores, we also need to know the full estimation 
	subsample
	*/
	tempvar smpl
	qui gen byte `smpl' = e(sample)
	
	tempvar xb
	qui _predict double `xb' if `smpl', xb
	

	//AB-----
	// Always use e() as saved FEs may be old estimation
	tempname mfe newid feest
	mat `mfe' = e(b_fe)
	qui egen `newid' = group(`e(identifier)') if `smpl'
	qui bysort `newid': gen `feest' = `mfe'[`newid',1]
	qui replace `xb' = `xb' + `feest'   // Estimates of FEs mean zero, basic xb has overall mean
	// Calculations below taken from probit_p.ado, logit_p.ado and methods and formulas of cloglog.ado help file
	// That is, derivative of ln(L) w.r.t. (alpha+x*beta)
	if  "`e(model)'" == "probit" {
		quietly gen `vtyp' ///
		`varn' = -normden(`xb')/norm(-`xb') if `e(depvar)' == 0
		quietly replace ///
		`varn' = normden(`xb')/norm(`xb') if `e(depvar)' != 0
	} 
	else if  "`e(model)'" == "logit" {
		quietly gen `vtyp' ///
		`varn' = -invlogit(`xb') if `e(depvar)' == 0
		quietly replace ///
		`varn' = invlogit(-`xb') if `e(depvar)' != 0
	}
	else if  "`e(model)'" == "cloglog" { 
		quietly gen `vtyp' ///
		`varn' = -exp(`xb') if `e(depvar)' == 0
		quietly replace ///
		`varn' = ( exp(`xb')*exp(-exp(`xb')) )/( 1-exp(-exp(`xb')) ) if `e(depvar)' != 0
	}
	else {
		di as err "model must either be probit, logit, or cloglog"
		exit 198
	}
	//AB^^^^^
	
	local cmd = cond("`e(prefix)'"=="svy","svy:","")+"`e(cmd)'"
	label var `varn' "equation-level score from `cmd'"
	return local scorevars `varn'
end

exit
