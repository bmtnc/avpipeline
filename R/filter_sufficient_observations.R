#' Filter Groups with Sufficient Observations
#'
#' Filters a grouped dataset to retain only groups that have at least the minimum
#' number of observations. Groups with fewer observations are completely removed.
#'
#' @param data Data frame to filter
#' @param group_col Character string specifying the column name to group by
#' @param min_obs Integer minimum number of observations required per group
#' @return Data frame with only groups having sufficient observations
#' @export
filter_sufficient_observations <- function(data, group_col, min_obs) {
  
  # Input validation for group_col
  if (!is.character(group_col) || length(group_col) != 1) {
    stop(paste0("Argument 'group_col' must be single character string, received: ", 
                class(group_col)[1], " of length ", length(group_col)))
  }
  
  # Validate data frame and required columns
  validate_df_cols(data, group_col)
  
  # Input validation for min_obs
  if (!is.numeric(min_obs) || length(min_obs) != 1) {
    stop(paste0("Argument 'min_obs' must be single numeric value, received: ", 
                class(min_obs)[1], " of length ", length(min_obs)))
  }
  
  if (is.na(min_obs) || min_obs < 1) {
    stop(paste0("Argument 'min_obs' must be positive integer, received: ", min_obs))
  }
  
  # Convert to integer for comparison
  min_obs <- as.integer(min_obs)
  
  # Create symbol for group column (NSE required for programmatic grouping)
  group_sym <- rlang::sym(group_col)
  
  # Filter groups with sufficient observations
  data %>%
    dplyr::group_by(!!group_sym) %>%
    dplyr::add_count() %>%
    dplyr::ungroup() %>%
    dplyr::filter(n >= min_obs) %>%
    dplyr::select(-n)
}