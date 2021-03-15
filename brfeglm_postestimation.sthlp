{smcl}
{* *! version 1.0.0  16mar2021}{...}
{viewerdialog predict "dialog brfeglm_p"}{...}
{viewerdialog estat "dialog probit_estat"}{...}
{viewerdialog lroc "dialog lroc"}{...}
{viewerdialog lsens "dialog lsens"}{...}
{vieweralsosee "[R] brfeglm postestimation" "mansection R brfeglmpostestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] brfeglm" "help brfeglm"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] estat classification" "help estat classification"}{...}
{vieweralsosee "[R] estat gof" "help logistic estat gof"}{...}
{vieweralsosee "[R] lroc" "help lroc"}{...}
{vieweralsosee "[R] lsens" "help lsens"}{...}
{viewerjumpto "Postestimation commands" "brfeglm postestimation##description"}{...}
{viewerjumpto "predict" "brfeglm postestimation##syntax_predict"}{...}
{viewerjumpto "margins" "brfeglm postestimation##syntax_margins"}{...}
{viewerjumpto "Examples" "brfeglm postestimation##examples"}{...}
{p2colset 1 32 34 2}{...}

{p2col:{bf:[R] brfeglm postestimation} {hline 2}}Postestimation tools for
brfeglm{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following standard postestimation commands are available:

{synoptset 20 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
INCLUDE help post_contrast
INCLUDE help post_estatic
INCLUDE help post_estatsum
INCLUDE help post_estatvce
INCLUDE help post_estimates
INCLUDE help post_forecast
INCLUDE help post_hausman
INCLUDE help post_lincom
INCLUDE help post_lrtest
{synopt:{helpb brfeglm_postestimation##margins:margins}}marginal
	means, predictive margins, marginal effects, and average marginal
	effects{p_end}
INCLUDE help post_marginsplot
INCLUDE help post_nlcom
{synopt :{helpb brfeglm postestimation##predict:predict}}predictions and score{p_end}
INCLUDE help post_predictnl
INCLUDE help post_pwcompare
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker syntax_predict}{...}
{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} 
[{cmd:,} {it:statistic} ]

{synoptset 20 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{syntab :Main}
{p2coldent :* {opt p:r}}probability of a positive outcome; the default{p_end}
{synopt :{cmd:xb}}a + xb, linear prediction{p_end}
{p2coldent :* {cmd:xbu}}a + xb + u_i, linear prediction including fixed effects{p_end}
{synopt :{cmd:stdp}}standard error of the linear prediction (a + xb){p_end}
{p2coldent :* {opt sc:ore}}first derivative of the log likelihood with respect to xbu{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help unstarred


INCLUDE help menu_predict


{marker des_predict}{...}
{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as
probabilities, linear predictions, standard errors, deviance residuals,
and equation-level scores.


{marker options_predict}{...}
{title:Options for predict}

{dlgtab:Main}

{phang}
{opt pr}, the default, calculates the probability of a positive outcome {it:including} the fixed effects.

{phang}
{opt xb} calculates the simple linear prediction, a + xb.

{phang}
{opt xbu} calculates the linear prediction {it:including} the fixed effects, a + xb + u_i.

{phang}
{opt stdp} calculates the standard error of the simple linear prediction, a + xb.

{phang}
{opt score} calculates the equation-level score, the derivative of the log
likelihood with respect to the linear prediction {it:including} the fixed effects.


INCLUDE help syntax_margins

{synoptset 17}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt p:r}}probability of a positive outcome; the default{p_end}
{synopt :{cmd:xb}}linear prediction{p_end}
{synopt :{cmd:xbu}}not allowed with {cmd:margins}{p_end}
{synopt :{opt stdp}}not allowed with {cmd:margins}{p_end}
{synopt :{opt sc:ore}}not allowed with {cmd:margins}{p_end}
{synoptline}
{p2colreset}{...}

INCLUDE help notes_margins


INCLUDE help menu_margins


{marker des_margins}{...}
{title:Description for margins}

{pstd}
{cmd:margins} estimates margins of response for probabilities and linear
predictions.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse union}{p_end}
{phang2}{cmd:. drop if idcode>1000}{p_end}
{phang2}{cmd:. brfeglm union age grade, model(probit) identifier(idcode)}{p_end}

{pstd}Obtain predicted probabilities{p_end}
{phang2}{cmd:. predict p}

{pstd}Calculate and display summary statistics{p_end}
{phang2}{cmd:. summarize union p}{p_end}

{pstd}Calculate average marginal effects{p_end}
{phang2}{cmd:. margins, dydx(*)}{p_end}

