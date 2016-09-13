# TITLE #######################################################################
# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: extracting data from the target Facebook pages
# 
# INPUTS: 
# - src/s00_init.R
# - data/fb_extract.Rdata
# OUTPUTS: 
# - data/fb_frame_clean.Rdata
# - data/sent_frame.Rdata
# - data/sent_frame.txt
#
# NOTES:
# - Don't bother correcting the spelling, it's ineffective.

# PREAMBLE ----------------------------------------------------------------

source("src/s00_init.R")
p_load(
  tm,
  qdap,
  parallel,
  doParallel,
  foreach
)
load("data/fb_extract.Rdata")



# DATASET RESTRUCTURE -----------------------------------------------------

# restructure dataset
(t1 <- Sys.time())
fb_frame_clean <- fb_frame %>% filter(
  !duplicated(.), # remove duplicated
  !is.na(message), # drop observations with no comments
  nchar(message) > 10, # drop observations with fewer than 10 characters
  substr(created_time,1,10) < max(substr(created_time,1,10)) # remove the latest date, it probably isn't the full day of data
) %>% mutate(
  created_time = substr(created_time,1,10), # extract date
  votes = likes_count, # accounting for the creator of the post
  message = iconv(message,"latin1","ASCII"), # convert to ASCII
  message = gsub("\\s{2,}"," ",Trim(message)) # remove leading, trailing and extra spaces
) %>% select(
  id, 
  from_id, 
  reply_to_id, 
  page, 
  admin, 
  likes_count,
  created_time, 
  message) # oppostion column is empty
Sys.time()-t1 # run time: 46 seconds



# TEXT PROCESSING ---------------------------------------------------------

# extract hashtags
(t1 <- Sys.time())
fb_frame_clean$hashtags <- as.character(sapply(fb_frame_clean$message, function(x) paste0(unlist(rm_hash(x, extract = T)), collapse = ", ")))
Sys.time() - t1 # run time: 3 mins

# remove unwanted content (URLs, citations, hashtags)
(t1 <- Sys.time())
fb_frame_clean$message %<>% rm_(pattern=pastex(paste0("@rm_",c("twitter_url","url","hash","citation"))))()
Sys.time() - t1 # run time: 1.12 mins

# replace emoticons and emojis
(t1 <- Sys.time())
pb <- txtProgressBar(min = 0, max = nrow(emoji_data), style = 3)
for(i in 1:nrow(emoji_data)){
  fb_frame_clean$message %<>% gsub(emoji_data$r_encoding[i],
                                   sprintf(" %s ",emoji_data$category[i]), 
                                   .)
  setTxtProgressBar(pb,i)
}
close(pb)
Sys.time() - t1 # run time: 11.7 mins


# expand contractions, abbreviations and ordinals, numbers and symbols (keep ' if you want to do this)
# (t1 <- Sys.time())
# for(i in c(
#   "contraction",
#   "abbreviation",
#   "ordinal",
#   "number",
#   "symbol"
# )){
#   cat(paste("working on",i))
#   fb_frame_clean$message %<>% list() %>% do.call(paste0("replace_",i),.)
# }
# Sys.time() - t1 # # run time: 

# fix the spelling (not worth the trouble, not accurate)
# csi <- check_spelling_interactive(fb_frame_clean$message[sample(nrow(fb_frame_clean),100)])
# # preprocessed(csi)
# fix_spelling <- attributes(csi)$correct
# t1 <- Sys.time()
# fb_frame_clean$message <- fix_spelling(fb_frame_clean$message)
# Sys.time() - t1 # # run time: 

# replace unwanted punctuations
(t1 <- Sys.time())
fb_frame_clean$message <- ifelse(is.na(fb_frame_clean$message),
                                 NA,paste0(fb_frame_clean$message,".")
                                 ) %>%
  gsub("(?![-.,?!\\w\\s])[[:punct:]]"," ",.,perl=T) %>%
  gsub("\\s{2,}"," ",.) %>%
  gsub("(?<=[[:punct:]])[[:punct:]]+","",.,perl=T)  %>%
  gsub("\\s+(?>[[:punct:]])","",.,perl=T) %>%
  gsub("([[:punct:]]+)","\\1 ",.) %>%
  Trim() %>% 
  gsub("\\s+"," ",.)
Sys.time() - t1 # # run time: 1.3 mins

# filter out missings again
fb_frame_clean %<>% filter(!is.na(message))

# split into sentences (for sentiment processing)
(t1 <- Sys.time())
sent_frame <- sentSplit(as.data.frame(fb_frame_clean),"message") # sentence splitter (ignore warnings)
sent_frame$obs <- as.numeric(gsub("(^\\d+).*$","\\1",sent_frame$tot)) # get observation numbers
sent_frame$sen <- as.numeric(gsub("^\\d+\\D(.*$)","\\1",sent_frame$tot)) # get sentence numbers
Sys.time() - t1 # # run time: 

# SAVE OUTPUTS ------------------------------------------------------------

save(fb_frame_clean, file="data/fb_frame_clean.Rdata")
save(sent_frame, file = "data/sent_frame.Rdata")
writeLines(sent_frame$message, "data/sent_frame.txt")
# write.csv(fb_frame_clean, file = "data/fb_frame_clean.csv",row.names=FALSE)
