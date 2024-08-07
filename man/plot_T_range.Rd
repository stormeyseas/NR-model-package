% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diagnostic-functions.R
\name{plot_T_range}
\alias{plot_T_range}
\title{Plot of species growth response over a range of temperatures}
\usage{
plot_T_range(T_range = seq(-10, 35, 0.25), spec_params)
}
\arguments{
\item{T_range}{a vector of the range of temperatures to be tested (defaults to seq(-10, 35, 0.25))}

\item{spec_params}{a vector of named numbers. Must include:
\itemize{
\item \code{T_opt} the optimum temperature for macroalgae growth
\item \code{T_min} the minimum temperature for macroalgae growth (when \code{T_c} < \code{T_min}, growth = 0)
\item \code{T_max} the maximum temperature for macroalgae growth (when \code{T_c} > \code{T_max}, growth = 0)
}}
}
\value{
a ggplot object of growth response over the specified temperature range
}
\description{
Plot of species growth response over a range of temperatures
}
\examples{
examples
}
\seealso{
\code{\link[=T_lim]{T_lim()}}
}
