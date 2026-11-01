\name{ccctest}
\alias{ccctest}
\alias{test_table}
\alias{selection}
\alias{print.ccctest}
\alias{summary.ccctest}
\title{Common Causality of Covariates}
\description{Unweighted CCC chi-square Wald tests and gated additive second-stage Holm selection. This is not a test of parallel trends or an ATT estimator.}
\usage{
ccctest(formula, data, group, time, cohort = NULL, untreated = NULL,
        vce = "HC1", alpha = .05, alltests = FALSE, subset = NULL)
test_table(x)
selection(x)
\method{print}{ccctest}(x, ...)
\method{summary}{ccctest}(object, ...)
}
\arguments{
\item{formula}{Outcome and covariate design, e.g. y ~ x + factor(category) + I(x^2). One common basis is used.}
\item{data}{Data frame.}
\item{group}{Policy-region column name, numeric or string.}
\item{time}{Ordered numeric period column. Calendar dates must use a declared numeric encoding.}
\item{cohort}{First-treatment column; zero explicitly denotes never treated. Missing means unknown. Time zero conflicts with this coding.}
\item{untreated}{Alternative status column, 1=untreated, 0=treated. If both are supplied they must agree.}
\item{vce}{HC1 (default), OLS, or homoskedastic. Cluster/survey inference is unsupported.}
\item{alpha}{Rejection threshold, using p <= alpha.}
\item{alltests}{Compute unused second-stage diagnostics after nonrejection.}
\item{subset}{Optional positional logical row mask.}
\item{x,object}{Returned result.}
\item{...}{Print arguments; unused by summary.}
}
\details{Stage 1 has saturated cell intercepts and K slopes in each of U observed untreated cells, with K(U-1) equality restrictions. Stage 2 retains all region slopes and time deviations normalized to the first observed period. It tests region equality and zero time deviations from the same additive fit. Both covariance options include U intercepts in residual degrees of freedom. No generalized inverses, silent dropping or ridge penalties are used. Rank/conditioning failures yield undetermined; an unused diagnostic failure preserves valid homogeneous selection. Stage 1 nonrejection selects homogeneous. Following rejection, Holm region-only selects region, time-only selects time, and both/neither select twoway with distinct reason codes.}
\value{A ccctest list with tests (W,Q,p,p_holm,reject,performed,used), selected, reason, status, sample mask, basis, fits, restrictions and diagnostics. Auxiliary fit covariances are for slope coefficients; intercepts and cell metadata are separate. Accessors return the table or selection code; summary returns the structured result.}
\note{Nonrejection does not prove CCC. HC1 is not cluster robust, including for repeated person IDs. Covariates affected by treatment, lack of overlap and misspecified conditional means are not repaired by selection. No general selected-model ATT confidence-interval guarantee follows from the chapter's simulations. More than 2000 slope parameters or cross-product condition above 1e12 is refused.}
\references{Sunny Karim (September 28, 2026), Testing Common Causality of Covariates: Evidence from Private-Sector Ban-the-Box Policies, pp. 25--30, equations (114)--(127). Background DID-INT: Karim and Webb (2024), Good Controls Gone Bad.}
\examples{
d <- read.csv(system.file("extdata", "original.csv", package="ccctest"))
fit <- ccctest(y_state ~ x, d, "group", "year", "gvar")
test_table(fit)
selection(fit)
}
