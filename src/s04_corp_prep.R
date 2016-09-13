# TITLE #######################################################################
# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: preparing text corpus
# 
# INPUTS: 
# - src/s00_init.R
# - data/fb_with_sentiment.Rdata
# 
# OUTPUTS: 
# - data/fb_dfm.Rdata
#
# NOTES:
# - 

# PREAMBLE ----------------------------------------------------------------

source("src/s00_init.R")
load("data/fb_with_sentiment.Rdata")

library(stringr)
library(qdap)
library(tm)
library(gofastr)
library(slam)
library(quanteda)

# prepare stopwords
stops <- c(
  tm::stopwords("english"),
  stopwords("SMART"),
  Top200Words
) %>% prep_stopwords() 

# set up constants
MIN_WORD_FREQ <- 1000
MIN_CHAR <- 4

# PROCESSING --------------------------------------------------------------

# clean text
fb_frame_clean %<>% mutate(
  message = tolower(message),
  message = gsub("[[:punct:]]|\\d","",message),
  message = gsub("^\\s+|\\s+$","",Trim(message))
)

(t1 <- Sys.time())
txt_corpus <- Corpus(VectorSource(fb_frame_clean$message))
txt_corpus <- tm_map(txt_corpus, removeWords, stops)
fb_dfm <- TermDocumentMatrix(txt_corpus,
                             list(minDocFreq = MIN_WORD_FREQ, 
                                  bounds=list(global=c(MIN_WORD_FREQ, 5*10^5)),
                                  wordLengths = c(MIN_CHAR,Inf), 
                                  tolower = FALSE, 
                                  stripWhitespace = TRUE, 
                                  removeNumbers = FALSE, 
                                  removePunctuation = FALSE, 
                                  stemming = TRUE, 
                                  stopwords = FALSE, 
                                  weighting = weightTf))
Sys.time() - t1 # 2.7 hours


# SAVE OUTPUTS ------------------------------------------------------------

save(fb_dfm, file = "data/fb_dfm.Rdata")
