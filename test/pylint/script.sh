#!/bin/bash

#git diff --cached --name-only --diff-filter=ACM | grep py | xargs pylint
echo '>>>SCRIPT............................'
ls -la
git status
git log --max-count=5
echo '>>>SCRIPT.....PYCHANGES............................'

PY_CHANGES=`git diff --name-only --diff-filter=ACM HEAD^ | grep '\.py'`

echo 'PY_CHANGES='$PY_CHANGES

if [[ $PY_CHANGES ]]
then
    echo $PY_CHANGES | xargs pylint
fi
