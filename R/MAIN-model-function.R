#' Grow macroalgae
#' 
#' @description
#' Initiate and grow macroalgae.
#'
#' @param start date, start of the growth period, date of at-sea deployment
#' @param grow_days integer, number of 
#' @param temperature vector
#' @param light vector
#' @param velocity vector
#' @param nitrate vector
#' @param ammonium vector
#' @param other_N vector 
#' @param site_params a named vector of species-specific parameters - see details
#' @param spec_params a named vector of site-specific parameters - see details
#' @param initials a named vector of the macroalgae starting conditions
#' @param other_constants a named vector of miscellaneous constants, including:
#' * s = 0.0045, the experimentally-derived shape factor for macroalgae movement in water
#' * gam = 1.13, the modified drag coefficient for macroalgae
#' * a2 = 0.2^2, 
#' * Cb = 0.0025, the bottom friction coefficient
#'
#' @importFrom lubridate is.Date ymd duration yday
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @import dplyr
#' @import rlang
#' @importFrom units set_units drop_units
#' 
#' @return dataframe of outputs
#' @export 
#' 
#' @details
#' Example csv with all the spec_params & site_params required? 
#' - Note that the final growth dataframe is inclusive of the start and end date, so the environmental vectors must be the same
#'
#' @examples "see here" link?
grow_macroalgae <- function(start, 
                            grow_days, 
                            temperature, 
                            light, 
                            velocity, 
                            nitrate, 
                            ammonium, 
                            other_N, 
                            ni_uptake, 
                            am_uptake, 
                            ot_uptake, 
                            site_params, 
                            spec_params, 
                            initials,
                            other_constants = c(s = 0.0045, gam = 1.13, a2 = 0.2^2, Cb = 0.0025)) {
  
  # Parse start date
  if (lubridate::is.Date(start)) {
    start_date <- start
  } else if (is.integer(start) | is.numeric(start)) {
    if (missing(start_year)) {start_year <- 2000}
    start_date <- parse_date_time(x = paste(start_year, start), orders = "yj") # - duration(1, "days")
  } else if (is.character(start)) {
    start_date <- lubridate::ymd(start)
  }

  # Populate start and end dates to create ts
  end_date <- start_date + lubridate::duration(grow_days, "days")
  start_t <- lubridate::yday(start_date)
  end_t <- start_t + grow_days
  t <- seq(start_t, end_t, 1)
  
  # Light, temperature and nutrient levels are passed to the function as vectors - check length
  if (length(temperature) != length(t)) {
    rlang::abort(message = glue::glue(
      "Error: temperature vector has length {obs} but timespan vector has length {exp}",
      obs = length(temperature),
      exp = length(t)))
  }
  if (length(light) != length(t)) {
    rlang::abort(message = glue::glue(
      "Error: light vector has length {obs} but timespan vector has length {exp}",
      obs = length(light),
      exp = length(t)))
  }
  if (length(nitrate) != length(t)) {
    rlang::abort(message = glue::glue(
      "Error: nitrate vector has length {obs} but timespan vector has length {exp}",
      obs = length(nitrate),
      exp = length(t)))
  }
  if (length(ammonium) != length(t)) {
    rlang::abort(message = glue::glue(
      "Error: ammonium vector has length {obs} but timespan vector has length {exp}",
      obs = length(ammonium),
      exp = length(t)))
  }
  if (length(velocity) != length(t)) {
    rlang::abort(message = glue::glue(
      "Error: velocity vector has length {obs} but timespan vector has length {exp}",
      obs = length(velocity),
      exp = length(t)))
  }
  
  # Site parameters
  farmV <- unname(site_params['farmA'] * site_params['hc'])         # Volume of farm site
  
  # Rename environmental vectors
  Tc <- temperature
  I <- light
  Ni_add <- nitrate
  Am_add <- ammonium
  U <- velocity
  u_c <- I_top <- Ni_conc <- Am_conc <- det <- Nf <- Ns <- N_int <- N_rel <- B_dw.mg <- B_ww.mg <- hm <- lambda <- lambda_0 <- other_conc <- Q_int <- Q_rel <- T_lim <- Q_lim <- I_lim <- growth_rate <- Ns_to_Nf <- Ns_loss <- Nf_loss <- red_Am <- remin <- other_add <- up_Am <- up_Ni <- 
    numeric(length = length(t))

  # For adding other_N (e.g. urea, amino acids)
  if (!missing(other_N) | length(other_N) == 0) {
    other_add[1] <- 0
  } else if (length(other_N) != length(t)) {
    rlang::abort(message = glue::glue("Error: other_N vector has length {obs} but timespan vector has length {exp}", obs = length(other_N), exp = length(t)))
  } else {
    other_add[1] <- other_N[1]
  }
  
  # External starting state
  Am_conc[1]       <- Am_add[1]
  Ni_conc[1]       <- Ni_add[1]
  other_conc[1]    <- other_add[1]
  
  # Macroalgae starting state
  Nf[1]            <- unname(initials['Nf'])  # Fixed nitrogen
  Ns[1]            <- Nf[1]*(unname(initials['Q_int'])/spec_params['Q_min'] - 1)          # Stored nitrogen
  det[1]           <- 10
  
  # Main run, after starting state
  for (i in 1:length(t)) {
    
  # Possibility of macroalgae dying
    if (Nf[i-1] <= 0) {
      Nf[i] <- 0
      Ns[i] <- 0
      B_dw.mg[i] <- 0
      B_ww.mg[i] <- 0
      hm[i] <- 0
      up_Am[i] <- 0
      up_Ni[i] <- 0
      up_Ot[i] <- 0
      
      Ns_to_Nf[i] <- 0
      Ns_loss[i] <- 0
      Nf_loss[i] <- 0
      N_int[i] <- NA
      N_rel[i] <- NA
      Q_int[i] <- NA
      Q_rel[i] <- NA
      Q_lim[i] <- NA
      growth_rate[i] <- NA

      Ni_conc[i] <- Ni_add[i]
      Am_conc[i] <- Am_add[i]
      other_N[i] <- other_add[i]
      T_lim[i] <- NA
      I_top[i] <- NA
      I_lim[i] <- NA
      u_c[i] <- NA
      lambda[i] <- NA
      lambda_0[i] <- NA

      red_Am[i] <- unname(site_params['Rd'] * Am_conc[i])
      remin[i] <- unname(site_params['rL'] * det[i])
      
    } else {
      Q_int[i]       <- Q_int(Nf[i], Ns[i], spec_params)
      Q_rel[i]       <- Q_rel(Q_int[i], spec_params)
      N_int[i]       <- N_int(Q_rel = Q_rel[i], Q_int = NA, spec_params)
      N_rel[i]       <- N_rel(N_int[i], spec_params)
      B_dw.mg[i]     <- (Nf[i]+Ns[i]) / N_int[i]
      B_ww.mg[i]     <- B_dw.mg[i] * unname(spec_params['DWWW'])
      hm[i]          <- algae_height(Nf[i], spec_params)
      
      # Environmental state (incoming)
      u_c[i]         <- suppressWarnings(u_c(U0 = U[i],
                                             macro_state = c(biomass = B_ww.mg[i]/1000, hm[i]),
                                             SA_WW = spec_params['SA_WW'],
                                             site_params = site_params,
                                             constants = other_constants))
      
      U_0            <- set_units(set_units(U[i], "m s-1"), "m d-1")
      lambda[i]      <- (u_c[i] * U_0)/farmV 
      lambda_0[i]    <- U_0/farmV 
    
      # Temperature limitation on growth
      T_lim[i]       <- T_lim(Tc[i], spec_params)
      
      # Internal nutrient limitation on growth
      Q_lim[i]       <- Q_lim(Nf[i], Ns[i], spec_params)
      
      # Light limitation on growth
      I_top[i]       <- unname(I[i] * exp(-site_params['kW'] * site_params['d_top']))
      I_lim[i]       <- I_lim(Nf[i], I_top[i], spec_params, site_params)
      
      Am_conc[i]     <- Am_add[i] * lambda_0[i]/lambda[i]
      Ni_conc[i]     <- Ni_add[i] * lambda_0[i]/lambda[i]
      other_conc[i]  <- other_add[i] * lambda_0[i]/lambda[i]
      
      # Biomass loss
      U_0            <- drop_units(set_units(U_0, "m s-1"))
      D_m            <- loss(U0 = U_0, turbulence = site_params['turbulence'], spec_params = spec_params)
      
      # Nitrogen pool changes
      growth_rate[i] <- unname(spec_params['mu'] * I_lim[i] * T_lim[i] * Q_lim[i])
      Ns_to_Nf[i]    <- pmin(growth_rate[i] * Ns[i], Ns[i]) # cannot convert more Ns than available
      Ns_loss[i]     <- unname(D_m * Ns[i])
      Nf_loss[i]     <- unname(D_m * Nf[i])
      red_Am[i]      <- unname(site_params['Rd'] * Am_conc[i]) # Reduction of ammonium (to nitrate)
      remin[i]       <- unname(site_params['rL'] * det[i]) # Remineralisation of detritus (to ammonium)
      
      up_Am[i]       <- Q_rel(Q_int(Nf[i], Ns[i], spec_params), spec_params) * (B_dw.mg[i]/1000) * 
                         get_uptake(conc = Am_conc[i], 
                                     uptake_shape = am_uptake, 
                                     Nform_abbr = "am", 
                                     spec_params = spec_params)
      up_Am[i]       <- pmin(up_Am[i], Am_conc[i])
      
      up_Ni[i]       <- Q_rel(Q_int(Nf[i], Ns[i], spec_params), spec_params) * (B_dw.mg[i]/1000) * 
                          get_uptake(conc = Ni_conc[i], 
                                     uptake_shape = ni_uptake, 
                                     Nform_abbr = "ni", 
                                     spec_params = spec_params)
      up_Ni[i]       <- pmin(up_Ni[i], Ni_conc[i])
    }
    
    if (i < length(t)) {
      # Changes in external state
      Am_conc[i+1] <- Am_conc[i] - up_Am[i] + Ns_loss[i] - red_Am[i] + remin[i]
      Ni_conc[i+1] <- Ni_conc[i] - up_Ni[i] + red_Am[i]
      det[i+1]     <- det[i] + Nf_loss[i] - remin[i]
      
      # Change in algae state
      Nf[i+1]      <- Nf[i] + Ns_to_Nf[i] - Nf_loss[i]
      Ns[i+1]      <- Ns[i] + up_Am[i] + up_Ni[i] - Ns_to_Nf[i] - Ns_loss[i]
    }
  }
    
    df <- data.frame(
      t = t, 
      date = seq(start_date, end_date, by = 'days'),
      Nf = Nf,
      Ns = Ns,
      growth_rate = growth_rate,
      Ns_to_Nf = Ns_to_Nf,
      Ns_loss = Ns_loss,
      Nf_loss = Nf_loss,
      N_int = N_int,
      N_rel = N_rel,
      Q_int = Q_int,
      Q_rel = Q_rel,
      Q_lim = Q_lim,
      B_dw.mg = B_dw.mg,
      B_ww.mg = B_ww.mg,
      Ni_add = Ni_add,
      Am_add = Am_add,
      other_add = other_add,
      Ni_conc = Ni_conc,
      Am_conc = Am_conc,
      other_N = other_N,
      up_Am = up_Am,
      up_Ni = up_Ni,
      up_Ot = NA,
      Tc = temperature,
      T_lim = T_lim,
      I = light,
      I_top = I_top,
      hm = hm,
      I_lim = I_lim,
      U = velocity,
      u_c = u_c,
      lambda = lambda,
      lambda_0 = lambda_0,
      det = det,
      red_Am = red_Am,
      remin = remin
    )
    return(df)
}


