{smcl}
{* *! version 1.0.0  15june2020}{...}
{viewerdialog brfeglm "dialog brfeglm"}{...}
{vieweralsosee "[R] brfeglm" "mansection R brfeglm"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] brfeglm postestimation" "help brfeglm postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] glm" "help glm"}{...}
{vieweralsosee "[R] heckoprobit" "help heckoprobit"}{...}
{vieweralsosee "[R] hetprobit" "help hetprobit"}{...}
{vieweralsosee "[R] ivprobit" "help ivprobit"}{...}
{vieweralsosee "[R] logistic" "help logistic"}{...}
{vieweralsosee "[R] logit" "help logit"}{...}
{vieweralsosee "[ME] meprobit" "help meprobit"}{...}
{vieweralsosee "[R] mprobit" "help mprobit"}{...}
{vieweralsosee "[R] npregress" "help npregress"}{...}
{vieweralsosee "[R] roc" "help roc"}{...}
{vieweralsosee "[R] scobit" "help scobit"}{...}
{vieweralsosee "[SVY] svy estimation" "help svy_estimation"}{...}
{vieweralsosee "[XT] xtprobit" "help xtprobit"}{...}
{vieweralsosee "[R] probit" "help probit"}{...}
{vieweralsosee "[R] logit" "help logit"}{...}
{vieweralsosee "[R] cloglog" "help cloglog"}{...}
{viewerjumpto "Syntax" "brfeglm##syntax"}{...}
{viewerjumpto "Menu" "brfeglm##menu"}{...}
{viewerjumpto "Description" "brfeglm##description"}{...}
{viewerjumpto "Options" "brfeglm##options"}{...}
{viewerjumpto "Examples" "brfeglm##examples"}{...}
{viewerjumpto "Stored results" "brfeglm##results"}{...}
{viewerjumpto "References" "brfeglm##references"}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[R] brfeglm} {hline 2}}Biased-reduced fixed effect glm regression for nonlinear models {p_end}
{p2col:}({mansection R brfeglm:View complete PDF manual entry}){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{opt brfeglm} {depvar} [{indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Model}
{synopt :{opt model(modeltype)}}nonlinear model, {it:modeltype} may be {opt probit}, {opt logit} or {opt cloglog};
 default is {cmd:model(probit)}{p_end}
{p2coldent :* {opth iden:tifier(idvar)}}set {it:idvar} as panel unit identifier for fixed effects{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt iwls}, {opt r:obust} or {opt cl:uster} {it:clustvar}{p_end}

{syntab :Reporting}
{synopt :{opt savef:e}}save predicted fixed effects as variable {it:__fe[idvar]}{p_end}
{synopt :{opt savew:eights}}save final weights as variable {it:__fe[idvar]wgt}{p_end}
{synopt :{opt fese:fast}}calculate and save standard errors of the predicted fixed effects{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{it:{help brfeglm##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab :Maximization}
{synopt :{opt iter:ate(#)}}perform maximum of # iterations; default is {cmd:iterate(5000)}{p_end}
{synopt :{opt tol:erance(#)}}tolerance for the coefficient vector; default is {cmd:tolerance(1.000e-6)}{p_end}

{synopt :{opt nocoe:f}}do not display the coefficient table; seldom
used{p_end}
INCLUDE help shortdes-coeflegend
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt identifier(idvar)} is required if {cmd:xtset} {it:panelvar} has not been specified.{p_end}
INCLUDE help fvvarlist
{p 4 6 2}{it:depvar} and {it:indepvars} may
contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}See {manhelp brfeglm_postestimation R:brfeglm postestimation} for features
available after estimation.  {p_end}


{marker menu}{...}
{title:Menu}

{phang}
{bf:Statistics > Longitudinal/panel data > Binary outcomes > Biased-reduced glm regression}


{marker description}{...}
{title:Description}

{pstd}
{cmd:brfeglm} fits a fixed-effects probit, logit or cloglog model for a binary dependent variable, assuming
that the probability of a positive outcome is determined by the respective standard
cumulative distribution function. {cmd:brfeglm} can compute predicted fixed-effects and is suitable when 
there is a high proportion of panel units without variation in the binary response. 
See {help brfeglm##KSW2020: Kunz et al. (2020)} for details. 


{marker options}{...}
{title:Options}

{dlgtab:Model}
{marker model}
{phang}
{opt model(modeltype)} specifies the distribution for the probability of a positive outcome in the 
binary dependent variable. {it:modeltype} may be {opt probit}, {opt logit} or {opt cloglog}. 
See {manhelp probit R:probit}, {manhelp logit R:logit} or {manhelp cloglog R:cloglog} for details of
model specification. The default is {cmd:model(probit)}.

{phang}
{opt identifier(idvar)} sets {it:idvar} as the panel unit identifier used to create fixed effects.
{it:idvar} can be different from the panel unit identifier of the current {help xtset} settings; however,
if {opt identifier(idvar)} is omitted, the panel unit identifier from {cmd:xtset} is used. The vector of 
predicted fixed effects, {cmd:e(b_fe)}, is sorted by {it:idvar}. 

{dlgtab:SE/Robust}

{phang}
{opth vce(vcetype)} specifies the type of standard error reported, which includes types that are derived from 
asymptotic theory ({opt iwls}), that are robust to some kinds of misspecification ({opt robust}), and that 
allow for intragroup correlation ({opt cluster} {it:clustvar}). 
{it:clustvar} may be different to {it: idvar}.

{dlgtab:Reporting}

{phang}
{opt savefe} saves predicted fixed effects as variable {it:__fe[idvar]}. Due to the weighting used in 
estimation, the predicted fixed effects are not mean zero. 

{phang}
{opt saveweights} saves final weights as variable {it:__fe[idvar]wgt}. These are {help aweight} type.

{phang}
{opt fesefast} calculates standard errors of the predicted fixed effects using {cmd: fese_fast} and
saves the resulting matrix in {cmd:e()}.
If option {opt savefe} is also used, the standard errors of the fixed effects are 
saved as variable {it:__fe[idvar]se}.
Option {opt fesefast} requires command {cmd: fese_fast} to be installed from <http://sacarny.com/programs/>.

{phang}
{opt level(#)}; see 
{helpb estimation options##level():[R] estimation options}.

INCLUDE help displayopts_list

{marker brfeglm_maximize}{...}
{dlgtab:Maximization}

{phang}
{opt iterate(#)} specifies the maximum number of iterations.  When the number of iterations equals iterate(), the
optimizer stops and presents the current results.  If convergence is declared before this threshold is
reached, it will stop when convergence is declared. The default is {cmd:iterate(5000)}.

{phang}
{opt tolerance(#)} specifies the tolerance for the coefficient vector.  When the relative change in the
coefficient vector from one iteration to the next is less than or equal to tolerance(), the tolerance()
convergence criterion is satisfied. The default is {cmd:tolerance(1.000e-6)}.


{phang}
{opt nocoef} specifies that the coefficient table not be displayed.  This
option is sometimes used by programmers but is of no use interactively. 

{phang}
{opt coeflegend}; see
     {helpb estimation options##coeflegend:[R] estimation options}.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse union}{p_end}
{phang2}{cmd:. drop if idcode>1000}{p_end}

{pstd}Fixed-effects BRGLM probit regression{p_end}
{phang2}{cmd:. brfeglm union age grade not_smsa, model(probit) identifier(idcode)}{p_end}

{phang}Same as above, but with clustered standard errors{p_end}
{phang2}{cmd:. brfeglm union age grade not_smsa, model(probit) identifier(idcode) cluster(idcode)}{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse union}{p_end}
{phang2}{cmd:. drop if idcode<4000}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}Fixed-effects BRGLM logit regression{p_end}
{phang2}{cmd:. brfeglm union age grade, model(logit)}{p_end}

{phang}Same as above, but saving the fixed effects and their standard errors{p_end}
{phang2}{cmd:. brfeglm union age grade, model(logit) savefe fesefast}{p_end}
{phang2}{cmd:. sum __feidcode*}{p_end}
    {hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:brfeglm} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups (fixed effects){p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_a)}}degrees of freedom for absorbed effect{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(fe_mean)}}mean of vector of predicted fixed effects{p_end}
{synopt:{cmd:e(fe_sd)}}standard deviation of vector of predicted fixed effects{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:brfeglm}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(model)}}model type ({opt probit}, {opt logit} or {opt cloglog}) {p_end}
{synopt:{cmd:e(identifier)}}group identifier{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {cmd:margins}{p_end}
{synopt:{cmd:e(depvar)}}optimization criterion (for display not estimation){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(b_fe)}}vector of predicted fixed-effects (sorted by {cmd:e(identifier)}){p_end}
{synopt:{cmd:e(se_fe)}}vector of standard errors of predicted fixed-effects (sorted by {cmd:e(identifier)}){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}




{marker references}{...}
{title:References}


{marker KSW2020}{...}
{phang}
Kunz, J. S., K. E. Staub and R. Winkelmann 2020. "Predicting fixed effects in panel probit models." Monash Business School 10/19 (2019).

