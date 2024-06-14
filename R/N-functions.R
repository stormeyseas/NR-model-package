#' Nitrogen uptake rate
#'
#' @param conc 
#' @param V 
#' @param K 
#'
#' @return
#' @export
#'
#' @examples
N_uptake <- function(conc, V, K) {
  uprate <- (V * conc / (K + conc))
  return(uprate)
}

NN <- function(N_perc, spec_params) {
  NN <- (spec_params["N_max"] - N_perc)/(spec_params["N_max"] - spec_params["N_min"])
  return(NN)
}

#' Convert mg N m^{-3} d^{-1} to \mu mol N hr^{-1}
#'
#' @param N_mg_m3 Nitrogen (or any compound containing a single N atom) concentration in mg N m^{-3} d^{-1}
#'
#' @return Nitrogen concentration in \mu mol N hr^{-1}
#' @export
#'
#' @examples
#' 
N_mgd_umolh <- function(N_mg_m3){
  umol_h = N_mg_m3 * 10^3 * # from milli to micro
    14.0067^-1 * # from g N to mol N
    24^-1 # from days to hours
  return(umol_h)
}

#' Convert mg N m^{-3} to $\mu$mol N L^{-1}
#'
#' @param mg_m3 Nitrogen (or any compound containing a single N atom) concentration in mg N m^{-3}
#'
#' @return Nitrogen concentration in $\mu$mol N L^{-1}
#' @export
#'
#' @examples
#' 
N_mgm3_umolL <- function(mg_m3){
  umol_L = mg_m3 / 14.0067
  return(umol_L)
}

#' Convert $\mu$mol N L^{-1} to mg N m^{-3}
#'
#' @param umol_L Nitrogen (or any compound containing a single N atom) concentration in $\mu$mol N L^{-1}
#'
#' @return Nitrogen concentration in mg N m$^{-3}$
#' @export
#'
#' @examples
#' 
N_umolL_mgm3 <- function(umol_L){
  mg_m3 = umol_L * 14.0067
  return(mg_m3)
}
