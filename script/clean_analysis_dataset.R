# This is part of the Impact_analysis.Rmd 
# The code generates clean data in a format ready for statistical analysis/ machine learning
# and free from NAs

# # Load necessary libraries
# library(tidyverse)
# library(randomForest)

# Identify unsuitable data types for regression/random forest
excluded_types <- c("calculate", "date", "geopoint", "note", "repeat", "text", "select all that apply")

# Filter variables based on type and presence in data
irrelevant_variables <- needs4_form %>%
  filter(type %in% excluded_types & name %in% names(lcsi_data)) %>%
  pull(name)

# Select only relevant variables
analysis_vars <- lcsi_data %>%
  # Remove metadata and mixed data with string/text information
  dplyr::select(-starts_with("X_"), -starts_with("meta")) %>% 
  dplyr::select(-all_of(irrelevant_variables)) %>% 
  names()

# Get select_multiple variables to include re-encoded select_multiple 
select_multiple_vars <- needs4_form %>%
  dplyr::filter(stringr::str_detect(type, "select all that apply")) %>%
  dplyr::pull(name)

# Ensure we only use columns present in both the form and data
select_multiple_vars <- intersect(select_multiple_vars, names(lcsi_data)) 

# Extracting the children of select multiple variables
children_vars <- names(lcsi_data)[!names(lcsi_data) %in% tolower(select_multiple_vars)]

# Drop variables starting with 'X_' (metadata)
children_vars <- children_vars[!grepl("^x_", children_vars)]

# Combine all desired variables into one vector
desired_vars<- c(analysis_vars, children_vars)

df_analysis <- lcsi_data %>%
  dplyr::select(dplyr::all_of(desired_vars)) %>%
  dplyr::select(!dplyr::contains("closure.")) %>%
  dplyr::select(!dplyr::starts_with("meta.")) %>%
  dplyr::select(!c("start", "end", "internal.collection_date", "needs.keyproblems")) %>% 
  dplyr::select(!dplyr::contains("internal.interviewer")) %>% 
  dplyr::mutate(id = 1:nrow(lcsi_data)) %>%
  dplyr::select(
    !contains(c("status", "year_1")),     # Exclude variables containing "status" or "year_1"
    !contains(c("uuid", "lcsi.")),        # Exclude variables containing "uuid" or "lcsi." 
    !starts_with("internal.data_collection_type"),
    !contains("disability.measures"),
    !contains("evaluation.feedback_how"),
    !contains("livelihoods.market_access_unsafe"),
    -any_of(irrelevant_variables)          # Exclude irrelevant variables
  )

# Adjust names to remove signs which cause trouble in the random forest
names(df_analysis) <- names(df_analysis) %>% 
  gsub("_50\\+", "_over_50", .) %>% 
  gsub("\\-", "_", .) %>% 
  gsub("\\/", "_", .) %>% 
  gsub("\\(", "", .) %>% 
  gsub("\\)", "", .) %>% 
  gsub("\\'", "", .)  %>% 
  # Remove spaces from names
  gsub(" ", "_", .) %>%
  # Remove commas from names
  gsub(",", "_", .) %>%
  tolower()

# Replace NAs in observations with missing altitude
data_with_missing_altitude <- df_analysis[is.na(df_analysis$altitude), ] %>% tibble()

# Model
lm_formula_altitude <- as.formula(
  paste("altitude ~ lat + lon + precision"))

lm_model_altitude <- lm(
  lm_formula_altitude,
  data = df_analysis
)

data_with_missing_altitude$altitude_imputed <- predict(lm_model_altitude, newdata = data_with_missing_altitude)

df_analysis_imputed <- df_analysis %>%
  left_join(data_with_missing_altitude %>% dplyr::select(id, altitude_imputed), by = "id") %>% # Assuming you have an ID column
  mutate(altitude = ifelse(is.na(altitude), altitude_imputed, altitude)) %>%
  dplyr::select(-altitude_imputed)


impute_with_lm <- function(data, var_to_impute, predictor_vars) {
  # Check if variable to impute exists in the data
  if (!(var_to_impute %in% names(data))) {
    stop(paste("Variable '", var_to_impute, "' not found in the data."))
  }
  
  # Create formula for the linear model
  lm_formula <- as.formula(paste(var_to_impute, "~", paste(predictor_vars, collapse = "+")))
  
  # Fit the linear model using complete cases (rows with no missing values in the formula variables)
  complete_cases <- complete.cases(data[, c(var_to_impute, predictor_vars)])
  if (sum(complete_cases) == 0) {
    stop(paste("No complete cases found for imputing variable '", var_to_impute, "'."))
  }
  lm_model <- lm(lm_formula, data = data[complete_cases, ])
  
  # Get rows with missing values for the target variable
  data_with_missing <- data[!complete_cases, ]
  
  # Impute missing values using the model's predictions
  if (nrow(data_with_missing) > 0) { # Check if there are any missing values to impute
    data_with_missing[[paste0(var_to_impute, "_imputed")]] <- predict(lm_model, newdata = data_with_missing) # Impute into new column
  }
  
  # Combine imputed data back into the original dataframe (only if there were missing values to impute)
  if (nrow(data_with_missing) > 0) { 
    data_imputed <- data %>%
      left_join(data_with_missing %>% dplyr::select(id, !!sym(paste0(var_to_impute, "_imputed"))), by = "id") %>% 
      mutate(!!var_to_impute := ifelse(is.na(!!sym(var_to_impute)), !!sym(paste0(var_to_impute, "_imputed")), !!sym(var_to_impute))) %>%
      dplyr::select(-matches("_imputed$")) 
  } else {
    data_imputed <- data  # No changes if no missing values
  }
  
  return(data_imputed)
}

# Impute missing values for lat, lon, and precision
df_analysis_imputed <- df_analysis

# Choose the predictors you want to use (customize as needed)
predictor_vars <- c("altitude", "area.village") 

df_analysis_imputed <- impute_with_lm(df_analysis_imputed, "lat", predictor_vars)
df_analysis_imputed <- impute_with_lm(df_analysis_imputed, "lon", predictor_vars)
df_analysis_imputed <- impute_with_lm(df_analysis_imputed, "precision", predictor_vars) %>% 
  # Remove ID column used for merging imputed data
  dplyr::select(-id)

# Set the threshold for NA percentage
na_threshold <- 0.05  # Remove columns with 10% or more missing values

# Calculate NA percentages for each column
na_percentages <- colMeans(is.na(df_analysis_imputed))

# Identify columns to remove
columns_to_remove <- names(na_percentages)[na_percentages >= na_threshold]

# Remove the identified columns
df_analysis <- df_analysis_imputed %>% unique() %>% 
  dplyr::select(-all_of(columns_to_remove)) %>% 
  drop_na() 

# # (Optional) Print the names of removed columns for inspection
#   cat("Removed columns:", columns_to_remove, "\n")

# Convert select_one variables to ordered factors
# Load custom function
suppressWarnings(
  source(
    'script/convert_to_ordered_factors.R', 
    encoding = 'UTF-8'
  )
)

# Correct the capitalization in the original dataframe (e.g., df_analysis)
needs4_formchoices$choices <- gsub("Very_High", "Very_high", needs4_formchoices$choices)
needs4_formchoices$choices <- gsub("Very_Low", "Very_low", needs4_formchoices$choices)


df_analysis  <- convert_to_ordered_factors(
  data = df_analysis, 
  form = needs4_form, 
  formchoices = needs4_formchoices,
  ignore = 
    c(
      "area.village",
      # Ignore recoded LCSI variables
      df_analysis %>% 
        dplyr::select(starts_with("lcsi.")) %>% 
        names()
    )
) %>% 
  # Removing geographic coordinate variables (as the project has limited action here)
  # Latitude and longitude are strong predictors of some variables. This can help to predict vulnerability using them and a few other strong predictors (analysis and on the ground)
  dplyr::select(
    # -lat, 
    # -lon, 
    # -precision, 
    -today
    )

# Convert data for machine learning
# Check and convert columns to appropriate types (rf: Random Forest)
df_analysis_rf <- df_analysis %>%
  mutate(across(where(is.factor), as.numeric)) %>%  # Convert factors to numeric
  mutate(across(where(is.list), ~ sapply(., as.character))) %>%  # Convert lists to character
  mutate(across(where(is.character), as.factor)) %>%
  mutate(across(where(is.factor), as.numeric))  # Convert character to numeric

# Ensure there are no columns with complex data types (data frames or lists)
df_analysis_rf <- df_analysis_rf %>%
  select_if(~ !is.data.frame(.) & !is.list(.)) %>% 
  na.omit()
