#-------------------------#
#--------LIBRARIES--------#
#-------------------------#
library(tidyverse) 
library(dplyr)
library(plyr) 


#-------------------------#
#-----GLOBAL VARIABLES----#
#-------------------------#
# script_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
# project_dir <- dirname(script_dir)
# setwd(project_dir)
# 
# source(file.path(script_dir, 'us-common-functions.R'))


# signal_name_list <- c('PP')
signal_name_list <- c('PP', 'E4_HR', 'E4_EDA', 'iWatch_HR')



full_df <- tibble()
mean_df <- tibble()
normalized_df <- tibble()
log_transformed_df <- tibble()

mean_v1_df <- tibble()
mean_v2_df <- tibble()



#-------------------------#
#---FUNCTION DEFINITION---#
#-------------------------#
read_data <- function() {
  full_df <<- custom_read_csv(file.path(project_dir, curated_data_dir, physiological_data_dir, qc1_file_name))
  # mean_v1_df <<- custom_read_csv(file.path(project_dir, curated_data_dir, physiological_data_dir, qc1_raw_mean_v1_file_name))
  # mean_v2_df <<- custom_read_csv(file.path(project_dir, curated_data_dir, physiological_data_dir, qc1_raw_mean_v2_file_name))
}

# process_rb_data <- function(df, signal) {
#   if (baseline_parameter==lowest_baseline) {
#     mean_df <<- mean_v2_df %>% 
#       select(Participant_ID, Treatment, Signal, Four_Day_Min) %>% 
#       filter(Treatment=='RB')
#     
#   } else if (baseline_parameter==corresponding_baseline) {
#     mean_df <<- mean_v2_df %>% 
#       select(Participant_ID, Treatment, Signal, Day1, Day2, Day3, Day4) %>% 
#       filter(Treatment=='RB')
#     
#   } else if (baseline_parameter==day3_day4_ws_mean) {
#     mean_df <<- mean_v2_df %>% 
#       select(Participant_ID, Treatment, Signal, Day3_Day4_Mean) %>% 
#       filter(Treatment=='WS')
#     
#   }  else if (baseline_parameter==day3_day4_ws_min) {
#     mean_df <<- mean_v2_df %>% 
#       select(Participant_ID, Treatment, Signal, Day3_Day4_Min) %>% 
#       filter(Treatment=='WS')
#   }
# }

# get_rb <- function(df, signal) {
#   # dat <- tibble(subj)
#   # names(dat) <- c('Participant_ID')
#   
#   # print(unique(df$Participant_ID))
#   # print(unique(subj))
#   
#   subj<-unique(df$Participant_ID)
#   
#   if (baseline_parameter==lowest_baseline) {
#     rb_val <- mean_df %>% 
#       filter(Participant_ID==subj & Signal==signal) %>% 
#       select(Four_Day_Min) %>% 
#       pull()
#   } else if (baseline_parameter==corresponding_baseline) {
#     day<-unique(df$Day)
#     rb_val <- mean_df %>% 
#       filter(Participant_ID==subj & Signal==signal) %>% 
#       select(!!day) %>% 
#       pull()
#   } else if (baseline_parameter==day3_day4_ws_mean) {
#     rb_val <- mean_df %>% 
#       filter(Participant_ID==subj & Signal==signal) %>% 
#       select(Day3_Day4_Mean) %>% 
#       pull()
#   } else if (baseline_parameter==day3_day4_ws_min) {
#     rb_val <- mean_df %>% 
#       filter(Participant_ID==subj & Signal==signal) %>% 
#       select(Day3_Day4_Min) %>% 
#       pull()
#   }
#   
#   # print(paste(signal, subj, rb_val))
#   rb_val
# }

# normalize_data <- function() {
#   ws_df <- full_df %>% 
#     filter(Treatment=='WS')
#   
#   if (baseline_parameter==corresponding_baseline) {
#     ws_df <- ws_df %>% 
#       group_by(Participant_ID, Day)
#   } else {
#     ws_df <- ws_df %>% 
#       group_by(Participant_ID) 
#   }
#       
#   normalized_df <<- ws_df %>%
#     do(mutate(., 
#               PP=PP-get_rb(., 'PP'),
#               E4_EDA=E4_EDA-get_rb(., 'E4_EDA'),
#               E4_HR=E4_HR-get_rb(., 'E4_HR'),
#               iWatch_HR=iWatch_HR-get_rb(., 'iWatch_HR'),
#               ))
#   
#   convert_to_csv(normalized_df, file.path(curated_data_dir, physiological_data_dir, qc1_normalized_file_name))
# }

transfer_data <- function() {
  
  if (transformation_parameter==log_transformation) {
    normalized_df <<- full_df %>% 
      mutate(PP=log(PP), 
             E4_EDA=log(E4_EDA),
             E4_HR=log(E4_HR),
             iWatch_HR=log(iWatch_HR),
      )
      # ------------------ Don't Delete ------------------ #
      # mutate(PP=log(PP+get_shift_val(normalized_df, 'PP')), 
      #        E4_EDA=log(E4_EDA+get_shift_val(normalized_df, 'E4_EDA')),
      #        E4_HR=log(E4_HR+get_shift_val(normalized_df, 'E4_HR')),
      #        iWatch_HR=log(iWatch_HR+get_shift_val(normalized_df, 'iWatch_HR')),
      # )
    
  } else if (transformation_parameter==boxcox_transformation) {
    normalized_df <<- full_df %>% 
      mutate(PP=boxcox(PP), 
             E4_EDA=boxcox(E4_EDA),
             E4_HR=boxcox(E4_HR),
             iWatch_HR=boxcox(iWatch_HR),
      )
  }
  
  convert_to_csv(normalized_df, file.path(project_dir, curated_data_dir, physiological_data_dir, qc1_transformed_file_name))
}


transform_data <-  function() {
  read_data()
  transfer_data()
  generate_mean_data(input_file_name=qc1_transformed_file_name, 
                     output_v1_file_name=qc1_transformed_mean_v1_file_name, 
                     output_v2_file_name=qc1_transformed_mean_v2_file_name)
  ##### process_rb_data()
  ##### normalize_data()
}




#-------------------------#
#-------Main Program------#
#-------------------------#
# transform_data()






