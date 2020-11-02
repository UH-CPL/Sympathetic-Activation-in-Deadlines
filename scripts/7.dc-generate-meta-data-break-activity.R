#-------------------------#
#--------LIBRARIES--------#
#-------------------------#
library(dplyr)




#-------------------------#
#-----GLOBAL VARIABLES----#
#-------------------------#
source(file.path(script_dir, 'us-common-functions.R'))




#-------------------------#
#---FUNCTION DEFINITION---#
#-------------------------#
generate_meta_data_break_activity <- function() {
  physiological_data_path <- file.path(project_dir, curated_data_dir, physiological_data_dir)
  
  
  #################################################################################################################
  # # ### 'mini_full_df.csv'
  # # ### full_df_file_name
  # data_file_name <- 'mini_full_df.csv'
  # 
  # segment_df <- custom_read_csv(file.path(physiological_data_path, data_file_name)) %>%
  #   dplyr::select(Participant_ID, Day, Treatment,
  #                 Timestamp, Sinterface_Time, TreatmentTime,
  #                 Trans_PP,
  #                 Segments_Activity,
  #                 Mask) %>%
  #   mutate(Segments_Activity=case_when(Treatment=="RB"~"Out",
  #                                           TRUE~.$Segments_Activity)) %>%
  #   dplyr::group_by(Participant_ID, Day) %>%
  #   mutate(Counter=sequence(rle(as.character(Segments_Activity))$lengths),
  #          Segment=case_when(Segments_Activity=="Out" & Counter==1~1, TRUE~0),
  #          Segment=ifelse(Segment==1, cumsum(Segment==1), NA),
  #          Segment=na.locf0(Segment)) %>%
  #   select(-Counter)
  # 
  # View(segment_df)
  # 
  # convert_to_csv(segment_df, file.path(physiological_data_path, segment_df_file_name))
  #################################################################################################################

  
  segment_df <- custom_read_csv(file.path(physiological_data_path, segment_df_file_name))

  segment_meta_data_df_1 <- segment_df %>%
    dplyr::group_by(Participant_ID, Day) %>%
    summarize(Length_Day=n(),
              Mean_PP_BR=mean(Trans_PP[Segments_Activity=="Out" & Segment==1], na.rm = TRUE),
              Length_BR=length(Trans_PP[Segments_Activity=="Out" & Segment==1])) %>%
    ungroup()
    
    
  segment_meta_data_df_2 <- segment_df %>%
    dplyr::group_by(Participant_ID, Day, Segment) %>%
    summarize(
          ## StartTime=head(Timestamp, 1),
          ## EndTime=tail(Timestamp, 1),
      
          # Mean_Trans_PP=mean(Trans_PP, na.rm = TRUE),
      
          SegmentLength=n(),
          
          # BreakTime=sum(Segments_Activity=="Out", na.rm = T),
          BreakTime=sum(Segments_Activity=="Out"),
          ReadingWritingTime=sum(Segments_Activity=="RW"),
          Mean_PP_RW=mean(Trans_PP[Segments_Activity=="RW"], na.rm = TRUE),
          OtherActivitiesTime=sum(Segments_Activity=="Other"),
          Mean_PP_Other=mean(Trans_PP[Segments_Activity=="Other"], na.rm = TRUE))


  
  segment_meta_data_df <- segment_meta_data_df_1 %>% 
    merge(segment_meta_data_df_2, by=c("Participant_ID", "Day")) %>%
    select(
      Participant_ID,
      Day,
      Length_Day,
      Segment,
      SegmentLength,
      Length_BR,
      Mean_PP_BR,
      BreakTime,
      ReadingWritingTime,
      Mean_PP_RW,
      OtherActivitiesTime,
      Mean_PP_Other
    )
  
  # View(segment_meta_data_df)
  # View(segment_meta_data_df_1)
  # View(segment_meta_data_df_2)
  
  convert_to_csv(segment_meta_data_df, file.path(physiological_data_path, segment_meta_data_df_file_name))
}


#-------------------------#
#-------Main Program------#
#-------------------------#
generate_meta_data_break_activity()