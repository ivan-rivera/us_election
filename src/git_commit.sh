#!/bin/bash

# GIT COMMIT FILE

cd ~/Documents/Projects/us_election/

# Commit message
# COMMIT_MESSAGE="$1"
COMMIT_MESSAGE="first commit"

# FIRST RUN
# ---------------
# git init
# git add remote ...


cat <<EOF > .gitignore
# GIT IGNORE FILE
# ===============
# R files
*.Rproj
*.Rdata
.Rproj.user
.Rhistory
.Rdata
.Ruserdata
.DS_Store
# ---------------
# FB authentication
extra01_app_access.R
# ----------------
# Reports
reports/*
# ----------------
# Self
src/git_commit.sh
# ----------------
EOF

# sync
git pull origin
git add *
git commit -u -m "$COMMIT_MESSAGE"
git push -u origin --all

