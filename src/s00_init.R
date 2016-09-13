# TITLE #######################################################################
# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: helper file with functions and constants
# 
# INPUTS: 
# - None
# OUTPUTS: 
# - VARIABLES
#   * fb_pages
# 
# NOTES:
# - DonaldTrump page appears to be more popular, but extract tends to fail,
#   attempted DonaldTrump4President instead


# PREAMBLE ----------------------------------------------------------------

library(pacman)

p_load(
  plyr,
  dplyr,
  tidyr,
  magrittr,
  ggplot2,
  readxl
)

# emoji data
emoji_data <- read_excel("resource/emoji_ann.xlsx")
emoji_data <- emoji_data[which(!is.na(emoji_data$Category)),c("R-encoding","Category")]
colnames(emoji_data) <- c("r_encoding","category")
emoji_data <- rbind(
  emoji_data %>% filter(category %in% c("happy","angry","love","sad","confusion")),
  data.frame(
    r_encoding = paste0("(\\=|\\:|;|\\-).?",paste0("\\",c(")","]","}","(","[","{","\\","\\/"))),
    category   = c(rep("happy",3),rep("sad",3),rep("confused",2)),
    stringsAsFactors = FALSE
  )
)

# CONSTANTS ---------------------------------------------------------------

#fb_pages <- c("DonaldTrump4President","hillaryclinton")
fb_pages <- c("DonaldTrump","hillaryclinton")

# FUNCTIONS ---------------------------------------------------------------


save_extract <- function(target_dataset,target_source = "facebook"){
  
  # this function saves a new extract and aggregated it with the existing extracts of the same type, keeping only unique entries
  # and keeps a backup of the previous version
  
  TS <- gsub("-","_",as.Date(Sys.time(),tz="NZ"))
  
  # read earlier versions
  earlier_versions <- list.files("data/","facebook_extract_")
  assign(paste0(target_source,"_files"), earlier_versions)
  
  if(length(earlier_versions) > 0){
    for(i in earlier_versions) load(paste0("data/",i))
    latest_version = system(sprintf("ls -t data/ | grep %s_extract_ | head -n 1",target_source),intern=T) # to keep a backup of latest file
  }
  
  aggregate_dataset <- 
    do.call("rbind",lapply(ls(patt=sprintf("^%s_extract_|target_dataset",target_source)),function(x) get(x,inherits=T))) %>%
    filter(!duplicated(.))
  
  # come up with an appropriate name for the new extract
  new_f_lab <- sprintf("new_%s_file_lab",target_source)
  assign(new_f_lab, sprintf("%s_extract_%s",target_source,TS))
  
  # in case of a clash add an extra suffix to the name
  counter <- 1
  while(get(new_f_lab) %in% gsub(".Rdata","",get(paste0(target_source,"_files")))){
    assign(new_f_lab, sprintf("%s_extract_%s_%s",target_source,TS,counter))
    counter <- counter+1
  }
  
  assign(get(new_f_lab),aggregate_dataset)
  
  save(list=get(new_f_lab), file=paste0("data/",get(new_f_lab),".Rdata"))
  
  # remove older versions except for the very latest one -- save that as a backup
  # if we are going to run these weekly, we would quickly collect a lot of unnecessary files...
  files_to_drop = base::setdiff(earlier_versions,latest_version)
  if(length(files_to_drop) > 0){
    for(i in files_to_drop) file.remove(paste0("data/",i))
  }
}

