#-------------------------#
#--------LIBRARIES--------#
#-------------------------#
library(dplyr)
library(tidyr)
library(zoo)




#-------------------------#
#-----GLOBAL VARIABLES----#
#-------------------------#
# script_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
# project_dir <- dirname(script_dir)
# setwd(project_dir)
# 
# source(file.path(script_dir, 'us-common-functions.R'))

physiological_data_path <<- file.path(project_dir, curated_data_dir, physiological_data_dir)
mean_df <<- custom_read_csv(file.path(physiological_data_path, qc1_transformed_mean_v2_file_name)) %>% 
  dplyr::filter(Signal=='PP',
                Treatment=='RB') %>% 
  dplyr::select(Participant_ID, Four_Day_Min) %>% 
  dplyr::rename(Lowest_RB_PP=Four_Day_Min)



#-------------------------#
#---FUNCTION DEFINITION---#
#-------------------------#
investigate_data <- function() {
  physiological_data_path <- file.path(project_dir, curated_data_dir, physiological_data_dir)
  
  #################################################################################################################
  # data_file_name <- qc0_raw_file_name
  # data_file_name <- qc0_final_file_name
  # data_file_name <- qc1_file_name
  data_file_name <- full_df_file_name
  
  investigation_df <- custom_read_csv(file.path(physiological_data_path, data_file_name)) %>%
    dplyr::group_by(Participant_ID, Day, Treatment, Sinterface_Time) %>%
    dplyr::summarize(Duplicate_Row=n()) %>% 
    filter(Duplicate_Row>1)
  
  View(investigation_df)
  convert_to_csv(investigation_df, file.path(physiological_data_path, paste0("investigation_", data_file_name)))
  #################################################################################################################
}


generate_segment_df <- function() {
  data_file_name <- full_df_file_name

  segment_df <- custom_read_csv(file.path(physiological_data_path, data_file_name)) %>%
    dplyr::select(Participant_ID, Day, Treatment,
                  Timestamp, Sinterface_Time, TreatmentTime,
                  Trans_PP,
                  Segments_Activity,
                  Reduced_Application_final,
                  Mask) %>%
    dplyr::mutate(Applications=Reduced_Application_final) %>%

    # filter(!is.na(Segments_Activity)) %>%  ## What is Segments_Activity and why removing NA??
    replace_na(list(Segments_Activity = "Missing Activity")) %>%

    dplyr::mutate(Segments_Activity=case_when(Treatment=="RB"~"Out",
                                            TRUE~.$Segments_Activity)) %>%
    dplyr::group_by(Participant_ID, Day) %>%
    dplyr::mutate(Counter=sequence(rle(as.character(Segments_Activity))$lengths),
           Segment=case_when(Segments_Activity=="Out" & Counter==1~1, TRUE~0),
           Segment=ifelse(Segment==1, cumsum(Segment==1), NA),
           Segment=na.locf0(Segment)) %>%
    dplyr::select(-Counter)

  convert_to_csv(segment_df, file.path(physiological_data_path, segment_df_file_name))
}


generate_segment_meta_data <- function() {
  ################################################################################################################################
  #       (end time - start time) vs. total row  --> Because after RB there was a time gap + Activity might not be continuous
  ################################################################################################################################
  segment_df <- custom_read_csv(file.path(physiological_data_path, segment_df_file_name))

  segment_meta_data_df_1 <<- segment_df %>%
    dplyr::group_by(Participant_ID, Day) %>%
    dplyr::summarize(
          Mean_PP_RestingBaseline=mean(Trans_PP[Segments_Activity=="Out" & Segment==1], na.rm = TRUE),
          Length_RestingBaseline=length(Trans_PP[Segments_Activity=="Out" & Segment==1]),
          Length_Day=n(),
          Length_Day_Timestamp=as.numeric(difftime(tail(Timestamp, 1), head(Timestamp, 1), units = "secs")+1),
          DiffLengthDaySec=Length_Day_Timestamp-Length_Day,
          DiffLengthDayPercentage=100*(DiffLengthDaySec)/Length_Day_Timestamp,
          ) %>%
    ungroup() 
  
  segment_meta_data_df_2 <- segment_df %>%
    dplyr::filter(Treatment=='WS') %>%
    dplyr::group_by(Participant_ID, Day) %>%
    dplyr::summarize(
      # Length_Day=n(),
      # Length_Day_Timestamp=as.numeric(difftime(tail(Timestamp, 1), head(Timestamp, 1), units = "secs")+1),
      # DiffLengthDaySec=Length_Day_Timestamp-Length_Day,
      # DiffLengthDayPercentage=100*(DiffLengthDaySec)/Length_Day_Timestamp,
      
      Length_WS=n(),
      Length_WS_Timestamp=as.numeric(difftime(tail(Timestamp, 1), head(Timestamp, 1), units = "secs")+1),
      DiffLengthWSSec=Length_WS_Timestamp-Length_WS,
      DiffLengthWSPercentage=100*(DiffLengthWSSec)/Length_WS_Timestamp,
      ) %>%
    ungroup()
    
  segment_meta_data_df <- segment_df %>%
    dplyr::group_by(Participant_ID, Day, Segment) %>%
    dplyr::summarize(
      
          StartSegmentTime=head(Timestamp, 1),
          EndSegmentTime=tail(Timestamp, 1),
          DiffSegmentTimeStamp=as.numeric(difftime(EndSegmentTime, StartSegmentTime, units = "secs")+1),
          
          Length_Segment=n(),
          DiffSegmentTimeSec=DiffSegmentTimeStamp-Length_Segment,
          DiffSegmentTimePercentage=100*(DiffSegmentTimeSec)/DiffSegmentTimeStamp,
          
          Length_Break=sum(Segments_Activity=="Out", na.rm = TRUE),
          Length_RW=sum(Segments_Activity=="RW", na.rm = TRUE),
          Length_SP=sum(Segments_Activity=="SP", na.rm = TRUE),
          Length_SA=sum(Segments_Activity=="SA", na.rm = TRUE),
          Length_MT=sum(Segments_Activity=="MT", na.rm = TRUE),
          Length_Missing_Activity=sum(Segments_Activity=="Missing Activity", na.rm = TRUE),
          Length_Other_Activities=sum(Segments_Activity=="Other", na.rm = TRUE),
          
          # WP_Sec=length(Applications[Applications=="Document Apps" & !is.na(Applications)]),
          # EM_Sec=length(Applications[Applications=="Email" & !is.na(Applications)]),
          # EA_Sec=length(Applications[Applications=="Entertaining Apps" & !is.na(Applications)]),
          # PA_Sec=length(Applications[Applications=="Programming Apps" & !is.na(Applications)]),
          # VC_Sec=length(Applications[Applications=="Virtual Communication Apps" & !is.na(Applications)]),
          # UT_Sec=length(Applications[Applications=="Utilities Apps" & !is.na(Applications)]),
          # WB_Sec=length(Applications[Applications=="Web Browsing Apps" & !is.na(Applications)]),
          # NO_APP_Sec=length(Applications[is.na(Applications)]),
          
          WP_Sec=sum(Applications=="Document Apps", na.rm = TRUE),
          EM_Sec=sum(Applications=="Email", na.rm = TRUE),
          EA_Sec=sum(Applications=="Entertaining Apps", na.rm = TRUE),
          PA_Sec=sum(Applications=="Programming Apps", na.rm = TRUE),
          VC_Sec=sum(Applications=="Virtual Communication Apps", na.rm = TRUE),
          UT_Sec=sum(Applications=="Utilities Apps", na.rm = TRUE),
          WB_Sec=sum(Applications=="Web Browsing Apps", na.rm = TRUE),
          NO_APP_Sec=sum(is.na(Applications)),
          
          Mean_PP=mean(Trans_PP[Segments_Activity!="Out"], na.rm = TRUE),
          # Mean_PP_RW=mean(Trans_PP[Segments_Activity=="RW"], na.rm = TRUE),
          # Mean_PP_Other_Activities=mean(Trans_PP[Segments_Activity=="Other"], na.rm = TRUE),
          
          ) %>% 
    dplyr::ungroup() %>% 
    
    dplyr::mutate(Segment_Order_Percentage=lag(Length_Segment),
                  Segment_Order_Percentage=case_when(Segment==1~0,
                                                     TRUE~as.double(Segment_Order_Percentage))) %>% 
  
    dplyr::group_by(Participant_ID, Day) %>%
    dplyr::mutate(Segment_Order_Percentage=cumsum(Segment_Order_Percentage),
                  
                  Cum_T_WP=cumsum(WP_Sec),
                  Cum_T_EM=cumsum(EM_Sec),
                  Cum_T_EA=cumsum(EA_Sec),
                  Cum_T_PA=cumsum(PA_Sec),
                  Cum_T_VC=cumsum(VC_Sec),
                  Cum_T_UT=cumsum(UT_Sec),
                  Cum_T_WB=cumsum(WB_Sec),
                  Cum_T_NO_APP=cumsum(NO_APP_Sec),
                  
                  Cum_T_Segment=cumsum(Length_Segment),
                  Cum_T_Break=cumsum(Length_Break),
                  Cum_T_RW=cumsum(Length_RW),
                  Cum_T_SP=cumsum(Length_SP),
                  Cum_T_SA=cumsum(Length_SA),
                  Cum_T_MT=cumsum(Length_MT),
                  Cum_T_Missing_Activity=cumsum(Length_Missing_Activity),
                  Cum_T_Other_Activities=cumsum(Length_Other_Activities),
                  ) %>% 
      
    merge(segment_meta_data_df_1, by=c("Participant_ID", "Day")) %>%
    merge(segment_meta_data_df_2, by=c("Participant_ID", "Day")) %>%
    merge(mean_df, by=c("Participant_ID")) %>% 
    
    dplyr::mutate(
                  ################################################################################
                  Segment_Order_Percentage=round(100*Segment_Order_Percentage/Length_Day, 0),
                  Segment_Order_Percentage=ifelse(Segment_Order_Percentage==0, 0.05, Segment_Order_Percentage),
                  ################################################################################

                  
                  ################################################################################
                  CT_SL=round(100*Cum_T_Segment/Length_Day, 2), ## For some cases, the CT_SL exceeds 100, because Cum_T_Segment includes RB, but Length_Day does not
                  
                  CT_RW=round(100*Cum_T_RW/Length_Day, 2),
                  CT_Out=round(100*Cum_T_Break/Length_Day, 2),
                  CT_SP=round(100*Cum_T_SP/Length_Day, 2),
                  CT_SA=round(100*Cum_T_SA/Length_Day, 2),
                  CT_MT=round(100*Cum_T_MT/Length_Day, 2),
                  CT_Missing_Activity=round(100*Cum_T_Missing_Activity/Length_Day, 2),
                  CT_Other_Activities=round(100*Cum_T_Other_Activities/Length_Day, 2),
                  
                  CT_Activity_Sum=CT_RW+CT_Out+CT_SP+CT_SA+CT_MT+CT_Missing_Activity+CT_Other_Activities,
                  ################################################################################
                  
                  
                  ################################################################################
                  CT_WP=round(100*Cum_T_WP/Length_Day, 2),
                  CT_EM=round(100*Cum_T_EM/Length_Day, 2),
                  CT_EA=round(100*Cum_T_EA/Length_Day, 2),
                  CT_PA=round(100*Cum_T_PA/Length_Day, 2),
                  CT_VC=round(100*Cum_T_VC/Length_Day, 2),
                  CT_UT=round(100*Cum_T_UT/Length_Day, 2),
                  CT_WB=round(100*Cum_T_WB/Length_Day, 2),
                  CT_NO_APP=round(100*Cum_T_NO_APP/Length_Day, 2),
                  
                  CT_Application_Sum=CT_WP+CT_EM+CT_EA+CT_PA+CT_VC+CT_UT+CT_WB+CT_NO_APP,
                  ################################################################################
                  )
    
    
    if (baseline_parameter==lowest_baseline) {
      segment_meta_data_df <- segment_meta_data_df %>%
        dplyr::mutate(
          Mean_PP_Normalized = Mean_PP - Lowest_RB_PP,
          # Mean_PP_RW_Normalized = Mean_PP_RW - Lowest_RB_PP,
          # Mean_PP_Other_Activities_Normalized = Mean_PP_Other_Activities - Lowest_RB_PP,
          
          Mean_PP_Normalized_Percentage_Change = 100*abs(Mean_PP_Normalized/Lowest_RB_PP),
        )
      
    } else if (baseline_parameter==corresponding_baseline) {
      segment_meta_data_df <- segment_meta_data_df %>%
        dplyr::mutate(
          Mean_PP_Normalized = Mean_PP - Mean_PP_RestingBaseline,
          # Mean_PP_RW_Normalized = Mean_PP_RW - Mean_PP_RestingBaseline,
          # Mean_PP_Other_Activities_Normalized = Mean_PP_Other_Activities - Mean_PP_RestingBaseline,
          
          Mean_PP_Normalized_Percentage_Change = 100*abs(Mean_PP_Normalized/Mean_PP_RestingBaseline),
        )
    }
  
  segment_meta_data_df <- segment_meta_data_df %>% 
    dplyr::mutate(T_D=Length_Day) %>% 
    dplyr::select(
      Participant_ID,
      Day,
      
      Length_Day,
      Length_Day_Timestamp,
      DiffLengthDaySec,
      DiffLengthDayPercentage,
      
      Length_WS,
      Length_WS_Timestamp,
      DiffLengthWSSec,
      DiffLengthWSPercentage,
      
      StartSegmentTime,
      EndSegmentTime,
      DiffSegmentTimeStamp,
      DiffSegmentTimePercentage,
      DiffSegmentTimeSec,
      
      Segment,
      Length_Segment,
      Segment_Order_Percentage,
      
      Length_RestingBaseline,
      Mean_PP_RestingBaseline,
      Lowest_RB_PP,
      
      T_D, ## Exactly same as Length_Day
      Length_Break,
      Length_RW,
      Length_Missing_Activity,
      Length_Other_Activities,
      
      CT_SL,
      CT_RW,
      CT_Out,
      CT_SP,
      CT_SA,
      CT_MT,
      CT_Missing_Activity,
      CT_Other_Activities,
      CT_Activity_Sum,
      
      CT_WP,
      CT_EM,
      CT_EA,
      CT_PA,
      CT_VC,
      CT_UT,
      CT_WB,
      CT_NO_APP,
      CT_Application_Sum,
      
      # Mean_PP,
      # Mean_PP_RW,
      # Mean_PP_Other_Activities,
      
      Mean_PP_Normalized,
      # Mean_PP_RW_Normalized,
      # Mean_PP_Other_Activities_Normalized,
      
      Mean_PP_Normalized_Percentage_Change,
    )

  # View(segment_df)
  View(segment_meta_data_df)
  convert_to_csv(segment_meta_data_df, file.path(physiological_data_path, segment_meta_data_df_file_name))
  #################################################################################################################
  
  
  # #################################################################################################################
  # segment_cum_percentage_test_df <- segment_meta_data_df %>%
  #   dplyr::select(
  #     Participant_ID,
  #     Day,
  #     Segment,
  #     T_D,
  #     CT_SL,
  #     CT_Activity_Sum,
  #     CT_Application_Sum
  #     )
  # View(segment_cum_percentage_test_df)
  # #################################################################################################################
}



generate_multi_level_segment_df <- function() {
  
  segment_meta_data_df <- custom_read_csv(file.path(physiological_data_path, segment_meta_data_df_file_name)) %>% 
    dplyr::mutate(Length_Segment_Without_Break=Length_Segment-Length_Break) %>% 
    dplyr::select(Participant_ID, Day, Segment, Length_Segment_Without_Break)
  
  segment_multilevel_df <- custom_read_csv(file.path(physiological_data_path, segment_df_file_name)) %>% 
    merge(segment_meta_data_df, by=c('Participant_ID', 'Day', 'Segment')) %>% 
    dplyr::group_by(Participant_ID, Day, Segment) %>% 
    dplyr::mutate(Half_Segment_Length=floor(Length_Segment_Without_Break/2),
                  Quarter_Segment_Length=floor(Length_Segment_Without_Break/4),
                  
                  Half_Segment = ifelse(Segments_Activity=='Out', 1, row_number()%/%Half_Segment_Length+2),
                  Quarter_Segment = ifelse(Segments_Activity=='Out', 1, row_number()%/%Quarter_Segment_Length+2),
                  
                  Half_Segment = ifelse(Half_Segment > 3, 3, Half_Segment),
                  Quarter_Segment = ifelse(Quarter_Segment > 5, 5, Quarter_Segment) ,
                  
                  Segment_Multi_Level_2 = paste0(Segment, "_", Half_Segment),
                  Segment_Multi_Level_4 = paste0(Segment, "_", Quarter_Segment),
                  )
  
  convert_to_csv(segment_multilevel_df, file.path(physiological_data_path, multi_level_segment_df_file_name))
}


generate_multi_level_segment_meta_data <- function() {
  #################################################################################################################
  generate_multi_level_segment_df()
  #################################################################################################################
  
  multi_level_segment_df <- custom_read_csv(file.path(physiological_data_path, multi_level_segment_df_file_name)) %>% 
    dplyr::mutate(Segment_Multi_Level=paste0(Segment_Multi_Level_2, '_', Segment_Multi_Level_4))
  
  
  #################################################################################################################
  segment_multilevel_2_meta_data_df <- multi_level_segment_df %>%
    dplyr::group_by(Participant_ID, Day, Segment, Segment_Multi_Level_2) %>%
    dplyr::summarize(
      Mean_PP_Multi_Level_2=mean(Trans_PP[Segments_Activity!="Out"], na.rm = TRUE),
      # Mean_PP_RW_Multi_Level_2=mean(Trans_PP[Segments_Activity=="RW"], na.rm = TRUE),
      # Mean_PP_Other_Activities_Multi_Level_2=mean(Trans_PP[Segments_Activity=="Other"], na.rm = TRUE),
    ) %>%
    ungroup() %>% 
    merge(mean_df, by=c('Participant_ID')) %>% 
    merge(segment_meta_data_df_1, by=c("Participant_ID", "Day")) %>%
    dplyr::group_by(Participant_ID, Day, Segment, Segment_Multi_Level_2) 
    
    if (baseline_parameter==lowest_baseline) {
      segment_multilevel_2_meta_data_df <- segment_multilevel_2_meta_data_df %>%
        dplyr::mutate(
          Mean_PP_Multi_Level_2_Normalized = Mean_PP_Multi_Level_2 - Lowest_RB_PP,
          # Mean_PP_RW_Multi_Level_2_Normalized = Mean_PP_RW_Multi_Level_2 - Lowest_RB_PP,
          # Mean_PP_Other_Activities_Multi_Level_2_Normalized = Mean_PP_Other_Activities_Multi_Level_2 - Lowest_RB_PP,
        )
      
    } else if (baseline_parameter==corresponding_baseline) {
      segment_multilevel_2_meta_data_df <- segment_multilevel_2_meta_data_df %>%
        dplyr::mutate(
          Mean_PP_Multi_Level_2_Normalized = Mean_PP_Multi_Level_2 - Mean_PP_RestingBaseline,
          # Mean_PP_RW_Multi_Level_2_Normalized = Mean_PP_RW_Multi_Level_2 - Mean_PP_RestingBaseline,
          # Mean_PP_Other_Activities_Multi_Level_2_Normalized = Mean_PP_Other_Activities_Multi_Level_2 - Mean_PP_RestingBaseline,
        )
    }
    
  segment_multilevel_2_meta_data_df <- segment_multilevel_2_meta_data_df %>%
    dplyr::select(Participant_ID, 
                  Day, 
                  Segment,
                  Segment_Multi_Level_2, 
                  # Mean_PP_Multi_Level_2,
                  # Mean_PP_RW_Multi_Level_2, 
                  # Mean_PP_Other_Activities_Multi_Level_2,
                  Mean_PP_Multi_Level_2_Normalized
                  # Mean_PP_RW_Multi_Level_2_Normalized,
                  # Mean_PP_Other_Activities_Multi_Level_2_Normalized,
                  )
  #################################################################################################################

  
  
  #################################################################################################################
  segment_multilevel_4_meta_data_df <- multi_level_segment_df %>%
    dplyr::group_by(Participant_ID, Day, Segment, Segment_Multi_Level_4) %>%
    dplyr::summarize(
      Mean_PP_Multi_Level_4=mean(Trans_PP[Segments_Activity!="Out"], na.rm = TRUE),
      # Mean_PP_RW_Multi_Level_4=mean(Trans_PP[Segments_Activity=="RW"], na.rm = TRUE),
      # Mean_PP_Other_Activities_Multi_Level_4=mean(Trans_PP[Segments_Activity=="Other"], na.rm = TRUE),
    ) %>%
    ungroup() %>%
    merge(mean_df, by=c('Participant_ID')) %>% 
    merge(segment_meta_data_df_1, by=c("Participant_ID", "Day")) %>%
    dplyr::group_by(Participant_ID, Day, Segment, Segment_Multi_Level_4)
    
    if (baseline_parameter==lowest_baseline) {
      segment_multilevel_4_meta_data_df <- segment_multilevel_4_meta_data_df %>%
        dplyr::mutate(
          Mean_PP_Multi_Level_4_Normalized = Mean_PP_Multi_Level_4 - Lowest_RB_PP,
          # Mean_PP_RW_Multi_Level_4_Normalized = Mean_PP_RW_Multi_Level_4 - Lowest_RB_PP,
          # Mean_PP_Other_Activities_Multi_Level_4_Normalized = Mean_PP_Other_Activities_Multi_Level_4 - Lowest_RB_PP,
        )
      
    } else if (baseline_parameter==corresponding_baseline) {
      segment_multilevel_4_meta_data_df <- segment_multilevel_4_meta_data_df %>%
        dplyr::mutate(
          Mean_PP_Multi_Level_4_Normalized = Mean_PP_Multi_Level_4 - Mean_PP_RestingBaseline,
          # Mean_PP_RW_Multi_Level_4_Normalized = Mean_PP_RW_Multi_Level_4 - Mean_PP_RestingBaseline,
          # Mean_PP_Other_Activities_Multi_Level_4_Normalized = Mean_PP_Other_Activities_Multi_Level_4 - Mean_PP_RestingBaseline,
        )
    }
    
  segment_multilevel_4_meta_data_df <- segment_multilevel_4_meta_data_df %>%
    dplyr::select(Participant_ID,
                  Day,
                  Segment,
                  Segment_Multi_Level_4,
                  # Mean_PP_Multi_Level_4,
                  # Mean_PP_RW_Multi_Level_4,
                  # Mean_PP_Other_Activities_Multi_Level_4,
                  Mean_PP_Multi_Level_4_Normalized,
                  # Mean_PP_RW_Multi_Level_4_Normalized,
                  # Mean_PP_Other_Activities_Multi_Level_4_Normalized,
                  )
  #################################################################################################################
  
  View(segment_multilevel_2_meta_data_df)
  View(segment_multilevel_4_meta_data_df)
  
  convert_to_csv(segment_multilevel_2_meta_data_df, file.path(physiological_data_path, "segment_multilevel_2_meta_data_df.csv"))
  convert_to_csv(segment_multilevel_4_meta_data_df, file.path(physiological_data_path, "segment_multilevel_4_meta_data_df.csv"))
}




#-------------------------#
#-------Main Program------#
#-------------------------#
### investigate_data()
# generate_segment_df()
# generate_segment_meta_data()
# generate_multi_level_segment_meta_data()




