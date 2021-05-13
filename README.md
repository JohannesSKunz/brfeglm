# BRFEGLM: estimate bias reduced fixed effect glm in Stata.

- Current version: `1.0.1 15mar2021`
- Jump to: [`overview`](#overview) [`installation`](#installation) [`example`](#example) [`update history`](#update-history) [`authors`](#authors) [`references`](#references) [`published applications`](#published-applications)

-----------

## Overview 

`brfeglm` is a [Stata](http://www.stata.com) command that estimates bias-reduced fixed effects glm models for probit, logit and cloglo by iterative weighted least squares (IWLS) and with a large dummy-variable set.

The program builds upon [brglm](https://github.com/JohannesSKunz/brglm), but is tailored to the estimation of fixed effects, it is much faster, omits the fixed effects from the regression output but extracts and stores them automatically in a new variables. 

Works with margin command. 

In combination with the package `fese_fast` it further allows to also get an estimate of the fixed effects standard error. 

## Installation

Can be installed in STATA via: 

```stata

* Install the most recent version of -brfeglm-
net install brfeglm, from("https://raw.githubusercontent.com/JohannesSKunz/brfeglm/master") replace
```

## Example 

Here is the Stata script:

```stata
webuse union
drop if idcode>1000

* Fixed-effects BRGLM probit regression
brfeglm union age grade not_smsa, model(probit) identifier(idcode)

* Same as above, but with clustered standard errors
brfeglm union age grade not_smsa, model(probit) identifier(idcode) cluster(idcode)

*Summarise the fixed effects estimates
su __feidcode*

*Calculate average marginal effects
margins, dydx(*)
```

## Update History
* **March 15, 2021**
  - initial commit

## Authors:

[Alexander Ballantyne](https://sites.google.com/view/arballantyne)
<br>University of Melbourne

[Johannes Kunz](https://sites.google.com/site/johannesskunz/)
<br>Monash University 

[Kevin E. Staub](http://www.kevinstaub.com)
<br>University of Melbourne 

[Rainer Winkelmann](https://www.econ.uzh.ch/en/people/faculty/winkelmann.html)
<br>University of Zurich

## References: 

**Bias reduced canonical link function models**:

Firth, David. 1993. [Bias Reduction of Maximum Likelihood Estimates](https://www.jstor.org/stable/2336755?seq=1#metadata_info_tab_contents). Biometrika. 80.1: 27-38.

**Bias reduced generalised linear models**: 

Kosmidis, I., & Firth, D. 2009. [Bias Reduction in Exponential Family Nonlinear Models](https://www.jstor.org/stable/27798867#metadata_info_tab_contents). Biometrika, 96(4), 793-804.

**Bias reduced fixed effect generalised linear models**: 

Kunz, Johannes, Kevin E. Staub, and Rainer Winkelmann. 2021. [Predicting Individual Effects in Fixed Effects Panel Probit Models](http://soda-wps.s3-website-ap-southeast-2.amazonaws.com/RePEc/ajr/sodwps/2021-05.pdf). Journal of the Royal Statistical Society: Series A. Forthcoming.

## Published applications:

Buchmueller, T. C., Cheng, T. C., Pham, N. T., & Staub, K. E. (2021). [The effect of income-based mandates on the demand for private hospital insurance and its dynamics](http://www.kevinstaub.com/ewExternalFiles/2021_jhe.pdf). Journal of Health Economics, 75, 102403.
