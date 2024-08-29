# Loads necessary packages
## ipak function: install and load multiple R packages.
## check to see if packages are installed. Install them if they are not, then load them into the R session. (source: https://gist.github.com/stevenworthington/3178163)

ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE, repos = "https://cran.uni-muenster.de/")
  sapply(pkg, require, character.only = TRUE)
}

# Loads packages
packages <- c(
  "exactRankTests", # For statistical tests
  "tidyverse",
  "MatchIt", # For Partial Sample Matching
  "callr", # To run background jobs (e.g. merging data, obtaining data from APIs)
  "magrittr",
  "shiny", # For dataframe manipulation (e.g. evalmatrix in evaluation reports)
  "stringdist", # For automatic correction of village names The Jaro-Winkler distance is a well-established string metric that takes into account character transpositions (swapping of letters) in addition to insertions, deletions, and substitutions. It's suitable for handling typos and minor variations in spellings.
  "RColorBrewer",
  "httr",
  "dplyr",
  "jsonlite",
  "ggplot2",
  "knitr",
  "lubridate",
  "readxl",
  "writexl",
  "DT",
  "mongolite",
  "stringr",
  "janitor",
  "Hmisc",
  "scales",
  "reshape2",
  "wordcloud",
  "stopwords",
  "quanteda",
  "pander",
  "textclean",
  "stringr", # Processing string variables
  "progress", # For progress bars
  "randomForest",
  "formattable",# Used for HTML tables
  "splitstackshape", # Used for plotting
  "cowplot", # Used for plotting
  "labelled", # Used in the LSCI code from WFP
  "expss", # Used in the LSCI code from WFP
  "clipr", # Use in write_clip to copy and paste AI outputs from the R console into the clipboard
  "ddpcr", # To suppress messages from gridExtra (disaggregated plots)
  "ggtext",
  "glue", # Improved version of paste or paste0 for improved code readability
  "bayesboot", # For graphs with bayesian bootstraps (numeric variables)
  "tidyr",
  "fixest" # For Differences in Differences analysis
  )

# 
# # # Loads packages silently
# suppressPackageStartupMessages(
#   invisible(
#     lapply(packages, library, character.only = TRUE)
#   )
# )

# Loads packages
invisible(ipak(packages))

# Removes intermediary objects from the environment
rm(ipak)