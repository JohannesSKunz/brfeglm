* Version 1.0.1 - 15 Mar 2021

* By Alex Ballantyne, Johannes S. Kunz, Kevin E. Staub & Rainer Winkelmann
* See helpfile for explanations. 

* The software is provided as is, without warranty of any kind, express or implied, including 
* but not limited to the warranties of merchantability, fitness for a particular purpose and 
* noninfringement. In no event shall the authors be liable for any claim, damages or other 
* liability, whether in an action of contract, tort or otherwise, arising from, out of or in 
* connection with the software or the use or other dealings in the software.

cap program drop brfeglm
	program brfeglm, eclass sortpreserve
	version 14.0
	syntax varlist(numeric ts fv) [if] [in]  , [  ///
	MODEL(string) ///
	IDENtifier(varname)  ///
	SAVEFe   ///
	SAVEWeights  ///
	FESEfast   ///
	ITERate(integer 5000) ///
	TOLerance(real 1.000e-6) ///
	Robust CLuster(passthru)	/// old options
	VCE(passthru)	///
	OFFset(varname)  ///
	Level(cilevel) NOCOEF  ///
	NOConstant noDISPLAY noHEADer ///
	DOOPT* ///
	] 
	
	
	tempvar nobs eta mu dmudeta v w z xb xboff pfe pfese ehat qi hi touse   qiblock hiblock flag
	tempname b V bold tol maxiter val VAL iter bold ystar converged logl ll bnew Vnew idrop feb fese fullV meanFE sdFE 
	
	
	//NOTE: nocons NOT allowed as it is an FE regression using dummies for every panel unit
	if "`noconstant'" != "" {
		di as err "option `noconstant' not allowed"
		exit 198
	}
	if "`offset'" != "" {
		di as err "option offset not allowed"
		exit 198
	}
	
	// check vce(type)
	_vce_parse, argopt(CLuster) opt(IWLS Robust) old	: , `vce' `robust' `cluster'
	local vce
	if "`r(cluster)'" != "" {
		local clustvar `r(cluster)'
		local vce vce(cluster `r(cluster)')
	}
	else if "`r(robust)'" != "" {
		local vce vce(robust)
	}
		
	
	// check panel and get panelvar/group identifier 
	cap _xt
	if  "`identifier'"=="" {	
		if _rc == 0 {  //xtset panel identifier has been set
			local identifier = "`r(ivar)'"	// Find variable used to determine groups/individuals in panel
			di as text "note: identifier() not specified; assuming identifier(`identifier') from panel identifier"
		}
		else {  //xtset has not been set and no group()
			di as err "identifier({it:varname}) or xtset {it:varname} required"
			exit 198
		}
	}
	else { // if using identifier() option
		local idtt `identifier'
		if "`idtt'" != "`r(ivar)'" & _rc == 0 { // Warn if identifier() different to panelvar
			di as text "note: identifier() is not the same as panel identifier"
			local xtidflag = 1
			local rivar = "`r(ivar)'"
			local rtvar = "`r(tvar)'"
		}
	}
	
	
	
	// Warn if identifier() different to cluster
	if "`identifier'" != "`clustvar'" & "`clustvar'"!="" { // 
		di as text "note: identifier() is not the same as cluster() variable"
	}
	
		
	// check model
	if "`model'" == "" local model "probit"

	else if !inlist("`model'", "probit", "logit", "cloglog")  {
	    di as err "must choose model probit, logit, or cloglog"
	    exit 198
	    }
		
	// check saveFE or saveWeights
	if  "`savefe'"!="" {	
		cap confirm variable __fe`identifier', exact
		if _rc == 0 {
			di as err "option `savefe' used but variable {it:__fe`identifier'} already exists"
			exit 198
		}
	}
	
	if  "`saveweights'"!="" {	
		cap confirm variable __fe`identifier'wgt, exact
		if _rc == 0 {
			di as err "option `saveweights' used but variable {it:__fe`identifier'wgt} already exists"
			exit 198
		}
	} 
	
	
	// check fese_fast installed; and variable name not taken; and time series or factor vars not used
	if "`fesefast'"!=""  {
		cap which fese_fast
		if _rc != 0 {
			di as err "command {bf:fese_fast} not found as either built-in or ado-file"
			di as err "please install fese_fast from http://sacarny.com/programs/"
			exit 111	
		}
		if  "`savefe'"!="" {
			cap confirm variable __fe`identifier'se, exact
			if _rc == 0 {
				di as err "option `fesefast' used with `savefe' but variable {it:__fe`identifier'se} already exists"
				exit 198
			}
		}
		local tsfv = ("`s(tsops)'" == "true" | "`s(fvops)'" == "true")
		if `tsfv' == 1 {
			di as err "option `fesefast' does not allow factor-variable or time-series operators"
			exit 101
		}
	}
	
	
	// Get display options and tokens
	_get_diopts diopts options, `options'
	local cfmt `"`s(cformat)'"'
	gettoken lhs rhs : varlist

	// Check and clean rhs variables 
	_rmcoll `lhs', probit				//check 0,1+ binary
	_fv_check_depvar `lhs'				//check for factor variables 
	_rmcoll `rhs', expand 				//check and drop collinearities (also for display purposes)
	local rhs = "`r(varlist)'"
	local komit = `r(k_omitted)'
	
	local nxvars : word count `r(varlist)'
	
	marksample touse    		// if  `touse' `in' used to drop missings in covariate, does not work yet??
	
	//qui xi i.`identifier', noomit		// Construct panel unit dummies (FE) 
	qui tab `identifier' if `touse', gen(_I`identifier')  // Construct panel unit dummies (FE)
	local rhsorig = "`rhs'"
	local rhs = "_I`identifier'* `rhs'"		//Reverse order _I xvars, later switch
	_rmcoll `rhs', expand  nocons				//check again for possible manual FE variables and warn if found
	
	local fecollflag = 0  //No longer used due to switching _I xvars
	
	local nxvarsall : word count `r(varlist)'
	local nfevars = `nxvarsall'-`nxvars'
	local rhs = "`r(varlist)'"
	
	//Switch ordering of _I and xvars: ensures structure known for makeweights()
	forvalues i = 1/`nxvarsall' {
		if `i' <= `nfevars' {
			local temp : word `i' of `rhs'
			local rhsfe = "`rhsfe' `temp'" 
		}
		else {
			local temp : word `i' of `rhs'
			local rhsxv = "`rhsxv' `temp'" 		
		}
	}
	local rhs = "`rhsxv' `rhsfe'"


//-------------------------------------------------------
// Estimation!
	
	* Initial values for eta from OLS
	qui areg `lhs' `rhsorig' if `touse'	, absorb(`identifier')  `options'  // WLS 
	qui predict `eta' if `touse' , xbd

	
	mat `bold' = e(b)

	sca `tol' = `tolerance' 	// tolerance level for convergence
	sca `maxiter' = `iterate'	// maximum number of iterations

	//-------------------------------------------------------
	// Entering WLS loop
	sca `val' = 1			// initialising convergence value
	local iter = 0			// initialising iteration number
	while `val'>`tol' & `iter'<`maxiter' {
		
		if "`model'"=="probit" {
			qui g double `mu'  		= normal(`eta')		
			qui g double `dmudeta' 	= normalden(`eta')	
			qui g double `v' 		= `mu'*(1-`mu')
			}

		if "`model'"=="cloglog" {
			qui g double `mu'  		= 1 - exp( -exp(`eta') )	//pi
			qui g double `dmudeta' 	= (1-`mu')*exp(`eta')		//d
			qui g double `v' 		= (1-`mu')*`mu'
			}	

		if "`model'"=="logit" {
			qui g double `mu'  		= 1/(1+exp(-`eta'))	
			qui g double `dmudeta' 	= `mu'*(1-`mu')	
			qui g double `v' 		= `mu'*(1-`mu')
			}
		

		
		qui g double `w' 		= `dmudeta'^2 / `v'	// weight for IWLS
		

		
		//-------------------------------------------------------
		// Make weights in mata
		qui g `qi' = .
		mata: makeweights("`rhs'", "`w'", "`identifier'", "`touse'", "`qi'", "`qiblock'", `fecollflag', `nxvars', `nxvarsall')
		qui g double `hi' = `qi'*`w' 							  // H = W^{1/2} X (X'WX)^{-1} X' W^{1/2}	

		qui gen `flag' = `qi' 
		qui replace `flag' = 0 if `touse' != 1
		local qmiss = missing(`flag')
		qui drop `flag'
		if (`qmiss'>0) {
			di as err "weights have missing values - likely numerical overflow issue"
		}
		
		
		if "`model'"=="probit" { // pseudo-responses for probit
			qui g double `ystar' = `lhs' - `hi'*`v'*`eta'/(2*`dmudeta') 
			}
		if "`model'"=="cloglog" { // pseudo-responses for logit
			qui g double `ystar' = `lhs' + `hi'*`mu' * (1-exp(`eta'))/(2*exp(`eta')) 
			}
		if "`model'"=="logit" { // pseudo-responses for logit
			qui g double `ystar' = `lhs' + `hi'*(1/2-`mu') 
			}
			
		qui g double `z'   		= `eta' + (`ystar' - `mu') * (1/`dmudeta') // dep. var. for IWLS

		
		
		// Using areg 100 times quicker than reg
		qui areg `z' `rhsorig' [aweight=`w'] if `touse'	, absorb(`identifier') `vce' `options' // WLS 
		qui predict `xb' if `touse' , xbd


		
		mat `VAL' = ( e(b)-`bold' )' * ( e(b)-`bold' ) // updating convergence value
		mata: st_numscalar("`val'", max(diagonal(st_matrix("`VAL'"))) )
		qui replace `eta' = `xb'				// updating eta=x'b
		mat `bold' = e(b)						// updating betas
		mat `bnew' = e(b)							// store betas
		mat `Vnew' = e(V)							// store betas		
		local iter = `iter' + 1					// updating iteration number
		di in green "Iteration `iter':" in green "    val = " in yellow `val'
		
		local converged=1
		if `val'<=`tol' | `iter'==`maxiter' {			
			if `iter'==`maxiter' {
				di in red "Warning: Convergence not achieved."
					local converged=0								//Convergence achived, store
				}
			}
		if "`model'"=="probit" { 									//calc loglikelihood values
			qui g double `logl'= `lhs'*ln(`mu')+(1-`lhs')*ln(1-`mu')
			}
		if "`model'"=="cloglog" {  
			qui g double `logl'= `lhs'*ln(`mu')+(1-`lhs')*ln(1-`mu')
			}	
		if "`model'"=="logit" {
			qui g double `logl'= `lhs'*ln(`mu')+(1-`lhs')*ln(1-`mu')
			}	
		qui su `logl'
		local ll=r(sum)									//Store ll-values
		

		// If converged
		if `val'<=`tol' | `converged'==0 {	

			// Get fixed effects from areg
			qui predict `pfe' if `touse' , d
			
			// Make FE matrix for eret
			tempvar tt1 tt2
			qui bysort `identifier': gen `tt1' = _n
			qui replace `tt1' = . if !e(sample)
			qui bysort `identifier': egen `tt2' = max(`tt1')
			qui gen `flag' = 1 if `tt1'==`tt2'
			drop `tt1' `tt2'
			mkmat `pfe' if `touse' & `flag'==1, matrix(`feb')
			mata: st_numscalar("`meanFE'", mean(st_matrix("`feb'"))) 
			mata: st_numscalar("`sdFE'", sqrt(variance(st_matrix("`feb'")))) 
			// FEs are mean zero (when weighted), so adjust to unweighted mean zero
			qui replace `pfe' = `pfe' - `meanFE'   
			mata: st_matrix("`feb'", st_matrix("`feb'"):-st_numscalar("`meanFE'"))  
			// Adjust constant 
			mat `bnew'[1,colnumb(`bnew',"_cons")] = `bnew'[1,colnumb(`bnew',"_cons")] + `meanFE'


			// Save weights as variable option (just in case)
			if  "`saveweights'"!="" {  
				qui g __fe`identifier'wgt = `w'
			}	
			
			// Save FEs as variable option
			if  "`savefe'"!="" {  
				qui g __fe`identifier' = `pfe'
			}

			// Build FE standard errors for eret (option)
			if "`fesefast'"!=""  {
				qui predict `ehat' if `touse' , r			
				// remove ommitted variables for fese_fast
				foreach rv in `rhsorig' {
					local temp = regexm("`rv'","o\..+")
					if `temp' != 1 {
						local rhsnoomit = "`rhsnoomit' `rv'" 
					}
				}
				// run fese_fast
				if "`xtidflag'" == "" {
					qui fese_fast `z' `rhsnoomit' if e(sample), homosced(`pfese') ehat(`ehat')	
				}
				else {
					// NOTE fese_fast looks at _dta[iis] for group variable
					// NEED to reset xtset before running fese_fast and restore	
					cap xtset `identifier'
					qui fese_fast `z' `rhsnoomit' if e(sample), homosced(`pfese') ehat(`ehat')	
					cap xtset `rivar' `rtvar'
				}	
				// Make FE SE matrix for eret
				mkmat `pfese' if `touse' & `flag'==1, matrix(`fese')
				// If not save FEs 
				if  "`savefe'"!="" {  
					qui g __fe`identifier'se = `pfese'
				}
			}

			qui drop `pfe'
			qui drop _I`identifier'*
			
			
		} // End If converged
		
		
		
		qui drop `mu' `dmudeta' `v' `w' `z' `xb' `qi' `hi' `ystar' `logl' 
		
		
	}
	// Exiting WLS loop
	//-------------------------------------------------------


	
//-------------------------------------------------------
// Outro
	
	local mnotok = "xbu stdp `e(marginsnotok)'"
	local rankV = e(rank)

	// Reconstruct ereturn
	local N=e(N)
	local df_r = e(df_r)
	if "`clustvar'"!="" {
		local Nclust = e(N_clust)
	}
	ereturn post `bnew' `Vnew' ,  depname("`lhs'") esample(`touse') buildfvinfo ADDCONS
	
	// scalars and vce
	ereturn scalar N = `N'
	ereturn scalar N_g = `nfevars'
	if "`clustvar'"!="" {
		ereturn scalar N_clust = `Nclust'
		ereturn local vcetype "Robust"
		ereturn local clustvar "`clustvar'"
		ereturn local vce "cluster"
	}
	else if "`vce'"=="vce(robust)" {
		ereturn local vcetype "Robust"
		ereturn local vce "robust"
	}
	else {
		ereturn local vce "iwls"
	}
	ereturn scalar converged=`converged'
	ereturn scalar ic = `iter'
	ereturn scalar ll = `ll'
	
	ereturn scalar k = `nxvars'+1
	ereturn scalar df_a = `nfevars'-1
	ereturn scalar df_m = `nxvars'+`nfevars'-`komit'-1
	
	ereturn scalar fe_mean = `meanFE'
	ereturn scalar fe_sd = `sdFE'
	
	ereturn scalar rank = `rankV'
	

	// Return matrices
	if "`fesefast'"!=""  {
		ereturn matrix se_fe = `fese'
	}
	ereturn matrix b_fe = `feb'

	// predict and margins info
	eret loc predict = "brfeglm_p"
	eret loc marginsnotok = "`mnotok'"
	eret loc marginsok = "default Pr"
	eret hidden local marginsderiv = "default Pr"
	// model and command info
	ereturn local opt "IWLS"
	ereturn hidden local crittype "log likelihood"
	ereturn local identifier "`identifier'"
	ereturn local model "`model'" 	
	ereturn local cmdline "brfeglm `0'"
	ereturn local cmd "brfeglm" 


	//Make display go now!
	if "`display'" == "" {
		Display, level(`level') model(`model') cfmt(`cfmt') mfe(`meanFE') sdfe(`sdFE') `header'  `nocoef' `diopts'
	}
	
end


//Display program using modified header
program Display
	syntax [, Level(cilevel) model(string) cfmt(string) mfe(string) sdfe(string) noHEADer  NOCOEF diopts *]
	
	//Display header
	if "`header'" == "" & "`nocoef'" == "" {
		_coef_table_header, title(Biased-reduced `model' glm regression) nomodel
	}
	
	//Display table
	if "`nocoef'" == "" {
		//ereturn display, level(`level') `options'
		_coef_table , plus level(`level') `options' `diopts'

		//Append mean and sd of FEs
		local c1 = `"`s(width_col1)'"'
		local w = `"`s(width)'"'
		if "`c1'"=="" {
			local c1 13
		}
		else {
			local c1 = int(`c1')
		}
		if "`w'"=="" {
			local w 78
		}
		else {
			local w = int(`w')
		}

		local c = `c1' - 1
		local rest = `w' - `c1' - 1
		if `"`cfmt'"' != "" {
			local dmeanFE	: display `cfmt' `mfe'
			local dsdFE	: display `cfmt' `sdfe'
		}
		else {
			local dmeanFE	: display %10.0g `mfe'
			local dsdFE	: display %10.0g `sdfe'
		}
		//di as txt %`c's "FE mean" " {c |} " as res %10s "`dmeanFE'"
		di as txt %`c's "FE s.d." " {c |} " as res %10s "`dsdFE'"
		di as txt "{hline `c1'}{c BT}{hline `rest'}"
		
		// Note on FEs
		di as txt "{p 0 6 2}" ///
			"Note: {bf:`e(N_g)'} estimates of fixed effects suppressed.{p_end}"
	}

end

//Mata program to make weights
mata:
void makeweights(string scalar rhs, string scalar w, string scalar identifier, string scalar touse, string scalar qvar, string scalar qblockvar, real scalar flag, real scalar nxvars, real scalar nxvarsall) {

			//-------------------------------------------------------
		// Matrix algebra in mata
		
		W=X=id=.
		st_view(X,.,tokens(rhs),touse)
		st_view(W,.,w,touse)
		st_view(id,.,identifier,touse)
		//flag = st_local("fecollflag")
		// Build panel unit matrix indexes (to loop through panel units in X*Sigma*X' calc)
		info = panelsetup(id, 1)
		
		
		//Simple dummy check
		XD = X[1..., (nxvars+1)..(nxvarsall)]
		if (allof((XD:==0)+(XD:==1),1)==0) {
			stata(`"di as err "fixed effects dummies non-binary, bug in code""')
			stata(`"exit 109"')
		}
		
		
		if (flag==0) {   //XWX Structure known (no omitted FE dummies)
			
			// Block inverse XWX -------------------------------
			XWX = cross(X,W,X)	//XWX is block matrix by rows [A, B' // B, C]
			
			if (nxvars!=0) {	// If any covariates
				A = XWX[|1, 1 \ nxvars, nxvars|]
				B = XWX[|nxvars+1, 1 \ nxvarsall, nxvars|]		// constant term ommitted
				C = XWX[|nxvars+1, nxvars+1 \ nxvarsall, nxvarsall|]
				if (diag0cnt(C)>0) {  // Avoid division by zero (add smallest number)
					diagC = diagonal(C)
					diagC = diagC + (diagC :== 0) :*mindouble()
					stata(`"di as text "division by zero avoided""')
				}
				else {
					diagC = diagonal(C)
				}
				Cinv = diag(1:/diagC)
				Omega = invsym(A-(cross(B,Cinv)*B))
				bottomleft = -Cinv*B*Omega
				bottomright = Cinv + Cinv*B*Omega*B'*Cinv
				XWXinv = (Omega, bottomleft' \ bottomleft, bottomright)
				_makesymmetric(XWXinv)
			}
			else {
				C = XWX
				if (diag0cnt(C)>0) {  // Avoid division by zero (add smallest number)
					diagC = diagonal(C)
					diagC = diagC + (diagC :== 0) :*mindouble()
					stata(`"di as text "division by zero avoided""')
				}
				else {
					diagC = diagonal(C)
				}
				XWXinv = diag(1:/diagC)
			}
			
			// Deconstruct diagonal(X*XWXin*X') -------------------------------	
			if (nxvars!=0) {	// If any covariates	
				SigD = XWXinv[|nxvars+1, nxvars+1 \ nxvarsall, nxvarsall|]
				SigV = XWXinv[|1, 1 \ nxvars, nxvars|]
				XD = X[1..., (nxvars+1)..(nxvarsall)]
				XV = X[1..., 1..nxvars]
				SigCross = XD*XWXinv[|nxvars+1, 1 \ nxvarsall, nxvars|]
				
				//P1: Dummy Sigma (XWXinv) block
				P1 = XD*diagonal(SigD)
				//P2: Cross term block (Sigma is symmetric so P2=P3')
				P2 = rowsum(SigCross:*XV)
				//P4: Variable sandwich block 
				P4 = rowsum((XV*SigV):*XV)
				//Construct 
				Q = P1+(2*P2)+P4  // Q is the diagonal of the matrix Q = X (X'WX) X' in McCullagh & Nelder

			}
			else {
				SigD = XWXinv[|nxvars+1, nxvars+1 \ nxvarsall, nxvarsall|]
				XD = X[1..., (nxvars+1)..(nxvarsall)]
				Q = XD*diagonal(SigD)
			}

		}
		else {  	// Else use original method invsym() (some FE dummies dropped due to collinearity)  -  inefficient!
		
			
			Q = diagonal( X * invsym( cross(X,W,X) ) * X' ) // Q is the diagonal of the matrix Q = X (X'WX) X' in McCullagh & Nelder
			
		}
		
		
		st_store(.,qvar,touse, Q)				
		
	
}
end
