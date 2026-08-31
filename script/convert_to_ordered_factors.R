#' Convert Select-One Variables to Ordered Factors
#'
#' This function takes a dataframe containing analysis data, a form dataframe,
#' and a formchoices dataframe, and converts select-one variables (as defined
#' in the form) to ordered factors in the analysis dataframe.
#'
#' @param data A dataframe containing the analysis data where select-one
#'   variables will be converted to ordered factors.
#' @param form A dataframe containing information about the form structure,
#'   including variable names and types.
#' @param formchoices A dataframe containing the possible choices for each
#'   variable in the form.
#' @param ignore Character vector of variables that should not be converted
#'   to ordered factors.
#'
#' @return A modified version of `data`, where select-one variables have been
#'   converted to ordered factors according to the levels defined in
#'   `formchoices`.
#'
#' @examples
#' \dontrun{
#' df_analysis_ordered <- convert_to_ordered_factors(
#'   data = df_analysis_scaled,
#'   form = needs4_form,
#'   formchoices = needs4_formchoices
#' )
#' }

convert_to_ordered_factors <- function(
    data,
    form,
    formchoices,
    ignore = c("area.village", "area.ward")
) {
  
  # --------------------------------------------------------------------------
  # Filter select-one variables from the form
  # --------------------------------------------------------------------------
  
  scale_form <- form %>%
    dplyr::filter(
      !is.na(type),
      !is.na(name),
      grepl("select one", type, ignore.case = TRUE),
      !(name %in% ignore)
    ) %>%
    dplyr::select(
      name,
      list_name,
      label.english
    )
  
  # --------------------------------------------------------------------------
  # Filter form choices of interest
  # --------------------------------------------------------------------------
  
  scale_formchoices <- formchoices %>%
    dplyr::filter(
      !is.na(list_name),
      !is.na(choices)
    ) %>%
    dplyr::select(
      list_name,
      choices,
      label.english
    )
  
  # --------------------------------------------------------------------------
  # Aggregate choices by list_name
  # --------------------------------------------------------------------------
  
  df_levels <- scale_formchoices %>%
    dplyr::group_by(list_name) %>%
    dplyr::summarise(
      levels = paste(
        unique(choices),
        collapse = ";"
      ),
      .groups = "drop"
    )
  
  # --------------------------------------------------------------------------
  # Join variable names to their corresponding choice levels
  # --------------------------------------------------------------------------
  
  df_levels_with_names <- df_levels %>%
    dplyr::left_join(
      scale_form,
      by = "list_name"
    ) %>%
    dplyr::filter(
      !is.na(name)
    ) %>%
    dplyr::select(
      name,
      levels,
      list_name
    )
  
  # --------------------------------------------------------------------------
  # Convert relevant columns to ordered factors
  # --------------------------------------------------------------------------
  
  for (i in seq_len(nrow(df_levels_with_names))) {
    
    var_name <- df_levels_with_names$name[i]
    
    factor_levels <- strsplit(
      df_levels_with_names$levels[i],
      ";",
      fixed = TRUE
    )[[1]]
    
    if (var_name %in% names(data)) {
      
      data[[var_name]] <- factor(
        data[[var_name]],
        levels = factor_levels,
        ordered = TRUE
      )
    }
  }
  
  return(data)
}