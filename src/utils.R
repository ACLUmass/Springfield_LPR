library(stringr)
library(perlrer)
library(data.table)
library(dplyr)
library(rlist)
library(sf)

# constants
STATES <- read_sf("../data/cb_2018_us_state_20m/cb_2018_us_state_20m.shp") %>% 
  select(NAME,
         STUSPS) 

STATES$NAME <- toupper(STATES$NAME)

STATE_NAMES <- toupper(STATES$NAME)
STATE_NAMES <- paste(STATE_NAMES, collapse = "|")

STATE_ABBRS <- STATES$STUSPS
STATE_ABBRS <- paste(STATE_ABBRS, collapse = "\\b|\\b")

# HSI is a little over the place (they do more than just immigration, should maybe remove?)
IMMIGRATION_KEYWORD <- "immigration|border( patrol)+|homeland security( investigation)+|\\bhsi\\b|\\bi.c.e.\\b|\\busbp\bb|\\bcbp\\b"

# work on a column of strings, not just a singular string
# we can also add matches like " TX ", i.e., state abbreviations that are by themselves
# or wrapped in parentheses or something
extract_state <- function(org) {
  # for now, if the string contains something like "XX state PD", we want to extract the state
  
  # Step 1: try the abbreviation match first
  state_pd <- str_extract(org, STATE_ABBRS)
  
  if (!is.na(state_pd)) {
    return(state_pd)
  }
  
  # Step 2: try the full state name match
  state_pd <- str_extract(org, STATE_NAMES)
  
  if (is.na(state_pd)) {
    return(state_pd)
  }
  
  state_pd <- (STATES %>% filter(NAME == state_pd))$STUSPS
  return(state_pd)
}

extract_immigration <- function(input_text) {
  return(grepl(IMMIGRATION_KEYWORD, input_text, ignore.case = TRUE))
}

# Here, cols is a list of characters
generate_col_name <- function(cols) {
  return(paste(cols, collapse="_"))
}

# This function is meant to remove duplicates through a majority voting system. It is often
# the case
# TODO
# 
# col_checks: a vector of vectors detailing the columns in df that we want to check
#             together for any duplicates.
majority_vote_dups <- function(df, col_checks, vote_threshold = 0.5) {
  # loop through the desired column conditions and slowly update thru extra columns
  dup_col_names <- c()
  for (cond in col_checks) {
    df <- find_dupes(df, cond)
    dup_col_names <- list.append(dup_col_names, generate_col_name(cond))# merge(dup_col_names, generate_col_name(cond))
  }
  
  print(head(df))
   
  # df$dup_col_names <- tobool(df$dup_col_names)
  print(dup_col_names)
  # at this point, there should be length(col_checks) additional columns in df, each of
  # them logical indicators of whether that row is a duplicate based on their condition.
  # now, we will create a final column based on majority voting.
  print("Creating our final duplicate likely column")
  df <- df %>% 
    rowwise() %>% 
    mutate(duplicate_likely = sum(c_across(all_of(dup_col_names))) / length(dup_col_names)) %>% 
    ungroup()
    #mutate(duplicate_likely = if_else((sum(dup_col_names) / length(dup_col_names)) > vote_threshold, TRUE, FALSE))

  df$duplicate_likely <- (df$duplicate_likely > 0.5)
  return(df)
}

## TODO
dedup <- function(df, dedup_cols) {
  # based on merging preferences, decided how to deduplicate
  # simple case: filter out the likely duplicates
  # complicated case: impute the missing values from the first unique row by adding
  # the information from all the other rows
  return(df)
}

# Given a dataframe and a list of columns in that dataframe to check for duplicates,
# find_dupes() returns the input df with an additional logical column signifying
# whether that row is a duplicate. Note that fortunately, duplicated(), which is 
# called here, assigns true to the first row from top to bottom that is a duplicate.
find_dupes <- function(df, cols) {
  col_name <- generate_col_name(cols)
  duplicated_df <- data.frame(duplicated(df[, cols]))
  names(duplicated_df) <- c(col_name)
  return(tibble::add_column(df, duplicated_df))
}