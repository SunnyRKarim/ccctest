\name{ccc_trends}
\alias{ccc_trends}
\alias{plot_data}
\alias{plot.ccc_trends}
\alias{print.ccc_trends}
\title{Untreated Trend Diagnostics}
\description{Standalone six-panel numeric diagnostics, with optional native R plots.}
\usage{
ccc_trends(formula, data, group, time, cohort, subset = NULL,
           focal = NULL, window = NULL, controls = "never",
           matches = NULL, focal_weights = NULL, reference = "zero")
plot_data(x)
\method{plot}{ccc_trends}(x, panels = "core", ...)
\method{print}{ccc_trends}(x, ...)
}
\arguments{
\item{formula,data,group,time,cohort,subset}{As in \code{ccctest}.}
\item{focal}{Selected future-adopting region labels. Defaults to all observed adopters.}
\item{window}{Optional inclusive pair of dates before earliest focal adoption.}
\item{controls}{never or notyet; comparisons remain untreated throughout the fixed window.}
\item{matches}{Data frame with focal, control and control_weight columns. Weights sum to one within focal region. No self-matches.}
\item{focal_weights}{Named nonnegative vector summing to one, default equal focal-region weights.}
\item{reference}{zero (default), pooled, or a numeric K-vector of common reference basis values.}
\item{x}{Returned trend object.}
\item{panels}{core, all, or an individual raw/homogeneous/region/time/twoway/integrated panel.}
\item{...}{Arguments to matplot or print.}
}
\value{A ccc_trends list containing aggregate series, pairwise audit data, cells, coefficients, matches, reference and diagnostics. plot returns an invisible reusable recordedplot; replayPlot can redraw it. plot_data returns the aggregate data frame.}
\details{Fits use the same common untreated window and saturated cell intercepts. Adjusted means subtract only the covariate contribution relative to the chosen reference. Unrestricted integrated changes evaluate all four endpoints at the focal treated target-period mean of the actual basis. Baseline and control means are not substituted. Fixed weights are software conventions. Changes are over adjacent observed dates; intervals are returned and are not necessarily annual. Pair data contain predictions, endpoint coefficients, target means and marginal-range flags; these flags do not prove joint overlap. Complete endpoint support is required. No confidence bands are computed.}
\note{The CCC testing sample and plotting sample differ. Graphs do not establish identifying assumptions; homogeneous adjustment is not an exhaustive CPT test. Integrated Parallel Trends is the current terminology. Heterogeneous adjusted curves depend on the reference. Input data, working directory and random state are preserved.}
\references{Sunny Karim (2026), Section 5.4, pp. 51--53, equations (147)--(149).}
\examples{
d <- read.csv(system.file("extdata", "original.csv", package="ccctest"))
tr <- ccc_trends(y_state ~ x, d, "group", "year", "gvar")
head(plot_data(tr))
plot(tr)
}
