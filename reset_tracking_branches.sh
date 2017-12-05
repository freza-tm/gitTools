#!/bin/bash
#
# call with --reset-all to reset all tracking branches, otherwise only master and release branches are reset

git diff-index --quiet HEAD > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 "[ERROR] Working directory is not clean, sync NOT performed!"
  exit 1
fi

git fetch --prune --all --tags

BRANCHMAP=$(git for-each-ref --format='%(refname:short)|%(upstream:short)' refs/heads)
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


echo ""
echo "RESETING branches:"
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

echo ""
echo "DELETING branches:"
for local in $TODELETE; do
  if [ "$local" = "$CURRENT_BRANCH" ]; then
    echo "  $local is current HEAD, cannot delete!"
  else
    echo "  $local $(git show-ref --heads -s $local)"
    git branch -d -f "$local" > /dev/null 2>&1
  fi
done

exit 0;