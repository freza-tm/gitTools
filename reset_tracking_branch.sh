#!/bin/bash
#
# call with SHA as parameter

if [ $# -ne 1 ]; then
  echo "Expected branch name as a parameter!"
  exit 1
fi

LOCAL=$1
LOCAL_FULL=refs/heads/$LOCAL
REMOTE=$1
REMOTE_FULL=refs/remotes/$REMOTE

git show-ref --verify --quiet $LOCAL_FULL 2>/dev/null
if [[ $? -eq 0 ]]; then
  REMOTE=$(git for-each-ref --format='%(upstream:short)' $LOCAL_FULL)
  REMOTE_FULL=refs/remotes/$REMOTE
  
  if [ -z "$REMOTE" ]; then
    echo "Local branch $LOCAL is not tracking any remote branch!"
    exit 0
  fi;

  git show-ref --verify --quiet $REMOTE_FULL
  if [ $? -ne 0 ]; then
    echo "Remote branch $REMOTE no longer exists!"
    exit 1
  fi
else
  git show-ref --verify --quiet $REMOTE_FULL 2>/dev/null
  if [[ $? -eq 0 ]]; then
    LOCAL=$(git for-each-ref --format='%(refname:short):%(upstream:short)' refs/heads/** | grep ":$REMOTE" | cut -d: -f1)
    if [[ -z $LOCAL ]]; then
      # create a name for the new local branch
      LOCAL=$(echo $REMOTE | cut -d/ -f2-)
    fi
  else
    echo "$1 does not represent a valid short branch name!"
    exit 1
  fi
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo
echo "$LOCAL -> $REMOTE"

if [ "$LOCAL" = "$CURRENT_BRANCH" ]; then
  git diff-index --quiet HEAD > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo >&2 "[ERROR] Working directory is not clean, sync NOT performed!"
    exit 1
  fi
  git reset --hard "$REMOTE" > /dev/null 2>&1
else
  git branch -f "$LOCAL" "$REMOTE" > /dev/null 2>&1
fi

exit 0;