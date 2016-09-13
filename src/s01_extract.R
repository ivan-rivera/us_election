# TITLE #######################################################################
# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: extracting data from the target Facebook pages
# 
# INPUTS: 
# - src/s00_init.R
# - fb_auth.Rdata
# OUTPUTS: 
# - data/fb_frame.Rdata
#
# NOTES:
# - Facebook API is not very stable, errors maybe encountered -- "Please try again later"
# - this script requires the existence of a fb_auth file which is produced
#   with a Rfacebook::fbOAuth() function. An FB token is required for this,
#   to get one, visit: https://developers.facebook.com/
# - later in the project, it was noticed that the data extract did not
#   collect all the comments for Hillary Clinton, the data was only there from
#   June onwards. Therefore during the later stages, this data was truncated for
#   Trump too.


# PREAMBLE ----------------------------------------------------------------

source("src/s00_init.R")
p_load(Rfacebook)
load("fb_auth.Rdata")

# EXTRACT -----------------------------------------------------------------

# test run:
# test <- getPage("DonaldTrump4President", fb_auth, n = post_n, since = since_date, feed = TRUE)

post_n <- 2000  # number of threads (posts that aren't replies) to collect
reply_n <- 1000  # how many replies to collect
since_date <- "2016/01/01"  # collect from this date onwards

page_comments <- list()
for(i in fb_pages){
  cat(sprintf("retrieving data from the page of %s...\n",i))
  visit_page <- getPage(i, fb_auth, n = post_n, since = since_date, feed = TRUE)
  post_df <- data.frame()
  pb <- txtProgressBar(min = 0, max = length(visit_page$id), style = 3)
  for(j in 1:length(visit_page$id)){
    tmp_df <- tryCatch(getPost(visit_page$id[j],n = reply_n, token = fb_auth)$comments, error = function(e) data.frame())
    if(nrow(tmp_df) > 0){
      tmp_df$reply_to_id <- visit_page$id[j]
      post_df <- rbind(tmp_df,post_df)
    }
    setTxtProgressBar(pb,j)
  }
  close(pb)
  post_origin_df <- visit_page[,c("from_id","from_name","message","created_time","likes_count","id")]
  post_origin_df$reply_to_id <- NA
  post_df <- rbind(post_df,post_origin_df)
  post_df$page <- i
  page_comments[[i]] <- post_df
}
fb_frame <- ldply(1:length(page_comments), function(x) page_comments[[x]])
fb_frame %<>% mutate(
  admin = ifelse(  # identify instances where candidates create their own posts
    (from_name %in% c(
      "Donald J. Trump",
      "Donald Trump For President"
      ) & grepl("DonaldTrump",page)  # keep this general in case page name changes
     ) 
    | 
      (from_name == "Hillary Clinton" & 
         page == "hillaryclinton"), 
    TRUE, FALSE),
  opposition = ifelse(  # identify instances where candidates are commenting on each others posts
    (from_name %in% c(
      "Donald J. Trump",
      "Donald Trump For President") & 
       page == "hillaryclinton") 
    | 
      (from_name == "Hillary Clinton" & 
         grepl("DonaldTrump",page)), 
    TRUE, FALSE)
)


# SAVE OUTPUTS ------------------------------------------------------------

save(fb_frame,file="data/fb_extract.Rdata")
# csv extract
