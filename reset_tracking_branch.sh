#!/bin/bash
#
# call with SHA as parameter

if [ $# -ne 1 ]; then
  echo "Expect commit hash as parameter!"
  exit 1
fi

LOCAL=`git name-rev --name-only --no-undefined $1`
if [ $? -ne 0 ]; then
  echo "Given SHA is not local branch!"
  exit 1
fi

REMOTE=`git for-each-ref --format='%(upstream:short)' refs/heads/$LOCAL`

if [ -z "$REMOTE" ]; then
  echo "Local branch is not tracking remote!"
  exit 0
fi;

git show-ref --verify --quiet "refs/remotes/$REMOTE"
if [ $? -ne 0 ]; then
  echo "Remote branch no longer exists!"
  exit 1
fi

CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

echo ""
echo "$LOCAL -> $REMOTE"
if [ "$LOCAL" = "$CURRENT_BRANCH" ]; then
  git reset --hard "$REMOTE" > /dev/null 2>&1
else
  git branch -f "$LOCAL" "$REMOTE" > /dev/null 2>&1
fi

exit 0;