#!/bin/bash
#
# call with --reset-all to reset all tracking branches, otherwise only master and release branches are reset

git diff-index --quiet HEAD > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 "[ERROR] Working directory is not clean, sync NOT performed!"
  exit 1
fi

git fetch --all --tags

BRANCHMAP=$(git for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:trackshort)' refs/heads)
AHEADS=$(echo "$BRANCHMAP" | grep ">" | cut -f1 -d '|')

BRANCHMAP=$(echo "$BRANCHMAP" | grep -v ">" | cut -f1,2 -d '|')

git fetch --prune --all --tags

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo ""
echo "NON-TRACKING branches:"
for branchpair in $BRANCHMAP; do
  local=${branchpair%|*}
  remote=${branchpair#*|}
  if [ -n "$remote" ]; then
    #check if remote is valid
    git show-ref --verify --quiet "refs/remotes/$remote"
    if [ $? -ne 0 ]; then
      TODELETE="${TODELETE}
      ${local}"
    else
      TORESET="${TORESET}
      ${branchpair}"
    fi
  else
    echo "  $local"
  fi
done

if [[ -n $1 || $1 != "--reset-all" ]]; then
  ALLRESETS=$TORESET
  TORESET=""
  for branchpair in $ALLRESETS; do
    if [[ "$branchpair" == master* || "$branchpair" = release* || "$branchpair" = frozen* ]]; then
      TORESET="${TORESET}
      ${branchpair}"
    fi
  done
fi

if [[ -n $TORESET ]]; then
  echo
  echo "RESETTING branches:"
  for branchpair in $TORESET; do
    local=${branchpair%|*}
    remote=${branchpair#*|}
    echo "  $local -> $remote"
    if [ "$local" = "$CURRENT_BRANCH" ]; then
    git reset --hard "$remote" > /dev/null 2>&1
    else
    git branch -f "$local" "$remote" > /dev/null 2>&1
    fi
  done
fi

TOUNTRACK=$(comm -12 <(echo $AHEADS) <(echo $TODELETE) )
TODELETE=$(comm -13 <(echo $AHEADS) <(echo $TODELETE) )

for branch in $TOUNTRACK; do
  git branch --unset-upstream $branch
done

if [[ -n $TOUNTRACK ]]; then
  TOUNTRACK=$(echo "$TOUNTRACK" | sed -r "s/^/  /")
  echo ""
  echo "UNTRACKING branches:
$TOUNTRACK"
fi

if [[ -n $TODELETE ]]; then
  echo
  echo "DELETING branches:"
  for local in $TODELETE; do
    if [ "$local" = "$CURRENT_BRANCH" ]; then
    echo "  $local is current HEAD, cannot delete!"
    else
    echo "  $local $(git show-ref --heads -s $local)"
    git branch -d -f "$local" > /dev/null 2>&1
    fi
  done
fi

exit 0;