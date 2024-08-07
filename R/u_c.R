#' Relative water attenuation within canopy
#' 
#' #' @description
#' A short description...
#'
#' @param U0 incoming incident water velocity (m/s)
#' @param macro_state vector of named numbers. Must include:
#'  * `biomass`, macroalgae wet weight (g)
#'  * `hm`, algae height (m)
#' @param SA_WW conversion of wet weight to surface area (default is 0.5\eqn{\times}0.5\eqn{\times}0.0306, based on *Macrocystis pyrifera*)
#' @param site_params vector of named numbers. Must include:
#'  * `hz`, total water depth (m)
#'  * `hc`, vertical water column occupied by the canopy (m)
#'  * `d_top`, depth of the top of the canopy beneath the water surface (m)
#' @param constants vector of named numbers defining extra constants for the attenuation submodel. Must include:
#'  * `s` = 0.0045
#'  * `gam` = 1.13
#'  * `a2` = 0.2^2
#'  * `Cb` = 0.0025
#'
#' @return the relative water attenuation coefficient (u_c)
#' @export
#' @seealso [algae_height(), u_b(), C_t()]
#' 
u_c <- function(U0, macro_state = c(biomass, hm), SA_WW = 0.5 * (0.0306/2), site_params, constants = c(s = 0.0045, gam = 1.13, a2 = 0.2^2, Cb = 0.0025)){
  
  D <- SA_WW * min(macro_state['hm']/site_params['hc'], 1) * macro_state['biomass']
  Kd <- 0.5 * site_params['hz'] * D * constants['s'] * U0^(constants['gam'] - 2)
  Hc <- (site_params['d_top'] + site_params['hc']) / site_params['hz']
  
  drag_test <- sqrt(Kd * (1 - Hc) * Hc * (constants['Cb'] * Hc + constants['a2']) - constants['a2'] * constants['Cb'] * Hc)
  if (is.na(drag_test)) {
    u_c <- 1
  } else {
    u_c <- (-constants['a2'] - constants['Cb'] * Hc ^ 2 + (1 - Hc) * drag_test) / (Kd * Hc * (1 - Hc) ^ 3 - constants['a2'] - constants['Cb'] * Hc ^ 3)
  }
  return(unname(u_c))
}
