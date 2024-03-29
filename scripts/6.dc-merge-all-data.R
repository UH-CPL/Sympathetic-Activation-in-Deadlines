#-------------------------#
#--------LIBRARIES--------#
#-------------------------#
library(dplyr)




#-------------------------#
#-----GLOBAL VARIABLES----#
#-------------------------#





#-------------------------#
#---FUNCTION DEFINITION---#
#-------------------------#
merge_all_data <- function() {
  physiological_data_path <- file.path(project_dir, curated_data_dir, physiological_data_dir)
  
  
  # "Participant_ID"         "Day"                    "Treatment"              "Timestamp"             
  # "Sinterface_Time"        "TreatmentTime"          "Raw_PP"                 "PP"                    
  # "Raw_E4_EDA"             "E4_EDA"                 "Raw_E4_HR"              "E4_HR"                 
  # "Raw_iWatch_HR"          "iWatch_HR"              "Activities"             "Activities_QC1"        
  # "Activities_QC2"         "Activity_One"           "Activity_Two"           "Activity_Three"        
  # "Reduced_Activities_QC1" "Reduced_Activity_One"   "Reduced_Activity_Two"   "Reduced_Activity_Three"
  # "Application"            "Application_QC1"        "Application_QC2"        "Application_QC3"       
  # "Mask" 
  # qc0_df <- custom_read_csv(file.path(physiological_data_path, qc0_final_file_name))
  # print(colnames(qc0_df))
  
  qc0_df <- custom_read_csv(file.path(physiological_data_path, qc0_final_file_name)) %>%
    dplyr::select(Participant_ID, Day, Treatment, 
                 Timestamp, Sinterface_Time, TreatmentTime, 
                 # BaseTreatmentTime,
                 # Raw_Noisy_PP, 
                 Raw_PP, Raw_E4_EDA, Raw_E4_HR, Raw_iWatch_HR, 
                 Activities, Activities_QC1, Activities_QC2, Activity_One, Activity_Two, Activity_Three,
                 Reduced_Activities_QC1, Reduced_Activity_One, Reduced_Activity_Two, Reduced_Activity_Three,
                 Segments_Activity,
                 Application, Application_QC1, Application_QC2, Application_QC3, 
                 Reduced_Application, Reduced_Application_final,
                 Mask)
  
  ############################################################################################
  #                             This might be QC1 or QC2
  ############################################################################################
  qc_df <- custom_read_csv(file.path(physiological_data_path, qc1_file_name)) %>% 
    dplyr::select(Timestamp, PP, E4_HR, E4_EDA, iWatch_HR) 
  
  
  # select(Participant_ID, Day, Treatment, Timestamp, TreatmentTime, PP, E4_HR, E4_EDA, iWatch_HR, Mask) 
  # %>% 
  #   dplyr::rename(
  #     Raw_E4_HR=E4_HR,
  #     Raw_iWatch_HR=iWatch_HR
  #   )
  
  transformed_df <- custom_read_csv(file.path(physiological_data_path, qc1_transformed_file_name)) %>% 
    dplyr::select(Timestamp, PP, E4_HR, E4_EDA, iWatch_HR) %>% 
    dplyr::rename(
      Trans_PP=PP,
      Trans_E4_HR=E4_HR,
      Trans_E4_EDA=E4_EDA,
      Trans_iWatch_HR=iWatch_HR
    )
  ############################################################################################
  
  
  
  # print_msg(head(qc0_df, 2))
  # print_msg(head(qc_df, 2))
  # print_msg(head(transformed_df, 2))
  
  
  print_msg('Merging data...')
  full_df <- transformed_df %>%
    #   # merge(qc0_df, by=c('Participant_ID', 'Day', 'Treatment', 'TreatmentTime'), all=T) %>%
    #   # merge(qc_df, by=c('Participant_ID', 'Day', 'Treatment', 'TreatmentTime'), all=T) %>%

    # merge(qc0_df, by='Timestamp', all=T) %>%
    # merge(qc_df, by='Timestamp', all=T) %>%

    dplyr::full_join(qc0_df, by='Timestamp') %>%
    dplyr::full_join(qc_df, by='Timestamp') %>%
    
    
    group_by(Participant_ID, Day, Treatment, Sinterface_Time) %>%
    slice(1) %>% 
    ungroup() %>% 


    arrange(Participant_ID, Day, Treatment, TreatmentTime) %>%
    dplyr::select(
      Participant_ID,
      Day,
      Treatment,
      Timestamp,
      Sinterface_Time,
      # BaseTreatmentTime,
      TreatmentTime,
      
      # Raw_Noisy_PP,
      Raw_PP,
      PP,
      Trans_PP,

      Raw_E4_EDA,
      E4_EDA,
      Trans_E4_EDA,

      Raw_E4_HR,
      E4_HR,
      Trans_E4_HR,

      Raw_iWatch_HR,
      iWatch_HR,
      Trans_iWatch_HR,

      # Activities, 
      # Activities_QC1, 
      # Activities_QC2, 
      
      Activity_One, 
      Activity_Two, 
      Activity_Three,
      
      Reduced_Activities_QC1,
      
      Reduced_Activity_One, 
      Reduced_Activity_Two, 
      Reduced_Activity_Three,
      
      Segments_Activity,
      
      # Application, 
      # Application_QC1, 
      # Application_QC2, 
      # Application_QC3, 
      
      Reduced_Application,
      Reduced_Application_final,
      
      Mask
    )

  print_msg('Done merging data...exporting')
  convert_to_csv(full_df, file.path(physiological_data_path, full_df_file_name))
  
  
  
  full_df_osf <- full_df %>%
    dplyr::select(
      Participant_ID,
      Day,
      Treatment,
      Timestamp,
      TreatmentTime,
      
      Raw_PP,
      Trans_PP,
      Trans_E4_EDA,
      Trans_E4_HR,
      Trans_iWatch_HR,
      
      Reduced_Activity_One, 
      Reduced_Activity_Two, 
      Reduced_Activity_Three,
      Reduced_Activities_QC1,
    
      Reduced_Application_final
      
    ) %>% 
    dplyr::rename(
      Noise_Removed_PP=Raw_PP,
      PP=Trans_PP,
      E4_EDA=Trans_E4_EDA,
      E4_HR=Trans_E4_HR,
      iWatch_HR=Trans_iWatch_HR,
      
      Activity1=Reduced_Activity_One, 
      Activity2=Reduced_Activity_Two, 
      Activity3=Reduced_Activity_Three,
      Activities=Reduced_Activities_QC1,
      
      Applications=Reduced_Application_final
    )
    
  
  convert_to_csv(full_df_osf, file.path(physiological_data_path, full_df_osf_file_name))
  
  half_subj_list <- c('T001', 'T003', 'T005', 'T007', 'T009')
  
  full_df_1 <- full_df_osf %>% 
    filter(Participant_ID %in% half_subj_list)
  convert_to_csv(full_df_1, file.path(physiological_data_path, 'full_df_1.csv'))
  
  full_df_2 <- full_df_osf %>% 
    filter(!(Participant_ID %in% half_subj_list))
  convert_to_csv(full_df_2, file.path(physiological_data_path, 'full_df_2.csv'))
  
  mini_full_df <- full_df_osf %>%
    filter(Participant_ID %in% c('T005'))
  
  convert_to_csv(mini_full_df, file.path(physiological_data_path, 'mini_full_df.csv'))
}




#-------------------------#
#-------Main Program------#
#-------------------------#
# merge_all_data()