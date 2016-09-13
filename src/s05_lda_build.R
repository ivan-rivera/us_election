# TITLE #######################################################################
# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: preparing text corpus
# 
# INPUTS: 
# - src/s00_init.R
# - data/fb_dfm.Rdata
# 
# OUTPUTS: 
# - data/r_lda_out.Rdata
# - data/lda_frame.Rdata
#
# NOTES:
# - 

# PREAMBLE ----------------------------------------------------------------

library(tm)
library(topicmodels)
library(slam)
library(stringr)
source("src/s00_init.R")
load("data/fb_dfm.Rdata")
load("data/fb_with_sentiment.Rdata")

#time_threshold <- fb_frame_clean$created_time >= "2016-06-01"

#fb_frame_clean %<>% filter(created_time >= "2016-06-01")

# BUILD LDA ---------------------------------------------------------------


dtm <- tm::as.DocumentTermMatrix(fb_dfm)

#dtm <- dtm[time_threshold,]

nonzero_index <- row_sums(dtm)
dtm <- dtm[nonzero_index > 0,]

train_test <- sample(c(0,1), nrow(dtm), replace = T, prob = c(0.9,0.1))

# parameters
OPT_TOPICS <- 30
ALPHA_MODIFIER <- 50
DELTA <- 0.1
RSEED <- 1
BURNIN <- 500
THIN <- 5
ITER <- 1000
KEEP_WORDS <- 10

LDA_control <- list(
  alpha = ALPHA_MODIFIER/OPT_TOPICS,
  delta = DELTA,
  estimate.beta = TRUE,
  best = TRUE,
  nstart = 1,
  seed = RSEED,
  burnin = BURNIN,
  thin = THIN,
  iter = ITER
)

# build the model
(t1 <- Sys.time())
fb_lda <- LDA(
  dtm[train_test == 1,],
  OPT_TOPICS,
  method = "Gibbs",
  LDA_control
)
Sys.time()-t1

# score all data
(t1 <- Sys.time())
lda_frame <- data.frame()
rand_ind <- sample(0:9, nrow(dtm), replace = T)
for(i in 0:9){ # split up to avoid memory problems
  cat(paste("\nprocessing batch ",i))
  tmp_lda <- LDA(dtm[rand_ind == i,],model=fb_lda,control=LDA_control)
  tmp_lda_frame <- as.data.frame(posterior(tmp_lda)$topics)
  tmp_lda_frame <- cbind(
    fb_frame_clean[nonzero_index > 0,c("id",
                                       "page",
                                       "admin",
                                       "likes_count",
                                       "sentiment_avg",
                                       "created_time")][rand_ind == i,],
    tmp_lda_frame
  )
  lda_frame <- rbind(lda_frame,tmp_lda_frame)
}
Sys.time()-t1

# extract term weights
term_weights <- as.data.frame(t(posterior(fb_lda)$terms))
total_word_weights <- col_sums(dtm[,rownames(term_weights)]) / sum(dtm[,rownames(term_weights)])
tw_df <- data.frame()
for(i in 1:ncol(term_weights)){
  tw_df <- rbind(tw_df,
                 term_weights %>% 
                   mutate(topic  = paste0("t",str_pad(i, 2, pad = "0")),
                          word   = rownames(.),
                          weight = .[,i]) %>%
                   select(topic,word,weight) %>% arrange(desc(weight)) %>% 
                   head(n=KEEP_WORDS)
  )
}

colnames(lda_frame)[7:ncol(lda_frame)] <- paste0("t",str_pad(1:(ncol(lda_frame)-6), 2, pad = "0"))

# name the topics
t_num <- "t20"
tw_df %>% filter(topic == t_num)
lda_frame %>% select_(.dots=c("id",t_num)) %>% arrange_(t_num) %>% tail()
fb_frame_clean %>% filter(id == "10156960073880725_1190121551006883") %>% select(message) # check out comments

topic_df <- data.frame(
  topic = paste0("t",formatC(seq(1:30),width=2,flag="0")),
  desc = c(
    "Democrats vs GOP Parties", #t1
    "Promises vs Actions", #t2
    "Chants of Support", #t3
    "Voting", #t4
    "The System and Corruption", #t5
    "Money and Donations", # t6
    "Obama", #t7
    "Melania Trump", # t8
    "Terrorism", # t9
    "Misc 1", # t10 -- not an informative topic, could be remove with vocab filtering
    "Law and Constitution", # t11
    "God and Christian Values", # t12
    "Democratic Candidates", # t13
    "Donald Trump for President", # t14
    "Lies", # t15
    "Ethnicity", # t16 
    "Minor Presidential Candidates", # t17
    "Clinton Family", # t18
    "State Elections", # t19
    "Clinton Email Scandal", # t20
    "Future Generations", # t21
    "Jobs and Immigration", # t22
    "Misc 2", # t23 -- dubious
    "Misc 3", # t24 -- dubious
    "Leadership", # t25
    "News and Media", # t26
    "Misc 4", # t27
    "Web Links", # t28
    "Tax and Government Spendings", # t29
    "War and Military" # t30
  ),
  stringsAsFactors = FALSE
)

colnames(lda_frame)[7:ncol(lda_frame)] <- topic_df$desc

# get dominant topics
lda_frame$dominant_topic <- apply(lda_frame[7:ncol(lda_frame)],1,function(x) colnames(lda_frame[7:ncol(lda_frame)])[which.max(x)])
lda_frame <- lda_frame[,c(1:6,ncol(lda_frame),7:(ncol(lda_frame)-1))]

# SAVE OUTPUTS ------------------------------------------------------------

save(total_word_weights, term_weights, tw_df, file = "data/r_lda_out.Rdata")
save(lda_frame, file = "data/lda_frame.Rdata")
