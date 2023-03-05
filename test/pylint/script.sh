#!/bin/bash

#git diff --cached --name-only --diff-filter=ACM | grep py | xargs pylint

PY_CHANGES=`git diff --cached --name-only --diff-filter=ACM | grep '\.py'`

echo 'PY_CHANGES='$PY_CHANGES

if [[ $PY_CHANGES ]]
then
    echo $PY_CHANGES | xargs pylint
fi
