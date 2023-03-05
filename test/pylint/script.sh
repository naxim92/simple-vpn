#!/bin/bash

git config --global safe.directory '*'
PY_CHANGES=`git diff --name-only --diff-filter=ACM HEAD^ | grep '\.py'`

echo 'PY_CHANGES='$PY_CHANGES

if [[ $PY_CHANGES ]]
then
    echo $PY_CHANGES | xargs pylint
fi
