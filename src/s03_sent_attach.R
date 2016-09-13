# TITLE #######################################################################
# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: attaching sentiment scores to the dataset
# 
# INPUTS: 
# - src/s00_init.R
# - data/sent_frame_annotated.txt
# - data/fb_frame_clean.Rdata
# - data/sent_frame.Rdata
# 
# OUTPUTS: 
# - data/fb_with_sentiment.Rdata
#
# NOTES:
# - run sentiment_annotation.sh first.

# PREAMBLE ----------------------------------------------------------------

library(qdap)

# source init
source("src/s00_init.R")

# load data
load("data/fb_frame_clean.Rdata")
load("data/sent_frame.Rdata")
sentiment_score <- readLines("data/sent_frame_annotated.txt")


# PROCESSING --------------------------------------------------------------

# integrating sentiment
sent_frame$sentiment <- gsub("^\\s+|\\s+$","",sentiment_score) # clean leading spaces
t1 <- Sys.time()
sent_frame %<>% mutate(
  sentiment_score = NA,
  sentiment_score = ifelse(sentiment == "Very Negative",-2,sentiment_score),
  sentiment_score = ifelse(sentiment == "Negative",     -1,sentiment_score),
  sentiment_score = ifelse(sentiment == "Neutral",       0,sentiment_score),
  sentiment_score = ifelse(sentiment == "Positive",      1,sentiment_score),
  sentiment_score = ifelse(sentiment == "Very Positive", 2,sentiment_score)
  #txt_weight      = wc(message)  # obtain sentence length for weighting
) %>% select(-sentiment)
Sys.time() - t1 # computation time: 15.66 mins

# averaging
sent_frame %<>% group_by(obs) %>% 
  #summarise(sentiment_avg = sum(sentiment_score*txt_weight)/sum(txt_weight)) %>% 
  summarise(sentiment_avg = mean(sentiment_score)) %>%
  ungroup()

# combine datasets
fb_frame_clean %<>% cbind(sent_frame) %>% select(-obs)


# SAVE OUTPUTS ------------------------------------------------------------

save(fb_frame_clean, file = "data/fb_with_sentiment.Rdata")

