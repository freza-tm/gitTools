#! /bin/bash
git diff-index --quiet HEAD > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo >&2 "[ERROR] Working directory is not clean, check NOT performed!"
   exit 1
fi

exitStatus=0

if [ $# -eq 1 ]; then
   git checkout -b master-merge-dry-run $1 > /dev/null 2>&1
else
   git checkout -b master-merge-dry-run > /dev/null 2>&1
fi

if [ $? -ne 0 ]; then
   echo >&2 "[ERROR] Checkout failed, probably wrong starting point. Check NOT performed!"
   exit 1
fi


git merge --no-commit --no-ff origin/master > /dev/null 2>&1

if [ $? -ne 0 ]; then
   echo >&2 "[WARNING] Merge conflict to master, create conflict branch if necessary!"
   exitStatus=1
else
   echo >&2 "[OK] Merge to master clean."
fi

git merge --abort > /dev/null 2>&1
git checkout - > /dev/null 2>&1
git branch -D master-merge-dry-run > /dev/null 2>&1
exit $exitStatus
