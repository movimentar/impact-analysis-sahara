#' Convert Select-One Variables to Ordered Factors
#'
#' This function takes a dataframe containing analysis data, a form dataframe, and a formchoices dataframe, and converts select-one variables (as defined in the form) to ordered factors in the analysis dataframe.
#'
#' @param data A dataframe containing the analysis data where select-one variables will be converted to ordered factors.
#' @param form A dataframe containing information about the form structure, including variable names and types.
#' @param formchoices A dataframe containing the possible choices for each variable in the form.
#'
#' @return A modified version of the input `data` dataframe, where select-one variables have been converted to ordered factors based on the levels defined in the `formchoices` dataframe.
#'
#' @examples
#' \dontrun{
#' df_analysis_ordered <- convert_to_ordered_factors(
#'   data = df_analysis_scaled, 
#'   form = needs4_form, 
#'   formchoices = needs4_formchoices
#' )
#' }
convert_to_ordered_factors <- function(data, form, formchoices, ignore = c("area.village", "area.ward")) {
  # Filter select_one variables from the form
  scale_form <- form %>%
    filter(grepl("select one", type, .) & !(name %in% ignore)) %>% 
    select(name:list_name, label.english)
  
  # Filter form choices of interest
  scale_formchoices <- formchoices %>%
    select(list_name, choices, label.english)
  
  # Aggregate choices by list_name
  df_levels <- scale_formchoices %>%
    group_by(list_name) %>%
    dplyr::summarize(levels = paste(unique(choices), collapse = ";"), .groups = "drop") 
  
  # Join to get variable names and levels
  df_levels_with_names <- df_levels %>%
    left_join(scale_form, by = "list_name") %>%
    select(name, levels, list_name)
  
  # Convert relevant columns to ordered factors
  for (i in 1:nrow(df_levels_with_names)) {
    var_name <- df_levels_with_names$name[i]
    levels <- strsplit(df_levels_with_names$levels[i], ";")[[1]]
    
    if (var_name %in% names(data)) {
      data[[var_name]] <- factor(data[[var_name]], levels = levels, ordered = TRUE)
    } 
  }
  
  return(data)
}
