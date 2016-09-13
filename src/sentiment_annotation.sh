#!/bin/bash

# *** SENTIMENT ANNOTATION USING STANFORD CORE NLP ***

# NOTE: This will take a while, run in screen on a server if possible...

java -cp "/Users/Ivan/Documents/Utilities/stanford-corenlp-full-2015-04-20/*" \
-mx5g edu.stanford.nlp.sentiment.SentimentPipeline \
-stdin < /Users/Ivan/Documents/Projects/us_election/data/sent_frame.txt >\
/Users/Ivan/Documents/Projects/us_election/data/sent_frame_annotated.txt

# check progress:
cat sent_frame_annotated.txt | wc -l
echo $((100*$(cat sent_frame_annotated.txt | wc -l)/$(cat sent_frame.txt | wc -l)))%