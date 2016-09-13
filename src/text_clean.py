# Exploring the content of Donald Trump's and Hillary Clinton's Facebook Pages
# ****************************************************************************
#
# PURPOSE: Testing python's tm capabilities
#
# INPUTS:
# - data/fb_frame_clean.csv
# OUTPUTS:
# -
#
# NOTES:
# -

# PREAMBLE ----------------------------------------------------------------

import re
import pandas as pd

# read the data
fb_extract = pd.read_csv('data/fb_frame_clean.csv')

# inspect column headers
# fb_extract.columns

# isolate text
txt = [i for i in fb_extract.message[0:10]]



# TEXT CLEANING ------------------------------------------------------------

# trying text blob
import textblob
txt = [textblob.TextBlob(text) for text in txt]

# correct spelling (this is a joke!)
for text in txt:
    tc = text.correct()
    if str(tc) != str(text):
        print('ORIGINAL: \n' + str(text) + '\nCORRECTED: \n' + str(tc))


# lemmatisation (nothing fancy)
for text in txt:
    for w in text.words:
        l = w.lemmatize()
        if w != l:
            print(l + ' --- ' + w)


# SENTIMENT TEST -----------------------------------------------------------


for text in txt:
    print(text.sentiment)

# NOTE: vaderSentiment doesn't seem to work (equivalent of qdap)

# NOTE: there is a wrapper for Stanford CoreNLP but nothing as comprehensive as Rs stansent


# CORPUS PREPARATION -------------------------------------------------------

# stem, filter based on tf idf
import nltk
import gensim

# tokeniser and cleaner
def tokenize_txt(text):
    return [
        token for token in gensim.parsing.preprocess_string(text)
        if text not in gensim.parsing.STOPWORDS
        ]

token_list = [tokenize_txt(t) for t in txt]

# create a dictionary
tdict = gensim.corpora.Dictionary(token_list)

tdict.doc2bow(token_list[0])

# TOPIC MODELLING ----------------------------------------------------------

# EXTRA FEATURES -----------------------------------------------------------
